-- Grant Science XP when gaining Electrical XP
require 'ZSS_Fix_Events'

if isClient() then return end

ZScienceSkill = ZScienceSkill or {}
ZScienceSkill.minGain = 1

local function onAddXP(character, perk, amount)
    if perk == Perks.Electricity and amount >= ZScienceSkill.minGain then
        local scienceXP = amount * 0.5
        if scienceXP >= ZScienceSkill.minGain then
            addXp(character, Perks.Science, scienceXP)
        end
    end
end

ZSS_Fix_Events.AddXP.Add(onAddXP)
