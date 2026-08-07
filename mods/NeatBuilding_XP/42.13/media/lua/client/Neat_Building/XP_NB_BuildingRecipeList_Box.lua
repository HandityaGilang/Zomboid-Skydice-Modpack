-- XP_NB: draw our extra lines (XP/skill and Mod) under the recipe title

require "ISUI/ISUIElement"
-- Load the mod options file to use its functions.
require "XP_NB_ModOptions"

-- The add-on can be enabled with either the full Neat Building variant or the UI-only variant.
-- If no Neat Building UI class is present, stay inactive instead of crashing.
if not NB_BuildingRecipeList_Box then
    print("[XP_NB] Neat Building UI not found; Neat Building XP addon is inactive.")
    return
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Load precomputed build sets (vanilla vs. NB-only)
-- These tables help us decide whether a recipe is vanilla / Neat Building / other.
do
    local ok, mod = pcall(require, "XP_NB_BuildSets")
    if not ok then
        ok, mod = pcall(require, "XP_NB_BuildSets")
    end
    if ok and type(mod) == "table" then
        rawset(_G, "XP_NB_SETS", mod)
    end
end

-- --- Mod-line resolver (single source of truth) -----------------------------
-- Framework providers we must NOT attribute to content mods
local XP_NB_FRAMEWORK_IDS = {
    NeatUI = true, NeatUI_Framework = true,
    Neat_Crafting = true, NeatCrafting = true,
}
-- Also guard by display name (game may only populate getModName)
local XP_NB_FRAMEWORK_NAMES = {
    ["neatcrafting"] = true, ["neat ui"] = true, ["neatuiframework"] = true, ["neatui"] = true,
}

local function _xpnb_norm(s)
    if not s or s == "" then return nil end
    s = tostring(s):lower():gsub("[^%w]", "")
    return s
end

local function _xpnb_isFramework(mid, mname)
    if mid and XP_NB_FRAMEWORK_IDS[mid] then return true end
    local nmid   = _xpnb_norm(mid)
    local nname  = _xpnb_norm(mname)
    if nmid  and XP_NB_FRAMEWORK_NAMES[nmid]  then return true end
    if nname and XP_NB_FRAMEWORK_NAMES[nname] then return true end
    return false
end

-- Returns the *display* label for the Mod line, or nil for vanilla (hide line).
local function XP_NB_resolveModLabel(recipe)
    if not recipe then return nil end
    local name  = recipe.getName and recipe:getName() or nil

    -- 1) Explicit overrides
    local sets = rawget(_G, "XP_NB_SETS")
    local overrides = sets and sets.XP_NB_MOD_NAME_BY_RECIPE
    if overrides and name and overrides[name] then
        return overrides[name]
    end

    -- 2) Precomputed sets
    local vanilla = sets and sets.XP_NB_VANILLA_BUILD_SET
    if vanilla and name and vanilla[name] then return nil end

    local neat = sets and sets.XP_NB_NEAT_BUILD_SET
    if neat and name and neat[name] then return getText("UI_XP_NB_modNeat") end

    local shelter = sets and sets.XP_NB_SHELTERHOLD_SET
    if shelter and name and shelter[name] then return "ShelterHold:Beehive" end

    -- 3) Provider fallback, filtering frameworks by id *o* nombre
    local mid   = recipe.getModID   and recipe:getModID()   or nil
    local mname = recipe.getModName and recipe:getModName() or nil
    if mid == "pz-vanilla" or mname == "Project Zomboid" then return nil end
    if _xpnb_isFramework(mid, mname) then
        -- Don’t misattribute to framework; treat as unknown
        return getText("UI_XP_NB_modOther")
    end
    if mname and mname ~= "" then return mname end
    if mid   and mid   ~= "" then return mid   end

    -- 4) Unknown → Other
    return getText("UI_XP_NB_modOther")
end

-- Expose the helper globally so other patches (FilterBar, etc.) can reuse the same logic
rawset(_G, "XP_NB_resolveModLabel", XP_NB_resolveModLabel)

-- Show/Build the line using the resolver above
function XP_NB_shouldShowModLine(recipe)
    if not (recipe and XP_NB_getShowRecipeMod and XP_NB_getShowRecipeMod()) then
        return false
    end
    return XP_NB_resolveModLabel(recipe) ~= nil
end

function XP_NB_makeModLine(recipe)
    local label = recipe and XP_NB_resolveModLabel(recipe) or nil
    if not label then return nil end
    return string.format("%s %s", getText("UI_XP_NB_modPrefix"), label)
end
-- ---------------------------------------------------------------------------




local function XP_NB_tr_or_raw(s)
    -- Returns translated text if 's' looks like a translation key, or the raw string otherwise.
    if type(s) ~= "string" then
        return tostring(s)
    end
    if s:find("^UI_") then
        -- Protect getText with pcall in case of unavailable key in some contexts.
        local ok, t = pcall(getText, s)
        if ok and t and t ~= "" then
            return t
        end
    end
    return s
end

-- Returns: lineHeight, lineGap, scaleZ
-- NOTE: Keep this local and above callers to avoid "Object tried to call nil".
local function XP_NB_lineMetrics()
    -- Get the base height for small UI font
    local h = getTextManager():getFontHeight(UIFont.Small)
    -- Small vertical gap between lines (15% of height, rounded)
    local gap = math.floor(h * 0.15 + 0.5)
    -- z-scale: leave as 1.0 unless you actually scale text elsewhere
    local z = 1.0
    return h, gap, z
end

---------------------------------------------------------------------
-- VARIABLE-HEIGHT helpers (count lines & estimate per-box height)
---------------------------------------------------------------------

