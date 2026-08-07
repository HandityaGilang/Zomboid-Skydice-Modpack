--[[
CatLover_ItemManager = {}

function CatLover_ItemManager.generateItemID()
    return string.format("CAT-%04d-%04d", 
        ZombRand(1000, 9999),
        ZombRand(1000, 9999)
    )
end

function CatLover_ItemManager.createCatLoverItem(player)
    if not player then
        return nil, nil
    end
    
    local item = player:getInventory():AddItem("Base.CatToy")
    if item then
        local stringID = CatLover_ItemManager.generateItemID()
        item:getModData().CatLover_ItemID = stringID
        player:getModData().CatLoverItemID = stringID
        if isServer() then
            local transmitSuccess, transmitError = pcall(function()
                player:transmitModData()
            end)
            if not transmitSuccess then
            end
        end
        
        return item, stringID
    end
    return nil, nil
end

function CatLover_ItemManager.restoreCatLoverItem(player)
    if not player then return end
    
    local modData = player:getModData()
    if modData.CatLoverSpawned and modData.CatLoverItemID then
        local savedID = modData.CatLoverItemID
        
        local existingItem = CatLover_ItemManager.findItemWithID(player:getInventory(), savedID)
        if not existingItem then
            local newItem = player:getInventory():AddItem("Base.CatToy")
            if newItem then
                newItem:getModData().CatLover_ItemID = savedID
            end
        end
    end
end

function CatLover_ItemManager.findItemWithID(inventory, targetID)
    if not inventory or not targetID then
        return nil
    end
    
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:getModData().CatLover_ItemID == targetID then
            return item
        end
    end
    return nil
end

function CatLover_ItemManager.validateItemIntegrity(player)
    if not player then return false end
    
    local modData = player:getModData()
    if modData.CatLoverSpawned and modData.CatLoverItemID then
        local existingItem = CatLover_ItemManager.findItemWithID(player:getInventory(), modData.CatLoverItemID)
        return existingItem ~= nil
    end
    return false
end

function CatLover_ItemManager.debugListCatLoverItems(player)
    if not player then return end
    
    local inventory = player:getInventory()
    local catLoverItems = {}
    
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and item:getModData().CatLover_ItemID then
            table.insert(catLoverItems, {
                item = item,
                id = item:getModData().CatLover_ItemID,
                type = item:getType()
            })
        end
    end
end

function CatLover_ItemManager.initialize()
    return true
end

CatLover_ItemManager.initialize()

_G.CatLover_ItemManager = CatLover_ItemManager


return CatLover_ItemManager
--]]