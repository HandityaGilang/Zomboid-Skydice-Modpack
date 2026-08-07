--[[
    "psr_powerbank" server lua object — B42 rewrite (no SGlobalObject dependency)
--]]

if isClient() and not isServer() then return end   -- coop host = isClient ET isServer vrais : ne couper QUE le client pur (sinon le système serveur est mort sur l'hôte coop)

local PSR = require "PSR/Utilities"
require "PSR/PSRStructures"

-- ⚠️ 2026-08-04 — la capture `local sandbox = SandboxVars.PSR or {}` était une garde ILLUSOIRE :
-- elle empêchait l'erreur d'indexation, mais si `SandboxVars.PSR` n'était pas encore peuplé au
-- chargement du module, `sandbox` restait **une table vide POUR TOUJOURS** ⇒ toute option lue
-- dessus valait `nil`, en silence, pour le reste de la partie.
-- 🔑 Conséquence concrète sur `batteryDegradeChance` : le test `== 0` (« 0 désactive ») devenait
--    `nil == 0` = faux ⇒ **la dégradation des batteries tournait quoi qu'ait réglé le joueur**.
--    C'est exactement la famille « option qui ment » traitée en vague 2 — le 3ᵉ membre, resté nu.
-- ⇒ lecture EN DIRECT au point d'usage (même idiome que `psrDrainRate` juste en dessous).
local function psrSandbox() return (SandboxVars and SandboxVars.PSR) or {} end

---@class PowerBankObject_Server
---@field luaSystem PowerbankSystem_Server
---@field x number
---@field y number
---@field z number
local PowerBank = {}
PowerBank.__index = PowerBank

function PowerBank:getSquare()
    return getSquare(self.x, self.y, self.z)
end

function PowerBank:getIsoObject()
    local square = self:getSquare()
    if not square then return nil end
    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if instanceof(obj, "IsoGenerator") and PSR.WorldUtil.getType(obj) == "PowerBank" then
            return obj
        end
    end
end

function PowerBank:initNew()
    self.on = false
    self.activated = false
    self.batteries = 0
    self.charge = 0
    self.maxcapacity = 0
    self.panels = {}
    self.npanels = 0
    self.drain = 0
    self.lastHour = 0
    self.conGenerator = false
    self.PSR_linkedBanks = {}
    self.PSR_manualStructures = {}
end

---Called for new objects (no saved state). Initialises from world and saves.
---@param isoObject IsoObject
function PowerBank:stateFromIsoObject(isoObject)
    self:initNew()

    -- 🩹 RESTAURATION AVANT DE REPARTIR DE ZERO (audit 2026-08-04).
    -- On arrive ici quand le systeme n'a PAS d'entree globale pour cette case. Ce n'est pas
    -- toujours une bank neuve : l'entree peut avoir ete purgee par `OnChunkLoaded` (voir le
    -- correctif jumeau dans PowerBankSystem_Server) ou perdue a la migration d'une save.
    -- Or l'IsoObject porte le MIROIR COMPLET de l'etat : `toModData` y ecrit les 13 champs de
    -- `savedObjectModData` a CHAQUE `saveData`. Repartir de `initNew()` seul rendait la bank
    -- ETEINTE, sans panneaux, sans reseau et sans structures connectees — un blackout de base.
    --
    -- ⚖️ Portee exacte, mesuree et non supposee : `charge`, `maxcapacity` et `batteries` ne sont
    -- PAS concernes — `calculateBatteryStats` (juste dessous) les recalcule depuis les batteries
    -- du conteneur, qui persistent avec l'objet. Ce qui se perdait, c'est `on`, `panels`,
    -- `npanels`, `PSR_linkedBanks`, `PSR_manualStructures` et `activated`.
    --
    -- Le miroir est la source de verite quand il existe ⇒ on le rejoue AVANT de completer.
    -- Les recalculs qui suivent ecrasent volontairement ce qu'ils savent mieux (stats batteries,
    -- drain), donc l'ordre compte et il est deliberé.
    local md = isoObject:getModData()
    if md and md.on ~= nil then          -- meme test de presence que loadIsoObject (`pb.on ~= nil`)
        self:fromModData(md)
    end

    self:calculateBatteryStats(isoObject:getContainer())
    self:autoConnectBackup()
    self:loadGenerator()
    self:updateDrain()
    self:updateSprite()
    self:saveData(true)
end

---Called for existing objects (loaded from disk). Syncs state to the IsoObject.
---@param isoObject IsoObject
function PowerBank:stateToIsoObject(isoObject)
    self:toModData(isoObject:getModData())
    isoObject:transmitModData()
    -- ❌ RETIRE 2026-08-04 : bloc de migration des vieilles saves ISA, MORT depuis toujours.
    -- La chaine `setGeneratorFullType` n'existe NULLE PART dans projectzomboid.jar 42.20 (scan
    -- complet du pool de constantes) ⇒ la garde `if isoObject.setGeneratorFullType` etait
    -- perpetuellement fausse et l'appel n'a jamais eu lieu.
    -- ✅ Et il n'a pas manque : le moteur resout le type par `IsoGenerator.getGeneratorItemType()`,
    -- une table sprite -> item construite depuis les items tagues `Generator` ayant un
    -- `WorldObjectSprite`. `Items.txt` donne bien les deux a la PowerBank, donc le moteur rend
    -- correctement `PSR.PowerBank` sans notre aide.
    self:loadGenerator()
    self:updateSprite()
end

function PowerBank:fromModData(modData)
    for _, key in ipairs(self.luaSystem.savedObjectModData) do
        self[key] = modData[key]
    end
end

function PowerBank:toModData(modData)
    for _, key in ipairs(self.luaSystem.savedObjectModData) do
        modData[key] = self[key]
    end
    modData.generatorFullType = "PSR.PowerBank"
end

---Sync power bank state to the IsoObject's mod data and optionally transmit to clients.
function PowerBank:saveData(transmit)
    local isoObject = self:getIsoObject()
    if not isoObject then return end
    self:toModData(isoObject:getModData())
    if transmit then
        isoObject:transmitModData()
    end
end

function PowerBank:shouldDrain(isoPb)
    if self.switchchanged then
        self.switchchanged = nil
    elseif not self.on then
        return false
    end
    if self.conGenerator and self.conGenerator.ison then return false end

    local world = getWorld()
    if world:isHydroPowerOn() then
        if isoPb then
            local pbSq = isoPb:getSquare()
            if pbSq and not pbSq:isOutside() then return false end
        else
            if world:getMetaGrid():getRoomAt(self.x, self.y, self.z) then return false end
        end
    end
    return true
end

PowerBank.fuelToSolarRate = 800

-- Vanilla PZ fuel consumption rates (L/h) per device type — sourced from PZ internals
local PSR_DRAIN_RATES = {
    light         = 0.002,  -- IsoLightSwitch (standalone lamp): directly controllable
    switch        = 0.002,  -- IsoLightSwitch wall switch: controls ceiling lights via GroupName system
    roomlight     = 0.002,  -- IsoLight / sprite fixtures: informational only
    radio         = 0.01,
    tv            = 0.03,
    stove         = 0.045,
    fridge        = 0.08,
    freezer       = 0.08,
    fridgeFreezer = 0.13,
    coldunit      = 0.15,   -- PFR Cold Unit (industrial cooling, slightly more demanding than a fridge-freezer combo)
    washer        = 0.09,
    dryer         = 0.09,
    microwave     = 0.065,
    appliance     = 0.04,
}

-- Sandbox-adjustable power consumption multiplier (percent, default 100 = vanilla rates).
-- Falls back to 100 on saves created before this option existed (nil SandboxVars key).
local function psrDrainRate(dtype)
    local rate = PSR_DRAIN_RATES[dtype]
    if not rate then return nil end
    local mult = (SandboxVars.PSR and SandboxVars.PSR.consumptionMultiplier) or 100
    return rate * (mult / 100)
end