-- How many XP lines would we draw for this recipe?
-- Prefer the same source the draw code uses.
local function XP_NB_countXPAwards(recipe)
    if not recipe then return 0 end
    if recipe.getXPAwardCount then
        return recipe:getXPAwardCount()
    end
    -- Fallback conservative
    return 0
end

-- Compute extra lines (beyond the 2 that already "fit" in the base box):
-- totalToDraw = Mod? (1) + XP lines; capped at 5; extra = max(0, totalToDraw - 2)
local function XP_NB_countExtraLinesForRecipe(recipe)
    local xpLines = XP_NB_countXPAwards(recipe)
    local hasMod  = XP_NB_shouldShowModLine(recipe) and 1 or 0
    local total   = xpLines + hasMod
    if total > 5 then
        -- Mod has priority: keep Mod, then up to 4 XP lines
        total = 5
    end
    local extra = total - 2
    return (extra > 0) and extra or 0
end

-- Returns desired pixel height for a given recipe box, or nil to skip.
function XP_NB_desiredHeightFor(list, box)
    -- Safety: only operate on tables
    if type(box) ~= "table" then return nil end

    -- Cache base height once (what NB originally uses for this row)
    local baseH = rawget(box, "XP_NB_baseH")
    if type(baseH) ~= "number" then
        -- Prefer the box current height; fallback to list.itemHeight; final fallback 48
        baseH = (type(box.height) == "number" and box.height)
             or (type(list) == "table" and type(list.itemHeight) == "number" and list.itemHeight)
             or 48
        box.XP_NB_baseH = baseH
    end

    -- How many extra lines (beyond the default 2) were actually drawn last frame?
    local extra = rawget(box, "XP_NB_knownExtraLines")
    if type(extra) ~= "number" then extra = 0 end
    if extra <= 0 then return baseH end

    -- Line height with NB/XP_NB scaling
    local lineH = select(1, XP_NB_lineMetrics()) -- returns (lineH,gap,z); we need lineH
    if type(lineH) ~= "number" then lineH = getTextManager():getFontHeight(UIFont.Small) end

    return baseH + (extra * lineH)
end

---------------------------------------------------------------------
-- VARIABLE-HEIGHT PATCH for NIVirtualScrollView (single, safe shim)
---------------------------------------------------------------------
-- Install a safe variable-height shim on a NI/NB virtual list.
function XP_NB_installVHOnList(list)
    if type(list) ~= "table" or list.XP_NB_VH_Patched then return end

    -- Helper to fetch the row container regardless of NB/NI flavor
    local function getRows(self)
        return self.items or self.data or self.entries or self.boxes or self.scrollItems
    end

    -- Helper to extract the actual box UIElement from a row record
    local function getBoxFromRow(rec)
        if type(rec) ~= "table" then return nil end
        return rec.item or rec.box or rec.element or rec.object or rec.ui or rec
    end

    local old_prerender = list.prerender
    list.prerender = function(self)
        local rows = getRows(self)
        if type(rows) == "table" then
            local n = #rows
            for i = 1, n do
                local rec = rows[i]
                local box = getBoxFromRow(rec)
                if type(box) == "table" then
                    local wantH = XP_NB_desiredHeightFor(self, box)
                    if type(wantH) == "number" and wantH > 0 then
                        -- NB/NI store height in different places; try them all safely
                        if type(rec) == "table" and type(rec.height) == "number" then
                            rec.height = wantH
                        end
                        if type(box.setHeight) == "function" then
                            box:setHeight(wantH)
                        else
                            box.height = wantH
                        end
                    end
                end
            end
        end
        if old_prerender then old_prerender(self) end
    end

    list.XP_NB_VH_Patched = true
end

---------------------------------------------------------------------------
-- VARIABLE-HEIGHT PATCH (safe shim) for NIVirtualScrollView
-- Goal: let each row have its own height so boxes don't overlap.
---------------------------------------------------------------------------

local function XP_NB_countXPRequirements(recipe)
    -- Count how many XP lines *exist* (independent of width/truncation).
    -- We reuse your XP_NB_makeXPLine(index) until it returns nil.
    local n, i = 0, 1
    while i <= 32 do
        local xpText = XP_NB_makeXPLine and XP_NB_makeXPLine(recipe, i, true) or nil
        if not xpText or xpText == "" then break end
        n = n + 1
        i = i + 1
    end
    return n
end

local function XP_NB_shouldShowModLineForRecipe(recipe)
    -- "vanilla" => no line; "neat" => Neat Building; else => Other.
    if not XP_NB_shouldShowModLine then return false end
    return XP_NB_shouldShowModLine(recipe) == true
end

local function XP_NB_predictRowHeight(baseH, recipe)
    -- Compute extra lines = min(XP lines + (mod?1:0), 5)
    local xpN   = XP_NB_countXPRequirements(recipe)
    local modN  = XP_NB_shouldShowModLineForRecipe(recipe) and 1 or 0
    local lines = xpN + modN
    if lines > 5 then lines = 5 end

    -- Use your current text scale + UIFont.Small height; gap ~2px like NB/NC.
    local scale  = (XP_NB_getTextScale and XP_NB_getTextScale()) or 1.0
    local lineH  = getTextManager():getFontHeight(UIFont.Small) * scale
    local gap    = 2
    local extraH = (lines > 0) and (lines * lineH + (lines-1) * gap) or 0

    -- Keep a small bottom padding similar to NB so right icons center nicely.
    return math.floor(baseH + extraH + 2)
end

