require "ISUI/ISPanel"

NC_SearchBox = ISPanel:derive("NC_SearchBox")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_SearchBox:initialise()
    ISPanel.initialise(self)
end

function NC_SearchBox:new(x, y, width, height, Mainpanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    o.Mainpanel = Mainpanel
    o.searchText = ""
    o.searchMode = "RecipeName"
    o.padding = NCConfig.padding
    o.buttonSize = math.floor(height)
    o.searchBoxHeight = height

    o.clearButtonSize = math.floor(height * 0.6)
    o.clearIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Close.png")
    o.UIElementBGTextures = {
        left = getTexture("media/ui/NeatUI/Button/Button_FULL_L.png"),
        middle = getTexture("media/ui/NeatUI/Button/Button_FULL_M.png"),
        right = getTexture("media/ui/NeatUI/Button/Button_FULL_R.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_SearchBox:createChildren()
    local buttonY = (self.height - self.buttonSize) / 2
    
    -- Search Mode Button
    local searchIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_SearchItem.png")
    self.searchModeButton = NC_SquareButton:new(
        0, 
        buttonY, 
        self.buttonSize, 
        searchIcon, 
        self, 
        self.onSearchModeButtonClick
    )
    self.searchModeButton:initialise()
    self:addChild(self.searchModeButton)
    
    -- Search Text Entry Box
    local searchBoxX = self.buttonSize + self.padding
    local searchBoxWidth = self.width - searchBoxX
    local searchBoxY = (self.height - self.searchBoxHeight) / 2
    
    self.searchBox = ISTextEntryBox:new(
        "", 
        searchBoxX, 
        searchBoxY, 
        searchBoxWidth, 
        self.searchBoxHeight
    )
    self.searchBox:initialise()
    self.searchBox.font = UIFont.Small
    self.searchBox.onTextChange = function()
        self:onSearchTextChanged()
    end
    self.searchBox.backgroundColor.a = 0
    self.searchBox.borderColor.a = 0
    self.searchBox.prerender = function(searchBox)
        NeatTool.ThreePatch.drawHorizontal(
            searchBox,
            -self.padding/2, 0, 
            searchBox.width + self.padding, searchBox.height,
            self.UIElementBGTextures.left,
            self.UIElementBGTextures.middle,
            self.UIElementBGTextures.right,
            1, 0.4, 0.4, 0.4
        )
    end
    self:addChild(self.searchBox)

    -- Clear Button
    local clearButtonX = searchBoxX + searchBoxWidth - self.clearButtonSize - self.padding/2
    local clearButtonY = searchBoxY + (self.searchBoxHeight - self.clearButtonSize) / 2
    
    self.clearButton = ISButton:new(
        clearButtonX,
        clearButtonY,
        self.clearButtonSize,
        self.clearButtonSize,
        "",
        self,
        self.onClearButtonClick
    )
    self.clearButton:initialise()
    self.clearButton.borderColor.a = 0
    self.clearButton.backgroundColor.a = 0
    self.clearButton.backgroundColorMouseOver.a = 0
    self.clearButton:setVisible(false)
    
    self.clearButton.prerender = function(button)
        if button:isVisible() then
            local alpha = button:isMouseOver() and 1.0 or 0.7
            button:drawTextureScaled(self.clearIcon,0, 0,button.width, button.height,alpha, 0.8, 0.8, 0.8)
        end
    end
    
    self:addChild(self.clearButton)
    
    self:updateSearchModeButton()

    if NC_InventorySearch and NC_InventorySearch.pendingSearch then
        local search = NC_InventorySearch.pendingSearch
        NC_InventorySearch.pendingSearch = nil
        
        self:setSearchMode(search.mode)
        self:setSearchText(search.text)
        self:performSearch()
    end
    
    self:updateClearButtonVisibility()
end

function NC_SearchBox:calculateLayout(__preferredWidth, __preferredHeight)
    local width = __preferredWidth or self.width
    local height = __preferredHeight or self.height
    
    self:setWidth(width)
    self:setHeight(height)

    if self.searchBox then
        local searchBoxX = self.buttonSize + self.padding
        local searchBoxWidth = width - searchBoxX - self.clearButtonSize - self.padding * 2
        local searchBoxY = (height - self.searchBoxHeight) / 2
        
        self.searchBox:setX(searchBoxX)
        self.searchBox:setY(searchBoxY)
        self.searchBox:setWidth(searchBoxWidth)

        if self.clearButton then
            local clearButtonX = searchBoxX + searchBoxWidth - self.clearButtonSize - self.padding/2
            local clearButtonY = searchBoxY + (self.searchBoxHeight - self.clearButtonSize) / 2
            self.clearButton:setX(clearButtonX)
            self.clearButton:setY(clearButtonY)
        end
    end

    if self.searchModeButton then
        local buttonY = (height - self.buttonSize) / 2
        self.searchModeButton:setY(buttonY)
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- Search
-- ----------------------------------------------------------------------------------------------------- --
function NC_SearchBox:onSearchTextChanged()
    self.searchText = self.searchBox:getInternalText()
    self:updateClearButtonVisibility()
    self:performSearch()
end

function NC_SearchBox:performSearch()
    local searchString = self.searchText or ""

    if self.searchMode and self.searchMode ~= "RecipeName" and searchString ~= "" then
        searchString = searchString .. "-@-" .. self.searchMode
    end

    self.Mainpanel:onSearchChanged(searchString)
end

function NC_SearchBox:onSearchModeButtonClick()
    local context = ISContextMenu.get(
        0, 
        self.searchModeButton:getAbsoluteX(), 
        self.searchModeButton:getAbsoluteY() + self.searchModeButton:getHeight()
    )
    
    local option1 = context:addOption(getText("IGUI_FilterType_RecipeName"), self, self.setSearchMode, "RecipeName")
    option1.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/Grey.png")
    
    local option2 = context:addOption(getText("IGUI_FilterType_InputName"), self, self.setSearchMode, "InputName")
    option2.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/Blue.png")
    
    local option3 = context:addOption(getText("IGUI_FilterType_OutputName"), self, self.setSearchMode, "OutputName")
    option3.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/Orange.png")
end

function NC_SearchBox:setSearchMode(mode)
    self.searchMode = mode
    self:updateSearchModeButton()

    if self.searchText and self.searchText ~= "" then
        self:performSearch()
    end
end

function NC_SearchBox:onClearButtonClick()
    self:clearSearch()
    self:updateClearButtonVisibility()
end

function NC_SearchBox:updateClearButtonVisibility()
    if self.clearButton then
        local hasText = self.searchText and self.searchText ~= ""
        self.clearButton:setVisible(hasText)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- UI Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_SearchBox:updateSearchModeButton()
    if not self.searchModeButton then return end

    if self.searchMode == "RecipeName" then
        self.searchModeButton:setActiveColor(0.2, 0.2, 0.2)
        self.searchModeButton:setActive(false)
    elseif self.searchMode == "InputName" then
        self.searchModeButton:setActiveColor(0.2, 0.4, 0.8)
        self.searchModeButton:setActive(true)
    elseif self.searchMode == "OutputName" then
        self.searchModeButton:setActiveColor(0.8, 0.5, 0.2)
        self.searchModeButton:setActive(true)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- set & get
-- ----------------------------------------------------------------------------------------------------- --
function NC_SearchBox:getSearchText()
    return self.searchText
end

function NC_SearchBox:getSearchMode()
    return self.searchMode
end

function NC_SearchBox:setSearchText(text)
    if self.searchBox then
        self.searchBox:setText(text or "")
        self.searchText = text or ""
        self:updateClearButtonVisibility()
    end
end

function NC_SearchBox:clearSearch()
    self:setSearchText("")
    self:performSearch()
end

return NC_SearchBox