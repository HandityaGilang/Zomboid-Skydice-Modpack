-- WMI_CleanBandagesContext.lua (B42.12 legacy)
-- Purpose:
--   Add a "Clean Bandages" submenu on water sources that behaves like the B42.13+ version:
--     * Uses ISWashClothing (instead of ISCleanBandage + recipe stubs).
--     * Cleans items in equipped bags sequentially: transfer -> wash -> return-to-bag.
--     * Supports a sandbox option to allow tainted water for cleaning rags/bandages.
--     * Supports a sandbox option for water used per bandage/strip.
--
-- Notes:
--   * Requires the shared patch "TimedActions/WMI_PatchWashClothing.lua" (added by this mod) to:
--       - Allow per-action water override.
--       - Return transformed ItemAfterCleaning items (BandageDirty, RippedSheetsDirty, etc.) back into the source bag.

require "TimedActions/ISWashClothing"              -- Vanilla timed action that handles ItemAfterCleaning swaps.
require "TimedActions/ISInventoryTransferAction"   -- Used to move items from bags to player inventory.
require "TimedActions/ISTimedActionQueue"          -- Used to queue actions sequentially.
require "TimedActions/WMI_PatchWashClothing"       -- Mod patch that adds return-to-bag + water override.

local WMI_Clean = {}

-- ---------------------------------------------------------------------------
-- Debug helpers
-- ---------------------------------------------------------------------------

local DEBUG = false
local TAG = "[WMI_Clean] "

local function log(...)
    if not DEBUG then return end
    print(TAG .. table.concat({...}, " "))
end

-- Safe userdata method existence check.
local function _safeHas(obj, key)
    if not obj or type(obj) ~= "userdata" then return false end
    local ok, v = pcall(function() return obj[key] end)
    return ok and v ~= nil
end

-- Safe method call wrapper.
local function _safeCall(obj, key, ...)
    if not obj or type(obj) ~= "userdata" then return nil end
    local ok, fn = pcall(function() return obj[key] end)
    if not ok or type(fn) ~= "function" then return nil end
    local ok2, res = pcall(fn, obj, ...)
    if not ok2 then return nil end
    return res
end

-- ---------------------------------------------------------------------------
-- Sandbox / tooltip helpers
-- ---------------------------------------------------------------------------

-- Read a sandbox boolean option by name with fallback.
local function _getSandboxBool(name, defaultValue)
    local sb = getSandboxOptions and getSandboxOptions() or nil
    if not sb or not sb.getOptionByName then return defaultValue end
    local opt = sb:getOptionByName(name)
    if not opt or not opt.getValue then return defaultValue end
    return opt:getValue()
end

-- Read a sandbox double option by name with fallback.
local function _getSandboxDouble(name, defaultValue)
    local sb = getSandboxOptions and getSandboxOptions() or nil
    if not sb or not sb.getOptionByName then return defaultValue end
    local opt = sb:getOptionByName(name)
    if not opt or not opt.getValue then return defaultValue end
    return opt:getValue()
end

-- Mod sandbox option (default true) - allow tainted water for cleaning rags/bandages.
local function _allowTaintedWater()
    return _getSandboxBool("WashSmart.AllowTaintedWater", true)
end

-- Mod sandbox option (default 4.0) - water used per bandage/strip.
local function _bandageWaterPerItem()
    -- Clamp defensively in case a server/modpack sets an odd value.
    local v = _getSandboxDouble("WashSmart.BandageWaterPerItem", 4.0)
    if type(v) ~= "number" then v = 4.0 end
    if v < 0.01 then v = 0.01 end
    return v
end

-- Vanilla cosmetic option - show tainted water tooltip.
local function _showTaintedTooltip()
    return _getSandboxBool("EnableTaintedWaterText", true)
end

-- Build a tainted-water tooltip; neutral if allowed, red-ish if blocked.
local function _makeTaintedTooltip(allowed)
    local tip = ISWorldObjectContextMenu.addToolTip()
    local color = allowed and "<RGB:1,1,1>" or "<RGB:1,0.5,0.5>"
    tip.description = " " .. color .. " " .. getText("Tooltip_item_TaintedWater")
    tip.maxLineWidth = 512
    return tip
