require("ISUI/ISPanelJoypad")

TABAS_BathSaltDropBoxPanel = ISPanelJoypad:derive("TABAS_BathSaltDropBoxPanel")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Menu = require("TubFluidContainer/TABAS_TubFluidContainerMenu")
local BathSaltDefs = require("TABAS_BathSaltDefs")
local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_BathSaltDropBoxPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_BathSaltDropBoxPanel:createChildren()
    local btnScale = self.btnScale
    local btnText = ""
    local y = BORDER_SPACING
    local labelX = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_TABAS_BathSalt") .. ":") + BORDER_SPACING
    local col = self.labelColor
	self.label = ISLabel:new(BORDER_SPACING, y, FONT_HGT_SMALL, getText("IGUI_TABAS_BathSalt") .. ":", col.r, col.g, col.b, col.a, UIFont.Small, true)
	self:addChild(self.label)
    col = self.textColor
    self.value = ISLabel:new(labelX + BORDER_SPACING, y, FONT_HGT_SMALL, getText("IGUI_TABAS_BathSalt_None"), col.r, col.g, col.b, col.a, UIFont.Small, true)
    self:addChild(self.value)

    self.currentBathSalt = self.tfc_Base:getWaterData("bathSalt")
    if self.currentBathSalt then
        self.def = BathSaltDefs.BathSaltTypes[self.currentBathSalt]
        self.value:setName(getText(self.def.name))
    else
        self.value:setName(getText("IGUI_TABAS_BathSalt_None"))
    end

    y = y + HGT_BUTTON + BORDER_SPACING
    col = self.labelColor
	self.benefitLbl = ISLabel:new(BORDER_SPACING*2, y, FONT_HGT_SMALL, getText("IGUI_TABAS_BathSalt_Benefits"), col.r, col.g, col.b, col.a, UIFont.Small, true)
    self:addChild(self.benefitLbl)

    self.textPanel = ISRichTextPanel:new(self.benefitLbl:getRight(), y, self.textWidth, self.height - y + BORDER_SPACING)
	self.textPanel:initialise()
	self:addChild(self.textPanel)
	self.textPanel.background = false
	self.textPanel:setMargins(FONT_HGT_SMALL, FONT_HGT_SMALL/2, FONT_HGT_SMALL*2, FONT_HGT_SMALL)
	self.textPanel.text = ""

    self:setTextPanel()

    y = y+BORDER_SPACING + btnScale/2
    self.btnAdd = TABAS_Panel.addButton(self:getWidth()/2 - btnScale, y, btnScale, btnScale, self.tex_addIcon, btnText, getText("IGUI_TABAS_AddBathSaltTooltip"), self, self.onClick, true)
    self.btnAdd.internal = "ADD"

    self.itemDropBox = ISItemDropBox:new (self.btnAdd:getRight() + BORDER_SPACING, y, btnScale, btnScale, true, self, self.addItem, self.removeItem, self.verifyItem, nil )
    self.itemDropBox.allowDropAlways = true
    self.itemDropBox.doBackDropTex = true
    -- self.itemDropBox:setHighlight(0,0,0,0,0,0,0,0)
    self.itemDropBox:setBackDropTex(self.tex_bathSalt, 0.8, 0.2,0.2,0.2)
    self.itemDropBox.onMouseDown = self.clickedDropBox
    self.itemDropBox:setToolTip(true, getText("IGUI_TABAS_BathSaltDropBoxTooltip"))
    self.itemDropBox.player = self.playerObj
    self.itemDropBox:initialise()

    self.itemDropBox.toolTipTextItem = getText("Fluid_Dropbox_Remove")
    self:addChild(self.itemDropBox)

    if getJoypadData(self.playerObj:getPlayerNum()) then
        self.itemDropBoxJoypad = TABAS_Panel.addButton(self.btnAdd:getRight() + BORDER_SPACING, y, btnScale, btnScale, nil, btnText, getText("IGUI_TABAS_BathSaltDropBoxTooltip"), self, self.onClick, true)
        self.itemDropBoxJoypad.internal = "DROPBOX"
        self.itemDropBoxJoypad.backgroundColor = {r=0, g=0, b=0, a=0}
    end
end

