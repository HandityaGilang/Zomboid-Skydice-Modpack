describe("Base.Book_Science", function()
    local player = get_player()

    before_all(function()
        set_sandbox_option("MinutesPerPage", 0.001)
        set_timed_action_instant(false) -- breaks skillbooks reading in SP
    end)

    before_each(function()
        init_player(player)
    end)
    
    it("grants Science XP", function()
        local book = add_item(player, subject)
        local xpBefore = player:getXp():getXP(Perks.Science)

        read_book(player, book)
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore
        end)
    end)
    
    it("grants more XP than scifi book", function()
        -- Read science book
        local sciBook = add_item(player, subject)
        local xpBefore1 = player:getXp():getXP(Perks.Science)

        read_book(player, sciBook)
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore1
        end)

        -- Read scifi book
        local sciFiBook = add_item(player, "Base.Book_SciFi")
        local xpBefore2 = player:getXp():getXP(Perks.Science)

        read_book(player, sciFiBook)
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore2
        end)

        local scienceXP = xpBefore2 - xpBefore1
        local scifiXP   = player:getXp():getXP(Perks.Science) - xpBefore2

        assert.gt(scienceXP, scifiXP)
    end)
    
    it("does not grant infinite XP", function()
        local book = add_item(player, subject)
        local xpBefore = player:getXp():getXP(Perks.Science)

        read_book(player, book) -- first time, grants XP
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore
        end)

        xpBefore = player:getXp():getXP(Perks.Science)
        for i = 1, 5 do
            read_book(player, book) -- same book again
            assert.eq(xpBefore, player:getXp():getXP(Perks.Science)) -- no xp
        end
    end)
end)

describe("Base.BookMechanic1", function()
    local player = get_player()

    before_each(function()
        init_player(player)
    end)
    
    it("grants Science XP", function()
        local book = add_item(player, subject)
        local xpBefore = player:getXp():getXP(Perks.Science)

        reset_pages(player, book)
        read_book(player, book)
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore
        end)
    end)
    
    it("does not grant infinite XP", function()
        local book = add_item(player, subject)
        local xpBefore = player:getXp():getXP(Perks.Science)

        reset_pages(player, book)
        read_book(player, book) -- first time, grants XP
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore
        end)

        xpBefore = player:getXp():getXP(Perks.Science)
        for i = 1, 5 do
            read_book(player, book) -- same book again
            assert.eq(xpBefore, player:getXp():getXP(Perks.Science)) -- no xp
        end
    end)
end)

return ZBSpec.runAsync()
