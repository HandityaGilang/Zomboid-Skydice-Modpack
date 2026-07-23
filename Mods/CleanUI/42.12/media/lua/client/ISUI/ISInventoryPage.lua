require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISInventoryPane"
require "ISUI/ISResizeWidget"
require "ISUI/ISMouseDrag"
require "ISUI/ISLayoutManager"
require "ISUI/InventoryWindow/ISInventoryWindowContainerControls"
require "ISUI/LootWindow/ISLootWindowContainerControls"
require "Definitions/ContainerButtonIcons"
require "defines"


local function CleanUI_canAccessVehicleContainer(vehicle, partIndex, playerObj, itemContainer)
    -- Keep UI refresh safe if vanilla or another mod throws while testing vehicle container access.
    if not vehicle or not playerObj then
        return false
    end

    local ok, result = pcall(function()
        return vehicle:canAccessContainer(partIndex, playerObj)
    end)
    if ok then
        return result == true
    end

    -- Fallback to the lighter character/container access check instead of breaking the inventory UI.
    if itemContainer then
        local okFallback, fallbackResult = pcall(function()
            return playerObj:canAccessContainer(itemContainer)
        end)
        if okFallback then
            return fallbackResult == true
        end
    end

    return false
end

local TurnOnOff = {
	ClothingDryer = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingDryer:new(getPlayer(), object))
            end
		end
	},
	ClothingWasher = {
		isPowered = function(object)
			if object:getFluidAmount() <= 0 then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingWasher:new(getPlayer(), object))
            end
		end
	},
	CombinationWasherDryer = {
		isPowered = function(object)
			if object:isModeWasher() and (object:getFluidAmount() <= 0) then return false end
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleComboWasherDryer:new(getPlayer(), object))
            end
		end
	},
	Stove = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:Activated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleStoveAction:new(getPlayer(), object))
            end
			--object:Toggle()
		end
	}
}

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

ISInventoryPage = ISPanel:derive("ISInventoryPage")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL
local MAXIMUM_RENAME_LENGTH = 28

ISInventoryPage.bagSoundDelay = 0.5
ISInventoryPage.bagSoundTime = 0


local function CleanUI_isMoveToFloorButtonAvailable(inventoryPage)
    -- Only show the quick Move To Floor button for loot containers that are not already the floor.
    local sourceContainer = inventoryPage and inventoryPage.inventoryPane and inventoryPage.inventoryPane.inventory
    return sourceContainer ~= nil and sourceContainer:getType() ~= "floor"
end

local function CleanUI_drawTitleIconButton(inventoryPage, btn, icon, disabled)
    -- Draw a compact title-bar button used by the optional split transfer layout.
    local brightness = btn.mouseOver and 0.22 or 0.12
    if disabled then
        brightness = 0.06
    end
    btn:drawTextureScaled(inventoryPage.buttonTex.bg, 0, 0, btn.width, btn.height, 1, brightness, brightness, brightness)
    btn:drawTextureScaled(inventoryPage.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

    if icon then
        local iconSize = btn.width * 0.8
        local iconXY = (btn.width - iconSize) / 2
        local alpha = disabled and 0.35 or 0.85
        btn:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, alpha, 0.8, 0.8, 0.8)
    end

    -- Custom button prerenders replace ISButton:prerender(), so tooltips must be updated explicitly.
    if btn.updateTooltip then
        btn:updateTooltip()
    end
end

function ISInventoryPage:onToggleVisible()
    self.inventoryPane:clearWorldObjectHighlights()
end

function ISInventoryPage:titleBarHeight(selected)
	return math.max(16, math.floor(self.titleFontHgt * 1.2))
end

function ISInventoryPage:initialise()
	ISPanel.initialise(self)
end

function ISInventoryPage:new (x, y, width, height, inventory, onCharacter, zoom)
	local o = {}
	o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
	o.x = x
	o.y = y
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
	o.width = width
	o.height = height
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.resizeWidgetSize = math.floor(FONT_HGT_SMALL * 0.4)
	o.anchorLeft = true
    o.backpackChoice = 1
    o.zoom = zoom
    o.isCollapsed = true
    if o.zoom == nil then o.zoom = 1 end

	o.inventory = inventory
    o.onCharacter = onCharacter
    o.resizeimage = getTexture("media/ui/CleanUI/ResizeIcon.png")
    o.invbasic = getTexture("media/ui/CleanUI/ICON/Icon_BasicInventory.png")

    o.buttonIcon = {
        close = getTexture("media/ui/CleanUI/ICON/Icon_Close.png"),
        pin = getTexture("media/ui/CleanUI/ICON/Icon_RightArrow.png"),
        collapse = getTexture("media/ui/CleanUI/ICON/Icon_DownArrow.png"),
        lock = getTexture("media/ui/CleanUI/ICON/Icon_Lock.png"),
        unlock = getTexture("media/ui/CleanUI/ICON/Icon_UnLock.png"),
        transfer = getTexture("media/ui/CleanUI/ICON/Icon_Transfer.png"),
        transferAll = getTexture("media/ui/CleanUI/ICON/Icon_TransferAll.png"),
        takeAll = getTexture("media/ui/CleanUI/ICON/Icon_TakeAll.png"),
        transferByName = getTexture("media/ui/CleanUI/ICON/Icon_SortByName.png"),
        transferByCategory = getTexture("media/ui/CleanUI/ICON/Icon_SortByType.png"),
        transferToGround = getTexture("media/ui/CleanUI/ICON/Icon_TransferToGround.png"),
        invTransferSingle = getTexture("media/ui/CleanUI/ICON/Icon_Inv_TransferSameTypeSingle.png"),
        invTransferMulti = getTexture("media/ui/CleanUI/ICON/Icon_Inv_TransferSameTypeMulti.png"),
        lootTransferSingle = getTexture("media/ui/CleanUI/ICON/Icon_Loot_TransferSameTypeSingle.png"),
        lootTransferMulti = getTexture("media/ui/CleanUI/ICON/Icon_Loot_TransferSameTypeMulti.png"),
    }

    o.buttonTex = {
        bg = getTexture("media/ui/CleanUI/Button/SQBackground.png"),
        border = getTexture("media/ui/CleanUI/Button/SQBorder.png")
    }

    o.containerButtonTex = {
        normal = getTexture("media/ui/CleanUI/Button/ContainerBtn_Normal.png"),
        selected = getTexture("media/ui/CleanUI/Button/ContainerBtn_Selected.png")
    }

    o.conDefault = getTexture("media/ui/Container_Shelf.png")
    o.highlightColors = {r=0.98,g=0.56,b=0.11}

    o.containerIconMaps = ContainerButtonIcons

    o.pin = true
    o.isCollapsed = false
    o.backpacks = {}
    o.collapseCounter = 0
	o.title = nil
	o.titleFont = UIFont.Small
	o.titleFontHgt = getTextManager():getFontHeight(o.titleFont)
    local sizes = { 32, 40, 48 }
    local baseSize = sizes[getCore():getOptionInventoryContainerSize()]
    local scaleMultiplier = CleanUI_getContainerButtonScaleMultiplier()
    o.buttonSize = math.floor(baseSize * scaleMultiplier)
    o.containerButtonPanelWidth = math.floor(o.buttonSize * 1.2)

    o.visibleTarget = o
    o.visibleFunction = ISInventoryPage.onToggleVisible

    o.disableJoypadNavigation = true

   return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Create Children
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPage:isPageLeft()
    local position = CleanUI_getContainerPosition(self)
    if position == "1" then
        return true
    else
        return false
    end
end

