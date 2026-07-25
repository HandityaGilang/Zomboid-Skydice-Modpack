local function research_recipe(player, item)
    ISTimedActionQueue.add(ISResearchRecipe:new(player, item))
    ZBSpec.wait_for_not(ISTimedActionQueue.isPlayerDoingAction, player)
end

describe(ISResearchRecipe, function()
    local player = get_player()

    before_all(function()
        set_timed_action_instant(true)
    end)

    before_each(function()
        init_player(player)
    end)
    
    it("grants Science XP", function()
        local filter = add_item(player, "Base.GasmaskFilter")
        local xpBefore = player:getXp():getXP(Perks.Science)

        research_recipe(player, filter)
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > xpBefore
        end)
    end)
end)

return ZBSpec.runAsync()
