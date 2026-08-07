require "TimedActions/ISReadABook"

local M13_ISReadABook_new = ISReadABook.new

function ISReadABook:new(character, item, time)
    local o = M13_ISReadABook_new(self, character, item, time)
    o.minutesPerPage = SandboxVars.M13ReadingTweaks.MPP or 1.0
    o.stopOnWalk = (not SandboxVars.M13ReadingTweaks.RWW)

    local numPages
        if item:getNumberOfPages() > 0 then
            ISReadABook.checkLevel(character, item)
            item:setAlreadyReadPages(character:getAlreadyReadPages(item:getFullType()))
            o.startPage = item:getAlreadyReadPages()
            numPages = item:getNumberOfPages()
        else
            numPages = 5
    end

    local f = 1 / getGameTime():getMinutesPerDay() / 2
    time = numPages * o.minutesPerPage / f

    if(character:HasTrait("FastReader")) then
        time = time * 0.7
    end
    if(character:HasTrait("SlowReader")) then
        time = time * 1.3
    end

    o.maxTime = time
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end
    
    return o
end

local M13_ISReadABook_new = ISReadABook.new
local M13_ISReadABook_IsValid = ISReadABook.isValid
local M13_ISReadABook_Stop = ISReadABook.stop

function ISReadABook:isValid(...)
	return (M13_ISReadABook_IsValid(self, ...) == true
		and (self.maxTime == 1
		 or  self.character:isSitOnGround() == self.M13["SitMod"]))
end

function ISReadABook:stop(...)
	local SitOnGround = M13_ISReadABook_Stop(self, ...)
        if self.maxTime ~= 1 then
            local characterIsSitOnGround = self.character:isSitOnGround()
                if		characterIsSitOnGround ~= self.M13["SitMod"]
                and characterIsSitOnGround then
                ISTimedActionQueue.add(ISReadABook:new(self.character, self.item, self.initialTime))
            end
	end
	return SitOnGround
end

function ISReadABook:new(character, item, time, ...)
	local SitMultiplier = M13_ISReadABook_new(self, character, item, time, ...)
	if SitMultiplier.maxTime ~= 1 then
		local PlayerSits = character:isSitOnGround()
		SitMultiplier.M13 = {
				["SitMod"] = PlayerSits
			}
		if PlayerSits then
			SitMultiplier.maxTime = math.floor(SitMultiplier.maxTime / SandboxVars.M13ReadingTweaks.PSM)
		end
	end
	return SitMultiplier
end