-- Speed up skill book reading based on Science perk level
-- Each Science level reduces reading time by 5% (up to 50% at level 10)

require "TimedActions/ISReadABook"

local originalGetDuration = ISReadABook.getDuration

function ISReadABook:getDuration()
    local time = originalGetDuration(self)
    
    -- Only apply bonus to skill books
    if SkillBook and SkillBook[self.item:getSkillTrained()] then
        local scienceLevel = self.character:getPerkLevel(Perks.Science)
        if scienceLevel > 0 then
            local speedBonus = 1 - (scienceLevel * 0.05)  -- 5% per level
            time = time * speedBonus
        end
    end
    
    return time
end