end

-- ---------------------------------------------------------------------------
-- Water source detection helpers
-- ---------------------------------------------------------------------------

-- Return a numeric water amount for different sink APIs (world objects and some items).
local function _getWaterAmount(obj)
    if not obj then return 0 end

    -- Preferred: FluidContainer API in B42 (most water sources).
    if _safeHas(obj, "getFluidAmount") then
        local amt = _safeCall(obj, "getFluidAmount")
        if type(amt) == "number" then return amt end
    end

    -- Legacy helpers exposed on Lua side (some builds still have this).
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.getWaterAmount then
        local ok, v = pcall(function() return ISWorldObjectContextMenu.getWaterAmount(obj) end)
        if ok and type(v) == "number" then return v end
    end

    -- Last resort: boolean "hasWater" only tells if >= 1 unit.
    if _safeHas(obj, "hasWater") and _safeCall(obj, "hasWater") then
        return 1
    end

    return 0
end

-- Strict-ish predicate for "this is a water source in the world".
local function _isWaterSource(obj)
    if not obj or type(obj) ~= "userdata" then return false end
    local amt = _getWaterAmount(obj)
    if type(amt) == "number" and amt >= 1 then return true end

    -- Some sources expose only tainted state but still are usable water sources.
    if _safeHas(obj, "isTaintedWater") and _safeCall(obj, "isTaintedWater") then
        return amt >= 1
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Inventory helpers (dirty item discovery)
-- ---------------------------------------------------------------------------

-- Dirty item types supported by vanilla cleaning via ItemAfterCleaning.
local DIRTY_DEFS = {
    { dirty = "Base.BandageDirty"       },
    { dirty = "Base.RippedSheetsDirty"  },
    { dirty = "Base.DenimStripsDirty"   },
    { dirty = "Base.LeatherStripsDirty" },
}

-- Get a localized display name for an item fullType.
local function _getItemDisplayName(fullType)
    if not fullType then return "?" end
    local key = "ItemName_" .. fullType
    local s = getText(key)
    if s and s ~= key then return s end

    local sm = getScriptManager()
    if sm and sm.FindItem then
        local si = sm:FindItem(fullType)
        if si and si.getDisplayName then
            return si:getDisplayName()
        end
    end
    return fullType
end

-- Get all items of a given fullType across player inventory + equipped bags.

-- Resolve a Texture for a given item fullType to use as a context-menu icon.
-- This tries the item's normal texture first, then falls back to an explicit texture name/path.
local function _getItemIconTextureOrFallback(fullType, fallbackTexName)
    -- Try to resolve an icon Texture for a given item type.
    -- Notes:
    --   * In B42.13+, ScriptItem:getNormalTexture() already returns a Texture object.
    --   * Some builds return a Texture name that isn't resolvable via getTexture(name),
    --     so returning the Texture object directly is the most reliable approach.

    -- 1) Prefer the script item's normal texture (already a Texture object when available).
    local sm = getScriptManager()
    if sm and fullType then
        local ok, scriptItem = pcall(function() return sm:FindItem(fullType) end)
        if ok and scriptItem then
            if scriptItem.getNormalTexture then
                local texObj = scriptItem:getNormalTexture()
                if texObj then
                    return texObj
                end
            end

            -- 2) Fallback: use the Icon name if present ("Item_<Icon>").
            if scriptItem.getIcon then
                local icon = scriptItem:getIcon()
                if icon and icon ~= "" then
                    local tex = getTexture("Item_" .. icon)
                    if tex then return tex end
                end
            end
        end
    end

    -- 3) Fallback to an explicit texture name/path (if provided).
    if fallbackTexName then
        local tex = getTexture(fallbackTexName)
        if tex then return tex end
    end

    -- 4) Last resort: create a temporary item instance and use its icon texture.
    -- This is safe: it does not add anything to the player's inventory.
    if fullType and InventoryItemFactory and InventoryItemFactory.CreateItem then
        local tmp = InventoryItemFactory.CreateItem(fullType)
        if tmp then
            if tmp.getTex then
                local tex = tmp:getTex()
                if tex then return tex end
            end
            if tmp.getTexture then
                local tex = tmp:getTexture()
                if tex then return tex end
            end
        end
    end

    return nil