local function getLineText(prefix, texts, setX)
    local text = ""
    for i=1, #texts do
        local name = texts[i]
        if name then
            if setX then
                text = text .. getText(prefix .. name) .. " <LINE> <SETX:" .. setX .. ">"
            else
                text = text .. getText(prefix .. name) .. " <LINE> "
            end
        end
    end
    return text
end

function TABAS_BathSaltDropBoxPanel:setTextPanel()
    local text = ""
    if self.tfc_Base:hasTfc() and self.def then
        text = getLineText("IGUI_TABAS_BathBenefit_", self.def.benefitCategories)
    end
    self.textPanel:setText(text)
    self.textPanel:paginate()
end

function TABAS_BathSaltDropBoxPanel:clickedDropBox(x, y)
    local self = self.parent
    local validItems = TABAS_Utils.getNearbyItems(self.playerObj, nil, 1, nil, TABAS_Tag.BathSalt, TABAS_Utils.predicateBathSalt)
    if not validItems or validItems:isEmpty() then return end

    local parent = self.parent
    local playerNum = self.playerObj:getPlayerNum()
    local oldFocus = JoypadState.players[playerNum+1] and JoypadState.players[playerNum+1].focus or nil
    local x = parent:getAbsoluteX() + parent:getWidth()
    local y = parent:getAbsoluteY() + self:getY()
    local context = ISContextMenu.get(playerNum, x, y)
    local addedItems = {}
    for i=1, validItems:size() do
        local item = validItems:get(i-1)
        if item then
            local def = BathSaltDefs.getDef(item:getType())
            if def then
                local name = getText(def.name)
                if not addedItems[name] then
                    addedItems[name] = {item=item, benefitCategories=def.benefitCategories}
                else
                    if addedItems[name].item:getCurrentUsesFloat() < item:getCurrentUsesFloat() then
                        addedItems[name].item = item
                    end
                end
            end
        end
    end
    local tooltipTitle = "<PUSHRGB:0.8,0.8,0.5>" .. getText("IGUI_TABAS_BathSalt_Benefits") .. " <POPRGB> <SPACE>"
    local setX = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_TABAS_BathSalt_Benefits")) + 10
    for i,v in pairs(addedItems) do
        local option = context:addOption(i, self.itemDropBox, ISItemDropBox.onDropItem, v.item)
        local tooltip = TABAS_Panel.addItemTooltip()
        local text = getLineText("IGUI_TABAS_BathBenefit_", v.benefitCategories, setX)
        tooltip.description = tooltipTitle .. text
        option.toolTip = tooltip
        option.iconTexture = v.item:getIcon()
    end
    context:setAlwaysOnTop(true)
    if oldFocus then
        context.origin = oldFocus
        context.mouseOver = 1
        setJoypadFocus(playerNum, context)
    end
end

function TABAS_BathSaltDropBoxPanel:addItem(_items)
    local list = ArrayList.new()
    for i=1, #_items do
        local item = _items[i]
        if not list:contains(item) then
            list:add(item)
        end
    end
    if list:size() == 1 then
       self:addItemAux(_items[1])
       return
    end
    local playerNum = self.playerObj:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.itemDropBox:getAbsoluteX()+16, self.itemDropBox:getAbsoluteY()+16)
    list:clear()
    for i=1, #_items do
        local item = _items[i]
        if not list:contains(item) then
            local option = context:addOption(item:getName(), self, self.addItemAux, item)
            local icon = item:getIcon()
            option.iconTexture = icon
            list:add(item)
        end
    end
    context.mouseOver = 1
end

function TABAS_BathSaltDropBoxPanel:addItemAux(_item)
    self.itemDropBox:setStoredItem( _item )
end

function TABAS_BathSaltDropBoxPanel:removeItem()
    self.itemDropBox:setStoredItem(nil)
end

function TABAS_BathSaltDropBoxPanel:verifyItem(_item)
    return TABAS_Utils.predicateBathSalt(_item)
end

function TABAS_BathSaltDropBoxPanel:onClick(_btn)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.playerObj)
    local doAction = actionQueue.queue[1] ~= nil
    if doAction then return end

	if self.canAdd and _btn.internal == "ADD" then
        local bathSalt = self.itemDropBox.storedItem
        local def = BathSaltDefs.getDef(bathSalt:getType())
		TFC_Menu.onAddBathSalt(self.playerObj:getPlayerNum(), self.tfc_Base, def, bathSalt)
	end
    if _btn.internal == "DROPBOX" then
        self:setOrClearItem()
    end
