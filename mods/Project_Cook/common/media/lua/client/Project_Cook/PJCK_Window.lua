require "ISUI/ISPanel"
require "Entity/ISUI/Controls/ISTableLayout"
require "Project_Cook/EvolvedRecipePanel/PJCK_EvoPanel"

PJCK_Window = ISPanel:derive("PJCK_Window")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local PJCK_TAB_EVOLVED = "evolved"
local PJCK_TAB_COOKER = "cooker"
local PJCK_TAB_CRAFT = "craft"

local function PJCK_safeRequire(moduleName)
    local ok, err = pcall(require, moduleName)
    if not ok then
        print("Project Cook: failed to load " .. tostring(moduleName) .. ": " .. tostring(err))
        return false
    end
    return true
end

local function PJCK_loadLegacyCommonUnits()
    PJCK_safeRequire("Entity/ISEntityUI")
    PJCK_safeRequire("ISUI/ISCraftingUI")
    PJCK_safeRequire("Project_Cook/CommonUnit/PJCK_UIHelper")
    PJCK_safeRequire("Project_Cook/CommonUnit/PJCK_SimpleScrollBar")
    PJCK_safeRequire("Project_Cook/CommonUnit/PJCK_ScrollView")
    PJCK_safeRequire("Project_Cook/CommonUnit/PJCK_VirtualScrollView")
    PJCK_safeRequire("Project_Cook/EvolvedRecipePanel/PJCK_SquareButton")
    return PJCK_UIHelper ~= nil and PJCK_ScrollView ~= nil and PJCK_SquareButton ~= nil
end

local function PJCK_loadCookerPanel()
    local ok = PJCK_loadLegacyCommonUnits()
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_ContainerButton") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_ValueAdjustmentSlot") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_PropaneTankSlot") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_CookerSlot") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_FoodSlot") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_CookerPicker") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_CookerAdjustmentPanel") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_InventoryPanel") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_CookerContainerPanel") and ok
    ok = PJCK_safeRequire("Project_Cook/Cooker/PJCK_CookerPanel") and ok
    return ok and PJCK_CookerPanel ~= nil
end

local function PJCK_loadHandCraftPanel()
    local ok = PJCK_loadLegacyCommonUnits()
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_CraftInput_Slot") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_CraftOutput_Slot") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_RecipeList_Box") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_InputSwitch_Box") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_InputSwitch_Expanded") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_CraftInput_Panel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_CraftOutput_Panel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_RecipeInfoPanel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_CraftActionPanel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_RecipeList_Panel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_InputSwitch_Panel") and ok
    ok = PJCK_safeRequire("Project_Cook/HandCraftPanel/PJCK_HandCraftPanel") and ok
    return ok and PJCK_HandCraftPanel ~= nil and HandcraftLogic ~= nil
end

-- Lightweight fallback shown when one of the restored beta tabs cannot be initialised.
PJCK_MessagePanel = ISPanel:derive("PJCK_MessagePanel")
function PJCK_MessagePanel:initialise()
    ISPanel.initialise(self)
end
function PJCK_MessagePanel:new(x, y, width, height, message)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor = {r = 0, g = 0, b = 0, a = 0}
    o.message = message or "This beta tab could not be loaded."
    return o
end
function PJCK_MessagePanel:prerender()
    self:drawRect(0, 0, self.width, self.height, 0.35, 0.08, 0.08, 0.08)
    self:drawRectBorder(0, 0, self.width, self.height, 0.8, 0.35, 0.35, 0.35)
    self:drawText(self.message, FONT_HGT_SMALL, FONT_HGT_SMALL, 1, 1, 1, 1, UIFont.Small)
end

-- ------------------------------------------------------ --
-- Update Items
-- ------------------------------------------------------ --

function PJCK_Window:getContainers()
    if not self.player then return nil end
    return ISInventoryPaneContextMenu.getContainers(self.player)
end

function PJCK_Window:getAllItems()
    return self.allItems
end

function PJCK_Window:updateAllItems(containers)
    self.allItems = ArrayList.new()
    if containers and CraftRecipeManager and CraftRecipeManager.getAllItemsFromContainers then
        CraftRecipeManager.getAllItemsFromContainers(containers, self.allItems)
    end
end

