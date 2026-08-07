require "ISBaseObject"
require "ISUI/ISButton"
require "ISUI/ISContextMenu"
require "ISUI/ISTextEntryBox"

ISInventoryCommonHandler_InventorySearch = ISBaseObject:derive("ISInventoryCommonHandler_InventorySearch")
local Handler = ISInventoryCommonHandler_InventorySearch
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

Handler.SEARCH_MODE_NAME = "name"
Handler.SEARCH_MODE_CATEGORY = "category"
Handler.SEARCH_MODE_BOTH = "both"

local function CleanUI_getTextOrFallback(key, fallback)
    -- Keep the UI readable even if an older branch is missing a new translation key.
    local text = getText(key)
    if not text or text == key then
        return fallback
    end
    return text
end

local function CleanUI_isNonEmptyText(text)
    return text and text ~= ""
end

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    return true
end

function Handler:getControl()
    if not self.control then
        self:createSearchControl()
    end
    return self.control
end

function Handler:createTextEntryBox(x, tooltip)
    -- Create one search field and attach the same right-click mode menu to it.
    local box = ISTextEntryBox:new("", x, 0, self.searchBoxWidth, self.buttonHeight)
    box.backgroundColor.a = 0
    box.borderColor.a = 0
    box:initialise()
    box:setFont(UIFont.Small)
    box.onTextChange = function()
        if self.suppressSearchUpdate then return end
        self:onSearchTextChange()
    end
    box.onRightMouseUp = function(_box, _x, _y)
        self:showSearchModeMenu()
        return true
    end
    if box.setTooltip then
        box:setTooltip(tooltip)
    else
        box.tooltip = tooltip
    end
    box:setVisible(true)
    self.control:addChild(box)
    return box
end

function Handler:createSearchControl()
    self.buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    self.searchBoxWidth = self.buttonHeight * 4
    self.fieldGap = math.max(4, math.floor(self.buttonHeight * 0.25))

    self.control = ISPanel:new(0, 0, self.searchBoxWidth + self.buttonHeight, self.buttonHeight)
    self.control:initialise()
    self.control.onRightMouseUp = function(_panel, _x, _y)
        self:showSearchModeMenu()
        return true
    end
    self.control.prerender = function(panel)

        CleanUI.ThreePatch.drawHorizontal(panel, 0, 0, panel.width, panel.height,
        getTexture("media/ui/CleanUI/Button/LongBackground_L.png"),
        getTexture("media/ui/CleanUI/Button/LongBackground_M.png"),
        getTexture("media/ui/CleanUI/Button/LongBackground_R.png"),
        0.6, 0.1, 0.1, 0.1)

        CleanUI.ThreePatch.drawHorizontal(panel, 0, 0, panel.width, panel.height,
        getTexture("media/ui/CleanUI/Button/LongBorder_L.png"),
        getTexture("media/ui/CleanUI/Button/LongBorder_M.png"),
        getTexture("media/ui/CleanUI/Button/LongBorder_R.png"),
        1, 0.4, 0.4, 0.4)

        self:renderFallbackSearchIcons(panel)
    end

    local tooltip = CleanUI_getTextOrFallback("UI_CleanUI_SearchModeTooltip", "Right-click to change search mode")
    self.searchField = self:createTextEntryBox(2, tooltip)
    self.categorySearchField = self:createTextEntryBox(self.searchBoxWidth + self.fieldGap, tooltip)

    self.clearButton = ISButton:new(self.searchBoxWidth, 0, self.buttonHeight, self.buttonHeight, "", self,
        function(_self) _self:clearSearch() end
    )
    self.clearButton:initialise()
    self.clearButton.prerender = function(button)
        local iconSize = math.floor(button.height * 0.8)
        local offset = (button.height - iconSize) / 2
        button:drawTextureScaled(getTexture("media/ui/CleanUI/ICON/Icon_Close.png"), offset, offset, iconSize, iconSize, 1, 0.7, 0.7, 0.7)
    end
    self.clearButton:setVisible(false)
    self.control:addChild(self.clearButton)

    self:updateSearchControlLayout()
end