-- VARIABLE-HEIGHT patch for NIVirtualScrollView (single, safe shim)
if not rawget(_G, "XP_NB_VH_SHIM") then
    XP_NB_VH_SHIM = true

    local _NV = NIVirtualScrollView
    if _NV then
        -- Keep originals
        local _orig_setDataSource   = _NV.setDataSource
        local _orig_updateMetrics   = _NV.updateScrollMetrics
        local _orig_calcRange       = _NV.calculateVisibleRange
        local _orig_refreshItems    = _NV.refreshItems
        local _orig_setSize         = _NV.setSize

        -- Rebuild per-index heights when data/width changes
		local function rebuildHeights(self)
			-- Guard clauses
			if not self or type(self.dataSource) ~= "table" then
				self.XP_NB_perIndexHeight = nil
				self._xpnb_dirty = false
				return
			end

			local baseH = tonumber(self.itemHeight) or 48
			local ds    = self.dataSource
			local N     = #ds

			-- Preserve existing per-index heights; allocate if missing
			local perH = self.XP_NB_perIndexHeight
			if type(perH) ~= "table" or #perH ~= N then
				perH = {}
				for i = 1, N do perH[i] = baseH end
			else
				-- Normalize any nil/invalid entries to baseH, but don't shrink/override valid ones
				for i = 1, N do
					local h = tonumber(perH[i])
					if not h or h <= 0 then perH[i] = baseH end
				end
			end

			-- (Optional) Predict height for new, unmeasured indices
			-- for i = 1, N do
			--     if perH[i] == baseH then
			--         local row    = ds[i]
			--         local recipe = row and (row.recipe or row.data or row.entity or row)
			--         local pred   = XP_NB_predictRowHeight and XP_NB_predictRowHeight(baseH, recipe) or baseH
			--         perH[i] = math.max(perH[i], pred)
			--     end
			-- end

			self.XP_NB_perIndexHeight = perH
			self._xpnb_dirty = false
		end

        -- Mark dirty on data change
		function _NV:setDataSource(ds)
			local ret = _orig_setDataSource(self, ds)
			-- Mark dirty and fully recompute so Y and widths are right *this frame*
			self._xpnb_dirty = true
			self:updateScrollMetrics()   -- recompute totalHeight/maxScrollOffset
			self:updateScrollBar()       -- toggle vscroll visibility now
			self:refreshItems()          -- position/resize pooled items with final widths
			self._xpnb_pendingFirstLayout = true -- request a silent prelayout pass (avoid visible jump)
			return ret
		end

        -- Mark dirty on resize (width changes may alter wrapping/truncation)
		function _NV:setSize(w, h)
			_orig_setSize(self, w, h)
			self._xpnb_dirty = true
			self:updateScrollMetrics()
			self:updateScrollBar()
			self:refreshItems()
		end

		-- Total content metrics using variable heights (padding is the inter-item spacing)
		function _NV:updateScrollMetrics()
			if self._xpnb_dirty then rebuildHeights(self) end
			local perH = self.XP_NB_perIndexHeight
			if perH then
				local pad   = tonumber(self.padding) or 0
				local viewH = tonumber(self.height)  or 0
				local total = pad
				for i = 1, #perH do
					total = total + (tonumber(perH[i]) or 0) + pad
				end
				-- IMPORTANT: set totalHeight for scrollbar math that calls getScrollHeight()
				self.totalHeight    = math.max(total, viewH)
				self.maxScrollOffset = math.max(0, total - viewH)

				-- Clamp scroll
				local so = tonumber(self.scrollOffset) or 0
				if so > self.maxScrollOffset then self.scrollOffset = self.maxScrollOffset end
				if self.scrollOffset < 0 then self.scrollOffset = 0 end
				return
			end
			return _orig_updateMetrics(self)
		end

        -- Visible window based on cumulative variable heights
        function _NV:calculateVisibleRange()
            if self._xpnb_dirty then rebuildHeights(self) end
            local perH = self.XP_NB_perIndexHeight
            if not perH then
                return _orig_calcRange(self)
            end

            local ds     = self.dataSource or {}
            local viewH  = tonumber(self.height)      or 0
            local pad    = tonumber(self.padding)     or 0
            local top    = tonumber(self.scrollOffset) or 0
            local bottom = top + viewH

            if #ds == 0 or viewH <= 0 then return 0, -1 end

            -- Find first visible index
            local y = pad
            local first = 1
            for i = 1, #ds do
                local nextY = y + (tonumber(perH[i]) or 0) + pad
                if nextY >= top then
                    first = i
                    break
                end
                y = nextY
            end

            -- Extend until bottom is exceeded
            local last = first
            while (y < bottom) and (last <= #ds) do
                y = y + (tonumber(perH[last]) or 0) + pad
                last = last + 1
            end

            last  = math.min(#ds, last)
            first = math.max(1, first)
            return first, last
        end

        -- Position and size pooled items using variable heights
		function _NV:refreshItems()
			if self._xpnb_dirty then rebuildHeights(self) end
			local perH = self.XP_NB_perIndexHeight
			if not perH then
				return _orig_refreshItems(self)
			end

			-- Ensure scrollbar state is correct *before* computing item widths
			self:updateScrollMetrics()
			self:updateScrollBar()

			local ds = self.dataSource or {}
			-- Compute visible window
			local startIndex, endIndex = self:calculateVisibleRange()

			-- Hide all pooled items upfront when window changes
			for _, item in ipairs(self.itemPool) do
				item:setVisible(false)
			end

			if startIndex > endIndex then
				-- Still keep metrics/scrollbar in sync
				self:updateScrollMetrics()
				self:updateScrollBar()
				return
			end

			local pad      = tonumber(self.padding)      or 0
			local width    = tonumber(self.width)        or 0
			local scroll   = tonumber(self.scrollOffset) or 0
			local vscrollW = (self.vscroll and self.vscroll:isVisible()) and (self.vscroll:getWidth() or 0) or 0
			local itemW    = math.max(0, width - vscrollW - pad * 2)

            -- Absolute y at the top of startIndex
            local yAbs = pad
            for i = 1, startIndex - 1 do
                yAbs = yAbs + (tonumber(perH[i]) or 0) + pad
            end

            -- Render/update pool slice
            local poolIdx = 1
            for idx = startIndex, endIndex do
                local item = self.itemPool[poolIdx]
                if not item then break end

                local data = ds[idx]
                local h    = tonumber(perH[idx]) or (tonumber(self.itemHeight) or 48)

                -- Rebind content and place the box
                self.onUpdateItem(item, data)
                item:setVisible(true)
                item:setX(pad)
                item:setY(yAbs - scroll)
                item:setWidth(itemW)
                item:setHeight(h)

                yAbs   = yAbs + h + pad
                poolIdx = poolIdx + 1
            end

            -- Recompute content and scrollbar each pass to avoid drift
            self:updateScrollMetrics()
            self:updateScrollBar()
        end
		
		-- Keep original list prerender to call after our prelayout
		local _orig_prerender_list = _NV.prerender

		function _NV:prerender()
			-- Ensure the per-index height table exists or is normalized
			if self._xpnb_dirty then rebuildHeights(self) end

			-- One-time silent prelayout after data source changes:
			-- measure visible items, commit their final heights, and position them
			-- BEFORE any drawing happens (prevents visible "jumping").
			if self._xpnb_pendingFirstLayout and not self._xpnb_inRefresh then
				self._xpnb_inRefresh = true

				-- 1) Bind scroll metrics and scrollbar state with current (base) heights
				self:updateScrollMetrics()
				self:updateScrollBar()
				self:refreshItems()

				-- 2) Measure desired heights of the currently visible pooled items
				--    without drawing them yet, and write back to per-index table.
				local startIndex, endIndex = self:calculateVisibleRange()
				local poolIdx = 1
				self.XP_NB_perIndexHeight = self.XP_NB_perIndexHeight or {}

				for idx = startIndex, endIndex do
					local item = self.itemPool[poolIdx]
					if not item then break end

					-- Measure height using the same logic as the box render (no draw).
					local wantH = XP_NB_measureDesiredHeightForBox
								  and XP_NB_measureDesiredHeightForBox(item)
								  or nil
					if wantH and wantH > 0 then
						self.XP_NB_perIndexHeight[idx] = wantH
						item:setHeight(wantH)
					end
					poolIdx = poolIdx + 1
				end

				-- 3) Recompute metrics with final heights and reposition items again
				self:updateScrollMetrics()
				self:updateScrollBar()
				self:refreshItems()

				self._xpnb_pendingFirstLayout = false
				self._xpnb_inRefresh = false
			end

			-- Now perform the original list prerender, which will draw children.
			if _orig_prerender_list then _orig_prerender_list(self) end

			-- Late reflow: if any child box changed its height during its prerender,
			-- do one more pass to keep coordinates in sync within the same frame.
			if self._xpnb_reflowQueued and not self._xpnb_inRefresh then
				self._xpnb_reflowQueued = false
				self._xpnb_inRefresh = true
				self:updateScrollMetrics()
				self:updateScrollBar()
				self:refreshItems()
				self._xpnb_inRefresh = false
			end
		end
    end
