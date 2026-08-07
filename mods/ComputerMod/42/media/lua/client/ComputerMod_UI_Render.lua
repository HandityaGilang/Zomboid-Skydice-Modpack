function ComputerModInstallUIRender(target)
    local shared = ComputerModUIShared or {}
    local styleRetroButton = shared.styleRetroButton
    local styleIconButton = shared.styleIconButton
    local getGameClockText = shared.getGameClockText
    local getGameDateText = shared.getGameDateText
    local getComputerTimeStep = shared.getComputerTimeStep
    local playComputerUISound = shared.playComputerUISound
    local getComputerWorldAgeHours = shared.getComputerWorldAgeHours
    local addItemWithSavedName = shared.addItemWithSavedName
    local tr = shared.tr or function(key, fallback) return fallback or key end
    local isDebugModeEnabled = shared.isDebugModeEnabled
    local isPlayerNearComputer = shared.isPlayerNearComputer
    local hasComputerPower = shared.hasComputerPower
    local applyEntryColors = shared.applyEntryColors
    local bootMessages = shared.bootMessages
    local browserSites = shared.browserSites
    local browserSiteOrder = shared.browserSiteOrder
    local publicBrowserSiteOrder = shared.publicBrowserSiteOrder
    local desktopFilesTexture = shared.desktopFilesTexture
    local desktopNoteTexture = shared.desktopNoteTexture
    local desktopBrowserTexture = shared.desktopBrowserTexture
    local desktopCalculatorTexture = shared.desktopCalculatorTexture
    local desktopFolderTexture = shared.desktopFolderTexture
    local desktopSettingsTexture = shared.desktopSettingsTexture
    local cdTexture = shared.cdTexture
    local desktopMailTexture = shared.desktopMailTexture
    local desktopChatTexture = shared.desktopChatTexture
    local desktopTrashTexture = shared.desktopTrashTexture
    local desktopMusicTexture = shared.desktopMusicTexture
    local desktopBoardTexture = shared.desktopBoardTexture
    local desktopPaintTexture = shared.desktopPaintTexture
    local desktopMarketTexture = shared.desktopMarketTexture
    local stickyNoteTexture = shared.stickyNoteTexture
    local gamesPongTexture = shared.gamesPongTexture
    local gamesSnakeTexture = shared.gamesSnakeTexture
    local gamesMinesTexture = shared.gamesMinesTexture
    local gamesTetrisTexture = shared.gamesTetrisTexture
    local gamesDoomTexture = shared.gamesDoomTexture
    local gamesInvadersTexture = shared.gamesInvadersTexture
    local gamesRacerTexture = shared.gamesRacerTexture
    local gamesFlappyTexture = shared.gamesFlappyTexture
    local gamesBreakoutTexture = shared.gamesBreakoutTexture
    local gamesAsteroidsTexture = shared.gamesAsteroidsTexture
    local gamesFroggerTexture = shared.gamesFroggerTexture
    local gamesMissileTexture = shared.gamesMissileTexture
    local gamesLanderTexture = shared.gamesLanderTexture
    local gamesCircuitTexture = shared.gamesCircuitTexture
    local startIconTexture = shared.startIconTexture
    local userTextures = shared.userTextures
    local easyComputerPasswords = shared.easyComputerPasswords
    local periodComputerNames = shared.periodComputerNames
    local backgroundPalettes = shared.backgroundPalettes
    local gameInstallOrder = shared.gameInstallOrder
    local gameInstallInfo = shared.gameInstallInfo
    local gameDownloadInfo = shared.gameDownloadInfo
    local gameDiscItems = shared.gameDiscItems
    local measureText = shared.measureText or function(font, text)
        if getTextManager and getTextManager() and getTextManager().MeasureStringX then
            return getTextManager():MeasureStringX(font or UIFont.Small, tostring(text or ""))
        end
        return string.len(tostring(text or "")) * 7
    end
    local getTextLineHeight = shared.getTextLineHeight or function(font)
        if getTextManager and getTextManager() and getTextManager().getFontHeight then
            return getTextManager():getFontHeight(font or UIFont.Small)
        end
        return 14
    end
    local function getPopupPosition(ui, x, y, w, h)
        local left = (ui.screenX or 0) + 2
        local top = (ui.screenY or 0) + 2
        local right = left + math.max(0, (ui.screenWidth or ui.width or 0) - w - 4)
        local bottom = top + math.max(0, (ui.screenHeight or ui.height or 0) - h - 4)
        return math.max(left, math.min(tonumber(x) or left, right)), math.max(top, math.min(tonumber(y) or top, bottom))
    end
function target:drawDesktop()
    local bg = self:getBackgroundPalette()
    local scale = tonumber(self.contentScale or self.uiScale or 1) or 1
    local taskbarH = math.floor(25 * scale + 0.5)
    local taskbarTopBorder = math.max(2, math.floor(2 * scale + 0.5))
    local taskbarBottomBorderY = taskbarH - math.max(2, math.floor(2 * scale + 0.5))
    local startButtonWidth = math.floor(62 * scale + 0.5)
    local startButtonHeight = math.floor(21 * scale + 0.5)
    local startInset = math.max(3, math.floor(3 * scale + 0.5))
    local startIconSize = math.floor(16 * scale + 0.5)
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1.0, bg.r, bg.g, bg.b)
    local taskbarY = self.screenY + self.screenHeight - taskbarH
    local blockedView = self.currentView == "PASSWORD" or self.currentView == "LOCK" or self.currentView == "PASSWORD_HACK" or self.currentView == "RESETTING" or self.currentView == "RESET_CONFIRM" or self.currentView == "DISC_WIPING" or self.currentView == "DISC_WIPE_CONFIRM"
    self:drawRect(self.screenX, taskbarY, self.screenWidth, taskbarH, 1.0, 0.75, 0.75, 0.75)
    self:drawRect(self.screenX, taskbarY, self.screenWidth, taskbarTopBorder, 1.0, 1.0, 1.0, 1.0)
    self:drawRect(self.screenX, taskbarY + taskbarBottomBorderY, self.screenWidth, math.max(2, taskbarH - taskbarBottomBorderY), 1.0, 0.35, 0.35, 0.35)
    if not blockedView then
        self:drawRect(self.screenX + startInset, taskbarY + taskbarTopBorder, startButtonWidth, startButtonHeight, 1, self.startMenuOpen and 0.66 or 0.75, self.startMenuOpen and 0.66 or 0.75, self.startMenuOpen and 0.7 or 0.75)
        self:drawRect(self.screenX + startInset, taskbarY + taskbarTopBorder, startButtonWidth, 1, 1, 1, 1, 1)
        self:drawRect(self.screenX + startInset, taskbarY + taskbarTopBorder, 1, startButtonHeight, 1, 1, 1, 1)
        self:drawRect(self.screenX + startInset + startButtonWidth - 1, taskbarY + taskbarTopBorder, 1, startButtonHeight, 1, 0.35, 0.35, 0.35)
        self:drawRect(self.screenX + startInset, taskbarY + taskbarTopBorder + startButtonHeight - 1, startButtonWidth, 1, 1, 0.35, 0.35, 0.35)
        if startIconTexture then
            self:drawTextureScaled(startIconTexture, self.screenX + math.floor(7 * scale + 0.5), taskbarY + math.floor(4 * scale + 0.5), startIconSize, startIconSize, 1, 1, 1, 1)
        else
            local tile = math.max(6, math.floor(7 * scale + 0.5))
            self:drawRect(self.screenX + math.floor(7 * scale + 0.5), taskbarY + math.floor(4 * scale + 0.5), tile, tile, 1, 0.88, 0.08, 0.08)
            self:drawRect(self.screenX + math.floor(15 * scale + 0.5), taskbarY + math.floor(4 * scale + 0.5), tile, tile, 1, 0.12, 0.28, 0.88)
            self:drawRect(self.screenX + math.floor(7 * scale + 0.5), taskbarY + math.floor(12 * scale + 0.5), tile, tile, 1, 0.12, 0.7, 0.22)
            self:drawRect(self.screenX + math.floor(15 * scale + 0.5), taskbarY + math.floor(12 * scale + 0.5), tile, tile, 1, 0.92, 0.82, 0.18)
        end
        self:drawTextInWidth(tr("Start"), self.screenX + math.floor(24 * scale + 0.5), taskbarY + math.floor(4 * scale + 0.5), math.floor(38 * scale + 0.5), 0, 0, 0, 1, UIFont.Small)
        local minimizedWindows = self:getMinimizedWindows()
        for i = 1, math.min(#minimizedWindows, 3) do
            local slot = self:getMinimizedTaskbarSlot(i)
            self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.78, 0.78, 0.76)
            self:drawRect(slot.x, slot.y, slot.w, 1, 1, 1, 1, 1)
            self:drawRect(slot.x, slot.y, 1, slot.h, 1, 1, 1, 1)
            self:drawRect(slot.x + slot.w - 1, slot.y, 1, slot.h, 1, 0.35, 0.35, 0.35)
            self:drawRect(slot.x, slot.y + slot.h - 1, slot.w, 1, 1, 0.35, 0.35, 0.35)
            self:drawTextInWidth(minimizedWindows[i].label or tr("Window"), slot.x + math.floor(5 * scale + 0.5), slot.y + math.floor(4 * scale + 0.5), slot.w - math.floor(10 * scale + 0.5), 0, 0, 0, 1, UIFont.Small)
        end
    end

    local iconSize = math.floor(34 * scale + 0.5)
    local desktopItems = self:getDesktopItems()
    local hoveredItem = self:getDesktopItemAt(self.hoverX or -1, self.hoverY or -1, desktopItems)
    for i = 1, #desktopItems do
        local item = desktopItems[i]
        if item.x and item.y and hoveredItem and hoveredItem.key == item.key then
            self:drawRect(item.x - 4, item.y - 4, math.floor(64 * scale + 0.5), math.floor(44 * scale + 0.5), 0.15, 0.85, 0.85, 0.85)
        end
        if item.x and item.y and item.labelY then
            if item.texture then
                local texH = item.kind == "folder" and math.floor(26 * scale + 0.5) or iconSize
                local texY = item.kind == "folder" and item.y or item.y
                local texX = item.kind == "folder" and item.x + math.floor(4 * scale + 0.5) or item.x + math.floor(12 * scale + 0.5)
                self:drawTextureScaled(item.texture, texX, texY, iconSize, texH, 1, 1, 1, 1)
            else
                self:drawRect(item.x + math.floor(12 * scale + 0.5), item.y, iconSize, iconSize, 1, 0.8, 0.8, 0.8)
            end
            local labelBoxW = math.floor(58 * scale + 0.5)
            self:drawTextInWidth(item.label, item.x, item.labelY, labelBoxW, 1, 1, 1, 1, UIFont.Small, "center")
        end
    end
    local dateTime = getGameDateText(self:isMonthFirstDate()) .. " " .. getGameClockText(self:is24HourClock())
    local dateX = self.screenX + self.screenWidth - math.floor(110 * scale + 0.5)
    self:drawTaskbarInternetIcon(dateX - math.floor(16 * scale + 0.5), taskbarY + math.floor(7 * scale + 0.5))
    self:drawTextInWidth(dateTime, dateX, taskbarY + math.floor(4 * scale + 0.5), math.floor(106 * scale + 0.5), 0, 0, 0, 1, UIFont.Small, "right")
end

function target:measureWrappedTextWidth(font, text)
    if not text then return 0 end
    return measureText(font, tostring(text))
end

