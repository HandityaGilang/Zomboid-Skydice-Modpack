require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Skills"
require "PlayableMinigames/PMG_Games"
require "PlayableMinigames/PMG_SessionHost"
require "PlayableMinigames/PMG_Window"

PMGClient = PMGClient or {}
PMGClient.windows = PMGClient.windows or {}
PMGClient.tickCounter = PMGClient.tickCounter or 0

local function isMultiplayerClient()
    return isClient and isClient()
end

local function normalizePlayerNum(playerNum)
    playerNum = tonumber(playerNum)
    if not playerNum or playerNum < 0 then
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
            HaloTextHelper.addText(playerObj, text, "[br/]", HaloTextHelper.getColorWhite())
        end)
        if ok then
            return
        end
    end
    if playerObj and playerObj.Say then
        playerObj:Say(text)
    end
end

local function clientText(key, fallback)
    if getText then
        local ok, value = pcall(function()
            return getText(key)
        end)
        if ok and value and value ~= key then
            return value
        end
    end
    return tostring(fallback or key)
end

local function getPlayerScreenRect(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    local core = getCore()
    local x = 0
    local y = 0
    local w = core:getScreenWidth()
    local h = core:getScreenHeight()
    if getPlayerScreenLeft then
        local ok, value = pcall(function()
            return getPlayerScreenLeft(playerNum)
        end)
        if ok and value then
            x = value
        end
    end
    if getPlayerScreenTop then
        local ok, value = pcall(function()
            return getPlayerScreenTop(playerNum)
        end)
        if ok and value then
            y = value
        end
    end
    if getPlayerScreenWidth then
        local ok, value = pcall(function()
            return getPlayerScreenWidth(playerNum)
        end)
        if ok and value and value > 0 then
            w = value
        end
    end
    if getPlayerScreenHeight then
        local ok, value = pcall(function()
            return getPlayerScreenHeight(playerNum)
        end)
        if ok and value and value > 0 then
            h = value
        end
    end
    return x, y, w, h
end

function PMGClient.ensureWindow(playerNum, state)
    playerNum = normalizePlayerNum(playerNum)
    local existing = PMGClient.windows[playerNum]
    if existing then
        existing.playerNum = playerNum
        existing.playerObj = getPlayerObj(playerNum)
        if getJoypadData and setJoypadFocus and getJoypadData(playerNum) then
            setJoypadFocus(playerNum, existing)
        end
        return existing
    end
    local screenX, screenY, screenW, screenH = getPlayerScreenRect(playerNum)
    local width = math.min(980, math.max(720, screenW - 24))
    local height = math.min(720, math.max(520, screenH - 24))
    local x = screenX + math.max(8, (screenW - width) / 2)
    local y = screenY + math.max(8, (screenH - height) / 2)
    local ui = PMGWindow:new(x, y, width, height, playerNum, getPlayerObj(playerNum))
    ui:initialise()
    ui:addToUIManager()
    PMGClient.windows[playerNum] = ui
    if getJoypadData and setJoypadFocus and getJoypadData(playerNum) then
        setJoypadFocus(playerNum, ui)
    end
    return ui
end

local function localViewerName(playerNum)
    return PMG.localPlayerIdentity(getPlayerObj(playerNum), playerNum)
end

local function windowWantsSession(window, session)
    if not window or not session then
        return false
    end
    local state = window.state
    if state and state.key and state.key == session.key then
        return true
    end
    local viewerName = localViewerName(window.playerNum)
    return PMG.findNameIndex(session.players or {}, viewerName) or PMG.findNameIndex(session.spectators or {}, viewerName)
end

local function localBroadcastState(game, session)
    local sent = false
    for playerNum, window in pairs(PMGClient.windows or {}) do
        if windowWantsSession(window, session) then
            local viewerName = localViewerName(playerNum)
            window:setState(PMG.redactedState(game, session, viewerName))
            sent = true
        end
    end
    if not sent and session and session.players and session.players[1] then
        local ui = PMGClient.ensureWindow(0, session)
        ui:setState(PMG.redactedState(game, session, session.players[1]))
    end
end

PMGClient.localHost = PMGClient.localHost or PMG_SessionHost.new({
    authenticatedPlayerName = function(playerObj, args)
        return PMG.localPlayerIdentity(playerObj, args and args.playerNum)
    end,
    localBroadcastState = localBroadcastState,
    validateWorldAnchor = function(gameId, anchor)
        return PMG_Anchors.validateAnchorForGame(gameId, anchor)
    end,
    message = function(playerObj, text)
        sayLocal(playerObj, text)
    end,
    rewardPlayer = function(playerObj, skillId, amount, reward)
        return PMG_Skills.rewardPlayer(playerObj, skillId, amount, reward)
    end,
})

local function fillAnchorArgs(args, gameId, anchor, playerNum)
    args = args or {}
    args.gameId = gameId
    args.x = anchor.x
    args.y = anchor.y
    args.z = anchor.z
    args.key = PMG.keyForAnchor(gameId, anchor.x, anchor.y, anchor.z)
    args.playerNum = playerNum
    args.source = anchor.source
    return args
end

local function sendMinigameCommand(playerNum, command, gameId, anchor, args)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if not playerObj or not anchor or not gameId then
        return
    end
    args = fillAnchorArgs(args, gameId, anchor, playerNum)
    if not isMultiplayerClient() then
        PMGClient.localHost:handleCommand(playerObj, command, args)
        return
    end
    PMG.sendClientCommand(playerObj, PMG.MODULE, command, args)
end

function PMGClient.start(playerNum, gameId, anchor, args)
    local pending = {
        key = PMG.keyForAnchor(gameId, anchor.x, anchor.y, anchor.z),
        gameId = gameId,
        phase = "opening",
        anchor = PMG.copyTable(anchor),
        players = { localViewerName(playerNum) },
        spectators = {},
        events = {},
        publicState = {
            gameId = gameId,
            gameName = (PMG_Registry.get(gameId) and PMG_Registry.get(gameId).name) or "Playable Minigame",
        },
        privateState = {},
    }
    local ui = PMGClient.ensureWindow(playerNum, pending)
    ui:setState(pending)
    sendMinigameCommand(playerNum, PMG.CMD_START, gameId, anchor, args or {})
end

function PMGClient.join(playerNum, gameId, anchor)
    sendMinigameCommand(playerNum, PMG.CMD_JOIN, gameId, anchor, {})
end

function PMGClient.watch(playerNum, gameId, anchor)
    sendMinigameCommand(playerNum, PMG.CMD_WATCH, gameId, anchor, {})
end

function PMGClient.leave(playerNum, state)
    if state and state.anchor then
        sendMinigameCommand(playerNum, PMG.CMD_LEAVE, state.gameId, state.anchor, {})
    end
end

function PMGClient.reset(playerNum, state)
    if state and state.anchor then
        sendMinigameCommand(playerNum, PMG.CMD_RESET, state.gameId, state.anchor, {})
    end
end

function PMGClient.action(playerNum, state, action, args)
    if state and state.anchor then
        args = args or {}
        args.action = action
        sendMinigameCommand(playerNum, PMG.CMD_ACTION, state.gameId, state.anchor, args)
    end
end

local function onStartGame(playerNum, gameId, anchor, options)
    PMGClient.start(playerNum, gameId, anchor, options or {})
end

local function onWatchGame(playerNum, gameId, anchor)
    PMGClient.watch(playerNum, gameId, anchor)
end

local CONTEXT_ICON_PATHS = {
    darts_501 = "media/textures/PlayableMinigames/game_darts.png",
    blackjack = "media/textures/PlayableMinigames/card_back.png",
    holdem = "media/textures/PlayableMinigames/card_back.png",
    solitaire = "media/textures/PlayableMinigames/card_back.png",
    cards = "media/textures/PlayableMinigames/card_back.png",
    checkers = "media/textures/PlayableMinigames/game_checkers.png",
    chess = "media/textures/PlayableMinigames/game_chess.png",
    board = "media/textures/PlayableMinigames/game_checkers.png",
}
local CONTEXT_ICON_TEXTURES = {}

local function contextIconTexture(iconId)
    local path = CONTEXT_ICON_PATHS[iconId] or iconId
    if not path or not getTexture then
        return nil
    end
    if CONTEXT_ICON_TEXTURES[path] == nil then
        CONTEXT_ICON_TEXTURES[path] = getTexture(path) or false
    end
    return CONTEXT_ICON_TEXTURES[path] or nil
end

local function setOptionIcon(option, iconId)
    if option then
        option.iconTexture = contextIconTexture(iconId)
    end
    return option
end

local function setOptionTooltip(option, description)
    if option and description and ISWorldObjectContextMenu and ISWorldObjectContextMenu.addToolTip then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = tostring(description)
        option.toolTip = toolTip
    end
    return option
end

local function addContextOption(context, label, iconId, ...)
    return setOptionIcon(context:addOption(label, ...), iconId)
end

local function addBetaContextOption(context, label, iconId, ...)
    return setOptionTooltip(addContextOption(context, label, iconId, ...), PMG.BETA_MINIGAME_WARNING)
end

local function addUnavailableOption(context, label, reason, iconId)
    local option = context:addOption(label)
    setOptionIcon(option, iconId)
    option.notAvailable = true
    setOptionTooltip(option, reason or "Unavailable.")
    return option
end

local function betaMinigamesEnabled()
    return PMG.betaMinigamesEnabled and PMG.betaMinigamesEnabled()
end

local function anchorForGame(baseAnchor, gameId)
    if not baseAnchor then
        return nil
    end
    local anchor = PMG.copyTable(baseAnchor)
    anchor.gameId = gameId
    anchor.key = PMG.keyForAnchor(gameId, anchor.x, anchor.y, anchor.z)
    return anchor
end

local function isActiveKnownSession(state, gameId, key)
    if not state or state.gameId ~= gameId or state.key ~= key then
        return false
    end
    return state.phase ~= PMG.PHASE_GAME_OVER
end

local function hasKnownSession(gameId, baseAnchor)
    local anchor = anchorForGame(baseAnchor, gameId)
    if not anchor then
        return false
    end
    local session = PMGClient.localHost and PMGClient.localHost.sessions and PMGClient.localHost.sessions[anchor.key] or nil
    if isActiveKnownSession(session, gameId, anchor.key) then
        return true
    end
    for _, window in pairs(PMGClient.windows or {}) do
        if window and isActiveKnownSession(window.state, gameId, anchor.key) then
            return true
        end
    end
    return false
end

local function addCardGameOptions(playerNum, context, baseAnchor)
    addBetaContextOption(context, "Play Blackjack (Beta)", "blackjack", playerNum, onStartGame, "blackjack", anchorForGame(baseAnchor, "blackjack"), { bet = 10 })
    addBetaContextOption(context, "Play Texas Hold'em (Beta)", "holdem", playerNum, onStartGame, "holdem", anchorForGame(baseAnchor, "holdem"), {})
    addBetaContextOption(context, "Play Solitaire (Beta)", "solitaire", playerNum, onStartGame, "solitaire", anchorForGame(baseAnchor, "solitaire"), { drawCount = 1 })
end

local function addKnownCardWatchOptions(playerNum, context, baseAnchor)
    if hasKnownSession("blackjack", baseAnchor) then
        addBetaContextOption(context, "Watch Blackjack (Beta)", "blackjack", playerNum, onWatchGame, "blackjack", anchorForGame(baseAnchor, "blackjack"))
    end
    if hasKnownSession("holdem", baseAnchor) then
        addBetaContextOption(context, "Watch Texas Hold'em (Beta)", "holdem", playerNum, onWatchGame, "holdem", anchorForGame(baseAnchor, "holdem"))
    end
    if hasKnownSession("solitaire", baseAnchor) then
        addBetaContextOption(context, "Watch Solitaire (Beta)", "solitaire", playerNum, onWatchGame, "solitaire", anchorForGame(baseAnchor, "solitaire"))
    end
end

local function addKnownBoardWatchOptions(playerNum, context, baseAnchor)
    if hasKnownSession("checkers", baseAnchor) then
        addBetaContextOption(context, "Watch Checkers (Beta)", "checkers", playerNum, onWatchGame, "checkers", anchorForGame(baseAnchor, "checkers"))
    end
    if hasKnownSession("chess", baseAnchor) then
        addBetaContextOption(context, "Watch Chess (Beta)", "chess", playerNum, onWatchGame, "chess", anchorForGame(baseAnchor, "chess"))
    end
end

local function addContextMenu(playerNum, context, worldobjects, test)
    if test then
        return
    end
    if not betaMinigamesEnabled() then
        return
    end
    local playerObj = getSpecificPlayer(playerNum)
    local dartboard = PMG_Anchors.findDartboardFromWorldObjects(worldobjects)
    if dartboard then
        local anchor = PMG_Anchors.anchorFromObject("darts_501", dartboard)
        local hasDarts = PMG_Anchors.hasDartsForAnchor(playerObj, anchor)
        if anchor then
            if not PMG.playerNearAnchor(playerObj, anchor, PMG.MAX_PLAY_DISTANCE) then
                addUnavailableOption(context, "Play Darts 501 (Beta)", "Move closer to the dartboard.", "darts_501")
            elseif not hasDarts then
                addUnavailableOption(context, "Play Darts 501 (Beta)", "Place three darts by the dartboard.", "darts_501")
                if hasKnownSession("darts_501", anchor) then
                    addBetaContextOption(context, "Watch Darts 501 (Beta)", "darts_501", playerNum, onWatchGame, "darts_501", anchor)
                end
            else
                addBetaContextOption(context, "Play Darts 501 (Beta)", "darts_501", playerNum, onStartGame, "darts_501", anchor, {})
            end
        end
    end
    local surface = PMG_Anchors.findCardSurfaceFromWorldObjects(worldobjects)
    local worldDeck = PMG_Anchors.findCardDeckFromWorldObjects(worldobjects)
    local cardAnchorObject = worldDeck or surface
    if cardAnchorObject then
        local anchor = PMG_Anchors.anchorFromObject("blackjack", cardAnchorObject)
        local hasDeck = PMG_Anchors.hasCardDeckForAnchor(playerObj, anchor)
        if anchor and hasDeck and PMG.playerNearAnchor(playerObj, anchor, PMG.MAX_PLAY_DISTANCE) then
            addCardGameOptions(playerNum, context, anchor)
        elseif anchor and not PMG.playerNearAnchor(playerObj, anchor, PMG.MAX_PLAY_DISTANCE) then
            addUnavailableOption(context, "Play Cards (Beta)", "Move closer to the card table or deck.", "cards")
        elseif anchor then
            addKnownCardWatchOptions(playerNum, context, anchor)
        end
    end

    local boardObject = PMG_Anchors.findCheckerBoardFromWorldObjects(worldobjects) or PMG_Anchors.findChessPiecesFromWorldObjects(worldobjects)
    if boardObject then
        local anchor = PMG_Anchors.anchorFromObject("checkers", boardObject)
        local hasBoard = PMG_Anchors.hasCheckerBoardForAnchor(playerObj, anchor)
        local hasChessSet = PMG_Anchors.hasChessSetForAnchor(playerObj, anchor)
        if anchor and PMG.playerNearAnchor(playerObj, anchor, PMG.MAX_PLAY_DISTANCE) and (hasBoard or hasChessSet) then
            if hasBoard then
                addBetaContextOption(context, "Play Checkers (Beta)", "checkers", playerNum, onStartGame, "checkers", anchorForGame(anchor, "checkers"), {})
            else
                addUnavailableOption(context, "Play Checkers (Beta)", "Place a checkerboard here.", "checkers")
            end
            if hasChessSet then
                addBetaContextOption(context, "Play Chess (Beta)", "chess", playerNum, onStartGame, "chess", anchorForGame(anchor, "chess"), {})
            else
                addUnavailableOption(context, "Play Chess (Beta)", "You need a checkerboard plus white and black chess pieces.", "chess")
            end
            addKnownBoardWatchOptions(playerNum, context, anchor)
        elseif anchor and not PMG.playerNearAnchor(playerObj, anchor, PMG.MAX_PLAY_DISTANCE) then
            addUnavailableOption(context, "Play Board Games (Beta)", "Move closer to the board or pieces.", "board")
        elseif anchor then
            addUnavailableOption(context, "Play Board Games (Beta)", "Place the relevant board-game items together here.", "board")
            addKnownBoardWatchOptions(playerNum, context, anchor)
        end
    end
end

function PMGClient.resolvePlayerNumForViewer(viewerName)
    viewerName = viewerName and tostring(viewerName) or nil
    if viewerName and viewerName ~= "" then
        for playerNum = 0, 3 do
            local playerObj = getPlayerObj(playerNum)
            if playerObj then
                if PMG.getUsername(playerObj) == viewerName or localViewerName(playerNum) == viewerName then
                    return playerNum
                end
            end
        end
        for playerNum, window in pairs(PMGClient.windows or {}) do
            if window and window.state and window.state.viewerName == viewerName then
                return normalizePlayerNum(playerNum)
            end
        end
    end
    return 0
end

function PMGClient.resolvePlayerNumForState(state)
    if state and state.viewerName then
        return PMGClient.resolvePlayerNumForViewer(state.viewerName)
    end
    if state and state.key then
        for playerNum, window in pairs(PMGClient.windows or {}) do
            if window and window.state and window.state.key == state.key then
                return normalizePlayerNum(playerNum)
            end
        end
    end
    return 0
end

local function onServerCommand(module, command, args)
    if module ~= PMG.MODULE then
        return
    end
    args = args or {}
    if command == PMG.CMD_STATE then
        local playerNum = PMGClient.resolvePlayerNumForState(args.state)
        local ui = PMGClient.ensureWindow(playerNum, args.state)
        ui:setState(args.state)
        return
    end
    if command == PMG.CMD_MESSAGE then
        local playerNum = PMGClient.resolvePlayerNumForViewer(args.viewerName)
        sayLocal(getPlayerObj(playerNum), tostring(args.text or "Minigame is not available."))
    end
end

function PMGClient.onTick()
    PMGClient.tickCounter = (PMGClient.tickCounter or 0) + 1
    if not isMultiplayerClient() and PMGClient.localHost then
        PMGClient.localHost:onTick()
    end
    if PMGClient.tickCounter % 30 ~= 0 then
        return
    end
    for windowPlayerNum, window in pairs(PMGClient.windows or {}) do
        if window and window.state and window.state.anchor then
            local playerObj = getPlayerObj(window.playerNum)
            if not playerObj or not PMG.playerNearAnchor(playerObj, window.state.anchor, PMG.MAX_PLAY_DISTANCE) then
                sayLocal(playerObj, clientText("IGUI_PlayableMinigames_ClosedTooFar", "Closed minigame: too far away."))
                window:close()
                PMGClient.windows[windowPlayerNum] = nil
            end
        end
    end
end

function PMGClient.onKeyPressed(key)
    local window = PMGClient.windows[0]
    if window and window.handleKeyPressed and window:handleKeyPressed(key) then
        return true
    end
    return false
end

Events.OnFillWorldObjectContextMenu.Add(addContextMenu)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(PMGClient.onTick)
Events.OnKeyPressed.Add(PMGClient.onKeyPressed)