function PJCK_Window:needUpdate()
    local currentMovingState = self.player:isPlayerMoving()
    local currentInventoryWeight = self.player:getInventoryWeight()

    if self.lastInventoryWeight ~= currentInventoryWeight then
        self.lastInventoryWeight = currentInventoryWeight
        return true
    end

    local needUpdate = (self.lastPlayerMovingState == true and currentMovingState == false)
    self.lastPlayerMovingState = currentMovingState

    return needUpdate
end

function PJCK_Window:updateData()
    if not self:needUpdate() then
        return
    end

    local containers = self:getContainers()
    self:updateAllItems(containers)

    if self.EvoPanel then
        self.EvoPanel:setContainers(containers)
    end

    if self.CookerPanel and self.CookerPanel.inventoryPanel then
        self.CookerPanel.inventoryPanel:updateContainerButtons()
        self.CookerPanel.inventoryPanel:updateFoodList()
    end

    if self.CookerPanel and self.CookerPanel.cookerContainerPanel and self.CookerPanel.cookerContainerPanel.updateFoodList then
        self.CookerPanel.cookerContainerPanel:updateFoodList()
    end
end

function PJCK_Window:getLegacyContentSize()
    -- Keep restored tabs at the same visible size as the current Project Cook panel whenever possible.
    local currentWidth = self:getWidth() or 0
    local currentHeight = self:getHeight() or 0
    local contentWidth = math.max(self.legacyContentWidth or 0, currentWidth)
    local contentHeight = math.max(self.legacyContentHeight or 0, currentHeight - (self.headerHeight or 0))

    return contentWidth, contentHeight
end

function PJCK_Window:clearCurrentPanelBeforeSwitch()
    if self.currentPanel and self.currentPanel.clearSelectedCookerHighlight then
        self.currentPanel:clearSelectedCookerHighlight()
    end

    if self.currentPanel then
        self:removeChild(self.currentPanel)
        self.currentPanel = nil
    end
end


-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_Window:initialise()
    ISPanel.initialise(self)
end

function PJCK_Window:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.playerNum = player:getPlayerNum()
    o.moveWithMouse = true
    o.lastPlayerMovingState = nil
    o.lastInventoryWeight = nil
    o.headerHeight = math.floor(FONT_HGT_MEDIUM * 1.7)
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)
    o.currentPanelType = PJCK_TAB_EVOLVED
    o.currentPanel = nil
    o.tabButtons = {}
    o.allItems = ArrayList.new()
    o.InputSwitchPanel = nil
    -- Restored beta tabs follow the maintained Base Cooking window size. This gives the
    -- legacy subpanels enough room without permanently changing the main window size.
    o.legacyContentWidth = math.min(900, math.max(760, math.floor(FONT_HGT_SMALL * 54)))
    o.legacyContentHeight = math.min(620, math.max(520, math.floor(FONT_HGT_SMALL * 38)))

    o.buttonTex = {
        bg = getTexture("media/ui/NeatUI/Button/Background.png"),
        border = getTexture("media/ui/NeatUI/Button/Boarder.png")
    }

    -- Restored beta tabs reuse some of the original Project Cook panel textures. They are loaded
    -- only by those legacy panels; Base Cooking continues to use the current maintained UI code.
    o.InsideBGTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_LT.png"),
        top = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_T.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_RT.png"),
        left = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_RB.png")
    }

    return o
end
-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_Window:createChildren()
    self:createHeader()
    self:switchToPanel(PJCK_TAB_EVOLVED)
    self:updateData()
end

