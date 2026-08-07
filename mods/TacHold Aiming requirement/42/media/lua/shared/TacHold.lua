TacHold = TacHold or {}
TacHold.activeMasks = {}

local function tacHold(player)
    if not player or player:isDead() or player:isAsleep() then
        return
    end

    local maskActive = TacHold.activeMasks[player]

    if player:isAiming() then
        if maskActive then
            player:clearVariable("RightHandMask")
            TacHold.activeMasks[player] = nil
        end
        return
    end

    if player:getPerkLevel(Perks.Aiming) < 3 then
        if maskActive then
            player:clearVariable("RightHandMask")
            TacHold.activeMasks[player] = nil
        end
        return
    end
    local queue = ISTimedActionQueue.queues[player]
    if queue then
        local firstAction = queue.queue[1]
        if firstAction and firstAction:isValid() and not firstAction.THIgnore then
            if maskActive then
                player:clearVariable("RightHandMask")
                TacHold.activeMasks[player] = nil
            end
            return
        end
    end

    local primary   = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if primary and primary == secondary then
        if instanceof(primary, "HandWeapon") and primary:isRanged() then
            player:setVariable("RightHandMask", "TacGunPose")
            TacHold.activeMasks[player] = true -- mark that we set it
            return
        end
    end

    if maskActive then
        player:clearVariable("RightHandMask")
        TacHold.activeMasks[player] = nil
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

local function TacHoldInit()
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

TacHoldInit()