function Handler:renderFallbackSearchIcons(panel)
    -- Older text boxes may not support placeholder text; keep the old magnifier fallback for them.
    if self.searchField and self.searchField.setPlaceholderText then return end

    local icon = getTexture("media/ui/CleanUI/ICON/Icon_Search.png")
    if not icon then return end

    local iconSize = math.floor(panel.height * 0.8)
    local offset = (panel.height - iconSize) / 2

    local text = self.searchField and self.searchField:getInternalText() or ""
    if self.searchField and self.searchField:isVisible() and not self.searchField:isFocused() and text == "" then
        panel:drawTextureScaled(icon, self.searchField:getX() + offset, offset, iconSize, iconSize, 1, 0.7, 0.7, 0.7)
    end

    local categoryText = self.categorySearchField and self.categorySearchField:getInternalText() or ""
    if self.categorySearchField and self.categorySearchField:isVisible() and not self.categorySearchField:isFocused() and categoryText == "" then
        panel:drawTextureScaled(icon, self.categorySearchField:getX() + offset, offset, iconSize, iconSize, 1, 0.7, 0.7, 0.7)
    end
end

function Handler:getSearchMode()
    return self.searchMode or Handler.SEARCH_MODE_NAME
end

function Handler:updateSearchControlLayout()
    if not self.control then return end

    local mode = self:getSearchMode()
    local combinedMode = mode == Handler.SEARCH_MODE_BOTH
    local totalWidth = self.searchBoxWidth + self.buttonHeight

    if combinedMode then
        totalWidth = (self.searchBoxWidth * 2) + self.fieldGap + self.buttonHeight
    end

    self.searchField:setX(2)
    self.searchField:setWidth(self.searchBoxWidth)
    self.categorySearchField:setX(self.searchBoxWidth + self.fieldGap)
    self.categorySearchField:setWidth(self.searchBoxWidth)
    self.categorySearchField:setVisible(combinedMode)
    self.clearButton:setX(totalWidth - self.buttonHeight)
    self.control:setWidth(totalWidth)

    self:updateSearchPlaceholders()
    self:updateClearButtonVisibility()
end

function Handler:updateSearchPlaceholders()
    -- The first box changes meaning in category-only mode; combined mode uses both boxes.
    if not self.searchField.setPlaceholderText then return end

    local mode = self:getSearchMode()
    if mode == Handler.SEARCH_MODE_CATEGORY then
        self.searchField:setPlaceholderText(CleanUI_getTextOrFallback("UI_CleanUI_SearchCategoryPlaceholder", "Category"))
    elseif mode == Handler.SEARCH_MODE_BOTH then
        self.searchField:setPlaceholderText(CleanUI_getTextOrFallback("UI_CleanUI_SearchNamePlaceholder", "Name"))
        self.categorySearchField:setPlaceholderText(CleanUI_getTextOrFallback("UI_CleanUI_SearchCategoryPlaceholder", "Category"))
    else
        self.searchField:setPlaceholderText(CleanUI_getTextOrFallback("UI_CleanUI_SearchNamePlaceholder", "Name"))
    end
end

function Handler:updateClearButtonVisibility()
    if not self.clearButton then return end

    local nameText, categoryText = self:getSearchTexts()
    self.clearButton:setVisible(CleanUI_isNonEmptyText(nameText) or CleanUI_isNonEmptyText(categoryText))
end

function Handler:getWindow()
    return self.inventoryWindow or self.lootWindow
end

function Handler:getSearchTexts()
    local mode = self:getSearchMode()
    local firstText = self.searchField and self.searchField:getInternalText() or ""
    local secondText = self.categorySearchField and self.categorySearchField:getInternalText() or ""

    if mode == Handler.SEARCH_MODE_CATEGORY then
        return "", firstText
    end
    if mode == Handler.SEARCH_MODE_BOTH then
        return firstText, secondText
    end
    return firstText, ""
end

function Handler:onSearchTextChange()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return end

    local nameText, categoryText = self:getSearchTexts()
    window.inventoryPane:searchContainer(nameText, categoryText, self:getSearchMode())
    self:updateClearButtonVisibility()
end

