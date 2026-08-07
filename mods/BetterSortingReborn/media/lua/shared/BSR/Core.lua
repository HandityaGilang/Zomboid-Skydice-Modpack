--------------------------------------------------------------------------------
-- Better Sorting Reborn — engine.
--
-- At OnGameBoot (after all item scripts are loaded, before the game starts):
--   1. builds the item -> category override map from the built-in data tables
--      (BSR.Data) and the mod-support packs whose mods are active
--      (BSR.ModPacks), manual overrides always beating auto rules;
--   2. applies every override through BSR.Compat;
--   3. runs the auto-categorization rules (BSR.Rules) on every remaining
--      item script.
--
-- Only DisplayCategory is ever touched — never an item's type — so the mod
-- can be added to or removed from an existing save at any time.
--
-- All game-API access goes through BSR.Compat, provided by the per-build
-- Compat.lua (root media/ for B41, 42/media/ for B42). This file must stay
-- build-agnostic.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}
BSR.ModPacks = BSR.ModPacks or {}
BSR.version = "1.0.1"

-- Set to true (e.g. from the in-game Lua console) for per-item logging.
BSR.verbose = BSR.verbose or false

function BSR.log(msg)
    print("[BSR] " .. msg)
end

function BSR.debugLog(msg)
    if BSR.verbose then print("[BSR] " .. msg) end
end

-- Normalizes an `only` marker: nil stays nil, anything else becomes a string
-- (so a numeric `only = 41` authoring slip still filters correctly).
local function normalizeOnly(only, source)
    if only == nil then return nil end
    only = tostring(only)
    if only ~= "41" and only ~= "42" then
        BSR.log("WARN: invalid only='" .. only .. "' in " .. source .. " (entry kept for both builds)")
        return nil
    end
    return only
end

-- Module part of a "Module.Item" full name (nil-safe, no getModuleName() call
-- so we never depend on that getter being present on script items).
local function moduleOf(fullName)
    return string.match(fullName, "^([^.]+)")
end

-- A pack rule is a predicate: every present condition must hold (AND). It is
-- evaluated ONLY on items with no explicit override, and only for packs whose
-- mod is active. Conditions:
--   contains = { "sub", ... }  fullName contains ANY of these (plain, OR)
--   module   = "Mod"           moduleOf(fullName) == this
--   type     = "Normal"        compat.getTypeName(item) == this
--   only     = "41"|"42"       build gate
-- category (required) is the DisplayCategory key applied on a match.
local function matchesPackRule(rule, fullName, item, compat, build)
    if rule.only and rule.only ~= build then return false end
    if rule.contains then
        local hit = false
        for i = 1, #rule.contains do
            if string.find(fullName, rule.contains[i], 1, true) then
                hit = true
                break
            end
        end
        if not hit then return false end
    end
    if rule.module and moduleOf(fullName) ~= rule.module then return false end
    if rule.type and compat.getTypeName(item) ~= rule.type then return false end
    return true
end

-- Builds { map = { fullName -> categoryKey }, sources = { fullName ->
-- "manual"|"pack" }, conflicts = n } for this boot. def format (shared by
-- BSR.Data values and pack.data values):
--   { only = "41"|"42"|nil, items = { "Module.Item", { "Module.Item", only = "42" }, ... } }
function BSR.buildOverrides(compat)
    local build = tostring(compat.build)
    local map = {}
    local sources = {}
    local conflicts = 0   -- real anomalies: a pack `data` item shadows a Data/ one
    local overlaps = 0    -- two third-party packs claim the same item (expected)
    local known = {}
    for i = 1, #(BSR.Categories or {}) do
        known[BSR.Categories[i].key] = true
    end

    local function addTable(categoryKey, def, source, kind)
        if not known[categoryKey] then
            BSR.log("WARN: unknown category '" .. tostring(categoryKey) .. "' in " .. source .. " (skipped)")
            return
        end
        local tableOnly = normalizeOnly(def.only, source)
        if tableOnly and tableOnly ~= build then return end
        local items = def.items or {}
        for i = 1, #items do
            local entry = items[i]
            local name, entryOnly
            if type(entry) == "table" then
                name, entryOnly = entry[1], normalizeOnly(entry.only, source)
            else
                name = entry
            end
            if name and (entryOnly == nil or entryOnly == build) then
                if map[name] and map[name] ~= categoryKey then
                    local prevKind = sources[name]
                    if kind == "pack" and prevKind == "manual" then
                        -- A pack's `data` shadowing a Data/ mapping is an
                        -- authoring slip: it should be an `overrides` entry.
                        conflicts = conflicts + 1
                        BSR.log("WARN: pack data " .. source .. " shadows the Data/ category '"
                            .. map[name] .. "' for " .. name .. " (use an `overrides` block)")
                    elseif prevKind == "manual" then
                        -- An `overrides` entry beating Data/: the intended
                        -- re-categorization mechanism, not an overlap.
                        BSR.debugLog(name .. ": override '" .. map[name] .. "' -> '"
                            .. categoryKey .. "' (" .. source .. ")")
                    else
                        -- Two active third-party packs claim the same item:
                        -- expected, resolved by sort order (last wins).
                        overlaps = overlaps + 1
                        BSR.debugLog(name .. ": pack overlap '" .. map[name] .. "' -> '"
                            .. categoryKey .. "' (" .. source .. " wins)")
                    end
                end
                map[name] = categoryKey
                sources[name] = kind
            end
        end
    end

    -- Phase 1: the built-in Data/ tables (vanilla items).
    for categoryKey, def in pairs(BSR.Data) do
        addTable(categoryKey, def, "BSR.Data." .. categoryKey, "manual")
    end

    -- Collect the active packs and sort them by name, so the winner of an item
    -- claimed by two packs is deterministic and independent of the game's Lua
    -- load order (later name in sort order wins).
    local activePacks = {}
    for i = 1, #BSR.ModPacks do
        local pack = BSR.ModPacks[i]
        local active = false
        for m = 1, #(pack.mods or {}) do
            if compat.isModActive(pack.mods[m]) then
                active = true
                break
            end
        end
        if active then activePacks[#activePacks + 1] = pack end
    end
    table.sort(activePacks, function(a, b) return tostring(a.name) < tostring(b.name) end)

    -- Phase 2: every active pack's `data` (the mod's own items). Runs before any
    -- overrides so a phase-3 re-categorization always wins over plain data.
    for i = 1, #activePacks do
        local pack = activePacks[i]
        BSR.debugLog("mod pack active: " .. tostring(pack.name))
        for categoryKey, def in pairs(pack.data or {}) do
            addTable(categoryKey, def, "pack " .. tostring(pack.name), "pack")
        end
    end

    -- Phase 3: active packs' `overrides` (deliberate re-categorization of a
    -- vanilla item) and their scoped rules.
    local packRules = {}
    for i = 1, #activePacks do
        local pack = activePacks[i]
        for categoryKey, def in pairs(pack.overrides or {}) do
            addTable(categoryKey, def, "override " .. tostring(pack.name), "override")
        end
        local rules = pack.rules or {}
        for r = 1, #rules do
            local rule = rules[r]
            local src = "pack " .. tostring(pack.name) .. " rule"
            if not known[rule.category] then
                BSR.log("WARN: unknown category '" .. tostring(rule.category)
                    .. "' in " .. src .. " (skipped)")
            else
                packRules[#packRules + 1] = {
                    contains = rule.contains,
                    module = rule.module,
                    type = rule.type,
                    only = normalizeOnly(rule.only, src),
                    category = rule.category,
                }
            end
        end
    end

    return { map = map, sources = sources, conflicts = conflicts,
             overlaps = overlaps, packRules = packRules }
