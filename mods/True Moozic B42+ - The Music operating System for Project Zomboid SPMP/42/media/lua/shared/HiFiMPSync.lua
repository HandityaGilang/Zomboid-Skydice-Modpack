--[[
    HiFiMPSync.lua
    Multiplayer sync for all 3 HiFi media slots (CD, Cassette, Vinyl).
    Mirrors TMItemMPSync pattern: server-authoritative give/consume.

    HiFiTimedAction performs its inventory changes locally (DoRemoveItem /
    AddItem). On a client those changes are invisible to the server, so this
    file wraps HiFiTimedAction:perform and mirrors every change through
    TM_HIFI server commands. No client-side item ADD/DELETE packets are ever
    sent, so B42 anti-cheat (item sync protections) stays happy.
]]

require "TCMusicDefenitions"

local HiFiMPSync = {}

------------------------------------------------------------
-- SERVER SIDE
------------------------------------------------------------
if isServer() or isCoopHost() then

    local function giveItem(player, fullType, scratchTable)
        if not fullType or fullType == "" then return end
        local inv = player and player:getInventory()
        if not inv then return end
        local item = instanceItem(fullType)
        if not item then return end
        if scratchTable and TCMusic and TCMusic.restoreScratchToItem then
            TCMusic.restoreScratchToItem(item, scratchTable)
        end
        inv:AddItem(item)
        sendAddItemToContainer(inv, item)
    end

    local function consumeItem(player, args)
        local inv = player and player:getInventory()
        if not inv or not args then return end
        local item = nil
        if args.itemId then
            local items = inv:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it and it.getID and it:getID() == args.itemId then
                    item = it
                    break
                end
            end
        end
        if not item and args.fullType and args.fullType ~= "" then
            item = inv:getFirstTypeRecurse(args.fullType)
        end
        if item then
            local container = item:getContainer() or inv
            container:DoRemoveItem(item)
            if sendRemoveItemFromContainer then
                sendRemoveItemFromContainer(container, item)
            end
        end
    end

    local function onClientCommand(module, command, player, args)
        if module ~= "TM_HIFI" then return end
        args = args or {}

        if command == "giveCD" or command == "giveTape" or command == "giveVinyl" then
            giveItem(player, args.fullType, args.scratch)
        elseif command == "consumeCD" or command == "consumeTape" or command == "consumeVinyl" then
            consumeItem(player, args)
        elseif command == "syncModData" then
            -- Forward modData changes to all clients for a world object
            local x = args.x
            local y = args.y
            local z = args.z
            local key = args.key
            local value = args.value
            if x and y and z and key then
                local sq = getCell():getGridSquare(x, y, z)
                if sq then
                    for i = 0, sq:getObjects():size() - 1 do
                        local obj = sq:getObjects():get(i)
                        if instanceof(obj, "IsoRadio") or instanceof(obj, "IsoWaveSignal") then
                            obj:getModData()[key] = value
                            obj:transmitModData()
                            break
                        end
                    end
                end
            end
        end
    end

    Events.OnClientCommand.Add(onClientCommand)
end

------------------------------------------------------------
-- CLIENT SIDE
------------------------------------------------------------
if isClient() then

    -- Per-action capture of state taken just before perform() runs.
    local _pending = {}

    local ADD_MODES = {
        AddCD = "consumeCD",
        AddCassette = "consumeTape",
        AddVinyl = "consumeVinyl",
    }
    local REMOVE_MODES = {
        RemoveCD = "giveCD",
        RemoveCassette = "giveTape",
        RemoveVinyl = "giveVinyl",
    }

    local function snapshotInventoryIds(player)
        local ids = {}
        local inv = player and player:getInventory()
        local items = inv and inv:getItems()
        if items then
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it and it.getID then
                    ids[it:getID()] = true
                end
            end
        end
        return ids
    end

    local function beforePerform(action)
        if not action or not action.mode then return end
        local mode = action.mode

        -- Item about to be consumed by the device (HiFiTimedAction:new stores
        -- the media item as self.secondaryItem).
        if ADD_MODES[mode] then
            local item = action.secondaryItem
            if item and item.getFullType then
                _pending[action] = {
                    fullType = item:getFullType(),
                    itemId = item.getID and item:getID() or nil,
                }
            end
            return
        end

        -- Item about to be returned to the player: snapshot inventory IDs so
        -- the freshly-created client item (phantom) can be found afterwards,
        -- and copy the device slot table so CD scratch data survives.
        if REMOVE_MODES[mode] then
            local md = action.device and action.device.getModData and action.device:getModData() or nil
            local slot = nil
            if md then
                if mode == "RemoveCD" then
                    slot = md.hifiCD
                elseif mode == "RemoveCassette" then
                    slot = md.hifiTape
                else
                    slot = md.hifiVinyl
                end
            end
            if not slot then return end
            local slotCopy = {}
            for k, v in pairs(slot) do slotCopy[k] = v end
            _pending[action] = {
                idsBefore = snapshotInventoryIds(action.character),
                slotCopy = slotCopy,
            }
        end
    end

    local function afterPerform(action)
        if not action or not action.mode then return end
        local pending = _pending[action]
        _pending[action] = nil
        if not pending then return end

        local mode = action.mode
        local player = action.character
        if not player then return end

        -- AddX: the action removed the item locally; ask the server to
        -- perform the authoritative removal of its copy.
        local consumeCmd = ADD_MODES[mode]
        if consumeCmd and pending.fullType then
            sendClientCommand(player, "TM_HIFI", consumeCmd, {
                fullType = pending.fullType,
                itemId = pending.itemId,
            })
            return
        end

        -- RemoveX: the action created a client-only phantom item. Remove the
        -- phantom locally and let the server give the item authoritatively.
        local giveCmd = REMOVE_MODES[mode]
        if giveCmd then
            local inv = player:getInventory()
            local items = inv and inv:getItems()
            local phantom = nil
            if items then
                for i = items:size() - 1, 0, -1 do
                    local it = items:get(i)
                    if it and it.getID and not pending.idsBefore[it:getID()] then
                        phantom = it
                        break
                    end
                end
            end
            if not phantom then return end

            local fullType = phantom:getFullType()
            inv:Remove(phantom)

            local payload = { fullType = fullType }
            if mode == "RemoveCD" then
                payload.scratch = pending.slotCopy
            end
            sendClientCommand(player, "TM_HIFI", giveCmd, payload)

            local inventoryPane = getPlayerInventory(player:getPlayerNum())
            if inventoryPane then
                inventoryPane:refreshBackpacks()
            end
        end
    end

    -- Patch HiFiTimedAction.perform
    require "TimedActions/HiFiTimedAction"

    if HiFiTimedAction then
        local origPerform = HiFiTimedAction.perform
        HiFiTimedAction.perform = function(self)
            beforePerform(self)
            origPerform(self)
            afterPerform(self)
        end
    end
end

return HiFiMPSync
