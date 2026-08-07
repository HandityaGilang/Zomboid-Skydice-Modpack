require "ISUI/ISContextMenu"
require "ComputerMod_Sandbox"
require "ComputerMod_ScreenGlow"
require "ComputerMod_Power"
require "ComputerMod_Network"
require "ComputerMod_Debug"
require "ComputerMod_RelayRepair"
require "ComputerMod_RelayRepairUI"

ComputerContextMenu = {}
local computerMenuTexture = getTexture("media/textures/files.PNG")

local gameDiscItems = {
    os = "ComputerMod.SystemCDPZOS",
    pong = "ComputerMod.GameCDPong",
    snake = "ComputerMod.GameCDSnake",
    minesweeper = "ComputerMod.GameCDMinesweeper",
    tetris = "ComputerMod.GameCDTetris",
    space_invaders = "ComputerMod.GameCDSpaceInvaders",
    doom = "ComputerMod.GameCDDoom",
    racer = "ComputerMod.GameCDRacer",
    flappy = "ComputerMod.GameCDFlappy",
    breakout = "ComputerMod.GameCDBreakout",
    asteroids = "ComputerMod.GameCDAsteroids",
    frogger = "ComputerMod.GameCDFrogger",
    missile = "ComputerMod.GameCDMissile",
    lander = "ComputerMod.GameCDLander",
    circuit = "ComputerMod.GameCDCircuit",
    memory = "ComputerMod.GameCDMemory",
    starpilot = "ComputerMod.GameCDStarPilot",
    caverunner = "ComputerMod.GameCDCaveRunner",
    lightsout = "ComputerMod.GameCDLightsOut",
    signalmatch = "ComputerMod.GameCDSignalMatch",
    boxpush = "ComputerMod.GameCDBoxPush",
    tileslide = "ComputerMod.GameCDTileSlide",
    pipelink = "ComputerMod.GameCDPipeLink",
    codebreaker = "ComputerMod.GameCDCodeBreaker",
    outbreakops = "ComputerMod.GameCDOutbreakOps",
    blank = "ComputerMod.BlankCD",
    hack = "ComputerMod.PasswordHackCD"
}

local gameDiscLabels = {
    os = "PZ OS 3.1 CD",
    pong = "Pong CD",
    snake = "Snake CD",
    minesweeper = "Minesweeper CD",
    tetris = "Tetris CD",
    space_invaders = "Invaders CD",
    doom = "Doom CD",
    racer = "Road Race CD",
    flappy = "Flappy Bird CD",
    breakout = "Breakout CD",
    asteroids = "Asteroids CD",
    frogger = "Frogger CD",
    missile = "Missile Command CD",
    lander = "Lunar Lander CD",
    circuit = "Circuit Runner CD",
    memory = "Memory Match CD",
    starpilot = "Star Pilot CD",
    caverunner = "Cave Runner CD",
    lightsout = "Lights Out CD",
    signalmatch = "Signal Match CD",
    boxpush = "Box Push CD",
    tileslide = "Tile Slide CD",
    pipelink = "Pipe Link CD",
    codebreaker = "Code Breaker CD",
    outbreakops = "Outbreak Ops CD",
    blank = "Blank CD",
    hack = "Password Hack CD"
}

local function normalizeDiscType(fullType)
    if not fullType then return nil end
    return string.lower(tostring(fullType))
end

local function getMountedDiscGame(data)
    if not data or not data.ComputerModMountedCD then return nil end
    local mountedGame = tostring(data.ComputerModMountedCD)
    if gameDiscItems[mountedGame] then return mountedGame end
    local mountedType = normalizeDiscType(data.ComputerModMountedCDItem or mountedGame)
    if mountedType then
        for gameId, fullType in pairs(gameDiscItems) do
            if normalizeDiscType(fullType) == mountedType then
                return gameId
            end
        end
    end
    return mountedGame
end

