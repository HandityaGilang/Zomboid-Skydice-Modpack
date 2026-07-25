describe("addXp for Science perk", function()
    local player = get_player()
    
    before_each(function()
        init_player(player)
    end)
    
    it("works without error", function()
        local xpBefore = player:getXp():getXP(Perks.Science)
        assert(xpBefore, "should not be nil")
        
        -- This should not throw NullPointerException
        addXp(player, Perks.Science, 50)
        
        local xpAfter = player:getXp():getXP(Perks.Science)
        assert.gt(xpAfter, xpBefore)
    end)
end)

return ZBSpec.runAsync()
