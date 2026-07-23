--[[
    Input.lua - Hotkey and Context Menu Handling
    
    Handles:
    - Smoke/stop hotkey presses
    - Finding smokables in inventory
    - Context menu integration
    - Shemagh/mask management
]]

require 'ISUI/ISInventoryPaneContextMenu'
require 'Core'
require 'Data'

--------------------------------------------------------------------------------
-- Light Source Detection
--------------------------------------------------------------------------------

--- Check if player has a required light source to smoke
-- @param smokable InventoryItem The smokable item
-- @param player IsoPlayer
-- @return InventoryItem|boolean Light source item or true/false
function TrueSmoking.hasLightSource(smokable, player)
    local required = smokable:getRequireInHandOrInventory()
    if not required then return true end
    
    -- Build lookup table of required types
    local types = {}
    for i = 1, required:size() do
        types[moduleDotType(smokable:getModule(), required:get(i - 1))] = true
    end
    
    -- Check vehicle lighter
    local vehicle = player:getVehicle()
    if vehicle and vehicle:canLightSmoke(player) then
        return true
    end
    
    -- Check for open flame
    if ISInventoryPaneContextMenu.hasOpenFlame(player) then
        return true
    end
    
    -- Check inventory for light sources
    local function hasUses(item)
        return item:getCurrentUsesFloat() > 0
    end
    
    local items = player:getInventory():getItems()
    for i = 1, items:size() do
        local item = items:get(i - 1)
        if types[item:getFullType()] and hasUses(item) then
            return item
        end
    end
    
    -- Check containers
    for typeName in pairs(types) do
        local item = player:getInventory():getFirstTypeRecurse(typeName)
        if item and hasUses(item) then
            return item
        end
    end
    
    return false
end

--------------------------------------------------------------------------------
-- Smokable Finding (Hotkey)
--------------------------------------------------------------------------------

--- Find and use a smokable from inventory
-- Priority: favorite cig > favorite pack > any cig > any pack
-- @param player IsoPlayer
function TrueSmoking.findAndSmoke(player)
    local found = {
        favCig = nil,
        favPack = nil,
        cig = nil,
        pack = nil,
    }
    
    local function scan(inv)
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local isSmokable = item:hasTag(ItemTag.SMOKABLE) and not item:hasTag(ItemTag.PACKED)
            local isPacked = item:hasTag(ItemTag.PACKED)
            
            if isSmokable then
                if item:isFavorite() then
                    found.favCig = found.favCig or item
                else
                    found.cig = found.cig or item
                end
            elseif isPacked then
                if item:isFavorite() then
                    found.favPack = found.favPack or item
                else
                    found.pack = found.pack or item
                end
            end
        end
    end
    
    -- Scan main inventory
    scan(player:getInventory())
    
    -- Scan worn containers
    local worn = player:getWornItems()
    for i = 0, worn:size() - 1 do
        local item = worn:get(i).item
        if item and item:IsInventoryContainer() then
            scan(item:getInventory())
        end
    end
    
    -- Use best match
    if found.favCig and TrueSmoking.hasLightSource(found.favCig, player) then
        ISInventoryPaneContextMenu.eatItem(found.favCig, 1, player:getPlayerNum())
        return
    end
    
    if found.favPack then
        TrueSmoking.useRecipe(found.favPack, player)
        return
    end
    
    if found.cig and TrueSmoking.hasLightSource(found.cig, player) then
        ISInventoryPaneContextMenu.eatItem(found.cig, 1, player:getPlayerNum())
        return
    end
    
    if found.pack then
        TrueSmoking.useRecipe(found.pack, player)
    end
end

--- Use a recipe on an item (for taking from pack)
-- @param item InventoryItem
-- @param player IsoPlayer
function TrueSmoking.useRecipe(item, player)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local recipes = CraftRecipeManager.getUniqueRecipeItems(item, player, containers)
    
    if recipes and recipes:size() > 0 then
        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i)
            if string.match(recipe:getName(), 'Take') then
                ISInventoryPaneContextMenu.OnNewCraft(item, recipe, player:getPlayerNum(), false)
                return
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Shemagh Management
--------------------------------------------------------------------------------

local SHEMAGH_COVERS = {
    ['Base.Hat_ShemaghFull']         = 'Base.Hat_ShemaghFace',
    ['Base.Hat_ShemaghFull_Green']   = 'Base.Hat_ShemaghFace_Green',
    ['Base.Hat_ShemaghFull_Cotton']  = 'Base.Hat_ShemaghFace_Cotton',
    ['Base.Hat_ShemaghFull_Burlap']  = 'Base.Hat_ShemaghFace_Burlap',
}

