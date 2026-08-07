require "SmarterStorageUI"
require "ISUI/ISInventoryPage"
require "ISUI/ISInventoryPane"
require "ISUI/ISContextMenu"
require "ISUI/ISPanel"

ISItemsListTable_ISPanel = ISPanel:derive("ISItemsListTable");
local SmarterStorage = {}

-- OPTIONS
SmarterStorage.options = {
	vanillaTooltips_enabled = false,
	renamedTooltips_enabled = true,
}

SetModOptions = function(options)
	SmarterStorage.options = options
end

-- MAIN

local vanilla_refreshBackpacks = ISInventoryPage.refreshBackpacks
function ISInventoryPage:refreshBackpacks()
    vanilla_refreshBackpacks(self)
    SmarterStorage.backpacks = self.backpacks
    SmarterStorage.player = getSpecificPlayer(self.player)
    SmarterStorage:updateSmarterStorageData(self)

    if self.title and not self.onCharacter and self.inventory:getType() ~= "floor" and self.inventory:getParent() then
        local modData = self.inventory:getParent():getModData()
        if modData.SmarterStorage_Name then self.title = modData.SmarterStorage_Name
        elseif modData.renameEverything_name then self.title = modData.renameEverything_name
        elseif modData.RenameContainer_CustomName then self.title = modData.RenameContainer_CustomName
        end
    end
end

local vanilla_onBackpackRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
function ISInventoryPage:onBackpackRightMouseDown(x, y)
    vanilla_onBackpackRightMouseDown(self, x, y)

    if not self.parent.onCharacter and self.inventory:getType() ~= "floor" and self.inventory:getParent() then 
        for i, button2 in ipairs(self.parent.backpacks) do
            if button2.mouseOver and not SmarterStorage:isVehicleContainer(button2.inventory) then
                ISInventoryPage.onBackpackClick(self.parent, button2)

                local context = getPlayerContextMenu(0)
                if not context or context.numOptions <= 1 then
                    local context = ISContextMenu.get(0, getMouseX(), getMouseY())
                end

                context:addOption(getText("ContextMenu_SmarterStorage_Edit"), button2, function() SmarterStorageUI.OnOpenPanel(self.parent) end)

                local subMenu = context:getNew(context)
                local presets = {"Weapons", "Ammo", "Medical", "Clothing", "Electronics", "Food", "Literature", "Tools", "Media", "Equipment", "Gardening", "Vehicles"}
                for i=1, #presets do
                    subMenu:addOption(getText("IGUI_SmarterStorage_" .. presets[i]), self.parent, function() SmarterStorage:applyPreset(self.parent, presets[i]) end)
                end

                local subMenuOption = context:addOption(getText("ContextMenu_SmarterStorage_Presets"), nil, nil)
                context:addSubMenu(subMenuOption, subMenu)

                context:addOption(getText("ContextMenu_SmarterStorage_Reset"), button2, function() SmarterStorage:resetSmarterStorageData(button2, self.parent) end)
			end
		end
    end
end

function SmarterStorage:applyPreset(inventoryPage, preset)
    if not preset then return end

    local psets = {
        Weapons = { name = "Weapons", item = "Base.Revolver_Long", color = { r=0.4, g=0, b=0, a=1 } },
        Ammo = { name = "Ammo", item = "Base.223Bullets", color = { r=0.4, g=0, b=0, a=1 } },
        Medical = { name = "Medical", item = "Base.Pills", color = { r=0, g=0.6, b=0, a=1 } },
        Clothing = { name = "Clothing", item = "Base.HoodieUP_WhiteTINT", color = { r=0, g=0.2, b=0.6, a=1 } },
        Electronics = { name = "Electronics", item = "Base.WristWatch_Left_DigitalBlack", color = { r=0, g=0, b=0.2, a=1 } },
        Food = { name = "Food", item = "Base.BreadSlices", color = { r=0.8, g=0.6, b=0, a=1 } },
        Literature = { name = "Literature", item = "Base.BookFarming1", color = { r=0, g=0.2, b=0.2, a=1 } },
        Tools = { name = "Tools", item = "Base.GardenSaw", color = { r=0.4, g=0.2, b=0, a=1 } },
        Media = { name = "Media", item = "Base.VHS", color = { r=0.4, g=0.4, b=0.4, a=1 } },
        Equipment = { name = "Equipment", item = "Base.Bag_ALICEpack_Army", color = { r=0, g=0.2, b=0, a=1 } },
        Gardening = { name = "Gardening", item = "farming.CarrotBagSeed", color = { r=0, g=0.4, b=0.2, a=1 } },
        Vehicles = { name = "Vehicles", item = "Base.NormalTire2", color = { r=0.4, g=0.2, b=0.8, a=1 } },
    }

    if psets[preset] == nil then return end
    SmarterStorageUI:setSmarterStorageData(getText("IGUI_SmarterStorage_" .. psets[preset].name), psets[preset].item, psets[preset].color, inventoryPage)
end

function SmarterStorage:isVehicleContainer(container)
    if container and container:getParent() then
        local parent = container:getParent()
        if instanceof(parent, "BaseVehicle") then
            return true
        elseif parent.getVehicle and parent:getVehicle() then
            return true
        end
    end
    return false
end

-- MANAGE MOD DATA

