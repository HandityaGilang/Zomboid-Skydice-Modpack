function ComputerModInstallUILifecycle(target)
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
    local desktopTrashTexture = shared.desktopTrashTexture
    local desktopMusicTexture = shared.desktopMusicTexture
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
    local startIconTexture = shared.startIconTexture
    local userTextures = shared.userTextures
    local easyComputerPasswords = shared.easyComputerPasswords
    local periodComputerNames = shared.periodComputerNames
    local backgroundPalettes = shared.backgroundPalettes
    local gameInstallOrder = shared.gameInstallOrder
    local gameInstallInfo = shared.gameInstallInfo
    local gameDownloadInfo = shared.gameDownloadInfo
    local gameDiscItems = shared.gameDiscItems
function target:disableComputerSpaceShove()
    if self.computerModSpaceGuardActive == true then return end
    self.computerModSpaceGuardActive = true
    self.computerModRestoreShoveStomp = false
    local playerObj = self.playerObj or (self.player and getSpecificPlayer and getSpecificPlayer(self.player)) or nil
    if not playerObj then return end
    local okAuthorized, authorized = pcall(function() return playerObj:isAuthorizeShoveStomp() end)
    if not okAuthorized or authorized ~= false then
        local okSet = pcall(function() playerObj:setAuthorizeShoveStomp(false) end)
        self.computerModRestoreShoveStomp = okSet == true
    end
end

function target:refreshComputerSpaceGuard()
    if self.computerModSpaceGuardActive ~= true then return end
    local playerObj = self.playerObj or (self.player and getSpecificPlayer and getSpecificPlayer(self.player)) or nil
    if playerObj then
        pcall(function() playerObj:setAuthorizeShoveStomp(false) end)
    end
end

function target:restoreComputerSpaceShove()
    if self.computerModSpaceGuardActive ~= true then return end
    local playerObj = self.playerObj or (self.player and getSpecificPlayer and getSpecificPlayer(self.player)) or nil
    if playerObj and self.computerModRestoreShoveStomp == true then
        pcall(function() playerObj:setAuthorizeShoveStomp(true) end)
    end
    self.computerModSpaceGuardActive = false
    self.computerModRestoreShoveStomp = false
end

function target:hideComputerScreen()
    self:saveCurrentNote()
    self:updateDownloadProgress(true)
    self:saveSessionView()
    self.folderContextMenu = nil
    self.gameContextMenu = nil
    self.startMenuOpen = false
    self.settingsMenuOpen = false
    self:setCalculatorButtonsVisible(false)
    if self.gameMusicID then
        getSoundManager():stopUISound(self.gameMusicID)
        self.gameMusicID = nil
    end
    self:setVisible(false)
    self:restoreComputerSpaceShove()
    self:removeFromUIManager()
    ComputerScreenUI.instance = nil
end

