--[[
    Added time param
]]
local originalNew = ISClothingExtraAction.new
function ISClothingExtraAction:new(character, item, extra, time)
    local o = originalNew(self, character, item, extra)
    o.maxTime = time and time or 1
    return o
end