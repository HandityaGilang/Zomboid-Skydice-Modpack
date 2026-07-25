describe(ZScienceSkill.isCombatPerk, function()
    it("detects Combat perk", function()
        assert.is_true(subject(Perks.Combat))
    end)
    
    it("detects Firearm perk", function()
        assert.is_true(subject(Perks.Firearm))
    end)

    it("detects Axe perk", function()
        assert.is_true(subject(Perks.Axe))
    end)
    
    it("rejects non-Combat perk", function()
        assert.is_false(subject(Perks.Woodwork))
    end)
end)

describe(ZScienceSkill.getSpecimenResearchKey, function()
    it("returns nil for nil", function()
        assert.is_nil(subject(nil))
    end)

    it("proxies the key for non-alieased or undefined keys", function()
        assert.eq("foo.bar", subject("foo.bar"))
        assert.eq("Base.AnimalBrain", subject("Base.AnimalBrain"))
    end)
    
    it("returns common key for aliased items", function()
        assert.eq("Base.Vinegar", subject("Base.Vinegar2"))
        assert.eq("Base.Vinegar", subject("Base.Vinegar_Jug"))
        assert.eq("Base.Vinegar", subject("Base.Vinegar")) -- not defined in data but should still work
    end)
end)

describe(ZScienceSkill.getItemStatus, function()
    local ITEM_ID = "Base.Dung_Pig"
    local func = subject

    context("with non-researchable item", function()
        it("returns nil", function()
            local item = ScriptManager.instance:getItem("Base.Shoes_Black")
            assert.is_nil(func(item))
        end)
    end)

    context("without player", function()
        it("returns item(s) without 'researched' status", function()
            local item = ScriptManager.instance:getItem(ITEM_ID)
            local expected = {
                data = {
                    {type = "specimen"}
                },
                total = 1
            }
            assert.same(expected, func(item))
        end)
    end)

    context("with player", function()
        local player = get_player()
        local specimen

        before_all(function()
            set_timed_action_instant(true)
            place_microscope(player)
            init_player()
            clear_research_data(player)
            specimen = add_item(player, ITEM_ID)
        end)

        context("when item is not researched", function()
            it("returns item(s) with researched=false", function()
                local expected = {
                    data = {
                        {type = "specimen", researched = false}
                    },
                    total = 1,
                    researched = 0,
                }
                assert.same(expected, func(specimen, player))
            end)
        end)

        context("when item is researched", function()
            before_each(function()
                research_specimen(player, specimen)
            end)
            it("returns item(s) with researched=false", function()
                local expected = {
                    data = {
                        {type = "specimen", researched = true}
                    },
                    total = 1,
                    researched = 1,
                }
                assert.same(expected, func(specimen, player))
            end)
        end)
    end)
end)

return ZBSpec.runAsync()
