require "RadioCom/RadioWindowModules/RWMPanel"
require "TimedActions/SWTCPlayerAction"
require "RadioCom/RadioWindowModules/SWTClcdbar"

if not SWTCCDAlbums then 
    SWTCCDAlbums = {} 
end

SWTCRWMMedia = RWMPanel:derive("SWTCRWMMedia")

local tickControl = 100  
local tickStart = 0

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

local CUSTOM_CD_STATUS_CODES = "BOR-1,UHP-1,STS-0.5"
local function playPlayerEmitterSound(playerObj, soundName)
    if not playerObj or not soundName or not playerObj.getEmitter then return nil end
    local emitter = playerObj:getEmitter()
    if not emitter then return nil end
    if emitter.playSoundImpl then
        return emitter:playSoundImpl(soundName, playerObj)
    end
    if emitter.playSound then
        return emitter:playSound(soundName)
    end
    return nil
end

local function getEquippedCDbag(player)
    if not player then return nil end
    local inv = player:getInventory()
    local items = inv:getItems()
    for i = 0, items:size()-1 do
        local item = items:get(i)
        if item and item:getFullType() == "Base.Bag_CDbag" and player:isEquipped(item) then
            return item
        end
    end
    return nil
end
function SWTCRWMMedia:initialise()
    ISPanel.initialise(self)
end

function SWTCRWMMedia:createChildren()
    local y = UI_BORDER_SPACING + 1
    local charW = getCore():getOptionFontSizeReal() >= 4 and 21 or 14
    local lcdCharWidth = math.floor((self:getWidth() - UI_BORDER_SPACING * 2 - 2) / charW)
    local lcdw = lcdCharWidth * charW
    local x = ((self:getWidth() / 2) - (lcdw / 2)) - 2

    self.lcd = SWTClcdbar:new(x, y, lcdCharWidth)
    self.lcd:initialise()
    if self.lcd.setTextMode then
        self.lcd:setTextMode(false)
    end
    self:addChild(self.lcd)

    y = self.lcd:getY() + self.lcd:getHeight() + UI_BORDER_SPACING

    local unitWidth = math.floor(lcdw / 5)
    
    self.itemDropBox = ISItemDropBox:new(x, y, BUTTON_HGT, BUTTON_HGT, false, self, 
                                        SWTCRWMMedia.addMedia, SWTCRWMMedia.removeMedia, 
                                        SWTCRWMMedia.verifyItem, nil)
    self.itemDropBox:initialise()
    self.itemDropBox:setBackDropTex(getTexture("Item_Disc"), 0.4, 1, 1, 1)
    self.itemDropBox:setDoBackDropTex(true)
    self.itemDropBox:setToolTip(true, getText("IGUI_media_dragCD"))
    self:addChild(self.itemDropBox)

    local buttonWidth = math.floor(unitWidth * 0.8)

    local prevX = x + unitWidth
    self.prevButton = ISButton:new(prevX + (unitWidth - buttonWidth) / 2, y, buttonWidth, BUTTON_HGT, "<<", self, SWTCRWMMedia.previousTrack)
    self.prevButton:initialise()
    self.prevButton.backgroundColor = {r=0, g=0, b=0, a=0.0}
    self.prevButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.2}
    self.prevButton.borderColor = {r=0, g=0, b=0, a=0.0}
    self:addChild(self.prevButton)

    local playX = x + unitWidth * 2
    self.toggleOnOffButton = ISButton:new(playX + (unitWidth - buttonWidth) / 2, y, buttonWidth, BUTTON_HGT, getText("ContextMenu_Turn_On"), self, SWTCRWMMedia.togglePlayMedia)
    self.toggleOnOffButton:initialise()
    self.toggleOnOffButton.backgroundColor = {r=0, g=0, b=0, a=0.0}
    self.toggleOnOffButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.2}
    self.toggleOnOffButton.borderColor = {r=0, g=0, b=0, a=0.0}
    self:addChild(self.toggleOnOffButton)
    
    local nextX = x + unitWidth * 3
    self.nextButton = ISButton:new(nextX + (unitWidth - buttonWidth) / 2, y, buttonWidth, BUTTON_HGT, ">>", self, SWTCRWMMedia.nextTrack)
    self.nextButton:initialise()
    self.nextButton.backgroundColor = {r=0, g=0, b=0, a=0.0}
    self.nextButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.2}
    self.nextButton.borderColor = {r=0, g=0, b=0, a=0.0}
    self:addChild(self.nextButton)


    y = self.toggleOnOffButton:getY() + self.toggleOnOffButton:getHeight() + UI_BORDER_SPACING + 1

    self:setHeight(y)