function ISInventoryPage:createChildren()
    self.minimumHeight = 100
    self.minimumWidth = 256 + self.buttonSize * 2

    local titleBarHeight = self:titleBarHeight()
    self.titleButtonSize = math.floor(titleBarHeight * 0.8)
    local buttonHeight = FONT_HGT_SMALL * 0.8
    local buttonOffset = 1 + (5-getCore():getOptionFontSizeReal())*2
    local textButtonOffset = buttonOffset * 3
    self.render3DItemRot = 0

    local inventoryPaneX = self:isPageLeft() and self.containerButtonPanelWidth or 0
    local inventoryPaneWidth = self.width - self.containerButtonPanelWidth

    -- controls Panel
    local controlsUIX = self:isPageLeft() and self.containerButtonPanelWidth or 0
    if self.onCharacter then
        self.controlsUI = ISInventoryWindowContainerControls:new(controlsUIX, titleBarHeight, self)
        self:addChild(self.controlsUI)
    else
        self.controlsUI = ISLootWindowContainerControls:new(controlsUIX, titleBarHeight, self)
        self:addChild(self.controlsUI)
    end

    -- inventorypane
    local panel2 = ISInventoryPane:new(inventoryPaneX, titleBarHeight, inventoryPaneWidth, self.height - titleBarHeight, self.inventory, self.zoom)
    panel2.anchorBottom = true
	panel2.anchorRight = true
    panel2.player = self.player
	panel2:initialise()
    panel2:setMode("details")
    panel2.inventoryPage = self
	self:addChild(panel2)
	self.inventoryPane = panel2

    local containerButtonPanelX = self:isPageLeft() and 0 or (self.width - self.containerButtonPanelWidth)
    self.containerButtonPanel = ISInventoryPageContainerButtonPanel:new(containerButtonPanelX, titleBarHeight, self.containerButtonPanelWidth, self.height - titleBarHeight)
    self.containerButtonPanel:noBackground()
    if self:isPageLeft() then
        self.containerButtonPanel.anchorLeft = true
        self.containerButtonPanel.anchorRight = false
        self.containerButtonPanel.anchorTop = true
        self.containerButtonPanel.anchorBottom = true
    else
        self.containerButtonPanel.anchorLeft = false
        self.containerButtonPanel.anchorRight = true
        self.containerButtonPanel.anchorTop = true
        self.containerButtonPanel.anchorBottom = true
    end
    self.containerButtonPanel.inventorypage = self
    self.containerButtonPanel:initialise()
    self:addChild(self.containerButtonPanel)

    -- resizeWidget
	local resizeWidget = ISResizeWidget:new(self.width - self.resizeWidgetSize, self.height - self.resizeWidgetSize, self.resizeWidgetSize, self.resizeWidgetSize, self)
	resizeWidget:initialise()
	self:addChild(resizeWidget)
	self.resizeWidget = resizeWidget
    local config = CleanUIConfig and CleanUIConfig.getConfig and CleanUIConfig.getConfig() or {}
    local isLocked = config["lockPanel"] or false
    if isLocked then
        self.resizeWidget:setVisible(false)
    end

    -- Close Button
    self.closeButton = ISButton:new(0, 0, self.titleButtonSize, self.titleButtonSize, "", self, ISInventoryPage.close)
    self.closeButton:initialise()
    self.closeButton.prerender = function(btn)
        btn:setX(self.width - self.padding - btn.width)
        btn:setY((titleBarHeight - btn.height) / 2)
        local color = btn.mouseOver and {r = 0.9, b = 0.3, g = 0.3} or {r = 0.8, b = 0.2, g = 0.2}
        btn:drawTextureScaled(self.buttonTex.bg, 0, 0, btn.width, btn.height, 1, color.r, color.g, color.b)
        btn:drawTextureScaled(self.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local iconSize = btn.width * 0.8
        local IconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(self.buttonIcon.close, IconXY, IconXY, iconSize, iconSize, 1, 1, 1, 1)
    end
    self:addChild(self.closeButton)
    if getCore():getGameMode() == "Tutorial" then
        self.closeButton:setVisible(false)
    end

    -- infoButton -- keep this button for mod compatibility
    self.infoButton = ISButton:new(0, 0, self.titleButtonSize, self.titleButtonSize, "", self, nil)
    self.infoButton:initialise()
    self:addChild(self.infoButton);
    self.infoButton:setVisible(false)

    -- Lock Button
    self.lockButton = ISButton:new(0, 0, self.titleButtonSize, self.titleButtonSize, "", self, ISInventoryPage.toggleLock)
    self.lockButton:initialise()
    self.lockButton.prerender = function(btn)
        btn:setX(self.closeButton:getX() - self.padding - btn.width)
        btn:setY((titleBarHeight - btn.height) / 2)

        local config = CleanUIConfig and CleanUIConfig.getConfig and CleanUIConfig.getConfig() or {}
        local configKey = self.onCharacter and "lockInventoryWindow" or "lockLootWindow"
        local isLocked = config[configKey] or false

        local icon = isLocked and self.buttonIcon.lock or self.buttonIcon.unlock
        local iconSize = btn.width
        local brightness = isLocked and 0.8 or 0.6
        btn:drawTextureScaled(icon, 0, 0, iconSize, iconSize, btn.mouseOver and 1 or 0.8, brightness, brightness, brightness)
    end
    self:addChild(self.lockButton)

    -- Pin Button
    self.pinButton = ISButton:new(0, 0, self.titleButtonSize, self.titleButtonSize, "", self, ISInventoryPage.setPinned)
    self.pinButton:initialise()
    self.pinButton.prerender = function(btn)
        btn:setX(self.padding)
        btn:setY((titleBarHeight - btn.height) / 2)
        local brightness = btn.mouseOver and 0.2 or 0.1
        btn:drawTextureScaled(self.buttonTex.bg, 0, 0, btn.width, btn.height, 1, brightness, brightness, brightness)
        btn:drawTextureScaled(self.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local iconSize = btn.width * 0.8
        local IconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(self.buttonIcon.pin, IconXY, IconXY, iconSize, iconSize, 1, 1, 1, 1)
    end
    self:addChild(self.pinButton)
    self.pinButton:setVisible(false)

    -- Collapse Button
    self.collapseButton = ISButton:new(0, 0, self.titleButtonSize, self.titleButtonSize, "", self, ISInventoryPage.collapse)
    self.collapseButton:initialise()
    self.collapseButton.prerender = function(btn)
        btn:setX(self.padding)
        btn:setY((titleBarHeight - btn.height) / 2)
        local color = btn.mouseOver and {r = 1, g = 0.55, b = 0.15} or {r = 0.95, g = 0.5, b = 0.1}
        btn:drawTextureScaled(self.buttonTex.bg, 0, 0, btn.width, btn.height, 1, color.r, color.g, color.b)
        btn:drawTextureScaled(self.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local iconSize = btn.width * 0.8
        local IconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(self.buttonIcon.collapse, IconXY, IconXY, iconSize, iconSize, 1, 1, 1, 1)
    end
    self:addChild(self.collapseButton)
    if getCore():getGameMode() == "Tutorial" then
        self.collapseButton:setVisible(false)
    end

    -- Transfer All Button
    local transferAllButtonWidth = math.max(self.titleButtonSize * 3, 80)
    self.transferAllButton = CleanUI_LongButton:new(0, 0, transferAllButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onTransferAllClick)
    self.transferAllButton.tooltip = self.onCharacter and getText("IGUI_invpage_Transfer_all") or getText("IGUI_invpage_Loot_all")
    self.transferAllButton:initialise()
    self.transferAllButton.render = function(btn)
        local weightLabel = ""
        local roundedWeight = round(self.totalWeight, 2)
        local playerObj = getSpecificPlayer(self.player)
        
        if self.capacity then
            local inventory = self.inventoryPane.inventory
            local part = inventory:getVehiclePart()
            
            if inventory == playerObj:getInventory() then
                weightLabel = roundedWeight .. " / " .. playerObj:getMaxWeight()
            elseif part and part:getId():contains("Seat") and part:getVehicle():getCharacter(part:getContainerSeatNumber()) then
                weightLabel = roundedWeight .. " / " .. (self.capacity/4)
            else
                -- Build 42.12.3 (SP): Simple capacity display
                weightLabel = roundedWeight .. " / " .. self.capacity
            end
        else
            weightLabel = roundedWeight .. ""
        end

        local textWidth = getTextManager():MeasureStringX(UIFont.Small, weightLabel)
        local iconSize = math.floor(btn.height * 0.9)
        btn:setWidth(textWidth + iconSize + self.padding * 3)
        btn:setX(self.lockButton:getX() - self.padding - btn.width)
        btn:setY((titleBarHeight - btn.height) / 2)

        local icon = self.onCharacter and self.buttonIcon.transferAll or self.buttonIcon.takeAll
        btn:drawTextureScaled(icon, self.padding, (btn.height - iconSize) / 2, iconSize, iconSize, 1, 0.8, 0.8, 0.8)
        btn:drawText(weightLabel, iconSize + self.padding * 2, (btn.height - FONT_HGT_SMALL) / 2, 1, 1, 1, 1, UIFont.Small)
    end
    self:addChild(self.transferAllButton)

    -- Transfer Button
    local transferButtonWidth = self.titleButtonSize
    self.transferButton = ISButton:new(0, 0, transferButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onTransferClick)
    self.transferButton:initialise()
    self.transferButton.prerender = function(btn)
        self:updateCleanUITransferButtonLayout(titleBarHeight)
        local useSplitButtons = CleanUI_getTransferButtonLayout() == "2"
        btn:setVisible(not useSplitButtons)
        if useSplitButtons then return end

        local color = btn.mouseOver and {r = 0.2, g = 0.2, b = 0.2} or {r = 0.1, g = 0.1, b = 0.1}
        btn:drawTextureScaled(self.buttonTex.bg, 0, 0, btn.width, btn.height, 1, color.r, color.g, color.b)
        btn:drawTextureScaled(self.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local iconSize = btn.width * 0.8
        local IconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(self.buttonIcon.transfer, IconXY, IconXY, iconSize, iconSize, 1, 0.8, 0.8, 0.8)
    end
    self:addChild(self.transferButton)

    -- Optional split transfer buttons
    self.transferMethodButton = ISButton:new(0, 0, transferButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onTransferMethodToggleClick)
    self.transferMethodButton:initialise()
    self.transferMethodButton.prerender = function(btn)
        self:updateCleanUITransferButtonLayout(titleBarHeight)
        if not btn:getIsVisible() then return end

        local transferMethod = CleanUI_getTransferMethod()
        local icon
        if self.onCharacter then
            icon = transferMethod == "2" and self.buttonIcon.invTransferMulti or self.buttonIcon.invTransferSingle
        else
            icon = transferMethod == "2" and self.buttonIcon.lootTransferMulti or self.buttonIcon.lootTransferSingle
        end
        btn.tooltip = transferMethod == "2" and getText("UI_CleanUI_TransferMethodNearbyTooltip") or getText("UI_CleanUI_TransferMethodSingleTooltip")
        CleanUI_drawTitleIconButton(self, btn, icon, false)
    end
    self:addChild(self.transferMethodButton)

    self.transferByNameButton = ISButton:new(0, 0, transferButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onTransferByNameClick)
    self.transferByNameButton:initialise()
    self.transferByNameButton.prerender = function(btn)
        self:updateCleanUITransferButtonLayout(titleBarHeight)
        if not btn:getIsVisible() then return end
        btn.tooltip = getText("UI_CleanUI_TransferByNameTooltip")
        ISInventoryPageTransferHandler.updateQuickButtonHighlight(self, btn, "type")
        CleanUI_drawTitleIconButton(self, btn, self.buttonIcon.transferByName, false)
    end
    self:addChild(self.transferByNameButton)

    self.transferByCategoryButton = ISButton:new(0, 0, transferButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onTransferByCategoryClick)
    self.transferByCategoryButton:initialise()
    self.transferByCategoryButton.prerender = function(btn)
        self:updateCleanUITransferButtonLayout(titleBarHeight)
        if not btn:getIsVisible() then return end
        btn.tooltip = getText("UI_CleanUI_TransferByCategoryTooltip")
        ISInventoryPageTransferHandler.updateQuickButtonHighlight(self, btn, "category")
        CleanUI_drawTitleIconButton(self, btn, self.buttonIcon.transferByCategory, false)
    end
    self:addChild(self.transferByCategoryButton)

    self.moveToFloorButton = ISButton:new(0, 0, transferButtonWidth, self.titleButtonSize, "", self, ISInventoryPage.onMoveToFloorClick)
    self.moveToFloorButton:initialise()
    self.moveToFloorButton.prerender = function(btn)
        self:updateCleanUITransferButtonLayout(titleBarHeight)
        if not btn:getIsVisible() then return end
        btn.tooltip = getText("UI_CleanUI_MoveToFloorTooltip")
        ISInventoryPageTransferHandler.updateQuickButtonHighlight(self, btn, "floor")
        CleanUI_drawTitleIconButton(self, btn, self.buttonIcon.transferToGround, false)
    end
    self:addChild(self.moveToFloorButton)

	self.totalWeight = ISInventoryPage.loadWeight(self.inventory)
	self.totalItems = 0

    self:refreshBackpacks()

    self:collapse()
end

function ISInventoryPage:onChangeFilter(selected)
end

-- ----------------------------------------------------------------------------------------------------- --
-- ISInventoryPageContainerButtonPanel
-- ----------------------------------------------------------------------------------------------------- --
ISInventoryPageContainerButtonPanel = ISPanel:derive("ISInventoryPageContainerButtonPanel")

function ISInventoryPageContainerButtonPanel:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    return o
end

function ISInventoryPageContainerButtonPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)

    local containerBgOpacity = CleanUI_getContainerBackgroundOpacity()
    local bg = self.inventorypage:isPageLeft() and NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_L.png") or NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/ContainerButtonArea_R.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 1, 1, 1, containerBgOpacity)
    end
    local lineX = self.inventorypage:isPageLeft() and self.width - 1 or 0
    self:drawRectStatic(lineX, 0, 1, self.height, 0.6, 0.0, 0.0, 0.0)
end

function ISInventoryPageContainerButtonPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
    self:repaintStencilRect(0, 0, self.width, self.height)
end

function ISInventoryPageContainerButtonPanel:keepSelectedButtonVisible()
    local scrollHeight = self:getScrollHeight()
    if scrollHeight > self:getHeight() then
        self:setScrollChildren(true)
        local button = self.parent.selectedButton
        local buttonY = button:getY() + self:getYScroll()
        if button ~= nil and buttonY <= 20 then
            self:setYScroll(-button.y + 20)
        elseif button ~= nil and buttonY + button:getHeight() + 20 > self.height then
            self:setYScroll((self.height - button.height) - button.y - 20)
        end
    else
        self:setYScroll(0.0)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Button Handle
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:updateItemCount()
    self.totalItems = luautils.countItemsRecursive({luautils.findRootInventory(self.inventoryPane.inventory)})
end

function ISInventoryPage:refreshWeight()
	return
end

function ISInventoryPage:lootAll()
    self.inventoryPane:lootAll()
end

function ISInventoryPage:transferAll()
    self.inventoryPane:transferAll()
end

function ISInventoryPage:onTransferAllClick()
    if self.onCharacter then
        self:transferAll()
    else
        self:lootAll()
    end
end

function ISInventoryPage:onTransferClick()
    local x = self.transferButton:getAbsoluteX()
    local y = self.transferButton:getAbsoluteY() + self.transferButton:getHeight()
    ISInventoryPageTransferHandler.showTransferMenu(self, x, y)
end

function ISInventoryPage:updateCleanUITransferButtonLayout(titleBarHeight)
    -- Keep the optional split transfer buttons aligned without changing the Transfer All button.
    titleBarHeight = titleBarHeight or self:titleBarHeight()
    local useSplitButtons = CleanUI_getTransferButtonLayout() == "2"
    local y = (titleBarHeight - self.titleButtonSize) / 2
    local x = self.transferAllButton:getX() - self.padding
    local leftMostX = self.transferButton and self.transferButton:getX() or x

    local function placeButton(btn, visible)
        if not btn then return end
        btn:setVisible(visible)
        if visible then
            x = x - btn.width
            btn:setX(x)
            btn:setY(y)
            leftMostX = x
            x = x - self.padding
        else
            ISInventoryPageTransferHandler.clearQuickButtonHighlight(self, btn)
            -- Hide any tooltip that was opened before the button became invisible.
            if btn.tooltipUI and btn.tooltipUI:getIsVisible() then
                btn.tooltipUI:setVisible(false)
                btn.tooltipUI:removeFromUIManager()
            end
        end
    end

    if not useSplitButtons then
        if self.transferButton then
            self.transferButton:setVisible(true)
            self.transferButton:setX(x - self.transferButton.width)
            self.transferButton:setY(y)
            leftMostX = self.transferButton:getX()
        end
        placeButton(self.moveToFloorButton, false)
        placeButton(self.transferByCategoryButton, false)
        placeButton(self.transferByNameButton, false)
        placeButton(self.transferMethodButton, false)
    else
        if self.transferButton then
            self.transferButton:setVisible(false)
        end
        placeButton(self.moveToFloorButton, (not self.onCharacter) and CleanUI_isMoveToFloorButtonAvailable(self))
        placeButton(self.transferByCategoryButton, true)
        placeButton(self.transferByNameButton, true)
        placeButton(self.transferMethodButton, true)
    end

    self.cleanUITransferButtonsLeftX = leftMostX
end

function ISInventoryPage:onTransferMethodToggleClick()
    CleanUI_toggleTransferMethod()
    self:cleanUIClearQuickTransferHighlights()
end

function ISInventoryPage:onTransferByNameClick()
    self:cleanUIClearQuickTransferHighlights()
    ISInventoryPageTransferHandler.transferSameType(self)
end

function ISInventoryPage:onTransferByCategoryClick()
    self:cleanUIClearQuickTransferHighlights()
    ISInventoryPageTransferHandler.transferSameCategory(self)
end

function ISInventoryPage:onMoveToFloorClick()
    self:cleanUIClearQuickTransferHighlights()
    ISInventoryPageTransferHandler.moveToFloor(self)
end

function ISInventoryPage:cleanUIClearQuickTransferHighlights()
    -- Clear all hover highlights before executing a quick transfer action.
    ISInventoryPageTransferHandler.clearQuickButtonHighlight(self, self.transferByNameButton)
    ISInventoryPageTransferHandler.clearQuickButtonHighlight(self, self.transferByCategoryButton)
    ISInventoryPageTransferHandler.clearQuickButtonHighlight(self, self.moveToFloorButton)
end


function ISInventoryPage:toggleLock()
    if CleanUIConfig and CleanUIConfig.updateConfig then
        local config = CleanUIConfig.getConfig()
        local configKey = self.onCharacter and "lockInventoryWindow" or "lockLootWindow"
        local currentLock = config[configKey] or false
        CleanUIConfig.updateConfig(configKey, not currentLock)
        self:setPagelocked()
    end
end

function ISInventoryPage:setPagelocked()
    local config = CleanUIConfig.getConfig()
    local configKey = self.onCharacter and "lockInventoryWindow" or "lockLootWindow"
    local isLocked = config[configKey] or false

    if self.resizeWidget then
        self.resizeWidget:setVisible(not isLocked)
    end
end

function ISInventoryPage:isPagelocked()
    local config = CleanUIConfig.getConfig()
    local configKey = self.onCharacter and "lockInventoryWindow" or "lockLootWindow"
    return config[configKey] or false
end

function ISInventoryPage:toggleStove()
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return
	end

	local object = self.inventoryPane.inventory:getParent()
	if not object then return end
	local className = object:getObjectName()
	TurnOnOff[className].toggle(object)
end

function ISInventoryPage:syncAddFuel()
	if self.onCharacter then return end
	local isVisible = self.addFuel:getIsVisible()
	self.addFuel:setTitle(getText("ContextMenu_DestroyForFuel"))
	local shouldBeVisible = false
	local fireTile = nil
	local campfire = nil
    local playerObj = getSpecificPlayer(self.player)
	if self.inventoryPane.inventory and self.inventoryPane.inventory:getParent() then
		fireTile = self.inventoryPane.inventory:getParent()
		campfire = CCampfireSystem.instance:getLuaObjectOnSquare(fireTile:getSquare())
		if campfire then
			shouldBeVisible = true

        elseif fireTile and fireTile:isFireInteractionObject() and (not fireTile:isPropaneBBQ()) then
			shouldBeVisible = true

		end
	end
	local containerButton
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible then
		self.addFuel:setVisible(shouldBeVisible)
	end
end

function ISInventoryPage:syncPutOut()
	if self.onCharacter then return end
	local isVisible = self.putOut:getIsVisible()
	local shouldBeVisible = false
	local fireTile = nil
	local campfire = nil
    local playerObj = getSpecificPlayer(self.player)
	if self.inventoryPane.inventory and self.inventoryPane.inventory:getParent() then
		fireTile = self.inventoryPane.inventory:getParent()
		campfire = CCampfireSystem.instance:getLuaObjectOnSquare(fireTile:getSquare())
		if campfire and campfire.isLit then
			shouldBeVisible = true
		    self.lightFire:setVisible(false)
        elseif fireTile and fireTile:isFireInteractionObject() and (not fireTile:isPropaneBBQ()) and fireTile:isLit() then
			shouldBeVisible = true
		    self.lightFire:setVisible(false)
		end
	end
	local containerButton
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible then
		self.putOut:setVisible(shouldBeVisible)
	end
end

function ISInventoryPage:syncLightFire()
	if self.onCharacter then return end
	local isVisible = self.lightFire:getIsVisible()
	local shouldBeVisible = false
	local fireTile = nil
	local campfire = nil
    local playerObj = getSpecificPlayer(self.player)
	local hasFuel
	if self.inventoryPane.inventory and self.inventoryPane.inventory:getParent() then
		fireTile = self.inventoryPane.inventory:getParent()
		campfire = CCampfireSystem.instance:getLuaObjectOnSquare(fireTile:getSquare())
		if campfire and not campfire.isLit then
			shouldBeVisible = true

        elseif fireTile and fireTile:isFireInteractionObject() and (not fireTile:isPropaneBBQ()) and (not fireTile:isLit()) then
			shouldBeVisible = true
		end
	end
	local containerButton
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible then
		self.lightFire:setVisible(shouldBeVisible)
	end
end

function ISInventoryPage:setInfo(text)
    self.infoText = text
end

function ISInventoryPage:onInfo()

end

function ISInventoryPage:collapse()
    if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
        return
    end
    self.pin = false
    self.collapseButton:setVisible(false)
    self.pinButton:setVisible(true)
    self.pinButton:bringToTop()
    self.inventoryPane:clearWorldObjectHighlights()
end

function ISInventoryPage:setPinned()
    self.pin = true
    self.collapseButton:setVisible(true)
    self.pinButton:setVisible(false)
    self.collapseButton:bringToTop()
end

function ISInventoryPage:isRemoveButtonVisible()
	if self.onCharacter then return false end
	if self.inventory:isEmpty() then return false end
	-- Build 42.12.3 (SP): Always allow trash can delete in singleplayer
	local obj = self.inventory:getParent()
	if not instanceof(obj, "IsoObject") then return false end
	local sprite = obj:getSprite()
	return sprite and sprite:getProperties() and sprite:getProperties():Is("IsTrashCan")
end

-- ----------------------------------------------------------------------------------------------------- --
-- Highlight Items
-- ----------------------------------------------------------------------------------------------------- --

-- Hack to give priority to another piece of code highlighting an object.
local ObjectsHighlightedElsewhere = {}
ObjectsHighlightedElsewhere[1] = {}
ObjectsHighlightedElsewhere[2] = {}
ObjectsHighlightedElsewhere[3] = {}
ObjectsHighlightedElsewhere[4] = {}
function ISInventoryPage.OnObjectHighlighted(playerNum, object, isHighlighted)
    ObjectsHighlightedElsewhere[playerNum+1][object] = isHighlighted or nil
    local pdata = getPlayerData(playerNum)
    if pdata then
        pdata.playerInventory:updateContainerHighlight()
        pdata.lootInventory:updateContainerHighlight()
    end
end

function ISInventoryPage:getContainerParent(container)
    if not container then return nil end
    if container:getParent() then return container:getParent() end
    local item = container:getContainingItem()
    if item and item:getWorldItem() then
        return item:getWorldItem()
    end
    return nil
end

function ISInventoryPage:updateContainerHighlight()
    local coloredObj = self:getContainerParent(self.coloredInv)
    if coloredObj and ((self.inventory ~= self.coloredInv) or self.isCollapsed) then
        if ObjectsHighlightedElsewhere[self.player+1][coloredObj] then
            -- Another piece of code is highlighting this object, don't change it.
        elseif coloredObj then
            coloredObj:setHighlighted(self.player, false)
            coloredObj:setOutlineHighlight(self.player, false)
            coloredObj:setOutlineHlAttached(self.player, false)
        end
        self.coloredInv = nil
    end

    coloredObj = self:getContainerParent(self.inventory)
    if ObjectsHighlightedElsewhere[self.player+1][coloredObj] then
        -- Another piece of code is highlighting this object, don't change it.
    elseif not self.isCollapsed then
--        print(self.inventory:getParent())
        if coloredObj and ((not instanceof(coloredObj, "IsoPlayer")) or instanceof(coloredObj, "IsoDeadBody")) then
            coloredObj:setHighlighted(self.player, true, false)
            if getCore():getOptionDoContainerOutline() then
                coloredObj:setOutlineHighlight(self.player, true)
                coloredObj:setOutlineHlAttached(self.player, true)
                coloredObj:setOutlineHighlightCol(self.player, getCore():getObjectHighlitedColor():getR(), getCore():getObjectHighlitedColor():getG(), getCore():getObjectHighlitedColor():getB(), 1)
            end
            coloredObj:setHighlightColor(self.player, getCore():getObjectHighlitedColor())
            self.coloredInv = self.inventory
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:update()
    local playerObj = getSpecificPlayer(self.player)
    if self.inventory:getEffectiveCapacity(playerObj) ~= self.capacity then
        self.capacity = self.inventory:getEffectiveCapacity(playerObj)
    end

    self:updateContainerHighlight()

    if (ISMouseDrag.dragging ~= nil and #ISMouseDrag.dragging > 0) or self.pin then
        self.collapseCounter = 0
        -- Build 42.12.3 (SP): No sync needed in singleplayer
        self.isCollapsed = false
        self:clearMaxDrawHeight()
        self.collapseCounter = 0
    end

    if not self.onCharacter then
        local playerObj = getSpecificPlayer(self.player)
        if self.lastDir ~= playerObj:getDir() then
            self.lastDir = playerObj:getDir()
            self:refreshBackpacks()
        elseif self.lastSquare ~= playerObj:getCurrentSquare() then
            self.lastSquare = playerObj:getCurrentSquare()
            self:refreshBackpacks()
        end

        -- If the currently-selected container is locked to the player, select another container.
        local object = self.inventory and self.inventory:getParent() or nil
        if #self.backpacks > 1 and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
            local currentIndex = self:getCurrentBackpackIndex()
            local unlockedIndex = self:prevUnlockedContainer(currentIndex, false)
            if unlockedIndex == -1 then
                unlockedIndex = self:nextUnlockedContainer(currentIndex, false)
            end
            if unlockedIndex ~= -1 then
                if playerObj:getJoypadBind() ~= -1 then
                    self.backpackChoice = unlockedIndex
                end
                self:selectContainer(self.backpacks[unlockedIndex])
            end
        end
    end

    if self.controlsUI then
        self.controlsUI:arrange()
        self.inventoryPane:setHeight(self.height - self.inventoryPane.y)
        self.inventoryPane:setY(self:titleBarHeight() + self.controlsUI.height)
    end

	self:updateContainerOpenCloseSounds()
end

function ISInventoryPage:close()
	ISPanel.close(self)
	if JoypadState.players[self.player+1] then
		setJoypadFocus(self.player, nil)
		local playerObj = getSpecificPlayer(self.player)
		playerObj:setBannedAttacking(false)
	end
    self.inventoryPane:clearWorldObjectHighlights()
    if self:playContainerCloseSound(self.inventoryPane.inventory) then
        self.selectedContainerForSound = nil
    else
        getSoundManager():playUISound("UIActivateButton")
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- JoyPad Handle
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:onLoseJoypadFocus(joypadData)
    ISPanel.onLoseJoypadFocus(self, joypadData)

    self.inventoryPane.doController = false
    local inv = getPlayerInventory(self.player)
	if not inv then
        return
    end
    local loot = getPlayerLoot(self.player)
    if inv.joyfocus or loot.joyfocus then
        return
    end

    if getFocusForPlayer(self.player) == nil then
        inv:setVisible(false)
        loot:setVisible(false)
        local playerObj = getSpecificPlayer(self.player)
        playerObj:setBannedAttacking(false)
        if playerObj:getVehicle() and playerObj:getVehicle():isDriver(playerObj) then
            getPlayerVehicleDashboard(self.player):addToUIManager()
        end
    end

end

function ISInventoryPage:onGainJoypadFocus(joypadData)
    ISPanel.onGainJoypadFocus(self, joypadData)

    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)
    inv:setVisible(true)
    loot:setVisible(true)
    getPlayerVehicleDashboard(self.player):removeFromUIManager()
    self.inventoryPane.doController = true
end

function ISInventoryPage:getCurrentBackpackIndex()
    for index,backpack in ipairs(self.backpacks) do
        if backpack.inventory == self.inventory then
            return index
        end
    end
    return -1
end

function ISInventoryPage:prevUnlockedContainer(index, wrap)
    local playerObj = getSpecificPlayer(self.player)
    for i=index-1,1,-1 do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
            return i
        end
    end
    return wrap and self:prevUnlockedContainer(#self.backpacks + 1, false) or -1
end

function ISInventoryPage:nextUnlockedContainer(index, wrap)
    if index < 0 then -- User clicked a container that isn't displayed
        return wrap and self:nextUnlockedContainer(0, false) or -1
    end
    local playerObj = getSpecificPlayer(self.player)
    for i=index+1,#self.backpacks do
        local backpack = self.backpacks[i]
        local object = backpack.inventory:getParent()
        if not (instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj)) then
            return i
        end
    end
    return wrap and self:nextUnlockedContainer(0, false) or -1
end

function ISInventoryPage:selectPrevContainer()
    local currentIndex = self:getCurrentBackpackIndex()
    local unlockedIndex = self:prevUnlockedContainer(currentIndex, true)
    if unlockedIndex == -1 then
        return
    end
    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:getJoypadBind() ~= -1 then
        self.backpackChoice = unlockedIndex
    end
    self:selectContainer(self.backpacks[unlockedIndex])
end

function ISInventoryPage:selectNextContainer()
    local currentIndex = self:getCurrentBackpackIndex()
    local unlockedIndex = self:nextUnlockedContainer(currentIndex, true)
    if unlockedIndex == -1 then
        return
    end
    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:getJoypadBind() ~= -1 then
        self.backpackChoice = unlockedIndex
    end
    self:selectContainer(self.backpacks[unlockedIndex])
end

function ISInventoryPage:onJoypadDown(button)
    ISContextMenu.globalPlayerContext = self.player
    local playerObj = getSpecificPlayer(self.player)
    
    if button == Joypad.AButton then
        self.inventoryPane:doContextOnJoypadSelected()
    end

    if button == Joypad.BButton then
        if isPlayerDoingActionThatCanBeCancelled(playerObj) then
            stopDoingActionThatCanBeCancelled(playerObj)
            return
        end
        self.inventoryPane:doJoypadExpandCollapse()
    end
    if button == Joypad.XButton and not JoypadState.disableGrab then
        self.inventoryPane:doGrabOnJoypadSelected()
    end
    if button == Joypad.YButton and not JoypadState.disableYInventory then
        setJoypadFocus(self.player, nil)
    end

    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if getCore():getGameMode() == "Tutorial" then shoulderSwitch = 1 end
    if button == Joypad.LBumper then
        if shoulderSwitch == 1 then
            getPlayerInventory(self.player):selectNextContainer()
        elseif shoulderSwitch == 2 then
            self:selectPrevContainer()
        elseif shoulderSwitch == 3 then
            setJoypadFocus(self.player, getPlayerInventory(self.player))
        end
    end
    if button == Joypad.RBumper then
        if shoulderSwitch == 1 then
            getPlayerLoot(self.player):selectNextContainer()
        elseif shoulderSwitch == 2 then
            self:selectNextContainer()
        elseif shoulderSwitch == 3 then
            setJoypadFocus(self.player, getPlayerLoot(self.player))
        end
    end
end

function ISInventoryPage:onJoypadDirUp(joypadData)
    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if shoulderSwitch == 3 then
        if isJoypadPressed(joypadData.id, Joypad.LBumper) then
            getPlayerInventory(self.player):selectPrevContainer()
            return
        end
        if isJoypadPressed(joypadData.id, Joypad.RBumper) then
            getPlayerLoot(self.player):selectPrevContainer()
            return
        end
    end
    self.inventoryPane.joyselection = self.inventoryPane.joyselection - 1
    self:ensureVisible(self.inventoryPane.joyselection + 1)
end

function ISInventoryPage:onJoypadDirDown(joypadData)
    local shoulderSwitch = getCore():getOptionShoulderButtonContainerSwitch()
    if shoulderSwitch == 3 then
        if isJoypadPressed(joypadData.id, Joypad.LBumper) then
            getPlayerInventory(self.player):selectNextContainer()
            return
        end
        if isJoypadPressed(joypadData.id, Joypad.RBumper) then
            getPlayerLoot(self.player):selectNextContainer()
            return
        end
    end
    self.inventoryPane.joyselection = self.inventoryPane.joyselection + 1
    self:ensureVisible(self.inventoryPane.joyselection + 1)
end

function ISInventoryPage:ensureVisible(index)
	local lb = self.inventoryPane
	-- Wrap index same as ISInventoryPane:renderdetails does
    if index < 1 then index = #lb.items end
    if index > #lb.items then index = 1 end
    local headerHgt = 17
    local y = headerHgt + lb.itemHgt * (index - 1)
    local height = lb.itemHgt
	if y < 0-lb:getYScroll() + headerHgt then
		lb:setYScroll(0 - y + headerHgt)
	elseif y + height > 0 - lb:getYScroll() + (lb.height - headerHgt) then
		lb:setYScroll(0 - (y + height - lb.height))
	end
end

function ISInventoryPage:onJoypadDirLeft()
    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)

    if self == loot then
        setJoypadFocus(self.player, inv)
    elseif self == inv then
        setJoypadFocus(self.player, loot)
    end
end

function ISInventoryPage:onJoypadDirRight()
    local inv = getPlayerInventory(self.player)
    local loot = getPlayerLoot(self.player)

    if self == loot then
        setJoypadFocus(self.player, inv)
    elseif self == inv then
        setJoypadFocus(self.player, loot)
    end
end

function ISInventoryPage.loadWeight(inv)
    if inv == nil then return 0 end

	return inv:getCapacityWeight()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Handle
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPage:onMouseMove(dx, dy)
	self.mouseOver = true

    if self.moving and self:isPagelocked() then
        self.moving = false
        return
    end
    
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end

    if not isGamePaused() then
        if self.isCollapsed and self.player and getSpecificPlayer(self.player) and getSpecificPlayer(self.player):isAiming() then
            return
        end
    end

    if self.isCollapsed and isKeyDown("PanCamera") then
        return
    end

    if not isMouseButtonDown(0) and not isMouseButtonDown(1) and not isMouseButtonDown(2) then

        self.collapseCounter = 0
        if self.isCollapsed and self:getMouseY() < self:titleBarHeight() then
           self.isCollapsed = false
		   	if isClient() and not self.onCharacter then
				self.inventoryPane.inventory:requestSync()
			end
           self:clearMaxDrawHeight()
           self.collapseCounter = 0
        end
    end
end

function ISInventoryPage:onMouseMoveOutside(dx, dy)
	self.mouseOver = false

    if self.moving and self:isPagelocked() then
        self.moving = false
        self:setCapture(false)
        return
    end
    
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end

    if ISMouseDrag.dragging ~= true and not self.pin and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) then
        self.collapseCounter = self.collapseCounter + getGameTime():getMultiplier() / getGameTime():getTrueMultiplier() / 0.8
        local bDo = false
        if ISMouseDrag.dragging == nil then
            bDo = true
        else
            for i, k in ipairs(ISMouseDrag.dragging) do
               bDo = true
               break
            end
        end
        local playerObj = getSpecificPlayer(self.player)
        if playerObj and playerObj:isAiming() then
            self.collapseCounter = 1000
        end
        if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
            bDo = false
        end
        if self.collapseCounter > 120 and not self.isCollapsed and bDo then
            self:collapseNow()
        end
    end
end

function ISInventoryPage:onMouseUp(x, y)
	if not self:getIsVisible() then
		return
	end

	self.moving = false
	self:setCapture(false)
end

function ISInventoryPage:onMouseDown(x, y)

	if not self:getIsVisible() then return end

    if self:isPagelocked() then return end

	getSpecificPlayer(self.player):nullifyAiming()

	self.downX = self:getMouseX()
	self.downY = self:getMouseY()
	self.moving = true
	self:setCapture(true)
end

function ISInventoryPage:onRightMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self:collapseNow()
    end
end
function ISInventoryPage:onMouseDownOutside(x, y)
    if((self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and  not self.pin) then
        self:collapseNow()
    end
end

function ISInventoryPage:onMouseUpOutside(x, y)
	if not self:getIsVisible() then
		return
	end

--	ISMouseDrag = {}
	self.moving = false
	self:setCapture(false)
end

function ISInventoryPage:isCycleContainerKeyDown()
	local keyName = getCore():getOptionCycleContainerKey()
	if keyName == "control" then
		return isCtrlKeyDown()
	end
	if keyName == "shift" then
		return isShiftKeyDown()
	end
	if keyName == "control+shift" then
		return isCtrlKeyDown() and isShiftKeyDown()
	end
	if keyName == "command" then
		return isMetaKeyDown()
	end
	if keyName == "command+shift" then
		return isMetaKeyDown() and isShiftKeyDown()
	end
	error "unknown cycle container key"
end

function ISInventoryPage:onMouseWheel(del)
    local inContainerArea = false
    if self:isPageLeft() then
        inContainerArea = self:getMouseX() < self.containerButtonPanel.width
    else
        inContainerArea = self:getMouseX() >= (self:getWidth() - self.containerButtonPanel.width)
    end

    if not inContainerArea and not self:isCycleContainerKeyDown() then
        return false
    end

	local currentIndex = self:getCurrentBackpackIndex()
	local unlockedIndex = -1

    -- When the container buttons aren't all visible, don't wrap scrolling when rapidly using the mousewheel.
	local ms = getTimestampMs()
	self.lastMouseWheelMS = self.lastMouseWheelMS or 0
	local wrap = (self.containerButtonPanel.height > self.containerButtonPanel:getScrollHeight()) or (ms - self.lastMouseWheelMS > 750)
	self.lastMouseWheelMS = ms

	if del < 0 then
		unlockedIndex = self:prevUnlockedContainer(currentIndex, wrap)
	else
		unlockedIndex = self:nextUnlockedContainer(currentIndex, wrap)
	end
	if unlockedIndex ~= -1 then
		local playerObj = getSpecificPlayer(self.player)
		if playerObj and playerObj:getJoypadBind() ~= -1 then
			self.backpackChoice = unlockedIndex
		end
		self:selectContainer(self.backpacks[unlockedIndex])
	end
	return true
end

ISInventoryPage.dirtyUI = function ()
   -- ISInventoryPage.playerInventory.inventoryPane:refreshContainer()
	for i=0, getNumActivePlayers() -1 do
		local pdata = getPlayerData(i)
		if pdata and pdata.playerInventory then
			pdata.playerInventory:refreshBackpacks()
			pdata.lootInventory:refreshBackpacks()
		end
	end
end

function ISInventoryPage:checkExplored(container, playerObj)
	if container:isExplored() then
		return
	end
	if isClient() then
		container:requestServerItemsForContainer()
	else
		ItemPicker.fillContainer(container, playerObj)
	end
	container:setExplored(true)
	if playerObj and playerObj:isLocalPlayer() then
		playerObj:triggerMusicIntensityEvent("SearchNewContainer")
	end
end

ISInventoryPage.onRenameContainer = function(container, player)
    local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or container:getType()
    if container:getCustomName() then title = container:getCustomName() end
    local modal = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_NameThisContainer"), title, nil, ISInventoryPage.onRenameContainerClick, player, getSpecificPlayer(player), container)
    modal:initialise()
    modal:addToUIManager()
    if JoypadState.players[player+1] then
        setJoypadFocus(player, modal)
    end
end

function ISInventoryPage:onRenameContainerClick(button, player, container)
    local playerNum = player:getPlayerNum()
    if button.internal == "OK" then
		local length = button.parent.entry:getInternalText():len()
        if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then
			if length <= MAXIMUM_RENAME_LENGTH then
                print("OKAY! " .. button.parent.entry:getText())
				container:setCustomName(button.parent.entry:getText())
				local pdata = getPlayerData(playerNum)
				pdata.playerInventory:refreshBackpacks()
				pdata.lootInventory:refreshBackpacks()
			else
				-- player:Say(getText("IGUI_PlayerText_ItemNameTooLong", MAXIMUM_RENAME_LENGTH))
				HaloTextHelper.addBadText(player, getText("IGUI_PlayerText_ItemNameTooLong", MAXIMUM_RENAME_LENGTH))
-- 				HaloTextHelper.addText(player, getText("IGUI_PlayerText_ItemNameTooLong", MAXIMUM_RENAME_LENGTH), getCore():getGoodHighlitedColor())
			end
        end
    end
    if JoypadState.players[playerNum+1] then
        setJoypadFocus(playerNum, getPlayerInventory(playerNum))
    end
end



function ISInventoryPage:onMouseOverButton(button,x,y)
	self.mouseOverButton = button
end

function ISInventoryPage:onMouseOutButton(button,x,y)
	self.mouseOverButton = nil
end

function ISInventoryPage:RestoreLayout(name, layout)
    if getJoypadData(self.player) then return end
    ISLayoutManager.DefaultRestoreWindow(self, layout)
    if layout.pin == 'true' then
        self:setPinned()
    end
    self.inventoryPane:RestoreLayout(name, layout)
end

function ISInventoryPage:SaveLayout(name, layout)
    if getJoypadData(self.player) then return end
    ISLayoutManager.DefaultSaveWindow(self, layout)
    if self.pin then layout.pin = 'true' else layout.pin = 'false' end
    self.inventoryPane:SaveLayout(name, layout)
end

ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible())
        getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible())
    end
