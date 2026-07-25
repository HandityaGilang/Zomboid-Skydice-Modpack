-- Test that Science perk is properly defined and can receive XP
describe(Perks.Science, function()
    it("exists in Perks table", function()
        assert.is_not_nil(subject)
    end)
    
    it("can be retrieved from PerkFactory", function()
        local perk = PerkFactory.getPerk(subject)
        assert.is_not_nil(perk)
    end)
    
    it("has correct parent (Crafting)", function()
        local perk = PerkFactory.getPerk(subject)
        assert.eq(Perks.Crafting, perk:getParent())
    end)
end)

describe("Science XP multiplier sandbox option", function()
    it("exists", function()
        local option = getSandboxOptions():getOptionByName("MultiplierConfig.Science")
        assert.is_not_nil(option, "MultiplierConfig.Science sandbox option must exist for addXp to work")
    end)
    
    it("has default value of 1.0", function()
        local option = getSandboxOptions():getOptionByName("MultiplierConfig.Science")
        assert.eq(1.0, option:getValue())
    end)
end)

return ZBSpec.runAsync()
