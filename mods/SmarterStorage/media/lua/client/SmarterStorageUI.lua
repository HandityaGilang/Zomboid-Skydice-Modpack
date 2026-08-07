require "ISUI/ISInventoryPane"

SmarterStorageUI = ISPanel:derive("SmarterStorageUI");
SmarterStorageUI.instance = nil -- needed?

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- called by main "SmarterStorage.lua" file to open instanced UI
function SmarterStorageUI.OnOpenPanel(inventoryPage)
    if SmarterStorageUI.instance == nil then
        SmarterStorageUI.instance = SmarterStorageUI:new(0, 0, 250, 400, getPlayer(), inventoryPage)
        SmarterStorageUI.instance.inventoryPane = inventoryPage
        SmarterStorageUI.instance:initialise()
    end

    SmarterStorageUI.instance:addToUIManager()
    SmarterStorageUI.instance:setVisible(true)

    return SmarterStorageUI.instance
end

----------------------
--  MAIN FUNCTIONS  --
----------------------

-- runs every time the player moves
local vanilla_refreshBackpacks = ISInventoryPage.refreshBackpacks
function ISInventoryPage:refreshBackpacks()
    vanilla_refreshBackpacks(self)
    SmarterStorageUI.backpacks = self.backpacks
    SmarterStorageUI.inv = self.inventory
end

-- create and add base ui elements
function SmarterStorageUI:createChildren()
    local winWid = self:getWidth()
    local winHgt = self:getHeight()
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local smlPad = 10
    local bigPad = 20
    local btnWid = (winWid - smlPad * 3) / 2

    -- GENERIC
    self.cancel = ISButton:new(smlPad, winHgt - btnHgt - smlPad, btnWid, btnHgt, getText("IGUI_SmarterStorage_Cancel"), self, SmarterStorageUI.onClick)
    self.cancel:initialise();
    self.cancel.internal = "cancel"
    self:addChild(self.cancel);

    self.ok = ISButton:new(winWid - btnWid - smlPad, winHgt - btnHgt - smlPad, btnWid, btnHgt, getText("IGUI_SmarterStorage_OK"), self, SmarterStorageUI.onClick)
    self.ok:initialise();
    self.ok.internal = "ok"
    self.ok.enable = false
    self:addChild(self.ok)

    -- NAME
    local name = SmarterStorageUI:getSmarterStorageData().name or self.inventoryPane.title or "not found"
    self.name = ISTextEntryBox:new(name, winWid - smlPad - 160, FONT_HGT_MEDIUM + bigPad, 160, btnHgt)
    self.name:initialise()
    self.name:instantiate()
    self.name.onTextChange = SmarterStorageUI.onNameChange
    self.name.isChanged = false
    self:addChild(self.name)

    -- COLOR
    self.color = ISButton:new(winWid - smlPad - 160, self.name.y + self.name.height + smlPad, 160, btnHgt, "", self, SmarterStorageUI.onColor);
    self.color:initialise();
    self.color.backgroundColor = SmarterStorageUI:getSmarterStorageData().color or {r = 0, g = 0, b = 0, a = 1}
    self.color.isSelected = false
    self:addChild(self.color);

    self.colorPicker = ISColorPicker:new(0, 0)
    self.colorPicker:initialise()
    self.colorPicker.pickedTarget = self;
    self.colorPicker.resetFocusTo = self;

    -- ICON
    self.filter = ISTextEntryBox:new("", winWid - smlPad - 160, self.color.y + self.color.height + smlPad, 160, btnHgt)
    self.filter:initialise();
    self.filter:instantiate();
    self.filter.onTextChange = SmarterStorageUI.onFilterChange
    self:addChild(self.filter)

    self.list = ISScrollingListBox:new(smlPad, self.filter.y + self.filter.height + smlPad, winWid - bigPad, self.cancel.y - self.filter.y - self.filter.height - bigPad)
    self.list:initialise();
    self.list:setFont(UIFont.Small, 2)
    self.list.itemheight = FONT_HGT_SMALL + 10
    self.list.selected = 0
    self.list.onmousedown = SmarterStorageUI.onIconSelected
    self.list.target = self
    self.list.doDrawItem = SmarterStorageUI.drawList
    self:addChild(self.list)
