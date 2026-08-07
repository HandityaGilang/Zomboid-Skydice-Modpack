require "TimedActions/ISWashYourself"

local TABAS_Patches = {}

TABAS_Patches.applied = false

local old_complete = ISWashYourself.complete

local function washYourSelf_complete(self)
    local result = old_complete(self)

    local md = self.character:getModData()
    local bodyGrime = md.tabas_BodyGrime or 0

	if bodyGrime >= 10 then
		local amount = SandboxVars.TakeABathAndShower.WashSelfRemoveGrimeAmount
		if amount > 0 then
			md.tabas_BodyGrime = math.max(0, round(bodyGrime - amount, 2))
			self.character:transmitModData()
		end
	end

    return result
end

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end

    if SandboxVars.TakeABathAndShower.EnableBodyGrime then
        ISWashYourself.complete = washYourSelf_complete
    end

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches