require "TimedActions/ISReadABook"

local M13_ReadABook_RWW = ISReadABook.new
local M13_ReadABook_PSM = ISReadABook.getDuration

-- Does a character stop reading when they move?
function ISReadABook:new(character, item, time)
    local o = M13_ReadABook_RWW(self, character, item, time)
    local sandboxVars = SandboxVars.M13ReadingTweaks or {}
    o.stopOnWalk = not sandboxVars.RWW
    return o
end

-- Is a character sitting? Shorten Reading time.
function ISReadABook:getDuration()
    local time = M13_ReadABook_PSM(self)
    local sandboxVars = SandboxVars.M13ReadingTweaks or {}
    local PSM = sandboxVars.PSM or 1.0
    
    if self.character:isSitOnGround() or self.character:isSittingOnFurniture() or self.character:isSeatedInVehicle() and PSM ~= 1.0 then
        time = time / PSM
    end
    
    return time;
end