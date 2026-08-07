local AE_TamingKeyHandler = {}
local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
local AE_SystemRouter = require("AnimalsEssentials/Core/AE_SystemRouter")

local function playerHasAcceptedFood(player, animal)
    if not player or not animal then return false end
    
    local inventory = player:getInventory()
    if not inventory then return false end
    
    -- Get animal category to check accepted foods
    local animalCategory = AnimalRegistry.GetAnimalType(animal)
    if not animalCategory then 
        print("[TAMING DEBUG] Could not determine animal category")
        return false 
    end
    
    print("[TAMING DEBUG] Checking accepted foods for category: " .. tostring(animalCategory))
    
    -- Get taming configuration for this animal category
    local tamingConfig = Config.GetTamingConfig(animalCategory)
    if not tamingConfig or not tamingConfig.AcceptedFoods then
        print("[TAMING DEBUG] No taming config or accepted foods found")
        return false
    end
    
    -- Check if player has any of the accepted foods
    for foodType, _ in pairs(tamingConfig.AcceptedFoods) do
        if inventory:contains(foodType) then
            print("[TAMING DEBUG] Found accepted food: " .. tostring(foodType))
            return true
        end
    end
    
    print("[TAMING DEBUG] No accepted foods found in inventory")
    return false
end

local function getNearestTameableAnimal(player)
    if not player then return nil end
    
    local playerX, playerY = player:getX(), player:getY()
    local nearestAnimal = nil
    local nearestDistance = 3.0
    
    local cell = player:getCell()
    if not cell then return nil end
    
    for x = playerX - 3, playerX + 3 do
        for y = playerY - 3, playerY + 3 do
            local square = cell:getGridSquare(x, y, 0)
            if square then
                local animals = square:getAnimals()
                for i = 0, animals:size() - 1 do
                    local animal = animals:get(i)
                    if animal then
                        local distance = IsoUtils.DistanceTo(playerX, playerY, animal:getX(), animal:getY())
                        if distance < nearestDistance then
                            nearestAnimal = animal
                            nearestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return nearestAnimal
end

function AE_TamingKeyHandler.onKeyPressed(key)
    if key ~= 18 then return end -- E key is 18
    
    local player = getPlayer()
    if not player then 
        print("[TAMING DEBUG] ERROR: No player found")
        return 
    end
    print("[TAMING DEBUG] Player found: " .. tostring(player:getDisplayName()))
    
    local animal = getNearestTameableAnimal(player)
    if not animal then 
        print("[TAMING DEBUG] No nearby tameable animal found")
        return 
    end
    print("[TAMING DEBUG] Found animal: " .. tostring(animal:getAnimalType()))
    
    local inventory = player:getInventory()
    if not inventory then return end
    
    local hasAcceptedFood = playerHasAcceptedFood(player, animal)
    print("[TAMING DEBUG] Player has accepted food: " .. tostring(hasAcceptedFood))
    if not hasAcceptedFood then
        print("[TAMING DEBUG] No accepted food found, aborting")
        return
    end
    
    AE_SystemRouter.processTamingAttempt(animal, player)
end

function AE_TamingKeyHandler.initialize()
    if Events and Events.OnKeyPressed then
        Events.OnKeyPressed.Add(AE_TamingKeyHandler.onKeyPressed)
    end
end

Events.OnGameStart.Add(AE_TamingKeyHandler.initialize)

return AE_TamingKeyHandler