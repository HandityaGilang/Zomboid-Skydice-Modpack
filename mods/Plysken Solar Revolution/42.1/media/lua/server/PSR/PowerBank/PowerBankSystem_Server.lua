--[[
    "psr_powerbank" server system — B42 rewrite (SGlobalObjects API)
--]]

if isClient() and not isServer() then return end   -- coop host = isClient ET isServer vrais : ne couper QUE le client pur (sinon le système serveur est mort sur l'hôte coop)

local PSR = require "PSR/Utilities"
local Powerbank = require "PSR/PowerBank/PowerBankObject_Server"

---@class PowerbankSystem_Server : PowerbankSystem
---@field instance PowerbankSystem_Server
local PBSystem = require("PSR/PowerBankSystem_Shared"):new({})
PBSystem.__index = PBSystem

PBSystem.savedObjectModData = { 'on', 'activated', 'batteries', 'charge', 'maxcapacity', 'drain', 'npanels', 'panels', "lastHour", "conGenerator", "PSR_linkedBanks", "PSR_computer", "PSR_manualStructures" }

function PBSystem:initSystem()
    PSR.PBSystem_Server = self
    self.system:setObjectModDataKeys(self.savedObjectModData)
    self.updateEveryTenMinutes = ((SandboxVars.PSR and SandboxVars.PSR.ChargeFreq) or 1) == 1
    if self.updateEveryTenMinutes then
        Events.EveryTenMinutes.Add(PBSystem.updatePowerbanks)
    else
        Events.EveryHours.Add(PBSystem.updatePowerbanks)
    end
    Events.EveryDays.Add(PBSystem.EveryDays)
    -- 42.19 : suppress the transient indoor "toxic gas" warning every game minute (see suppressToxic).
    Events.EveryOneMinute.Add(PBSystem.suppressToxic)
end

function PBSystem:noise(message)
    if self.wantNoise then print("PSR_Server: " .. message) end
end

function PBSystem:getInitialStateForClient()
    return nil
end

function PBSystem:OnChunkLoaded(wx, wy)
    local globalObjects = self.system:getObjectsInChunk(wx, wy)
    for i = 1, globalObjects:size() do
        local globalObject = globalObjects:get(i - 1)
        local square = getCell():getGridSquare(globalObject:getX(), globalObject:getY(), globalObject:getZ())
        local isoObject = self:getIsoObjectOnSquare(square)
        if isoObject then
            self:loadIsoObject(isoObject)
        elseif square then
            -- 🩹 PREUVE POSITIVE EXIGEE (audit 2026-08-04).
            -- `getIsoObjectOnSquare` rend nil dans DEUX cas qui n'ont rien a voir :
            --   · la case est chargee et ne porte aucune bank  -> la bank a bien disparu ✅
            --   · `square` est nil (chunk pas encore charge)   -> ON NE SAIT PAS ❌
            -- La fonction commence par `if not square then return end`, donc les deux cas
            -- arrivaient ici et l'entree etait supprimee dans les deux. Un nettoyage destructif
            -- ne doit jamais agir sur une absence d'information (regle payee sur PFR : faux
            -- degel = perte de nourriture definitive).
            -- ⚠️ Cette structure vient du vanilla (`SGlobalObjectSystem.lua`), ou la perte est
            -- triviale (un feu de camp). Ici elle coutait l'etat complet d'une bank. Le vanilla
            -- `MOCampfire` fait d'ailleurs ce qui manquait : relire le modData avant de decider.
            self:noise('OnChunkLoaded: luaObject without isoObject, removing')
            self.system:removeObject(globalObject)
        end
    end
    self.system:finishedWithList(globalObjects)
end

---Wrap a global object's mod data with PowerBank methods. Safe to call multiple times.
---@param globalObject table
---@return PowerBankObject_Server
function PBSystem:wrapGlobalObject(globalObject)
    local pb = globalObject:getModData()
    if getmetatable(pb) ~= Powerbank then
        pb.x = globalObject:getX()
        pb.y = globalObject:getY()
        pb.z = globalObject:getZ()
        pb.luaSystem = self
        setmetatable(pb, Powerbank)
    end
    return pb
