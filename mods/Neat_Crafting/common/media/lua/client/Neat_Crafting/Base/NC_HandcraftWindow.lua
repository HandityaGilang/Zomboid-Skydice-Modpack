require "ISUI/ISPanel"

NC_HandcraftWindow = ISPanel:derive("NC_HandcraftWindow")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandcraftWindow:initialise()
    ISPanel.initialise(self)
end

function NC_HandcraftWindow:new(x, y, width, height, player, isoObject, queryOverride, contextRecipe)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.isoObject = isoObject
    o.queryOverride = queryOverride
    o.contextRecipe = contextRecipe
    o.moveWithMouse = true
    o.hasClosedWindowInstance = false
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)

    o.headerHeight = math.floor(FONT_HGT_MEDIUM * 1.5)
    o.headerButtonSize = FONT_HGT_MEDIUM
    o:setWantKeyEvents(true)
    
    return o
end

function NC_HandcraftWindow:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local minWidth = NCConfig.minPanelWidth
    local minHeight = NCConfig.windowMinHeight

    if width <= minWidth and height <= minHeight and 
       self.width == minWidth and self.height == minHeight then
        return
    end

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    if self.header then
        self.header:setX(0)
        self.header:setY(0)
        self.header:calculateLayout(width, self.headerHeight)
        width = math.max(width, self.header:getWidth())
    end
    
    if self.HandCraftPanel then
        local panelY = self.headerHeight
        local panelHeight = height - self.headerHeight
        
        self.HandCraftPanel:setX(0)
        self.HandCraftPanel:setY(panelY)
        self.HandCraftPanel:calculateLayout(width, panelHeight)
        
        width = math.max(width, self.HandCraftPanel:getWidth())
        height = math.max(height, self.HandCraftPanel:getHeight() + self.headerHeight)
    end

    self:setWidth(width)
    self:setHeight(height)
    -- Debug print removed: layout can run frequently during resize.
end

-- ----------------------------------------------------------------------------------------------------- --
-- create Children
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandcraftWindow:createChildren()
    self:createHandCraftPanel()
    self:createHeader()
    self:createResizeWidget()
end

function NC_HandcraftWindow:createHeader()
    self.header = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CraftHeader, 0, 0, self.width, self.headerHeight, self)
    self.header:initialise()
    self:addChild(self.header)
    self.header:calculateLayout(self.width, self.headerHeight)
end

-- create HandCraftPanel
function NC_HandcraftWindow:createHandCraftPanel()
    -- Do not pass context recipe data into the panel constructor slot reserved for recipe tag queries.
    self.HandCraftPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_HandCraftPanel, 0, self.headerHeight, self.width, self.height - self.headerHeight, self, self.player, nil, self.isoObject, nil)

    -- Only strings are valid query overrides for CraftRecipeManager.queryRecipes.
    if type(self.queryOverride) == "string" and self.queryOverride ~= "" then
        self.HandCraftPanel.recipeQuery = self.queryOverride
    else
        self.HandCraftPanel.recipeQuery = "InHandCraft;AnySurfaceCraft"
    end

    self.HandCraftPanel:initialise()
    self:addChild(self.HandCraftPanel)
end

function NC_HandcraftWindow:createResizeWidget()
    local resizeSize = self.padding
    self.resizeWidget = ISResizeWidget:new(self.width - resizeSize-2, self.height - resizeSize-2, resizeSize, resizeSize, self, false)
    self.resizeWidget.anchorRight = true
    self.resizeWidget.anchorBottom = true
    self.resizeWidget:initialise()
    self.resizeWidget.prerender = function(widget)
        local alpha = widget.mouseOver and 0.8 or 0.6
        widget:drawTextureScaledAspect(getTexture("media/ui/NeatUI/Resize/ResizeIcon.png"), 0, 0, widget.width, widget.height, alpha, 1, 1, 1)
    end
    self.resizeWidget.resizeFunction = function(target, newWidth, newHeight)
        target:calculateLayout(newWidth, newHeight)
    end
    self:addChild(self.resizeWidget)
end
-- ----------------------------------------------------------------------------------------------------- --
-- Others
-- ----------------------------------------------------------------------------------------------------- --

function NC_HandcraftWindow:getWindowTitle()
    return getText("IGUI_CraftUI_Title")
end

function NC_HandcraftWindow:getWindowIcon()
    return getTexture("media/ui/Neat_Crafting/ICON/CraftingBase.png")
end

function NC_HandcraftWindow:onSearchChanged(searchString)
    if self.HandCraftPanel then
        self.HandCraftPanel:onSearchTextChanged(searchString)
    end
end

function NC_HandcraftWindow:close()
    if self.hasClosedWindowInstance then
        return
    end
    self.hasClosedWindowInstance = true
    
    ISEntityUI.OnCloseWindow(self)
    if JoypadState.players[self.playerNum+1] then
        if isJoypadFocusOnElementOrDescendant(self.playerNum, self) then
            setJoypadFocus(self.playerNum, nil)
        end
    end
    
    if self.entity then
        self.entity:setUsingPlayer(nil)
    end
    
    self:removeFromUIManager()
end


-- ----------------------------------------------------------------------------------------------------- --
-- Keyboard function
-- ----------------------------------------------------------------------------------------------------- --

function NC_HandcraftWindow:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key)
end

function NC_HandcraftWindow:onKeyRelease(key)
    if self:isVisible() and (key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key)) then
        self:close()
        self:removeFromUIManager()
        return true
    end
    return false
end

function NC_HandcraftWindow:onKeyPressed(key)
    if key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key) then
        return true
    end
    return false
end


-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandcraftWindow:prerender()
    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/MainPanelBG_FlatTop.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY() + self.headerHeight, self.width, self.height - self.headerHeight, 0.15, 0.15, 0.15, NCConfig.windowBackgroundAlpha)
    end

    self:drawRect(0, self.headerHeight-1, self.width, 2, 1, 0, 0, 0)
end

function NC_HandcraftWindow:render()
end

return NC_HandcraftWindow