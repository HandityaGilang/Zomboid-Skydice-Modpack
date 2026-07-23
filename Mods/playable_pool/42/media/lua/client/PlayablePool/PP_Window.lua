require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "PlayablePool/PP_Core"
require "PlayablePool/PP_Skills"
require "PlayablePool/PP_Physics"

PPPoolWindow = ISCollapsableWindow:derive("PPPoolWindow")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local TEXTURES = {}
local TABLE_IMAGE_ASPECT = 2.0
local SIDEBAR_TO_TABLE_HEIGHT = 0.56
local MIN_SIDEBAR_WIDTH = 300
local MIN_TABLE_PIXEL_HEIGHT = 360
local DEFAULT_TABLE_PIXEL_HEIGHT = 648
local LOCK_WINDOW_ASPECT = false
local BALL_TEXTURE_SCALE_FIX = (PP.BALL_SPRITE_TEXTURE_SIZE or 96) / (PP.BALL_SPRITE_VISIBLE_SIZE or 86)
local SETTINGS = {
    showIllegalTarget = true,
    aimCheat = false,
    debugGeometry = false,
    calibrateGeometry = false,
}
local ANIMATION_SOUND_UI_ALIASES = {
    PPBallClack1 = "PPBallClack1UI",
    PPBallClack2 = "PPBallClack2UI",
    PPBallRail = "PPBallRailUI",
    PPBallPocket = "PPBallPocketUI",
}
local RESULT_SOUND_UI_ALIASES = {
    PPVictory = "PPVictoryUI",
    PPDefeat = "PPDefeatUI",
}

local function isDebugClient()
    return (isDebugEnabled and isDebugEnabled()) or (getDebug and getDebug()) or false
end

local function isSingleplayerClient()
    return not (isClient and isClient())
end

local function isAdminDebugClient()
    if not isDebugClient() then
        return false
    end
    local playerObj = getPlayer and getPlayer() or nil
    local accessLevel = ""
    if playerObj and playerObj.getAccessLevel then
        local ok, value = pcall(function()
            return playerObj:getAccessLevel()
        end)
        if ok and value then
            accessLevel = tostring(value)
        end
    end
    return string.lower(accessLevel) == "admin"
end

local function isAdminDebugPlayer(playerObj)
    if not isDebugClient() then
        return false
    end
    local accessLevel = ""
    if playerObj and playerObj.getAccessLevel then
        local ok, value = pcall(function()
            return playerObj:getAccessLevel()
        end)
        if ok and value then
            accessLevel = tostring(value)
        end
    end
    return string.lower(accessLevel) == "admin"
end

local function playPoolSound(alias)
    if not alias or not getSoundManager then
        return false
    end
    local ok, sound = pcall(function()
        return getSoundManager():playUISound(alias)
    end)
    return ok and sound ~= nil
end

local function playPoolAnimationSound(alias, fallback)
    local uiAlias = ANIMATION_SOUND_UI_ALIASES[alias]
    if uiAlias and playPoolSound(uiAlias) then
        return true
    end
    if playPoolSound(alias) then
        return true
    end
    if fallback then
        return playPoolSound(fallback)
    end
    return false
end

local function playPoolResultSound(alias, fallback)
    local uiAlias = RESULT_SOUND_UI_ALIASES[alias]
    if uiAlias and playPoolSound(uiAlias) then
        return true
    end
    if playPoolSound(alias) then
        return true
    end
    if fallback then
        return playPoolSound(fallback)
    end
    return false
end

local function texture(name)
    if not TEXTURES[name] then
        TEXTURES[name] = getTexture("media/textures/PlayablePool/" .. name)
    end
    return TEXTURES[name]
end

local function drawSprite(ui, name, x, y, size, alpha)
    local tex = texture(name)
    if tex then
        ui:drawTextureScaled(tex, x - size / 2, y - size / 2, size, size, alpha or 1, 1, 1, 1)
    else
        ui:drawRect(x - size / 2, y - size / 2, size, size, alpha or 1, 1, 1, 1)
    end
end

local function drawBallNumber(ui, ball, x, y, ballSize)
    return
end

local function drawTextureFill(ui, name, x, y, w, h, alpha)
    local tex = texture(name)
    if tex then
        ui:drawTextureScaled(tex, x, y, w, h, alpha or 1, 1, 1, 1)
        return true
    end
    return false
end

local LINE_DEFAULTS = {
    pointSize = 4,
    pointSpacing = 12,
    pointDensity = 1,
    alpha = 0.82,
}

local function lineCommand(x1, y1, x2, y2, options)
    options = options or {}
    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        r = options.r or 0.95,
        g = options.g or 0.86,
        b = options.b or 0.46,
        alpha = options.alpha or LINE_DEFAULTS.alpha,
        pointSize = options.pointSize or LINE_DEFAULTS.pointSize,
        pointSpacing = options.pointSpacing or LINE_DEFAULTS.pointSpacing,
        pointDensity = options.pointDensity or LINE_DEFAULTS.pointDensity,
    }
end

local function renderLineCommand(ui, line)
    if not line then
        return
    end
    local dx = line.x2 - line.x1
    local dy = line.y2 - line.y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return
    end

    local spacing = math.max(2, (line.pointSpacing or LINE_DEFAULTS.pointSpacing) / math.max(0.1, line.pointDensity or 1))
    local steps = math.max(1, math.floor(length / spacing))
    local size = line.pointSize or LINE_DEFAULTS.pointSize
    for i = 0, steps do
        local t = i / steps
        ui:drawRect(line.x1 + dx * t - size / 2, line.y1 + dy * t - size / 2, size, size, line.alpha or 0.82, line.r or 1, line.g or 1, line.b or 1)
    end
end

local function drawPoolLine(ui, x1, y1, x2, y2, options)
    renderLineCommand(ui, lineCommand(x1, y1, x2, y2, options))
end

local function drawDottedLine(ui, x1, y1, x2, y2, r, g, b, size, gap)
    drawPoolLine(ui, x1, y1, x2, y2, {
        r = r,
        g = g,
        b = b,
        pointSize = size or 4,
        pointSpacing = gap or 8,
        pointDensity = 0.52,
        alpha = 0.82,
    })
end

local function drawLine(ui, x1, y1, x2, y2, r, g, b, size, alpha, step)
    drawPoolLine(ui, x1, y1, x2, y2, {
        r = r,
        g = g,
        b = b,
        pointSize = size or 3,
        pointSpacing = step or 8,
        alpha = alpha or 0.9,
    })
end

local function drawDebugCircle(ui, cx, cy, radius, r, g, b, alpha)
    local steps = math.max(18, math.floor(radius / 2))
    local size = 3
    for i = 0, steps - 1 do
        local angle = (math.pi * 2) * i / steps
        ui:drawRect(cx + math.cos(angle) * radius - size / 2, cy + math.sin(angle) * radius - size / 2, size, size, alpha or 0.75, r or 1, g or 1, b or 1)
    end
end

local function ballColor(ballOrId)
    local id = type(ballOrId) == "table" and ballOrId.id or ballOrId
    local key = id
    if type(id) == "number" and id > 8 then
        key = id - 8
    end
    local color = PP.BALL_COLORS and PP.BALL_COLORS[key] or nil
    return color or { r = 0.95, g = 0.86, b = 0.46 }
end

local function previewVelocityLineStyle(energy, baseSize)
    energy = math.max(0, math.min(1, tonumber(energy) or 0))
    return {
        r = 0.015,
        g = 0.012,
        b = 0.010,
        pointSize = (baseSize or 5) + energy * 4,
        pointSpacing = 8,
        alpha = 0.72 + energy * 0.22,
    }
end

local function drawCross(ui, x, y, size, r, g, b, alpha)
    size = size or 18
    local half = size / 2
    drawLine(ui, x - half, y - half, x + half, y + half, 0.08, 0.02, 0.02, 7, 0.45, 3)
    drawLine(ui, x + half, y - half, x - half, y + half, 0.08, 0.02, 0.02, 7, 0.45, 3)
    drawLine(ui, x - half, y - half, x + half, y + half, r or 1, g or 0.12, b or 0.08, 4, alpha or 0.95, 2)
    drawLine(ui, x + half, y - half, x - half, y + half, r or 1, g or 0.12, b or 0.08, 4, alpha or 0.95, 2)
end

local function normalize(dx, dy)
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= 0 then
        return 0, 0, 0
    end
    return dx / length, dy / length, length
end

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function textWidth(text, font)
    local tm = getTextManager and getTextManager() or nil
    if tm and tm.MeasureStringX then
        local ok, width = pcall(function()
            return tm:MeasureStringX(font or UIFont.Small, tostring(text or ""))
        end)
        if ok and width then
            return width
        end
    end
    return string.len(tostring(text or "")) * 7
end

local function fitText(text, font, maxWidth)
    text = tostring(text or "")
    if textWidth(text, font) <= maxWidth then
        return text
    end
    local suffix = "..."
    local limit = math.max(1, string.len(text) - 1)
    while limit > 1 do
        local candidate = string.sub(text, 1, limit) .. suffix
        if textWidth(candidate, font) <= maxWidth then
            return candidate
        end
        limit = limit - 1
    end
    return suffix
end

local function formatNumber(value)
    return string.format("%.3f", tonumber(value) or 0):gsub("0+$", ""):gsub("%.$", "")
end

local function tryCopyTextToClipboard(text)
    local attempts = {
        function()
            if Clipboard and Clipboard.setClipboard then
                Clipboard.setClipboard(text)
                return true
            end
            return false
        end,
        function()
            if Clipboard and Clipboard.SetClipboard then
                Clipboard.SetClipboard(text)
                return true
            end
            return false
        end,
        function()
            if getClipboard then
                local clipboard = getClipboard()
                if clipboard and clipboard.setClipboard then
                    clipboard:setClipboard(text)
                    return true
                end
            end
            return false
        end,
        function()
            if UIManager and UIManager.setClipboard then
                UIManager.setClipboard(text)
                return true
            end
            return false
        end,
        function()
            if luajava then
                local toolkit = luajava.bindClass("java.awt.Toolkit")
                local selectionClass = luajava.bindClass("java.awt.datatransfer.StringSelection")
                local selection = selectionClass.new(text)
                toolkit:getDefaultToolkit():getSystemClipboard():setContents(selection, nil)
                return true
            end
            return false
        end,
    }

    for i = 1, #attempts do
        local ok, copied = pcall(attempts[i])
        if ok and copied then
            return true
        end
    end
    return false
end