function target:wrapTextLines(text, font, maxWidth, maxLines)
    local lines = {}
    if not text or text == "" then
        return lines
    end
    local source = tostring(text):gsub("\r\n", "\n")
    local paragraphs = {}
    for part in string.gmatch(source .. "\n", "(.-)\n") do
        paragraphs[#paragraphs + 1] = part
    end
    if #paragraphs == 0 then
        paragraphs[1] = source
    end

    local function pushLine(lineText)
        if maxLines and #lines >= maxLines then return false end
        lines[#lines + 1] = lineText
        return true
    end

    for p = 1, #paragraphs do
        local paragraph = paragraphs[p]
        if paragraph == "" then
            if not pushLine("") then break end
        else
            local current = ""
            for word in string.gmatch(paragraph, "%S+") do
                local candidate = current == "" and word or (current .. " " .. word)
                if current ~= "" and self:measureWrappedTextWidth(font, candidate) > maxWidth then
                    if not pushLine(current) then break end
                    current = word
                else
                    current = candidate
                end
                if maxLines and #lines >= maxLines then break end
            end
            if (not maxLines or #lines < maxLines) and current ~= "" then
                if not pushLine(current) then break end
            end
        end
        if maxLines and #lines >= maxLines then break end
    end

    if maxLines and #lines > maxLines then
        while #lines > maxLines do
            table.remove(lines)
        end
    end
    if maxLines and #lines == maxLines then
        local last = lines[#lines] or ""
        if #last > 3 and self:measureWrappedTextWidth(font, last) > maxWidth then
            while #last > 0 and self:measureWrappedTextWidth(font, last .. "...") > maxWidth do
                last = string.sub(last, 1, #last - 1)
            end
            lines[#lines] = last .. "..."
        end
    end
    return lines
end

function target:getVideoSiteListStartY()
    local bodyY = self.clientY + 38
    local bodyW = self.clientW - 16
    local site = ComputerModVideoSites and ComputerModVideoSites[self.browserCurrentAddress or ""]
    local subtitle = site and site.subtitle or ""
    local subtitleLines = self:wrapTextLines(subtitle, UIFont.Small, bodyW - 20, 2)
    return bodyY + 34 + (#subtitleLines * getTextLineHeight(UIFont.Small)) + 14
end

function target:drawGamesWindow()
    local winX = self.windowX
    local winY = self.windowY
    local winW = self.windowW
    local winH = self.windowH
    self:drawRect(winX, winY, winW, winH, 1.0, 0.85, 0.85, 0.85)
    self:drawRect(winX, winY, winW, 2, 1, 1, 1, 1)
    self:drawRect(winX, winY, 2, winH, 1, 1, 1, 1)
    self:drawRect(winX + winW - 2, winY, 2, winH, 1, 0.25, 0.25, 0.25)
    self:drawRect(winX, winY + winH - 2, winW, 2, 1, 0.25, 0.25, 0.25)
    self:drawRect(winX + 3, winY + 3, winW - 6, self.titleH - 3, 1, 0.02, 0.02, 0.55)
    self:drawText(tr("Games"), winX + 8, winY + 5, 1, 1, 1, 1, UIFont.Small)
    local visibleGames = self:getVisibleGames()
    if #visibleGames == 0 then
        self:drawText(tr("No games installed."), winX + 22, winY + 50, 0, 0, 0, 1, UIFont.Small)
        self:drawText(tr("Find a game CD and install it from My Files."), winX + 22, winY + 70, 0.18, 0.18, 0.18, 1, UIFont.Small)
        return
    end
    local slots = self:getGameIconSlots()
    for i = 1, #visibleGames do
        local gameId = visibleGames[i]
        local info = gameInstallInfo[gameId]
        local slot = slots[i]
        slot.texture = info.texture
        slot.label = info.label
        if self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x, slot.y, slot.w, math.max(44, slot.h - 16), 0.15, 0.55, 0.55, 0.55)
        end
        local iconSize = slot.iconSize or 34
        local iconX = slot.x + math.floor((slot.w - iconSize) * 0.5)
        local iconY = slot.y + math.max(2, math.floor((slot.h - iconSize - 18) * 0.35))
        if slot.texture then
            self:drawTextureScaled(slot.texture, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        else
            self:drawRect(iconX, iconY + 4, iconSize, math.max(6, math.floor(iconSize * 0.35)), 1, 0.2, 0.95, 0.95)
            self:drawRect(iconX + math.floor(iconSize * 0.35), iconY, math.max(6, math.floor(iconSize * 0.30)), iconSize, 1, 0.2, 0.95, 0.95)
            self:drawRect(iconX, iconY + math.floor(iconSize * 0.58), iconSize, math.max(6, math.floor(iconSize * 0.30)), 1, 0.95, 0.85, 0.2)
        end
        self:drawTextInWidth(slot.label, slot.x + 2, slot.y + slot.h - 18, slot.w - 4, 0, 0, 0, 1, UIFont.Small, "center")
    end
end

function target:drawAppWindow(title, leftText, rightText)
    title = tr(title or "")
    leftText = tr(leftText or "ARROWS: Move")
    rightText = tr(rightText or "SPACE: Restart")
    self:drawRect(self.windowX, self.windowY, self.windowW, self.windowH, 1, 0.72, 0.72, 0.66)
    self:drawRect(self.windowX, self.windowY, self.windowW, 2, 1, 1, 1, 1)
    self:drawRect(self.windowX, self.windowY, 2, self.windowH, 1, 1, 1, 1)
    self:drawRect(self.windowX + self.windowW - 2, self.windowY, 2, self.windowH, 1, 0.25, 0.25, 0.25)
    self:drawRect(self.windowX, self.windowY + self.windowH - 2, self.windowW, 2, 1, 0.25, 0.25, 0.25)
    self:drawRect(self.windowX + 3, self.windowY + 3, self.windowW - 6, self.titleH - 3, 1, 0.02, 0.02, 0.55)
    self:drawTextInWidth(title, self.windowX + 8, self.windowY + 5, self.windowW - 62, 1, 1, 1, 1, UIFont.Small)
    self:drawRect(self.clientX - 1, self.clientY - 1, self.clientW + 2, self.clientH + 2, 1, 0.1, 0.1, 0.1)
    self:drawRect(self.windowX + 4, self.windowY + self.windowH - self.statusH - 2, self.windowW - 8, self.statusH, 1, 0.72, 0.72, 0.66)
    local statusWidth = math.floor((self.windowW - 24) * 0.5)
    self:drawTextInWidth(leftText, self.windowX + 8, self.windowY + self.windowH - self.statusH, statusWidth, 0, 0, 0, 1, UIFont.Small)
    self:drawTextInWidth(rightText, self.windowX + self.windowW - statusWidth - 8, self.windowY + self.windowH - self.statusH, statusWidth, 0, 0, 0, 1, UIFont.Small, "right")
end

function target:drawFilesWindow()
    local winX = self.windowX
    local winY = self.windowY
    local winW = self.windowW
    local winH = self.windowH
    self:drawRect(winX, winY, winW, winH, 1, 0.85, 0.85, 0.82)
    self:drawRect(winX, winY, winW, 2, 1, 1, 1, 1)
    self:drawRect(winX, winY, 2, winH, 1, 1, 1, 1)
    self:drawRect(winX + winW - 2, winY, 2, winH, 1, 0.25, 0.25, 0.25)
    self:drawRect(winX, winY + winH - 2, winW, 2, 1, 0.25, 0.25, 0.25)
    self:drawRect(winX + 3, winY + 3, winW - 6, self.titleH - 3, 1, 0.02, 0.02, 0.55)
    self:drawText(tr("My Files"), winX + 8, winY + 5, 1, 1, 1, 1, UIFont.Small)
end

function target:drawBootScreen()
    local sx = self.screenX
    local sy = self.screenY
    local sw = self.screenWidth
    local sh = self.screenHeight
    local progress = math.min(1, math.max(0, self.bootTimer / 58))
    self:drawRect(sx, sy, sw, sh, 1, 0.0, 0.0, 0.0)
    self:drawText("PhoenixBIOS 4.03  Copyright 1985-1993", sx + 18, sy + 18, 0.74, 0.74, 0.74, 1, UIFont.Small)
    self:drawText("PZ-486DX ISA/IDE BIOS", sx + 18, sy + 38, 0.74, 0.74, 0.74, 1, UIFont.Small)
    self:drawText("Press DEL to enter SETUP", sx + 236, sy + 18, 0.84, 0.84, 0.74, 1, UIFont.Small)

    local memory = math.min(640, math.floor(progress * 640))
    self:drawText("Memory Test : " .. tostring(memory) .. "K OK", sx + 18, sy + 72, 0.82, 0.82, 0.82, 1, UIFont.Small)
    self:drawText("Fixed Disk 0 : 540MB IDE HDD", sx + 18, sy + 92, 0.82, 0.82, 0.82, 1, UIFont.Small)
    self:drawText("Keyboard    : Detected", sx + 18, sy + 112, 0.82, 0.82, 0.82, 1, UIFont.Small)

    local lineY = sy + 142
    for i = 1, #bootMessages do
        local line = bootMessages[i]
        if self.bootTimer >= line.time then
            self:drawText(line.text, sx + 30, lineY, line.r, line.g, line.b, 1, UIFont.Small)
            lineY = lineY + 17
        end
    end

    if math.floor(self.bootTimer / 8) % 2 == 0 then
        self:drawRect(sx + 30, lineY + 5, 8, 2, 1, 0.82, 0.82, 0.82)
    end

    if self.bootTimer > 50 then
        if self:isOSInstalled() then
            self:drawText("Starting PZ OS 3.1...", sx + 18, sy + sh - 34, 0.82, 0.82, 0.82, 1, UIFont.Small)
        else
            self:drawText("Missing operating system", sx + 18, sy + sh - 34, 0.92, 0.72, 0.72, 1, UIFont.Small)
        end
    else
        self:drawText("Verifying DMI pool data...", sx + 18, sy + sh - 34, 0.72, 0.72, 0.72, 1, UIFont.Small)
    end
end

function target:drawStartMenu()
    if not self.startMenuOpen then return end
    local x = self.screenX + 4
    local debugNet = isDebugModeEnabled and isDebugModeEnabled(self.playerObj)
    local menuRows = debugNet and 4 or 3
    local h = 8 + menuRows * 28
    local y = self.screenY + self.screenHeight - h - 26
    local w = 112
    self:drawRect(x, y, w, h, 1, 0.78, 0.78, 0.76)
    self:drawRect(x, y, w, 1, 1, 1, 1, 1)
    self:drawRect(x, y, 1, h, 1, 1, 1, 1)
    self:drawRect(x + w - 1, y, 1, h, 1, 0.25, 0.25, 0.25)
    self:drawRect(x, y + h - 1, w, 1, 1, 0.25, 0.25, 0.25)
    if self.settingsMenuOpen then
        self:drawRect(x + w - 8, y + 2, 128, 84, 1, 0.78, 0.78, 0.76)
        self:drawRect(x + w - 8, y + 2, 128, 1, 1, 1, 1, 1)
        self:drawRect(x + w - 8, y + 2, 1, 84, 1, 1, 1, 1)
        self:drawRect(x + w + 119, y + 2, 1, 84, 1, 0.25, 0.25, 0.25)
        self:drawRect(x + w - 8, y + 85, 128, 1, 1, 0.25, 0.25, 0.25)
        self:drawText(tr("Password"), x + w + 2, y + 8, 0, 0, 0, 1, UIFont.Small)
        self:drawText(tr("Music playback"), x + w + 2, y + 34, 0, 0, 0, 1, UIFont.Small)
        self:drawText(tr("Clock format"), x + w + 2, y + 61, 0, 0, 0, 1, UIFont.Small)
    end
end

function target:drawBrowserPage()
    if self.isInternetEnabled and not self:isInternetEnabled() then
        self:drawNoInternetPage("Browser")
        return
    end
    local bodyX = self.clientX + 8
    local bodyY = self.clientY + 38
    local bodyW = self.clientW - 16
    local bodyH = self.clientH - 46
    local page = self.browserPage or browserSites["knox-weather.net"]

    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.97, 0.97, 0.95)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.75, 0.75, 0.75)
    if self.browserLoading then
        self:drawRect(bodyX + 8, bodyY + 4, bodyW - 16, 4, 1, 0.78, 0.78, 0.78)
        self:drawRect(bodyX + 8, bodyY + 4, math.floor((bodyW - 16) * ((self.browserLoadProgress or 0) / 100)), 4, 1, 0.12, 0.42, 0.88)
        self:drawTextInWidth(tr("Loading") .. " " .. tostring(self.browserPendingAddress or self.browserCurrentAddress or "site") .. "...", bodyX + 10, bodyY + 24, bodyW - 20, 0.18, 0.18, 0.18, 1, UIFont.Small)
        return
    end
    self:drawTextInWidth(tr(page.title or "Browser"), bodyX + 10, bodyY + 10, bodyW - 20, 0, 0, 0, 1, UIFont.Medium)
    local isMagazineSite = ComputerModMagazineSites and ComputerModMagazineSites[self.browserCurrentAddress or ""] ~= nil
    local isVideoSite = ComputerModVideoSites and ComputerModVideoSites[self.browserCurrentAddress or ""] ~= nil
    if self.browserCurrentAddress ~= "knoxshare.bbs" and not isMagazineSite and not isVideoSite then
        self:drawTextInWidth(tr(page.subtitle or ""), bodyX + 10, bodyY + 34, bodyW - 20, 0.25, 0.25, 0.25, 1, UIFont.Small)
    end
    if self.fileNoticeText and self.fileNoticeText ~= "" and not isVideoSite then
        self:drawTextInWidth(self.fileNoticeText, bodyX + 244, bodyY + 52, bodyW - 254, 0.55, 0.08, 0.08, 1, UIFont.Small)
    end

    if self.browserCurrentAddress == "knoxshare.bbs" then
        local selected = self.downloadSelection or "pong"
        local selectedInfo = gameInstallInfo[selected]
        local selectedDownload = gameDownloadInfo[selected]
        self:drawTextInWidth(tr("Selected:") .. " " .. (selectedInfo and selectedInfo.label or tr("None")), bodyX + 244, bodyY + 70, bodyW - 254, 0.08, 0.08, 0.08, 1, UIFont.Small)
        if selectedDownload then
            self:drawText(string.format("Size: %.1f MB", selectedDownload.sizeMB), bodyX + 244, bodyY + 90, 0.2, 0.2, 0.2, 1, UIFont.Small)
        end
        local data = self:getComputerData()
        if data and data.ComputerModActiveDownloadGame then
            local active = data.ComputerModActiveDownloadGame
            local activeInfo = gameInstallInfo[active]
            local downloadInfo = gameDownloadInfo[active]
            local progress = data.ComputerModActiveDownloadProgress or 0
            local size = downloadInfo and downloadInfo.sizeMB or 1
            local ratio = math.min(1, progress / size)
            self:drawTextInWidth(tr("Downloading") .. " " .. (activeInfo and activeInfo.label or tr("Game")) .. "...", bodyX + 244, bodyY + 118, bodyW - 254, 0.08, 0.08, 0.08, 1, UIFont.Small)
            self:drawRect(bodyX + 244, bodyY + 140, bodyW - 260, 12, 1, 0.72, 0.72, 0.72)
            self:drawRect(bodyX + 246, bodyY + 142, math.floor((bodyW - 264) * ratio), 8, 1, 0.12, 0.42, 0.88)
            self:drawText(tostring(math.floor(ratio * 100)) .. "%", bodyX + bodyW - 42, bodyY + 156, 0.2, 0.2, 0.2, 1, UIFont.Small)
        elseif selected and self:isInstallerDownloaded(selected) then
            self:drawTextInWidth(tr("Setup file is in Downloads."), bodyX + 244, bodyY + 118, bodyW - 254, 0.1, 0.35, 0.1, 1, UIFont.Small)
        else
            self:drawTextInWidth(tr("Ready to download."), bodyX + 244, bodyY + 118, bodyW - 254, 0.2, 0.2, 0.2, 1, UIFont.Small)
        end
        return
    end

    if ComputerModMagazineSites and ComputerModMagazineSites[self.browserCurrentAddress or ""] then
        local site = ComputerModMagazineSites[self.browserCurrentAddress]
        self:drawText(tr(site.subtitle or ""), bodyX + 10, bodyY + 34, 0.25, 0.25, 0.25, 1, UIFont.Small)
        self:drawText(tr("Archive list:"), bodyX + 10, bodyY + 58, 0.08, 0.08, 0.08, 1, UIFont.Small)
        local slots = self:getMagazineDownloadSlots()
        for i = 1, #slots do
            local slot = slots[i]
            if self.browserMagazineSelection == slot.id then
                self:drawRect(slot.x - 2, slot.y - 1, slot.w + 4, slot.h + 2, 0.2, 0.15, 0.35, 0.85)
            elseif self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
                self:drawRect(slot.x - 2, slot.y - 1, slot.w + 4, slot.h + 2, 0.12, 0.55, 0.55, 0.55)
            end
            self:drawTextInWidth(self:getMagazineDisplayName(slot.id), slot.x + 2, slot.y + 2, slot.w - 4, 0.05, 0.2, 0.55, 1, UIFont.Small)
        end
        local validMags = self:filterMagazineList(site.magazines or {})
        local selectedId = self.browserMagazineSelection or validMags[1] or nil
        local selectedLabel = selectedId and self:getMagazineDisplayName(selectedId) or tr("None")
        self:drawText(tr("Selected:") .. " " .. selectedLabel, bodyX + 10, bodyY + bodyH - 56, 0.08, 0.08, 0.08, 1, UIFont.Small)
        self:drawText(tr("Save a local copy to Downloads."), bodyX + 10, bodyY + bodyH - 38, 0.2, 0.2, 0.2, 1, UIFont.Small)
        return
    end

    if ComputerModVideoSites and ComputerModVideoSites[self.browserCurrentAddress or ""] then
        local site = ComputerModVideoSites[self.browserCurrentAddress]
        local subtitleLines = self:wrapTextLines(tr(site.subtitle or ""), UIFont.Small, bodyW - 20, 2)
        local subtitleY = bodyY + 34
        local subtitleLineHeight = getTextLineHeight(UIFont.Small)
        for i = 1, #subtitleLines do
            self:drawText(subtitleLines[i], bodyX + 10, subtitleY + (i - 1) * subtitleLineHeight, 0.25, 0.25, 0.25, 1, UIFont.Small)
        end
        local listHeaderY = self:getVideoSiteListStartY()
        self:drawText(tr("Tape list:"), bodyX + 10, listHeaderY, 0.08, 0.08, 0.08, 1, UIFont.Small)
        local slots = self:getVideoDownloadSlots()
        for i = 1, #slots do
            local slot = slots[i]
            if self.browserVideoSelection == slot.id then
                self:drawRect(slot.x - 2, slot.y - 1, slot.w + 4, slot.h + 2, 0.2, 0.15, 0.35, 0.85)
            elseif self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
                self:drawRect(slot.x - 2, slot.y - 1, slot.w + 4, slot.h + 2, 0.12, 0.55, 0.55, 0.55)
            end
            self:drawTextInWidth(self:getVideoDisplayName(slot.id), slot.x + 2, slot.y + 2, slot.w - 4, 0.05, 0.2, 0.55, 1, UIFont.Small)
        end
        local selectedId = self.browserVideoSelection or (site.videos and site.videos[1]) or nil
        local selectedLabel = selectedId and self:getVideoDisplayName(selectedId) or tr("None")
        local data = self:getComputerData()
        local activeVideo = data and data.ComputerModActiveVideoDownloadId or nil
        local activeProgress = data and data.ComputerModActiveVideoDownloadProgress or 0
        local footerY = bodyY + bodyH - 58
        self:drawRect(bodyX + 8, footerY - 6, bodyW - 124, 40, 1, 0.96, 0.96, 0.94)
        self:drawTextInWidth(tr("Selected:") .. " " .. selectedLabel, bodyX + 10, footerY, bodyW - 138, 0.08, 0.08, 0.08, 1, UIFont.Small)
        if activeVideo and activeVideo == selectedId then
            local progressBarW = math.max(48, bodyW - 314)
            self:drawText(tr("Saving tape to Downloads..."), bodyX + 10, footerY + 16, 0.2, 0.2, 0.2, 1, UIFont.Small)
            self:drawRect(bodyX + 180, footerY + 18, progressBarW, 8, 1, 0.72, 0.72, 0.72)
            self:drawRect(bodyX + 182, footerY + 20, math.floor((progressBarW - 4) * math.min(1, activeProgress or 0)), 4, 1, 0.12, 0.42, 0.88)
        elseif selectedId and self:isVideoDownloaded(selectedId) then
            self:drawText(tr("Tape already saved to Downloads."), bodyX + 10, footerY + 16, 0.12, 0.35, 0.12, 1, UIFont.Small)
        else
            self:drawText(tr("Use Save Tape to add it."), bodyX + 10, footerY + 16, 0.2, 0.2, 0.2, 1, UIFont.Small)
        end
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            local noticeLines = self:wrapTextLines(self.fileNoticeText, UIFont.Small, bodyW - 138, 2)
            local noticeLineHeight = getTextLineHeight(UIFont.Small)
            for i = 1, #noticeLines do
                self:drawText(noticeLines[i], bodyX + 10, bodyY + bodyH - 84 + ((i - 1) * noticeLineHeight), 0.55, 0.08, 0.08, 1, UIFont.Small)
            end
        end
        return
    end

    if page.title == "Search Results" then
        local subtitle = tostring(page.subtitle or "")
        local typed = string.match(subtitle, "^No direct site match for%s+(.+)$")
        if typed then
            subtitle = tr("No direct site match for") .. " " .. typed
        else
            subtitle = tr(subtitle)
        end
        self:drawText(subtitle, bodyX + 10, bodyY + 34, 0.25, 0.25, 0.25, 1, UIFont.Small)
        self:drawText(tr("Suggested addresses:"), bodyX + 10, bodyY + 62, 0.08, 0.08, 0.08, 1, UIFont.Small)
        for i = 1, #publicBrowserSiteOrder do
            local col = math.floor((i - 1) / 5)
            local row = (i - 1) % 5
            self:drawTextInWidth(publicBrowserSiteOrder[i], bodyX + 10 + col * 158, bodyY + 84 + row * 18, 150, 0.05, 0.2, 0.55, 1, UIFont.Small)
        end
        return
    end

    local maxLines = #page.lines
    local y = bodyY + 62
    for i = 1, math.min(#page.lines, maxLines) do
        self:drawTextInWidth(tr(page.lines[i]), bodyX + 10, y, bodyW - 20, 0.08, 0.08, 0.08, 1, UIFont.Small)
        y = y + 18
    end

    self:drawText(tr("Featured sites:"), bodyX + 10, bodyY + bodyH - 56, 0.2, 0.2, 0.2, 1, UIFont.Small)
    local siteY = bodyY + bodyH - 38
    for i = 1, math.min(#browserSiteOrder, 3) do
        self:drawTextInWidth(browserSiteOrder[i], bodyX + 10 + (i - 1) * 118, siteY, 110, 0.05, 0.2, 0.55, 1, UIFont.Small)
    end
end

function target:getFileFolderSlots()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local slots = {}
    local folderNames = self:getComputerFolders()
    local folderBaseY = bodyY + (self:getMountedDiscGame() and 138 or 132)
    local columns = 3
    local stepX = 132
    local stepY = 28
    for i = 1, #folderNames do
        local fx = bodyX + 12 + ((i - 1) % columns) * stepX
        local fy = folderBaseY + math.floor((i - 1) / columns) * stepY
        slots[i] = {x = fx, y = fy, w = 112, h = 24}
    end
    return slots
end

function target:getMountedDiscSlot()
    local discInfo = self:getMountedDiscInfo()
    if not discInfo then return nil end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local drivePanelW = math.floor((bodyW - 30) / 2)
    local dX = bodyX + 10 + drivePanelW + 10
    local drivePanelY = bodyY + 34
    return {x = dX, y = drivePanelY, w = drivePanelW, h = 74, gameId = discInfo.gameId, info = discInfo}
end

function target:getDesktopFolderSlots()
    local slots = {}
    local folderNames = self:getComputerFolders()
    local grid = self:getDesktopGridSlots()
    local offset = #self:getDesktopAppItems()
    for i = 1, #folderNames do
        local slot = grid[offset + i]
        if slot then
            slots[i] = {x = slot.x, y = slot.y, w = slot.w, h = slot.h}
        end
    end
    return slots
end

function target:getFolderItemSlots()
    local slots = {}
    local bodyX = self.clientX + 12
    local bodyY = self.clientY + 42
    local entries = self:getFolderContents(self.currentFolderName or "")
    local columns = 3
    local stepX = 138
    local stepY = 40
    for i = 1, #entries do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        slots[i] = {x = bodyX + col * stepX, y = bodyY + row * stepY, w = 128, h = 34, entry = entries[i], index = i}
    end
    return slots
end

function target:getFolderItemAt(x, y)
    local slots = self:getFolderItemSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return slot.index, slot.entry
        end
    end
    return nil, nil
end

function target:getMagazineDownloadSlots()
    local slots = {}
    local site = ComputerModMagazineSites and ComputerModMagazineSites[self.browserCurrentAddress or ""]
    if not site or type(site.magazines) ~= "table" then return slots end
    local validMags = self:filterMagazineList(site.magazines)
    local bodyX = self.clientX + 16
    local bodyY = self.clientY + 76
    for i = 1, #validMags do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        slots[i] = {x = bodyX + col * 168, y = bodyY + row * 24, w = 156, h = 20, id = validMags[i], index = i}
    end
    return slots
end

function target:getMagazineDownloadAt(x, y)
    local slots = self:getMagazineDownloadSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return slot.id
        end
    end
    return nil
end

function target:getVideoDownloadSlots()
    local slots = {}
    local site = ComputerModVideoSites and ComputerModVideoSites[self.browserCurrentAddress or ""]
    if not site or type(site.videos) ~= "table" then return slots end
    local bodyX = self.clientX + 16
    local bodyY = self:getVideoSiteListStartY() + 18
    local columns = 3
    local slotW = 132
    local stepX = 140
    local stepY = 22
    for i = 1, #site.videos do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        slots[i] = {x = bodyX + col * stepX, y = bodyY + row * stepY, w = slotW, h = 18, id = site.videos[i], index = i}
    end
    return slots
end

function target:getVideoDownloadAt(x, y)
    local slots = self:getVideoDownloadSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return slot.id
        end
    end
    return nil
end

function target:getBrowserLinkAt(x, y)
    local bodyX = self.clientX + 8
    local bodyY = self.clientY + 38
    local bodyW = self.clientW - 16
    local bodyH = self.clientH - 46
    local page = self.browserPage or browserSites["knox-weather.net"]
    if page.title == "Search Results" then
        for i = 1, #publicBrowserSiteOrder do
            local col = math.floor((i - 1) / 5)
            local row = (i - 1) % 5
            local sx = bodyX + 10 + col * 158
            local sy = bodyY + 84 + row * 18
            if x >= sx and x <= sx + 138 and y >= sy and y <= sy + 16 then
                return publicBrowserSiteOrder[i]
            end
        end
    else
        local siteY = bodyY + bodyH - 38
        for i = 1, math.min(#browserSiteOrder, 3) do
            local sx = bodyX + 10 + (i - 1) * 118
            if x >= sx and x <= sx + 110 and y >= siteY and y <= siteY + 16 then
                return browserSiteOrder[i]
            end
        end
    end
    return nil
end

function target:getTrashItemAt(x, y)
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 50
    local trash = self:getTrashEntries()
    for i = 1, math.min(#trash, 8) do
        local sy = bodyY + (i - 1) * 24
        if x >= bodyX and x <= bodyX + 220 and y >= sy and y <= sy + 20 then
            return i, trash[i]
        end
    end
    return nil, nil
end

function target:getMarketShopSlotAt(x, y)
    if self.marketTab ~= "shop" or not self:isMarketLoggedIn() then return nil end
    local items = self:getMarketShopItems()
    local layout = self:getMarketListLayout()
    for i = 1, math.min(#items, layout.rows) do
        local sy = layout.listY + (i - 1) * layout.rowH
        if x >= layout.x and x <= layout.x + layout.w and y >= sy and y <= sy + layout.rowH - 4 then
            return items[i]
        end
    end
    return nil
end

function target:getMarketJobSlotAt(x, y)
    if self.marketTab ~= "jobs" or not self:isMarketLoggedIn() then return nil end
    local jobs = self:getMarketJobs()
    local layout = self:getMarketListLayout()
    for i = 1, math.min(#jobs, layout.rows) do
        local sy = layout.listY + (i - 1) * layout.jobRowH
        if x >= layout.x and x <= layout.x + layout.w and y >= sy and y <= sy + layout.jobRowH - 4 then
            return jobs[i]
        end
    end
    return nil
end

function target:getMarketCategoryAt(x, y)
    if self.marketTab ~= "shop" or not self:isMarketLoggedIn() then return nil end
    local categories = ComputerModMarket and ComputerModMarket.categories or {}
    local layout = self:getMarketListLayout()
    local y1 = layout.panelY + 30
    for i = 1, #categories do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        local bx = layout.panelX + 8 + col * math.floor((layout.panelW - 16) / 4)
        local by = y1 + row * 22
        local bw = math.floor((layout.panelW - 22) / 4)
        if x >= bx and x <= bx + bw and y >= by and y <= by + 18 then
            return categories[i].id
        end
    end
    return nil
end

function target:getMarketListLayout()
    local panelX = self.clientX + 18
    local panelY = self.clientY + 66
    local panelW = self.clientW - 36
    local panelH = self.clientH - 92
    local categoryRows = 0
    if self.marketTab == "shop" then
        local categories = ComputerModMarket and ComputerModMarket.categories or {}
        categoryRows = math.ceil(#categories / 4)
    end
    local listY = panelY + 32 + categoryRows * 22
    local rowH = 27
    local jobRowH = 31
    local usableH = math.max(32, panelY + panelH - listY - 8)
    local rows = math.max(1, math.floor(usableH / (self.marketTab == "jobs" and jobRowH or rowH)))
    return {panelX = panelX, panelY = panelY, panelW = panelW, panelH = panelH, x = panelX + 8, w = panelW - 16, listY = listY, rowH = rowH, jobRowH = jobRowH, rows = rows}
end

function target:getMarketItemTexture(item)
    if not getTexture or not item then return nil end
    self.marketItemTextureCache = self.marketItemTextureCache or {}
    local cacheKey = tostring(item.fullType or item.icon or item.id or "")
    if self.marketItemTextureCache[cacheKey] ~= nil then
        return self.marketItemTextureCache[cacheKey]
    end
    local function tryTextureName(name)
        if not name or name == "" then return nil end
        name = tostring(name)
        local candidates = {
            "Item_" .. name,
            "media/textures/Item_" .. name .. ".png",
            "media/textures/Item_" .. name,
            "media/ui/Item_" .. name .. ".png"
        }
        for i = 1, #candidates do
            local tex = getTexture(candidates[i])
            if tex then return tex end
        end
        return nil
    end
    local function cacheTexture(tex)
        self.marketItemTextureCache[cacheKey] = tex or false
        return tex
    end
    if item.fullType and InventoryItemFactory and InventoryItemFactory.CreateItem then
        local ok, inventoryItem = pcall(function() return InventoryItemFactory.CreateItem(item.fullType) end)
        if ok and inventoryItem then
            local methods = {"getTex", "getTexture", "getNormalTexture"}
            for i = 1, #methods do
                local method = inventoryItem[methods[i]]
                if method then
                    local okTex, tex = pcall(function() return method(inventoryItem) end)
                    if okTex and tex then return cacheTexture(tex) end
                end
            end
        end
    end
    if item.fullType and getScriptManager then
        local okScript, scriptItem = pcall(function() return getScriptManager():FindItem(item.fullType) end)
        if okScript and scriptItem then
            local scriptMethods = {"getIcon", "getNormalTexture"}
            for i = 1, #scriptMethods do
                local method = scriptItem[scriptMethods[i]]
                if method then
                    local okIcon, iconName = pcall(function() return method(scriptItem) end)
                    if okIcon and iconName and type(iconName) ~= "string" and type(iconName) ~= "number" then
                        return cacheTexture(iconName)
                    end
                    local tex = okIcon and tryTextureName(iconName) or nil
                    if tex then return cacheTexture(tex) end
                end
            end
        end
    end
    if item.icon and item.icon ~= "" then
        local tex = tryTextureName(item.icon)
        if tex then return cacheTexture(tex) end
    end
    if item.fullType and string.find(tostring(item.fullType), "%.") then
        local shortName = tostring(item.fullType):match("%.([^%.]+)$")
        local tex = tryTextureName(shortName)
        if tex then return cacheTexture(tex) end
    end
    local fallback = tryTextureName(item.id)
    return cacheTexture(fallback)
end

function target:drawTaskbarInternetIcon(x, y)
    local scale = tonumber(self.contentScale or self.uiScale or 1) or 1
    local connected = not self.isInternetEnabled or self:isInternetEnabled()
    local barW = math.max(2, math.floor(2 * scale + 0.5))
    local gap = math.max(1, math.floor(2 * scale + 0.5))
    local baseH = math.max(3, math.floor(3 * scale + 0.5))
    for i = 1, 4 do
        local h = baseH * i
        local bx = x + (i - 1) * (barW + gap)
        local by = y + baseH * 4 - h
        if connected then
            self:drawRect(bx, by, barW, h, 1, 0.05, 0.34 + i * 0.12, 0.12)
        else
            self:drawRect(bx, by, barW, h, 1, 0.36, 0.36, 0.36)
        end
    end
    if not connected then
        local slashW = math.max(2, math.floor(2 * scale + 0.5))
        for i = 0, math.floor(12 * scale + 0.5) do
            self:drawRect(x + i, y + i, slashW, slashW, 1, 0.76, 0.05, 0.05)
        end
    end
end

function target:drawNoInternetPage(title)
    local bodyX = self.clientX + 8
    local bodyY = self.clientY + 38
    local bodyW = self.clientW - 16
    local bodyH = self.clientH - 46
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.9)
    self:drawText(title or tr("Network"), bodyX + 16, bodyY + 18, 0.05, 0.05, 0.05, 1, UIFont.Medium)
    self:drawText(tr("No internet connection."), bodyX + 16, bodyY + 52, 0.55, 0.05, 0.05, 1, UIFont.Small)
    self:drawText(tr("Use the debug network control to reconnect."), bodyX + 16, bodyY + 76, 0.22, 0.22, 0.22, 1, UIFont.Small)
end

function target:getMarketPaperworkButtonAt(x, y)
    if self.currentView ~= "MARKET_JOB" then return nil end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bw = math.floor((self.clientW - 72) / 4)
    local by = bodyY + math.floor(self.clientH * 0.58)
    for i = 1, 4 do
        local bx = bodyX + 18 + (i - 1) * (bw + 12)
        if x >= bx and x <= bx + bw and y >= by and y <= by + 32 then
            return i
        end
    end
    return nil
end

function target:getMarketCountdownText(kind)
    if not ComputerModMarket or not ComputerModMarket.getHoursUntilNext then return "" end
    local hours = ComputerModMarket.getHoursUntilNext(kind)
    local minutes = math.max(0, math.ceil((tonumber(hours or 0) or 0) * 60))
    local h = math.floor(minutes / 60)
    local m = minutes % 60
    return tostring(h) .. "h " .. tostring(m) .. "m"
end

function target:getStickyPasswordNoteRect()
    local data = self:getComputerData()
    if not data or data.ComputerModStickyNoteVisible ~= true or not data.ComputerModStickyNotePassword or data.ComputerModStickyNotePassword == "" then return nil end
    local frameScale = self.displayProfileSpec and tonumber(self.displayProfileSpec.frameScale or 1) or tonumber(self.uiScale or 1) or 1
    local size = math.max(120, math.floor(144 * frameScale + 0.5))
    local x = self.screenX + self.screenWidth - size - math.floor(14 * frameScale + 0.5)
    local y = math.max(1, self.screenY - math.floor(60 * frameScale + 0.5))
    local closeSize = math.max(18, math.floor(20 * frameScale + 0.5))
    return {x = x, y = y, w = size, h = size, closeX = x + size - closeSize - math.floor(3 * frameScale + 0.5), closeY = y + math.floor(3 * frameScale + 0.5), closeW = closeSize, closeH = closeSize, scale = frameScale}
end

function target:dismissStickyPasswordNote()
    local data = self:getComputerData()
    if not data or data.ComputerModStickyNoteVisible ~= true then return end
    data.ComputerModStickyNoteVisible = false
    data.ComputerModStickyNoteRemoved = true
    if self.computer and self.computer.transmitModData then
        self.computer:transmitModData()
    end
end

function target:drawStickyPasswordNote()
    local rect = self:getStickyPasswordNoteRect()
    if not rect then return end
    if stickyNoteTexture then
        self:drawTextureScaled(stickyNoteTexture, rect.x, rect.y, rect.w, rect.h, 1, 1, 1, 1)
    else
        self:drawRect(rect.x, rect.y, rect.w, rect.h, 1, 0.94, 0.79, 0.25)
    end
    local data = self:getComputerData()
    local label = "PASS:"
    local password = tostring(data and data.ComputerModStickyNotePassword or "")
    local font = rect.scale >= 1.75 and UIFont.Medium or UIFont.Small
    local function centeredX(text)
        return rect.x + math.floor((rect.w - measureText(font, text)) * 0.5)
    end
    self:drawText(label, centeredX(label), rect.y + math.floor(rect.h * 0.39), 0.20, 0.15, 0.08, 1, font)
    self:drawText(password, centeredX(password), rect.y + math.floor(rect.h * 0.58), 0.10, 0.08, 0.04, 1, font)
    self:drawRect(rect.closeX, rect.closeY, rect.closeW, rect.closeH, 0.88, 0.48, 0.10, 0.08)
    self:drawText("X", rect.closeX + math.floor(rect.closeW * 0.24), rect.closeY - 1, 1, 0.92, 0.78, 1, UIFont.Small)
end

local function mixDesktopCacheValue(hash, value)
    local valueType = type(value)
    if valueType == "number" then
        return (hash * 33 + math.floor(value * 1000)) % 2147483647
    end
    if valueType == "boolean" then
        return (hash * 33 + (value and 1 or 0)) % 2147483647
    end
    local text = tostring(value or "")
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % 2147483647
    end
    return hash
end

function target:invalidateDesktopCache()
    self.computerModDesktopItemsCache = nil
    self.computerModDesktopItemsSignature = nil
end

function target:getDesktopCacheSignature()
    local data = self:getComputerData()
    if not data then return 0 end
    local hash = 5381
    hash = mixDesktopCacheValue(hash, self.screenX)
    hash = mixDesktopCacheValue(hash, self.screenY)
    hash = mixDesktopCacheValue(hash, self.screenWidth)
    hash = mixDesktopCacheValue(hash, self.screenHeight)
    hash = mixDesktopCacheValue(hash, self.contentScale or self.uiScale or 1)
    if not self.computerModDesktopAppFlags then
        self.computerModDesktopAppFlags = {
            board = not ComputerModSandbox or ComputerModSandbox.getBool("EnableBoardApp", true),
            chat = not ComputerModSandbox or ComputerModSandbox.getBool("EnableChatApp", true),
            market = not ComputerModSandbox or ComputerModSandbox.getBool("EnableCommerceApp", true)
        }
    end
    hash = mixDesktopCacheValue(hash, self.computerModDesktopAppFlags.board)
    hash = mixDesktopCacheValue(hash, self.computerModDesktopAppFlags.chat)
    hash = mixDesktopCacheValue(hash, self.computerModDesktopAppFlags.market)
    local hidden = type(data.ComputerModHiddenDesktopItems) == "table" and data.ComputerModHiddenDesktopItems or {}
    for key, value in pairs(hidden) do
        hash = mixDesktopCacheValue(hash, key)
        hash = mixDesktopCacheValue(hash, value)
    end
    local folders = type(data.ComputerModFolders) == "table" and data.ComputerModFolders or {}
    hash = mixDesktopCacheValue(hash, #folders)
    for i = 1, #folders do
        hash = mixDesktopCacheValue(hash, folders[i])
    end
    local notes = type(data.ComputerModDesktopNotes) == "table" and data.ComputerModDesktopNotes or {}
    hash = mixDesktopCacheValue(hash, #notes)
    for i = 1, #notes do
        local note = notes[i]
        if note then
            hash = mixDesktopCacheValue(hash, note.key)
            hash = mixDesktopCacheValue(hash, note.name)
        end
    end
    local paints = type(data.ComputerModPaintFiles) == "table" and data.ComputerModPaintFiles or {}
    hash = mixDesktopCacheValue(hash, #paints)
    for i = 1, #paints do
        local paint = paints[i]
        if paint then
            hash = mixDesktopCacheValue(hash, paint.key)
            hash = mixDesktopCacheValue(hash, paint.name)
        end
    end
    local files = type(data.ComputerModDesktopFiles) == "table" and data.ComputerModDesktopFiles or {}
    hash = mixDesktopCacheValue(hash, #files)
    for i = 1, #files do
        local file = files[i]
        if file then
            hash = mixDesktopCacheValue(hash, file.desktopKey)
            hash = mixDesktopCacheValue(hash, file.type)
            hash = mixDesktopCacheValue(hash, file.id)
            hash = mixDesktopCacheValue(hash, file.label)
        end
    end
    local layout = type(data.ComputerModDesktopLayout) == "table" and data.ComputerModDesktopLayout or {}
    for key, value in pairs(layout) do
        hash = mixDesktopCacheValue(hash, key)
        hash = mixDesktopCacheValue(hash, value)
    end
    return hash
end

function target:getDesktopGridSlots()
    local cached = self.computerModDesktopGridSlots
    if cached
        and self.computerModDesktopGridScreenX == self.screenX
        and self.computerModDesktopGridScreenY == self.screenY
        and self.computerModDesktopGridScreenWidth == self.screenWidth
        and self.computerModDesktopGridScreenHeight == self.screenHeight
        and self.computerModDesktopGridScale == (self.contentScale or self.uiScale or 1)
    then
        return cached
    end
    local scale = tonumber(self.contentScale or self.uiScale or 1) or 1
    local slotW = math.floor(58 * scale + 0.5)
    local slotH = math.floor(58 * scale + 0.5)
    local startX = self.screenX + math.floor(18 * scale + 0.5)
    local startY = self.screenY + math.floor(12 * scale + 0.5)
    local stepX = math.floor(95 * scale + 0.5)
    local stepY = math.floor(75 * scale + 0.5)
    local taskbarH = math.floor(25 * scale + 0.5)
    local availableW = math.max(slotW, self.screenWidth - math.floor(36 * scale + 0.5))
    local availableH = math.max(slotH, self.screenHeight - taskbarH - math.floor(18 * scale + 0.5))
    local cols = math.max(5, math.floor((availableW - slotW) / stepX) + 1)
    local rows = math.max(4, math.floor((availableH - slotH) / stepY) + 1)
    local slots = {}
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local x = startX + col * stepX
            local y = startY + row * stepY
            slots[#slots + 1] = {x = x, y = y, w = slotW, h = slotH, labelY = y + math.floor(38 * scale + 0.5)}
        end
    end
    self.computerModDesktopGridSlots = slots
    self.computerModDesktopGridScreenX = self.screenX
    self.computerModDesktopGridScreenY = self.screenY
    self.computerModDesktopGridScreenWidth = self.screenWidth
    self.computerModDesktopGridScreenHeight = self.screenHeight
    self.computerModDesktopGridScale = self.contentScale or self.uiScale or 1
    return slots
end

function target:getDesktopAppItems()
    local items = {
        {key = "app_files", kind = "app", app = "files", label = tr("My Files"), texture = desktopFilesTexture},
        {key = "app_notepad", kind = "app", app = "notepad", label = tr("Notepad"), texture = desktopNoteTexture},
        {key = "app_browser", kind = "app", app = "browser", label = tr("Browser"), texture = desktopBrowserTexture},
        {key = "app_calculator", kind = "app", app = "calculator", label = tr("Calculator"), texture = desktopCalculatorTexture},
        {key = "app_games", kind = "app", app = "games", label = tr("Games"), texture = desktopFolderTexture},
        {key = "app_trash", kind = "app", app = "trash", label = tr("Trash"), texture = desktopTrashTexture},
        {key = "app_music", kind = "app", app = "music", label = tr("Music"), texture = desktopMusicTexture},
        {key = "app_mail", kind = "app", app = "mail", label = tr("Mail"), texture = desktopMailTexture},
        {key = "app_settings", kind = "app", app = "settings", label = tr("Settings"), texture = desktopSettingsTexture},
        {key = "app_paint", kind = "app", app = "paint", label = tr("Paint"), texture = desktopPaintTexture}
    }
    if not ComputerModSandbox or ComputerModSandbox.getBool("EnableBoardApp", true) then
        items[#items + 1] = {key = "app_board", kind = "app", app = "board", label = tr("Board"), texture = desktopBoardTexture}
    end
    if not ComputerModSandbox or ComputerModSandbox.getBool("EnableChatApp", true) then
        items[#items + 1] = {key = "app_chat", kind = "app", app = "chat", label = tr("Chat"), texture = desktopChatTexture}
    end
    if not ComputerModSandbox or ComputerModSandbox.getBool("EnableCommerceApp", true) then
        items[#items + 1] = {key = "app_market", kind = "app", app = "market", label = tr("Market"), texture = desktopMarketTexture}
    end
    return items
end

function target:getDesktopNoteItems()
    local items = {}
    local notes = self.getDesktopNotes and self:getDesktopNotes() or {}
    for i = 1, #notes do
        local note = notes[i]
        if note and note.key and note.name then
            items[#items + 1] = {key = "note:" .. tostring(note.key), kind = "note", noteKey = note.key, label = note.name, texture = desktopNoteTexture}
        end
    end
    return items
end

function target:getDesktopPaintItems()
    local items = {}
    local files = self.getPaintFiles and self:getPaintFiles() or {}
    for i = 1, #files do
        local file = files[i]
        if file and file.key and file.name then
            items[#items + 1] = {key = "paint:" .. tostring(file.key), kind = "paint", paintKey = file.key, label = file.name, texture = desktopPaintTexture}
        end
    end
    return items
end

function target:getDesktopStoredFileItems()
    local items = {}
    local files = self.getDesktopStoredFiles and self:getDesktopStoredFiles() or {}
    for i = 1, #files do
        local file = files[i]
        if file and file.desktopKey then
            items[#items + 1] = {
                key = "stored:" .. tostring(file.desktopKey),
                kind = "stored",
                entry = file,
                label = self:getReadableEntryDisplayName(file),
                texture = self:getReadableEntryIconTexture(file)
            }
        end
    end
    return items
end

function target:ensureDesktopLayout(preparedItems, preparedSlots)
    local data = self:getComputerData()
    if not data then return {} end
    data.ComputerModDesktopLayout = data.ComputerModDesktopLayout or {}
    if type(preparedItems) ~= "table" then
        self:getDesktopItems()
        return data.ComputerModDesktopLayout
    end
    local slots = preparedSlots or self:getDesktopGridSlots()
    local layout = data.ComputerModDesktopLayout
    local used = {}
    local nextSlot = 1
    local exists = {}
    for i = 1, #preparedItems do
        local key = preparedItems[i].key
        exists[key] = true
        local slotIndex = tonumber(layout[key] or 0) or 0
        if slotIndex < 1 or slotIndex > #slots or used[slotIndex] then
            while used[nextSlot] do
                nextSlot = nextSlot + 1
            end
            slotIndex = nextSlot
            layout[key] = slotIndex
            used[slotIndex] = true
            nextSlot = nextSlot + 1
        else
            used[slotIndex] = true
        end
    end
    for key in pairs(layout) do
        if not exists[key] then
            layout[key] = nil
        end
    end
    return layout
end

function target:getDesktopItems()
    local signature = self:getDesktopCacheSignature()
    if self.computerModDesktopItemsCache and self.computerModDesktopItemsSignature == signature then
        return self.computerModDesktopItemsCache
    end
    local items = {}
    local appItems = self:getDesktopAppItems()
    for i = 1, #appItems do
        if not self:isDesktopItemHidden(appItems[i].key) then
            items[#items + 1] = appItems[i]
        end
    end
    local folders = self:getComputerFolders()
    for i = 1, #folders do
        local key = "folder:" .. folders[i]
        if not self:isDesktopItemHidden(key) then
            items[#items + 1] = {key = key, kind = "folder", folderName = folders[i], label = folders[i], texture = desktopFolderTexture, folderIndex = i}
        end
    end
    local notes = self:getDesktopNoteItems()
    for i = 1, #notes do
        if not self:isDesktopItemHidden(notes[i].key) then
            items[#items + 1] = notes[i]
        end
    end
    local paints = self:getDesktopPaintItems()
    for i = 1, #paints do
        if not self:isDesktopItemHidden(paints[i].key) then
            items[#items + 1] = paints[i]
        end
    end
    local stored = self:getDesktopStoredFileItems()
    for i = 1, #stored do
        items[#items + 1] = stored[i]
    end
    local slots = self:getDesktopGridSlots()
    local layout = self:ensureDesktopLayout(items, slots)
    for i = 1, #items do
        local slot = slots[layout[items[i].key] or i]
        if slot then
            items[i].x = slot.x
            items[i].y = slot.y
            items[i].w = slot.w
            items[i].h = slot.h
            items[i].labelY = slot.labelY
            items[i].slotIndex = layout[items[i].key] or i
        end
    end
    table.sort(items, function(a, b) return (a.slotIndex or 0) < (b.slotIndex or 0) end)
    self.computerModDesktopItemsCache = items
    self.computerModDesktopItemsSignature = self:getDesktopCacheSignature()
    return items
end

function target:getDesktopItemAt(x, y, preparedItems)
    local items = preparedItems or self:getDesktopItems()
    for i = 1, #items do
        local item = items[i]
        if item.x and item.y and item.w and item.h and x >= item.x and x <= item.x + item.w and y >= item.y and y <= item.y + item.h + 16 then
            return item
        end
    end
    return nil
end

function target:getDesktopSlotAt(x, y)
    local slots = self:getDesktopGridSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h + 16 then
            return i
        end
    end
    return nil
end

function target:moveDesktopItemToSlot(itemKey, targetSlot)
    local data = self:getComputerData()
    if not data or not itemKey or not targetSlot then return end
    local layout = self:ensureDesktopLayout()
    local occupiedKey = nil
    for key, slot in pairs(layout) do
        if key ~= itemKey and slot == targetSlot then
            occupiedKey = key
            break
        end
    end
    local sourceSlot = layout[itemKey]
    layout[itemKey] = targetSlot
    if occupiedKey then
        local slots = self:getDesktopGridSlots()
        local placed = false
        for i = targetSlot + 1, #slots do
            local free = true
            for key, slot in pairs(layout) do
                if key ~= occupiedKey and slot == i then
                    free = false
                    break
                end
            end
            if free then
                layout[occupiedKey] = i
                placed = true
                break
            end
        end
        if not placed then
            layout[occupiedKey] = sourceSlot or layout[occupiedKey]
        end
    end
    data.ComputerModDesktopLayout = layout
    self:invalidateDesktopCache()
    if self.computer and self.computer.transmitModData then
        self.computer:transmitModData()
    end
end

function target:activateDesktopItem(item)
    if not item then return end
    if item.kind == "folder" then
        if item.folderName == "Downloads" then
            self:openDownloadsFolder()
        else
            self:openFolderView(item.folderName)
        end
        return
    end
    if item.kind == "note" then
        self:openDesktopNote(item.noteKey)
        return
    end
    if item.kind == "paint" then
        self:openPaintFile(item.paintKey)
        return
    end
    if item.kind == "stored" then
        self:readFolderEntry(item.entry)
        return
    end
    if item.app == "files" then self:startFiles()
    elseif item.app == "notepad" then self:startNotepad()
    elseif item.app == "browser" then self:startBrowser()
    elseif item.app == "calculator" then self:startCalculator()
    elseif item.app == "games" then self:openGamesMenu()
    elseif item.app == "trash" then self:openTrashFolder()
    elseif item.app == "board" then self:startPostsBoard()
    elseif item.app == "music" then self:startMusicPlayer()
    elseif item.app == "mail" then self:startMail()
    elseif item.app == "chat" then self:startChat()
    elseif item.app == "settings" then self:openSettingsWindow()
    elseif item.app == "paint" then self:startPaint()
    elseif item.app == "market" then self:startMarket()
    end
end

function target:getFolderIndexAt(x, y)
    if self.currentView == "DESKTOP" then
        local item = self:getDesktopItemAt(x, y)
        return item and item.kind == "folder" and item.folderIndex or nil
    end
    local slots = self:getFileFolderSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return i
        end
    end
    return nil
end

function target:deleteFolderByIndex(index)
    local folders = self:getComputerFolders()
    if not folders[index] then return end
    if folders[index] == "Downloads" then
        self.folderContextMenu = nil
        return
    end
    local removedName = folders[index]
    self:addFolderToTrash(removedName, self.currentView == "DESKTOP" and "desktop" or "files", nil)
    table.remove(folders, index)
    self.folderContextMenu = nil
    local data = self:getComputerData()
    if data then
        data.ComputerModFolders = folders
        if data.ComputerModFolderContents then
            data.ComputerModFolderContents[removedName] = nil
        end
        if data.ComputerModUserFolders then
            data.ComputerModUserFolders[removedName] = nil
        end
        if self.computer.transmitModData then
            self.computer:transmitModData()
        end
    end
end

function target:getDiscContextActions()
    local discSlot = self:getMountedDiscSlot()
    if not discSlot then return {} end
    local actions = {}
    if discSlot.gameId ~= "os" and discSlot.gameId ~= "blank" and discSlot.gameId ~= "generic" and discSlot.gameId ~= "hack" then
        actions[#actions + 1] = {id = "install", label = tr("Install")}
    end
    actions[#actions + 1] = {id = "eject", label = tr("ContextMenu_ComputerMod_RemoveCD", "Remove CD")}
    if discSlot.gameId ~= "generic" then
        actions[#actions + 1] = {id = "wipe", label = tr("Wipe")}
    end
    actions[#actions + 1] = {id = "rename", label = tr("Rename")}
    return actions
end

function target:onMouseDown(x, y)
    local stickyRect = self:getStickyPasswordNoteRect()
    if stickyRect and x >= stickyRect.x and x <= stickyRect.x + stickyRect.w and y >= stickyRect.y and y <= stickyRect.y + stickyRect.h then
        if x >= stickyRect.closeX and x <= stickyRect.closeX + stickyRect.closeW and y >= stickyRect.closeY and y <= stickyRect.closeY + stickyRect.closeH then
            self:dismissStickyPasswordNote()
        end
        return true
    end
    local scaleX = self.width / 649
    local scaleY = self.height / 560
    local muteX1 = math.floor(236 * scaleX)
    local muteX2 = math.floor(344 * scaleX)
    local muteY1 = math.floor(466 * scaleY)
    local muteY2 = math.floor(501 * scaleY)
    local powerX1 = math.floor(496 * scaleX)
    local powerX2 = math.floor(542 * scaleX)
    local powerY1 = math.floor(476 * scaleY)
    local powerY2 = math.floor(526 * scaleY)
    if x >= muteX1 and x <= muteX2 and y >= muteY1 and y <= muteY2 then
        playComputerUISound("ComputerTurnOnOff")
        self:toggleMusicMute()
        return true
    end
    if x >= powerX1 and x <= powerX2 and y >= powerY1 and y <= powerY2 then
        self:shutdownComputer()
        return true
    end
    if self.gameContextMenu then
        local menuX = self.gameContextMenu.drawX or self.gameContextMenu.x
        local menuY = self.gameContextMenu.drawY or self.gameContextMenu.y
        local menuH = self:canWriteGameToDisc(self.gameContextMenu.gameId) and 48 or 24
        if x >= menuX and x <= menuX + 94 and y >= menuY and y <= menuY + 24 then
            self:uninstallGame(self.gameContextMenu.gameId)
            return true
        elseif menuH > 24 and x >= menuX and x <= menuX + 94 and y >= menuY + 24 and y <= menuY + 48 then
            self:writeGameToMountedDisc(self.gameContextMenu.gameId)
            return true
        end
        self.gameContextMenu = nil
    end
    if self.discContextMenu then
        local menuX = self.discContextMenu.drawX or self.discContextMenu.x
        local menuY = self.discContextMenu.drawY or self.discContextMenu.y
        local actions = self:getDiscContextActions()
        local menuW = 112
        local menuH = #actions * 24
        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            local action = actions[math.floor((y - menuY) / 24) + 1]
            self.discContextMenu = nil
            if action and action.id == "install" then
                local discGame = self:getMountedDiscGame()
                if discGame then self:openInstallWizard(discGame) end
            elseif action and action.id == "eject" then
                if self.ejectMountedDisc then self:ejectMountedDisc() end
            elseif action and action.id == "wipe" then
                self:openDiscWipeConfirm()
            elseif action and action.id == "rename" then
                self.folderEditReturnView = "FILES"
                self:startFolderEdit("rename_cd", (self:getComputerData() and self:getComputerData().ComputerModMountedCDLabel) or "Blank CD")
            end
            return true
        end
        self.discContextMenu = nil
    end
    if self.folderContextMenu then
        local menuX = self.folderContextMenu.drawX or self.folderContextMenu.x
        local menuY = self.folderContextMenu.drawY or self.folderContextMenu.y
        if x >= menuX and x <= menuX + 92 and y >= menuY and y <= menuY + 24 then
            self.folderEditReturnView = self.currentView == "DESKTOP" and "DESKTOP" or "FILES"
            self:startFolderEdit("rename", self:getComputerFolders()[self.folderContextMenu.index])
            self.folderContextMenu = nil
            return true
        elseif x >= menuX and x <= menuX + 92 and y >= menuY + 24 and y <= menuY + 48 then
            self:deleteFolderByIndex(self.folderContextMenu.index)
            return true
        end
        self.folderContextMenu = nil
    end
    if self.desktopContextMenu then
        local menuX = self.desktopContextMenu.drawX or self.desktopContextMenu.x
        local menuY = self.desktopContextMenu.drawY or self.desktopContextMenu.y
        local submenuOpen = self.desktopContextMenu.submenuOpen
        local submenuX = self.desktopContextMenu.submenuX or (menuX + 94)
        local submenuY = self.desktopContextMenu.submenuY or menuY
        local allowNote = self.desktopContextMenu.allowNote == true
        local submenuH = allowNote and 48 or 24
        if submenuOpen and x >= submenuX and x <= submenuX + 104 and y >= submenuY and y <= submenuY + submenuH then
            self.folderEditReturnView = self.currentView == "DESKTOP" and "DESKTOP" or "FILES"
            if y <= submenuY + 24 then
                self:startFolderEdit("create")
            elseif allowNote then
                self:startFolderEdit("create_note")
            end
            self.desktopContextMenu = nil
            return true
        end
        if x >= menuX and x <= menuX + 94 and y >= menuY and y <= menuY + 24 then
            self.desktopContextMenu.submenuOpen = true
            return true
        end
        self.desktopContextMenu = nil
    end
    if self.desktopItemContextMenu then
        local menu = self.desktopItemContextMenu
        local menuX = menu.drawX or menu.x
        local menuY = menu.drawY or menu.y
        local submenuX = menu.submenuX or (menuX + 94)
        local submenuY = menu.submenuY or menuY
        local entry = self:getDesktopFileEntry(menu.item)
        local targets = menu.targets or self:getStorageTargetsForEntry(entry)
        if menu.item and menu.item.kind == "app" then
            if x >= menuX and x <= menuX + 96 and y >= menuY and y <= menuY + 24 then
                self:activateDesktopItem(menu.item)
                self.desktopItemContextMenu = nil
                return true
            end
            self.desktopItemContextMenu = nil
            return true
        end
        if menu.subMode and x >= submenuX and x <= submenuX + 132 and y >= submenuY and y <= submenuY + math.min(#targets, 8) * 24 then
            local index = math.floor((y - submenuY) / 24) + 1
            local targetInfo = targets[index]
            if targetInfo then
                if menu.subMode == "move" then
                    self:moveDesktopItemToStorage(menu.item, targetInfo.name)
                else
                    self:copyDesktopItemToStorage(menu.item, targetInfo.name)
                end
                self.desktopItemContextMenu = nil
                return true
            end
        end
        local isFolderItem = menu.item and menu.item.kind == "folder"
        local deleteY = isFolderItem and 48 or 24
        local copyY = isFolderItem and 72 or 48
        local moveY = isFolderItem and 96 or 72
        if x >= menuX and x <= menuX + 96 and y >= menuY and y <= menuY + 24 then
            self:activateDesktopItem(menu.item)
            self.desktopItemContextMenu = nil
            return true
        elseif isFolderItem and x >= menuX and x <= menuX + 96 and y >= menuY + 24 and y <= menuY + 48 then
            self.folderEditReturnView = "DESKTOP"
            self:startFolderEdit("rename", menu.item.folderName)
            self.desktopItemContextMenu = nil
            return true
        elseif x >= menuX and x <= menuX + 96 and y >= menuY + deleteY and y <= menuY + deleteY + 24 then
            if self:deleteDesktopItem(menu.item) then
                self.fileNoticeText = tr("Moved to Trash.")
                self.fileNoticeTimer = 120
            end
            self.desktopItemContextMenu = nil
            return true
        elseif x >= menuX and x <= menuX + 96 and y >= menuY + copyY and y <= menuY + copyY + 24 then
            menu.subMode = "copy"
            return true
        elseif x >= menuX and x <= menuX + 96 and y >= menuY + moveY and y <= menuY + moveY + 24 then
            menu.subMode = "move"
            return true
        end
        self.desktopItemContextMenu = nil
    end
    if self.trashContextMenu then
        local menuX = self.trashContextMenu.drawX or self.trashContextMenu.x
        local menuY = self.trashContextMenu.drawY or self.trashContextMenu.y
        if x >= menuX and x <= menuX + 94 and y >= menuY and y <= menuY + 24 then
            self:emptyTrash()
            self.trashContextMenu = nil
            return true
        end
        self.trashContextMenu = nil
    end
    if self.fileItemContextMenu then
        local menuX = self.fileItemContextMenu.drawX or self.fileItemContextMenu.x
        local menuY = self.fileItemContextMenu.drawY or self.fileItemContextMenu.y
        local item = self.fileItemContextMenu
        if x >= menuX and x <= menuX + 86 and y >= menuY and y <= menuY + 24 then
            if item.source == "folder" then
                local entries = self:getFolderContents(self.currentFolderName or "")
                if entries[item.index] then
                    self:readFolderEntry(entries[item.index])
                end
            elseif item.source == "downloads" then
                local downloads = self:getDownloadedMagazines()
                if downloads[item.index] then
                    self:readFolderEntry(downloads[item.index])
                end
            end
            self.fileItemContextMenu = nil
            return true
        elseif x >= menuX and x <= menuX + 86 and y >= menuY + 24 and y <= menuY + 48 then
            if item.source == "folder" then
                local entries = self:getFolderContents(self.currentFolderName or "")
                if entries[item.index] then
                    self:addFolderEntryToTrash(entries[item.index], "folder", self.currentFolderName or "")
                    table.remove(entries, item.index)
                end
            elseif item.source == "downloads" then
                local downloads = self:getDownloadedMagazines()
                if downloads[item.index] then
                    self:addMagazineToTrash(downloads[item.index])
                    table.remove(downloads, item.index)
                end
            end
            if self.computer and self.computer.transmitModData then
                self.computer:transmitModData()
            end
            self.fileItemContextMenu = nil
            return true
        elseif x >= menuX and x <= menuX + 86 and y >= menuY + 48 and y <= menuY + 72 then
            local entry = nil
            if item.source == "folder" then
                local entries = self:getFolderContents(self.currentFolderName or "")
                entry = entries[item.index]
                if entry and self:addEntryToDesktop(entry) then
                    table.remove(entries, item.index)
                end
            elseif item.source == "downloads" then
                local downloads = self:getDownloadedMagazines()
                entry = downloads[item.index]
                if entry and self:addEntryToDesktop(entry) then
                    table.remove(downloads, item.index)
                end
            end
            if self.computer and self.computer.transmitModData then
                self.computer:transmitModData()
            end
            self.fileNoticeText = entry and tr("Moved to desktop.") or self.fileNoticeText
            self.fileNoticeTimer = entry and 120 or self.fileNoticeTimer
            self.fileItemContextMenu = nil
            return true
        elseif self:isDiscStorageOpenable() and x >= menuX and x <= menuX + 86 and y >= menuY + 72 and y <= menuY + 96 then
            local entry = nil
            if item.source == "folder" then
                local entries = self:getFolderContents(self.currentFolderName or "")
                entry = entries[item.index]
            elseif item.source == "downloads" then
                local downloads = self:getDownloadedMagazines()
                entry = downloads[item.index]
            end
            if entry and self:isEntryAllowedOnDisc(entry) and self:addEntryToStorage(entry, "__CD__") then
                self.fileNoticeText = tr("Copied to Blank CD (D:).")
                self.fileNoticeTimer = 120
            end
            self.fileItemContextMenu = nil
            return true
        end
        self.fileItemContextMenu = nil
    end
    if self.trashItemContextMenu then
        local menuX = self.trashItemContextMenu.drawX or self.trashItemContextMenu.x
        local menuY = self.trashItemContextMenu.drawY or self.trashItemContextMenu.y
        if x >= menuX and x <= menuX + 86 and y >= menuY and y <= menuY + 24 then
            self:restoreTrashEntry(self.trashItemContextMenu.index)
            self.trashItemContextMenu = nil
            return true
        end
        self.trashItemContextMenu = nil
    end
    if self.paintFileContextMenu then
        local menuX = self.paintFileContextMenu.drawX or self.paintFileContextMenu.x
        local menuY = self.paintFileContextMenu.drawY or self.paintFileContextMenu.y
        if x >= menuX and x <= menuX + 86 and y >= menuY and y <= menuY + 24 then
            self:deletePaintFileByKey(self.paintFileContextMenu.paintKey)
            self.paintFileContextMenu = nil
            return true
        end
        self.paintFileContextMenu = nil
    end
    if self.currentView == "PAINT" then
        local button = self:getPaintButtonAt(x, y)
        if button == "save" then
            self:savePaintDrawing()
            return true
        elseif button == "clear" then
            self:clearPaintDrawing()
            return true
        elseif button == "delete" then
            self:deleteActivePaintDrawing()
            return true
        end
        local color = self:getPaintPaletteAt(x, y)
        if color then
            self.paintColor = color
            return true
        end
        if self:paintCell(x, y) then
            self.paintDrawing = true
            return true
        end
    elseif self.currentView == "NETWORK_TERMINAL" then
        local button = self:getNetworkRepairButtonRect()
        if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
            if not self:isInternetEnabled() and self:isNetworkTerminalRepaired() then
                self:startNetworkRepair()
            end
            return true
        end
        return true
    elseif self.currentView == "NETWORK_REPAIR" then
        return true
    end
    if self.currentView == "FILES" then
        local discSlot = self:getMountedDiscSlot()
        if discSlot and x >= discSlot.x and x <= discSlot.x + discSlot.w and y >= discSlot.y and y <= discSlot.y + discSlot.h then
            if discSlot.gameId == "os" then
                self:showError(tr("This disc must be booted from BIOS."))
                return true
            end
            if discSlot.gameId == "blank" then
                self:openDiscFolder()
                return true
            end
            if discSlot.gameId == "generic" then
                self:showError(tr("This CD has no installer."))
                return true
            end
            if discSlot.gameId == "hack" then
                self:showError(tr("Use this disc from the password screen."))
                return true
            end
            self:openInstallWizard(discSlot.gameId)
            return true
        end
        local folderIndex = self:getFolderIndexAt(x, y)
        if folderIndex then
            if self:getComputerFolders()[folderIndex] == "Downloads" then
                self:openDownloadsFolder()
            else
                self:openFolderView(self:getComputerFolders()[folderIndex])
            end
            return true
        end
    elseif self.currentView == "DESKTOP" then
        local minimizedWindows = self:getMinimizedWindows()
        for i = 1, math.min(#minimizedWindows, 3) do
            local minimizedSlot = self:getMinimizedTaskbarSlot(i)
            if minimizedSlot and x >= minimizedSlot.x and x <= minimizedSlot.x + minimizedSlot.w and y >= minimizedSlot.y and y <= minimizedSlot.y + minimizedSlot.h then
                self:restoreMinimizedWindow(i)
                return true
            end
        end
        local desktopItem = self:getDesktopItemAt(x, y)
        if desktopItem then
            self.desktopDrag = {
                item = desktopItem,
                startX = x,
                startY = y,
                dragging = false
            }
            return true
        end
    elseif self.currentView == "DOWNLOADS" then
        local installerId = self:getDownloadedInstallerAt(x, y)
        if installerId then
            self:openInstallWizard(installerId)
            return true
        end
        local magIndex, magEntry = nil, nil
        local magSlots = self:getDownloadedMagazines()
        local slots = self:getDownloadedInstallerSlots()
        local baseY = self.clientY + 44 + math.ceil(#slots / 3) * 42 + 18
        for i = 1, #magSlots do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local sx = self.clientX + 10 + col * 138
            local sy = baseY + row * 42
            if x >= sx and x <= sx + 128 and y >= sy and y <= sy + 34 then
                magIndex = i
                magEntry = magSlots[i]
                break
            end
        end
        if magIndex and magEntry then
            self:readFolderEntry(magEntry)
            return true
        end
    elseif self.currentView == "BROWSER" then
        local videoId = self:getVideoDownloadAt(x, y)
        if videoId then
            self.browserVideoSelection = videoId
            return true
        end
        local magId = self:getMagazineDownloadAt(x, y)
        if magId then
            self.browserMagazineSelection = magId
            return true
        end
        local linkAddress = self:getBrowserLinkAt(x, y)
        if linkAddress and self.browserAddressEntry then
            self.browserAddressEntry:setText(linkAddress)
            self:navigateBrowser()
            return true
        end
    elseif self.currentView == "MAIL" then
        local mailIndex = self:getMailMessageAt(x, y)
        if mailIndex then
            self:selectMailMessageByIndex(mailIndex)
            self:setMailControlsVisible(true)
            return true
        end
    elseif self.currentView == "CHAT" then
        local contactIndex = self:getChatContactAt(x, y)
        if contactIndex then
            self:selectChatContactByIndex(contactIndex)
            return true
        end
        local requestIndex = self:getChatRequestAt(x, y)
        if requestIndex then
            self:selectChatRequestByIndex(requestIndex)
            return true
        end
        local chatScrollBar = self:getChatMessageScrollBarRect()
        if chatScrollBar and x >= chatScrollBar.x and x <= chatScrollBar.x + chatScrollBar.w and y >= chatScrollBar.y and y <= chatScrollBar.y + chatScrollBar.h then
            local offset = tonumber(self.chatMessageScrollOffset or chatScrollBar.maxOffset) or chatScrollBar.maxOffset
            if y < chatScrollBar.thumbY then
                offset = offset - chatScrollBar.pageSize
            elseif y > chatScrollBar.thumbY + chatScrollBar.thumbH then
                offset = offset + chatScrollBar.pageSize
            end
            self.chatMessageScrollOffset = math.max(0, math.min(chatScrollBar.maxOffset, offset))
            self.chatExpandedMessageIndex = nil
            return true
        end
        local messageIndex = self:getChatMessageAt(x, y)
        if messageIndex then
            if self.chatExpandedMessageIndex == messageIndex then
                self.chatExpandedMessageIndex = nil
            else
                self.chatExpandedMessageIndex = messageIndex
            end
            return true
        else
            self.chatExpandedMessageIndex = nil
        end
    elseif self.currentView == "BOARD" then
        local scrollBar = self:getBoardScrollBarRect()
        if scrollBar and x >= scrollBar.x and x <= scrollBar.x + scrollBar.w and y >= scrollBar.y and y <= scrollBar.y + scrollBar.h then
            local offset = tonumber(self.boardScrollOffset or 0) or 0
            if y < scrollBar.thumbY then
                offset = offset - scrollBar.pageSize
            elseif y > scrollBar.thumbY + scrollBar.thumbH then
                offset = offset + scrollBar.pageSize
            end
            self.boardScrollOffset = math.max(0, math.min(scrollBar.maxOffset, offset))
            self.boardExpandedPostIndex = nil
            return true
        end
        local boardIndex = self:getBoardPostAt(x, y)
        if boardIndex then
            if self.boardExpandedPostIndex == boardIndex then
                self.boardExpandedPostIndex = nil
            else
                self.boardExpandedPostIndex = boardIndex
            end
            return true
        else
            self.boardExpandedPostIndex = nil
        end
    elseif self.currentView == "MARKET" then
        local category = self:getMarketCategoryAt(x, y)
        if category then
            self:selectMarketCategory(category)
            return true
        end
        local item = self:getMarketShopSlotAt(x, y)
        if item then
            self:buyMarketItem(item.id)
            return true
        end
        local job = self:getMarketJobSlotAt(x, y)
        if job then
            self:completeMarketJob(job.id)
            return true
        end
    elseif self.currentView == "MARKET_JOB" then
        local choice = self:getMarketPaperworkButtonAt(x, y)
        if choice then
            self:handleMarketPaperworkChoice(choice)
            return true
        end
    elseif self.currentView == "FOLDER" then
        local itemIndex, itemEntry = self:getFolderItemAt(x, y)
        if itemIndex and itemEntry then
            self:readFolderEntry(itemEntry)
            return true
        end
    elseif self.currentView == "TRASH" then
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function target:onMouseUp(x, y)
    if self.paintDrawing then
        self.paintDrawing = false
        return true
    end
    if self.desktopDrag then
        local drag = self.desktopDrag
        self.desktopDrag = nil
        if drag.dragging then
            local targetSlot = self:getDesktopSlotAt(x, y)
            if targetSlot and drag.item then
                self:moveDesktopItemToSlot(drag.item.key, targetSlot)
            end
        elseif drag.item then
            self:activateDesktopItem(drag.item)
        end
        return true
    end
    if ISPanel.onMouseUp then
        return ISPanel.onMouseUp(self, x, y)
    end
    return true
end

function target:onMouseWheel(del)
    if self.currentView == "BOARD" then
        local posts = self:getBoardPosts()
        local visibleCount = self:getBoardVisibleCount()
        local historyCount = math.min(#posts, 10)
        local maxOffset = math.max(0, historyCount - visibleCount)
        local offset = tonumber(self.boardScrollOffset or 0) or 0
        self.boardScrollOffset = math.max(0, math.min(maxOffset, offset + (tonumber(del) or 0)))
        self.boardExpandedPostIndex = nil
        return true
    end
    if self.currentView == "CHAT" then
        local scrollBar = self:getChatMessageScrollBarRect()
        if scrollBar then
            local offset = tonumber(self.chatMessageScrollOffset or scrollBar.maxOffset) or scrollBar.maxOffset
            self.chatMessageScrollOffset = math.max(0, math.min(scrollBar.maxOffset, offset + (tonumber(del) or 0)))
            self.chatExpandedMessageIndex = nil
        end
        return true
    end
    if ISPanel.onMouseWheel then
        return ISPanel.onMouseWheel(self, del)
    end
    return false
end

function target:onRightMouseDown(x, y)
    if self.currentView == "GAMES" then
        local gameId = self:getGameIconAt(x, y)
        if gameId then
            return self:openGameContextMenu(gameId, x, y)
        end
    end
    if self.currentView == "FILES" then
        local discSlot = self:getMountedDiscSlot()
        if discSlot and x >= discSlot.x and x <= discSlot.x + discSlot.w and y >= discSlot.y and y <= discSlot.y + discSlot.h then
            self.startMenuOpen = false
            self.settingsMenuOpen = false
            self.folderContextMenu = nil
            self.discContextMenu = {x = x, y = y}
            self:updateStartMenuButtons()
            return true
        end
    end
    if self.currentView == "DOWNLOADS" then
        local installers = self:getDownloadedInstallerSlots()
        for i = 1, #installers do
            local slot = installers[i]
            if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
                return ISPanel.onRightMouseDown(self, x, y)
            end
        end
        local mags = self:getDownloadedMagazines()
        local installerRows = math.ceil(#installers / 3)
        local baseY = self.clientY + 44 + installerRows * 42 + 18
        for i = 1, #mags do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local sx = self.clientX + 10 + col * 138
            local sy = baseY + row * 42
            if x >= sx and x <= sx + 128 and y >= sy and y <= sy + 34 then
                self.fileItemContextMenu = {x = x, y = y, source = "downloads", index = i}
                return true
            end
        end
    end
    if self.currentView == "FOLDER" then
        local itemIndex = self:getFolderItemAt(x, y)
        if itemIndex then
            self.fileItemContextMenu = {x = x, y = y, source = "folder", index = itemIndex}
            return true
        end
    end
    if self.currentView == "TRASH" then
        local trashIndex = self:getTrashItemAt(x, y)
        if trashIndex then
            self.trashItemContextMenu = {x = x, y = y, index = trashIndex}
            return true
        end
    end
    if self.currentView == "FILES" or self.currentView == "DESKTOP" then
        if self.currentView == "DESKTOP" then
            local desktopItem = self:getDesktopItemAt(x, y)
            if desktopItem then
                self.startMenuOpen = false
                self.settingsMenuOpen = false
                self.folderContextMenu = nil
                self.discContextMenu = nil
                self.trashContextMenu = nil
                self.paintFileContextMenu = nil
                self.desktopContextMenu = nil
                self.desktopItemContextMenu = {x = x, y = y, item = desktopItem}
                self:updateStartMenuButtons()
                return true
            end
        end
        local folderIndex = self:getFolderIndexAt(x, y)
        if folderIndex then
            if self:getComputerFolders()[folderIndex] == "Downloads" then
                return true
            end
            self.startMenuOpen = false
            self.settingsMenuOpen = false
            self.discContextMenu = nil
            self.folderContextMenu = {x = x, y = y, index = folderIndex}
            self:updateStartMenuButtons()
            return true
        end
        self.desktopContextMenu = {x = x, y = y, allowNote = self.currentView == "DESKTOP"}
        return true
    end
    self.folderContextMenu = nil
    self.discContextMenu = nil
    self.gameContextMenu = nil
    self.desktopContextMenu = nil
    self.desktopItemContextMenu = nil
    self.trashContextMenu = nil
    self.fileItemContextMenu = nil
    self.trashItemContextMenu = nil
    return ISPanel.onRightMouseDown(self, x, y)
end

function target:onMouseMove(dx, dy)
    self.hoverX = self:getMouseX()
    self.hoverY = self:getMouseY()
    if self.paintDrawing and self.currentView == "PAINT" then
        self:paintCell(self.hoverX or 0, self.hoverY or 0)
    end
    if self.desktopDrag and not self.desktopDrag.dragging then
        if math.abs((self.hoverX or 0) - (self.desktopDrag.startX or 0)) > 6 or math.abs((self.hoverY or 0) - (self.desktopDrag.startY or 0)) > 6 then
            self.desktopDrag.dragging = true
        end
    end
    if ISPanel.onMouseMove then return ISPanel.onMouseMove(self, dx, dy) end
    return false
end

function target:onMouseMoveOutside(dx, dy)
    self.hoverX = -1
    self.hoverY = -1
    if self.desktopDrag then
        self.desktopDrag.dragging = true
    end
    if ISPanel.onMouseMoveOutside then return ISPanel.onMouseMoveOutside(self, dx, dy) end
    return false
end

function target:drawFilesPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Drives"), bodyX + 10, bodyY + 8, 0, 0, 0, 1, UIFont.Medium)
    local discSlot = self:getMountedDiscSlot()
    local drivePanelY = bodyY + 34
    local drivePanelH = 74
    local driveGap = 8
    local hasDisc = discSlot ~= nil
    local drivePanelW = hasDisc and math.floor((bodyW - 28) / 2) or (bodyW - 20)
    local cX = bodyX + 10
    local dX = cX + drivePanelW + driveGap

    self:drawRect(cX, drivePanelY, drivePanelW, drivePanelH, 1, 0.92, 0.92, 0.9)
    self:drawRect(cX, drivePanelY, drivePanelW, 1, 1, 1, 1, 1)
    local installedGameCount = #self:getInstalledGames()
    local downloadedSetupCount = #self:getDownloadedInstallers()
    local downloadedMagazineCount = #self:getDownloadedMagazines()
    local usedSpace = 240 + installedGameCount * 8 + downloadedSetupCount * 3 + downloadedMagazineCount * 2
    if self:isOSInstalled() then
        usedSpace = usedSpace + 18
    end
    if usedSpace > 540 then usedSpace = 540 end
    if desktopFilesTexture then
        self:drawTextureScaled(desktopFilesTexture, cX + 8, drivePanelY + 10, 28, 28, 1, 1, 1, 1)
    end
    self:drawTextInWidth(tr("Local Disk (C:)"), cX + 44, drivePanelY + 8, drivePanelW - 50, 0, 0, 0, 1, UIFont.Small, nil, 14)
    self:drawTextInWidth(tr("Used space:"), cX + 44, drivePanelY + 24, drivePanelW - 50, 0.22, 0.22, 0.22, 1, UIFont.Small, nil, 14)
    self:drawTextInWidth(tostring(usedSpace) .. " MB / 540 MB", cX + 44, drivePanelY + 38, drivePanelW - 50, 0.22, 0.22, 0.22, 1, UIFont.Small, nil, 14)
    self:drawRect(cX + 44, drivePanelY + 58, drivePanelW - 56, 10, 1, 0.72, 0.72, 0.72)
    self:drawRect(cX + 46, drivePanelY + 60, math.floor((drivePanelW - 60) * (usedSpace / 540)), 6, 1, 0.12, 0.42, 0.88)

    if hasDisc then
        local discInfo = discSlot.info or gameInstallInfo[discSlot.gameId]
        local discSizeMB = (discInfo and discInfo.discSizeMB) or 8
        local discCapacityMB = (discInfo and discInfo.blank) and 650 or discSizeMB
        local discUsedMB = (discInfo and discInfo.blank) and 0 or discSizeMB
        if discSlot.gameId == "blank" then
            local entries = self:getMountedDiscContents()
            discUsedMB = 0
            for i = 1, #entries do
                local entry = entries[i]
                if entry.type == "video" then
                    discUsedMB = discUsedMB + 8
                elseif entry.type == "paint" then
                    discUsedMB = discUsedMB + 1
                elseif entry.type == "folder" then
                    discUsedMB = discUsedMB + 1
                else
                    discUsedMB = discUsedMB + 0.5
                end
            end
            discUsedMB = math.floor(discUsedMB)
        end
        if discInfo and discInfo.generic then
            discCapacityMB = 650
            discUsedMB = 648
        end
        self:drawRect(dX, drivePanelY, drivePanelW, drivePanelH, 1, 0.92, 0.92, 0.9)
        self:drawRect(dX, drivePanelY, drivePanelW, 1, 1, 1, 1, 1)
        if discInfo and discInfo.texture then
            self:drawTextureScaled(discInfo.texture, dX + 8, drivePanelY + 10, 28, 28, 1, 1, 1, 1)
        elseif cdTexture then
            self:drawTextureScaled(cdTexture, dX + 8, drivePanelY + 10, 28, 28, 1, 1, 1, 1)
        else
            self:drawRect(dX + 10, drivePanelY + 12, 24, 24, 1, 0.8, 0.8, 0.82)
        end
        self:drawTextInWidth((discInfo and discInfo.disc or tr("Game CD")) .. " (D:)", dX + 44, drivePanelY + 8, drivePanelW - 50, 0, 0, 0, 1, UIFont.Small, nil, 14)
        self:drawTextInWidth(tr("Used space:"), dX + 44, drivePanelY + 24, drivePanelW - 50, 0.22, 0.22, 0.22, 1, UIFont.Small, nil, 14)
        self:drawTextInWidth(tostring(discUsedMB) .. " MB / " .. tostring(discCapacityMB) .. " MB", dX + 44, drivePanelY + 38, drivePanelW - 50, 0.22, 0.22, 0.22, 1, UIFont.Small, nil, 14)
        self:drawRect(dX + 44, drivePanelY + 58, drivePanelW - 56, 10, 1, 0.72, 0.72, 0.72)
        if discUsedMB > 0 then
            self:drawRect(dX + 46, drivePanelY + 60, drivePanelW - 60, 6, 1, 0.84, 0.64, 0.18)
        end
    end

    local foldersHeaderY = drivePanelY + drivePanelH + 10
    if self.fileNoticeText and self.fileNoticeText ~= "" then
        self:drawText(self.fileNoticeText, bodyX + 10, foldersHeaderY - 16, 0.55, 0.08, 0.08, 1, UIFont.Small)
    end
    self:drawText(tr("Folders"), bodyX + 10, foldersHeaderY, 0, 0, 0, 1, UIFont.Small)
    local folderNames = self:getComputerFolders()
    if #folderNames == 0 then
        self:drawText(tr("No folders found."), bodyX + 16, foldersHeaderY + 24, 0.3, 0.3, 0.3, 1, UIFont.Small)
        return
    end
    for i = 1, #folderNames do
        local fx = bodyX + 16 + ((i - 1) % 3) * 132
        local fy = foldersHeaderY + 14 + math.floor((i - 1) / 3) * 28
        if self.hoverX and self.hoverY and self.hoverX >= fx and self.hoverX <= fx + 112 and self.hoverY >= fy and self.hoverY <= fy + 24 then
            self:drawRect(fx - 4, fy - 2, 120, 26, 0.15, 0.55, 0.55, 0.55)
        end
        if desktopFolderTexture then
            self:drawTextureScaled(desktopFolderTexture, fx, fy, 28, 22, 1, 1, 1, 1)
        end
        self:drawTextInWidth(folderNames[i], fx + 38, fy + 4, 74, 0.05, 0.05, 0.05, 1, UIFont.Small)
    end
end

function target:drawDownloadsPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Downloads"), bodyX + 10, bodyY + 8, 0, 0, 0, 1, UIFont.Medium)
    local installers = self:getDownloadedInstallers()
    local magazines = self:getDownloadedMagazines()
    if #installers == 0 and #magazines == 0 then
        self:drawText(tr("No downloaded setup files."), bodyX + 16, bodyY + 44, 0.3, 0.3, 0.3, 1, UIFont.Small)
        return
    end
    local slots = self:getDownloadedInstallerSlots()
    for i = 1, #slots do
        local slot = slots[i]
        local info = gameInstallInfo[slot.gameId]
        if self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x - 2, slot.y - 2, slot.w + 4, slot.h + 4, 0.15, 0.55, 0.55, 0.55)
        end
        self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.9, 0.9, 0.88)
        self:drawRect(slot.x, slot.y, slot.w, 1, 1, 1, 1, 1)
        self:drawRect(slot.x + 6, slot.y + 6, 20, 22, 1, 0.72, 0.72, 0.78)
        self:drawRect(slot.x + 10, slot.y + 10, 12, 2, 1, 0.16, 0.16, 0.28)
        self:drawTextInWidth((info and info.label or "Game") .. " Setup.exe", slot.x + 34, slot.y + 6, slot.w - 40, 0.04, 0.04, 0.04, 1, UIFont.Small, nil, 14)
        self:drawTextInWidth(self:isGameInstalled(slot.gameId) and tr("Installed") or tr("Ready to install"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
    end
    local headerY = bodyY + 44 + math.ceil(#slots / 3) * 42 + 2
    if #magazines > 0 then
        self:drawText(tr("Documents"), bodyX + 10, headerY, 0, 0, 0, 1, UIFont.Small)
        for i = 1, #magazines do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local sx = self.clientX + 10 + col * 138
            local sy = headerY + 18 + row * 42
            local entry = magazines[i]
            if self.hoverX and self.hoverY and self.hoverX >= sx and self.hoverX <= sx + 128 and self.hoverY >= sy and self.hoverY <= sy + 34 then
                self:drawRect(sx - 2, sy - 2, 132, 38, 0.15, 0.55, 0.55, 0.55)
            end
            self:drawRect(sx, sy, 128, 34, 1, 0.9, 0.9, 0.88)
            local tex = self:getReadableEntryIconTexture(entry)
            if tex then
                self:drawTextureScaled(tex, sx + 6, sy + 5, 22, 22, 1, 1, 1, 1)
            end
            self:drawTextInWidth(self:getReadableEntryDisplayName(entry), sx + 34, sy + 6, 88, 0.04, 0.04, 0.04, 1, UIFont.Small, nil, 14)
            if entry.type == "video" then
                self:drawTextInWidth(tr("Double click to watch"), sx + 34, sy + 20, 88, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
            else
                self:drawTextInWidth(tr("Double click to read"), sx + 34, sy + 20, 88, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
            end
        end
    end
    if self.magazineReadInProgress and self.magazineReadEntry then
        local ratio = math.min(1, (self.magazineReadTimer or 0) / (self.magazineReadDuration or 1))
        self:drawText(tr("Reading") .. " " .. self:getReadableEntryDisplayName(self.magazineReadEntry), bodyX + 10, bodyY + bodyH - 32, 0.08, 0.08, 0.08, 1, UIFont.Small)
        self:drawRect(bodyX + 150, bodyY + bodyH - 30, bodyW - 164, 10, 1, 0.72, 0.72, 0.72)
        self:drawRect(bodyX + 152, bodyY + bodyH - 28, math.floor((bodyW - 168) * ratio), 6, 1, 0.12, 0.42, 0.88)
    end
end

function target:drawFolderPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(self:getStorageDisplayName(self.currentFolderName or tr("Folder")), bodyX + 10, bodyY + 8, 0, 0, 0, 1, UIFont.Medium)
    local entries = self:getFolderContents(self.currentFolderName or "")
    if #entries == 0 then
        self:drawText(tr("This folder is empty."), bodyX + 16, bodyY + 44, 0.3, 0.3, 0.3, 1, UIFont.Small)
        return
    end
    local slots = self:getFolderItemSlots()
    for i = 1, #slots do
        local slot = slots[i]
        local entry = slot.entry
        if self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x - 2, slot.y - 2, slot.w + 4, slot.h + 4, 0.15, 0.55, 0.55, 0.55)
        end
        self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.9, 0.9, 0.88)
        local tex = self:getReadableEntryIconTexture(entry)
        if tex then
            self:drawTextureScaled(tex, slot.x + 6, slot.y + 5, 22, 22, 1, 1, 1, 1)
        end
        self:drawTextInWidth(self:getReadableEntryDisplayName(entry), slot.x + 34, slot.y + 6, slot.w - 40, 0.04, 0.04, 0.04, 1, UIFont.Small, nil, 14)
        if entry.type == "app" then
            self:drawTextInWidth("Application shortcut", slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        elseif entry.type == "folder" then
            self:drawTextInWidth("Folder shortcut", slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        elseif entry.type == "note" then
            self:drawTextInWidth(tr("Text note"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        elseif entry.type == "paint" then
            self:drawTextInWidth(tr("Paint drawing"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        elseif entry.type == "video" then
            self:drawTextInWidth(tr("Watch for comfort"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        elseif entry.type == "newspaper" then
            self:drawTextInWidth(tr("Read for comfort"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        else
            self:drawTextInWidth(tr("Read to learn recipes"), slot.x + 34, slot.y + 20, slot.w - 40, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 14)
        end
    end
    if self.magazineReadInProgress and self.magazineReadEntry then
        local ratio = math.min(1, (self.magazineReadTimer or 0) / (self.magazineReadDuration or 1))
        self:drawText(tr("Reading") .. " " .. self:getReadableEntryDisplayName(self.magazineReadEntry), bodyX + 10, bodyY + bodyH - 32, 0.08, 0.08, 0.08, 1, UIFont.Small)
        self:drawRect(bodyX + 150, bodyY + bodyH - 30, bodyW - 164, 10, 1, 0.72, 0.72, 0.72)
        self:drawRect(bodyX + 152, bodyY + bodyH - 28, math.floor((bodyW - 168) * ratio), 6, 1, 0.12, 0.42, 0.88)
    end
end

function target:drawSettingsPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    local navX = bodyX + 12
    local navW = 96
    local panelX = navX + navW + 22
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawRect(navX + navW + 10, bodyY + 6, 1, bodyH - 12, 1, 0.72, 0.72, 0.72)
    local avatar = self:getComputerAvatar()
    if self.settingsCategory == "security" then
        self:drawText(tr("Computer password"), panelX, bodyY + 24, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Set or clear the local password."), panelX, bodyY + 46, 0.22, 0.22, 0.22, 1, UIFont.Small)
    elseif self.settingsCategory == "system" then
        self:drawText(tr("Music and clock"), panelX, bodyY + 24, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("These settings are saved per computer."), panelX, bodyY + 46, 0.22, 0.22, 0.22, 1, UIFont.Small)
        self:drawText(tr("Playback"), panelX, bodyY + 78, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Date order"), panelX, bodyY + 128, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Debug mode"), panelX, bodyY + 178, 0.05, 0.05, 0.05, 1, UIFont.Small)
        local player = self.playerObj or getPlayer and getPlayer() or nil
        if ComputerModDebug and ComputerModDebug.isAdmin and not ComputerModDebug.isAdmin(player) then
            self:drawText(tr("Admin required."), panelX, bodyY + 226, 0.72, 0.08, 0.08, 1, UIFont.Small)
        end
    elseif self.settingsCategory == "display" then
        self:drawText(tr("Desktop color"), panelX, bodyY + 24, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Pick a background color for this computer."), panelX, bodyY + 46, 0.22, 0.22, 0.22, 1, UIFont.Small)
        for i = 1, #backgroundPalettes do
            local palette = backgroundPalettes[i]
            local x = panelX + (i - 1) * 32
            local y = self.clientY + 76
            if i == self:getBackgroundPaletteIndex() then
                self:drawRect(x - 2, y - 2, 28, 24, 1, 0.1, 0.35, 0.85)
            end
            self:drawRect(x, y, 24, 20, 1, palette.r, palette.g, palette.b)
        end
        self:drawText(tr("Text size"), panelX, bodyY + 116, 0.05, 0.05, 0.05, 1, UIFont.Small)
    else
        self:drawText(tr("User name"), panelX, bodyY + 24, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Profile picture"), panelX, bodyY + 96, 0.05, 0.05, 0.05, 1, UIFont.Small)
        for i = 1, 6 do
            local x = panelX + (i - 1) * 32
            local y = self.clientY + 144
            if i == avatar then
                self:drawRect(x - 2, y - 2, 30, 28, 1, 0.1, 0.35, 0.85)
            end
            if userTextures[i] then
                self:drawTextureScaled(userTextures[i], x + 3, y + 2, 22, 22, 1, 1, 1, 1)
            end
        end
    end
end

function target:getChatContactSlots()
    local slots = {}
    local contacts = self:getChatContacts()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local listX = bodyX + 10
    local listY = bodyY + 62
    local listW = 170
    for i = 1, math.min(#contacts, 6) do
        local rowY = listY + (i - 1) * 28
        slots[i] = {x = listX, y = rowY, w = listW, h = 24, contact = contacts[i]}
    end
    return slots
end

function target:getChatContactAt(x, y)
    local slots = self:getChatContactSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return i
        end
    end
    return nil
end

function target:getChatRequestSlots()
    local slots = {}
    local requests = self:getChatRequests()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local listX = bodyX + 10
    local listY = bodyY + self.clientH - 102
    local listW = 170
    for i = 1, math.min(#requests, 2) do
        local rowY = listY + (i - 1) * 28
        slots[i] = {x = listX, y = rowY, w = listW, h = 24, request = requests[i]}
    end
    return slots
end

function target:getChatRequestAt(x, y)
    local slots = self:getChatRequestSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return i
        end
    end
    return nil
end

function target:getChatMessageSlots()
    local slots = {}
    local partner = self:getSelectedChatPartner()
    if not partner then
        return slots
    end
    local layout = self:getChatMessageLayout()
    local window = self:getChatMessageWindow(layout.visibleCount)
    if window.historyCount <= 0 then return slots end
    local rowIndex = 1
    local slotW = layout.chatW - (window.hasScroll and 36 or 20)
    for i = window.startIndex, window.endIndex do
        local message = window.conversation[i]
        if type(message) == "table" then
            local rowY = layout.rowTop + (rowIndex - 1) * layout.rowH
            slots[#slots + 1] = {
                x = layout.chatX + 10,
                y = rowY,
                w = slotW,
                h = 30,
                message = message,
                messageIndex = i
            }
            rowIndex = rowIndex + 1
        end
    end
    return slots
end

function target:getChatMessageLayout()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    local leftX = bodyX + 10
    local leftW = 170
    local chatX = leftX + leftW + 12
    local chatY = bodyY + 62
    local chatW = bodyW - (chatX - bodyX) - 10
    local messageInputTop = self.chatMessageEntry and self.chatMessageEntry:getY() or (bodyY + bodyH - 70)
    local messageAreaH = math.max(84, messageInputTop - chatY - 10)
    local rowTop = chatY + 36
    local rowH = 36
    local visibleCount = math.min(10, math.max(1, math.floor((messageAreaH - 48) / rowH)))
    return {
        bodyX = bodyX,
        bodyY = bodyY,
        bodyW = bodyW,
        bodyH = bodyH,
        chatX = chatX,
        chatY = chatY,
        chatW = chatW,
        messageAreaH = messageAreaH,
        rowTop = rowTop,
        rowH = rowH,
        visibleCount = visibleCount
    }
end

function target:getChatMessageWindow(visibleCount)
    local conversation = self:getChatConversation()
    visibleCount = math.max(1, math.min(10, tonumber(visibleCount or 1) or 1))
    local historyCount = math.min(#conversation, 10)
    local historyStart = math.max(1, #conversation - historyCount + 1)
    local maxOffset = math.max(0, historyCount - visibleCount)
    local previousMaxOffset = tonumber(self.chatMessageLastMaxOffset or maxOffset) or maxOffset
    local offset = tonumber(self.chatMessageScrollOffset)
    if offset == nil or offset >= previousMaxOffset then
        offset = maxOffset
    end
    offset = math.max(0, math.min(maxOffset, tonumber(offset or 0) or 0))
    self.chatMessageScrollOffset = offset
    self.chatMessageLastMaxOffset = maxOffset
    local drawCount = math.min(visibleCount, historyCount - offset)
    local endIndex = drawCount > 0 and (historyStart + offset + drawCount - 1) or 0
    return {
        conversation = conversation,
        historyCount = historyCount,
        startIndex = historyStart + offset,
        endIndex = endIndex,
        maxOffset = maxOffset,
        offset = offset,
        hasScroll = historyCount > visibleCount,
        pageSize = visibleCount
    }
end

function target:getChatMessageScrollBarRect()
    if not self:getSelectedChatPartner() then return nil end
    local layout = self:getChatMessageLayout()
    local window = self:getChatMessageWindow(layout.visibleCount)
    if not window.hasScroll then return nil end
    local trackY = layout.rowTop
    local trackH = math.max(24, (layout.visibleCount * layout.rowH) - 6)
    local thumbH = math.max(18, math.floor(trackH * layout.visibleCount / window.historyCount))
    local thumbY = trackY
    if window.maxOffset > 0 then
        thumbY = trackY + math.floor((trackH - thumbH) * window.offset / window.maxOffset)
    end
    return {
        x = layout.chatX + layout.chatW - 18,
        y = trackY,
        w = 8,
        h = trackH,
        thumbY = thumbY,
        thumbH = thumbH,
        maxOffset = window.maxOffset,
        pageSize = window.pageSize
    }
end

function target:getChatMessageAt(x, y)
    local slots = self:getChatMessageSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return slot.messageIndex
        end
    end
    return nil
end

function target:drawChatPage()
    if self.isInternetEnabled and not self:isInternetEnabled() then
        self:drawNoInternetPage("Chat")
        return
    end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawTextInWidth(tr("Knox Messenger"), bodyX + 10, bodyY + 8, bodyW - 20, 0, 0, 0, 1, UIFont.Medium, "center")
    if self.accountRecoveryService == "chat" then
        self:drawText(tr("User name"), bodyX + 18, bodyY + 52, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("New password"), bodyX + 18, bodyY + 86, 96, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Enter a new password for this account."), bodyX + 18, bodyY + 126, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 18, bodyY + 154, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
        return
    end
    if not self:isChatLoggedIn() then
        self:drawText(tr("User name"), bodyX + 18, bodyY + 52, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Password"), bodyX + 18, bodyY + 86, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Recovery email"), bodyX + 18, bodyY + 120, 96, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Create an account or sign in from any computer."), bodyX + 18, bodyY + 190, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        self:drawTextInWidth(tr("User names use letters, numbers, dots, dashes or underscores."), bodyX + 18, bodyY + 208, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 18, bodyY + 232, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
        return
    end

    if self.chatRequestMode then
        self:drawText(tr("Add contact"), bodyX + 10, bodyY + 40, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Enter another user's account name."), bodyX + 10, bodyY + 72, 0.22, 0.22, 0.22, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 10, bodyY + 104, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
        return
    end

    local leftX = bodyX + 10
    local leftY = bodyY + 62
    local leftW = 170
    local chatX = leftX + leftW + 12
    local chatY = leftY
    local chatW = bodyW - (chatX - bodyX) - 10
    local messageInputTop = self.chatMessageEntry and self.chatMessageEntry:getY() or (bodyY + bodyH - 70)
    local messageAreaH = math.max(84, messageInputTop - chatY - 10)
    self:drawRect(leftX, leftY, leftW, bodyH - 76, 1, 0.90, 0.90, 0.88)
    self:drawRect(chatX, chatY, chatW, messageAreaH, 1, 0.98, 0.98, 0.96)
    self:drawRect(chatX, chatY, chatW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Contacts"), leftX + 4, bodyY + 40, 0.05, 0.05, 0.05, 1, UIFont.Small)
    self:drawText(tr("Requests"), leftX + 4, bodyY + bodyH - 122, 0.05, 0.05, 0.05, 1, UIFont.Small)

    local contactSlots = self:getChatContactSlots()
    for i = 1, #contactSlots do
        local slot = contactSlots[i]
        local contact = slot.contact
        local selected = self.chatSelectedUser and contact.username == self.chatSelectedUser
        if selected then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.76, 0.82, 0.94)
        elseif self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.82, 0.82, 0.8)
        end
        self:drawTextInWidth(contact.displayName or contact.username, slot.x + 6, slot.y + 5, slot.w - 12, 0.05, 0.05, 0.05, 1, UIFont.Small)
    end

    local requestSlots = self:getChatRequestSlots()
    for i = 1, #requestSlots do
        local slot = requestSlots[i]
        local request = slot.request
        local selected = self.chatSelectedRequestUser and request.from == self.chatSelectedRequestUser
        if selected then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.85, 0.80, 0.62)
        elseif self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.82, 0.82, 0.8)
        end
        self:drawTextInWidth(request.displayName or request.from, slot.x + 6, slot.y + 5, slot.w - 12, 0.05, 0.05, 0.05, 1, UIFont.Small)
    end

    local partner = self:getSelectedChatPartner()
    local conversation = self:getChatConversation()
    if partner then
        self:drawTextInWidth(partner.displayName or partner.username, chatX + 10, chatY + 8, chatW - 20, 0.05, 0.05, 0.05, 1, UIFont.Medium)
        self:drawRect(chatX + 10, chatY + 28, chatW - 20, 1, 1, 0.76, 0.76, 0.76)
        local messageSlots = self:getChatMessageSlots()
        for i = 1, #messageSlots do
            local slot = messageSlots[i]
            local entry = slot.message
            if type(entry) == "table" then
                local isSelf = entry.from == self:getActiveChatUser()
                local who = isSelf and tr("You") or tostring(partner.displayName or partner.username)
                local bodyLines = self:wrapTextLines(tostring(entry.body or ""), UIFont.Small, slot.w - 14, 1)
                if self.chatExpandedMessageIndex == slot.messageIndex then
                    self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.79, 0.86, 0.95)
                elseif isSelf then
                    self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.86, 0.91, 0.99)
                else
                    self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.92, 0.92, 0.9)
                end
                self:drawTextInWidth(who .. " [" .. tostring(entry.stamp or "") .. "]", slot.x + 6, slot.y + 3, slot.w - 12, 0.10, 0.10, 0.10, 1, UIFont.Small, nil, 13)
                self:drawTextInWidth((bodyLines[1] or ""), slot.x + 6, slot.y + 16, slot.w - 12, 0.16, 0.16, 0.16, 1, UIFont.Small, nil, 13)
            end
        end
        local chatScrollBar = self:getChatMessageScrollBarRect()
        if chatScrollBar then
            self:drawRect(chatScrollBar.x, chatScrollBar.y, chatScrollBar.w, chatScrollBar.h, 1, 0.76, 0.76, 0.73)
            self:drawRect(chatScrollBar.x + 1, chatScrollBar.thumbY, chatScrollBar.w - 2, chatScrollBar.thumbH, 1, 0.34, 0.34, 0.32)
        end
        local expandedIndex = self.chatExpandedMessageIndex
        local expandedEntry = expandedIndex and conversation[expandedIndex] or nil
        if type(expandedEntry) == "table" then
            local popupW = math.min(chatW - 24, 320)
            local popupX = chatX + chatW - popupW - 10
            local popupLines = self:wrapTextLines(tostring(expandedEntry.body or ""), UIFont.Small, popupW - 18, 10)
            local popupLineHeight = getTextLineHeight(UIFont.Small)
            local popupH = 30 + (#popupLines * popupLineHeight)
            local popupY = math.max(chatY + 34, chatY + messageAreaH - popupH - 8)
            self:drawRect(popupX, popupY, popupW, popupH, 1, 0.98, 0.97, 0.90)
            self:drawRect(popupX, popupY, popupW, 1, 1, 0.64, 0.64, 0.46)
            self:drawText(tr("Message details"), popupX + 8, popupY + 6, 0.12, 0.12, 0.12, 1, UIFont.Small)
            for i = 1, #popupLines do
                self:drawTextInWidth(popupLines[i], popupX + 8, popupY + 24 + (i - 1) * popupLineHeight, popupW - 16, 0.16, 0.16, 0.16, 1, UIFont.Small)
            end
        end
    elseif #requestSlots > 0 then
        self:drawTextInWidth(tr("Select a request and accept it to start chatting."), chatX + 10, chatY + 10, chatW - 20, 0.25, 0.25, 0.25, 1, UIFont.Small)
    else
        self:drawTextInWidth(tr("No contacts yet. Add someone to start a chat."), chatX + 10, chatY + 10, chatW - 20, 0.25, 0.25, 0.25, 1, UIFont.Small)
    end
    if self.fileNoticeText and self.fileNoticeText ~= "" then
        self:drawText(self.fileNoticeText, chatX + 10, bodyY + bodyH - 86, 0.55, 0.08, 0.08, 1, UIFont.Small)
    end
end

function target:getMailMessageSlots()
    local slots = {}
    local messages = self:getMailMessages()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local listX = bodyX + 10
    local listY = bodyY + 58
    local listW = 172
    for i = 1, math.min(#messages, 7) do
        local rowY = listY + (i - 1) * 36
        slots[i] = {x = listX, y = rowY, w = listW, h = 32, message = messages[i]}
    end
    return slots
end

function target:getMailMessageAt(x, y)
    local slots = self:getMailMessageSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return i
        end
    end
    return nil
end

function target:drawMailPage()
    if self.isInternetEnabled and not self:isInternetEnabled() then
        self:drawNoInternetPage("Mail")
        return
    end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawTextInWidth(tr("County Mail"), bodyX + 10, bodyY + 8, bodyW - 20, 0, 0, 0, 1, UIFont.Medium, "center")
    if not self:isMailLoggedIn() then
        self:drawText(tr("Email"), bodyX + 18, bodyY + 52, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Password"), bodyX + 18, bodyY + 86, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(self:hasMailAccount() and tr("Use an existing mailbox or create a new one.") or tr("Create a mailbox or sign in to one that already exists."), bodyX + 18, bodyY + 126, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        self:drawTextInWidth(tr("Address format must include @ and a server name."), bodyX + 18, bodyY + 144, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 18, bodyY + 168, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
        return
    end

    if self.mailComposeMode then
        self:drawText(tr("To"), bodyX + 10, bodyY + 40, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Subject"), bodyX + 10, bodyY + 68, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Message"), bodyX + 10, bodyY + 98, 0.05, 0.05, 0.05, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 10, bodyY + bodyH - 18, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
        return
    end

    local listX = bodyX + 10
    local listY = bodyY + 58
    local listW = 172
    local previewX = listX + listW + 12
    local previewY = listY
    local previewW = bodyW - (previewX - bodyX) - 10
    local previewH = bodyH - 62
    self:drawRect(listX, listY, listW, bodyH - 62, 1, 0.90, 0.90, 0.88)
    self:drawRect(previewX, previewY, previewW, previewH, 1, 0.98, 0.98, 0.96)
    self:drawRect(previewX, previewY, previewW, 1, 1, 0.76, 0.76, 0.76)

    local slots = self:getMailMessageSlots()
    for i = 1, #slots do
        local slot = slots[i]
        local mail = slot.message
        local selected = self.mailSelectedMessageId and tonumber(mail.id or 0) == tonumber(self.mailSelectedMessageId or 0)
        if selected then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.76, 0.82, 0.94)
        elseif self.hoverX and self.hoverY and self.hoverX >= slot.x and self.hoverX <= slot.x + slot.w and self.hoverY >= slot.y and self.hoverY <= slot.y + slot.h then
            self:drawRect(slot.x + 2, slot.y + 2, slot.w - 4, slot.h - 4, 1, 0.82, 0.82, 0.8)
        end
        self:drawTextInWidth(mail.subject or tr("Mail"), slot.x + 6, slot.y + 4, slot.w - 12, 0.05, 0.05, 0.05, 1, UIFont.Small, nil, 13)
        self:drawTextInWidth(mail.from or "", slot.x + 6, slot.y + 17, slot.w - 12, 0.25, 0.25, 0.25, 1, UIFont.Small, nil, 13)
    end

    local selected = self:getSelectedMailMessage()
    if selected then
        self:drawTextInWidth(selected.subject or tr("Mail"), previewX + 10, previewY + 8, previewW - 20, 0.05, 0.05, 0.05, 1, UIFont.Medium)
        self:drawTextInWidth(tr("From:") .. " " .. tostring(selected.from or ""), previewX + 10, previewY + 34, previewW - 96, 0.18, 0.18, 0.18, 1, UIFont.Small)
        if selected.stamp and selected.stamp ~= "" then
            self:drawTextInWidth(selected.stamp, previewX + previewW - 78, previewY + 34, 68, 0.18, 0.18, 0.18, 1, UIFont.Small, "right")
        end
        self:drawRect(previewX + 10, previewY + 54, previewW - 20, 1, 1, 0.76, 0.76, 0.76)
        local mailLineHeight = getTextLineHeight(UIFont.Small)
        local bodyLines = self:wrapTextLines(selected.body or "", UIFont.Small, previewW - 20, math.max(1, math.floor((previewH - 86) / mailLineHeight)))
        for i = 1, #bodyLines do
            self:drawTextInWidth(bodyLines[i], previewX + 10, previewY + 64 + (i - 1) * mailLineHeight, previewW - 20, 0.12, 0.12, 0.12, 1, UIFont.Small)
        end
    else
        self:drawText(tr("Inbox is empty."), previewX + 10, previewY + 10, 0.25, 0.25, 0.25, 1, UIFont.Small)
    end
    if self.fileNoticeText and self.fileNoticeText ~= "" then
        self:drawText(self.fileNoticeText, previewX + 10, previewY + previewH - 18, 0.55, 0.08, 0.08, 1, UIFont.Small)
    end
end

function target:drawMusicPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawRect(bodyX + 18, bodyY + 20, bodyW - 36, 52, 1, 0.10, 0.10, 0.12)
    self:drawText(tr("Music Player"), bodyX + 18, bodyY + 28, 0.82, 0.90, 1, 1, UIFont.Medium)
    self:drawText(tr("No disc loaded"), bodyX + 18, bodyY + 50, 0.72, 0.76, 0.82, 1, UIFont.Small)
    self:drawRect(bodyX + 18, bodyY + 92, bodyW - 36, 10, 1, 0.72, 0.72, 0.72)
    self:drawRect(bodyX + 18, bodyY + 124, 30, 22, 1, 0.82, 0.82, 0.82)
    self:drawRect(bodyX + 56, bodyY + 124, 30, 22, 1, 0.82, 0.82, 0.82)
    self:drawRect(bodyX + 94, bodyY + 124, 30, 22, 1, 0.82, 0.82, 0.82)
    self:drawText(tr("Music integration later."), bodyX + 18, bodyY + bodyH - 24, 0.32, 0.32, 0.32, 1, UIFont.Small)
end

function target:drawTrashPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Trash"), bodyX + 10, bodyY + 8, 0, 0, 0, 1, UIFont.Medium)
    local trash = self:getTrashEntries()
    if #trash == 0 then
        self:drawText(tr("Trash is empty."), bodyX + 18, bodyY + 44, 0.25, 0.25, 0.25, 1, UIFont.Small)
        self:drawText(tr("Right click the desktop trash icon to empty it."), bodyX + 18, bodyY + 64, 0.25, 0.25, 0.25, 1, UIFont.Small)
        return
    end
    for i = 1, math.min(#trash, 8) do
        local entry = trash[i]
        local label = entry.name or self:getReadableEntryDisplayName(entry)
        local rowY = bodyY + 34 + (i - 1) * 24
        if entry.type == "folder" then
            if desktopFolderTexture then
                self:drawTextureScaled(desktopFolderTexture, bodyX + 18, rowY, 20, 16, 1, 1, 1, 1)
            end
        elseif entry.type == "paint" then
            if desktopPaintTexture then
                self:drawTextureScaled(desktopPaintTexture, bodyX + 18, rowY - 4, 20, 20, 1, 1, 1, 1)
            end
        else
            local tex = self:getReadableEntryIconTexture(entry)
            if tex then
                self:drawTextureScaled(tex, bodyX + 18, rowY - 2, 18, 18, 1, 1, 1, 1)
            end
        end
        self:drawText(label, bodyX + 44, rowY, 0.08, 0.08, 0.08, 1, UIFont.Small)
    end
end

function target:getBoardVisibleCount()
    local availableListH = self.clientH - 134
    local rowH = 28
    return math.max(0, math.floor((availableListH - 8) / rowH))
end

function target:getBoardScrollBarRect()
    local posts = self:getBoardPosts()
    local visibleCount = self:getBoardVisibleCount()
    local historyCount = math.min(#posts, 10)
    if visibleCount <= 0 or historyCount <= visibleCount then return nil end
    local maxOffset = historyCount - visibleCount
    local offset = math.max(0, math.min(maxOffset, tonumber(self.boardScrollOffset or 0) or 0))
    self.boardScrollOffset = offset
    local trackY = self.clientY + 132
    local trackH = math.max(24, self.clientH - 150)
    local thumbH = math.max(18, math.floor(trackH * visibleCount / historyCount))
    local thumbY = trackY + math.floor((trackH - thumbH) * offset / maxOffset)
    return {
        x = self.clientX + self.clientW - 20,
        y = trackY,
        w = 8,
        h = trackH,
        thumbY = thumbY,
        thumbH = thumbH,
        maxOffset = maxOffset,
        pageSize = visibleCount
    }
end

function target:getBoardPostSlots()
    local slots = {}
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local posts = self:getBoardPosts()
    local listY = bodyY + 124
    local rowH = 28
    local maxPosts = self:getBoardVisibleCount()
    local historyCount = math.min(#posts, 10)
    local maxOffset = math.max(0, historyCount - maxPosts)
    local offset = math.max(0, math.min(maxOffset, tonumber(self.boardScrollOffset or 0) or 0))
    self.boardScrollOffset = offset
    local drawCount = math.min(maxPosts, historyCount - offset)
    local hasScroll = historyCount > maxPosts
    for i = 1, drawCount do
        local postIndex = offset + i
        local rowY = listY + 8 + (i - 1) * rowH
        slots[i] = {
            x = bodyX + 14,
            y = rowY,
            w = bodyW - (hasScroll and 46 or 28),
            h = 22,
            post = posts[postIndex],
            postIndex = postIndex
        }
    end
    return slots
end

function target:getBoardPostAt(x, y)
    local slots = self:getBoardPostSlots()
    for i = 1, #slots do
        local slot = slots[i]
        if x >= slot.x and x <= slot.x + slot.w and y >= slot.y and y <= slot.y + slot.h then
            return slot.postIndex
        end
    end
    return nil
end

function target:drawBoardPage()
    if self.isInternetEnabled and not self:isInternetEnabled() then
        self:drawNoInternetPage(tr("Town Board"))
        return
    end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    local posts = self:getBoardPosts()
    local listY = bodyY + 124
    local availableListH = bodyH - 134
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Town Board"), bodyX + 10, bodyY + 8, 0, 0, 0, 1, UIFont.Medium)
    self:drawText(tr("Name"), bodyX + 10, bodyY + 38, 0.05, 0.05, 0.05, 1, UIFont.Small)
    self:drawText(tr("Post a short public message for everyone on the server."), bodyX + 10, bodyY + 108, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawRect(bodyX + 10, listY, bodyW - 20, availableListH, 1, 0.98, 0.98, 0.96)
    local slots = self:getBoardPostSlots()
    for i = 1, #slots do
        local slot = slots[i]
        local post = slot.post
        local bodyText = tostring(post.body or "")
        if #bodyText > 48 then
            bodyText = string.sub(bodyText, 1, 45) .. "..."
        end
        if self.boardExpandedPostIndex == slot.postIndex then
            self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.79, 0.86, 0.95)
        else
            self:drawRect(slot.x, slot.y, slot.w, slot.h, 1, 0.90, 0.90, 0.88)
        end
        self:drawTextInWidth((post.name or tr("Anonymous")) .. "  [" .. tostring(post.stamp or "") .. "]", slot.x + 6, slot.y + 3, 170, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(bodyText, slot.x + 182, slot.y + 3, slot.w - 190, 0.18, 0.18, 0.18, 1, UIFont.Small)
    end
    local scrollBar = self:getBoardScrollBarRect()
    if scrollBar then
        self:drawRect(scrollBar.x, scrollBar.y, scrollBar.w, scrollBar.h, 1, 0.76, 0.76, 0.73)
        self:drawRect(scrollBar.x + 1, scrollBar.thumbY, scrollBar.w - 2, scrollBar.thumbH, 1, 0.34, 0.34, 0.32)
    end
    if #posts == 0 then
        self:drawText(tr("No public posts yet."), bodyX + 18, listY + 12, 0.25, 0.25, 0.25, 1, UIFont.Small)
    end
    local expanded = self.boardExpandedPostIndex and posts[self.boardExpandedPostIndex] or nil
    if expanded then
        local popupW = math.min(bodyW - 40, 336)
        local popupX = bodyX + bodyW - popupW - 18
        local popupLines = self:wrapTextLines(tostring(expanded.body or ""), UIFont.Small, popupW - 18, 10)
        local popupLineHeight = getTextLineHeight(UIFont.Small)
        local popupH = 30 + (#popupLines * popupLineHeight)
        local popupY = math.max(bodyY + 30, listY + availableListH - popupH - 10)
        self:drawRect(popupX, popupY, popupW, popupH, 1, 0.98, 0.97, 0.90)
        self:drawRect(popupX, popupY, popupW, 1, 1, 0.64, 0.64, 0.46)
        self:drawText(tr("Post details"), popupX + 8, popupY + 6, 0.12, 0.12, 0.12, 1, UIFont.Small)
        for i = 1, #popupLines do
            self:drawTextInWidth(popupLines[i], popupX + 8, popupY + 24 + (i - 1) * popupLineHeight, popupW - 16, 0.16, 0.16, 0.16, 1, UIFont.Small)
        end
    end
    if self.fileNoticeText and self.fileNoticeText ~= "" then
        self:drawText(self.fileNoticeText, bodyX + 10, bodyY + bodyH - 18, 0.55, 0.08, 0.08, 1, UIFont.Small)
    end
end

function target:drawFolderEditPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    local creatingNote = self.folderEditMode == "create_note"
    local renamingCD = self.folderEditMode == "rename_cd"
    self:drawText(renamingCD and tr("Rename CD") or (self.folderEditMode == "rename" and tr("Rename folder") or (creatingNote and tr("Create note") or tr("Create folder"))), bodyX + 12, bodyY + 14, 0.12, 0.12, 0.12, 1, UIFont.Medium)
    self:drawText(renamingCD and tr("CD name") or (creatingNote and tr("Note name") or tr("Folder name")), bodyX + 12, bodyY + 50, 0.05, 0.05, 0.05, 1, UIFont.Small)
end

function target:drawPasswordPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    if self.currentView == "LOCK" then
        local avatar = self:getComputerAvatar()
        if userTextures[avatar] then
            self:drawTextureScaled(userTextures[avatar], bodyX + 22, bodyY + 26, 54, 54, 1, 1, 1, 1)
        else
            self:drawRect(bodyX + 22, bodyY + 26, 54, 54, 1, 0.25, 0.32, 0.48)
            self:drawRect(bodyX + 39, bodyY + 38, 20, 20, 1, 0.85, 0.85, 0.86)
            self:drawRect(bodyX + 32, bodyY + 62, 34, 12, 1, 0.85, 0.85, 0.86)
        end
        self:drawText(self:getComputerUsername(), bodyX + 92, bodyY + 28, 0.05, 0.05, 0.05, 1, UIFont.Medium)
        if self:hasPassword() then
            self:drawText(tr("Password"), bodyX + 92, bodyY + 58, 0, 0, 0, 1, UIFont.Small)
        else
            self:drawText(tr("No password set."), bodyX + 92, bodyY + 76, 0.2, 0.2, 0.2, 1, UIFont.Small)
        end
    else
        self:drawText(tr("Machine ID"), bodyX + 12, bodyY + 10, 0, 0, 0, 1, UIFont.Small)
        self:drawText((self:getComputerData() and self:getComputerData().ComputerModMachineID) or tr("UNKNOWN"), bodyX + 96, bodyY + 10, 0.2, 0.2, 0.2, 1, UIFont.Small)
        self:drawText(self:getPasswordStatusText(), bodyX + 12, bodyY + 36, 0.18, 0.18, 0.18, 1, UIFont.Small)
        self:drawText(tr("Password"), bodyX + 12, bodyY + 58, 0, 0, 0, 1, UIFont.Small)
        self:drawText(tr("Leave empty and press Save to disable the password."), bodyX + 12, bodyY + 156, 0.22, 0.22, 0.22, 1, UIFont.Small)
    end
    if self.passwordErrorText and self.passwordErrorText ~= "" then
        self:drawText(self.passwordErrorText, bodyX + 12, bodyY + 126, 0.65, 0.08, 0.08, 1, UIFont.Small)
    end
    local remaining = self:getPasswordHackLockRemaining()
    if self.currentView == "LOCK" and remaining > 0 then
        self:drawText(tr("Hack locked:") .. " " .. tostring(math.ceil(remaining)) .. " " .. tr("hours left."), bodyX + 92, bodyY + 104, 0.65, 0.08, 0.08, 1, UIFont.Small)
    elseif self.currentView == "LOCK" and self:isHackDiscMounted() and self:hasPassword() and self:getHackRequiredElectricalLevel() > 0 and self:getElectricalSkillLevel() < self:getHackRequiredElectricalLevel() then
        self:drawText(tr("Electrical") .. " " .. tostring(self:getHackRequiredElectricalLevel()) .. " " .. tr("required."), bodyX + 92, bodyY + 104, 0.72, 0.48, 0.12, 1, UIFont.Small)
    elseif self.currentView == "LOCK" and self:isHackDiscMounted() and self:hasPassword() then
        self:drawText(tr("Recovery disc detected."), bodyX + 92, bodyY + 104, 0.12, 0.28, 0.12, 1, UIFont.Small)
    end
end

function target:drawPasswordHackPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local barX = bodyX + 28
    local barY = bodyY + 94
    local barW = bodyW - 56
    local targetW = math.max(20, math.floor(barW * 0.11))
    local targetX = barX + math.floor((barW * (self.passwordHackTarget or 0.5)) - (targetW / 2))
    if targetX < barX then targetX = barX end
    if targetX + targetW > barX + barW then targetX = barX + barW - targetW end
    local lineX = barX + math.floor(barW * (self.passwordHackLine or 0))
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.04, 0.04, 0.045)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.32, 0.32, 0.34)
    self:drawText(tr("Password Recovery"), bodyX + 18, bodyY + 18, 0.88, 0.88, 0.86, 1, UIFont.Medium)
    self:drawText(tr("Press SPACE when the marker crosses the green window."), bodyX + 18, bodyY + 50, 0.72, 0.72, 0.72, 1, UIFont.Small)
    self:drawText(tr("Hits:") .. " " .. tostring(self.passwordHackHits or 0) .. " / 3", bodyX + 18, bodyY + 70, 0.78, 0.78, 0.78, 1, UIFont.Small)
    self:drawRect(barX, barY, barW, 18, 1, 0.16, 0.16, 0.16)
    self:drawRect(targetX, barY + 2, targetW, 14, 1, 0.16, 0.72, 0.22)
    self:drawRect(lineX, barY - 5, 3, 28, 1, 0.92, 0.92, 0.9)
    self:drawText(tr("One miss locks this computer for 12 in-game hours."), bodyX + 18, bodyY + bodyH - 38, 0.78, 0.36, 0.32, 1, UIFont.Small)
end

function target:getNetworkRepairButtonRect()
    return {
        x = self.screenX + self.screenWidth - 166,
        y = self.screenY + self.screenHeight - 54,
        w = 146,
        h = 26
    }
end

function target:drawNetworkTerminalPage()
    local bodyX = self.screenX
    local bodyY = self.screenY
    local bodyW = self.screenWidth
    local bodyH = self.screenHeight
    local connected = self:isInternetEnabled()
    local repaired = self.isNetworkTerminalRepaired and self:isNetworkTerminalRepaired() or false
    local terminalLabel = self.getNetworkTerminalLabel and self:getNetworkTerminalLabel() or "Network Relay"
    local terminalId = self.getNetworkTerminalId and self:getNetworkTerminalId() or "unknown"
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.02, 0.02, 0.02)
    self:drawRect(bodyX + 6, bodyY + 6, bodyW - 12, bodyH - 12, 1, 0.07, 0.07, 0.08)
    self:drawRect(bodyX + 6, bodyY + 6, bodyW - 12, 22, 1, 0.62, 0.62, 0.58)
    self:drawText("KNOXNET RELAY MAINTENANCE UTILITY 1.03", bodyX + 14, bodyY + 10, 0, 0, 0, 1, UIFont.Small)
    self:drawText("Copyright 1988-1993 Knox Telecommunications", bodyX + 18, bodyY + 40, 0.78, 0.78, 0.72, 1, UIFont.Small)
    self:drawText(tr("Relay:"), bodyX + 18, bodyY + 68, 0.78, 0.78, 0.72, 1, UIFont.Small)
    self:drawText(terminalLabel, bodyX + 92, bodyY + 68, 0.92, 0.92, 0.84, 1, UIFont.Small)
    self:drawText("ID:", bodyX + 18, bodyY + 88, 0.78, 0.78, 0.72, 1, UIFont.Small)
    self:drawText(tostring(terminalId), bodyX + 92, bodyY + 88, 0.92, 0.92, 0.84, 1, UIFont.Small)
    self:drawText(tr("Backbone:"), bodyX + 18, bodyY + 116, 0.78, 0.78, 0.72, 1, UIFont.Small)
    self:drawText(connected and tr("ONLINE") or tr("OFFLINE"), bodyX + 112, bodyY + 116, connected and 0.22 or 0.95, connected and 0.86 or 0.34, connected and 0.28 or 0.22, 1, UIFont.Small)
    self:drawText(tr("Hardware:"), bodyX + 18, bodyY + 136, 0.78, 0.78, 0.72, 1, UIFont.Small)
    self:drawText(repaired and tr("SERVICED") or tr("FAULT"), bodyX + 112, bodyY + 136, repaired and 0.22 or 0.95, repaired and 0.86 or 0.34, repaired and 0.28 or 0.22, 1, UIFont.Small)
    self:drawText(tr("Power loss drops the link. Serviced relays do not need parts again."), bodyX + 18, bodyY + 162, 0.72, 0.72, 0.66, 1, UIFont.Small)
    if repaired then
        self:drawText(tr("Service tag accepted. Restore power and activate the link."), bodyX + 18, bodyY + 194, 0.72, 0.72, 0.66, 1, UIFont.Small)
    end
    local button = self:getNetworkRepairButtonRect()
    local hovered = self.hoverX and self.hoverY
        and self.hoverX >= button.x and self.hoverX <= button.x + button.w
        and self.hoverY >= button.y and self.hoverY <= button.y + button.h
    local buttonR = connected and 0.34 or (repaired and 0.10 or 0.82)
    local buttonG = connected and 0.36 or (repaired and 0.52 or 0.24)
    local buttonB = connected and 0.34 or (repaired and 0.34 or 0.08)
    if hovered and not connected and repaired then
        buttonR = math.min(1, buttonR + 0.10)
        buttonG = math.min(1, buttonG + 0.10)
        buttonB = math.min(1, buttonB + 0.08)
    end
    self:drawRect(button.x - 2, button.y - 2, button.w + 4, button.h + 4, 1, 0.02, 0.02, 0.02)
    self:drawRect(button.x, button.y, button.w, button.h, 1, buttonR, buttonG, buttonB)
    self:drawRect(button.x, button.y, button.w, 2, 1, 1.00, 0.86, 0.54)
    self:drawRect(button.x, button.y, 2, button.h, 1, 1.00, 0.86, 0.54)
    self:drawRect(button.x + button.w - 2, button.y, 2, button.h, 1, 0.12, 0.04, 0.02)
    self:drawRect(button.x, button.y + button.h - 2, button.w, 2, 1, 0.12, 0.04, 0.02)
    local buttonText = connected and tr("ONLINE") or (repaired and tr("Activate Link") or tr("FAULT"))
    self:drawTextCentre(buttonText, button.x + math.floor(button.w / 2), button.y + 6, 1, 1, 0.92, 1, UIFont.Small)
    if self.fileNoticeText and self.fileNoticeText ~= "" and (self.fileNoticeTimer or 0) > 0 then
        local noticeLines = self:wrapTextLines(self.fileNoticeText, UIFont.Small, math.max(120, bodyX + bodyW - button.x - 20), 5)
        local noticeLineHeight = getTextLineHeight(UIFont.Small)
        for i = 1, #noticeLines do
            self:drawText(noticeLines[i], button.x, bodyY + 188 + (i - 1) * noticeLineHeight, 0.95, 0.82, 0.42, 1, UIFont.Small)
        end
    end
end

function target:drawNetworkRepairPage()
    self:drawNetworkTerminalPage()
end

function target:drawResetConfirmPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Confirm disk wipe"), bodyX + 12, bodyY + 14, 0.15, 0.15, 0.15, 1, UIFont.Medium)
    self:drawText(tr("This will remove the operating system."), bodyX + 12, bodyY + 48, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("It will also erase local data."), bodyX + 12, bodyY + 66, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("Notepad text, calculator memory, folders,"), bodyX + 12, bodyY + 86, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("settings and installed games will be cleared."), bodyX + 12, bodyY + 104, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("Press Confirm Reset to continue."), bodyX + 12, bodyY + 122, 0.45, 0.1, 0.1, 1, UIFont.Small)
end

function target:drawResetPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local progress = math.min(1, self.resetTimer / 72)
    local fillW = math.floor((bodyW - 28) * progress)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.06, 0.06, 0.065)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.45, 0.45, 0.48)
    self:drawText(tr("Disk wipe in progress"), bodyX + 12, bodyY + 16, 0.82, 0.82, 0.82, 1, UIFont.Medium)
    self:drawText(tr("Clearing local folders"), bodyX + 12, bodyY + 56, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawText(tr("Removing system files"), bodyX + 12, bodyY + 76, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawText(tr("Wiping notes and preferences"), bodyX + 12, bodyY + 96, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawRect(bodyX + 12, bodyY + bodyH - 46, bodyW - 24, 16, 1, 0.18, 0.18, 0.18)
    if fillW > 0 then
        self:drawRect(bodyX + 14, bodyY + bodyH - 44, fillW, 12, 1, 0.72, 0.72, 0.76)
    end
    self:drawText(tostring(math.floor(progress * 100)) .. "%", bodyX + bodyW - 42, bodyY + bodyH - 66, 0.76, 0.76, 0.76, 1, UIFont.Small)
end

function target:drawDiscWipeConfirmPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local discGame = self:getMountedDiscGame()
    local info = discGame and gameInstallInfo[discGame] or nil
    local discName = info and info.disc or "CD"
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(tr("Confirm CD wipe"), bodyX + 12, bodyY + 14, 0.15, 0.15, 0.15, 1, UIFont.Medium)
    self:drawText(discName, bodyX + 12, bodyY + 48, 0.1, 0.1, 0.1, 1, UIFont.Small)
    self:drawText(tr("This will erase the disc contents."), bodyX + 12, bodyY + 70, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("The disc will become a blank CD."), bodyX + 12, bodyY + 90, 0.22, 0.22, 0.22, 1, UIFont.Small)
    self:drawText(tr("Press Wipe CD to continue."), bodyX + 12, bodyY + 118, 0.45, 0.1, 0.1, 1, UIFont.Small)
end

function target:drawDiscWipingPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local progress = math.min(1, self.discWipeTimer / 72)
    local fillW = math.floor((bodyW - 28) * progress)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.06, 0.06, 0.065)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.45, 0.45, 0.48)
    self:drawText(tr("CD wipe in progress"), bodyX + 12, bodyY + 16, 0.82, 0.82, 0.82, 1, UIFont.Medium)
    self:drawText(tr("Erasing file table"), bodyX + 12, bodyY + 58, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawText(tr("Clearing program data"), bodyX + 12, bodyY + 78, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawText(tr("Preparing blank media"), bodyX + 12, bodyY + 98, 0.7, 0.7, 0.7, 1, UIFont.Small)
    self:drawRect(bodyX + 12, bodyY + bodyH - 50, bodyW - 24, 16, 1, 0.18, 0.18, 0.18)
    if fillW > 0 then
        self:drawRect(bodyX + 14, bodyY + bodyH - 48, fillW, 12, 1, 0.84, 0.64, 0.18)
    end
    self:drawText(tostring(math.floor(progress * 100)) .. "%", bodyX + bodyW - 42, bodyY + bodyH - 68, 0.76, 0.76, 0.76, 1, UIFont.Small)
end

function target:drawBiosPage()
    local bodyX = self.screenX + 16
    local bodyY = self.screenY + 16
    local mountedDisc = self:getMountedDiscGame()
    local mountedLabel = mountedDisc and gameInstallInfo[mountedDisc] and gameInstallInfo[mountedDisc].disc or "None"
    local valueX = bodyX + 154
    self:drawText(tr("CMOS SETUP UTILITY"), bodyX + 10, bodyY + 8, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(tr("Standard CMOS Features"), bodyX + 10, bodyY + 32, 0.88, 0.88, 0.88, 1, UIFont.Small)
    self:drawText(tr("Primary Master:"), bodyX + 14, bodyY + 60, 0.86, 0.86, 0.86, 1, UIFont.Small)
    self:drawText(self:isOSInstalled() and tr("540MB IDE HDD") or tr("540MB IDE HDD (Blank)"), valueX, bodyY + 60, 1, 1, 1, 1, UIFont.Small)
    self:drawText(tr("Secondary Master:"), bodyX + 14, bodyY + 80, 0.86, 0.86, 0.86, 1, UIFont.Small)
    self:drawText(mountedLabel, valueX, bodyY + 80, 1, 1, 1, 1, UIFont.Small)
    self:drawText(tr("Boot Sequence:"), bodyX + 14, bodyY + 100, 0.86, 0.86, 0.86, 1, UIFont.Small)
    self:drawText("A, C, CDROM", valueX, bodyY + 100, 1, 1, 1, 1, UIFont.Small)
    self:drawText(tr("Password Lock:"), bodyX + 14, bodyY + 120, 0.86, 0.86, 0.86, 1, UIFont.Small)
    self:drawText(self:hasPassword() and tr("Enabled") or tr("Disabled"), valueX, bodyY + 120, 1, 1, 1, 1, UIFont.Small)
    self:drawText(tr("Use the options below to boot or wipe the disk."), bodyX + 14, bodyY + 180, 0.86, 0.86, 0.86, 1, UIFont.Small)
end

function target:drawBootErrorPage()
    local bodyX = self.screenX + 16
    local bodyY = self.screenY + 22
    local mountedDisc = self:getMountedDiscGame()
    local cdLine = mountedDisc == "os" and tr("Bootable CD-ROM detected.") or tr("Insert a PZ OS 3.1 CD to continue.")
    self:drawText(tr("DISK BOOT FAILURE"), bodyX + 10, bodyY + 16, 0.92, 0.92, 0.92, 1, UIFont.Medium)
    self:drawText(tr("NO OPERATING SYSTEM"), bodyX + 10, bodyY + 42, 0.92, 0.82, 0.62, 1, UIFont.Small)
    self:drawText(tr("Fixed disk is not bootable."), bodyX + 10, bodyY + 72, 0.8, 0.8, 0.8, 1, UIFont.Small)
    self:drawText(cdLine, bodyX + 10, bodyY + 90, 0.8, 0.8, 0.8, 1, UIFont.Small)
    self:drawText(tr("Open BIOS and boot from CD-ROM."), bodyX + 10, bodyY + 118, 0.86, 0.86, 0.86, 1, UIFont.Small)
end

function target:drawFullScreenBios()
    local bodyX = self.screenX + 4
    local bodyY = self.screenY + 4
    local bodyW = self.screenWidth - 8
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, self.screenHeight - 8, 1, 0.05, 0.10, 0.36)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.82, 0.82, 0.92)
end

function target:drawFullScreenBootError()
    local bodyX = self.screenX + 4
    local bodyY = self.screenY + 4
    local bodyW = self.screenWidth - 8
    local bodyH = self.screenHeight - 8
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1, 0.02, 0.02, 0.02)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.03, 0.03, 0.03)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.60, 0.60, 0.60)
end

function target:drawOSInstallPage()
    local bodyX = self.screenX + 4
    local bodyY = self.screenY + 4
    local bodyW = self.screenWidth - 8
    local bodyH = self.screenHeight - 8
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.82, 0.82, 0.92)
    self:drawText(tr("PZ OS 3.1 Setup"), bodyX + 12, bodyY + 12, 1, 1, 1, 1, UIFont.Medium)
    if self.installStep == 1 then
        self:drawText(tr("Setup is preparing your hard disk."), bodyX + 16, bodyY + 52, 0.92, 0.92, 0.92, 1, UIFont.Small)
        self:drawText(tr("This process will install a bootable operating system."), bodyX + 16, bodyY + 72, 0.92, 0.92, 0.92, 1, UIFont.Small)
        self:drawText(tr("Press Next to continue."), bodyX + 16, bodyY + 104, 0.86, 0.86, 0.86, 1, UIFont.Small)
    elseif self.installStep == 2 then
        self:drawText(tr("Target drive"), bodyX + 16, bodyY + 52, 0.92, 0.92, 0.92, 1, UIFont.Small)
        self:drawRect(bodyX + 16, bodyY + 72, bodyW - 32, 24, 1, 0.88, 0.88, 0.92)
        self:drawText("C:\\PZOS", bodyX + 24, bodyY + 77, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Files required: 18 MB"), bodyX + 16, bodyY + 112, 0.86, 0.86, 0.86, 1, UIFont.Small)
        self:drawText(tr("Boot files will be written to the master disk."), bodyX + 16, bodyY + 132, 0.86, 0.86, 0.86, 1, UIFont.Small)
    else
        if self.installNextButton then
            self.installNextButton:setTitle(self:isOSInstalled() and tr("Installed") or tr("Install"))
        end
        self:drawText(tr("Ready to install PZ OS 3.1."), bodyX + 16, bodyY + 52, 0.92, 0.92, 0.92, 1, UIFont.Small)
        self:drawText(tr("The hard disk will become bootable again."), bodyX + 16, bodyY + 72, 0.86, 0.86, 0.86, 1, UIFont.Small)
        if self:isOSInstalled() then
            self:drawText(tr("Operating system already present on disk."), bodyX + 16, bodyY + 104, 0.72, 0.92, 0.72, 1, UIFont.Small)
        else
            self:drawText(tr("Press Install to begin copying system files."), bodyX + 16, bodyY + 104, 0.86, 0.86, 0.86, 1, UIFont.Small)
        end
    end
end

function target:drawOSInstallingPage()
    local bodyX = self.screenX + 4
    local bodyY = self.screenY + 4
    local bodyW = self.screenWidth - 8
    local bodyH = self.screenHeight - 8
    local progress = math.min(1, self.installProgress / 84)
    local fillW = math.floor((bodyW - 32) * progress)
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.82, 0.82, 0.92)
    self:drawText(tr("Installing PZ OS 3.1"), bodyX + 12, bodyY + 12, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(tr("Copying kernel files..."), bodyX + 16, bodyY + 58, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawText(tr("Writing boot sector..."), bodyX + 16, bodyY + 78, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawText(tr("Registering system drivers..."), bodyX + 16, bodyY + 98, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawRect(bodyX + 16, bodyY + bodyH - 48, bodyW - 32, 16, 1, 0.12, 0.12, 0.18)
    if fillW > 0 then
        self:drawRect(bodyX + 18, bodyY + bodyH - 46, fillW, 12, 1, 0.74, 0.74, 0.88)
    end
    self:drawText(tostring(math.floor(progress * 100)) .. "%", bodyX + bodyW - 42, bodyY + bodyH - 68, 0.92, 0.92, 0.92, 1, UIFont.Small)
end

function target:drawOSFirstRunPage()
    local bodyX = self.screenX + 8
    local bodyY = self.screenY + 8
    local bodyW = self.screenWidth - 16
    local bodyH = self.screenHeight - 8
    local formX = bodyX + 168
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.03, 0.08, 0.40)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.82, 0.82, 0.92)
    self:drawText(tr("Welcome to PZ OS 3.1"), bodyX + 12, bodyY + 12, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(tr("Create the local user for this machine."), bodyX + 16, bodyY + 42, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawText(tr("User name"), bodyX + 28, bodyY + 80, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawText(tr("Password"), bodyX + 28, bodyY + 120, 0.92, 0.92, 0.92, 1, UIFont.Small)
    self:drawText(tr("(optional)"), bodyX + 28, bodyY + 138, 0.72, 0.72, 0.78, 1, UIFont.Small)
    self:drawText(tr("Profile picture"), bodyX + 28, bodyY + 174, 0.92, 0.92, 0.92, 1, UIFont.Small)
    local avatar = self:getComputerAvatar()
    for i = 1, 6 do
        local x = formX + (i - 1) * 34
        local y = bodyY + 170
        if i == avatar then
            self:drawRect(x - 2, y - 2, 30, 28, 1, 0.72, 0.72, 0.88)
        end
        if userTextures[i] then
            self:drawTextureScaled(userTextures[i], x + 3, y + 2, 22, 22, 1, 1, 1, 1)
        else
            self:drawText(tostring(i), x + 10, y + 6, 1, 1, 1, 1, UIFont.Small)
        end
    end
end

function target:drawInstallPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local info = gameInstallInfo[self.installGameId or ""]
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    if not info then
        self:drawText(tr("No installation media found."), bodyX + 12, bodyY + 20, 0.2, 0.2, 0.2, 1, UIFont.Small)
        return
    end
    self:drawText(info.label .. " " .. tr("Setup"), bodyX + 12, bodyY + 14, 0.12, 0.12, 0.12, 1, UIFont.Medium)
    if self.installStep == 1 then
        self:drawText(info.label .. " " .. tr("setup wizard."), bodyX + 12, bodyY + 48, 0.2, 0.2, 0.2, 1, UIFont.Small)
        self:drawText(info.system and tr("This installer will copy system files to the hard disk.") or tr("This installer will copy the game to the local drive."), bodyX + 12, bodyY + 68, 0.2, 0.2, 0.2, 1, UIFont.Small)
        self:drawText(tr("Click Next to continue."), bodyX + 12, bodyY + 100, 0.2, 0.2, 0.2, 1, UIFont.Small)
    elseif self.installStep == 2 then
        self:drawText(tr("Destination folder"), bodyX + 12, bodyY + 48, 0.08, 0.08, 0.08, 1, UIFont.Small)
        self:drawRect(bodyX + 12, bodyY + 68, bodyW - 24, 22, 1, 1, 1, 1)
        self:drawText(info.system and "C:\\PZOS" or ("C:\\Games\\" .. info.label), bodyX + 18, bodyY + 72, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(info.system and tr("Required space: 18 MB") or tr("Required space: 12 MB"), bodyX + 12, bodyY + 104, 0.2, 0.2, 0.2, 1, UIFont.Small)
        self:drawText(tr("Program group:"), bodyX + 12, bodyY + 120, 0.2, 0.2, 0.2, 1, UIFont.Small)
        self:drawText(info.system and tr("System Files") or tr("Retro Games"), bodyX + 12, bodyY + 136, 0.2, 0.2, 0.2, 1, UIFont.Small)
    else
        if self.installNextButton then
            self.installNextButton:setTitle(self:isGameInstalled(self.installGameId) and tr("Installed") or tr("Install"))
        end
        self:drawText(tr("Ready to install") .. " " .. info.label .. ".", bodyX + 12, bodyY + 48, 0.08, 0.08, 0.08, 1, UIFont.Small)
        self:drawText(info.system and tr("System files will be written to the hard disk.") or tr("Files will be copied to the local game directory."), bodyX + 12, bodyY + 68, 0.2, 0.2, 0.2, 1, UIFont.Small)
        if (info.system and self:isOSInstalled()) or (not info.system and self:isGameInstalled(self.installGameId)) then
            self:drawText(tr("This game is already installed."), bodyX + 12, bodyY + 90, 0.12, 0.3, 0.12, 1, UIFont.Small)
            self:drawText(tr("Close this window"), bodyX + 12, bodyY + 108, 0.12, 0.3, 0.12, 1, UIFont.Small)
            self:drawText(tr("or reinstall from the CD."), bodyX + 12, bodyY + 124, 0.12, 0.3, 0.12, 1, UIFont.Small)
        else
            self:drawText(tr("Click Install to finish setup."), bodyX + 12, bodyY + 102, 0.2, 0.2, 0.2, 1, UIFont.Small)
        end
    end
end

function target:drawInstallingPage()
    local bodyX = self.clientX + 18
    local bodyY = self.clientY + 22
    local bodyW = self.clientW - 36
    local bodyH = self.clientH - 44
    local info = gameInstallInfo[self.installGameId or ""]
    local progress = math.min(1, self.installProgress / 84)
    local fillW = math.floor((bodyW - 28) * progress)
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.94, 0.94, 0.92)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText((info and info.label or tr("Game")) .. " " .. tr("installation"), bodyX + 12, bodyY + 16, 0.1, 0.1, 0.1, 1, UIFont.Medium)
    self:drawText(tr("Copying files to local disk..."), bodyX + 12, bodyY + 58, 0.2, 0.2, 0.2, 1, UIFont.Small)
    self:drawText(tr("Registering game shortcuts..."), bodyX + 12, bodyY + 78, 0.2, 0.2, 0.2, 1, UIFont.Small)
    self:drawText(tr("Finalizing installation..."), bodyX + 12, bodyY + 98, 0.2, 0.2, 0.2, 1, UIFont.Small)
    self:drawRect(bodyX + 12, bodyY + bodyH - 50, bodyW - 24, 16, 1, 0.18, 0.18, 0.18)
    if fillW > 0 then
        self:drawRect(bodyX + 14, bodyY + bodyH - 48, fillW, 12, 1, 0.18, 0.52, 0.92)
    end
    self:drawText(tostring(math.floor(progress * 100)) .. "%", bodyX + bodyW - 42, bodyY + bodyH - 68, 0.2, 0.2, 0.2, 1, UIFont.Small)
end

function target:drawMarketPage()
    if self.isInternetEnabled and not self:isInternetEnabled() then
        self:drawNoInternetPage("Market")
        return
    end
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    local data = self:getMarketData()
    local layout = self:getMarketListLayout()
    local panelX = layout.panelX
    local panelY = layout.panelY
    local panelW = layout.panelW
    local panelH = layout.panelH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.92, 0.92, 0.88)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.72, 0.72, 0.68)
    if self.accountRecoveryService == "market" then
        self:drawText(tr("Market"), bodyX + 14, bodyY + 12, 0.05, 0.05, 0.05, 1, UIFont.Medium)
        self:drawText(tr("User"), bodyX + 54, bodyY + 82, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("New password"), bodyX + 18, bodyY + 116, 96, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Enter a new password for this account."), bodyX + 18, bodyY + 154, bodyW - 36, 0.22, 0.22, 0.22, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 18, bodyY + 180, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
    elseif not self:isMarketLoggedIn() then
        self:drawText(tr("Market"), bodyX + 14, bodyY + 12, 0.05, 0.05, 0.05, 1, UIFont.Medium)
        self:drawText(tr("Create or log into a market account."), bodyX + 18, bodyY + 42, 0.12, 0.12, 0.12, 1, UIFont.Small)
        self:drawText(tr("User"), bodyX + 54, bodyY + 82, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawText(tr("Pass"), bodyX + 54, bodyY + 116, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Recovery email"), bodyX + 18, bodyY + 150, 96, 0.05, 0.05, 0.05, 1, UIFont.Small)
        if self.fileNoticeText and self.fileNoticeText ~= "" then
            self:drawText(self.fileNoticeText, bodyX + 18, bodyY + 210, 0.55, 0.08, 0.08, 1, UIFont.Small)
        end
    else
        self:drawTextInWidth(tr("User:") .. " " .. tostring(self:getMarketUsername() or ""), bodyX + 14, bodyY + 42, bodyW - 148, 0.14, 0.14, 0.14, 1, UIFont.Small)
        self:drawTextInWidth(tr("Balance: $") .. tostring(data.money or 0), bodyX + bodyW - 126, bodyY + 42, 112, 0.1, 0.28, 0.1, 1, UIFont.Small, "right")
        self:drawRect(panelX, panelY, panelW, panelH, 1, 0.98, 0.98, 0.94)
        local refreshKind = (self.marketTab == "jobs") and "jobs" or "shop"
        self:drawTextInWidth((self.marketTab == "jobs") and tr("Daily jobs") or tr("Daily shop"), panelX + 10, panelY + 8, panelW - 132, 0.05, 0.05, 0.05, 1, UIFont.Small)
        self:drawTextInWidth(tr("Refresh:") .. " " .. self:getMarketCountdownText(refreshKind), panelX + panelW - 116, panelY + 8, 106, 0.24, 0.24, 0.24, 1, UIFont.Small, "right")
        if self.marketTab == "jobs" then
            local jobs = self:getMarketJobs()
            local completed = data.completedJobs or {}
            local progressData = data.jobProgress or {}
            local currentKills = ComputerModMarket and ComputerModMarket.getPlayerZombieKills and ComputerModMarket.getPlayerZombieKills(self.playerObj or getPlayer()) or 0
            for i = 1, math.min(#jobs, layout.rows) do
                local sy = layout.listY + (i - 1) * layout.jobRowH
                local done = completed[jobs[i].id] == true
                self:drawRect(layout.x, sy, layout.w, layout.jobRowH - 4, 1, done and 0.68 or 0.78, done and 0.80 or 0.78, done and 0.68 or 0.74)
                local textX = layout.x + 6
                if jobs[i].type == "deliver" then
                    local tex = self:getMarketItemTexture(jobs[i])
                    if tex then
                        self:drawTextureScaled(tex, layout.x + 5, sy + 5, 18, 18, 1, 1, 1, 1)
                    end
                    textX = layout.x + 28
                end
                self:drawTextInWidth(tr(jobs[i].label), textX, sy + 4, layout.x + layout.w - textX - 68, 0, 0, 0, 1, UIFont.Small, nil, 12)
                self:drawTextInWidth(done and tr("Done") or ("+$" .. tostring(jobs[i].reward)), panelX + panelW - 66, sy + 4, 56, 0, done and 0.28 or 0.18, 0, 1, UIFont.Small, "right", 12)
                if not done then
                    local detail = tr("Click to complete")
                    if jobs[i].type == "kill" then
                        local progress = progressData[jobs[i].id] or {}
                        local startKills = tonumber(progress.startKills or currentKills) or currentKills
                        local amount = math.max(0, currentKills - startKills)
                        detail = tostring(math.min(amount, tonumber(jobs[i].target or 1) or 1)) .. "/" .. tostring(jobs[i].target or 1) .. " " .. tr("infected cleared")
                    elseif jobs[i].type == "deliver" then
                        local have = 0
                        if ComputerModMarket and ComputerModMarket.getInventoryJobItemCount and self.playerObj and self.playerObj.getInventory then
                            have = ComputerModMarket.getInventoryJobItemCount(self.playerObj:getInventory(), jobs[i])
                        end
                        detail = tostring(math.min(have, tonumber(jobs[i].target or 1) or 1)) .. "/" .. tostring(jobs[i].target or 1) .. " " .. tr("item(s) ready")
                    elseif jobs[i].type == "paperwork" then
                        detail = tr("Complete sorting minigame")
                    end
                    self:drawTextInWidth(detail, textX, sy + 16, layout.x + layout.w - textX - 8, 0.18, 0.18, 0.18, 1, UIFont.Small, nil, 12)
                end
            end
        else
            local categories = ComputerModMarket and ComputerModMarket.categories or {}
            local catW = math.floor((panelW - 22) / 4)
            for i = 1, #categories do
                local col = (i - 1) % 4
                local row = math.floor((i - 1) / 4)
                local bx = panelX + 8 + col * math.floor((panelW - 16) / 4)
                local by = panelY + 30 + row * 22
                local selected = (self.marketCategory or "all") == categories[i].id
                self:drawRect(bx, by, catW, 18, 1, selected and 0.54 or 0.78, selected and 0.62 or 0.78, selected and 0.76 or 0.74)
                self:drawRect(bx, by, catW, 1, 1, 1, 1, 1)
                self:drawTextInWidth(tr(categories[i].label), bx + 5, by + 3, catW - 10, 0, 0, 0, 1, UIFont.Small, "center", 14)
            end
            local items = self:getMarketShopItems()
            for i = 1, math.min(#items, layout.rows) do
                local sy = layout.listY + (i - 1) * layout.rowH
                local stock = tonumber(items[i].stock or 0) or 0
                self:drawRect(layout.x, sy, layout.w, layout.rowH - 4, 1, stock <= 0 and 0.66 or 0.78, stock <= 0 and 0.66 or 0.78, stock <= 0 and 0.66 or 0.74)
                local tex = self:getMarketItemTexture(items[i])
                if tex then
                    self:drawTextureScaled(tex, layout.x + 4, sy + 3, 18, 18, 1, 1, 1, 1)
                end
                self:drawTextInWidth(tr(items[i].label), layout.x + 28, sy + 5, layout.w - 156, 0, 0, 0, 1, UIFont.Small)
                self:drawTextInWidth(tr("Stock:") .. " " .. tostring(stock), panelX + panelW - 128, sy + 5, 72, 0.22, 0.22, 0.22, 1, UIFont.Small, "right")
                self:drawTextInWidth("$" .. tostring(items[i].price), panelX + panelW - 52, sy + 5, 42, 0, 0.18, 0, 1, UIFont.Small, "right")
            end
            if #items == 0 then
                self:drawText(tr("No stock in this category today."), layout.x + 6, layout.listY + 5, 0.22, 0.22, 0.22, 1, UIFont.Small)
            elseif #items > layout.rows then
                self:drawText(tr("More stock available after the next refresh."), layout.x + 6, panelY + panelH - 18, 0.22, 0.22, 0.22, 1, UIFont.Small)
            end
        end
    end
    if self.fileNoticeText and self.fileNoticeText ~= "" and (self.fileNoticeTimer or 0) > 0 then
        self:drawText(self.fileNoticeText, bodyX + 14, bodyY + bodyH - 24, 0.42, 0.06, 0.06, 1, UIFont.Small)
    end
end

function target:drawMarketPaperworkPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    local job = self.marketPaperworkJob
    local sequence = self.marketPaperworkSequence or {}
    local step = tonumber(self.marketPaperworkStep or 1) or 1
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.9, 0.9, 0.84)
    self:drawRect(bodyX + 14, bodyY + 42, bodyW - 28, 70, 1, 0.98, 0.98, 0.94)
    self:drawText(job and tr(job.label) or tr("Paperwork job"), bodyX + 22, bodyY + 50, 0.04, 0.04, 0.04, 1, UIFont.Medium)
    self:drawText(self.marketPaperworkPrompt or tr("Complete the office task."), bodyX + 22, bodyY + 78, 0.18, 0.18, 0.18, 1, UIFont.Small)
    self:drawText(tr("Progress:") .. " " .. tostring(math.min(step - 1, #sequence)) .. "/" .. tostring(#sequence), bodyX + bodyW - 112, bodyY + 78, 0.12, 0.24, 0.12, 1, UIFont.Small)
    local names = {tr("Invoice"), tr("Stock"), tr("Date"), tr("Code")}
    local labels = self.marketPaperworkLabels or {tr("Invoice"), tr("Stock"), tr("Date"), tr("Code")}
    local targetLabel = labels[sequence[step] or 1] or "?"
    local mode = self.marketPaperworkMode or "fields"
    if mode == "codes" then
        self:drawText(tr("Printout:") .. " " .. targetLabel, bodyX + 22, bodyY + 102, 0.08, 0.08, 0.08, 1, UIFont.Small)
    elseif mode == "checksum" then
        self:drawText(tr("Requested checksum:") .. " " .. targetLabel, bodyX + 22, bodyY + 102, 0.08, 0.08, 0.08, 1, UIFont.Small)
    else
        self:drawText(tr("Next field:") .. " " .. targetLabel, bodyX + 22, bodyY + 102, 0.08, 0.08, 0.08, 1, UIFont.Small)
    end
    local bw = math.floor((bodyW - 72) / 4)
    local by = bodyY + math.floor(bodyH * 0.58)
    for i = 1, 4 do
        local bx = bodyX + 18 + (i - 1) * (bw + 12)
        local active = mode == "fields" and sequence[step] == i
        self:drawRect(bx, by, bw, 32, 1, active and 0.62 or 0.74, active and 0.82 or 0.74, active and 0.62 or 0.72)
        self:drawRect(bx, by, bw, 1, 1, 1, 1, 1)
        self:drawRect(bx, by, 1, 32, 1, 1, 1, 1)
        self:drawRect(bx + bw - 1, by, 1, 32, 1, 0.25, 0.25, 0.25)
        self:drawRect(bx, by + 31, bw, 1, 1, 0.25, 0.25, 0.25)
        self:drawText(labels[i] or names[i] or tostring(i), bx + 8, by + 9, 0, 0, 0, 1, UIFont.Small)
    end
    if (self.marketPaperworkErrorTimer or 0) > 0 then
    self:drawText(tr("Wrong field. Sequence reset."), bodyX + 22, by + 46, 0.55, 0.05, 0.05, 1, UIFont.Small)
    elseif mode == "fields" then
        self:drawText(tr("Click the green field."), bodyX + 22, by + 46, 0.2, 0.2, 0.2, 1, UIFont.Small)
    else
        self:drawText(tr("Choose the matching option."), bodyX + 22, by + 46, 0.2, 0.2, 0.2, 1, UIFont.Small)
    end
end

function target:drawFolderContextMenu()
    if not self.folderContextMenu then return end
    local menu = self.folderContextMenu
    local menuW = 92
    local menuH = 48
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("Rename"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    self:drawTextInWidth(tr("Delete"), menuX + 10, menuY + 29, menuW - 20, 0, 0, 0, 1, UIFont.Small)
end

function target:drawDiscContextMenu()
    if not self.discContextMenu then return end
    local menu = self.discContextMenu
    local actions = self:getDiscContextActions()
    if #actions == 0 then
        self.discContextMenu = nil
        return
    end
    local menuW = 112
    local menuH = #actions * 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    for i = 1, #actions do
        self:drawTextInWidth(actions[i].label, menuX + 10, menuY + 5 + (i - 1) * 24, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    end
end

function target:drawGameContextMenu()
    if not self.gameContextMenu then return end
    local menu = self.gameContextMenu
    local menuW = 94
    local canWrite = self:canWriteGameToDisc(menu.gameId)
    local menuH = canWrite and 48 or 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("Uninstall"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    if canWrite then
        self:drawTextInWidth(tr("Write To Disc"), menuX + 10, menuY + 29, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    end
end

function target:drawDesktopContextMenu()
    if not self.desktopContextMenu then return end
    local menu = self.desktopContextMenu
    local menuW = 94
    local menuH = 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    local hoveredMain = self.hoverX and self.hoverY and self.hoverX >= menuX and self.hoverX <= menuX + menuW and self.hoverY >= menuY and self.hoverY <= menuY + menuH
    local submenuW = 104
    local submenuH = menu.allowNote and 48 or 24
    local submenuX, submenuY = getPopupPosition(self, menuX + menuW - 2, menuY, submenuW, submenuH)
    local hoveredSub = self.hoverX and self.hoverY and self.hoverX >= submenuX and self.hoverX <= submenuX + submenuW and self.hoverY >= submenuY and self.hoverY <= submenuY + submenuH
    menu.submenuOpen = hoveredMain or hoveredSub or menu.submenuOpen == true
    menu.submenuX = submenuX
    menu.submenuY = submenuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("New >"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    if menu.submenuOpen then
        self:drawRect(submenuX, submenuY, submenuW, submenuH, 1, 0.82, 0.82, 0.82)
        self:drawRect(submenuX, submenuY, submenuW, 1, 1, 1, 1, 1)
        self:drawRect(submenuX, submenuY, 1, submenuH, 1, 1, 1, 1)
        self:drawRect(submenuX + submenuW - 1, submenuY, 1, submenuH, 1, 0.25, 0.25, 0.25)
        self:drawRect(submenuX, submenuY + submenuH - 1, submenuW, 1, 1, 0.25, 0.25, 0.25)
        self:drawTextInWidth(tr("Folder"), submenuX + 10, submenuY + 5, submenuW - 20, 0, 0, 0, 1, UIFont.Small)
        if menu.allowNote then
            self:drawTextInWidth(tr("Notepad"), submenuX + 10, submenuY + 29, submenuW - 20, 0, 0, 0, 1, UIFont.Small)
        end
    end
end

function target:drawDesktopItemContextMenu()
    if not self.desktopItemContextMenu then return end
    local menu = self.desktopItemContextMenu
    local entry = self:getDesktopFileEntry(menu.item)
    local isApp = menu.item and menu.item.kind == "app"
    local isFolder = menu.item and menu.item.kind == "folder"
    if not entry and not isApp then return end
    local targets = self:getStorageTargetsForEntry(entry)
    local menuW = 96
    local menuH = isApp and 24 or (isFolder and 120 or 96)
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    local copyY = isFolder and 72 or 48
    local moveY = isFolder and 96 or 72
    local hoverCopy = (not isApp) and self.hoverX and self.hoverY and self.hoverX >= menuX and self.hoverX <= menuX + menuW and self.hoverY >= menuY + copyY and self.hoverY <= menuY + copyY + 24
    local hoverMove = self.hoverX and self.hoverY and self.hoverX >= menuX and self.hoverX <= menuX + menuW and self.hoverY >= menuY + moveY and self.hoverY <= menuY + moveY + 24
    local subMode = hoverCopy and "copy" or (hoverMove and "move" or menu.subMode)
    local submenuW = 132
    local submenuH = math.max(24, math.min(#targets, 8) * 24)
    local submenuX, submenuY = getPopupPosition(self, menuX + menuW - 2, subMode == "move" and menuY + moveY or menuY + copyY, submenuW, submenuH)
    local hoverSub = self.hoverX and self.hoverY and self.hoverX >= submenuX and self.hoverX <= submenuX + submenuW and self.hoverY >= submenuY and self.hoverY <= submenuY + submenuH
    if hoverCopy or hoverMove or hoverSub then
        menu.subMode = subMode
    end
    menu.submenuX = submenuX
    menu.submenuY = submenuY
    menu.targets = targets
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    local openLabel = entry and (entry.type == "magazine" or entry.type == "newspaper" or entry.type == "video") and (entry.type == "video" and tr("Watch") or tr("Read")) or tr("Open")
    self:drawTextInWidth(openLabel, menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    if not isApp then
        if isFolder then
            self:drawTextInWidth(tr("Rename"), menuX + 10, menuY + 29, menuW - 20, 0, 0, 0, 1, UIFont.Small)
            self:drawTextInWidth(tr("Delete"), menuX + 10, menuY + 53, menuW - 20, 0, 0, 0, 1, UIFont.Small)
            self:drawTextInWidth(tr("Copy To >"), menuX + 10, menuY + 77, menuW - 20, 0, 0, 0, 1, UIFont.Small)
            self:drawTextInWidth(tr("Move To >"), menuX + 10, menuY + 101, menuW - 20, 0, 0, 0, 1, UIFont.Small)
        else
            self:drawTextInWidth(tr("Delete"), menuX + 10, menuY + 29, menuW - 20, 0, 0, 0, 1, UIFont.Small)
            self:drawTextInWidth(tr("Copy To >"), menuX + 10, menuY + 53, menuW - 20, 0, 0, 0, 1, UIFont.Small)
            self:drawTextInWidth(tr("Move To >"), menuX + 10, menuY + 77, menuW - 20, 0, 0, 0, 1, UIFont.Small)
        end
    end
    if not isApp and menu.subMode and #targets > 0 then
        self:drawRect(submenuX, submenuY, submenuW, submenuH, 1, 0.82, 0.82, 0.82)
        self:drawRect(submenuX, submenuY, submenuW, 1, 1, 1, 1, 1)
        self:drawRect(submenuX, submenuY, 1, submenuH, 1, 1, 1, 1)
        self:drawRect(submenuX + submenuW - 1, submenuY, 1, submenuH, 1, 0.25, 0.25, 0.25)
        self:drawRect(submenuX, submenuY + submenuH - 1, submenuW, 1, 1, 0.25, 0.25, 0.25)
        for i = 1, math.min(#targets, 8) do
            self:drawTextInWidth(targets[i].label, submenuX + 8, submenuY + 5 + (i - 1) * 24, submenuW - 16, 0, 0, 0, 1, UIFont.Small)
        end
    end
end

function target:drawTrashContextMenu()
    if not self.trashContextMenu then return end
    local menu = self.trashContextMenu
    local menuW = 94
    local menuH = 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("Empty Trash"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
end

function target:drawFileItemContextMenu()
    if not self.fileItemContextMenu then return end
    local menu = self.fileItemContextMenu
    local menuW = 86
    local menuH = self:isDiscStorageOpenable() and 96 or 72
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    local entry = nil
    if menu.source == "folder" then
        local entries = self:getFolderContents(self.currentFolderName or "")
        entry = entries[menu.index]
    elseif menu.source == "downloads" then
        local downloads = self:getDownloadedMagazines()
        entry = downloads[menu.index]
    end
    local openLabel = entry and (entry.type == "app" or entry.type == "folder" or entry.type == "note" or entry.type == "paint") and tr("Open") or tr("Read")
    self:drawTextInWidth(openLabel, menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    self:drawTextInWidth(tr("Delete"), menuX + 10, menuY + 29, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    self:drawTextInWidth(tr("Desktop"), menuX + 10, menuY + 53, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    if self:isDiscStorageOpenable() then
        self:drawTextInWidth(tr("Copy CD"), menuX + 10, menuY + 77, menuW - 20, 0, 0, 0, 1, UIFont.Small)
    end
end

function target:drawTrashItemContextMenu()
    if not self.trashItemContextMenu then return end
    local menu = self.trashItemContextMenu
    local menuW = 86
    local menuH = 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("Restore"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
end

function target:drawPaintFileContextMenu()
    if not self.paintFileContextMenu then return end
    local menu = self.paintFileContextMenu
    local menuW = 86
    local menuH = 24
    local menuX, menuY = getPopupPosition(self, menu.x, menu.y, menuW, menuH)
    menu.drawX = menuX
    menu.drawY = menuY
    self:drawRect(menuX, menuY, menuW, menuH, 1, 0.82, 0.82, 0.82)
    self:drawRect(menuX, menuY, menuW, 1, 1, 1, 1, 1)
    self:drawRect(menuX, menuY, 1, menuH, 1, 1, 1, 1)
    self:drawRect(menuX + menuW - 1, menuY, 1, menuH, 1, 0.25, 0.25, 0.25)
    self:drawRect(menuX, menuY + menuH - 1, menuW, 1, 1, 0.25, 0.25, 0.25)
    self:drawTextInWidth(tr("Delete"), menuX + 10, menuY + 5, menuW - 20, 0, 0, 0, 1, UIFont.Small)
end

function target:getPaintPalette()
    return {
        {r = 0, g = 0, b = 0},
        {r = 1, g = 1, b = 1},
        {r = 0.86, g = 0.08, b = 0.08},
        {r = 0.1, g = 0.32, b = 0.86},
        {r = 0.05, g = 0.62, b = 0.22},
        {r = 0.94, g = 0.82, b = 0.1},
        {r = 0.78, g = 0.18, b = 0.72},
        {r = 0.96, g = 0.52, b = 0.12}
    }
end

function target:getPaintCanvasRect()
    local toolW = 112
    local x = self.clientX + 10
    local y = self.clientY + 36
    local w = self.clientW - toolW - 28
    local h = self.clientH - 52
    return {x = x, y = y, w = w, h = h}
end

function target:getPaintCellAt(x, y)
    local rect = self:getPaintCanvasRect()
    if x < rect.x or x > rect.x + rect.w or y < rect.y or y > rect.y + rect.h then return nil, nil end
    local cols = self.paintCanvasW or 32
    local rows = self.paintCanvasH or 18
    local cellW = rect.w / cols
    local cellH = rect.h / rows
    local col = math.floor((x - rect.x) / cellW) + 1
    local row = math.floor((y - rect.y) / cellH) + 1
    if col < 1 or col > cols or row < 1 or row > rows then return nil, nil end
    return col, row
end

function target:paintCell(x, y)
    local col, row = self:getPaintCellAt(x, y)
    if not col or not row then return false end
    self.paintCanvas = self.paintCanvas or {}
    local key = tostring(col) .. ":" .. tostring(row)
    self.paintCanvas[key] = self.paintColor or 1
    return true
end

function target:getPaintButtonAt(x, y)
    local toolX = self.clientX + self.clientW - 108
    local buttons = {
        {id = "save", x = toolX, y = self.clientY + 36, w = 92, h = 22},
        {id = "clear", x = toolX, y = self.clientY + 64, w = 92, h = 22},
        {id = "delete", x = toolX, y = self.clientY + 92, w = 92, h = 22}
    }
    for i = 1, #buttons do
        local b = buttons[i]
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            return b.id
        end
    end
    return nil
end

function target:getPaintPaletteAt(x, y)
    local toolX = self.clientX + self.clientW - 108
    local startY = self.clientY + 142
    local palette = self:getPaintPalette()
    for i = 1, #palette do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        local px = toolX + col * 22
        local py = startY + row * 22
        if x >= px and x <= px + 18 and y >= py and y <= py + 18 then
            return i
        end
    end
    return nil
end

function target:drawPaintPage()
    local bodyX = self.clientX
    local bodyY = self.clientY
    local bodyW = self.clientW
    local bodyH = self.clientH
    self:drawRect(bodyX, bodyY, bodyW, bodyH, 1, 0.95, 0.95, 0.93)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.76, 0.76, 0.76)
    self:drawText(self.activePaintKey and tr("Editing saved drawing") or tr("New drawing"), bodyX + 10, bodyY + 10, 0, 0, 0, 1, UIFont.Small)
    local rect = self:getPaintCanvasRect()
    self:drawRect(rect.x - 2, rect.y - 2, rect.w + 4, rect.h + 4, 1, 0.18, 0.18, 0.18)
    self:drawRect(rect.x, rect.y, rect.w, rect.h, 1, 1, 1, 1)
    local cols = self.paintCanvasW or 32
    local rows = self.paintCanvasH or 18
    local cellW = rect.w / cols
    local cellH = rect.h / rows
    local palette = self:getPaintPalette()
    for key, value in pairs(self.paintCanvas or {}) do
        local c, r = string.match(key, "^(%d+):(%d+)$")
        c = tonumber(c)
        r = tonumber(r)
        local color = palette[value or 1] or palette[1]
        if c and r then
            self:drawRect(rect.x + (c - 1) * cellW, rect.y + (r - 1) * cellH, math.ceil(cellW), math.ceil(cellH), 1, color.r, color.g, color.b)
        end
    end
    for c = 1, cols - 1 do
        local gx = rect.x + c * cellW
        self:drawRect(gx, rect.y, 1, rect.h, 0.08, 0, 0, 0)
    end
    for r = 1, rows - 1 do
        local gy = rect.y + r * cellH
        self:drawRect(rect.x, gy, rect.w, 1, 0.08, 0, 0, 0)
    end
    local toolX = bodyX + bodyW - 108
    local labels = {save = tr("Save"), clear = tr("Clear"), delete = tr("Delete")}
    local buttons = {
        {id = "save", y = bodyY + 36},
        {id = "clear", y = bodyY + 64},
        {id = "delete", y = bodyY + 92}
    }
    for i = 1, #buttons do
        local b = buttons[i]
        self:drawRect(toolX, b.y, 92, 22, 1, 0.74, 0.74, 0.72)
        self:drawRect(toolX, b.y, 92, 1, 1, 1, 1, 1)
        self:drawText(labels[b.id], toolX + 10, b.y + 4, 0, 0, 0, 1, UIFont.Small)
    end
    self:drawText(tr("Colors"), toolX, bodyY + 122, 0, 0, 0, 1, UIFont.Small)
    for i = 1, #palette do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        local px = toolX + col * 22
        local py = bodyY + 142 + row * 22
        local color = palette[i]
        if i == (self.paintColor or 1) then
            self:drawRect(px - 2, py - 2, 22, 22, 1, 0.1, 0.28, 0.76)
        end
        self:drawRect(px, py, 18, 18, 1, color.r, color.g, color.b)
        self:drawRect(px, py, 18, 1, 1, 0, 0, 0)
        self:drawRect(px, py, 1, 18, 1, 0, 0, 0)
    end
    if self.paintNoticeText and self.paintNoticeText ~= "" then
        self:drawText(self.paintNoticeText, toolX, bodyY + bodyH - 30, 0.08, 0.28, 0.08, 1, UIFont.Small)
    end
end

function target:drawCalculatorPage()
    local bodyX = self.clientX + 22
    local bodyY = self.clientY + 18
    local bodyW = self.clientW - 44
    self:drawRect(bodyX, bodyY, bodyW, 38, 1, 0.88, 0.9, 0.88)
    self:drawRect(bodyX, bodyY, bodyW, 1, 1, 0.6, 0.62, 0.6)
    self:drawText(self.calculatorDisplay or "0", bodyX + bodyW - 90, bodyY + 11, 0, 0.12, 0, 1, UIFont.Medium)
end

function target:prerender()
    if self.bgTexture then
        self:drawTextureScaled(self.bgTexture, 0, 0, self.width, self.height, 1, 1, 1, 1)
    end
    self:drawRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight, 1.0, 0, 0, 0)
    if self.setStencilRect then
        self:setStencilRect(self.screenX, self.screenY, self.screenWidth, self.screenHeight)
    end

    if self.bootStep < 3 and not self:isFirmwareView() then
        self:drawBootScreen()
    else
        if self.currentView == "BIOS" then
            self:drawFullScreenBios()
            self:drawBiosPage()
        elseif self.currentView == "BOOT_ERROR" then
            self:drawFullScreenBootError()
            self:drawBootErrorPage()
        elseif self.currentView == "RESET_CONFIRM" and self.resetReturnView == "BIOS" then
            self:drawFullScreenBios()
            self:drawResetConfirmPage()
        elseif self.currentView == "RESETTING" and self.resetReturnView == "BIOS" then
            self:drawFullScreenBios()
            self:drawResetPage()
        elseif self.currentView == "INSTALLER" and self.installGameId == "os" then
            self:drawOSInstallPage()
        elseif self.currentView == "INSTALLING" and self.installGameId == "os" then
            self:drawOSInstallingPage()
        elseif self.currentView == "OS_SETUP" then
            self:drawOSFirstRunPage()
        elseif self.currentView == "NETWORK_TERMINAL" then
            self:drawNetworkTerminalPage()
        elseif self.currentView == "NETWORK_REPAIR" then
            self:drawNetworkRepairPage()
        else
            self:drawDesktop()
            if self.currentView == "GAMES" then
                self:drawGamesWindow()
            elseif self.currentView == "PONG" then
                self:drawAppWindow("Pong.exe", "ARROWS: Move", "SPACE: Restart")
            elseif self.currentView == "SNAKE" then
                self:drawAppWindow("Snake.exe", "ARROWS: Move", "SPACE: Restart")
            elseif self.currentView == "MINESWEEPER" then
                self:drawAppWindow("Minesweeper.exe", "LEFT: Open", "RIGHT: Flag")
            elseif self.currentView == "TETRIS" then
                self:drawAppWindow("Tetris.exe", "ARROWS: Move", "UP: Rotate")
            elseif self.currentView == "SPACE_INVADERS" then
                self:drawAppWindow("Invaders.exe", "ARROWS: Move", "SPACE: Fire")
            elseif self.currentView == "DOOM" then
                self:drawAppWindow("Doom.exe", "WASD: Move", "ARROWS+SPACE")
            elseif self.currentView == "RACER" then
                self:drawAppWindow("RoadRace.exe", "LEFT/RIGHT: Steer", "UP/DOWN + SPACE")
            elseif self.currentView == "FLAPPY" then
                self:drawAppWindow("FlappyBird.exe", "SPACE/UP: Flap", "SPACE: Restart")
            elseif self.currentView == "FILES" then
                self:drawFilesWindow()
                self:drawFilesPage()
            elseif self.currentView == "DOWNLOADS" then
                self:drawFilesWindow()
                self:drawDownloadsPage()
            elseif self.currentView == "FOLDER" then
                self:drawFilesWindow()
                self:drawFolderPage()
            elseif self.currentView == "FOLDER_EDIT" then
                self:drawAppWindow("Folder", "NAME", "SAVE")
                self:drawFolderEditPage()
            elseif self.currentView == "PASSWORD" or self.currentView == "LOCK" then
                self:drawAppWindow(self.currentView == "LOCK" and "Welcome" or "Security", self.currentView == "LOCK" and "LOGIN" or "PASSWORD", self.currentView == "LOCK" and "PZ OS 3.1" or "PASSWORD")
                self:drawPasswordPage()
            elseif self.currentView == "PASSWORD_HACK" then
                self:drawAppWindow("Hack.exe", "SPACE: Stop", "3 HITS")
                self:drawPasswordHackPage()
            elseif self.currentView == "RESET_CONFIRM" then
                self:drawAppWindow("Security", "CONFIRM RESET", "DATA WILL BE LOST")
                self:drawResetConfirmPage()
            elseif self.currentView == "RESETTING" then
                self:drawAppWindow("System Reset", "ERASING DATA", "PLEASE WAIT")
                self:drawResetPage()
            elseif self.currentView == "DISC_WIPE_CONFIRM" then
                self:drawAppWindow("CD Utility", "CONFIRM WIPE", "DATA WILL BE LOST")
                self:drawDiscWipeConfirmPage()
            elseif self.currentView == "DISC_WIPING" then
                self:drawAppWindow("CD Utility", "WIPING DISC", "PLEASE WAIT")
                self:drawDiscWipingPage()
            elseif self.currentView == "INSTALLER" then
                self:drawAppWindow("Setup.exe", "NEXT: Continue", "INSTALL: Finish")
                self:drawInstallPage()
            elseif self.currentView == "INSTALLING" then
                self:drawAppWindow("Setup.exe", "INSTALLING", "PLEASE WAIT")
                self:drawInstallingPage()
            elseif self.currentView == "CALCULATOR" then
                self:drawAppWindow("Calculator.exe", "CLICK: Input", "C: Clear")
                self:drawCalculatorPage()
            elseif self.currentView == "NOTEPAD" then
                self:drawAppWindow(self.activeNotepadName and (self.activeNotepadName .. ".txt") or "Notepad.exe", "TEXT: Auto-save", "CLOSE: Desktop")
            elseif self.currentView == "BROWSER" then
                self:drawAppWindow("Browser.exe", "GO: Open site", "START: System")
                self:drawBrowserPage()
            elseif self.currentView == "SETTINGS" then
                self:drawAppWindow("Settings.exe", "SAVE: User", "START: System")
                self:drawSettingsPage()
            elseif self.currentView == "MAIL" then
                self:drawAppWindow("Mail.exe", "LOGIN: Local Mail", "START: System")
                self:drawMailPage()
            elseif self.currentView == "CHAT" then
                self:drawAppWindow("Chat.exe", "MESSAGES: Server", "START: System")
                self:drawChatPage()
            elseif self.currentView == "BOARD" then
                self:drawAppWindow("Board.exe", "POST: Share news", "START: System")
                self:drawBoardPage()
            elseif self.currentView == "MARKET" then
                self:drawAppWindow("Market.exe", "SHOP: Buy", "JOBS: Earn")
                self:drawMarketPage()
            elseif self.currentView == "MARKET_JOB" then
                self:drawAppWindow("Job.exe", "CLICK: Match", "FIELDS")
                self:drawMarketPaperworkPage()
            elseif self.currentView == "MUSIC" then
                self:drawAppWindow("Music.exe", "VISUAL ONLY", "START: System")
                self:drawMusicPage()
            elseif self.currentView == "TRASH" then
                self:drawAppWindow("Trash.exe", "RECYCLE BIN", "START: System")
                self:drawTrashPage()
            elseif self.currentView == "PONG" then
                self:drawAppWindow("Pong.exe", "UP/DOWN: Move", "SPACE: Restart")
            elseif self.currentView == "SNAKE" then
                self:drawAppWindow("Snake.exe", "ARROWS: Move", "SPACE: Restart")
            elseif self.currentView == "MINESWEEPER" then
                self:drawAppWindow("Minesweeper.exe", "CLICK: Reveal", "RCLICK: Flag")
            elseif self.currentView == "TETRIS" then
                self:drawAppWindow("Tetris.exe", "ARROWS: Move", "SPACE: Rotate")
            elseif self.currentView == "SPACE_INVADERS" then
                self:drawAppWindow("Invaders.exe", "ARROWS: Move", "SPACE: Fire")
            elseif self.currentView == "DOOM" then
                self:drawAppWindow("Doom.exe", "ARROWS: Move", "SPACE: Fire")
            elseif self.currentView == "RACER" then
                self:drawAppWindow("Road Race.exe", "ARROWS: Steer", "SPACE: Restart")
            elseif self.currentView == "FLAPPY" then
                self:drawAppWindow("Flappy.exe", "SPACE: Flap", "SPACE: Restart")
            elseif self.currentView == "BREAKOUT" then
                self:drawAppWindow("Breakout.exe", "ARROWS: Move", "SPACE: Restart")
            elseif self.currentView == "ASTEROIDS" then
                self:drawAppWindow("Asteroids.exe", "ARROWS: Fly", "SPACE: Fire")
            elseif self.currentView == "FROGGER" then
                self:drawAppWindow("Frogger.exe", "ARROWS: Hop", "SPACE: Restart")
            elseif self.currentView == "MISSILE" then
                self:drawAppWindow("Missile.exe", "ARROWS: Aim", "SPACE: Launch")
            elseif self.currentView == "LANDER" then
                self:drawAppWindow("Lander.exe", "ARROWS: Rotate", "UP: Thrust")
            elseif self.currentView == "CIRCUIT" then
                self:drawAppWindow("Circuit.exe", "ARROWS: Move", "SPACE: Restart")
            elseif self.currentView == "MEMORY" then
                self:drawAppWindow("Memory.exe", "CLICK: Flip", "SPACE: Restart")
            elseif self.currentView == "STARPILOT" then
                self:drawAppWindow("StarPilot.exe", "ARROWS: Fly", "SPACE: Fire")
            elseif self.currentView == "CAVERUNNER" then
                self:drawAppWindow("CaveRun.exe", "UP/DOWN: Fly", "SPACE: Restart")
            elseif self.currentView == "LIGHTSOUT" then
                self:drawAppWindow("Lights.exe", "CLICK: Toggle", "SPACE: New")
            elseif self.currentView == "SIGNALMATCH" then
                self:drawAppWindow("Signal.exe", "CLICK: Repeat", "SPACE: Restart")
            elseif self.currentView == "BOXPUSH" then
                self:drawAppWindow("BoxPush.exe", "ARROWS: Push", "SPACE: Next")
            elseif self.currentView == "TILESLIDE" then
                self:drawAppWindow("TileSld.exe", "CLICK: Move", "SPACE: Shuffle")
            elseif self.currentView == "PIPELINK" then
                self:drawAppWindow("PipeLink.exe", "CLICK: Rotate", "SPACE: New")
            elseif self.currentView == "CODEBREAKER" then
                self:drawAppWindow("CodeBrk.exe", "CLICK: Set", "CHECK: Try")
            elseif self.currentView == "OUTBREAKOPS" then
                self:drawAppWindow("Ops.exe", "WASD: Move", "SPACE: Action")
            elseif self.currentView == "PAINT" then
                self:drawAppWindow("Paint.exe", "DRAW: Mouse", "SAVE: Desktop")
                self:drawPaintPage()
            end
        end
        if isDebugModeEnabled(self.playerObj) and not self:isFirmwareView() then
            local data = self:getComputerData()
            if data and data.ComputerModPasswordEnabled and data.ComputerModPassword then
                local debugText = "DEBUG PASS: " .. tostring(data.ComputerModPassword)
                self:drawRect(self.screenX + self.screenWidth - 138, self.screenY + 10, 126, 18, 0.7, 0, 0, 0)
                self:drawText(debugText, self.screenX + self.screenWidth - 132, self.screenY + 13, 1, 0.95, 0.85, 0.2, UIFont.Small)
            end
        end
        if not self:isFirmwareView() then
            for i = 0, self.screenHeight, 4 do
                self:drawRect(self.screenX, self.screenY + i, self.screenWidth, 1, 0.12, 0, 0, 0)
            end
            self:drawStartMenu()
            self:drawFolderContextMenu()
            self:drawDiscContextMenu()
            self:drawGameContextMenu()
            self:drawDesktopContextMenu()
            self:drawDesktopItemContextMenu()
            self:drawTrashContextMenu()
            self:drawFileItemContextMenu()
            self:drawTrashItemContextMenu()
            self:drawPaintFileContextMenu()
        end
    end
    if self.clearStencilRect then
        self:clearStencilRect()
    end
    self:drawStickyPasswordNote()
end

end
