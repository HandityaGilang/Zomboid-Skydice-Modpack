-- Allowed Items --
local AllowedFoodContainerItems = {
    "VFX.FoodStorageContainerSoup",
    "VFX.FoodStorageContainerStew",
    "VFX.FoodStorageContainerStirFry",
    "VFX.FoodStorageContainerRoastVegetables",
    "VFX.FoodStorageContainerSalad",
    "VFX.FoodStorageContainerFruitSalad",
    "VFX.FoodStorageContainerSpaghetti",
    "VFX.FoodStorageContainerRice",
    "VFX.FoodStorageContainerBrownRice",
    "VFX.FoodStorageContainerJasmineRice",
    "VFX.FoodStorageContainerBasmatiRice",
    "VFX.FoodStorageContainerArborioRice",
    "VFX.FoodStorageContainerMacaroni",
    "VFX.FoodStorageContainerFettuccine",
    "VFX.FoodStorageContainerPenne",
    "VFX.FoodStorageContainerGnocchi",
    "VFX.FoodStorageContainerLasagna",
    "VFX.FoodStorageContainerChili",
    "VFX.FoodStorageContainerCurry",
    "VFX.FoodStorageContainerCasserole",
    "VFX.FoodStorageContainerMeatloaf",
    "VFX.FoodStorageContainerScallopedPotatoBake",
    "VFX.FoodStorageContainerFriedRice",
    "VFX.MetalFoodStorageContainerSoup",
    "VFX.MetalFoodStorageContainerStew",
    "VFX.MetalFoodStorageContainerStirFry",
    "VFX.MetalFoodStorageContainerRoastVegetables",
    "VFX.MetalFoodStorageContainerSalad",
    "VFX.MetalFoodStorageContainerFruitSalad",
    "VFX.MetalFoodStorageContainerSpaghetti",
    "VFX.MetalFoodStorageContainerRice",
    "VFX.MetalFoodStorageContainerBrownRice",
    "VFX.MetalFoodStorageContainerJasmineRice",
    "VFX.MetalFoodStorageContainerBasmatiRice",
    "VFX.MetalFoodStorageContainerArborioRice",
    "VFX.MetalFoodStorageContainerMacaroni",
    "VFX.MetalFoodStorageContainerFettuccine",
    "VFX.MetalFoodStorageContainerPenne",
    "VFX.MetalFoodStorageContainerGnocchi",
    "VFX.MetalFoodStorageContainerLasagna",
    "VFX.MetalFoodStorageContainerChili",
    "VFX.MetalFoodStorageContainerCurry",
    "VFX.MetalFoodStorageContainerCasserole",
    "VFX.MetalFoodStorageContainerMeatloaf",
    "VFX.MetalFoodStorageContainerScallopedPotatoBake",
    "VFX.MetalFoodStorageContainerFriedRice",
}

local function IsAllowedFoodContainerItem(item)
    local fullType = item:getFullType()
    for _, allowed in ipairs(AllowedFoodContainerItems) do
        if fullType == allowed then
            return true
        end
    end
    return false
end

-- UI Window --
    ISUIAddNoteToFoodContainer = ISCollapsableWindow:derive("ISUIAddNoteToFoodContainer")

    function ISUIAddNoteToFoodContainer:initialise()
        ISCollapsableWindow.initialise(self)

        local fontHgt = getTextManager():getFontHeight(UIFont.Small)
        local btnWid = 100
        local btnHgt = math.max(fontHgt + 6, 25)
        local padBottom = 10

        self.entry = ISTextEntryBox:new(self.containerItem:getModData().containerNote or "", 10, 30, self.width - 20, 30)
        self.entry:initialise()
        self.entry:instantiate()
        self.entry:setMultipleLine(false)
        self.entry:setMaxTextLength(30)
        self:addChild(self.entry)

        self.ok = ISButton:new((self.width / 2) - btnWid - 5, self.entry:getBottom() + 10, btnWid, btnHgt, getText("UI_Ok"), self, ISUIAddNoteToFoodContainer.onClick)
        self.ok.internal = "OK"
        self.ok:initialise()
        self.ok:instantiate()
        self:addChild(self.ok)

        self.cancel = ISButton:new((self.width / 2) + 5, self.entry:getBottom() + 10, btnWid, btnHgt, getText("UI_Cancel"), self, ISUIAddNoteToFoodContainer.onClick)
        self.cancel.internal = "CANCEL"
        self.cancel:initialise()
        self.cancel:instantiate()
        self:addChild(self.cancel)

        self:setHeight(self.ok:getBottom() + padBottom + 10)
    end

    function ISUIAddNoteToFoodContainer:onClick(button)
        if button.internal == "OK" then
            if self.containerItem then
                local note = self.entry:getText()
                if note and note:trim() ~= "" then
                    self.containerItem:getModData().containerNote = note
                    self.containerItem:setName(self.originalName .. " - " .. note)
                    self.containerItem:setCustomName(true)
                end
            end
            self:close()
        elseif button.internal == "CANCEL" then
            self:close()
        end
    end

    function ISUIAddNoteToFoodContainer:close()
        self:setVisible(false)
        self:removeFromUIManager()
    end

    function ISUIAddNoteToFoodContainer:new(containerItem)
        local width = 320
        local height = 120
        local o = ISCollapsableWindow:new((getCore():getScreenWidth() - width) / 2, (getCore():getScreenHeight() - height) / 2, width, height)
        setmetatable(o, self)
        self.__index = self
        o.containerItem = containerItem
        local name = containerItem:getName()
        name = name:gsub("%s*%(.*%)%s*$", "")
        o.originalName = name
        o.title = "Add Note to Food Container"
        o.backgroundColor = {r=0, g=0, b=0, a=0.8}
        o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
        o.anchorLeft = true
        o.anchorRight = true
        o.anchorTop = true
        o.anchorBottom = true
        return o
    end

-- Context Menu --
    Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
        for _, item in ipairs(ISInventoryPane.getActualItems(items)) do
            if IsAllowedFoodContainerItem(item) then
                context:addOption("Add Note to Food Container", getSpecificPlayer(player), function(playerObj)
                    local win = ISUIAddNoteToFoodContainer:new(item)
                    win:initialise()
                    win:addToUIManager()
                end)
            end
        end
    end)
