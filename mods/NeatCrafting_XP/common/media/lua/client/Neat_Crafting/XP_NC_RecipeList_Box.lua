----------------------------------------------------------------
-- Neat Crafting - Addon XP Display
-- File: XP_NC_RecipeList_Box.lua
-- Purpose: add XP lines + exact-height boxes without widening the icon strip
-- Notes:
--   * Credits kept:
--       - Reflection helper adapted from "Starlit Library" by albion.
--       - Several UI ideas adapted from "Neat Crafting" by Rocco.
----------------------------------------------------------------

require "ISUI/ISUIElement"

----------------------------------------------------------------
-- Config / debug
----------------------------------------------------------------
local XP_NC_DEBUG = false
local function dprint(...)
    if XP_NC_DEBUG then print(...) end
end

-- Fonts
local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function XP_NC_is4215Plus()
    local core = getCore and getCore() or nil
    local v = core and core.getVersion and core:getVersion() or ""
    local maj, minr = tostring(v):match("^(%d+)%.(%d+)")
    return tonumber(maj) == 42 and (tonumber(minr) or 0) >= 15
end

local XP_NC_B42_15_PLUS = XP_NC_is4215Plus()

local function XP_NC_shouldApplyInitialSkillBoost(perk)
    -- CraftRecipe.awardXP() in B42.17 still calls AddXP(..., doXPBoost=true),
    -- so electrical recipes must keep the same initial-skill XP boost path as
    -- other craft recipe perks. Keep this wrapper for older/newer build fallbacks.
    return true
end

local function XP_NC_isValidResolvedPerk(perk)
    -- Reject nil and the PerkFactory.Perks.MAX sentinel returned by FromString()
    -- when an ID is unknown.
    return perk ~= nil and not (PerkFactory and PerkFactory.Perks and perk == PerkFactory.Perks.MAX)
end

local function XP_NC_resolvePerk(perkIdOrName)
    -- XP awards from recipe scripts use internal perk IDs such as "Electricity",
    -- while getPerkFromName() expects the translated display name, e.g. "Electrical".
    -- Resolve by ID first, then by static enum field, then by translated name.
    if perkIdOrName == nil then return nil end
    local raw = tostring(perkIdOrName)
    local id = raw:gsub("^Perks%.", "")

    if PerkFactory and PerkFactory.Perks then
        if type(PerkFactory.Perks.FromString) == "function" then
            local ok, perk = pcall(PerkFactory.Perks.FromString, id)
            if ok and XP_NC_isValidResolvedPerk(perk) then return perk end
        end

        local okField, perk = pcall(function() return PerkFactory.Perks[id] end)
        if okField and XP_NC_isValidResolvedPerk(perk) then return perk end
    end

    if PerkFactory and PerkFactory.PerkList then
        local okList, listSize = pcall(function() return PerkFactory.PerkList:size() end)
        if okList and listSize then
            for i = 0, listSize - 1 do
                local okPerk, listedPerk = pcall(function() return PerkFactory.PerkList:get(i) end)
                if okPerk and XP_NC_isValidResolvedPerk(listedPerk) then
                    local okId, listedId = pcall(function() return listedPerk:getId() end)
                    if okId and tostring(listedId) == id then return listedPerk end
                    if tostring(listedPerk) == id then return listedPerk end
                end
            end
        end
    end

    if PerkFactory and type(PerkFactory.getPerkFromName) == "function" then
        local okName, perk = pcall(PerkFactory.getPerkFromName, raw)
        if okName and XP_NC_isValidResolvedPerk(perk) then return perk end

        if id ~= raw then
            local okIdName, perkByIdName = pcall(PerkFactory.getPerkFromName, id)
            if okIdName and XP_NC_isValidResolvedPerk(perkByIdName) then return perkByIdName end
        end
    end

    return nil
end

----------------------------------------------------------------
-- Options helpers (provided by XP_NC_ModOptions.lua)
----------------------------------------------------------------
-- XP_NC_getxpShow() -> bool
-- XP_NC_getxpFormat() -> string index ("1","2","3",...)
-- XP_NC_getShowRecipeMod() -> bool
-- XP_NC_getTextScale() -> number (0.7..1.2)

local function XP_NC_getZoom()
    -- Scale used for extra text lines (XP + Mod)
    local z = (XP_NC_getTextScale and tonumber(XP_NC_getTextScale())) or 0.8
    if z < 0.5 then z = 0.5 elseif z > 2.0 then z = 2.0 end
    return z
end

----------------------------------------------------------------
-- Shared NC textures (reused across all boxes to avoid re-fetch)
----------------------------------------------------------------
local SLOTICON_TEX   = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
local SLOTLEFT_TEX   = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
local SLOTBORDER_TEX = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")

----------------------------------------------------------------
-- Small helpers
----------------------------------------------------------------
local function formatNumber(value)
    local rounded = math.floor(value * 100 + 0.5) / 100
    return tostring(rounded)
end

-- Crafty trait applies only to perks whose parent is Crafting (B42.12+).
-- We keep a fallback list of perk *types* for builds/mod environments where perk:getParent() is unavailable.
local XP_NC_CRAFTING_PERK_TYPES = {
    Woodwork = true, Carving = true, Cooking = true, Electricity = true, Glassmaking = true,
    FlintKnapping = true, Masonry = true, Blacksmith = true, Mechanics = true, Pottery = true,
    Tailoring = true, MetalWelding = true,
}

-- Mirrors IsoGameCharacter$XP.AddXP
local function getXPMultiplier(player, perk)
    if not player or not perk then
        return {
            skillBoost = 1,
            bookMultiplier = 1,
            learnerMultiplier = 1,
            craftyMultiplier = 1,
            sandboxMultiplier = 1,
            total = 1,
            string = "1*1*1*1",
        }
    end
    local xp = player:getXp()
    local xpMultiplier = {}

    -- 1) initial level boost (or trait-driven boost)
    if XP_NC_shouldApplyInitialSkillBoost(perk) then
        local startingLevel = xp:getPerkBoost(perk) or -1
        if startingLevel == 0 then
            xpMultiplier.skillBoost = 0.25
        elseif startingLevel == 1 then
            xpMultiplier.skillBoost = 1.0
        elseif startingLevel == 2 then
            xpMultiplier.skillBoost = 1.33
        elseif startingLevel >= 3 then
            xpMultiplier.skillBoost = 1.66
        else
            print("[NC - Addon XP Display] CAUTION. unexpected perkBoost")
            xpMultiplier.skillBoost = 0.25
        end
    else
        xpMultiplier.skillBoost = 1.0
    end

    -- 2) book multiplier
    xpMultiplier.bookMultiplier = math.max(xp:getMultiplier(perk) or 1, 1)

	-- 3) Trait multiplier
    -- 3a) Fast/Slow Learner
    xpMultiplier.learnerMultiplier = 1

    -- Trait API changed in 42.13: HasTrait(string) -> hasTrait(CharacterTrait)
    local function hasTraitCompat(pl, traitObj, legacyId)
        -- Prefer new API (Build 42.13+)
        if pl and type(pl.hasTrait) == "function" and traitObj ~= nil then
            return pl:hasTrait(traitObj)
        end
        -- Fallback for older builds
        if pl and type(pl.HasTrait) == "function" and legacyId ~= nil then
            return pl:HasTrait(legacyId)
        end
        return false
    end

    local fastLearner = (CharacterTrait and CharacterTrait.FAST_LEARNER) or nil
    local slowLearner = (CharacterTrait and CharacterTrait.SLOW_LEARNER) or nil

    if hasTraitCompat(player, fastLearner, "FastLearner") then
        xpMultiplier.learnerMultiplier = 1.3
    elseif hasTraitCompat(player, slowLearner, "SlowLearner") then
        xpMultiplier.learnerMultiplier = 0.7
    end

    -- 3b) Crafty (Build 42.12+): +30% XP for perks in the Crafting category
    xpMultiplier.craftyMultiplier = 1
	
	-- Detect Crafty across builds:
	-- - B42.13+: player:hasTrait(CharacterTrait.CRAFTY)
	-- - B42.12.x: player:HasTrait("Crafty")
	local craftyTrait = (CharacterTrait and CharacterTrait.CRAFTY) or nil
	local hasCrafty = hasTraitCompat(player, craftyTrait, "Crafty")	

    local function isCraftingPerk(p)
        if not p then return false end
        -- Prefer the parent-category check when available (B42.13+)
        if p.getParent and PerkFactory and PerkFactory.Perks and PerkFactory.Perks.Crafting then
            return p:getParent() == PerkFactory.Perks.Crafting
        end
        -- Fallback: match by perk type string
        local t = (p.getType and p:getType()) or nil
        return (t and XP_NC_CRAFTING_PERK_TYPES[t]) or false
    end

    if hasCrafty and isCraftingPerk(perk) then
        xpMultiplier.craftyMultiplier = 1.3
    end

    -- 4) sandbox multiplier
    if SandboxVars.MultiplierConfig and SandboxVars.MultiplierConfig.GlobalToggle == true then
        xpMultiplier.sandboxMultiplier = SandboxVars.MultiplierConfig.Global or 1
    else
        local option = getSandboxOptions() and getSandboxOptions():getOptionByName("MultiplierConfig." .. tostring(perk:getType()))
        xpMultiplier.sandboxMultiplier = (option and option:getValue()) or 1
    end

    xpMultiplier.total = xpMultiplier.skillBoost * xpMultiplier.bookMultiplier *
                         xpMultiplier.learnerMultiplier * xpMultiplier.craftyMultiplier * xpMultiplier.sandboxMultiplier
    return xpMultiplier
