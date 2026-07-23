require("SimpleStatus")

local SSBar = require("ISSSBar")
local load_mod_compatible = require("ss.mods.compatible")
local stats = require("ss.stats")
local utils = require("ss.utils")

local bars = {}
local configs = {}

local function initConfig(config, pos)
    config = config or {}
    config.fontSize = config.fontSize or "Small"
    local font = utils.font[config.fontSize] or utils.font.Small
    -- shorter side of the rect
    config.barWidth = utils.fn.lineHight(font) or config.barWidth or 20
    -- affects the Longer side of the rect
    config.barInc = config.barInc or 110
    config.opacity = config.opacity or 0.66

    config.pos = config.pos or pos


    -- Shift + \
    config.toggleKey = config.toggleKey or 43
    -- Shift + L 
    config.lockedKey = config.lockedKey or 38
    
    if config.locked == nil then config.locked = false end
    if config.isVertical == nil then config.isVertical = false end
    if config.isRulerOn == nil then config.isRulerOn = true end

    config.shownConfig = config.shownConfig or {}
    config.toggleStats = config.toggleStats or {}


    for _, name in ipairs(stats._values) do
        if config.shownConfig[name] == nil then
            config.shownConfig[name] = stats[name].shown
        end
    end
    for _, name in pairs(stats._reverse._values) do
        if config.toggleStats[name] == nil then
            config.toggleStats[name] = false
        end
    end
    return config
end

local function init()
    -- Load Mod Compatible Stats
    load_mod_compatible()
end

init()


Events.OnCreatePlayer.Add(function(playerNum, playerObj)
    -- if respawn, del first
    local bar = bars[playerNum+1]
    if not rawequal(bar, nil) then
        bar:setVisible(false)
        print("remove old ui")
        bar:removeFromUIManager()
        bar = nil
    end
    
    -- load config
    local cfg = utils.fn.loadConfig(playerNum)
    local pos = {20, 630}
    cfg =  initConfig(cfg, pos)
    configs[playerNum+1] = cfg
    -- create Bar
    bar = SSBar:new(playerObj, cfg)
    bars[playerNum+1] = bar
    bar:initialise()
    bar:addToUIManager()
end)

Events.OnKeyPressed.Add(function(key)
    for _, bar in ipairs(bars) do
        if bar then bar:handleKey(key) end
    end

    return key
end)