-- InvContextCDClean.lua
-- Right-click a scratched CD -> "Clean CD scratches".
-- Requires a polish (Toothpaste or Peanut Butter) plus something clean to
-- wipe with (rag, bath towel, dish towel, napkins, tissue, toilet paper or
-- The polish is used up entirely. A clean rag turns into a dirty rag;
-- towels/napkins/tissue lose one use; cotton balls are consumed.
-- Each clean lowers the scratch one step:
--   100% -> 75% -> 50% -> 25% -> clean.

require "TCMusicDefenitions"

-- Polishes: consumed entirely per clean (no amount bar).
local CLEANERS = {
    "Base.Toothpaste",
    "Base.PeanutButter",
}

-- Wipes. kind:
--   swap    = replaced by its dirty variant
--   drain   = loses one drainable use (deleted when empty)
--   consume = deleted
local WIPES = {
    { fullType = "Base.RippedSheets",  kind = "swap", dirty = "Base.RippedSheetsDirty" },
    { fullType = "Base.BathTowel",     kind = "drain" },
    { fullType = "Base.DishCloth",     kind = "drain" },
    { fullType = "Base.PaperNapkins2", kind = "drain" },
    { fullType = "Base.Tissue",        kind = "drain" },
    { fullType = "Base.ToiletPaper",   kind = "drain" },
    { fullType = "Base.CottonBalls",   kind = "consume" },
}

-- Same CD classification the loot/scratch system uses.
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

local function isScratchedCD(item)
    if not item or not instanceof(item, "InventoryItem") then return false end
    local fullType = item:getFullType()
    if type(fullType) ~= "string" then return false end
    local module, typeName = string.match(fullType, "^([^%.]+)%.(.+)$")
    if not module or module == "Base" then return false end
    if not isCDTypeName(typeName) then return false end
    local md = item:getModData()
    return md.TMScratch ~= nil and md.TMScratch > 0
end

local function findCleaner(inv)
    for _, ft in ipairs(CLEANERS) do
        local it = inv:getFirstTypeRecurse(ft)
        if it then return it end
    end
    return nil
end

local function findWipe(inv)
    for _, def in ipairs(WIPES) do
        local it = inv:getFirstTypeRecurse(def.fullType)
        if it then
            if def.kind == "drain" then
                if it.getCurrentUsesFloat and it:getCurrentUsesFloat() > 0.0001 then
                    return it, def
                end
            else
                return it, def
            end
        end
    end
    return nil, nil
end

-- MP: consume/give via the existing TMItemMPSync server commands (server
-- removal/addition is broadcast back to the client). SP: direct.
local function removeItemForPlayer(player, item)
    if isClient() then
        sendClientCommand(player, "TMItemMPSync", "consumeTape", {
            itemId = item:getID(),
            fullType = item:getFullType(),
        })
    else
        local c = item:getContainer() or player:getInventory()
        c:DoRemoveItem(item)
    end
end

local function giveItemToPlayer(player, fullType)
    if isClient() then
        sendClientCommand(player, "TMItemMPSync", "giveTape", { fullType = fullType })
    else
        player:getInventory():AddItem(fullType)
    end
end

local function useWipe(player, wipe, def)
    if def.kind == "swap" then
        removeItemForPlayer(player, wipe)
        giveItemToPlayer(player, def.dirty)
    elseif def.kind == "drain" then
        local useDelta = (wipe.getUseDelta and wipe:getUseDelta()) or 0.1
        local left = (wipe.getCurrentUsesFloat and wipe:getCurrentUsesFloat()) or 0
        left = left - useDelta
        if left > 0.0001 then
            wipe:setUsedDelta(left)
            if TCMusic and TCMusic.safeSyncItem then TCMusic.safeSyncItem(wipe) elseif isClient() then wipe:syncItemFields() end
        else
            removeItemForPlayer(player, wipe)
        end
    else -- consume
        removeItemForPlayer(player, wipe)
    end
end

local function doCleanCD(player, cd)
    if not player or not cd then return end
    local md = cd:getModData()
    local cur = md.TMScratch or 0
    if cur <= 0 then return end

    -- Re-resolve materials at action time (menu may be stale).
    local inv = player:getInventory()
    local cleaner = findCleaner(inv)
    local wipe, wipeDef = findWipe(inv)
    if not cleaner or not wipe then return end

    local nextTier = TCMusic.getNextScratchTier(cur)
    TCMusic.setScratchTier(cd, nextTier > 0 and nextTier or nil)

    removeItemForPlayer(player, cleaner)
    useWipe(player, wipe, wipeDef)
end

local function onFillContext(player, context, items)
    if not items then return end
    local plr = getSpecificPlayer(player)
    if not plr then return end

    -- Find the first scratched CD in the clicked selection.
    local cd = nil
    for _, v in ipairs(items) do
        local item = v
        if not instanceof(item, "InventoryItem") and type(v) == "table" and v.items then
            item = v.items[1]
        end
        if item and isScratchedCD(item) then
            cd = item
            break
        end
    end
    if not cd then return end

    -- Retroactive: make sure already-scratched CDs get the how-to-clean tooltip.
    TCMusic.applyScratchTooltip(cd)

    local cur = cd:getModData().TMScratch or 0
    local nextTier = TCMusic.getNextScratchTier(cur)
    local nextLabel = nextTier > 0 and (tostring(nextTier) .. "%") or (getTextOrNull("IGUI_TM_CD_Clean") or "clean")
    local label = (getTextOrNull("ContextMenu_TM_CleanCD") or "Clean CD scratches") .. " (" .. tostring(cur) .. "% -> " .. nextLabel .. ")"

    local inv = plr:getInventory()
    local cleaner = findCleaner(inv)
    local wipe = findWipe(inv)

    local option = context:addOption(label, plr, doCleanCD, cd)
    if not cleaner or not wipe then
        option.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip:setName(getTextOrNull("ContextMenu_TM_CleanCD") or "Clean CD scratches")
        tip.description = getTextOrNull("Tooltip_TM_CleanCD_Requires")
            or "Requires Toothpaste or Peanut Butter, plus something clean to wipe with: <LINE> rag, bath towel, dish towel, napkins, tissue, toilet paper or cotton balls."
        option.toolTip = tip
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContext)