function Handler:showSearchModeMenu()
    if not self.control then return end

    local window = self:getWindow()
    local x = self.control:getAbsoluteX()
    local y = self.control:getAbsoluteY() + self.control:getHeight()
    local context = ISContextMenu.get(self.playerNum or 0, x, y)
    local mode = self:getSearchMode()

    local nameOption = context:addOption(CleanUI_getTextOrFallback("UI_CleanUI_SearchByItemName", "Search by Item Name"), self, Handler.setSearchMode, Handler.SEARCH_MODE_NAME)
    context:setOptionChecked(nameOption, mode == Handler.SEARCH_MODE_NAME)

    local categoryOption = context:addOption(CleanUI_getTextOrFallback("UI_CleanUI_SearchByCategory", "Search by Category"), self, Handler.setSearchMode, Handler.SEARCH_MODE_CATEGORY)
    context:setOptionChecked(categoryOption, mode == Handler.SEARCH_MODE_CATEGORY)

    local bothOption = context:addOption(CleanUI_getTextOrFallback("UI_CleanUI_SearchByNameAndCategory", "Search by Name and Category"), self, Handler.setSearchMode, Handler.SEARCH_MODE_BOTH)
    context:setOptionChecked(bothOption, mode == Handler.SEARCH_MODE_BOTH)

    if context.numOptions > 1 then
        context:setVisible(true)
        if window and JoypadState.players[self.playerNum + 1] then
            context.origin = window
            context.mouseOver = 1
            setJoypadFocus(self.playerNum, context)
        end
    end
end

function Handler:setSearchMode(mode)
    local oldMode = self:getSearchMode()
    if mode ~= Handler.SEARCH_MODE_CATEGORY and mode ~= Handler.SEARCH_MODE_BOTH then
        mode = Handler.SEARCH_MODE_NAME
    end
    if oldMode == mode then return end

    local oldNameText, oldCategoryText = self:getSearchTexts()
    self.searchMode = mode
    self.suppressSearchUpdate = true

    -- Preserve the most useful query when switching modes so users do not lose their typed text.
    if mode == Handler.SEARCH_MODE_NAME then
        self.searchField:setText(oldNameText ~= "" and oldNameText or oldCategoryText)
        self.categorySearchField:setText("")
    elseif mode == Handler.SEARCH_MODE_CATEGORY then
        self.searchField:setText(oldCategoryText ~= "" and oldCategoryText or oldNameText)
        self.categorySearchField:setText("")
    else
        self.searchField:setText(oldNameText)
        self.categorySearchField:setText(oldCategoryText)
    end

    self.suppressSearchUpdate = false
    self:updateSearchControlLayout()
    self:onSearchTextChange()
end

function Handler:clearSearch()
    self.suppressSearchUpdate = true
    self.searchField:setText("")
    self.categorySearchField:setText("")
    self.suppressSearchUpdate = false
    self:updateClearButtonVisibility()

    local window = self:getWindow()
    if window and window.inventoryPane then
        window.inventoryPane:searchContainer("", "", self:getSearchMode())
    end
    self.searchField:focus()
end

function Handler:perform()
    self.searchField:focus()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Temp move the TransferMenu here for joypad
-- ----------------------------------------------------------------------------------------------------- --
function Handler:showTransferMenu()
    local window = self:getWindow()
    if not window then return end

    local x = self.control:getAbsoluteX()
    local y = self.control:getAbsoluteY() + self.control:getHeight()

    local context = ISInventoryPageTransferHandler.showTransferMenu(window, x, y)

    if context and JoypadState.players[self.playerNum + 1] then
        context.origin = window
        context.mouseOver = 1
        setJoypadFocus(self.playerNum, context)
    end
end

function Handler:handleJoypadContextMenu(context)
    context:addOption(getText("UI_CleanUI_TransferMenu"), self, self.showTransferMenu)

    return context
end

function Handler:addJoypadContextMenuOption(context, text)
    local option = context:addOption(text, self, self.perform)
    return option
end

function Handler:new()
    local o = ISBaseObject.new(self)
    o.altColor = false
    o.searchMode = Handler.SEARCH_MODE_NAME
    o.suppressSearchUpdate = false
    return o
end
