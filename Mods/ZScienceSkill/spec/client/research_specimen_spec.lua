-- Client-side integration tests for ISResearchSpecimen
-- Tests the full research flow with player actions

describe(ISResearchSpecimen, function()
    local player = get_player()
    
    before_all(function()
        set_timed_action_instant(true)
        place_microscope(player)
    end)
    
    before_each(function()
        init_player(player)
        clear_research_data(player)
    end)
    
    describe("researching a specimen", function()
        it("grants Science XP for Cricket", function()
            local specimen = add_item(player, "Base.Cricket")
            local xpBefore = player:getXp():getXP(Perks.Science)
            
            research_specimen(player, specimen)
            
            wait_for(function()
                return player:getXp():getXP(Perks.Science) > xpBefore
            end)
        end)
        
        it("marks specimen as researched in ModData", function()
            local specimen = add_item(player, "Base.Cricket")
            
            assert.is_false(described_class.isResearched(player, specimen))
            
            research_specimen(player, specimen)
            
            wait_for(function()
                return described_class.isResearched(player, specimen)
            end)
        end)
        
        it("cannot research same specimen twice", function()
            local specimen = add_item(player, "Base.Cricket")
            local xpBefore = player:getXp():getXP(Perks.Science)
            
            research_specimen(player, specimen)
            wait_for(function()
                return player:getXp():getXP(Perks.Science) > xpBefore
            end)
            
            -- Get XP after first research
            local xpAfterFirst = player:getXp():getXP(Perks.Science)
            
            -- Add another cricket and try to research
            local specimen2 = add_item(player, "Base.Cricket")
            research_specimen(player, specimen2)
            
            -- XP should not increase (already researched this type)
            assert.eq(xpAfterFirst, player:getXp():getXP(Perks.Science))
        end)
    end)
    
    describe("researching dung specimens", function()
        it("grants Tracking XP for dung", function()
            local dung = add_item(player, "Base.Dung_Deer")
            local trackingBefore = player:getXp():getXP(Perks.Tracking)
            
            research_specimen(player, dung)
            
            wait_for(function()
                return player:getXp():getXP(Perks.Tracking) > trackingBefore
            end)
        end)
    end)
    
    describe("researching pills", function()
        it("grants Doctor XP for pills", function()
            local pills = add_item(player, "Base.PillsAntiDep")
            local doctorBefore = player:getXp():getXP(Perks.Doctor)
            
            research_specimen(player, pills)
            
            wait_for(function()
                return player:getXp():getXP(Perks.Doctor) > doctorBefore
            end)
        end)
    end)
end)

return ZBSpec.runAsync()
