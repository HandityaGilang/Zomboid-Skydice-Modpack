require "BasementBuilder/BasementBuilder_Core"
require "BasementBuilder/BasementBuilder_EnvironmentServer"

BasementBuilder_Server = BasementBuilder_Server or {}
local function predicateNotBroken(item)
    return item and not item:isBroken()
end

local function hasCount(playerObj, fullType, count)
    if not playerObj then return false end
    return playerObj:getInventory():getItemCount(fullType, true) >= count
end

local function getShovel(playerObj)
    return BasementBuilder.getDigTool(playerObj)
end

local function getHammer(playerObj)
    if not playerObj then return nil end
    local hammerTypes = { "Hammer", "BallPeenHammer" }
    for _, hammerType in ipairs(hammerTypes) do
        local hammer = playerObj:getInventory():getFirstTypeEvalRecurse(hammerType, predicateNotBroken)
        if hammer then
            return hammer
        end
    end
    return nil
end

local function consumeOne(playerObj, fullType)
    local item = playerObj:getInventory():getFirstTypeRecurse(fullType)
    if item then
        playerObj:getInventory():Remove(item)
        return true
    end
    return false
end

local function consumeNails(playerObj, amount)
    for _ = 1, amount do
        if not consumeOne(playerObj, "Base.Nails") then
            return false
        end
    end
    return true
end

local function damageShovel(shovel, playerObj)
    if not shovel then return end
    shovel:setCondition(math.max(0, shovel:getCondition() - 1))
    if shovel:getCondition() <= 0 then
        playerObj:getInventory():Remove(shovel)
    end
end

function BasementBuilder_Server.syncPlayer(playerObj)
    local data = BasementBuilder.getSaveData()
    local payload = {
        nextId = data.nextId or 1,
        basements = data.basements or {},
    }
    if playerObj then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "syncData", payload)
        return
    end
    sendServerCommand(BasementBuilder.MODULE, "syncData", payload)
end

function BasementBuilder_Server.onDigCommand(playerObj, args)
    if not playerObj or not args then return end
    local square = playerObj:getCell():getGridSquare(args.x, args.y, args.z)
    if not square then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "No square" })
        return
    end

    local shovel = getShovel(playerObj)
    if not shovel then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "No shovel" })
        return
    end

    if args.mode == "start" then
        if not getHammer(playerObj) then
            return
        end
        if not playerObj:getInventory():containsTypeRecurse("Base.EmptySandbag") then
            return
        end
        if not playerObj:getInventory():containsTypeRecurse("BasementBuilder.BasementStarterKit") then
            return
        end
        local valid, reason = BasementBuilder._safeCanStartBasement(square)
        if not valid then
            return
        end
        if not consumeOne(playerObj, "BasementBuilder.BasementStarterKit") then
            return
        end
        BasementBuilder.startBasement(square, args.styleId, args.palette)
        damageShovel(shovel, playerObj)
        BasementBuilder_Server.syncPlayer()
        return
    end

    local valid, basement, reason = BasementBuilder._safeCanExpandFrom(square, args.tx, args.ty)
    if not valid or not basement then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = reason })
        return
    end
    if not playerObj:getInventory():containsTypeRecurse("Base.Log") then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "Missing log" })
        return
    end
    if playerObj:getInventory():getItemCount("Base.Nails", true) < BasementBuilder.EXPAND_NAIL_COST then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "Missing nails" })
        return
    end

    if not consumeOne(playerObj, "Base.Log") then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "Consume log failed" })
        return
    end
    if not consumeNails(playerObj, BasementBuilder.EXPAND_NAIL_COST) then
        sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = false, reason = "Consume nails failed" })
        return
    end

    BasementBuilder.expandBasement(basement, args.tx, args.ty)
    damageShovel(shovel, playerObj)
    BasementBuilder_Server.syncPlayer()
    sendServerCommand(playerObj, BasementBuilder.MODULE, "expandResult", { success = true, x = args.tx, y = args.ty })
end

function BasementBuilder_Server.onClientCommand(module, command, playerObj, args)
    if module ~= BasementBuilder.MODULE then return end
    if command == "dig" then
        BasementBuilder_Server.onDigCommand(playerObj, args)
        return
    end
    if command == "sync" then
        BasementBuilder_Server.syncPlayer(playerObj)
    end
end

function BasementBuilder_Server.onGameStart()
end

Events.OnClientCommand.Add(BasementBuilder_Server.onClientCommand)
Events.OnGameStart.Add(BasementBuilder_Server.onGameStart)
