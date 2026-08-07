require "TimedActions/ISWashYourself"

local TABAS_Patches = {}
local TABAS_BodyGrimeUtils = require("TABAS_BodyGrimeUtils")

TABAS_Patches.applied = false

local old_complete = ISWashYourself.complete

local function washYourSelf_complete(self)
    local result = old_complete(self)
    local amount = SandboxVars.TakeABathAndShower.WashSelfRemoveGrimeAmount
    if amount > 0 then
        TABAS_BodyGrimeUtils.removeBodyGrime(self.character, amount)
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