end

----------------------------------------------------------------
-- Reflection helper (credit: albion / Starlit Library)
----------------------------------------------------------------
local function getFieldValue(object, fieldName)
    if XP_NC_B42_15_PLUS then
        -- Reflection-based field access is no longer usable in normal B42.15+ gameplay.
        return nil
    end
    if not object then return nil end
    for i = 0, getNumClassFields(object) - 1 do
        local field = getClassField(object, i)
        local currentFieldName = string.match(tostring(field), "([^%.]+)$")
        if currentFieldName == fieldName then
            return getClassFieldVal(object, field)
        end
    end
    return nil
end

-- B42.15+ fix: parse XP award entries from raw script bodies, bypassing the
-- unregistered CraftRecipe$xp_Award inner class. On older builds, keep the
-- previous reflection-backed path for compatibility.
-- Returns a list of { perkId = string, amount = number }.
local _NC_xpAwardCache = setmetatable({}, { __mode = "k" })
local function NC_parseRecipeXPAwards(recipe)
    if not recipe then return {} end
    local cached = _NC_xpAwardCache[recipe]
    if cached then return cached end

    local result = {}
    local byPerkId = {}

    if XP_NC_B42_15_PLUS then
        local ok, bodies = pcall(function()
            return recipe.getLoadedScriptBodies and recipe:getLoadedScriptBodies()
        end)
        if ok and bodies then
            for i = 0, bodies:size() - 1 do
                local body = bodies:get(i)
                if body then
                    for line in tostring(body):gmatch("[^\n\r]+") do
                        local xpStr = line:match("^%s*[Xx][Pp][Aa][Ww][Aa][Rr][Dd]%s*=%s*(.-)%s*,?%s*$")
                        if xpStr and xpStr ~= "" then
                            for perkName, amountStr in xpStr:gmatch("([%w_%.]+)%s*:%s*([%d%.]+)") do
                                local perkId = tostring(perkName)
                                local amount = tonumber(amountStr) or 0
                                local entry = byPerkId[perkId]
                                if entry then
                                    entry.amount = entry.amount + amount
                                else
                                    entry = { perkId = perkId, amount = amount }
                                    byPerkId[perkId] = entry
                                    result[#result + 1] = entry
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        if recipe.getXPAwardCount and recipe:getXPAwardCount() > 0 then
            for i = 0, recipe:getXPAwardCount() - 1 do
                local xp = recipe:getXPAward(i)
                local perk = xp and getFieldValue(xp, "perk")
                local amount = xp and getFieldValue(xp, "amount")
                local perkId = nil
                if perk and perk.getId then
                    perkId = perk:getId()
                elseif perk and perk.getType then
                    perkId = perk:getType()
                elseif perk then
                    perkId = tostring(perk)
                end
                if perkId then
                    local entry = byPerkId[perkId]
                    if entry then
                        entry.amount = entry.amount + (tonumber(amount) or 0)
                    else
                        entry = { perkId = perkId, amount = tonumber(amount) or 0 }
                        byPerkId[perkId] = entry
                        result[#result + 1] = entry
                    end
                end
            end
        end
    end

    _NC_xpAwardCache[recipe] = result
    return result
end

-- ---------------------------------------------------------------------------
-- B42.13+: Prefer recipe provider metadata (mod id/name) over module/item heuristics
-- ---------------------------------------------------------------------------
local function NC_getRecipeProvider(recipe)
    -- Read provider fields defensively; different builds may expose different names
    local mid   = (recipe and recipe.getModID   and recipe:getModID())   or getFieldValue(recipe, "modID")   or getFieldValue(recipe, "modId")
    local mname = (recipe and recipe.getModName and recipe:getModName()) or getFieldValue(recipe, "modName")
    return mid, mname
end

local function NC_providerToPrettyName(mid, mname)
    -- Treat vanilla and the "Base" module as "no useful provider" (keep searching via WorldDictionary)
    if mname == "Project Zomboid" or mid == "pz-vanilla" then
        return nil
    end
    if mname == "Base" or mid == "Base" then
        return nil
    end

    -- Prefer a human-readable provider name if present and not a placeholder
    if mname and mname ~= "" and mname ~= "<unknown_mod>" then
        return mname
    end

    -- Otherwise map provider id -> display name if possible
    if mid and mid ~= "" and mid ~= "<unknown_mod>" then
        -- Prefer WorldDictionary mapping (usually more reliable than getModInfoByID)
        if WorldDictionary and WorldDictionary.getModNameFromID then
            local nm = WorldDictionary.getModNameFromID(mid)
            if nm and nm ~= "" and nm ~= "Unknown mod" and nm ~= "Project Zomboid" and nm ~= "Base" then
                return nm
            end
        end

        if getModInfoByID ~= nil then
            local mi = getModInfoByID(mid)
            if mi and mi.getName then
                local nm = mi:getName()
                if nm and nm ~= "" and nm ~= "Base" then
                    return nm
                end
            end
        end

        return mid
    end

    return nil
end

----------------------------------------------------------------
-- Recipe -> Mod pretty-name helpers
----------------------------------------------------------------

local function NC_tryGetRecipeModName(recipe)
    if not recipe then return nil end
	
	-- B42.13+: use provider metadata if available
	local mid, mname = NC_getRecipeProvider(recipe)
	local prettyFromProvider = NC_providerToPrettyName(mid, mname)

	-- If provider is "Base" (or otherwise unhelpful), keep going and try WorldDictionary-based resolution
	if prettyFromProvider and prettyFromProvider ~= "Base" then
		return prettyFromProvider
	end

    local moduleName = (recipe.getModule and recipe:getModule() and recipe:getModule():getName()) or "Base"
    if getModInfoByID ~= nil then
        local mi = getModInfoByID(moduleName)
        if mi then return mi:getName() end
    end
	local function modNameFromFullType(fulltype)
		if not fulltype or fulltype == "" then return nil end
		if not WorldDictionary then return nil end

		local modID = nil
		if WorldDictionary.getItemModID then
			modID = WorldDictionary.getItemModID(fulltype)
		end
		if (not modID or modID == "") and WorldDictionary.getEntityModID then
			modID = WorldDictionary.getEntityModID(fulltype)
		end

		-- Ignore "Base" module and vanilla
		if not modID or modID == "" or modID == "Base" or modID == "pz-vanilla" then
			return nil
		end

		if WorldDictionary.getModNameFromID then
			local nm = WorldDictionary.getModNameFromID(modID)
			if nm and nm ~= "" and nm ~= "Unknown mod" and nm ~= "Project Zomboid" and nm ~= "Base" then
				return nm
			end
		end

		if getModInfoByID ~= nil then
			local mi = getModInfoByID(modID)
			if mi then
				local nm = mi:getName()
				if nm and nm ~= "" then return nm end
			end
		end

		return modID
	end
    local res = recipe.getResult and recipe:getResult()
    if res then
        local fulltype = (res.module or moduleName or "Base") .. "." .. tostring(res.type)
        local name = modNameFromFullType(fulltype)
        if name then return name end
    end
    local sources = recipe.getSource and recipe:getSource()
    if sources and sources.size then
        for i = 0, sources:size()-1 do
            local src = sources:get(i)
            if src and src.getItems then
                local items = src:getItems()
                if items and items.size then
                    for j = 0, items:size()-1 do
                        local it = items:get(j)
                        if it then
                            local ft = it:find("%.") and it or (moduleName .. "." .. it)
                            local name = modNameFromFullType(ft)
                            if name then return name end
                        end
                    end
                end
            end
        end
    end
    return moduleName
end

function NC_isLikelyVanillaRecipe(recipe)
    -- Defensive default: treat nil as vanilla
    if not recipe then return true end

    -- 1) Prefer explicit provider metadata (works in B42 and avoids heuristics when available)
    local mid = (recipe.getModID and recipe:getModID())
        or getFieldValue(recipe, "modID")
        or getFieldValue(recipe, "modId")

    local mname = (recipe.getModName and recipe:getModName())
        or getFieldValue(recipe, "modName")

    -- Explicit vanilla markers
    if mname == "Project Zomboid" or mid == "pz-vanilla" then
        return true
    end

    -- If a provider exists and it's not vanilla, it is NOT vanilla
    if (mname and mname ~= "" and mname ~= "Project Zomboid")
        or (mid and mid ~= "" and mid ~= "pz-vanilla") then
        return false
    end

    -- 2) Helper: safely get a Java List size
    local function listSize(list)
        if not list then return 0 end
        local ok, n = pcall(function() return list:size() end)
        if ok and type(n) == "number" then return n end
        if list.size then
            ok, n = pcall(list.size, list)
            if ok and type(n) == "number" then return n end
        end
        return 0
    end

    -- 3) Helper: try to extract any output fulltype (module.type) from CraftRecipe outputs
    local function getAnyOutputFullType(moduleNameFallback)
        -- Legacy path (some UIs expose a pseudo-result)
        if recipe.getResult then
            local ok, res = pcall(recipe.getResult, recipe)
            if ok and res and res.type then
                local m = res.module or moduleNameFallback or "Base"
                return tostring(m) .. "." .. tostring(res.type)
            end
        end

        -- CraftRecipe path: outputs (B42)
        if recipe.getOutputs then
            local ok, outs = pcall(recipe.getOutputs, recipe)
            if ok and outs then
                local n = listSize(outs)
                for i = 0, n - 1 do
                    local outOk, out = pcall(function() return outs:get(i) end)
                    if outOk and out then
                        -- Prefer possible result items (resolved after world dictionary init)
                        if out.getPossibleResultItems then
                            local okItems, items = pcall(out.getPossibleResultItems, out)
                            if okItems and items and listSize(items) > 0 then
                                local okIt, it = pcall(function() return items:get(0) end)
                                if okIt and it and it.getFullName then
                                    local okFT, ft = pcall(it.getFullName, it)
                                    if okFT and ft then return tostring(ft) end
                                end
                            end
                        end

                        -- Fallback: try common field names (varies by build / implementation)
                        local ft = getFieldValue(out, "fullType")
                            or getFieldValue(out, "itemFullType")
                            or getFieldValue(out, "item")
                        if type(ft) == "string" and ft:find("%.") then
                            return ft
                        end
                    end
                end
            end
        end

        return nil
    end

    -- 4) Legacy heuristic: module name (if we can read it)
    local moduleName = (recipe.getModule and recipe:getModule() and recipe:getModule():getName()) or "Base"
    if moduleName ~= "Base" then
        -- If it's not the Base module and no provider says vanilla, assume it's modded
        return false
    end

    -- 5) Legacy heuristic: consult WorldDictionary using an output fulltype
    local fulltype = getAnyOutputFullType(moduleName)
    if fulltype and WorldDictionary and WorldDictionary.getItemModID then
        local modID = WorldDictionary.getItemModID(fulltype)

        -- If the dictionary doesn't know the item yet, DON'T assume vanilla by default:
        -- treat non-Base modules as modded (fixes cases like Better Electronics)
        if not modID then
            local outModule = fulltype:match("^([^.]+)%.")
            return (outModule == nil) or (outModule == "Base")
        end

        -- Recognize vanilla ids
        return (modID == "pz-vanilla") or (modID == "Base")
    end

    -- 6) Final fallback: if we couldn't prove it's modded, treat as vanilla
    return true