end

function BSR.applyAll()
    local compat = BSR.Compat
    if not compat then
        print("[BSR] ERROR: no Compat layer loaded for this game build — nothing done")
        return
    end
    BSR.log("Better Sorting Reborn v" .. BSR.version .. " (build " .. tostring(compat.build) .. ")")

    local overrides = BSR.buildOverrides(compat)

    -- Pass 1: explicit overrides (data tables + mod packs), by direct lookup.
    local appliedManual, appliedPack, unknown = 0, 0, 0
    for fullName, categoryKey in pairs(overrides.map) do
        local script = compat.getScriptItem(fullName)
        if script then
            if compat.applyCategory(script, categoryKey) then
                if overrides.sources[fullName] == "manual" then
                    appliedManual = appliedManual + 1
                else
                    appliedPack = appliedPack + 1  -- pack data or pack override
                end
                BSR.debugLog(fullName .. " -> " .. categoryKey)
            end
        else
            unknown = unknown + 1
            BSR.debugLog("unknown item skipped: " .. fullName)
        end
    end

    -- Pass 2: on everything that has no manual override, try the active packs'
    -- scoped rules first (mod-specific, first match wins), then fall back to
    -- the generic auto rules.
    local build = tostring(compat.build)
    local packRules = overrides.packRules or {}
    local auto, packRule = 0, 0
    local all = compat.getAllScriptItems()
    if all then
        for i = 0, all:size() - 1 do
            local script = all:get(i)
            local ok, fullName = pcall(function() return script:getFullName() end)
            if ok and fullName and not overrides.map[fullName] then
                local categoryKey, fromPackRule = nil, false
                for r = 1, #packRules do
                    if matchesPackRule(packRules[r], fullName, script, compat, build) then
                        categoryKey = packRules[r].category
                        fromPackRule = true
                        break
                    end
                end
                if not categoryKey then
                    categoryKey = BSR.Rules.evaluate(script, compat)
                end
                if categoryKey and compat.applyCategory(script, categoryKey) then
                    if fromPackRule then
                        packRule = packRule + 1
                    else
                        auto = auto + 1
                    end
                    BSR.debugLog(fullName .. " -> " .. categoryKey
                        .. (fromPackRule and " (pack rule)" or " (auto)"))
                end
            end
        end
    else
        BSR.log("WARN: could not list item scripts; auto rules skipped")
    end

    BSR.log(string.format(
        "%d items categorized (%d manual + %d mod-pack overrides + %d pack-rule, %d auto), %d unknown items skipped, %d conflicts, %d pack overlaps",
        appliedManual + appliedPack + packRule + auto, appliedManual, appliedPack, packRule, auto,
        unknown, overrides.conflicts, overrides.overlaps or 0))
end

local function onGameBoot()
    -- Categories are client-side cosmetics; do nothing on a dedicated server.
    if isServer and isServer() then return end
    local ok, err = pcall(BSR.applyAll)
    if not ok then
        print("[BSR] ERROR during categorization: " .. tostring(err))
    end
end

Events.OnGameBoot.Add(onGameBoot)