local function wrapText(text, font, maxWidth, maxLines)
    text = tostring(text or "")
    local lines = {}
    local current = ""
    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        if current ~= "" and textWidth(candidate, font) > maxWidth then
            lines[#lines + 1] = current
            current = word
            if maxLines and #lines >= maxLines then
                lines[#lines] = fitText(lines[#lines], font, maxWidth)
                return lines
            end
        else
            current = candidate
        end
    end
    if current ~= "" and (not maxLines or #lines < maxLines) then
        lines[#lines + 1] = fitText(current, font, maxWidth)
    end
    return lines
end

local function drawWrappedTextCentre(ui, text, x, y, maxWidth, font, r, g, b, a, maxLines)
    local lines = wrapText(text, font, maxWidth, maxLines)
    local lineHeight = getTextManager():getFontHeight(font) + 3
    for i = 1, #lines do
        ui:drawTextCentre(lines[i], x, y + (i - 1) * lineHeight, r, g, b, a, font)
    end
    return #lines * lineHeight
end

local function windowTitleHeight()
    if ISCollapsableWindow and ISCollapsableWindow.TitleBarHeight then
        return ISCollapsableWindow.TitleBarHeight()
    end
    return math.max(16, (FONT_HGT_SMALL or 12) + 1)
end

local function contentWidthForTableHeight(tableH)
    return tableH * (TABLE_IMAGE_ASPECT + SIDEBAR_TO_TABLE_HEIGHT)
end

function PPPoolWindow.getWindowSizeForTableHeight(tableH)
    tableH = math.max(MIN_TABLE_PIXEL_HEIGHT, tonumber(tableH) or DEFAULT_TABLE_PIXEL_HEIGHT)
    local maxTableH = tableH
    if getCore then
        local screenW = math.max(1, getCore():getScreenWidth())
        local screenH = math.max(1, getCore():getScreenHeight())
        maxTableH = math.min(screenH - 96 - windowTitleHeight(), (screenW - 80) / (TABLE_IMAGE_ASPECT + SIDEBAR_TO_TABLE_HEIGHT))
    end
    tableH = math.max(MIN_TABLE_PIXEL_HEIGHT, math.min(tableH, maxTableH))
    return math.floor(contentWidthForTableHeight(tableH) + 0.5), math.floor(tableH + windowTitleHeight() + 0.5)
end

function PPPoolWindow.getDefaultWindowSize(screenW, screenH)
    local maxTableH = DEFAULT_TABLE_PIXEL_HEIGHT
    if screenW and screenH then
        maxTableH = math.min(DEFAULT_TABLE_PIXEL_HEIGHT, screenH - 96 - windowTitleHeight(), (screenW - 80) / (TABLE_IMAGE_ASPECT + SIDEBAR_TO_TABLE_HEIGHT))
    end
    return PPPoolWindow.getWindowSizeForTableHeight(maxTableH)
end

function PPPoolWindow:playResultSound(winner, players)
    if not winner or winner == self.resultSoundWinner then
        return
    end
    self.resultSoundWinner = winner
    winner = tostring(winner)
    if winner == self.playerName then
        playPoolResultSound("PPVictory", "UIActivateMainMenuItem")
    elseif PP.findNameIndex(players or {}, self.playerName) or #(players or {}) == 0 then
        playPoolResultSound("PPDefeat", "UIPauseMenuEnter")
    end
end

function PPPoolWindow:playTurnSound(previousTurn, nextTurn, nextState, delayResults)
    local phase = nextState and PP.phaseForState(nextState) or nil
    if delayResults or not nextState or nextState.winner or (phase ~= PP.PHASE_TURN_READY and phase ~= PP.PHASE_READY) then
        return
    end
    local name = self.playerName
    if not name or name == "Unknown" or nextTurn ~= name then
        return
    end
    if not PP.findNameIndex(nextState.players or {}, name) then
        return
    end

    local turnKey = tostring(nextState.shotNumber or "") .. ":" .. tostring(nextTurn)
    if self.lastTurnSoundKey == turnKey then
        return
    end
    self.lastTurnSoundKey = turnKey
    if not playPoolSound("PPTurn") then
        playPoolSound("UIActivateTab")
    end
end

function PPPoolWindow:setState(state)
    local nextState = PP.copyTable(state)
    if nextState then
        PP.refreshStatePhase(nextState)
    end
    local previousShot = self.state and self.state.shotNumber
    local previousWinner = self.state and self.state.winner
    local previousMessage = self.state and self.state.message
    local previousPlayers = self.state and self.state.players and #self.state.players or 0
    local previousTurn = self.state and PP.currentPlayerName(self.state)
    local animation = nextState and nextState.animation
    local delayResults = false
    if animation and animation.shotNumber and animation.shotNumber ~= self.animShotNumber then
        self.animation = PP.copyTable(animation)
        self.animShotNumber = animation.shotNumber
        self.animStartedAt = getTimestampMs()
        self.deferredState = PP.copyTable(animation.finalState or nextState)
        self.deferredPreviousTurn = previousTurn
        local shooter = nextState.lastShot and nextState.lastShot.shooter or previousTurn or "Player"
        nextState = self.state and PP.copyTable(self.state) or PP.copyTable(nextState)
        nextState.message = tostring(shooter) .. "'s shot is in motion..."
        nextState.events = self.state and PP.copyTable(self.state.events or {}) or {}
        nextState.aim = nil
        nextState.shotInMotion = true
        PP.setPhase(nextState, PP.PHASE_SIMULATING)
        delayResults = true
        self.animationSoundIndex = 1
        self.animationCountSoundsPlayed = nil
        playPoolSound("UIObjectMenuObjectRotate")
    elseif not animation and nextState and nextState.shotNumber ~= self.animShotNumber then
        self.animation = nil
        self.animStartedAt = nil
        self.animationCountSoundsPlayed = nil
        self.animShotNumber = nextState.shotNumber
        self.animationSoundIndex = nil
        self.deferredState = nil
        self.deferredPreviousTurn = nil
        self.deferredWinnerSound = nil
    end

    if nextState and not nextState.winner then
        self.resultSoundWinner = nil
        self.deferredWinnerSound = nil
    end

    if nextState and nextState.players and #nextState.players > previousPlayers then
        playPoolSound("UIObjectMenuObjectPlace")
    end
    if nextState and nextState.shotNumber and previousShot and nextState.shotNumber > previousShot then
        if nextState.message and string.find(string.lower(nextState.message), "sank", 1, true) then
            playPoolSound("UIObjectMenuObjectPickup")
        end
    end
    if nextState and nextState.winner and nextState.winner ~= previousWinner then
        if delayResults then
            self.deferredWinnerSound = tostring(nextState.winner)
        else
            self:playResultSound(nextState.winner, nextState.players)
        end
    end
    self:playTurnSound(previousTurn, nextState and PP.currentPlayerName(nextState), nextState, delayResults)
    self.state = nextState
    if previousShot ~= (nextState and nextState.shotNumber) or previousWinner ~= (nextState and nextState.winner) then
        self.cheatPreviewCache = nil
        self.previewSimCache = nil
    end
    if self.aiming and not self:canShoot() then
        self:syncAim(false, true)
        self.aiming = false
        self.rightAiming = false
        self.aimHandleStartX = nil
        self.aimHandleStartY = nil
        self.powerMeterSide = nil
    end
    if not delayResults and nextState and not nextState.winner and nextState.message and nextState.message ~= previousMessage then
        self.bannerText = nextState.message
        self.bannerUntil = getTimestampMs() + 2600
    end
end

function PPPoolWindow:close()
    if self.aiming then
        self:syncAim(false, true)
    end
    self.aiming = false
    self.rightAiming = false
    self.aimHandleStartX = nil
    self.aimHandleStartY = nil
    self.powerMeterSide = nil
    if PPClient and PPClient.leaveTable and self.state and self.state.anchor then
        PPClient.leaveTable(self.playerNum, self.state.anchor)
    end
    if setJoypadFocus and getFocusForPlayer and self.playerNum ~= nil and getFocusForPlayer(self.playerNum) == self then
        setJoypadFocus(self.playerNum, nil)
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if PPClient then
        PPClient.windows = PPClient.windows or {}
        PPClient.windows[self.playerNum or 0] = nil
        if (self.playerNum or 0) == 0 then
            PPClient.window = nil
        end
    end
end

function PPPoolWindow:initialise()
    ISCollapsableWindow.initialise(self)
    if ISUIElement and ISUIElement.stayOnSplitScreen and self.playerNum ~= nil then
        pcall(function()
            ISUIElement.stayOnSplitScreen(self, self.playerNum)
        end)
    end
end

function PPPoolWindow:getPlayerObj()
    if self.playerObj then
        return self.playerObj
    end
    if getSpecificPlayer and self.playerNum ~= nil then
        local playerObj = getSpecificPlayer(self.playerNum)
        if playerObj then
            self.playerObj = playerObj
            return playerObj
        end
    end
    return getPlayer and getPlayer() or nil
end

function PPPoolWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    if LOCK_WINDOW_ASPECT and self.resizeWidget then
        self.resizeWidget.resizeFunction = PPPoolWindow.resizeToAspect
    end
    if LOCK_WINDOW_ASPECT and self.resizeWidget2 then
        self.resizeWidget2.resizeFunction = PPPoolWindow.resizeToAspect
    end
end

function PPPoolWindow:resizeToAspect(width, height)
    local titleH = self:titleBarHeight()
    local contentAspect = TABLE_IMAGE_ASPECT + SIDEBAR_TO_TABLE_HEIGHT
    local widthTableH = (tonumber(width) or self.width) / contentAspect
    local heightTableH = (tonumber(height) or self.height) - titleH
    local widthDelta = math.abs((tonumber(width) or self.width) - self.width)
    local heightDelta = math.abs((tonumber(height) or self.height) - self.height) * contentAspect
    local tableH = heightDelta >= widthDelta and heightTableH or widthTableH
    local nextW, nextH = PPPoolWindow.getWindowSizeForTableHeight(tableH)

    self:setWidth(nextW)
    self:setHeight(nextH)
    if self:getX() + nextW > getCore():getScreenWidth() then
        self:setX(math.max(0, getCore():getScreenWidth() - nextW))
    end
    if self:getY() + nextH > getCore():getScreenHeight() then
        self:setY(math.max(0, getCore():getScreenHeight() - nextH))
    end
end

function PPPoolWindow:toggleFullscreen()
    local core = getCore and getCore() or nil
    if not core then
        return false
    end
    if self.poolFullscreen then
        local rect = self.preFullscreenRect
        if rect then
            self:setX(rect.x)
            self:setY(rect.y)
            self:setWidth(rect.w)
            self:setHeight(rect.h)
        end
        self.poolFullscreen = false
        self.preFullscreenRect = nil
        return true
    end

    self.preFullscreenRect = { x = self:getX(), y = self:getY(), w = self.width, h = self.height }
    self:setX(0)
    self:setY(0)
    self:setWidth(core:getScreenWidth())
    self:setHeight(core:getScreenHeight())
    self.poolFullscreen = true
    return true
end

function PPPoolWindow:handleTitleBarDoubleClick(x, y)
    if y > self:titleBarHeight() or x < 28 or x > self.width - 64 then
        return false
    end
    local now = getTimestampMs()
    local lastAt = self.lastTitleBarClickAt or 0
    local lastX = self.lastTitleBarClickX or x
    local lastY = self.lastTitleBarClickY or y
    self.lastTitleBarClickAt = now
    self.lastTitleBarClickX = x
    self.lastTitleBarClickY = y
    if now - lastAt <= 360 and math.abs(x - lastX) <= 10 and math.abs(y - lastY) <= 6 then
        self.lastTitleBarClickAt = nil
        return self:toggleFullscreen()
    end
    return false
end

function PPPoolWindow:enforceAspectRatio()
    if not LOCK_WINDOW_ASPECT then
        return
    end
    local nextW, nextH = PPPoolWindow.getWindowSizeForTableHeight(self.height - self:titleBarHeight())
    if math.abs(nextW - self.width) > 1 or math.abs(nextH - self.height) > 1 then
        self:resizeToAspect(nextW, nextH)
    end
end

function PPPoolWindow:prerender()
    self:enforceAspectRatio()
    ISCollapsableWindow.prerender(self)
    if self.rightAiming then
        if self:isRightMouseStillDown() then
            self:confineAimCursor(self:getMouseX(), self:getMouseY())
        else
            self.rightAiming = false
        end
    end
    self:updateHeldKeyboardControls()
end

function PPPoolWindow:getTableRect()
    local titleH = self:titleBarHeight()
    local contentW = math.max(1, self.width)
    local contentH = math.max(1, self.height - titleH)
    local sidebarW = math.min(MIN_SIDEBAR_WIDTH, math.max(1, contentW * 0.42))
    local maxTableW = math.max(1, contentW - sidebarW)
    local tableW = math.min(maxTableW, contentH * TABLE_IMAGE_ASPECT)
    local tableH = math.min(contentH, tableW / TABLE_IMAGE_ASPECT)
    local y = titleH + math.max(0, (contentH - tableH) / 2)
    return 0, y, tableW, tableH
end

function PPPoolWindow:getSidebarRect()
    local titleH = self:titleBarHeight()
    local tx, _, tw = self:getTableRect()
    local x = tx + tw
    return x, titleH, math.max(1, self.width - x), math.max(1, self.height - titleH)
end

function PPPoolWindow:getGamePaneRect()
    local titleH = self:titleBarHeight()
    local sx = self:getSidebarRect()
    return 0, titleH, sx, math.max(1, self.height - titleH)
end

function PPPoolWindow:getWinnerPanelRect()
    local gx, gy, gw, gh = self:getGamePaneRect()
    local panelW = math.min(520, math.max(320, gw - 80))
    panelW = math.min(panelW, math.max(1, gw - 32))
    local panelH = math.min(260, math.max(220, gh - 32))
    local x = clamp(gx + gw / 2 - panelW / 2, gx + 16, gx + gw - panelW - 16)
    local y = clamp(gy + gh / 2 - panelH / 2, gy + 16, gy + gh - panelH - 16)
    return x, y, panelW, panelH, gx + gw / 2
end

function PPPoolWindow:getTableScale()
    local tx, ty, tw, th = self:getPlayfieldRect()
    return math.min(tw / PP.TABLE_W, th / PP.TABLE_H)
end

function PPPoolWindow:getBallSpriteSize()
    local visibleDiameter = self:getTableScale() * (PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R) * 2
    return math.max(27, math.floor(visibleDiameter * BALL_TEXTURE_SCALE_FIX + 0.5))
end

function PPPoolWindow:getPlayfieldRect()
    local tx, ty, tw, th = self:getTableRect()
    local map = PP.getPlayfieldMap and PP.getPlayfieldMap() or { insetX = 0.043, insetTop = 0.085, insetBottom = 0.059 }
    local x = tx + tw * map.insetX
    local y = ty + th * map.insetTop
    local w = tw * (1 - map.insetX * 2)
    local h = th * (1 - map.insetTop - map.insetBottom)
    return x, y, w, h
end

function PPPoolWindow:tableToUi(ball)
    local x, y, w, h = self:getPlayfieldRect()
    return x + ball.x / PP.TABLE_W * w, y + ball.y / PP.TABLE_H * h
end

function PPPoolWindow:uiToTable(x, y)
    local tx, ty, tw, th = self:getPlayfieldRect()
    return (x - tx) / tw * PP.TABLE_W, (y - ty) / th * PP.TABLE_H
end

function PPPoolWindow:tableVectorToUiVector(dirX, dirY)
    local _, _, tw, th = self:getPlayfieldRect()
    return normalize((dirX or 0) * tw / PP.TABLE_W, (dirY or 0) * th / PP.TABLE_H)
end

function PPPoolWindow:tableAngleToUiVector(angle)
    return self:tableVectorToUiVector(math.cos(angle or 0), math.sin(angle or 0))
end

function PPPoolWindow:uiPointToTableAngle(cue, x, y)
    if not cue then
        return 0
    end
    local tableX, tableY = self:uiToTable(x, y)
    return PP.atan2(tableY - cue.y, tableX - cue.x)
end

function PPPoolWindow:uiBackPointToTableAngle(cue, x, y)
    if not cue then
        return 0
    end
    local tableX, tableY = self:uiToTable(x, y)
    return PP.atan2(cue.y - tableY, cue.x - tableX)
end

function PPPoolWindow:isInsideTable(x, y)
    local tx, ty, tw, th = self:getPlayfieldRect()
    return x >= tx and x <= tx + tw and y >= ty and y <= ty + th
end

function PPPoolWindow:isInsideGameRegion(x, y)
    local gx, gy, gw, gh = self:getGamePaneRect()
    return x >= gx and x <= gx + gw and y >= gy and y <= gy + gh
end

function PPPoolWindow:getAimCursorBounds()
    local tx, ty, tw, th = self:getPlayfieldRect()
    return tx - 20, ty - 20, tx + tw + 20, ty + th + 20
end

function PPPoolWindow:isMyTurn()
    if not self.state or not self.playerName then
        return false
    end
    local phase = PP.phaseForState(self.state)
    local ready = phase == PP.PHASE_TURN_READY or phase == PP.PHASE_READY or (phase == PP.PHASE_AIMING and self.state.aim and self.state.aim.playerName == self.playerName)
    return not self:isAnimating() and ready and self.state.modeSelected and PP.currentPlayerName(self.state) == self.playerName and not self.state.winner and #self.state.players >= 2
end

function PPPoolWindow:isSpectator()
    if not self.state or not self.playerName then
        return false
    end
    return PP.findNameIndex(self.state.spectators or {}, self.playerName) ~= nil and not PP.findNameIndex(self.state.players or {}, self.playerName)
end

function PPPoolWindow:isPlacingCue()
    return self:isMyTurn() and self.state.ballInHand and self.state.ballInHandPlayer == self.playerName
end

function PPPoolWindow:canShoot()
    return self:isMyTurn() and not self:isPlacingCue()
end

function PPPoolWindow:canEditShotCall()
    return self:canShoot() and PP.eightBallCallRequired and PP.eightBallCallRequired(self.state)
end

function PPPoolWindow:getActiveShotCall()
    if not self.state then
        return nil
    end
    if self.state.shotCall then
        return self.state.shotCall
    end
    return PP.buildShotCallForAim and PP.buildShotCallForAim(self.state, self.playerName, self.aimAngle or self.keyboardAngle or 0) or nil
end

function PPPoolWindow:setShotCall(shotCall)
    if not self.state or not self.state.anchor or not PPClient or not PPClient.setShotCall then
        return false
    end
    local ok = PP.setShotCall and PP.setShotCall(self.state, self.playerName, shotCall)
    if not ok then
        return false
    end
    PPClient.setShotCall(self.playerNum, self.state.anchor, self.state.shotCall)
    return true
end

function PPPoolWindow:cycleCalledBall()
    if not self:canEditShotCall() then
        return false
    end
    local targets = PP.legalTargetBalls and PP.legalTargetBalls(self.state, self.playerName) or {}
    if #targets == 0 then
        return false
    end
    local current = self:getActiveShotCall()
    local index = 0
    for i = 1, #targets do
        if current and targets[i].id == current.ballId then
            index = i
            break
        end
    end
    local nextBall = targets[(index % #targets) + 1]
    local pocketId = current and current.pocketId or (PP.POCKET_ORDER and PP.POCKET_ORDER[1])
    return self:setShotCall({ ballId = nextBall.id, pocketId = pocketId })
end

function PPPoolWindow:cycleCalledPocket()
    if not self:canEditShotCall() then
        return false
    end
    local current = self:getActiveShotCall()
    local call = current or (PP.buildShotCallForAim and PP.buildShotCallForAim(self.state, self.playerName, self.aimAngle or self.keyboardAngle or 0))
    if not call or not call.ballId then
        return false
    end
    local order = PP.POCKET_ORDER or {}
    local index = 0
    for i = 1, #order do
        if order[i] == call.pocketId then
            index = i
            break
        end
    end
    local pocketId = order[(index % #order) + 1]
    return self:setShotCall({ ballId = call.ballId, pocketId = pocketId })
end

function PPPoolWindow:toggleSafetyCall()
    if not self:canEditShotCall() then
        return false
    end
    local current = self:getActiveShotCall()
    if current and current.safety then
        local call = PP.buildShotCallForAim and PP.buildShotCallForAim(self.state, self.playerName, self.aimAngle or self.keyboardAngle or 0) or nil
        return self:setShotCall(call)
    end
    return self:setShotCall({ safety = true })
end

function PPPoolWindow:canChooseMode()
    if not self.state or not self.state.anchor or not self.playerName then
        return false
    end
    if not PP.findNameIndex(self.state.players or {}, self.playerName) then
        return false
    end
    return not self:isAnimating() and not self.state.winner and ((not self.state.modeSelected) or (self.state.shotNumber or 0) == 0)
end

function PPPoolWindow:getBilliardsLevel()
    return PP.getPlayerBilliardsLevel(self:getPlayerObj())
end

function PPPoolWindow:getSkillProfile()
    return PP.getBilliardsSkillProfile(self:getBilliardsLevel())
end

function PPPoolWindow:getCurrentShotPower(defaultPower)
    return clamp(self.pendingPower or self.keyboardPower or self.lastShotPower or defaultPower or 300, 30, PP.MAX_POWER)
end

function PPPoolWindow:setCueSpin(spinX, spinY)
    local x, y = PP.clampCueSpin(spinX or self.cueSpinX or 0, spinY or self.cueSpinY or 0, self:getBilliardsLevel())
    self.cueSpinX = x
    self.cueSpinY = y
end

function PPPoolWindow:isAnimating()
    return self.animation and self.animStartedAt and true or false
end

function PPPoolWindow:playDueAnimationSounds(elapsed)
    local sounds = self.animation and self.animation.sounds
    local events = sounds and sounds.events
    if not events or #events == 0 then
        if sounds and not self.animationCountSoundsPlayed and (elapsed or 0) >= 60 then
            self.animationCountSoundsPlayed = true
            if (sounds.impacts or 0) > 0 then
                playPoolAnimationSound((sounds.impacts or 0) > 1 and "PPBallClack2" or "PPBallClack1", "UIObjectMenuObjectPickup")
            elseif (sounds.rails or 0) > 0 then
                playPoolAnimationSound("PPBallRail", "UIObjectMenuObjectRotate")
            elseif (sounds.pockets or 0) > 0 then
                playPoolAnimationSound("PPBallPocket", "UIObjectMenuObjectPlace")
            end
        end
        return
    end
    self.animationSoundIndex = self.animationSoundIndex or 1
    while self.animationSoundIndex <= #events do
        local event = events[self.animationSoundIndex]
        if not event or (event.ms or 0) > elapsed then
            break
        end
        if event.kind == "impact" then
            if (event.strength or 0) >= 0.55 then
                playPoolAnimationSound("PPBallClack2", "UIObjectMenuObjectPickup")
            else
                playPoolAnimationSound("PPBallClack1", "UIObjectMenuObjectPickup")
            end
        elseif event.kind == "rail" then
            playPoolAnimationSound("PPBallRail", "UIObjectMenuObjectRotate")
        elseif event.kind == "pocket" then
            playPoolAnimationSound("PPBallPocket", "UIObjectMenuObjectPlace")
        end
        self.animationSoundIndex = self.animationSoundIndex + 1
    end
end

function PPPoolWindow:getAnimatedBalls()
    if not self.animation or not self.animation.frames or #self.animation.frames == 0 then
        return nil
    end
    local frameMs = self.animation.frameMs or 24
    local elapsed = getTimestampMs() - self.animStartedAt
    self:playDueAnimationSounds(elapsed)
    local exact = elapsed / frameMs + 1
    local index = math.floor(exact)
    local t = exact - index
    if index >= #self.animation.frames then
        self.animation = nil
        self.animStartedAt = nil
        self.animationSoundIndex = nil
        self.animationCountSoundsPlayed = nil
        if self.deferredState then
            local previousTurn = self.deferredPreviousTurn
            local finalState = PP.copyTable(self.deferredState)
            self.state = finalState
            if finalState.winner then
                self.bannerText = nil
                self.bannerUntil = nil
                self:playResultSound(self.deferredWinnerSound or finalState.winner, finalState.players)
            else
                self.bannerText = finalState.message
                self.bannerUntil = getTimestampMs() + 2600
                self:playTurnSound(previousTurn, PP.currentPlayerName(finalState), finalState, false)
            end
            self.deferredState = nil
            self.deferredPreviousTurn = nil
            self.deferredWinnerSound = nil
        end
        return nil
    end

    local a = self.animation.frames[index]
    local b = self.animation.frames[index + 1] or a
    local balls = {}
    for i = 1, #a do
        local from = a[i]
        local to = b[i] or from
        balls[i] = {
            id = from.id,
            x = from.x + ((to.x or from.x) - from.x) * t,
            y = from.y + ((to.y or from.y) - from.y) * t,
            pocketed = from.pocketed or to.pocketed,
        }
    end
    return balls
end

function PPPoolWindow:getDisplayBalls()
    return self:getAnimatedBalls() or (self.state and self.state.balls) or {}
end

function PPPoolWindow:getSettings()
    return SETTINGS
end

function PPPoolWindow:canUseAimCheat()
    if not isDebugClient() then
        return false
    end
    if not (isClient and isClient()) then
        return true
    end
    return isAdminDebugPlayer(self:getPlayerObj()) or isAdminDebugClient()
end

function PPPoolWindow:isAimCheatEnabled()
    return self:canUseAimCheat() and self:getSettings().aimCheat == true
end

function PPPoolWindow:drawTable(tx, ty, tw, th)
    if drawTextureFill(self, "pool_table.png", tx, ty, tw, th, 1) then
        return
    end
    local rail = math.max(12, th * 0.055)
    self:drawRect(tx, ty, tw, th, 1, 0.08, 0.04, 0.02)
    self:drawRect(tx + rail, ty + rail, tw - rail * 2, th - rail * 2, 1, 0.04, 0.28, 0.14)
    self:drawRectBorder(tx, ty, tw, th, 1, 0.02, 0.13, 0.07)

    local pockets = {
        { x = tx, y = ty }, { x = tx + tw / 2, y = ty }, { x = tx + tw, y = ty },
        { x = tx, y = ty + th }, { x = tx + tw / 2, y = ty + th }, { x = tx + tw, y = ty + th },
    }
    for i = 1, #pockets do
        drawSprite(self, "pocket.png", pockets[i].x, pockets[i].y, 34, 1)
    end
end

function PPPoolWindow:drawGameFloor()
    local x, y, w, h = self:getGamePaneRect()
    self:drawRect(x, y, w, h, 1, 0, 0, 0)
end

function PPPoolWindow:drawGeometryOverlay()
    if not self:getSettings().debugGeometry then
        return
    end
    local edge = PP.getCollisionEdge and PP.getCollisionEdge("sprite") or {}
    if self.drawCalibrationPolygon then
        self:drawCalibrationPolygon(edge, 0.25, 0.95, 1.00, 0.46, 3)
        self:drawCalibrationSegments(PP.getCollisionSegmentsInSprite and PP.getCollisionSegmentsInSprite() or {}, 0.96, 0.92, 0.30, 0.56, 3)
        self:drawCalibrationSegments(PP.getPocketMouthBridgeSegments and PP.getPocketMouthBridgeSegments("sprite") or {}, 1.00, 0.24, 0.12, 0.22, 2)
    end
    local pockets = PP.getPocketCenters and PP.getPocketCenters() or {}
    for i = 1, #pockets do
        local sx = pockets[i].spriteX
        local sy = pockets[i].spriteY
        if (not sx or not sy) and PP.tableToSprite then
            sx, sy = PP.tableToSprite(pockets[i].x, pockets[i].y)
        end
        local px, py = self:spriteToUi({ x = sx, y = sy })
        local capture = (PP.getPocketCaptureRadius and PP.getPocketCaptureRadius(pockets[i]) or PP.POCKET_R) * self:getTableScale()
        local gravity = (PP.getPocketGravityRadius and PP.getPocketGravityRadius(pockets[i]) or PP.POCKET_R) * self:getTableScale()
        drawDebugCircle(self, px, py, gravity, 0.28, 0.72, 1.00, 0.34)
        drawDebugCircle(self, px, py, capture, 1.00, 0.44, 0.24, 0.58)
    end
    local balls = self:getDisplayBalls()
    local radius = (PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R) * self:getTableScale()
    for i = 1, #balls do
        if not balls[i].pocketed then
            local bx, by = self:tableToUi(balls[i])
            drawDebugCircle(self, bx, by, radius, 0.96, 0.92, 0.30, 0.64)
        end
    end
end

function PPPoolWindow:resetGeometryCalibration()
    local edge = PP.getCollisionEdge and PP.getCollisionEdge("sprite") or {}
    local pockets = PP.getPocketCenters and PP.getPocketCenters() or {}
    local edgeCopy = {}
    for i = 1, #edge do
        edgeCopy[#edgeCopy + 1] = { id = edge[i].id, x = edge[i].x, y = edge[i].y }
    end
    local copy = {}
    for i = 1, #pockets do
        local sx = pockets[i].spriteX
        local sy = pockets[i].spriteY
        if (not sx or not sy) and PP.tableToSprite then
            sx, sy = PP.tableToSprite(pockets[i].x, pockets[i].y)
        end
        copy[#copy + 1] = {
            id = pockets[i].id,
            spriteX = sx,
            spriteY = sy,
            captureRadius = pockets[i].captureRadius,
            gravityRadius = pockets[i].gravityRadius,
            mouthRadius = pockets[i].mouthRadius,
            commitRadius = pockets[i].commitRadius,
        }
    end
    self.geometryCalibration = { collisionEdge = edgeCopy, pockets = copy }
    self.geometrySelected = nil
    self.geometryUndo = {}
end

function PPPoolWindow:getGeometryCalibration()
    if not self.geometryCalibration then
        self:resetGeometryCalibration()
    end
    return self.geometryCalibration
end

function PPPoolWindow:calibrationPayload()
    local data = self:getGeometryCalibration()
    local lines = {
        "-- Playable Pool geometry calibration",
        "-- Sprite-space authored contact edge; paste into PP.TABLE_GEOMETRY.",
        "collisionEdge = {",
    }
    for i = 1, #(data.collisionEdge or {}) do
        local point = data.collisionEdge[i]
        local id = point.id and (" id = \"" .. tostring(point.id) .. "\",") or ""
        lines[#lines + 1] = "    {" .. id .. " x = " .. formatNumber(point.x) .. ", y = " .. formatNumber(point.y) .. " },"
    end
    lines[#lines + 1] = "},"
    lines[#lines + 1] = "pockets = {"
    for i = 1, #data.pockets do
        local pocket = data.pockets[i]
        local tx, ty = PP.spriteToTable(pocket.spriteX, pocket.spriteY)
        local suffix = ""
        if pocket.captureRadius then
            suffix = suffix .. ", captureRadius = " .. formatNumber(pocket.captureRadius)
        end
        if pocket.gravityRadius then
            suffix = suffix .. ", gravityRadius = " .. formatNumber(pocket.gravityRadius)
        end
        if pocket.mouthRadius then
            suffix = suffix .. ", mouthRadius = " .. formatNumber(pocket.mouthRadius)
        end
        if pocket.commitRadius then
            suffix = suffix .. ", commitRadius = " .. formatNumber(pocket.commitRadius)
        end
        lines[#lines + 1] = "    { id = \"" .. tostring(pocket.id) .. "\", x = " .. formatNumber(tx) .. ", y = " .. formatNumber(ty) .. ", spriteX = " .. formatNumber(pocket.spriteX) .. ", spriteY = " .. formatNumber(pocket.spriteY) .. suffix .. " },"
    end
    lines[#lines + 1] = "},"
    return table.concat(lines, "\n")
end

function PPPoolWindow:spriteToUi(point)
    local tx, ty, tw, th = self:getTableRect()
    local geometry = PP.getTableGeometry and PP.getTableGeometry() or {}
    local sw = geometry.spriteW or 1774
    local sh = geometry.spriteH or 887
    return tx + (point.x or point.spriteX or 0) / sw * tw, ty + (point.y or point.spriteY or 0) / sh * th
end

function PPPoolWindow:uiToSprite(x, y)
    local tx, ty, tw, th = self:getTableRect()
    local geometry = PP.getTableGeometry and PP.getTableGeometry() or {}
    local sw = geometry.spriteW or 1774
    local sh = geometry.spriteH or 887
    return (x - tx) / tw * sw, (y - ty) / th * sh
end

function PPPoolWindow:drawCalibrationPolygon(points, r, g, b, alpha, size)
    for i = 1, #(points or {}) do
        local a = points[i]
        local nextPoint = points[i % #points + 1]
        local ax, ay = self:spriteToUi(a)
        local bx, by = self:spriteToUi(nextPoint)
        drawLine(self, ax, ay, bx, by, r, g, b, size or 4, alpha or 0.9, 3)
    end
end

function PPPoolWindow:drawCalibrationSegments(segments, r, g, b, alpha, size)
    for i = 1, #(segments or {}) do
        local seg = segments[i]
        local ax, ay = self:spriteToUi({ x = seg.ax, y = seg.ay })
        local bx, by = self:spriteToUi({ x = seg.bx, y = seg.by })
        drawLine(self, ax, ay, bx, by, r, g, b, size or 4, alpha or 0.9, 3)
    end
end

function PPPoolWindow:calibrationEdgeInTable()
    local data = self:getGeometryCalibration()
    local result = {}
    for i = 1, #(data.collisionEdge or {}) do
        local sx, sy = data.collisionEdge[i].x, data.collisionEdge[i].y
        local x, y = PP.spriteToTable(sx, sy)
        result[i] = { id = data.collisionEdge[i].id, x = x, y = y }
    end
    return result
end

function PPPoolWindow:calibrationCollisionSegmentsInSprite()
    local data = self:getGeometryCalibration()
    if PP.getCollisionSegmentsForEdge then
        return PP.getCollisionSegmentsForEdge(data.collisionEdge or {})
    end
    return {}
end

function PPPoolWindow:pushGeometryUndo()
    local data = self:getGeometryCalibration()
    self.geometryUndo = self.geometryUndo or {}
    self.geometryUndo[#self.geometryUndo + 1] = PP.copyTable(data)
    if #self.geometryUndo > 24 then
        table.remove(self.geometryUndo, 1)
    end
end

function PPPoolWindow:undoGeometryEdit()
    local undo = self.geometryUndo or {}
    local prev = undo[#undo]
    if prev then
        undo[#undo] = nil
        self.geometryCalibration = prev
        self.geometrySelected = nil
        self.bannerText = "Undid geometry edit."
        self.bannerUntil = getTimestampMs() + 1800
    end
end

function PPPoolWindow:nearestGeometrySegment(spriteX, spriteY)
    local points = self:getGeometryCalibration().collisionEdge or {}
    local best = nil
    for i = 1, #points do
        local a = points[i]
        local nextPoint = points[i % #points + 1]
        local dx = nextPoint.x - a.x
        local dy = nextPoint.y - a.y
        local lenSq = dx * dx + dy * dy
        if lenSq > 0 then
            local t = clamp(((spriteX - a.x) * dx + (spriteY - a.y) * dy) / lenSq, 0, 1)
            local px = a.x + dx * t
            local py = a.y + dy * t
            local distSq = (spriteX - px) * (spriteX - px) + (spriteY - py) * (spriteY - py)
            if not best or distSq < best.distSq then
                best = { index = i, distSq = distSq }
            end
        end
    end
    return best
end

function PPPoolWindow:insertGeometryVertex(spriteX, spriteY)
    local data = self:getGeometryCalibration()
    local segment = self:nearestGeometrySegment(spriteX, spriteY)
    local insertAt = segment and (segment.index + 1) or (#(data.collisionEdge or {}) + 1)
    self:pushGeometryUndo()
    table.insert(data.collisionEdge, insertAt, { id = "edge_" .. tostring(insertAt), x = spriteX, y = spriteY })
    self.geometrySelected = { type = "edge", index = insertAt }
end

function PPPoolWindow:deleteSelectedGeometryPoint()
    local selected = self.geometrySelected
    local data = self:getGeometryCalibration()
    if not selected or selected.type ~= "edge" or not data.collisionEdge or not data.collisionEdge[selected.index] then
        return false
    end
    self:pushGeometryUndo()
    table.remove(data.collisionEdge, selected.index)
    self.geometrySelected = nil
    return true
end

function PPPoolWindow:clearGeometryEdge()
    local data = self:getGeometryCalibration()
    if not data.collisionEdge or #data.collisionEdge == 0 then
        return false
    end
    self:pushGeometryUndo()
    data.collisionEdge = {}
    self.geometrySelected = nil
    self.geometryDrag = nil
    return true
end

function PPPoolWindow:copyGeometryCalibration()
    local text = self:calibrationPayload()
    local copied = tryCopyTextToClipboard(text)
    print("[PlayablePool] Geometry calibration values:\n" .. text)
    self.bannerText = copied and "Copied geometry Lua to clipboard." or "Printed geometry Lua to console/log."
    self.bannerUntil = getTimestampMs() + 3500
    return copied
end

function PPPoolWindow:drawGeometryEditorPanel(panelX, panelY)
    local panelW = 560
    self:drawRect(panelX, panelY, panelW, 104, 0.78, 0.02, 0.02, 0.02)
    self:drawRectBorder(panelX, panelY, panelW, 104, 0.92, 0.80, 0.55, 0.35)
    self:drawText("Sprite geometry editor", panelX + 10, panelY + 8, 1.00, 0.86, 0.46, 1, UIFont.Small)
    self:drawText("Drag points. Click table to add. Right click selected point to delete.", panelX + 10, panelY + 30, 0.86, 0.84, 0.76, 1, UIFont.Small)
    self:drawText("Copy emits sprite-space collisionEdge and pockets for PP.TABLE_GEOMETRY.", panelX + 10, panelY + 48, 0.72, 0.82, 0.88, 1, UIFont.Small)
    local copyRect = { x = panelX + 10, y = panelY + 74, w = 122, h = 22 }
    local undoRect = { x = panelX + 140, y = panelY + 74, w = 76, h = 22 }
    local resetRect = { x = panelX + 224, y = panelY + 74, w = 76, h = 22 }
    local clearRect = { x = panelX + 308, y = panelY + 74, w = 94, h = 22 }
    self.geometryCopyRect = copyRect
    self.geometryUndoRect = undoRect
    self.geometryResetRect = resetRect
    self.geometryClearRect = clearRect
    self:drawRect(copyRect.x, copyRect.y, copyRect.w, copyRect.h, 0.82, 0.20, 0.12, 0.035)
    self:drawRectBorder(copyRect.x, copyRect.y, copyRect.w, copyRect.h, 0.92, 0.88, 0.62, 0.30)
    self:drawTextCentre("Copy Lua", copyRect.x + copyRect.w / 2, copyRect.y + 3, 0.96, 0.90, 0.72, 1, UIFont.Small)
    self:drawRect(undoRect.x, undoRect.y, undoRect.w, undoRect.h, 0.72, 0.06, 0.05, 0.04)
    self:drawRectBorder(undoRect.x, undoRect.y, undoRect.w, undoRect.h, 0.82, 0.64, 0.48, 0.26)
    self:drawTextCentre("Undo", undoRect.x + undoRect.w / 2, undoRect.y + 3, 0.86, 0.82, 0.70, 1, UIFont.Small)
    self:drawRect(resetRect.x, resetRect.y, resetRect.w, resetRect.h, 0.72, 0.06, 0.05, 0.04)
    self:drawRectBorder(resetRect.x, resetRect.y, resetRect.w, resetRect.h, 0.82, 0.64, 0.48, 0.26)
    self:drawTextCentre("Reset", resetRect.x + resetRect.w / 2, resetRect.y + 3, 0.86, 0.82, 0.70, 1, UIFont.Small)
    self:drawRect(clearRect.x, clearRect.y, clearRect.w, clearRect.h, 0.78, 0.18, 0.04, 0.04)
    self:drawRectBorder(clearRect.x, clearRect.y, clearRect.w, clearRect.h, 0.90, 0.52, 0.38, 0.32)
    self:drawTextCentre("Clear Edge", clearRect.x + clearRect.w / 2, clearRect.y + 3, 0.92, 0.78, 0.64, 1, UIFont.Small)
end

function PPPoolWindow:drawGeometryCalibration()
    local settings = self:getSettings()
    if not settings.calibrateGeometry then
        self.geometryDrag = nil
        return
    end
    settings.debugGeometry = true

    local data = self:getGeometryCalibration()
    self.geometryHandles = {}
    self:drawCalibrationPolygon(data.collisionEdge, 0.25, 0.95, 1.00, 0.92, 5)
    self:drawCalibrationSegments(self:calibrationCollisionSegmentsInSprite(), 0.96, 0.92, 0.30, 0.58, 3)

    for i = 1, #(data.collisionEdge or {}) do
        local point = data.collisionEdge[i]
        local px, py = self:spriteToUi(point)
        local selected = self.geometrySelected and self.geometrySelected.type == "edge" and self.geometrySelected.index == i
        self:drawRect(px - 5, py - 5, 10, 10, selected and 0.96 or 0.82, selected and 0.20 or 0.04, selected and 0.92 or 0.55, 0.78)
        self:drawRectBorder(px - 6, py - 6, 12, 12, 0.95, 0.70, 0.95, 1.00)
        self.geometryHandles[#self.geometryHandles + 1] = { type = "edge", index = i, x = px, y = py, radius = 14 }
    end

    for i = 1, #data.pockets do
        local pocket = data.pockets[i]
        local px, py = self:spriteToUi({ x = pocket.spriteX, y = pocket.spriteY })
        local capture = (pocket.captureRadius or (PP.POCKET_R or 32)) * self:getTableScale()
        local mouth = (pocket.mouthRadius or (PP.getPocketMouthRadius and PP.getPocketMouthRadius() or PP.POCKET_R or 32)) * self:getTableScale()
        drawDebugCircle(self, px, py, mouth, 0.28, 0.72, 1.00, 0.34)
        drawDebugCircle(self, px, py, capture, 1.00, 0.92, 0.20, 0.82)
        self:drawTextCentre(tostring(pocket.id), px, py + capture + 4, 1.00, 0.92, 0.58, 0.95, UIFont.Small)
        self.geometryHandles[#self.geometryHandles + 1] = { type = "pocket", index = i, x = px, y = py, radius = math.max(18, capture * 0.45) }
    end

    local gx, gy, gw, gh = self:getGamePaneRect()
    local panelW = 560
    local panelH = 104
    local panelX = gx + math.max(12, (gw - panelW) / 2)
    local panelY = gy + math.max(12, (gh - panelH) / 2)
    self:drawGeometryEditorPanel(panelX, panelY)
end

function PPPoolWindow:drawAimGuide(cueUiX, cueUiY, tx, ty, tw, th, aim)
    if not cueUiX or not cueUiY then
        return
    end

    aim = aim or {}
    local angle = aim.angle or self.aimAngle
    if not angle then
        local dx = cueUiX - self.mouseX
        local dy = cueUiY - self.mouseY
        if math.sqrt(dx * dx + dy * dy) <= 1 then
            return
        end
        local cue = PP.findBall({ balls = self:getDisplayBalls() }, "cue")
        angle = self:uiBackPointToTableAngle(cue, self.mouseX, self.mouseY)
    end

    local nx = math.cos(angle)
    local ny = math.sin(angle)
    if nx == 0 and ny == 0 then
        return
    end
    local uiNx, uiNy = self:tableVectorToUiVector(nx, ny)

    local power = aim.power or self.pendingPower or 300
    local localAim = not (aim.playerName and aim.playerName ~= self.playerName)
    local powerRatio = clamp(power / PP.MAX_POWER, 0, 1)
    self:drawTrajectoryPreview(cueUiX, cueUiY, nx, ny, tx, ty, tw, th, power, localAim)
    local pullLength = 42 + 110 * powerRatio
    local cueBackX = cueUiX - uiNx * pullLength
    local cueBackY = cueUiY - uiNy * pullLength
    drawDottedLine(self, cueUiX, cueUiY, cueBackX, cueBackY, 0.36, 0.72, 1.00, 3, 9)

    drawLine(self, cueBackX, cueBackY, cueUiX - uiNx * 18, cueUiY - uiNy * 18, 0.73, 0.36, 0.18, 5, 0.85, 3)
    drawLine(self, cueBackX, cueBackY, cueUiX - uiNx * 18, cueUiY - uiNy * 18, 0.98, 0.68, 0.42, 2, 0.65, 4)
    self:drawRect(cueBackX - 3, cueBackY - 3, 6, 6, 0.95, 0.98, 0.88, 0.52)
    if aim.playerName and aim.playerName ~= self.playerName then
        self:drawTextCentre(tostring(aim.playerName) .. " aiming", cueBackX, cueBackY - FONT_HGT_SMALL - 8, 0.70, 0.88, 1.00, 0.92, UIFont.Small)
    else
        self:drawCuePowerMeter(cueUiX, cueUiY, powerRatio, tx, ty, tw, th, uiNx, uiNy)
        self:drawCueSpinIndicator(cueUiX, cueUiY)
    end
end

function PPPoolWindow:getSmoothedRemoteAim(aim)
    if not aim or aim.playerName == self.playerName then
        self.remoteAimVisual = nil
        return aim
    end
    local now = getTimestampMs()
    local targetAngle = aim.angle or 0
    local targetPower = aim.power or 300
    local visual = self.remoteAimVisual
    if not visual or visual.playerName ~= aim.playerName then
        visual = {
            playerName = aim.playerName,
            angle = targetAngle,
            power = targetPower,
            targetAngle = targetAngle,
            targetPower = targetPower,
            startedAt = now,
            duration = 1,
        }
    elseif math.abs((visual.targetAngle or 0) - targetAngle) > 0.0001 or math.abs((visual.targetPower or 0) - targetPower) > 0.5 then
        visual.fromAngle = visual.angle or targetAngle
        visual.fromPower = visual.power or targetPower
        visual.targetAngle = targetAngle
        visual.targetPower = targetPower
        visual.startedAt = now
        visual.duration = 260
    end

    local t = clamp((now - (visual.startedAt or now)) / math.max(1, visual.duration or 1), 0, 1)
    t = t * t * (3 - 2 * t)
    local fromAngle = visual.fromAngle or visual.angle or targetAngle
    local delta = ((targetAngle - fromAngle + math.pi) % (math.pi * 2)) - math.pi
    visual.angle = fromAngle + delta * t
    visual.power = (visual.fromPower or visual.power or targetPower) + (targetPower - (visual.fromPower or visual.power or targetPower)) * t
    self.remoteAimVisual = visual

    local copy = PP.copyTable and PP.copyTable(aim) or { playerName = aim.playerName }
    copy.angle = visual.angle
    copy.power = visual.power
    return copy
end

function PPPoolWindow:drawCuePowerMeter(anchorX, anchorY, powerRatio, tx, ty, tw, th, dirX, dirY)
    local w = 104
    local h = 10
    local gap = self:getBallSpriteSize() / 2 + 24
    local nx = -(dirY or 0)
    local ny = dirX or 1
    if nx == 0 and ny == 0 then
        ny = 1
    end
    local left = anchorX - w / 2
    local right = tx + tw - w - 8
    local top = ty + 8 + FONT_HGT_SMALL + 6
    local bottom = ty + th - h - 8
    local x1 = clamp(left + nx * gap, tx + 8, right)
    local y1 = clamp(anchorY - h / 2 + ny * gap, top, bottom)
    local x2 = clamp(left - nx * gap, tx + 8, right)
    local y2 = clamp(anchorY - h / 2 - ny * gap, top, bottom)
    if not self.powerMeterSide then
        local preferredSide = anchorY < ty + th * 0.52 and 1 or -1
        local preferredY = preferredSide == 1 and y1 or y2
        local alternateY = preferredSide == 1 and y2 or y1
        local function edgeClearance(y)
            return math.min(math.abs(y - top), math.abs(bottom - y))
        end
        if edgeClearance(alternateY) > edgeClearance(preferredY) + 18 then
            preferredSide = -preferredSide
        end
        self.powerMeterSide = preferredSide
    end
    local x = self.powerMeterSide == 1 and x1 or x2
    local y = self.powerMeterSide == 1 and y1 or y2
    self:drawRect(x - 3, y - FONT_HGT_SMALL - 5, w + 6, h + FONT_HGT_SMALL + 9, 0.48, 0.02, 0.02, 0.02)
    self:drawRect(x, y, w, h, 0.82, 0.02, 0.02, 0.02)
    self:drawRect(x + 1, y + 1, (w - 2) * powerRatio, h - 2, 0.94, 0.95, 0.72, 0.22)
    self:drawRectBorder(x, y, w, h, 0.92, 0.78, 0.62, 0.32)
    self:drawTextCentre(tostring(math.floor(powerRatio * 100)) .. "%", x + w / 2, y - FONT_HGT_SMALL - 2, 0.95, 0.86, 0.46, 1, UIFont.Small)
end

function PPPoolWindow:drawCueSpinIndicator(cueUiX, cueUiY)
    local level = self:getBilliardsLevel()
    if level < 2 then
        return
    end
    local size = math.max(26, math.floor(self:getBallSpriteSize() * 0.92))
    local x = cueUiX + size * 1.15
    local y = cueUiY - size * 1.15
    local spinX, spinY = PP.clampCueSpin(self.cueSpinX or 0, self.cueSpinY or 0, level)
    self.cueSpinX = spinX
    self.cueSpinY = spinY
    self:drawRect(x - size / 2 - 3, y - size / 2 - 3, size + 6, size + 6, 0.55, 0.02, 0.02, 0.02)
    drawSprite(self, "ball_cue.png", x, y, size, 0.82)
    self:drawRect(x + spinX * size * 0.32 - 3, y - spinY * size * 0.32 - 3, 6, 6, 0.95, 0.25, 0.55, 1.00)
    self:drawTextCentre("spin", x, y + size / 2 + 2, 0.92, 0.84, 0.54, 0.95, UIFont.Small)
end

function PPPoolWindow:findTrajectoryHit(cue, dirX, dirY)
    return self:findRayHit(cue, dirX, dirY, self:getDisplayBalls(), cue.id, nil)
end

function PPPoolWindow:reflectTrajectoryAtWall(impact, dirX, dirY)
    local nx = impact and impact.normalX
    local ny = impact and impact.normalY
    if not nx or not ny then
        return normalize(dirX, dirY)
    end
    local dot = dirX * nx + dirY * ny
    local reflectX = dirX - 2 * dot * nx
    local reflectY = dirY - 2 * dot * ny
    return normalize(reflectX, reflectY)
end

function PPPoolWindow:findBounceTrajectoryHit(cue, dirX, dirY, wallHit)
    if not wallHit or wallHit.type ~= "wall" then
        return nil
    end
    local impact = { x = cue.x + dirX * wallHit.t, y = cue.y + dirY * wallHit.t, normalX = wallHit.normalX, normalY = wallHit.normalY }
    local reflectX, reflectY = self:reflectTrajectoryAtWall(impact, dirX, dirY)
    local origin = {
        x = impact.x + reflectX * 1.5,
        y = impact.y + reflectY * 1.5,
    }
    local hit = self:findRayHit(origin, reflectX, reflectY, self:getDisplayBalls(), cue.id, nil)
    if hit then
        hit.origin = origin
        hit.dirX = reflectX
        hit.dirY = reflectY
        hit.wallImpact = impact
    end
    return hit
end

function PPPoolWindow:findRayHit(origin, dirX, dirY, balls, movingId, ignoredId)
    local best = nil
    local physicsR = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
    local hitRadius = physicsR * 2

    for i = 1, #balls do
        local ball = balls[i]
        if ball.id ~= movingId and ball.id ~= ignoredId and not ball.pocketed then
            local relX = ball.x - origin.x
            local relY = ball.y - origin.y
            local along = relX * dirX + relY * dirY
            if along > 0.5 then
                local closestSq = relX * relX + relY * relY - along * along
                local radiusSq = hitRadius * hitRadius
                if closestSq <= radiusSq then
                    local offset = math.sqrt(math.max(0, radiusSq - closestSq))
                    local t = along - offset
                    if t > 0.5 and (not best or t < best.t) then
                        best = { type = "ball", t = t, ball = ball }
                    end
                end
            end
        end
    end

    local segments = PP.getCollisionSegments and PP.getCollisionSegments() or {}
    for i = 1, #segments do
        local seg = segments[i]
        local sx = seg.bx - seg.ax
        local sy = seg.by - seg.ay
        local det = dirX * sy - dirY * sx
        if math.abs(det) > 0.000001 then
            local ox = seg.ax - origin.x
            local oy = seg.ay - origin.y
            local t = (ox * sy - oy * sx) / det
            local u = (ox * dirY - oy * dirX) / det
            if t > 0.5 and u >= 0 and u <= 1 and (not best or t < best.t) then
                best = { type = "wall", t = t, normalX = seg.nx, normalY = seg.ny, edge = seg.id }
            end
        end
    end
    return best
end

function PPPoolWindow:drawIllegalTargetIndicator(ball, x, y, ballSize)
    if not ball or not PP.isLegalFirstHit or not self:getSettings().showIllegalTarget then
        return
    end
    if PP.isLegalFirstHit(self.state, ball.id, PP.currentPlayerName(self.state)) then
        return
    end
    drawCross(self, x, y, math.max(12, ballSize * 0.48), 1.00, 0.10, 0.06, 0.92)
end

function PPPoolWindow:drawRecursiveAimBranch(origin, dirX, dirY, balls, movingId, ignoredId, depth, energy, r, g, b)
    if depth > 5 or energy < 0.08 then
        return
    end
    local hit = self:findRayHit(origin, dirX, dirY, balls, movingId, ignoredId)
    local startX, startY = self:tableToUi(origin)
    local alpha = clamp(0.18 + energy * 0.44, 0.16, 0.72)
    local size = clamp(2 + energy * 4, 2, 6)

    if not hit then
        local physicsR = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
        local endPoint = {
            x = clamp(origin.x + dirX * PP.TABLE_W * energy, physicsR, PP.TABLE_W - physicsR),
            y = clamp(origin.y + dirY * PP.TABLE_W * energy, physicsR, PP.TABLE_H - physicsR),
        }
        local endX, endY = self:tableToUi(endPoint)
        drawDottedLine(self, startX, startY, endX, endY, r, g, b, size, 12)
        return
    end

    local impact = { x = origin.x + dirX * hit.t, y = origin.y + dirY * hit.t, normalX = hit.normalX, normalY = hit.normalY }
    local impactX, impactY = self:tableToUi(impact)
    drawLine(self, startX, startY, impactX, impactY, r, g, b, size, alpha, 2)

    if hit.type == "wall" then
        local reflectX, reflectY = self:reflectTrajectoryAtWall(impact, dirX, dirY)
        local nextOrigin = {
            x = impact.x + reflectX * 1.5,
            y = impact.y + reflectY * 1.5,
        }
        self:drawRecursiveAimBranch(nextOrigin, reflectX, reflectY, balls, movingId, nil, depth + 1, energy * 0.72, r, g, b)
        return
    end

    if hit.type == "ball" and hit.ball then
        local normalX, normalY = normalize(hit.ball.x - impact.x, hit.ball.y - impact.y)
        local contactDot = clamp(dirX * normalX + dirY * normalY, 0, 1)
        local tangentX = dirX - normalX * contactDot
        local tangentY = dirY - normalY * contactDot
        tangentX, tangentY = normalize(tangentX, tangentY)
        local targetEnergy = energy * contactDot * contactDot * 0.92
        local cueEnergy = energy * math.max(0, 1 - contactDot * contactDot) * 0.72
        local targetOrigin = {
            x = hit.ball.x + normalX * 1.5,
            y = hit.ball.y + normalY * 1.5,
        }
        self:drawRecursiveAimBranch(targetOrigin, normalX, normalY, balls, hit.ball.id, movingId, depth + 1, targetEnergy, 1.00, 0.74, 0.18)
        if cueEnergy > 0.08 and (tangentX ~= 0 or tangentY ~= 0) then
            local cueOrigin = {
                x = impact.x + tangentX * 1.5,
                y = impact.y + tangentY * 1.5,
            }
            self:drawRecursiveAimBranch(cueOrigin, tangentX, tangentY, balls, movingId, hit.ball.id, depth + 1, cueEnergy, 0.38, 0.82, 1.00)
        end
    end
end

function PPPoolWindow:drawRecursiveAimPreview(cue, dirX, dirY, previewPower)
    if not self:isAimCheatEnabled() then
        return
    end
    if not PP.simulateShot or not self.state then
        local energy = clamp((previewPower or self.pendingPower or 300) / PP.MAX_POWER, 0.16, 1)
        self:drawRecursiveAimBranch(cue, dirX, dirY, self:getDisplayBalls(), cue.id, nil, 1, energy, 0.98, 0.98, 0.82)
        return
    end

    local angle = PP.atan2(dirY, dirX)
    local power = clamp(previewPower or self.pendingPower or 300, 30, PP.MAX_POWER)
    local spinX, spinY = PP.clampCueSpin(self.cueSpinX or 0, self.cueSpinY or 0, self:getBilliardsLevel())
    local key = tostring(self.state.shotNumber or 0) .. ":" .. tostring(math.floor(angle * 80)) .. ":" .. tostring(math.floor(power / 28)) .. ":" .. tostring(math.floor(spinX * 6)) .. ":" .. tostring(math.floor(spinY * 6))
    if not self.cheatPreviewCache or self.cheatPreviewCache.key ~= key then
        local now = getTimestampMs()
        if self.cheatPreviewCache and self.cheatPreviewCache.lines and now - (self.lastCheatPreviewBuildMs or 0) < 150 then
            key = self.cheatPreviewCache.key
        else
            local previewState = PP.copyTable(self.state)
            previewState.aim = nil
            local _, result = PP.simulateShot(previewState, angle, power, {
                skillLevel = self:getBilliardsLevel(),
                spinX = spinX,
                spinY = spinY,
                preview = true,
                maxTicks = 560,
            })
            self.cheatPreviewCache = { key = key, result = result, lines = self:buildCheatPreviewLines(result) }
            self.lastCheatPreviewBuildMs = now
        end
    end

    local result = self.cheatPreviewCache and self.cheatPreviewCache.result or nil
    local lines = self.cheatPreviewCache and self.cheatPreviewCache.lines or nil
    if not result or not lines then
        return
    end

    for i = 1, #(lines.trails or {}) do
        local trail = lines.trails[i]
        drawPoolLine(self, trail.x1, trail.y1, trail.x2, trail.y2, trail.options)
    end

    local ballSize = self:getBallSpriteSize()
    for i = 1, #(lines.ghosts or {}) do
        local ghost = lines.ghosts[i]
        drawSprite(self, ghost.sprite, ghost.x, ghost.y, ballSize, ghost.alpha)
    end
    if lines.firstHit then
        drawSprite(self, "ball_cue.png", lines.firstHit.x, lines.firstHit.y, ballSize, 0.18)
        self:drawIllegalTargetIndicator({ id = lines.firstHit.id }, lines.firstHit.x, lines.firstHit.y, ballSize)
    end
end

function PPPoolWindow:buildCheatPreviewLines(result)
    local output = { trails = {}, ghosts = {}, firstHit = nil }
    if not result or not result.frames then
        return output
    end

    local firstById = {}
    local lastById = {}
    local movedById = {}
    for frameIndex = 1, #result.frames do
        local frame = result.frames[frameIndex]
        for i = 1, #frame do
            local ball = frame[i]
            if not ball.pocketed then
                local ux, uy = self:tableToUi(ball)
                local last = lastById[ball.id]
                if not firstById[ball.id] then
                    firstById[ball.id] = { x = ux, y = uy, ball = ball }
                end
                if last and frameIndex % 3 == 0 then
                    local movedDx = ux - (firstById[ball.id].x or ux)
                    local movedDy = uy - (firstById[ball.id].y or uy)
                    if movedDx * movedDx + movedDy * movedDy > 4 then
                        movedById[ball.id] = true
                        local c = ballColor(ball)
                        if ball.id == "cue" then
                            c = { r = 0.58, g = 0.86, b = 1.00 }
                        end
                        output.trails[#output.trails + 1] = {
                            x1 = last.x,
                            y1 = last.y,
                            x2 = ux,
                            y2 = uy,
                            options = {
                                r = c.r,
                                g = c.g,
                                b = c.b,
                                alpha = ball.id == "cue" and 0.60 or 0.48,
                                pointSize = ball.id == "cue" and 4 or 3,
                                pointSpacing = ball.id == "cue" and 18 or 20,
                            },
                        }
                    end
                end
                lastById[ball.id] = { x = ux, y = uy }
            else
                lastById[ball.id] = nil
            end
        end
    end

    for id, last in pairs(lastById) do
        if movedById[id] then
            local sprite = id == "cue" and "ball_cue.png" or ("ball_" .. tostring(id) .. ".png")
            output.ghosts[#output.ghosts + 1] = { sprite = sprite, x = last.x, y = last.y, alpha = id == "cue" and 0.20 or 0.26 }
        end
    end
    if result.firstHit and result.firstHitX and result.firstHitY then
        local fx, fy = self:tableToUi({ x = result.firstHitX, y = result.firstHitY })
        output.firstHit = { id = result.firstHit, x = fx, y = fy }
    end
    return output
end

function PPPoolWindow:drawTrajectoryPreview(cueUiX, cueUiY, tableDirX, tableDirY, tx, ty, tw, th, previewPower, allowCheat)
    local cue = PP.findBall({ balls = self:getDisplayBalls() }, "cue")
    if not cue then
        return
    end

    local dirX, dirY = normalize(tableDirX or 0, tableDirY or 0)
    if dirX == 0 and dirY == 0 then
        return
    end
    local power = clamp(previewPower or self.pendingPower or 300, 30, PP.MAX_POWER)
    if allowCheat then
        self:drawRecursiveAimPreview(cue, dirX, dirY, power)
    end
    local powerRatio = math.max(0.10, math.min(1, power / PP.MAX_POWER))
    local profile = self:getSkillProfile()
    local skillLevel = profile.level or 0
    local previewAlpha = profile.previewAlpha or 0.5
    local balls = self:getDisplayBalls()
    local hit = self:findRayHit(cue, dirX, dirY, balls, cue.id, nil)

    if not hit then
        local fallbackDistance = math.max(PP.TABLE_W or 900, PP.TABLE_H or 380)
        local endX, endY = self:tableToUi({ x = cue.x + dirX * fallbackDistance, y = cue.y + dirY * fallbackDistance })
        drawPoolLine(self, cueUiX, cueUiY, endX, endY, { r = 0.94, g = 0.94, b = 0.86, pointSize = 4, pointSpacing = 10, alpha = previewAlpha })
        if skillLevel >= 8 then
            drawSprite(self, "ball_cue.png", endX, endY, self:getBallSpriteSize(), 0.18)
        end
        return endX, endY
    end

    local impact = { x = cue.x + dirX * hit.t, y = cue.y + dirY * hit.t, normalX = hit.normalX, normalY = hit.normalY }
    local impactUiX, impactUiY = self:tableToUi(impact)
    drawPoolLine(self, cueUiX, cueUiY, impactUiX, impactUiY, { r = 0.96, g = 0.96, b = 0.88, pointSize = 4, pointSpacing = 9, alpha = previewAlpha })
    local ballSize = self:getBallSpriteSize()
    drawSprite(self, "ball_cue.png", impactUiX, impactUiY, ballSize, 0.18 + previewAlpha * 0.14)
    self:drawRect(impactUiX - 3, impactUiY - 3, 6, 6, 0.86, 1.00, 0.88, 0.48)

    local function drawVelocity(startPoint, vecX, vecY, energy, baseSize, maxPx)
        local nx, ny, speed = normalize(vecX or 0, vecY or 0)
        if speed <= 0 then
            return nil
        end
        local vectorBudgetPx = (maxPx or (24 + 64 * powerRatio)) * (profile.previewVectorScale or 1)
        local length = math.min(vectorBudgetPx, 18 + speed * 72) / math.max(0.001, self:getTableScale())
        local endPoint = { x = startPoint.x + nx * length, y = startPoint.y + ny * length }
        local sx, sy = self:tableToUi(startPoint)
        local ex, ey = self:tableToUi(endPoint)
        drawPoolLine(self, sx, sy, ex, ey, previewVelocityLineStyle(energy or powerRatio, baseSize or 5))
        return endPoint
    end

    if hit.type == "ball" and hit.ball then
        local target = hit.ball
        if target then
            self:drawIllegalTargetIndicator(target, impactUiX, impactUiY, ballSize)
            local normalX, normalY = normalize(target.x - impact.x, target.y - impact.y)
            local transfer = clamp(dirX * normalX + dirY * normalY, 0, 1)
            local tangentX = dirX - normalX * transfer
            local tangentY = dirY - normalY * transfer
            local targetEnergy = powerRatio * transfer * transfer
            local cueEnergy = powerRatio * math.max(0, 1 - transfer * transfer)
            local targetStart = { x = target.x, y = target.y }
            drawVelocity(targetStart, normalX * targetEnergy, normalY * targetEnergy, targetEnergy, 5)
            if skillLevel >= 10 and targetEnergy > 0 then
                local nx, ny, speed = normalize(normalX, normalY)
                if speed > 0 then
                    local start = { x = targetStart.x + nx * 28, y = targetStart.y + ny * 28 }
                    drawVelocity(start, normalX * targetEnergy, normalY * targetEnergy, targetEnergy * 0.7, 4, 42)
                end
            end
            local cueTangentX, cueTangentY = normalize(tangentX, tangentY)
            if cueEnergy > 0.02 and (cueTangentX ~= 0 or cueTangentY ~= 0) then
                drawVelocity(impact, cueTangentX * cueEnergy, cueTangentY * cueEnergy, cueEnergy, 5)
            else
                self:drawTextCentre("direct", impactUiX, impactUiY - 28, 0.82, 0.96, 1, 0.85, UIFont.Small)
            end
        end
    elseif hit.type == "wall" then
        local reflectX, reflectY = self:reflectTrajectoryAtWall(impact, dirX, dirY)
        drawVelocity(impact, reflectX * powerRatio, reflectY * powerRatio, powerRatio, 4, 54)
        local bounceHit = self:findBounceTrajectoryHit(cue, dirX, dirY, hit)
        local bouncePreviewDistance = 58 / math.max(0.001, self:getTableScale())
        if bounceHit and bounceHit.type == "ball" and bounceHit.ball and bounceHit.t <= bouncePreviewDistance then
            local ballImpact = {
                x = (bounceHit.origin and bounceHit.origin.x or impact.x) + (bounceHit.dirX or reflectX) * bounceHit.t,
                y = (bounceHit.origin and bounceHit.origin.y or impact.y) + (bounceHit.dirY or reflectY) * bounceHit.t,
            }
            local bx, by = self:tableToUi(ballImpact)
            drawSprite(self, "ball_cue.png", bx, by, ballSize, 0.13 + previewAlpha * 0.10)
            self:drawIllegalTargetIndicator(bounceHit.ball, bx, by, ballSize)
        end
    end
    return impactUiX, impactUiY
end

function PPPoolWindow:updateWinnerButtons()
    local visible = self.state and self.state.winner and not self:isAnimating() and true or false
    if not visible then
        self.winnerResetRect = nil
        self.winnerCloseRect = nil
        return
    end

    local panelX, panelY, panelW, panelH, cx = self:getWinnerPanelRect()
    local buttonH = 30
    local resetW = 132
    local closeW = 96
    local gap = 14
    local totalW = resetW + closeW + gap
    local y = panelY + panelH - buttonH - 16
    self.winnerResetRect = { x = cx - totalW / 2, y = y, w = resetW, h = buttonH }
    self.winnerCloseRect = { x = cx - totalW / 2 + resetW + gap, y = y, w = closeW, h = buttonH }
end

function PPPoolWindow:drawWinnerButton(rect, text, primary)
    if not rect then
        return
    end
    if primary then
        self:drawRect(rect.x, rect.y, rect.w, rect.h, 0.92, 0.30, 0.18, 0.04)
        self:drawRectBorder(rect.x, rect.y, rect.w, rect.h, 1.00, 1.00, 0.74, 0.30)
        self:drawRectBorder(rect.x + 2, rect.y + 2, rect.w - 4, rect.h - 4, 0.45, 0.98, 0.88, 0.52)
        self:drawTextCentre(text, rect.x + rect.w / 2, rect.y + 7, 1.00, 0.94, 0.76, 1, UIFont.Small)
    else
        self:drawRect(rect.x, rect.y, rect.w, rect.h, 0.72, 0.08, 0.07, 0.055)
        self:drawRectBorder(rect.x, rect.y, rect.w, rect.h, 0.82, 0.56, 0.44, 0.26)
        self:drawTextCentre(text, rect.x + rect.w / 2, rect.y + 7, 0.86, 0.82, 0.70, 1, UIFont.Small)
    end
end

function PPPoolWindow:drawWinnerOverlay(tx, ty, tw, th)
    if not self.state or not self.state.winner then
        return
    end

    self:updateWinnerButtons()
    local gx, gy, gw, gh = self:getGamePaneRect()
    self:drawRect(gx, gy, gw, gh, 0.70, 0.02, 0.02, 0.02)

    local x, y, panelW, panelH, cx = self:getWinnerPanelRect()
    self:drawRect(x + 6, y + 8, panelW, panelH, 0.45, 0, 0, 0)
    self:drawRect(x, y, panelW, panelH, 0.96, 0.09, 0.07, 0.04)
    self:drawRectBorder(x, y, panelW, panelH, 1, 0.88, 0.68, 0.33)
    self:drawRectBorder(x + 3, y + 3, panelW - 6, panelH - 6, 0.65, 0.32, 0.22, 0.12)

    local winner = tostring(self.state.winner)
    local localWin = winner == self.playerName
    local title = localWin and "YOU WON" or "GAME OVER"
    local iconName = localWin and "victory_icon.png" or "defeat_icon.png"
    local reason = tostring(self.state.winReason or self.state.message or (winner .. " won."))
    local iconY = y + 38
    local titleY = y + 78
    local reasonY = y + 112
    local playersY = math.max(y + 164, y + panelH - 74)
    drawSprite(self, iconName, cx, iconY, 64, 1)
    self:drawTextCentre(title, cx, titleY, 1.00, localWin and 0.86 or 0.42, localWin and 0.36 or 0.32, 1, UIFont.Large)
    drawWrappedTextCentre(self, reason, cx, reasonY, panelW - 64, UIFont.Medium, 0.94, 0.92, 0.80, 1, 2)

    local players = table.concat(self.state.players or {}, "  vs  ")
    self:drawTextCentre(fitText(players, UIFont.Small, panelW - 64), cx, playersY, 0.68, 0.82, 0.72, 1, UIFont.Small)
    self:drawWinnerButton(self.winnerResetRect, "Reset Rack", true)
    self:drawWinnerButton(self.winnerCloseRect, "Close", false)
end

function PPPoolWindow:getModePanelRect()
    local gx, gy, gw, gh = self:getGamePaneRect()
    local panelW = math.min(620, math.max(360, gw - 80))
    local panelH = math.min(330, math.max(250, gh - 80))
    panelW = math.min(panelW, math.max(1, gw - 32))
    panelH = math.min(panelH, math.max(1, gh - 32))
    local x = clamp(gx + gw / 2 - panelW / 2, gx + 16, gx + gw - panelW - 16)
    local y = clamp(gy + gh / 2 - panelH / 2, gy + 16, gy + gh - panelH - 16)
    return x, y, panelW, panelH, gx + gw / 2
end

function PPPoolWindow:drawModeSelectOverlay()
    if not self.state or self.state.modeSelected then
        self.modeRects = nil
        return
    end

    local gx, gy, gw, gh = self:getGamePaneRect()
    self:drawRect(gx, gy, gw, gh, 0.76, 0.02, 0.02, 0.02)

    local x, y, panelW, panelH, cx = self:getModePanelRect()
    self:drawRect(x + 6, y + 8, panelW, panelH, 0.45, 0, 0, 0)
    self:drawRect(x, y, panelW, panelH, 0.97, 0.08, 0.06, 0.035)
    self:drawRectBorder(x, y, panelW, panelH, 1, 0.88, 0.68, 0.33)
    self:drawRectBorder(x + 3, y + 3, panelW - 6, panelH - 6, 0.65, 0.32, 0.22, 0.12)
    self:drawTextCentre("CHOOSE GAME", cx, y + 22, 1.00, 0.86, 0.46, 1, UIFont.Medium)
    self:drawTextCentre("Choose a pool mode", cx, y + 50, 0.72, 0.86, 0.74, 1, UIFont.Small)

    local modes = PP.GAME_MODES or {}
    local gap = 18
    local buttonW = math.floor((panelW - 54 - gap * (#modes - 1)) / math.max(1, #modes))
    local buttonH = math.min(170, panelH - 105)
    local buttonY = y + 86
    self.modeRects = {}
    for i = 1, #modes do
        local mode = modes[i]
        local bx = x + 27 + (i - 1) * (buttonW + gap)
        local selected = self.state.modeId == mode.id
        self:drawRect(bx, buttonY, buttonW, buttonH, 0.86, selected and 0.24 or 0.10, selected and 0.14 or 0.08, selected and 0.04 or 0.055)
        self:drawRectBorder(bx, buttonY, buttonW, buttonH, 0.95, selected and 1.00 or 0.55, selected and 0.76 or 0.38, selected and 0.34 or 0.20)
        drawSprite(self, mode.icon, bx + buttonW / 2, buttonY + 52, 82, 1)
        drawWrappedTextCentre(self, mode.description, bx + buttonW / 2, buttonY + 105, buttonW - 28, UIFont.Small, 0.86, 0.84, 0.76, 0.95, 3)
        self.modeRects[#self.modeRects + 1] = { x = bx, y = buttonY, w = buttonW, h = buttonH, modeId = mode.id }
    end
end

function PPPoolWindow:drawPlayerPanels(x, y, w)
    local state = self.state
    if not state then
        return 0
    end
    local panelH = FONT_HGT_SMALL + 18
    local gap = 7
    for i = 1, 2 do
        local py = y + (i - 1) * (panelH + gap)
        local name = state.players and state.players[i] or "Open seat"
        local phase = PP.phaseForState(state)
        local active = state.currentPlayer == i and (phase == PP.PHASE_AIMING or phase == PP.PHASE_TURN_READY or phase == PP.PHASE_READY) and not state.winner
        self:drawRect(x, py, w, panelH, 0.78, active and 0.23 or 0.07, active and 0.15 or 0.07, active and 0.05 or 0.06)
        self:drawRectBorder(x, py, w, panelH, 0.90, active and 1.00 or 0.45, active and 0.74 or 0.34, active and 0.32 or 0.22)
        local label = active and "SHOOTING" or (i == 1 and "PLAYER 1" or "PLAYER 2")
        local textY = py + math.floor((panelH - FONT_HGT_SMALL) / 2)
        local nameX = x + 102
        local nameW = math.max(24, w - (nameX - x) - 8)
        self:drawText(label, x + 10, textY, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawText(fitText(name, UIFont.Small, nameW), nameX, textY, 0.94, 0.92, 0.82, 1, UIFont.Small)
    end
    local totalH = panelH * 2 + gap
    if state.spectators and #state.spectators > 0 then
        self:drawText(fitText("Watching: " .. table.concat(state.spectators, ", "), UIFont.Small, w - 16), x + 8, y + totalH + 5, 0.67, 0.82, 0.92, 1, UIFont.Small)
        totalH = totalH + FONT_HGT_SMALL + 8
    end
    return totalH
end

function PPPoolWindow:drawEventHistory(x, y, w, h)
    local events = self.state and self.state.events
    self.logRect = nil
    if not events or #events == 0 or h < FONT_HGT_SMALL * 4 then
        return
    end
    local rowH = FONT_HGT_SMALL + 7
    local logH = h - FONT_HGT_SMALL - 8
    local maxRows = math.min(#events, math.max(1, math.floor((logH - 12) / rowH)))
    local maxScroll = math.max(0, #events - maxRows)
    self.logScroll = clamp(self.logScroll or 0, 0, maxScroll)
    self:drawText("Game Log", x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local logY = y + FONT_HGT_SMALL + 8
    self.logRect = { x = x, y = logY, w = w, h = logH, maxScroll = maxScroll }
    self:drawRect(x, logY, w, logH, 0.42, 0.02, 0.02, 0.02)
    self:drawRectBorder(x, logY, w, logH, 0.75, 0.38, 0.30, 0.18)
    local endIndex = #events - self.logScroll
    local startIndex = math.max(1, endIndex - maxRows + 1)
    for row = 1, maxRows do
        local event = events[startIndex + row - 1]
        if not event then
            break
        end
        local r, g, b = 0.78, 0.84, 0.76
        if event.kind == "foul" then
            r, g, b = 1.00, 0.48, 0.34
        elseif event.kind == "score" or event.kind == "win" then
            r, g, b = 0.96, 0.82, 0.35
        elseif event.kind == "join" or event.kind == "watch" then
            r, g, b = 0.55, 0.82, 1.00
        end
        self:drawText(fitText(event.text, UIFont.Small, w - 20), x + 8, logY + 8 + (row - 1) * rowH, r, g, b, 0.96, UIFont.Small)
    end
    if maxScroll > 0 then
        local trackX = x + w - 7
        local trackY = logY + 6
        local trackH = logH - 12
        local thumbH = math.max(18, trackH * maxRows / #events)
        local thumbY = trackY + (trackH - thumbH) * (maxScroll - self.logScroll) / maxScroll
        self:drawRect(trackX, trackY, 3, trackH, 0.55, 0.20, 0.16, 0.10)
        self:drawRect(trackX - 1, thumbY, 5, thumbH, 0.85, 0.78, 0.62, 0.32)
    end
end

function PPPoolWindow:drawShotCallControls(x, y, w)
    self.callRects = nil
    if not self:canEditShotCall() then
        return 0
    end
    local call = self:getActiveShotCall()
    local panelH = 80
    local buttonH = 24
    self:drawText("Call", x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local py = y + FONT_HGT_SMALL + 6
    self:drawRect(x, py, w, panelH - FONT_HGT_SMALL - 6, 0.50, 0.02, 0.02, 0.018)
    self:drawRectBorder(x, py, w, panelH - FONT_HGT_SMALL - 6, 0.72, 0.42, 0.34, 0.20)
    local label = PP.shotCallLabel and PP.shotCallLabel(call) or "-"
    self:drawText(fitText(label, UIFont.Small, w - 16), x + 8, py + 6, 0.92, 0.88, 0.72, 1, UIFont.Small)
    local gap = 6
    local bw = math.floor((w - 16 - gap * 2) / 3)
    local by = py + 30
    self.callRects = {
        { x = x + 8, y = by, w = bw, h = buttonH, action = "ball" },
        { x = x + 8 + bw + gap, y = by, w = bw, h = buttonH, action = "pocket" },
        { x = x + 8 + (bw + gap) * 2, y = by, w = bw, h = buttonH, action = "safety" },
    }
    local labels = { "Ball", "Pocket", "Safety" }
    for i = 1, #self.callRects do
        local r = self.callRects[i]
        local active = call and call.safety and r.action == "safety"
        self:drawRect(r.x, r.y, r.w, r.h, 0.68, active and 0.21 or 0.06, active and 0.14 or 0.04, active and 0.035 or 0.025)
        self:drawRectBorder(r.x, r.y, r.w, r.h, 0.82, active and 0.95 or 0.55, active and 0.76 or 0.40, active and 0.36 or 0.22)
        self:drawTextCentre(fitText(labels[i], UIFont.Small, r.w - 6), r.x + r.w / 2, r.y + math.floor((buttonH - FONT_HGT_SMALL) / 2), 0.94, 0.88, 0.68, 1, UIFont.Small)
    end
    return panelH + 8
end

function PPPoolWindow:drawDebugPanel(x, y, w)
    if not isDebugClient() then
        self.debugRects = nil
        return 0
    end
    local panelH = 74
    self:drawText("Debug", x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local py = y + FONT_HGT_SMALL + 7
    self:drawRect(x, py, w, panelH - FONT_HGT_SMALL - 7, 0.50, 0.02, 0.02, 0.018)
    self:drawRectBorder(x, py, w, panelH - FONT_HGT_SMALL - 7, 0.72, 0.42, 0.34, 0.20)
    local buttonH = 28
    local bx = x + 8
    local by = py + 7
    local bw = w - 16
    self.debugRects = {
        { x = bx, y = by, w = bw, h = buttonH, action = PPPoolWindow.onDebugMyTurn },
    }
    self:drawRect(bx, by, bw, buttonH, 0.64, 0.05, 0.04, 0.025)
    self:drawRectBorder(bx, by, bw, buttonH, 0.84, 0.62, 0.44, 0.26)
    self:drawTextCentre("Force My Turn", bx + bw / 2, by + math.floor((buttonH - FONT_HGT_SMALL) / 2), 0.94, 0.88, 0.68, 1, UIFont.Small)
    return panelH + 8
end

function PPPoolWindow:drawTurnBanner(tx, ty, tw)
    if self.state and self.state.winner then
        return
    end
    if not self.bannerText or not self.bannerUntil or getTimestampMs() > self.bannerUntil then
        return
    end
    local w = math.min(520, tw - 60)
    local x = tx + tw / 2 - w / 2
    local y = ty + 16
    self:drawRect(x + 4, y + 5, w, 34, 0.40, 0, 0, 0)
    self:drawRect(x, y, w, 34, 0.86, 0.08, 0.05, 0.03)
    self:drawRectBorder(x, y, w, 34, 0.90, 0.90, 0.68, 0.30)
    self:drawTextCentre(tostring(self.bannerText), tx + tw / 2, y + 8, 0.98, 0.92, 0.70, 1, UIFont.Small)
end

function PPPoolWindow:getHint()
    local state = self.state
    if not state then
        return "Waiting for pool table state..."
    end
    if state.winner then
        return "Winner: " .. tostring(state.winner) .. ". Play Again to rack."
    end
    if not state.modeSelected then
        return self:canChooseMode() and "Choose 8-Ball or 9-Ball." or "Waiting for game mode."
    end
    if state.shotInMotion then
        return state.message or "Shot in motion..."
    end
    if self:isAnimating() then
        return "Shot in motion..."
    end
    if #state.players < 2 then
        return "Choose an AI opponent or wait for another player."
    end
    if self:isSpectator() then
        return "Watching this table."
    end
    if self:isPlacingCue() then
        return "Ball in hand. Click a clear spot."
    end
    if self:isMyTurn() then
        return "Your turn. Aim, set power, shoot."
    end
    return state.message or ""
end

function PPPoolWindow:drawSidebar(x, y, w, h)
    self:drawRect(x, y, w, h, 0.90, 0.04, 0.035, 0.03)
    self:drawRectBorder(x, y, w, h, 0.95, 0.50, 0.38, 0.18)
    local bottom = y + h - 14
    local cursorY = y + 14

    self.debugRects = nil
    self.aiRects = nil
    self.callRects = nil
    self.resetRackRect = nil
    self.resetRackReason = nil

    self:drawText("Playable Pool", x + 14, cursorY, 0.96, 0.86, 0.58, 1, UIFont.Small)
    cursorY = cursorY + FONT_HGT_SMALL + 4
    self:drawText(tostring(self.state and self.state.mode or PP.GAME_MODE), x + 14, cursorY, 0.68, 0.82, 0.72, 1, UIFont.Small)
    cursorY = cursorY + FONT_HGT_SMALL + 12

    cursorY = cursorY + self:drawPlayerPanels(x + 14, cursorY, w - 28) + 14

    local ai = nil
    local currentDifficulty = nil
    if self.state and PP.getStateAI then
        ai, currentDifficulty = PP.getStateAI(self.state)
    end
    if self.state and not self.state.winner and (ai or #(self.state.players or {}) < 2) then
        local order = PP.AI_DIFFICULTY_ORDER or { "easy", "medium", "hard" }
        local gap = 7
        local bw = math.max(64, math.floor((w - 28 - gap * (#order - 1)) / math.max(1, #order)))
        local buttonH = 28
        self.aiRects = {}
        self:drawText(fitText("To play solo, select AI difficulty", UIFont.Small, w - 28), x + 14, cursorY, 0.88, 0.84, 0.70, 1, UIFont.Small)
        cursorY = cursorY + FONT_HGT_SMALL + 6
        for i = 1, #order do
            local difficulty = PP.getAIDifficulty(order[i])
            local bx = x + 14 + (i - 1) * (bw + gap)
            local selected = currentDifficulty and currentDifficulty.id == difficulty.id
            self:drawRect(bx, cursorY, bw, buttonH, 0.70, selected and 0.25 or 0.08, selected and 0.16 or 0.055, selected and 0.04 or 0.025)
            self:drawRectBorder(bx, cursorY, bw, buttonH, 0.88, selected and 1.00 or 0.70, selected and 0.76 or 0.48, selected and 0.30 or 0.22)
            self:drawTextCentre(fitText(difficulty.name, UIFont.Small, bw - 8), bx + bw / 2, cursorY + math.floor((buttonH - FONT_HGT_SMALL) / 2), 0.96, 0.88, 0.62, 1, UIFont.Small)
            self.aiRects[#self.aiRects + 1] = { x = bx, y = cursorY, w = bw, h = buttonH, difficulty = difficulty.id }
        end
        cursorY = cursorY + buttonH + 7
        if ai then
            local removeW = w - 28
            local bx = x + 14
            self:drawRect(bx, cursorY, removeW, buttonH, 0.68, 0.18, 0.035, 0.025)
            self:drawRectBorder(bx, cursorY, removeW, buttonH, 0.85, 0.82, 0.38, 0.28)
            self:drawTextCentre("Remove Bot", bx + removeW / 2, cursorY + math.floor((buttonH - FONT_HGT_SMALL) / 2), 1.00, 0.74, 0.56, 1, UIFont.Small)
            self.aiRects[#self.aiRects + 1] = { x = bx, y = cursorY, w = removeW, h = buttonH, remove = true }
            cursorY = cursorY + buttonH + 7
        else
            cursorY = cursorY + 5
        end
    end

    if self.state and not self.state.winner then
        local resetOk = false
        local resetReason = nil
        if PP.canResetRack then
            resetOk, resetReason = PP.canResetRack(self.state, self.playerName, { resolving = self:isAnimating() })
        end
        local buttonH = 28
        local bx = x + 14
        local bw = w - 28
        local alpha = resetOk and 0.72 or 0.38
        self:drawRect(bx, cursorY, bw, buttonH, alpha, resetOk and 0.12 or 0.08, resetOk and 0.10 or 0.075, resetOk and 0.055 or 0.05)
        self:drawRectBorder(bx, cursorY, bw, buttonH, resetOk and 0.86 or 0.48, resetOk and 0.82 or 0.46, resetOk and 0.58 or 0.42, resetOk and 0.24 or 0.18)
        self:drawTextCentre(fitText("Reset Rack", UIFont.Small, bw - 8), bx + bw / 2, cursorY + math.floor((buttonH - FONT_HGT_SMALL) / 2), resetOk and 0.96 or 0.58, resetOk and 0.88 or 0.56, resetOk and 0.62 or 0.50, 1, UIFont.Small)
        if resetOk then
            self.resetRackRect = { x = bx, y = cursorY, w = bw, h = buttonH }
        else
            self.resetRackReason = resetReason
        end
        cursorY = cursorY + buttonH + 12
    end

    local statusY = cursorY
    local turn = PP.currentPlayerName(self.state) or "-"
    local onText = PP.onBallLabel and PP.onBallLabel(self.state) or "-"
    local billiardsLevel = self:getBilliardsLevel()
    self:drawText("Status", x + 14, statusY, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(fitText(self.state and self.state.status or "-", UIFont.Small, w - 96), x + 82, statusY, 0.94, 0.92, 0.82, 1, UIFont.Small)
    self:drawText("Turn", x + 14, statusY + FONT_HGT_SMALL + 6, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(fitText(turn, UIFont.Small, w - 96), x + 82, statusY + FONT_HGT_SMALL + 6, 0.94, 0.92, 0.82, 1, UIFont.Small)
    self:drawText("On", x + 14, statusY + (FONT_HGT_SMALL + 6) * 2, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(onText, x + 82, statusY + (FONT_HGT_SMALL + 6) * 2, 0.94, 0.92, 0.82, 1, UIFont.Small)
    self:drawText("Skill", x + 14, statusY + (FONT_HGT_SMALL + 6) * 3, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(tostring(billiardsLevel), x + 82, statusY + (FONT_HGT_SMALL + 6) * 3, 0.94, 0.92, 0.82, 1, UIFont.Small)

    cursorY = statusY + (FONT_HGT_SMALL + 6) * 4 + 12
    cursorY = cursorY + self:drawShotCallControls(x + 14, cursorY, w - 28)

    local hintY = cursorY + 4
    self:drawText("Now", x + 14, hintY, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(fitText(self:getHint(), UIFont.Small, w - 28), x + 14, hintY + FONT_HGT_SMALL + 4, 0.90, 0.88, 0.78, 1, UIFont.Small)

    local helpY = hintY + (FONT_HGT_SMALL + 4) * 3 + 8
    local lineH = FONT_HGT_SMALL + 4
    if helpY + lineH <= bottom then
        self:drawText("Controls", x + 14, helpY, 0.96, 0.78, 0.40, 1, UIFont.Small)
        local controls = {
            "Hold right-click: aim",
            "Wheel or Up/Down: power",
            "Left/Right: fine angle",
            "Ctrl + arrows/wheel: spin",
            "Left-click or Space: shoot",
        }
        for i = 1, #controls do
            local cy = helpY + lineH * i
            if cy + FONT_HGT_SMALL > bottom then
                break
            end
            self:drawText(fitText(controls[i], UIFont.Small, w - 28), x + 14, cy, 0.82, 0.82, 0.74, 1, UIFont.Small)
        end
    end

    local logY = helpY + lineH * 7 + 4
    if isDebugClient() and logY + 90 <= bottom then
        logY = logY + self:drawDebugPanel(x + 14, logY, w - 28)
    end
    if logY + FONT_HGT_SMALL * 4 <= bottom then
        self:drawEventHistory(x + 14, logY, w - 28, bottom - logY)
    end
end

function PPPoolWindow:getSettingsButtonRect()
    local size = math.max(16, self:titleBarHeight() - 2)
    return self.width - size - 28, 1, size, size
end

function PPPoolWindow:drawSettingsButton()
    local x, y, w, h = self:getSettingsButtonRect()
    self.settingsButtonRect = { x = x, y = y, w = w, h = h }
    self:drawRect(x, y, w, h, self.settingsOpen and 0.82 or 0.46, 0.03, 0.03, 0.03)
    self:drawRectBorder(x, y, w, h, 0.85, 0.70, 0.55, 0.32)
    local cx = x + w / 2
    local cy = y + h / 2
    self:drawRect(cx - 1, y + 3, 2, h - 6, 0.90, 0.80, 0.62, 0.45)
    self:drawRect(x + 3, cy - 1, w - 6, 2, 0.90, 0.80, 0.62, 0.45)
    self:drawRect(cx - 3, cy - 3, 6, 6, 0.95, 0.90, 0.78, 0.56)
end

function PPPoolWindow:drawSettingsMenu()
    if not self.settingsOpen then
        self.settingsRects = nil
        return
    end
    local button = self.settingsButtonRect or { x = self.width - 48, y = 1, w = 18, h = 18 }
    local menuW = self:canUseAimCheat() and 230 or 190
    local menuX = clamp(button.x + button.w - menuW, 4, self.width - menuW - 4)
    local menuY = self:titleBarHeight() + 4
    local rows = {
        { key = "showIllegalTarget", label = "Show bad-target X", visible = true },
        { key = "aimCheat", label = "Aim Debug", visible = self:canUseAimCheat() },
        { key = "debugGeometry", label = "Geometry Overlay", visible = isDebugClient() },
        { key = "calibrateGeometry", label = "Edit Geometry", visible = isDebugClient() },
    }
    local visibleRows = {}
    for i = 1, #rows do
        if rows[i].visible then
            visibleRows[#visibleRows + 1] = rows[i]
        end
    end
    local rowH = 26
    local menuH = 12 + rowH * #visibleRows
    self.settingsMenuRect = { x = menuX, y = menuY, w = menuW, h = menuH }
    self.settingsRects = {}
    self:drawRect(menuX, menuY, menuW, menuH, 0.95, 0.03, 0.025, 0.018)
    self:drawRectBorder(menuX, menuY, menuW, menuH, 0.95, 0.70, 0.52, 0.24)
    local settings = self:getSettings()
    for i = 1, #visibleRows do
        local row = visibleRows[i]
        local y = menuY + 6 + (i - 1) * rowH
        local checked = settings[row.key] == true
        self:drawRect(menuX + 8, y + 5, 14, 14, 0.72, 0.02, 0.02, 0.02)
        self:drawRectBorder(menuX + 8, y + 5, 14, 14, 0.88, 0.66, 0.50, 0.28)
        if checked then
            drawLine(self, menuX + 10, y + 12, menuX + 14, y + 17, 0.44, 1.00, 0.48, 3, 0.95, 2)
            drawLine(self, menuX + 14, y + 17, menuX + 21, y + 8, 0.44, 1.00, 0.48, 3, 0.95, 2)
        end
        self:drawText(row.label, menuX + 30, y + 3, 0.92, 0.86, 0.70, 1, UIFont.Small)
        self.settingsRects[#self.settingsRects + 1] = { x = menuX, y = y, w = menuW, h = rowH, key = row.key }
    end
end

function PPPoolWindow:handleSettingsClick(x, y)
    local button = self.settingsButtonRect
    if button and x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
        self.settingsOpen = not self.settingsOpen
        return true
    end
    if self.settingsOpen and self.settingsRects then
        for i = 1, #self.settingsRects do
            local rect = self.settingsRects[i]
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                if rect.key ~= "aimCheat" or self:canUseAimCheat() then
                    local settings = self:getSettings()
                    settings[rect.key] = not settings[rect.key]
                    if rect.key == "calibrateGeometry" and settings.calibrateGeometry then
                        settings.debugGeometry = true
                    elseif rect.key == "debugGeometry" and not settings.debugGeometry then
                        settings.calibrateGeometry = false
                        self.geometryDrag = nil
                    end
                end
                return true
            end
        end
        local menu = self.settingsMenuRect
        if not menu or x < menu.x or x > menu.x + menu.w or y < menu.y or y > menu.y + menu.h then
            self.settingsOpen = false
        end
    end
    return false
end

function PPPoolWindow:render()
    ISCollapsableWindow.render(self)
    self:drawSettingsButton()

    local state = self.state
    if not state then
        self:drawText("Waiting for pool table state...", 24, self:titleBarHeight() + 18, 1, 1, 1, 1, UIFont.Small)
        self:drawSettingsMenu()
        return
    end

    local tx, ty, tw, th = self:getTableRect()
    local sx, sy, sw, sh = self:getSidebarRect()
    self:drawGameFloor()
    self:drawTable(tx, ty, tw, th)
    self:updateWinnerButtons()

    local cueUiX
    local cueUiY
    local balls = self:getDisplayBalls()
    local ballSize = self:getBallSpriteSize()
    for i = 1, #balls do
        local ball = balls[i]
        if not ball.pocketed then
            local ux, uy = self:tableToUi(ball)
            drawSprite(self, "ball_" .. tostring(ball.id) .. ".png", ux, uy, ballSize, 1)
            if ball.id == "cue" then
                cueUiX = ux
                cueUiY = uy
            else
                drawBallNumber(self, ball, ux, uy, ballSize)
            end
        end
    end
    self:drawGeometryOverlay()
    self:drawGeometryCalibration()
    if self:isPlacingCue() and self:isInsideTable(self.mouseX or -1, self.mouseY or -1) then
        drawSprite(self, "ball_cue.png", self.mouseX, self.mouseY, ballSize, 0.62)
        self:drawTextCentre("place cue", self.mouseX, self.mouseY + ballSize / 2 + 4, 0.95, 0.86, 0.46, 0.95, UIFont.Small)
    end

    if self.aiming and cueUiX and cueUiY then
        self:drawAimGuide(cueUiX, cueUiY, tx, ty, tw, th)
    elseif state.aim and state.aim.playerName ~= self.playerName and cueUiX and cueUiY and not self:isAnimating() then
        self:drawAimGuide(cueUiX, cueUiY, tx, ty, tw, th, self:getSmoothedRemoteAim(state.aim))
    else
        self.remoteAimVisual = nil
    end

    if state.winner and not self:isAnimating() then
        self:drawWinnerOverlay(tx, ty, tw, th)
    end
    if not state.modeSelected and not state.winner and not self:isAnimating() then
        self:drawModeSelectOverlay()
    else
        self.modeRects = nil
    end
    self:drawTurnBanner(tx, ty, tw)
    self:drawSidebar(sx, sy, sw, sh)
    self:drawSettingsMenu()

end

function PPPoolWindow:getCueUiPosition()
    if not self.state then
        return nil, nil, nil
    end
    local cue = PP.findBall(self.state, "cue")
    if not cue or cue.pocketed then
        return nil, nil, nil
    end
    local cueX, cueY = self:tableToUi(cue)
    return cue, cueX, cueY
end

function PPPoolWindow:syncAim(active, force)
    if not PPClient or not PPClient.sendAim or not self.state or not self.state.anchor then
        return
    end
    if active and not self:canShoot() then
        return
    end

    local now = getTimestampMs()
    local angle = self.aimAngle or self.keyboardAngle or 0
    local power = self:getCurrentShotPower(300)
    if active and not force then
        local last = self.lastAimSync or {}
        local age = now - (last.at or 0)
        local angleDelta = math.abs(angle - (last.angle or angle))
        local powerDelta = math.abs(power - (last.power or power))
        if age < 110 and angleDelta < 0.012 and powerDelta < 6 then
            return
        end
    end

    self.lastAimSync = { at = now, angle = angle, power = power, active = active and true or false }
    PPClient.sendAim(self.playerNum, self.state.anchor, angle, power, active)
end

function PPPoolWindow:updateKeyboardAim()
    local cue, cueX, cueY = self:getCueUiPosition()
    if not cue then
        return false
    end

    if not self.aiming then
        self.powerMeterSide = nil
    end
    self.aiming = true
    self.aimStartX = cueX
    self.aimStartY = cueY
    self.pendingPower = self:getCurrentShotPower(300)
    self.keyboardPower = self.pendingPower
    self.aimAngle = self.keyboardAngle or self.aimAngle or 0
    local pull = self.pendingPower / 3.2
    local uiNx, uiNy = self:tableAngleToUiVector(self.aimAngle)
    self.mouseX = cueX - uiNx * pull
    self.mouseY = cueY - uiNy * pull
    self:syncAim(true, false)
    return true
end

function PPPoolWindow:ensureKeyboardAim()
    if not self:canShoot() then
        return false
    end
    if not self.keyboardAngle then
        local cue, cueX, cueY = self:getCueUiPosition()
        if not cue then
            return false
        end
        self.keyboardAngle = self.aimAngle or 0
        if self.mouseX and self.mouseY then
            local dx = cueX - self.mouseX
            local dy = cueY - self.mouseY
            if math.sqrt(dx * dx + dy * dy) > 1 then
                self.keyboardAngle = self:uiBackPointToTableAngle(cue, self.mouseX, self.mouseY)
                self.aimAngle = self.keyboardAngle
            end
        end
    end
    if not self.keyboardPower then
        self.keyboardPower = self:getCurrentShotPower(300)
    end
    return self:updateKeyboardAim()
end

function PPPoolWindow:shootKeyboardAim()
    if not self.aiming or not self:canShoot() then
        return false
    end
    return self:commitShot()
end

function PPPoolWindow:commitShot()
    if not self.aiming or not self:canShoot() then
        return false
    end
    local power = clamp(self.pendingPower or self.keyboardPower or self.lastShotPower or 0, 0, PP.MAX_POWER)
    if power >= 30 and PPClient and PPClient.shoot then
        local spinX, spinY = PP.clampCueSpin(self.cueSpinX or 0, self.cueSpinY or 0, self:getBilliardsLevel())
        local angle = self.aimAngle or self.keyboardAngle or 0
        local shotCall = self:getActiveShotCall()
        playPoolSound("UIObjectMenuObjectRotate")
        PPClient.shoot(self.playerNum, self.state.anchor, angle, power, spinX, spinY, self:isAimCheatEnabled(), shotCall)
        self.lastShotPower = power
    end
    self:syncAim(false, true)
    self.aiming = false
    self.rightAiming = false
    self.aimHandleStartX = nil
    self.aimHandleStartY = nil
    self.powerMeterSide = nil
    return true
end

function PPPoolWindow:handleKeyPressed(key)
    if not Keyboard or not self:canShoot() then
        return false
    end

    if key == Keyboard.KEY_LEFT or key == Keyboard.KEY_RIGHT or key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        return self:ensureKeyboardAim()
    end

    if key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
        if not self:ensureKeyboardAim() then
            return false
        end
        return self:shootKeyboardAim()
    end

    if key == Keyboard.KEY_ESCAPE and self.aiming then
        self:syncAim(false, true)
        self.aiming = false
        self.rightAiming = false
        self.aimHandleStartX = nil
        self.aimHandleStartY = nil
        self.powerMeterSide = nil
        return true
    end
    return false
end

function PPPoolWindow:cancelAim()
    if self.aiming then
        self:syncAim(false, true)
    end
    self.aiming = false
    self.rightAiming = false
    self.aimHandleStartX = nil
    self.aimHandleStartY = nil
    self.powerMeterSide = nil
    return true
end

function PPPoolWindow:handleKeyStartPressed(key)
    if not Keyboard or key ~= Keyboard.KEY_SPACE then
        return false
    end
    if self.state and not self.state.winner and not self:isSpectator() then
        return true
    end
    return false
end

function PPPoolWindow:updateHeldKeyboardControls()
    if not Keyboard or not self:canShoot() then
        self.lastKeyboardAimMs = nil
        return
    end

    local left = isKeyDown(Keyboard.KEY_LEFT)
    local right = isKeyDown(Keyboard.KEY_RIGHT)
    local up = isKeyDown(Keyboard.KEY_UP)
    local down = isKeyDown(Keyboard.KEY_DOWN)
    if not left and not right and not up and not down then
        self.lastKeyboardAimMs = nil
        return
    end
    if not self:ensureKeyboardAim() then
        return
    end

    local now = getTimestampMs()
    local last = self.lastKeyboardAimMs or now
    self.lastKeyboardAimMs = now
    local dt = math.max(0.008, math.min(0.05, (now - last) / 1000))
    local fine = isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT)
    local profile = self:getSkillProfile()
    local angleRate = fine and profile.keyboardFineAngleRate or profile.keyboardAngleRate
    local powerRate = fine and profile.keyboardFinePowerRate or profile.keyboardPowerRate
    local spinMode = isKeyDown(Keyboard.KEY_LCONTROL) or isKeyDown(Keyboard.KEY_RCONTROL)

    if spinMode then
        local spinRate = fine and 0.28 or 0.75
        if left then
            self:setCueSpin((self.cueSpinX or 0) - spinRate * dt, self.cueSpinY or 0)
        end
        if right then
            self:setCueSpin((self.cueSpinX or 0) + spinRate * dt, self.cueSpinY or 0)
        end
        if up then
            self:setCueSpin(self.cueSpinX or 0, (self.cueSpinY or 0) + spinRate * dt)
        end
        if down then
            self:setCueSpin(self.cueSpinX or 0, (self.cueSpinY or 0) - spinRate * dt)
        end
    else
        if left then
            self.keyboardAngle = (self.keyboardAngle or 0) - angleRate * dt
        end
        if right then
            self.keyboardAngle = (self.keyboardAngle or 0) + angleRate * dt
        end
        if up then
            self.keyboardPower = math.min(PP.MAX_POWER, (self.keyboardPower or 300) + powerRate * dt)
        end
        if down then
            self.keyboardPower = math.max(30, (self.keyboardPower or 300) - powerRate * dt)
        end
    end
    self.aimAngle = self.keyboardAngle
    self:updateKeyboardAim()
end

function PPPoolWindow:ensureCuePlacementCursor()
    if not self:isPlacingCue() then
        return false
    end
    if not self:isInsideTable(self.mouseX or -1, self.mouseY or -1) then
        local tx, ty, tw, th = self:getPlayfieldRect()
        self.mouseX = tx + tw * 0.25
        self.mouseY = ty + th * 0.5
    end
    return true
end

function PPPoolWindow:nudgeCuePlacement(dx, dy)
    if not self:ensureCuePlacementCursor() then
        return false
    end
    local tx, ty, tw, th = self:getPlayfieldRect()
    local step = math.max(6, self:getBallSpriteSize() * 0.55)
    self.mouseX = clamp((self.mouseX or tx + tw * 0.25) + dx * step, tx, tx + tw)
    self.mouseY = clamp((self.mouseY or ty + th * 0.5) + dy * step, ty, ty + th)
    return true
end

function PPPoolWindow:placeCueFromCursor()
    if not self:ensureCuePlacementCursor() or not PPClient or not PPClient.placeCue then
        return false
    end
    local tableX, tableY = self:uiToTable(self.mouseX, self.mouseY)
    PPClient.placeCue(self.playerNum, self.state.anchor, tableX, tableY)
    playPoolSound("UIObjectMenuObjectPlace")
    return true
end

function PPPoolWindow:handleJoypadDirection(dx, dy)
    if self:isPlacingCue() then
        return self:nudgeCuePlacement(dx, dy)
    end
    if not self:canShoot() then
        return false
    end
    if not self:ensureKeyboardAim() then
        return false
    end

    local profile = self:getSkillProfile()
    local angleStep = profile.keyboardFineAngleRate or math.rad(0.75)
    local powerStep = math.max(8, (profile.keyboardFinePowerRate or 55) * 0.16)
    if self.joypadSpinMode then
        local spinStep = 0.12
        self:setCueSpin((self.cueSpinX or 0) + dx * spinStep, (self.cueSpinY or 0) - dy * spinStep)
    else
        self.keyboardAngle = (self.keyboardAngle or 0) + dx * angleStep
        self.keyboardPower = clamp((self.keyboardPower or self.pendingPower or self.lastShotPower or 300) - dy * powerStep, 30, PP.MAX_POWER)
    end
    self.aimAngle = self.keyboardAngle
    self:updateKeyboardAim()
    return true
end

function PPPoolWindow:onGainJoypadFocus(joypadData)
    self.joypadFocused = true
    self.joypadData = joypadData
end

function PPPoolWindow:onLoseJoypadFocus(joypadData)
    self.joypadFocused = false
    self.joypadData = nil
    self.joypadSpinMode = false
end

function PPPoolWindow:onJoypadDown(button, joypadData)
    if not Joypad then
        return false
    end
    self.joypadData = joypadData
    if button == Joypad.AButton then
        if self:isPlacingCue() then
            return self:placeCueFromCursor()
        end
        if self:canShoot() then
            if not self:ensureKeyboardAim() then
                return false
            end
            return self:shootKeyboardAim()
        end
        return true
    end
    if button == Joypad.BButton then
        if self.settingsOpen then
            self.settingsOpen = false
            return true
        end
        if self.aiming then
            return self:cancelAim()
        end
        return true
    end
    if button == Joypad.YButton and self:canUseAimCheat() then
        local settings = self:getSettings()
        settings.aimCheat = not settings.aimCheat
        return true
    end
    if button == Joypad.XButton or button == Joypad.LBumper or button == Joypad.RBumper then
        self.joypadSpinMode = true
        return true
    end
    if button == Joypad.DPadLeft then
        return self:handleJoypadDirection(-1, 0)
    end
    if button == Joypad.DPadRight then
        return self:handleJoypadDirection(1, 0)
    end
    if button == Joypad.DPadUp then
        return self:handleJoypadDirection(0, -1)
    end
    if button == Joypad.DPadDown then
        return self:handleJoypadDirection(0, 1)
    end
    return false
end

function PPPoolWindow:onJoypadButtonReleased(button, joypadData)
    if Joypad and (button == Joypad.XButton or button == Joypad.LBumper or button == Joypad.RBumper) then
        self.joypadSpinMode = false
        return true
    end
    return false
end

function PPPoolWindow:onJoypadDirLeft(joypadData)
    return self:handleJoypadDirection(-1, 0)
end

function PPPoolWindow:onJoypadDirRight(joypadData)
    return self:handleJoypadDirection(1, 0)
end

function PPPoolWindow:onJoypadDirUp(joypadData)
    return self:handleJoypadDirection(0, -1)
end

function PPPoolWindow:onJoypadDirDown(joypadData)
    return self:handleJoypadDirection(0, 1)
end

function PPPoolWindow:onMouseWheel(del)
    local mx = self:getMouseX()
    local my = self:getMouseY()
    if self.logRect and mx >= self.logRect.x and mx <= self.logRect.x + self.logRect.w and my >= self.logRect.y and my <= self.logRect.y + self.logRect.h then
        self.logScroll = clamp((self.logScroll or 0) - (tonumber(del) or 0), 0, self.logRect.maxScroll or 0)
        return true
    end
    if not self:canShoot() then
        return false
    end
    if not self:ensureKeyboardAim() then
        return false
    end
    if Keyboard and (isKeyDown(Keyboard.KEY_LCONTROL) or isKeyDown(Keyboard.KEY_RCONTROL)) then
        local delta = -(tonumber(del) or 0) * 0.12
        self:setCueSpin(self.cueSpinX or 0, (self.cueSpinY or 0) + delta)
        return true
    end
    local profile = self:getSkillProfile()
    local wheelStep = 42 - (profile.t or 0) * 14
    self.keyboardPower = clamp((self.keyboardPower or self.pendingPower or self.lastShotPower or 300) - (tonumber(del) or 0) * wheelStep, 30, PP.MAX_POWER)
    self.pendingPower = self.keyboardPower
    self:updateKeyboardAim()
    return true
end

function PPPoolWindow:onDebugMyTurn()
    if self.state and self.state.anchor and PPClient and PPClient.debugMyTurn then
        PPClient.debugMyTurn(self.playerNum, self.state.anchor)
    end
end

function PPPoolWindow:onAddAI(difficulty)
    if self.state and self.state.anchor and PPClient and PPClient.addAI then
        playPoolSound("UIObjectMenuObjectPlace")
        PPClient.addAI(self.playerNum, self.state.anchor, difficulty)
    end
end

function PPPoolWindow:onRemoveAI()
    if self.state and self.state.anchor and PPClient and PPClient.removeAI then
        playPoolSound("UIObjectMenuObjectPickup")
        PPClient.removeAI(self.playerNum, self.state.anchor)
    end
end

function PPPoolWindow:onChooseMode(modeId)
    if self:canChooseMode() and PPClient and PPClient.setMode then
        playPoolSound("UIObjectMenuObjectPlace")
        PPClient.setMode(self.playerNum, self.state.anchor, modeId)
    end
end

function PPPoolWindow:onResetRack()
    if not (self.state and self.state.anchor and PPClient and PPClient.reset) then
        return
    end
    local resetOk = true
    local resetReason = nil
    if PP.canResetRack then
        resetOk, resetReason = PP.canResetRack(self.state, self.playerName, { resolving = self:isAnimating() })
    end
    if not resetOk then
        self.bannerText = tostring(resetReason or "Rack cannot be reset right now.")
        if getTimestampMs then
            self.bannerUntil = getTimestampMs() + 1600
        else
            self.bannerUntil = nil
        end
        playPoolSound("UIActivateTab")
        return
    end
    playPoolSound("UIObjectMenuObjectPlace")
    PPClient.reset(self.playerNum, self.state.anchor)
end

function PPPoolWindow:onWinnerReset()
    if self.state and self.state.anchor and PPClient and PPClient.reset then
        playPoolSound("UIObjectMenuObjectPlace")
        self.bannerText = nil
        self.bannerUntil = nil
        self.resultSoundWinner = nil
        PPClient.reset(self.playerNum, self.state.anchor)
    end
end

function PPPoolWindow:onWinnerClose()
    playPoolSound("UIObjectMenuObjectPickup")
    self:close()
end

function PPPoolWindow:updateMouseAimFromPoint(x, y)
    local cue, cueX, cueY = self:getCueUiPosition()
    if not cue then
        return false
    end
    local dx = x - cueX
    local dy = y - cueY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < math.max(24, self:getBallSpriteSize() * 0.75) then
        return false
    end
    self.aimAngle = self:uiPointToTableAngle(cue, x, y)
    self.keyboardAngle = self.aimAngle
    self.aimStartX = cueX
    self.aimStartY = cueY
    self.mouseX = x
    self.mouseY = y
    self:syncAim(true, false)
    return true
end

function PPPoolWindow:setSystemMousePosition(x, y)
    if not Mouse or not Mouse.setXY then
        return false
    end
    local ok = pcall(function()
        Mouse.setXY(math.floor(self:getAbsoluteX() + x + 0.5), math.floor(self:getAbsoluteY() + y + 0.5))
    end)
    return ok
end

function PPPoolWindow:isRightMouseStillDown()
    if not Mouse or not Mouse.isRightDown then
        return true
    end
    local ok, isDown = pcall(function()
        return Mouse.isRightDown()
    end)
    return not ok or isDown
end

function PPPoolWindow:confineAimCursor(x, y)
    local minX, minY, maxX, maxY = self:getAimCursorBounds()
    local confinedX = clamp(x, minX, maxX)
    local confinedY = clamp(y, minY, maxY)
    if confinedX ~= x or confinedY ~= y then
        self:setSystemMousePosition(confinedX, confinedY)
    end
    self.mouseX = confinedX
    self.mouseY = confinedY
    return confinedX, confinedY
end

function PPPoolWindow:beginMouseAim(x, y)
    if not self:canShoot() then
        return false
    end
    local cue, cueX, cueY = self:getCueUiPosition()
    if not cue then
        return false
    end
    x, y = self:confineAimCursor(x, y)
    if not self.aiming then
        self.powerMeterSide = nil
    end
    self.aiming = true
    self.rightAiming = true
    self.aimStartX = cueX
    self.aimStartY = cueY
    self.pendingPower = self:getCurrentShotPower(300)
    self.keyboardPower = self.pendingPower
    self:updateMouseAimFromPoint(x, y)
    return true
end

function PPPoolWindow:isGeometryCalibrationEnabled()
    local settings = self:getSettings()
    return settings and settings.calibrateGeometry and isDebugClient()
end

function PPPoolWindow:handleGeometryCalibrationMouseDown(x, y)
    if not self:isGeometryCalibrationEnabled() then
        return false
    end
    local copyRect = self.geometryCopyRect
    if copyRect and x >= copyRect.x and x <= copyRect.x + copyRect.w and y >= copyRect.y and y <= copyRect.y + copyRect.h then
        self:copyGeometryCalibration()
        return true
    end
    local undoRect = self.geometryUndoRect
    if undoRect and x >= undoRect.x and x <= undoRect.x + undoRect.w and y >= undoRect.y and y <= undoRect.y + undoRect.h then
        self:undoGeometryEdit()
        return true
    end
    local resetRect = self.geometryResetRect
    if resetRect and x >= resetRect.x and x <= resetRect.x + resetRect.w and y >= resetRect.y and y <= resetRect.y + resetRect.h then
        self:resetGeometryCalibration()
        self.bannerText = "Reset geometry editor."
        self.bannerUntil = getTimestampMs() + 2500
        return true
    end
    local clearRect = self.geometryClearRect
    if clearRect and x >= clearRect.x and x <= clearRect.x + clearRect.w and y >= clearRect.y and y <= clearRect.y + clearRect.h then
        if self:clearGeometryEdge() then
            self.bannerText = "Cleared geometry edge points."
        else
            self.bannerText = "Geometry edge is already clear."
        end
        self.bannerUntil = getTimestampMs() + 2200
        return true
    end
    local handles = self.geometryHandles or {}
    for i = #handles, 1, -1 do
        local h = handles[i]
        local dx = x - h.x
        local dy = y - h.y
        local radius = h.radius or 14
        if dx * dx + dy * dy <= radius * radius then
            self:pushGeometryUndo()
            self.geometrySelected = { type = h.type, index = h.index }
            self.geometryDrag = { type = h.type, key = h.key, index = h.index }
            self:updateGeometryCalibrationDrag(x, y)
            return true
        end
    end
    if self:isInsideGameRegion(x, y) then
        local sx, sy = self:uiToSprite(x, y)
        self:insertGeometryVertex(sx, sy)
        return true
    end
    return false
end

function PPPoolWindow:updateGeometryCalibrationDrag(x, y)
    if not self.geometryDrag then
        return false
    end
    local data = self:getGeometryCalibration()
    local spriteX, spriteY = self:uiToSprite(x, y)
    local geometry = PP.getTableGeometry and PP.getTableGeometry() or {}
    spriteX = clamp(spriteX, -120, (geometry.spriteW or 1774) + 120)
    spriteY = clamp(spriteY, -120, (geometry.spriteH or 887) + 120)

    local drag = self.geometryDrag
    if drag.type == "edge" and data.collisionEdge[drag.index] then
        data.collisionEdge[drag.index].x = spriteX
        data.collisionEdge[drag.index].y = spriteY
        return true
    end

    if drag.type == "pocket" and data.pockets[drag.index] then
        data.pockets[drag.index].spriteX = spriteX
        data.pockets[drag.index].spriteY = spriteY
        return true
    end
    return false
end

function PPPoolWindow:onMouseMove(dx, dy)
    ISCollapsableWindow.onMouseMove(self, dx, dy)
    local mx = self:getMouseX()
    local my = self:getMouseY()
    if self.geometryDrag then
        self:updateGeometryCalibrationDrag(mx, my)
        self.mouseX = mx
        self.mouseY = my
        return
    end
    if self.rightAiming and self.aimStartX then
        mx, my = self:confineAimCursor(mx, my)
        self:updateMouseAimFromPoint(mx, my)
    else
        self.mouseX = mx
        self.mouseY = my
    end
end

function PPPoolWindow:onMouseMoveOutside(dx, dy)
    self:onMouseMove(dx, dy)
end

function PPPoolWindow:onMouseDown(x, y)
    if self:handleSettingsClick(x, y) then
        return true
    end
    if self:handleTitleBarDoubleClick(x, y) then
        return true
    end
    if self:handleGeometryCalibrationMouseDown(x, y) then
        return true
    end
    if self.modeRects then
        for i = 1, #self.modeRects do
            local rect = self.modeRects[i]
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                self:onChooseMode(rect.modeId)
                return true
            end
        end
        if self:isInsideGameRegion(x, y) then
            return true
        end
    end
    if self.state and self.state.winner and not self:isAnimating() then
        self:updateWinnerButtons()
        local resetRect = self.winnerResetRect
        local closeRect = self.winnerCloseRect
        if resetRect and x >= resetRect.x and x <= resetRect.x + resetRect.w and y >= resetRect.y and y <= resetRect.y + resetRect.h then
            self:onWinnerReset()
            return true
        end
        if closeRect and x >= closeRect.x and x <= closeRect.x + closeRect.w and y >= closeRect.y and y <= closeRect.y + closeRect.h then
            self:onWinnerClose()
            return true
        end
    end
    local resetRackRect = self.resetRackRect
    if resetRackRect and x >= resetRackRect.x and x <= resetRackRect.x + resetRackRect.w and y >= resetRackRect.y and y <= resetRackRect.y + resetRackRect.h then
        self:onResetRack()
        return true
    end
    if self.debugRects then
        for i = 1, #self.debugRects do
            local rect = self.debugRects[i]
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                rect.action(self)
                return true
            end
        end
    end
    if self.aiRects then
        for i = 1, #self.aiRects do
            local rect = self.aiRects[i]
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                if rect.remove then
                    self:onRemoveAI()
                else
                    self:onAddAI(rect.difficulty)
                end
                return true
            end
        end
    end
    if self.callRects then
        for i = 1, #self.callRects do
            local rect = self.callRects[i]
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                if rect.action == "ball" then
                    self:cycleCalledBall()
                elseif rect.action == "pocket" then
                    self:cycleCalledPocket()
                elseif rect.action == "safety" then
                    self:toggleSafetyCall()
                end
                playPoolSound("UIObjectMenuObjectRotate")
                return true
            end
        end
    end
    if self:isInsideGameRegion(x, y) and not self:isMyTurn() then
        self.mouseX = x
        self.mouseY = y
        return true
    end
    if not self:isMyTurn() then
        return ISCollapsableWindow.onMouseDown(self, x, y)
    end
    if self:isPlacingCue() then
        if self:isInsideTable(x, y) and PPClient and PPClient.placeCue then
            local tableX, tableY = self:uiToTable(x, y)
            PPClient.placeCue(self.playerNum, self.state.anchor, tableX, tableY)
            playPoolSound("UIObjectMenuObjectPlace")
            return true
        end
        if self:isInsideGameRegion(x, y) then
            return true
        end
        return ISCollapsableWindow.onMouseDown(self, x, y)
    end
    if self.aiming and self:isInsideGameRegion(x, y) then
        return self:commitShot()
    end
    if self:isInsideTable(x, y) then
        return true
    end
    if self:isInsideGameRegion(x, y) then
        return true
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end

function PPPoolWindow:onMouseUp(x, y)
    if self.geometryDrag then
        self.geometryDrag = nil
        return true
    end
    return ISCollapsableWindow.onMouseUp(self, x, y)
end

function PPPoolWindow:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

function PPPoolWindow:onRightMouseDown(x, y)
    if self:isGeometryCalibrationEnabled() and self:isInsideGameRegion(x, y) then
        if self:deleteSelectedGeometryPoint() then
            self.bannerText = "Deleted geometry point."
            self.bannerUntil = getTimestampMs() + 1800
        end
        return true
    end
    if not self:isMyTurn() or self:isPlacingCue() then
        if ISCollapsableWindow.onRightMouseDown then
            return ISCollapsableWindow.onRightMouseDown(self, x, y)
        end
        return false
    end
    if self:isInsideTable(x, y) then
        return self:beginMouseAim(x, y)
    end
    if self:isInsideGameRegion(x, y) then
        return true
    end
    if ISCollapsableWindow.onRightMouseDown then
        return ISCollapsableWindow.onRightMouseDown(self, x, y)
    end
    return false
end

function PPPoolWindow:onRightMouseUp(x, y)
    if self.rightAiming then
        self.rightAiming = false
        self.aimHandleStartX = nil
        self.aimHandleStartY = nil
        return true
    end
    if ISCollapsableWindow.onRightMouseUp then
        return ISCollapsableWindow.onRightMouseUp(self, x, y)
    end
    return false
end

function PPPoolWindow:onRightMouseUpOutside(x, y)
    return self:onRightMouseUp(x, y)
end

function PPPoolWindow:new(x, y, width, height, playerName, playerNum, playerObj)
    if LOCK_WINDOW_ASPECT then
        width, height = PPPoolWindow.getWindowSizeForTableHeight((tonumber(height) or DEFAULT_TABLE_PIXEL_HEIGHT) - windowTitleHeight())
    end
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.title = "Playable Pool"
    o.playerName = playerName
    o.playerNum = playerNum or 0
    o.playerObj = playerObj
    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.88 }
    o.borderColor = { r = 0.45, g = 0.36, b = 0.20, a = 1 }
    o.resizable = true
    if LOCK_WINDOW_ASPECT then
        o.minimumWidth, o.minimumHeight = PPPoolWindow.getWindowSizeForTableHeight(MIN_TABLE_PIXEL_HEIGHT)
    else
        o.minimumWidth = 720
        o.minimumHeight = 420
    end
    o.mouseX = 0
    o.mouseY = 0
    o.joypadFocused = false
    o.joypadSpinMode = false
    return o
end