end

----------------------------------------------------------------
-- Precalculate heights LUT and use real overflow
----------------------------------------------------------------
-- Remember the box's internal padding once (read on first box creation)
local XP_NC_BOX_PADDING = nil

-- Compute single-line metrics for current scale
local _LM_cache = { z = nil, h = nil, g = nil }  -- module-scope memo
local function XP_NC_lineMetrics()
    local z = XP_NC_getZoom()
    if _LM_cache.z == z and _LM_cache.h and _LM_cache.g then
        return _LM_cache.h, _LM_cache.g
    end
    local lineH = FONT_HGT_SMALL * z
    local gap   = math.max(1, math.floor(lineH * 0.12))
    _LM_cache.z, _LM_cache.h, _LM_cache.g = z, lineH, gap
    return lineH, gap
end

-- Build height LUT for k=0..5 overflow lines.
-- Each overflow line adds exactly one line height; we also keep a tiny bottom gap.
-- NOTE: This depends on current text scale (via XP_NC_lineMetrics),
--       so rebuild when the scale changes.
local function XP_NC_buildHeightLUT(baseH)
    -- Single call: get both line height and gap
    local lineH, gap = XP_NC_lineMetrics()

    local lut = {}
    -- k = number of extra lines beyond the base box capacity
    for k = 0, 5 do
        -- Strictly linear growth from baseH so extra lines ALWAYS increase height
        lut[k] = baseH + k * lineH + gap
    end
    return lut
end

-- Global LUT cache keyed by "<zoom>|<baseH>"
local XP_NC_LUT_CACHE = {}
local function XP_NC_getHeightLUT(baseH)
    local key = tostring(XP_NC_getZoom()) .. "|" .. tostring(baseH)
    local lut = XP_NC_LUT_CACHE[key]
    if not lut then
        lut = XP_NC_buildHeightLUT(baseH)
        XP_NC_LUT_CACHE[key] = lut
    end
    return lut
end

-- Keep weak references to all patched lists so we can invalidate heights globally
local XP_NC_allLists = setmetatable({}, { __mode = "k" })

-- Global invalidation entry-point (called by XP_NC_ModOptions when options change)
_G.XP_NC_invalidateHeights = function()
    -- Clear LUTs to force rebuild with new scale
    XP_NC_LUT_CACHE = {}
    -- Mark all known lists dirty and recompute metrics
    for list in pairs(XP_NC_allLists) do
        if list then
            list.XP_NC_heightsDirty = true
            if list.updateScrollMetrics then pcall(function() list:updateScrollMetrics() end) end
            -- No refreshItems here; let UI cycle repaint naturally
        end
    end
end

-- Count how many distinct XP perks are NOT covered by any required skill
local function XP_NC_countXPLinesNotInReq(recipe)
    if not recipe then return 0 end
    local reqSet = {}
    local reqShownTotal = 0
    if recipe.getRequiredSkillCount and recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local rs = recipe:getRequiredSkill(i)
            local perk = rs and rs.getPerk and rs:getPerk()
            if perk then reqSet[perk:getId()] = true end
            reqShownTotal = reqShownTotal + 1
        end
    end

    local seen = {}
    local xpNotReq = 0
    for _, xpEntry in ipairs(NC_parseRecipeXPAwards(recipe)) do
        local key = xpEntry.perkId
        if not seen[key] then
            seen[key] = true
            if not reqSet[key] then
                xpNotReq = xpNotReq + 1
            end
        end
    end
    return xpNotReq, reqShownTotal
end

			-- -- Whether to draw the Mod line
			-- local function XP_NC_shouldShowMod(recipe)
				-- return XP_NC_shouldShowModLine and XP_NC_shouldShowModLine(recipe) or false
			-- end

-- Per-recipe metrics cache (weak keys to allow GC)
local XP_NC_metricsCache = setmetatable({}, { __mode = "k" })
local function XP_NC_getRecipeMetrics(recipe)
    if not recipe then return 0, 0 end
    local c = XP_NC_metricsCache[recipe]
    if c then return c.xpNotReq, c.reqTotal end

    -- Build set of required skill perks
    local reqSet, reqTotal = {}, 0
    if recipe.getRequiredSkillCount and recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local rs = recipe:getRequiredSkill(i)
            local perk = rs and rs.getPerk and rs:getPerk()
            if perk then reqSet[perk:getId()] = true end
            reqTotal = reqTotal + 1
        end
    end

    -- Count distinct XP-award perks that are NOT in reqSet
    local seen, xpNotReq = {}, 0
    for _, xpEntry in ipairs(NC_parseRecipeXPAwards(recipe)) do
        local key = xpEntry.perkId
        if not seen[key] then
            seen[key] = true
            if not reqSet[key] then xpNotReq = xpNotReq + 1 end
        end
    end

    XP_NC_metricsCache[recipe] = { xpNotReq = xpNotReq, reqTotal = reqTotal }
    return xpNotReq, reqTotal
