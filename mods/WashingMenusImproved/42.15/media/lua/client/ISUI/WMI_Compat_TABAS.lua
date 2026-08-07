-- WMI_Compat_TABAS.lua
-- Compatibility shim for the "Take A Bath And Shower" (TABAS) mod (B42.13+).
--
-- Goals:
--  1) Bathtubs: add WMI "Wash" + "Clean Bandages" to the end of the TABAS bathtub root submenu ("White Bath", etc.)
--  2) Showers: replace TABAS/vanilla "Wash" inside the TABAS shower root submenu with WMI "Wash",
--     and then place WMI "Clean Bandages" right after it.
--
-- Notes:
--  - TABAS nests its menus differently for baths vs showers.
--  - Event ordering depends on mod load order. We register our OnFill handler via OnTick so we end up AFTER TABAS.

require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISContextMenu"

-- WMI Clean Bandages module (exposes injectIntoSubMenu in our mod).
local WMI_Clean = require "ISUI/WMI_CleanBandagesContext"

-- Toggle TABAS-compat debug logs (set true temporarily while debugging).
local WMI_TABAS_DEBUG = false

-- Cache the TABAS enabled state.
-- Mods cannot be enabled/disabled while a save is running, so we compute this once.
local _TABAS_ACTIVE = nil

-- Cached TABAS utils module.
local _TABAS_Utils = nil

-- Cached TABAS iso helper module (42.15+ uses TABAS_Iso for bath/shower object linking).
local _TABAS_Iso = nil

-- Internal: debug logging helper.
local function _log(...)
    if not WMI_TABAS_DEBUG then return end
    local msg = ""
    for i = 1, select("#", ...) do
        msg = msg .. tostring(select(i, ...))
    end
    print("[WMI][TABAS] " .. msg)
end

-- Internal: normalize an activated mod id (TABAS may appear as "\TakeABathAndShower42" in some lists).
local function _normalizeModId(id)
    if not id then return nil end
    id = tostring(id)
    -- Strip leading slashes/backslashes.
    while #id > 0 do
        local c = id:sub(1, 1)
        if c == "\\" or c == "/" then
            id = id:sub(2)
        else
            break
        end
    end
    return id
end

-- Internal: compute whether TABAS is enabled (robust against leading "\\").
local function _computeTABASActive()
    -- TABAS does not publish globals in B42 (its modules are local and returned by require).
    -- So the most reliable low-cost signal is the activated mod list (normalized), with a fallback
    -- to package.loaded/require when that list isn't available yet.

    -- Fast-path: if TABAS modules are already loaded, TABAS is definitely active.
    if package and package.loaded then
        if package.loaded["TABAS_Utils"] or package.loaded["TABAS_ContextMenuCommon"] then
            _log("TABAS module already loaded (package.loaded)")
            return true
        end
    end

    -- Primary: scan activated mods once (handles leading \"\\" in ids).
    if getActivatedMods then
        local mods = getActivatedMods()
        if mods then
            local n = 0
            if mods.size then
                n = mods:size()
            elseif mods.getn then
                n = mods:getn()
            end
            _log("number of mods = " .. tostring(n))

            for i = 0, n - 1 do
                local id = nil
                if mods.get then
                    id = mods:get(i)
                else
                    id = mods[i + 1]
                end
                id = _normalizeModId(id)
                if id and id:find("TakeABathAndShower", 1, true) then
                    _log("TakeABathAndShower found. i = " .. tostring(i))
                    return true
                end
            end
            return false
        end
    end

    -- Fallback: try requiring TABAS_Utils (rare; mainly if called too early in load).
    local ok, mod = pcall(require, "TABAS_Utils")
    if ok and mod then
        _TABAS_Utils = mod
        _log("TABAS_Utils available (fallback require)")
        return true
    end

    return false
end

