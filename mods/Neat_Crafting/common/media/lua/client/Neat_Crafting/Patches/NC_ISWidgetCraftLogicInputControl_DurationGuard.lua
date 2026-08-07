-- NC_ISWidgetCraftLogicInputControl_DurationGuard.lua
-- Workaround for a Build 42.19 vanilla workstation UI issue.
--
-- Vanilla ISWidgetCraftLogicInputControl:createDynamicChildren() builds the craft logic
-- duration label with:
--   string.format(getText("EC_CraftLogic_Duration", "%02dd %02dh %02dm %02ds"), ...)
-- In 42.19, the English Entity translation for EC_CraftLogic_Duration uses "%1".
-- Passing that through Java Formatter can throw UnknownFormatConversionException,
-- which then leaves Lua with a nil/null text and crashes on :gsub().
--
-- This patch only intercepts that one translation key during the vanilla widget build.
-- It converts the old placeholder to a Lua string.format-compatible duration pattern
-- and falls back to a safe English format if the translated value is unusable.

require "Entity/ISUI/Components/Crafting/ISWidgetCraftLogicInputControl"

local function NC_BuildSafeCraftLogicDurationFormat(baseGetText)
    local durationFormat = "%02dd %02dh %02dm %02ds"
    local durationFormatReplacement = "%%02dd %%02dh %%02dm %%02ds"
    local fallback = "Time Required:\\n" .. durationFormat

    if type(baseGetText) == "function" then
        local ok, rawText = pcall(baseGetText, "EC_CraftLogic_Duration")
        if ok and type(rawText) == "string" and rawText ~= "" and rawText ~= "EC_CraftLogic_Duration" then
            local candidate = rawText

            -- Support the current bad vanilla placeholder and a couple of likely variants.
            candidate = candidate:gsub("%%1%$s", durationFormatReplacement)
            candidate = candidate:gsub("%%1", durationFormatReplacement)
            candidate = candidate:gsub("%%s", durationFormatReplacement)

            -- Validate that the result is safe for the vanilla string.format call.
            local formatOk = pcall(function()
                string.format(candidate:gsub('\\n', '\n'), 0, 0, 0, 0)
            end)

            if formatOk then
                return candidate
            end
        end
    end

    return fallback
end

if ISWidgetCraftLogicInputControl and not ISWidgetCraftLogicInputControl._NC_durationGuardPatched then
    ISWidgetCraftLogicInputControl._NC_durationGuardPatched = true
    ISWidgetCraftLogicInputControl._NC_old_createDynamicChildren_DurationGuard = ISWidgetCraftLogicInputControl._NC_old_createDynamicChildren_DurationGuard or ISWidgetCraftLogicInputControl.createDynamicChildren

    local oldCreateDynamicChildren = ISWidgetCraftLogicInputControl._NC_old_createDynamicChildren_DurationGuard

    function ISWidgetCraftLogicInputControl:createDynamicChildren()
        local baseGetText = getText

        local function guardedGetText(key, ...)
            if key == "EC_CraftLogic_Duration" then
                -- First try vanilla normally in case the game fixes the key later.
                local ok, value = pcall(baseGetText, key, ...)
                if ok and type(value) == "string" then
                    local candidate = value
                    local durationFormatReplacement = "%%02dd %%02dh %%02dm %%02ds"
                    candidate = candidate:gsub("%%1%$s", durationFormatReplacement)
                    candidate = candidate:gsub("%%1", durationFormatReplacement)
                    candidate = candidate:gsub("%%s", durationFormatReplacement)

                    local formatOk = pcall(function()
                        string.format(candidate:gsub('\\n', '\n'), 0, 0, 0, 0)
                    end)
                    if formatOk then
                        return candidate
                    end
                end

                return NC_BuildSafeCraftLogicDurationFormat(baseGetText)
            end

            return baseGetText(key, ...)
        end

        getText = guardedGetText
        local ok, a, b, c, d = pcall(oldCreateDynamicChildren, self)
        getText = baseGetText

        if not ok then
            error(a)
        end

        return a, b, c, d
    end
end
