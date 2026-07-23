require "UnoNoMercy/UNM_Core"
require "UnoNoMercy/UNM_Rules"
require "UnoNoMercy/UNM_Host"
require "UnoNoMercy/UNM_Window"

UNM_Client = UNM_Client or {}
UNM_Client.windows = UNM_Client.windows or {}
UNM_Client.pendingOpens = UNM_Client.pendingOpens or {}

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
    return UNM.localIdentity(getPlayerObj(playerNum), playerNum)
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

function UNM_Client.ensureWindow(playerNum, state)
    playerNum = normalizePlayerNum(playerNum)
    if UNM_Client.windows[playerNum] then
        return UNM_Client.windows[playerNum]
    end
    local sx, sy, sw, sh = screenRect(playerNum)
    local width = math.min(980, math.max(720, sw - 24))
    local height = math.min(720, math.max(520, sh - 24))
    local ui = UNM_Window:new(sx + math.max(8, (sw - width) / 2), sy + math.max(8, (sh - height) / 2), width, height, playerNum, getPlayerObj(playerNum))
    ui:initialise()
    ui:addToUIManager()
    UNM_Client.windows[playerNum] = ui
    return ui
end

local function pendingOpenKey(key, viewerName)
    return tostring(key or "") .. "\n" .. tostring(viewerName or "")
end

local function rememberPendingOpen(playerNum, anchor)
    if not anchor then
        return
    end
    UNM_Client.pendingOpens[pendingOpenKey(anchor.key, localViewerName(playerNum))] = normalizePlayerNum(playerNum)
end

local function consumePendingOpen(state)
    if not state then
        return nil
    end
    local key = pendingOpenKey(state.key, state.viewerName)
    local playerNum = UNM_Client.pendingOpens[key]
    UNM_Client.pendingOpens[key] = nil
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
    return UNM.findName(session.players or {}, viewer) or UNM.findName(session.spectators or {}, viewer)
end

local function applyLocalMoodRelief(playerName, boredom, stress, unhappiness)
    for playerNum = 0, 3 do
        local playerObj = getPlayerObj(playerNum)
        if playerObj and localViewerName(playerNum) == tostring(playerName) then
            UNM.reduceCharacterStat(playerObj, "BOREDOM", boredom)
            UNM.reduceCharacterStat(playerObj, "STRESS", stress)
            UNM.reduceCharacterStat(playerObj, "UNHAPPINESS", unhappiness)
            return
        end
    end
end

