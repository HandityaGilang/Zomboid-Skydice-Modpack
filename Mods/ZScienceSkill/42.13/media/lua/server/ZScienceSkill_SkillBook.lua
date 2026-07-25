-- HAS to be in server/ because shared/ is loaded BEFORE server/
-- and vanilla server/XpSystem/XPSystem_SkillBook.lua that is loaded AFTER shared/
-- sets SkillBook = {}

-- client still gets SkillBook["Science"] defined

SkillBook["Science"] = {}
SkillBook["Science"].perk = Perks.Science
SkillBook["Science"].maxMultiplier1 = 3
SkillBook["Science"].maxMultiplier2 = 5
SkillBook["Science"].maxMultiplier3 = 8
SkillBook["Science"].maxMultiplier4 = 12
SkillBook["Science"].maxMultiplier5 = 16
