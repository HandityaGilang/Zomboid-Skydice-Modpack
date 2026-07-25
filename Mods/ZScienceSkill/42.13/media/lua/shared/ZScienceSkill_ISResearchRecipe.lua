-- Speed up recipe research and grant Science XP based on Science perk level

require "TimedActions/ISResearchRecipe"

-- Speed up research based on Science level (5% per level)
local originalGetDuration = ISResearchRecipe.getDuration

function ISResearchRecipe:getDuration()
    local time = originalGetDuration(self)
    
    local scienceLevel = self.character:getPerkLevel(Perks.Science)
    if scienceLevel > 0 then
        local speedBonus = 1 - (scienceLevel * 0.05)  -- 5% per level, up to 50% at level 10
        time = time * speedBonus
    end
    
    return time
end

-- Grant Science XP when completing recipe research
local originalComplete = ISResearchRecipe.complete

function ISResearchRecipe:complete()
    local result = originalComplete(self)
    
    -- XP scales with recipe complexity
    local maxSkillReq = 0
    if self.scriptItem then
        local researchList = self.scriptItem:getResearchableRecipes(self.character, true)
        if researchList and researchList:size() > 0 then
            for i = 0, researchList:size() - 1 do
                local recipe = researchList:get(i)
                if ScriptManager.instance:getCraftRecipe(recipe) then
                    local craftRecipe = ScriptManager.instance:getCraftRecipe(recipe)
                    if craftRecipe then
                        local skillReq = craftRecipe:getHighestSkillRequirement() or 0
                        if skillReq > maxSkillReq then
                            maxSkillReq = skillReq
                        end
                    end
                end
            end
        end
    end
    
    local xp = 15 + (maxSkillReq * 5)
    addXp(self.character, Perks.Science, xp)
    
    return result
end