UNM_Client.localHost = UNM_Client.localHost or UNM_Host.new({
    playerName = function(playerObj, args)
        return UNM.localIdentity(playerObj, args and args.playerNum)
    end,
    localBroadcast = function(session)
        for playerNum, window in pairs(UNM_Client.windows or {}) do
            if windowWantsSession(window, session) then
                local viewer = localViewerName(playerNum)
                UNM_Client.pendingOpens[pendingOpenKey(session.key, viewer)] = nil
                window:setState(UNM.redactedState(session, viewer))
            end
        end
        for key, playerNum in pairs(UNM_Client.pendingOpens or {}) do
            local viewer = localViewerName(playerNum)
            if pendingOpenKey(session.key, viewer) == key and (UNM.findName(session.players or {}, viewer) or UNM.findName(session.spectators or {}, viewer)) then
                UNM_Client.pendingOpens[key] = nil
                local ui = UNM_Client.ensureWindow(playerNum, session)
                ui:setState(UNM.redactedState(session, viewer))
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

function UNM_Client.sendCommand(playerNum, command, anchor, args)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if not playerObj or not anchor then
        return
    end
    args = fillArgs(args or {}, anchor, playerNum)
    if isMultiplayerClient() then
        UNM.sendClientCommand(playerObj, UNM.MODULE, command, args)
    else
        UNM_Client.localHost:handleCommand(playerObj, command, args)
    end
end

function UNM_Client.start(playerNum, anchor)
    rememberPendingOpen(playerNum, anchor)
    local pending = {
        key = anchor.key,
        anchor = UNM.copy(anchor),
        phase = "opening",
        players = { localViewerName(playerNum) },
        publicState = { title = "UNO No Mercy", events = {} },
        privateState = { hand = {} },
        legalActions = {},
        viewerName = localViewerName(playerNum),
    }
    local ui = UNM_Client.ensureWindow(playerNum, pending)
    ui:setState(pending)
    UNM_Client.sendCommand(playerNum, UNM.CMD_START, anchor, {})
end

function UNM_Client.watch(playerNum, anchor)
    rememberPendingOpen(playerNum, anchor)
    local pending = {
        key = anchor.key,
        anchor = UNM.copy(anchor),
        phase = "opening",
        players = {},
        publicState = { title = "UNO No Mercy", events = {} },
        privateState = { hand = {} },
        legalActions = {},
        viewerName = localViewerName(playerNum),
    }
    local ui = UNM_Client.ensureWindow(playerNum, pending)
    ui:setState(pending)
    UNM_Client.sendCommand(playerNum, UNM.CMD_WATCH, anchor, {})
end

function UNM_Client.leave(playerNum, state)
    if state and state.anchor then
        UNM_Client.sendCommand(playerNum, UNM.CMD_LEAVE, state.anchor, {})
    end
end

function UNM_Client.reset(playerNum, state)
    if state and state.anchor then
        UNM_Client.sendCommand(playerNum, UNM.CMD_RESET, state.anchor, {})
    end
end

function UNM_Client.action(playerNum, state, action, args)
    if state and state.anchor then
        args = args or {}
        args.action = action
        UNM_Client.sendCommand(playerNum, UNM.CMD_ACTION, state.anchor, args)
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
    return fullType == "Base.NoMercyDeck" or fullType == "NoMercyDeck"
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
    local anchor = UNM.anchorFromObject(deckObject)
    if not anchor then
        return
    end
    if not UNM.playerNearAnchor(playerObj, anchor, UNM.MAX_PLAY_DISTANCE) then
        local option = context:addOption(UNM.text("IGUI_UNM_Play", "Play UNO No Mercy"))
        option.notAvailable = true
        return
    end
    context:addOption(UNM.text("IGUI_UNM_Play", "Play UNO No Mercy"), playerNum, UNM_Client.start, anchor)
    context:addOption(UNM.text("IGUI_UNM_Watch", "Watch UNO No Mercy"), playerNum, UNM_Client.watch, anchor)
end

local function playerNumForViewer(viewerName)
    viewerName = tostring(viewerName or "")
    for playerNum = 0, 3 do
        if localViewerName(playerNum) == viewerName or UNM.username(getPlayerObj(playerNum)) == viewerName then
            return playerNum
        end
    end
    return 0
end

local function onServerCommand(module, command, args)
    if module ~= UNM.MODULE then
        return
    end
    args = args or {}
    if command == UNM.CMD_STATE then
        local state = args.state
        local playerNum = playerNumForViewer(state and state.viewerName)
        local ui = UNM_Client.windows[playerNum]
        local pendingPlayerNum = consumePendingOpen(state)
        if not ui then
            if pendingPlayerNum ~= nil then
                playerNum = pendingPlayerNum
                ui = UNM_Client.ensureWindow(playerNum, state)
            end
        end
        if ui then
            ui:setState(state)
        end
    elseif command == UNM.CMD_MESSAGE then
        sayLocal(getPlayerObj(playerNumForViewer(args.viewerName)), args.text)
    end
end

function UNM_Client.onTick()
    if not isMultiplayerClient() and UNM_Client.localHost then
        UNM_Client.localHost:onTick()
    end
    for playerNum, window in pairs(UNM_Client.windows or {}) do
        if window and window.state and window.state.anchor then
            local playerObj = getPlayerObj(playerNum)
            if not playerObj or not UNM.playerNearAnchor(playerObj, window.state.anchor, UNM.MAX_PLAY_DISTANCE) then
                sayLocal(playerObj, "Closed UNO No Mercy: too far away.")
                window:close()
                UNM_Client.windows[playerNum] = nil
            end
        end
    end
end

function UNM_Client.everyOneMinute()
    if not isMultiplayerClient() and UNM_Client.localHost then
        UNM_Client.localHost:relieveActivePlayers()
    end
end

local function stopClientMusic()
    if UNM_Music and UNM_Music.forceStop then
        UNM_Music.forceStop()
    end
end

Events.OnFillWorldObjectContextMenu.Add(onContextMenu)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(UNM_Client.onTick)
Events.EveryOneMinute.Add(UNM_Client.everyOneMinute)
Events.OnDisconnect.Add(stopClientMusic)
Events.OnMainMenuEnter.Add(stopClientMusic)