end

local function _getAllTypeRecurse(inv, fullType)
    if not inv or not fullType then return {} end

    -- B42 API: fullType is accepted.
    local ok, arr = pcall(function() return inv:getAllTypeRecurse(fullType) end)
    if not ok or not arr then
        -- Fallback: type-only name for older APIs.
        local typeOnly = tostring(fullType):match("([^.]+)$")
        local ok2, arr2 = pcall(function() return inv:getItemsFromType(typeOnly, true) end)
        if ok2 then arr = arr2 end
    end

    local out = {}
    if arr then
        for i = 0, arr:size() - 1 do
            local it = arr:get(i)
            if it then table.insert(out, it) end
        end
    end
    return out
end

-- Return a stable list of "tuples" for menu building:
--   { dirtyType=..., label=..., items={...}, count=... }
local function _collectDirtyTuples(playerObj)
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inv then return {} end

    local tuples = {}
    for _, def in ipairs(DIRTY_DEFS) do
        local items = _getAllTypeRecurse(inv, def.dirty)
        local count = #items
        if count > 0 then
            table.insert(tuples, {
                dirtyType = def.dirty,
                cleanType = def.clean,
                label     = _getItemDisplayName(def.dirty),
                iconTexture = _getItemIconTextureOrFallback(def.clean or def.dirty, nil),
                items     = items,
                count     = count,
            })
        end
    end
    return tuples
end

-- Compute blood/dirt for ISWashClothing duration. For these items it's usually 0,
-- but keeping this correct makes future items behave sensibly.
local function _getBloodAndDirt(item)
    local bloodAmount, dirtAmount = 0, 0
    if item and instanceof(item, "Clothing") then
        local parts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
        if parts then
            for i = 0, parts:size() - 1 do
                local part = parts:get(i)
                bloodAmount = bloodAmount + item:getBlood(part)
                dirtAmount  = dirtAmount  + item:getDirt(part)
            end
        end
    elseif item and item.getBloodLevel then
        bloodAmount = item:getBloodLevel()
    end
    return bloodAmount, dirtAmount
end

-- ---------------------------------------------------------------------------
-- TimedAction chaining: transfer -> wash -> return-to-bag (via patched ISWashClothing)
-- ---------------------------------------------------------------------------

-- Queue washing actions sequentially. Each item is optionally transferred from its source container
-- to player inventory, washed, and (if it transforms) returned to the original container by the patch.
local function _queueWashSequential(playerObj, waterObject, items, waterPerItem)
    if not playerObj or not waterObject or not items or #items == 0 then return end

    local inv = playerObj:getInventory()
    local prev = nil

    for i = 1, #items do
        local it = items[i]
        if it then
            local src = it:getContainer()
            local returnContainer = (src and src ~= inv) and src or nil

            -- Transfer from bag/container into main inventory if needed.
            if returnContainer then
                local transferAction = ISInventoryTransferAction:new(playerObj, it, returnContainer, inv)
                if prev then
                    ISTimedActionQueue.addAfter(prev, transferAction)
                else
                    ISTimedActionQueue.add(transferAction)
                end
                prev = transferAction
            end

            -- Create the wash action. The patch reads:
            --   * wmiReturnContainer (optional) to return the new clean item back into the bag.
            --   * wmiWaterOverride (optional) to consume the sandbox-configured amount of water.
            local bloodAmount, dirtAmount = _getBloodAndDirt(it)
            local washAction = ISWashClothing:new(
                playerObj,
                waterObject,
                nil,              -- soaps list not needed for ItemAfterCleaning transforms
                it,
                bloodAmount,
                dirtAmount,
                false,            -- noSoap=false (duration uses min clamp anyway)
                returnContainer,  -- optional: where to return transformed item
                waterPerItem      -- optional: water override (units)
            )

            if prev then
                ISTimedActionQueue.addAfter(prev, washAction)
            else
                ISTimedActionQueue.add(washAction)
            end
            prev = washAction
        end
    end
end

