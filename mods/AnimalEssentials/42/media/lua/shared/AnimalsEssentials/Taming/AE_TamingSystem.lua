local AE_TamingSystem = {}
local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
local AE_DataConfig = require("AnimalsEssentials/Config/AE_DataConfig")
local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
local AE_OperationGuards = require("AnimalsEssentials/Foundation/AE_OperationGuards")
local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local SandboxSettings = nil
local function getSandboxSettings()
    if not SandboxSettings then
        local success, result = pcall(function()
            return require("AnimalsEssentials/Config/AE_SandboxSettings")
        end)
        if success and result then
            SandboxSettings = result
        else
            SandboxSettings = {
                GetMaxTamedAnimals = function() return 3 end,
                GetTamingGainMultiplier = function() return 1.0 end
            }
        end
    end
    
    if not SandboxSettings or not SandboxSettings.GetMaxTamedAnimals then
        SandboxSettings = {
            GetMaxTamedAnimals = function() return 3 end,
            GetTamingGainMultiplier = function() return 1.0 end
        }
    end
    
    return SandboxSettings
end
local BehaviorManager = nil
local function getBehaviorManager()
    if not BehaviorManager then
        BehaviorManager = require("AnimalsEssentials/BehaviorSystems/AE_BehaviorManager")
        if BehaviorManager and BehaviorManager.initialize then
            BehaviorManager.initialize()
        end
    end
    return BehaviorManager
end
local HomeLocation = nil
local function getHomeLocation()
    if not HomeLocation then
        HomeLocation = require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
    end
    return HomeLocation
end
AE_TamingSystem.KEY_TAMENESS = AE_DataConfig.ModDataKeys.Tameness
AE_TamingSystem.KEY_IS_TAMED = AE_DataConfig.ModDataKeys.IsTamed
AE_TamingSystem.KEY_OWNER = AE_DataConfig.ModDataKeys.Owner
AE_TamingSystem.KEY_NAME = AE_DataConfig.ModDataKeys.AnimalName
AE_TamingSystem.KEY_LAST_FOLLOW_UPDATE = AE_DataConfig.ModDataKeys.LastFollowUpdate
AE_TamingSystem.KEY_SLOT_ASSIGNED = AE_DataConfig.ModDataKeys.SlotAssigned
AE_TamingSystem.KEY_STABLE_ID = AE_DataConfig.ModDataKeys.StableID
AE_TamingSystem.KEY_PLAYER_TAMED_COUNT = "PlayerTamedAnimalsCount"
AE_TamingSystem.KEY_PLAYER_TAME_LIMIT_BONUS = "PlayerTameLimitBonus"
AE_TamingSystem.lastAlreadyTamedNotification = {}
AE_TamingSystem.ALREADY_TAMED_COOLDOWN = 30000
AE_TamingSystem.pendingSlotAssignments = {}
AE_TamingSystem.nextStableID = 1

AE_TamingSystem.animalsTamingInProgress = {}
AE_TamingSystem.tamingTimeouts = {}
AE_TamingSystem.TAMING_TIMEOUT_MS = 10000

AE_TamingSystem.persistentAnimalMapping = {}
AE_TamingSystem.instanceToPersistentMap = {}
AE_TamingSystem.mappingCleanupInterval = 36000
local function convertNameForID(name)
    if not name or name == "" then
        return nil
    end
    local sanitized = tostring(name):gsub("^%s*(.-)%s*$", "%1")
    sanitized = sanitized:gsub("%s+", "_")
    sanitized = sanitized:gsub("[^%w_]", "")
    sanitized = sanitized:lower()
    if #sanitized > Config.Naming.MaxNameLength then
        sanitized = sanitized:sub(1, Config.Naming.MaxNameLength)
    end
    if sanitized == "" then
        return nil
    end
    return sanitized
end
function AE_TamingSystem.GenerateAnimalID(playerName)
    local sanitizedName = convertNameForID(playerName)
    if not sanitizedName then
        return nil
    end
    return sanitizedName
end
function AE_TamingSystem.IsAnimalNameInUse(player, name)
    if not player or not name then return false end
    local sanitized = tostring(name):gsub("^%s*(.-)%s*$", "%1")
    sanitized = sanitized:gsub("%s+", "_")
    sanitized = sanitized:gsub("[^%w_]", "")
    sanitized = sanitized:lower()
    if #sanitized > Config.Naming.MaxNameLength then
        sanitized = sanitized:sub(1, Config.Naming.MaxNameLength)
    end
    if sanitized == "" then return false end
    local globalData = ModData.get(Config.GlobalModDataKeys.TamingData)
    if not globalData then return false end
    if not globalData.players then return false end
    local playerNum = player:getPlayerNum()
    local playerData = globalData.players[playerNum]
    if not playerData then return false end
    for i = 1, Config.Taming.MaxTamedSlots do
        local animalID = playerData[AE_TamingSystem.KEY_TAMED_SLOTS[i]]
        if animalID and animalID == sanitized then
            return true
        end
    end
    return false
end
AE_TamingSystem.animalCache = {}
AE_TamingSystem.lastCacheClear = 0
function AE_TamingSystem.IDsMatch(id1, id2)
    if not id1 or not id2 then return false end
    if id1 == id2 then return true end
    local id1Base = id1:match("^(.-)_%d+$") or id1
    local id2Base = id2:match("^(.-)_%d+$") or id2
    return id1Base == id2Base
end
local function getGlobalData()
    local globalData = ModData.get(Config.GlobalModDataKeys.TamingData)
    if not globalData then
        globalData = {}
        ModData.add(Config.GlobalModDataKeys.TamingData, globalData)
    end
    return globalData
end
local function getPlayerModData(player)
    if not player then return nil end
    local globalData = getGlobalData()
    local playerNum = player:getPlayerNum()
    if not globalData.players then
        globalData.players = {}
    end
    if not globalData.players[playerNum] then
        globalData.players[playerNum] = {}
    end
    return globalData.players[playerNum]
end
local function transmitGlobalData()
    ModData.transmit(Config.GlobalModDataKeys.TamingData)
end
function AE_TamingSystem.isValidAnimal(animal)
    if not animal then return false end

    if not AnimalRegistry.isInitialized then
        return false
    end

    local success, result = pcall(function()
        local animalType = animal:getAnimalType()
        if not animalType then return false end
        return AnimalRegistry.IsFrameworkAnimal(animal)
    end)
    if success then
        return result
    else
        return false
    end
end
function AE_TamingSystem.getAnimalModData(animal)
    if not animal then return nil end
    if not AE_TamingSystem.isValidAnimal(animal) then
        return nil
    end
    return AE_DataService.getAllModData(animal)
end
local function clampTameness(value)
    if type(value) ~= "number" or value ~= value then
        return 0.0
    end
    return math.min(100.0, math.max(0.0, value))
