-- WMI_Compat_TABAS.lua
-- Compatibility shim for the "Take A Bath And Shower" (TABAS) mod.
--
-- Goal:
--   Add WMI's structured "Wash" submenu + "Clean Bandages" submenu into TABAS's bathtub root submenu
--   (the one shown as "White Bath", etc.), instead of the nested faucet submenu.

require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISContextMenu"
local WMI_Clean = require "ISUI/WMI_CleanBandagesContext"

-- Toggle TABAS-compat debug logs.
-- Set to false once everything works to keep the console clean.
local WMI_TABAS_DEBUG = false

-- TABAS keeps its utils table LOCAL (TABAS_Utils = require("TABAS_Utils")) in its own files.
-- Do NOT rely on a global TABAS_Utils. We pcall(require) to avoid hard-depending on TABAS.
local _TABAS_Utils = nil

local _TABAS_ACTIVE = nil

local function _normalizeModId(id)
    if not id then return nil end
    id = tostring(id)
    -- Strip leading path separators (TABAS sometimes shows up as \TakeABathAndShower42).
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

local function _isTABASActive()
    if _TABAS_ACTIVE ~= nil then return _TABAS_ACTIVE end
    -- Avoid require() spam when TABAS is not enabled. Mods can't be toggled mid-session.
    local mods = (getActivatedMods and getActivatedMods()) or nil
    if not mods then _TABAS_ACTIVE = false; return false end
    local n = 0
    if mods.size then n = mods:size() elseif mods.getn then n = mods:getn() end
    for i = 0, n - 1 do
        local mid = mods.get and mods:get(i) or mods[i + 1]
        mid = _normalizeModId(mid)
        if mid and mid:find("TakeABathAndShower", 1, true) then
            _TABAS_ACTIVE = true
            return true
        end
    end
    _TABAS_ACTIVE = false
    return false
end


local function _log(...)
    if not WMI_TABAS_DEBUG then return end
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print("[WMI][TABAS] " .. table.concat(parts, " "))
end

local function _getTABASUtils()
    if _TABAS_Utils then return _TABAS_Utils end
    local ok, modOrErr = pcall(require, "TABAS_Utils")
    if ok then
        _TABAS_Utils = modOrErr
        _log("TABAS_Utils loaded")
        return _TABAS_Utils
    end
    _log("TABAS_Utils not available:", modOrErr)
    return nil
end

-- Check if TABAS is present and exposes the helpers we need.
local function _tabasAvailable()
    if not _isTABASActive() then return false end
    local TABAS_Utils = _getTABASUtils()
    return TABAS_Utils
        and TABAS_Utils.getBathSprites
        and TABAS_Utils.getObjectFromWorldObjects
        and TABAS_Utils.getFullyBathObject
end

-- Find the bathtub root submenu created by TABAS.
local function _findBathRootSubMenu(context, displayName)
    -- 1) Preferred: TABAS uses the faucet display name as the root option label.
    if displayName and context.getOptionFromName then
        local opt = context:getOptionFromName(displayName)
        if opt and opt.subOption then
            return context:getSubMenu(opt.subOption)
        end
    end

    -- 2) Fallback: scan for a submenu that contains TABAS's faucet-menu option.
    local tabasFaucetLabel = nil
    if getText then
        tabasFaucetLabel = getText("ContextMenu_TABAS_FaucetMenu")
    end
    if not tabasFaucetLabel or not context.options then return nil end

    for _, opt in ipairs(context.options) do
        if opt and opt.subOption then
            local sub = context:getSubMenu(opt.subOption)
            if sub and sub.getOptionFromName and sub:getOptionFromName(tabasFaucetLabel) then
                return sub
            end
        end
    end

    return nil
end

-- Inject WMI menus into TABAS bathtub submenu.
local function _onFill(playerNum, context, worldobjects, test)
    if test then return end
    if not _tabasAvailable() then return end

    local TABAS_Utils = _getTABASUtils()
    if not TABAS_Utils then return end

    -- Detect a bathtub among the clicked world objects (same logic TABAS uses).
    local bathSprites = TABAS_Utils.getBathSprites()
    local bathObj = TABAS_Utils.getObjectFromWorldObjects(worldobjects, bathSprites)
    if not bathObj then return end
    _log("Bath detected. player=", playerNum)

    -- Resolve faucet object (water source) and tub object.
    local faucetObj = nil
    local tubObj = nil
    faucetObj, tubObj = TABAS_Utils.getFullyBathObject(bathObj)
    if not faucetObj then
        _log("getFullyBathObject returned nil faucet")
        return
    end

    -- Locate the TABAS root submenu (e.g., "White Bath").
    local displayName = ISWorldObjectContextMenu.getMoveableDisplayName(faucetObj)
    _log("Looking for TABAS root submenu. displayName=", displayName)
    local bathSub = _findBathRootSubMenu(context, displayName)
    if not bathSub then
        _log("TABAS root submenu not found")
        return
    end
    _log("TABAS root submenu found")

    -- Avoid injecting twice into the same submenu table.
    if bathSub._wmiTABASInjected then return end
    bathSub._wmiTABASInjected = true

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    -- Append WMI "Wash" (structured) as a top-level submenu inside the bathtub menu.
    if WS and WS.WMI_BuildWashMenu then
        _log("Injecting WMI Wash menu")
        WS.WMI_BuildWashMenu(bathSub, worldobjects, playerObj, faucetObj, context)
    else
        _log("WS.WMI_BuildWashMenu not available (WS=", tostring(WS), ")")
    end

    -- Append WMI "Clean Bandages" after the "Wash" option (if present).
    if WMI_Clean and WMI_Clean.injectIntoSubMenu then
        _log("Injecting WMI Clean Bandages menu")
        WMI_Clean.injectIntoSubMenu(bathSub, playerObj, faucetObj)
    else
        _log("WMI_Clean.injectIntoSubMenu not available")
    end

    -- Recompute layout (safe no-ops if not present).
    if bathSub.calcHeight then bathSub:calcHeight() end
    if bathSub.calcWidth and bathSub.setWidth then bathSub:setWidth(bathSub:calcWidth()) end
end

-- Register late (OnGameStart) so we run after TABAS rebuilt the bathtub menu.
local _registered = false
local function _register()
    if _registered then return end
    _registered = true
    if _isTABASActive() then
        Events.OnFillWorldObjectContextMenu.Add(_onFill)
    end
end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(_register)
else
    -- Fallback for older event sets (shouldn't happen on B42+, but safe).
    _register()
end

