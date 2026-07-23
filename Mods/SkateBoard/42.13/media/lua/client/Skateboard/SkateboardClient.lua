require("TimedActions/ISInventoryTransferUtil")
require("Skateboard/SkateboardCore")
require("Skateboard/SkateboardOptions")
require("Skateboard/TimedAction/SkateboardHopOnAction")
require("Skateboard/TimedAction/SkateboardTrickOllie")

---@class SkateboardClient
Skateboard = Skateboard or {}
Skateboard.Client = Skateboard.Client or {}

local Client = Skateboard.Client
local Core = Skateboard.Core
local Options = Skateboard.Options

Client.lastAddSoundTimestamp = 0
Client.lastSyncedState = Client.lastSyncedState or {}
Client.lastSyncedSoundState = Client.lastSyncedSoundState or {}

---@return number, number, boolean
local function getSkateboardSpeedSettings()
    local speedSlow = 1.7
    local speedFast = 2.5
    local immersive = true

    if isClient() then
        -- this code is ran client side in multiplayer
        if SandboxVars and SandboxVars.Skateboard then
            if SandboxVars.Skateboard.skateboardWalkSpeedMultiplier then
                speedSlow = SandboxVars.Skateboard.skateboardWalkSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardRunSpeedMultiplier then
                speedFast = SandboxVars.Skateboard.skateboardRunSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardImmersive ~= nil then
                immersive = SandboxVars.Skateboard.skateboardImmersive
            end
        end
    elseif isServer() then
        -- this code is ran server side in multiplayer
        if SandboxVars and SandboxVars.Skateboard then
            if SandboxVars.Skateboard.skateboardWalkSpeedMultiplier then
                speedSlow = SandboxVars.Skateboard.skateboardWalkSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardRunSpeedMultiplier then
                speedFast = SandboxVars.Skateboard.skateboardRunSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardImmersive ~= nil then
                immersive = SandboxVars.Skateboard.skateboardImmersive
            end
        end
    else
        -- this code is ran in singleplayer
        local options = Options.get()
        if options then
            local walkOption = options:getOption(Options.Key.WalkSpeedMultiplier)
            local runOption = options:getOption(Options.Key.RunSpeedMultiplier)
            local immersiveOption = options:getOption(Options.Key.ImmersiveMode)
            if walkOption then
                speedSlow = walkOption:getValue()
            end
            if runOption then
                speedFast = runOption:getValue()
            end
            if immersiveOption then
                immersive = immersiveOption:getValue()
            end
        end
    end

    return speedSlow, speedFast, immersive
end

---@param player IsoPlayer|nil
---@param soundName string
---@param isPlaying boolean
---@return nil
function Client.syncSoundState(player, soundName, isPlaying)
    if not (isClient() and player) then
        return
    end

    if player.isLocalPlayer and not player:isLocalPlayer() then
        return
    end

    local previousState = Client.lastSyncedSoundState[soundName]
    if previousState == isPlaying then
        return
    end

    sendClientCommand(Core.SyncModule, "Sound", {
        sound = soundName,
        playing = isPlaying
    })
    Client.lastSyncedSoundState[soundName] = isPlaying
end

---@param player IsoPlayer
---@return number
local function getVariableFloat(player, variable)
    if player.getVariableFloat then
        return player:getVariableFloat(variable, 0)
    end

    local rawValue = player:getVariableString(variable)
    return tonumber(rawValue) or 0
end

---@param player IsoPlayer
---@return table
local function getSyncState(player)
    return {
        active = player:getVariableBoolean(Core.PlayerVars.Active),
        held = player:getVariableBoolean(Core.PlayerVars.Held),
        rolling = player:getVariableBoolean(Core.PlayerVars.Rolling),
        toHandPlayed = player:getVariableBoolean(Core.PlayerVars.ToHandPlayed),
        walkSpeed = getVariableFloat(player, Core.PlayerVars.WalkSpeed),
        runSpeed = getVariableFloat(player, Core.PlayerVars.RunSpeed),
        speed = getVariableFloat(player, Core.PlayerVars.Speed),
        ollie = player:getVariableBoolean(Core.PlayerVars.Ollie),
        ollieStarted = player:getVariableBoolean(Core.PlayerVars.OllieStarted)
    }