end

---@param x number
---@param y number
---@param z number
---@return PowerBankObject_Server?
function PBSystem:getLuaObjectAt(x, y, z)
    local go = self.system:getObjectAt(x, y, z)
    if go then return self:wrapGlobalObject(go) end
end

---@param square IsoGridSquare
---@return PowerBankObject_Server?
function PBSystem:getLuaObjectOnSquare(square)
    if not square then return end
    return self:getLuaObjectAt(square:getX(), square:getY(), square:getZ())
end

---@param i number  (0-indexed)
---@return PowerBankObject_Server
function PBSystem:getLuaObjectByIndex(i)
    return self:wrapGlobalObject(self.system:getObjectByIndex(i))
end

---@return number
function PBSystem:getLuaObjectCount()
    return self.system:getObjectCount()
end


---Create or load the global object entry for an IsoObject.
---@param isoObject IsoObject
function PBSystem:loadIsoObject(isoObject)
    local isoMd = isoObject:getModData()
    local x, y, z = isoObject:getX(), isoObject:getY(), isoObject:getZ()

    local go = self.system:getObjectAt(x, y, z)
    local pb
    if go then
        pb = self:wrapGlobalObject(go)
        if pb.on ~= nil then
            pb:stateToIsoObject(isoObject)
        else
            pb:stateFromIsoObject(isoObject)
        end
    else
        go = self.system:newObject(x, y, z)
        pb = self:wrapGlobalObject(go)
        pb:stateFromIsoObject(isoObject)
    end
end

---@param luaPb PowerBankObject_Server
function PBSystem:removeLuaObject(luaPb)
    local go = self.system:getObjectAt(luaPb.x, luaPb.y, luaPb.z)
    if go then self.system:removeObject(go) end
end

---triggered by SGlobalObjectSystem when an IsoObject is placed/loaded
---@param isoObject IsoObject
function PBSystem:OnObjectAdded(isoObject)
    local PSRType = PSR.WorldUtil.getType(isoObject)
    if not PSRType then
        return
    elseif PSRType == "PowerBank" then
        if not instanceof(isoObject, "IsoGenerator") then
            isoObject = PSR.WorldUtil.replaceIsoObjectWithGenerator(isoObject)
        end
        if self:isValidIsoObject(isoObject) then
            self:loadIsoObject(isoObject)
        end
    elseif PSRType == "Panel" then
        local modData = isoObject:getModData()
        modData.pbLinked = nil
        modData.connectDelta = nil
        isoObject:transmitModData()
    end
end


