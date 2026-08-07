local AZB42_SYNC_MODULE = "AZB42InventorySync"

local function refreshInventory(playerNum)
    playerNum = playerNum or 0

    if getPlayerInventory then
        local inventoryPage = getPlayerInventory(playerNum)
        if inventoryPage and inventoryPage.refreshBackpacks then
            inventoryPage:refreshBackpacks()
        end
    end

    if getPlayerLoot then
        local lootPage = getPlayerLoot(playerNum)
        if lootPage and lootPage.refreshBackpacks then
            lootPage:refreshBackpacks()
        end
    end

    if getPlayerData then
        local pdata = getPlayerData(playerNum)
        if pdata then
            if pdata.playerInventory and pdata.playerInventory.refreshBackpacks then
                pdata.playerInventory:refreshBackpacks()
            end
            if pdata.lootInventory and pdata.lootInventory.refreshBackpacks then
                pdata.lootInventory:refreshBackpacks()
            end
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= AZB42_SYNC_MODULE or command ~= "refreshInventory" then
        return
    end

    refreshInventory(args and args.playerNum or 0)
end

Events.OnServerCommand.Add(onServerCommand)
