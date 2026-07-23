require 'MF_ISMoodle'

MoodleSystem = MoodleSystem or {}
MoodleSystem.__index = MoodleSystem

function MoodleSystem:new(table, playerNum, moodleId)
    local obj = {}
    setmetatable(obj, self)

    obj.table = table
    obj.playerNum = playerNum
    obj.moodleId = moodleId

    if getActivatedMods():contains('\\MoodleFramework') then
        MF.createMoodle(obj.moodleId)
    end

    return obj
end

function MoodleSystem:start()
    local function updateWrapper()
        self:update()
    end
    Events.OnTick.Add(updateWrapper)
    self.updateWrapper = updateWrapper
end

function MoodleSystem:stop()
    local moodle = MF.getMoodle(self.moodleId, self.playerNum)
    if moodle ~= nil then
        moodle:setValue(0.5)
    end
    if self.updateWrapper then
        Events.OnTick.Remove(self.updateWrapper)
        self.updateWrapper = nil
    end
end

function MoodleSystem:update()
end

SmokingMoodle = SmokingMoodle or {}
setmetatable(SmokingMoodle, { __index = MoodleSystem })
SmokingMoodle.__index = SmokingMoodle

function SmokingMoodle:new(table, playerNum)
    local moodleImage = TrueSmoking.Options.UseNewMoodle and 'smoking_new' or 'smoking_old'
    local obj = MoodleSystem.new(self, table, playerNum, moodleImage)
    return obj
end

function SmokingMoodle:update()
    local moodle = MF.getMoodle(self.moodleId, self.playerNum)
    if not self.table.isSmoking then return end
    if moodle == nil then return end

    local item = self.table.Smokable
    local smokeLit = item.smokeLit
    local percent = item.smokeLength / item.originalSmokeLength
    local percentVal = tonumber(percent) or 0
    local displayedPercentage = string.format('%.1f%%', percentVal * 100)

    local estimateLeft = {
        [0] = "< 1/8",
        [10] = "~ 1/8",
        [20] = "~ 2/8",
        [30] = "~ 3/8",
        [40] = "~ 4/8",
        [50] = "~ 5/8",
        [60] = "~ 6/8",
        [80] = "~ 7/8",
        [90] = "~ 8/8"
    }

    local estimate = "~"

    if TrueSmoking.Config.ShowSmokePercent then
        estimate = displayedPercentage
    else
        local highestEstimate = "~"
        for k, v in pairs(estimateLeft) do
            if percentVal * 100 >= k then
                highestEstimate = v
            end
        end
        estimate = highestEstimate
    end

    local smokeLitText = smokeLit and 'lit' or 'out'

    moodle:setThresholds(0.10, 0.20, 0.35, 0.4999, 0.5001, 0.65, 0.85, 0.90)

    -- Only wiggle once every minute if the smoke is not lit
    if not self.lastWiggleTime then
        self.lastWiggleTime = os.time()
    end

    local currentTime = os.time()
    if not smokeLit and (currentTime - self.lastWiggleTime >= 10) then
        moodle:doWiggle()
        self.lastWiggleTime = currentTime
    end

    if TrueSmoking.Config.HideMoodles then
        percentVal = 0.5
    end

    moodle:setValue(percentVal)

    local debugInfo = ""
    if TrueSmoking.Config.DebugMoodles then
        debugInfo = self:generateDebugInfo(item)
    end

    moodle:setDescription(
        moodle:getGoodBadNeutral(),
        moodle:getLevel(),
        getText('Moodles_smoking_Custom', smokeLitText, estimate) .. debugInfo
    )
end

