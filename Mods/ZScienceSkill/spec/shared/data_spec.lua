-- Test for ZScienceSkill/Data.lua
-- Validates data tables are correctly defined

describe(ZScienceSkill.Data.literature, function()
    it("is a table", function()
        assert.is_table(subject)
    end)
    
    it("has correct science book XP values", function()
        assert.eq(35, subject["Base.Book_Science"])
        assert.eq(30, subject["Base.Paperback_Science"])
        assert.eq(15, subject["Base.Magazine_Science"])
    end)
    
    it("gives more XP for science books than scifi", function()
        local scienceXP = subject["Base.Book_Science"]
        local scifiXP = subject["Base.Book_SciFi"]
        assert.gt(scienceXP, scifiXP, "Science books should give more XP than Sci-Fi books")
    end)
    
    it("has numbers or tables", function()
        for key, xp in pairs(subject) do
            assert.is_string(key)
            assert((type(xp) == "number" and xp > 0) or type(xp) == "table")
        end
    end)
end)

describe(ZScienceSkill.skillBookXP, function()
    it("is a table", function()
        assert.is_table(subject)
    end)
    
    it("has correct XP progression", function()
        assert.eq(10, subject[1])
        assert.eq(20, subject[3])
        assert.eq(30, subject[5])
        assert.eq(40, subject[7])
        assert.eq(50, subject[9])
    end)
    
    it("increases with level", function()
        assert.lt(subject[1], subject[3])
        assert.lt(subject[3], subject[5])
        assert.lt(subject[5], subject[7])
        assert.lt(subject[7], subject[9])
    end)
end)

describe(ZScienceSkill.Data.traits, function()
    it("is a table", function()
        assert.is_table(subject)
    end)

    it("has Herbalist required specimens count", function()
        assert.is_not_nil(subject[CharacterTrait.HERBALIST])
    end)

    it("has at least required number of Herbalist specimens", function()
        local required = subject[CharacterTrait.HERBALIST] or 10
        local count = 0

        for _, specimenCfg in pairs(ZScienceSkill.Data.specimens) do
            if type(specimenCfg) == "table" and specimenCfg.trait == CharacterTrait.HERBALIST then
                count = count + 1
            end
        end

        assert.is_true(count >= required, "Expected at least " .. required .. " specimens, found " .. count)
    end)
end)

describe(ZScienceSkill.Data.fluids, function()
    it("is a table", function()
        assert.is_table(subject)
    end)
    
    it("has Acid and Blood", function()
        assert.is_table(subject["Acid"])
        assert.is_table(subject["Blood"])
    end)
    
    it("all fluids grant positive Science XP", function()
        for fluidName, perks in pairs(subject) do
            assert.is_number(perks.Science)
            assert.gt(perks.Science, 0)
        end
    end)
    
    it("SecretFlavoring grants 200 Science XP", function()
        assert.is_not_nil(subject["SecretFlavoring"])
        assert.eq(200, subject["SecretFlavoring"].Science)
    end)
end)

return ZBSpec.runAsync()
