-- CONVERTED: AE_EquipmentUI.lua
-- SESSION 3D: Enhanced with AE_DataService validation and integration

local AE_EquipmentUI = {}

AE_EquipmentUI.WINDOW_WIDTH = 506   -- Increased by 33%: 380 * 1.33
AE_EquipmentUI.WINDOW_HEIGHT = 438  -- Increased by 33%: 329 * 1.33
AE_EquipmentUI.SLOT_SIZE = 40
AE_EquipmentUI.ANIMAL_IMAGE_SIZE = 242  -- Increased by 10%: 220 * 1.1
AE_EquipmentUI.ANIMAL_IMAGE_X = 132  -- Centered: (506-242)/2 
AE_EquipmentUI.ANIMAL_IMAGE_Y = 98   -- Centered: (438-242)/2

local SLOT_BG_COLOR = {r = 0.2, g = 0.2, b = 0.25, a = 0.9}
local SLOT_BORDER_COLOR = {r = 0.4, g = 0.4, b = 0.4, a = 1.0}
local SLOT_HOVER_COLOR = {r = 0.4, g = 0.6, b = 0.8, a = 0.5}
local EMPTY_SLOT_COLOR = {r = 0.15, g = 0.15, b = 0.15, a = 0.8}

AE_EquipmentUI.isOpen = false
AE_EquipmentUI.equipmentWindow = nil
AE_EquipmentUI.player = nil
AE_EquipmentUI.animalID = nil
AE_EquipmentUI.animalSlot = nil
AE_EquipmentUI.popupWindow = nil

-- CONVERTED: Enhanced validation with AE_DataService
function AE_EquipmentUI.validateEquipmentState()
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.isAnimalValid
    end)
    
    if dataServiceAvailable and AE_EquipmentUI.player and AE_EquipmentUI.animalID then
        -- Get animal from TamingSystem for validation
        local TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
        local animal = TamingSystem.GetAnimalFromSlot(AE_EquipmentUI.player, AE_EquipmentUI.animalSlot)
        
        if animal then
            if not AE_DataService.isAnimalValid(animal) then
                return false, "invalid_animal"
            end
            
            if not AE_DataService.isTamed(animal) then
                return false, "not_tamed"
            end
            
            local animalID = AE_DataService.getStableID(animal)
            if not animalID or animalID == "" then
                return false, "no_stable_id"
            end
            
            if animalID ~= AE_EquipmentUI.animalID then
                return false, "id_mismatch"
            end
        else
            return false, "animal_not_found"
        end
    end
    
    return true, "valid"
end

local EquipmentSlotButton = ISButton:derive("EquipmentSlotButton")

function EquipmentSlotButton:new(x, y, width, height, slotData, parent)
    local o = ISButton:new(x, y, width, height, "", parent, parent.onSlotClick)
    setmetatable(o, self)
    self.__index = self

    o.slotData = slotData
    o.parent = parent
    o.backgroundColor = EMPTY_SLOT_COLOR
    o.borderColor = SLOT_BORDER_COLOR

    return o
end

function EquipmentSlotButton:prerender()
    ISButton.prerender(self)

    -- Draw slot background
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a,
                  self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, 1,
                        self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Get equipped item
    local AE_EquipmentSystem = require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_EquipmentSystem")
    local equippedItem = AE_EquipmentSystem.getEquippedItem(self.parent.animalID, self.slotData.id)

    if equippedItem then
        -- Draw equipped item texture if available
        if equippedItem.texture then
            local texture = getTexture(equippedItem.texture)
            if texture then
                local padding = 5
                self:drawTextureScaledAspect(texture, padding, padding,
                                            self.width - padding * 2, self.height - padding * 2, 1, 1, 1, 1)
            end
        end
        -- When item is equipped, don't draw the slot label
    else
        -- Draw slot label when empty (centered in the slot)
        local labelText = self.slotData.name or "+"
        local textWidth = getTextManager():MeasureStringX(UIFont.Large, labelText)
        local textHeight = getTextManager():MeasureStringY(UIFont.Large, labelText)
        local textX = (self.width - textWidth) / 2
        local textY = (self.height - textHeight) / 2
        self:drawText(labelText, textX, textY, 0.8, 0.8, 0.8, 1, UIFont.Large)
    end
end

function EquipmentSlotButton:onMouseEnter()
    self.borderColor = SLOT_HOVER_COLOR
end

function EquipmentSlotButton:onMouseExit()
    self.borderColor = SLOT_BORDER_COLOR
end

local EquipmentWindow = ISPanel:derive("AE_EquipmentWindow")