end

function SWTCRWMMedia:togglePlayMedia()
    self:performTogglePlayMedia()
end

function SWTCRWMMedia:removeMedia()
    local cdbag = getEquippedCDbag(self.player)
    local targetContainer = cdbag and cdbag:getInventory() or nil
    ISTimedActionQueue.add(SWTCPlayerAction:new("RemoveMedia", self.player, self.device, nil, targetContainer))
end

function SWTCRWMMedia:addMedia(_items)
    if not _items or #_items == 0 then
        return
    end
    
    self:performAddMedia(_items[1])
end

function SWTCRWMMedia:verifyItem(_item)
    return self:isCustomCD(_item) or self:isOriginalCD(_item)
end

function SWTCRWMMedia:performTogglePlayMedia()
    if not self.player or not self.device or not self.deviceData then
        return
    end

    if not self.deviceData:getIsTurnedOn() or self.deviceData:getPower() <= 0 then
        return
    end

    if self.deviceData:getHeadphoneType() < 0 then
        if self.player:getModData().customMusic and self.player:getModData().customMusic.isPlaying then
            local modData = self.device:getModData()
            modData.customMusic.isPlaying = false
            self:stopCurrentTrack()
            local originalVolume = self.player:getModData().originalMusicVolume
            if originalVolume then
                getCore():setOptionMusicVolume(originalVolume)
                self.player:getModData().originalMusicVolume = nil
            end
        end
        return
    end
    
    local modData = self.device:getModData()
    if modData.originalCD then
        self:performToggleOriginalCD()
        return
    end
    if not modData.customMusic or not modData.customMusic.cdType then
        return
    end
    
    local isCurrentlyPlaying = modData.customMusic.isPlaying == true
    
    if isCurrentlyPlaying then
        modData.customMusic.isPlaying = false
        
        self:stopCurrentTrack()
        local originalVolume = self.player:getModData().originalMusicVolume
        if originalVolume then
            getCore():setOptionMusicVolume(originalVolume)
            self.player:getModData().originalMusicVolume = nil
        end

    else
        self:playCurrentTrack()
    end
end
function SWTCRWMMedia:performToggleOriginalCD()
    local modData = self.device:getModData()
    
    if not modData.originalCD then
        return
    end
    if modData.originalCD.isPlaying then
        modData.originalCD.isPlaying = false
        if self.deviceData and self.deviceData.stopPlayMedia then
            self.deviceData:stopPlayMedia()
        elseif self.deviceData and self.deviceData.StopPlayMedia then
            self.deviceData:StopPlayMedia()
        end
        if modData.originalCD.textDisplayTimer then
            Events.OnTick.Remove(modData.originalCD.textDisplayTimer)
            modData.originalCD.textDisplayTimer = nil
        end
        
    else
        modData.originalCD.isPlaying = true
        if self.deviceData and self.deviceData.startPlayMedia then
            self.deviceData:startPlayMedia()
        elseif self.deviceData and self.deviceData.StartPlayMedia then
            self.deviceData:StartPlayMedia()
        end
        if modData.originalCD.mediaData and modData.originalCD.mediaData.getLines then
            local lines = modData.originalCD.mediaData:getLines()
            if lines and lines:size() > 0 then
                modData.originalCD.currentLineIndex = 0
                modData.originalCD.textDisplayTimer = function()
                    if not modData.originalCD or not modData.originalCD.isPlaying then
                        Events.OnTick.Remove(modData.originalCD.textDisplayTimer)
                        modData.originalCD.textDisplayTimer = nil
                        return
                    end
                    if modData.originalCD.currentLineIndex < lines:size() then
                        local line = lines:get(modData.originalCD.currentLineIndex)
                        if line and line:getText() then
                        end
                        modData.originalCD.currentLineIndex = modData.originalCD.currentLineIndex + 1
                    else
                        modData.originalCD.currentLineIndex = 0
                    end
                end
                Events.OnTick.Add(modData.originalCD.textDisplayTimer)
            end
        end
    end
