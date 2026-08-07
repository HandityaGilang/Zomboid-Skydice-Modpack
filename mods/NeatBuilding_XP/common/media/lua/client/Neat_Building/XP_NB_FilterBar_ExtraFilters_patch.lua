-- XP_NB_FilterBar_ExtraFilters_patch.lua
--
-- This patch is loaded after Neat Building and adds the XP/mod-only filter buttons.
-- Neat Building itself provides the core extra filters (can-build / skill / known / min-size)
-- and the two-row filter bar layout.

--============================================================
-- Small helpers
--============================================================
local function XP_NB_getTextureAny(paths)
    -- Try multiple texture paths and return the first valid texture
    for i = 1, #paths do
        local tex = getTexture(paths[i])
        if tex then return tex end
    end
    return nil
end

--============================================================
-- XP / Mod filter click handlers (installed only after NB_FilterBar exists)
--============================================================
local function XP_NB_installFilterClickHandlers()
    if not NB_FilterBar or NB_FilterBar._XP_NB_ClickHandlersPatched then
        return false
    end

    NB_FilterBar._XP_NB_ClickHandlersPatched = true

    function NB_FilterBar:onXP_NB_XPFilterClick()
        -- Toggle XP-only filter
        self._XP_NB_filterXP = not (self._XP_NB_filterXP == true)
        if self.xpBtn then
            self.xpBtn:setActive(self._XP_NB_filterXP == true)
        end
        if self.BuildingPanel and self.BuildingPanel.onFilterChanged then
            self.BuildingPanel:onFilterChanged()
        end
    end

    function NB_FilterBar:onXP_NB_ModFilterClick()
        -- Toggle Mod-only filter
        self._XP_NB_filterMod = not (self._XP_NB_filterMod == true)
        if self.modBtn then
            self.modBtn:setActive(self._XP_NB_filterMod == true)
        end
        if self.BuildingPanel and self.BuildingPanel.onFilterChanged then
            self.BuildingPanel:onFilterChanged()
        end
    end

    return true
end

--============================================================
-- Patch NB_FilterBar:createChildren to add XP/mod-only buttons
--============================================================
local function XP_NB_patchFilterBar()
    if not NB_FilterBar or NB_FilterBar._XP_NB_XPModButtonsPatched then
        return false
    end

    XP_NB_installFilterClickHandlers()

    NB_FilterBar._XP_NB_XPModButtonsPatched = true

    local _oldCreateChildren = NB_FilterBar.createChildren
    function NB_FilterBar:createChildren()
        -- Call original first (creates the base filter bar + built-in extra filters)
        if _oldCreateChildren then
            _oldCreateChildren(self)
        end

        -- Guard: avoid adding buttons twice for the same instance
        if self._XP_NB_xpModButtonsAdded then return end
        self._XP_NB_xpModButtonsAdded = true

        -- Initialize states (persist per instance)
        self._XP_NB_filterXP  = self._XP_NB_filterXP  == true
        self._XP_NB_filterMod = self._XP_NB_filterMod == true

        -- Load icons (prefer Neat_Building; allow fallback paths)
        local xpIcon = XP_NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_XPAward.png",
            "media/ui/Neat_Building/Icon/Icon_XPAward.png",
            "media/ui/Neat_Crafting/ICON/Icon_XPAward.png",
            "media/ui/Neat_Crafting/Icon/Icon_XPAward.png",
        })

        local modIcon = XP_NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_ModOnly.png",
            "media/ui/Neat_Building/Icon/Icon_ModOnly.png",
            "media/ui/Neat_Crafting/ICON/Icon_ModOnly.png",
            "media/ui/Neat_Crafting/Icon/Icon_ModOnly.png",
        })

        -- Create XP button
        self.xpBtn = NI_SquareButton:new(0, 0, 10, xpIcon, self, self.onXP_NB_XPFilterClick)
        self.xpBtn:initialise()
        self.xpBtn:setActiveColor(0.2, 0.6, 0.2)
        self.xpBtn:setActive(self._XP_NB_filterXP == true)
        self.xpBtn:setTooltip(getText("UI_NB_filterOnlyXPAward"))
        self:addChild(self.xpBtn)

        -- Create Mod button
        self.modBtn = NI_SquareButton:new(0, 0, 10, modIcon, self, self.onXP_NB_ModFilterClick)
        self.modBtn:initialise()
        self.modBtn:setActiveColor(0.2, 0.6, 0.2)
        self.modBtn:setActive(self._XP_NB_filterMod == true)
        self.modBtn:setTooltip(getText("UI_NB_filterOnlyModRecipes"))
        self:addChild(self.modBtn)

        -- Force relayout so new buttons don't stay at (0,0)
        if self.calculateLayout then
            self:calculateLayout(self.width, self.height)
        end
    end

    return true
end

--============================================================
-- Bootstrap patch (safe even if load order changes)
--============================================================
Events.OnGameBoot.Add(function()
    if XP_NB_patchFilterBar() then return end

    -- Fallback: retry on tick until NB_FilterBar exists
    local tickFn
    tickFn = function()
        if XP_NB_patchFilterBar() then
            Events.OnTick.Remove(tickFn)
        end
    end
    Events.OnTick.Add(tickFn)
end)