local SHEMAGH_SCARVES = {
    ['Base.ShemaghScarfFace']        = 'Base.ShemaghScarf',
    ['Base.ShemaghScarfFace_Green']  = 'Base.ShemaghScarf_Green',
}

--- Get shemagh covering player's face
-- @param player IsoPlayer
-- @param reCover boolean If true, find any shemagh for re-covering
-- @return InventoryItem|false
function TrueSmoking.getShemagh(player, reCover)
    local slots = { 'FullHat', 'Hat', 'Neck', 'Scarf', 'Mask' }
    
    for _, slot in ipairs(slots) do
        local item = player:getWornItem(slot)
        if item and item ~= '' then
            local fullType = item:getFullType()
            if fullType:contains('Shemagh') then
                if item:hasTag('TrueSmoking:CantSmoke') or reCover then
                    return item
                end
            end
        end
    end
    
    return false
end

--- Adjust shemagh to cover/uncover face
-- @param player IsoPlayer
-- @param item InventoryItem The shemagh
-- @param uncover boolean True to uncover face
function TrueSmoking.adjustShemagh(player, item, uncover)
    local fullType = item:getFullType()
    
    local function trySwap(covers)
        for covered, open in pairs(covers) do
            local target = uncover and open or covered
            if (fullType == covered and uncover) or (fullType == open and not uncover) then
                ISTimedActionQueue.add(ISClothingExtraAction:new(player, item, target))
                return true
            end
        end
        return false
    end
    
    if trySwap(SHEMAGH_COVERS) then return end
    trySwap(SHEMAGH_SCARVES)
end

--- Re-equip mask and shemagh after smoking
-- @param player IsoPlayer
function TrueSmoking.checkForMaskAndEquip(player)
    if not player then return end
    
    local data = player:getModData().TrueSmoking
    if not data then return end
    
    -- Re-equip stored mask
    if data.mask and instanceof(data.mask, 'InventoryItem') then
        ISTimedActionQueue.add(ISWearClothing:new(player, data.mask))
    end
    
    -- Re-cover shemagh
    if data.shemagh then
        local shemagh = TrueSmoking.getShemagh(player, true)
        if shemagh then
            TrueSmoking.adjustShemagh(player, shemagh, false)  -- false = cover
        end
    end
end

--------------------------------------------------------------------------------
-- Hotkey Handler
--------------------------------------------------------------------------------

--- Handle smoke-related key presses
-- @param key number Key code
function TrueSmoking.onKeyPressed(key)
    local player = getPlayer()
    if not player then return end
    
    local data = TrueSmoking.Data.getSmoking(player)
    local ref = TrueSmoking.getPlayerRef(player)
    local config = TrueSmoking.Config
    
    if not ref.smokable or not ref.smokable.putOut then
        data.isSmoking = false
    end
    
    -- Puff/light while smoking
    if data.isSmoking and key == config.keySmoke then
        if ref.smokable.smokeLit then
            ref.smokable:puff()
        else
            ref.smokable:light()
        end
        return
    end
    
    -- Find smokable when not smoking
    if not data.isSmoking and key == config.keySmoke and config.FindSmoke then
        TrueSmoking.findAndSmoke(player)
        return
    end
    
    -- Put out cigarette
    if data.isSmoking and key == config.keyStopSmoke then
        ref.smokable:putOut()
        return
    end
    
    -- Re-equip mask when not smoking
    if not data.isSmoking and key == config.keyStopSmoke then
        local modData = player:getModData().TrueSmoking
        if modData and modData.mask and TrueSmoking.Options.ManageHeadGear then
            ISTimedActionQueue.add(ISWearClothing:new(player, modData.mask))
        end
    end
end

--------------------------------------------------------------------------------
-- Context Menu Integration
--------------------------------------------------------------------------------

--- Modify context menu smoke option availability
-- @param playerNum number Player index
-- @param context ISContextMenu
-- @param items table Selected items
function TrueSmoking.onContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    
    local data = player:getModData().TrueSmoking
    if not data then return end
    
    for _, v in ipairs(items) do
        local item = instanceof(v, 'InventoryItem') and v or v.items[1]
        local option = context:getOptionFromName(getText('ContextMenu_Smoke'))
        
        if option then
            if data.isSmoking or not TrueSmoking.hasLightSource(item, player) then
                option.notAvailable = true
            else
                option.notAvailable = false
            end
        end
    end
end