end

function SWTCRWMMedia:performAddMedia(item)
    if not item or not self.player or not self.device then
        return
    end
    if self:isOriginalCD(item) then
        return self:addOriginalCD(item)
    end
    if not self:isCustomCD(item) then
        return
    end
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.cdType then
        return
    end
    if not modData.customMusic then
        modData.customMusic = {}
    end
    local itemType = item:getType()
    local cdData = self:getCDData(itemType)
    
    if cdData then
        modData.customMusic.cdType = itemType
        modData.customMusic.cdDisplayName = cdData.displayName
        modData.customMusic.tracks = cdData.tracks
        modData.customMusic.currentTrack = 1
        modData.customMusic.totalTracks = #cdData.tracks
        modData.customMusic.isPlaying = false
        -- store full item type for correct ejecting later
        modData.customMusic.fullItemType = self:getItemFullType(itemType)
        local container = item:getContainer()
        if container then
            container:DoRemoveItem(item)
        end
    end
end

function SWTCRWMMedia:getItemFullType(itemType)
    if not itemType then return nil end
    if SWTCCDAlbums and SWTCCDAlbums[itemType] and SWTCCDAlbums[itemType].fullItemType then
        return SWTCCDAlbums[itemType].fullItemType
    end
    local modId = string.match(itemType, "^([^_]+)_")
    if modId then
        return modId .. "_CustomMusic." .. itemType
    end
    return "Base." .. itemType
end

function SWTCRWMMedia:isCustomCD(_item)
    if not _item then return false end
    local itemType = _item:getType()
    local cdData = self:getCDData(itemType)
    
    if cdData then
        return true
    end
    
    return false
end

function SWTCRWMMedia:isOriginalCD(_item)
    if not _item then return false end
    if _item:getFullType() ~= "Base.Disc_Retail" then
        return false
    end
    if not _item:isRecordedMedia() then
        return false
    end
    
    return true
end

function SWTCRWMMedia:addOriginalCD(item)
    if not item or not self.player or not self.device then
        return false
    end
    
    local modData = self.device:getModData()
    if (modData.customMusic and modData.customMusic.cdType) or (modData.originalCD) then
        return false
    end
    if not modData.originalCD then
        modData.originalCD = {}
    end
    modData.originalCD.cdType = "Disc_Retail"
    modData.originalCD.cdDisplayName = "CD"
    modData.originalCD.isPlaying = false
    modData.originalCD.originalItem = item 
    modData.originalCD.mediaData = item:getMediaData()
    
    if self.deviceData and self.deviceData.addMediaItem then
        self.deviceData:addMediaItem(item)
    end
    local container = item:getContainer()
    if container then
        container:DoRemoveItem(item)
    end
    
    return true
end

function SWTCRWMMedia:getCDData(itemType)
    if not itemType then return nil end
    if not SWTCCDAlbums then
        SWTCCDAlbums = {}
    end
    local albumData = SWTCCDAlbums[itemType]
    if albumData then
        
        return {
            displayName = albumData.displayName,
            tracks = albumData.tracks,
            totalTracks = albumData.totalTracks
        }
    end
    return nil
