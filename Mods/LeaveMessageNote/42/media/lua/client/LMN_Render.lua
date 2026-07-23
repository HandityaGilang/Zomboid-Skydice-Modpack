
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 
            
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISUIElement"
require "ISUI/ISTickBox"
require "LMN_Utils"
require "LMN_AdminPanelUI"

LMN_PopupUI = LMN_PopupUI or {}
LMN_PopupUI.currentPopup = nil
LMN_PopupUI.currentNote = nil
LMN_PopupUI.currentWorldObj = nil
LMN_PopupUI.checkRadius = 0.1
LMN_PopupUI.dontShowAgainNotes = {}
LMN_PopupUI.lastPlayerPos = {x=0, y=0, z=0}
LMN_PopupUI.notesInRadius = {}  -- Track semua note dalam radius

LMN_PopupUI.lastCheckTime = 0
LMN_PopupUI.CHECK_INTERVAL = 0.1  -- 100ms = 10x per detik
LMN_PopupUI.lastPopupTime = 0
LMN_PopupUI.POPUP_COOLDOWN = 1.0  -- 1 detik cooldown antar popup
LMN_PopupUI.savedPositions = {}

-- Track note pas di radius player
function LMN_PopupUI.updateNotesInRadius()
    local player = getPlayer()
    if not player then return {} end
    
    local playerSquare = player:getCurrentSquare()
    if not playerSquare then return {} end
    
    local pX, pY, pZ = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
    local cell = getCell()
    if not cell then return {} end
    
    local newNotesInRadius = {}
    
    for dx = -1, 1 do
        for dy = -1, 1 do
            local distance = math.sqrt(dx*dx + dy*dy)
            if distance <= 1 then
                local square = cell:getGridSquare(pX + dx, pY + dy, pZ)
                if square then
                    local worldObjects = square:getWorldObjects()
                    if worldObjects then
                        for i = 0, worldObjects:size() - 1 do
                            local worldObj = worldObjects:get(i)
                            if worldObj then
                                local item = worldObj:getItem()
                                if item and item:getFullType() == "Base.Note" then
                                    local text = item:getModData().leaveMessage
                                    if text and text ~= "" and LMN_PopupUI.shouldShowNote(item) then
                                        local noteId = tostring(item:getID())
                                        newNotesInRadius[noteId] = {
                                            item = item,
                                            worldObj = worldObj,
                                            text = text,
                                            square = square,
                                            distance = distance
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return newNotesInRadius
end

function LMN_PopupUI.shouldShowNote(noteItem)
    if not noteItem then return true end
    local noteId = "note_" .. tostring(noteItem:getID())
    return not LMN_PopupUI.dontShowAgainNotes[noteId]
end

function LMN_PopupUI.markDontShowAgain(noteItem)
    if not noteItem then return end
    local player = getPlayer()
    if not player then return end

    local noteId = "note_" .. tostring(noteItem:getID())
    
    LMN_PopupUI.dontShowAgainNotes[noteId] = true
    
    if isClient() then
        sendClientCommand(player, "LMN_Player", "SaveDontShow", {
            noteId = noteId
        })
    else
        local pData = player:getModData()
        pData.LMN_dontShowNotes = pData.LMN_dontShowNotes or {}
        pData.LMN_dontShowNotes[noteId] = true
    end
end

LMN_PopupUI.noteOpenSounds = {
    "NoteOpen1",
    "NoteOpen2",
    "NoteOpen3"
}

function LMN_PopupUI.playRandomNoteSound()
    if not getSoundManager() then return end
    local sounds = LMN_PopupUI.noteOpenSounds
    local snd = sounds[ZombRand(#sounds) + 1]
    getSoundManager():playUISound(snd)
end


function LMN_PopupUI.createPopup(text, noteItem, worldObj)
    local currentTime = getTimestampMs() / 1000
    if currentTime - LMN_PopupUI.lastPopupTime < LMN_PopupUI.POPUP_COOLDOWN then
        return
    end
    LMN_PopupUI.lastPopupTime = currentTime

    if not LMN_PopupUI.shouldShowNote(noteItem) then
        return
    end
    
    if LMN_PopupUI.currentPopup then
        LMN_PopupUI.currentPopup:setVisible(false)
        LMN_PopupUI.currentPopup:removeFromUIManager()
        LMN_PopupUI.currentPopup = nil
    end
    
    local player = getPlayer()
    if not player then return end
    
    if player:getVehicle() then
        return
    end
    
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    
    local font = UIFont.Medium
    local lineHeight = getTextManager():getFontHeight(font) + 2
    local maxWidth = 500
    
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local currentLine = ""
    for _, word in ipairs(words) do
        local testLine = currentLine .. (currentLine == "" and "" or " ") .. word
        local lineWidth = getTextManager():MeasureStringX(font, testLine)
        
        if lineWidth <= maxWidth - 40 then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    local textHeight = #lines * lineHeight
    local popupWidth = maxWidth
    local popupHeight = textHeight + 140
    
    popupWidth = math.min(popupWidth, screenWidth * 0.9)
    popupHeight = math.min(popupHeight, screenHeight * 0.8)

    if not LMN_PopupUI.savedPositions then
        LMN_PopupUI.savedPositions = {}
    end

    -- Check saved position untuk note ini
    local startX = (screenWidth - popupWidth) / 2
    local startY = (screenHeight - popupHeight) / 2
    
    if noteItem then
        local noteId = "note_" .. tostring(noteItem:getID())
        if LMN_PopupUI.savedPositions and LMN_PopupUI.savedPositions[noteId] then
            local saved = LMN_PopupUI.savedPositions[noteId]
            -- Pastikan tidak keluar layar
            startX = math.max(10, math.min(saved.x, screenWidth - popupWidth - 10))
            startY = math.max(10, math.min(saved.y, screenHeight - popupHeight - 10))
        end
    end
    
    -- VARIABEL UNTUK CHECKBOX & BUTTON
    local checkboxSize = 16
    local checkboxPadding = 8
    local checkboxText = "Don't show it again"
    local checkboxTextWidth = getTextManager():MeasureStringX(UIFont.Small, checkboxText)
    local totalCheckboxWidth = checkboxSize + checkboxPadding + checkboxTextWidth
    
    local checkboxX = 20
    local checkboxY = popupHeight - 35
    local checkboxRect = {x = checkboxX, y = checkboxY, width = checkboxSize, height = checkboxSize}
    
    local buttonWidth = 70 -- Lebar
    local buttonHeight = 18 -- Tinggi (kadang lupa gw)
    local buttonX = popupWidth - buttonWidth - 20
    local buttonY = popupHeight - 34
    local buttonRect = {x = buttonX, y = buttonY, width = buttonWidth, height = buttonHeight}
    
    local buttonText = "OK"
    local buttonTextWidth = getTextManager():MeasureStringX(UIFont.Small, buttonText)
    local buttonTextX = buttonX + (buttonWidth - buttonTextWidth) / 0
    local buttonTextY = buttonY - 2
    
    -- startX dan startY
    local window = ISPanel:new(
        startX,
        startY,
        popupWidth,
        popupHeight
    )

    window.isAdmin = LMN.isAdmin(getPlayer())
    window.settingsIcon = getTexture("media/ui/LMNS.png")

    window.dragging = false
    window.dragOffsetX = 0
    window.dragOffsetY = 0
    window.alpha = 1
    window.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.85}
    window.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    window.noteItem = noteItem
    window.lines = lines
    window.font = font
    window.textHeight = textHeight
    window.lineHeight = lineHeight
    window.checkboxSelected = false
    window.buttonHovered = false
    window.checkboxHovered = false

    local md = noteItem and noteItem:getModData() or {}
    md.LMN_Admin = md.LMN_Admin or {
        hideDontShow = false,
        destroyAfterOpen = false,
        lockPickup = false
    }
    window.adminData = md.LMN_Admin
    
    -- SEMUA RENDER DALAM SATU FUNGSI BIAR GA PUSING AGGGHH
    window.render = function(self)
        local alpha = 1 - self.alpha
        
        -- MAIN WINDOW BACKGROUND
        self:drawRect(0, 0, self.width, self.height, 
            self.backgroundColor.a * alpha,
            self.backgroundColor.r, 
            self.backgroundColor.g, 
            self.backgroundColor.b)
        
        -- WINDOW BORDER
        self:drawRectBorder(0, 0, self.width, self.height, 
            self.borderColor.a * alpha,
            self.borderColor.r, 
            self.borderColor.g, 
            self.borderColor.b)
        
        -- TITLE "NOTE"
        self:drawTextCentre("NOTE", 
            self.width / 2, 20, 
            1, 1, 1, alpha,
            UIFont.Large)
        
        -- TITLE UNDERLINE
        self:drawRect(20, 48, self.width - 40, 1, alpha, 0.5, 0.5, 0.5)
        
        -- TEXT AREA BACKGROUND
        self:drawRect(20, 60, self.width - 40, self.textHeight, 
            alpha * 0.1, 0.2, 0.2, 0.2)
        
        -- NOTE TEXT LINES
        for i, line in ipairs(self.lines) do
            local lineWidth = getTextManager():MeasureStringX(self.font, line)
            local x = 20 + ((self.width - 40 - lineWidth) / 2)
            local y = 60 + ((i-1) * self.lineHeight)
            
            self:drawText(line, x, y, 1.0, 1.0, 0.7, alpha, self.font)
        end

        -- Dont show it again area
        if not (self.adminData and self.adminData.hideDontShow) then
            
            -- CHECKBOX BOX
            local checkboxBorderAlpha = alpha
            if self.checkboxHovered then
                checkboxBorderAlpha = alpha * 0.9
            end
            
            self:drawRectBorder(checkboxRect.x, checkboxRect.y, 
                checkboxRect.width, checkboxRect.height, 
                checkboxBorderAlpha, 0.7, 0.7, 0.7)
            
            -- CHECKMARK JIKA DI SELECT
            if self.checkboxSelected then
                local checkPadding = 3
                self:drawRect(
                    checkboxRect.x + checkPadding, 
                    checkboxRect.y + checkPadding, 
                    checkboxRect.width - (checkPadding * 2), 
                    checkboxRect.height - (checkPadding * 2), 
                    alpha, 0.2, 0.8, 0.2
                )
            end
            
            -- CHECKBOX TEXT
            local checkboxTextX = checkboxRect.x + checkboxRect.width + checkboxPadding
            local checkboxTextY = checkboxRect.y + 1
            self:drawText(checkboxText, checkboxTextX, checkboxTextY, 
                1, 1, 1, alpha, UIFont.Small)

        end
        
        -- BUTTON BACKGROUND 
        local buttonBgAlpha = alpha * 0.3
        local buttonBorderAlpha = alpha
        
        if self.buttonHovered then
            buttonBgAlpha = alpha * 0.4
            buttonBorderAlpha = alpha * 0.9
        end
        
        self:drawRect(buttonRect.x, buttonRect.y, 
            buttonRect.width, buttonRect.height, 
            buttonBgAlpha, 0.3, 0.3, 0.3)
        
        -- BUTTON BORDER
        self:drawRectBorder(buttonRect.x, buttonRect.y, 
            buttonRect.width, buttonRect.height, 
            buttonBorderAlpha, 0.6, 0.6, 0.6)
        
        -- BUTTON TEXT
        self:drawTextCentre(buttonText, 
            buttonRect.x + (buttonWidth / 2), 
            buttonTextY, 
            1, 1, 1, alpha, UIFont.Medium)

        -- ADMIN SETTINGS ICON (Berbahagialah kalian para admin!)
        if self.isAdmin then
            self:drawTextureScaled(
                self.settingsIcon,
                self.width - 26,
                6,
                20,
                20,
                1, 1, 1, 1
            )
        end
    end
    
    -- HANDLE MOUSE CLICK
    window.onMouseDown = function(self, x, y)
        if self.isAdmin then
            local iconX = self.width - 26
            local iconY = 6

            if x >= iconX and x <= iconX + 20 and
            y >= iconY and y <= iconY + 20 then

                LMN_AdminPanelUI.toggle(self)

                if getSoundManager() then
                    getSoundManager():playUISound("UIActivateButton")
                end

                return true
            end
        end

        if not (self.adminData and self.adminData.hideDontShow) then
            if x >= checkboxRect.x and x <= checkboxRect.x + totalCheckboxWidth and
            y >= checkboxRect.y and y <= checkboxRect.y + checkboxRect.height then

                self.checkboxSelected = not self.checkboxSelected

                if getSoundManager() then
                    getSoundManager():playUISound("UIActivateButton")
                end
                return true
            end
        end

        if x >= buttonRect.x and x <= buttonRect.x + buttonRect.width and
        y >= buttonRect.y and y <= buttonRect.y + buttonRect.height then

            if getSoundManager() then
                getSoundManager():playUISound("UIActivateButton")
            end

            if self.checkboxSelected then
                LMN_PopupUI.markDontShowAgain(self.noteItem)
            end

            self.animatingOut = true
            return true
        end

        local titleY1 = 10
        local titleY2 = 50

        if y >= titleY1 and y <= titleY2 then
            self.dragging = true

            local mx = getMouseX()
            local my = getMouseY()

            self.dragOffsetX = mx - self.x
            self.dragOffsetY = my - self.y

            self:bringToTop()
            return true
        end

        return false
    end

    -- DRAGGING
    window.onMouseMove = function(self, dx, dy)
        if not self.dragging then return end
        if not isMouseButtonDown(0) then
            self.dragging = false
            return
        end

        local mx = getMouseX()
        local my = getMouseY()

        local newX = mx - self.dragOffsetX
        local newY = my - self.dragOffsetY

        local sw = getCore():getScreenWidth()
        local sh = getCore():getScreenHeight()

        newX = math.max(0, math.min(newX, sw - self.width))
        newY = math.max(0, math.min(newY, sh - self.height))

        self:setX(newX)
        self:setY(newY)

        if self.buttonHovered and not self._hoverSoundPlayed then
            getSoundManager():playUISound("UIMouseOver")
            self._hoverSoundPlayed = true
        elseif not self.buttonHovered then
            self._hoverSoundPlayed = false
        end
    end

    window.onMouseUp = function(self, x, y)
        self.dragging = false
    end

    -- Animasi
    window.animatingIn = true
    window.animatingOut = false
    
    function window:onUpdate()
        -- FADE IN: dari 1 (invisible) ke 0 (visible)
        if self.animatingIn then
            self.alpha = self.alpha - 0.1
            if self.alpha <= 0 then
                self.alpha = 0
                self.animatingIn = false
            end
        -- FADE OUT: dari 0 (visible) ke 1 (invisible)
        elseif self.animatingOut then
            self.alpha = self.alpha + 0.1
            if self.alpha >= 1 then
                self:setVisible(false)
                self:removeFromUIManager()
                    if self.adminData and self.adminData.destroyAfterOpen and not self.isAdmin then
                        local worldObj = LMN_PopupUI.currentWorldObj
                        if worldObj then
                            worldObj:getSquare():removeWorldObject(worldObj)
                            worldObj:removeFromWorld()
                        end
                    end

                LMN_PopupUI.currentPopup = nil
                LMN_PopupUI.currentNote = nil
                LMN_PopupUI.currentWorldObj = nil
                return
            end
        end
    end
    
    -- Key bind (ENTER, SPACE, ESC untuk close) gatau berfungsi apa engga bodoamat pusing
    function window:onKeyPress(key)
        if key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
            if self.checkboxSelected then
                LMN_PopupUI.markDontShowAgain(noteItem)
            end
            
            -- SOUND EFFECT: Key press close
            if getSoundManager() then
                getSoundManager():playUISound("UIActivateButton")
            end
            
            self.animatingOut = true
            return true
        end
    end
    
    window:setCapture(false)
    window.movable = true
    window.resizable = false
    window:addToUIManager()
    window:bringToTop()
    
    LMN_PopupUI.currentPopup = window
    LMN_PopupUI.currentNote = noteItem
    LMN_PopupUI.currentWorldObj = worldObj
    
    -- SOUND EFFECT: Popup muncul
    LMN_PopupUI.playRandomNoteSound()
end

-- FUNGSI UTAMA: Fast check setiap frame
function LMN_PopupUI.fastCheck()
    local player = getPlayer()
    if not player or player:getVehicle() then 
        return 
    end

    local newNotes = LMN_PopupUI.updateNotesInRadius()

    if LMN_PopupUI.currentNote and LMN_PopupUI.currentPopup and LMN_PopupUI.currentPopup:getIsVisible() then
        local noteId = tostring(LMN_PopupUI.currentNote:getID())
        if not newNotes[noteId] then
            if not LMN_PopupUI.currentPopup.animatingOut then
                LMN_PopupUI.currentPopup.animatingOut = true
            end
        end
    end
    
    LMN_PopupUI.notesInRadius = newNotes
end

-- Check khusus saat note di-drop (immediate response)
local function onWorldItemAdded(worldItem)
    if not worldItem then return end
    
    local item = worldItem:getItem()
    local md = item:getModData()
    if md.LMN_Admin and md.LMN_Admin.lockPickup then
        return
    end
        
    if item and item:getFullType() == "Base.Note" then
        local text = item:getModData().leaveMessage
        if text and text ~= "" and LMN_PopupUI.shouldShowNote(item) then
            local player = getPlayer()
            if player then
                local playerSquare = player:getCurrentSquare()
                local noteSquare = worldItem:getSquare()
                
                if playerSquare and noteSquare then
                    local pZ = playerSquare:getZ()
                    local nZ = noteSquare:getZ()
                    
                    if pZ == nZ then
                        local pX, pY = playerSquare:getX(), playerSquare:getY()
                        local nX, nY = noteSquare:getX(), noteSquare:getY()
                        local distance = math.sqrt((pX - nX)^2 + (pY - nY)^2)
                        
                        if distance <= LMN_PopupUI.checkRadius then
                            LMN_PopupUI.createPopup(text, item, worldItem)
                        end
                    end
                end
            end
        end
    end
end

function LMN_PopupUI.loadPreferences()
    if not LMN_PopupUI.savedPositions then
        LMN_PopupUI.savedPositions = {}
    end
    
    local player = getPlayer()
    if player then
        local playerData = player:getModData()
        if playerData.LMN_dontShowNotes then
            LMN_PopupUI.dontShowAgainNotes = playerData.LMN_dontShowNotes
        end
        if playerData.LMN_notePositions then
            for noteId, pos in pairs(playerData.LMN_notePositions) do
                LMN_PopupUI.savedPositions[noteId] = pos
            end
        end
    end
end

function LMN_PopupUI.initialize()
    LMN_PopupUI.currentPopup = nil
    LMN_PopupUI.currentNote = nil
    LMN_PopupUI.currentWorldObj = nil
    LMN_PopupUI.notesInRadius = {}
    LMN_PopupUI.dontShowAgainNotes = {}
    
    if not LMN_PopupUI.savedPositions then
        LMN_PopupUI.savedPositions = {}
    end
   
    LMN_PopupUI.loadPreferences()
end

function LMN_PopupUI.onRenderTick()
    local currentTime = getTimestampMs() or 0
    
    if LMN_PopupUI.currentPopup and LMN_PopupUI.currentPopup.onUpdate then
        LMN_PopupUI.currentPopup:onUpdate()
    end
    
    if currentTime - LMN_PopupUI.lastCheckTime < LMN_PopupUI.CHECK_INTERVAL then
        return
    end
    LMN_PopupUI.lastCheckTime = currentTime
    
    LMN_PopupUI.fastCheck()
end

Events.OnGameStart.Add(LMN_PopupUI.initialize)
Events.OnCreatePlayer.Add(LMN_PopupUI.loadPreferences)
Events.OnRenderTick.Add(LMN_PopupUI.onRenderTick)