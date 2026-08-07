----------------------------------------------------------------
-- XP_NC - Extra filter buttons for Neat Crafting FilterBar
-- Adds:
--   1) "XP only" filter (recipes that award XP)
--   2) "Mod only" filter (recipes that are not vanilla/base)
--
-- This addon must load AFTER Neat Crafting.
----------------------------------------------------------------

Events.OnGameBoot.Add(function()
    if rawget(_G, "XP_NC_DISABLE_XP_MOD_LINES") == true then return end
    if not NC_FilterBar or not NC_SquareButton then return end

    -- Avoid double patching
    if NC_FilterBar._XP_NC_ExtraFiltersPatched then return end
    NC_FilterBar._XP_NC_ExtraFiltersPatched = true

    ------------------------------------------------------------
    -- Small helpers
    ------------------------------------------------------------

    local function T(key, fallback)
        -- Use getTextOrNull if available, otherwise fallback
        if getTextOrNull then
            local s = getTextOrNull(key)
            if s and s ~= "" then return s end
        end
        return fallback
    end

    local function recipeAwardsXP(recipe)
        -- True if the recipe has any XP awards
        if not recipe or not recipe.getXPAwardCount then return false end
        local ok, n = pcall(recipe.getXPAwardCount, recipe)
        return ok and type(n) == "number" and n > 0
    end

    local function recipeIsVanillaLikely(recipe)
        -- Prefer the more robust function from XP_NC_RecipeList_Box.lua if it exists
        if NC_isLikelyVanillaRecipe then
            local ok, res = pcall(NC_isLikelyVanillaRecipe, recipe)
            if ok then return res == true end
        end

        -- Fallback heuristic (simple and safe):
        -- If provider metadata exists and is not vanilla -> treat as modded
        if not recipe then return true end

        local mid = nil
        local mname = nil

        if recipe.getModID then
            local ok, v = pcall(recipe.getModID, recipe)
            if ok then mid = v end
        end
        if recipe.getModName then
            local ok, v = pcall(recipe.getModName, recipe)
            if ok then mname = v end
        end

        if mname == "Project Zomboid" or mid == "pz-vanilla" then
            return true
        end
        if (mname and mname ~= "" and mname ~= "Project Zomboid")
            or (mid and mid ~= "" and mid ~= "pz-vanilla") then
            return false
        end

        local moduleName = (recipe.getModule and recipe:getModule() and recipe:getModule():getName()) or "Base"
        if moduleName ~= "Base" then
            return false
        end

        return true
    end

    ------------------------------------------------------------
    -- 1) Patch shouldIncludeRecipe to apply new filters
    ------------------------------------------------------------

    local _oldShouldInclude = NC_FilterBar.shouldIncludeRecipe
    function NC_FilterBar:shouldIncludeRecipe(recipe)
        -- Keep original NC filters first
        if _oldShouldInclude and not _oldShouldInclude(self, recipe) then
            return false
        end

        if recipe then
            -- XP-only filter
            if self.showOnlyXPAward and (not recipeAwardsXP(recipe)) then
                return false
            end

            -- Mod-only filter (exclude likely-vanilla)
            if self.showOnlyModRecipes and recipeIsVanillaLikely(recipe) then
                return false
            end
        end

        return true
    end

    ------------------------------------------------------------
    -- 2) Add click handlers
    ------------------------------------------------------------

    function NC_FilterBar:onXPAwardFilterButtonClick()
        self.showOnlyXPAward = not self.showOnlyXPAward
        if self.xpAwardFilterButton then
            self.xpAwardFilterButton:setActive(self.showOnlyXPAward)
        end
        if self.HandCraftPanel and self.HandCraftPanel.onFilterChanged then
            self.HandCraftPanel:onFilterChanged()
        end
    end

    function NC_FilterBar:onModOnlyFilterButtonClick()
        self.showOnlyModRecipes = not self.showOnlyModRecipes
        if self.modOnlyFilterButton then
            self.modOnlyFilterButton:setActive(self.showOnlyModRecipes)
        end
        if self.HandCraftPanel and self.HandCraftPanel.onFilterChanged then
            self.HandCraftPanel:onFilterChanged()
        end
    end

    ------------------------------------------------------------
    -- 3) Patch createChildren to insert the two new buttons
    ------------------------------------------------------------

    local _oldCreateChildren = NC_FilterBar.createChildren
    function NC_FilterBar:createChildren()
        if _oldCreateChildren then
            _oldCreateChildren(self)
        end

        -- Prevent duplicates if createChildren is called again
        if self._XP_NC_ExtraButtonsAdded then return end
        self._XP_NC_ExtraButtonsAdded = true

        -- Initialize new flags if missing
        if self.showOnlyXPAward == nil then self.showOnlyXPAward = false end
        if self.showOnlyModRecipes == nil then self.showOnlyModRecipes = false end

        -- Try the real NC folder name first (ICON), then fallback (Icon)
		local xpIcon  = getTexture("media/ui/Neat_Crafting/ICON/Icon_XPAward.png")
            or getTexture("media/ui/Neat_Crafting/Icon/Icon_XPAward.png")

        -- New icon added in XP_NC
		local modIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_ModOnly.png")
            or getTexture("media/ui/Neat_Crafting/Icon/Icon_ModOnly.png")

        -- Create XP button
        local xpBtn = NC_SquareButton:new(0, 0, 10, xpIcon, self, self.onXPAwardFilterButtonClick)
        xpBtn:initialise()
        xpBtn:setTooltip(T("IGUI_XP_NC_ShowOnlyXPAward", "Show only recipes that award XP"))
        xpBtn:setActive(self.showOnlyXPAward)
        self:addChild(xpBtn)
        self.xpAwardFilterButton = xpBtn

        -- Create Mod-only button
        local modBtn = NC_SquareButton:new(0, 0, 10, modIcon, self, self.onModOnlyFilterButtonClick)
        modBtn:initialise()
        modBtn:setTooltip(T("IGUI_XP_NC_ShowOnlyModRecipes", "Show only mod recipes"))
        modBtn:setActive(self.showOnlyModRecipes)
        self:addChild(modBtn)
        self.modOnlyFilterButton = modBtn

        -- Insert into the existing row of buttons.
        -- Default: append at the end (after Benefit filter, etc.)
        if self.buttons then
            table.insert(self.buttons, xpBtn)
            table.insert(self.buttons, modBtn)

            -- If you want a specific position, change inserts, e.g.:
            -- table.insert(self.buttons, 6, xpBtn)   -- after Benefit
            -- table.insert(self.buttons, 7, modBtn)
        end
    end
end)