end

function SWTCRWMMedia:hasCustomCD()
    local modData = self.device:getModData()
    return (modData.customMusic and modData.customMusic.cdType ~= nil) or (modData.originalCD ~= nil)
end

function SWTCRWMMedia:isPlayingCustomCD()
    local modData = self.device:getModData()
    return modData.customMusic and modData.customMusic.isPlaying == true
end
function SWTCRWMMedia:isPlayingOriginalCD()
    local modData = self.device:getModData()
    return modData.originalCD and modData.originalCD.isPlaying == true
end

function SWTCRWMMedia:getCurrentTrackName()
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.tracks and modData.customMusic.currentTrack then
        local trackIndex = modData.customMusic.currentTrack
        if trackIndex >= 1 and trackIndex <= #modData.customMusic.tracks then
            local trackData = modData.customMusic.tracks[trackIndex]
            if type(trackData) == "table" and trackData.soundName then
                return trackData.soundName
            end
        end
    end
    return nil
end

function SWTCRWMMedia:getCurrentTrackDisplayName()
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.tracks and modData.customMusic.currentTrack then
        local trackIndex = modData.customMusic.currentTrack
        if trackIndex >= 1 and trackIndex <= #modData.customMusic.tracks then
            local trackData = modData.customMusic.tracks[trackIndex]

            if type(trackData) == "table" and trackData.displayName then
                local raw = trackData.displayName
                if string.match(raw, "^IGUI_") then
                    -- Use getTextOrNull so a missing translation falls through
                    -- to a clean fallback instead of leaking the IGUI_ key.
                    local translated = getTextOrNull(raw)
                    if translated then return translated end
                    return (getTextOrNull("IGUI_TM_Track") or "Track") .. " " .. tostring(trackIndex)
                else
                    return raw
                end
            end
            return (getTextOrNull("IGUI_TM_Track") or "Track") .. " " .. tostring(trackIndex)
        end
    end
    return getText("IGUI_Unknown_Track")
end

function SWTCRWMMedia:getMediaText()
    local modData = self.device:getModData()
    if modData.originalCD and modData.originalCD.cdDisplayName then
        if modData.originalCD.mediaData then
            local text = ""
            local addedSegment = false
            
            if modData.originalCD.mediaData:getTitleEN() then
                addedSegment = true
                text = modData.originalCD.mediaData:getTitleEN()
            end
            if modData.originalCD.mediaData:getSubtitleEN() then
                addedSegment = true
                text = text .. (addedSegment and " - " or "") .. modData.originalCD.mediaData:getSubtitleEN()
            end
            if modData.originalCD.mediaData:getAuthorEN() then
                addedSegment = true
                text = text .. (addedSegment and " - " or "") .. modData.originalCD.mediaData:getAuthorEN()
            end
            
            if addedSegment then
                return text
            end
        end
        
        return modData.originalCD.cdDisplayName
    end
    if modData.customMusic and modData.customMusic.cdDisplayName then
        local raw = modData.customMusic.cdDisplayName
        local albumName = raw
        if string.match(raw, "^IGUI_") then
            albumName = getTextOrNull(raw) or "CD"
        end
        if modData.customMusic.currentTrack and modData.customMusic.totalTracks then
            local trackDisplayName = self:getCurrentTrackDisplayName()
            return albumName .. " [" .. modData.customMusic.currentTrack .. "/" .. modData.customMusic.totalTracks .. "] - " .. trackDisplayName
        else
            return albumName
        end
    end
    
    return getText("IGUI_SWTC_NoCD")
end

function SWTCRWMMedia:stopCurrentTrack()
    local deviceId = self:getDeviceId()
    if deviceId and self.player:getModData().customMusicIds and self.player:getModData().customMusicIds[deviceId] then
        self.player:getEmitter():stopSound(self.player:getModData().customMusicIds[deviceId])
        self.player:getModData().customMusicIds[deviceId] = nil
    end