end

---@param previous table
---@param current table
---@return boolean
local function didSyncStateChange(previous, current)
    previous = previous or {}
    if previous.active ~= current.active then
        return true
    end
    if previous.held ~= current.held then
        return true
    end
    if previous.rolling ~= current.rolling then
        return true
    end
    if previous.toHandPlayed ~= current.toHandPlayed then
        return true
    end
    if math.abs((previous.walkSpeed or 0) - current.walkSpeed) > 0.001 then
        return true
    end
    if math.abs((previous.runSpeed or 0) - current.runSpeed) > 0.001 then
        return true
    end
    if math.abs((previous.speed or 0) - current.speed) > 0.001 then
        return true
    end
    if previous.ollie ~= current.ollie then
        return true
    end
    if previous.ollieStarted ~= current.ollieStarted then
        return true
    end

    return false
end

---@param player IsoPlayer|nil
---@param force boolean|nil
---@return nil
function Client.syncState(player, force)
    if not (isClient() and player) then
        return
    end

    if player.isLocalPlayer and not player:isLocalPlayer() then
        return
    end

    local currentState = getSyncState(player)
    local previousState = Client.lastSyncedState
    if force or didSyncStateChange(previousState, currentState) then
        sendClientCommand(Core.SyncModule, "SetState", currentState)
        Client.lastSyncedState = currentState
    end
end

---@nodiscard
---@param player IsoPlayer|nil
---@return boolean
function Client.hasSkateboardInteractionTarget(player)
    if not player then
        return false
    end

    local currentItem = player:getPrimaryHandItem()
    if currentItem and currentItem.isEquipped and not currentItem:isEquipped() then
        currentItem = nil
    end

    if Core.isSkateboardItem(currentItem) then
        return true
    end

    local square = player:getSquare()
    if not square then
        return false
    end

    local items = Client.getItems(square)
    for _, worldObj in ipairs(items) do
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if Core.isSkateboardItem(item) then
                return true
            end
        end
    end

    return false
end

---@nodiscard
---@param player IsoPlayer|nil
---@param inventoryItem InventoryItem|nil
---@param destContainer ItemContainer|nil
---@return boolean
function Client.queueTransfer(player, inventoryItem, destContainer)
    if not (player and inventoryItem and destContainer) then
        return false
    end

    local srcContainer = inventoryItem:getContainer()
    if not srcContainer or srcContainer == destContainer then
        return false
    end

    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        local action = ISInventoryTransferUtil.newInventoryTransferAction(
            player,
            inventoryItem,
            srcContainer,
            destContainer
        )
        if action then
            action.maxTime = 0
            action.useProgressBar = false
            action.stopOnWalk = false
            action.stopOnRun = false
            ISTimedActionQueue.add(action)
            return true
        end
    end

    return false
end

---@nodiscard
---@return boolean
function Client.anyPlayerHasSkateboardEquipped()
    local playerCount = getNumActivePlayers and getNumActivePlayers() or 1

    if not playerCount or playerCount <= 0 then
        local playerObj = getSpecificPlayer(0)
        if not playerObj then
            return false
        end

        return Core.isSkateboardItem(playerObj:getPrimaryHandItem())
    end

    for playerIndex = 0, playerCount - 1 do
        local playerObj = getSpecificPlayer(playerIndex)
        if playerObj and Core.isSkateboardItem(playerObj:getPrimaryHandItem()) then
            return true
        end
    end

    return false
end

---@return nil
function Client.removeSkateboardEventsIfUnused()
    if Core.State.isEquipping then
        return
    end

    local playerCount = getNumActivePlayers and getNumActivePlayers() or 1
    if not playerCount or playerCount <= 0 then
        local playerObj = getSpecificPlayer(0)
        if playerObj and playerObj:getVariableBoolean(Core.PlayerVars.Active) then
            return
        end
    else
        for playerIndex = 0, playerCount - 1 do
            local playerObj = getSpecificPlayer(playerIndex)
            if playerObj and playerObj:getVariableBoolean(Core.PlayerVars.Active) then
                return
            end
        end
    end

    if not Client.anyPlayerHasSkateboardEquipped() then
        Events.OnPlayerUpdate.Remove(Client.updateSkateboardFlag)
        Events.OnPlayerUpdate.Remove(Client.updateSkateboardAudio)
    end