end

ISInventoryPage.toggleInventory = function()
	if ISInventoryPage.playerInventory:getIsVisible() then
		ISInventoryPage.playerInventory:setVisible(false)
	else
		ISInventoryPage.playerInventory:setVisible(true)
	end
end

-- ----------------------------------------------------------------------------------------------------- --
-- InventoryContainerPanel
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPage.GetFloorContainer(playerNum)
	if ISInventoryPage.floorContainer == nil then
		ISInventoryPage.floorContainer = {}
	end
	if ISInventoryPage.floorContainer[playerNum+1] == nil then
		ISInventoryPage.floorContainer[playerNum+1] = ItemContainer.new("floor", nil, nil)
		ISInventoryPage.floorContainer[playerNum+1]:setExplored(true)
	end
	return ISInventoryPage.floorContainer[playerNum+1]
end
function ISInventoryPage:setForceSelectedContainer(container, ms)
	self.forceSelectedContainer = container
	self.forceSelectedContainerTime = getTimestampMs() + (ms or 1000)
end

function ISInventoryPage:dropItemsInContainer(button)
	if self.player ~= 0 then return false end
	if ISMouseDrag.dragging == nil then return false end
	local playerObj = getSpecificPlayer(self.player)
	if (getCore():getGameMode() ~= "Tutorial") and self:canPutIn() then
		local doWalk = true
		local items = {}
		local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
		for i,v in ipairs(dragging) do
			local transfer = v:getContainer() and not button.inventory:isInside(v)
			if v:isFavorite() and not button.inventory:isInCharacterInventory(playerObj) then
				transfer = false
			end
			if not button.inventory:isItemAllowed(v) then
				transfer = false
			end
			if transfer then
				-- only walk for the first item
				if doWalk then
					if not luautils.walkToContainer(button.inventory, self.player) then
						break
					end
					doWalk = false
				end
				table.insert(items, v)
			end
		end
		self.inventoryPane:transferItemsByWeight(items, button.inventory)
		self.inventoryPane.selected = {}
		getPlayerLoot(self.player).inventoryPane.selected = {}
		getPlayerInventory(self.player).inventoryPane.selected = {}
	end
	if ISMouseDrag.draggingFocus then
		ISMouseDrag.draggingFocus:onMouseUp(0,0)
		ISMouseDrag.draggingFocus = nil
		ISMouseDrag.dragging = nil
	end
	self:refreshWeight()
    self:updateItemCount()
	return true