end

-- Helper you can call when options that affect line count/scale change
-- Example usage: XP_NB_markListHeightsDirtyInPanel(self.parentPanel)
function XP_NB_markListHeightsDirtyInPanel(panel)
    local list = panel and panel.scrollView
    if list then list._xpnb_dirty = true end
end

---------------------------------------------------------------------


-- This handles rounding correctly (e.g., 1.239 -> 1.24)
local function formatNumber(value)
	local rounded = math.floor(value * 100 + 0.5) / 100
    return tostring(rounded)
end

-- Crafty trait applies only to perks whose parent is Crafting (B42.12+).
-- We keep a fallback list of perk *types* for builds/mod environments where perk:getParent() is unavailable.
local XP_NB_CRAFTING_PERK_TYPES = {
    Woodwork = true, Carving = true, Cooking = true, Electricity = true, Glassmaking = true,
    FlintKnapping = true, Masonry = true, Blacksmith = true, Mechanics = true, Pottery = true,
    Tailoring = true, MetalWelding = true,
}

-- Compatibility helper for B42.13+ trait API (and fallback to legacy API)
local function hasTraitCompat(playerObj, traitConst, legacyTraitName)
    -- Prefer the new API: playerObj:hasTrait(CharacterTrait.SOMETHING)
    -- We explicitly check "type == function" to avoid calling non-callable fields.
    if playerObj and type(playerObj.hasTrait) == "function" and traitConst ~= nil then
        return playerObj:hasTrait(traitConst)
    end

    -- Fallback for older builds/mod environments: playerObj:HasTrait("Something")
    if playerObj and type(playerObj.HasTrait) == "function" and legacyTraitName ~= nil then
        return playerObj:HasTrait(legacyTraitName)
    end

    -- Default: trait not present / API not available
    return false
end

