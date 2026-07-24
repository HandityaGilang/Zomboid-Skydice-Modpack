--[[
    HiFiMPSync.lua
    Multiplayer sync for all 3 HiFi media slots (CD, Cassette, Vinyl).
    Mirrors TMItemMPSync pattern: server-authoritative give/consume.
]]

local HiFiMPSync = {}

------------------------------------------------------------
-- SERVER SIDE
------------------------------------------------------------
if isServer() or isCoopHost() then

    local function onClientCommand(module, command, player, args)
        if module ~= "TM_HIFI" then return end

        local inv = player:getInventory()

        if command == "giveCD" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                inv:AddItem(fullType)
                player:getInventory():setDrawDirty(true)
            end

        elseif command == "consumeCD" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                local item = inv:getFirstTypeRecurse(fullType)
                if item then inv:Remove(item) end
            end

        elseif command == "giveTape" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                inv:AddItem(fullType)
                player:getInventory():setDrawDirty(true)
            end

        elseif command == "consumeTape" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                local item = inv:getFirstTypeRecurse(fullType)
                if item then inv:Remove(item) end
            end

        elseif command == "giveVinyl" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                inv:AddItem(fullType)
                player:getInventory():setDrawDirty(true)
            end

        elseif command == "consumeVinyl" then
            local fullType = args.fullType
            if fullType and fullType ~= "" then
                local item = inv:getFirstTypeRecurse(fullType)
                if item then inv:Remove(item) end
            end

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

    -- Hook into HiFiTimedAction to capture item before action removes it
    local _capturedItems = {}

    local function beforePerform(action)
        if not action or not action.mode then return end
        local mode = action.mode

        -- Capture the item that's about to be consumed (AddCD, AddCassette, AddVinyl)
        if mode == "AddCD" or mode == "AddCassette" or mode == "AddVinyl" then
            if action.mediaItem then
                _capturedItems[action] = action.mediaItem:getFullType()
            end
        end

        -- Capture item that will be returned (RemoveCD, RemoveCassette, RemoveVinyl)
        if mode == "RemoveCD" then
            local md = action.deviceObj and action.deviceObj:getModData()
            if md and md.hifiCD then
                _capturedItems[action] = md.hifiCD
            end
        elseif mode == "RemoveCassette" then
            local md = action.deviceObj and action.deviceObj:getModData()
            if md and md.hifiTape then
                _capturedItems[action] = md.hifiTape
            end
        elseif mode == "RemoveVinyl" then
            local md = action.deviceObj and action.deviceObj:getModData()
            if md and md.hifiVinyl then
                _capturedItems[action] = md.hifiVinyl
            end
        end
    end

    local function afterPerform(action)
        if not action or not action.mode then return end
        local mode = action.mode
        local player = action.character
        local captured = _capturedItems[action]
        _capturedItems[action] = nil

        if not captured or captured == "" then return end
        if not player then return end

        -- AddCD/AddCassette/AddVinyl: client already removed item from inventory;
        -- ask server to also consume it (the client action did it optimistically)
        if mode == "AddCD" then
            sendClientCommand(player, "TM_HIFI", "consumeCD", { fullType = captured })

        elseif mode == "AddCassette" then
            sendClientCommand(player, "TM_HIFI", "consumeTape", { fullType = captured })

        elseif mode == "AddVinyl" then
            sendClientCommand(player, "TM_HIFI", "consumeVinyl", { fullType = captured })

        -- RemoveCD/RemoveCassette/RemoveVinyl: client added item optimistically;
        -- remove the phantom and let server give it authoritatively
        elseif mode == "RemoveCD" then
            local phantom = player:getInventory():getFirstTypeRecurse(captured)
            if phantom then player:getInventory():Remove(phantom) end
            sendClientCommand(player, "TM_HIFI", "giveCD", { fullType = captured })

        elseif mode == "RemoveCassette" then
            local phantom = player:getInventory():getFirstTypeRecurse(captured)
            if phantom then player:getInventory():Remove(phantom) end
            sendClientCommand(player, "TM_HIFI", "giveTape", { fullType = captured })

        elseif mode == "RemoveVinyl" then
            local phantom = player:getInventory():getFirstTypeRecurse(captured)
            if phantom then player:getInventory():Remove(phantom) end
            sendClientCommand(player, "TM_HIFI", "giveVinyl", { fullType = captured })
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