-- Raw footprint bbox (x1,y1,x2,y2) of a BuildingDef.
local function defBbox(def)
    return def:getX(), def:getY(), def:getX() + def:getW() - 1, def:getY() + def:getH() - 1
end

local function rangesOverlap(a1, a2, b1, b2)
    return a1 <= b2 and b1 <= a2
end

-- Is `cand` part of the SAME vertical structure as the anchor building?
-- PZ models a house-with-basement as SEPARATE building defs (surface lvl[0..N] + a distinct
-- [BASEMENT] def lvl[-M..-1], nested/overlapping footprint). A building belongs to the anchor's
-- structure iff its footprint OVERLAPS the anchor's AND it is vertically STACKED — either flagged
-- isBasement(), or its z-range is DISJOINT from the anchor's (a different floor set, not a
-- same-level neighbour). Footprint overlap (raw bbox) excludes adjacent houses; the z-disjoint /
-- basement test excludes same-level neighbours → preserves the anti-grief scoping (we never bill
-- another player's building, cf. getDrainVanilla).
local function isAssociatedBuilding(cand, anchorDef, ux1, uy1, ux2, uy2)
    local cdef = cand:getDef()
    if not cdef then return false end
    local cx1, cy1, cx2, cy2 = defBbox(cdef)
    if not rangesOverlap(ux1, ux2, cx1, cx2) then return false end
    if not rangesOverlap(uy1, uy2, cy1, cy2) then return false end
    if cdef.isBasement and cdef:isBasement() then return true end
    if anchorDef.getMinLevel and anchorDef.getMaxLevel and cdef.getMinLevel and cdef.getMaxLevel then
        local az1, az2 = anchorDef:getMinLevel(), anchorDef:getMaxLevel()
        local cz1, cz2 = cdef:getMinLevel(), cdef:getMaxLevel()
        if not rangesOverlap(az1, az2, cz1, cz2) then return true end
    end
    return false
end

-- Adds/removes generator positions for all building squares across all floors.
-- Uses world coordinates (tx, ty, tz) matching GPB v2's working implementation.
local function psrApplyBuildingChunks(building, selfZ, remove)
    local def = building:getDef()
    if not def then return end
    local extX  = def:getX() - 2
    local extY  = def:getY() - 2
    local extX2 = def:getX() + def:getW() + 1
    local extY2 = def:getY() + def:getH() + 1
    local minZ  = math.max(0, selfZ - 3)
    local maxZ  = selfZ + 16
    local cell  = getCell()
    for wx = extX, extX2 do
        for wy = extY, extY2 do
            for wz = minZ, maxZ do
                local sq = cell:getGridSquare(wx, wy, wz)
                if sq then
                    local chunk = sq:getChunk()
                    if chunk then
                        if remove then
                            chunk:removeGeneratorPos(wx, wy, wz)
                        else
                            chunk:addGeneratorPos(wx, wy, wz)
                        end
                        if sq.RecalcAllWithNeighbours then
                            sq:RecalcAllWithNeighbours(false)
                        end
                        -- ❌ RETIRE 2026-08-04 : `chunk:recalcHashCodeObjects()` visait le MAUVAIS
                        -- receveur — c'est une methode d'`IsoGridSquare`, pas d'`IsoChunk` (qui
                        -- n'a que `recalcNeighboursNow()` / `hashCode()`). La garde etait donc
                        -- perpetuellement fausse et l'appel n'a jamais eu lieu.
                        -- ⚖️ On le SUPPRIME au lieu de le « reparer » sur `sq` : le corriger le
                        -- ferait COMMENCER a s'executer — une operation de chunk appelee une fois
                        -- PAR CASE, donc jusqu'a 64 fois redondantes par chunk — a l'interieur de
                        -- la fonction que la mesure du 2026-08-04 place parmi les plus chaudes
                        -- du mod (13,8 ms de moyenne par appel). Reparer ici couterait, pas
                        -- gagnerait.
                    end
                end
            end
        end
    end
end

-- Cache « nom de sprite -> type d'appareil » pour la section heuristique de `psrGetDeviceType`.
-- Borne par le nombre de sprites distincts du jeu (quelques milliers au pire), remplie
-- paresseusement. `false` = calcule, aucun type ; `nil` = pas encore calcule.
local psrSpriteTypeCache = {}

local function psrGetDeviceType(obj)
    -- "light"     = IsoLightSwitch without CustomName="Switch": standalone lamps (floor, exterior,
    --               wall mount) that respond directly to setActivated → Disable/Enable available.
    -- "switch"    = IsoLightSwitch with CustomName="Switch": wall-mounted switch buttons that
    --               control ceiling lights via PZ's GroupName tile system → controllable,
    --               toggling the switch (client-side obj:toggle()) turns linked ceiling lights on/off.
    if instanceof(obj, "IsoLightSwitch") then
        -- Wall switches: CustomName="Switch" is a SQUARE property (not sprite property).
        -- Use square:getProperties():get("CustomName") — the same API as PZ's debug tile panel.
        -- (sprite:getProperties():Val() returns nil in B42 — wrong accessor.)
        local sq = obj:getSquare()
        if sq and sq.getProperties then
            local sqProps = sq:getProperties()
            if sqProps and sqProps.get then
                local customName = sqProps:get("CustomName")
                if customName == "Switch" then
                    return "switch"  -- wall switch → controls ceiling lights
                end
            end
        end
        return "light"  -- standalone lamp (floor, exterior, wall mount)
    end
    -- PFR Cold Unit (cross-mod support, soft check — no runtime dependency).
    -- Detected by modData tag set by PFR.PFRMoveableProps at placement time.
    if obj.hasModData and obj:hasModData() and obj:getModData().PFR_isColdUnit == true then
        return "coldunit"
    end
    -- ❌ RETIRE 2026-08-04 : `instanceof(obj, "IsoLight")` etait TOUJOURS FAUX. La classe
    -- `IsoLight` N'EXISTE PAS en 42.20 (verifie dans projectzomboid.jar : seules `IsoRoomLight`
    -- et `IsoLightSource` existent), et `instanceof` sur un nom inconnu rend `false` EN SILENCE,
    -- sans erreur. Les lumieres de piece ne sont donc detectees que par l'heuristique de nom de
    -- sprite plus bas — ce qui etait deja le cas en pratique, ce test n'ayant jamais rien fait.
    -- ⚠️ `IsoRoomLight` ne conviendrait pas non plus : ce n'est pas un `IsoObject`, il n'apparait
    -- pas dans `sq:getObjects()`, et son etat vit dans des CHAMPS publics que Lua n'expose pas.
    if instanceof(obj, "IsoTelevision")  then return "tv"    end
    if instanceof(obj, "IsoRadio")       then return "radio" end
    if instanceof(obj, "IsoStove")       then return "stove" end
    if instanceof(obj, "IsoClothingWasher") or instanceof(obj, "IsoStackedWasherDryer")    then return "washer" end
    if instanceof(obj, "IsoClothingDryer")  or instanceof(obj, "IsoCombinationWasherDryer") then return "dryer"  end
    if obj.getContainerByType then
        -- Include the "_off" variants so a fridge/freezer switched off (by the PSR computer or by
        -- the Fridges Off! mod) is still detected → stays listed and re-enableable.
        local hasFridge  = obj:getContainerByType("fridge")  ~= nil or obj:getContainerByType("fridge_off")  ~= nil
        local hasFreezer = obj:getContainerByType("freezer") ~= nil or obj:getContainerByType("freezer_off") ~= nil
        local hasWasher  = obj:getContainerByType("clothingwasher") ~= nil
        local hasDryer   = obj:getContainerByType("clothingdryer")  ~= nil
        if hasFridge and hasFreezer then return "fridgeFreezer" end
        if hasFridge  then return "fridge"  end
        if hasFreezer then return "freezer" end
        if hasWasher  then return "washer"  end
        if hasDryer   then return "dryer"   end
    end
    -- 🔴 CHEMIN CHAUD MEMOISE (audit 2026-08-04).
    -- Ce bloc est le cas PAR DEFAUT : on ne l'atteint que si tous les `instanceof` et les tests de
    -- conteneur au-dessus ont echoue, c'est-a-dire pour la quasi-totalite des objets du monde
    -- (murs, sols, meubles, decor). Il faisait un `string.lower` — donc une ALLOCATION — plus
    -- jusqu'a 10 `string.find` PAR OBJET, a la frequence des scans de batiment. Ordre de grandeur
    -- sur un mall : ~80 000 allocations et jusqu'a 800 000 `find` par scan, en pure pression GC.
    -- Le resultat ne depend QUE du nom de sprite ⇒ memoisable sans changer un seul comportement.
    -- ⚠️ On ne memoise QUE cette section : les branches en amont dependent de l'objet (classe Java,
    -- conteneurs, propriete de case) et deux objets partageant un sprite peuvent y differer.
    local sprite = obj:getSprite()
    local sname  = sprite and sprite:getName()
    if sname then
        local cached = psrSpriteTypeCache[sname]
        if cached == nil then          -- nil = jamais calcule ; false = calcule, aucun type
            cached = false
            local n = string.lower(sname)
            -- Ordre STRICTEMENT identique a l'ancienne cascade de `return`.
            if string.find(n, "microwave") then cached = "microwave"
            elseif string.find(n, "fridge") and string.find(n, "freezer") then cached = "fridgeFreezer"
            elseif string.find(n, "fridge")  then cached = "fridge"
            elseif string.find(n, "freezer") then cached = "freezer"
            elseif string.find(n, "stove") or string.find(n, "oven") then cached = "stove"
            -- NOTE: no sprite-name heuristic for washer/dryer. A real electric washer/dryer is always
            -- caught above by instanceof (IsoClothingWasher/Dryer/StackedWasherDryer/CombinationWasherDryer)
            -- or by getContainerByType("clothingwasher"/"clothingdryer"). The sprite-name fallback only ever
            -- produced FALSE POSITIVES: passive B42 crafting stations whose sprites contain "drying"/"washing"
            -- (e.g. the Large Plant/Leather Drying Rack — entity DryingRackLarge, sprite crafted_skins_drying_*)
            -- were typed "dryer" and billed a phantom electric drain (~288 Ah/day each). They are not powered.
            -- Sprite-based room lighting → "roomlight" (informational, not controllable)
            elseif string.find(n, "lamp") or string.find(n, "lighting") or string.find(n, "floorlamp") then cached = "roomlight"
            elseif not string.find(n, "switch") and (
                string.find(n, "lights_") or string.find(n, "fluorescent") or
                string.find(n, "ceiling_light") or string.find(n, "wall_light")) then cached = "roomlight"
            end
            psrSpriteTypeCache[sname] = cached
        end
        if cached then return cached end
    end
    if obj.getDeviceData then
        local ok, dd = pcall(function() return obj:getDeviceData() end)
        if ok and dd then return "appliance" end
    end
    return nil