-- Parallel calculation based on ProjectZomboid\zombie\characters\IsoGameCharacter$XP.class AddXP
local function getXPMultiplier(player, perk)
    if not player or not perk then
        return 1
    end

    local xp = player:getXp()
    local perkLevel = player:getPerkLevel(perk)
	local xpMultiplier = {}
	
    -- 1. Multiplier per initial skill level (or boosts from earned traits, like using Dynamic Traits and Expanded Moodles)
	-- For strength and fitness skills xpMultiplier.skillBoost = 1.0, but they are't expected to appear in Building Menu
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
		print("[NB - Addon XP Display] CAUTION: Check out xpMultiplier.skillBoost: startingLevel is not {0, 1, 2, 3} or higher")
		xpMultiplier.skillBoost = 0.25 -- Default multiplier for level 0
	end
    
    -- 2. Skill Book Multiplier
	xpMultiplier.bookMultiplier = math.max(xp:getMultiplier(perk) or 1, 1)
	
	-- 3. Trait multiplier
	-- 3a. Fast/Slow Learner Traits 
	xpMultiplier.learnerMultiplier = 1

	-- Use registry-based traits on B42.13+, fallback to legacy string traits otherwise
	local fastLearnerTrait = CharacterTrait and CharacterTrait.FAST_LEARNER or nil
	local slowLearnerTrait = CharacterTrait and CharacterTrait.SLOW_LEARNER or nil

	if hasTraitCompat(player, fastLearnerTrait, "FastLearner") then
		xpMultiplier.learnerMultiplier = 1.3
	elseif hasTraitCompat(player, slowLearnerTrait, "SlowLearner") then
		xpMultiplier.learnerMultiplier = 0.7
	end

	-- 3b. Crafty Trait Multiplier (Build 42.12+): +30% XP, but only for perks in the Crafting category
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
		return (t and XP_NB_CRAFTING_PERK_TYPES[t]) or false
	end

	if hasCrafty and isCraftingPerk(perk) then
		xpMultiplier.craftyMultiplier = 1.3
	end

	-- 4. Global World (Sandbox) Multiplier
	if SandboxVars.MultiplierConfig and SandboxVars.MultiplierConfig.GlobalToggle == true then
		xpMultiplier.sandboxMultiplier = SandboxVars.MultiplierConfig.Global or 1
	else
		local sandboxOption = getSandboxOptions() and getSandboxOptions():getOptionByName("MultiplierConfig." .. tostring(perk:getType()))

		xpMultiplier.sandboxMultiplier = (sandboxOption and sandboxOption:getValue()) or 1
	end

	xpMultiplier.total = xpMultiplier.skillBoost * xpMultiplier.bookMultiplier * xpMultiplier.learnerMultiplier * xpMultiplier.craftyMultiplier * xpMultiplier.sandboxMultiplier
    return xpMultiplier
end

-- The following 'getFieldValue' function is a modified version originally
-- found in the 'Starlit Library' mod (Starlit/utils/Reflection.lua).
-- It is included here to remove the direct dependency on Starlit Library.
-- All credits for the original code go to the author of Starlit Library: albion.
local function getFieldValue(object, fieldName)
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