end
function AE_TamingSystem.Initialize(animal)
    if not Config.IsSystemEnabled("TamingSystem") then return false end
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    if AE_DataService.getTameness(animal) == nil then
        AE_DataService.setTameness(animal, 0.0)
        AE_DataService.setTamed(animal, false)
        AE_DataService.setOwner(animal, nil)
        AE_DataService.setAnimalName(animal, "Animal")
        AE_DataService.setSlotAssigned(animal, false)
        AE_DataService.setStableID(animal, nil)
    end
    local modData = AE_TamingSystem.getAnimalModData(animal)
    if not modData then return false end
    if modData[AE_DataConfig.ModDataKeys.CustomHunger] == nil then
        local success, vanillaHunger = pcall(function()
            local stats = animal:getStats()
            if stats then
                local h = stats:getHunger()
                if h ~= nil then return 100 - h end
            end
            return nil
        end)
        modData[AE_DataConfig.ModDataKeys.CustomHunger] = (success and vanillaHunger) or 70
    end
    if modData[AE_DataConfig.ModDataKeys.CustomThirst] == nil then
        local success, vanillaThirst = pcall(function()
            local stats = animal:getStats()
            if stats then
                local t = stats:getThirst()
                if t ~= nil then return 100 - t end
            end
            return nil
        end)
        modData[AE_DataConfig.ModDataKeys.CustomThirst] = (success and vanillaThirst) or 70
    end
    if AE_EnvironmentDetector.isSinglePlayer() then
        animal:transmitModData()
    else
        if not isClient() then
            animal:transmitModData()
        end
    end
    return true
end
function AE_TamingSystem.GetTameness(animal)
    if not AE_DataService.isAnimalValid(animal) then return 0.0 end
    local tameness = AE_DataService.getTameness(animal)
    return type(tameness) == "number" and tameness or 0.0
end
function AE_TamingSystem.SetTameness(animal, newValue)
    if not AE_DataService.isAnimalValid(animal) then return nil end
    local clampedValue = clampTameness(newValue)
    local success = AE_DataService.setTameness(animal, clampedValue)
    if not success then return nil end
    
    local animalCategory = AnimalRegistry.GetAnimalType(animal)
    local tamingConfig = Config.GetTamingConfig(animalCategory)
    local threshold = tamingConfig and tamingConfig.TamenessThreshold or 100.0
    if clampedValue >= threshold and not AE_DataService.isTamed(animal) then
        AE_TamingSystem.MakeAnimalTamed(animal)
    end
    return clampedValue
end
function AE_TamingSystem.IncreaseTameness(animal, amount)
    if not AE_DataService.isAnimalValid(animal) then return nil end
    local sandboxSettings = getSandboxSettings()
    local multiplier = 1.0  -- Safe default
    if sandboxSettings and sandboxSettings.GetTamingGainMultiplier then
        multiplier = sandboxSettings.GetTamingGainMultiplier()
    end
    local adjustedAmount = amount * multiplier
    local currentTameness = AE_TamingSystem.GetTameness(animal)
    return AE_TamingSystem.SetTameness(animal, currentTameness + adjustedAmount)
end
function AE_TamingSystem.IsTamed(animal)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    return AE_DataService.isTamed(animal)
end
function AE_TamingSystem.IsOwner(animal, player)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    if not player then return false end
    local success, playerNum = pcall(function()
        return player:getPlayerNum()
    end)
    if not success or not playerNum then return false end
    local owner = AE_TamingSystem.GetOwner(animal)
    if not owner then return false end
    return owner == playerNum
end
function AE_TamingSystem.MakeAnimalTamed(animal)
    if not AE_DataService.isAnimalValid(animal) then
        return false
    end
    
    AE_DataService.setTamed(animal, true)
    AE_DataService.setTameness(animal, 100.0)
    
    if not AE_DataService.getStableID(animal) then
        local animalName = AE_DataService.getAnimalName(animal)
        if not animalName or animalName == "" then
            local animalType = AnimalRegistry.GetAnimalType(animal)
            animalName = animalType and animalType:gsub("^%l", string.upper) or "Animal"
        end
        local stableID = AE_TamingSystem.GenerateAnimalID(animalName)
        if stableID then
            AE_DataService.setStableID(animal, stableID)
        end
    end
    
    if AE_DataService.getSlotAssigned(animal) == nil then
        AE_DataService.setSlotAssigned(animal, false)
    end
    
    if not AE_DataService.getAnimalName(animal) then
        local animalType = AnimalRegistry.GetAnimalType(animal)
        local animalName = animalType and animalType:gsub("^%l", string.upper) or "Animal"
        AE_DataService.setAnimalName(animal, animalName)
    end
    
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        animal:transmitModData()
    else
        if not isClient() then
            animal:transmitModData()
        end
    end
    if Config.IsSystemEnabled("CombatProtection") then
        local animalCategory = AnimalRegistry.GetAnimalType(animal)
        local combatConfig = Config.GetCombatProtectionConfig(animalCategory)
        if combatConfig and combatConfig.CompleteInvulnerability then
            animal:setInvincible(true)
        end
    end
    local behaviorMgr = getBehaviorManager()
    if behaviorMgr then
        local success = behaviorMgr.InitializeAnimal(animal)
    end
    
    local stableID = AE_TamingSystem.createPersistentMapping(animal)
    if stableID then
        print("[PERSISTENT MAPPING] Created mapping for newly tamed animal: " .. stableID)
    end
    
    return true
end
function AE_TamingSystem.GetPlayerTameLimit(player)
    return 9999
end
function AE_TamingSystem.GetPlayerTamedCount(player)
    if not player then return 0 end
    local playerNum = player:getPlayerNum()
    local count = 0
    
    for animalID, animal in pairs(AE_TamingSystem.animalCache) do
        if animal and not animal:isDead() then
            local owner = AE_DataService.getOwner(animal)
            if owner == playerNum and AE_DataService.isTamed(animal) then
                count = count + 1
            end
        end
    end
    return count
end
function AE_TamingSystem.CanPlayerTameMore(player)
    local currentCount = AE_TamingSystem.GetPlayerTamedCount(player)
    local limit = AE_TamingSystem.GetPlayerTameLimit(player)
    return currentCount < limit
end
function AE_TamingSystem.GetOwner(animal)
    if not AE_TamingSystem.isValidAnimal(animal) then return nil end
    return AE_DataService.getOwner(animal)
end
function AE_TamingSystem.SetOwner(animal, player)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    if not player then return false end
    local playerNum = player:getPlayerNum()
    local success = AE_DataService.setOwner(animal, playerNum)
    if success then
        if AE_EnvironmentDetector.isSinglePlayer() then
            animal:transmitModData()
        else
            if not isClient() then
                animal:transmitModData()
            end
        end
    end
    return success
end
function AE_TamingSystem.GetName(animal)
    if not AE_TamingSystem.isValidAnimal(animal) then
        local animalType = AnimalRegistry.GetAnimalType(animal)
        return animalType and animalType:gsub("^%l", string.upper) or "Animal"
    end
    local name = AE_DataService.getAnimalName(animal)
    if not name then
        local animalType = AnimalRegistry.GetAnimalType(animal)
        return animalType and animalType:gsub("^%l", string.upper) or "Animal"
    end
    return name
end
function AE_TamingSystem.SetName(animal, name)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    local finalName = name or "Animal"
    local success = AE_DataService.setAnimalName(animal, finalName)
    if success then
        if animal.setCustomName then
            animal:setCustomName(finalName)
        end
        if AE_EnvironmentDetector.isSinglePlayer() then
            animal:transmitModData()
        else
            if not isClient() then
                animal:transmitModData()
            end
        end
    end
    return success
end
function AE_TamingSystem.FindAvailableSlot(player)
        if not player then return nil end
    return true
