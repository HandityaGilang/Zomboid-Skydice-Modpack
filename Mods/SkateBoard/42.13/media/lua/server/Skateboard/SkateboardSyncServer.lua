require("Skateboard/SkateboardCore")

if isClient() then
    return
end

local Core = Skateboard.Core

local Bridge = {}
Bridge[Core.SyncModule] = {}
local lastKnownStateById = {}

---@param player IsoPlayer
---@param args table
---@return table|nil
local function buildState(player, args)
    if not (player and args) then
        return nil
    end

    return {
        id = player:getOnlineID(),
        active = args.active,
        held = args.held,
        rolling = args.rolling,
        toHandPlayed = args.toHandPlayed,
        walkSpeed = args.walkSpeed,
        runSpeed = args.runSpeed,
        speed = args.speed,
        ollie = args.ollie,
        ollieStarted = args.ollieStarted
    }
end

---@param player IsoPlayer
---@param args table
---@return nil
Bridge[Core.SyncModule].SetActive = function(player, args)
    local id = player and player:getOnlineID() or nil
    if not id then
        return
    end

    sendServerCommand(Core.SyncModule, "SetActive", {
        id = id,
        active = args.active
    })
    if lastKnownStateById[id] then
        lastKnownStateById[id].active = args.active
    end
end

---@param player IsoPlayer
---@param args table
---@return nil
Bridge[Core.SyncModule].SetState = function(player, args)
    local state = buildState(player, args)
    if not state then
        return
    end

    sendServerCommand(Core.SyncModule, "SetState", state)
    lastKnownStateById[state.id] = state
end

---@param player IsoPlayer
---@param args table
---@return nil
Bridge[Core.SyncModule].Sound = function(player, args)
    sendServerCommand(Core.SyncModule, "Sound", {
        id = player:getOnlineID(),
        sound = args.sound,
        playing = args.playing
    })
end

---@param player IsoPlayer
---@param args table
---@return nil
Bridge[Core.SyncModule].RequestState = function(player, args)
    for _, state in pairs(lastKnownStateById) do
        sendServerCommand(Core.SyncModule, "SetState", state)
    end
end

---@param player IsoPlayer
---@param args table
---@return nil
Bridge[Core.SyncModule].EquipSkateboard = function(player, args)
    local itemId = args and args.itemId
    if not itemId then
        return
    end

    local item = player:getInventory():getItemWithID(itemId)
    if not item then
        return
    end

    player:setPrimaryHandItem(item)
    player:setSecondaryHandItem(item)
    sendEquip(player)
end

---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
---@return nil
local function handleClientCommand(module, command, player, args)
    local modTable = Bridge[module]
    if modTable and modTable[command] then
        modTable[command](player, args)
    end
end

Events.OnClientCommand.Add(handleClientCommand)
