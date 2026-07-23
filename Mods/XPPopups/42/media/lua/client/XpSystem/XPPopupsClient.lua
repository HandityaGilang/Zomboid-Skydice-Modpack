-- XP Popups client-side handler.
-- Tracks XP changes locally and shows popups for all skills.
-- Works in both singleplayer and multiplayer without server commands.
--
-- Previous versions used a server-side Events.AddXP tracker + sendServerCommand,
-- which does not fire Events.OnServerCommand in singleplayer. This version polls
-- XP values directly on the client, which works in all game modes.

-- tostring(perkType) returns the Java enum name. These are the cases where
-- the enum name differs from the IGUI_perks_ translation key suffix.
local perkKeyOverrides = {
    Lightfoot       = "Lightfooted",
    Sneak           = "Sneaking",
    PlantScavenging = "Foraging",
}

local function isPopupEnabled(perkId)
    local opts = PZAPI.ModOptions:getOptions("XPPopups")
    if opts then
        local opt = opts:getOption(perkId)
        if opt then
            return opt:getValue()
        end
    end
    -- Fallback defaults if options not yet loaded
    if perkId == "Fitness" or perkId == "Strength" or perkId == "PlantScavenging" or perkId == "Electricity" then
        return false
    end
    return true
end

local function showPopup(player, perkId, amount)
    local keyName = perkKeyOverrides[perkId] or perkId
    local perkName = getText("IGUI_perks_" .. keyName)
    local xpText = getText("Challenge_Challenge2_CurrentXp", amount)
    HaloTextHelper.addTextWithArrow(player, perkName .. " " .. xpText, "[br/]", true, HaloTextHelper.getGoodColor())
end

-- ===== Client-side XP tracking =====
-- Polls every few ticks to detect XP changes for all local players (slots 0-3).
-- In multiplayer, the client's player XP is synced from the server, so changes
-- are visible here shortly after they are granted.

local cachedPerkList = nil
local function getPerks()
    if not cachedPerkList then
        cachedPerkList = {}
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            if perk then
                table.insert(cachedPerkList, perk)
            end
        end
    end
    return cachedPerkList
end

local xpCache = {}

local function initCache(player)
    xpCache[player] = {}
    for _, perk in ipairs(getPerks()) do
        xpCache[player][perk] = player:getXp():getXP(perk)
    end
end

local function checkPlayer(player)
    if not xpCache[player] then
        initCache(player)
        return
    end
    for _, perk in ipairs(getPerks()) do
        local current = player:getXp():getXP(perk)
        local cached  = xpCache[player][perk]
        if cached and current > cached then
            local diff = round(current - cached, 2)
            if diff > 0 then
                local perkId = tostring(perk)
                if isPopupEnabled(perkId) then
                    showPopup(player, perkId, diff)
                end
            end
        end
        xpCache[player][perk] = current
    end
end

local CHECK_INTERVAL = 3
local tickCount = 0

local function onTick()
    tickCount = tickCount + 1
    if tickCount < CHECK_INTERVAL then return end
    tickCount = 0
    for i = 0, 3 do
        local player = getSpecificPlayer(i)
        if player then
            checkPlayer(player)
        end
    end
end

Events.OnTick.Add(onTick)
