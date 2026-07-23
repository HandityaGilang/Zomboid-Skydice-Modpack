local AE_Hostility = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

-- Dependencies with defensive loading
local AnimalRegistry = nil
local Config = nil

local success, result = pcall(function()
    return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
end)
if success and result then
    AnimalRegistry = result
end

-- Inter-mod communication for config access
local AE_CoreCommunication = nil
success, result = pcall(function()
    return require("AnimalsEssentials/CoreSystems/AE_CoreCommunication")
end)
if success and result then
    AE_CoreCommunication = result
end

local hostilityStates = {}
local MELEE_ATTACK_RANGE = 1.5
local ATTACK_INTERVAL = 2.0
local STALKING_INTENSITY_THRESHOLD = 100
local EMERGENCY_PURSUIT_DISTANCE = 31
local MAX_PURSUIT_DISTANCE = 49

local function getGameTimeMinutes()
    return getGameTime():getWorldAgeHours() * 60
end

local function getDistance(entity1, entity2)
    if not entity1 or not entity2 then return 999999 end
    local x1, y1 = entity1:getX(), entity1:getY()
    local x2, y2 = entity2:getX(), entity2:getY()
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function calculateIntensityIncrement(distance)
    if distance >= 30 then
        return 1 + ZombRand(7)
    elseif distance >= 20 then
        return 7 + ZombRand(6)
    elseif distance >= 10 then
        return 12 + ZombRand(7)
    elseif distance >= 5 then
        return 18 + ZombRand(8)
    else
        return 25 + ZombRand(11)
    end
end

local function updateTargetVelocityPrediction(state, target, currentGameTime)
    if not target then return end
    local tx, ty = target:getX(), target:getY()
    if not state.targetLastPosition then
        state.targetLastPosition = {x = tx, y = ty, time = currentGameTime}
        state.targetVelocity = {x = 0, y = 0}
        return
    end
    local timeDelta = currentGameTime - state.targetLastPosition.time
    if timeDelta >= 0.1 then
        local dx = tx - state.targetLastPosition.x
        local dy = ty - state.targetLastPosition.y
        state.targetVelocity.x = dx / timeDelta
        state.targetVelocity.y = dy / timeDelta
        state.targetLastPosition.x = tx
        state.targetLastPosition.y = ty
        state.targetLastPosition.time = currentGameTime
    end
end

local function predictTargetPosition(target, state, predictionTime)
    if not target or not state.targetVelocity then
        return target:getX(), target:getY()
    end
    local tx, ty = target:getX(), target:getY()
    local predictedX = tx + (state.targetVelocity.x * predictionTime)
    local predictedY = ty + (state.targetVelocity.y * predictionTime)
    return predictedX, predictedY
end

local function generatePredictiveWaypoint(animal, state, predictedX, predictedY)
    local ax, ay = animal:getX(), animal:getY()
    local dx = predictedX - ax
    local dy = predictedY - ay
    local distance = math.sqrt(dx * dx + dy * dy)
    local seedBasedOffset = (state.individualSeed % 70) / 100.0
    local progressPercent = 0.2 + seedBasedOffset
    local waypointX = ax + (dx * progressPercent)
    local waypointY = ay + (dy * progressPercent)
    local randomOffsetX = -5 + ZombRand(11)
    local randomOffsetY = -5 + ZombRand(11)
    waypointX = waypointX + randomOffsetX
    waypointY = waypointY + randomOffsetY
    if distance > 0 then
        local biasStrength = 0.2
        local currentAngle = math.atan2(dy, dx)
        local biasedAngle = currentAngle + (state.preferredAngleOffset * biasStrength)
        local biasDistance = 3 + ZombRand(5)
        waypointX = waypointX + (math.cos(biasedAngle) * biasDistance)
        waypointY = waypointY + (math.sin(biasedAngle) * biasDistance)
    end
    return waypointX, waypointY
end

