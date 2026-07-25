-- Test that specimens with shared 'key' field are tracked together
describe("Specimen shared key", function()
    it("vinegar items share the same research key", function()
        local config1 = ZScienceSkill.Data.specimens["Base.Vinegar2"]
        local config2 = ZScienceSkill.Data.specimens["Base.Vinegar_Jug"]
        
        assert.is_table(config1, "Base.Vinegar2 should be defined")
        assert.is_table(config2, "Base.Vinegar_Jug should be defined")
        assert.eq("Base.Vinegar", config1.key)
        assert.eq("Base.Vinegar", config2.key)
    end)
    
    it("vinegar items grant Science XP", function()
        local config1 = ZScienceSkill.Data.specimens["Base.Vinegar2"]
        local config2 = ZScienceSkill.Data.specimens["Base.Vinegar_Jug"]
        
        assert.eq(20, config1.Science)
        assert.eq(20, config2.Science)
    end)
end)

describe("Specimen research with shared key", function()
    local player = get_player()
    
    before_each(function()
        clear_research_data()
    end)
    
    it("researching one vinegar marks the shared key as researched", function()
        ZScienceSkill.setResearched(player, "Base.Vinegar")
        
        -- Both items should now be considered researched
        local vinegar2 = create_item("Base.Vinegar2")
        local vinegarJug = create_item("Base.Vinegar_Jug")
        
        assert.is_true(ISResearchSpecimen.isResearched(player, vinegar2))
        assert.is_true(ISResearchSpecimen.isResearched(player, vinegarJug))
    end)
    
    it("items without shared key use fullType as research key", function()
        ZScienceSkill.setResearched(player, "Base.BakingSoda")
        
        local bakingSoda = create_item("Base.BakingSoda")
        assert.is_true(ISResearchSpecimen.isResearched(player, bakingSoda))
    end)
    
    it("unresearched vinegar is not marked as researched", function()
        local vinegar2 = create_item("Base.Vinegar2")
        assert.is_false(ISResearchSpecimen.isResearched(player, vinegar2))
    end)
end)

return ZBSpec.runAsync()