end

local function psrGetFuelRate(obj)
    local dtype = psrGetDeviceType(obj)
    return dtype and psrDrainRate(dtype)
end

local function psrIsLight(obj) return psrGetDeviceType(obj) == "light" end

-- Returns true if the device is currently on (draws power right now).
-- Stoves, washer/dryer: only when actively in use (isActivated() == true).
-- Fridge / freezer: ON unless switched to a "_off" container type (toggleable since v1.44 via
-- container:setType — there is no setActivated API for fridges, the type swap is the clean way).
-- Microwave / appliance: always on when present (no clean toggle API).
local function psrIsDeviceOn(obj)
    -- PFR Cold Unit toggle state lives in modData (PFR_on).
    if obj.hasModData and obj:hasModData() and obj:getModData().PFR_isColdUnit == true then
        return obj:getModData().PFR_on == true
    end
    if instanceof(obj, "IsoLightSwitch") then return obj:isActivated() end
    -- ❌ RETIRE 2026-08-04 : `instanceof(obj, "IsoLight")` etait TOUJOURS FAUX (classe inexistante
    -- en 42.20, verifie dans le jar). L'intention restait juste — une lumiere de piece est allumee
    -- des que le batiment est alimente et son etat individuel n'est ni lisible ni pilotable depuis
    -- Lua — mais ce test ne l'a jamais mise en oeuvre. Les objets typés "roomlight" par
    -- l'heuristique de sprite retombent sur le traitement par defaut plus bas.
    if instanceof(obj, "IsoTelevision") or instanceof(obj, "IsoRadio") then
        local ok, dd = pcall(function() return obj:getDeviceData() end)
        return ok and dd and dd:getIsTurnedOn() or false
    end
    if instanceof(obj, "IsoClothingWasher") or instanceof(obj, "IsoStackedWasherDryer") or
       instanceof(obj, "IsoClothingDryer")  or instanceof(obj, "IsoCombinationWasherDryer") then
        return obj:isActivated()
    end
    -- Vanilla coherence : IsoStove uses Activated() (capital A, legacy API specific to stoves),
    -- NOT isActivated() — confirmed via vanilla ISInventoryPaneContextMenu.lua:4493.
    -- Returns true only while actively cooking (timer running). Idle stoves used to be counted
    -- as always-on — fixed in v1.34. Defensive guard if method ever disappears in a future build.
    if instanceof(obj, "IsoStove") then
        if obj.Activated then return obj:Activated() end
        return true
    end
    -- Fridge / freezer: OFF when their container was switched to the "_off" type (PSR computer
    -- toggle, interoperable with the Fridges Off! mod). When off, the container no longer cools
    -- and is excluded from the drain (getDrainBuilding only counts devices where active == true).
    if obj.getContainerByType then
        local coolingOff = (obj:getContainerByType("fridge_off") ~= nil) or (obj:getContainerByType("freezer_off") ~= nil)
        local coolingOn  = (obj:getContainerByType("fridge")     ~= nil) or (obj:getContainerByType("freezer")     ~= nil)
        if coolingOff and not coolingOn then return false end
    end
    return true  -- fridge, freezer, microwave, appliance: always on when present
end

-- Physically turns on or off a specific device type on a given square.
-- Only acts on toggleable types (light, tv, radio, washer, dryer).
-- Sets device state server-side for drain tracking only.
-- Visual sync to clients is handled by applyDeviceToggle (sendServerCommand → client APIs).
local function psrSetDeviceState(sq, dtype, on)
    local objs = sq:getObjects()
    if not objs then return end
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj and psrGetDeviceType(obj) == dtype then
            if dtype == "light" or dtype == "switch" then
                if instanceof(obj, "IsoLightSwitch") then
                    obj:setActivated(on)
                end
            elseif dtype == "tv" or dtype == "radio" then
                -- Mirror the fridge/freezer pattern below: refresh the object's cached power flag
                -- BEFORE flipping IsTurnedOn, otherwise vanilla's own update tick sees a stale
                -- "not powered" state and reverts IsTurnedOn back to false a moment later
                -- (reported symptom: "turns on then immediately switches back to disabled").
                if obj.checkHaveElectricity then obj:checkHaveElectricity() end
                if obj.getDeviceData then
                    local ok, dd = pcall(function() return obj:getDeviceData() end)
                    if ok and dd then dd:setIsTurnedOn(on) end
                end
            elseif dtype == "washer" or dtype == "dryer" then
                -- A device can be typed washer/dryer via getContainerByType or sprite name
                -- (PowerBankObject_Server:psrGetDeviceType), i.e. a plain IsoObject with no
                -- setActivated method → "Object tried to call nil". Defensive guard, mirrors
                -- the IsoStove Activated() guard above and the instanceof checks in psrIsDeviceOn.
                if obj.setActivated then obj:setActivated(on) end
            elseif dtype == "coldunit" then
                -- PFR Cold Unit: server-side state lives in modData. Visual sync to clients
                -- is handled by applyDeviceToggle (client-side) which also calls transmitModData.
                local md = obj:getModData()
                md.PFR_on = on
                if obj.transmitModData then obj:transmitModData() end
            elseif dtype == "fridge" or dtype == "freezer" or dtype == "fridgeFreezer" then
                -- Toggle a fridge/freezer by swapping the container type fridge<->fridge_off
                -- (same mechanism as the Fridges Off! mod → interoperable). An "_off" container is
                -- not recognised by the engine as a cooling unit: food no longer chills and PSR
                -- stops draining it (psrIsDeviceOn → false → excluded from getDrainBuilding).
                -- Visual sync to remote clients is handled by applyDeviceToggle (client-side setType).
                local fc = obj:getContainerByType(on and "fridge_off" or "fridge")
                if fc then fc:setType(on and "fridge" or "fridge_off") end
                local zc = obj:getContainerByType(on and "freezer_off" or "freezer")
                if zc then zc:setType(on and "freezer" or "freezer_off") end
                if obj.checkHaveElectricity then obj:checkHaveElectricity() end
            end
            -- stove, microwave, appliance: not toggleable (no clean API / always-on by design)
        end
    end
