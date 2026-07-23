-- Register SkillBook["Tinkering"] at file load time for client-side UI.
-- Server registration is in TinkeringSkill_XPSystem.lua (server/).
-- SkillBook is created by vanilla XPSystem_SkillBook.lua (server/); on client
-- it may not exist yet, so we guard with 'or {}'. This entry is needed for
-- ISInventoryPane / ISLiteratureUI to display the correct perk name.
SkillBook = SkillBook or {}
if not SkillBook["Tinkering"] then
    SkillBook["Tinkering"] = {
        perk           = Perks.Tinkering,
        maxMultiplier1 = 3,
        maxMultiplier2 = 5,
        maxMultiplier3 = 8,
        maxMultiplier4 = 12,
        maxMultiplier5 = 16,
    }
end