-- ---------------------------------------------------------------------------
-- Click handlers (called from context menu options)
-- ---------------------------------------------------------------------------

-- Clean a single item of a specific type.
function WMI_Clean.onCleanOne(playerObj, dirtyType, waterObject)
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inv then return end

    if waterObject and waterObject.isTaintedWater and waterObject:isTaintedWater() and (not _allowTaintedWater()) then
        return
    end

    local items = _getAllTypeRecurse(inv, dirtyType)
    if #items == 0 then return end

    -- Walk next to the water source before starting actions.
    if waterObject and waterObject.getSquare then
        if not luautils.walkAdj(playerObj, waterObject:getSquare(), true) then return end
    end

    local waterPerItem = _bandageWaterPerItem()
    _queueWashSequential(playerObj, waterObject, { items[1] }, waterPerItem)
end

-- Clean as many items of a specific type as water allows.
function WMI_Clean.onCleanMultiple(playerObj, dirtyType, waterObject)
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inv then return end

    if waterObject and waterObject.isTaintedWater and waterObject:isTaintedWater() and (not _allowTaintedWater()) then
        return
    end

    local waterPerItem = _bandageWaterPerItem()
    local waterAmt = _getWaterAmount(waterObject) or 0
    local maxItems = math.floor((waterAmt + 1e-6) / waterPerItem)
    if maxItems <= 0 then return end

    local items = _getAllTypeRecurse(inv, dirtyType)
    if #items == 0 then return end

    -- Select up to the max number of items.
    local selected = {}
    for i = 1, math.min(#items, maxItems) do
        table.insert(selected, items[i])
    end
    if #selected == 0 then return end

    if waterObject and waterObject.getSquare then
        if not luautils.walkAdj(playerObj, waterObject:getSquare(), true) then return end
    end

    _queueWashSequential(playerObj, waterObject, selected, waterPerItem)
end

-- Clean as many dirty bandage/strip items as water allows across all supported types.
function WMI_Clean.onCleanAll(playerObj, waterObject, tupleList)
    local inv = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    if not inv then return end

    if waterObject and waterObject.isTaintedWater and waterObject:isTaintedWater() and (not _allowTaintedWater()) then
        return
    end

    local waterPerItem = _bandageWaterPerItem()
    local waterAmt = _getWaterAmount(waterObject) or 0
    local maxItems = math.floor((waterAmt + 1e-6) / waterPerItem)
    if maxItems <= 0 then return end

    -- Select items in a stable order (DIRTY_DEFS order).
    local selected = {}
    local count = 0
    for _, def in ipairs(DIRTY_DEFS) do
        if count >= maxItems then break end
        local items = _getAllTypeRecurse(inv, def.dirty)
        for i = 1, #items do
            if count >= maxItems then break end
            table.insert(selected, items[i])
            count = count + 1
        end
    end
    if #selected == 0 then return end

    if waterObject and waterObject.getSquare then
        if not luautils.walkAdj(playerObj, waterObject:getSquare(), true) then return end
    end

    _queueWashSequential(playerObj, waterObject, selected, waterPerItem)
end

-- ---------------------------------------------------------------------------
-- Menu construction
-- ---------------------------------------------------------------------------

-- Insert 'newOpt' right after the option whose name is 'afterName'.
local function _insertOptionAfterByName(parentMenu, newOpt, afterName)
    if not parentMenu or not parentMenu.options or not newOpt then return end
    local idxAfter, idxNew = nil, nil
    for i, opt in ipairs(parentMenu.options) do
        local name = tostring(opt.name or opt.text or "")
        if name == afterName then idxAfter = i end
        if opt == newOpt then idxNew = i end
    end
    if not idxAfter or not idxNew or idxNew == idxAfter + 1 then return end
    table.remove(parentMenu.options, idxNew)
    table.insert(parentMenu.options, idxAfter + 1, newOpt)
end

-- Add one dirty-type submenu under the Clean Bandages branch.
local function _addTypeSubmenu(rootSub, playerObj, waterObject, tuple)
    local dirtyType = tuple.dirtyType
    local label     = tuple.label
    local count     = tuple.count

    local isTainted = waterObject.isTaintedWater and waterObject:isTaintedWater() or false
    local blocked   = isTainted and (not _allowTaintedWater())

    local tip = nil
    if isTainted and _showTaintedTooltip() then
        tip = _makeTaintedTooltip(_allowTaintedWater())
    end

    -- Compute (n/N) for this type based on water-per-item.
    local waterPerItem = _bandageWaterPerItem()
    local waterAmt = _getWaterAmount(waterObject) or 0
    local maxItems = math.floor((waterAmt + 1e-6) / waterPerItem)
    local can = math.min(count, maxItems)

    local typeOpt = rootSub:addOption(label .. " (" .. tostring(count) .. ")")
    -- Use the clean-item icon for this entry (if available).
    local icon = tuple.iconTexture
    if icon then typeOpt.iconTexture = icon end
    if tip then typeOpt.toolTip = tip end
    typeOpt.notAvailable = blocked or (count <= 0)

    local typeSub = ISContextMenu:getNew(rootSub)
    rootSub:addSubMenu(typeOpt, typeSub)

    -- "One" entry.
    local optOne = typeSub:addActionsOption(getText("ContextMenu_One") or "One",
        WMI_Clean.onCleanOne, dirtyType, waterObject)
    if icon then optOne.iconTexture = icon end
    if tip then optOne.toolTip = tip end
    optOne.notAvailable = blocked or (count <= 0)

    -- "All (n/N)" entry (disabled if n==0).
    local allLabel = (getText("ContextMenu_All") or "All") .. " (" .. tostring(can) .. "/" .. tostring(count) .. ")"
    local optAll = typeSub:addActionsOption(allLabel,
        WMI_Clean.onCleanMultiple, dirtyType, waterObject)
    if icon then optAll.iconTexture = icon end
    if tip then optAll.toolTip = tip end
    optAll.notAvailable = blocked or (can <= 0)
end

-- Build and insert the Clean Bandages submenu under a water-source submenu.
local function buildCleanBandagesMenu(context, playerNum, waterObject, placeAfterName)
    local amt = _getWaterAmount(waterObject) or 0
    if not waterObject or amt < 1 then return end

    local playerObj = getSpecificPlayer(playerNum)
    local tuples = _collectDirtyTuples(playerObj)
    if #tuples == 0 then return end

    local isTainted = waterObject.isTaintedWater and waterObject:isTaintedWater() or false
    local blocked   = isTainted and (not _allowTaintedWater())

    local tip = nil
    if isTainted and _showTaintedTooltip() then
        tip = _makeTaintedTooltip(_allowTaintedWater())
    end

    local CLEAN = getText("ContextMenu_CleanBandageEtc") or "Clean Bandages"
    local WASH  = getText("ContextMenu_Wash") or "Wash"

    -- Create the branch option and submenu.
    local root = context:addOption(CLEAN)
    if tip then root.toolTip = tip end
    root.notAvailable = blocked

    -- Give the root entry an icon (bandage/first available type).
    local rootIcon = (tuples[1] and tuples[1].iconTexture) or _getItemIconTextureOrFallback("Base.Bandage", nil)
    if rootIcon then root.iconTexture = rootIcon end

    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, subMenu)

    -- Place it right after "Wash" if possible.
    if placeAfterName then
        _insertOptionAfterByName(context, root, placeAfterName)
    end

    -- Compute All (n/N) for total items based on water-per-item.
    local total = 0
    for _, t in ipairs(tuples) do total = total + t.count end

    local waterPerItem = _bandageWaterPerItem()
    local maxItems = math.floor((amt + 1e-6) / waterPerItem)
    local can = math.min(total, maxItems)

    local allLabel = (getText("ContextMenu_All") or "All") .. " (" .. tostring(can) .. "/" .. tostring(total) .. ")"
    local optAll = subMenu:addActionsOption(allLabel, WMI_Clean.onCleanAll, waterObject, tuples)
    if tip then optAll.toolTip = tip end
    optAll.notAvailable = blocked or (can <= 0)

    -- Add each supported type submenu.
    for _, t in ipairs(tuples) do
        _addTypeSubmenu(subMenu, playerObj, waterObject, t)
    end

    return root, subMenu
