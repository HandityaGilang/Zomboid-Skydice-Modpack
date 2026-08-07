local old_ISCheckTrapActioncomplete = ISCheckTrapAction.complete

function ISCheckTrapAction:complete()
	local trap = STrapSystem.instance:getLuaObjectAt(self.trap.x, self.trap.y, self.trap.z)
    if trap and trap.trapType == "Hold.BaitHive" then
        local item = instanceItem(trap.animal.item)

        if trap.player == self.character:getUsername() then
            addXp(self.character, Perks.Trapping, 10)
        end

        if isServer() then
            self.character:getInventory():AddItem(item)
            sendAddItemToContainer(self.character:getInventory(), item)
        else
            self.character:getInventory():AddItem(item)
        end

        trap:clearAnimalAndChangeSprite()
    else
        old_ISCheckTrapActioncomplete(self)
    end
end
