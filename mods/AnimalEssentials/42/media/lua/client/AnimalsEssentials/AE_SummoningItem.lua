local AE_SummoningItem = {}

function AE_SummoningItem.createMenuEntry(player, context, items)
    for i = 1, #items do
        local item = items[i]
        if not instanceof(item, "InventoryItem") then
            item = item.items[1]
        end

        if item:getFullType() == "Base.CatToy" or
           item:getType() == "CatToy" then
            local displayName = "Summon Cat"

            context:addOption(displayName, item, AE_SummoningItem.onSummon, player)
            return
        end
    end
end

function AE_SummoningItem.onSummon(item, player)
    print("[AE_SummoningItem] CLIENT: onSummon called")
    
    local player = getPlayer()
    if not player then 
        print("[AE_SummoningItem] CLIENT: getPlayer() failed")
        return 
    end
    print("[AE_SummoningItem] CLIENT: Player object acquired")

    if item then
        local inventory = player:getInventory()
        if not inventory then 
            print("[AE_SummoningItem] CLIENT: getInventory() failed")
            return 
        end
        inventory:Remove(item)
        print("[AE_SummoningItem] CLIENT: Item removed from inventory")
    end

    if not player then
        print("[AE_SummoningItem] CLIENT: Player check failed")
        return
    end
    
    local spawnX = player:getX()
    local spawnY = player:getY()
    local spawnZ = player:getZ()
    
    print("[AE_SummoningItem] CLIENT: Coordinates - x: " .. tostring(spawnX) .. ", y: " .. tostring(spawnY) .. ", z: " .. tostring(spawnZ))
    print("[AE_SummoningItem] CLIENT: Using validated spawning system")

    local animal = AE_SummoningItem.spawnCatWithWeightSystem(spawnX, spawnY, spawnZ)
    if animal then
        print("[AE_SummoningItem] CLIENT: Cat spawned successfully!")
    else
        print("[AE_SummoningItem] CLIENT: All spawning attempts failed")
    end
end

function AE_SummoningItem.selectWeightedVariant()
    local catSpawnOptions = {
        {variant = "babykitten", weight = 31.75},
        {variant = "babykittenmanx", weight = 31.75},
        
  
        {variant = "tom", weight = 8},
        {variant = "queen", weight = 8},
        {variant = "tommanx", weight = 8},
        {variant = "queenmanx", weight = 8},
        
        {variant = "babysmokeykitten", weight = 1.5},
        {variant = "smokeyboi", weight = 1.5},  
        {variant = "smokeygirly", weight = 1.5}
    }
    
    local totalWeight = 0
    for _, entry in ipairs(catSpawnOptions) do
        totalWeight = totalWeight + entry.weight
    end
    
    local randomValue = ZombRand(totalWeight * 100) / 100
    
    local currentWeight = 0
    for _, entry in ipairs(catSpawnOptions) do
        currentWeight = currentWeight + entry.weight
        if randomValue <= currentWeight then
            return entry.variant
        end
    end
    
    return "babykitten"
end

function AE_SummoningItem.spawnCatWithWeightSystem(x, y, z)
    local AE_RouterIntegrationUtils = require("AnimalsEssentials/Core/AE_RouterIntegrationUtils")
    
    local player = getPlayer()
    if not player then
        return false
    end
    
    return AE_RouterIntegrationUtils.routedSpawnCat(player, x, y, z, 3)
end

function AE_SummoningItem.Initialize()
    Events.OnFillInventoryObjectContextMenu.Add(AE_SummoningItem.createMenuEntry)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(AE_SummoningItem.Initialize)
else
    AE_SummoningItem.Initialize()
end

return AE_SummoningItem