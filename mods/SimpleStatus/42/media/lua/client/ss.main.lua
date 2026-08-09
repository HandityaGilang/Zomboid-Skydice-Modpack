require("SimpleStatus")

local SSBar               = require("ISSSBar")
local load_mod_compatible = require("ss.mods.compatible")
local stats               = require("ss.stats")
local utils               = require("ss.utils")

---@type table<integer, SSBar>
local bars                = {}

local function loadPlayerConfig(user, md)
    if not md then
        md = {}
    end
    print("[SimpleStatus] Loading config for player: " .. user)
    md[user]        = md[user] or {}

    local cfg       = {}

    -- All display settings from ModData
    cfg.fontSize    = md[user]["SS_fontSize"] or "Small"
    local font      = utils.font[cfg.fontSize] or utils.font.Small
    cfg.barWidth    = utils.fn.lineHight(font)
    cfg.isVertical  = (md[user]["SS_isVertical"] == true)
    cfg.isRulerOn   = (md[user]["SS_isRulerOn"] ~= false) -- default: true

    -- Panel position and lock state
    local px        = md[user]["SS_pos_x"]
    local py        = md[user]["SS_pos_y"]
    cfg.pos         = (px and py) and { px, py } or { 20, 630 }
    cfg.locked      = (md[user]["SS_locked"] == true)

    -- Per-stat visibility
    cfg.shownConfig = {}
    for _, name in ipairs(stats._values) do
        local saved = md[user]["SS_shown_" .. name]
        if saved ~= nil then
            cfg.shownConfig[name] = saved
        else
            cfg.shownConfig[name] = stats[name].shown
        end
    end

    -- Stat pair toggles
    cfg.toggleStats = {}
    for _, name in ipairs(stats._reverse._values) do
        cfg.toggleStats[name] = (md[user]["SS_tog_" .. name] == true)
    end

    return cfg
end

load_mod_compatible()

local function onCreatePlayer(player_index, player)
    if not isMultiplayer() then
        local md = ModData.getOrCreate("SimpleStatusConfig")
        ModData.add("SimpleStatusConfig", md)
    end

    local function createUI()
        local md = ModData.get("SimpleStatusConfig")
        if not md then return end

        Events.OnTick.Remove(createUI)
        if not player then return end

        ---@type string
        local username
        if isMultiplayer() then
            username = player:getUsername()
        else
            username = "player" .. (player_index + 1)
        end

        print("[SimpleStatus] Showing status bar for player: " .. username)

        local bar = bars[player_index + 1]
        if bar ~= nil then
            -- remove if exists: player death and re-create
            bar:setVisible(false)
            bar:removeFromUIManager()
            table.remove(bars, player_index + 1)
        end

        local cfg = loadPlayerConfig(username, md)
        bar = SSBar:new(player, cfg, username)
        
        bars[player_index + 1] = bar
        bar:initialise()
        bar:addToUIManager()

        print("[SimpleStatus] Status bar created for player: " .. username)
    end

    Events.OnTick.Add(createUI)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnKeyPressed.Add(function(key)
    for _, bar in ipairs(bars) do
        bar:handleKey(key)
    end
end)