function target:shutdownComputer()
    self:saveCurrentNote()
    self:updateDownloadProgress(true)
    self:setComputerPowerOn(false)
    self.folderContextMenu = nil
    self.gameContextMenu = nil
    self.startMenuOpen = false
    self.settingsMenuOpen = false
    self:setCalculatorButtonsVisible(false)
    if self.pongInstance then self:removeChild(self.pongInstance); self.pongInstance = nil end
    if self.snakeInstance then self:removeChild(self.snakeInstance); self.snakeInstance = nil end
    if self.minesweeperInstance then self:removeChild(self.minesweeperInstance); self.minesweeperInstance = nil end
    if self.tetrisInstance then self:removeChild(self.tetrisInstance); self.tetrisInstance = nil end
    if self.spaceInvadersInstance then self:removeChild(self.spaceInvadersInstance); self.spaceInvadersInstance = nil end
    if self.doomInstance then self:removeChild(self.doomInstance); self.doomInstance = nil end
    if self.racerInstance then self:removeChild(self.racerInstance); self.racerInstance = nil end
    if self.flappyInstance then self:removeChild(self.flappyInstance); self.flappyInstance = nil end
    if self.breakoutInstance then self:removeChild(self.breakoutInstance); self.breakoutInstance = nil end
    if self.asteroidsInstance then self:removeChild(self.asteroidsInstance); self.asteroidsInstance = nil end
    if self.froggerInstance then self:removeChild(self.froggerInstance); self.froggerInstance = nil end
    if self.missileInstance then self:removeChild(self.missileInstance); self.missileInstance = nil end
    if self.landerInstance then self:removeChild(self.landerInstance); self.landerInstance = nil end
    if self.circuitInstance then self:removeChild(self.circuitInstance); self.circuitInstance = nil end
    if self.memoryInstance then self:removeChild(self.memoryInstance); self.memoryInstance = nil end
    if self.starPilotInstance then self:removeChild(self.starPilotInstance); self.starPilotInstance = nil end
    if self.caveRunnerInstance then self:removeChild(self.caveRunnerInstance); self.caveRunnerInstance = nil end
    if self.lightsOutInstance then self:removeChild(self.lightsOutInstance); self.lightsOutInstance = nil end
    if self.signalMatchInstance then self:removeChild(self.signalMatchInstance); self.signalMatchInstance = nil end
    if self.boxPushInstance then self:removeChild(self.boxPushInstance); self.boxPushInstance = nil end
    if self.tileSlideInstance then self:removeChild(self.tileSlideInstance); self.tileSlideInstance = nil end
    if self.pipeLinkInstance then self:removeChild(self.pipeLinkInstance); self.pipeLinkInstance = nil end
    if self.codeBreakerInstance then self:removeChild(self.codeBreakerInstance); self.codeBreakerInstance = nil end
    if self.outbreakOpsInstance then self:removeChild(self.outbreakOpsInstance); self.outbreakOpsInstance = nil end
    if self.gameMusicID then
        getSoundManager():stopUISound(self.gameMusicID)
        self.gameMusicID = nil
    end
    getSoundManager():playUISound("ComputerTurnOnOff")
    self:setVisible(false)
    self:restoreComputerSpaceShove()
    self:removeFromUIManager()
    ComputerScreenUI.instance = nil
end