function SmarterStorage:resetSmarterStorageData(containerButton, parent)
    if not containerButton then return end
    
    local modData = containerButton.inventory:getParent() and containerButton.inventory:getParent():getModData()
    if not modData then return end

    -- ss data
    if modData.SmarterStorage_Name then modData.SmarterStorage_Name = nil end
    if modData.SmarterStorage_Color then modData.SmarterStorage_Color = nil end
    if modData.SmarterStorage_Icon then modData.SmarterStorage_Icon = nil end
    -- other data
    if modData.RenameContainer_CustomName then modData.RenameContainer_CustomName = nil end
    if modData.renameEverything_name then modData.renameEverything_name = nil end

    containerButton.inventory:getParent():transmitModData()
    SmarterStorage:updateSmarterStorageData(self)
    
    if not parent.onCharacter then
        parent:refreshBackpacks()
    end
end

function SmarterStorage:updateSmarterStorageData(self)
    for _, containerButton in pairs(SmarterStorage.backpacks) do
        local modData = containerButton.inventory:getParent() and containerButton.inventory:getParent():getModData()

        if containerButton and not containerButton.parent.onCharacter and self.inventoryPane and containerButton.inventory and self.inventoryPane.inventory then
            if containerButton.inventory == self.inventoryPane.inventory then
                if modData and modData.SmarterStorage_Color then
                    local c = modData.SmarterStorage_Color
                    containerButton:setBackgroundRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.4))
                    containerButton:setBackgroundColorMouseOverRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.2))
                else
                    containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
                end
            else -- not open container colors
                if modData and modData.SmarterStorage_Color then
                    local c = modData.SmarterStorage_Color
                    containerButton:setBackgroundRGBA(c.r, c.g, c.b, c.a)
                    containerButton:setBackgroundColorMouseOverRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.2))
                end
            end

            if modData then
                if modData.SmarterStorage_Icon then
                    local icon = SmarterStorage:getItemTexture(modData.SmarterStorage_Icon)
                    if icon then
                        containerButton:setImage(icon)
                    end
                end
                
                if SmarterStorage.options.renamedTooltips_enabled then
                    if modData.renameEverything_name and modData.renameEverything_name ~= modData.SmarterStorage_Name then
                        modData.SmarterStorage_Name = modData.renameEverything_name
                    elseif modData.RenameContainer_CustomName and modData.RenameContainer_CustomName ~= modData.SmarterStorage_Name then
                        modData.SmarterStorage_Name = modData.RenameContainer_CustomName
                    end

                    if modData.SmarterStorage_Name and modData.SmarterStorage_Name ~= "" then
                        containerButton.tooltip = modData.SmarterStorage_Name
                    elseif SmarterStorage.options.vanillaTooltips_enabled then
                        containerButton.tooltip = containerButton.name
                    end
                elseif SmarterStorage.options.vanillaTooltips_enabled and containerButton.name and containerButton.name ~= "" then
                    containerButton.tooltip = containerButton.name
                end
            end
        end
    end
end

-- SetNewContainer override
local vanilla_setNewContainer = ISInventoryPage.setNewContainer
function ISInventoryPage:setNewContainer(inventory)
    vanilla_setNewContainer(self, inventory)

    for i, containerButton in ipairs(self.backpacks) do
        local modData = containerButton.inventory:getParent() and containerButton.inventory:getParent():getModData()

        if containerButton.inventory == inventory then
            if modData and modData.SmarterStorage_Color then
                local c = modData.SmarterStorage_Color
                containerButton:setBackgroundRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.4))
                containerButton:setBackgroundColorMouseOverRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.2))
            else
                containerButton:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
            end
            if modData and modData.SmarterStorage_Name then
                if self.title and not self.onCharacter and self.inventory:getType() ~= "floor" and self.inventory:getParent() then
                    local modData = self.inventory:getParent():getModData()
                    if modData.SmarterStorage_Name then self.title = modData.SmarterStorage_Name
                    elseif modData.renameEverything_name then self.title = modData.renameEverything_name
                    elseif modData.RenameContainer_CustomName then self.title = modData.RenameContainer_CustomName
                    end
                end
            end
        elseif modData and modData.SmarterStorage_Color then
            local c = modData.SmarterStorage_Color
            containerButton:setBackgroundRGBA(c.r, c.g, c.b, c.a)
            containerButton:setBackgroundColorMouseOverRGBA(SmarterStorage:lightenRGBA(c.r, c.g, c.b, c.a, 0.2))
        end
    end

    self:syncToggleStove()
end

-- HELPER FUNCTIONS

function SmarterStorage:lightenRGBA(r, g, b, a, factor)
    factor = math.max(0, math.min(factor, 1))

    local newR = math.min(1.0, r + (1.0 - r) * factor)
    local newG = math.min(1.0, g + (1.0 - g) * factor)
    local newB = math.min(1.0, b + (1.0 - b) * factor)

    return newR, newG, newB, a
end

function SmarterStorage:getItemTexture(itemName)
    -- the old icon name stored in moddata was the texture name. for example... Item_BulletMold
    -- the new way is the items full name from the getFullName() function. for example... Base.223BulletsMold
    -- this change was needed to support modded items.
    if not itemName then return end

    local itemClass = InventoryItemFactory.CreateItem(itemName)
    return itemClass and itemClass:getTexture() or getTexture(itemName)
end