end

---@class SkateboardResetOptions
---@field preserveBlock boolean|nil

---@param player IsoPlayer|nil
---@param options SkateboardResetOptions|nil
---@return nil
function Client.resetPlayerState(player, options)
    if not player then
        return
    end

    Core.State.isEquipping = false

    local wasActive = player:getVariableBoolean(Core.PlayerVars.Active)

    player:setVariable(Core.PlayerVars.Held, false)
    player:setVariable(Core.PlayerVars.Active, false)
    player:setVariable(Core.PlayerVars.Rolling, false)
    player:setVariable(Core.PlayerVars.RollingTimestamp, "0")
    player:setVariable(Core.PlayerVars.ToHandPlayed, "false")
    player:setVariable(Core.PlayerVars.IdleToAimPlaying, false)
    player:setVariable(Core.PlayerVars.WalkSpeed, 1.0)
    player:setVariable(Core.PlayerVars.RunSpeed, 1.0)
    player:setVariable(Core.PlayerVars.Speed, 1.0)
    player:setIgnoreAutoVault(false)

    local emitter = player:getEmitter()
    if emitter then
        if emitter:isPlaying("SkateboardRolling") then
            emitter:stopSoundByName("SkateboardRolling")
        end
        if emitter:isPlaying("SkateboardToHand") then
            emitter:stopSoundByName("SkateboardToHand")
        end
    end
    player:getModData().skateboardRollingVolumeSet = false
    Client.syncSoundState(player, "SkateboardRolling", false)
    Client.syncSoundState(player, "SkateboardToHand", false)
    Client.syncSoundState(player, "SkateboardOllie", false)

    if not (options and options.preserveBlock) then
        player:setBlockMovement(false)
    end

    if wasActive and isClient() then
        Client.syncState(player, true)
    end

    Client.removeSkateboardEventsIfUnused()
end

---@nodiscard
---@param player IsoPlayer|nil
---@return boolean
function Client.shouldCleanupPlayer(player)
    if not player then
        return false
    end

    if Core.State.isEquipping then
        return false
    end

    if Core.isSkateboardItem(player:getPrimaryHandItem()) then
        return false
    end

    if player:getVariableBoolean(Core.PlayerVars.Active) then
        return true
    end

    if player:getVariableBoolean(Core.PlayerVars.Held) then
        return true
    end

    if player:isIgnoreAutoVault() then
        return true
    end

    return false
end

---@param player IsoPlayer
---@return nil
function Client.failSafeCleanup(player)
    if Client.shouldCleanupPlayer(player) then
        Client.resetPlayerState(player)
    end
end

---@nodiscard
---@param player IsoPlayer|nil
---@param rawItem InventoryItem|IsoWorldInventoryObject|nil
---@return boolean
function Client.dropInstant(player, rawItem)
    local inventoryItem = Core.getInventoryItem(rawItem)
    if not player or not inventoryItem then
        return false
    end

    if not Core.isSkateboardItem(inventoryItem) then
        return false
    end

    local square = player:getSquare()
    if not square then
        return false
    end

    Client.resetPlayerState(player, { preserveBlock = true })
    ISInventoryPaneContextMenu.dropItem(inventoryItem, player:getPlayerNum())

    return true
end

