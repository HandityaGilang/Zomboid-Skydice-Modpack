describe(ISReadABook, function()
    local player = get_player()

    it("has shorter duration for skillbooks", function()
        local book = create_item("Base.BookFirstAid1")

        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, book, 1):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, book, 1):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, book, 1):getDuration()

        assert(dur10 < dur05)
        assert(dur05 < dur00)
    end)

    it("has same duration for regular books", function()
        local book = create_item("Base.Book")

        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, book, 1):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, book, 1):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, book, 1):getDuration()

        assert(dur10 == dur05)
        assert(dur05 == dur00)
    end)
end)

return ZBSpec.runAsync()
