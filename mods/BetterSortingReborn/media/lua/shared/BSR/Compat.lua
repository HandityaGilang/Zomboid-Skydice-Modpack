--------------------------------------------------------------------------------
-- Better Sorting Reborn — Build 41 compatibility layer (41.78.x).
--
-- This file lives in the mod's ROOT media/ folder, which only Build 41 loads
-- (Build 42 loads common/ + 42/ instead and gets its own Compat.lua).
--
-- This is the ONLY place, together with 42/media/.../Compat.lua, that is
-- allowed to touch the game API directly. Both files must expose the exact
-- same interface:
--
--   Compat.build                        41 or 42
--   Compat.isModActive(modId)           -> boolean
--   Compat.getScriptItem(fullName)      -> script Item or nil
--   Compat.getAllScriptItems()          -> java ArrayList of script Items
--   Compat.applyCategory(item, key)     -> boolean (success)
--   Compat.getTypeName(item)            -> "Food"|"Literature"|"Drainable"|
--                                          "Weapon"|"Normal"|... or nil
--   Compat.canStoreWater(item)          -> boolean
--   Compat.getLearnedRecipes(item)      -> java List or nil
--------------------------------------------------------------------------------

BSR = BSR or {}

local Compat = { build = 41 }
BSR.Compat = Compat

function Compat.isModActive(modId)
    local ok, mods = pcall(getActivatedMods)
    return ok and mods ~= nil and mods:contains(modId)
end

function Compat.getScriptItem(fullName)
    local ok, item = pcall(function() return ScriptManager.instance:getItem(fullName) end)
    if ok then return item end
    return nil
end

function Compat.getAllScriptItems()
    -- getAllItems() global: every loaded item script, across all active mods.
    local ok, all = pcall(getAllItems)
    if ok then return all end
    return nil
end

-- DoParam re-parses the property exactly as if it were written in the item's
-- script block. This is the mechanism the original Better Sorting used on
-- B40/B41; it only mutates the in-memory script, never the save.
function Compat.applyCategory(item, categoryKey)
    local ok, err = pcall(function()
        item:DoParam("DisplayCategory = " .. categoryKey)
    end)
    if not ok then
        print("[BSR] WARN: DoParam failed for " .. tostring(categoryKey) .. ": " .. tostring(err))
    end
    return ok
end

function Compat.getTypeName(item)
    local ok, name = pcall(function() return item:getTypeString() end)
    if ok then return name end
    return nil
end

function Compat.canStoreWater(item)
    local ok, v = pcall(function() return item:getCanStoreWater() end)
    return ok and v == true
end

function Compat.getLearnedRecipes(item)
    local ok, v = pcall(function() return item:getTeachedRecipes() end)
    if ok then return v end
    return nil
end
