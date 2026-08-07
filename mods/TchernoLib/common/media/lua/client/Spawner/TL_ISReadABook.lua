
local ul_ISReadABookupdate = ISReadABook.update
function ISReadABook:update()
    if self and self.item and self.item:getFullType() == 'Base.FakeBook' and self.character then
        local itemType = self.item:getModData()[Spawn.SpawnKey]
        self.character:getInventory():AddItem(itemType or 'Base.FakeBook')--TODO extract item from mod data
        self:stop()
        self.item:Use()
        self.character:Say(getText("IGUI_FakeBook_Open"))
    else
        ul_ISReadABookupdate(self)
    end
end