require "PlayableSurvivalCards/PSC_Core"
require "PlayableSurvivalCards/PSC_Rules"
require "PlayableSurvivalCards/PSC_Host"
require "PlayableSurvivalCards/PSC_Window"

PSC_Client = PSC_Client or {}
PSC_Client.windows = PSC_Client.windows or {}
PSC_Client.pendingOpens = PSC_Client.pendingOpens or {}

local function isMultiplayerClient()
    return isClient and isClient()
end

local function normalizePlayerNum(playerNum)
    playerNum = tonumber(playerNum) or 0
    if playerNum < 0 then
        return 0
    end
    return math.floor(playerNum)
end

local function getPlayerObj(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    if getSpecificPlayer then
        local playerObj = getSpecificPlayer(playerNum)
        if playerObj then
            return playerObj
        end
    end
    return getPlayer and getPlayer() or nil
end

local function sayLocal(playerObj, text)
    if HaloTextHelper and playerObj then
        local ok = pcall(function()
            HaloTextHelper.addText(playerObj, tostring(text or ""), "[br/]", HaloTextHelper.getColorWhite())
        end)
        if ok then
            return
        end
    end
    if playerObj and playerObj.Say then
        playerObj:Say(tostring(text or ""))
    end
end

local function localViewerName(playerNum)
    return PSC.localIdentity(getPlayerObj(playerNum), playerNum)
end

local function screenRect(playerNum)
    local core = getCore()
    local x = 0
    local y = 0
    local w = core:getScreenWidth()
    local h = core:getScreenHeight()
    if getPlayerScreenLeft then
        local ok, value = pcall(function()
            return getPlayerScreenLeft(playerNum)
        end)
        if ok and value then x = value end
    end
    if getPlayerScreenTop then
        local ok, value = pcall(function()
            return getPlayerScreenTop(playerNum)
        end)
        if ok and value then y = value end
    end
    if getPlayerScreenWidth then
        local ok, value = pcall(function()
            return getPlayerScreenWidth(playerNum)
        end)
        if ok and value and value > 0 then w = value end
    end
    if getPlayerScreenHeight then
        local ok, value = pcall(function()
            return getPlayerScreenHeight(playerNum)
        end)
        if ok and value and value > 0 then h = value end
    end
    return x, y, w, h
end

function PSC_Client.ensureWindow(playerNum, state)
    playerNum = normalizePlayerNum(playerNum)
    if PSC_Client.windows[playerNum] then
        return PSC_Client.windows[playerNum]
    end
    local sx, sy, sw, sh = screenRect(playerNum)
    local width = math.min(980, math.max(720, sw - 24))
    local height = math.min(720, math.max(520, sh - 24))
    local ui = PSC_Window:new(sx + math.max(8, (sw - width) / 2), sy + math.max(8, (sh - height) / 2), width, height, playerNum, getPlayerObj(playerNum))
    ui:initialise()
    ui:addToUIManager()
    PSC_Client.windows[playerNum] = ui
    return ui
end

local function pendingOpenKey(key, viewerName)
    return tostring(key or "") .. "\n" .. tostring(viewerName or "")
end

local function rememberPendingOpen(playerNum, anchor)
    if not anchor then
        return
    end
    PSC_Client.pendingOpens[pendingOpenKey(anchor.key, localViewerName(playerNum))] = normalizePlayerNum(playerNum)
end

local function consumePendingOpen(state)
    if not state then
        return nil
    end
    local key = pendingOpenKey(state.key, state.viewerName)
    local playerNum = PSC_Client.pendingOpens[key]
    PSC_Client.pendingOpens[key] = nil
    return playerNum
end

local function windowWantsSession(window, session)
    if not window or not session then
        return false
    end
    if window.state and window.state.key == session.key then
        return true
    end
    local viewer = localViewerName(window.playerNum)
    return PSC.findName(session.players or {}, viewer) or PSC.findName(session.spectators or {}, viewer)
end

local function applyLocalMoodRelief(playerName, boredom, stress, unhappiness)
    for playerNum = 0, 3 do
        local playerObj = getPlayerObj(playerNum)
        if playerObj and localViewerName(playerNum) == tostring(playerName) then
            PSC.reduceCharacterStat(playerObj, "BOREDOM", boredom)
            PSC.reduceCharacterStat(playerObj, "STRESS", stress)
            PSC.reduceCharacterStat(playerObj, "UNHAPPINESS", unhappiness)
            return
        end
    end
end

PSC_Client.localHost = PSC_Client.localHost or PSC_Host.new({
    playerName = function(playerObj, args)
        return PSC.localIdentity(playerObj, args and args.playerNum)
    end,
    localBroadcast = function(session)
        for playerNum, window in pairs(PSC_Client.windows or {}) do
            if windowWantsSession(window, session) then
                local viewer = localViewerName(playerNum)
                PSC_Client.pendingOpens[pendingOpenKey(session.key, viewer)] = nil
                window:setState(PSC.redactedState(session, viewer))
            end
        end
        for key, playerNum in pairs(PSC_Client.pendingOpens or {}) do
            local viewer = localViewerName(playerNum)
            if pendingOpenKey(session.key, viewer) == key and (PSC.findName(session.players or {}, viewer) or PSC.findName(session.spectators or {}, viewer)) then
                PSC_Client.pendingOpens[key] = nil
                local ui = PSC_Client.ensureWindow(playerNum, session)
                ui:setState(PSC.redactedState(session, viewer))
            end
        end
    end,
    message = function(playerObj, text)
        sayLocal(playerObj, text)
    end,
    applyMoodRelief = applyLocalMoodRelief,
})

local function fillArgs(args, anchor, playerNum)
    args = args or {}
    args.x = anchor.x
    args.y = anchor.y
    args.z = anchor.z
    args.key = anchor.key
    args.source = anchor.source
    args.playerNum = playerNum
    return args
end

function PSC_Client.sendCommand(playerNum, command, anchor, args)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if not playerObj or not anchor then
        return
    end
    args = fillArgs(args or {}, anchor, playerNum)
    if isMultiplayerClient() then
        PSC.sendClientCommand(playerObj, PSC.MODULE, command, args)
    else
        PSC_Client.localHost:handleCommand(playerObj, command, args)
    end
end

function PSC_Client.start(playerNum, anchor)
    rememberPendingOpen(playerNum, anchor)
    local pending = {
        key = anchor.key,
        anchor = PSC.copy(anchor),
        phase = "opening",
        players = { localViewerName(playerNum) },
        publicState = { title = "UNO", events = {} },
        privateState = { hand = {} },
        legalActions = {},
        viewerName = localViewerName(playerNum),
    }
    local ui = PSC_Client.ensureWindow(playerNum, pending)
    ui:setState(pending)
    PSC_Client.sendCommand(playerNum, PSC.CMD_START, anchor, {})
end

function PSC_Client.watch(playerNum, anchor)
    rememberPendingOpen(playerNum, anchor)
    local pending = {
        key = anchor.key,
        anchor = PSC.copy(anchor),
        phase = "opening",
        players = {},
        publicState = { title = "UNO", events = {} },
        privateState = { hand = {} },
        legalActions = {},
        viewerName = localViewerName(playerNum),
    }
    local ui = PSC_Client.ensureWindow(playerNum, pending)
    ui:setState(pending)
    PSC_Client.sendCommand(playerNum, PSC.CMD_WATCH, anchor, {})
end

function PSC_Client.leave(playerNum, state)
    if state and state.anchor then
        PSC_Client.sendCommand(playerNum, PSC.CMD_LEAVE, state.anchor, {})
    end
end

function PSC_Client.reset(playerNum, state)
    if state and state.anchor then
        PSC_Client.sendCommand(playerNum, PSC.CMD_RESET, state.anchor, {})
    end
end

function PSC_Client.action(playerNum, state, action, args)
    if state and state.anchor then
        args = args or {}
        args.action = action
        PSC_Client.sendCommand(playerNum, PSC.CMD_ACTION, state.anchor, args)
    end
end

local function worldItemFullType(isoObject)
    if not isoObject or not isoObject.getItem then
        return nil
    end
    local ok, item = pcall(function()
        return isoObject:getItem()
    end)
    if not ok or not item then
        return nil
    end
    if item.getFullType then
        return tostring(item:getFullType())
    end
    if item.getType then
        return tostring(item:getType())
    end
    return nil
end

local function isUnoDeckObject(isoObject)
    local fullType = worldItemFullType(isoObject)
    return fullType == "Base.SurvivalColorDeck" or fullType == "SurvivalColorDeck"
end

local function findUnoDeck(worldobjects)
    if not worldobjects then
        return nil
    end
    local function scanList(list)
        if not list then
            return nil
        end
        for i = 0, list:size() - 1 do
            local object = list:get(i)
            if isUnoDeckObject(object) then
                return object
            end
        end
        return nil
    end
    for i = 1, #worldobjects do
        local object = worldobjects[i]
        if isUnoDeckObject(object) then
            return object
        end
        if object and object.getSquare then
            local square = object:getSquare()
            if square then
                local found = scanList(square:getWorldObjects())
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

local function onContextMenu(playerNum, context, worldobjects, test)
    if test then
        return
    end
    local playerObj = getPlayerObj(playerNum)
    local deckObject = findUnoDeck(worldobjects)
    if not deckObject then
        return
    end
    local anchor = PSC.anchorFromObject(deckObject)
    if not anchor then
        return
    end
    if not PSC.playerNearAnchor(playerObj, anchor, PSC.MAX_PLAY_DISTANCE) then
        local option = context:addOption(PSC.text("IGUI_PSC_Play", "Play UNO"))
        option.notAvailable = true
        return
    end
    context:addOption(PSC.text("IGUI_PSC_Play", "Play UNO"), playerNum, PSC_Client.start, anchor)
    context:addOption(PSC.text("IGUI_PSC_Watch", "Watch UNO"), playerNum, PSC_Client.watch, anchor)
end

local function playerNumForViewer(viewerName)
    viewerName = tostring(viewerName or "")
    for playerNum = 0, 3 do
        if localViewerName(playerNum) == viewerName or PSC.username(getPlayerObj(playerNum)) == viewerName then
            return playerNum
        end
    end
    return 0
end

local function onServerCommand(module, command, args)
    if module ~= PSC.MODULE then
        return
    end
    args = args or {}
    if command == PSC.CMD_STATE then
        local state = args.state
        local playerNum = playerNumForViewer(state and state.viewerName)
        local ui = PSC_Client.windows[playerNum]
        local pendingPlayerNum = consumePendingOpen(state)
        if not ui then
            if pendingPlayerNum ~= nil then
                playerNum = pendingPlayerNum
                ui = PSC_Client.ensureWindow(playerNum, state)
            end
        end
        if ui then
            ui:setState(state)
        end
    elseif command == PSC.CMD_MESSAGE then
        sayLocal(getPlayerObj(playerNumForViewer(args.viewerName)), args.text)
    end
end

function PSC_Client.onTick()
    if not isMultiplayerClient() and PSC_Client.localHost then
        PSC_Client.localHost:onTick()
    end
    for playerNum, window in pairs(PSC_Client.windows or {}) do
        if window and window.state and window.state.anchor then
            local playerObj = getPlayerObj(playerNum)
            if not playerObj or not PSC.playerNearAnchor(playerObj, window.state.anchor, PSC.MAX_PLAY_DISTANCE) then
                sayLocal(playerObj, "Closed UNO: too far away.")
                window:close()
                PSC_Client.windows[playerNum] = nil
            end
        end
    end
end

function PSC_Client.everyOneMinute()
    if not isMultiplayerClient() and PSC_Client.localHost then
        PSC_Client.localHost:relieveActivePlayers()
    end
end

local function stopResultMusic()
    if PSC_ResultMusic and PSC_ResultMusic.stop then
        PSC_ResultMusic.stop()
    end
end

Events.OnFillWorldObjectContextMenu.Add(onContextMenu)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(PSC_Client.onTick)
Events.EveryOneMinute.Add(PSC_Client.everyOneMinute)
Events.OnDisconnect.Add(stopResultMusic)
Events.OnMainMenuEnter.Add(stopResultMusic)
