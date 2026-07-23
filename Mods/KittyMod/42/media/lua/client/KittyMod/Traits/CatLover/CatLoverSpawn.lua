
--[[
require("shared/KittyMod/Utils/CatLover_ItemManager")

local function handleCatLoverSpawn()
    local player = getPlayer()
    if not player then return end
    
    if not player.HasTrait or not player:HasTrait("CatLover_Trait") then
        return
    end
    
    local modData = player:getModData()
    if modData.CatLoverSpawned then
        CatLover_ItemManager.restoreCatLoverItem(player)
        return
    end
    
    if isClient() then
        sendServerCommand("KittyMod", "SpawnCatLoverItem", {playerID = player:getPlayerNum()})
    else
        local item, itemID = CatLover_ItemManager.createCatLoverItem(player)
        if item and itemID then
            modData.CatLoverSpawned = true
        end
    end
end

local function onCreatePlayer(playerIndex, player)
    if player == getPlayer() then
        handleCatLoverSpawn()
    end
end

local function onPlayerLoad(player)
    if player == getPlayer() then
        CatLover_ItemManager.restoreCatLoverItem(player)
    end
end

-- Register event handlers
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(function()
    local player = getPlayer()
    if player then
        onPlayerLoad(player)
    end
end)
--]]