end

-- Compute "overflow lines" k (0..5) and the cap for XP drawing
local function XP_NC_computeOverflow(recipe)
    local xpNotReq, reqTotal = XP_NC_getRecipeMetrics(recipe)
    local modShown = XP_NC_shouldShowModLine(recipe) and 1 or 0

    -- cap total extra lines to 5 (XP + Mod <= 5). Prefer keeping the Mod line.
    local xpCap    = math.max(0, 5 - modShown)
    local xpToShow = math.min(xpNotReq, xpCap)

	-- Only two required-skill lines fit in the base box. Extra req lines count as overflow.
	local baseSlots   = 2
	local reqShown    = math.min(reqTotal or 0, baseSlots)
	local extraReq    = math.max(0, (reqTotal or 0) - baseSlots)
	local slotsLeft   = math.max(0, baseSlots - reqShown)

	-- All below-top-two lines share the same 5-line cap (XP + Mod + extra req)
	local totalExtra = extraReq + xpToShow + modShown

    local overflowK  = math.max(0, totalExtra - slotsLeft)
    if overflowK > 5 then overflowK = 5 end
    return overflowK, xpToShow, modShown
end

----------------------------------------------------------------
-- Height math (extra lines = XP perks (distinct) – 1 + Mod line?)
----------------------------------------------------------------
local function XP_NC_countDistinctXPAwards(recipe)
    if not recipe then return 0 end
    local seen, n = {}, 0
    for _, xpEntry in ipairs(NC_parseRecipeXPAwards(recipe)) do
        local key = xpEntry.perkId
        if not seen[key] then
            seen[key] = true
            n = n + 1
        end
    end
    return n
end

function XP_NC_shouldShowModLine(recipe)
    local showModOpt = true
    if XP_NC_getShowRecipeMod then showModOpt = XP_NC_getShowRecipeMod() end
    if not showModOpt then return false end
    if not recipe then return false end

    -- 1) If NC can tell it's clearly vanilla, hide it.
    if NC_isLikelyVanillaRecipe and NC_isLikelyVanillaRecipe(recipe) then
        return false
    end
	
	-- [COMMENTED]: It does not make sense to check that because it will return the same
		-- -- 2) If we can resolve a pretty mod name and it's not "Base", show it.
		-- local pretty = NC_tryGetRecipeModName and NC_tryGetRecipeModName(recipe)
		-- if pretty and pretty ~= "Base" then
			-- return true
		-- end

		-- -- 3) Fallback: we couldn't prove it's vanilla, so prefer showing the line.
    return true
end

-- Count precisely how many extra text lines we must add below the two skill lines.
local function XP_NC_countExtraLines(recipe)
    if not recipe then return 0 end

    -- 1) Perks shown as skill lines (only the first two are printed on the box)
    local reqSet, reqShown = {}, 0
    if recipe.getRequiredSkillCount and recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local rs = recipe:getRequiredSkill(i)
            local perk = rs and rs.getPerk and rs:getPerk()
            local key  = perk and perk:getId()
            if key then reqSet[key] = true end
            if reqShown < 2 then reqShown = reqShown + 1 end -- at most 2 lines are rendered
        end
    end

    -- 2) Distinct XP-awarding perks that are NOT already covered by those skill lines
    local xpDistinct = 0
    do
        local seen = {}
        for _, xpEntry in ipairs(NC_parseRecipeXPAwards(recipe)) do
            local key = xpEntry.perkId
            if not seen[key] then
                seen[key] = true
                if not reqSet[key] then
                    xpDistinct = xpDistinct + 1   -- this will become its own XP line
                end
            end
        end
    end

    -- 3) Slots left in the base box (it fits 2 lines under the name)
    local slotsLeft = math.max(0, 2 - reqShown)

    -- 4) Total new lines below the skill lines = XP lines + optional Mod line
    local totalNew = xpDistinct + (XP_NC_shouldShowModLine(recipe) and 1 or 0)

    -- 5) Extra lines that force the box to grow
    return math.max(0, totalNew - slotsLeft)
end

-- Height wanted for a recipe box (pixel-perfect incl. Mod line fit)
local function XP_NC_desiredHeight(baseH, recipe)
    -- Compute the target height for this recipe box, including:
    --  (1) delta for the two base lines vs NC's reference zoom (0.8),
    --  (2) growth for overflow lines (XP + optional Mod line beyond base slots),
    --  (3) small safety/tuning so the bottom gap looks like interline spacing.
    if not recipe then return baseH end

    -- Overflow math (k = extra lines that force growth)
    local overflowK, xpToShow, modShownRaw = XP_NC_computeOverflow(recipe)
    local modShown = (modShownRaw == 1 or modShownRaw == true) and 1 or 0
    local kNum     = tonumber(overflowK) or 0

    -- Reference zoom used by NC's base box (0.8) and current line metrics
    local zoomRef    = 0.8
    local lineHRef   = FONT_HGT_SMALL * zoomRef
    local lineH, gap = XP_NC_lineMetrics()

    -- Base delta: make the box taller/shorter when the two base lines scale
    local deltaBase = 2 * (lineH - lineHRef)

    -- Effective k in LUT: DO NOT add a full extra line for Mod
    -- 'overflowK' already accounts for how many extra lines (XP + Mod) do not fit
    local effK = math.min(5, math.max(0, kNum))

    -- Strictly linear LUT: baseH + effK*lineH + gap
    local lut = XP_NC_getHeightLUT(baseH)
    local h   = (lut[effK] or baseH) + deltaBase

    -- ---- Bottom-gap tuning ----
    -- Idea:
    --  * When effK > 0 (there ARE overflow lines), we slightly tighten the bottom
    --    so the gap looks similar to interline spacing (not bigger).
    --  * When Mod line is drawn, add a very small nudge so descenders never clip.
    --  * When everything fits in base (effK==0) but we still draw lines,
    --    keep a tiny epsilon.
    local tighten   = math.floor(lineH * 0.15)   -- reduce bottom gap a bit on overflow (0.12-0.18)
    local modNudge  = 0; -- math.max(1, math.floor(lineH * 0.04))  -- small add if Mod shown(0.04-0.06)

    if effK > 0 then
        -- Tighten bottom gap for any overflow case (with or without Mod)
        h = h - tighten
        if modShown == 1 then
            -- Put back a tiny nudge so Mod line never kisses the border
            h = h + modNudge
        end
    else
        -- No overflow picked, but if we draw any extra lines keep a tiny epsilon
        local hasAnyLine = ((xpToShow or 0) + modShown) > 0
        if hasAnyLine then
            local epsilon = math.max(1, math.ceil(lineH * 0.12))
            h = math.max(h, baseH + deltaBase + epsilon)
        end
    end

    return h
end