end
function AE_TamingSystem.AssignAnimalToSlot(player, animal, slotNum)
    if not player or not animal then return false end
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    
    local stableID = AE_DataService.getStableID(animal)
    local needsBehaviorInit = false
    if not stableID or stableID == "" or stableID == "unnamed" then
        local animalName = AE_DataService.getAnimalName(animal)
        if not animalName or animalName == "" then
            local animalType = AnimalRegistry.GetAnimalType(animal)
            animalName = animalType and animalType:gsub("^%l", string.upper) or "Animal"
        end
        stableID = AE_TamingSystem.GenerateAnimalID(animalName)
        if stableID then
            AE_DataService.setStableID(animal, stableID)
            needsBehaviorInit = true
        end
    end
    
    local playerNum = player:getPlayerNum()
    AE_DataService.setOwner(animal, playerNum)
    AE_DataService.setSlotAssigned(animal, true)
    
    -- Update cache and notify system
    if AE_EnvironmentDetector.isSinglePlayer() then
        animal:transmitModData()
    else
        if not isClient() then
            animal:transmitModData()
        end
    end
    AE_TamingSystem.animalCache[stableID] = animal
    transmitGlobalData()
    
    if needsBehaviorInit then
        local behaviorMgr = getBehaviorManager()
        if behaviorMgr then
            behaviorMgr.InitializeAnimal(animal)
        end
    end
    return true
end
function AE_TamingSystem.GetAnimalFromSlot(player, slotNum)
    if not player then return nil end
    
    -- ID-based system: Get all tamed animals for player, return by index
    -- This maintains compatibility while using ID-based lookup
    local playerNum = player:getPlayerNum()
    local tamedAnimals = {}
    
    -- Collect all animals owned by this player
    for animalID, animal in pairs(AE_TamingSystem.animalCache) do
        if animal and not animal:isDead() then
            local owner = AE_DataService.getOwner(animal)
            if owner == playerNum and AE_DataService.isTamed(animal) then
                table.insert(tamedAnimals, animal)
            end
        end
    end
    
    -- Return animal at requested index (maintains slot-like behavior)
    if slotNum > 0 and slotNum <= #tamedAnimals then
        return tamedAnimals[slotNum]
    end
    if AE_TamingSystem.animalCache[animalID] then
        local cached = AE_TamingSystem.animalCache[animalID]
        if cached and not cached:isDead() then
            return cached
        else
            AE_TamingSystem.animalCache[animalID] = nil
        end
    end
    local cell = player:getCell()
    if not cell then return nil end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    for x = px - 5, px + 5, 1 do
        for y = py - 5, py + 5, 1 do
            local checkSquare = cell:getGridSquare(x, y, pz)
            if checkSquare then
                local animals = checkSquare:getAnimals()
                if animals and animals:size() > 0 then
                    for i = 0, animals:size() - 1 do
                        local animal = animals:get(i)
                        if animal and AnimalRegistry.IsFrameworkAnimal(animal) then
                            local animalModData = AE_TamingSystem.getAnimalModData(animal)
                            if animalModData then
                                local animalStableID = animalModData[AE_TamingSystem.KEY_STABLE_ID] 
                                if animalStableID and AE_TamingSystem.IDsMatch(animalStableID, animalID) then
                                    AE_TamingSystem.animalCache[animalID] = animal
                                    return animal
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for x = px - 20, px + 20, 3 do
        for y = py - 20, py + 20, 3 do
            if (x < px - 5 or x > px + 5) or (y < py - 5 or y > py + 5) then
                local checkSquare = cell:getGridSquare(x, y, pz)
                if checkSquare then
                    local animals = checkSquare:getAnimals()
                    if animals and animals:size() > 0 then
                        for i = 0, animals:size() - 1 do
                            local animal = animals:get(i)
                            if animal and AnimalRegistry.IsFrameworkAnimal(animal) then
                                local animalModData = AE_TamingSystem.getAnimalModData(animal)
                                if animalModData then
                                    local animalStableID = animalModData[AE_TamingSystem.KEY_STABLE_ID] 
                                    if animalStableID and AE_TamingSystem.IDsMatch(animalStableID, animalID) then
                                        AE_TamingSystem.animalCache[animalID] = animal
                                        return animal
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for x = px - 50, px + 50, 5 do
        for y = py - 50, py + 50, 5 do
            if (x < px - 20 or x > px + 20) or (y < py - 20 or y > py + 20) then
                local checkSquare = cell:getGridSquare(x, y, pz)
                if checkSquare then
                    local animals = checkSquare:getAnimals()
                    if animals and animals:size() > 0 then
                        for i = 0, animals:size() - 1 do
                            local animal = animals:get(i)
                            if animal and AnimalRegistry.IsFrameworkAnimal(animal) then
                                local animalModData = AE_TamingSystem.getAnimalModData(animal)
                                if animalModData then
                                    local animalStableID = animalModData[AE_TamingSystem.KEY_STABLE_ID]   
                                    if animalStableID and AE_TamingSystem.IDsMatch(animalStableID, animalID) then
                                        AE_TamingSystem.animalCache[animalID] = animal
                                        return animal
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end
function AE_TamingSystem.RemoveAnimalFromSlot(player, animal)
    if not player or not animal then return false end
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    
    -- ID-based system: Clear ownership and assignment
    local animalID = AE_DataService.getStableID(animal)
    if not animalID or animalID == "" then return false end
    
    -- Verify animal belongs to this player before removal
    local owner = AE_DataService.getOwner(animal)
    local playerNum = player:getPlayerNum()
    if owner ~= playerNum then return false end
    
    -- Remove ownership and assignment via unified backend
    AE_DataService.setOwner(animal, nil)
    AE_DataService.setSlotAssigned(animal, false)
    
    -- Update cache and notify system
    if AE_EnvironmentDetector.isSinglePlayer() then
        animal:transmitModData()
    else
        if not isClient() then
            animal:transmitModData()
        end
    end
    AE_TamingSystem.animalCache[animalID] = nil
    transmitGlobalData()
    return true
end
function AE_TamingSystem.ProcessPendingSlotAssignments()
    if #AE_TamingSystem.pendingSlotAssignments == 0 then return end
    local toRemove = {}
    for i = #AE_TamingSystem.pendingSlotAssignments, 1, -1 do
        local assignment = AE_TamingSystem.pendingSlotAssignments[i]
        local player = assignment.player
        local animal = assignment.animal
        if player and animal and not animal:isDead() then
            local animalModData = AE_TamingSystem.getAnimalModData(animal)
            local animalID = animalModData and animalModData[AE_TamingSystem.KEY_STABLE_ID]
            if animalID and animalID ~= "" and animalID ~= "unnamed" then
                local slot = AE_TamingSystem.FindAvailableSlot(player)
                if slot then
                    AE_TamingSystem.AssignAnimalToSlot(player, animal, slot)
                    table.insert(toRemove, i)
                end
            end
        else
            table.insert(toRemove, i)
        end
    end
    for _, idx in ipairs(toRemove) do
        table.remove(AE_TamingSystem.pendingSlotAssignments, idx)
    end
end