-- Internal: cached check to avoid repeatedly scanning getActivatedMods() in SP/MP.
local function _isTABASActive()
    if _TABAS_ACTIVE ~= nil then
        return _TABAS_ACTIVE
    end
    _log("function _isTABASActive() computing once")
    _TABAS_ACTIVE = _computeTABASActive()
    return _TABAS_ACTIVE
end

-- Internal: safe require for TABAS_Utils.
local function _getTABASUtils()
    if _TABAS_Utils then return _TABAS_Utils end
    local ok, mod = pcall(require, "TABAS_Utils")
    if ok and mod then
        _TABAS_Utils = mod
        _log("TABAS_Utils loaded")
        return _TABAS_Utils
    end
    return nil
end

-- Internal: safe require for TABAS_Iso (TABAS 42.15+)
local function _getTABASIso()
    if _TABAS_Iso then return _TABAS_Iso end
    local ok, mod = pcall(require, "TABAS_Iso")
    if ok and mod then
        _TABAS_Iso = mod
        _log("TABAS_Iso loaded")
    end
    return _TABAS_Iso
end

-- Internal: get the "moveable display name" for an IsoObject (B42.13+ supports helper; fall back to sprite props).
local function _getMoveableDisplayName(obj)
    if not obj then return nil end

    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.getMoveableDisplayName then
        local ok, v = pcall(ISWorldObjectContextMenu.getMoveableDisplayName, obj)
        if ok then return v end
    end

    if obj.getSprite and obj:getSprite() then
        local props = obj:getSprite():getProperties()
        if props then
            -- Support both old and new PropertyContainer APIs.
            local hasProp = props.has or props.Is
            local getProp = props.get or props.Val
            if hasProp and getProp and hasProp(props, "CustomName") then
                local name = getProp(props, "CustomName")
                if hasProp(props, "GroupName") then
                    name = tostring(getProp(props, "GroupName")) .. " " .. tostring(name)
                end
                if Translator and Translator.getMoveableDisplayName then
                    return Translator.getMoveableDisplayName(name)
                end
                return name
            end
        end
    end

    return nil
end

-- Internal: find a root submenu by its option name.
local function _findRootSubMenuByName(context, optionName)
    if not context or not context.options or not optionName then return nil end
    for _, opt in ipairs(context.options) do
        if opt and opt.name == optionName then
            if context.getSubMenu and opt.subOption then
                return context:getSubMenu(opt.subOption)
            end
            if opt.subMenu then
                return opt.subMenu
            end
        end
    end
    return nil
end

