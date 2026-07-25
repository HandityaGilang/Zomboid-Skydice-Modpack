-- Client-side integration tests for fluid research
-- Tests researching items containing fluids (bleach, blood, etc.)

describe("Fluid research", function()
    local player = get_player()
    
    before_all(function()
        set_timed_action_instant(true)
        place_microscope(player)
    end)
    
    before_each(function()
        init_player(player)
        clear_research_data(player)
    end)
    
    describe("Base.Bleach", function()
        it("grants Science XP", function()
            local bleach = add_item(player, subject) -- bottle of bleach
            local xpBefore = player:getXp():getXP(Perks.Science)
            
            -- Verify it's recognized as a fluid specimen
            assert(ISResearchSpecimen.isSpecimen(bleach), "Bleach should be a specimen")
            
            local fluidType = ZScienceSkill.getFluidType(bleach)
            assert.eq("Bleach", fluidType)
            
            research_specimen(player, bleach)
            
            wait_for(function()
                return player:getXp():getXP(Perks.Science) > xpBefore
            end)
        end)
        
        it("marks fluid as researched", function()
            local bleach = add_item(player, subject)
            
            assert.is_false(ISResearchSpecimen.isResearched(player, bleach))
            
            research_specimen(player, bleach)
            
            wait_for(function()
                return ISResearchSpecimen.isResearched(player, bleach)
            end)
        end)
        
        it("cannot research same fluid type twice", function()
            local bleach1 = add_item(player, subject)
            local xpBefore = player:getXp():getXP(Perks.Science)
            
            research_specimen(player, bleach1)
            wait_for(function()
                return player:getXp():getXP(Perks.Science) > xpBefore
            end)
            
            local xpAfterFirst = player:getXp():getXP(Perks.Science)
            
            -- Add another bleach and try to research
            local bleach2 = add_item(player, subject)
            
            -- Should already be marked as researched
            assert.is_true(ISResearchSpecimen.isResearched(player, bleach2))
        end)

        it("does not consider empty bottle as a specimen", function()
            local bleach = add_item(player, subject)
            bleach:getFluidContainer():Empty()
            wait_for_this(bleach:getFluidContainer(), "isEmpty")

            assert.is_false(ISResearchSpecimen.isSpecimen(bleach), "Empty bottle should not be a specimen")
        end)

        it("does not consider water in a bleach bottle as a specimen", function()
            local bleach = add_item(player, subject)
            bleach:getFluidContainer():Empty()
            wait_for_this(bleach:getFluidContainer(), "isEmpty")

            bleach:getFluidContainer():addFluid(FluidType.Water, 1)
            assert.is_false(bleach:getFluidContainer():isEmpty())
            assert.is_false(ISResearchSpecimen.isSpecimen(bleach), "Empty bottle should not be a specimen")
        end)
    end)
end)

return ZBSpec.runAsync()