----------------------------------------------------------------
-- XP text injection
----------------------------------------------------------------
function NC_RecipeList_Box:updateSkillTexts()
    self.skillTexts = {}
    self.unmatchedXPTexts = {}
	-- Extra required-skill lines beyond the first two (these also consume vertical space)
	self.extraReqTexts = {}
	
    -- Skip rebuild if inputs are identical
    local zoomScale = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8
    local fitW      = (self.maxTextWidth or 9999) / zoomScale
    local xpShow    = XP_NC_getxpShow and XP_NC_getxpShow() or true
    local xpFormat  = XP_NC_getxpFormat and tostring(XP_NC_getxpFormat()) or "1"

    local _textKey = table.concat({
        tostring(self.recipe),
        tostring(fitW),
        tostring(zoomScale),
        tostring(xpShow),
        tostring(xpFormat),
    }, "|")

	if self._xpnc_textKey == _textKey and self._xpnc_skillTexts and self._xpnc_unmatchedXPTexts then
		-- Restore all cached arrays, including extra required-skill lines
		self.skillTexts       = self._xpnc_skillTexts
		self.unmatchedXPTexts = self._xpnc_unmatchedXPTexts
		self.extraReqTexts    = self._xpnc_extraReqTexts or {}
		return
	end

    if not self.recipe or (self.recipe.getRequiredSkillCount and self.recipe:getRequiredSkillCount() == 0 and self.recipe.getXPAwardCount and self.recipe:getXPAwardCount() == 0) then
        return
    end
	--

    local player = self.player
    local xpAwards = {}

    -- Collect XP awards: perkId -> amount (these are the lines we want to show)
    for _, xpEntry in ipairs(NC_parseRecipeXPAwards(self.recipe)) do
        xpAwards[xpEntry.perkId] = xpEntry.amount
    end

    -- Required skills (top two) — Rocco original behaviour; merge XP with them if same perk.
    if self.recipe.getRequiredSkillCount and self.recipe:getRequiredSkillCount() > 0 then
        for i = 0, self.recipe:getRequiredSkillCount() - 1 do
            local requiredSkill = self.recipe:getRequiredSkill(i)
            local skillPerk = requiredSkill:getPerk()
            local skillName = skillPerk:getName()
            local level = requiredSkill:getLevel()

            local xpAmount = xpAwards[skillPerk:getId()]

            -- Build the skill line as: "LV<level> <skillName> (<xp details>)"
            local basePrefix = "LV" .. level .. " " .. skillName
            local skillText

            if XP_NC_getxpShow and XP_NC_getxpShow() and xpAmount then
                local xpFormat = XP_NC_getxpFormat and XP_NC_getxpFormat() or "1"

                if xpFormat == "1" then
                    -- Base XP
                    skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " XP)"
                else
                    local mult = getXPMultiplier(player, skillPerk)
                    local xpAmountFinal = math.floor(xpAmount * mult.total * 100 + 0.5) / 100

                    if xpFormat == "2" then
                        -- Final XP
                        skillText = basePrefix .. " (+" .. xpAmountFinal .. " XP)"
                    elseif xpFormat == "3" then
                        -- Multiplier (base * total = final)
                        skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " * " .. formatNumber(mult and mult.total or 1) .. " = " .. xpAmountFinal .. " XP)"
                    elseif xpFormat == "4" then
                        -- Breakdown (skillBoost*book*learner*crafty*sandbox)
                        if mult then mult.string = formatNumber(mult.skillBoost) .. "*" .. formatNumber(mult.bookMultiplier) .. "*" .. formatNumber(mult.learnerMultiplier*mult.craftyMultiplier) .. "*" .. formatNumber(mult.sandboxMultiplier) end
                        skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " * " .. (mult and mult.string or "1") .. " = " .. xpAmountFinal .. " XP)"
                    else
                        skillText = basePrefix
                    end
                end
            else
                -- No XP shown (or no XP award for this perk)
                skillText = basePrefix
            end


			local zoomScale = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8 -- use same zoom as render
			local fitW = self.maxTextWidth / zoomScale                    -- measure width in un-zoomed font space
			skillText = NeatTool.truncateText(skillText, fitW, UIFont.Small, "...")
            local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)

            table.insert(self.skillTexts, { text = skillText, isMet = isMet })
			-- If there are more than 2 required skills, keep the extras to render below
			-- NOTE: loop is 0-based (0,1,2,...). Index >= 2 means "3rd and onward".
			if i >= 2 then
				table.insert(self.extraReqTexts, { text = skillText, isMet = isMet })
			end

            if xpAmount then xpAwards[skillPerk:getId()] = nil end -- avoid duplicate in unmatched XP
        end
    end

    -- Remaining XP awards lines (these are exactly the “XP lines” you wanted)
    for perkId, amount in pairs(xpAwards) do
        if XP_NC_getxpShow and XP_NC_getxpShow() then
            local perk = XP_NC_resolvePerk(perkId)
            local perkName = (perk and perk.getName and perk:getName()) or perkId
            local xpText
            local xpFormat = XP_NC_getxpFormat and XP_NC_getxpFormat() or "1"
            if xpFormat == "1" then
                xpText = "+ " .. formatNumber(amount) .. " XP " .. perkName
            else
                local mult = perk and getXPMultiplier(player, perk)
                local xpAmountFinal = mult and math.floor(amount * mult.total * 100 + 0.5)/100 or amount
                if xpFormat == "2" then
                    xpText = "+ " .. xpAmountFinal .. " XP " .. perkName
                elseif xpFormat == "3" then
                    xpText = "+ " .. formatNumber(amount) .. " * " .. formatNumber(mult and mult.total or 1) .. " = " .. xpAmountFinal .. " XP " .. perkName
                elseif xpFormat == "4" then
                    if mult then mult.string = formatNumber(mult.skillBoost) .. "*" .. formatNumber(mult.bookMultiplier) .. "*" .. formatNumber(mult.learnerMultiplier*mult.craftyMultiplier) .. "*" .. formatNumber(mult.sandboxMultiplier) end
                    xpText = "+ " .. formatNumber(amount) .. " * " .. (mult and mult.string or "1") .. " = " .. xpAmountFinal .. " XP " .. perkName
                else
                    xpText = "+ " .. formatNumber(amount) .. " XP " .. perkName
                end
            end

			local zoomScale = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8
			local fitW = self.maxTextWidth / zoomScale
			xpText = NeatTool.truncateText(xpText, fitW, UIFont.Small, "...")
            table.insert(self.unmatchedXPTexts, { text = xpText, amount = amount })
        end
    end
    -- (CACHE) save computed lines for the same key
    self._xpnc_textKey          = _textKey
    self._xpnc_skillTexts       = self.skillTexts
	self._xpnc_extraReqTexts    = self.extraReqTexts  -- extra required-skill lines
    self._xpnc_unmatchedXPTexts = self.unmatchedXPTexts
end

----------------------------------------------------------------
-- VARIABLE-HEIGHT PATCH for NIVirtualScrollView (single, safe shim)
--  * Keeps original list lifecycle (pool/create/etc.).
--  * Replaces total height, visible-range and item placement using per-item heights.
--  * Avoids overlap and shows a full page of items (no “only 2–3 at top” bug).
----------------------------------------------------------------
local function XP_NC_extractRecipeFromData(data)
    if not data then return nil end
    if type(data) == "table" then
        if data.recipe then return data.recipe end
        if data.Recipe then return data.Recipe end
        if data.recipeData and data.recipeData.recipe then return data.recipeData.recipe end
        if data.item and data.item.recipe then return data.item.recipe end
    end
    if type(data) == "userdata" or type(data) == "table" then
        if data.getXPAwardCount and data.getRequiredSkillCount then
            return data
        end
    end
    return nil
end

