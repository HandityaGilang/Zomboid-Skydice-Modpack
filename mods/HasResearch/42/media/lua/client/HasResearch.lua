local HasResearch = {
    ---@type IsoPlayer
    player = nil,
    ---@type ItemContainer
    inventory = nil,
    texture = getTexture("media/ui/HasResearch.png")
}

---Cache player and inventory
---@param playerIndex integer
---@param player IsoPlayer
HasResearch.OnCreatePlayer = function(playerIndex, player)
    HasResearch.player = player
    HasResearch.inventory = player:getInventory()
end

---@param player IsoPlayer
---@param item InventoryItem
HasResearch.isTarget = function(player, item)
    local researcheableRecipes = item:getScriptItem():getResearchableRecipes(player, true)
    return researcheableRecipes and researcheableRecipes:size() > 0
end

HasResearch.InventoryPaneRenderDetails = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
    HasResearch.InventoryPaneRenderDetails(self, doDragged)

    local y = 0
    local player = getSpecificPlayer(self.player)
    local MOUSEX = self:getMouseX()
    local MOUSEY = self:getMouseY()
    local YSCROLL = self:getYScroll()
    local HEIGHT = self:getHeight()

    for _, v in ipairs(self.itemslist) do
        local count = 1
        for _, v2 in ipairs(v.items) do
            ---@type InventoryItem
            local item = v2
            if HasResearch.isTarget(player, item) and count == 1 then
                local doIt = true
				local xoff = 0
				local yoff = 0
				local isDragging = false
				if self.dragging ~= nil and self.selected[y+1] ~= nil and self.dragStarted then
					xoff = MOUSEX - self.draggingX
					yoff = MOUSEY - self.draggingY
					if not doDragged then
						doIt = false
					else
						isDragging = true
					end
				else
					if doDragged then
						doIt = false
					end
				end

                local topOfItem = y * self.itemHgt + YSCROLL
				if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
					doIt = false
				end

                if doIt == true then
					local tex = item:getTex()
					if tex ~= nil then
						local texWH = math.min(self.itemHgt-2,32)
                        if count == 1  then
							self:drawTexture(HasResearch.texture, xoff+7, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 1, 1, 1, 1)
						elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y+1) - (count-1)] == nil) then
							self:drawTexture(HasResearch.texture, xoff+7, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 0.3, 1, 1, 1)
						end
					end
				end
            end
            y = y + 1
            if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
                break
            end
            if count == 51 then
                break
            end
            count = count + 1
        end
    end
end

-- Hooks
Events.OnCreatePlayer.Add(HasResearch.OnCreatePlayer)