---@param worldobjects table
---@param items table
---@param playerIndex number
---@return nil
function Client.dropSkateboard(worldobjects, items, playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    for _, item in ipairs(items) do
        if Client.dropInstant(player, item) then
            return
        end
    end
end

---@param key number
---@return nil
function Client.onKeyPressed(key)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local options = Options.get()
    if not options then
        return
    end
    local ollieKey = options:getOption(Options.Key.OllieKey):getValue()
    local equipKey = options:getOption(Options.Key.EquipKey):getValue()

    if key == ollieKey and player:getVariableBoolean(Core.PlayerVars.Active) then
        ISTimedActionQueue.add(SkateboardTrickOllie:new(player))
        return
    end

    if key ~= equipKey then
        return
    end

    if not Client.hasSkateboardInteractionTarget(player) then
        return
    end

    local currentItem = player:getPrimaryHandItem()
    if Core.isSkateboardItem(currentItem) then
        Client.dropSkateboard(nil, { currentItem }, 0)
        return
    end

    local square = player:getSquare()
    if not square then
        return
    end

    local items = Client.getItems(square)
    local closestSkateboard = nil
    local closestDistance = 1000

    for _, worldObj in ipairs(items) do
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if Core.isSkateboardItem(item) then
                local distance = Core.getDistance2D(
                    worldObj:getWorldPosX(),
                    worldObj:getWorldPosY(),
                    square:getX(),
                    square:getY()
                )
                if distance < closestDistance then
                    closestSkateboard = worldObj
                    closestDistance = distance
                end
            end
        end
    end

    if not closestSkateboard then
        return
    end

    Core.State.isEquipping = true

    Client.equipSkateboard({ closestSkateboard }, 0, closestSkateboard)
end

---@param playerIndex number
---@param context ISContextMenu
---@param worldobjects table
---@param test boolean
---@return nil
function Client.addWorldContext(playerIndex, context, worldobjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    local currentWeapon = player:getPrimaryHandItem()
    if Core.isSkateboardItem(currentWeapon) then
        context:addOption("Hop off skateboard", worldobjects, Client.dropSkateboard, { currentWeapon }, playerIndex)
        return
    end

    local originSquare = worldobjects[1]:getSquare()
    if not instanceof(originSquare, "IsoGridSquare") then
        return
    end

    local items = Client.getItems(originSquare)
    local skateboards = {}

    for _, worldObj in ipairs(items) do
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if item and instanceof(item, "InventoryContainer") then
                local containerType = item:getItemContainer():getType()
                if Core.isSkateboardType(containerType) then
                    table.insert(skateboards, worldObj)
                end
            end
        end
    end

    if #skateboards == 0 then
        return
    end

    local closestSkateboard = nil
    local closestDistance = 1000

    for _, worldObj in ipairs(skateboards) do
        local distance = Core.getDistance2D(
            worldObj:getWorldPosX(),
            worldObj:getWorldPosY(),
            player:getSquare():getX(),
            player:getSquare():getY()
        )
        if distance < closestDistance then
            closestSkateboard = worldObj
            closestDistance = distance
        end
    end

    if closestSkateboard then
        context:addOption("Hop on skateboard", worldobjects, Client.equipSkateboard, playerIndex, closestSkateboard)
    end
end

---@param worldobjects table
---@param playerIndex number
---@param item InventoryItem
---@param container ItemContainer
---@return nil
function Client.hopOnSkateboard(worldobjects, playerIndex, item, container)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    local worldItem = item:getWorldItem()
    if worldItem then
        Client.equipSkateboard(worldobjects, playerIndex, worldItem)
        return
    end

    ISTimedActionQueue.add(ISEquipHeavyItem:new(player, item, 4))
end

---@param worldobjects table
---@param playerIndex number
---@param worldObj IsoWorldInventoryObject
---@return nil
function Client.equipSkateboard(worldobjects, playerIndex, worldObj)
    local player = getSpecificPlayer(playerIndex)
    if not (player and worldObj) then
        return
    end

    local playerSquare = player:getSquare()
    local itemSquare = worldObj:getSquare()
    if not (playerSquare and itemSquare) then
        return
    end

    local targetX = itemSquare:getX()
    local targetY = itemSquare:getY()

    player:faceLocation(targetX, targetY)

    local distance = Core.getDistance2D(playerSquare:getX(), playerSquare:getY(), targetX, targetY)
    if distance > 1.5 then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, itemSquare))
    end
    local item = worldObj:getItem()
    ISInventoryPaneContextMenu.equipWeapon(item, true, true, playerIndex)
    ISTimedActionQueue.add(SkateboardHopOnAction:new(player, item))
end