local function XP_NC_installVHOnList(list)
    if not list or list.XP_NC_vh_installed then return end
    list.XP_NC_vh_installed = true
    dprint("[XP_NC] [vh] installing variable-height on list instance")

    -- Track this list instance so global invalidation can touch it later
    XP_NC_allLists[list] = true

    -- cache
    list.XP_NC_heights   = {}
    list.XP_NC_prefix    = {0} -- prefix[i] = sum_{k<=i}(height[k] + pad)
    list.XP_NC_cacheKey  = ""
    list.XP_NC_baseBoxH  = list.itemHeight or 83.2
	list.XP_NC_heightsDirty = true

    ----------------------------------------------------------------
    -- datasource adapters (Lua table OR Java/Kahlua List)
    ----------------------------------------------------------------
    local function ds_len(ds)
        -- Java/Kahlua list exposes :size(); Lua tables use #ds
        if type(ds) == "table" then
            return #ds
        elseif ds and type(ds.size) == "function" then
            -- Kahlua List uses 0-based indexing; size() returns count
            return ds:size()
        else
            return 0
        end
    end

    local function ds_get(ds, i)
        -- i is 1-based (Lua style) in our code; adjust if Java list
        if type(ds) == "table" then
            return ds[i]
        elseif ds and type(ds.get) == "function" then
            return ds:get(i - 1) -- convert to 0-based
        else
            return nil
        end
    end

    ----------------------------------------------------------------
    -- DataSource signature for cheap "same content" detection
    ----------------------------------------------------------------
    list.XP_NC_lastSigCount = -1
    list.XP_NC_lastSigFirst = nil
    list.XP_NC_lastSigLast  = nil

    local function ds_signature(ds)
        local n = ds_len(ds)
        if n == 0 then return 0, nil, nil end
        local first = tostring(ds_get(ds, 1))
        local last  = tostring(ds_get(ds, n))
        return n, first, last
    end

    -- keep originals
    local _orig_setDataSource        = list.setDataSource
    local _orig_refreshItems         = list.refreshItems
    local _orig_updateScrollMetrics  = list.updateScrollMetrics
    local _orig_calculateVisibleRange= list.calculateVisibleRange

    local function currentCacheKey()
        local showMod = (XP_NC_getShowRecipeMod and XP_NC_getShowRecipeMod()) and 1 or 0
        local zoom = XP_NC_getZoom()
        return tostring(zoom) .. "|" .. tostring(showMod)
    end

	local function recomputeHeights(self)
        -- Skip if nothing marked dirty (prevents redundant recomputes)
        if not self.XP_NC_heightsDirty then return end
	
        local ds    = self.dataSource or {}
        local baseH = self.XP_NC_baseBoxH or self.itemHeight or 80

        local H = {}
        local n = ds_len(ds)  -- unified length
        for i = 1, n do
            local recipe = XP_NC_extractRecipeFromData(ds_get(ds, i))

			if recipe then
				-- Use the unified height calculator (handles Mod-line epsilon)
				H[i] = XP_NC_desiredHeight(baseH, recipe)
			else
				H[i] = baseH
			end
		end
		self.XP_NC_heights = H

        -- build prefix (sum of heights + per-row gap)
		local pad = self.padding or 0
		self.XP_NC_prefix = {0}
		local acc = 0
		for i = 1, #H do
			acc = acc + (H[i] or baseH) + pad
			self.XP_NC_prefix[i] = acc
		end
		
        -- Done; clear dirty flag (so other callers won't recompute again)
        self.XP_NC_heightsDirty = false
	end

    -- override setDataSource: keep original; only mark dirty if content actually changed
    if type(list.setDataSource) == "function" and not list._XP_NC_setDataSourceWrapped then
        local _orig_setDS = list.setDataSource
        function list:setDataSource(dataSource, forceRefresh)
            local n, f, l = ds_signature(dataSource)
            local same = (self.XP_NC_lastSigCount == n) and (self.XP_NC_lastSigFirst == f) and (self.XP_NC_lastSigLast == l)

            -- Always call original to keep internal state in sync
            local ret = _orig_setDS(self, dataSource, forceRefresh)

			-- Force item rebinding on data changes even if the visible range doesn't move
			-- (category switches can keep start/end equal and pooled items would not update)
			self.visibleStartIndex, self.visibleEndIndex = -1, -1   -- make refreshItems rebind
			self.XP_NC_needReassign = true                          -- extra guard for our override

            -- Only mark dirty if the content actually changed
            if not same then
                self.XP_NC_lastSigCount = n
                self.XP_NC_lastSigFirst = f
                self.XP_NC_lastSigLast  = l
                self.XP_NC_heightsDirty = true
                if self.updateScrollMetrics then self:updateScrollMetrics() end
                -- No refreshItems() here -> avoids flicker and redundant paints
            end
            return ret
        end
        list._XP_NC_setDataSourceWrapped = true
    end

    -- override calculateVisibleRange using prefix sums (variable heights)
	function list:calculateVisibleRange()
        local ds = self.dataSource or {}
        local n  = ds_len(ds)
		if n == 0 then return 1, 0 end

		-- Ensure prefix is built before using it (guard for category switches)
		if self.XP_NC_heightsDirty or not self.XP_NC_prefix or not self.XP_NC_prefix[n] then
			if recomputeHeights then recomputeHeights(self) end
			self.XP_NC_heightsDirty = false
		end

		local pref = self.XP_NC_prefix or {0}
		local pad  = self.padding
		if type(pad) ~= "number" then pad = tonumber(pad) or 0 end

		local top    = self.scrollOffset or 0
		local bottom = top + self.height

		local function lowerBound(x)
			local lo, hi = 1, n
			while lo < hi do
				local mid = math.floor((lo + hi) / 2)
				-- Fallback to 0 if pref[mid] is missing to avoid __add error
				local itemBottom = pad + (pref[mid] or 0)
				if itemBottom > x then
					hi = mid
				else
					lo = mid + 1
				end
			end
			return lo
		end

		local function upperBound(x)
			local lo, hi = 1, n
			while lo < hi do
				local mid = math.floor((lo + hi + 1) / 2)
				local itemTop = pad + (pref[mid-1] or 0)
				if itemTop < x then
					lo = mid
				else
					hi = mid - 1
				end
			end
			return lo
		end

		local s = lowerBound(top);    if s > n then return n, n end
		local e = upperBound(bottom); if e < s then e = s end

		-- small buffer to avoid popping
		s = math.max(1, s - 1)
		e = math.min(n, e + 1)
		return s, e
	end

    -- override updateScrollMetrics to use sum of per-item heights
	function list:updateScrollMetrics()
		if self.XP_NC_heightsDirty then
			if recomputeHeights then recomputeHeights(self) end
			self.XP_NC_heightsDirty = false
		end

		_orig_updateScrollMetrics(self)

		local ds   = self.dataSource or {}
		local n    = #ds
		local pref = self.XP_NC_prefix or {0}

		local pad  = self.padding
		if type(pad) ~= "number" then pad = tonumber(pad) or 0 end

		local last = pref[n] or 0
		local rowGap = self.XP_NC_rowGap or 1
		local totalCore = math.max(pad + math.max(0, last - rowGap), self.height)

		self.totalHeight = totalCore
		if n == 0 or totalCore <= self.height then
			self.maxScrollOffset = 0
		else
			self.maxScrollOffset = totalCore - self.height
		end
		self.scrollOffset = math.max(0, math.min(self.scrollOffset or 0, self.maxScrollOffset or 0))

		if self.updateScrollBar then self:updateScrollBar() end
	end

    -- override refreshItems to place items by cumulative heights (no overlap)
    function list:refreshItems()
        if not self.onUpdateItem or #self.itemPool == 0 then return end
		if self.XP_NC_inRefresh then return end
		self.XP_NC_inRefresh = true

		-- Ensure prefix/heights exist before querying visible range
		local ds = self.dataSource or {}
		local n  = ds_len(ds)
		if self.XP_NC_heightsDirty or not self.XP_NC_prefix or not self.XP_NC_prefix[n] then
			if recomputeHeights then recomputeHeights(self) end
			self.XP_NC_heightsDirty = false
		end

        -- with updated metrics, get visible range
        local startIndex, endIndex = self:calculateVisibleRange()
		
		-- Also reassign when a new dataSource was set (category switched)
		local forceReassign = self.XP_NC_needReassign == true
		local needReassignData = forceReassign or (startIndex ~= self.visibleStartIndex or endIndex ~= self.visibleEndIndex)

        self.visibleStartIndex = startIndex
        self.visibleEndIndex   = endIndex

        if needReassignData then
            for _, item in ipairs(self.itemPool) do item:setVisible(false) end
        end

        local ds   = self.dataSource or {}
        local n    = ds_len(ds)
        local H    = self.XP_NC_heights
        local pref = self.XP_NC_prefix
        local pad  = self.padding or 5

        local poolIndex = 1
        for i = startIndex, endIndex do
            if poolIndex > #self.itemPool then break end
            if i <= n then
                local item = self.itemPool[poolIndex]
                local data = ds_get(ds, i)

                if needReassignData then
                    self.onUpdateItem(item, data) -- NC will call :setRecipe inside
                    item:setVisible(true)
                end

                local h = H[i] or (item.getHeight and item:getHeight()) or (self.itemHeight or 0)
                if item.setHeight then item:setHeight(h) end

                local rowGap = self.XP_NC_rowGap or 1
                local y = pad + (pref[i-1] or 0) - rowGap - (self.scrollOffset or 0)
                item:setY(y)

                poolIndex = poolIndex + 1
            end
        end
		self.XP_NC_inRefresh = false
		self.XP_NC_needReassign = false
    end
end

-- Expose variable-height installer as a global so patch files can call it safely.
-- Make the installer visible to other modules (patch calls it via _G.*)
_G.XP_NC_installVHOnList = XP_NC_installVHOnList


----------------------------------------------------------------
-- Dynamic-height patch on the box: keep icon strip width fixed
----------------------------------------------------------------
local function XP_NC_applyPostSetEntry(self, entry, canMake)
    -- Install the variable-height scroll shim on the real list used by NC.
    local list = self.parentPanel and (self.parentPanel.currentScrollView or self.parentPanel.list)
    if list then
        XP_NC_installVHOnList(list)
    end

    -- Build 42.16+ recipe groups reuse the same UI boxes through setEntry().
    -- Group headers are not real recipes, so keep them at base height and clear
    -- any cached recipe-specific text/height state left from recycled boxes.
    if self.entryType == "group" or not self.recipe then
        local baseH = self.XP_NC_baseHeight or self.height
        if math.abs((self.height or 0) - baseH) > 0.1 then
            self:setHeight(baseH)
            if list then
                list.XP_NC_heightsDirty = true
            end
        end

        if self.XP_NC_iconAreaW then self.iconAreaSize = self.XP_NC_iconAreaW end
        if self.XP_NC_iconSize   then self.iconSize    = self.XP_NC_iconSize   end

        self.XP_NC_lastRecipe    = nil
        self.XP_NC_lastDesiredH  = nil
        self.XP_NC_lastHeightKey = nil
        self.XP_NC_modShown      = false
        self.XP_NC_modPretty     = nil
        self.XP_NC_modText       = nil
        self._xpnc_sharedBudgetLeft = nil
        return
    end

    local recipe = self.recipe
    local baseH   = self.XP_NC_baseHeight or self.height
    local keyZoom = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8
    local keyMod  = (XP_NC_getShowRecipeMod and XP_NC_getShowRecipeMod()) and 1 or 0
    local heightKey = tostring(keyZoom) .. "|" .. tostring(keyMod)

    local desiredH
    if self.XP_NC_lastRecipe == recipe and self.XP_NC_lastDesiredH and self.XP_NC_lastHeightKey == heightKey then
        desiredH = self.XP_NC_lastDesiredH
    else
        desiredH = XP_NC_desiredHeight(baseH, recipe)
        self.XP_NC_lastRecipe    = recipe
        self.XP_NC_lastDesiredH  = desiredH
        self.XP_NC_lastHeightKey = heightKey
    end

    if math.abs((self.height or 0) - desiredH) > 0.1 then
        self:setHeight(desiredH)

        -- Do NOT change icon strip width/size.
        if self.XP_NC_iconAreaW then self.iconAreaSize = self.XP_NC_iconAreaW end
        if self.XP_NC_iconSize   then self.iconSize    = self.XP_NC_iconSize   end

        -- Mark heights dirty; defer recompute to the next updateScrollMetrics call.
        if list then
            list.XP_NC_heightsDirty = true
        end
    end

    local wantMod = XP_NC_shouldShowModLine and XP_NC_shouldShowModLine(recipe)
    self.XP_NC_modShown = wantMod and true or false
    if self.XP_NC_modShown then
        local modPretty = NC_tryGetRecipeModName and NC_tryGetRecipeModName(recipe)
        self.XP_NC_modPretty = modPretty
        local z    = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8
        local fitW = (self.maxTextWidth or 9999) / z
        local txt  = getText("UI_XP_NC_modPrefix") .. tostring(modPretty or "")

        if NeatTool and NeatTool.truncateText then
            self.XP_NC_modText = NeatTool.truncateText(txt, fitW, UIFont.Small, "...")
        else
            self.XP_NC_modText = txt
        end
    else
        self.XP_NC_modPretty, self.XP_NC_modText = nil, nil
    end
end

local function XP_NC_installDynamicHeightPatch()
    dprint("install dynamic height patch called")
    if _G.XP_NC_patch_applied then dprint("patch already applied"); return end
    if not NC_RecipeList_Box or not NC_RecipeList_Box.new then
        dprint("[XP_NC] NC_RecipeList_Box not ready (will rely on OnGameStart)")
        return
    end
    dprint("[XP_NC] NC_RecipeList_Box detected applying wrappers")

    local _orig_new = NC_RecipeList_Box.new
    function NC_RecipeList_Box:new(x, y, width, height, recipe, parentPanel)
        local o = _orig_new(self, x, y, width, height, recipe, parentPanel)

        -- Remember fixed base metrics so icon/text don’t shift horizontally.
        o.XP_NC_baseHeight = height
        o.XP_NC_iconAreaW  = o.iconAreaSize   -- fixed width for the left strip
        o.XP_NC_iconSize   = o.iconSize       -- fixed icon size

        o.XP_NC_lastRecipe    = nil
        o.XP_NC_lastDesiredH  = nil
		if not XP_NC_BOX_PADDING then XP_NC_BOX_PADDING = o.padding end
        return o
    end

    if NC_RecipeList_Box.setEntry then
        local _orig_setEntry = NC_RecipeList_Box.setEntry
        function NC_RecipeList_Box:setEntry(entry, canMake)
            _orig_setEntry(self, entry, canMake)
            XP_NC_applyPostSetEntry(self, entry, canMake)
        end
    else
        dprint("[XP_NC] setEntry not present to wrap")
    end

    if NC_RecipeList_Box.setRecipe then
        local _orig_setRecipe = NC_RecipeList_Box.setRecipe
        function NC_RecipeList_Box:setRecipe(recipe, canMake)
            _orig_setRecipe(self, recipe, canMake)
            XP_NC_applyPostSetEntry(self, recipe, canMake)
        end
    else
        dprint("[XP_NC] setRecipe not present to wrap")
    end

    _G.XP_NC_patch_applied = true
    dprint("[XP_NC] patch applied ok")
end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(XP_NC_installDynamicHeightPatch)
    dprint("[XP_NC] OnGameStart hook added")
else
    dprint("[XP_NC] OnGameStart not available")
end

-- Try immediately too
XP_NC_installDynamicHeightPatch()

-- Override prerender to draw fixed-width backgrounds (sloticon/slotleft)
function NC_RecipeList_Box:prerender()
    -- === NC colors/alpha ===
    local bgAlpha = self.canMakeRecipe and 1.0 or 0.5
    local r, g, b = 0.15, 0.15, 0.15                 -- idle background tint like NC
    if self:isMouseOver() then r, g, b = 0.20, 0.20, 0.20 end

    -- Selection toggles ONLY the border tint (orange) and forces alpha 1.0 (NC behaviour)
    local br, bgc, bb = 0.2, 0.2, 0.2                -- border grey by default
    local handCraftPanel = self.parentPanel and self.parentPanel.HandCraftPanel
    if handCraftPanel and handCraftPanel.logic:getRecipe() == self.recipe then
        br, bgc, bb = 0.8, 0.5, 0.2                  -- border orange when selected
        bgAlpha = 1.0
    end

    -- === NC textures (cache) ===
    self._xpnc_sloticon   = self._xpnc_sloticon   or NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    self._xpnc_slotleft   = self._xpnc_slotleft   or NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    self._xpnc_slotborder = self._xpnc_slotborder or NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")

    -- Fixed icon strip width (do NOT scale with self.height)
    local absX, absY = self:getAbsoluteX(), self:getAbsoluteY()
    local w, h       = self.width, self.height
    local iconStripW = self.XP_NC_iconAreaW or self.iconAreaSize
    local rightX     = absX + iconStripW
    local rightW     = math.max(0, w - iconStripW)

    -- === Left icon background (fixed width), NC tint + bgAlpha ===
    if self._xpnc_sloticon then
        self._xpnc_sloticon:render(absX, absY, iconStripW, h, r, g, b, bgAlpha)
    else
        self:drawRect(0, 0, iconStripW, h, 0.08 * bgAlpha, 1, 1, 1)
    end

    -- === Right/text background, NC tint + bgAlpha ===
    if self._xpnc_slotleft then
        self._xpnc_slotleft:render(rightX, absY, rightW, h, r, g, b, bgAlpha)
    else
        self:drawRect(iconStripW, 0, rightW, h, 0.05 * bgAlpha, 1, 1, 1)
    end

    -- === Border with NC texture (tinted grey/orange) ===
    if self._xpnc_slotborder then
        self._xpnc_slotborder:render(absX, absY, w, h, br, bgc, bb, bgAlpha)
    else
        self:drawRectBorder(0, 0, w, h, 0.7 * bgAlpha, 1, 1, 1)
    end

    -- Keep base behaviors (children clipping, etc.)
    ISUIElement.prerender(self)
end

----------------------------------------------------------------
-- Render (icon strip width fixed; text area stays aligned)
----------------------------------------------------------------
function NC_RecipeList_Box:render()
    -- Safety: nothing to draw if there is no active entry.
    if not self.recipe and self.entryType ~= "group" then return end
	
    -- Left icon strip stays fixed even if the box grows in height ---
    local iconStripW = self.XP_NC_iconAreaW or self.iconAreaSize   -- fixed width for icon strip
    local baseH      = self.XP_NC_baseHeight or self.height        -- base height (used to center the icon)
    local iconSize   = self.XP_NC_iconSize or self.iconSize
    local indentOffset = (self.getEntryIndentOffset and self:getEntryIndentOffset()) or 0

    local iconAreaX, iconAreaY = indentOffset, 0

    if self.entryType == "group" and self.node then
        local groupIcon = (self.node.getIconTexture and self.node:getIconTexture()) or nil
        if groupIcon and iconSize and iconSize > 0 then
            local iconAlpha = self.canMakeRecipe and 1.0 or 0.6
            local iconX = iconAreaX + (iconStripW - iconSize) / 2
            local iconY = iconAreaY + (baseH - iconSize) / 2
            self:drawTextureScaledAspect(groupIcon, iconX, iconY, iconSize, iconSize, iconAlpha, 1, 1, 1)
        end

        local groupStateTexture = self.groupClosedTexture
        if self.node.getExpandedState and self.node:getExpandedState() == CraftRecipeListNodeExpandedState.OPEN then
            groupStateTexture = self.groupOpenTexture
        elseif self.node.getExpandedState and self.node:getExpandedState() == CraftRecipeListNodeExpandedState.PARTIAL then
            groupStateTexture = self.groupPartialTexture
        end

        if groupStateTexture then
            local arrowSize = math.floor(baseH * 0.4)
            local arrowX = iconAreaX + self.padding
            local arrowY = (baseH - arrowSize) / 2
            self:drawTextureScaledAspect(groupStateTexture, arrowX, arrowY, arrowSize, arrowSize, 1, 1, 1, 1)
        end
        return
    end

    -- Draw recipe icon (centered vertically by base height; never upscaled)
    local recipeIcon = self.recipe:getIconTexture()
    if recipeIcon and iconSize and iconSize > 0 then
        local alphaIcon = self.canMakeRecipe and 1.0 or 0.5
        local IconX = iconAreaX + (iconStripW - iconSize) / 2
        local IconY = iconAreaY + (baseH - iconSize) / 2
        self:drawTextureScaledAspect(recipeIcon, IconX, IconY, iconSize, iconSize, alphaIcon, 1, 1, 1)
    end

    -- Draw favourite heart (same logic as NC; uses full box height for size)
    local favString = BaseCraftingLogic.getFavouriteModDataString(self.recipe)
    if self.player:getModData()[favString] then
        local favIconSize = math.floor(self.height / 5)
        local favIconX = iconAreaX + self.padding
        local favIconY = iconAreaY + baseH - favIconSize - self.padding
        self:drawTextureScaledAspect(self.favouriteIcon, favIconX, favIconY, favIconSize, favIconSize, 1, 0.8, 0.2, 0.2)
    end

    -- --- Text area: two skill lines + XP lines + optional Mod line ---
    -- nameLabel (title) is an ISLabel child created in createChildren(), so we start below it
    local zoomScale = (XP_NC_getZoom and XP_NC_getZoom()) or 0.8
	local lineStep  = FONT_HGT_SMALL * zoomScale
    local textX     = iconStripW + self.padding + indentOffset
    local textY     = self.padding + FONT_HGT_SMALL
    local alphaText = self.canMakeRecipe and 1.0 or 0.5

    -- 1) Required-skill lines
    if self.skillTexts and #self.skillTexts > 0 then
        for i = 1, math.min(#self.skillTexts, 2) do
            local s = self.skillTexts[i]
            -- green if met; reddish if not met
            local r, g, b = (s.isMet and 0.2 or 1.0), (s.isMet and 1.0 or 0.2), 0.2
            self:drawTextZoomed(s.text, textX, textY, zoomScale, r, g, b, alphaText, UIFont.Small)
            textY = textY + lineStep
        end
		
		-- --- Extra required-skill lines (beyond the first two) ---
		-- These share the same 5-line budget as XP + Mod.
		local extraPrinted = 0
		local extraReqList = self.extraReqTexts or {}
		do
			-- Decide if Mod will be shown (affects the budget shared with XP and extra req)
			local willShowMod = (XP_NC_shouldShowModLine and XP_NC_shouldShowModLine(self.recipe)) and true or false
			local sharedBudget = 5 - (willShowMod and 1 or 0) -- reserve one slot if Mod will be drawn

			if #extraReqList > 0 and sharedBudget > 0 then
				local upto = math.min(#extraReqList, sharedBudget)
				for i = 1, upto do
					local s = extraReqList[i]
					local r, g, b = (s.isMet and 0.2 or 1.0), (s.isMet and 1.0 or 0.2), 0.2
					self:drawTextZoomed(s.text, textX, textY, zoomScale, r, g, b, alphaText, UIFont.Small)
					textY = textY + lineStep
					extraPrinted = extraPrinted + 1
				end
			end

			-- Store the remaining budget for the XP block below
			self._xpnc_sharedBudgetLeft = math.max(0, (5 - (willShowMod and 1 or 0)) - extraPrinted)
		end		
    end

    -- 2) XP lines (capped so XP+Mod ≤ 5). We prefer to keep the Mod line if present.
    local showXP   = true
    if XP_NC_getxpShow then showXP = XP_NC_getxpShow() and true or false end

    -- Decide if we will show the Mod line and compute cap for XP
    local modShown, modPretty = false, nil
    if XP_NC_shouldShowModLine and XP_NC_shouldShowModLine(self.recipe) then
        modShown  = true
        modPretty = NC_tryGetRecipeModName and NC_tryGetRecipeModName(self.recipe)
    end
	-- Whatever remains after extra req lines is the cap for XP lines
	local maxXp = math.max(0, self._xpnc_sharedBudgetLeft or (5 - (modShown and 1 or 0)))

    if showXP and self.unmatchedXPTexts and #self.unmatchedXPTexts > 0 then
        local upto = math.min(#self.unmatchedXPTexts, maxXp)
        for i = 1, upto do
            local xpData = self.unmatchedXPTexts[i]
            -- XP lines in green
            self:drawTextZoomed(xpData.text, textX, textY, zoomScale, 0.2, 1.0, 0.2, alphaText, UIFont.Small)
            textY = textY + lineStep
        end
    end

    -- 3) Optional Mod line (cornflower blue-ish)
    if modShown and modPretty then
        -- Truncate to fit the text column width like NC
		local modText = self.XP_NC_modText or (getText("UI_XP_NC_modPrefix") .. tostring(modPretty))
		if not self.XP_NC_modText and NeatTool and NeatTool.truncateText then
			local fitW = (self.maxTextWidth or 9999) / zoomScale
			modText = NeatTool.truncateText(modText, fitW, UIFont.Small, "...")
			self.XP_NC_modText = modText
		end
        self:drawTextZoomed(modText, textX, textY, zoomScale, 0.392, 0.584, 0.929, alphaText, UIFont.Small)
        textY = textY + lineStep
    end

    -- --- Right-side status icons (same as NC) ---
    local rightMargin = self.padding
    local iconsToShow = {}

    -- cannot be done in dark -> light icon
    if not self.recipe:canBeDoneInDark() then
        table.insert(iconsToShow, { texture = self.lightIconTexture,  alpha = alphaText })
    end
    -- need to be learnt -> book icon
    if self.recipe:needToBeLearn() then
        table.insert(iconsToShow, { texture = self.skillIconTexture,  alpha = alphaText })
    end
    -- needs surface -> surface icon
    if not self.recipe:isInHandCraftCraft() then
        table.insert(iconsToShow, { texture = self.surfaceIconTexture, alpha = alphaText })
    end
    -- can walk while crafting -> walk icon
    if self.recipe:isCanWalk() and not self.player:hasAwkwardHands() then
        table.insert(iconsToShow, { texture = self.walkIconTexture,   alpha = alphaText })
    end

    local iconX = self.width - rightMargin - self.statusIconSize
    local availableHeight   = self.height - self.padding * 2
    local totalIconsHeight  = 3 * self.statusIconSize               -- NC layout style
    local iconSpacing       = (availableHeight - totalIconsHeight) / 2

    for i = 1, #iconsToShow do
        local ic = iconsToShow[i]
        local iconY = self.padding + (i - 1) * (self.statusIconSize + iconSpacing)
        self:drawTextureScaled(ic.texture, iconX, iconY, self.statusIconSize, self.statusIconSize, ic.alpha, 1, 1, 1)
    end
end