---triggered by SGlobalObjectSystem when an IsoObject is about to be removed
---@param isoObject IsoObject
function PBSystem:OnObjectAboutToBeRemoved(isoObject)
    local PSRType = PSR.WorldUtil.getType(isoObject)
    -- Nettoyage si un Desktop Computer lié au PSR est ramassé (IsoMoveable vanilla, pas un PSRType)
    local linkedBank = isoObject:getModData().PSR_linkedBank
    if linkedBank then
        local pb = self:getLuaObjectAt(linkedBank.x, linkedBank.y, linkedBank.z)
        if pb then
            pb.PSR_computer = nil
            pb:saveData(true)
        end
        isoObject:getModData().PSR_linkedBank = nil
        isoObject:transmitModData()
    end
    if not PSRType then
        return
    end
    if self:isValidIsoObject(isoObject) then
        local luaObject = self:getLuaObjectOnSquare(isoObject:getSquare())
        if not luaObject then return end
        for _, link in ipairs(luaObject.PSR_linkedBanks or {}) do
            local linked = self:getLuaObjectAt(link.x, link.y, link.z)
            if linked then
                PSR.WorldUtil.removeLinkEntry(linked, luaObject.x, luaObject.y, luaObject.z)
                linked:saveData(true)
            end
        end
        -- Clear OUTGOING links so nothing keeps pointing at a bank that no longer exists
        -- (player-observed 2026-07-04: computer + panels still linked after the bank was removed).
        -- Computer: clear the linked computer's back-reference (mirrors UnlinkComputer).
        if luaObject.PSR_computer then
            local csq = getSquare(luaObject.PSR_computer.x, luaObject.PSR_computer.y, luaObject.PSR_computer.z)
            if csq then
                local cobjs = csq:getObjects()
                for i = 0, cobjs:size() - 1 do
                    local obj = cobjs:get(i)
                    local lb = obj and obj:getModData().PSR_linkedBank
                    if lb and lb.x == luaObject.x and lb.y == luaObject.y and lb.z == luaObject.z then
                        obj:getModData().PSR_linkedBank = nil
                        obj:transmitModData()
                        break
                    end
                end
            end
        end
        -- Panels: clear each connected panel's pbLinked/connectDelta (mirrors disconnectPanel).
        for _, panel in ipairs(luaObject.panels or {}) do
            local psq = getSquare(panel.x, panel.y, panel.z)
            if psq then
                local pobjs = psq:getSpecialObjects()
                for i = 0, pobjs:size() - 1 do
                    local obj = pobjs:get(i)
                    local md = obj and obj:getModData()
                    -- Only clear panels actually linked to THIS bank (coord check, like the computer
                    -- block above) so a stale/foreign panel linked to another bank is left untouched.
                    if md and md.pbLinked and md.pbLinked.x == luaObject.x
                       and md.pbLinked.y == luaObject.y and md.pbLinked.z == luaObject.z then
                        md.pbLinked = nil
                        md.connectDelta = nil
                        obj:transmitModData()
                        break
                    end
                end
            end
        end
        -- Clear the back-ref tag on each manually-connected extension's anchor square (mirrors the
        -- computer/panel cleanup): the bank's own PSR_manualStructures list dies with the bank object,
        -- but the anchor square's PSR_structBank tag would otherwise stay stale.
        for _, s in ipairs(luaObject.PSR_manualStructures or {}) do
            for _, c in ipairs(PSR.Structures.resolveSquares(s.x, s.y, s.z)) do
                local ssq = getSquare(c.x, c.y, c.z)
                if ssq then
                    local sobjs = ssq:getObjects()
                    if sobjs then
                        for i = 0, sobjs:size() - 1 do
                            local obj = sobjs:get(i)
                            local md = obj and obj:getModData()
                            if md and md.PSR_structBank and md.PSR_structBank.x == luaObject.x
                               and md.PSR_structBank.y == luaObject.y and md.PSR_structBank.z == luaObject.z then
                                md.PSR_structBank = nil
                                obj:transmitModData()
                                break
                            end
                        end
                    end
                end
            end
        end
        -- Clear the injected electricity BEFORE the object goes away (picked up / destroyed while
        -- still on) so appliances don't keep power for free. Must run before removeLuaObject while
        -- the square + generator are still resolvable.
        luaObject:removePowerCoverage()
        self:removeLuaObject(luaObject)
    elseif PSRType == "Panel" then
        self:removePanel(isoObject)
    end
end

function PBSystem:OnClientCommand(command, playerObj, args)
    local fn = self.Commands[command]
    if fn ~= nil then fn(playerObj, args) end
end

function PBSystem:removePanel(panel)
    local pbData = panel:getModData().pbLinked
    if pbData == nil then return end
    local pb = self:getLuaObjectAt(pbData.x, pbData.y, pbData.z)
    panel:getModData().pbLinked = nil
    panel:transmitModData()
    if pb == nil then return end
    local x, y, z = panel:getX(), panel:getY(), panel:getZ()
    for i = #pb.panels, 1, -1 do
        local _panel = pb.panels[i]
        if _panel.x == x and _panel.y == y and _panel.z == z then
            table.remove(pb.panels, i)
            pb.npanels = (pb.npanels or 1) - 1
            break
        end
    end
    pb:saveData(true)
end

