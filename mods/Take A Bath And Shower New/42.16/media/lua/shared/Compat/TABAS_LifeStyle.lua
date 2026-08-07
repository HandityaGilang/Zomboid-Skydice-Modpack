local TABAS_Patches = {}

TABAS_Patches.applied = false

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end

    local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
    local TABAS_Iso = require("TABAS_Iso")
    local TABAS_Utils = require("TABAS_Utils")

    local old_washCleansedBody = TABAS_BathingUtils.washCleansedBody
    function TABAS_BathingUtils.washCleansedBody(character, wornItems, pct, grimeWashFactor, makeOff)
        local result = old_washCleansedBody(character, wornItems, pct, grimeWashFactor, makeOff)

        if not isClient() then
            local decrease = math.max(0, math.floor(((pct or 0) * 6) * 10) / 10)
            if decrease > 0 then
                local md = character:getModData()
                if md.hygieneNeed == nil then
                    md.hygieneNeed = 40
                end

                local oldValue = md.hygieneNeed
                local newValue = math.max(0, math.floor((md.hygieneNeed - decrease) * 10) / 10)
                if newValue ~= md.hygieneNeed then
                    md.hygieneNeed = newValue
                    character:transmitModData()
                    TABAS_Utils.debugPrint("Compat Lifestyle", string.format(
                    "washCleansedBody hygieneNeed %.1f -> %.1f (-%.1f, pct=%.2f)",
                    oldValue, newValue, oldValue - newValue, pct or 0 ))
                end
            end
        end

        return result
    end

    local old_endBathing = TABAS_BathingUtils.endBathing
    function TABAS_BathingUtils.endBathing(character, isCompleted, clearAnim)
        local bathSession = nil
        if character then
            local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
            bathSession = TABAS_TakeBathSession:get(character)
        end
        local washCount = bathSession and bathSession.washCount or 0

        local result = old_endBathing(character, isCompleted, clearAnim)

        if result and isCompleted then
            local md = character:getModData()
            if md.hygieneNeed == nil then
                md.hygieneNeed = 40
            end

            local oldValue = md.hygieneNeed
            local target = washCount > 0 and 25 or 35
            local changed = false
            if md.hygieneNeed > target then
                md.hygieneNeed = target
                changed = true
            end

            local hours = character:getHoursSurvived()
            if md.lastBath ~= hours then
                md.lastBath = hours
                changed = true
            end

            if changed then
                character:transmitModData()
                TABAS_Utils.debugPrint("Compat Lifestyle", string.format(
                    "endBathing hygieneNeed %.1f -> %.1f (washCount=%d, completed=%s, target=%d)",
                    oldValue, md.hygieneNeed, washCount or 0, tostring(isCompleted), target))
            end
        end

        return result
    end

    if TABAS_TakeShower and TABAS_TakeShower.complete then
        local old_showerComplete = TABAS_TakeShower.complete
        function TABAS_TakeShower:complete()
            local result = old_showerComplete(self)

            if self and self.completed then
                local md = self.character:getModData()
                if md.hygieneNeed == nil then
                    md.hygieneNeed = 40
                end

                local oldValue = md.hygieneNeed
                local changed = false
                if md.hygieneNeed > 40 then
                    md.hygieneNeed = 40
                    changed = true
                end

                local hours = self.character:getHoursSurvived()
                if md.lastBath ~= hours then
                    md.lastBath = hours
                    changed = true
                end

                if changed then
                    self.character:transmitModData()
                    TABAS_Utils.debugPrint("Compat Lifestyle", string.format(
                        "showerComplete hygieneNeed %.1f -> %.1f (completed=%s)",
                        oldValue, md.hygieneNeed, tostring(self.completed)))
                end
            end

            return result
        end
    end

    if not isServer() then
        local function removeLSBathShowerOptions(player, context, worldObjects, test)
            if test and ISWorldObjectContextMenu.Test then return true end

            local object, type = TABAS_Iso.getBathingObjectFromWorldObjects(worldObjects)
            if not object or not type then return end

            if type == "Shower" or type == "Bathtub" then
                context:removeOptionByName(getText("ContextMenu_Shower_Use"))
                context:removeOptionByName(getText("ContextMenu_Shower_Use_NoHot"))
                context:removeOptionByName(getText("ContextMenu_Shower_NoWater"))
                context:removeOptionByName(getText("ContextMenu_Bath_Use"))
                context:removeOptionByName(getText("ContextMenu_Bath_UseBubble"))
                context:removeOptionByName(getText("ContextMenu_Bath_Use_NoHot"))
                context:removeOptionByName(getText("ContextMenu_Bath_NoWater"))
            end
        end

        Events.OnFillWorldObjectContextMenu.Add(removeLSBathShowerOptions)
    end

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