end

function ISInventoryPage:playContainerOpenCloseSounds(button)
    if button.inventory ~= self.inventoryPane.lastinventory then
        if button.inventory:getOpenSound() then
            if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
                local eventInstance = getSpecificPlayer(self.player):playSound(button.inventory:getOpenSound())
                if eventInstance ~= 0 then
                    ISInventoryPage.bagSoundTime = getTimestamp()
                    self.selectedContainerForSound = button.inventory
                end
            end
        end

        if not button.inventory:getOpenSound() and self.inventoryPane.lastinventory:getCloseSound() then
            if ISInventoryPage.bagSoundTime + ISInventoryPage.bagSoundDelay < getTimestamp() then
                ISInventoryPage.bagSoundTime = getTimestamp()
                local eventInstance = getSpecificPlayer(self.player):playSound(self.inventoryPane.lastinventory:getCloseSound())
                if eventInstance ~= 0 then
                    ISInventoryPage.bagSoundTime = getTimestamp()
                    self.selectedContainerForSound = button.inventory
                end
            end
        end
    end
end
function ISInventoryPage:playContainerOpenSound(container)
    if not container then return end
    if self.onCharacter then return false end
    if isGamePaused() then return false end
    if not container:getOpenSound() then return false end
    getSoundManager():playUISound(container:getOpenSound())
    return true