do
    local o = PSR.delayedProcess:new{maxTimes=999}

    function o.process(tick)
        if not o.data then o:stop() return end
        for i = #o.data, 1, -1 do
            if o.data[i].obj:getObjectIndex() == -1 then
                local square = o.data[i].sq
                local generator = square and square:getGenerator()
                if generator then
                    generator:setActivated(false)
                    generator:remove()
                end
                table.remove(o.data, i)
            end
        end
        if o.data[1] == nil or o.times <= 1 then o:stop() return end
        o.times = o.times - 1
    end

    function o:addItem(isoObject)
        if not self.data then
            self.data = {}
            self.event.Add(self.process)
        end
        self.times = self.maxTimes
        table.insert(self.data, { obj = isoObject, sq = isoObject:getSquare() })
    end

    PBSystem.processRemoveObj = o
end

---@param character IsoPlayer
---@param generator IsoGenerator
function PBSystem:onPlugGenerator(character, generator)
    if not (character and generator and generator:getSquare()) then return end
    local area = PSR.WorldUtil.getValidBackupArea(character:getPerkLevel(Perks.Electricity))
    local luaPowerbanks = PSR.WorldUtil.getPowerBanksInArea(generator:getSquare(), area.radius, area.levels, area.distance)
    if luaPowerbanks[1] == nil then return end
    local x, y, z = generator:getX(), generator:getY(), generator:getZ()
    for i = 1, #luaPowerbanks do
        local pb = luaPowerbanks[i]
        local connect = true
        if pb.conGenerator and IsoUtils.DistanceToSquared(pb.x, pb.y, pb.z, pb.conGenerator.x, pb.conGenerator.y, pb.conGenerator.z)
                                <= IsoUtils.DistanceToSquared(pb.x, pb.y, pb.z, x, y, z) then
            connect = false
        end
        if connect then pb:connectBackupGenerator(generator) end
    end
end

---@param character IsoPlayer
---@param generator IsoGenerator
function PBSystem:onUnPlugGenerator(character, generator)
    if not generator then return end
    local x, y, z = generator:getX(), generator:getY(), generator:getZ()
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self:getLuaObjectByIndex(i)
        if pb.conGenerator and pb.conGenerator.x == x and pb.conGenerator.y == y and pb.conGenerator.z == z then
            pb:disconnectBackupGenerator(generator)
        end
    end
end

---@param character IsoPlayer
---@param generator IsoGenerator
---@param activate boolean
function PBSystem:onActivateGenerator(character, generator, activate)
    if not generator then return end
    local x, y, z = generator:getX(), generator:getY(), generator:getZ()
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self:getLuaObjectByIndex(i)
        if pb.conGenerator and pb.conGenerator.x == x and pb.conGenerator.y == y and pb.conGenerator.z == z then
            pb.conGenerator.ison = activate
        end
    end
end

function PBSystem:onTransferItem(action, character, item, srcContainer, destContainer, dropSquare)
    local maxCapacity = item:getModData().PSR_maxCapacity
    if not maxCapacity then return end
    local src = srcContainer:getParent()
    local dst = destContainer:getParent()
    local remove = src ~= nil and PSR.WorldUtil.objectIsType(src, "PowerBank")
    local add    = dst ~= nil and PSR.WorldUtil.objectIsType(dst, "PowerBank")
    if not (remove or add) then return end
    local capacity = maxCapacity * (1 - math.pow((1 - (item:getCondition() / 100)), 6))
    local charge = capacity * item:getCurrentUsesFloat()
    if remove then
        local pb = self:getLuaObjectAt(src:getX(), src:getY(), src:getZ())
        if not pb then return end
        pb.batteries = (pb.batteries or 0) - 1
        if pb.batteries > 0 then
            pb.charge = (pb.charge or 0) - charge
            pb.maxcapacity = (pb.maxcapacity or 0) - capacity
        else
            pb.charge = 0
            pb.maxcapacity = 0
        end
        pb:updateGenerator()
        pb:updateSprite()
        pb:saveData(true)
    end
    if add then
        local pb = self:getLuaObjectAt(dst:getX(), dst:getY(), dst:getZ())
        if not pb then return end
        pb.batteries = pb.batteries + 1
        pb.charge = pb.charge + charge
        pb.maxcapacity = pb.maxcapacity + capacity
        pb:updateGenerator()
        pb:updateSprite()
        pb:saveData(true)
    end
