describe(ISResearchSpecimen, function()
    before_each(function()
        clear_research_data()
    end)

    after_each(function()
        clear_research_data()
    end)

    describe(".isSpecimen", function()
        it("identifies Cricket as a specimen", function()
            local cricket = create_item("Base.Cricket")
            assert.is_not_nil(cricket)
            assert.is_true(described_class.isSpecimen(cricket))
        end)
        
        it("does not identify Axe as a specimen", function()
            local axe = create_item("Base.Axe")
            assert.is_not_nil(axe)
            assert.is_false(described_class.isSpecimen(axe))
        end)
    end)

    describe(".isResearched", function()
        local player = getPlayer()
        
        it("returns false for a new specimen", function()
            local specimen = create_item("Base.Specimen_Brain")
            assert.is_not_nil(specimen)
            
            assert.is_false(described_class.isResearched(player, specimen))
        end)
        
        it("returns true after marking a specimen as researched", function()
            local specimen = create_item("Base.Specimen_Brain")
            assert.is_not_nil(specimen)
            
            local pzsData = ZScienceSkill.getPlayerZSData(player)
            pzsData.researchedSpecimens = pzsData.researchedSpecimens or {}
            pzsData.researchedSpecimens[specimen:getFullType()] = true
            
            assert.is_true(described_class.isResearched(player, specimen))
        end)
    end)
end)

return ZBSpec.runAsync()
