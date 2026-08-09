require("SimpleStatus")

local SSBar               = require("ISSSBar")
local load_mod_compatible = require("ss.mods.compatible")
local stats               = require("ss.stats")
local utils               = require("ss.utils")

---@type table<integer, SSBar>
local bars                = {}

---@param player IsoPlayer
local function loadPlayerConfig(player)
    print("[SimpleStatus] Loading config for player: " .. player:getUsername())

    local md_cfg    = player:getModData()["SimpleStatusConfig"] or {}

    local cfg       = {}

    -- All display settings from ModData
    cfg.fontSize    = md_cfg["SS_fontSize"] or "Small"
    local font      = utils.font[cfg.fontSize] or utils.font.Small
    cfg.barWidth    = utils.fn.lineHight(font)
    cfg.isVertical  = (md_cfg["SS_isVertical"] == true)
    cfg.isRulerOn   = (md_cfg["SS_isRulerOn"] ~= false) -- default: true

    -- Panel position and lock state
    local px        = md_cfg["SS_pos_x"]
    local py        = md_cfg["SS_pos_y"]
    cfg.pos         = (px and py) and { px, py } or { 20, 630 }
    cfg.locked      = (md_cfg["SS_locked"] == true)

    -- Per-stat visibility
    cfg.shownConfig = {}
    for _, name in ipairs(stats._values) do
        local saved = md_cfg["SS_shown_" .. name]
        if saved ~= nil then
            cfg.shownConfig[name] = saved
        else
            cfg.shownConfig[name] = stats[name].shown
        end
    end

    -- Stat pair toggles
    cfg.toggleStats = {}
    for _, name in ipairs(stats._reverse._values) do
        cfg.toggleStats[name] = (md_cfg["SS_tog_" .. name] == true)
    end

    return cfg
end

load_mod_compatible()

---@param player_index integer
---@param player IsoPlayer
local function onCreatePlayer(player_index, player)
    if not player then return end

    local md = player:getModData()
    md = md["SimpleStatusConfig"] or {}

    print("[SimpleStatus] Showing status bar for player: " .. player:getUsername())

    local bar = bars[player_index + 1]
    if bar ~= nil then
        -- remove if exists: player death and re-create
        bar:setVisible(false)
        bar:removeFromUIManager()
        table.remove(bars, player_index + 1)
    end

    local cfg = loadPlayerConfig(player)
    bar = SSBar:new(player, cfg)

    bars[player_index + 1] = bar
    bar:initialise()
    bar:addToUIManager()

    print("[SimpleStatus] Status bar created for player: " .. player:getUsername())
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnKeyPressed.Add(function(key)
    for _, bar in ipairs(bars) do
        bar:handleKey(key)
    end
end)