end

function SWTCRWMMedia:playCurrentTrack()
    local modData = self.device:getModData()
    if not modData.customMusic then return false end
    modData.customMusic.isPlaying = true
    local originalVolume = getCore():getOptionMusicVolume()
    self.player:getModData().originalMusicVolume = originalVolume
    getCore():setOptionMusicVolume(0)
    local currentSoundName = self:getCurrentTrackName()
    
    if currentSoundName then
        local deviceId = self:getDeviceId()
        if not self.player:getModData().customMusicIds then
            self.player:getModData().customMusicIds = {}
        end
        if self.player:getModData().customMusicIds[deviceId] then
            self.player:getEmitter():stopSound(self.player:getModData().customMusicIds[deviceId])
        end
        self.player:getModData().customMusicIds[deviceId] = playPlayerEmitterSound(self.player, currentSoundName)
        
        if self.player:getModData().customMusicIds[deviceId] then
            local actualVolume = self.deviceData:getDeviceVolume() * 0.4
            self.player:getEmitter():setVolume(self.player:getModData().customMusicIds[deviceId], actualVolume)
            local uniqueGuid = "custom-cd-guid-initial-" .. tostring(getTimestampMs())
            ISRadioInteractions:getInstance().OnDeviceText(uniqueGuid, CUSTOM_CD_STATUS_CODES, -1, -1, -1, "Custom CD playing")
            
            return true
        else
            modData.customMusic.isPlaying = false
            return false
        end
    else
        modData.customMusic.isPlaying = false
        return false
    end
end

function SWTCRWMMedia:nextTrack()
    if not self:hasCustomCD() then return end
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.tracks then
        local wasPlaying = self:isPlayingCustomCD()
        if wasPlaying then
            self:stopCurrentTrack()
        end
        modData.customMusic.currentTrack = modData.customMusic.currentTrack + 1
        if modData.customMusic.currentTrack > modData.customMusic.totalTracks then
            modData.customMusic.currentTrack = 1
        end
        if wasPlaying then
            self:playCurrentTrack()
        end
        
        return true
    end
    return false
end

function SWTCRWMMedia:previousTrack()
    if not self:hasCustomCD() then return end
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.tracks then
        local wasPlaying = self:isPlayingCustomCD()
        if wasPlaying then
            self:stopCurrentTrack()
        end
        modData.customMusic.currentTrack = modData.customMusic.currentTrack - 1
        if modData.customMusic.currentTrack < 1 then
            modData.customMusic.currentTrack = modData.customMusic.totalTracks  -- 循环到最后一首
        end
        if wasPlaying then
            self:playCurrentTrack()
        end
        
        return true
    end
    return false
end

