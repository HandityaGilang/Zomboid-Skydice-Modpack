require "GydeTraitMagazines_Shared"

local old_ISReadABookPerform = ISReadABook.perform
local old_isValid = ISReadABook.isValid

local sBvars = SandboxVars.GydeTraitMags

-- isValid can stay mostly unchanged, but MUST use shared table
function ISReadABook:isValid()
    local magazineType = self.item:getFullType()
    local traitData = GydeTraitMags.magazineTraits[magazineType]

    -- Special case for deaf trait and keen hearing magazine.
    if magazineType == "Base.KeenHearingMag" and self.character:hasTrait(CharacterTrait.DEAF) then
        -- I don't know why but without this the message plays twice, isValid is called twice I guess?
        if not self.hasDisplayedDeafMessage then
            self.character:Say(getText("IGUI_PlayerText_AmDeaf" .. ZombRand(1,4)))
            self.hasDisplayedDeafMessage = true
        end
        return false
    end

    -- Guard for minimum day requirement.
    if traitData and sBvars.DaysBeforeRead > 0 then
        local daysSurvived = getPlayer():getHoursSurvived() / 24
        if daysSurvived < sBvars.DaysBeforeRead then
            -- I don't know why but without this the message plays twice, isValid is called twice I guess? (2)
            if not self.hasDisplayedEarlyMessage then
                self.character:Say(getText("IGUI_PlayerText_CantReadYet"))
                self.hasDisplayedEarlyMessage = true
            end
            return false
        end
    end

    return old_isValid(self)
end

function ISReadABook:perform(...)
    local magType = self.item:getFullType()

    -- Only execute if the magazine is from GTM.
    if GydeTraitMags.magazineTraits[magType] then
        sendClientCommand(self.character, "GydeTraitMags", "ApplyMagazine", {
            magazineType = magType
        })

        self.character:StopAllActionQueue()
        return
    end

    old_ISReadABookPerform(self, ...)
end