end

function PBSystem.EveryDays()
    local self = PBSystem.instance
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self:getLuaObjectByIndex(i)
        local isopb = pb:getIsoObject()
        if isopb then
            local inv = isopb:getContainer()
            pb:degradeBatteries(inv)
            pb:calculateBatteryStats(inv)
        end
        pb:checkPanels()
    end
end

function PBSystem:updateNetwork(network, solaroutput)
    -- Sync battery state from containers before every tick (ISTransferAction may not fire in B42 coop)
    for _, member in ipairs(network) do
        local iso = member:getIsoObject()
        if iso then
            member:calculateBatteryStats(iso:getContainer())
            member:updateSprite()
        end
    end
    local totalDrain, totalPanels = 0, 0
    local drainCounted = false
    for _, member in ipairs(network) do
        if member:shouldDrain(member:getIsoObject()) then
            member:updateDrain()
            if not drainCounted then
                totalDrain = member.drain
                drainCounted = true
            end
        end
        totalPanels = totalPanels + (member.npanels or 0)
    end
    local totalCharge, totalCapacity = self:getNetworkStats(network)
    local dCharge = solaroutput * totalPanels - totalDrain
    if self.updateEveryTenMinutes then dCharge = dCharge / 6 end
    local newCharge = totalCharge + dCharge
    if newCharge < 0 then newCharge = 0
    elseif newCharge > totalCapacity then newCharge = totalCapacity end
    self:distributeCharge(network, newCharge, totalCapacity)
    for _, member in ipairs(network) do
        local isoMember = member:getIsoObject()
        local memberModCharge = (member.maxcapacity or 0) > 0 and (member.charge or 0) / member.maxcapacity or 0
        if isoMember then
            member:updateBatteries(isoMember:getContainer(), memberModCharge)
            member:updateGenerator()
            member:updateSprite(memberModCharge)
        end
        member:updateConGenerator(newCharge)
        member:saveData(true)
    end
    if self.wantNoise then
        self:noise(string.format("network: %d banks, %.1f/%.1f kWh, dCharge: %.1f, panels: %d, drain: %.1f",
            #network, newCharge, totalCapacity, dCharge, totalPanels, totalDrain))
    end
end

function PBSystem.updatePowerbanks()
    local self = PBSystem.instance
    local solaroutput = self:getModifiedSolarOutput(1)
    local processed = {}
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self:getLuaObjectByIndex(i)
        local key = pb.x .. "," .. pb.y .. "," .. pb.z
        if not processed[key] then
            local network = self:getNetwork(pb)
            for _, member in ipairs(network) do
                processed[member.x .. "," .. member.y .. "," .. member.z] = true
            end
            self:updateNetwork(network, solaroutput)
        end
    end
end

-- B42.19 : the vanilla generator update re-flags an indoor activated generator's building as
-- toxic much more aggressively than pre-42.19 (generator system rework, 42.19 changelog #117/#119).
-- PSR's setToxic(false) in updateGenerator only runs on the charge tick (every 10 game minutes,
-- or hourly with ChargeFreq=2), which leaves long windows where players inside see a transient
-- "toxic gas" warning. Cosmetic only — the flag is cleared before damage accumulates (confirmed
-- by player report 2026-06-02 : warning visible, zero damage) — but worth suppressing properly.
-- This light tick re-clears the flag every game minute (~2.5 real seconds) so the window is
-- imperceptible. Known side effect (pre-existing since v1.8, just more frequent now) : a real
-- fuel generator running in the SAME building as a PSR bank won't gas the player either — the
-- toxic flag is building-wide and PSR can't tell who set it.
function PBSystem.suppressToxic()
    local self = PBSystem.instance
    if not self then return end
    for i = 0, self.system:getObjectCount() - 1 do
        local pb = self:getLuaObjectByIndex(i)
        if pb and pb.activated then
            local square = pb.getSquare and pb:getSquare() or nil
            local building = square and square:getBuilding() or nil
            -- Clear UNCONDITIONALLY — do NOT gate on building:isToxic(). In MP the
            -- indoor-generator toxic re-flag happens CLIENT-side, so the server's
            -- isToxic() reads false while clients gas themselves. The server-side
            -- setToxic(false) broadcast each game minute is precisely what overrides
            -- the client re-flag (that's the cost of the "Receive Toxic Building"
            -- log lines). Gating on isToxic() (v1.39) silently re-introduced the gas
            -- chamber in MP — gas is destructive, the log lines are cosmetic. (v1.40)
            if building then
                building:setToxic(false)
            end
        end
    end
end

---B42 registration — called by Events.OnSGlobalObjectSystemInit
function PBSystem.OnSGlobalObjectSystemInit()
    local jSystem = SGlobalObjects.registerSystem("psr_powerbank")
    jSystem:setObjectModDataKeys(PBSystem.savedObjectModData)

    local o = jSystem:getModData()
    setmetatable(o, PBSystem)
    o.system = jSystem
    o.wantNoise = getDebug()
    PBSystem.instance = o
    o:initSystem()
end

Events.OnSGlobalObjectSystemInit.Add(PBSystem.OnSGlobalObjectSystemInit)

-- B42: SGlobalObjects does not fire OnObjectAdded for player-placed objects.
-- Hook the PZ event directly so freshly placed banks get registered.
-- Banks are placed as IsoMoveable — replaceIsoObjectWithGenerator converts them
-- to IsoGenerator and re-fires OnObjectAdded, which then registers them below.
local function onObjectAdded(isoObject)
    if not PBSystem.instance then return end
    local ptype = PSR.WorldUtil.getType(isoObject)
    if not ptype then return end
    if ptype == "Panel" then
        local square = isoObject:getSquare()
        local spriteName = isoObject:getTextureName()
        -- Wall panels: need a wall in the correct facing direction.
        -- For map walls: stored on the adjacent square (E for W-panel, S for N-panel).
        -- For player-built walls (IsoThumpable): stored on the panel's own square.
        -- ⚠️ 2026-08-04 — CE BLOC EST INATTEIGNABLE (audit vague 1) : l'override `placeMoveable`
        -- des sprites 6/7 n'émet volontairement pas `OnObjectAdded`. La validation réelle vit
        -- côté CURSEUR (`shared/PSR/MoveableProps.lua`), où les 3 règles ont été reportées.
        -- On le garde comme filet si un jour l'event repasse par ici — mais ne pas le croire
        -- « la » validation : il ne s'exécute pas.
        if (spriteName == "solarmod_tileset_01_6" or spriteName == "solarmod_tileset_01_7") and square then
            local cell = square:getCell()
            local x, y, z = square:getX(), square:getY(), square:getZ()
            local isWPanel = spriteName == "solarmod_tileset_01_6"
            local wallTag = isWPanel and "WallW" or "WallN"
            local wallFound = false
            -- Case adjacente. ⚠️ Le commentaire disait « map walls via IsoWall » : FAUX depuis
            -- toujours — `IsoWall` n'existe pas en 42.20 et `squareHasWall` ne reconnaît QUE
            -- les murs construits par le joueur (`IsoThumpable`). Cf. la note dans
            -- `WorldUtilities.lua:squareHasWall`.
            local adjSq = isWPanel and cell:getGridSquare(x+1, y, z) or cell:getGridSquare(x, y+1, z)
            if PSR.WorldUtil.squareHasWall(adjSq) then wallFound = true end
            -- Check panel's own square for player-built walls (IsoThumpable with WallW/WallN sprite prop)
            if not wallFound then
                local objs = square:getObjects()
                for i = 0, objs:size()-1 do
                    local obj = objs:get(i)
                    if instanceof(obj, "IsoThumpable") then
                        local sp = obj:getSprite()
                        if sp then
                            local props = sp:getProperties()
                            if props and (props:has(wallTag) or props:has("WallNW")) then
                                wallFound = true
                                break
                            end
                        end
                    end
                end
            end
            if not wallFound then
                square:transmitRemoveItemFromSquare(isoObject)
                PSR.WorldUtil.returnItemToNearbyPlayer(square, "PSR.SolarPanelWall")
                PSR.WorldUtil.notifyNearbyPlayers(square, "IGUI_PSR_WallPanel_NeedsWall")
                return
            end
        end
        -- All panels: must be placed outdoors (need sunlight)
        if square and not square:isOutside() then
            local fullType = PSR.WorldUtil.PSRPanelFullTypes[spriteName] or "PSR.SolarPanelFlat"
            square:transmitRemoveItemFromSquare(isoObject)
            PSR.WorldUtil.returnItemToNearbyPlayer(square, fullType)
            PSR.WorldUtil.notifyNearbyPlayers(square, "IGUI_PSR_Panel_OutdoorOnly")
            return
        end
        -- Wall panels: cross-rotation consistency.
        -- W panel at (x,y) ↔ N panel at (x+1,y-1). If the other rotation's square
        -- is under a roof, reject this one too (prevents rotation bypass).
        if square and (spriteName == "solarmod_tileset_01_6" or spriteName == "solarmod_tileset_01_7") then
            local cell = square:getCell()
            local x, y, z = square:getX(), square:getY(), square:getZ()
            local cx = spriteName == "solarmod_tileset_01_6" and x + 1 or x - 1
            local cy = spriteName == "solarmod_tileset_01_6" and y - 1 or y + 1
            local crossSq = cell:getGridSquare(cx, cy, z)
            if crossSq and not crossSq:isOutside() then
                local fullType = PSR.WorldUtil.PSRPanelFullTypes[spriteName] or "PSR.SolarPanelWall"
                square:transmitRemoveItemFromSquare(isoObject)
                PSR.WorldUtil.returnItemToNearbyPlayer(square, fullType)
                PSR.WorldUtil.notifyNearbyPlayers(square, "IGUI_PSR_Panel_OutdoorOnly")
                return
            end
        end
        -- Clear stale connection data whenever a panel is placed/replaced
        local modData = isoObject:getModData()
        modData.pbLinked = nil
        modData.connectDelta = nil
        isoObject:transmitModData()
        return
    end
    if ptype ~= "PowerBank" then return end
    if not instanceof(isoObject, "IsoGenerator") then
        local square = isoObject:getSquare()
        if square and square:isOutside() then
            square:transmitRemoveItemFromSquare(isoObject)
            PSR.WorldUtil.returnItemToNearbyPlayer(square, "PSR.PowerBank")
            PSR.WorldUtil.notifyNearbyPlayers(square, "IGUI_PSR_PowerBank_IndoorsOnly")
            return
        end
        -- Defer: getSprite() unreliable inside placeMoveableInternal callback
        local pending = isoObject
        local function doReplace()
            Events.OnTick.Remove(doReplace)
            if pending:getSquare() then
                PSR.WorldUtil.replaceIsoObjectWithGenerator(pending)
            end
        end
        Events.OnTick.Add(doReplace)
        return
    end
    local x, y, z = isoObject:getX(), isoObject:getY(), isoObject:getZ()
    if PBSystem.instance.system:getObjectAt(x, y, z) then return end
    PBSystem.instance:loadIsoObject(isoObject)
end
Events.OnObjectAdded.Add(onObjectAdded)

-- Disconnect panels from bank when picked up
Events.OnObjectAboutToBeRemoved.Add(function(isoObject)
    if PBSystem.instance then
        PBSystem.instance:OnObjectAboutToBeRemoved(isoObject)
    end
end)

return PBSystem