function SmokingMoodle:generateDebugInfo(item)
    local debugText = "\n\n[DEBUG INFO]"

    debugText = debugText .. string.format("\nCurrent Length: %.2f", item.smokeLength)
    debugText = debugText .. string.format("\nOriginal Length: %.2f", item.originalSmokeLength)
    debugText = debugText .. string.format("\nRemaining: %.1f%%", (item.smokeLength / item.originalSmokeLength) * 100)
    debugText = debugText .. string.format("\nLit Status: %s", item.smokeLit and "Lit" or "Out")
    debugText = debugText .. string.format("\nPuff Percent: %.6f", item.puffPercent)

    debugText = debugText .. string.format("\n\n[Burn Parameters]")
    debugText = debugText .. string.format("\nCurrent Rate: %.8f", item.burnRate)
    debugText = debugText .. string.format("\nTarget Min: %.8f", item.burnMin)
    debugText = debugText .. string.format("\nTarget Max: %.8f", item.burnMax)
    debugText = debugText .. string.format("\nDecay Rate: %.8f", item.decayRate)
    debugText = debugText .. string.format("\nBurn Speed: %.8f", item.burnSpeed)
    debugText = debugText .. string.format("\nBurn Speed Decay: %.8f", item.burnSpeedDecay)

    debugText = debugText .. string.format("\n\n[Effect Parameters]")
    debugText = debugText .. string.format("\nEffect Multiplier: %.2f", item.effectMultiplier)
    debugText = debugText .. string.format("\nNicotine Content: %.2f", item.nicotineContent)

    debugText = debugText .. string.format("\n\n[Activity Factors]")
    debugText = debugText .. string.format("\nPuff: %.2f", item.puffFactor)
    debugText = debugText .. string.format("\nWalking: %.2f", item.walkingFactor)
    debugText = debugText .. string.format("\nRunning: %.2f", item.runningFactor)
    debugText = debugText .. string.format("\nSprinting: %.2f", item.sprintingFactor)

    debugText = debugText .. string.format("\n\n[Conditions:]")
    for condition, allowed in pairs(item.conditions) do
        debugText = debugText .. string.format("\n%s: %s", condition, allowed and "Yes" or "No")
    end

    if item.smokeLit and item.smokeLength > 0 and item.burnRate > 0 then
        local timeToFinish = item.smokeLength / item.burnRate
        local minutes = math.floor(timeToFinish / 60)
        local seconds = math.floor(timeToFinish % 60)
        debugText = debugText .. string.format("\n\n[Time Estimates]")
        debugText = debugText .. string.format("\nEstimated time left: ~%dm %ds", minutes, seconds)

        local gameMinutes = timeToFinish / (60 * getGameTime():getMinutesPerDay() * getGameSpeed())
        if gameMinutes > 0 then
            debugText = debugText .. string.format("\nReal time: ~%.1f minutes", gameMinutes)
        end
    end

    debugText = debugText .. string.format("\n\n[Item Info]")
    debugText = debugText .. string.format("\nItem Type: %s", item.fullType or "Unknown")
    debugText = debugText .. string.format("\nOnEat Method: %s", item.onEat)
    debugText = debugText .. string.format("\nReplaceOnUse: %s", tostring(item.replaceOnUse))

    return debugText
end

NicotineMoodle = NicotineMoodle or {}
setmetatable(NicotineMoodle, { __index = MoodleSystem })
NicotineMoodle.__index = NicotineMoodle

function NicotineMoodle:new(table, playerNum)
    local obj = MoodleSystem.new(self, table, playerNum, "nicotine")
    obj.player = getSpecificPlayer(playerNum)
    return obj
end