-- Internal: replace a target menu's existing "Wash" option with WMI's structured one, then ensure "Clean Bandages"
-- is positioned immediately after it.
local function _sanitizeMenuOptions(menu)
    -- Repack options to avoid Lua 'nil' holes or Java 'null' entries.
    -- Holes can cause render/ipairs to stop early (menu looks truncated) while numOptions remains high (scroll arrows appear).
    if not menu or not menu.options then return end

    local nullObj = rawget(_G, "null") -- may be nil if not present

    -- Find the maximum numeric key without sorting (faster than collecting + sort).
    local maxKey = 0
    for k, _ in pairs(menu.options) do
        if type(k) == "number" and k > maxKey then
            maxKey = k
        end
    end

    local packed = {}
    for i = 1, maxKey do
        local opt = menu.options[i]
        if opt ~= nil and opt ~= nullObj then
            packed[#packed + 1] = opt
        end
    end

    menu.options = packed

    -- ISContextMenu invariant: #options == (numOptions - 1)
    menu.numOptions = #packed + 1

    -- Ensure option.id matches the array index (some vanilla helpers rebuild options using v.id)
    for i, opt in ipairs(packed) do
        if type(opt) == "table" then
            opt.id = i
        end
    end

    if menu.calcHeight then menu:calcHeight() end
    if menu.calcWidth and menu.setWidth then
        menu:setWidth(menu:calcWidth())
    end
end

local function _removeAllOptionsByName(menu, optName)
    -- Remove all entries with the same visible name.
    -- ISContextMenu:removeOptionByName() only removes the first match, which is not enough
    -- when another mod (or an earlier helper call) already duplicated a menu entry.
    if not menu or not optName or not menu.removeOptionByName or not menu.getOptionFromName then
        return 0
    end

    local removed = 0
    while menu:getOptionFromName(optName) do
        menu:removeOptionByName(optName)
        removed = removed + 1
    end
    return removed
end

local function _menuHasFluidOptions(menu)
    if not menu or not menu.getOptionFromName then return false end
    local tDrink = (getText and getText("ContextMenu_Drink")) or "Drink"
    local tFill = (getText and getText("ContextMenu_Fill")) or "Fill"
    local tWash = (getText and getText("ContextMenu_Wash")) or "Wash"
    return menu:getOptionFromName(tDrink) or menu:getOptionFromName(tFill) or menu:getOptionFromName(tWash)
end

local function _replaceWashWithWMI(targetMenu, playerObj, waterObj, worldobjects, rootContext)
    -- Replace TABAS/vanilla Wash option with WMI Wash and add Clean Bandages right after.
    -- This must be robust against sparse option tables because ISContextMenu:render() uses ipairs(self.options)
    -- (a nil hole will truncate rendering and cause bogus scroll arrows).
    if not targetMenu or not playerObj or not waterObj then return false end

    local tWash = (getText and getText("ContextMenu_Wash")) or "Wash"
    local tClean = (getText and getText("ContextMenu_CleanBandageEtc")) or "Clean Bandages"

    -- Pack options before touching them (fixes any pre-existing holes/nulls).
    _sanitizeMenuOptions(targetMenu)

    -- Preflight: build WMI Wash in a temporary menu.
    -- If it wouldn't add a Wash option (e.g., nothing to wash / blocked by building check),
    -- keep the existing TABAS Wash to avoid removing it and leaving a blank slot.
    local canBuild = false
    if WS and WS.WMI_BuildWashMenu and ISContextMenu and ISContextMenu.getNew then
        local tmpMenu = ISContextMenu:getNew(rootContext or targetMenu)
        WS.WMI_BuildWashMenu(tmpMenu, worldobjects, playerObj, waterObj, rootContext or targetMenu)
        if tmpMenu.getOptionFromName and tmpMenu:getOptionFromName(tWash) then
            canBuild = true
        end
    end


    -- Fallback: TABAS shower objects are not always valid water sources (depending on load order / TABAS version).
    -- Try to find a working water object from the existing submenu option params (Drink/Fill/etc) by preflighting WMI_BuildWashMenu.
    if not canBuild and targetMenu and targetMenu.options and WS and WS.WMI_BuildWashMenu and ISContextMenu and ISContextMenu.getNew then
        local seen = {}
        for _, opt in ipairs(targetMenu.options) do
            if type(opt) == "table" then
                for i = 1, 6 do
                    local p = opt["param" .. i]
                    if p and type(p) == "userdata" then
                        local key = tostring(p)
                        if not seen[key] then
                            seen[key] = true
                            local ok, found = pcall(function()
                                local tmpMenu = ISContextMenu:getNew(rootContext or targetMenu)
                                WS.WMI_BuildWashMenu(tmpMenu, worldobjects, playerObj, p, rootContext or targetMenu)
                                if tmpMenu.getOptionFromName and tmpMenu:getOptionFromName(tWash) then
                                    return p
                                end
                                return nil
                            end)
                            if ok and found then
                                waterObj = found
                                canBuild = true
                                break
                            end
                        end
                    end
                end
            end
            if canBuild then break end
        end
    end
    if not canBuild then
        _log("WMI Wash preflight produced no option; keeping existing Wash")
        return false
    end

    -- Remove every existing Wash/Clean entry before inserting WMI's replacements.
    -- This prevents leftover TABAS/vanilla "Wash" entries when a submenu already contains duplicates.
    _removeAllOptionsByName(targetMenu, tWash)
    _removeAllOptionsByName(targetMenu, tClean)

    _sanitizeMenuOptions(targetMenu)

    -- Add WMI Wash at the end of this submenu.
    WS.WMI_BuildWashMenu(targetMenu, worldobjects, playerObj, waterObj, rootContext or targetMenu)

    -- Add Clean Bandages right after.
    if WMI_Clean and WMI_Clean.injectIntoSubMenu then
        _log("Injecting WMI Clean Bandages (sink=" .. tostring(waterObj) .. ")")
        WMI_Clean.injectIntoSubMenu(targetMenu, playerObj, waterObj)
    else
        _log("WMI_Clean.injectIntoSubMenu not available")
    end

    _sanitizeMenuOptions(targetMenu)

    return true
end

-- Internal: collect inventory items that can receive water using the modern B42 fluid-container API.
local function _collectFillTargets(playerObj)
    local items = {}
    if not playerObj or not playerObj.getInventory then return items end

    local inv = playerObj:getInventory()
    if not inv or not inv.getAllEvalRecurse then return items end

    local function _canFill(item)
        if not item or not item.getFluidContainer then return false end
        local fluidContainer = item:getFluidContainer()
        if not fluidContainer then return false end
        if fluidContainer.isFull and fluidContainer:isFull() then return false end
        if Fluid and Fluid.Water and fluidContainer.canAddFluid then
            return fluidContainer:canAddFluid(Fluid.Water)
        end
        return true
    end

    local javaList = inv:getAllEvalRecurse(_canFill)
    if not javaList then return items end

    for i = 0, javaList:size() - 1 do
        items[#items + 1] = javaList:get(i)
    end
    return items
end

-- Internal: group inventory items by display name for the fallback Fill submenu.
local function _groupItemsByName(items)
    table.sort(items, function(a, b)
        return tostring(a:getName()):lower() < tostring(b:getName()):lower()
    end)

    local grouped = {}
    local current = {}
    local previousName = nil

    for _, item in ipairs(items) do
        local name = tostring(item:getName())
        if previousName and name ~= previousName then
            grouped[#grouped + 1] = current
            current = {}
        end
        current[#current + 1] = item
        previousName = name
    end

    if #current > 0 then
        grouped[#grouped + 1] = current
    end

    return grouped
end

-- Internal: let TABAS build Drink/Fill when possible, then fall back to a minimal modern B42 implementation.
local function _ensureFluidOptions(playerNum, targetMenu, waterObj, worldobjects)
    if not targetMenu or not waterObj or not worldobjects then return false end

    local tDrink = (getText and getText("ContextMenu_Drink")) or "Drink"
    local tFill = (getText and getText("ContextMenu_Fill")) or "Fill"

    local function _hasFluidOptions()
        return targetMenu.getOptionFromName and (targetMenu:getOptionFromName(tDrink) or targetMenu:getOptionFromName(tFill))
    end

    -- If TABAS already populated this submenu, do not ask it to build the fluid menu again.
    -- Rebuilding here duplicates entries such as Drink/Wash inside the bathtub Faucet Water submenu.
    _sanitizeMenuOptions(targetMenu)
    if _menuHasFluidOptions(targetMenu) then
        return true
    end

    -- First try TABAS' own helper. In 42.16+ this preserves TABAS' richer tooltips and grouping.
    local okCommon, TABAS_Common = pcall(require, "ContextMenu/TABAS_ContextMenuCommon")
    if okCommon and TABAS_Common and TABAS_Common.vanillaFluidMenu then
        pcall(TABAS_Common.vanillaFluidMenu, playerNum, waterObj, targetMenu, worldobjects)
        if _hasFluidOptions() then
            return true
        end

        -- Older 42.15 builds used a different signature for the same helper.
        pcall(TABAS_Common.vanillaFluidMenu, playerNum, worldobjects, false, waterObj, targetMenu)
        if _hasFluidOptions() then
            return true
        end
    end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return false end

    -- Generic Drink fallback using the current vanilla world-object action.
    if targetMenu.getOptionFromName and (not targetMenu:getOptionFromName(tDrink)) and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onDrink then
        targetMenu:addOption(tDrink, worldobjects, ISWorldObjectContextMenu.onDrink, waterObj, playerNum)
    end

    -- Generic Fill fallback using the current vanilla world-object action.
    if targetMenu.getOptionFromName and (not targetMenu:getOptionFromName(tFill)) and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onTakeWater then
        local containers = _collectFillTargets(playerObj)
        local validContainers = {}

        for i = 1, #containers do
            local item = containers[i]
            local fluidContainer = (item and item.getFluidContainer) and item:getFluidContainer() or nil
            if fluidContainer and waterObj.canTransferFluidTo and waterObj:canTransferFluidTo(fluidContainer) then
                validContainers[#validContainers + 1] = item
            end
        end

        if #validContainers == 1 then
            local option = targetMenu:addOption(tFill, worldobjects, ISWorldObjectContextMenu.onTakeWater, waterObj, nil, validContainers[1], playerNum)
            if option then option.itemForTexture = validContainers[1] end
        elseif #validContainers > 1 then
            local fillOption = targetMenu:addOption(tFill)
            local fillSubMenu = ISContextMenu:getNew(targetMenu)
            targetMenu:addSubMenu(fillOption, fillSubMenu)

            local fillAllText = (getText and getText("ContextMenu_FillAll")) or "Fill All"
            fillSubMenu:addOption(fillAllText, worldobjects, ISWorldObjectContextMenu.onTakeWater, waterObj, validContainers, nil, playerNum)

            local fillOneText = (getText and getText("ContextMenu_FillOne")) or "Fill One"
            local groupedContainers = _groupItemsByName(validContainers)
            for _, group in ipairs(groupedContainers) do
                local item = group[1]
                if #group > 1 then
                    local groupOption = fillSubMenu:addOption(item:getName() .. " (" .. #group .. ")", worldobjects, nil)
                    if groupOption then groupOption.itemForTexture = item end

                    local groupSubMenu = ISContextMenu:getNew(fillSubMenu)
                    fillSubMenu:addSubMenu(groupOption, groupSubMenu)

                    local fillOneOption = groupSubMenu:addOption(fillOneText, worldobjects, ISWorldObjectContextMenu.onTakeWater, waterObj, nil, item, playerNum)
                    if fillOneOption then fillOneOption.itemForTexture = item end

                    local fillAllOption = groupSubMenu:addOption(fillAllText, worldobjects, ISWorldObjectContextMenu.onTakeWater, waterObj, group, nil, playerNum)
                    if fillAllOption then fillAllOption.itemForTexture = item end
                else
                    local option = fillSubMenu:addOption(item:getName(), worldobjects, ISWorldObjectContextMenu.onTakeWater, waterObj, nil, item, playerNum)
                    if option then option.itemForTexture = item end
                end
            end
        end
    end

    return _hasFluidOptions() and true or false
end

-- Inject WMI menus into TABAS bathtub submenu (append at end of the "White Bath" root submenu).
local function _tryInjectBath(playerNum, context, worldobjects, bathObj)
    local TABAS_Utils = _getTABASUtils()
    if not TABAS_Utils or not bathObj then return false end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return false end

    local faucetObj, tubObj = nil, nil

    -- TABAS 42.15+: object linking helpers moved to TABAS_Iso
    local TABAS_Iso = _getTABASIso()
    if TABAS_Iso and TABAS_Iso.getFullyBathObject then
        local ok, f, t = pcall(TABAS_Iso.getFullyBathObject, bathObj)
        if ok and f then
            faucetObj = f
            tubObj = t
        end
    end

    -- Legacy fallback (older TABAS builds)
    if (not faucetObj) and TABAS_Utils.getFullyBathObject then
        local ok, f, t = pcall(TABAS_Utils.getFullyBathObject, bathObj)
        if ok and f then
            faucetObj = f
            tubObj = t
        end
    end

    -- Final fallback: use bath object itself as "water object".
    if not faucetObj then faucetObj = bathObj end

    local displayName = _getMoveableDisplayName(faucetObj) or _getMoveableDisplayName(bathObj)
    _log("Looking for TABAS root submenu. displayName= " .. tostring(displayName))

    local bathSub = _findRootSubMenuByName(context, displayName)
    if not bathSub then
        _log("Bath detected but TABAS bath submenu not found yet (will retry)")
        return false
    end

    if bathSub._wmiTABASInjectedBath then
        return true
    end
    bathSub._wmiTABASInjectedBath = true

    -- Prefer injecting into the TABAS "Faucet Water" submenu (if present), since TABAS nests fluid actions there.
    local targetMenu = bathSub
    local tFaucet = (getText and getText("ContextMenu_TABAS_FaucetMenu")) or "Faucet Water"
    local faucetOpt = bathSub.getOptionFromName and bathSub:getOptionFromName(tFaucet) or nil
    if faucetOpt then
        local faucetSub = nil
        if bathSub.getSubMenu and faucetOpt.subOption then
            faucetSub = bathSub:getSubMenu(faucetOpt.subOption)
        end
        if (not faucetSub) and faucetOpt.subMenu then
            faucetSub = faucetOpt.subMenu
        end
        if faucetSub then
            targetMenu = faucetSub
        end
    end

    -- TABAS 42.15 note:
    -- Some TABAS builds leave "Faucet Water" empty. Prefer TABAS' own helper when it exists,
    -- then fall back to a minimal modern Drink/Fill builder that works with the patched TABAS fluid actions.
    _ensureFluidOptions(playerNum, targetMenu, faucetObj, worldobjects)

    if WS and WS.WMI_BuildWashMenu then
        if targetMenu ~= bathSub then
            _log("Injecting WMI Wash + Clean Bandages into Faucet Water submenu (bath)")
        else
            _log("Injecting WMI Wash + Clean Bandages into bathtub root submenu (bath)")
        end
        -- This is safe even if there is no existing Wash option: it will append WMI Wash at the end.
        -- If WMI has nothing to wash, it will keep the existing TABAS/vanilla Wash unchanged.
        _replaceWashWithWMI(targetMenu, playerObj, faucetObj, worldobjects, context)
    else
        _log("WS.WMI_BuildWashMenu not available")
    end

    _sanitizeMenuOptions(targetMenu)

    return true
end

-- Inject / replace WMI Wash + Clean Bandages inside TABAS shower submenu.
local function _tryInjectShower(playerNum, context, worldobjects, showerObj)
    if not showerObj then return false end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return false end

    local displayName = _getMoveableDisplayName(showerObj)
    _log("Looking for TABAS shower root submenu. displayName= " .. tostring(displayName))

    local showerSub = _findRootSubMenuByName(context, displayName)
    if not showerSub then
        _log("Shower detected but TABAS shower submenu not found yet (will retry)")
        return false
    end

    if showerSub._wmiTABASInjectedShower then
        return true
    end

    _log("Replacing TABAS shower Wash with WMI Wash")
    local ok = _replaceWashWithWMI(showerSub, playerObj, showerObj, worldobjects, context)
    if ok then
        showerSub._wmiTABASInjectedShower = true
        return true
    end
    return false
end

-- Deferred retries (handles event-order differences).
local _retryBath = nil
local _retryShower = nil

local function _scheduleRetry(fnName, tickFn)
    if not Events or not Events.OnTick or not Events.OnTick.Add then return end
    Events.OnTick.Add(tickFn)
end

-- OnFill handler
local function _onFill(playerNum, context, worldobjects, test)
    _log("function _onFill started")
    if test then return end
    if not _isTABASActive() then return end

    local TABAS_Utils = _getTABASUtils()
    if not TABAS_Utils then return end

    -- Detect bath / shower objects.
    -- TABAS 42.15+ uses TABAS_Iso.getBathingObjectFromWorldObjects(worldObjects) -> (object, "Bathtub"/"Shower")
    -- Older TABAS versions (42.13/42.14 era) used TABAS_Utils sprite lists. We support both.
    local bathObj = nil
    local showerObj = nil

    local okIso, TABAS_Iso = pcall(require, "TABAS_Iso")
    if okIso and TABAS_Iso and TABAS_Iso.getBathingObjectFromWorldObjects then
        local ok, obj, objType = pcall(TABAS_Iso.getBathingObjectFromWorldObjects, worldobjects)
        if ok and obj and objType then
            if objType == "Bathtub" then
                bathObj = obj
            elseif objType == "Shower" then
                showerObj = obj
            end
        end
    end

    -- Fallback for older TABAS builds.
    if (not bathObj) and (not showerObj) and TABAS_Utils then
        if TABAS_Utils.getBathSprites and TABAS_Utils.getObjectFromWorldObjects then
            local sprites = TABAS_Utils.getBathSprites()
            bathObj = TABAS_Utils.getObjectFromWorldObjects(worldobjects, sprites)
        end

        if (not bathObj) and TABAS_Utils.getShowerSprites and TABAS_Utils.getObjectFromWorldObjects then
            local sprites = TABAS_Utils.getShowerSprites()
            showerObj = TABAS_Utils.getObjectFromWorldObjects(worldobjects, sprites)
        end
    end

    if bathObj then
        _log("Bath detected. player= " .. tostring(playerNum))

        if _tryInjectBath(playerNum, context, worldobjects, bathObj) then
            return
        end

        -- Retry for a few ticks until TABAS has built its root submenu.
        -- If the player right-clicks repeatedly, remove any previous retry callback to avoid stacking tick handlers.
        if _retryBath and Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(_retryBath)
        end
        local tries = 0
        _retryBath = function()
            tries = tries + 1
			_log("Bath detected. tries = " .. tostring(tries))
            if _tryInjectBath(playerNum, context, worldobjects, bathObj) then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(_retryBath)
                end
                return
            end
            if tries >= 8 then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(_retryBath)
                end
            end
        end
        _scheduleRetry("bath", _retryBath)
        return
    end

    if showerObj then
        _log("Shower detected. player= " .. tostring(playerNum))

        -- Always defer shower injection to the next tick.
        -- When TABAS loads after WMI, TABAS may rebuild the shower submenu after our OnFill handler runs.
        -- Deferring ensures we run after all OnFill handlers and can reliably remove TABAS' vanilla-style Wash.

        -- If the player right-clicks repeatedly, remove any previous retry callback to avoid stacking tick handlers.
        if _retryShower and Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(_retryShower)
        end

        local tries = 0
        _retryShower = function()
            tries = tries + 1
			_log("Shower detected. tries = " .. tostring(tries))
            if _tryInjectShower(playerNum, context, worldobjects, showerObj) then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(_retryShower)
                end
                return
            end
            if tries >= 8 then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(_retryShower)
                end
            end
        end
        _scheduleRetry("shower", _retryShower)
        return
    end
end

-- ---------------------------------------------------------------------------
-- Registration
--
-- We register OnFill only when TABAS is enabled. This avoids any per-tick polling in MP when TABAS isn't active.
-- We don't rely on registration order: if TABAS builds its submenus after our handler runs,
-- our deferred retry logic will inject on the next tick.
if _isTABASActive() then
    if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
        Events.OnFillWorldObjectContextMenu.Add(_onFill)
        _log("Registered OnFillWorldObjectContextMenu handler")
    end
end
