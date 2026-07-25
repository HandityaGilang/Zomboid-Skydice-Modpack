-- Test for ZScienceSkill_XPBoost.lua
-- Verifies skill XP boost is applied correctly

local function carve_spear(player, item)
    local recipe = getScriptManager():getCraftRecipe("CarveSpear")
    local playerNum = player:getPlayerNum()

    ISInventoryPaneContextMenu.OnNewCraft(item, recipe, playerNum, false)
    ZBSpec.wait_for_not(ISTimedActionQueue.isPlayerDoingAction, player)
end

describe("XP boost", function()
    local player = get_player()

    before_all(function()
        init_player()
        set_timed_action_instant(true)
        add_item(player, "Base.HuntingKnife")
        all_exec("ZScienceSkill.minGain=0")
    end)

    after_all(function()
        set_perk_level(player, Perks.Science, 0)
    end)
    
    it("increases skill XP gain with higher Science level", function()
        local function make(level, min_diff)
            set_perk_level(player, Perks.Science, level)

            local xpBefore = player:getXp():getXP(Perks.Carving)
            local stick = add_item(player, "Base.LongStick")
            carve_spear(player, stick)
            wait_for(function()
                return player:getXp():getXP(Perks.Carving) - xpBefore > min_diff
            end)
            return player:getXp():getXP(Perks.Carving) - xpBefore
        end

        local xp0 = make( 0, 0)
        local xp5 = make( 5, xp0)
        local xpA = make(10, xp5)
    end)
end)

return ZBSpec.runAsync()