---@nodiscard
---@param square IsoGridSquare
---@return table
function Client.getItems(square)
    local items = {}
    if not instanceof(square, "IsoGridSquare") then
        return items
    end

    local squares = {
        square,
        square:getN(),
        square:getS(),
        square:getE(),
        square:getW()
    }

    for _, scanSquare in ipairs(squares) do
        if scanSquare then
            for _, worldObj in ipairs(scanSquare:getLuaTileObjectList()) do
                table.insert(items, worldObj)
            end
        end
    end

    return items
end

---@param player IsoPlayer
---@return nil
function Client.updateSkateboardAudio(player)
    local active = player:getVariableBoolean(Core.PlayerVars.Active)
    local emitter = player:getEmitter()
    local modData = player:getModData()
    local soundVolume = 0.40
    local soundRange = 15
    local options = Options.get()
    if options then
        soundVolume = options:getOption(Options.Key.SoundVolume):getValue()
        soundRange = options:getOption(Options.Key.SoundRange):getValue()
    end

    if player.isLocalPlayer and not player:isLocalPlayer() then
        if emitter:isPlaying("SkateboardRolling") then
            emitter:stopSoundByName("SkateboardRolling")
        end
        if emitter:isPlaying("SkateboardToHand") then
            emitter:stopSoundByName("SkateboardToHand")
        end
        if emitter:isPlaying("SkateboardOllie") then
            emitter:stopSoundByName("SkateboardOllie")
        end
        return
    end

    if not active then
        if emitter:isPlaying("SkateboardRolling") then
            emitter:stopSoundByName("SkateboardRolling")
        end
        Client.syncSoundState(player, "SkateboardRolling", false)
        Client.syncSoundState(player, "SkateboardToHand", false)
        Client.syncSoundState(player, "SkateboardOllie", false)
        player:setVariable(Core.PlayerVars.Rolling, "false")
        player:setVariable(Core.PlayerVars.RollingTimestamp, "0")
        player:setVariable(Core.PlayerVars.ToHandPlayed, "false")
        modData.skateboardRollingVolumeSet = false
        Client.syncState(player)
        return
    end

    if not player:getVariableBoolean(Core.PlayerVars.Rolling) then
        player:setVariable(Core.PlayerVars.RollingTimestamp, "0")
    end

    local isAiming = player:getVariableBoolean("aim")
    local isMoving = player:getVariableBoolean("ismoving")

    if isAiming then
        player:setVariable(Core.PlayerVars.RollingTimestamp, "0")
        if emitter:isPlaying("SkateboardRolling") then
            emitter:stopSoundByName("SkateboardRolling")
        end
        player:setVariable(Core.PlayerVars.Rolling, false)
        modData.skateboardRollingVolumeSet = false
        Client.syncSoundState(player, "SkateboardRolling", false)
        if not player:getVariableBoolean(Core.PlayerVars.ToHandPlayed) then
            local sound = emitter:playSoundImpl("SkateboardToHand", nil)
            emitter:setVolume(sound, soundVolume * 0.8)
            Client.syncSoundState(player, "SkateboardToHand", true)
            if not isMoving then
                player:setBlockMovement(true)
                Core.runAfter(0.8, function()
                    player:setBlockMovement(false)
                end)
            end
            player:setVariable(Core.PlayerVars.ToHandPlayed, "true")
        end
        Client.syncState(player)
        return
    end

    player:setVariable(Core.PlayerVars.ToHandPlayed, "false")
    if not emitter:isPlaying("SkateboardToHand") then
        Client.syncSoundState(player, "SkateboardToHand", false)
    end

    if emitter:isPlaying("SkateboardRolling") and player:isPlayerMoving() then
        if not modData.skateboardRollingVolumeSet then
            emitter:stopSoundByName("SkateboardRolling")
            Client.syncSoundState(player, "SkateboardRolling", false)
        else
            player:setVariable(Core.PlayerVars.Rolling, true)
            Client.lastAddSoundTimestamp = Core.throttleAddSound(
                Client.lastAddSoundTimestamp or 0,
                player,
                soundRange
            )
            Client.syncState(player)
            return
        end
    end

    if not player:isPlayerMoving() then
        player:setVariable(Core.PlayerVars.Rolling, false)
        player:setVariable(Core.PlayerVars.RollingTimestamp, "0")
        modData.skateboardRollingVolumeSet = false
        emitter:stopSoundByName("SkateboardRolling")
        Client.syncSoundState(player, "SkateboardRolling", false)
        Client.syncState(player)
        return
    end

    player:setVariable(Core.PlayerVars.Rolling, true)
    if emitter:isPlaying("SkateboardRolling") then
        Client.lastAddSoundTimestamp = Core.throttleAddSound(
            Client.lastAddSoundTimestamp or 0,
            player,
            soundRange
        )
        Client.syncState(player)
        return
    end

    if tonumber(player:getVariableString(Core.PlayerVars.RollingTimestamp)) < 1 then
        player:setVariable(Core.PlayerVars.RollingTimestamp, tostring(getTimestampMs()))
    end

    local startTimestamp = tonumber(player:getVariableString(Core.PlayerVars.RollingTimestamp))
    if getTimestampMs() - startTimestamp >= 750 and not emitter:isPlaying("SkateboardRolling") then
        if not emitter:isPlaying("SkateboardOllie") then
            local sound = emitter:playSoundImpl("SkateboardRolling", nil)
            emitter:setVolume(sound, soundVolume)
            modData.skateboardRollingVolumeSet = true
            Client.syncSoundState(player, "SkateboardRolling", true)
        end
    end

    Client.syncState(player)