function target:handleClose()
    self:saveCurrentNote()
    self.folderContextMenu = nil
    self:setCalculatorButtonsVisible(false)
    if self.pongInstance or self.snakeInstance or self.minesweeperInstance or self.tetrisInstance or self.spaceInvadersInstance or self.doomInstance or self.racerInstance or self.flappyInstance or self.breakoutInstance or self.asteroidsInstance or self.froggerInstance or self.missileInstance or self.landerInstance or self.circuitInstance or self.memoryInstance or self.starPilotInstance or self.caveRunnerInstance or self.lightsOutInstance or self.signalMatchInstance or self.boxPushInstance or self.tileSlideInstance or self.pipeLinkInstance or self.codeBreakerInstance or self.outbreakOpsInstance then
        if self.pongInstance then self:removeChild(self.pongInstance); self.pongInstance = nil end
        if self.snakeInstance then self:removeChild(self.snakeInstance); self.snakeInstance = nil end
        if self.minesweeperInstance then self:removeChild(self.minesweeperInstance); self.minesweeperInstance = nil end
        if self.tetrisInstance then self:removeChild(self.tetrisInstance); self.tetrisInstance = nil end
        if self.spaceInvadersInstance then self:removeChild(self.spaceInvadersInstance); self.spaceInvadersInstance = nil end
        if self.doomInstance then self:removeChild(self.doomInstance); self.doomInstance = nil end
        if self.racerInstance then self:removeChild(self.racerInstance); self.racerInstance = nil end
        if self.flappyInstance then self:removeChild(self.flappyInstance); self.flappyInstance = nil end
        if self.breakoutInstance then self:removeChild(self.breakoutInstance); self.breakoutInstance = nil end
        if self.asteroidsInstance then self:removeChild(self.asteroidsInstance); self.asteroidsInstance = nil end
        if self.froggerInstance then self:removeChild(self.froggerInstance); self.froggerInstance = nil end
        if self.missileInstance then self:removeChild(self.missileInstance); self.missileInstance = nil end
        if self.landerInstance then self:removeChild(self.landerInstance); self.landerInstance = nil end
        if self.circuitInstance then self:removeChild(self.circuitInstance); self.circuitInstance = nil end
        if self.memoryInstance then self:removeChild(self.memoryInstance); self.memoryInstance = nil end
        if self.starPilotInstance then self:removeChild(self.starPilotInstance); self.starPilotInstance = nil end
        if self.caveRunnerInstance then self:removeChild(self.caveRunnerInstance); self.caveRunnerInstance = nil end
        if self.lightsOutInstance then self:removeChild(self.lightsOutInstance); self.lightsOutInstance = nil end
        if self.signalMatchInstance then self:removeChild(self.signalMatchInstance); self.signalMatchInstance = nil end
        if self.boxPushInstance then self:removeChild(self.boxPushInstance); self.boxPushInstance = nil end
        if self.tileSlideInstance then self:removeChild(self.tileSlideInstance); self.tileSlideInstance = nil end
        if self.pipeLinkInstance then self:removeChild(self.pipeLinkInstance); self.pipeLinkInstance = nil end
        if self.codeBreakerInstance then self:removeChild(self.codeBreakerInstance); self.codeBreakerInstance = nil end
        if self.outbreakOpsInstance then self:removeChild(self.outbreakOpsInstance); self.outbreakOpsInstance = nil end
        if self.gameMusicID then
            getSoundManager():stopUISound(self.gameMusicID)
            self.gameMusicID = nil
        end
        self:restoreMainCloseButton()
        self.closeButton:setVisible(false)
        self:openGamesMenu()
    elseif self.currentView == "NOTEPAD" then
        self:restoreMainCloseButton()
        self:backToDesktop()
    elseif self.currentView == "GAMES" then
        self:backToDesktop()
    elseif self.currentView == "MARKET_JOB" then
        self.currentView = "MARKET"
        self.marketTab = "jobs"
        self.marketPaperworkJob = nil
        self.marketPaperworkSequence = nil
        self.marketPaperworkStep = 1
        self:setMarketControlsVisible(true)
        self:updateStartMenuButtons()
    else
        self:shutdownComputer()
    end
end

function target:refreshUIControls(force)
    local currentView = tostring(self.currentView or "")
    local viewChanged = self.computerModLastControlView ~= currentView
    if viewChanged then
        self.computerModLastControlView = currentView
        if currentView ~= "GAMES" and self.hideGameLauncherButtons then
            self:hideGameLauncherButtons()
        end
    end
    local now = getTimestampMs and getTimestampMs() or 0
    local due = now <= 0 or not self.computerModLastControlRefresh or now - self.computerModLastControlRefresh >= 250
    if force == true or viewChanged or due then
        self.computerModLastControlRefresh = now
        self:updateStartMenuButtons()
    end
end

