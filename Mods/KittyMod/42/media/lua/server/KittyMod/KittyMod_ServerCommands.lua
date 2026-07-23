--[[
require("shared/KittyMod/Utils/CatLover_ItemManager")

local function onServerCommand(module, command, player, args)
    if module ~= "KittyMod" then return end
    
    if command == "SpawnCatLoverItem" then
        if not player then return end
        
        local modData = player:getModData()
        if modData.CatLoverSpawned then
            return
        end
        
        if not player:HasTrait("CatLover_Trait") then
            return
        end
        

        local item, itemID = CatLover_ItemManager.createCatLoverItem(player)
        if item and itemID then
            modData.CatLoverSpawned = true
            local syncSuccess, syncError = pcall(function()
                syncItemModData(player, item)
            end)
            if not syncSuccess then
            end
        end
    end
end

Events.OnClientCommand.Add(onServerCommand)
--]]