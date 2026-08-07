-- Thigs doesn't work through script, so we do this

local function setupMutualExclusiveTraits()

    local exclusives = {
        CharacterTrait.COWARDLY,
        CharacterTrait.BRAVE,
        CharacterTrait.HEMOPHOBIC,
        CharacterTrait.CLAUSTROPHOBIC,
        CharacterTrait.AGORAPHOBIC,
    }

    for _, vanillaTrait in ipairs(exclusives) do
        CharacterTraitDefinition.setMutualExclusive(
            PK42.CharacterTrait.PSYCHOPATH,
            vanillaTrait
        )
    end
end

Events.OnGameBoot.Add(setupMutualExclusiveTraits)

-- ==========================================
-- A failed attempt turn the trait point cost into a sandbox variable
-- ==========================================
--[[
local function setupPsychopathTrait()
    local opts = SandboxVars.PK42
    local cost = opts and opts.TraitCost or 10

    CharacterTraitDefinition.addCharacterTraitDefinition(
        PK42.CharacterTrait.PSYCHOPATH,
        "UI_trait_psychopath",
        cost,
        "UI_trait_psychopathDesc",
        false,  -- isProfessionTrait
        false   -- disabledInMultiplayer
    )

    -- XP boosts
    local def = CharacterTraitDefinition.getCharacterTraitDefinition(PK42.CharacterTrait.PSYCHOPATH)
    if def then
        def:addXPBoost(Perks.SmallBlade, 3)
        def:addXPBoost(Perks.SmallBlunt, 1)
        def:addXPBoost(Perks.Axe, 2)
        def:addXPBoost(Perks.Blunt, 1)
        def:addXPBoost(Perks.LongBlade, 1)

        -- exclusões mútuas
        CharacterTraitDefinition.setMutualExclusive(PK42.CharacterTrait.PSYCHOPATH, CharacterTrait.HEMOPHOBIC)
        CharacterTraitDefinition.setMutualExclusive(PK42.CharacterTrait.PSYCHOPATH, CharacterTrait.COWARDLY)
        CharacterTraitDefinition.setMutualExclusive(PK42.CharacterTrait.PSYCHOPATH, CharacterTrait.BRAVE)
    end
end

Events.OnGameBoot.Add(setupPsychopathTrait)
]]

