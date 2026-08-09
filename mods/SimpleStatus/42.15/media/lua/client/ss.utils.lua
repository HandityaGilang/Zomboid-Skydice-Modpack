local utils = {
    color = {
        red = { r = 1, g = 0, b = 0 },
        green = { r = 0, g = 1, b = 0 },
        blue = { r = 0, g = 0, b = 1 },
        yellow = { r = 1, g = 1, b = 0 },
        orangeyellow = { r = 1, g = 0.74, b = 0 },
        orange = { r = 1, g = 0.55, b = 0 },
        orangered = { r = 1, g = 0.27, b = 0 },
        darkred = { r = 0.55, g = 0, b = 0 },
        cyan = { r = 0, g = 1, b = 1 },
        magenta = { r = 1, g = 0, b = 1 },
        white = { r = 1, g = 1, b = 1 },
        black = { r = 0, g = 0, b = 0 },
    },
    font = {
        Small = UIFont.Small,
        Medium = UIFont.Medium,
        Large = UIFont.Large,
    }
}

local function getBarTitile(t)
    return getText("IGUI_SS_BARTITLE_" .. t)
end


local function getOptName(t)
    return getText("IGUI_SS_OPT_" .. t)
end


---@param fcolor {r:number, g:number, b:number}
---@param tcolor {r:number, g:number, b:number}
---@param p number
---@return {r:number, g:number, b:number}
local function getPColor(fcolor, tcolor, p)
    local r = fcolor.r + (tcolor.r - fcolor.r) * p
    local g = fcolor.g + (tcolor.g - fcolor.g) * p
    local b = fcolor.b + (tcolor.b - fcolor.b) * p
    return { r = r, g = g, b = b }
end


local function getStrWidth(font, str)
    return getTextManager():MeasureStringX(font, str)
end


local function maxWidthOfStrs(font, strs)
    local maxlen = 0
    for _, str in ipairs(strs) do
        local len = getStrWidth(font, str)
        if len > maxlen then maxlen = len end
    end
    return maxlen
end


local function getTempertueStr(temperture)
    local c = getCore():getOptionDisplayAsCelsius()
    local deg_char = string.char(176)

    local unit = deg_char .. "C"
    if not c then
        temperture = temperture * 1.8 + 32
        unit = deg_char .. "F"
    end

    temperture = round((temperture * 10.0) / 10, 1)
    return tostring(temperture) .. " " .. unit
end

local function listContains(list, element)
    for _, value in ipairs(list) do
        if value == element then
            return true
        end
    end
    return false
end
local function lineHight(font)
    return getTextManager():getFontHeight(font)
end


local function to_upper(str)
    local result = ""
    for i = 1, #str do
        local c = str:sub(i, i)
        if c >= "a" and c <= "z" then
            c = string.char(string.byte(c) - 32)
        end
        result = result .. c
    end
    return result
end

local function join_keys(tab, sep)
    local keys = {}
    for k, _ in pairs(tab) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return table.concat(keys, sep)
end


utils.fn = {
    getBarTitile = getBarTitile,
    getOptName = getOptName,
    getPColor = getPColor,
    getStrWidth = getStrWidth,
    maxWidthOfStrs = maxWidthOfStrs,
    getTempertueStr = getTempertueStr,
    listContains = listContains,
    lineHight = lineHight,
    to_upper = to_upper,
    join_keys = join_keys,
}

return utils