end

-- ---------------------------------------------------------------------------
-- Context menu injection (B42.12: sinks are submenus under the clicked object)
-- ---------------------------------------------------------------------------

-- Find the "water object submenu" (the submenu that contains Wash/Drink/Fill entries).
local function findWaterSubMenu(context)
    local DRINK = getText("ContextMenu_Drink") or "Drink"
    local WASH  = getText("ContextMenu_Wash")  or "Wash"

    for _, opt in ipairs(context.options or {}) do
        if opt and opt.subOption then
            local sub = context:getSubMenu(opt.subOption)
            if sub and sub.getMenuOptionNames then
                local names = sub:getMenuOptionNames()
                if names[DRINK] or names[WASH] then
                    return sub
                end
            end
        end
    end
    return nil
end

-- Try to extract the actual water object referenced by this submenu.
local function _getWaterObjectFromSubmenu(sub)
    if not sub or not sub.options then return nil end
    local DRINK  = getText("ContextMenu_Drink")  or "Drink"
    local FILL   = getText("ContextMenu_Fill")   or "Fill"
    local REFILL = getText("ContextMenu_Refill") or "Refill"

    -- Pass 1: scan Drink/Fill/Refill actions and read their params.
    for _, ch in ipairs(sub.options) do
        if ch.name == DRINK or ch.name == FILL or ch.name == REFILL then
            for i = 1, 6 do
                local p = ch["param" .. i]
                if p and type(p) == "userdata" and _isWaterSource(p) then
                    return p
                end
            end
        end
    end

    -- Pass 2: scan any option params for a water object.
    for _, ch in ipairs(sub.options) do
        for i = 1, 6 do
            local p = ch["param" .. i]
            if p and type(p) == "userdata" and _isWaterSource(p) then
                return p
            end
        end
    end

    return nil