function target:update()
    self:refreshComputerSpaceGuard()
    if not isPlayerNearComputer(self.playerObj, self.computer) then
        self:hideComputerScreen()
        return
    end
    if not hasComputerPower(self.computer) then
        self:setComputerPowerOn(false)
        self:setVisible(false)
        self:restoreComputerSpaceShove()
        self:removeFromUIManager()
        ComputerScreenUI.instance = nil
        if self.playerObj and self.playerObj.Say then
            self.playerObj:Say("Power is out.")
        end
        return
    end

    local timeStep = getComputerTimeStep()
    self:updateDownloadProgress()

    if self.browserLoading then
        self.browserLoadProgress = math.min(100, (self.browserLoadProgress or 0) + timeStep * 3.2)
        if self.browserLoadProgress >= 100 then
            self:finishBrowserLoad()
        end
    end

    if self.paintNoticeTimer and self.paintNoticeTimer > 0 then
        self.paintNoticeTimer = math.max(0, self.paintNoticeTimer - timeStep)
        if self.paintNoticeTimer <= 0 then
            self.paintNoticeText = nil
        end
    end

    if self.marketPaperworkErrorTimer and self.marketPaperworkErrorTimer > 0 then
        self.marketPaperworkErrorTimer = math.max(0, self.marketPaperworkErrorTimer - timeStep)
    end

    if self.magazineReadInProgress then
        self.magazineReadTimer = (self.magazineReadTimer or 0) + timeStep
        if self.magazineReadTimer >= (self.magazineReadDuration or 36) then
            self.magazineReadInProgress = false
            self.magazineReadTimer = 0
            if self.magazineReadEntry then
                self:completeReadableEntry(self.magazineReadEntry)
            end
            self.magazineReadEntry = nil
        end
    end

    if self.resetInProgress then
        self.resetTimer = self.resetTimer + timeStep
        if self.resetTimer >= 72 then
            self:performComputerReset()
        end
    end

    if self.discWipeInProgress then
        self.discWipeTimer = self.discWipeTimer + timeStep
        if self.discWipeTimer >= 72 then
            self:performDiscWipe()
        end
    end

    if self.installInProgress then
        self.installProgress = self.installProgress + timeStep
        if self.installProgress >= 84 then
            self.installInProgress = false
            self:removeMinimizedView("INSTALLING")
            self:removeMinimizedView("INSTALLER")
            local installedNow = self:installGame(self.installGameId)
            if self.installNextButton then
                self.installNextButton:setTitle(tr("Installed"))
            end
            if self.installGameId == "os" then
                self:openOSFirstRunSetup()
            else
                self:startFiles()
                if installedNow and self.tryTriggerGameInstallVirus then
                    self:tryTriggerGameInstallVirus()
                end
            end
            return
        end
    end

    if self.bootStep < 3 and not self:isFirmwareView() then
        self.bootTimer = self.bootTimer + timeStep

        if self.bootTimer > 1 and self.bootStep == 0 then
            self.bootStep = 1
            getSoundManager():playUISound("ComputerStartup")
        end
        if self.bootTimer > 8 and self.bootStep == 1 then self.bootStep = 2 end
        if self.bootTimer > 58 and self.bootStep == 2 then
            self.bootStep = 3
            self:setComputerPowerOn(true)
            if self:isNetworkTerminal() then
                self:openNetworkTerminal()
                playComputerUISound("ComputerWinOpen")
            elseif self:isOSInstalled() then
                self:openLockScreen()
                playComputerUISound("ComputerWinOpen")
            else
                self:showBootError()
            end
            self:updateStartMenuButtons()
        end
    end

    if self.currentView == "NOTEPAD" and self.notepadEntry and self.notepadEntry:isVisible() then
        self.noteSaveTick = self.noteSaveTick + 1
        if self.noteSaveTick >= 15 then
            self.noteSaveTick = 0
            self:saveCurrentNote()
        end
    else
        self.noteSaveTick = 0
    end

    if self.passwordErrorTimer and self.passwordErrorTimer > 0 then
        self.passwordErrorTimer = self.passwordErrorTimer - 1
        if self.passwordErrorTimer <= 0 then
            self.passwordErrorText = nil
            self.passwordErrorTimer = 0
        end
    end

    if self.fileNoticeTimer and self.fileNoticeTimer > 0 then
        self.fileNoticeTimer = self.fileNoticeTimer - 1
        if self.fileNoticeTimer <= 0 then
            self.fileNoticeText = nil
            self.fileNoticeTimer = 0
        end
    end

    self:updatePasswordHack(timeStep)
    self:updateNetworkRepair(timeStep)
    self:refreshUIControls(false)
end

end