end

---@param player IsoPlayer
---@return nil
function Client.updateSkateboardFlag(player)
    local primaryItem = player:getPrimaryHandItem()
    local secondaryItem = player:getSecondaryHandItem()
    local handItem = primaryItem or secondaryItem

    if Core.State.isEquipping then
        if handItem and Core.isSkateboardItem(handItem) then
            Core.State.isEquipping = false
        end
    end

    if not handItem then
        return
    end

    if not Core.isSkateboardItem(handItem) then
        Client.resetPlayerState(player)
        return
    end

    local bodyDamage = player.getBodyDamage and player:getBodyDamage() or nil
    player:setVariable(Core.PlayerVars.Active, true)
    player:setIgnoreAutoVault(true)

    if bodyDamage then
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            for index = 1, bodyParts:size() do
                local part = bodyParts:get(index - 1)
                if part then
                    local partType = string.lower(tostring(part:getType()))
                    if string.find(partType, "leg") or string.find(partType, "foot") then
                        if part:HasInjury() and part:getFractureTime() > 0 then
                            player:setVariable(Core.PlayerVars.Speed, 0.01)
                            Client.syncState(player)
                            return
                        end

                        if part:getHealth() < 75 then
                            player:setVariable(Core.PlayerVars.Speed, (part:getHealth() / 100) * 0.8)
                            Client.syncState(player)
                            return
                        end
                    end
                end
            end
        end
    end

    local speedSlow, speedFast, immersive = getSkateboardSpeedSettings()

    player:setVariable(Core.PlayerVars.Speed, 1.00)
    player:setVariable(Core.PlayerVars.WalkSpeed, speedSlow)
    player:setVariable(Core.PlayerVars.RunSpeed, speedFast)

    local square = player:getSquare()
    local isRough = SkateboardHopOnAction.squareIsRough(square)

    if isRough and immersive then
        player:setVariable(Core.PlayerVars.Speed, 0.20)
    else
        player:setVariable(Core.PlayerVars.Speed, 1.00)
    end

    Client.syncState(player)
end

local lastAddSoundTimestamp = 0

---@param player IsoPlayer
---@param soundName string
---@param isPlaying boolean
---@return nil
local function syncOllieSound(player, soundName, isPlaying)
    if isClient() and Skateboard and Skateboard.Client and Skateboard.Client.syncSoundState then
        Skateboard.Client.syncSoundState(player, soundName, isPlaying)
    end
end