end

-- OnFill hook injects the Clean Bandages submenu into each detected sink submenu.
local function onFill(playerNum, context, worldobjects, test)
    if test then return end

    local DRINK = getText("ContextMenu_Drink") or "Drink"
    local WASH  = getText("ContextMenu_Wash")  or "Wash"
    local CLEAN = getText("ContextMenu_CleanBandageEtc") or "Clean Bandages"

    -- Iterate all top-level submenus and inject into every "water submenu" we can find.
    for _, opt in ipairs(context.options or {}) do
        if opt and opt.subOption then
            local sub = context:getSubMenu(opt.subOption)
            if sub and sub.getMenuOptionNames then
                local names = sub:getMenuOptionNames()
                if names and (names[WASH] or names[DRINK]) then
                    -- Avoid injecting twice.
                    if names[CLEAN] then
                        -- already injected
                    else
                        local waterObject = _getWaterObjectFromSubmenu(sub)

                        -- Fallback - probe clicked objects when submenu params don't contain the sink.
                        if not waterObject then
                            for _, obj in ipairs(worldobjects or {}) do
                                if _isWaterSource(obj) then
                                    waterObject = obj
                                    break
                                end
                            end
                        end

                        if waterObject and _isWaterSource(waterObject) then
                            buildCleanBandagesMenu(sub, playerNum, waterObject, WASH)
                        end
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFill)



-- ---------------------------------------------------------------------------
-- Public helper API (for compat mods)
-- ---------------------------------------------------------------------------

-- Inject the "Clean Bandages" submenu into an existing ISContextMenu.
-- This is intended for compatibility with mods that create their own parent submenu (e.g., TABAS bathtubs).
function WMI_Clean.injectIntoSubMenu(targetMenu, playerObj, sink)
    -- targetMenu: ISContextMenu where the option should be appended
    -- playerObj: IsoPlayer
    -- sink: water source IsoObject
    -- Build 42.12 Legacy: internal builder takes (context, playerNum, waterObject, placeAfterName)
    if not targetMenu or not playerObj or not sink then return end
    local playerNum = 0
    if playerObj.getPlayerNum then
        playerNum = playerObj:getPlayerNum() or 0
    end
    buildCleanBandagesMenu(targetMenu, playerNum, sink, nil)
end

return WMI_Clean