end

function SmarterStorageUI:initialise()
    ISPanel.initialise(self)
    self:createChildren()
    self:generateItemList()
end

function SmarterStorageUI.onIconSelected(list)
    list.ok.enable = true
end

function SmarterStorageUI.onNameChange(name)
    name.parent.ok.enable = true
    name.isChanged = true
end

function SmarterStorageUI:onColor(button)
    self.colorPicker:setX(button:getAbsoluteX());
    self.colorPicker:setY(button:getAbsoluteY() + button:getHeight());
    self.colorPicker.pickedFunc = SmarterStorageUI.onPickedColor;
    self.colorPicker:addToUIManager()
end

function SmarterStorageUI:onPickedColor(color, mouseUp)
    self.color.backgroundColor = { r=color.r, g=color.g, b=color.b, a = 1 }
    self.color.isSelected = true
    self.ok.enable = true
end

function SmarterStorageUI.onFilterChange(filter)
    local filterTxt = string.lower(filter:getInternalText())
    local list = filter.parent.list
    if not list.allItems then list.allItems = list.items end
    list:clear()
    
    for i, item in ipairs(list.allItems) do
        item = item.item
        local txtToCheck = string.lower(item:getDisplayName())

        if checkStringPattern(filterTxt) and string.match(txtToCheck, filterTxt) then
            list:addItem(item:getDisplayName(), item);
        end
    end
end

