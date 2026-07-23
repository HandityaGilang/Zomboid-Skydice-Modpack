--[[
    Add instant equip time for the visual smoke
]]
local originalNew = ISUnequipAction.new
function ISUnequipAction:new(character, item, maxTime)
    local o = originalNew(self, character, item, maxTime)

    local playerRef = TrueSmoking:getPlayerReference(character)

    if item:getBodyLocation() == "Mask_Smoke" and playerRef.isSmoking then
        o.maxTime = 1
    end

    return o
end

--[[
    If the player somehow unequips the visual smoke we need to put the smoke out
]]
local originalComplete = ISUnequipAction.complete
function ISUnequipAction:complete()
    originalComplete(self)

    local playerRef = TrueSmoking:getPlayerReference(self.character)

    if self.item:getBodyLocation() == "Mask_Smoke" and playerRef.isSmoking then
        playerRef.Smokable:putOut()
    end

    return true
end
