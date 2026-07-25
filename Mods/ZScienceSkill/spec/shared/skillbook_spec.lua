describe(SkillBook.Science, function()
    it("is a table", function()
        assert.is_table(subject)
    end)

    it("has a perk", function()
        assert.eq(Perks.Science, subject.perk)
    end)

    it("has multipliers", function()
        assert.eq(3, subject.maxMultiplier1)
        assert.eq(5, subject.maxMultiplier2)
        assert.eq(8, subject.maxMultiplier3)
        assert.eq(12, subject.maxMultiplier4)
        assert.eq(16, subject.maxMultiplier5)
    end)
end)

return ZBSpec.runAsync()