---@param player IsoPlayer
---@return nil
function Client.updateOllieSounds(player)
    local skateboardActive = player:getVariableBoolean(Core.PlayerVars.Active)
    if not skateboardActive then
        return
    end

    local ollieStarted = player:getVariableBoolean(Core.PlayerVars.OllieStarted)
    local ollie = player:getVariableBoolean(Core.PlayerVars.Ollie)
    local emitter = player:getEmitter()
    local soundVolume = 0.40
    local soundRange = 15
    local options = Options.get()
    if options then
        soundVolume = options:getOption(Options.Key.SoundVolume):getValue()
        soundRange = options:getOption(Options.Key.SoundRange):getValue()
    end

    if ollie then
        if ollieStarted then
            if emitter:isPlaying("SkateboardRolling") then
                Core.runAfter(0.3, function()
                    if emitter:isPlaying("SkateboardRolling") then
                        emitter:stopSoundByName("SkateboardRolling")
                    end
                end)
            end
            if not emitter:isPlaying("SkateboardOllie") then
                Core.runAfter(0.15, function()
                    if not emitter:isPlaying("SkateboardOllie") then
                        local sound = emitter:playSoundImpl("SkateboardOllie", nil)
                        emitter:setVolume(sound, soundVolume)
                        syncOllieSound(player, "SkateboardOllie", true)
                        lastAddSoundTimestamp = Core.throttleAddSound(lastAddSoundTimestamp, player, soundRange)
                    end
                end)
            else
                lastAddSoundTimestamp = Core.throttleAddSound(lastAddSoundTimestamp, player, soundRange)
            end
        end
        return
    end

    if not ollie and not ollieStarted then
        if emitter:isPlaying("SkateboardOllie") then
            if not emitter:isPlaying("SkateboardRolling") then
                local sound = emitter:playSoundImpl("SkateboardRolling", nil)
                emitter:setVolume(sound, soundVolume)
                syncOllieSound(player, "SkateboardRolling", true)
            end
            emitter:stopSoundByName("SkateboardOllie")
            syncOllieSound(player, "SkateboardOllie", false)
        end
    end
end

---@return nil
function Client.initSkateboard()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local speedSlow, speedFast = getSkateboardSpeedSettings()
    local primaryItem = player:getPrimaryHandItem()

    if not Core.isSkateboardItem(primaryItem) then
        Client.resetPlayerState(player)
        return
    end

    player:setVariable(Core.PlayerVars.Active, true)
    player:setIgnoreAutoVault(true)
    player:setVariable(Core.PlayerVars.Held, true)
    Events.OnPlayerUpdate.Add(Client.updateSkateboardFlag)
    Events.OnPlayerUpdate.Add(Client.updateSkateboardAudio)
    player:setVariable(Core.PlayerVars.IdleToAimPlaying, false)
    player:setVariable(Core.PlayerVars.WalkSpeed, speedSlow)
    player:setVariable(Core.PlayerVars.RunSpeed, speedFast)
    player:setVariable(Core.PlayerVars.Rolling, false)
    player:setVariable(Core.PlayerVars.RollingTimestamp, "0")

    Client.syncState(player, true)
end

local originalAttachItem = ISAttachItemHotbar.animEvent

---@param event AnimEvent
---@return nil
function ISAttachItemHotbar:animEvent(event)
    if Core.isSkateboardItem(self.item) then
        self.character:setVariable(Core.PlayerVars.Held, true)
        Client.syncState(self.character, true)
    end

    originalAttachItem(self, event)
end

local originalDetachItem = ISDetachItemHotbar.animEvent

---@param event AnimEvent
---@return nil
function ISDetachItemHotbar:animEvent(event)
    if Core.isSkateboardItem(self.item) then
        Client.resetPlayerState(self.character)
        self.character:setVariable(Core.PlayerVars.Held, false)
        Client.syncState(self.character, true)
    end

    originalDetachItem(self, event)
end

local originalEquipPerform = ISEquipWeaponAction.perform
function ISEquipWeaponAction:perform()
    if Core.isSkateboardItem(self.item) then
        Events.OnPlayerUpdate.Add(Client.updateSkateboardFlag)
        Events.OnPlayerUpdate.Add(Client.updateSkateboardAudio)
        self.character:setVariable(Core.PlayerVars.Held, true)
        Client.syncState(self.character, true)
    end

    originalEquipPerform(self)
end

Events.OnKeyPressed.Add(Client.onKeyPressed)
Events.OnFillWorldObjectContextMenu.Add(Client.addWorldContext)
Events.OnGameStart.Add(Client.initSkateboard)
Events.OnPlayerUpdate.Add(Client.failSafeCleanup)

return Client