function SWTCRWMMedia:update()
    ISPanel.update(self)
    
    if self.player and self.device and self.deviceData then
        local isOn = self.deviceData:getIsTurnedOn()
        local needsPower = false
        if self.deviceData:getIsBatteryPowered() then
            if not self.deviceData:getHasBattery() or self.deviceData:getPower() <= 0 then
                needsPower = true
            end
        elseif not self.deviceData:canBePoweredHere() then
            needsPower = true
        end
        if needsPower and isOn then
            self.deviceData:setIsTurnedOn(false)
            isOn = false
            if self:isPlayingCustomCD() then
                local modData = self.device:getModData()
                modData.customMusic.isPlaying = false
                self:stopCurrentTrack()
                local originalVolume = self.player:getModData().originalMusicVolume
                if originalVolume then
                    getCore():setOptionMusicVolume(originalVolume)
                    self.player:getModData().originalMusicVolume = nil
                end
            end
        end
        if isOn and self:isPlayingCustomCD() then
            local deviceId = self:getDeviceId()
            if deviceId and self.player:getModData().customMusicIds and self.player:getModData().customMusicIds[deviceId] then
                local emitter = self.player:getEmitter()
                if emitter and not emitter:isPlaying(self.player:getModData().customMusicIds[deviceId]) then
                    local modData = self.device:getModData()
                    if modData.customMusic and modData.customMusic.tracks and modData.customMusic.totalTracks > 1 then
                        modData.customMusic.currentTrack = modData.customMusic.currentTrack + 1
                        if modData.customMusic.currentTrack > modData.customMusic.totalTracks then
                            modData.customMusic.currentTrack = 1  -- 循环到第一首
                        end
                        self.player:getModData().customMusicIds[deviceId] = nil
                        self:playCurrentTrack()
                    else
                        modData.customMusic.isPlaying = false
                        self.player:getModData().customMusicIds[deviceId] = nil
                        local originalVolume = self.player:getModData().originalMusicVolume
                        if originalVolume then
                            getCore():setOptionMusicVolume(originalVolume)
                            self.player:getModData().originalMusicVolume = nil
                        end
                    end
                end
            end
        end
        if isOn and self:isPlayingCustomCD() then
            self.tickStart = self.tickStart + 1
            if self.tickStart % self.tickControl == 0 then
                self.tickStart = 0
                local hasHeadphones = self.deviceData:getHeadphoneType() >= 0
                if not hasHeadphones then
                    local volume = self.deviceData:getDeviceVolume()
                    local baseRadius
                    if self.player:isOutside() then
                        baseRadius = 30 * volume
                    else
                        baseRadius = 10 * volume
                    end
                    local soundMultiplier = getSandboxOptions():getOptionByName("FirearmNoiseMultiplier")
                    if soundMultiplier then
                        baseRadius = baseRadius * soundMultiplier:getValue()
                    end
                    local radius = math.ceil(baseRadius)
                    
                    if radius > 0 then
                        addSound(self.player, self.player:getX(), self.player:getY(), self.player:getZ(), radius, volume)
                    end
                end
                if self:isPlayingCustomCD() then
                    local uniqueGuid = "custom-cd-guid-" .. tostring(getTimestampMs())
                    ISRadioInteractions:getInstance().OnDeviceText(uniqueGuid, CUSTOM_CD_STATUS_CODES, -1, -1, -1, "Custom CD playing")
                end
            end
        end
        self.lcd:toggleOn(isOn)
        if (not isOn) and self:isPlayingCustomCD() then
            local modData = self.device:getModData()
            modData.customMusic.isPlaying = false
            self:stopCurrentTrack()
            local originalVolume = self.player:getModData().originalMusicVolume
            if originalVolume then
                getCore():setOptionMusicVolume(originalVolume)
                self.player:getModData().originalMusicVolume = nil
            end
        end
        if isOn and self:isPlayingCustomCD() and self.deviceData:getHeadphoneType() < 0 then
            local modData = self.device:getModData()
            modData.customMusic.isPlaying = false
            self:stopCurrentTrack()
            local originalVolume = self.player:getModData().originalMusicVolume
            if originalVolume then
                getCore():setOptionMusicVolume(originalVolume)
                self.player:getModData().originalMusicVolume = nil
            end
        end
        local hasCD = self:hasCustomCD()
        local hasPower = not needsPower
        local canUse = hasCD and isOn and hasPower
        
        self.toggleOnOffButton:setEnable(canUse)
        self.prevButton:setEnable(canUse)
        self.nextButton:setEnable(canUse)
        if canUse then
            self.toggleOnOffButton.borderColor = {r=1.0, g=1.0, b=1.0, a=0.3}
        else
            self.toggleOnOffButton.borderColor = {r=1.0, g=0.0, b=0.0, a=0.3}
        end
        if self:isPlayingOriginalCD() then
            self.toggleOnOffButton:setTitle(self.textStop)
        elseif self:isPlayingCustomCD() then
            self.toggleOnOffButton:setTitle(self.textStop)
        else
            self.toggleOnOffButton:setTitle(self.textPlay)
        end
        
        if self:hasCustomCD() then
            self.itemDropBox:setStoredItemFake(self.cdTex)
            local hasHeadphones = self.deviceData:getHeadphoneType() >= 0
            if self:isPlayingOriginalCD() then
                self.lcd:setText(self:getMediaText())
                self.lcd:setDoScroll(true)
            elseif self:isPlayingCustomCD() then
                self.lcd:setText(self:getMediaText())
                self.lcd:setDoScroll(true)
            elseif not hasHeadphones then
                self.lcd:setText(self.textNeedHeadphones)
            else
                self.lcd:setText(self.idleText)
            end
        else
            self.itemDropBox:setStoredItemFake(nil)
            self.lcd:setText(self.textNoCD)
        end
    end
