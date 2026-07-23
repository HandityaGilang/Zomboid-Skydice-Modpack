
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

require "ISUI/ISPanel"
require "ISUI/ISTickBox"
require "ISUI/ISToolTip"
require "LMN_SyncAdmin3"

if not LMN then LMN = {} end

LMN_AdminPanelUI = {}
LMN_AdminPanelUI.panel = nil

LMN = LMN or {}
LMN.AdminPanel = LMN.AdminPanel or {
    activeNoteId = nil,
    isOpen = false
}

function LMN_AdminPanelUI.toggle(parent)
    if not parent or not parent.noteItem then return end

    local noteItem = parent.noteItem
    local md = noteItem:getModData()
    md.LMN_Admin = md.LMN_Admin or {
        hideDontShow = false,
        destroyAfterOpen = false,
        lockPickup = false
    }

    if LMN_AdminPanelUI.panel then
        local panel = LMN_AdminPanelUI.panel

        if panel.noteItem == noteItem then
            panel.animatingOut = true
            return
        end

        panel.parentWindow = parent
        panel.noteItem = noteItem
        panel.adminData = md.LMN_Admin

        panel:setX(parent.x + parent.width - panel.width - 10)
        panel:setY(parent.y + 40)
        panel:bringToTop()
        return
    end
    
    -- Ukuran panel
    local w, h = 280, 140
    local x = parent.x + parent.width - w + 0
    local y = parent.y - 145

    -- biar ga keluar layar
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    x = math.max(10, math.min(x, screenWidth - w - 10))
    y = math.max(10, math.min(y, screenHeight - h - 10))

    local panel = ISPanel:new(x, y, w, h)
    panel:initialise()
    panel:addToUIManager()
    panel:bringToTop()
    
    -- Link ke parent window
    panel.parentWindow = parent
    
    -- VARIABEL DRAGGING
    panel.dragging = false
    panel.dragOffsetX = 0
    panel.dragOffsetY = 0
    
    -- VARIABEL ANIMASI
    panel.alpha = 0 
    panel.animatingIn = true
    panel.animatingOut = false
    
    -- VARIABEL AUTO-HIDE
    panel.checkNoteDistance = true
    panel.lastNoteCheckTime = 0
    panel.NOTE_CHECK_INTERVAL = 0.5
    
    -- SIMPAN DATA
    panel.noteItem = noteItem
    panel.adminData = md.LMN_Admin
    panel.backgroundColor = {r=0.05, g=0.05, b=0.05, a=1}
    panel.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    panel.titleBarColor = {r=0.2, g=0.2, b=0.2, a=1}
    panel.titleBarHeight = 25
    
    -- CHECKBOX DATA (MANUAL RENDER)
    panel.checkboxes = {
        {
            text = "Hide (Don't show it again)",
            y = panel.titleBarHeight + 15,
            selected = panel.adminData.hideDontShow or false,
            id = 1
        },
        {
            text = "Destroy After Open",
            y = panel.titleBarHeight + 40,
            selected = panel.adminData.destroyAfterOpen or false,
            id = 2
        },
        {
            text = "Cannot Be Picked Up",
            y = panel.titleBarHeight + 65,
            id = 3,
            selected = (function()
                local noteId = noteItem and noteItem.getID and noteItem:getID()
                local cached = (LMN.ClientLockedNotes and LMN.ClientLockedNotes[noteId])
                local md = noteItem and noteItem.getModData and noteItem:getModData()
                local localState = (md and md.LMN_Admin and md.LMN_Admin.lockPickup) and true or false
                if cached ~= nil then return cached end
                return localState
            end)()
        }
    }

    -- RENDER FUNCTION (SEMUA DI SATU TEMPAT BIAR GA PUSING HUHU)
    panel.render = function(self)
        local alpha = self.alpha
        
        -- BACKGROUND
        self:drawRect(0, 0, self.width, self.height, 
            alpha,
            self.backgroundColor.r,
            self.backgroundColor.g,
            self.backgroundColor.b)
        
        -- BORDER
        self:drawRectBorder(0, 0, self.width, self.height, 
            alpha,
            self.borderColor.r,
            self.borderColor.g,
            self.borderColor.b)
        
        -- TITLE BAR (area untuk dragging)
        self:drawRect(0, 0, self.width, self.titleBarHeight, 
            alpha,
            self.titleBarColor.r,
            self.titleBarColor.g,
            self.titleBarColor.b)
        
        -- TITLE TEXT
        self:drawTextCentre("Admin Settings", 
            self.width/2, 6, 
            1, 1, 1, alpha, UIFont.Small)
        
        -- TOMBOL CLOSE (X merah di kanan atas)
        local closeBtnSize = 16
        local closeBtnX = self.width - closeBtnSize - 5
        local closeBtnY = 5
        
        -- Background tombol close
        self:drawRect(closeBtnX, closeBtnY, closeBtnSize, closeBtnSize, 
            alpha, 0.8, 0.1, 0.1)  -- Merah
        
        -- Border tombol close
        self:drawRectBorder(closeBtnX, closeBtnY, closeBtnSize, closeBtnSize, 
            alpha, 1, 1, 1)  -- Putih
        
        -- Text "X"
        self:drawText("X", closeBtnX + 5, closeBtnY + 1, 
            1, 1, 1, alpha, UIFont.Small)
        
        -- Simpan posisi tombol close untuk mouse click
        self.closeBtnRect = {
            x = closeBtnX,
            y = closeBtnY,
            width = closeBtnSize,
            height = closeBtnSize
        }
        
        -- Judul garis bawah title bar
        self:drawRect(0, self.titleBarHeight-1, self.width, 1, 
            alpha, 0.5, 0.5, 0.5)
        
        -- Cek render checkbox manual
        for i, checkbox in ipairs(self.checkboxes) do
            local boxX = 20
            local boxY = checkbox.y
            local boxSize = 16
            
            -- Checkbox border
            self:drawRectBorder(boxX, boxY, boxSize, boxSize, 
                alpha, 0.7, 0.7, 0.7)
            
            -- Checkbox fill jika selected
            if checkbox.selected then
                local padding = 3
                self:drawRect(boxX + padding, boxY + padding, 
                    boxSize - (padding * 2), boxSize - (padding * 2), 
                    alpha, 0.2, 0.8, 0.2)
            end
            
            -- Checkbox text
            self:drawText(checkbox.text, boxX + boxSize + 8, boxY + 1, 
                0.9, 0.9, 0.9, alpha, UIFont.Small)
        end
    end
    
    -- MOUSE HANDLERS
    panel.onMouseDown = function(self, x, y)
        -- Cek tombol close
        if self.closeBtnRect and
           x >= self.closeBtnRect.x and x <= self.closeBtnRect.x + self.closeBtnRect.width and
           y >= self.closeBtnRect.y and y <= self.closeBtnRect.y + self.closeBtnRect.height then
            
            self.animatingOut = true

            if LMN.AdminPanel.activeNoteId == tostring(self.noteItem:getID()) then
                LMN.AdminPanel.activeNoteId = nil
                LMN.AdminPanel.isOpen = false
            end
            
            if getSoundManager() then
                getSoundManager():playUISound("UIClickClose")
            end
            return true
        end
        
        -- Cek klik di title bar biar bisa drag
        if y <= self.titleBarHeight then
            self.dragging = true
            local mx = getMouseX()
            local my = getMouseY()
            self.dragOffsetX = mx - self.x
            self.dragOffsetY = my - self.y
            self:bringToTop()
            
            if getSoundManager() then
                getSoundManager():playUISound("UIActivateButton")
            end
            return true
        end
        
        -- Cek klik di checkbox
        for i, checkbox in ipairs(self.checkboxes) do
            local boxX = 20
            local boxY = checkbox.y
            local boxSize = 16
            
            -- Hitung area klik (kotak + text)
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, checkbox.text)
            local totalWidth = boxSize + 8 + textWidth
            
            if x >= boxX and x <= boxX + totalWidth and
               y >= boxY and y <= boxY + boxSize then
                
                -- Toggle checkbox
                checkbox.selected = not checkbox.selected
                
                if getSoundManager() then
                    getSoundManager():playUISound("UIActivateButton")
                end
                
                local playerObj = getPlayer()

                -- Admin Data
                if checkbox.id == 1 then 
                    local note = self.noteItem
                    if not note then return true end
                    
                    local desired = checkbox.selected
                    self.adminData.hideDontShow = desired
                    
                    if LMN_AdminClient1 and LMN_AdminClient1.sendHideMode then
                        LMN_AdminClient1.sendHideMode(playerObj, note, desired)
                    end

                elseif checkbox.id == 2 then 
                    local note = self.noteItem
                    if not note then return true end
                    
                    local desired = checkbox.selected
                    self.adminData.destroyAfterOpen = desired
                    
                    if isClient() then
                        local w = note:getWorldItem()
                        if w then
                            sendClientCommand(playerObj, "LMN", "SetDestroyMode", {
                                noteId = note:getID(),
                                active = desired,
                                x = w:getX(),
                                y = w:getY(),
                                z = w:getZ()
                            })
                        end
                    end

                elseif checkbox.id == 3 then
                    local note = self.noteItem
                    if not note then return true end
                    
                    local desired = checkbox.selected
                    
                    if isClient() then
                        local w = note:getWorldItem()
                        if w then
                            if not LMN.ClientLockedNotes then LMN.ClientLockedNotes = {} end
                            LMN.ClientLockedNotes[note:getID()] = desired
                             
                            sendClientCommand(playerObj, "LMN", "SetPickupLock", {
                                noteId = note:getID(),
                                locked = desired,
                                x = w:getX(),
                                y = w:getY(),
                                z = w:getZ()
                            })
                        end
                    end
                end
                
                return true
            end
        end
        
        return false
    end
    
    panel.onMouseMove = function(self, dx, dy)
        if not self.dragging then return end
        if not isMouseButtonDown(0) then
            self.dragging = false
            return
        end
        
        local mx = getMouseX()
        local my = getMouseY()
        
        local newX = mx - self.dragOffsetX
        local newY = my - self.dragOffsetY
        
        newX = math.max(0, math.min(newX, screenWidth - self.width))
        newY = math.max(0, math.min(newY, screenHeight - self.height))
        
        self:setX(newX)
        self:setY(newY)
    end
    
    panel.onMouseUp = function(self, x, y)
        self.dragging = false
    end
    
    -- Animasi dan cek jarak note
    panel.onUpdate = function(self)
        -- FADE IN: dari 0 ke 1
        if self.animatingIn then
            self.alpha = self.alpha + 0.05
            if self.alpha >= 1 then
                self.alpha = 1
                self.animatingIn = false
            end
        
        -- FADE OUT: dari 1 ke 0
        elseif self.animatingOut then
            self.alpha = self.alpha - 0.05
            if self.alpha <= 0 then
                self:setVisible(false)
                self:removeFromUIManager()
                    if self.renderTickFunc then
                        Events.OnRenderTick.Remove(self.renderTickFunc)
                    end

                LMN_AdminPanelUI.panel = nil
                
                -- Reset variabel yang dibagi
                if LMN.AdminPanel.activeNoteId == tostring(self.noteItem:getID()) then
                    LMN.AdminPanel.activeNoteId = nil
                    LMN.AdminPanel.isOpen = false
                end
                
                return
            end
        end
        
        -- Cek window kalau udh ditutup
        if self.parentWindow and not self.parentWindow:getIsVisible() then
            if not self.animatingOut then
                self.animatingOut = true
            end
        end
        
        -- Cek jarak note
        if self.checkNoteDistance then
            local currentTime = getTimestampMs() / 1000
            if currentTime - self.lastNoteCheckTime > self.NOTE_CHECK_INTERVAL then
                self.lastNoteCheckTime = currentTime
                
                if self.noteItem then
                    local player = getPlayer()
                    if player then
                        local playerSquare = player:getCurrentSquare()
                        if playerSquare then
                            local foundNote = false
                            local cell = getCell()
                            if cell then
                                local pX, pY, pZ = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
                                for dx = -1, 1 do
                                    for dy = -1, 1 do
                                        local square = cell:getGridSquare(pX + dx, pY + dy, pZ)
                                        if square then
                                            local worldObjects = square:getWorldObjects()
                                            if worldObjects then
                                                for i = 0, worldObjects:size() - 1 do
                                                    local worldObj = worldObjects:get(i)
                                                    if worldObj then
                                                        local item = worldObj:getItem()
                                                        if item and item:getID() == self.noteItem:getID() then
                                                            foundNote = true
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        if foundNote then break end
                                    end
                                    if foundNote then break end
                                end
                            end
                            
                            if not foundNote and not self.animatingOut then
                                self.animatingOut = true
                            end
                        end
                    end
                end
            end
        end
    end
    
    panel.renderTickFunc = function()
        if panel and panel.onUpdate then
            panel:onUpdate()
        end
    end

    Events.OnRenderTick.Add(panel.renderTickFunc)
    
    -- Set variable yang dibagi
    LMN.AdminPanel.activeNoteId = tostring(panel.noteItem:getID())
    LMN.AdminPanel.isOpen = true
    
    -- Berbunyi dia
    if getSoundManager() then
        getSoundManager():playUISound("UIToggleTab")
    end
    
    LMN_AdminPanelUI.panel = panel
end

-- Function untuk force close panel dari luar
function LMN_AdminPanelUI.forceClose()
    if LMN_AdminPanelUI.panel then
        LMN_AdminPanelUI.panel.animatingOut = true
    end
end