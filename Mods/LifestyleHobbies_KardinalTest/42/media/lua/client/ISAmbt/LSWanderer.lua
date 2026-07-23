--------------------------------------------------------------------------------------------------
--        ----      |              |            |         |                |    --    |      ----            --
--        ----      |              |            |         |                |    --       |      ----            --
--        ----      |        -------       -----|     ---------        -----          -      ----       -------
--        ----      |            ---            |         -----        ------        --      ----            --
--        ----      |            ---            |         -----        -------          ---      ----            --
--        ----      |        -------       ----------     -----        -------         ---      ----       -------
--            |      |        -------            |         -----        -------         ---          |            --
--            |      |        -------            |          -----        -------         ---          |            --
--------------------------------------------------------------------------------------------------

require 'ISAmbt/AmbtMng'
require 'ISUI/Maps/ISWorldMap'
require 'Helper/MovementUtil'
require 'LifestyleCore/LSK_Scheduler'

--ambt.goal1 - string or float / your first goal
--ambt.goal1progress - boolean or float / progress on your first goal. If goal is a string then goal progress must return a boolean (true if satisfied)
--ambt.reset - if true then all progress will reset if the player disables this ambition mid-progress
--LSAmbtMng.doComplete(player, ambt) - call when your ambition conditions are satisfied

local LSAMBTWEvent = {
    false,
    2,
    false,
}

local wandDelay
local wandCount = 0
local wanderTickRegistered = false
local LSWOnMove

local function removeWanderTick()
    if wanderTickRegistered or LSAMBTWEvent[1] then
        LSKScheduler.remove("ambition-wanderer")
    end
    wanderTickRegistered = false
    LSAMBTWEvent[1] = false
end

local function wandTimerPerform()
    if not wandDelay then return false; end
    if wandCount > wandDelay then wandCount = 0; return true; end
    wandCount = wandCount + getGameTime():getGameWorldSecondsSinceLastUpdate()
    return false
end

local function LSAmbtActiveComplete(player, ambt)
    local LSMovUtil = require('Helper/MovementUtil')
    if LSMovUtil.isRunning then return; end
    LSMovUtil.setRunning(true)
end

local function LSAmbtComplete(player, ambt)
    if not player:hasTrait(CharacterTrait.OUTDOORSMAN) then
        --player:getTraits():add("Outdoorsman")
        sendClientCommand(player, "LSK", "ChangeTrait", {"OUTDOORSMAN", "add"})
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), true, HaloTextHelper.getColorGreen())
    end
    local playerWeight = player:getMaxWeightBase()
    if not ambt.newWeight or (not LSAMBTWEvent[3] and playerWeight ~= ambt.newWeight) or playerWeight < ambt.newWeight then 
        ambt.newWeight = playerWeight+LSAMBTWEvent[2]
        if isClient() then sendClientCommand(player, "LSK", "ChangeMaxWeight", {ambt.newWeight}); else player:setMaxWeightBase(ambt.newWeight); end
        LSAMBTWEvent[3] = true
        return
    end
end

local function playerMovedAway(pX, pY, x, y)
    if not pX or not pY or not x or not y then return false; end
    if pX > x+1 or pX < x-1 or pY > y+1 or pY < y-1 then
        local diffX, diffY = math.floor(math.abs(pX-x)), math.floor(math.abs(pY-y))
        return math.min(10, diffX+diffY)
    end
    return false
end

LSWOnMove = function() -- OnPlayerMove Event not firing in b42 mp
    if wandTimerPerform() then
    local player = getPlayer()
    if not player or player:isDead() then removeWanderTick(); return; end
    if player:getVehicle() or not player:isPlayerMoving() then return; end
    local ambitions = player:getModData().Ambitions
    local ambt = ambitions and ambitions['LSWanderer']
    if not ambt or ambt.completed or not ambt.isActive then removeWanderTick(); return; end
    if not ambt or not ambt['goal1progress'] then return; end
    local pX, pY = player:getX(), player:getY()
    local steps = playerMovedAway(pX, pY, ambt.ogX, ambt.ogY)
    if not ambt.ogX or not ambt.ogY or steps then
        steps = steps or 1
        ambt['goal1progress'] = math.ceil(ambt['goal1progress']+steps); ambt.ogX = pX; ambt.ogY = pY
    end
    --[[
    if not ambt.ogSqr or player:getSquare() ~= ambt.ogSqr then
        ambt['goal1progress'] = math.ceil(ambt['goal1progress']+1); ambt.ogSqr = player:getSquare()
    end
    ]]--
    --[[
    local addMeters, isRunning = 0, "walking"
    if player:isRunning() then isRunning = "running"; end
    print("Player moving at "..tostring(player:getMoveSpeed()).." and is "..isRunning)
    ]]--
    end
end

local function LSAmbtActiveIncomplete(player, ambt)
    if not player:isAsleep() then 
        local completed = true
        if not ambt['goal1progress'] then ambt['goal1progress'] = 0; end
        if ambt['goal1progress'] < ambt['goal1'] then completed = false; end
        if completed then LSAmbtMng.doComplete(player, ambt); return; end
        if not wanderTickRegistered then
            LSKScheduler.remove("ambition-wanderer")
            LSKScheduler.register("ambition-wanderer", LSKScheduler.LANES.NORMAL, LSWOnMove)
            wanderTickRegistered = true
            LSAMBTWEvent[1] = true
        end
    end
end

local function disableEventsCheck(player, ambt)
    if ambt.completed or not ambt.isActive then removeWanderTick(); end
end

LSAmbtMng.LSWanderer = function(player, ambt)
    disableEventsCheck(player, ambt)
    if ambt.completed then -- ambition was completed
        if ambt.isActive then LSAmbtActiveComplete(player, ambt); end --has active bonuses
        LSAmbtComplete(player, ambt)
    elseif ambt.isActive or ambt.isPassive then LSAmbtActiveIncomplete(player, ambt); end -- ambition is in progress
end

local function setDelay()
    removeWanderTick()
    wandDelay = 5/(tonumber(GTLSCheck) or 1)

end

Events.OnGameStart.Add(setDelay)
Events.OnMainMenuEnter.Add(removeWanderTick)