local function updateStalkingIntensity(state, distance, deltaTime)
    if not state.stalkingIntensity then
        state.stalkingIntensity = 0
    end
    if not state.lastIntensityUpdate then
        state.lastIntensityUpdate = 0
    end
    state.lastIntensityUpdate = state.lastIntensityUpdate + 1
    local updateFrequency = distance >= 20 and 30 or (distance >= 10 and 20 or 10)
    if state.lastIntensityUpdate >= updateFrequency then
        local increment = calculateIntensityIncrement(distance)
        state.stalkingIntensity = state.stalkingIntensity + increment
        state.lastIntensityUpdate = 0
        if state.stalkingIntensity >= STALKING_INTENSITY_THRESHOLD then
            state.stalkingIntensity = ZombRand(15)
            return true
        end
    end
    return false
end

local function checkIfStuck(animal, state, currentGameTime)
    if not animal or not state then return false end
    local ax, ay = animal:getX(), animal:getY()
    if not state.lastKnownPosition then
        state.lastKnownPosition = {x = ax, y = ay, time = currentGameTime}
        state.isStuck = false
        return false
    end
    local timeSinceLastCheck = currentGameTime - state.lastKnownPosition.time
    if timeSinceLastCheck >= state.stuckCheckInterval then
        local dx = ax - state.lastKnownPosition.x
        local dy = ay - state.lastKnownPosition.y
        local distanceMoved = math.sqrt(dx * dx + dy * dy)
        if distanceMoved < 0.5 then
            state.isStuck = true
        else
            state.isStuck = false
            state.adaptivePathfindingActive = false
        end
        state.lastKnownPosition.x = ax
        state.lastKnownPosition.y = ay
        state.lastKnownPosition.time = currentGameTime
    end
    return state.isStuck
end

local function generateAdaptiveWaypoint(animal, state, predictedX, predictedY)
    local ax, ay = animal:getX(), animal:getY()
    local dx = predictedX - ax
    local dy = predictedY - ay
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance == 0 then
        local randomAngle = (ZombRand(360) * math.pi / 180)
        return ax + math.cos(randomAngle) * 10, ay + math.sin(randomAngle) * 10
    end
    local dirX = dx / distance
    local dirY = dy / distance
    local perpAngle = (state.individualSeed % 2 == 0) and (math.pi / 2) or (-math.pi / 2)
    local perpX = dirX * math.cos(perpAngle) - dirY * math.sin(perpAngle)
    local perpY = dirX * math.sin(perpAngle) + dirY * math.cos(perpAngle)
    local sideDistance = 10 + ZombRand(6)
    local waypointX = ax + (perpX * sideDistance)
    local waypointY = ay + (perpY * sideDistance)
    local forwardProgress = 0.3 + (ZombRand(21) / 100.0)
    waypointX = waypointX + (dirX * distance * forwardProgress)
    waypointY = waypointY + (dirY * distance * forwardProgress)
    return waypointX, waypointY
end

local function triggerAttackAnimation(animal, target)
    if not animal or not target then return end
    local success = pcall(function()
        local ax, ay = animal:getX(), animal:getY()
        local tx, ty = target:getX(), target:getY()
        local dx = tx - ax
        local dy = ty - ay
        local angle = math.atan2(dy, dx)
        local degrees = math.deg(angle)
        local direction = math.floor(((degrees + 202.5) % 360) / 45)
        if animal.setDir then
            animal:setDir(IsoDirections.fromIndex(direction))
        end
    end)
end

local function isPreyAnimal(targetAnimal, config)
    if not targetAnimal or not config or not config.PreyAnimals then
        return false
    end
    local success, targetType = pcall(function()
        return targetAnimal:getAnimalType()
    end)
    if not success or not targetType then
        return false
    end
    for _, preyType in ipairs(config.PreyAnimals) do
        if targetType == preyType then
            return true
        end
    end
    return false
end

