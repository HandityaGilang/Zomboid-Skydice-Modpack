local json = require("ss.json")

local utils = {
    color = {
        red = { 1, 0, 0 },
        green = { 0, 1, 0 },
        blue = { 0, 0, 1 },
        yellow = { 1, 1, 0 },
        orangeyellow = { 1, 0.74, 0 },
        orange = { 1, 0.55, 0 },
        orangered = { 1, 0.27, 0 },
        darkred = { 0.55, 0, 0 },
        cyan = { 0, 1, 1 },
        magenta = { 1, 0, 1 },
        white = { 1, 1, 1 },
        black = { 0, 0, 0 },
    },
    font = {
        Small = UIFont.Small,
        Medium = UIFont.Medium,
        Large = UIFont.Large,
    }
}

local function loadConfig(playerNum)
    if playerNum == nil or playerNum == 0 then playerNum = "" end
    playerNum = tostring(playerNum)

    local file, _ = getFileReader("SStatConfig"..playerNum..".json", true)
    if file == nil then return nil end

    local content  = ""
    local tbl  = {}

    while true do
        local line = file:readLine()
        if line == nil then break end
        table.insert(tbl, line:match("^%s*(.-)%s*$"))
    end

    file:close()

    for _, v in ipairs(tbl) do
        content = content .. v
    end
    if content == "" then return nil end
    return json.decode(content)
end


local function saveConfig(config, playerNum)
    if playerNum == nil or playerNum == 0 then playerNum = "" end
    playerNum = tostring(playerNum)

    local file, _ = getFileWriter("SStatConfig"..playerNum..".json", true, false)
    if file == nil then return nil end

    local contents = json.encode(config)
    file:write(contents)
    file:close()
end


local function getBarTitile(t)
    return getText("IGUI_SS_BARTITLE_" .. t)
end


local function getOptName(t)
    return getText("IGUI_SS_OPT_" .. t)
end


local function getPColor(fcolor, tcolor, p)
    local r = fcolor[1] + (tcolor[1] - fcolor[1]) * p
    local g = fcolor[2] + (tcolor[2] - fcolor[2]) * p
    local b = fcolor[3] + (tcolor[3] - fcolor[3]) * p
    return { r, g, b }
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

local function log(...)
    local file, _ = getFileWriter("ST_Log.txt", true, true)
    if file == nil then return nil end

    local timestamp = getTimestamp()
    local s = timestamp .. " : "
    for _, v in ipairs({...}) do
        s = s .. tostring(v) .. " "
    end
    file:writeln(s)
    file:close()

end

local function to_upper(str)
    local result = ""
    for i = 1, #str do
      local c = str:sub(i,i)
      if c >= "a" and c <= "z" then
        c = string.char(string.byte(c) - 32)
      end
      result = result .. c
    end
    return result
end

utils.fn = {
    loadConfig = loadConfig,
    saveConfig = saveConfig,
    getBarTitile = getBarTitile,
    getOptName = getOptName,
    getPColor = getPColor,
    getStrWidth = getStrWidth,
    maxWidthOfStrs = maxWidthOfStrs,
    getTempertueStr = getTempertueStr,
    listContains = listContains,
    lineHight = lineHight,
    log = log,
    to_upper = to_upper,
}

return utils