function PJCK_Window:createHeader()
    self.closeButton = ISButton:new(0, 0, 50, 50, "", self, self.onCloseClick)
    self.closeButton:initialise()
    self.closeButton.prerender = function(btn)
        local color = btn:isMouseOver() and {r = 0.85, g = 0.25, b = 0.25} or {r = 0.8, g = 0.2, b = 0.2}
        if self.buttonTex.bg then
            btn:drawTextureScaled(self.buttonTex.bg, 0, 0, btn.width, btn.height, 0.8, color.r, color.g, color.b)
        else
            btn:drawRect(0, 0, btn.width, btn.height, 0.8, color.r, color.g, color.b)
        end
        if self.buttonTex.border then
            btn:drawTextureScaled(self.buttonTex.border, 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        end
        local closeTex = getTexture("media/ui/Project_Cook/ICON/Icon_close.png") or getTexture("media/ui/Project_Cook/ICON/icon_close.png")
        if closeTex then
            btn:drawTextureScaled(closeTex, 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)
        end
    end
    self:addChild(self.closeButton)

    self:createTabButton(PJCK_TAB_EVOLVED, getText("IGUI_PJCK_EvolvedRecipe"))
    self:createTabButton(PJCK_TAB_COOKER, getText("IGUI_PJCK_Cooker"))
    self:createTabButton(PJCK_TAB_CRAFT, getText("IGUI_PJCK_CraftRecipe"))
    self:updateTabButtonStates()
end

function PJCK_Window:createTabButton(panelType, label)
    label = label or panelType
    local button = ISButton:new(0, 0, 10, 10, label, self, self.onTabClick)
    button.onClickArgs = { panelType }
    button:initialise()
    button:setDisplayBackground(false)
    button:setFont(UIFont.Small)
    button.panelType = panelType
    button.prerender = function(btn)
        local active = self.currentPanelType == btn.panelType
        local alpha = active and 0.55 or (btn:isMouseOver() and 0.35 or 0.18)
        btn:drawRect(0, 0, btn.width, btn.height, alpha, 0.16, 0.16, 0.16)
        btn:drawRectBorder(0, 0, btn.width, btn.height, active and 0.9 or 0.55, active and 0.8 or 0.45, active and 0.8 or 0.45, active and 0.8 or 0.45)
        btn:drawTextCentre(btn.title, btn.width / 2, math.floor((btn.height - FONT_HGT_SMALL) / 2), 1, 1, 1, active and 1 or 0.8, UIFont.Small)
    end
    self:addChild(button)
    table.insert(self.tabButtons, button)
    return button
end

function PJCK_Window:createEvoPanel()
    if not PJCK_EvoPanel then
        require "Project_Cook/EvolvedRecipePanel/PJCK_EvoPanel"
    end
    if not PJCK_EvoPanel then
        require "Project_Cook/Cell/PJCK_BaseItemColumn"
        require "Project_Cook/Cell/PJCK_InputColumn"
        require "Project_Cook/EvolvedRecipePanel/PJCK_BaseItem"
        require "Project_Cook/EvolvedRecipePanel/PJCK_CookingInfo"
        require "Project_Cook/EvolvedRecipePanel/PJCK_InputPanel"
        require "Project_Cook/EvolvedRecipePanel/PJCK_InputToolbar"
        require "Project_Cook/EvolvedRecipePanel/PJCK_ItemSlot"
        require "Project_Cook/EvolvedRecipePanel/PJCK_BaseItemSlot"
        require "Project_Cook/EvolvedRecipePanel/PJCK_NutritionBlock"
        require "Project_Cook/EvolvedRecipePanel/PJCK_EvoPanel"
    end

    self.EvoPanel = PJCK_EvoPanel:new(0, 0, 50, 50, self)
    self.EvoPanel:initialise()
    self:addChild(self.EvoPanel)
    self.currentPanel = self.EvoPanel
end

function PJCK_Window:createCookerPanel()
    local ok = PJCK_loadCookerPanel()
    if ok then
        local created, panelOrErr = pcall(function()
            local contentWidth, contentHeight = self:getLegacyContentSize()
            local panel = PJCK_CookerPanel:new(0, 0, contentWidth, contentHeight, self)
            panel:initialise()
            return panel
        end)
        if created and panelOrErr then
            self.CookerPanel = panelOrErr
        else
            print("Project Cook: failed to initialise Cooker tab: " .. tostring(panelOrErr))
            self.CookerPanel = PJCK_MessagePanel:new(0, 0, self.legacyContentWidth, self.legacyContentHeight, "Cooker beta tab failed to initialise. Check console.txt for details.")
            self.CookerPanel:initialise()
        end
    else
        self.CookerPanel = PJCK_MessagePanel:new(0, 0, self.legacyContentWidth, self.legacyContentHeight, "Cooker beta tab is unavailable in this setup.")
        self.CookerPanel:initialise()
    end
    self:addChild(self.CookerPanel)
    self.currentPanel = self.CookerPanel
end

function PJCK_Window:createHandCraftPanel()
    local ok = PJCK_loadHandCraftPanel()
    if ok then
        local created, panelOrErr = pcall(function()
            local contentWidth, contentHeight = self:getLegacyContentSize()
            local panel = PJCK_HandCraftPanel:new(0, 0, contentWidth, contentHeight, self)
            panel:initialise()
            return panel
        end)
        if created and panelOrErr then
            self.HandCraftPanel = panelOrErr
        else
            print("Project Cook: failed to initialise Cooking By Recipes tab: " .. tostring(panelOrErr))
            self.HandCraftPanel = PJCK_MessagePanel:new(0, 0, self.legacyContentWidth, self.legacyContentHeight, "Cooking By Recipes beta tab failed to initialise. Check console.txt for details.")
            self.HandCraftPanel:initialise()
        end
    else
        self.HandCraftPanel = PJCK_MessagePanel:new(0, 0, self.legacyContentWidth, self.legacyContentHeight, "Cooking By Recipes beta tab is unavailable in this setup.")
        self.HandCraftPanel:initialise()
    end
    self:addChild(self.HandCraftPanel)
    self.currentPanel = self.HandCraftPanel
end

function PJCK_Window:switchToPanel(panelType)
    if self.InputSwitchPanel then
        self:closeInputSwitchPanel()
    end

    self:clearCurrentPanelBeforeSwitch()

    self.EvoPanel = nil
    self.CookerPanel = nil
    self.HandCraftPanel = nil
    self.currentPanelType = panelType or PJCK_TAB_EVOLVED

    if self.currentPanelType == PJCK_TAB_COOKER then
        self:createCookerPanel()
    elseif self.currentPanelType == PJCK_TAB_CRAFT then
        self:createHandCraftPanel()
    else
        self.currentPanelType = PJCK_TAB_EVOLVED
        self:createEvoPanel()
    end

    self:updateTabButtonStates()

    if self.currentPanelType == PJCK_TAB_COOKER or self.currentPanelType == PJCK_TAB_CRAFT then
        local contentWidth, contentHeight = self:getLegacyContentSize()
        self:calculateLayout(contentWidth, contentHeight + self.headerHeight)
    else
        self:calculateLayout(0, 0)
    end

    self:updateData()
end

function PJCK_Window:updateTabButtonStates()
    if not self.tabButtons then return end
    for _, button in ipairs(self.tabButtons) do
        button.isActive = (button.panelType == self.currentPanelType)
    end
end

function PJCK_Window:onTabClick(button, panelType)
    if not panelType and button then
        panelType = button.panelType
    end

    if panelType and panelType ~= self.currentPanelType then
        self:switchToPanel(panelType)
    end
end

function PJCK_Window:calculateLayout(_preferredWidth, _preferredHeight)
    -- Start from the requested size instead of the current size. This allows the window
    -- to shrink again after leaving a restored beta tab such as Cooker.
    local width = math.max(_preferredWidth or 0, 50)
    local height = math.max(_preferredHeight or 0, 50)
    local buttonSize = FONT_HGT_MEDIUM
    local contentWidth = width
    local contentHeight = math.max(self.legacyContentHeight, height - self.headerHeight)

    if self.currentPanelType == PJCK_TAB_EVOLVED and self.EvoPanel then
        self.EvoPanel:setX(0)
        self.EvoPanel:setY(self.headerHeight)
        self.EvoPanel:calculateLayout(width, height)
        width = math.max(width, self.EvoPanel:getWidth())
        height = math.max(height, self.EvoPanel:getHeight() + self.headerHeight)
    elseif self.currentPanel then
        width = math.max(width, self.legacyContentWidth)
        height = math.max(height, self.legacyContentHeight + self.headerHeight)
        contentWidth = width
        contentHeight = height - self.headerHeight
        self.currentPanel:setX(0)
        self.currentPanel:setY(self.headerHeight)
        self.currentPanel:setWidth(contentWidth)
        self.currentPanel:setHeight(contentHeight)
    end

    local closePadding = FONT_HGT_SMALL / 2
    if self.closeButton then
        self.closeButton:setX(width - buttonSize - closePadding)
        self.closeButton:setY(math.floor((self.headerHeight - buttonSize) / 2))
        self.closeButton:setWidth(buttonSize)
        self.closeButton:setHeight(buttonSize)
    end

    local iconSize = math.floor(FONT_HGT_MEDIUM / 16) * 16
    local tabsX = self.padding + iconSize + self.padding + getTextManager():MeasureStringX(UIFont.Medium, "Project Cook") + self.padding * 3
    local tabsY = math.floor(self.headerHeight * 0.18)
    local tabsH = math.max(FONT_HGT_SMALL + 6, math.floor(self.headerHeight * 0.64))
    local maxRight = width - buttonSize - closePadding * 2

    if self.tabButtons then
        for _, button in ipairs(self.tabButtons) do
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, button.title or "")
            local tabW = math.max(textWidth + self.padding * 4, FONT_HGT_SMALL * 5)
            if tabsX + tabW > maxRight then
                tabW = math.max(FONT_HGT_SMALL * 4, maxRight - tabsX)
            end
            button:setX(tabsX)
            button:setY(tabsY)
            button:setWidth(tabW)
            button:setHeight(tabsH)
            tabsX = tabsX + tabW + self.padding
        end
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Input switch panel used by the restored Cooking By Recipes beta tab
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_Window:showInputSwitchPanel()
    if not self.HandCraftPanel or not PJCK_InputSwitch_Panel then
        return
    end

    if not self.InputSwitchPanel then
        local width = FONT_HGT_SMALL * 12
        local height = self:getHeight()
        self.InputSwitchPanel = PJCK_InputSwitch_Panel:new(0, 0, width, height, self)
        self.InputSwitchPanel:initialise()
        self.InputSwitchPanel:addToUIManager()
        self.InputSwitchPanel:setVisible(true)
    else
        self.InputSwitchPanel:setVisible(true)
        self.InputSwitchPanel:bringToTop()
    end