end

function TABAS_BathSaltDropBoxPanel:setOrClearItem()
    if not self.itemDropBox:isVisible() then return end
    if self.itemDropBox.boxOccupied then
        self.itemDropBox:onRightMouseUp(0, 0) -- remove item
    else
        self.itemDropBox:onMouseDown(0, 0) -- choose item via context menu
    end
end

function TABAS_BathSaltDropBoxPanel:refreshFast()
    local btnVisible = not self.currentBathSalt
    local canAdd = btnVisible and self.itemDropBox.storedItem ~= nil and self.tfc_Base:canAddBathSalt()
    if self.canAdd ~= canAdd then
        self.canAdd = canAdd
        self.btnAdd:setEnable(canAdd)
    end
end

function TABAS_BathSaltDropBoxPanel:refreshSlow(force)
    local enabled = self.tfc_Base:hasTfc() and not self.tfc_Base:isEmpty()
    if not enabled then
        if self.currentBathSalt ~= nil or self.def ~= nil then
            self.currentBathSalt = nil
            self.def = nil
        end
    else
        local currentBathSalt = self.tfc_Base:getWaterData("bathSalt")
        if force or self.currentBathSalt ~= currentBathSalt then
            self.currentBathSalt = currentBathSalt
            self.def = BathSaltDefs.BathSaltTypes[currentBathSalt]
            self:setTextPanel()
        end
    end

    local btnVisible = not self.currentBathSalt
    self.btnAdd:setVisible(btnVisible)
    self.itemDropBox:setVisible(btnVisible)
    self.benefitLbl:setVisible(not btnVisible)
    self.textPanel:setVisible(not btnVisible)

    if self.itemDropBoxJoypad then
        self.itemDropBoxJoypad:setVisible(btnVisible)
        local item = self.itemDropBox.storedItem
        if item then
            local icon = item:getIcon()
            self.itemDropBoxJoypad:setImage(icon)
            local size = self.itemDropBoxJoypad:getWidth() - 4
            self.itemDropBoxJoypad:forceImageSize(size, size)
        else
            self.itemDropBoxJoypad:setImage(nil)
        end
    end
end

function TABAS_BathSaltDropBoxPanel:update()
    if self._managedByParent then return end
    self:refreshSlow(false)
    self:refreshFast()
end

function TABAS_BathSaltDropBoxPanel:prerender()
    ISPanelJoypad.prerender(self)
end

function TABAS_BathSaltDropBoxPanel:render()
    ISPanelJoypad.render(self)
    if self.currentBathSalt then
        self.value:setName(getText(self.def.name))
    else
        self.value:setName(getText("IGUI_TABAS_BathSalt_None"))
    end
end

function TABAS_BathSaltDropBoxPanel:onJoypadDown(button, joypadData)
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
end

function TABAS_BathSaltDropBoxPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
end

function TABAS_BathSaltDropBoxPanel:new(x, y, playerObj, tfc_Base)
    local text
    local minWidth = FONT_HGT_SMALL * 8.5
    local textWidth = minWidth
    for k, _ in pairs(BathSaltDefs.BenefitCategories) do
        text = getText("IGUI_TABAS_BathBenefit_" .. k) .. " <LINE> "
        if not string.find(text, "IGUI_") then -- if has not translated
            textWidth = math.max(textWidth, getTextManager():MeasureStringX(UIFont.Small, text))
        end
    end
    local width = textWidth + getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_TABAS_BathSalt_Benefits")) + FONT_HGT_SMALL*2 + BORDER_SPACING * 4
    local height = 200
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y

    o.buttonBorderColor = CONST.COLOR.buttonBorderColor
    o.labelColor = CONST.COLOR.labelColor
    o.textColor = CONST.COLOR.textColor
    o.tex_addIcon = CONST.TEXTURE.bathSaltAdd
    o.tex_bathSalt = CONST.TEXTURE.bathSaltItem
    o.width = width
    o.height = height
    o.textWidth = textWidth + FONT_HGT_SMALL*2
    o.btnScale = HGT_BUTTON * 2
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base

    return o
end
