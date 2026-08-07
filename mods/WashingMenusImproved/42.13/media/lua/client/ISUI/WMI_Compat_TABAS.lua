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

    -- Remove existing Wash/Clean options using vanilla helper (shifts array, avoids nil holes).
    if targetMenu.removeOptionByName then
        targetMenu:removeOptionByName(tWash)
        targetMenu:removeOptionByName(tClean)
    end

    _sanitizeMenuOptions(targetMenu)

    -- Add WMI Wash at the end of this submenu.
    WS.WMI_BuildWashMenu(targetMenu, worldobjects, playerObj, waterObj, rootContext or targetMenu)

    -- Add Clean Bandages right after.
    if WMI_Clean and WMI_Clean.injectIntoSubMenu then
        WMI_Clean.injectIntoSubMenu(targetMenu, playerObj, waterObj)
    end

    _sanitizeMenuOptions(targetMenu)

    return true
end

-- Inject WMI menus into TABAS bathtub submenu (append at end of the "White Bath" root submenu).
local function _tryInjectBath(playerNum, context, worldobjects, bathObj)
    local TABAS_Utils = _getTABASUtils()
    if not TABAS_Utils or not bathObj then return false end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return false end

    local faucetObj = nil
    if TABAS_Utils.getFullyBathObject then
        local ok, f = pcall(TABAS_Utils.getFullyBathObject, bathObj)
        if ok and f then
            faucetObj = f
        end
    end
    -- Fallback: use bath object itself as "water object".
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

    -- Append WMI Wash
    if WS and WS.WMI_BuildWashMenu then
        _log("Injecting WMI Wash menu (bath)")
        WS.WMI_BuildWashMenu(bathSub, worldobjects, playerObj, faucetObj, context)
    else
        _log("WS.WMI_BuildWashMenu not available")
    end

    -- Append Clean Bandages
    if WMI_Clean and WMI_Clean.injectIntoSubMenu then
        _log("Injecting WMI Clean Bandages menu (bath)")
        WMI_Clean.injectIntoSubMenu(bathSub, playerObj, faucetObj)
    else
        _log("WMI_Clean.injectIntoSubMenu not available")
    end

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

    -- Detect bath / shower objects from TABAS sprite lists.
    local bathObj = nil
    if TABAS_Utils.getBathSprites and TABAS_Utils.getObjectFromWorldObjects then
        local sprites = TABAS_Utils.getBathSprites()
        bathObj = TABAS_Utils.getObjectFromWorldObjects(worldobjects, sprites)
    end

    local showerObj = nil
    if (not bathObj) and TABAS_Utils.getShowerSprites and TABAS_Utils.getObjectFromWorldObjects then
        local sprites = TABAS_Utils.getShowerSprites()
        showerObj = TABAS_Utils.getObjectFromWorldObjects(worldobjects, sprites)
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