end

-- Scan one square: list its devices into deviceList (full=all appliance types, else lights only) and
-- add powered+active ones to totalRate. Shared by the building scan and the manual-structure scan.
local function scanCellDevices(sq, full, totalRate, deviceList)
    local objs = sq:getObjects()
    if not objs then return totalRate end
    local powered = sq:haveElectricity()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj then
            local dtype = full and psrGetDeviceType(obj) or (psrIsLight(obj) and "light")
            if dtype then
                local rate   = psrDrainRate(dtype) or 0   -- garde : un dtype sans taux ne plante pas totalRate
                local active = psrIsDeviceOn(obj)
                -- List always (computer UI); bill only if actually powered.
                if active and powered then totalRate = totalRate + rate end
                deviceList[#deviceList + 1] = { x = x, y = y, z = z, dtype = dtype, rate = rate, active = active }
            end
        end
    end
    return totalRate
end

-- 🕳️ PONT VERS LES SOUS-SOLS CREUSES -- helper partage par LES DEUX chemins de drain.
-- ⚠️ 1er jet insuffisant : je ne l'avais branche que sur `getDrainVanilla`, or ce
-- chemin ne sert que si la bank est HORS bâtiment. Une bank posee dans une maison
-- passe par `getDrainBuilding` -- et la, `minZ` part de l'etage de la bank et ne
-- descend que si un BATIMENT EMPILE est detecte. Un bunker creuse n'etant pas un
-- batiment, `z=-1` n'etait jamais balaye. Constate en jeu : « je ne vois que les
-- 5 lampes en 0 et pas les autres en -1 ».
-- La regle : le pont doit vivre la ou vit le SCAN, pas la ou vit un des deux cas.
local PSR_DUG_TAG = "PUR_bunker"

-- On descend EXACTEMENT aussi loin que le moteur alimente : ni plus (on facturerait
-- des appareils morts), ni moins (ils resteraient gratuits). Valeur vanilla lue, pas
-- supposee -- `GeneratorVerticalPowerRange`, defaut 3 (media/lua/shared/Sandbox/).
local function psrVerticalRange()
    local v = SandboxVars and SandboxVars.GeneratorVerticalPowerRange
    if type(v) ~= "number" or v < 0 then return 3 end
    return v
end

-- Rayon horizontal du generateur, LU dans le vanilla (`GeneratorTileRange`, defaut 20)
-- plutot que code en dur : le joueur peut l'augmenter en sandbox, et la facturation
-- doit suivre la couverture, pas une constante.
local function psrGenTileRange()
    local v = SandboxVars and SandboxVars.GeneratorTileRange
    if type(v) ~= "number" or v <= 0 then return 20 end
    return v
end

-- Balaie les colonnes CREUSEES sous le RAYON DU GENERATEUR, tant que la case porte
-- le tag. Le cout est proportionnel au bunker, pas a la boite : une colonne ordinaire
-- coute un `getSquare` + un test de modData, puis s'arrete (`break`).
--
-- ⚠️ LA BOITE EST CELLE DU GENERATEUR, PAS CELLE DU BATIMENT (corrige 2026-07-28
-- apres test). J'utilisais l'emprise du batiment dans le chemin `getDrainBuilding` :
-- une lampe creusee sous la maison etait vue, une autre plus loin dans la galerie ne
-- l'etait pas. C'est faux par nature -- une galerie s'etend ou le joueur creuse, et
-- ce qui l'alimente n'est pas le batiment mais le rayon 3D du generateur. La regle
-- reste la meme : on facture EXACTEMENT ce que le moteur alimente.
-- (Portee anti-grief : le tag est lui-meme le perimetre -- ce sont les cases du
-- chantier du joueur. PUR est SP-only ; a revoir si un jour il passe en MP.)
-- Le pont ne peut RIEN trouver si le mod de bunker n'est pas charge : sans lui, aucune case du
-- monde ne porte le tag. On teste sa presence UNE seule fois (resultat memorise) au lieu de payer
-- (2r+1)^2 lectures de case a CHAQUE evaluation de drain -- soit ~1681 par appel, x3 par clic dans
-- le Device Management, chez des joueurs qui n'ont meme pas le mod. Verification SOUPLE (liste des
-- mods actifs) : aucune dependance runtime, aucun require.
-- Repli volontaire : si l'API n'existe pas dans ce contexte, on considere le mod ABSENT -- le pont
-- est de toute facon inerte la ou le tag n'est pas replique (il est pose cote client).
local PSR_BUNKER_MOD_ID  = "PUR"
local psrBunkerModCached = nil
local function psrBunkerModPresent()
    if psrBunkerModCached ~= nil then return psrBunkerModCached end
    psrBunkerModCached = false
    if getActivatedMods then
        local mods = getActivatedMods()
        if mods and mods.contains and mods:contains(PSR_BUNKER_MOD_ID) then
            psrBunkerModCached = true
        end
    end
    return psrBunkerModCached
end

local function psrScanDugBelow(cx, cy, cz, totalRate, deviceList)
    if not psrBunkerModPresent() then return totalRate end
    local depth = psrVerticalRange()
    if depth <= 0 then return totalRate end
    local r = psrGenTileRange()
    for x = cx - r, cx + r do
        for y = cy - r, cy + r do
            for dz = 1, depth do
                local sq = getSquare(x, y, cz - dz)
                -- `getModData()` CREE la table si elle n'existe pas : l'appeler sur des centaines de
                -- cases vierges alloue pour rien et les marque comme portant des donnees. On teste
                -- donc `hasModData()` d'abord (idiome vanilla). Repli si la methode n'existe pas sur
                -- IsoGridSquare : ancien comportement, jamais de faux negatif.
                local md = nil
                if sq then
                    if sq.hasModData then
                        if sq:hasModData() then md = sq:getModData() end
                    elseif sq.getModData then
                        md = sq:getModData()
                    end
                end
                if not (md and md[PSR_DUG_TAG]) then break end
                totalRate = scanCellDevices(sq, true, totalRate, deviceList)
            end
        end
    end
    return totalRate
end