-- SUB-SESSION 1: Core State Management Functions
function AE_TamingSystem.SetTamingInProgress(animal, inProgress)
    if not animal then return end
    
    local animalID = animal:getOnlineID()
    local currentTime = getTimestampMs()
    
    if inProgress then
        AE_TamingSystem.animalsTamingInProgress[animalID] = true
        AE_TamingSystem.tamingTimeouts[animalID] = currentTime + AE_TamingSystem.TAMING_TIMEOUT_MS
        print("[TAMING STATE] Set in progress: " .. animalID)
        
        -- SUB-SESSION 5: MP state synchronization
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- No action needed for single-player
        else
            if not isClient() then
                sendServerCommand("AE_TamingService", "tamingStateChanged", {
                    animalID = animalID,
                    inProgress = true,
                    timestamp = currentTime
                })
            end
        end
    else
        AE_TamingSystem.animalsTamingInProgress[animalID] = nil
        AE_TamingSystem.tamingTimeouts[animalID] = nil
        print("[TAMING STATE] Cleared in progress: " .. animalID)
        
        -- SUB-SESSION 5: MP state synchronization
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- No action needed for single-player
        else
            if not isClient() then
                sendServerCommand("AE_TamingService", "tamingStateChanged", {
                    animalID = animalID,
                    inProgress = false,
                    timestamp = currentTime
                })
            end
        end
    end
end

function AE_TamingSystem.IsTamingInProgress(animal)
    if not animal then return false end
    
    local animalID = animal:getOnlineID()
    local currentTime = getTimestampMs()
    
    if not AE_TamingSystem.animalsTamingInProgress[animalID] then
        return false
    end
    
    local timeout = AE_TamingSystem.tamingTimeouts[animalID]
    if timeout and currentTime > timeout then
        AE_TamingSystem.animalsTamingInProgress[animalID] = nil
        AE_TamingSystem.tamingTimeouts[animalID] = nil
        print("[TAMING STATE] Cleared stuck taming state: " .. animalID)
        return false
    end
    
    return true
end