-- Override NB_BuildingRecipeList_Box:updateSkillTexts
-- Modified function to display XP awards in the UI.
-- The original function has been replaced with this version to add XP information.
-- This adaptacion was found in the Neat Crafting mod code.
-- All credits for the original code go to the author of Neat Neat Crafting mod: Rocco.
function NB_BuildingRecipeList_Box:updateSkillTexts()
	self.skillTexts = {}
	self.unmatchedXPTexts = {}
	
	-- Addon XP Display added for quicker return: self.recipe:getXPAwardCount() == 0
	if not self.recipe or (self.recipe:getRequiredSkillCount() == 0 and self.recipe:getXPAwardCount() == 0) then return end
	
	local player = getPlayer()
	local maxTextWidth = self.width - self.iconAreaSize - self.padding * 2 - (self.statusIconSize + self.padding)
    
	-- Scale-aware fit width: truncate using unscaled width so drawing at 'z' fits
	local z = (XP_NB_getTextScale and XP_NB_getTextScale()) or 1.0
	if z <= 0 then z = 1.0 end
	local fitW = math.max(0, math.floor(maxTextWidth / z + 0.5))

	-- Get experience rewards
	local xpAwards = {}

	if self.recipe:getXPAwardCount() > 0 then
		for i = 0, self.recipe:getXPAwardCount() - 1 do
			local xpAward = self.recipe:getXPAward(i)
				if xpAward then
				local amount = getFieldValue(xpAward, "amount") or 0
				local perkObj = getFieldValue(xpAward, "perk")
				if perkObj then
					perkName = perkObj:getName()
					xpAwards[perkName] = {amount = amount, perkObj = perkObj} -- Modified to store both amount and object
				end
			end
		end
	end

	-- Process skill requirements
	if self.recipe:getRequiredSkillCount() > 0 then
		for i = 0, self.recipe:getRequiredSkillCount() - 1 do
			local requiredSkill = self.recipe:getRequiredSkill(i)
			local skillPerk = requiredSkill:getPerk()
			local skillName = skillPerk:getName()
			local level = requiredSkill:getLevel()

            local xpAwardData = xpAwards[skillName]
            local skillText

            -- Build the requirement line as: "LV<level> <skillName> (<xp details>)"
            local basePrefix = "LV" .. level .. " " .. skillName

            -- Addon XP Display: Handle XP Display
            if XP_NB_getxpShow() and xpAwardData then
                local xpAmount = xpAwardData.amount
                local xpFormat = XP_NB_getxpFormat()

                if xpFormat == "1" then -- Basic XP
                    skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " XP)"
                else
                    local xpMultiplier = getXPMultiplier(player, xpAwardData.perkObj)
                    local xpAmountMultiplied = math.floor(xpAmount * xpMultiplier.total * 100 + 0.5) / 100

                    if xpFormat == "2" then -- Final XP
                        skillText = basePrefix .. " (+" .. xpAmountMultiplied .. " XP)"
                    elseif xpFormat == "3" then -- Multiplier
                        skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " * " .. formatNumber(xpMultiplier.total) .. " = " .. xpAmountMultiplied .. " XP)"
                    elseif xpFormat == "4" then -- Breakdown
                        xpMultiplier.string = formatNumber(xpMultiplier.skillBoost) .. "*" .. formatNumber(xpMultiplier.bookMultiplier) .. "*" .. formatNumber(xpMultiplier.learnerMultiplier*xpMultiplier.craftyMultiplier) .. "*" .. formatNumber(xpMultiplier.sandboxMultiplier)
                        skillText = basePrefix .. " (+" .. formatNumber(xpAmount) .. " * " .. xpMultiplier.string .. " = " .. xpAmountMultiplied .. " XP)"
                    else
                        -- Fallback if format is unexpected
                        skillText = basePrefix
                    end
                end
            else
                -- No XP shown (or no XP award for this perk)
                skillText = basePrefix
            end
			
			skillText = NeatTool.truncateText(skillText, fitW, UIFont.Small, "...")
			local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)

			table.insert(self.skillTexts, {
				text  = skillText,
				isMet = isMet,
				hasXP = (xpAwardData ~= nil)  -- << flag: this requirement line shows XP
			})

			-- Addon XP Display: Remove XP from xpAwards if handled here
			if xpAwardData then
				xpAwards[skillName] = nil
			end
        end
    end

    -- Process remaining experience rewards
    for perkName, xpAwardData in pairs(xpAwards) do
        local amount = xpAwardData.amount
        local perkObj = xpAwardData.perkObj
        
        if XP_NB_getxpShow() then
			local xpText
            local xpFormat = XP_NB_getxpFormat()
            
            if xpFormat == "1" then
                xpText = "+ " .. formatNumber(amount) .. " XP " .. perkName
			else
				local xpMultiplier = getXPMultiplier(player, perkObj)
				local xpAmountMultiplied = math.floor(amount * xpMultiplier.total * 100 + 0.5)/100
				if xpFormat == "2" then
					xpText = "+ " .. xpAmountMultiplied .. " XP " .. perkName
				elseif xpFormat == "3" then
					xpText = "+ " .. formatNumber(amount) .. " * " .. formatNumber(xpMultiplier.total) .. " = " .. xpAmountMultiplied .. " XP " .. perkName
				elseif xpFormat == "4" then
					xpMultiplier.string = formatNumber(xpMultiplier.skillBoost) .. "*" .. formatNumber(xpMultiplier.bookMultiplier) .. "*" .. formatNumber(xpMultiplier.learnerMultiplier*xpMultiplier.craftyMultiplier) .. "*" .. formatNumber(xpMultiplier.sandboxMultiplier)
					xpText = "+ " .. formatNumber(amount) .. " * " .. xpMultiplier.string .. " = " .. xpAmountMultiplied .. " XP " .. perkName
				end
			end
			xpText = NeatTool.truncateText(xpText, fitW, UIFont.Small, "...")
			table.insert(self.unmatchedXPTexts, {
				text = xpText,
				amount = amount
			})
        end
    end
	
	-- Mark the list as dirty so variable heights are recomputed next frame
	if self.parentPanel and self.parentPanel.scrollView then
		self.parentPanel.scrollView._xpnb_dirty = true
	end	
end

