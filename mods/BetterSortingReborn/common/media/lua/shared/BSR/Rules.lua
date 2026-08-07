--------------------------------------------------------------------------------
-- Better Sorting Reborn — auto-categorization rules.
--
-- Fallback categorization for items that have no manual override in the data
-- tables. Ordered list, first matching rule wins (same behavior as the
-- original Better Sorting core).
--
-- Rule fields:
--   name        stable identifier, used in error logs.
--   only        "41" / "42": rule is skipped on the other build. Rules that
--               duplicate (or would fight) the richer vanilla B42 taxonomy
--               are 41-only.
--   replaces42  on B42 only: set of current DisplayCategory values the rule
--               is allowed to replace. Vanilla B42 already ships good
--               categories for most items; a rule must not stomp a specific
--               vanilla category (e.g. "Memento") just because the item type
--               matches. Items with no current category are always eligible.
--   fn(item, compat) -> category key or nil.
--
-- Every game-API getter is called through call()/compat so that a renamed or
-- removed getter degrades into "rule does not match" plus one logged warning,
-- never into a boot error. This is the exact failure mode that killed the
-- original mod in game patch 42.13.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Rules = BSR.Rules or {}

-- Calls item:<method>() under pcall. Returns (true, value) on success and
-- (false, nil) when the method is missing or throws (logging the failure
-- once per method name) — so callers can tell "getter broken" apart from a
-- genuine nil return value.
local warned = {}
local function tryCall(item, method)
    local f = item[method]
    if f == nil then
        if not warned[method] then
            warned[method] = true
            print("[BSR] WARN: item getter '" .. method .. "' does not exist on this game version")
        end
        return false, nil
    end
    local ok, value = pcall(f, item)
    if not ok then
        if not warned[method] then
            warned[method] = true
            print("[BSR] WARN: item getter '" .. method .. "' failed: " .. tostring(value))
        end
        return false, nil
    end
    return true, value
end

-- Convenience form: collapses failure into nil.
local function call(item, method)
    local ok, value = tryCall(item, method)
    if ok then return value end
    return nil
end
BSR.Rules.call = call

BSR.Rules.list = {

    -- Anything that can hold water is a container, except Drainable items
    -- (water bottles and the like), which sort with beverages.
    -- 41-only: vanilla B42 already has the finer WaterContainer category.
    {
        name = "water-container",
        only = "41",
        fn = function(item, compat)
            if not compat.canStoreWater(item) then return nil end
            if compat.getTypeName(item) == "Drainable" then return "FoodB" end
            return "Container"
        end,
    },

    -- 41-only: vanilla B42 keeps a deliberate "Water" category (2 items).
    {
        name = "water-category",
        only = "41",
        fn = function(item, compat)
            if call(item, "getDisplayCategory") == "Water" then return "FoodB" end
            return nil
        end,
    },

    -- Split Food into Perishable / Non-Perishable. The rotten-days bounds
    -- come from the original mod: items that never rot report 0 or a huge
    -- sentinel value.
    {
        name = "food-perishable",
        replaces42 = { Food = true },
        fn = function(item, compat)
            if compat.getTypeName(item) ~= "Food" then return nil end
            local rot = call(item, "getDaysTotallyRotten")
            if rot and rot > 0 and rot < 1000000000 then return "FoodP" end
            return "FoodN"
        end,
    },

    -- Split Literature by what the book actually does. On B42 this only
    -- regroups the generic vanilla buckets (Literature/SkillBook/
    -- Entertainment); specific ones like Cartography or Memento are kept.
    {
        name = "literature",
        replaces42 = { Literature = true, SkillBook = true, Entertainment = true },
        fn = function(item, compat)
            if compat.getTypeName(item) ~= "Literature" then return nil end
            local skill = call(item, "getSkillTrained")
            if skill and string.len(skill) > 0 then return "LitS" end
            local recipes = compat.getLearnedRecipes(item)
            if recipes then
                local ok, empty = pcall(function() return recipes:isEmpty() end)
                if ok and not empty then return "LitR" end
            end
            local stress = call(item, "getStressChange") or 0
            local boredom = call(item, "getBoredomChange") or 0
            local unhappy = call(item, "getUnhappyChange") or 0
            if stress ~= 0 or boredom ~= 0 or unhappy ~= 0 then return "LitE" end
            return "LitW"
        end,
    },

    -- 41-only: vanilla B42 keeps its own "Explosives" category.
    {
        name = "explosives",
        only = "41",
        fn = function(item, compat)
            if compat.getTypeName(item) ~= "Weapon" then return nil end
            local cat = call(item, "getDisplayCategory")
            if cat == "Explosives" or cat == "Devices" then return "WepBomb" end
            return nil
        end,
    },

    -- Last resort: vanilla categories whose TRANSLATED LABEL is identical to
    -- one of ours. The game groups by key, not by label, so an item left on
    -- the vanilla key renders as a second header with the exact same name
    -- ("two Cooking categories"). Only pairs where both keys are populated
    -- are listed — e.g. vanilla "Furniture"/"Appearance" are NOT here because
    -- BSR.Data.Furn and BSR.Data.Appear are 41-only, so nothing competes with
    -- them on B42.
    --
    -- This is a safety net, not the categorization: items whose right home is
    -- NOT the same-label key (mugs -> Container, six-packs -> FoodA, openers
    -- -> Tool, ...) carry an explicit override in Data/ and never reach here.
    -- Keeping it generic also covers items added by future game patches and
    -- by third-party mods that reuse the vanilla key.
    --
    -- Deliberately not `only = "42"`: on B41 it is a no-op if the vanilla
    -- category does not exist, and the same de-duplication if it does.
    {
        name = "label-collision",
        replaces42 = { Cooking = true, Electronics = true },
        fn = function(item, compat)
            local cat = call(item, "getDisplayCategory")
            if cat == "Cooking" then return "Cook" end
            if cat == "Electronics" then return "Elec" end
            return nil
        end,
    },
}

local ruleErrors = {}

-- Returns the category key for an item, or nil to leave it untouched.
function BSR.Rules.evaluate(item, compat)
    local build = tostring(compat.build)
    for i = 1, #BSR.Rules.list do
        local rule = BSR.Rules.list[i]
        local applicable = (rule.only == nil) or (rule.only == build)
        if applicable and rule.replaces42 and compat.build == 42 then
            -- Fail CLOSED: if the getter is broken we cannot know whether the
            -- item carries a specific vanilla category, so don't touch it.
            local ok, current = tryCall(item, "getDisplayCategory")
            if not ok then
                applicable = false
            elseif current ~= nil and not rule.replaces42[current] then
                applicable = false
            end
        end
        if applicable then
            local ok, result = pcall(rule.fn, item, compat)
            if ok then
                if result then return result end
            elseif not ruleErrors[rule.name] then
                ruleErrors[rule.name] = true
                print("[BSR] WARN: rule '" .. rule.name .. "' failed: " .. tostring(result))
            end
        end
    end
    return nil
end
