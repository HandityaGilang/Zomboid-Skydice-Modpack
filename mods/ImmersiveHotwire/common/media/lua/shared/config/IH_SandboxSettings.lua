local SandboxSettings = {}
local Config = require "config/IH_Config"

SandboxSettings.LEGACY_WIRE_MIGRATION_VERSION = "1.1.0"
SandboxSettings.DATA_VERSION = "1.2.0"

SandboxSettings.DEFAULT = {
    SCREWDRIVERS = { "Base.Screwdriver", "Base.Screwdriver_Old", "Base.Screwdriver_Improvised", "Base.Multitool", "Base.Handiknife" },
    SCREWDRIVERS_TAGS = {},
    PLIERS = { "Base.Pliers", "Base.Multitool" },
    PLIERS_TAGS = {},
}

SandboxSettings.ALARM = Config.ALARM or {
    RISK_MAX = 100,
    ADD_SPARK = 20,
    ADD_FAIL_START = 10,
    ADD_SCREW = 2,
    ADD_CUT = 10,
}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function splitToolsString(s)
    local out = {}
    if type(s) ~= "string" then return out end

    s = s:gsub(",", ";")

    for token in s:gmatch("([^;]+)") do
        token = trim(token)
        if token ~= "" then
            out[#out + 1] = token
        end
    end

    return out
end

local function unique(list)
    local seen, out = {}, {}
    for _, v in ipairs(list or {}) do
        if v and v ~= "" and not seen[v] then
            seen[v] = true
            out[#out + 1] = v
        end
    end
    return out
end

local function getSandboxValue(kind)
    local vars = SandboxVars and SandboxVars.ImmersiveHotwire
    if not vars then return nil end

    if kind == "SCREWDRIVERS" then return vars.Screwdrivers end
    if kind == "SCREWDRIVERS_TAGS" then return vars.ScrewdriversTags end
    if kind == "PLIERS" then return vars.Pliers end
    if kind == "PLIERS_TAGS" then return vars.PliersTags end
    if kind == "HOTWIRE_EVERY_TIME" then return vars.HotwireEveryTime end
    if kind == "DUCTTAPE_NEEDED_TO_UNHOTWIRE" then return vars.DucttapeNeededToUnhotwire end
    if kind == "SHOW_DRAG_LINE" then return vars.ShowDragLine end

    return nil
end

local function getOptionsValue(kind)
    local options = getSandboxOptions and getSandboxOptions() or nil
    if not options then return nil end

    if kind == "SCREWDRIVERS" then
        local opt = options:getOptionByName("ImmersiveHotwire.Screwdrivers")
        return opt and opt:getValue() or nil
    end
    if kind == "SCREWDRIVERS_TAGS" then
        local opt = options:getOptionByName("ImmersiveHotwire.ScrewdriversTags")
        return opt and opt:getValue() or nil
    end
    if kind == "PLIERS" then
        local opt = options:getOptionByName("ImmersiveHotwire.Pliers")
        return opt and opt:getValue() or nil
    end
    if kind == "PLIERS_TAGS" then
        local opt = options:getOptionByName("ImmersiveHotwire.PliersTags")
        return opt and opt:getValue() or nil
    end
    if kind == "HOTWIRE_EVERY_TIME" then
        local opt = options:getOptionByName("ImmersiveHotwire.HotwireEveryTime")
        return opt and opt:getValue() or nil
    end
    if kind == "DUCTTAPE_NEEDED_TO_UNHOTWIRE" then
        local opt = options:getOptionByName("ImmersiveHotwire.DucttapeNeededToUnhotwire")
        return opt and opt:getValue() or nil
    end
    if kind == "SHOW_DRAG_LINE" then
        local opt = options:getOptionByName("ImmersiveHotwire.ShowDragLine")
        return opt and opt:getValue() or nil
    end
    return nil
end

local function copyList(list)
    local out = {}
    for i = 1, #list do
        out[i] = list[i]
    end
    return out
end

local function resolveToolPair(rawItems, rawTags, defaultItems)
    local items = unique(splitToolsString(rawItems))
    local tags = unique(splitToolsString(rawTags))
    if #items == 0 and #tags == 0 then
        items = copyList(defaultItems or {})
    end
    return items, tags
end

local function buildTools(resolveValue)
    local screwdrivers, screwdriverTags = resolveToolPair(
        resolveValue("SCREWDRIVERS"),
        resolveValue("SCREWDRIVERS_TAGS"),
        SandboxSettings.DEFAULT.SCREWDRIVERS
    )
    local pliers, plierTags = resolveToolPair(
        resolveValue("PLIERS"),
        resolveValue("PLIERS_TAGS"),
        SandboxSettings.DEFAULT.PLIERS
    )
    local result = {
        SCREWDRIVERS = screwdrivers,
        SCREWDRIVERS_TAGS = screwdriverTags,
        PLIERS = pliers,
        PLIERS_TAGS = plierTags,
    }
    return result
end

function SandboxSettings.buildToolsFromOptions()
    return buildTools(getOptionsValue)
end

function SandboxSettings.buildToolsFromSandbox()
    return buildTools(getSandboxValue)
end

function SandboxSettings.get(kind)
    local tools = SandboxSettings.buildToolsFromSandbox()
    return tools[kind] or {}
end

function SandboxSettings.isHotwireEveryTime()
    local value = getSandboxValue("HOTWIRE_EVERY_TIME")
    if value ~= nil then
        return value == true
    end
    local opt = getOptionsValue("HOTWIRE_EVERY_TIME")
    if opt ~= nil then
        return opt == true
    end
    return false
end

function SandboxSettings.isDucttapeNeededToUnhotwire()
    local value = getSandboxValue("DUCTTAPE_NEEDED_TO_UNHOTWIRE")
    if value ~= nil then
        return value == true
    end
    local opt = getOptionsValue("DUCTTAPE_NEEDED_TO_UNHOTWIRE")
    if opt ~= nil then
        return opt == true
    end
    return true
end

function SandboxSettings.isDragLineEnabled()
    local value = getSandboxValue("SHOW_DRAG_LINE")
    if value ~= nil then
        return value == true
    end
    local opt = getOptionsValue("SHOW_DRAG_LINE")
    if opt ~= nil then
        return opt == true
    end
    return true
end

return SandboxSettings


