local Utils = {}

Utils.LABEL_R = 1.0
Utils.LABEL_G = 1.0
Utils.LABEL_B = 0.8
Utils.VALUE_R = 1.0
Utils.VALUE_G = 1.0
Utils.VALUE_B = 1.0
Utils.GOOD_R = 0.0
Utils.GOOD_G = 0.9
Utils.GOOD_B = 0.0
Utils.BAD_R = 0.9
Utils.BAD_G = 0.0
Utils.BAD_B = 0.0

function Utils.call(obj, method, ...)
    if not obj or not method or type(obj[method]) ~= "function" then
        return nil
    end

    local ok, result = pcall(obj[method], obj, ...)
    if ok then return result end
    return nil
end

function Utils.isInstance(item, className)
    if not item or not className or not instanceof then return false end
    local ok, result = pcall(instanceof, item, className)
    return ok and result == true
end

function Utils.hasTag(item, tag)
    if not item or not tag or not item.hasTag then return false end
    local ok, result = pcall(item.hasTag, item, tag)
    return ok and result == true
end

function Utils.isClothing(item)
    return Utils.call(item, "IsClothing") == true or Utils.call(item, "getCategory") == "Clothing"
end

function Utils.round(value, decimals)
    if type(value) ~= "number" then return nil end
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utils.formatNumber(value, decimals)
    local rounded = Utils.round(value, decimals or 1)
    if rounded == nil then return nil end
    if rounded == math.floor(rounded) then
        return tostring(math.floor(rounded))
    end
    return tostring(rounded)
end

function Utils.formatPercent(value, decimals)
    if type(value) ~= "number" then return nil end
    return Utils.formatNumber(value * 100, decimals or 0) .. "%"
end

function Utils.text(key, fallback)
    if key and getTextOrNull then
        return getTextOrNull(key) or fallback or key
    end
    if key and getText then
        local ok, value = pcall(getText, key)
        if ok and value then return value end
    end
    return fallback or key or ""
end

function Utils.row(label, value, valueR, valueG, valueB)
    if label == nil or label == "" then return nil end
    if value == nil then value = "" end
    return {
        label = tostring(label) .. ":",
        value = tostring(value),
        labelR = Utils.LABEL_R,
        labelG = Utils.LABEL_G,
        labelB = Utils.LABEL_B,
        valueR = valueR or Utils.VALUE_R,
        valueG = valueG or Utils.VALUE_G,
        valueB = valueB or Utils.VALUE_B,
    }
end

function Utils.note(label, r, g, b)
    if label == nil or label == "" then return nil end
    return {
        label = tostring(label),
        value = "",
        labelR = r or Utils.LABEL_R,
        labelG = g or Utils.LABEL_G,
        labelB = b or Utils.LABEL_B,
    }
end

function Utils.addRow(rows, row)
    if row then table.insert(rows, row) end
end

function Utils.timeString(minutes)
    if type(minutes) ~= "number" then return nil end
    if ISCampingMenu and ISCampingMenu.timeString then
        local ok, text = pcall(ISCampingMenu.timeString, minutes)
        if ok and text then return text end
    end

    minutes = Utils.round(minutes, 1)
    local hours = math.floor(minutes / 60)
    local remaining = minutes - hours * 60
    if hours > 0 then
        local text = tostring(hours) .. " " .. Utils.text(hours == 1 and "IGUI_Gametime_hour" or "IGUI_Gametime_hours", hours == 1 and "hour" or "hours")
        if remaining > 0 then
            text = text .. ", " .. Utils.formatNumber(remaining, 1) .. " " .. Utils.text(remaining == 1 and "IGUI_Gametime_minute" or "IGUI_Gametime_minutes", remaining == 1 and "minute" or "minutes")
        end
        return text
    end
    return Utils.formatNumber(minutes, 1) .. " " .. Utils.text(minutes == 1 and "IGUI_Gametime_minute" or "IGUI_Gametime_minutes", minutes == 1 and "minute" or "minutes")
end

function Utils.newProvider(optionFn, priority, getRows)
    return {
        priority = priority or 30,
        getRows = function(self, ctx)
            if type(optionFn) == "function" and optionFn() ~= true then return nil end
            if not ctx or not ctx.item or Utils.isClothing(ctx.item) then return nil end
            local ok, rows = pcall(getRows, ctx.item, ctx)
            if ok and type(rows) == "table" and #rows > 0 then
                return rows
            end
            return nil
        end,
        getTextX = function(self, ctx)
            if ctx.ownerProvider and ctx.ownerProvider.id == "BetterClothingInfo" then return 5 end
            return 12
        end,
        getLinePadLeft = function(self, ctx)
            if ctx.ownerProvider and ctx.ownerProvider.id == "BetterClothingInfo" then return 5 end
            return 10
        end,
        getLinePadRight = function(self, ctx)
            if ctx.ownerProvider and ctx.ownerProvider.id == "BetterClothingInfo" then return 5 end
            return 10
        end,
    }
end

return Utils