---------------------------------------------------------------------------
-- Render recipe box (left icons fixed, dynamic text, right status icons)
---------------------------------------------------------------------------
function NB_BuildingRecipeList_Box:renderRecipeInfo()
    local recipe   = self.recipe
    if not recipe then return end

    -- 1) Ensure VH shim is installed on the actual list once
    if not self._xpnb_vh then
        local panel = self.parentPanel or (self.parent and self.parent.parentPanel) or nil
        local list  = panel and panel.scrollView or nil
        if list and list.setData then
            -- touching setData will not happen here; just mark dirty so shim recomputes heights
            list._xpnb_dirty = true
            self._xpnb_vh = true
        end
    end

	-- 2) Geometry: fixed left strip + comfortable left padding for text
	local padding      = self.padding
	local leftStripW   = self.iconSize or 34       -- fixed: do NOT scale with box height
	local leftPadRight = 6
	local rightStripW  = 60                        -- status icons column (unchanged)
	local textX        = self.iconAreaSize + self.padding -- [MODIFIED 1.6.7] was: padding + leftStripW + leftPadRight
	
	-- local textW        = self.width - textX - rightStripW - padding
	local textW = self.width - textX - (self.statusIconSize + self.padding * 2)
	if textW < 10 then textW = 10 end

	-- Text scale and metrics for small lines (XP/Mod)
	local scale = (XP_NB_getTextScale and XP_NB_getTextScale()) or 1.0
	if scale <= 0 then scale = 1.0 end

	-- Use ceil to match the real advance of drawTextZoomed vertically
	local lineH = math.ceil(getTextManager():getFontHeight(UIFont.Small) * scale)
	local gap   = 2
	local fitWpx = math.max(0, math.floor(textW / scale + 0.5))

    -- 3) Alpha: highlight buildable
    local canBuild = self.canBuild == true
    local alpha    = canBuild and 1.0 or 0.5

    -- 4) Title (NB draws name at UIFont.Small; keep NB behaviour)
	local displayName = NeatTool.truncateText(recipe:getTranslationName(), textW, UIFont.Small, "...")
    self:drawText(displayName, textX, padding, 1,1,1, alpha, UIFont.Small)
    local y = padding + getTextManager():getFontHeight(UIFont.Small)
	
	-- 5) XP + Mod lines (uniform spacing: one gap between consecutive lines)
	local lines = {}

	-- Build (and cache) the flat XP rows
	self._xpnb_flat = nil
	if XP_NB_getxpShow and XP_NB_getxpShow() then
		local flat = {}
		if self.skillTexts then
			for _, row in ipairs(self.skillTexts) do
				if row.hasXP and row.text and row.text ~= "" then
					table.insert(flat, row)
				end
			end
		end
		if self.unmatchedXPTexts then
			for _, row in ipairs(self.unmatchedXPTexts) do
				table.insert(flat, { text = row.text, isMet = true })
			end
		end
		-- Cap at 4 XP lines
		for i = 1, math.min(4, #flat) do
			table.insert(lines, flat[i])
		end
	end

	-- Optionally append Mod line as one more row (max total 5)
	if XP_NB_shouldShowModLine(recipe) and #lines < 5 then
		local modText = XP_NB_makeModLine(recipe)
		if modText and modText ~= "" then
			table.insert(lines, { text = modText, isMod = true })
		end
	end

	-- Draw rows with identical vertical spacing
	for i = 1, #lines do
		local row = lines[i]
		local rr, gg, bb
		if row.isMod then
			rr, gg, bb = 0.392, 0.584, 0.929     -- Mod line color
		else
			rr, gg, bb = (row.isMet and 0.2 or 0.8), (row.isMet and 0.8 or 0.1), (row.isMet and 0.2 or 0.1)
		end
		local shown = NeatTool.truncateText(row.text, fitWpx, UIFont.Small, row.isMod and "…" or "...")
		self:drawTextZoomed(shown, textX, y, scale, rr, gg, bb, alpha, UIFont.Small)

		-- advance only BETWEEN lines (prevents double-gap before Mod)
		if i < #lines then
			y = y + lineH + gap
		end
	end

    -----------------------------------------------------------------------
    -- 6) LEFT STRIP (fixed-size recipe icon + optional favourite star)
    -- Draw the recipe icon preserving aspect ratio (prevents squished thumbnails)
    -----------------------------------------------------------------------
    local iconCenterY = math.floor((self.height or 0) * 0.5)

    -- Use numeric icon size if available; fallback keeps UI stable
    local iconBoxSize = (type(self.iconSize) == "number" and self.iconSize) or (tonumber(self.iconSize) or 34)
    local iconDrawH   = iconBoxSize
    local iconDrawW   = iconBoxSize
    local iconY       = iconCenterY - math.floor(iconDrawH / 2)

    -- Center the icon box within the left strip width (iconAreaSize can be nil depending on load order)
    local stripW = (type(self.iconAreaSize) == "number" and self.iconAreaSize) or (tonumber(self.iconAreaSize) or iconBoxSize)
    local iconX  = math.floor((stripW - iconDrawW) / 2) -- was based on square icon assumptions

	local recipeIcon  = self.recipe:getIconTexture()
    if recipeIcon then
        -- Preserve the original texture aspect ratio inside the square box
        local texW = recipeIcon.getWidth and recipeIcon:getWidth() or nil
        local texH = recipeIcon.getHeight and recipeIcon:getHeight() or nil

        if texW and texH and texW > 0 and texH > 0 then
            local s = math.min(iconDrawW / texW, iconDrawH / texH)
            local drawW = math.floor(texW * s + 0.5)
            local drawH = math.floor(texH * s + 0.5)
            local drawX = iconX + math.floor((iconDrawW - drawW) / 2)
            local drawY = iconY + math.floor((iconDrawH - drawH) / 2)
            self:drawTextureScaled(recipeIcon, drawX, drawY, drawW, drawH, alpha, 1, 1, 1)
        else
            -- Fallback: draw as a square if texture size is unavailable
            self:drawTextureScaled(recipeIcon, iconX, iconY, iconDrawW, iconDrawH, alpha, 1, 1, 1)
        end
    end

    -- Draw layer icon for multi-level recipes
    if self.recipe and BuildingRecipeGroups.hasMultipleLevels(self.recipe:getName()) then
        local layerIconSize = 20
        local layerIconX = self.padding
        local layerIconY = self.padding

        self:drawTextureScaledAspect(self.layerIcon, layerIconX, layerIconY, layerIconSize, layerIconSize, 1, 0.8, 0.8, 0.8)
    end

    -- favourite star ONLY if flagged in player modData (NB logic)
    if BuildLogic and self.player then
        local favString = BuildLogic.getFavouriteModDataString(self.recipe)
        if favString and self.player:getModData()[favString] and self.favouriteIcon then
            local s = 16
            local fx = iconX + leftStripW - s
            local fy = padding
            self:drawTextureScaled(self.favouriteIcon, fx, fy, s, s, 1, 0.8, 0.2, 0.2)
        end
    end
    -----------------------------------------------------------------------
    -- 7) RIGHT STRIP (status icons) — NB already calculates which ones and draws them.
    -----------------------------------------------------------------------
    -- NB’s original code coloca los iconos a la derecha; llama a sus helpers:
    local rightMargin = self.padding
    local iconsToShow = {}

    if not self.recipe:canBeDoneInDark() then
        local alpha = self.canBuild and 1.0 or 0.5
        table.insert(iconsToShow, {texture = self.lightIconTexture, alpha = alpha})
    end

    if self.recipe:needToBeLearn() then
        local alpha = self.canBuild and 1.0 or 0.5
        table.insert(iconsToShow, {texture = self.skillIconTexture, alpha = alpha})
    end

    local iconX = self.width - rightMargin - self.statusIconSize
    local availableHeight = self.height - self.padding * 2
    local totalIconsHeight = math.min(#iconsToShow, 3) * self.statusIconSize
    local iconSpacing = math.max(0, (availableHeight - totalIconsHeight) / math.max(1, math.min(#iconsToShow, 3) - 1))

    for i = 1, math.min(#iconsToShow, 3) do
        local icon = iconsToShow[i]
        local iconY = self.padding + (i - 1) * (self.statusIconSize + iconSpacing)
        self:drawTextureScaled(icon.texture, iconX, iconY, self.statusIconSize, self.statusIconSize, icon.alpha, 1, 1, 1)
    end
end

-- Measure desired height without drawing (used in prerender)
local function XP_NB_measureDesiredHeightForBox(self)
    local panel = self.parentPanel
    local list  = panel and panel.scrollView
    local baseH = self.XP_NB_baseH or (list and list.itemHeight) or 48
    local padding = self.padding or 4

    -- Text area geometry (same as renderRecipeInfo)
    local textX = (self.iconAreaSize or 34) + padding
    local textW = self.width - textX - ((self.statusIconSize or 60) + padding * 2)
    if textW < 10 then textW = 10 end

    -- Line metrics (match drawTextZoomed advance)
    local scale = (XP_NB_getTextScale and XP_NB_getTextScale()) or 1.0
    if scale <= 0 then scale = 1.0 end
    local lineH = math.ceil(getTextManager():getFontHeight(UIFont.Small) * scale)
    local gap   = 2

    -- Make sure skill/XP lists are up-to-date
    if self.updateSkillTexts then self:updateSkillTexts() end

    -- Build flat XP lines like renderRecipeInfo (but no drawing)
    local flat = {}
    if XP_NB_getxpShow and XP_NB_getxpShow() then
        if self.skillTexts then
            for _, row in ipairs(self.skillTexts) do
                if row.hasXP and row.text and row.text ~= "" then
                    table.insert(flat, row)
                end
            end
        end
        if self.unmatchedXPTexts then
            for _, row in ipairs(self.unmatchedXPTexts) do
                table.insert(flat, { text = row.text, isMet = true })
            end
        end
    end

    local xpLines = math.min(4, #flat)
    local lines   = xpLines
    if XP_NB_shouldShowModLine and XP_NB_shouldShowModLine(self.recipe) and lines < 5 then
        lines = lines + 1
    end

    local titleH = getTextManager():getFontHeight(UIFont.Small)
    local contentBottom = padding + titleH + (lines > 0 and gap or 0)
                           + (lines > 0 and (lines * lineH + (lines - 1) * gap) or 0)
    local desiredH = math.max(baseH, contentBottom + padding)
    return desiredH
end

-- Fix left strips to a constant width without editing NB files
do
    if NB_BuildingRecipeList_Box and not NB_BuildingRecipeList_Box._XP_NB_FixedStrip then
        NB_BuildingRecipeList_Box._XP_NB_FixedStrip = true

        -- Cache original prerender so we can call it later
        local _orig_prerender = NB_BuildingRecipeList_Box.prerender

        -- Textures used by NB (we only suppress these two in the original call)
        local TEX_SLOTICON = "media/ui/Neat_Building/Button/SlotBG_IconSide.png"
        local TEX_SLOTLEFT = "media/ui/Neat_Building/Button/SlotBG_LEFT.png"

        function NB_BuildingRecipeList_Box:prerender()
			-- 1) Ensure dynamic height is applied BEFORE NB draws any background
			local desiredH = XP_NB_measureDesiredHeightForBox(self)
			if desiredH and desiredH > 0 and desiredH ~= self.height then
				self:setHeight(desiredH)

				-- keep list bookkeeping in sync (no rebuild here)
				local list = self.parentPanel and self.parentPanel.scrollView
				if list and list.dataSource then
					for i = 1, #list.dataSource do
						if list.dataSource[i] == self.recipe then
							list.XP_NB_perIndexHeight = list.XP_NB_perIndexHeight or {}
							list.XP_NB_perIndexHeight[i] = desiredH
							-- Queue a second pass so Y positions are recomputed this frame
							list._xpnb_reflowQueued = true
							break
						end
					end
				end
			end
			
            -- 2) Compute colors like NB does
            local bgAlpha = self.canBuild and 1.0 or 0.5
            local r, g, b = 0.15, 0.15, 0.15
            if self:isMouseOver() then r, g, b = 0.2, 0.2, 0.2 end

            -- 3) Draw our fixed-width strips
            --    NOTE: iconAreaSize is set once at creation (base height). That’s our fixed strip width.
            local wIconStrip = self.iconAreaSize or self.iconSize or 34

            local getTex = NinePatchTexture.getSharedTexture
            local sloticon = getTex(TEX_SLOTICON)
            if sloticon then
                -- sloticon: fixed width, full box height
                sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), wIconStrip, self.height, r, g, b, bgAlpha)
            end
            local slotleft = getTex(TEX_SLOTLEFT)
            if slotleft then
                -- slotleft: starts after fixed strip, fills remaining width
                slotleft:render(self:getAbsoluteX() + wIconStrip, self:getAbsoluteY(),
                                self.width - wIconStrip, self.height, r, g, b, bgAlpha)
            end

            -- 4) Call NB’s original prerender, but temporarily HIDE those two textures
            --    so the original code won’t redraw them with a variable width.
            local _orig_get = NinePatchTexture.getSharedTexture
            NinePatchTexture.getSharedTexture = function(name)
                if name == TEX_SLOTICON or name == TEX_SLOTLEFT then
                    return nil -- suppress just these two for the original call
                end
                return _orig_get(name)
            end

            local ok, err = pcall(_orig_prerender, self)

            -- Always restore
            NinePatchTexture.getSharedTexture = _orig_get
            if not ok then error(err) end
        end
    end
end
