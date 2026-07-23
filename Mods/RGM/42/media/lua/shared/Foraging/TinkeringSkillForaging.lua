
-- B42: forageSkills table must be initialized before writing to it
local function registerTinkererTraitInForageSkills()
    forageSkills = forageSkills or {}
    forageSkills.tinkerer = {
        name            = "rgm:reforger",
        type            = "trait",
        visionBonus     = 0,
        weatherEffect   = 0,
        darknessEffect  = 0,
        specialisations = {
            ["Trash"]       = 30,
            ["Junk"]        = 30,
            ["JunkWeapons"] = 30,
        },
    }
    forageSkills.loodoman = {
        name            = "Loodoman",
        type            = "trait",
        visionBonus     = 0,
        weatherEffect   = 0,
        darknessEffect  = 0,
        specialisations = {
            ["Trash"]       = 30,
            ["Junk"]        = 30,
            ["JunkWeapons"] = 30,
        },
    }
end

Events.preAddSkillDefs.Add(registerTinkererTraitInForageSkills)
