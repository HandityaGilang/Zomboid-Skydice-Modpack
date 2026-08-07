-- WMI_CleanBandagesContext.lua
-- MP-safe "Clean Bandages" submenu for water sources (B42.13+).
--
-- Key differences vs the old implementation:
--   * Uses ISWashClothing (NetTimedAction-safe) instead of ISCleanBandage (recipe-stub issues in MP).
--   * Processes equipped-bag items one-by-one: transfer -> wash -> return (including ItemAfterCleaning transforms).
--   * Requires the shared patch "TimedActions/WMI_PatchWashClothing.lua" to return transformed clean items to the source bag.

require "TimedActions/ISWashClothing"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/WMI_PatchWashClothing"
require "ISUI/ISInventoryPaneContextMenu"

local WMI_Clean = {}
local DEBUG = false
local TAG = "[WMI_Clean] "

local function log(...)
    if not DEBUG then return end
    print(TAG .. table.concat({...}, " "))
end

-- Compatibility helper: Build 42.15 removed the explicit `soapList` constructor argument from ISWashClothing:new(...).
-- Route WMI calls to the correct signature without duplicating build-specific code at each call site.
local function WMI_IsB4215Plus()
    if not getGameVersion then return false end
    local version = tostring(getGameVersion() or "")
    local major, minor = string.match(version, "^(%d+)%.(%d+)")
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    return (major > 42) or (major == 42 and minor >= 15)
end

