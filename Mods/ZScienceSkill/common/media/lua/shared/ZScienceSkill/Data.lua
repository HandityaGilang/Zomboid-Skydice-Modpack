ZScienceSkill = ZScienceSkill or {}

ZScienceSkill.Data = {
    fluids                     = {},
    literature                 = {},
    literatureReadOnce         = {},
    specimens                  = {},
    traits                     = {}, -- CharacterTrait => N required specimens to unlock
    profPreResearchedSpecimens = {}, -- [profession id] = { research key, ... } pre-filled for profession integrations
}

ZScienceSkill.NON_PERK_KEYWORDS = {
    key   = true,
    trait = true,
}

function ZScienceSkill.Data.add(tables)
    for data_key, values_tbl in pairs(tables) do
        if ZScienceSkill.Data[data_key] then
            for k, v in pairs(values_tbl) do
                ZScienceSkill.Data[data_key][k] = v
            end
        else
            print("ZScienceSkill.Data.add: target not found for key: " .. data_key)
        end
    end
end

-- Skill book XP by level (any skill book grants small Science XP)
ZScienceSkill.skillBookXP = {
    [1] = 10,  -- Vol. 1
    [3] = 20,  -- Vol. 2
    [5] = 30,  -- Vol. 3
    [7] = 40,  -- Vol. 4
    [9] = 50,  -- Vol. 5
}
