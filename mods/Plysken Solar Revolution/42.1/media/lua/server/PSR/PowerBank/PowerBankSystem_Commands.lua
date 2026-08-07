if isClient() and not isServer() then return end   -- coop host = isClient ET isServer vrais : ne couper QUE le client pur (sinon le système serveur est mort sur l'hôte coop)

---@class PowerbankSystem_Server
local PSR = require "PSR/Utilities"
local PBSystem = require "PSR/PowerBank/PowerBankSystem_Server"

-- Register shared TimedAction classes in server's global env so PZ can mirror them in coop
require "PSR/TimedActions/ActivatePowerbank"
require "PSR/TimedActions/ConnectPanel"
require "PSR/TimedActions/DisconnectPanel"
require "PSR/TimedActions/LinkBanks"
require "PSR/TimedActions/UnlinkBanks"
require "PSR/TimedActions/LinkComputer"
require "PSR/TimedActions/UnlinkComputer"
require "PSR/TimedActions/ConnectStructure"

local Commands = {}

local function noise(message) return PBSystem.instance:noise(message) end

---@param args table
---@return PowerBankObject_Server
local function getPowerBank(args)
    return PBSystem.instance:getLuaObjectAt(args.x, args.y, args.z)
end

function Commands.disconnectPanel(player, args)
    local pb = getPowerBank(args.pb)
    if pb == nil then return end
    local x, y, z = args.panel.x, args.panel.y, args.panel.z
    for i, panel in ipairs(pb.panels) do
        if panel.x == x and panel.y == y and panel.z == z then
            table.remove(pb.panels, i)
            pb.npanels = (pb.npanels or 1) - 1
            break
        end
    end
    local sq = getSquare(x, y, z)
    if sq then
        local objects = sq:getSpecialObjects()
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            local md = obj:getModData()
            if md.pbLinked then
                md.pbLinked = nil
                md.connectDelta = nil
                obj:transmitModData()
                break
            end
        end
    end
    pb:saveData(true)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════
-- ❌ RETIRÉES LE 2026-08-04 (méga audit, vague 4) — CINQ COMMANDES QUE PERSONNE N'ÉMET :
--    `connectPanel` · `activateGenerator` · `activatePowerbank` · `linkBank` · `unlinkBank`
--
-- 🔎 Pourquoi elles étaient mortes : PSR suit le pattern ISA — la `TimedAction` fait le travail
--    ELLE-MÊME dans son `complete()`, en attaquant `PSR.PBSystem_Server` en direct (sur dédié,
--    `complete()` s'exécute côté serveur via `NetTimedAction`). Ces 5 commandes n'étaient donc
--    que des DOUBLONS du corps de la TimedAction correspondante — `LinkBanks:complete()`
--    (`LinkBanks.lua:77`) était mot pour mot `Commands.linkBank`. Aucun client ne les appelait.
--
-- ⚠️ Détecteur validé sur TÉMOINS avant de conclure (2 filtres précédents avaient rendu de faux
--    verdicts) : la recherche remonte bien les 5 commandes RÉELLEMENT émises — `disconnectPanel`
--    (`DisconnectPanel.lua:92`), `moveBattery` (`Patches.lua:71/90`), `countBatteries`,
--    `plugGenerator` et `troubleshoot` (`PSRStatusWindowDebugView.lua:103/112/118`). 📌 Les
--    commandes passent par DEUX transports (`sendClientCommand` ET `PSR.PBSystem_Client:sendCommand`) :
--    c'est ce qu'un filtre trop étroit avait raté. Toute commande ajoutée ici doit être cherchée
--    sur les deux.
--
-- 🔒 Et ce n'est pas QUE du nettoyage : elles écrivaient de l'état autoritaire (charge, liens,
--    on/off, panneaux) SANS revalidation d'autorité — atteignables uniquement par un paquet
--    fabriqué. Les retirer ferme une surface d'attaque MP.
--
-- ✅ Remplacements vivants, pour qui chercherait où c'est fait maintenant :
--    connectPanel      → `ConnectPanel:complete()`      (`shared/PSR/TimedActions/ConnectPanel.lua:115`)
--    activatePowerbank → `ActivatePowerBank:complete()` (`.../ActivatePowerbank.lua:76`)
--    linkBank          → `LinkBanks:complete()`         (`.../LinkBanks.lua:77`)
--    unlinkBank        → `UnlinkBanks:complete()`       (`.../UnlinkBanks.lua:83`)
--    activateGenerator → `PowerBankSystem_Server.lua:355` (`applyDeviceToggle`), et l'état réel
--                        est de toute façon remiroité par `updateConGenerator` (`:1180`).
-- ═══════════════════════════════════════════════════════════════════════════════════════════

function Commands.moveBattery(player,args)
    local pb = getPowerBank(args[1])
    if pb == nil then return end
    noise("Transfering Battery")
    -- Recalcule l'état depuis le CONTENEUR RÉEL (autoritaire serveur), comme countBatteries/activatePowerbank,
    -- au lieu d'appliquer les deltas charge/capacité calculés CÔTÉ CLIENT (args[3]/args[4]) :
    -- supprime le vecteur de triche (client modifié pouvait gonfler la charge) ET la dérive sur transferts répétés.
    -- Sûr : la commande est envoyée APRÈS ISTransferAction.transferItem (l'item a déjà bougé côté serveur).
    local isopb = pb:getIsoObject()
    if isopb then
        pb:calculateBatteryStats(isopb:getContainer())
    end
    pb:updateGenerator()
    pb:updateSprite()
    pb:saveData(true)
end

function Commands.plugGenerator(player,args)
    local square = getSquare(args.gen.x,args.gen.y,args.gen.z)
    local generator = square and square:getGenerator()
    for _,i in ipairs(args.pbList) do
        local pb = getPowerBank(i)
        if pb then
            if args.plug and generator then
                noise("adding backup")
                pb:connectBackupGenerator(generator)
            else
                if pb.conGenerator and pb.conGenerator.x == args.gen.x and pb.conGenerator.y == args.gen.y and pb.conGenerator.z == args.gen.z then
                    noise("removing backup")
                    pb.conGenerator = false
                end
            end
            pb:saveData(true)
        end
    end
end

-- ❌ `activateGenerator` et `activatePowerbank` retirées ici le 2026-08-04 — voir le bloc en tête
--    de fichier (jamais émises, doublons des `complete()` de TimedAction).

function Commands.countBatteries(player,args)
    local pb = getPowerBank(args)
    local isopb = pb and pb:getIsoObject()
    if isopb then
        pb:calculateBatteryStats(isopb:getContainer())
        pb:updateSprite()
        pb:saveData(true)
    end
end

function Commands.troubleshoot(player, args)
    local pb = getPowerBank(args)
    if not pb then return end

    local isoPB = pb:getIsoObject()
    if not isoPB then return end
    local pbSquare = isoPB:getSquare()
    if not pbSquare then return end

    -- remove invalid generators
    local objects = pbSquare:getSpecialObjects()
    for i = objects:size() - 1, 0 , -1 do
        local object = objects:get(i)
        if instanceof(object, "IsoGenerator") and object:getSprite() == nil then
            object:remove()
        end
    end

    -- remove old attached sprites
    local attached = isoPB:getAttachedAnimSprite()
    if attached then
        attached:clear()
    end

    pb:calculateBatteryStats(isoPB:getContainer())
    pb:updateSprite()
    pb:saveData(true)
end

-- ❌ `linkBank` et `unlinkBank` retirées ici le 2026-08-04 — voir le bloc en tête de fichier
--    (jamais émises ; `Commands.linkBank` était mot pour mot `LinkBanks:complete()`).

--- Builds a grouped device list from the bank's building scan.
--- Groups: { dtype, total, activeCount, rate, devices=[{x,y,z,rate,active}] }
--- ⚡ PERF 2026-08-04 : `dl` est un paramètre OPTIONNEL. `updateDrain()` vient souvent de produire
--- exactement cette liste et de la ranger dans `pb.deviceList` — la recalculer était un balayage
--- complet de la structure pour rien.
--- ✅ Et c'est aussi plus JUSTE : sans ça, la conso facturée (scan de `updateDrain`) et la liste
---    affichée (ce scan-ci, un instant plus tard) venaient de DEUX relevés différents et pouvaient
---    se contredire à l'écran. Elles viennent désormais du même.
---@param dl table|nil deviceList déjà résolue (sinon on la calcule comme avant)
local function buildDeviceGroups(pb, dl)
    local sq = pb:getSquare()
    local groups, order = {}, {}
    if not sq then return groups, order end
    if not dl then
        local building = sq:getBuilding()
        local drainUnused
        if building then
            drainUnused, dl = pb:getDrainBuilding(sq, building)
        else
            drainUnused, dl = pb:getDrainVanilla(sq)
        end
    end
    if not dl then return groups, order end
    for _, dev in ipairs(dl) do
        if not groups[dev.dtype] then
            groups[dev.dtype] = { dtype=dev.dtype, total=0, activeCount=0, rate=0, devices={}, seen={} }
            order[#order + 1] = dev.dtype
        end
        local g   = groups[dev.dtype]
        local sqk = dev.x .. "_" .. dev.y .. "_" .. dev.z
        if not g.seen[sqk] then
            g.seen[sqk]             = true
            g.total                 = g.total + 1
            if dev.active then g.activeCount = g.activeCount + 1 end
            g.devices[#g.devices+1] = { x=dev.x, y=dev.y, z=dev.z, rate=dev.rate, active=dev.active }
        else
            for _, e in ipairs(g.devices) do
                if e.x==dev.x and e.y==dev.y and e.z==dev.z then
                    e.rate = e.rate + dev.rate; break
                end
            end
        end
        if dev.active then g.rate = g.rate + dev.rate end
    end
    return groups, order
end

--- Sends the current device list (grouped by type, with active state) to the requesting client.
--- args: { x, y, z } — bank coordinates
---@param freshList table|nil deviceList tout juste produite par `updateDrain()` (évite un re-scan)
function Commands.requestDeviceList(playerObj, args, freshList)
    local pb = getPowerBank(args)
    if not pb then return end
    local groups, order = buildDeviceGroups(pb, freshList)
    local deviceList = {}
    for _, dtype in ipairs(order) do
        local g = groups[dtype]; g.seen = nil
        deviceList[#deviceList + 1] = g
    end
    sendServerCommand(playerObj, "PSR", "deviceList", {
        devices = deviceList,
        bx = pb.x, by = pb.y, bz = pb.z,
    })
end

--- Collect coordinates of devices of a given type in a bank's building (for applyDeviceToggle).
local function collectDeviceCoords(pb, dtype)
    local sq = pb:getSquare()
    if not sq then return {} end
    local building = sq:getBuilding()
    local drainUnused, dl
    if building then
        drainUnused, dl = pb:getDrainBuilding(sq, building)
    else
        drainUnused, dl = pb:getDrainVanilla(sq)
    end
    if not dl then return {} end
    local coords, seen = {}, {}
    for _, dev in ipairs(dl) do
        if dev.dtype == dtype then
            local key = dev.x .. "_" .. dev.y .. "_" .. dev.z
            if not seen[key] then
                seen[key] = true
                coords[#coords + 1] = { x=dev.x, y=dev.y, z=dev.z }
            end
        end
    end
    return coords
end

--- Physically turns on/off all devices of a type for a bank, then refreshes the client.
--- args: { bank={x,y,z}, dtype="light", on=bool }
function Commands.controlDeviceGroup(playerObj, args)
    local pb = getPowerBank(args.bank)
    if not pb or not args.dtype then return end
    -- Collect coords BEFORE toggling (getDrainBuilding reads live state)
    local coords = collectDeviceCoords(pb, args.dtype)
    -- ⚡ PERF : on PASSE ces coords au lieu de laisser la méthode rebalayer toute la structure
    -- pour retrouver exactement les mêmes cases (2 scans identiques pour un seul clic).
    pb:controlDeviceGroup(args.dtype, args.on, coords)
    pb:updateDrain()
    pb:saveData(true)
    if #coords > 0 then
        if args.dtype == "fridge" or args.dtype == "freezer" or args.dtype == "fridgeFreezer" then
            -- container:setType does NOT auto-replicate over the network → broadcast to ALL clients
            -- so each one applies the swap. setType is idempotent (skips if already the target type),
            -- so the requester receiving it too is harmless.
            sendServerCommand("PSR", "applyDeviceToggle", { dtype=args.dtype, on=args.on, devices=coords })
        else
            sendServerCommand(playerObj, "PSR", "applyDeviceToggle", { dtype=args.dtype, on=args.on, devices=coords })
        end
    end
    -- ⚡ PERF : `updateDrain()` ci-dessus vient de produire la liste — on la réutilise au lieu
    -- de rebalayer la structure une 2ᵉ fois pour la même information.
    Commands.requestDeviceList(playerObj, { x=pb.x, y=pb.y, z=pb.z }, pb.deviceList)
end

--- Physically turns on/off a single device (by square + dtype), then refreshes the client.
--- args: { bank={x,y,z}, x, y, z, dtype="light", on=bool }
function Commands.controlDevice(playerObj, args)
    local pb = getPowerBank(args.bank)
    if not pb or not args.dtype then return end
    pb:controlDevice(args.x, args.y, args.z, args.dtype, args.on)
    pb:updateDrain()
    pb:saveData(true)
    if args.dtype == "fridge" or args.dtype == "freezer" or args.dtype == "fridgeFreezer" then
        -- setType does not auto-replicate → broadcast to all clients (idempotent, see controlDeviceGroup).
        sendServerCommand("PSR", "applyDeviceToggle", { dtype=args.dtype, on=args.on, devices={{ x=args.x, y=args.y, z=args.z }} })
    else
        sendServerCommand(playerObj, "PSR", "applyDeviceToggle", { dtype=args.dtype, on=args.on, devices={{ x=args.x, y=args.y, z=args.z }} })
    end
    -- ⚡ PERF : réutilise la liste que `updateDrain()` vient de produire (cf. controlDeviceGroup).
    Commands.requestDeviceList(playerObj, { x=pb.x, y=pb.y, z=pb.z }, pb.deviceList)
end

PBSystem.Commands = Commands

-- Route all client→server commands for the "psr_powerbank" module.
-- PBSystem:OnClientCommand dispatches to Commands[command] by name.
Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "psr_powerbank" then return end
    if PBSystem.instance then
        PBSystem.instance:OnClientCommand(command, player, args)
    end
end)