end

function ISInventoryPage:playContainerCloseSound(container)
    if not container then return end
    if self.onCharacter then return false end
    if isGamePaused() then return false end
    if not container:getCloseSound() then return false end
    getSoundManager():playUISound(container:getCloseSound())
    return true
end

-- NOTE: This expects to be called from update() when the window isn't visible, to play getCloseSound()
-- when the window collapses.
function ISInventoryPage:updateContainerOpenCloseSounds()
    if self.onCharacter then return end
    if isGamePaused() then return end
    if self:isReallyVisible() and not self.isCollapsed then
        if not self.selectedContainerForSound then
            self:playContainerOpenSound(self.inventoryPane.inventory)
        end
        self.selectedContainerForSound = self.inventoryPane.inventory
    else
        if self.selectedContainerForSound then
            self:playContainerCloseSound(self.selectedContainerForSound)
            self.selectedContainerForSound = nil
        end
    end
end

function ISInventoryPage:selectContainer(button)
	local playerObj = getSpecificPlayer(self.player)

    if button.inventory ~= self.inventoryPane.lastinventory then
        local object = button.inventory and button.inventory:getParent() or nil
        if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
            return
        end
        self:playContainerOpenCloseSounds(button)
    end

    self.inventoryPane.lastinventory = button.inventory
    self.inventoryPane.inventory = button.inventory
    self.inventoryPane.selected = {}
    if not button.inventory:isExplored() then
        if not isClient() then
			ItemPicker.fillContainer(button.inventory, playerObj)
        else
            button.inventory:requestServerItemsForContainer()
        end
        button.inventory:setExplored(true)
    end

	self.title = button.name

	self.capacity = button.capacity

    self:refreshBackpacks()
end

function ISInventoryPage:setNewContainer(inventory)
    self.inventoryPane.inventory = inventory
    self.inventory = inventory
    self.inventoryPane:refreshContainer()

    local playerObj = getSpecificPlayer(self.player)
    self.capacity = inventory:getEffectiveCapacity(playerObj)

    -- highlight the container if it is in the list
	for i,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == inventory then
			self.title = containerButton.name
            self:playContainerOpenCloseSounds(containerButton)
            self.inventoryPane.lastinventory = inventory
		end
	end

end

