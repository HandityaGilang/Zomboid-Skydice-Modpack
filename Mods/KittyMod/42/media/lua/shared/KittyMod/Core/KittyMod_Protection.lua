local KittyMod_Protection = {}

local catBackups = {}
local backupTimeout = 300000

function KittyMod_Protection.initialize()
    if Events then
        if Events.OnObjectMove then
            Events.OnObjectMove.Add(KittyMod_Protection.onObjectMove)
        end
        if Events.OnGameStart then
            Events.OnGameStart.Add(KittyMod_Protection.cleanupOldBackups)
        end
    end
end

function KittyMod_Protection.onObjectMove(object)
    if not object or not object:isAnimal() then return end
    
    local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
    if not KittyMod_ModData.isCat(object) then return end
    
    if KittyMod_Protection.isPickupAction(object) then
        KittyMod_Protection.backupCatData(object)
    elseif KittyMod_Protection.isPutdownAction(object) then
        KittyMod_Protection.restoreCatDataIfNeeded(object)
    end
end

function KittyMod_Protection.isPickupAction(cat)
    return cat:getContainer() ~= nil
end

function KittyMod_Protection.isPutdownAction(cat)
    return cat:getContainer() == nil and KittyMod_Protection.hasRecentBackup(cat)
end

function KittyMod_Protection.backupCatData(cat)
    if not cat then return false end
    
    local catID = cat.animalId or cat:getOnlineID()
    if not catID then return false end
    
    local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
    
    catBackups[catID] = {
        catModData = {},
        vanillaData = {
            customName = cat.customName,
            hoursSurvived = cat:getHoursSurvived(),
            health = cat:getHealth(),
            fullGenome = cat.fullGenome,
            animalId = cat.animalId,
            isFemale = cat:isFemale(),
            wild = cat.wild,
            stressLevel = cat.stressLevel
        },
        timestamp = getTimestamp()
    }
    
    local modData = cat:getModData()
    for key, value in pairs(modData) do
        if key:startsWith("KITTY_") then
            catBackups[catID].catModData[key] = value
        end
    end
    return true
end

function KittyMod_Protection.restoreCatDataIfNeeded(cat)
    if not cat or not KittyMod_Protection.hasMissingCatData(cat) then return false end
    
    local catID = cat.animalId
    if not catID then return false end
    
    local backup = catBackups[catID]
    if not backup then
        return false
    end
    
    for key, value in pairs(backup.catModData) do
        cat:getModData()[key] = value
    end
    
    if backup.vanillaData.customName then
        cat.customName = backup.vanillaData.customName
    end
    if backup.vanillaData.hoursSurvived then
        cat:setHoursSurvived(backup.vanillaData.hoursSurvived)
    end
    if backup.vanillaData.health then
        cat:setHealth(backup.vanillaData.health)
    end
    if backup.vanillaData.fullGenome then
        cat.fullGenome = backup.vanillaData.fullGenome
    end
    if backup.vanillaData.wild ~= nil then
        cat.wild = backup.vanillaData.wild
    end
    if backup.vanillaData.stressLevel then
        cat.stressLevel = backup.vanillaData.stressLevel
    end
    catBackups[catID] = nil
    return true
end

function KittyMod_Protection.hasMissingCatData(cat)
    if not cat then return false end
    local modData = cat:getModData()
    return modData["KITTY_Breed"] == nil or modData["KITTY_Tameness"] == nil
end

function KittyMod_Protection.hasRecentBackup(cat)
    if not cat then return false end
    local catID = cat.animalId
    if not catID or not catBackups[catID] then return false end
    local currentTime = getTimestamp()
    local backupAge = currentTime - catBackups[catID].timestamp
    return backupAge <= backupTimeout
end

function KittyMod_Protection.cleanupOldBackups()
    local currentTime = getTimestamp()
    local toRemove = {}
    for catID, backup in pairs(catBackups) do
        local backupAge = currentTime - backup.timestamp
        if backupAge > backupTimeout then
            table.insert(toRemove, catID)
        end
    end
    for _, catID in ipairs(toRemove) do
        catBackups[catID] = nil
    end
    if #toRemove > 0 then
    end
end

function KittyMod_Protection.manualBackup(cat)
    return KittyMod_Protection.backupCatData(cat)
end

function KittyMod_Protection.manualRestore(cat)
    return KittyMod_Protection.restoreCatDataIfNeeded(cat)
end

function KittyMod_Protection.getBackupInfo(catID)
    if catBackups[catID] then
        return {
            timestamp = catBackups[catID].timestamp,
            age = getTimestamp() - catBackups[catID].timestamp,
            hasData = true
        }
    end
    return {hasData = false}
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(KittyMod_Protection.initialize)
end

return KittyMod_Protection