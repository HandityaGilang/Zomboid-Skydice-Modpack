local old_ISReadABookPerform = ISReadABook.perform
local old_isValid = ISReadABook.isValid

local sBvars = SandboxVars.GydeTraitMags

-- Map magazines to their corresponding traits
local magazineTraits = {
    ["Base.NutritionistMag"] = "Nutritionist",
    ["Base.OutdoorsmanMag"] = "Outdoorsman",
    ["Base.HandyMag"] = "Handy",
    ["Base.AxeManMag"] = "Axeman",
    ["Base.BurglarMag"] = "Burglar",
    ["Base.SpeedDemonMag"] = { positive = "SpeedDemon", negative = "SundayDriver" },
    ["Base.OrganizedMag"] = { positive = "Organized", negative = "Disorganized" },
    ["Base.FastLearnerMag"] = { positive = "FastLearner", negative = "SlowLearner" },
    ["Base.FastReaderMag"] = { positive = "FastReader", negative = "SlowReader" },
    ["Base.GracefulMag"] = { positive = "Graceful", negative = "Clumsy" },
    ["Base.DextrousMag"] = { positive = "Dextrous", negative = "AllThumbs" },
    ["Base.InconspicuousMag"] = { positive = "Inconspicuous", negative = "Conspicuous" },
    ["Base.KeenHearingMag"] = { positive = "KeenHearing", negative = "HardOfHearing" }
}

-- Helper Function: Check if the player can read a magazine.
local function CheckIfCanRead()
    if sBvars.DaysBeforeRead == 0 then return true end

    local player = getPlayer()
    local daysSurvived = player:getHoursSurvived() / 24

    return daysSurvived >= sBvars.DaysBeforeRead
end

-- Helper Function: Make character say something.
local function DisplayMessage(character, messageKey)
    if not character.hasDisplayedMessage then
        character:Say(getText(messageKey), 0.55, 0.55, 0.55, UIFont.Dialogue, 0, "default")
        character.hasDisplayedMessage = true
    end
end

-- Override ISReadABook:isValid
function ISReadABook:isValid()
    local magazineType = self.item:getFullType()
    local traitData = magazineTraits[magazineType]

    if traitData and not CheckIfCanRead() then
        DisplayMessage(self.character, "IGUI_PlayerText_CantReadYet")
        return false
    end

    -- Special case for Deaf trait.
    if magazineType == "Base.KeenHearingMag" and self.character:getTraits():contains("Deaf") then
        if not self.hasDisplayedDeafMessage then
            local randomDeafMessageIndex = ZombRand(1, 4)
            local deafMessageKey = "IGUI_PlayerText_AmDeaf" .. tostring(randomDeafMessageIndex)
            self.character:Say(getText(deafMessageKey), 0.55, 0.55, 0.55, UIFont.Dialogue, 0, "default")
            self.hasDisplayedDeafMessage = true
        end
        return false
    end

    return old_isValid(self)
end

-- Override ISReadABook:perform
function ISReadABook:perform(...)
    local magazineType = self.item:getFullType()
    local traitData = magazineTraits[magazineType]

    if traitData then
        local traits = self.character:getTraits()
        local modData = self.character:getModData()

        if type(traitData) == "table" then
            -- Handle traits with counterparts
            if traits:contains(traitData.negative) then
                modData["StartedWith" .. traitData.negative] = true
                traits:remove(traitData.negative)
                if sBvars.ReplaceTraits and not traits:contains(traitData.positive) then
                    traits:add(traitData.positive)
                end
            elseif not traits:contains(traitData.positive) then
                if not modData["StartedWith" .. traitData.negative] or sBvars.ReplaceTraits then
                    traits:add(traitData.positive)
                end
            elseif sBvars.ReadRemove then
                traits:remove(traitData.positive)
            end
        else
            -- Handle simple traits
            if not traits:contains(traitData) then
                traits:add(traitData)
            elseif sBvars.ReadRemove then
                traits:remove(traitData)
            end
        end
    end

	-- Delete the magazine after reading if enabled and it's from the mod.
	if sBvars.ReadDelete and magazineTraits[magazineType] then
		self.character:getInventory():Remove(self.item)
		return
	end

    print("GTM: old_ISReadABookPerform.")
    return old_ISReadABookPerform(self, ...)
end