function ISInventoryPage:selectButtonForContainer(container)
	if self.inventoryPane.inventory == container then
		return
	end
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == container then
            local playerObj = getSpecificPlayer(self.player)
            local object = container and container:getParent() or nil
            if instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
                return
            end
			if playerObj and playerObj:getJoypadBind() ~= -1 then
				self.backpackChoice = index
			end
			self:selectContainer(containerButton)
			return
		end
	end
end

function ISInventoryPage:onBackpackMouseDown(button, x, y)
	ISMouseDrag = {}
	if not isKeyDown("Melee") then
	    getSpecificPlayer(self.player):nullifyAiming()
    end
end

function ISInventoryPage:onBackpackClick(button)
	local playerObj = getSpecificPlayer(self.player)
	if playerObj and playerObj:getJoypadBind() ~= -1 then
		for i,button2 in ipairs(self.backpacks) do
			if button2 == button then
				self.backpackChoice = index
				break
			end
		end
	end
	self:selectContainer(button)
end

function ISInventoryPage:onBackpackMouseUp(x, y)
	if not self.pressed and not ISMouseDrag.dragging then return end
	ISButton.onMouseUp(self, x, y)
	local page = self.parent.parent
	if page:dropItemsInContainer(self) then return end
	page:onBackpackClick(self)
end

function ISInventoryPage:onBackpackRightMouseDown(x, y)
	local page = self.parent.parent
	local container = self.inventory
	if not container then return end

    -- Cache container metadata once so virtual/stale containers cannot break the context menu.
    local parent = container:getParent()
    local containerType = container:getType()
    local isCharacterOrFloorContainer = containerType == "inventorymale" or containerType == "inventoryfemale" or containerType == "floor"
    local hasWorldObjectParent = parent and not instanceof(parent, "BaseVehicle") and not isCharacterOrFloorContainer
    local parentSquare = nil
    if hasWorldObjectParent then
        -- Some MP/virtual containers may not have a valid world object parent square.
        local ok, square = pcall(function()
            return parent:getSquare()
        end)
        if ok then
            parentSquare = square
        end
    end

	local item = container:getContainingItem()
	local context = ISContextMenu.get(page.player, getMouseX(), getMouseY())
	if item then
		context = ISInventoryPaneContextMenu.createMenu(page.player, page.onCharacter, {item}, getMouseX(), getMouseY())
		if context and context.numOptions > 1 and JoypadState.players[page.player+1] then
			context.origin = page
			context.mouseOver = 1
			setJoypadFocus(page.player, context)
		end
		return
    elseif hasWorldObjectParent then
        if parentSquare and SafeHouse.isSafehouseAllowInteract(parentSquare, getSpecificPlayer(page.player)) then
            context:addOption(getText("ContextMenu_RenameBag"), container, ISInventoryPage.onRenameContainer, page.player)
            if not ISLootZed.cheat and not isAdmin() then return end
        end
	end
    if ISLootZed.cheat or isAdmin() then
        local playerObj = getSpecificPlayer(page.player)
        if hasWorldObjectParent then
            context:addOption("Refill container", container, function(container)
                if container:getSourceGrid() then
                    if isClient() then
                        local items = container:getItems()
                        local tItems = {}
                        for i = items:size()-1, 0, -1 do
                            table.insert(tItems, items:get(i))
                        end

                        for i, v in ipairs(tItems) do
                            ISRemoveItemTool.removeItem(v, page.player)
                        end

                        local sq = container:getSourceGrid()
                        local currentParent = container:getParent()
                        if not currentParent then return end

                        local cIndex = -1
                        for i = 0, currentParent:getContainerCount()-1 do
                            if currentParent:getContainerByIndex(i) == container then
                                cIndex = i
                            end
                        end
                        local args = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = currentParent:getObjectIndex(), containerIndex = cIndex }
                        sendClientCommand(playerObj, 'object', 'clearContainerExplore', args)
                        container:removeItemsFromProcessItems()
                        container:clear()
                        container:requestServerItemsForContainer()
                        container:setExplored(true)
                        sendClientCommand(playerObj, 'object', 'updateOverlaySprite', args)
                    else
                        if container:getSourceGrid():getRoom() and container:getSourceGrid():getRoom():getRoomDef() and container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer() then
                            container:getSourceGrid():getRoom():getRoomDef():getProceduralSpawnedContainer():clear()
                        end
                        container:removeItemsFromProcessItems()
                        container:clear()
                        ItemPicker.fillContainer(container, playerObj)
                        if container:getParent() then
                            ItemPicker.updateOverlaySprite(container:getParent())
                        end
                        container:setExplored(true)
                    end
                end
            end, playerObj)
        end
        if ISLootZed.cheat then
            context:addOption("Open LootZed", container, function(container, playerObj)
                LootZedTool.SpawnItemCheckerList = {}
                LootZedTool.fillContainer_CalcChances(container, playerObj)

                if ISLootZed.instance ~= nil then
                    ISLootZed.instance:updateContent()
                    ISLootZed.instance:setVisible(true);
                else
                    local ui = ISLootZed:new(750, 800, playerObj);
                    ui:initialise();
                    ui:addToUIManager();
                    ISLootZed.instance:updateContent()
                end
            end, playerObj)
        end
        return
    end
	if context:isReallyVisible() then
		if context and JoypadState.players[page.player+1] then
			context.origin = page
		end
		context:closeAll()
	end
end

local sqsContainers = {}
local sqsVehicles = {}
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    local titleBarHeight = self:titleBarHeight()
	local playerObj = getSpecificPlayer(self.player)
	local c = #self.backpacks + 1
	local x = (self.containerButtonPanelWidth - self.buttonSize) / 2
	local y = ((c - 1) * (self.buttonSize) + c * self.padding)
	local button
	if #self.buttonPool > 0 then
		button = table.remove(self.buttonPool, 1)
		button:setX(x)
		button:setY(y)
	else
		button = ISButton:new(x, y, self.buttonSize, self.buttonSize, "", self, ISInventoryPage.onBackpackClick, ISInventoryPage.onBackpackMouseDown, false)
		button.anchorLeft = false
		button.anchorTop = false
		button.anchorRight = true
		button.anchorBottom = false
		button:initialise()
        button.prerender = function(btn)
            ISButton.prerender(button)
            local brightness = button:isMouseOver() and 0.9 or 0.5
            button:drawTextureScaled(self.containerButtonTex.normal, 0, 0, btn.width, btn.height, 0.5, brightness, brightness, brightness)
            if button.inventory == self.inventory then
                button:drawTextureScaled(self.containerButtonTex.selected, 0, 0, btn.width, btn.height, 0.8, 0.8, 0.8, 0.8)
            end
        end
		button:forceImageSize(math.floor(self.buttonSize * 0.8 / 8) * 8,math.floor(self.buttonSize * 0.8 / 8) * 8)
	end
    button:setTextureRGBA(1.0, 1.0, 1.0, 1.0)
	button.textureOverride = nil
	button.inventory = container
	button.onclick = ISInventoryPage.onBackpackClick
	button.onmousedown = ISInventoryPage.onBackpackMouseDown
	button.onMouseUp = ISInventoryPage.onBackpackMouseUp
	button.onRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
	button:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
	button:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
	button:setSound("activate", nil)
	button.capacity = container:getEffectiveCapacity(playerObj)
    button:setDisplayBackground(false)
	if instanceof(texture, "Texture") then
		button:setImage(texture)
    else
		if ContainerButtonIcons[container:getType()] ~= nil then
			button:setImage(ContainerButtonIcons[container:getType()])
		else
			button:setImage(self.conDefault)
		end
	end
	button.name = name
	
    -- Tooltip: Capacity
    if tooltip then
        local playerObj = getSpecificPlayer(self.player)
        local currentWeight = round(container:getCapacityWeight(), 2)
        local maxCapacity = container:getEffectiveCapacity(playerObj)
        local tooltipText = tooltip
        if self.onCharacter then
            local containerItem = container:getContainingItem()
            if containerItem then
                local itemWeight = round(containerItem:getEquippedWeight(), 2)
                tooltipText = tooltipText .. "\n" .. getText("Tooltip_item_Weight") .." : " .. itemWeight
            end
        end
        tooltipText = tooltipText .. "\n" .. currentWeight .. " / " .. maxCapacity

        button.tooltip = tooltipText
    else
        button.tooltip = nil
    end
	
	self.containerButtonPanel:addChild(button)
	self.backpacks[c] = button
	return button
end

function ISInventoryPage:refreshBackpacks()
    ISHandCraftPanel.drawDirty = true
    ISBuildPanel.drawDirty = true

	self.buttonPool = self.buttonPool or {}
	for i,v in ipairs(self.backpacks) do
		self.containerButtonPanel:removeChild(v)
		table.insert(self.buttonPool, i, v)
	end

	local floorContainer = ISInventoryPage.GetFloorContainer(self.player)

	self.inventoryPane.lastinventory = self.inventoryPane.inventory

	self.inventoryPane:hideButtons()

	local oldNumBackpacks = #self.backpacks
	table.wipe(self.backpacks)

	local containerButton = nil

	local playerObj = getSpecificPlayer(self.player)

	triggerEvent("OnRefreshInventoryWindowContainers", self, "begin")

	if self.onCharacter then
		local name = getText("IGUI_InventoryTooltip")
		containerButton = self:addContainerButton(playerObj:getInventory(), self.invbasic, name, nil)
		containerButton.capacity = self.inventory:getMaxWeight()
		if not self.capacity then
			self.capacity = containerButton.capacity
		end
		local it = playerObj:getInventory():getItems()
		for i = 0, it:size()-1 do
			local item = it:get(i)
			if item:getCategory() == "Container" and playerObj:isEquipped(item) or item:getType() == "KeyRing"  or item:hasTag( "KeyRing") then
				-- found a container, so create a button for it...
				containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
				if(item:getVisual() and item:getClothingItem()) then
					local tint = item:getVisual():getTint(item:getClothingItem())
					containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
				end
			end
		end
	elseif playerObj:getVehicle() then
		local vehicle = playerObj:getVehicle()
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and CleanUI_canAccessVehicleContainer(vehicle, partIndex-1, playerObj, vehiclePart:getItemContainer()) and vehiclePart:getId() ~= "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
                -- changed to include tooltips outside of the player inventory because some people want it
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
-- 				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
				self:checkExplored(containerButton.inventory, playerObj)
                -- check for bags in seats/trunks
                if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                    local it = vehiclePart:getItemContainer():getItems()
                    for i = 0, it:size()-1 do
                        local item = it:get(i)
                        if item:getCategory() == "Container"  then
                            -- found a container, so create a button for it...
                            containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                            if(item:getVisual() and item:getClothingItem()) then
                                local tint = item:getVisual():getTint(item:getClothingItem())
                                containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                            end
                        end
                    end
                end
			end
	    end
		for partIndex=1,vehicle:getPartCount() do
			local vehiclePart = vehicle:getPartByIndex(partIndex-1)
			if vehiclePart:getItemContainer() and CleanUI_canAccessVehicleContainer(vehicle, partIndex-1, playerObj, vehiclePart:getItemContainer()) and vehiclePart:getId() == "TruckBed" then
				local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
				-- changed to include tooltips outside of the player inventory because it matters to some people
				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
