--------------------------------------------------------------------------------
-- Better Sorting Reborn — Build 42 compatibility layer (validated against
-- 42.19.0 bytecode, re-validated unchanged against 42.20 stable;
-- see docs/adr/0001-categorization-mechanism.md).
--
-- This file lives in 42/media/, loaded by Build 42 only (on top of common/).
-- It must expose the same interface as the B41 file in the mod root's
-- media/lua/shared/BSR/Compat.lua — see the interface list there.
--
-- B41 -> B42 API differences handled here:
--   * getActivatedMods() entries are prefixed with "\" in B42.
--   * Item.getTypeString() is gone; the item type is a registry object
--     (Item.getItemType() -> zombie.scripting.objects.ItemType, namespaced
--     "base:food" etc., introduced by the 42.13 identifier system).
--   * Item.getCanStoreWater() is gone (public field canStoreWater remains).
--   * Item.getTeachedRecipes() was renamed getLearnedRecipes().
--   * DisplayCategory itself is UNCHANGED: still a plain string, still
--     settable through DoParam - it is NOT part of the 42.13 registries.
--     Still true in 42.20 (the B42 stable release): DoParam(String,String)
--     does `this.displayCategory = value.trim()` with no registry lookup,
--     and Registries still has no DISPLAY_CATEGORY entry.
--------------------------------------------------------------------------------

BSR = BSR or {}

local Compat = { build = 42 }
BSR.Compat = Compat

function Compat.isModActive(modId)
    local ok, mods = pcall(getActivatedMods)
    if not ok or mods == nil then return false end
    -- B42 mod IDs are listed with a leading backslash; accept both forms.
    return mods:contains(modId) or mods:contains("\\" .. modId)
end

function Compat.getScriptItem(fullName)
    local ok, item = pcall(function() return getScriptManager():getItem(fullName) end)
    if ok then return item end
    return nil
end

function Compat.getAllScriptItems()
    local ok, all = pcall(function() return getScriptManager():getAllItems() end)
    if ok then return all end
    return nil
end

-- Item.DoParam(String) survived the 42.13 refactor unchanged for
-- DisplayCategory: it trims and stores the value with no registry lookup
-- (verified in 42.19.0 bytecode; the compatibility patch by pimat.studio
-- ships the same mechanism and still works on 42.19).
function Compat.applyCategory(item, categoryKey)
    local ok, err = pcall(function()
        item:DoParam("DisplayCategory = " .. categoryKey)
    end)
    if not ok then
        print("[BSR] WARN: DoParam failed for " .. tostring(categoryKey) .. ": " .. tostring(err))
    end
    return ok
end

-- Maps the ItemType registry singletons back to B41-style type names, so the
-- shared rules can stay build-agnostic. Built lazily at first use (item-type
-- registries are filled from scripts long before OnGameBoot fires).
--
-- Primary derivation probes canonical vanilla items through APIs verified in
-- the 42.19.0 bytecode (getScriptManager():getItem + Item.getItemType), which
-- also guarantees the map keys are the exact singletons other items return.
-- The ItemType/ResourceLocation registry globals are only a fallback, since
-- their Lua exposure is not bytecode-verifiable.
local typeNames = nil

local TYPE_PROBES = {
    Food = "Base.Apple",
    Literature = "Base.BookCarpentry1",
    Weapon = "Base.Hammer",
    Normal = "Base.Bleach",
    Drainable = "Base.PaintBlack",
}

local function initTypeNames()
    typeNames = {}
    local count = 0
    for name, probeItem in pairs(TYPE_PROBES) do
        local ok, itemType = pcall(function()
            local script = getScriptManager():getItem(probeItem)
            return script and script:getItemType() or nil
        end)
        if ok and itemType ~= nil then
            typeNames[itemType] = name
            count = count + 1
        else
            local ok2, itemType2 = pcall(function()
                return ItemType.get(ResourceLocation.of("base:" .. string.lower(name)))
            end)
            if ok2 and itemType2 ~= nil then
                typeNames[itemType2] = name
                count = count + 1
            else
                print("[BSR] WARN: could not resolve item type '" .. name .. "'")
            end
        end
    end
    if count == 0 then
        print("[BSR] WARN: could not resolve any ItemType identifier; type-based rules disabled")
    end
end

function Compat.getTypeName(item)
    if typeNames == nil then initTypeNames() end
    local ok, itemType = pcall(function() return item:getItemType() end)
    if not ok or itemType == nil then return nil end
    local name = typeNames[itemType]
    if name then return name end
    -- Modded item type outside the known base set: expose it raw.
    local ok2, str = pcall(function() return tostring(itemType) end)
    if ok2 then return str end
    return nil
end

function Compat.canStoreWater(item)
    -- No getter in B42; the public field is exposed to Lua.
    local ok, v = pcall(function() return item.canStoreWater end)
    return ok and v == true
end

function Compat.getLearnedRecipes(item)
    local ok, v = pcall(function() return item:getLearnedRecipes() end)
    if ok then return v end
    return nil
end
