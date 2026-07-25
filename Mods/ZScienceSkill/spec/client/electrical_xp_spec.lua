-- Test for ZScienceSkill_ElectricalXP.lua
-- Verifies Science XP is granted when gaining Electrical XP

local function dismantle_radio(player, item)
    local scriptMgr = getScriptManager()
    assert(scriptMgr, "ScriptManager not found")

    local recipe = scriptMgr:getCraftRecipe("DismantleRadio") or scriptMgr:getCraftRecipe("DismantleElectronicsDevice") -- changed in 42.14
    assert(recipe, "Recipe not found")

    local playerNum = player:getPlayerNum()

    ISInventoryPaneContextMenu.OnNewCraft(item, recipe, playerNum, false)
    ZBSpec.wait_for_not(ISTimedActionQueue.isPlayerDoingAction, player)
end

describe("Electrical XP synergy", function()
    local player = get_player()

    before_all(function()
        set_timed_action_instant(true)
        add_item(player, "Base.Screwdriver")
        -- TODO: find reliable way to get more Electircal XP in test and remove ZScienceSkill.minGain
        all_exec("ZScienceSkill.minGain=0")
    end)
    
    it("grants Science XP when gaining Electrical XP", function()
        local scienceBefore = player:getXp():getXP(Perks.Science)
        local electricalBefore = player:getXp():getXP(Perks.Electricity)

        local radio = add_item(player, "Base.RadioBlack")
        dismantle_radio(player, radio) -- Should gain some Science XP (50% of Electrical)
        wait_for(function()
            return player:getXp():getXP(Perks.Electricity) > electricalBefore
        end)
        
        wait_for(function()
            return player:getXp():getXP(Perks.Science) > scienceBefore
        end)
    end)
end)

return ZBSpec.runAsync()