end

function SWTCRWMMedia:clear()
    RWMPanel.clear(self)
end

function SWTCRWMMedia:readFromObject(_player, _deviceObject, _deviceData, _deviceType)
    self.mediaIndex = -9999
    if self.itemDropBox then
        self.itemDropBox:setBackDropTex(getTexture("Item_Disc"), 0.4, 1, 1, 1)
        self.itemDropBox:setToolTip(true, getText("IGUI_SWTC_DragCD"))
    end
    if self.lcd then
        self.lcd.ledColor = { r=0.172, g=0.686, b=0.764, a=1.0 }
    end
    
    local read = RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType)
    
    if self.player then
        self.itemDropBox.mouseEnabled = true
        if JoypadState.players[self.player:getPlayerNum() + 1] then
            self.itemDropBox.mouseEnabled = false
        end
    end
    
    return true
end

function SWTCRWMMedia:new(x, y, width, height)
    local o = RWMPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=0.0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.fontheight = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ") + 2
    o.cdTex = getTexture("Item_Disc")
    o.lcdBlue = {
        text = { r=0.039, g=0.180, b=0.2, a=1.0 },
        back = { r=0.172, g=0.686, b=0.764, a=1.0 }
    }
    
    o.mediaIndex = -9999
    o.mediaText = ""
    o.idleText = getText("IGUI_SWTC_Ready")
    o.textPlay = getText("IGUI_SWTC_Play")
    o.textStop = getText("IGUI_SWTC_Stop")
    o.textNoCD = getText("IGUI_SWTC_NoCD")
    o.textNeedHeadphones = getText("IGUI_SWTC_NEED_HEADPHONES")
    o.tickStart = 0
    o.tickControl = 300
    
    return o
end
function SWTCRWMMedia:getDeviceId()
    if not self.device then return nil end
    if instanceof(self.device, "InventoryItem") then
        return "item_" .. self.device:getID()
    elseif instanceof(self.device, "IsoObject") then
        return "world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
    elseif instanceof(self.device, "VehiclePart") then
        if self.device:getVehicle() then
            return "vehicle_" .. self.device:getVehicle():getId() .. "_" .. self.device:getType()
        else
            return "vehiclepart_" .. self.device:getType()
        end
    else
        return "default_" .. tostring(self.device)
    end
end
function SWTCRWMMedia:isDevicePlaying()
    local deviceId = self:getDeviceId()
    if deviceId and self.player:getModData().customMusicIds and self.player:getModData().customMusicIds[deviceId] then
        local emitter = self.player:getEmitter()
        return emitter and emitter:isPlaying(self.player:getModData().customMusicIds[deviceId])
    end
    return false
end
function SWTCRWMMedia:replaceMedia(newItem)
    if self:hasCustomCD() then
        local function tryAdd()
            if not self:hasCustomCD() then
                self:addMedia({newItem})
                Events.OnTick.Remove(tryAdd)
            end
        end
        self:removeMedia()
        Events.OnTick.Add(tryAdd)
    else
        self:addMedia({newItem})
    end
end