local function cmText(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= key then return value end
    end
    return fallback
end

local function getDiscEntryFromItem(item)
    if not item or not item.getFullType then return nil end
    local fullType = item:getFullType()
    local normalized = normalizeDiscType(fullType)
    if not normalized then return nil end
    local itemData = item.getModData and item:getModData() or nil
    local savedDiscLabel = itemData and itemData.ComputerModDiscLabel or nil
    local displayName = savedDiscLabel and tostring(savedDiscLabel) or (item.getDisplayName and tostring(item:getDisplayName() or "") or "")

    for gameId, mappedType in pairs(gameDiscItems) do
        if normalized == normalizeDiscType(mappedType) then
            local label = displayName ~= "" and displayName or gameDiscLabels[gameId] or gameId
            return {gameId = gameId, label = label, fullType = fullType}
        end
    end

    return nil
end

local function addItemWithSavedName(inventory, fullType, savedName)
    if not inventory or not inventory.AddItem or not fullType then return end
    local item = inventory:AddItem(fullType)
    if item and savedName and savedName ~= "" and item.setName then
        pcall(function() item:setName(savedName) end)
    end
    if item and item.getModData and savedName and savedName ~= "" then
        item:getModData().ComputerModDiscLabel = savedName
    end
    return item
end

local function syncInventoryItem(inventory, item, added)
    if inventory and inventory.setDrawDirty then
        pcall(function() inventory:setDrawDirty(true) end)
    end
    if not inventory or not item then return end
    if isClient and isClient() then
        if added and sendAddItemToContainer then
            pcall(function() sendAddItemToContainer(inventory, item) end)
        elseif not added and sendRemoveItemFromContainer then
            pcall(function() sendRemoveItemFromContainer(inventory, item) end)
        end
    end
end

local function cloneDiscContents(contents)
    local copy = {}
    if type(contents) ~= "table" then return copy end
    for i = 1, #contents do
        local entry = contents[i]
        if type(entry) == "table" then
            local entryCopy = {}
            for k, v in pairs(entry) do
                if type(v) == "table" then
                    local nested = {}
                    for nk, nv in pairs(v) do
                        nested[nk] = nv
                    end
                    entryCopy[k] = nested
                else
                    entryCopy[k] = v
                end
            end
            copy[#copy + 1] = entryCopy
        end
    end
    return copy
end

local function returnDiscToPlayer(playerObj, inventory, fullType, label, contents)
    if not inventory or not fullType then return nil end
    local savedContents = cloneDiscContents(contents)
    if isClient and isClient() then return nil end
    local item = addItemWithSavedName(inventory, fullType, label)
    if item and item.getModData and type(savedContents) == "table" then
        item:getModData().ComputerModDiscContents = savedContents
    end
    syncInventoryItem(inventory, item, true)
    return item
end

local function playComputerUISound(soundName, playerObj)
    if not soundName or soundName == "" then return end
    if getSoundManager then
        pcall(function() getSoundManager():playUISound(soundName) end)
    end
    if playerObj and playerObj.getEmitter then
        pcall(function() playerObj:getEmitter():playSound(soundName) end)
    end
end

local function getComputerCommandArgs(computer)
    if not computer or not computer.getSquare then return nil end
    local square = computer:getSquare()
    if not square then return nil end
    local data = computer.getModData and computer:getModData() or nil
    return {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        machineId = data and tostring(data.ComputerModMachineID or "") or ""
    }
end

local function isPlayerNearComputer(playerObj, computer)
    if not playerObj or not computer or not playerObj:getSquare() or not computer:getSquare() then return false end
    if playerObj:getZ() ~= computer:getZ() then return false end
    return math.abs(playerObj:getX() - computer:getX()) <= 2.6 and math.abs(playerObj:getY() - computer:getY()) <= 2.6
end

local function hasComputerPower(computer)
    return ComputerModPower and ComputerModPower.hasComputerPower and ComputerModPower.hasComputerPower(computer) or false
end

local function isNetworkTerminalRepaired(data)
    if not data or data.ComputerModNetworkTerminal ~= true then return false end
    if data.ComputerModNetworkRepaired == true then return true end
    local terminalId = data.ComputerModNetworkTerminalId
    local store = ComputerModNetwork and ComputerModNetwork.getStore and ComputerModNetwork.getStore() or nil
    local terminalStore = store and store.terminals and terminalId and store.terminals[terminalId] or nil
    return terminalStore and terminalStore.repaired == true
end

local function isRelayRepairAvailable(playerObj)
    if ComputerModDebug and ComputerModDebug.isEnabled and ComputerModDebug.isEnabled(playerObj) then return true end
    local internetEnabled = ComputerModNetwork and ComputerModNetwork.isInternetEnabled and ComputerModNetwork.isInternetEnabled() or true
    local gridPowerAvailable = ComputerModRelayRepair.isWorldGridPowerAvailable()
    return internetEnabled == false and gridPowerAvailable == false
end

local function isComputerSpriteName(spriteName)
    local value = spriteName and string.lower(tostring(spriteName)) or ""
    return value == "appliances_com_01_72"
        or value == "appliances_com_01_73"
        or value == "appliances_com_01_74"
        or value == "appliances_com_01_75"
        or value == "appliances_com_01_76"
        or value == "appliances_com_01_77"
        or value == "appliances_com_01_78"
        or value == "appliances_com_01_79"
end

local computerScreenOnSprites = {
    appliances_com_01_72 = "appliances_com_01_76",
    appliances_com_01_73 = "appliances_com_01_77",
    appliances_com_01_74 = "appliances_com_01_78",
    appliances_com_01_75 = "appliances_com_01_79"
}

local computerScreenOffSprites = {
    appliances_com_01_76 = "appliances_com_01_72",
    appliances_com_01_77 = "appliances_com_01_73",
    appliances_com_01_78 = "appliances_com_01_74",
    appliances_com_01_79 = "appliances_com_01_75"
}

local function getComputerSpriteName(object)
    local sprite = object and object.getSprite and object:getSprite() or nil
    return sprite and sprite.getName and sprite:getName() or nil
end

local function addComputerCandidates(objects, candidates, seen)
    if not objects or not objects.size or not objects.get then return end
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if object and not seen[object] and isComputerSpriteName(getComputerSpriteName(object)) then
            seen[object] = true
            candidates[#candidates + 1] = object
        end
    end
end

local function findClickedOrNearbyComputer(worldobjects, playerObj)
    local anchorSquare = nil
    for _, object in ipairs(worldobjects or {}) do
        if object then
            if isComputerSpriteName(getComputerSpriteName(object)) then
                return object
            end
            if not anchorSquare and object.getSquare then
                anchorSquare = object:getSquare()
            end
        end
    end
    if not anchorSquare or not getCell then return nil end
    local cell = getCell()
    if not cell then return nil end

    local candidates = {}
    local seen = {}
    local anchorX = anchorSquare:getX()
    local anchorY = anchorSquare:getY()
    local anchorZ = anchorSquare:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local square = cell:getGridSquare(anchorX + dx, anchorY + dy, anchorZ)
            if square then
                if square.getObjects then
                    addComputerCandidates(square:getObjects(), candidates, seen)
                end
                if square.getSpecialObjects then
                    addComputerCandidates(square:getSpecialObjects(), candidates, seen)
                end
            end
        end
    end

    local bestComputer = nil
    local bestScore = nil
    for i = 1, #candidates do
        local computer = candidates[i]
        if isPlayerNearComputer(playerObj, computer) then
            local clickDX = computer:getX() - anchorX
            local clickDY = computer:getY() - anchorY
            local playerDX = playerObj:getX() - computer:getX()
            local playerDY = playerObj:getY() - computer:getY()
            local score = (clickDX * clickDX + clickDY * clickDY) * 100 + playerDX * playerDX + playerDY * playerDY
            if not bestScore or score < bestScore then
                bestComputer = computer
                bestScore = score
            end
        end
    end
    return bestComputer
end

local function syncComputerWorldScreen(object, powerOn)
    if not object then return end
    local spriteName = getComputerSpriteName(object)
    if not spriteName then
        if ComputerModScreenGlow and ComputerModScreenGlow.syncObject then
            ComputerModScreenGlow.syncObject(object, powerOn)
        end
        return
    end
    local value = string.lower(tostring(spriteName))
    local nextSpriteName = nil
    if powerOn then
        nextSpriteName = computerScreenOnSprites[value]
    else
        nextSpriteName = computerScreenOffSprites[value]
    end
    if not nextSpriteName or nextSpriteName == spriteName then
        if ComputerModScreenGlow and ComputerModScreenGlow.syncObject then
            ComputerModScreenGlow.syncObject(object, powerOn)
        end
        return
    end
    local changed = false
    if object.setSpriteFromName then
        changed = pcall(function() object:setSpriteFromName(nextSpriteName) end)
    elseif object.setSprite and getSprite then
        local sprite = getSprite(nextSpriteName)
        if sprite then
            changed = pcall(function() object:setSprite(sprite) end)
        end
    end
    if changed and object.transmitUpdatedSpriteToClients then
        pcall(function() object:transmitUpdatedSpriteToClients() end)
    end
    if ComputerModScreenGlow and ComputerModScreenGlow.syncObject then
        ComputerModScreenGlow.syncObject(object, powerOn)
    end
end

function ComputerContextMenu.doMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if ComputerScreenUI.instance and ComputerScreenUI.instance:isVisible() then return end

    local clickedComputer = findClickedOrNearbyComputer(worldobjects, getSpecificPlayer(player))

    if clickedComputer then
        local data = clickedComputer.getModData and clickedComputer:getModData() or nil
        if not data or data.ComputerModNetworkTerminal ~= true then
            syncComputerWorldScreen(clickedComputer, data and data.ComputerModPowerOn == true)
        end
        local rootOption = context:addOption(data and data.ComputerModNetworkTerminal == true and cmText("ContextMenu_ComputerMod_NetworkTerminal", "Network Terminal") or cmText("ContextMenu_ComputerMod_Computer", "Computer"))
        if rootOption then
            rootOption.iconTexture = computerMenuTexture
        end
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(rootOption, subMenu)
        local isTerminal = data and data.ComputerModNetworkTerminal == true
        local terminalRepaired = isTerminal and isNetworkTerminalRepaired(data)
        if isTerminal and not terminalRepaired then
            local repairOption = subMenu:addOption(cmText("IGUI_ComputerMod_UI_Repair_Relay", "Repair Relay"), worldobjects, ComputerContextMenu.openRelayRepairUI, player, clickedComputer)
            if not isRelayRepairAvailable(getSpecificPlayer(player)) then
                repairOption.notAvailable = true
            end
        elseif data and data.ComputerModPowerOn then
            subMenu:addOption(cmText("ContextMenu_ComputerMod_ResumeSession", "Resume Session"), worldobjects, ComputerContextMenu.openComputerUI, player, clickedComputer)
        else
            subMenu:addOption(cmText("ContextMenu_ComputerMod_TurnOn", "Turn On"), worldobjects, ComputerContextMenu.openComputerUI, player, clickedComputer)
        end
        local mountedGame = getMountedDiscGame(data)
        local mountedLabel = data and data.ComputerModMountedCDLabel or nil
        local playerObj = getSpecificPlayer(player)
        if isTerminal then
            return
        elseif mountedGame then
            subMenu:addOption(cmText("ContextMenu_ComputerMod_RemoveCD", "Remove CD") .. ": " .. (mountedLabel or gameDiscLabels[mountedGame] or "CD"), worldobjects, ComputerContextMenu.removeGameCD, player, clickedComputer, mountedGame)
        else
            local discs = ComputerContextMenu.getPlayerGameDiscs(playerObj)
            for i = 1, #discs do
                local disc = discs[i]
                subMenu:addOption(cmText("ContextMenu_ComputerMod_InsertCD", "Insert CD") .. ": " .. disc.label, worldobjects, ComputerContextMenu.insertGameCD, player, clickedComputer, disc.gameId, disc.fullType, disc.label)
            end
        end
    end
end

function ComputerContextMenu.openRelayRepairUI(worldobjects, player, computer)
    local playerObj = getSpecificPlayer(player)
    if not isPlayerNearComputer(playerObj, computer) then
        ComputerModRelayRepairUI.showWarning(player, cmText("IGUI_ComputerMod_Closer", "I need to get closer."))
        return
    end
    local data = computer and computer.getModData and computer:getModData() or nil
    if not data or data.ComputerModNetworkTerminal ~= true or isNetworkTerminalRepaired(data) then return end
    if not isRelayRepairAvailable(playerObj) then return end
    if not ComputerModRelayRepair.isToolEquipped(playerObj) then
        ComputerModRelayRepairUI.showWarning(player, cmText("IGUI_ComputerMod_UI_Screwdriver", "Screwdriver") .. " " .. cmText("IGUI_ComputerMod_UI_required", "required."))
        return
    end
    if not hasComputerPower(computer) then
        ComputerModRelayRepairUI.showWarning(player, cmText("IGUI_ComputerMod_NoPower", "No power."))
        return
    end
    ComputerModRelayRepairUI.open(player, computer)
end

function ComputerContextMenu.getPlayerGameDiscs(playerObj)
    local discs = {}
    if not playerObj or not playerObj.getInventory then return discs end
    local inventory = playerObj:getInventory()
    if not inventory or not inventory.getItems then return discs end
    local items = inventory:getItems()
    local seen = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local disc = getDiscEntryFromItem(item)
        if disc then
            local key = tostring(disc.gameId) .. "::" .. tostring(disc.fullType) .. "::" .. tostring(disc.label)
            if not seen[key] then
                discs[#discs + 1] = disc
                seen[key] = true
            end
        end
    end
    return discs
end

function ComputerContextMenu.openComputerUI(worldobjects, player, computer)
    local playerObj = getSpecificPlayer(player)
    if not isPlayerNearComputer(playerObj, computer) then
        playerObj:Say(cmText("IGUI_ComputerMod_Closer", "I need to get closer."))
        return
    end
    local data = computer and computer.getModData and computer:getModData() or nil
    if data and data.ComputerModNetworkTerminal == true and not isNetworkTerminalRepaired(data) then
        if isRelayRepairAvailable(playerObj) then
            ComputerContextMenu.openRelayRepairUI(worldobjects, player, computer)
        end
        return
    end
    if not hasComputerPower(computer) then
        if playerObj and playerObj.Say then
            playerObj:Say(cmText("IGUI_ComputerMod_NoPower", "No power."))
        end
        return
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local uiW = 649
    local uiH = 560
    if ComputerScreenUI and ComputerScreenUI.getDisplayProfile then
        local profile = ComputerScreenUI.getDisplayProfile(screenW, screenH)
        uiW = profile and profile.uiW or uiW
        uiH = profile and profile.uiH or uiH
    elseif ComputerScreenUI and ComputerScreenUI.getRecommendedScale then
        local uiScale = ComputerScreenUI.getRecommendedScale(screenW, screenH)
        uiW = math.floor(649 * uiScale + 0.5)
        uiH = math.floor(560 * uiScale + 0.5)
    end
    local x = math.floor((screenW - uiW) / 2)
    local y = math.floor((screenH - uiH) / 2)
    x = math.max(0, math.min(x, math.max(0, screenW - uiW)))
    y = math.max(0, math.min(y, math.max(0, screenH - uiH)))
    local ui = ComputerScreenUI:new(x, y, player, computer)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    ui:setVisible(true)
    if ui.disableComputerSpaceShove then
        ui:disableComputerSpaceShove()
    end
end

function ComputerContextMenu.insertGameCD(worldobjects, player, computer, gameId, itemFullType, discLabel)
    local playerObj = getSpecificPlayer(player)
    if not isPlayerNearComputer(playerObj, computer) then
        playerObj:Say(cmText("IGUI_ComputerMod_Closer", "I need to get closer."))
        return
    end
    if not computer or not computer.getModData then return end
    local data = computer:getModData()
    if data and data.ComputerModNetworkTerminal == true then return end
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local targetItem = nil
    if inventory and inventory.getItems then
        local items = inventory:getItems()
        local fallbackItem = nil
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local itemType = item and item.getFullType and item:getFullType() or nil
            local targetType = itemFullType or gameDiscItems[gameId]
            if itemType and targetType and string.lower(itemType) == string.lower(targetType) then
                local itemData = item.getModData and item:getModData() or nil
                local itemLabel = itemData and itemData.ComputerModDiscLabel and tostring(itemData.ComputerModDiscLabel) or (item.getDisplayName and tostring(item:getDisplayName() or "") or "")
                fallbackItem = fallbackItem or item
                if not discLabel or discLabel == "" or itemLabel == discLabel then
                    targetItem = item
                    break
                end
            end
        end
        targetItem = targetItem or fallbackItem
    end
    if not targetItem then
        if playerObj and playerObj.Say then
            playerObj:Say(cmText("IGUI_ComputerMod_NeedDisc", "I need the disc first."))
        end
        return
    end
    data = computer:getModData()
    if data.ComputerModMountedCD then
        if playerObj and playerObj.Say then
            playerObj:Say(cmText("IGUI_ComputerMod_DiscInsertedAlready", "A disc is already inserted."))
        end
        return
    end
    if isClient and isClient() and sendClientCommand then
        local args = getComputerCommandArgs(computer)
        if not args then return end
        args.gameId = gameId
        args.label = discLabel or ""
        if targetItem and targetItem.getID then
            local ok, itemId = pcall(function() return targetItem:getID() end)
            if ok and itemId ~= nil then args.itemId = itemId end
        end
        sendClientCommand(playerObj, "ComputerModCD", "InsertDisc", args)
        return
    end
    data.ComputerModMountedCD = gameId
    data.ComputerModMountedCDItem = targetItem and targetItem.getFullType and targetItem:getFullType() or itemFullType or gameDiscItems[gameId]
    local targetData = targetItem and targetItem.getModData and targetItem:getModData() or nil
    data.ComputerModMountedCDLabel = (targetData and targetData.ComputerModDiscLabel) or (targetItem and targetItem.getDisplayName and targetItem:getDisplayName()) or discLabel or gameDiscLabels[gameId] or "CD"
    data.ComputerModMountedCDContents = {}
    if targetItem and targetItem.getModData then
        local itemData = targetItem:getModData()
        if itemData and type(itemData.ComputerModDiscContents) == "table" then
            data.ComputerModMountedCDContents = cloneDiscContents(itemData.ComputerModDiscContents)
        end
    end
    if inventory and inventory.Remove then
        inventory:Remove(targetItem)
        syncInventoryItem(inventory, targetItem, false)
        if inventory.setDrawDirty then
            pcall(function() inventory:setDrawDirty(true) end)
        end
    end
    playComputerUISound("ComputerCDEject", playerObj)
    if computer.transmitModData then
        computer:transmitModData()
    end
    if playerObj and playerObj.Say then
        playerObj:Say(cmText("IGUI_ComputerMod_CDInserted", "CD inserted."))
    end
end

function ComputerContextMenu.removeGameCD(worldobjects, player, computer, gameId)
    local playerObj = getSpecificPlayer(player)
    if not isPlayerNearComputer(playerObj, computer) then
        playerObj:Say(cmText("IGUI_ComputerMod_Closer", "I need to get closer."))
        return
    end
    if not computer or not computer.getModData then return end
    local data = computer:getModData()
    if data and data.ComputerModNetworkTerminal == true then return end
    local mountedGame = getMountedDiscGame(data)
    if not mountedGame or (mountedGame ~= gameId and data.ComputerModMountedCD ~= gameId) then
        return
    end
    if isClient and isClient() and sendClientCommand then
        local args = getComputerCommandArgs(computer)
        if not args then return end
        sendClientCommand(playerObj, "ComputerModCD", "EjectDisc", args)
        return
    end
    local inventory = playerObj and playerObj.getInventory and playerObj:getInventory() or nil
    local returnedDisc = nil
    if inventory and inventory.AddItem then
        returnedDisc = returnDiscToPlayer(playerObj, inventory, data.ComputerModMountedCDItem or gameDiscItems[mountedGame], data.ComputerModMountedCDLabel, data.ComputerModMountedCDContents)
    end
    if not returnedDisc then
        if playerObj and playerObj.Say then
            playerObj:Say(cmText("IGUI_ComputerMod_CDActionFailed", "The CD drive operation failed."))
        end
        return
    end
    data.ComputerModMountedCD = nil
    data.ComputerModMountedCDItem = nil
    data.ComputerModMountedCDLabel = nil
    data.ComputerModMountedCDContents = nil
    playComputerUISound("ComputerCDEject", playerObj)
    if computer.transmitModData then
        computer:transmitModData()
    end
    if playerObj and playerObj.Say then
        playerObj:Say(cmText("IGUI_ComputerMod_CDRemoved", "CD removed."))
    end
end

Events.OnFillWorldObjectContextMenu.Add(ComputerContextMenu.doMenu)