function EquipmentWindow:new(x, y, width, height, player, animalID, animalSlot, animalType)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.animalID = animalID
    o.animalSlot = animalSlot
    o.animalType = animalType or "animal"
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0.8}
    o.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1}
    o.moveWithMouse = true
    o.slotButtons = {}

    return o
end

function EquipmentWindow:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function EquipmentWindow:createChildren()
    local displayType = self.animalType:gsub("^%l", string.upper)
    local titleLabel = ISLabel:new(10, 10, 20, displayType .. " Equipment", 1, 1, 1, 1, UIFont.Medium, true)
    titleLabel:initialise()
    titleLabel:instantiate()
    self:addChild(titleLabel)

    local closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    closeButton:initialise()
    closeButton:instantiate()
    closeButton.borderColor = {r = 1, g = 1, b = 1, a = 0.3}
    self:addChild(closeButton)

    local backButton = ISButton:new(10, self.height - 35, 100, 25, "< Back", self, self.onBack)
    backButton:initialise()
    backButton:instantiate()
    backButton.borderColor = {r = 0.8, g = 0.8, b = 0.8, a = 1}
    backButton.backgroundColor = {r = 0.3, g = 0.3, b = 0.3, a = 0.8}
    self:addChild(backButton)

    -- Load animal texture (dynamic based on animal type)
    local texturePaths = {
        "ui/" .. self.animalType .. "uifinal1",
        "media/textures/ui/" .. self.animalType .. "uifinal1.png",
        self.animalType .. "uifinal1",
        -- Fallback to generic
        "ui/animal_generic",
        "media/textures/ui/animal_generic.png",
        "animal_generic"
    }

    self.animalTexture = nil
    for _, path in ipairs(texturePaths) do
        self.animalTexture = getTexture(path)
        if self.animalTexture then
            break
        end
    end

    local AE_EquipmentSystem = require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_EquipmentSystem")
    local equipmentSlots = AE_EquipmentSystem.getAvailableSlots(self.animalType)

    -- Create equipment slot buttons based on animal type
    for _, slot in ipairs(equipmentSlots) do
        local button = EquipmentSlotButton:new(
            slot.x, slot.y,
            AE_EquipmentUI.SLOT_SIZE,
            AE_EquipmentUI.SLOT_SIZE,
            slot, self
        )
        button:initialise()
        button:instantiate()
        self:addChild(button)
        table.insert(self.slotButtons, button)
    end
end

function EquipmentWindow:prerender()
    ISPanel.prerender(self)
    
    -- CONVERTED: Validate equipment state before rendering
    local isValid, reason = AE_EquipmentUI.validateEquipmentState()
    if not isValid and reason ~= "valid" then
        -- Show validation error on screen
        local textMgr = getTextManager()
        local errorText = "Equipment Error: " .. (reason or "unknown")
        textMgr:DrawString(UIFont.Small, 10, self.height - 60, errorText, 1, 0.2, 0.2, 1)
    end

    -- Draw animal silhouette/background
    if self.animalTexture then
        self:drawTextureScaledAspect(
            self.animalTexture,
            AE_EquipmentUI.ANIMAL_IMAGE_X,
            AE_EquipmentUI.ANIMAL_IMAGE_Y,
            AE_EquipmentUI.ANIMAL_IMAGE_SIZE,
            AE_EquipmentUI.ANIMAL_IMAGE_SIZE,
            0.3, 0.3, 0.3, 0.6  -- Draw with low opacity as background
        )
    end
end

function EquipmentWindow:onSlotClick(slotData)
    -- CONVERTED: Validate before opening equipment interaction
    local isValid, reason = AE_EquipmentUI.validateEquipmentState()
    if not isValid then
        if self.player and self.player.Say then
            self.player:Say("Cannot access equipment: " .. (reason or "unknown error"))
        end
        return
    end
    
    local AE_EquipmentSystem = require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_EquipmentSystem")
    AE_EquipmentSystem.showEquipmentPopup(self.player, self.animalID, slotData, self)
end

function EquipmentWindow:onClose()
    AE_EquipmentUI.close()
end

function EquipmentWindow:onBack()
    AE_EquipmentUI.close()
    if AE_EquipmentUI.onBackCallback then
        AE_EquipmentUI.onBackCallback()
    end
end