local function WMI_NewWashAction(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
    if WMI_IsB4215Plus() then
        -- 42.15+: soaps are fetched internally by vanilla.
        return ISWashClothing:new(playerObj, sink, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
    end

    -- 42.13 / 42.14: keep the legacy constructor shape.
    return ISWashClothing:new(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
end

-- ---------------------------------------------------------------------------
-- Sandbox / tooltip helpers
-- ---------------------------------------------------------------------------

local function _getSandboxBool(name, defaultValue)
    local ok, opts = pcall(function() return getSandboxOptions() end)
    if not ok or not opts or not opts.getOptionByName then return defaultValue end
    local opt = opts:getOptionByName(name)
    if not opt then return defaultValue end
    if opt.getValue then
        return opt:getValue()
    end
    return defaultValue
end

-- Mod sandbox option: Allow tainted water for cleaning (default true)
local function _allowTaintedWater()
    -- Adjust this key if your sandbox-options.txt uses a different name
    return _getSandboxBool("WashSmart.AllowTaintedWater", true)
end

-- Read a sandbox double option by name with fallback.
local function _getSandboxDouble(name, defaultValue)
    local ok, opts = pcall(function() return getSandboxOptions() end)
    if not ok or not opts or not opts.getOptionByName then return defaultValue end
    local opt = opts:getOptionByName(name)
    if not opt then return defaultValue end
    if opt.getValue then
        return opt:getValue()
    end
    return defaultValue
end

-- Mod sandbox option (default 4.0) - water used per bandage/strip.
local function _bandageWaterPerItem()
    local v = _getSandboxDouble("WashSmart.BandageWaterPerItem", 4.0)
    if type(v) ~= "number" then v = 4.0 end
    if v < 0.01 then v = 0.01 end
    return v
end

-- Vanilla option: show tainted water tooltip/warning (only cosmetic)
local function _showTaintedTooltip()
    return _getSandboxBool("EnableTaintedWaterText", true)
end

local function _makeTaintedTooltip(isAllowed)
    local tip = ISToolTip:new()
    tip:initialise()
    tip:setVisible(false)
    tip:setName(getText("Tooltip_item_TaintedWater") or "Tainted Water")
    local txt = getText("Tooltip_item_TaintedWater")
    if not txt then txt = "Tainted water." end
    -- Use neutral text if allowed, red warning if blocked
    if isAllowed then
        tip.description = txt .. "\n" .. (getText("Tooltip_WMI_TaintedAllowed") or "Allowed by sandbox.")
    else
        tip.description = "<RGB:1,0,0>" .. txt .. "\n" .. (getText("Tooltip_WMI_TaintedBlocked") or "Blocked by sandbox.")
    end
    return tip
end

-- ---------------------------------------------------------------------------
-- Item collection helpers
-- ---------------------------------------------------------------------------

local DIRTY_DEFS = {
    { dirty = "Base.BandageDirty"       },
    { dirty = "Base.RippedSheetsDirty"  },
    { dirty = "Base.DenimStripsDirty"   },
    { dirty = "Base.LeatherStripsDirty" },
}

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

    local arr = nil
    local ok, res = pcall(function() return inv:getAllTypeRecurse(fullType) end)
    if ok and res then arr = res end

    if not arr then
        -- Fallback: type-only name for older APIs
        local typeOnly = tostring(fullType):match("([^.]+)$")
        local ok2, res2 = pcall(function() return inv:getItemsFromType(typeOnly, true) end)
        if ok2 and res2 then arr = res2 end
    end

    local out = {}
    if arr then
        for i = 0, arr:size() - 1 do
            local it = arr:get(i)
            if it and (not it.getJobDelta or it:getJobDelta() == 0) then
                table.insert(out, it)
            end
        end
    end
    return out
end

local function _computeWashAmounts(item)
    -- Mirrors vanilla ISWorldObjectContextMenu's logic.
    local bloodAmount, dirtAmount = 0, 0

    if item and instanceof(item, "Clothing") then
        for i = 0, BloodBodyPartType.MAX:index() - 1 do
            local part = BloodBodyPartType.FromIndex(i)
            bloodAmount = bloodAmount + item:getBlood(part)
            dirtAmount  = dirtAmount  + item:getDirt(part)
        end
    elseif item and item.getBloodLevel then
        bloodAmount = item:getBloodLevel()
    end

    return bloodAmount, dirtAmount
end

local function _selectByWater(items, waterRemaining, waterPerItem)
    -- Select as many items as possible within available water.
    local selected = {}
    if not items or #items == 0 then return selected end
    if not waterRemaining or waterRemaining < 1 then return selected end

    local req = waterPerItem or _bandageWaterPerItem()
    local used = 0
    for _, it in ipairs(items) do
        if used + req > waterRemaining + 1e-6 then break end
        used = used + req
        table.insert(selected, it)
    end

    return selected
end

-- Soap list (vanilla logic: bar soap + cleaning liquids)
local function predicateCleaningLiquid(item)
    if not item or not item.hasComponent then return false end
    if not item:hasComponent(ComponentType.FluidContainer) then return false end
    local fc = item:getFluidContainer()
    if not fc then return false end

    local okBleach = (Fluid and Fluid.Bleach and fc.contains and fc:contains(Fluid.Bleach)) or false
    local okClean  = (Fluid and Fluid.CleaningLiquid and fc.contains and fc:contains(Fluid.CleaningLiquid)) or false
    if not (okBleach or okClean) then return false end

    local minAmt = (ZomboidGlobals and ZomboidGlobals.CleanBloodBleachAmount) or 0.099
    return fc.getAmount and (fc:getAmount() >= minAmt)
end

local function _buildSoapList(playerObj)
    local soapList = {}
    local inv = playerObj:getInventory()

    local barList = inv:getItemsFromType("Soap2", true)
    for i = 0, barList:size() - 1 do
        table.insert(soapList, barList:get(i))
    end

    local bottleList = inv:getAllEvalRecurse(predicateCleaningLiquid)
    for i = 0, bottleList:size() - 1 do
        table.insert(soapList, bottleList:get(i))
    end

    return soapList
end

-- ---------------------------------------------------------------------------
-- Core queue: transfer -> wash -> return (transform-safe)
-- ---------------------------------------------------------------------------

local function _queueWashItemsSequential(playerObj, sink, soapList, items, closeCtx, noSoap, waterOverride)
    if not items or #items == 0 then return end
    if not luautils.walkAdj(playerObj, sink:getSquare(), true) then
        log("walkAdj failed")
        return
    end

    local playerInv = playerObj:getInventory()

    -- Snapshot item IDs in the player's main inventory for a given full type.
    -- This is used to detect the NEW item created by stack splitting during transfers in MP.
    local function _snapshotIdsByFullType(fullType)
        local ids = {}
        if not fullType then return ids end
        local all = playerInv:getItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            if it and it.getFullType and it:getFullType() == fullType then
                ids[it:getID()] = true
            end
        end
        return ids
    end

    -- Find the newly added item in the main inventory after a transfer.
    -- If a stack is split, the transferred item may be a NEW object with a NEW ID.
    local function _findNewItemByFullType(fullType, beforeIds)
        if not fullType or not beforeIds then return nil end
        local all = playerInv:getItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            if it and it.getFullType and it:getFullType() == fullType then
                local id = it.getID and it:getID() or nil
                if id and not beforeIds[id] then
                    return it
                end
            end
        end
        return nil
    end

    local function afterTransfer(transferAction, originalContainer, willTransform)
        -- In MP, client-side container state can lag; don't hard-block on container checks.
        if not transferAction or not transferAction.item then
            log("AfterTransfer -> missing transferAction.item")
            return
        end

        local movedItem = transferAction.item

        -- For stackables (bandages/strips) the transfer can split and create a NEW item instance.
        -- Detect the actual item now present in the main inventory by comparing IDs before/after the transfer.
        local fullType = transferAction.wmiFullType or (movedItem and movedItem.getFullType and movedItem:getFullType()) or nil
        if transferAction.wmiBeforeIds and fullType then
            local fresh = _findNewItemByFullType(fullType, transferAction.wmiBeforeIds)
            if fresh then
                movedItem = fresh
            end
        end

        if not movedItem then
            log("AfterTransfer -> movedItem resolved to nil")
            return
        end

        local bloodAmount, dirtAmount = _computeWashAmounts(movedItem)

        -- For transforming items (ItemAfterCleaning), pass the original container so the shared patch can return the NEW item.
        local returnContainer = (willTransform and originalContainer) or nil

        local washAction = WMI_NewWashAction(playerObj, sink, soapList, movedItem, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
        ISTimedActionQueue.addAfter(transferAction, washAction)

        -- Non-transform items can be returned by transferring the same object back.
        if (not willTransform) and originalContainer and (originalContainer ~= playerInv) then
            local back = ISInventoryTransferAction:new(playerObj, movedItem, playerInv, originalContainer)
            if back.setAllowMissingItems then back:setAllowMissingItems(true) end
            ISTimedActionQueue.addAfter(washAction, back)
        end
    end

    for _, item in ipairs(items) do
        if item then
            local originalContainer = item:getContainer()
            local willTransform = false
            if item.getItemAfterCleaning then
                local afterType = item:getItemAfterCleaning()
                willTransform = afterType ~= nil and afterType ~= ""
            end

            if originalContainer and (originalContainer ~= playerInv) then
                local xfer = ISInventoryTransferAction:new(playerObj, item, originalContainer, playerInv)
                -- Record a snapshot when the transfer STARTS (not when it is created),
                -- so we can detect the newly-added item in the main inventory (handles MP stack splitting).
                xfer.wmiFullType = item:getFullType()
                local _wmiOrigStart = xfer.start
                function xfer:start()
                    self.wmiBeforeIds = _snapshotIdsByFullType(self.wmiFullType)
                    if _wmiOrigStart then _wmiOrigStart(self) end
                end

                if xfer.setAllowMissingItems then xfer:setAllowMissingItems(true) end
                xfer:setOnComplete(afterTransfer, xfer, originalContainer, willTransform)
                ISTimedActionQueue.add(xfer)
            else
                local bloodAmount, dirtAmount = _computeWashAmounts(item)
                local returnContainer = (willTransform and originalContainer) or nil
                ISTimedActionQueue.add(WMI_NewWashAction(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride))
            end
        end
    end

    if closeCtx and closeCtx.closeAll then
        closeCtx:closeAll()
    end
end

-- ---------------------------------------------------------------------------
-- Menu building and actions
-- ---------------------------------------------------------------------------

local function _collectTuples(playerObj)
    local inv = playerObj:getInventory()
    local tuples = {}
    for _, def in ipairs(DIRTY_DEFS) do
        local items = _getAllTypeRecurse(inv, def.dirty)
        local count = #items
        if count > 0 then
            table.insert(tuples, {
                dirtyType = def.dirty,
                cleanType = def.clean,
                label     = _getItemDisplayName(def.dirty),
                iconTexture = _getItemIconTextureOrFallback(def.dirty, nil),
                count     = count,
            })
        end
    end
    return tuples
end

local function _insertOptionAfter(subMenu, afterName, opt)
    if not subMenu or not subMenu.options then return end
    local idx = nil
    for i, o in ipairs(subMenu.options) do
        if o and o.name == afterName then idx = i break end
    end
    if not idx then return end
    -- Move the newly-added option to be right after "afterName"
    for i, o in ipairs(subMenu.options) do
        if o == opt then
            table.remove(subMenu.options, i)
            break
        end
    end
    table.insert(subMenu.options, idx + 1, opt)
end

local function _buildCleanBandagesMenu(subMenu, playerObj, sink)
    local waterAmount = (sink and sink.getFluidAmount and sink:getFluidAmount()) or 0
    if not sink or waterAmount < 1 then return end

    local tuples = _collectTuples(playerObj)
    if #tuples == 0 then return end

    local isTainted = sink.isTaintedWater and sink:isTaintedWater() or false
    local allowTainted = _allowTaintedWater()
    local notAvail = isTainted and (not allowTainted)

    local tip = nil
    if isTainted and _showTaintedTooltip() then
        tip = _makeTaintedTooltip(allowTainted)
    end

    local CLEAN = getText("ContextMenu_CleanBandageEtc") or "Clean Bandages"
    local WASH  = getText("ContextMenu_Wash") or "Wash"

    -- Add the branch option first, then move it right after "Wash"
    local optRoot = subMenu:addOption(CLEAN)
    if tip then optRoot.toolTip = tip end
    optRoot.notAvailable = notAvail

    -- Give the root entry an icon (bandage/first available type).
    local rootIcon = (tuples[1] and tuples[1].iconTexture) or _getItemIconTextureOrFallback("Base.Bandage", nil)
    if rootIcon then optRoot.iconTexture = rootIcon end

    local rootSub = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(optRoot, rootSub)

    _insertOptionAfter(subMenu, WASH, optRoot)

    -- Build soap list once (for actions). We still compute "noSoap" per selection.
    local soapList = _buildSoapList(playerObj)
    local soapRemaining = 0
    if soapList and #soapList >= 1 then
        soapRemaining = ISWashClothing.GetSoapRemaining(soapList)
    end

    -- ALL (across all dirty types), capped by available water
    local allItems = {}
    for _, t in ipairs(tuples) do
        local items = _getAllTypeRecurse(playerObj:getInventory(), t.dirtyType)
        for _, it in ipairs(items) do table.insert(allItems, it) end
    end

    local waterRemaining = waterAmount
    local waterPerItem = _bandageWaterPerItem()
    local selectedAll = _selectByWater(allItems, waterRemaining, waterPerItem)
    local totalN = #allItems
    local totaln = #selectedAll

    local optAll = rootSub:addActionsOption(getText("ContextMenu_AllWithCount", totaln),
        function(pObj, sinkObj, selected, soapListRef, soapRemain)
            -- Decide if we have enough soap for this batch
            local reqSoap = 0
            for _, it in ipairs(selected) do
                reqSoap = reqSoap + ISWashClothing.GetRequiredSoap(it)
            end
            local noSoap = reqSoap > soapRemain
            _queueWashItemsSequential(pObj, sinkObj, soapListRef, selected, rootSub, noSoap, waterPerItem)
        end,
        sink, selectedAll, soapList, soapRemaining
    )
    optAll.iconTexture = nil
    if tip then optAll.toolTip = tip end
    optAll.notAvailable = notAvail

    -- Per-type entries
    for _, t in ipairs(tuples) do
        local items = _getAllTypeRecurse(playerObj:getInventory(), t.dirtyType)
        local selected = _selectByWater(items, waterRemaining, waterPerItem)

        if t.count > 1 then
            local optType = rootSub:addOption(t.label)
            -- Use the clean-item icon for this type (if available).
            if t.iconTexture then optType.iconTexture = t.iconTexture end
            if tip then optType.toolTip = tip end
            optType.notAvailable = notAvail

            local typeSub = ISContextMenu:getNew(rootSub)
            rootSub:addSubMenu(optType, typeSub)

            -- One
            local optOne = typeSub:addActionsOption(getText("ContextMenu_One"),
                function(pObj, sinkObj, dirtyType, soapListRef)
                    local its = _getAllTypeRecurse(pObj:getInventory(), dirtyType)
                    if #its == 0 then return end
                    _queueWashItemsSequential(pObj, sinkObj, soapListRef, { its[1] }, typeSub, false, waterPerItem)
                end,
                sink, t.dirtyType, soapList
            )
            if t.iconTexture then optOne.iconTexture = t.iconTexture end
            if tip then optOne.toolTip = tip end
            optOne.notAvailable = notAvail

            -- All (this type)
            local optMany = typeSub:addActionsOption(getText("ContextMenu_AllWithCount", #selected),
                function(pObj, sinkObj, selectedList, soapListRef, soapRemain)
                    local reqSoap = 0
                    for _, it in ipairs(selectedList) do
                        reqSoap = reqSoap + ISWashClothing.GetRequiredSoap(it)
                    end
                    local noSoap = reqSoap > soapRemain
                    _queueWashItemsSequential(pObj, sinkObj, soapListRef, selectedList, typeSub, noSoap, waterPerItem)
                end,
                sink, selected, soapList, soapRemaining
            )
            if t.iconTexture then optMany.iconTexture = t.iconTexture end
            if tip then optMany.toolTip = tip end
            optMany.notAvailable = notAvail
        else
            -- Single entry
            local opt = rootSub:addActionsOption(t.label,
                function(pObj, sinkObj, dirtyType, soapListRef)
                    local its = _getAllTypeRecurse(pObj:getInventory(), dirtyType)
                    if #its == 0 then return end
                    _queueWashItemsSequential(pObj, sinkObj, soapListRef, { its[1] }, rootSub, false, waterPerItem)
                end,
                sink, t.dirtyType, soapList
            )
            if t.iconTexture then opt.iconTexture = t.iconTexture end
            if tip then opt.toolTip = tip end
            opt.notAvailable = notAvail
        end
    end
end

-- ---------------------------------------------------------------------------
-- Water submenu discovery (same idea as before, but simpler)
-- ---------------------------------------------------------------------------

local function _getSubMenuFromOption(rootContext, opt)
    if not rootContext or not opt then return nil end
    local id = opt.subOption
    if not id then return nil end
    return rootContext:getSubMenu(id)
end

local function _isWaterSource(obj)
    if not obj or type(obj) ~= "userdata" then return false end
    if obj.getFluidAmount then
        local ok, amt = pcall(function() return obj:getFluidAmount() end)
        if ok and type(amt) == "number" and amt > 0 then return true end
    end
    if obj.hasWater and obj:hasWater() then return true end
    return false
end

local function _findWaterObjectInSubMenu(subMenu)
    for _, ch in ipairs(subMenu.options or {}) do
        for i = 1, 6 do
            local p = ch["param"..i]
            if _isWaterSource(p) then
                return p
            end
        end
    end
    return nil
end

local function _iterWaterSubmenus(context)
    local tDrink  = getText("ContextMenu_Drink")  or "Drink"
    local tFill   = getText("ContextMenu_Fill")   or "Fill"
    local tRefill = getText("ContextMenu_Refill") or "Refill"
    local tWash   = getText("ContextMenu_Wash")   or "Wash"

    local out = {}
    for _, top in ipairs(context.options or {}) do
        local sub = _getSubMenuFromOption(context, top)
        if sub and sub.options then
            local hasDrink, hasFill, hasWash = false, false, false
            for _, ch in ipairs(sub.options) do
                local n = ch.name
                if n == tDrink then hasDrink = true end
                if n == tFill or n == tRefill then hasFill = true end
                if n == tWash then hasWash = true end
            end
            if hasWash and (hasDrink or hasFill) then
                local waterObj = _findWaterObjectInSubMenu(sub)
                if waterObj then
                    table.insert(out, { sub = sub, water = waterObj })
                end
            end
        end
    end
    return out
end

-- Public helper used by compatibility shims (e.g., TABAS bathtubs) that need to inject this menu into a custom submenu.
function WMI_Clean.injectIntoSubMenu(targetMenu, playerObj, sink)
    -- targetMenu: ISContextMenu to receive the "Clean Bandages" option
    -- playerObj: IsoPlayer
    -- sink: water source IsoObject
    _buildCleanBandagesMenu(targetMenu, playerObj, sink)
end

-- ---------------------------------------------------------------------------
-- Event hooks
-- ---------------------------------------------------------------------------

local function onFill(player, context, worldobjects, test)
    if test then return end

    local entries = _iterWaterSubmenus(context)
    if #entries == 0 then return end

    local CLEAN = getText("ContextMenu_CleanBandageEtc") or "Clean Bandages"
    local injected = 0

    for _, e in ipairs(entries) do
        local sub = e.sub
        local sink = e.water

        -- Dedup: don't inject twice into the same submenu
        local already = false
        for _, opt in ipairs(sub.options or {}) do
            if opt and opt.name == CLEAN then
                already = true
                break
            end
        end
        if not already then
            local playerObj = getSpecificPlayer(player)
            _buildCleanBandagesMenu(sub, playerObj, sink)
            injected = injected + 1
        end
    end

    log("OnFill -> injected on", injected, "submenus")
end

Events.OnFillWorldObjectContextMenu.Add(onFill)

return WMI_Clean
