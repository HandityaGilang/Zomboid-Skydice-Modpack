require "TimedActions/ISReadABook"


local M13_ISReadABook_new = ISReadABook.new
local M13_ISReadABook_isValid = ISReadABook.isValid
local M13_ISReadABook_stop = ISReadABook.stop

function adjustReadingTime(o)
    local sandboxVars = SandboxVars.M13ReadingTweaks or {}
    local PSM = sandboxVars.PSM or 1.0

    if o.character:isSitOnGround() or o.character:isSittingOnFurniture() then
        o.maxTime = math.floor(o.maxTime / PSM)
    end
end

function ISReadABook:new(character, item, time)
    local o = M13_ISReadABook_new(self, character, item, time)
    local sandboxVars = SandboxVars.M13ReadingTweaks or {}
    o.stopOnWalk = not sandboxVars.RWW
    o.M13 = {
        SitOnGround = character:isSitOnGround(),
        SitOnFurniture = character:isSittingOnFurniture(),
    }
    adjustReadingTime(o)
    return o
end

function ISReadABook:isValid()
    local currentSitOnGround = self.character:isSitOnGround()
    local currentSitOnFurniture = self.character:isSittingOnFurniture()
    if self.maxTime ~= 1 and 
       (currentSitOnGround ~= self.M13.SitOnGround or currentSitOnFurniture ~= self.M13.SitOnFurniture) then
        self.M13.SitOnGround = currentSitOnGround
        self.M13.SitOnFurniture = currentSitOnFurniture
        adjustReadingTime(self)
    end

    return M13_ISReadABook_isValid(self)
end

function ISReadABook:stop()
    M13_ISReadABook_stop(self)

    if self.maxTime ~= 1 then
        local currentSitOnGround = self.character:isSitOnGround()
        local currentSitOnFurniture = self.character:isSittingOnFurniture()
        if currentSitOnGround ~= self.M13.SitOnGround or currentSitOnFurniture ~= self.M13.SitOnFurniture then
            self.M13.SitOnGround = currentSitOnGround
            self.M13.SitOnFurniture = currentSitOnFurniture
            adjustReadingTime(self)
            ISTimedActionQueue.add(ISReadABook:new(self.character, self.item, self.initialTime))
        end
    end
end