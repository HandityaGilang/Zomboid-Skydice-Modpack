--//////////////////////////////////////////////////--
--    Reactive Sound Events - Archetypes / Loot Rules
--    Defines rules for SubKit probability by Category
--//////////////////////////////////////////////////--

local ReactiveSE_Archetypes = {}

-- These rules govern which SubKits (Food, Water, etc.) can spawn.
local ARCHETYPE_RULES = {
    CIVILIAN = {
        allowedSubKits = { "Food", "Water", "Tools", "MeleeWeapon", "Medicine", "Vice" },
        subKitChances = {
            Food = 60,
            Water = 50,
            Tools = 20,
            MeleeWeapon = 30,
            Medicine = 20,
            Vice = 40
        }
    },
    SURVIVOR = {
        allowedSubKits = { "Food", "Water", "Tools", "MeleeWeapon", "Medicine", "Vice" },
        subKitChances = {
            Food = 80,
            Water = 80,
            Tools = 70,
            MeleeWeapon = 70,
            Medicine = 60,
            Vice = 20
        }
    },
    BANDIT = {
        allowedSubKits = { "Food", "Water", "MeleeWeapon", "Medicine", "Vice" },
        subKitChances = {
            Food = 20,
            Water = 30,
            MeleeWeapon = 80,
            Medicine = 10,
            Vice = 80
        }
    },
    AUTHORITY = {
        allowedSubKits = { "Food", "Water", "MeleeWeapon", "Medicine", "Vice" },
        subKitChances = {
            Food = 40,
            Water = 80,
            MeleeWeapon = 60,
            Medicine = 70,
            Vice = 10
        }
    },
    MILITARY = {
        allowedSubKits = { "Food", "Water", "MeleeWeapon", "Medicine" },
        subKitChances = {
            Food = 50,
            Water = 100,
            MeleeWeapon = 100,
            Medicine = 80
        }
    }
}

---Gets the rules for a specific category
---@param category string
---@return table
function ReactiveSE_Archetypes.GetRules(category)
    return ARCHETYPE_RULES[category] or ARCHETYPE_RULES.CIVILIAN
end

return ReactiveSE_Archetypes
