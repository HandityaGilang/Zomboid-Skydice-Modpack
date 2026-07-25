-- Medical treatment bonuses based on Science skill
-- Improves bandage effectiveness and treatment speed
-- in /shared because vanilla timed actions are in /shared

require "TimedActions/ISApplyBandage"
require "TimedActions/ISDisinfect"
require "TimedActions/ISSplint"

-- Bandage effectiveness bonus: +5% per Science level
local originalBandageComplete = ISApplyBandage.complete
function ISApplyBandage:complete()
    local result = originalBandageComplete(self)
    
    if result and self.doIt then  -- doIt = applying (not removing)
        local scienceLevel = self.character:getPerkLevel(Perks.Science)
        if scienceLevel > 0 then
            local currentLife = self.bodyPart:getBandageLife()
            if currentLife > 0 then
                local scienceBonus = scienceLevel * 0.05  -- +5% per level
                self.bodyPart:setBandageLife(currentLife * (1 + scienceBonus))
            end
        end
    end
    
    return result
end

-- Bandage speed bonus: 3% faster per Science level
local originalBandageGetDuration = ISApplyBandage.getDuration
function ISApplyBandage:getDuration()
    local baseTime = originalBandageGetDuration(self)
    local scienceLevel = self.character:getPerkLevel(Perks.Science)
    local scienceMultiplier = 1 - (scienceLevel * 0.03)
    return baseTime * scienceMultiplier
end


-- Disinfect speed bonus: 3% faster per Science level
local originalDisinfectGetDuration = ISDisinfect.getDuration
function ISDisinfect:getDuration()
    local baseTime = originalDisinfectGetDuration(self)
    local scienceLevel = self.character:getPerkLevel(Perks.Science)
    local scienceMultiplier = 1 - (scienceLevel * 0.03)
    return baseTime * scienceMultiplier
end


-- Splint speed bonus: 3% faster per Science level
local originalSplintGetDuration = ISSplint.getDuration
function ISSplint:getDuration()
    local baseTime = originalSplintGetDuration(self)
    local scienceLevel = self.character:getPerkLevel(Perks.Science)
    local scienceMultiplier = 1 - (scienceLevel * 0.03)
    return baseTime * scienceMultiplier
end
