TacPHold = TacPHold or {}
TacPHold.activeMasks = {}

local RIGHT_MASK = "TacPistolRight"
local LEFT_MASK  = "TacPistolLeft"

local function clearTacMasks(player)
    if not player then return end

    if player:getVariableString("RightHandMask") == RIGHT_MASK then
        player:clearVariable("RightHandMask")
    end

    if player:getVariableString("LeftHandMask") == LEFT_MASK then
        player:clearVariable("LeftHandMask")
    end

    TacPHold.activeMasks[player] = nil
end


local function tacHold(player)
    if not player or player:isDead() or player:isAsleep() then
        return
    end

    local maskActive = TacPHold.activeMasks[player]

if player:isAiming() then
    local startTime = getGameTime():getWorldAgeHours()

    local function delayedClear()
        local currentTime = getGameTime():getWorldAgeHours()
        local elapsedSeconds = (currentTime - startTime) * 3600

        if elapsedSeconds >= 4 then
            if maskActive then
                clearTacMasks(player)
            end
            Events.OnTick.Remove(delayedClear)
        end
    end

    Events.OnTick.Add(delayedClear)
    return
end
	
	if player:isSneaking() then
    if maskActive then
        clearTacMasks(player)
    end
    return
end
	
	if player:isSprinting() then
    if maskActive then
        clearTacMasks(player)
    end
    return
end

 local queue = ISTimedActionQueue.queues[player]
if queue and queue.queue and #queue.queue > 0 then
    if maskActive then
        clearTacMasks(player)
    end
    return
end

    local primary   = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if secondary then
        if player:getVariableString("LeftHandMask") == LEFT_MASK then
            player:clearVariable("LeftHandMask")
        end
    end

    if primary and instanceof(primary, "HandWeapon") then
        if primary:isRanged() and not primary:isTwoHandWeapon() then

            if player:getVariableString("RightHandMask") ~= RIGHT_MASK then
                player:setVariable("RightHandMask", RIGHT_MASK)
            end

            if not secondary then
                if player:getVariableString("LeftHandMask") ~= LEFT_MASK then
                    player:setVariable("LeftHandMask", LEFT_MASK)
                end
            end

            TacPHold.activeMasks[player] = true
            return
        end
    end

    if maskActive then
        clearTacMasks(player)
    end
end


local curPlayer = 0

local function tacHoldMP(player)
    if not player or player:isDead() or player:isAsleep() then
        return
    end

    tacHold(player)

    local players = getOnlinePlayers()
    if not players or players:size() == 0 then
        return
    end

    if curPlayer >= players:size() then
        curPlayer = 0
    end

    local mPlayer = players:get(curPlayer)

    if mPlayer and mPlayer ~= player then
        tacHold(mPlayer)
    end

    curPlayer = curPlayer + 1
end


local function TacPHoldInit()
    print(getText("UI_Init_TacHold"))

    if isServer() then
        return
    end

    local function onPlayerUpdate(player)
        if isClient() then
            tacHoldMP(player)
        else
            tacHold(player)
        end
    end

    Events.OnGameStart.Add(function()
        Events.OnPlayerUpdate.Add(onPlayerUpdate)
    end)
end

TacPHoldInit()