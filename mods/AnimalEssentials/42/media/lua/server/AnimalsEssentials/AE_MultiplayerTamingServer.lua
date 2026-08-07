local function getAnimalByID(animalID)
    local cell = getCell()
    if not cell then return nil end
    
    for x = 0, cell:getGridWidth() - 1 do
        for y = 0, cell:getGridHeight() - 1 do
            local square = cell:getGridSquare(x, y, 0)
            if square then
                local animals = square:getAnimals()
                for i = 0, animals:size() - 1 do
                    local animal = animals:get(i)
                    if animal and (animal:getOnlineID() == animalID or animal:getID() == animalID) then
                        return animal
                    end
                end
            end
        end
    end
    return nil
end

local function onServerCommand(module, command, player, args)
    if module ~= "AE_TamingService" then return end
    
    if command == "feedAnimal" then
        local animal = getAnimalByID(args.animalID)
        if animal then
            local AE_TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
            local success = AE_TamingSystem.FeedAnimal(animal, player)
            
            sendClientCommand(player, "AE_TamingService", "feedResult", {
                success = success,
                animalID = args.animalID
            })
        end
    end
end

Events.OnClientCommand.Add(onServerCommand)