-- 				containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
				self:checkExplored(containerButton.inventory, playerObj)
                -- check for bags in seats/trunks
                if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                    local it = vehiclePart:getItemContainer():getItems()
                    for i = 0, it:size()-1 do
                        local item = it:get(i)
                        if item:getCategory() == "Container"  then
                            -- found a container, so create a button for it...
                            containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                            if(item:getVisual() and item:getClothingItem()) then
                                local tint = item:getVisual():getTint(item:getClothingItem())
                                containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                            end
                        end
                    end
                end
			end
		end
	else
		local cx = playerObj:getX()
		local cy = playerObj:getY()
		local cz = playerObj:getZ()

		-- Do floor
		local container = floorContainer
		container:removeItemsFromProcessItems()
		container:clear()

		local sqs = sqsContainers
		table.wipe(sqs)

		local dir = playerObj:getDir()
		local lookSquare = nil
		if self.lookDir ~= dir then
			self.lookDir = dir
			local dx,dy = 0,0
			if dir == IsoDirections.NW or dir == IsoDirections.W or dir == IsoDirections.SW then
				dx = -1
			end
			if dir == IsoDirections.NE or dir == IsoDirections.E or dir == IsoDirections.SE then
				dx = 1
			end
			if dir == IsoDirections.NW or dir == IsoDirections.N or dir == IsoDirections.NE then
				dy = -1
			end
			if dir == IsoDirections.SW or dir == IsoDirections.S or dir == IsoDirections.SE then
				dy = 1
			end
			lookSquare = getCell():getGridSquare(cx + dx, cy + dy, cz)
		end

		local vehicleContainers = sqsVehicles
		table.wipe(vehicleContainers)

		for dy=-1,1 do
			for dx=-1,1 do
				local square = getCell():getGridSquare(cx + dx, cy + dy, cz)
				if square then
					table.insert(sqs, square)
				end
			end
		end

		for _,gs in ipairs(sqs) do
			-- stop grabbing thru walls...
			local currentSq = playerObj:getCurrentSquare()
			--if gs ~= currentSq and currentSq and currentSq:isBlockedTo(gs) then
            if gs ~= currentSq and currentSq and not currentSq:canReachTo(gs) then
				gs = nil
			end

            -- don't show containers in safehouse if you're not allowed
            if gs then
                if isClient() and not SafeHouse.isSafehouseAllowLoot(gs, playerObj) then
                    gs = nil
                end
            end

			if gs ~= nil then
				local numButtons = #self.backpacks

				local wobs = gs:getWorldObjects()
				for i = 0, wobs:size()-1 do
					local o = wobs:get(i)
					-- FIXME: An item can be in only one container in coop the item won't be displayed for every player.
					floorContainer:AddItem(o:getItem())
					if o:getItem() and o:getItem():getCategory() == "Container" then
						local item = o:getItem()
                        -- changed to include tooltips outside of the player inventory because some people want it
						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
-- 						containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), nil)
						if item:getVisual() and item:getClothingItem() then
							local tint = item:getVisual():getTint(item:getClothingItem())
							containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
						end
					end
				end

				local sobs = gs:getStaticMovingObjects()
				for i = 0, sobs:size()-1 do
					local so = sobs:get(i)
					if so:getContainer() ~= nil then
					    -- added console spam when there's a missing container name translation string
					    if getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) == nil and isDebugEnabled() then
					        print("Missing IGUI_ContainerTitle_ tranlastion string for " .. tostring(so:getContainer():getType()))
					    end

					    -- changed to just show the container type if there's no translation string to make it easier to add the needed string
						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or "!Needs IGUI_ContainerTitle defined for: " .. so:getContainer():getType()
-- 						local title = getTextOrNull("IGUI_ContainerTitle_" .. so:getContainer():getType()) or ""
                        -- changed to include tooltips outside of the player inventory because some people want it
                        if instanceof(so, "IsoDeadBody") and so:isAnimal() then
                            break
                        end
						containerButton = self:addContainerButton(so:getContainer(), nil, title, title)
-- 						containerButton = self:addContainerButton(so:getContainer(), nil, title, nil)
						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local obs = gs:getObjects()
				for i = 0, obs:size()-1 do
					local o = obs:get(i)
					for containerIndex = 1,o:getContainerCount() do
						local container = o:getContainerByIndex(containerIndex-1)
						-- added console spam when a container type doesn't have a translation string defined
					    if getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) == nil and isDebugEnabled() then
					        print("Missing IGUI_ContainerTitle_ translation string for " .. tostring(container:getType()))
					    end
					    -- changed to just show the container type if there's no translation string to make it easier to add the needed string
						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or "!Needs IGUI_ContainerTitle defined for: " .. container:getType()
						if container:getCustomName() then title = container:getCustomName() end
-- 						local title = getTextOrNull("IGUI_ContainerTitle_" .. container:getType()) or ""
                        -- changed to include tooltips outside of the player inventory because some people want it
						containerButton = self:addContainerButton(container, nil, title, title)
-- 						containerButton = self:addContainerButton(container, nil, title, nil)
						if instanceof(o, "IsoThumpable") and o:isLockedToCharacter(playerObj) then
							containerButton.onclick = nil
							containerButton.onmousedown = nil
							containerButton:setOnMouseOverFunction(nil)
							containerButton:setOnMouseOutFunction(nil)
							containerButton.textureOverride = getTexture("media/ui/lock.png")
						end

						if instanceof(o, "IsoThumpable") and o:isLockedByPadlock() and playerObj:getInventory():haveThisKeyId(o:getKeyId()) then
							containerButton.textureOverride = getTexture("media/ui/lockOpen.png")
						end

						self:checkExplored(containerButton.inventory, playerObj)
					end
				end

				local vehicle = gs:getVehicleContainer()
				if vehicle and not vehicleContainers[vehicle] then
					vehicleContainers[vehicle] = true
					for partIndex=1,vehicle:getPartCount() do
						local vehiclePart = vehicle:getPartByIndex(partIndex-1)
						if vehiclePart:getItemContainer() and CleanUI_canAccessVehicleContainer(vehicle, partIndex-1, playerObj, vehiclePart:getItemContainer()) then
							local tooltip = getText("IGUI_VehiclePart" .. vehiclePart:getItemContainer():getType())
                            -- changed to include tooltips outside of the player inventory because some people want it
							containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, tooltip)
-- 							containerButton = self:addContainerButton(vehiclePart:getItemContainer(), nil, tooltip, nil)
							self:checkExplored(containerButton.inventory, playerObj)
							-- check for bags in seats/trunks
                            if vehiclePart:getId() and vehiclePart:getId() ~= "GloveBox" then
                                local it = vehiclePart:getItemContainer():getItems()
                                for i = 0, it:size()-1 do
                                    local item = it:get(i)
                                    if item:getCategory() == "Container"  then
                                        -- found a container, so create a button for it...
                                        containerButton = self:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName())
                                        if(item:getVisual() and item:getClothingItem()) then
                                            local tint = item:getVisual():getTint(item:getClothingItem())
                                            containerButton:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                                        end
                                    end
                                end
                            end
						end
					end
				end

				if (numButtons < #self.backpacks) and (gs == lookSquare) then
					self.inventoryPane.inventory = self.backpacks[numButtons + 1].inventory
				end
			end
		end

		triggerEvent("OnRefreshInventoryWindowContainers", self, "beforeFloor")

		local title = getTextOrNull("IGUI_ContainerTitle_floor") or ""
		containerButton = self:addContainerButton(floorContainer, ContainerButtonIcons.floor, title, nil)
		containerButton.capacity = floorContainer:getMaxWeight()
	end

	triggerEvent("OnRefreshInventoryWindowContainers", self, "buttonsAdded")

	local found = false
	local foundIndex = -1
	for index,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventoryPane.inventory then
			foundIndex = index
			found = true
			break
		end
	end

	self.inventoryPane.inventory = self.inventoryPane.lastinventory
	self.inventory = self.inventoryPane.inventory
	if self.backpackChoice ~= nil and playerObj:getJoypadBind() ~= -1 then
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.backpackChoice = 1
		end
		if self.backpackChoice > #self.backpacks then
			self.backpackChoice = 1
		end
		if self.backpacks[self.backpackChoice] ~= nil then
			self.inventoryPane.inventory = self.backpacks[self.backpackChoice].inventory
			self.capacity = self.backpacks[self.backpackChoice].capacity
		end
	else
		if not self.onCharacter and oldNumBackpacks == 1 and #self.backpacks > 1 then
			self.inventoryPane.inventory = self.backpacks[1].inventory
			self.capacity = self.backpacks[1].capacity
		elseif found then
			self.inventoryPane.inventory = self.backpacks[foundIndex].inventory
			self.capacity = self.backpacks[foundIndex].capacity
		elseif not found and #self.backpacks > 0 then
			if self.backpacks[1] and self.backpacks[1].inventory then
				self.inventoryPane.inventory = self.backpacks[1].inventory
				self.capacity = self.backpacks[1].capacity
			end
		elseif self.inventoryPane.lastinventory ~= nil then
			self.inventoryPane.inventory = self.inventoryPane.lastinventory
		end
	end

	if self.forceSelectedContainer then
		if self.forceSelectedContainerTime > getTimestampMs() then
			for _,containerButton in ipairs(self.backpacks) do
				if containerButton.inventory == self.forceSelectedContainer then
					self.inventoryPane.inventory = containerButton.inventory
					self.capacity = containerButton.capacity
					break
				end
			end
		else
			self.forceSelectedContainer = nil
		end
	end

	self.inventoryPane:bringToTop()
	self.resizeWidget:bringToTop()

	self.inventory = self.inventoryPane.inventory

	self.title = nil
	for k,containerButton in ipairs(self.backpacks) do
		if containerButton.inventory == self.inventory then
            self.selectedButton = containerButton
			self.title = containerButton.name
		end
	end

	if self.inventoryPane ~= nil then
		self.inventoryPane:refreshContainer()
	end

	self:refreshWeight()

	self:updateItemCount()

    if self.controlsUI then
        self.controlsUI:arrange()
        self.inventoryPane:setHeight(self.height - self.inventoryPane.y)
        self.inventoryPane:setY(self:titleBarHeight() + self.controlsUI.height)
    end
    self.containerButtonPanel:setHeight(self.height - self:titleBarHeight())
    self.containerButtonPanel:setWidth(self.containerButtonPanelWidth)
    self.containerButtonPanel:setScrollHeight(self.backpacks[#self.backpacks]:getBottom() + self.padding)

	triggerEvent("OnRefreshInventoryWindowContainers", self, "end")
end

function ISInventoryPage:onInventoryContainerSizeChanged()
	local sizes = { 32, 40, 48 }
	local baseSize = sizes[getCore():getOptionInventoryContainerSize()]
	local scaleMultiplier = CleanUI_getContainerButtonScaleMultiplier()
	self.buttonSize = math.floor(baseSize * scaleMultiplier)
	self.containerButtonPanelWidth = math.floor(self.buttonSize * 1.2)
	self.minimumWidth = 256 + self.containerButtonPanelWidth
    self.inventoryPane:setX(self:isPageLeft() and self.containerButtonPanelWidth or 0)
	self.inventoryPane:setWidth(self.width - self.containerButtonPanelWidth)
	self.containerButtonPanel:setWidth(self.containerButtonPanelWidth)
    self.controlsUI:setX(self:isPageLeft() and self.containerButtonPanelWidth or 0)
    local buttonPanelX = self:isPageLeft() and 0 or (self.width - self.containerButtonPanelWidth)
	self.containerButtonPanel:setX(buttonPanelX)
	local buttonX = (self.containerButtonPanelWidth - self.buttonSize) / 2
	
	for _,button in ipairs(self.buttonPool) do
		button:setWidth(self.buttonSize)
		button:setHeight(self.buttonSize)
		button:forceImageSize(math.floor(self.buttonSize * 0.8 / 8) * 8,math.floor(self.buttonSize * 0.8 / 8) * 8)
	end
	local y = self.padding
	for _,button in ipairs(self.backpacks) do
		button:setX(buttonX)
		button:setY(y)
		y = y + self.buttonSize + self.padding
		button:setWidth(self.buttonSize)
		button:setHeight(self.buttonSize)
		button:forceImageSize(math.floor(self.buttonSize * 0.8 / 8) * 8,math.floor(self.buttonSize * 0.8 / 8) * 8)
	end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPage:prerender()

    local titleBarHeight = self:titleBarHeight()
    local height = self:getHeight()
    if self.isCollapsed then
        height = titleBarHeight
        local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/CUI_TitleBarBG_Collapsed.png")
        if titlebarbkg then
            titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), titleBarHeight, 0.6, 0.6, 0.6, 0.95)
        end
    end

    if not self.isCollapsed then
        -- TitleBar
        local titlebarbkg = NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/CUI_TitleBarBG.png")
        if titlebarbkg then
            titlebarbkg:render(self:getAbsoluteX(), self:getAbsoluteY(), self:getWidth(), titleBarHeight, 0.6, 0.6, 0.6, 0.95)
        end

        --Background
        local bg = self:isPageLeft() and NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_R.png") or NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBackground_L.png")
        local border = self:isPageLeft() and NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_R.png") or NinePatchTexture.getSharedTexture("media/ui/CleanUI/Panel/MainBorder_L.png")
        local bgOpacity = CleanUI_getBackgroundOpacity()
        if bg and border then
            local startX = self:isPageLeft() and self.containerButtonPanel.width or 0
            bg:render(self:getAbsoluteX() + startX, self:getAbsoluteY() + titleBarHeight, self.width - self.containerButtonPanel.width, height - titleBarHeight, 0.05, 0.05, 0.05, bgOpacity)
            border:render(self:getAbsoluteX() + startX, self:getAbsoluteY() + titleBarHeight, self.width - self.containerButtonPanel.width, height - titleBarHeight, 0.8, 0.8, 0.8, bgOpacity)
        end
        self:drawRect(0, titleBarHeight, self.width, 1, 1, 0.0, 0.0, 0.0)
    end

    if self.updateCleanUITransferButtonLayout then
        self:updateCleanUITransferButtonLayout(titleBarHeight)
    end
    local transferButtonsLeftX = self.cleanUITransferButtonsLeftX or self.transferButton:getX()
    local availableWidth = transferButtonsLeftX - (self.pinButton or self.collapseButton):getRight() - self.padding * 2
    if self.title and self.onCharacter then
        local x = self.padding + self.titleButtonSize + self.padding
        local y = (titleBarHeight - FONT_HGT_SMALL) / 2
        local truncatedText = CleanUI.truncateText(self.title, availableWidth, self.font)
        self:drawText(truncatedText, x, y, 1,1,1,1)
    end

	-- load the current weight of the container
	self.totalWeight = ISInventoryPage.loadWeight(self.inventoryPane.inventory)
	-- used handle characters being in seats
	local occupied

    if self.title and not self.onCharacter then
        local fontHgt = getTextManager():getFontHeight(self.font)
        local text = self.title
        if self.inventoryPane.inventory and self.inventoryPane.inventory:getParent() then
            local fireTile = self.inventoryPane.inventory:getParent()
            local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(fireTile:getSquare())
            if campfire then
                shouldBeVisible = true
                text = text .. ": " .. (ISCampingMenu.timeString(luautils.round(campfire.fuelAmt)))
            elseif fireTile and fireTile:isFireInteractionObject() then
                shouldBeVisible = truev
                if fireTile:isPropaneBBQ() and not fireTile:hasPropaneTank() then
                    text = text .. ": " .. getText("IGUI_BBQ_NeedsPropaneTank")
                else
                    text = text .. ": " .. tostring(ISCampingMenu.timeString(fireTile:getFuelAmount()))
                end
            end
        end
        
        local x = self.padding + self.titleButtonSize + self.padding
        local y = (titleBarHeight - fontHgt) / 2
        text = occupied and text .. " " .. getText("IGUI_invpage_Occupied") or text
        local truncatedText = CleanUI.truncateText(text, availableWidth, self.font)
        self:drawText(truncatedText, x, y, 1,1,1,1)
    end

    self:setStencilRect(0,0,self.width, height)

    self.containerButtonPanel:keepSelectedButtonVisible()

    local playerObj = getSpecificPlayer(self.player)
    if playerObj and playerObj:isInvPageDirty() then
        playerObj:setInvPageDirty(false)
        ISInventoryPage.renderDirty = false
        ISInventoryPage.dirtyUI()
    end
    if ISInventoryPage.renderDirty then
        ISInventoryPage.renderDirty = false
        ISInventoryPage.dirtyUI()
    end
