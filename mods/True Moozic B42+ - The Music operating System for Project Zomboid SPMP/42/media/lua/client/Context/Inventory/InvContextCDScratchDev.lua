-- InvContextCDScratchDev.lua
-- Admin / debug-mode right-click option on CD albums:
--   "[TM] Set CD Scratch" -> Clean / 25% / 50% / 100%
-- Lets admins and debug users change a CD's scratch tier in-game.

require "TCMusicDefenitions"

-- Same CD classification the loot system uses (TCLootControl).
local function isCDTypeName(typeName)
    if type(typeName) ~= "string" then return false end
    local lower = string.lower(typeName)
    if string.find(lower, "cdplayer", 1, true) or string.find(lower, "cdcase", 1, true) or string.find(lower, "cdcarryingcase", 1, true) then
        return false
    end
    if string.sub(typeName, 1, 3) == "CD_" then return true end
    if string.len(typeName) > 2 and string.sub(typeName, -2) == "CD" then return true end
    return false
end

local function isScratchableCD(item)
    if not item or not instanceof(item, "InventoryItem") then return false end
    local fullType = item:getFullType()
    if type(fullType) ~= "string" then return false end
    local module, typeName = string.match(fullType, "^([^%.]+)%.(.+)$")
    if not module or module == "Base" then return false end
    return isCDTypeName(typeName)
end

local function isDevAllowed()
    -- Debug mode (SP or MP with -debug)
    if isDebugEnabled and isDebugEnabled() then return true end
    if getDebug and getDebug() then return true end
    local core = getCore and getCore() or nil
    if core and core.getDebug and core:getDebug() then return true end
    -- Admin / staff (vanilla InvContextMedia pattern: getCore():getDebug() or isAdmin())
    -- getAccessLevel()/isAdmin() dereference GameClient.connection -> NPE in SP.
    -- Only safe when actually connected as a network client.
    if isClient() then
        if isAdmin and isAdmin() then return true end
        local ok, lvl = pcall(function()
            return string.lower(tostring(getAccessLevel() or ""))
        end)
        if ok and (lvl == "admin" or lvl == "moderator" or lvl == "overseer" or lvl == "gm") then
            return true
        end
    end
    if isCoopHost and isCoopHost() then return true end
    return false
end

local function applyTier(player, cds, tier)
    for _, cd in ipairs(cds) do
        TCMusic.setScratchTier(cd, tier)
    end
end

local function onFillContext(player, context, items)
    if not items then return end
    if not isDevAllowed() then return end
    local plr = getSpecificPlayer(player)
    if not plr then return end

    -- Collect all CD items in the clicked selection (handles stacks).
    local cds = {}
    for _, v in ipairs(items) do
        if instanceof(v, "InventoryItem") then
            if isScratchableCD(v) then table.insert(cds, v) end
        elseif type(v) == "table" and v.items then
            -- Stack: entry 1 is the representative; 2..n are the real items.
            local first = 2
            if #v.items == 1 then first = 1 end
            for i = first, #v.items do
                local it = v.items[i]
                if isScratchableCD(it) then table.insert(cds, it) end
            end
        end
    end
    if #cds == 0 then return end

    local currentTier = cds[1]:getModData().TMScratch or 0
    local option = context:addOption("[TM] Set CD Scratch", nil, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(option, sub)

    local tiers = {
        { tier = nil, value = 0,   label = "Clean (0%)" },
        { tier = 25,  value = 25,  label = "25% scratched" },
        { tier = 50,  value = 50,  label = "50% scratched" },
        { tier = 75,  value = 75,  label = "75% scratched" },
        { tier = 100, value = 100, label = "100% scratched" },
    }
    for _, t in ipairs(tiers) do
        local label = t.label
        if currentTier == t.value then label = label .. "  <" end
        sub:addOption(label, plr, applyTier, cds, t.tier)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContext)