-- this recreates the entire list? is this really needed?
-- only adding this to add the icons. performance maybe?
-- ~26fps before adding this
function SmarterStorageUI:drawList(y, item, alt)
    local yScroll = self:getYScroll()
    local itemHeight = self.itemheight
    local height = self.height
    local width = self:getWidth()
    local iconSize = FONT_HGT_SMALL + 5
    local iconPad = 5
    local alpha = 0.9

    -- Check if the item is within the visible area
    if y + yScroll + itemHeight < 0 or y + yScroll >= height then
        return y + itemHeight
    end

    -- Draw main background
    self:drawRectBorder(0, y, width, itemHeight, alpha, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Draw alternating colors
    if self.selected == item.index then
        self:drawRect(0, y, width, itemHeight, 0.3, 0.7, 0.35, 0.15)
    elseif alt then
        self:drawRect(0, y, width, itemHeight, 0.3, 0.6, 0.5, 0.5)
    end

    -- Draw item icon
    local texture = SmarterStorageUI:getItemIcon(item.item)
    if texture then
        self:drawTextureScaledAspect2(texture, iconPad, y + (itemHeight - iconSize) / 2, iconSize, iconSize, 1, 1, 1, 1)
    end

    -- Draw item name
    self:drawText(item.item:getDisplayName(), iconSize + (iconPad * 3), y + 4, 1, 1, 1, alpha, self.font)

    return y + itemHeight
end

function SmarterStorageUI:getItemIcon(item)
    if not item then return nil end

    local itemClass = InventoryItemFactory.CreateItem(item:getFullName())
    if not itemClass then return nil end
    return itemClass:getTexture()
end

-- WHY THE FUCK DOES THE UI HAVE TO BE DRAWN EVERY FRAME?!?!?!?
function SmarterStorageUI:prerender()
    local pad = 10
    local width = self.width
    local height = self.height
    local backgroundColor = self.backgroundColor
    local borderColor = self.borderColor

    self:drawRect(0, 0, width, height, backgroundColor.a, backgroundColor.r, backgroundColor.g, backgroundColor.b)
    self:drawRectBorder(0, 0, width, height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)
    self:drawTextCentre("Smarter Storage", width / 2, pad, 1, 1, 1, 1, UIFont.Medium)

    -- Draw labels
    local labels = {
        {text = getText("IGUI_SmarterStorage_Name"), y = self.name.y + (self.name.height - FONT_HGT_SMALL) / 2},
        {text = getText("IGUI_SmarterStorage_Color"), y = self.color.y + (self.color.height - FONT_HGT_SMALL) / 2},
        {text = getText("IGUI_SmarterStorage_Icon"), y = self.filter.y + (self.filter.height - FONT_HGT_SMALL) / 2},
    }

    for _, label in ipairs(labels) do
        self:drawText(label.text, pad, label.y, 1, 1, 1, 1, UIFont.Small)
    end
end

-- get all items that have icons
function SmarterStorageUI:generateItemList()
    local allItems = getAllItems()

    for i=0, allItems:size()-1 do
        local item = allItems:get(i)

        if not item:getObsolete() and not item:isHidden() then
            local icon = SmarterStorageUI:getItemIcon(item)
            if icon and icon:getName() ~= "Question_On" then
                self.list:addItem(item:getDisplayName(), item)
            end
        end
    end

    table.sort(self.list.items, function(a,b) return not string.sort(a.item:getDisplayName(), b.item:getDisplayName()) end)
end

-- buttion click actions
function SmarterStorageUI:onClick(button)
    if button.internal == "cancel" then
        self:setVisible(false)
        self:removeFromUIManager()
        SmarterStorageUI.instance = nil
    elseif button.internal == "ok" then
        local name = self.name.isChanged and self.name:getText() or nil
        local item = self.list.selected > 0 and button.parent.list.items[button.parent.list.selected].item
        item = item and item:getFullName() or nil
        local color = self.color.isSelected and self.color.backgroundColor or nil
        SmarterStorageUI:setSmarterStorageData(name, item, color, self.inventoryPage)

        -- TO MAKE PRESETS
        -- print("------------")
        -- if name then print("name = " .. name) end
        -- if item then print("item = " .. item) end
        -- if color then 
        --     local col = ""
        --     for k, v in pairs(color) do
        --         col = col .. k ..": " .. v .. ", "
        --     end
        --     print(col)
        -- end
        -- print("------------")

        self:removeFromUIManager()
        SmarterStorageUI.instance = nil
    end
end

----------------------
--  MOD DATA FUNCS  --
----------------------

function SmarterStorageUI:setSmarterStorageData(name, itemName, color, inventoryPage)
    if SmarterStorageUI.inv and SmarterStorageUI.inv:getParent() then
        local modData = SmarterStorageUI.inv:getParent():getModData()
        if not modData then return end

        if name then
            modData.SmarterStorage_Name = name
            if modData.RenameContainer_CustomName then modData.RenameContainer_CustomName = name end
            if modData.renameEverything_name then modData.renameEverything_name = name end
        end
        if itemName then modData.SmarterStorage_Icon = itemName end
        if color then modData.SmarterStorage_Color = color end

        SmarterStorageUI.inv:getParent():transmitModData()
    end

    if inventoryPage then
        inventoryPage:refreshBackpacks()
    end
end

function SmarterStorageUI:getSmarterStorageData()
    local data = {
        name = nil,
        color = nil,
        icon = nil,
    }
    if SmarterStorageUI.inv and SmarterStorageUI.inv:getParent() then
        local modData = SmarterStorageUI.inv:getParent():getModData()
        if not modData then return end

        if modData.SmarterStorage_Name then data.name = modData.SmarterStorage_Name end
        if modData.SmarterStorage_Color then data.color = modData.SmarterStorage_Color end
        if modData.SmarterStorage_Icon then data.icon = modData.SmarterStorage_Icon end
    end

    return data 
end

----------------------
--  NEW PANEL FUNC  --
----------------------

-- call this function to create new windows?
function SmarterStorageUI:new(x, y, width, height, player, inventoryPage)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = {r = 0.9, g = 0.55, b = 0.1, a = 1}
    o.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1}
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0.8}
    o.buttonBorderColor = {r = 0.7, g = 0.7, b = 0.7, a = 0.5}
    o.width = width
    o.height = height
    o.player = player
    o.moveWithMouse = true
    o.inventoryPage = inventoryPage
    SmarterStorageUI.instance = o
    return o
end
