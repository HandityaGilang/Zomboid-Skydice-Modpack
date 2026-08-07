require "SmarterStorageUI"
require "ISUI/ISInventoryPage"
require "ISUI/ISInventoryPane"
require "ISUI/ISContextMenu"
require "ISUI/ISPanel"

ISItemsListTable_ISPanel = ISPanel:derive("ISItemsListTable");
local SmarterStorage = {}
SmarterStorage.presets = {
    Weapons = { name = "Weapons", item = "Base.ShortSword", color = { r=0.4, g=0, b=0, a=1 } },
    MeleeWeapons = { name = "MeleeWeapons", item = "Base.Nightstick", color = { r=0.4, g=0, b=0, a=1 } },
    Shotguns = { name = "Shotguns", item = "Base.ShotgunSawnoff", color = { r=0.4, g=0, b=0, a=1 } },
    Pistols = { name = "Pistols", item = "Base.Pistol2", color = { r=0.4, g=0, b=0, a=1 } },
    Rifles = { name = "Rifles", item = "Base.AssaultRifle2", color = { r=0.4, g=0, b=0, a=1 } },
    Ammo = { name = "Ammo", item = "Base.3030Bullets", color = { r=0.4, g=0.15, b=0.15, a=1 } },
    PistolBullets = { name = "PistolBullets", item = "Base.Bullets9mm", color = { r=0.4, g=0.15, b=0.15, a=1 } },
    RifleBullets = { name = "RifleBullets", item = "Base.556Bullets", color = { r=0.4, g=0.15, b=0.15, a=1 } },
    ShotgunShells = { name = "ShotgunShells", item = "Base.ShotgunShells", color = { r=0.4, g=0.15, b=0.15, a=1 } },
    Tools = { name = "Tools", item = "Base.GardenSaw", color = { r=0.4, g=0.2, b=0, a=1 } },
    Clothing = { name = "Clothing", item = "Base.HoodieUP_WhiteTINT", color = { r=0, g=0.2, b=0.6, a=1 } },
    Explosives = { name = "Explosives", item = "Base.Firecracker", color = { r=0.65, g=0.11, b=0.25, a=1 } },
    Backpacks = { name = "Backpacks", item = "Base.Bag_Military", color = { r=0, g=0.2, b=0, a=1 } },
    Containers = { name = "Containers", item = "Base.Bag_ProtectiveCase", color = { r=0.25, g=0.25, b=0.25, a=1 } },
    Literature = { name = "Literature", item = "Base.BookFarming1", color = { r=0, g=0.2, b=0.2, a=1 } },
    DigitalMedia = { name = "DigitalMedia", item = "Base.VHS_Home", color = { r=0.4, g=0.4, b=0.4, a=1 } },
    Medical = { name = "Medical", item = "Base.Pills", color = { r=0, g=0.6, b=0, a=1 } },
    Food = { name = "Food", item = "Base.BreadSlices", color = { r=0.8, g=0.6, b=0, a=1 } },
    Drinks = { name = "Drinks", item = "Base.WaterBottle", color = { r=0.15, g=0.5, b=0.6, a=1 } },
    Gardening = { name = "Gardening", item = "Base.CarrotBagSeed2", color = { r=0, g=0.4, b=0.2, a=1 } },
    Camping = { name = "Camping", item = "Base.TentYellow", color = { r=0.13, g=0.35, b=0.15, a=1 } },
    Cooking = { name = "Cooking", item = "Base.Saucepan", color = { r=0.56, g=0.41, b=0.2, a=1 } },
    Fishing = { name = "Fishing", item = "Base.FishingRod", color = { r=0.1, g=0.42, b=0.5, a=1 } },
    AnimalParts = { name = "AnimalParts", item = "Base.Pig_Boar_Head_Pink", color = { r=0.55, g=0.19, b=0.4, a=1 } },
    Automotive = { name = "Automotive", item = "Base.OldBrake1", color = { r=0.8, g=0.2, b=0.2, a=1 } },
    Household = { name = "Household", item = "Base.BathTowel", color = { r=0.55, g=0.19, b=0.4, a=1 } },
    Materials = { name = "Materials", item = "Base.Plank", color = { r=0.43, g=0.28, b=0.1, a=1 } },
    Electronics = { name = "Electronics", item = "Base.Headphones", color = { r=0.59, g=0.2, b=0.19, a=1 } },
    Junk = { name = "Junk", item = "Base.MoneyBundle", color = { r=0.16, g=0.39, b=0.2, a=1 } },
    Furniture = { name = "Furniture", item = "Base.Mov_DarkBlueChair", color = { r=0.17, g=0.33, b=0.5, a=1 } },
}

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

    -- retroactive fix for player inventory icons
    if self.onCharacter and SmarterStorage.backpacks then
        for _, button in ipairs(SmarterStorage.backpacks) do
            if button and button.inventory and button.inventory:getParent() then
                local parent = button.inventory:getParent()
                if parent then
                    local modData = parent:getModData()

                    if modData and modData.SmarterStorage_Name or modData.SmarterStorage_Color or modData.SmarterStorage_Icon then
                        modData.SmarterStorage_Name = nil
                        modData.SmarterStorage_Color = nil
                        modData.SmarterStorage_Icon = nil
                    end
                end
            end
        end
    end

    if self.title and not self.onCharacter and self.inventory:getType() ~= "floor" and self.inventory:getParent() then
        local modData = self.inventory:getParent():getModData()
        
        if modData.SmarterStorage_Name then self.title = modData.SmarterStorage_Name
        elseif modData.renameEverything_name then self.title = modData.renameEverything_name
        elseif modData.RenameContainer_CustomName then self.title = modData.RenameContainer_CustomName
        end

        if SmarterStorage.targetButton and self.inventory ~= SmarterStorage.targetButton.inventory then
            SmarterStorageUI.closeIfDifferent(SmarterStorage.targetButton, self.inventory)
        end
    end
