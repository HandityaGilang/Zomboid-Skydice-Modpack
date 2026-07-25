-- Client-side integration tests for Herbalist unlock
-- Research 10 unique plants to unlock the Herbalist perk

-- Plants that count toward Herbalist unlock
local HERBALIST_PLANTS = {
    "Base.BerryBlack",
    "Base.BerryBlue",
    "Base.MushroomsButton",
    "Base.Comfrey",
    "Base.Ginseng",
    "Base.Plantain",
    "Base.Dandelions",
    "Base.Nettles",
    "Base.Rosehips",
    "Base.Thistle",
}

describe("Herbalist unlock", function()
    local player = get_player()
    
    before_all(function()
        set_timed_action_instant(true)
        place_microscope(player)
    end)
    
    before_each(function()
        init_player(player)
        clear_research_data(player)
        -- Remove Herbalist trait/recipe if present
        all_exec("(getPlayer() or getOnlinePlayers():get(0)):getKnownRecipes():remove('Herbalist')")
        all_exec("(getPlayer() or getOnlinePlayers():get(0)):getCharacterTraits():remove(CharacterTrait.HERBALIST)")
    end)
    
    it("does not unlock Herbalist with 9 plants", function()
        -- Research 9 plants
        for i = 1, 9 do
            local plant = add_item(player, HERBALIST_PLANTS[i])
            research_specimen(player, plant)
            wait_for(ISResearchSpecimen.isResearched, player, plant)
        end
        
        -- Should NOT have Herbalist yet
        assert.is_false(player:isRecipeActuallyKnown("Herbalist"))
    end)
    
    it("unlocks Herbalist after researching 10 unique plants", function()
        -- Research all 10 plants
        for i = 1, 10 do
            local plant = add_item(player, HERBALIST_PLANTS[i])
            research_specimen(player, plant)
            wait_for(ISResearchSpecimen.isResearched, player, plant)
        end
        
        -- Should have Herbalist now
        wait_for(player.isRecipeActuallyKnown, player, "Herbalist")
        
        -- Should also have the trait
        assert.is_true(player:hasTrait(CharacterTrait.HERBALIST))
    end)
    
    it("tracks plant count in ModData", function()
        for i = 1, 5 do
            local plant = add_item(player, HERBALIST_PLANTS[i])
            research_specimen(player, plant)
            wait_for(ISResearchSpecimen.isResearched, player, plant)
        end
        
        -- All 5 plants should be tracked
        local plants = player:getModData().ZScienceSkill.researchedPlants
        for i = 1, 5 do
            assert.is_true(plants[HERBALIST_PLANTS[i]])
        end
    end)
    
    it("does not count non-plant specimens toward Herbalist", function()
        local cricket = add_item(player, "Base.Cricket")
        research_specimen(player, cricket)
        wait_for(ISResearchSpecimen.isResearched, player, cricket)
        
        -- Cricket is not a plant, so researchedPlants should be empty
        assert.eq(nil, player:getModData().researchedPlants)
    end)
end)

return ZBSpec.runAsync()
