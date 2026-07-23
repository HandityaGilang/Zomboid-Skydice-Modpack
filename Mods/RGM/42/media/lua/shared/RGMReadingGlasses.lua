require "TimedActions/ISReadABook"

-- Applies reading speed bonus from "Book Worm" glasses.
-- B42: ISReadABook controls duration via getDuration().

local function RGM_getReadingSpeedMult(character)
    if not character then return 1 end
    local worn = type(character.getWornItems) == "function" and character:getWornItems()
    if not worn then return 1 end
    local mult = 1
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        local item  = entry and type(entry.getItem) == "function" and entry:getItem()
        if item then
            local mod = item:getModData().modifier
            if mod and mod.statsMultipliers then
                local rs = mod.statsMultipliers["reading speed"]
                if rs and rs > 1 then mult = mult * rs end
            end
        end
    end
    return mult
end

if ISReadABook and ISReadABook.getDuration then
    local _origGetDuration = ISReadABook.getDuration
    function ISReadABook:getDuration()
        local duration = _origGetDuration(self)
        local speedMult = RGM_getReadingSpeedMult(self.character or self.chr)
        if speedMult > 1 and duration and duration > 1 then
            return math.max(1, math.floor(duration / speedMult + 0.5))
        end
        return duration
    end
end