-- CONVERTED: Enhanced equipment UI opening with validation
function AE_EquipmentUI.open(player, animalID, animalSlot, onBackCallback)
    if AE_EquipmentUI.isOpen then
        AE_EquipmentUI.close()
    end

    AE_EquipmentUI.player = player
    AE_EquipmentUI.animalID = animalID
    AE_EquipmentUI.animalSlot = animalSlot
    AE_EquipmentUI.onBackCallback = onBackCallback

    -- Get animal type for dynamic UI
    local TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
    local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    local animal = TamingSystem.GetAnimalFromSlot(player, animalSlot)
    local animalType = "animal"
    
    if animal then
        animalType = AnimalRegistry.GetAnimalType(animal) or "animal"
        
        -- CONVERTED: Validate equipment access before proceeding
        local dataServiceAvailable = pcall(function()
            return AE_DataService ~= nil and AE_DataService.isAnimalValid
        end)
        
        if dataServiceAvailable then
            if not AE_DataService.isAnimalValid(animal) then
                if player and player.Say then
                    player:Say("Invalid animal - cannot access equipment")
                end
                return
            end
            
            if not AE_DataService.isTamed(animal) then
                if player and player.Say then
                    player:Say("Animal must be tamed to access equipment")
                end
                return
            end
            
            local stableID = AE_DataService.getStableID(animal)
            if not stableID or stableID == "" then
                if player and player.Say then
                    player:Say("Animal not properly registered")
                end
                return
            end
            
            if stableID ~= animalID then
                if player and player.Say then
                    player:Say("Animal ID mismatch - cannot access equipment")
                end
                return
            end
        end
        
        local AE_EquipmentSystem = require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_EquipmentSystem")
        AE_EquipmentSystem.restoreEquipmentToAnimal(animal, animalID, player)
    else
        if player and player.Say then
            player:Say("Animal not found - cannot open equipment")
        end
        return
    end

    local core = getCore()
    local x = (core:getScreenWidth() - AE_EquipmentUI.WINDOW_WIDTH) / 2
    local y = (core:getScreenHeight() - AE_EquipmentUI.WINDOW_HEIGHT) / 2

    AE_EquipmentUI.equipmentWindow = EquipmentWindow:new(
        x, y,
        AE_EquipmentUI.WINDOW_WIDTH,
        AE_EquipmentUI.WINDOW_HEIGHT,
        player, animalID, animalSlot, animalType
    )
    AE_EquipmentUI.equipmentWindow:initialise()
    AE_EquipmentUI.equipmentWindow:instantiate()

    -- Add click-outside-to-close handlers
    AE_EquipmentUI.equipmentWindow.onMouseDownOutside = function(self, x, y)
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()

        if mouseX < 0 or mouseX > self.width or mouseY < 0 or mouseY > self.height then
            AE_EquipmentUI.close()
            return true
        end
        return false
    end

    AE_EquipmentUI.equipmentWindow.onRightMouseDownOutside = function(self, x, y)
        AE_EquipmentUI.close()
        return true
    end

    AE_EquipmentUI.equipmentWindow:addToUIManager()
    AE_EquipmentUI.equipmentWindow:setVisible(true)

    AE_EquipmentUI.isOpen = true
end

function AE_EquipmentUI.close()
    if AE_EquipmentUI.equipmentWindow then
        AE_EquipmentUI.equipmentWindow:setVisible(false)
        AE_EquipmentUI.equipmentWindow:removeFromUIManager()
        AE_EquipmentUI.equipmentWindow = nil
    end

    if AE_EquipmentUI.popupWindow then
        AE_EquipmentUI.popupWindow:setVisible(false)
        AE_EquipmentUI.popupWindow:removeFromUIManager()
        AE_EquipmentUI.popupWindow = nil
    end

    AE_EquipmentUI.isOpen = false
    AE_EquipmentUI.player = nil
    AE_EquipmentUI.animalID = nil
    AE_EquipmentUI.animalSlot = nil
    AE_EquipmentUI.onBackCallback = nil
end

-- CONVERTED: Enhanced equipment state monitoring
function AE_EquipmentUI.getEquipmentStatus(animalID)
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil
    end)
    
    if not dataServiceAvailable then
        return { status = "data_service_unavailable" }
    end
    
    local TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
    local player = getPlayer()
    if not player then
        return { status = "no_player" }
    end
    
    local animal = nil
    for slot = 1, 6 do  -- Assuming max 6 slots
        local slotAnimal = TamingSystem.GetAnimalFromSlot(player, slot)
        if slotAnimal then
            local stableID = AE_DataService.getStableID(slotAnimal)
            if stableID == animalID then
                animal = slotAnimal
                break
            end
        end
    end
    
    if not animal then
        return { status = "animal_not_found" }
    end
    
    return {
        status = "available",
        animal = animal,
        tamed = AE_DataService.isTamed(animal),
        valid = AE_DataService.isAnimalValid(animal),
        stableID = AE_DataService.getStableID(animal)
    }
end

return AE_EquipmentUI