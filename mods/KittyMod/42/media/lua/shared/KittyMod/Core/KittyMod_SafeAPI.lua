local KittyMod_SafeAPI = {}

local apiChecked = false
local apiAvailable = {
    getAnimalsInRange = false,
    getAnimalByID = false,
    animalsEssentialsCore = false
}

function KittyMod_SafeAPI.initialize()
    if apiChecked then return end
    
    KittyMod_SafeAPI.checkAPIAvailability()
    apiChecked = true
end

function KittyMod_SafeAPI.checkAPIAvailability()
    local player = getPlayer()
    if player then
        local cell = player:getCell()
        if cell then
            apiAvailable.getAnimalsInRange = (cell.getAnimalsInRange ~= nil)
        end
    end
    
    local testAnimal = {}
    apiAvailable.getAnimalByID = (getAnimalByID ~= nil)
    
    local success, _ = pcall(function()
        return require("AnimalsEssentials/Core/AE_Core")
    end)
    apiAvailable.animalsEssentialsCore = success
end

function KittyMod_SafeAPI.getAnimalsInRange(player, range)
    if not player then return nil end
    
    KittyMod_SafeAPI.initialize()
    
    local cell = player:getCell()
    if not cell then return nil end
    
    local x, y = player:getX(), player:getY()
    if not x or not y then return nil end
    
    if apiAvailable.getAnimalsInRange then
        local success, animals = pcall(function()
            return cell:getAnimalsInRange(x, y, range)
        end)
        
        if success then
            return animals
        end
    end
    
    return nil
end

function KittyMod_SafeAPI.safeGetAnimalByID(animalID)
    if not animalID then return nil end
    
    KittyMod_SafeAPI.initialize()
    
    if apiAvailable.getAnimalByID then
        local success, animal = pcall(function()
            return getAnimalByID(animalID)
        end)
        
        if success then
            return animal
        end
    end
    
    return nil
end

function KittyMod_SafeAPI.isAPIAvailable(apiName)
    KittyMod_SafeAPI.initialize()
    return apiAvailable[apiName] or false
end

function KittyMod_SafeAPI.requireFrameworkModule(modulePath)
    local success, module = pcall(function()
        return require(modulePath)
    end)
    
    if success and module then
        return module
    end
    
    return nil
end

function KittyMod_SafeAPI.executeFrameworkFunction(module, functionName, ...)
    if not module or not module[functionName] then
        return nil
    end
    
    local success, result = pcall(module[functionName], ...)
    if success then
        return result
    end
    
    return nil
end

function KittyMod_SafeAPI.getAPIStatus()
    KittyMod_SafeAPI.initialize()
    return {
        checked = apiChecked,
        available = apiAvailable,
        frameworkPresent = apiAvailable.animalsEssentialsCore
    }
end

return KittyMod_SafeAPI