end

function PJCK_Window:UpdateInputSwitchPanelPosition()
    if self.InputSwitchPanel then
        self.InputSwitchPanel:updatePosition()
    end
end

function PJCK_Window:closeInputSwitchPanel()
    if self.InputSwitchPanel then
        self.InputSwitchPanel:Close()
        self.InputSwitchPanel = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Function
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_Window:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:UpdateInputSwitchPanelPosition()
        return true
    end
    return false
end

function PJCK_Window:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:UpdateInputSwitchPanelPosition()
        return true
    end
    return false
end

function PJCK_Window:onMouseUp(x, y)
    if self.moving then
        self.moving = false
        self:UpdateInputSwitchPanelPosition()
        return true
    end
    return false
end

function PJCK_Window:onMouseUpOutside(x, y)
    if self.moving then
        self.moving = false
        self:UpdateInputSwitchPanelPosition()
        return true
    end
    return false
end

function PJCK_Window:onCloseClick()
    if self.InputSwitchPanel then
        self:closeInputSwitchPanel()
    end

    PJCK_CookingUI.OnCloseWindow(self)

    self:setVisible(false)
    self:removeFromUIManager()
end

function PJCK_Window:update()
    ISPanel.update(self)
    self:updateData()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_Window:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainPanelBG_FlatTop.png")
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainTitle_BG.png")
    if contentBG and TitleBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.headerHeight, self.width, self.height - self.headerHeight, 0.15, 0.15, 0.15, 1)
        TitleBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.headerHeight, 0.08, 0.08, 0.08, 1)
    else
        self:drawRect(0, 0, self.width, self.height, 0.85, 0.08, 0.08, 0.08)
    end
    self:drawRect(0, self.headerHeight - 1, self.width, 1, 1, 0, 0, 0)

    local iconSize = math.floor(FONT_HGT_MEDIUM / 16) * 16
    local optionTex = getTexture("media/ui/Project_Cook/ICON/Icon_Option.png")
    if optionTex then
        self:drawTextureScaled(optionTex, self.padding, math.floor((self.headerHeight - iconSize) / 2), iconSize, iconSize, 1, 1, 1, 1)
    end
    self:drawText("Project Cook", self.padding + iconSize + self.padding, math.floor((self.headerHeight - FONT_HGT_MEDIUM) / 2), 1, 1, 1, 1, UIFont.Medium)
end

return PJCK_Window