end

local vanilla_onBackpackRightMouseDown = ISInventoryPage.onBackpackRightMouseDown
function ISInventoryPage:onBackpackRightMouseDown(x, y)
    vanilla_onBackpackRightMouseDown(self, x, y)

    local page = self.parent and self.parent.parent or self.parent
    if not page or not page.player then return end
    if page.onCharacter then return end
    if not page.inventory or page.inventory:getType() == "floor" then return end
    if not page.inventory:getParent() then return end

    for i, button in ipairs(page.backpacks) do
        if button.mouseOver and not SmarterStorage:isVehicleContainer(button.inventory) then
            ISInventoryPage.onBackpackClick(page, button)

            local context = getPlayerContextMenu(0)
            if not context or context.numOptions <= 1 then
                local context = ISContextMenu.get(0, getMouseX(), getMouseY())
            end

            SmarterStorage.targetButton = button

            context:removeOptionByName("Rename")

            context:addOption(getText("ContextMenu_SmarterStorage_Edit"), SmarterStorage.targetButton, function() SmarterStorageUI.OnOpenPanel(page, SmarterStorage.targetButton) end)

            local presetsSubMenuContents = context:getNew(context)
            local presetsSubMenu = context:addOption(getText("ContextMenu_SmarterStorage_Presets"), nil, nil)
            context:addSubMenu(presetsSubMenu, presetsSubMenuContents)

            context:addOption(getText("ContextMenu_SmarterStorage_Copy"), button, function() SmarterStorage:copySmarterStorageData(SmarterStorage.targetButton, page) end)
            context:addOption(getText("ContextMenu_SmarterStorage_Paste"), button, function() SmarterStorage:pasteSmarterStorageData(SmarterStorage.targetButton, page) end)
            context:addOption(getText("ContextMenu_SmarterStorage_Reset"), button, function() SmarterStorage:resetSmarterStorageData(SmarterStorage.targetButton, page) end)
            
            local gearSubMenuContents = context:getNew(presetsSubMenuContents)
            local gearSubMenu = presetsSubMenuContents:addOption(getText("IGUI_SmarterStorage_Gear"), nil, nil)
            presetsSubMenuContents:addSubMenu(gearSubMenu, gearSubMenuContents)

            local weaponsSubMenuContents = context:getNew(gearSubMenuContents)
            local weapons = {"Weapons", "MeleeWeapons", "Shotguns", "Pistols", "Rifles"}
            for i=1, #weapons do
                local option = weaponsSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. weapons[i]), page, function() SmarterStorage:applyPreset(page, weapons[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[weapons[i]].item)
            end
            local weaponsSubMenu = gearSubMenuContents:addOption(getText("IGUI_SmarterStorage_Weapons"), nil, nil)
            gearSubMenuContents:addSubMenu(weaponsSubMenu, weaponsSubMenuContents)

            local ammoSubMenuContents = context:getNew(gearSubMenuContents)
            local ammo = {"Ammo", "PistolBullets", "RifleBullets", "ShotgunShells"}
            for i=1, #ammo do
                local option = ammoSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. ammo[i]), page, function() SmarterStorage:applyPreset(page, ammo[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[ammo[i]].item)
            end
            local ammoSubMenu = gearSubMenuContents:addOption(getText("IGUI_SmarterStorage_Ammo"), nil, nil)
            gearSubMenuContents:addSubMenu(ammoSubMenu, ammoSubMenuContents)

            local gear = {"Tools", "Clothing", "Explosives"}
            for i=1, #gear do
                local option = gearSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. gear[i]), page, function() SmarterStorage:applyPreset(page, gear[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[gear[i]].item)
            end
        
            local storageSubMenuContents = context:getNew(presetsSubMenuContents)
            local storageSubMenu = presetsSubMenuContents:addOption(getText("IGUI_SmarterStorage_Storage"), nil, nil)
            presetsSubMenuContents:addSubMenu(storageSubMenu, storageSubMenuContents)
            local storage = {"Backpacks", "Containers"}
            for i=1, #storage do
                local option = storageSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. storage[i]), page, function() SmarterStorage:applyPreset(page, storage[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[storage[i]].item)
            end

            local mediaSubMenuContents = context:getNew(presetsSubMenuContents)
            local mediaSubMenu = presetsSubMenuContents:addOption(getText("IGUI_RadioMedia"), nil, nil)
            presetsSubMenuContents:addSubMenu(mediaSubMenu, mediaSubMenuContents)
            local media = {"Literature", "DigitalMedia"}
            for i=1, #media do
                local option = mediaSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. media[i]), page, function() SmarterStorage:applyPreset(page, media[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[media[i]].item)
            end

            local survivalSubMenuContents = context:getNew(presetsSubMenuContents)
            local survivalSubMenu = presetsSubMenuContents:addOption(getText("IGUI_perks_Survivalist"), nil, nil)
            presetsSubMenuContents:addSubMenu(survivalSubMenu, survivalSubMenuContents)
            local survival = {"Medical", "Food", "Drinks", "Gardening", "Camping", "Cooking", "Fishing"}
            for i=1, #survival do
                local option = survivalSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. survival[i]), page, function() SmarterStorage:applyPreset(page, survival[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[survival[i]].item)
            end
            
            local uncategorizedPresets = {"AnimalParts", "Automotive", "Household", "Materials", "Electronics", "Junk", "Furniture"}
            for i=1, #uncategorizedPresets do
                local option = presetsSubMenuContents:addOption(getText("IGUI_SmarterStorage_" .. uncategorizedPresets[i]), page, function() SmarterStorage:applyPreset(page, uncategorizedPresets[i]) end)
                option.iconTexture = SmarterStorage:getItemTexture(SmarterStorage.presets[uncategorizedPresets[i]].item)
            end
        end
    end
end

function SmarterStorage:applyPreset(inventoryPage, preset)
    if not preset then return end

    if SmarterStorage.presets[preset] == nil then return end
    SmarterStorageUI:setTargetButton(SmarterStorage.targetButton)
    SmarterStorageUI:setSmarterStorageData(getText("IGUI_SmarterStorage_" .. SmarterStorage.presets[preset].name), SmarterStorage.presets[preset].item, SmarterStorage.presets[preset].color, inventoryPage)
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

function SmarterStorage:copySmarterStorageData(containerButton, parent)
    if not containerButton then return end
    
    local modData = containerButton.inventory:getParent() and containerButton.inventory:getParent():getModData()
    if not modData then return end

    local name = ""
    local icon = ""
    local r, g, b, a = "", "", "", ""

    if modData.SmarterStorage_Name and modData.SmarterStorage_Name ~= "" then
        name = modData.SmarterStorage_Name
    end
    if modData.SmarterStorage_Icon and modData.SmarterStorage_Icon ~= "" then
        icon = modData.SmarterStorage_Icon
    end
    if modData.SmarterStorage_Color then
        r = modData.SmarterStorage_Color.r
        g = modData.SmarterStorage_Color.g
        b = modData.SmarterStorage_Color.b
        a = modData.SmarterStorage_Color.a
    end
    
    Clipboard.setClipboard("SSName:" .. name .. "|SSColor:" .. r .. "," .. g .. "," .. b .. "," .. a .. "|SSIcon:" .. icon)
end

function SmarterStorage:pasteSmarterStorageData(containerButton, parent)
    local modData = containerButton.inventory:getParent() and containerButton.inventory:getParent():getModData()
    if not modData then return end

    local input = Clipboard.getClipboard()
    local data = {}
    local ssNameFound, ssColorFound, ssIconFound = false, false, false

    for field in input:gmatch("[^|]+") do
        local key, value = field:match("^(%w+):(.*)$")
        if key and value ~= nil then
            if key == "SSColor" then
                local r, g, b, a = value:match("([^,]+),([^,]+),([^,]+),([^,]+)")
                r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
                if r and g and b and a then
                    data[key] = {r = r, g = g, b = b, a = a}
                    ssColorFound = true
                else
                    return "Error: SSColor values must be valid numbers"
                end
            elseif key == "SSName" then
                data[key] = value
                ssNameFound = true
            elseif key == "SSIcon" then
                data[key] = value
                ssIconFound = true
            else
                data[key] = value
            end
        end
    end

    if not ssNameFound or not ssColorFound or not ssIconFound then
        return "Error: Missing required fields (SSName, SSColor, SSIcon)"
    end

    if data.SSColor then
        data.SSColor.rgba = {r = data.SSColor.r, g = data.SSColor.g, b = data.SSColor.b, a = data.SSColor.a}
    else
        modData.SmarterStorage_Color = nil
    end

    SmarterStorageUI:setTargetButton(SmarterStorage.targetButton)
    SmarterStorageUI:setSmarterStorageData(data.SSName, data.SSIcon, data.SSColor.rgba, parent)
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

    -- devs commented out the below func in 42.12 idk why. idk why i needed it in the first place. i just know i did. lol.
    -- self:syncToggleStove()
end

-- HELPER FUNCTIONS
function SmarterStorage:lightenRGBA(r, g, b, a, factor)
    if not r or not g or not b or not a or not factor then
        -- print("lightenRGBA: All arguments must be provided.")
        return nil, nil, nil, nil
    end

    factor = math.max(0, math.min(factor, 1))

    local newR = math.min(1.0, r + (1.0 - r) * factor)
    local newG = math.min(1.0, g + (1.0 - g) * factor)
    local newB = math.min(1.0, b + (1.0 - b) * factor)

    return newR, newG, newB, a
end

function SmarterStorage:getItemTexture(itemName)
    -- the old icon name stored in modData was the texture name. for example... Item_BulletMold
    -- the new way is the items full name from the getFullName() function. for example... Base.223BulletsMold
    -- this change was needed to support modded items.
    if not itemName then return end

    local itemClass = instanceItem(itemName)
    return itemClass and itemClass:getTexture() or getTexture(itemName)
end
