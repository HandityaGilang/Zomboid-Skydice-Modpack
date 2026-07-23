-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

local painDialogue = {
    "Ouch!",
    "Ow!",
    "Ahh!",
    "Oof!",
    "Agh!",
    "Ugh!",
    "Argh!",
}

-- ---@param bagInv ItemContainer
-- ---@return boolean
-- local function searchForTinOpenerInBag(bagInv)
--     local bagItems = bagInv:getItems()
--     for i=0, bagItems:size()-1 do
--         local bagItem = bagItems:get(i)
--         if bagItem:getType() == "TinOpener" then
--             return true
--         end
--     end
--     return false
-- end

-- ---@param playerObj IsoPlayer
-- ---@return boolean
-- local function searchForTinOpener(playerObj)
--     local inventory = playerObj:getInventory()
--     local invItems = inventory and inventory:getItems()
--     for i=0, invItems:size()-1 do
--         local invItem = invItems:get(i)
--         if not instanceof(invItem, "InventoryContainer") then
--             if invItem:getType() == "TinOpener" then
--                 return true
--             end
--         else
--             --- @cast invItem InventoryContainer
--             if searchForTinOpenerInBag(invItem:getInventory()) then
--                 return true
--             end
--         end
--     end
--     return false
-- end

local ISHandcraftActionComplete = ISHandcraftAction.complete
function ISHandcraftAction:complete()

    if string.match(self.craftRecipe:getName(), "CSOpen") 
    and self.craftRecipe:getName():contains("WithAnyTool") then

        local playerObj = getPlayer()
        -- if searchForTinOpener(playerObj) then
        --     ISHandcraftActionComplete(self)
        --     return
        -- end

        if ZombRand(100)+1 <= SandboxVars.CommonSense.CanWoundChance then
            
            local randomIndex = ZombRand(#painDialogue) + 1
            playerObj:Say(painDialogue[randomIndex]) --[[@diagnostic disable-line: undefined-field]]
            playerObj:getEmitter():playSound("KitchenKnifeHit")

            local bodyDamage = playerObj:getBodyDamage()
            bodyDamage:ReduceGeneralHealth(8 * 0.25) -- fixed value for CanWoundIntensity

            local bodyParts = bodyDamage:getBodyParts()
            for i=0, BodyPartType.ToIndex(BodyPartType.MAX)-1 do
                local bodyPart = bodyParts:get(i)
                if bodyPart:getType() == BodyPartType.Hand_R then
                    bodyPart:setBleedingTime(1)
                end
            end
        end
    end
    ISHandcraftActionComplete(self)
end