local function scanForTargets(animal, config)
    if not animal then return {} end
    local square = animal:getSquare()
    if not square then return {} end
    local cell = square:getCell()
    if not cell then return {} end
    local ax, ay, az = animal:getX(), animal:getY(), animal:getZ()
    local targets = {}
    local radius = config.DetectionRadius or 20
    for x = ax - radius, ax + radius do
        for y = ay - radius, ay + radius do
            local checkSquare = cell:getGridSquare(x, y, az)
            if checkSquare then
                local animals = checkSquare:getAnimals()
                if animals then
                    for i = 0, animals:size() - 1 do
                        local otherAnimal = animals:get(i)
                        if otherAnimal and otherAnimal ~= animal and not otherAnimal:isDead() then
                            local distance = getDistance(animal, otherAnimal)
                            if distance <= radius then
                                if isPreyAnimal(otherAnimal, config) then
                                    table.insert(targets, {
                                        type = "prey",
                                        entity = otherAnimal,
                                        distance = distance,
                                        priority = 5
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return targets
end

local function selectTarget(animal, targets, config)
    if not targets or #targets == 0 then
        return nil
    end
    table.sort(targets, function(a, b)
        if a.priority == b.priority then
            return a.distance < b.distance
        end
        return a.priority > b.priority
    end)
    return targets[1]
end

local function applyDamageToTarget(attacker, target)
    if not target or target:isDead() then
        return true
    end
    local success, targetKilled = pcall(function()
        if target.Kill then
            target:Kill(attacker)
            return true
        else
            return false
        end
    end)
    return success and targetKilled
end

local function getHostilityConfig(animalCategory)
    if not Config then
        if AE_CoreCommunication and AE_CoreCommunication.requestConfig then
            AE_CoreCommunication.requestConfig(function(configData)
                Config = configData
            end)
        end
        -- Fallback config for cats
        return {
            Enabled = true,
            PreyAnimals = {"rat", "ratmale", "ratfemale", "mouse", "mousemale", "mousefemale", "rabbit", "rabbitmale", "rabbitfemale", "chicken", "rooster", "hen"},
            DetectionRadius = 30,
            ChaseRadius = 40,
            AttackCooldownSeconds = 5,
            EngageDurationMinutes = 15
        }
    end
    return Config.GetHostilityConfig and Config.GetHostilityConfig(animalCategory) or nil
end

function AE_Hostility.Initialize(animal)
    if not animal then
        return false
    end
    if not AnimalRegistry then
        return false
    end
    
    local animalCategory = AnimalRegistry.GetAnimalType and AnimalRegistry.GetAnimalType(animal)
    if not animalCategory then
        return false
    end
    local hostilityConfig = getHostilityConfig(animalCategory)
    if not hostilityConfig or not hostilityConfig.Enabled then
        return false
    end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID or animalID == "" then
        animalID = "wild_" .. tostring(animal:getOnlineID())
    end
    
    if not hostilityStates[animalID] then
        hostilityStates[animalID] = {
            currentTarget = nil,
            isEngaged = false,
            lastScanTime = 0,
            lastAttackTime = 0,
            attackCooldownUntil = 0,
            engagementStartTime = 0,
            targetLastPosition = nil,
            targetVelocity = {x = 0, y = 0},
            predictedWaypoint = nil,
            stalkingIntensity = 0,
            lastIntensityUpdate = 0,
            isEmergencyPursuit = false,
            emergencyPursuitCounter = 0,
            individualSeed = ZombRand(1000) + 1,
            preferredAngleOffset = (ZombRand(360) * math.pi / 180),
            isInCombat = false,
            totalKills = 0,
            lastSeenTargetTime = 0,
            targetLostGracePeriod = 10,
            lastMovementTime = 0,
            movementCooldownUntil = 0,
            longDistanceRetargetCount = 0,
            emergencyPursuitTickCounter = 0,
            lastKnownPosition = nil,
            isStuck = false,
            stuckCheckInterval = 10,
            adaptivePathfindingActive = false,
            isAttackPaused = false,
            attackPauseTicksRemaining = 0,
            attackAnimationEndTime = 0,
            intensityInitializationOffset = (ZombRand(100) / 100.0) * 5.0,
            stalkingThreshold = 100
        }
    end
    return true
end

function AE_Hostility.GetState(animal)
    if not animal then return nil end
    local animalID = AE_DataService.getStableID(animal)
    if not animalID or animalID == "" then
        animalID = "wild_" .. tostring(animal:getOnlineID())
    end
    return hostilityStates[animalID]
end

function AE_Hostility.Update(animal, deltaSeconds)
    if not animal then return end
    if not AnimalRegistry then return end
    
    local animalCategory = AnimalRegistry.GetAnimalType and AnimalRegistry.GetAnimalType(animal)
    if not animalCategory then return end
    
    local hostilityConfig = getHostilityConfig(animalCategory)
    if not hostilityConfig or not hostilityConfig.Enabled then return end
    
    local state = AE_Hostility.GetState(animal)
    if not state then
        AE_Hostility.Initialize(animal)
        state = AE_Hostility.GetState(animal)
        if not state then return end
    end
    
    local currentTime = getTimestampMs()
    local currentGameTime = getGameTimeMinutes()
    local currentTimeSec = currentTime / 1000.0
    
    if state.isAttackPaused then
        state.attackPauseTicksRemaining = state.attackPauseTicksRemaining - 1
        if state.attackPauseTicksRemaining <= 0 then
            state.isAttackPaused = false
            state.attackPauseTicksRemaining = 0
        end
    end
    
    if state.attackCooldownUntil > currentGameTime then
        return
    end
    
    if state.isEngaged then
        if not state.currentTarget or state.currentTarget:isDead() then
            state.isEngaged = false
            state.currentTarget = nil
        else
            local distance = getDistance(animal, state.currentTarget)
            if distance <= hostilityConfig.ChaseRadius then
                state.lastSeenTargetTime = currentGameTime
                updateTargetVelocityPrediction(state, state.currentTarget, currentGameTime)
                
                if distance >= EMERGENCY_PURSUIT_DISTANCE and distance <= MAX_PURSUIT_DISTANCE then
                    if not state.isEmergencyPursuit then
                        state.isEmergencyPursuit = true
                        state.emergencyPursuitCounter = 0
                        state.longDistanceRetargetCount = state.longDistanceRetargetCount + 1
                        if state.longDistanceRetargetCount >= 3 then
                            state.isEngaged = false
                            state.isInCombat = false
                            state.currentTarget = nil
                            state.targetLastPosition = nil
                            state.targetVelocity = {x = 0, y = 0}
                            state.predictedWaypoint = nil
                            state.stalkingIntensity = 0
                            state.longDistanceRetargetCount = 0
                            state.isEmergencyPursuit = false
                            return
                        end
                    end
                elseif state.isEmergencyPursuit and distance < EMERGENCY_PURSUIT_DISTANCE then
                    state.isEmergencyPursuit = false
                    state.longDistanceRetargetCount = 0
                end
                
                local shouldMove = false
                if state.isEmergencyPursuit then
                    state.emergencyPursuitCounter = state.emergencyPursuitCounter + 1
                    if state.emergencyPursuitCounter >= 2 then
                        shouldMove = true
                        state.emergencyPursuitCounter = 0
                    end
                else
                    shouldMove = updateStalkingIntensity(state, distance, deltaSeconds)
                end
                
                local isStuck = checkIfStuck(animal, state, currentGameTime)
                if shouldMove and distance > MELEE_ATTACK_RANGE and not state.isAttackPaused then
                    local predictionTime = 1.0
                    local predictedX, predictedY = predictTargetPosition(state.currentTarget, state, predictionTime)
                    local waypointX, waypointY
                    if isStuck then
                        state.adaptivePathfindingActive = true
                        waypointX, waypointY = generateAdaptiveWaypoint(animal, state, predictedX, predictedY)
                    else
                        waypointX, waypointY = generatePredictiveWaypoint(animal, state, predictedX, predictedY)
                    end
                    state.predictedWaypoint = {x = waypointX, y = waypointY}
                    state.lastMovementTime = currentGameTime
                end
                
                if distance <= MELEE_ATTACK_RANGE then
                    state.isInCombat = true
                    local isAttackAnimating = currentTimeSec < state.attackAnimationEndTime
                    if currentTimeSec >= state.lastAttackTime + ATTACK_INTERVAL and not isAttackAnimating then
                        triggerAttackAnimation(animal, state.currentTarget)
                        local targetKilled = applyDamageToTarget(animal, state.currentTarget)
                        state.lastAttackTime = currentTimeSec
                        state.attackAnimationEndTime = currentTimeSec + 1.0
                        state.isAttackPaused = true
                        state.attackPauseTicksRemaining = 10
                        if targetKilled then
                            state.totalKills = state.totalKills + 1
                            state.isEngaged = false
                            state.isInCombat = false
                            state.currentTarget = nil
                            state.targetLastPosition = nil
                            state.targetVelocity = {x = 0, y = 0}
                            state.predictedWaypoint = nil
                            state.stalkingIntensity = 0
                            state.isEmergencyPursuit = false
                            state.lastSeenTargetTime = 0
                            state.longDistanceRetargetCount = 0
                            state.isStuck = false
                            state.adaptivePathfindingActive = false
                            state.attackCooldownUntil = currentGameTime + (hostilityConfig.AttackCooldownSeconds / 60)
                        end
                    end
                else
                    state.isInCombat = false
                end
            else
                if state.lastSeenTargetTime == 0 then
                    state.lastSeenTargetTime = currentGameTime
                end
                local timeSinceLastSeen = currentGameTime - state.lastSeenTargetTime
                if distance > MAX_PURSUIT_DISTANCE or 
                   timeSinceLastSeen > state.targetLostGracePeriod or
                   currentGameTime - state.engagementStartTime > hostilityConfig.EngageDurationMinutes then
                    state.isEngaged = false
                    state.isInCombat = false
                    state.currentTarget = nil
                    state.targetLastPosition = nil
                    state.targetVelocity = {x = 0, y = 0}
                    state.predictedWaypoint = nil
                    state.stalkingIntensity = 0
                    state.isEmergencyPursuit = false
                    state.lastSeenTargetTime = 0
                    state.longDistanceRetargetCount = 0
                    state.isStuck = false
                    state.adaptivePathfindingActive = false
                    state.attackCooldownUntil = currentGameTime + (hostilityConfig.AttackCooldownSeconds / 60)
                end
            end
        end
    end
    
    if not state.isEngaged then
        if currentTime - state.lastScanTime >= 2000 then
            local targets = scanForTargets(animal, hostilityConfig)
            local selectedTarget = selectTarget(animal, targets, hostilityConfig)
            if selectedTarget then
                state.currentTarget = selectedTarget.entity
                state.isEngaged = true
                state.engagementStartTime = currentGameTime
            end
            state.lastScanTime = currentTime
        end
    end
end

function AE_Hostility.IsEngaged(animal)
    local state = AE_Hostility.GetState(animal)
    return state and state.isEngaged or false
end

function AE_Hostility.IsInCombat(animal)
    local state = AE_Hostility.GetState(animal)
    return state and state.isInCombat or false
end

function AE_Hostility.GetTarget(animal)
    local state = AE_Hostility.GetState(animal)
    if not state or not state.isEngaged then
        return nil
    end
    return state.currentTarget
end

function AE_Hostility.GetTargetPosition(animal)
    local state = AE_Hostility.GetState(animal)
    if not state then
        return nil, nil
    end
    if state.isAttackPaused then
        return nil, nil
    end
    if not state.currentTarget then
        return nil, nil
    end
    if state.isInCombat then
        return state.currentTarget:getX(), state.currentTarget:getY()
    end
    if state.predictedWaypoint then
        return state.predictedWaypoint.x, state.predictedWaypoint.y
    end
    return state.currentTarget:getX(), state.currentTarget:getY()
end

function AE_Hostility.SetForagingTarget(animal, prey)
    local state = AE_Hostility.GetState(animal)
    if not state then
        AE_Hostility.Initialize(animal)
        state = AE_Hostility.GetState(animal)
    end
    if state and prey then
        local currentGameTime = getGameTimeMinutes()
        state.currentTarget = prey
        state.isEngaged = true
        state.engagementStartTime = currentGameTime
        state.lastSeenTargetTime = currentGameTime
        state.stalkingIntensity = 0
        state.isEmergencyPursuit = false
        state.adaptivePathfindingActive = false
        return true
    end
    return false
end

function AE_Hostility.Disengage(animal)
    local state = AE_Hostility.GetState(animal)
    if state then
        state.isEngaged = false
        state.isInCombat = false
        state.currentTarget = nil
        state.targetLastPosition = nil
        state.targetVelocity = {x = 0, y = 0}
        state.predictedWaypoint = nil
        state.stalkingIntensity = 0
        state.isEmergencyPursuit = false
    end
end

return AE_Hostility