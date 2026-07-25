describe(ISResearchRecipe, function()
    it("has shorter duration with higher Science skill", function()
        local player = get_player()
        local item = create_item("Base.ScrapMetal")

        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, item):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, item):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, item):getDuration()

        assert(dur10 < dur05)
        assert(dur05 < dur00)
    end)
end)

return ZBSpec.runAsync()