end

function ISInventoryPage:render()
	local titleBarHeight = self:titleBarHeight()
    local height = self:getHeight()
    if self.isCollapsed then
        height = titleBarHeight
    end

    self:clearStencilRect()

    -- Draw backpack border over backpacks....
    if not self.isCollapsed then
        if not self:isPagelocked() then
            self:drawTextureScaled(self.resizeimage, self.width - self.resizeWidgetSize, self.height - self.resizeWidgetSize, self.resizeWidgetSize, self.resizeWidgetSize, self.resizeWidget.mouseOver and 1 or 0.6, 1, 1, 1)
        end
        if self.controlsUI and self.controlsUI:isVisible() then
            self:drawRectStatic(self.controlsUI.x + self.padding, self.inventoryPane.y, self.controlsUI.width - self.padding * 2, 1, 0.6, 0.6, 0.6, 0.6)
        end
    end


    if self.joyfocus then
        -- Draw the controller focus border inside the panel bounds so the
        -- right/bottom edges are not clipped by the UI element boundary.
        local focusW = math.max(1, self:getWidth() - 1)
        local focusH = math.max(1, self:getHeight() - 1)
        self:drawRectBorder(0, 0, focusW, focusH, 0.4, 0.2, 1.0, 1.0)
        self:drawRectBorder(1, 1, math.max(1, focusW - 2), math.max(1, focusH - 2), 0.4, 0.2, 1.0, 1.0)
    end

    if self.render3DItems and #self.render3DItems > 0 then
        self:render3DItemPreview()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Inventorypage Helper
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPage:collapseNow()
    if self.isCollapsed then return end
    self.isCollapsed = true
    self:setMaxDrawHeight(self:titleBarHeight())
end

function ISInventoryPage:canPutIn()
    local playerObj = getSpecificPlayer(self.player)
    local container = self.mouseOverButton and self.mouseOverButton.inventory or nil
    if not container then
        return false
    end
    local items = {}
    local minWeight = 100000
    local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    for i,item in ipairs(dragging) do
        local itemOK = true
        if item:isFavorite() and not container:isInCharacterInventory(playerObj) then
            itemOK = false
        end
        if container:isInside(item) then
            itemOK = false
        end
        if container:getType() == "floor" and item:getWorldItem() then
            itemOK = false
        end
        if item:getContainer() == container then
            itemOK = false
        end
        if not container:isItemAllowed(item) then
            itemOK = false
        end
        if itemOK then
            table.insert(items, item)
        end
        if item:getUnequippedWeight() < minWeight then
            minWeight = item:getUnequippedWeight()
        end
    end
    if #items == 1 then
        return container:hasRoomFor(playerObj, items[1])
    elseif #items > 0 then
        return container:hasRoomFor(playerObj, minWeight)
    end
    return false
end

function ISInventoryPage:drawTextRight(str, x, y, r, g, b, a, font)
    if self.javaObject ~= nil and str ~= nil then
        if font ~= nil then
            self.javaObject:DrawTextRight(font, str, x, y, r, g, b, a)
        else
            self.javaObject:DrawTextRight(UIFont.Small, str, x, y, r, g, b, a)
        end
    end
end

function ISInventoryPage:drawText(str, x, y, r, g, b, a, font)
    if self.javaObject ~= nil then
        if font ~= nil then
            self.javaObject:DrawText(font, str, x, y, r, g, b, a)
        else
            self.javaObject:DrawText(UIFont.Small, str, x, y, r, g, b, a)
        end
    end
end

function ISInventoryPage:render3DItemPreview()
    if isKeyDown("Rotate building") then
        if not self.render3DItemRot then
            self.render3DItemRot = 0
        end
        local rot = self.render3DItemRot
        if isKeyDown(Keyboard.KEY_LSHIFT) then
            rot = rot -10
        else
            rot = rot + 10
        end
        if rot < 0 then
            rot = 360
        end
        if rot > 360 then
            rot = 0
        end
        self.render3DItemRot = rot
    end
    local playerObj = getSpecificPlayer(self.player)

    local worldX = screenToIsoX(self.player, getMouseX(), getMouseY(), playerObj:getZ())
    local worldY = screenToIsoY(self.player, getMouseX(), getMouseY(), playerObj:getZ())
    local sq = getSquare(worldX, worldY, playerObj:getZ())
    if not sq then
        return
    end
    self.render3DItemXOffset = worldX - sq:getX()
    self.render3DItemYOffset = worldY - sq:getY()
    self.render3DItemZOffset = 0

    for i=0,sq:getObjects():size()-1 do
        local object = sq:getObjects():get(i)
        if object:getProperties():getSurface() and object:getProperties():getSurface() > 0 then

            self.render3DItemZOffset = (object:getProperties():getSurface() / 192) * 2
            break
        end
    end
    self.selectedSqDrop = sq
    if self.render3DItems then
        for i,v in ipairs(self.render3DItems) do
            Render3DItem(v, sq, worldX, worldY, self.render3DItemZOffset, self.render3DItemRot)
        end
    end

end

-- ----------------------------------------------------------------------------------------------------- --
-- Events Handle
-- ----------------------------------------------------------------------------------------------------- --

ISInventoryPage.ContainerSizeChanged = function()
	for i=1,getNumActivePlayers() do
		local pdata = getPlayerData(i-1)
		if pdata then
			pdata.playerInventory:onInventoryContainerSizeChanged()
			pdata.lootInventory:onInventoryContainerSizeChanged()
		end
	end
end

ISInventoryPage.onInventoryFontChanged = function()
    for i=1,getNumActivePlayers() do
        local pdata = getPlayerData(i-1)
        if pdata then
            pdata.playerInventory.inventoryPane:onInventoryFontChanged()
            pdata.lootInventory.inventoryPane:onInventoryFontChanged()
        end
    end
end

ISInventoryPage.OnContainerUpdate = function(object)
    ISInventoryPage.renderDirty = true
end

ISInventoryPage.ongamestart = function()
    ISInventoryPage.renderDirty = true
end

function ISInventoryPage:removeAll()
	self.inventoryPane:removeAll(self.player)
end

Events.OnKeyPressed.Add(ISInventoryPage.onKeyPressed)
Events.OnContainerUpdate.Add(ISInventoryPage.OnContainerUpdate)
Events.OnGameStart.Add(ISInventoryPage.ongamestart)