function NicotineMoodle:update()
    local player = self.player
    if not player or not player:getModData().nicotineSystem then return end

    local data = player:getModData().nicotineSystem
    local moodle = MF.getMoodle(self.moodleId, self.playerNum)
    if not moodle then return end

    local shouldShow = TrueSmoking.Config.DebugMoodles or (data.withdrawalLevel > 20 and data.nicotineLevel < 10)
    local hideMoodles = TrueSmoking.Config.HideMoodles or TrueSmoking.Config.HideAddictionMoodle

    local moodleValue = 0.5  -- default = hidden/neutral

    if shouldShow and not hideMoodles then
        local withdrawalNorm = math.min(data.withdrawalLevel / 100.0, 1.0)
        moodleValue = 1.0 - withdrawalNorm  -- 1.0 = no withdrawal (green), 0.0 = max (red)
    end

    moodle:setThresholds(0.10, 0.20, 0.35, 0.4999, 0.5001, 0.65, 0.85, 0.90)
    moodle:setValue(moodleValue)

    if shouldShow and not hideMoodles then
        local addiction = data.addictionLevel
        local titleText = ""

        if addiction >= 87.5 then
            titleText = getText("Moodles_nicotine_Bad_lvl4")       -- Extremely
        elseif addiction >= 75 then
            titleText = getText("Moodles_nicotine_Bad_lvl3")       -- Severely
        elseif addiction >= 62.5 then
            titleText = getText("Moodles_nicotine_Bad_lvl2")       -- Heavily
        elseif addiction >= 50 then
            titleText = getText("Moodles_nicotine_Bad_lvl1")       -- Strongly
        elseif addiction >= 37.5 then
            titleText = getText("Moodles_nicotine_Good_lvl1")      -- Moderately
        elseif addiction >= 25 then
            titleText = getText("Moodles_nicotine_Good_lvl2")      -- Mild
        elseif addiction >= 12.5 then
            titleText = getText("Moodles_nicotine_Good_lvl3")      -- Slightly
        else
            titleText = getText("Moodles_nicotine_Good_lvl4")      -- No Addiction
        end

        local level = moodle:getLevel()
        local gbn = moodle:getGoodBadNeutral()
        if level > 0 and gbn ~= 0 then
            moodle:setTitle(gbn, level, titleText)
        end

        local descText = ""
        if data.withdrawalLevel >= 80 then
            descText = getText("Moodles_nicotine_withdrawal_4")
        elseif data.withdrawalLevel >= 60 then
            descText = getText("Moodles_nicotine_withdrawal_3")
        elseif data.withdrawalLevel >= 40 then
            descText = getText("Moodles_nicotine_withdrawal_2")
        elseif data.withdrawalLevel >= 20 then
            descText = getText("Moodles_nicotine_withdrawal_1")
        else
            descText = getText("Moodles_nicotine_withdrawal_0")
        end

        local debugInfo = ""
        if TrueSmoking.Config.DebugMoodles then
            debugInfo = self:generateDebugInfo(data)
        end

        moodle:setDescription(gbn, level, descText .. debugInfo)

        if data.withdrawalLevel >= 60 and (not self.lastWiggle or os.time() - self.lastWiggle > 30) then
            moodle:doWiggle()
            self.lastWiggle = os.time()
        end
    end
end

function NicotineMoodle:generateDebugInfo(data)
    local debugText = "\n\n[DEBUG INFO]"

    debugText = debugText .. "\n[Nicotine]"
    debugText = debugText .. string.format("\nLevel: %.2f%%", data.nicotineLevel)
    debugText = debugText .. string.format("\nNicotine Time: %.1f hours", data.nicotineTime)
    debugText = debugText .. string.format("\nNicotine Overflow: %.2f%%", data.nicotineOverflow)
    debugText = debugText .. "\n\n[Addiction]"
    debugText = debugText .. string.format("\nLevel: %.3f", data.addictionLevel)
    debugText = debugText .. string.format("\nAddiction Time: %.1f days", data.AddictionTime)

    debugText = debugText .. "\n\n[Withdrawal]"
    debugText = debugText .. string.format("\nWithdrawal Level: %.1f%%", data.withdrawalLevel)

    debugText = debugText .. "\n\n[Stats]"
    debugText = debugText .. string.format("\nUnhappiness Cap: %.2f", data.unhappinessCap)
    debugText = debugText .. string.format("\nBoredom Cap: %.2f", data.boredomCap)

    return debugText
end

function NicotineMoodle:getAddictionRecoveryText()
    local player = self.player
    if not player or not player:getModData().nicotineSystem then return "" end

    local data = player:getModData().nicotineSystem

    local level = data.withdrawalLevel
    if level >= 80 then
        return getText("Moodles_nicotine_withdrawal_4")
    elseif level >= 60 then
        return getText("Moodles_nicotine_withdrawal_3")
    elseif level >= 40 then
        return getText("Moodles_nicotine_withdrawal_2")
    elseif level >= 20 then
        return getText("Moodles_nicotine_withdrawal_1")
    elseif level >= 0 then
        return getText("Moodles_nicotine_withdrawal_0")
    end

    return ""
end