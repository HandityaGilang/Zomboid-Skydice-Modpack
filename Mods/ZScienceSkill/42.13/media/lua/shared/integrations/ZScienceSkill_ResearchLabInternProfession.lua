-- Add Science XP boost to Lab Intern profession (ResearchLabInternProfession) when that mod is present.
-- Runs on game boot so the character creation screen shows Science in the profession's XP boosts.

local SCIENCE_BOOST_LEVEL = 2

local function patchLabInternProfession()
    print("[ZScienceSkill] patching Lab Intern profession")

    if not RLP or not RLP.CharacterProfession or not RLP.CharacterProfession.LAB_INTERN then return end
    if not CharacterProfessionDefinition or not CharacterProfessionDefinition.getCharacterProfessionDefinition then return end
    if not Perks or not Perks.Science then return end

    local profDef = CharacterProfessionDefinition.getCharacterProfessionDefinition(RLP.CharacterProfession.LAB_INTERN)
    if not profDef then return end

    if profDef.addXPBoost then
        pcall(function() profDef:addXPBoost(Perks.Science, SCIENCE_BOOST_LEVEL) end)
        if BaseGameCharacterDetails and BaseGameCharacterDetails.SetProfessionDescription then
            pcall(function() BaseGameCharacterDetails.SetProfessionDescription(profDef) end)
        end
    end
end

Events.OnGameBoot.Add(patchLabInternProfession)