function AE_TamingSystem.cleanupStuckTamingStates()
    local currentTime = getTimestampMs()
    local stuckStates = {}
    local networkIssues = {}
    
    for animalID, timeout in pairs(AE_TamingSystem.tamingTimeouts) do
        if currentTime > timeout then
            table.insert(stuckStates, animalID)
            
            -- SUB-SESSION 5: Detect potential network disconnection issues
            local timeDiff = currentTime - timeout
            if timeDiff > (AE_TamingSystem.TAMING_TIMEOUT_MS * 2) then
                table.insert(networkIssues, {
                    animalID = animalID,
                    ageMs = timeDiff,
                    reason = "potential_network_disconnection"
                })
            end
        end
    end
    
    for _, animalID in ipairs(stuckStates) do
        AE_TamingSystem.animalsTamingInProgress[animalID] = nil
        AE_TamingSystem.tamingTimeouts[animalID] = nil
        print("[TAMING STATE] Cleaned up stuck state: " .. animalID)
        
        -- SUB-SESSION 5: MP notification of cleanup
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- No action needed for single-player
        else
            if not isClient() then
                sendServerCommand("AE_TamingService", "tamingStateChanged", {
                    animalID = animalID,
                    inProgress = false,
                    reason = "timeout_cleanup",
                    timestamp = currentTime
                })
            end
        end
    end
    
    -- SUB-SESSION 5: Log network issues for diagnostics
    if #networkIssues > 0 then
        print("[TAMING DIAGNOSTICS] Detected " .. #networkIssues .. " potential network-related state issues")
        for _, issue in ipairs(networkIssues) do
            print("[TAMING DIAGNOSTICS] Network issue - Animal: " .. issue.animalID .. 
                  ", Age: " .. math.floor(issue.ageMs / 1000) .. "s, Reason: " .. issue.reason)
        end
    end
    
    if #stuckStates > 0 then
        print("[TAMING STATE] Cleaned " .. #stuckStates .. " stuck taming states")
    end
end

function AE_TamingSystem.getTamingStateInfo()
    local activeCount = 0
    for _ in pairs(AE_TamingSystem.animalsTamingInProgress) do
        activeCount = activeCount + 1
    end
    
    return {
        animalsTamingInProgress = AE_TamingSystem.animalsTamingInProgress,
        tamingTimeouts = AE_TamingSystem.tamingTimeouts,
        activeCount = activeCount,
        timestamp = getTimestampMs(),
        timeoutDuration = AE_TamingSystem.TAMING_TIMEOUT_MS
    }
end

-- SUB-SESSION 5: Production-ready diagnostic tools
function AE_TamingSystem.getSystemDiagnostics()
    local diagnostics = {
        timestamp = getTimestampMs(),
        activeTamingStates = 0,
        timeoutStates = 0,
        bypassStates = 0,
        oldestTaming = nil,
        memoryUsage = {
            tamingProgress = 0,
            tamingTimeouts = 0,
            animalCache = 0
        },
        systemHealth = "HEALTHY"
    }
    
    -- Analyze active taming states
    for animalID, state in pairs(AE_TamingSystem.animalsTamingInProgress) do
        diagnostics.activeTamingStates = diagnostics.activeTamingStates + 1
        diagnostics.memoryUsage.tamingProgress = diagnostics.memoryUsage.tamingProgress + 1
        
        if state == "RESTORING" or state == "INTERFACE_TAMING" then
            diagnostics.bypassStates = diagnostics.bypassStates + 1
        end
    end
    
    -- Analyze timeout states
    local currentTime = getTimestampMs()
    for animalID, timeoutData in pairs(AE_TamingSystem.tamingTimeouts) do
        diagnostics.memoryUsage.tamingTimeouts = diagnostics.memoryUsage.tamingTimeouts + 1
        
        if timeoutData.timestamp and currentTime - timeoutData.timestamp > AE_TamingSystem.TAMING_TIMEOUT_MS then
            diagnostics.timeoutStates = diagnostics.timeoutStates + 1
        end
        
        if not diagnostics.oldestTaming or (timeoutData.timestamp and timeoutData.timestamp < diagnostics.oldestTaming) then
            diagnostics.oldestTaming = timeoutData.timestamp
        end
    end
    
    -- Analyze cache usage
    for _ in pairs(AE_TamingSystem.animalCache or {}) do
        diagnostics.memoryUsage.animalCache = diagnostics.memoryUsage.animalCache + 1
    end
    
    -- Determine system health
    if diagnostics.timeoutStates > 5 then
        diagnostics.systemHealth = "DEGRADED"
    elseif diagnostics.timeoutStates > 10 or diagnostics.activeTamingStates > 20 then
        diagnostics.systemHealth = "CRITICAL"
    end
    
    return diagnostics
end

function AE_TamingSystem.printSystemDiagnostics()
    local diag = AE_TamingSystem.getSystemDiagnostics()
    print("[TAMING DIAGNOSTICS] =================")
    print("System Health: " .. diag.systemHealth)
    print("Active Taming States: " .. diag.activeTamingStates)
    print("Timeout States: " .. diag.timeoutStates)
    print("Bypass States: " .. diag.bypassStates)
    print("Memory Usage - Progress: " .. diag.memoryUsage.tamingProgress)
    print("Memory Usage - Timeouts: " .. diag.memoryUsage.tamingTimeouts)
    print("Memory Usage - Cache: " .. diag.memoryUsage.animalCache)
    if diag.oldestTaming then
        local age = getTimestampMs() - diag.oldestTaming
        print("Oldest Taming State Age: " .. math.floor(age / 1000) .. "s")
    end
    print("=======================================")
end

-- PHASE 3: Enhanced production diagnostics with persistent mapping analysis
function AE_TamingSystem.getEnhancedDiagnostics()
    local diag = AE_TamingSystem.getSystemDiagnostics()
    
    -- PHASE 3: Add persistent mapping diagnostics
    diag.persistentMapping = {
        totalMappings = 0,
        staleMappings = 0,
        memoryEstimate = 0
    }
    
    if AE_TamingSystem.persistentAnimalMapping then
        for stableID, animal in pairs(AE_TamingSystem.persistentAnimalMapping) do
            diag.persistentMapping.totalMappings = diag.persistentMapping.totalMappings + 1
            diag.persistentMapping.memoryEstimate = diag.persistentMapping.memoryEstimate + 150  -- Estimate bytes per mapping
            
            if not animal or animal:isDead() or not animal:isExistInTheWorld() then
                diag.persistentMapping.staleMappings = diag.persistentMapping.staleMappings + 1
            end
        end
    end
    
    -- PHASE 3: Performance metrics
    diag.performance = {
        mappingEfficiency = 0,
        staleRatio = 0,
        totalMemoryKB = math.floor(diag.persistentMapping.memoryEstimate / 1024)
    }
    
    if diag.persistentMapping.totalMappings > 0 then
        diag.performance.staleRatio = diag.persistentMapping.staleMappings / diag.persistentMapping.totalMappings
        diag.performance.mappingEfficiency = (diag.persistentMapping.totalMappings - diag.persistentMapping.staleMappings) / diag.persistentMapping.totalMappings
    end
    
    return diag
end

function AE_TamingSystem.printEnhancedDiagnostics()
    local diag = AE_TamingSystem.getEnhancedDiagnostics()
    
    -- Standard diagnostics
    print("[ENHANCED TAMING DIAGNOSTICS] ========")
    print("System Health: " .. diag.systemHealth)
    print("Active Taming States: " .. diag.activeTamingStates)
    print("Timeout States: " .. diag.timeoutStates)
    print("Bypass States: " .. diag.bypassStates)
    
    -- PHASE 3: Persistent mapping diagnostics
    print("--- Persistent Identity Mapping ---")
    print("Total Mappings: " .. diag.persistentMapping.totalMappings)
    print("Stale Mappings: " .. diag.persistentMapping.staleMappings)
    print("Mapping Efficiency: " .. string.format("%.1f%%", diag.performance.mappingEfficiency * 100))
    print("Memory Usage: " .. diag.performance.totalMemoryKB .. " KB")
    
    -- Memory breakdown
    print("--- Memory Analysis ---")
    print("Taming Progress: " .. diag.memoryUsage.tamingProgress .. " entries")
    print("Timeout Tracking: " .. diag.memoryUsage.tamingTimeouts .. " entries") 
    print("Animal Cache: " .. diag.memoryUsage.animalCache .. " entries")
    print("Persistent Mapping: " .. diag.persistentMapping.totalMappings .. " entries")
    
    -- Performance analysis
    if diag.performance.staleRatio > 0.2 then
        print("WARNING: High stale mapping ratio (" .. string.format("%.1f%%", diag.performance.staleRatio * 100) .. ") - cleanup recommended")
    end
    
    if diag.performance.totalMemoryKB > 100 then
        print("NOTICE: Memory usage above 100KB - monitoring recommended")
    end
    
    print("=========================================")
end

-- PHASE 1: Core Persistent Identity Bridge Functions
function AE_TamingSystem.createPersistentMapping(animal)
    if not animal then return nil end
    
    local stableID = AE_DataService.getStableID(animal)
    local animalID = animal:getOnlineID()
    
    if stableID and animalID then
        AE_TamingSystem.persistentAnimalMapping[stableID] = animal
        AE_TamingSystem.instanceToPersistentMap[animalID] = stableID
        
        -- PHASE 3: MP compatibility - notify clients of mapping updates
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- No action needed for single-player
        else
            if not isClient() then
                sendServerCommand("AE_TamingService", "persistentMappingCreated", {
                    stableID = stableID,
                    animalID = animalID,
                    timestamp = getTimestampMs()
                })
            end
        end
        
        return stableID
    end
    return nil
end

function AE_TamingSystem.removePersistentMapping(animal)
    if not animal then return end
    
    local animalID = animal:getOnlineID()
    local stableID = AE_TamingSystem.instanceToPersistentMap[animalID]
    
    if stableID then
        AE_TamingSystem.persistentAnimalMapping[stableID] = nil
        AE_TamingSystem.instanceToPersistentMap[animalID] = nil
    end
end

function AE_TamingSystem.recognizeRestoredAnimal(newAnimal)
    if not newAnimal then return false end
    
    local stableID = AE_DataService.getStableID(newAnimal)
    local isTamed = AE_DataService.isTamed(newAnimal)
    
    if not stableID or not isTamed then
        return false
    end
    
    local mappingCreated = AE_TamingSystem.createPersistentMapping(newAnimal)
    if mappingCreated then
        AE_TamingSystem.animalCache[newAnimal:getID()] = newAnimal
        
        Events.TriggerEvent("OnTamedAnimalInstanceUpdated", stableID, newAnimal)
        
        print("[PERSISTENT MAPPING] Recognized restored animal: " .. stableID .. " -> " .. newAnimal:getID())
        return true
    end
    
    return false
end

function AE_TamingSystem.findAnimalByPersistentID(stableID)
    if not stableID then return nil end
    
    local animal = AE_TamingSystem.persistentAnimalMapping[stableID]

    if animal and animal:isExistInTheWorld() and not animal:isDead() then
        return animal
    else
        if animal then
            AE_TamingSystem.removePersistentMapping(animal)
        else
            AE_TamingSystem.persistentAnimalMapping[stableID] = nil
        end
        return nil
    end
end

function AE_TamingSystem.cleanupPersistentMappings()
    local staleStableIDs = {}
    local staleInstanceIDs = {}
    
    for stableID, animal in pairs(AE_TamingSystem.persistentAnimalMapping) do
        if not animal or animal:isDead() or not animal:isExistInTheWorld() then
            table.insert(staleStableIDs, stableID)
        end
    end
    
    for instanceID, stableID in pairs(AE_TamingSystem.instanceToPersistentMap) do
        if not AE_TamingSystem.persistentAnimalMapping[stableID] then
            table.insert(staleInstanceIDs, instanceID)
        end
    end
    
    for _, stableID in ipairs(staleStableIDs) do
        local animal = AE_TamingSystem.persistentAnimalMapping[stableID]
        if animal then
            local instanceID = animal:getOnlineID()
            AE_TamingSystem.instanceToPersistentMap[instanceID] = nil
        end
        AE_TamingSystem.persistentAnimalMapping[stableID] = nil
    end
    
    for _, instanceID in ipairs(staleInstanceIDs) do
        AE_TamingSystem.instanceToPersistentMap[instanceID] = nil
    end
    
    -- PHASE 3: Enhanced logging with performance metrics
    if #staleStableIDs > 0 or #staleInstanceIDs > 0 then
        print("[PERSISTENT MAPPING] Cleaned " .. #staleStableIDs .. " stale persistent mappings and " .. #staleInstanceIDs .. " stale instance mappings")
        
        -- Memory estimate after cleanup
        local remainingMappings = 0
        for _ in pairs(AE_TamingSystem.persistentAnimalMapping) do
            remainingMappings = remainingMappings + 1
        end
        local memoryEstimateKB = math.floor((remainingMappings * 150) / 1024)
        print("[PERSISTENT MAPPING] " .. remainingMappings .. " mappings remaining, estimated " .. memoryEstimateKB .. " KB memory usage")
        
        -- PHASE 3: Automatic cleanup recommendations
        if #staleStableIDs > 10 then
            print("[PERSISTENT MAPPING] WARNING: High number of stale mappings detected - consider more frequent cleanup")
        end
    end
end
local function getPlayersFoodCount(player)
    local inv = player:getInventory()
    if not inv then return 0 end
    local totalFood = 0
    for _, animalConfig in ipairs(Config.RegisteredAnimals) do
        local tamingConfig = Config.GetTamingConfig(animalConfig.category)
        if tamingConfig and tamingConfig.AcceptedFoods then
            for itemType, _ in pairs(tamingConfig.AcceptedFoods) do
                local count = inv:getItemCount(itemType)
                totalFood = totalFood + count
            end
        end
    end
    return totalFood
end
local function consumeOneFood(player, animalCategory)
    local inv = player:getInventory()
    if not inv then return false, 0 end
    local tamingConfig = Config.GetTamingConfig(animalCategory)
    if not tamingConfig or not tamingConfig.AcceptedFoods then
        return false, 0
    end
    for itemType, tameValue in pairs(tamingConfig.AcceptedFoods) do
        local item = inv:getFirstTypeRecurse(itemType)
        if item then
            inv:Remove(item)
            return true, tameValue
        end
    end
    return false, 0
end

local function identifyAnimalByLocation(animal)
    if not animal then return nil end
    
    local existingStableID = AE_DataService.getStableID(animal)
    if existingStableID then
        return existingStableID
    end
    
    return nil
end

local function validateAnimalForTaming(animal, player)
    local animalID = animal and animal:getID() or "unknown"
    
    local success, result = AE_OperationGuards.withOperationGuard(animalID, "validatingAnimal", function()
        if not AE_DataService.isAnimalValid(animal) then
            return false
        end
        
        if not player then
            return false
        end
        
        if AE_TamingSystem.IsTamingInProgress(animal) then
            local tamingState = AE_TamingSystem.animalsTamingInProgress[animal:getOnlineID()]
            if tamingState == "RESTORING" or tamingState == "INTERFACE_TAMING" then
                print("[TAMING DEBUG] Allowing " .. tamingState .. " bypass")
                return true
            end
            print("[TAMING DEBUG] Animal already being tamed: " .. tostring(animal:getOnlineID()))
            return false
        end
        
        
        return true
    end)
    
    if not success then
        return false
    end
    
    return result
end

function AE_TamingSystem.FeedAnimal(animal, player)
    print("[TAMING DEBUG] FeedAnimal called with animal: " .. tostring(animal) .. ", player: " .. tostring(player))
    if not Config.IsSystemEnabled("TamingSystem") then 
        print("[TAMING DEBUG] ERROR: TamingSystem not enabled")
        return false 
    end
    print("[TAMING DEBUG] TamingSystem is enabled")
    if not AE_TamingSystem.isValidAnimal(animal) then 
        print("[TAMING DEBUG] ERROR: Invalid animal")
        return false 
    end
    print("[TAMING DEBUG] Animal is valid")
    if not player then 
        print("[TAMING DEBUG] ERROR: No player provided")
        return false 
    end
    print("[TAMING DEBUG] Player is valid")
    if AE_TamingSystem.IsTamed(animal) then
        local owner = AE_TamingSystem.GetOwner(animal)
        if owner and owner ~= player:getPlayerNum() then
            local currentTime = getTimestampMs()
            local lastNotif = AE_TamingSystem.lastAlreadyTamedNotification[animal] or 0
            if currentTime - lastNotif > AE_TamingSystem.ALREADY_TAMED_COOLDOWN then
                player:Say("This animal already belongs to someone else.")
                AE_TamingSystem.lastAlreadyTamedNotification[animal] = currentTime
            end
            return false
        end
        return false
    end
    local foodCount = getPlayersFoodCount(player)
    if foodCount <= 0 then
        return false
    end
    if not AE_TamingSystem.CanPlayerTameMore(player) then
        local currentCount = AE_TamingSystem.GetPlayerTamedCount(player)
        local limit = AE_TamingSystem.GetPlayerTameLimit(player)
        player:Say("I can't tame any more animals! (" .. currentCount .. "/" .. limit .. ")")
        return false
    end
    print("[TAMING DEBUG] About to call AnimalRegistry.GetAnimalType")
    local animalCategory = AnimalRegistry.GetAnimalType(animal)
    print("[TAMING DEBUG] AnimalRegistry.GetAnimalType returned: " .. tostring(animalCategory))
    local consumed, tameValue = consumeOneFood(player, animalCategory)
    if not consumed then
        return false
    end
    local currentTameness = AE_TamingSystem.GetTameness(animal)
    local newTameness = AE_TamingSystem.IncreaseTameness(animal, tameValue)
    local tamingConfig = Config.GetTamingConfig(animalCategory)
    local threshold = tamingConfig and tamingConfig.TamenessThreshold or 100.0
    if newTameness >= threshold then
        print("[TAMING DEBUG] Threshold reached, starting validation")
        if not validateAnimalForTaming(animal, player) then
            print("[TAMING DEBUG] Pre-taming validation failed")
            return false
        end
        print("[TAMING DEBUG] Pre-taming validation passed")
        
        AE_TamingSystem.SetTamingInProgress(animal, true)
        print("[TAMING DEBUG] Taming in progress flag set")
        
        AE_TamingSystem.SetOwner(animal, player)
        AE_TamingSystem.MakeAnimalTamed(animal, player)
        
        AE_TamingSystem.SetTamingInProgress(animal, false)
        print("[TAMING DEBUG] Taming completed, flag cleared")
        
        table.insert(AE_TamingSystem.pendingSlotAssignments, {
            player = player,
            animal = animal
        })
        local animalType = AnimalRegistry.GetAnimalType(animal)
        player:Say("I've tamed " .. (animalType and "a " .. animalType or "an animal") .. "!")
        AE_TamingSystem.ReinforceAcceptance(animal, player)
        
        local delayTicks = 60
        local tickCount = 0
        local namingHandler
        namingHandler = function()
            tickCount = tickCount + 1
            if tickCount >= delayTicks then
                AE_TamingSystem.ShowAnimalNamingUI(animal, player)
                Events.OnTick.Remove(namingHandler)
            end
        end
        Events.OnTick.Add(namingHandler)
        return true
    else
        player:Say("The animal is getting friendlier... (" .. math.floor(newTameness) .. "%)")
        return true
    end
end
function AE_TamingSystem.ShowAnimalNamingUI(animal, player, isRenaming)
    if not AE_TamingSystem.isValidAnimal(animal) then return end
    if not player then return end
    local currentName = ""
    local oldID = nil
    if isRenaming then
        currentName = AE_TamingSystem.GetName(animal) or ""
        local modData = AE_TamingSystem.getAnimalModData(animal)
        if modData then
            oldID = modData[AE_TamingSystem.KEY_STABLE_ID]
        end
    end
    local dataServiceAvailable = false
    if not AE_DataService then
        print("[NAMING DEBUG] AE_DataService not loaded, attempting dynamic require")
        local success, result = pcall(function()
            return require("AnimalsEssentials/DataServices/AE_DataService")
        end)
        if success and result then
            AE_DataService = result
            dataServiceAvailable = true
            print("[NAMING DEBUG] AE_DataService loaded successfully")
        else
            print("[NAMING DEBUG] Failed to load AE_DataService, using fallback ModData access")
            dataServiceAvailable = false
        end
    else
        dataServiceAvailable = true
    end
    
    local playerModData = getPlayerModData(player)
    local animalType = AnimalRegistry.GetAnimalType(animal)
    local displayType = animalType and animalType:gsub("^%l", string.upper) or "Animal"
    local modal = ISTextBox:new(
        getCore():getScreenWidth() / 2 - 200,
        getCore():getScreenHeight() / 2 - 100,
        400,
        200,
        isRenaming and ("Rename Your " .. displayType .. "!") or ("Name Your " .. displayType .. "!"),
        currentName,
        nil,
        function(target, button, animalToName, playerWhoTamed)
            if button.internal == "OK" then
                local enteredName = button.parent.entry:getText()
                if not enteredName or enteredName == "" then
                    button.parent:setTitle((isRenaming and "Rename Your " .. displayType .. "!" or "Name Your " .. displayType .. "!") .. " (Name cannot be empty)")
                    return
                end
                if #enteredName > Config.Naming.MaxNameLength then
                    enteredName = enteredName:sub(1, Config.Naming.MaxNameLength)
                end
                local nameInUse = false
                for animalID, cachedAnimal in pairs(AE_TamingSystem.animalCache) do
                    if AE_DataService.getOwner(cachedAnimal) == player:getPlayerNum() then
                        local existingName = AE_DataService.getAnimalName(cachedAnimal)
                        if existingName and existingName ~= "" and existingName == enteredName then
                            if not (isRenaming and existingName == currentName) then
                                nameInUse = true
                                break
                            end
                        end
                    end
                end
                if nameInUse then
                    button.parent:setTitle("Hmm... I already have an animal with that name")
                    button.parent.entry:setText("")
                    return
                end
                local uniqueID = AE_TamingSystem.GenerateAnimalID(enteredName)
                if not uniqueID then
                    button.parent:setTitle((isRenaming and "Rename Your " .. displayType .. "!" or "Name Your " .. displayType .. "!") .. " (Invalid name - try letters/numbers)")
                    button.parent.entry:setText("")
                    return
                end
                AE_TamingSystem.SetName(animalToName, enteredName)
                if animalToName.setCustomName then
                    animalToName:setCustomName(enteredName)
                end
                local modData = AE_TamingSystem.getAnimalModData(animalToName)
                if modData then
                    local oldID = modData[AE_TamingSystem.KEY_STABLE_ID]
                    modData[AE_TamingSystem.KEY_STABLE_ID] = uniqueID
                    if AE_EnvironmentDetector.isSinglePlayer() then
                        animalToName:transmitModData()
                    else
                        if not isClient() then
                            animalToName:transmitModData()
                        end
                    end
                    if isRenaming then
                        local stableID = AE_DataService.getStableID(animalToName)
                        if stableID then
                            AE_TamingSystem.animalCache[uniqueID] = animalToName
                            if oldID and AE_TamingSystem.animalCache[oldID] then
                                AE_TamingSystem.animalCache[oldID] = nil
                            end
                            transmitGlobalData()
                        end
                        playerWhoTamed:Say("Renamed to " .. enteredName .. "!")
                    else
                        playerWhoTamed:Say("Welcome, " .. enteredName .. "!")
                    end
                    button.parent:close()
                end
            end
        end,
        nil,
        animal,
        player
    )
    modal:initialise()
    modal:addToUIManager()
    modal.entry:setMaxTextLength(Config.Naming.MaxNameLength)
end
function AE_TamingSystem.ReleaseTamedAnimal(animal, player)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    if not player then return false end
    
    AE_TamingSystem.RemoveAnimalFromSlot(player, animal)
    AE_DataService.setTamed(animal, false)
    AE_DataService.setOwner(animal, nil)
    AE_DataService.setSlotAssigned(animal, false)
    animal:setInvincible(false)
    if AE_EnvironmentDetector.isSinglePlayer() then
        animal:transmitModData()
    else
        if not isClient() then
            animal:transmitModData()
        end
    end
    return true
end
function AE_TamingSystem.ReinforceAcceptance(animal, player)
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    if not player then return false end
    if not AE_TamingSystem.IsTamed(animal) then return false end
    animal:addAcceptance(player, 100.0)
    return true
end
function AE_TamingSystem.ReinforceAllTamedAnimals(player)
    if not player then return end
    local cell = player:getCell()
    if not cell then return end
    local playerModData = getPlayerModData(player)
    if not playerModData then return end
    if not AE_DataService then return end
    
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    for x = px - 30, px + 30 do
        for y = py - 30, py + 30 do
            local checkSquare = cell:getGridSquare(x, y, pz)
            if checkSquare then
                local animals = checkSquare:getAnimals()
                for i = 0, animals:size() - 1 do
                    local animal = animals:get(i)
                    if animal and AnimalRegistry.IsFrameworkAnimal(animal) then
                        if AE_DataService.isTamed(animal) then
                            local owner = AE_DataService.getOwner(animal)
                            if owner == player:getPlayerNum() then
                                AE_TamingSystem.ReinforceAcceptance(animal, player)
                                
                                local stableID = AE_DataService.getStableID(animal)
                                if stableID then
                                    AE_TamingSystem.animalCache[stableID] = animal
                                    
                                    local animalName = AE_DataService.getAnimalName(animal)
                                    if animalName and animalName ~= "" and animal.setCustomName then
                                        animal:setCustomName(animalName)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
local function checkAnimalDeaths()
    -- Defensive programming: validate dependencies
    local player = getPlayer()
    if not player then return end
    if not AE_DataService then return end
    if not AE_TamingSystem.animalCache then return end
    
    local playerNum = player:getPlayerNum()
    local deadAnimals = {}
    
    -- ID-based system: Check all cached animals for death
    for animalID, animal in pairs(AE_TamingSystem.animalCache) do
        if animal and animal:isDead() then
            -- Verify this animal belongs to the current player
            local owner = AE_DataService.getOwner(animal)
            if owner == playerNum and AE_DataService.isTamed(animal) then
                -- Get animal name for death message
                local animalName = AE_DataService.getAnimalName(animal)
                if animalName and animalName ~= "" then
                    player:Say("Oh no!! my animal " .. animalName .. " has died!!")
                else
                    player:Say("Oh no!! my animal has died!!")
                end
                
                -- Mark for removal (don't modify cache during iteration)
                table.insert(deadAnimals, animalID)
            end
        end
    end
    
    -- Clean up dead animals from cache
    for _, animalID in ipairs(deadAnimals) do
        AE_TamingSystem.animalCache[animalID] = nil
    end
    
    -- Notify system if any animals were removed
    if #deadAnimals > 0 then
        transmitGlobalData()
    end
end
AE_TamingSystem.processedAnimals = {}
AE_TamingSystem.filledSlots = {}
local function tryInitializeAnimal(animal, player)
    if not animal or not player then return false end
    if not AE_TamingSystem.isValidAnimal(animal) then return false end
    local animalKey = tostring(animal)
    if AE_TamingSystem.processedAnimals[animalKey] then
        return false
    end
    local animalModData = AE_TamingSystem.getAnimalModData(animal)
    if not animalModData then return false end
    local animalID = animalModData[AE_TamingSystem.KEY_STABLE_ID]
    local animalName = animalModData[AE_TamingSystem.KEY_NAME]
    if not AE_DataService then
        AE_TamingSystem.processedAnimals[animalKey] = true
        return false
    end
    
    local stableID = AE_DataService.getStableID(animal)
    if not stableID or stableID == "" then
        AE_TamingSystem.processedAnimals[animalKey] = true
        return false
    end
    
    local owner = AE_DataService.getOwner(animal)
    local playerNum = player:getPlayerNum()
    
    if owner == playerNum and AE_DataService.isTamed(animal) then
        AE_TamingSystem.animalCache[stableID] = animal
        
        local animalName = AE_DataService.getAnimalName(animal)
        if animalName and animal.setCustomName then
            animal:setCustomName(animalName)
        end
        
        local animalModData = AE_TamingSystem.getAnimalModData(animal)
        if animalModData then
                if animalModData[AE_DataConfig.ModDataKeys.CustomHunger] == nil then
                    local success, vanillaHunger = pcall(function()
                        local stats = animal:getStats()
                        if stats then
                            local h = stats:getHunger()
                            if h ~= nil then return 100 - h end
                        end
                        return nil
                    end)
                    animalModData[AE_DataConfig.ModDataKeys.CustomHunger] = (success and vanillaHunger) or 70
                end
                if animalModData[AE_DataConfig.ModDataKeys.CustomThirst] == nil then
                    local success, vanillaThirst = pcall(function()
                        local stats = animal:getStats()
                        if stats then
                            local t = stats:getThirst()
                            if t ~= nil then return 100 - t end
                        end
                        return nil
                    end)
                    animalModData[AE_DataConfig.ModDataKeys.CustomThirst] = (success and vanillaThirst) or 70
                end
        end
        
        if AE_EnvironmentDetector.isSinglePlayer() then
            animal:transmitModData()
        else
            if not isClient() then
                animal:transmitModData()
            end
        end
        
        if Config.IsSystemEnabled("CombatProtection") then
            local animalCategory = AnimalRegistry.GetAnimalType(animal)
            local combatConfig = Config.GetCombatProtectionConfig(animalCategory)
            if combatConfig and combatConfig.CompleteInvulnerability then
                animal:setInvincible(true)
            end
        end
        
        AE_TamingSystem.processedAnimals[animalKey] = true
        return true
    end
    
    AE_TamingSystem.processedAnimals[animalKey] = true
    return false
end

Events.OnCreateLivingCharacter.Add(function(character)
    if not Config.IsSystemEnabled("TamingSystem") then return end
    if not character then return end
    if not character:isAnimal() then return end
    if not AE_TamingSystem.isValidAnimal(character) then return end
    local animal = character
    task.wait(0.2)
    local player = getPlayer()
    if player then
        tryInitializeAnimal(animal, player)
    end
end)
Events.OnGameStart.Add(function()
    if not Config.IsSystemEnabled("TamingSystem") then return end

    local AE_InitializationCoordinator = require("AnimalsEssentials/Coordination/AE_InitializationCoordinator")
    local status = AE_InitializationCoordinator.getStatus()
    if not status.completed then
        print("[AE_TamingSystem] OnGameStart: Initialization not complete, deferring animal scan")
        return
    end

    AE_TamingSystem.animalCache = {}
    AE_TamingSystem.processedAnimals = {}
    AE_TamingSystem.filledSlots = {}
    
    -- SUB-SESSION 1: Initialize state tracking systems
    AE_TamingSystem.animalsTamingInProgress = {}
    AE_TamingSystem.tamingTimeouts = {}
    print("[TAMING STATE] Foundation state tracking initialized")
    
    -- Defensive programming: validate player and environment
    local player = getPlayer()
    if not player then return end
    local cell = player:getCell()
    if not cell then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local searchRadius = 40
    local animalsFound = 0
    local animalsInitialized = 0
    for x = px - searchRadius, px + searchRadius, 2 do
        for y = py - searchRadius, py + searchRadius, 2 do
            local checkSquare = cell:getGridSquare(x, y, pz)
            if checkSquare then
                local animals = checkSquare:getAnimals()
                if animals then
                    for i = 0, animals:size() - 1 do
                        local animal = animals:get(i)
                        if animal and AE_TamingSystem.isValidAnimal(animal) then
                            animalsFound = animalsFound + 1
                            if tryInitializeAnimal(animal, player) then
                                animalsInitialized = animalsInitialized + 1
                            end
                        end
                    end
                end
            end
        end
    end
end)
local tickCounter = 0
Events.OnTick.Add(function()
    if not Config.IsSystemEnabled("TamingSystem") then return end
    tickCounter = tickCounter + 1
    if #AE_TamingSystem.pendingSlotAssignments > 0 then
        AE_TamingSystem.ProcessPendingSlotAssignments()
    end
    if tickCounter % 300 == 0 then
        checkAnimalDeaths()
    end
    if tickCounter % 18000 == 0 then
        local deadEntries = {}
        for id, animal in pairs(AE_TamingSystem.animalCache) do
            if not animal or animal:isDead() then
                table.insert(deadEntries, id)
            end
        end
        for _, id in ipairs(deadEntries) do
            AE_TamingSystem.animalCache[id] = nil
            
            -- SUB-SESSION 5: Clear taming states for dead animals
            if AE_TamingSystem.animalsTamingInProgress[id] then
                print("[TAMING CLEANUP] Clearing taming state for dead animal: " .. id)
                AE_TamingSystem.animalsTamingInProgress[id] = nil
                AE_TamingSystem.tamingTimeouts[id] = nil
                
                -- Notify MP clients of state change
                if AE_EnvironmentDetector.isSinglePlayer() then
                    -- No action needed for single-player
                else
                    if not isClient() then
                        sendServerCommand("AE_TamingService", "tamingStateChanged", {
                            animalID = id,
                            inProgress = false,
                            reason = "animal_death",
                            timestamp = getTimestampMs()
                        })
                    end
                end
            end
        end
        
        -- SUB-SESSION 5: Integrate taming state cleanup with existing cycles
        AE_TamingSystem.cleanupStuckTamingStates()
        
        -- PHASE 1: Integrate persistent mapping cleanup with existing cycles
        AE_TamingSystem.cleanupPersistentMappings()
    end
end)

-- Interface Implementation: Connect TamingSystem to AE_TamingInterface
if AE_TamingInterface then
    -- Update interface functions to use actual TamingSystem implementations
    AE_TamingInterface.makeAnimalTamed = function(animal)
        return AE_TamingSystem.MakeAnimalTamed(animal)
    end
    
    AE_TamingInterface.generateAnimalID = function(animalName)
        return AE_TamingSystem.GenerateAnimalID(animalName)
    end
    
    AE_TamingInterface.validateTamingEligibility = function(animal)
        return not AE_DataService.isTamed(animal) and AE_DataService.isAnimalValid(animal)
    end
end

return AE_TamingSystem