-- Building-aware drain over the FULL vertical structure.
-- PZ models a multi-level building as several stacked BuildingDefs (surface lvl[0..N] + a distinct
-- [BASEMENT] def lvl[-M..-1]). Anchoring the scan on the single building the bank sits in misses the
-- basement (bank upstairs) or the upper floors (bank in the basement) — appliances there were powered
-- by the generator radius but never billed (player report 2026-06-29, confirmed in-game via DEV diag).
-- We collect every building of the same physical structure (footprint-overlapping + vertically
-- stacked) and scan the whole column. Footprint-scoped → never bills a neighbour's building.
-- deviceList is ALSO the computer management list, so it must list every device of the structure
-- regardless of live power (or the computer UI would go blank when the bank is off/empty). Only the
-- billed drain (totalRate) is gated on haveElectricity → a floor the bank does not actually reach is
-- listed but not billed. Returns totalDrain (Ah), deviceList ({ x,y,z,dtype,rate,active }).
function PowerBank:getDrainBuilding(square, building)
    local def = building:getDef()
    if not def then return 0, {} end

    -- 1) Collect the associated buildings (bank's building + stacked basements/surface) and the union
    --    footprint. The vertical PROBE window is bounded by the buildings' real levels (not a fixed
    --    sweep) — we only need to hit ONE cell of a stacked building to detect it; its own levels then
    --    drive the full scan range (step 2). Iterate until the bbox/probe stop growing (a bank in a
    --    small basement discovers the larger surface building above and must scan its full footprint).
    local function lvlOf(d) if d.getMinLevel and d.getMaxLevel then return d:getMinLevel(), d:getMaxLevel() end return self.z, self.z end
    local assoc = { [building] = true }
    local ux1, uy1, ux2, uy2 = defBbox(def)
    local aMin, aMax = lvlOf(def)
    local probeZ1, probeZ2 = aMin - 4, aMax + 2   -- a few levels below (basement) / one above (surface parent)
    -- Track the ACTUAL z where associated cells are seen. The scan range must NOT rely solely on
    -- getMinLevel() (a [BASEMENT] def can report its floor as ≥0 depending on tileset → the basement
    -- would be detected but its z left out of the scan → silently unbilled). The physically-probed z
    -- of a detected basement/floor is the robust source of truth.
    local foundMinZ, foundMaxZ = self.z, self.z
    for _ = 1, 3 do
        local grew = false
        for z = probeZ1, probeZ2 do
            for x = ux1, ux2 do
                for y = uy1, uy2 do
                    local sq = getSquare(x, y, z)
                    local b = sq and sq:getBuilding()
                    if b then
                        if not assoc[b] and isAssociatedBuilding(b, def, ux1, uy1, ux2, uy2) then
                            assoc[b] = true
                            local bdef = b:getDef()
                            local bx1, by1, bx2, by2 = defBbox(bdef)
                            if bx1 < ux1 then ux1 = bx1; grew = true end
                            if by1 < uy1 then uy1 = by1; grew = true end
                            if bx2 > ux2 then ux2 = bx2; grew = true end
                            if by2 > uy2 then uy2 = by2; grew = true end
                            local bz1, bz2 = lvlOf(bdef)
                            if bz1 - 4 < probeZ1 then probeZ1 = bz1 - 4; grew = true end
                            if bz2 + 2 > probeZ2 then probeZ2 = bz2 + 2; grew = true end
                        end
                        if assoc[b] then
                            if z < foundMinZ then foundMinZ = z end
                            if z > foundMaxZ then foundMaxZ = z end
                        end
                    end
                end
            end
        end
        if not grew then break end
    end

    -- 2) z-range = union of the ACTUAL detected z (robust, independent of getMinLevel) AND the
    --    associated buildings' declared levels (extends to a tall tower's upper floors). Absolute clamp.
    local minZ, maxZ = foundMinZ, foundMaxZ
    for b in pairs(assoc) do
        local bdef = b:getDef()
        if bdef then
            local z1, z2 = lvlOf(bdef)
            if z1 < minZ then minZ = z1 end
            if z2 > maxZ then maxZ = z2 end
        end
    end
    if minZ < self.z - 16 then minZ = self.z - 16 end
    if maxZ > self.z + 48 then maxZ = self.z + 48 end

    -- 3) Scan the structure column (union footprint +2 for exterior wall lights). Single pass over
    --    a non-overlapping box → no per-cell dedup needed. List every device; bill only powered ones.
    local ex1, ey1, ex2, ey2 = ux1 - 2, uy1 - 2, ux2 + 2, uy2 + 2

    -- Manually-connected player-built extensions (opt-in) : resolve their EXACT cells (bounded, ≤400 per
    -- structure) and scan them SEPARATELY below with a full device scan. We do NOT extend the main box
    -- (that would sweep a large empty rectangle every drain tick) — the cells are scanned directly, and
    -- skipped in the main loop to avoid double-count. Closes the "powered but not billed" gap for an
    -- extension attached to a vanilla building (already powered by the vanilla generator radius).
    local manualSet, manualCells
    if self.PSR_manualStructures and #self.PSR_manualStructures > 0 then
        manualSet, manualCells = {}, {}
        for _, anchor in ipairs(self.PSR_manualStructures) do
            for _, s in ipairs(PSR.Structures.resolveSquares(anchor.x, anchor.y, anchor.z)) do
                local k = s.x .. "_" .. s.y .. "_" .. s.z
                if not manualSet[k] then
                    manualSet[k] = true
                    manualCells[#manualCells + 1] = s
                end
            end
        end
    end

    local totalRate  = 0
    local deviceList = {}
    for z = minZ, maxZ do
        for x = ex1, ex2 do
            for y = ey1, ey2 do
                local sq = getSquare(x, y, z)
                if sq then
                    local sqBld = sq:getBuilding()
                    local interior = assoc[sqBld] == true
                    -- Manual cells are scanned separately (full) below → skip here (no double-count).
                    local inManual = manualSet and manualSet[x .. "_" .. y .. "_" .. z]
                    if not inManual and (interior or sqBld == nil) then
                        totalRate = scanCellDevices(sq, interior, totalRate, deviceList)
                    end
                end
            end
        end
    end

    -- 🕳️ Sous-sols CREUSES sous l'emprise du batiment. Ils ne sont pas des batiments,
    -- donc ils n'ont pas fait bouger `minZ` : sans ce passage, leurs appareils sont
    -- alimentes par le rayon 3D du generateur mais jamais factures ni listes.
    totalRate = psrScanDugBelow(self.x, self.y, self.z, totalRate, deviceList)

    -- Manually-connected extensions : full device scan on their exact cells only (bounded, cheap).
    if manualCells then
        for _, s in ipairs(manualCells) do
            local msq = getSquare(s.x, s.y, s.z)
            if msq then totalRate = scanCellDevices(msq, true, totalRate, deviceList) end
        end
    end

    return totalRate * self.fuelToSolarRate, deviceList
end

-- Vanilla generator coverage radius (B42 default, ~20 tiles). The Power Bank IS an active
-- IsoGenerator, so OUTSIDE a vanilla building (square:getBuilding() == nil, e.g. a player-built
-- base) the engine powers every appliance within this radius on the bank's floor. Before this fix
-- getDrainVanilla returned 0 → those appliances ran for free, no battery drain (player report:
-- "player built buildings do not drain power from batteries, but appliances work after shutdown").
-- We now mirror the coverage: scan the same radius and bill the active devices, exactly like
-- getDrainBuilding does per room. Same floor only (dominant single-level player-built case);
-- multi-floor player-built drain is a documented limitation (docs/RISKS.md). Server-side & MP-safe:
-- identical path to the building drain, result stored in self.drain + transmitted via modData,
-- no new network state. Runs at most EveryTenMinutes/EveryHours, so the box scan cost is fine.
local PSR_VANILLA_GEN_RANGE = 20

-- 🕳️ (note d'origine) PONT VERS LES SOUS-SOLS CREUSES (2026-07-28).
-- Symptome rapporte : dans un bunker creuse, les lampes S'ALLUMENT mais n'apparaissent
-- pas dans le Solar Computer -- donc elles consomment du courant GRATUIT. C'est
-- exactement la faute corrigee en v1.47 (« le drain doit refleter la couverture »),
-- sur un autre terrain.
-- Pourquoi elles s'allument : la bank EST un IsoGenerator, et le rayon natif du
-- moteur est en 3D (`GeneratorTileRange` en largeur, `GeneratorVerticalPowerRange`
-- en profondeur). Pourquoi elles n'etaient pas vues : ce scan ne regardait QUE
-- l'etage de la bank (`cz` fixe).
-- Pourquoi un TAG et pas `getBuilding()` : une case creusee n'appartient a aucun
-- BuildingDef -- c'est la raison d'etre du tag. Verification SOUPLE (`modData`) :
-- aucune dependance a l'autre mod, et sans lui aucune case n'est taguee, donc
-- comportement inchange.
function PowerBank:getDrainVanilla(square)
    local cx, cy, cz = square:getX(), square:getY(), square:getZ()
    local totalRate  = 0
    local deviceList = {}

    -- Sous-sols creuses sous le rayon du generateur.
    totalRate = psrScanDugBelow(cx, cy, cz, totalRate, deviceList)

    -- 🔴 STRUCTURES MANUELLES — AJOUTEES ICI (audit 2026-08-04).
    -- `getDrainBuilding` les lisait, PAS `getDrainVanilla` — or c'est ce dernier qui s'execute des
    -- que la bank n'est pas dans un batiment vanilla, c'est-a-dire dans TOUTE base entierement
    -- player-built (le cas dominant en fin de partie). Le joueur cliquait « Connect structure »,
    -- l'ancre etait taguee, le halo confirmait, le menu basculait sur « Disconnect »… et le drain
    -- ne bougeait pas d'un ampere. *Toute la boucle de retour disait « c'est fait », le compteur
    -- disait le contraire* — indetectable sans compter les Ah a la main.
    -- Meme construction que dans getDrainBuilding : ensemble dedoublonne, cases SAUTEES dans la
    -- boucle principale, puis scannees a part. On ne prend pas de risque de double facturation.
    local manualSet, manualCells
    if self.PSR_manualStructures and #self.PSR_manualStructures > 0 then
        manualSet, manualCells = {}, {}
        for _, anchor in ipairs(self.PSR_manualStructures) do
            for _, s in ipairs(PSR.Structures.resolveSquares(anchor.x, anchor.y, anchor.z)) do
                local k = s.x .. "_" .. s.y .. "_" .. s.z
                if not manualSet[k] then
                    manualSet[k] = true
                    manualCells[#manualCells + 1] = s
                end
            end
        end
    end

    for x = cx - PSR_VANILLA_GEN_RANGE, cx + PSR_VANILLA_GEN_RANGE do
        for y = cy - PSR_VANILLA_GEN_RANGE, cy + PSR_VANILLA_GEN_RANGE do
            local sq = getSquare(x, y, cz)
            -- Only bill/manage squares OUTSIDE any vanilla building (getBuilding()==nil), i.e. the
            -- player-built base + open ground this bank actually powers. Squares belonging to a
            -- vanilla building are the responsibility of a bank inside that building (getDrainBuilding,
            -- which likewise ignores other buildings) — NOT scanned here. Without this filter the
            -- radius would bill, AND expose to the Computer (remote toggle), the appliances of a
            -- neighbour's vanilla house within 20 tiles (MP grief: switching off someone's fridge).
            -- Les cases des structures manuelles sont scannees separement plus bas (scan complet)
            -- -> on les saute ici, sinon elles seraient facturees deux fois.
            local inManual = manualSet and manualSet[x .. "_" .. y .. "_" .. cz]
            if sq and not inManual and sq:getBuilding() == nil then
                local objs = sq:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local obj = objs:get(i)
                        if obj then
                            local dtype = psrGetDeviceType(obj)
                            if dtype then
                                -- `or 0` : le chemin frere `scanCellDevices` a cette garde et son
                                -- commentaire ; celui-ci ne l'avait pas. Aujourd'hui les 14 dtype
                                -- ont tous un taux, donc c'est latent — mais l'ajout d'un type sans
                                -- taux (ce qui est deja arrive avec `coldunit`) planterait
                                -- `totalRate + nil` cote serveur, et seulement sur ce chemin-la.
                                local rate   = psrDrainRate(dtype) or 0
                                local active = psrIsDeviceOn(obj)
                                if active then totalRate = totalRate + rate end
                                deviceList[#deviceList + 1] = { x=x, y=y, z=cz, dtype=dtype, rate=rate, active=active }
                            end
                        end
                    end
                end
            end
        end
    end

    -- Structures manuelles : scan complet sur leurs cases exactes uniquement (borne, peu couteux).
    if manualCells then
        for _, s in ipairs(manualCells) do
            local msq = getSquare(s.x, s.y, s.z)
            if msq then totalRate = scanCellDevices(msq, true, totalRate, deviceList) end
        end
    end

    return totalRate * self.fuelToSolarRate, deviceList
end

-- Physically turns on/off ALL devices of a given type in the bank's building.
-- ⚡ PERF 2026-08-04 : `coords` est un paramètre OPTIONNEL — quand l'appelant vient DÉJÀ de
-- résoudre les cases de ce `dtype` (c'est le cas de `Commands.controlDeviceGroup`, qui les
-- collecte juste avant pour les envoyer aux clients), on les réutilise au lieu de relancer un
-- balayage complet de la structure. Un clic sur « tout éteindre » déclenchait ainsi DEUX scans
-- identiques à quelques lignes d'intervalle. Sans `coords`, comportement strictement inchangé.
-- 📌 Ce n'est pas un cache : rien n'est conservé entre deux appels, donc aucune péremption
--    possible — on arrête juste de recalculer deux fois la même chose dans le même geste.
---@param coords table|nil liste {x,y,z} déjà résolue pour ce dtype
function PowerBank:controlDeviceGroup(dtype, on, coords)
    if coords then
        for _, c in ipairs(coords) do
            local devSq = getSquare(c.x, c.y, c.z)
            if devSq then psrSetDeviceState(devSq, dtype, on) end
        end
        return
    end
    local sq = self:getSquare()
    if not sq then return end
    local building = sq:getBuilding()
    -- Resolve the device list the same way updateDrain does: building scan when in a vanilla
    -- building, vanilla-radius scan otherwise (player-built base) — so the group toggle works
    -- in both, consistent with the per-device drain.
    local drainUnused, dl
    if building then
        drainUnused, dl = self:getDrainBuilding(sq, building)
    else
        drainUnused, dl = self:getDrainVanilla(sq)
    end
    if not dl then return end
    local done = {}
    for _, dev in ipairs(dl) do
        if dev.dtype == dtype then
            local key = dev.x .. "_" .. dev.y .. "_" .. dev.z
            if not done[key] then
                done[key] = true
                local devSq = getSquare(dev.x, dev.y, dev.z)
                if devSq then psrSetDeviceState(devSq, dtype, on) end
            end
        end
    end
end

-- Physically turns on/off a single device (identified by square + dtype).
function PowerBank:controlDevice(x, y, z, dtype, on)
    local devSq = getSquare(x, y, z)
    if devSq then psrSetDeviceState(devSq, dtype, on) end
end

function PowerBank:updateDrain()
    local square = self:getSquare()
    if not square then return end
    -- Élague d'abord les extensions manuelles dont la structure a été démolie : sans ça la bank
    -- facturait une ruine indéfiniment (rien ne couvrait ce chemin — ni la déconnexion volontaire,
    -- ni le retrait de la bank). N'efface que sur preuve positive : case chargée ET tag disparu.
    -- Coût nul quand la liste est vide, c'est-à-dire dans l'écrasante majorité des cas.
    PSR.WorldUtil.pruneDeadStructures(self)
    local building = square:getBuilding()
    if building then
        self.drain, self.deviceList = self:getDrainBuilding(square, building)
    else
        self.drain, self.deviceList = self:getDrainVanilla(square)
    end
end

function PowerBank:updateBatteries(container, modCharge)
    if not container then return end
    local items = container:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if container:isItemAllowed(item) then
            item:setCurrentUsesFloat(modCharge)
        else
            container:Remove(item)
            self:getSquare():AddWorldInventoryItem(item, 0.5, 0.5, 0)
            self.luaSystem:noise("Removed invalid item from Battery Bank: " .. item:getFullType())
        end
    end
    container:setDrawDirty(true)
end

function PowerBank:degradeBatteries(container)
    if not container then return end
    -- Lecture en direct : « 0 désactive » doit rester vrai même si le module a été chargé avant
    -- que les SandboxVars ne soient peuplées (cf. la note en tête de fichier).
    if psrSandbox().batteryDegradeChance == 0 then return end
    if not self.on then return end
    local items = container:getItems()
    for i = items:size() - 1, 0, -1 do repeat
        local item = items:get(i)
        if not item:getModData().PSR_maxCapacity then break end
        local cond = item:getCondition()
        if cond <= 0 then break end
        item:setCondition(math.max(0, cond - 1))
    until true
    end
end

function PowerBank:calculateBatteryStats(container)
    if not container then return end
    local batteries, capacity, charge = 0, 0, 0
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local maxCapacity = item:getModData().PSR_maxCapacity
        if maxCapacity then
            local condition = item:getCondition()
            if condition > 0 then
                batteries = batteries + 1
                local cap = maxCapacity * (1 - math.pow((1 - (condition / 100)), 6))
                capacity = capacity + cap
                charge = charge + cap * item:getCurrentUsesFloat()
            end
        else
            self.luaSystem:noise("Warning: invalid item in Battery Bank: " .. item:getFullType())
        end
    end
    self.batteries = batteries
    self.maxcapacity = capacity
    self.charge = charge
end

function PowerBank:getPanelStatus(panel)
    local x, y, z = panel:getX(), panel:getY(), panel:getZ()
    if IsoUtils.DistanceToSquared(x, y, self.x, self.y) <= 400.0 and math.abs(z - self.z) <= 3 then
        for _, panelXYZ in ipairs(self.panels) do
            if x == panelXYZ.x and y == panelXYZ.y and z == panelXYZ.z then return "connected" end
        end
        return "not connected"
    else
        return "far"
    end
end

function PowerBank:getPanelStatusOnSquare(square)
    local panel = PSR.WorldUtil.findTypeOnSquare(square, "Panel")
    if panel ~= nil then
        return panel, square:isOutside() and self:getPanelStatus(panel) or "indoors"
    end
    return nil, ""
end

function PowerBank:checkPanels()
    local dup = {}
    self.panels = self.panels or {}
    for i = #self.panels, 1, -1 do
        local panel = self.panels[i]
        local square = getSquare(panel.x, panel.y, panel.z)
        if square ~= nil then
            local panelObj, status = self:getPanelStatusOnSquare(square)
            if not panelObj or status ~= "connected" or dup[square] then
                table.remove(self.panels, i)
                if panelObj ~= nil then
                    panelObj:getModData().pbLinked = nil
                    panelObj:transmitModData()
                end
            end
            dup[square] = true
        end
    end
    self.npanels = #self.panels
end

local chargeSprites = {
    [0.10] = { "solarmod_tileset_01_1",  "solarmod_tileset_01_2",  "solarmod_tileset_01_3",  "solarmod_tileset_01_4",  "solarmod_tileset_01_5"  },
    [0.35] = { "solarmod_tileset_01_16", "solarmod_tileset_01_20", "solarmod_tileset_01_24", "solarmod_tileset_01_28", "solarmod_tileset_01_32" },
    [0.65] = { "solarmod_tileset_01_17", "solarmod_tileset_01_21", "solarmod_tileset_01_25", "solarmod_tileset_01_29", "solarmod_tileset_01_33" },
    [0.95] = { "solarmod_tileset_01_18", "solarmod_tileset_01_22", "solarmod_tileset_01_26", "solarmod_tileset_01_30", "solarmod_tileset_01_34" },
    [1.00] = { "solarmod_tileset_01_19", "solarmod_tileset_01_23", "solarmod_tileset_01_27", "solarmod_tileset_01_31", "solarmod_tileset_01_35" },
}
local chargeThresholds = { 0.10, 0.35, 0.65, 0.95, 1.00 }

function PowerBank:getSpriteForOverlay(modCharge)
    if (self.batteries or 0) <= 0 then return nil end
    if modCharge == nil then modCharge = self.maxcapacity > 0 and self.charge / self.maxcapacity or 0 end
    local sprites
    for _, threshold in ipairs(chargeThresholds) do
        if modCharge < threshold then sprites = chargeSprites[threshold]; break end
    end
    sprites = sprites or chargeSprites[1.00]
    local b = self.batteries
    if b < 5 then return sprites[1]
    elseif b < 9 then return sprites[2]
    elseif b < 13 then return sprites[3]
    elseif b < 17 then return sprites[4]
    else return sprites[5] end
end

function PowerBank:updateSprite(modCharge)
    local newSprite = self:getSpriteForOverlay(modCharge)
    local isoObject = self:getIsoObject()
    if not isoObject then return end
    local attached = isoObject:getAttachedAnimSprite()
    if attached ~= nil then
        for i = 0, attached:size() - 1 do
            local attachedSprite = attached:get(i)
            local attachedName = attachedSprite:getName()
            if attachedName == newSprite then return end
            if attachedName and string.find(attachedName, "^solarmod_tileset_01_") then
                isoObject:RemoveAttachedAnim(i)
                break
            end
        end
    end
    if newSprite ~= nil then
        isoObject:addAttachedAnimSpriteByName(newSprite)
    end
end

function PowerBank:updateGenerator(dCharge)
    if dCharge == nil then
        dCharge = self.luaSystem:getModifiedSolarOutput(self.npanels or 0) - (self.drain or 0)
        if ((SandboxVars.PSR and SandboxVars.PSR.ChargeFreq) or 1) == 1 then dCharge = dCharge / 6 end
    end
    local activate = self.on and (self.charge or 0) + dCharge > 0
    local square = self:getSquare()
    if not square then return end
    local gen = square:getGenerator()
    if not gen then return end
    local building = square:getBuilding()
    if activate then
        if not gen:isActivated() then
            gen:setConnected(true)
            gen:setActivated(true)
        end
        -- 2026-08-03 — LE CARBURANT SUIT LA CHARGE (signal joueur Discord, Realistic Temperature).
        -- Jusqu'ici `setFuel(100)` etait ecrit UNE SEULE FOIS a la creation de la bank
        -- (WorldUtilities.lua) et plus jamais mis a jour : notre generateur ANNONCAIT donc une valeur
        -- fausse. Ce n'est pas une compat, c'est arreter de mentir sur notre propre etat -- tout mod
        -- tiers qui interroge un generateur de la maniere standard etait trompe, RT est seulement
        -- celui qui l'a remarque.
        -- 🔴 Le vrai enjeu n'est PAS le test de RT mais ce qu'il fait ensuite : quand il trouve le
        -- carburant a 0 il appelle `generator:setActivated(false)` (RC_Heaters.lua:821 ET
        -- RC_NetworkServer.lua:638, verifie dans son code) -- il ETEINT donc notre bank, que notre
        -- tick suivant rallume. D'ou des micro-coupures sur TOUT ce que la bank alimente, pas
        -- seulement sur ses radiateurs. Le plancher a 1 % ci-dessous ferme cette branche.
        -- ⚠️ CE QU'ON NE FAIT PAS, ET C'EST DELIBERE : on ne RELIT pas ce champ pour facturer ce
        -- qu'un tiers a consomme. Ce serait plus juste (RT decremente le carburant pour representer
        -- la conso du radiateur, on l'ecrase donc a chaque tick => chauffage gratuit), mais on ne
        -- peut PAS distinguer sa consommation de la combustion du moteur vanilla => on facturerait
        -- deux fois, chez TOUS les joueurs, y compris ceux qui n'ont pas RT. Mesure qui debloquerait
        -- ce chantier : prouver que le moteur ne brule PAS le carburant d'une bank (question posee
        -- au joueur : ses radiateurs marchaient-ils au debut avant de s'arreter ?).
        local mc  = self.maxcapacity or 0
        local pct = (mc > 0) and (((self.charge or 0) / mc) * 100) or 0
        if pct > 100 then pct = 100 elseif pct < 1 then pct = 1 end
        gen:setFuel(pct)
        if building then
            building:setToxic(false)  -- unconditional: gating on isToxic() breaks MP (see suppressToxic, v1.40)
            psrApplyBuildingChunks(building, self.z, false)
        end
    else
        -- Ne retirer QUE ce qu'on a effectivement injecte. `self.activated` est le drapeau de NOTRE
        -- propre injection (false a la pose, persiste en modData, recalcule au chargement par
        -- loadGenerator). Sans ce garde, une bank posee, ETEINTE et jamais connectee effaçait la
        -- couverture du batiment a CHAQUE tick de charge : un generateur essence vanilla qui
        -- alimentait la maison perdait son courant quelques secondes apres la pose de la bank, puis
        -- toutes les 10 minutes de jeu (signal joueur 2026-07-29).
        -- ✅ PROUVE PAR TEST A/B IN-GAME (2026-07-29), pas deduit : sans ce garde, une bank posee /
        -- eteinte / non connectee fait tomber la couverture du batiment de 625 a 561 cases (= 64,
        -- soit un CHUNK entier) alors que le generateur essence du joueur tourne et est branche ;
        -- la retirer rend le courant (625), la reposer le recoupe (561). Avec le garde : 625 stable.
        if self.activated and building then
            psrApplyBuildingChunks(building, self.z, true)
        end
        if gen:isActivated() then
            gen:setActivated(false)
            gen:setConnected(false)
        end
        -- Symetrie du bloc ci-dessus : une bank eteinte ou vide ne doit pas continuer d'ANNONCER du
        -- carburant, sinon un mod tiers la voit comme une source vivante alors qu'elle ne distribue
        -- rien. Sans cette ligne l'etat serait a moitie juste (le carburant suivrait la charge tant
        -- que la bank tourne, puis se figerait a sa derniere valeur a l'extinction).
        gen:setFuel(0)
    end
    self.activated = activate
end

function PowerBank:loadGenerator()
    local generator = self:getIsoObject()
    if not generator then return end
    generator:getCell():addToProcessIsoObjectRemove(generator)
    self:updateGenerator()
    self:updateConGenerator()
end

-- Clears this bank's injected electricity when it is PICKED UP / DESTROYED without being turned off
-- first. updateGenerator's deactivate branch (which removes the generator chunks) never runs on a
-- direct removal → the addGeneratorPos flags AND the generator's vanilla surrounding radius would
-- otherwise persist, powering appliances for free indefinitely (player-observed 2026-07-04).
-- Symmetric with placement (pose⇒dépose). Called from OnObjectAboutToBeRemoved before removeLuaObject.
function PowerBank:removePowerCoverage()
    local square = self:getSquare()
    if not square then return end
    local building = square:getBuilding()
    if building then
        psrApplyBuildingChunks(building, self.z, true)
    end
    local gen = square:getGenerator()
    if gen and gen:isActivated() then
        gen:setActivated(false)
        gen:setConnected(false)
    end
end

function PowerBank:connectBackupGenerator(generator)
    self.conGenerator = {
        x    = generator:getX(),
        y    = generator:getY(),
        z    = generator:getZ(),
        ison = generator:isActivated(),
    }
    self.lastHour = 0
    self:saveData(true)
end

function PowerBank:disconnectBackupGenerator(generator)
    self.conGenerator = false
    self:saveData(true)
end

function PowerBank:autoConnectBackup()
    local area = PSR.WorldUtil.getValidBackupArea(3)
    self.conGenerator = false
    for ix = self.x - area.radius, self.x + area.radius do
        for iy = self.y - area.radius, self.y + area.radius do
            for iz = self.z - area.levels, self.z + area.levels do
                if ix >= 0 and iy >= 0 and iz >= 0 then
                    local sq = IsoUtils.DistanceToSquared(self.x, self.y, self.z, ix, iy, iz) <= area.distance and getSquare(ix, iy, iz)
                    local generator = sq and self.luaSystem:getValidBackupOnSquare(sq)
                    if generator then
                        self:connectBackupGenerator(generator)
                        return
                    end
                end
            end
        end
    end
end

function PowerBank:getConGenerator()
    if self.conGenerator then
        local square = getSquare(self.conGenerator.x, self.conGenerator.y, self.conGenerator.z)
        if square then
            local generator = square:getGenerator()
            if not generator then self.conGenerator = false end
            return generator, square
        end
    end
end

-- Failsafe basé sur la charge du RÉSEAU lié, mais sur le DRAIN individuel (self.drain) de la bank.
-- POURQUOI seulement la charge : le bug d'origine = une bank sous-chargée d'un réseau (ex 2e bank
-- avec 1 batterie) voyait sa PART de charge tomber sous son drain et allumait le générateur de
-- secours en pleine JOURNÉE alors que le réseau avait des heures de réserve (signal joueur 2026-06-24).
-- On compare donc la charge RÉSEAU (networkCharge, passée par updateNetwork).
-- POURQUOI PAS un drain réseau : updateNetwork met totalDrain à 0 dès qu'un secours tourne
-- (shouldDrain=false), et `0 or self.drain` ne retombe PAS sur le fallback (0 est truthy en Lua) ->
-- le seuil s'effondrerait à 0 et le secours clignoterait ON/OFF chaque heure (régression détectée par
-- audit adverse 2026-06-24). self.drain reste GELÉ à sa dernière vraie valeur quand le secours tourne
-- (updateDrain est gardé par shouldDrain) -> hystérésis correcte, le secours reste allumé jusqu'à
-- vraie recharge. Cas 1 bank / appel sans contexte (loadGenerator) : networkCharge nil -> self.charge
-- -> comportement strictement identique à avant.
function PowerBank:updateConGenerator(networkCharge)
    local currentHour = math.floor(getGameTime():getWorldAgeHours())
    if self.lastHour == currentHour then return end
    local conGenerator, square = self:getConGenerator()
    if conGenerator then
        conGenerator:update()
        -- 🔴 ASYMETRIE CORRIGEE (audit 2026-08-04) : l'extinction vivait DANS la garde ci-dessous.
        -- Trois gestes la faisaient tomber alors que le secours tournait — eteindre la bank,
        -- ramasser la tuile Failsafe, ramasser la bank — et il n'existe aucun autre appelant de
        -- `setActivated(false)` sur ce generateur. Le groupe electrogene tournait donc jusqu'a la
        -- panne seche, en regazant le batiment. *Un effet livre sans son contre-effet* : c'est le
        -- cadre REALISME, viole ici depuis l'origine.
        --
        -- ⚠️ MAIS on n'eteint QUE CE QU'ON A ALLUME. Eteindre des que la garde tombe couperait le
        -- generateur que le joueur a demarre LUI-MEME, ce qui serait pire que le defaut. D'ou le
        -- drapeau `byFailsafe`, meme idiome que `self.activated` pour la couverture batiment
        -- (« ne retirer QUE ce qu'on a effectivement injecte »).
        local armed       = self.on and PSR.WorldUtil.findOnSquare(square, "solarmod_tileset_01_15")
        local charge      = networkCharge or self.charge
        local minfailsafe = self.drain

        if conGenerator:isActivated() then
            -- Deux raisons d'eteindre : la batterie est rechargee, OU le failsafe n'est plus arme.
            if self.conGenerator.byFailsafe and ((not armed) or charge > minfailsafe) then
                conGenerator:setActivated(false)
                self.conGenerator.byFailsafe = nil
            end
        elseif armed then
            if charge < minfailsafe and conGenerator:getFuel() > 0 and conGenerator:getCondition() > 20 then
                conGenerator:setActivated(true)
                self.conGenerator.byFailsafe = true   -- c'est NOUS : on s'engage a l'eteindre
            end
        end
        self.lastHour = currentHour
        self.conGenerator.ison = conGenerator:isActivated()
    end
end

return PowerBank
