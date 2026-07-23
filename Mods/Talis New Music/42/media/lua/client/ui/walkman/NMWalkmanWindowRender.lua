local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

function WalkmanWindow:prerender()
    self:beginFrameEpoch("prerender")
    local resolved = self:resolveContextCached()
    self:syncPlayButtonFromTransport(resolved, true, false)
    local nowMs = getNowMs()
    local lastHeadphoneSyncMs = tonumber(self._nmLastHeadphoneWearSyncMs) or 0
    if (nowMs - lastHeadphoneSyncMs) >= 250 then
        self._nmLastHeadphoneWearSyncMs = nowMs
        if NMHeadphoneSlot and NMHeadphoneSlot.tickWearSync and self.headphoneSlot and self.headphoneSlot.button then
            self._nmHeadphoneWearSyncActive = (NMHeadphoneSlot.tickWearSync(self, resolved) == true)
        else
            self._nmHeadphoneWearSyncActive = false
        end
    end
    ISPanel.prerender(self)
    if self.backgroundColor then
        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    end
    if not UI_TEXTURES.backplateBase and getTexture then
        UI_TEXTURES.backplateBase = getTexture(BACKPLATE_BASE_TEXTURE_PATH)
    end
    if not UI_TEXTURES.backplateSlotBg and getTexture then
        UI_TEXTURES.backplateSlotBg = getTexture(BACKPLATE_SLOT_BG_TEXTURE_PATH)
    end
    if not UI_TEXTURES.lidEdge and getTexture then
        UI_TEXTURES.lidEdge = getTexture(LID_EDGE_TEXTURE_PATH)
    end
    if not UI_TEXTURES.playButton and getTexture then
        UI_TEXTURES.playButton = getTexture(PLAY_BUTTON_TEXTURE_PATH)
    end
    if not UI_TEXTURES.prevButton and getTexture then
        UI_TEXTURES.prevButton = getTexture(PREV_BUTTON_TEXTURE_PATH)
    end
    if not UI_TEXTURES.nextButton and getTexture then
        UI_TEXTURES.nextButton = getTexture(NEXT_BUTTON_TEXTURE_PATH)
    end
    if not UI_TEXTURES.volumeWheel and getTexture then
        UI_TEXTURES.volumeWheel = getTexture(VOLUME_WHEEL_TEXTURE_PATH)
    end
    if not UI_TEXTURES.loopButton and getTexture then
        UI_TEXTURES.loopButton = getTexture(LOOP_BUTTON_TEXTURE_PATH)
    end
    if not UI_TEXTURES.spool and getTexture then
        UI_TEXTURES.spool = getTexture(SPOOL_TEXTURE_PATH)
    end
    if UI_TEXTURES.volumeWheel then
        local wheelRect = self:getVolumeWheelRect()
        local centerX = wheelRect.x + (wheelRect.w / 2)
        local centerY = wheelRect.y + (wheelRect.h / 2)
        local effectiveVolume = self._nmWheelDragging == true and self._nmWheelPreviewVolume or self._nmWheelStableVolume
        self:DrawTextureAngle(UI_TEXTURES.volumeWheel, centerX, centerY, self:getVolumeWheelAngle(effectiveVolume or 1.0))
    end
    if UI_TEXTURES.loopButton then
        local loopRect = self:getLoopButtonRect()
        self:drawTextureScaled(UI_TEXTURES.loopButton, loopRect.x, loopRect.y, loopRect.w, loopRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    local walkmanTextures = self:resolveWalkmanUITextures()
    local playButtonTexture = walkmanTextures and walkmanTextures.play or UI_TEXTURES.playButton
    local prevButtonTexture = walkmanTextures and walkmanTextures.prev or UI_TEXTURES.prevButton
    local nextButtonTexture = walkmanTextures and walkmanTextures.next or UI_TEXTURES.nextButton
    if playButtonTexture then
        local playRect = self:getPlayButtonRect()
        self:drawTextureScaled(playButtonTexture, playRect.x, playRect.y, playRect.w, playRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if prevButtonTexture then
        local prevRect = self:getPrevButtonRect()
        self:drawTextureScaled(prevButtonTexture, prevRect.x, prevRect.y, prevRect.w, prevRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if nextButtonTexture then
        local nextRect = self:getNextButtonRect()
        self:drawTextureScaled(nextButtonTexture, nextRect.x, nextRect.y, nextRect.w, nextRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if walkmanTextures and walkmanTextures.base then
        self:drawTextureScaled(walkmanTextures.base, 0, 0, self.width, self.height, 1.0, 1.0, 1.0, 1.0)
    elseif UI_TEXTURES.backplateBase then
        self:drawTextureScaled(UI_TEXTURES.backplateBase, 0, 0, self.width, self.height, 1.0, 1.0, 1.0, 1.0)
    end
    if walkmanTextures and walkmanTextures.side then
        local sideRect = self:getWalkmanSideRect()
        self:drawTextureScaled(walkmanTextures.side, sideRect.x, sideRect.y, sideRect.w, sideRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if UI_TEXTURES.backplateSlotBg then
        self:drawTextureScaled(UI_TEXTURES.backplateSlotBg, 0, 0, self.width, self.height, 1.0, 1.0, 1.0, 1.0)
    end
    local timedCassetteState = self:getTimedCassetteAnimationState()
    if timedCassetteState.visible == true and timedCassetteState.texture then
        self:drawTextureScaled(timedCassetteState.texture, timedCassetteState.x, timedCassetteState.y, timedCassetteState.w, timedCassetteState.h, timedCassetteState.alpha, 1.0, 1.0, 1.0)
    else
        local cassetteMediaState = self:getCassetteDisplayMediaState()
        if cassetteMediaState.visible == true and cassetteMediaState.texture then
            local cassetteRect = self:getCassetteDisplayRect()
            self:drawTextureScaled(cassetteMediaState.texture, cassetteRect.x, cassetteRect.y, cassetteRect.w, cassetteRect.h, 1.0, 1.0, 1.0, 1.0)
            local labelState = self:getCassetteLabelRenderState()
            if labelState then
                local labelRect = labelState.rect
                self:drawRect(labelRect.x, labelRect.y, labelRect.w, labelRect.h, CASSETTE_LABEL_BG.a, CASSETTE_LABEL_BG.r, CASSETTE_LABEL_BG.g, CASSETTE_LABEL_BG.b)
                local tm = getTextManager and getTextManager() or nil
                local textH = tm and tm.MeasureStringY and tm:MeasureStringY(UIFont.Small, "Ag") or 10
                local textY = labelRect.y + math.floor(((labelRect.h - textH) * 0.5) + 0.5)
                self:drawText(labelState.text, labelRect.x + CASSETTE_LABEL_TEXT_PAD_X, textY, CASSETTE_LABEL_TEXT_COLOR.r, CASSETTE_LABEL_TEXT_COLOR.g, CASSETTE_LABEL_TEXT_COLOR.b, CASSETTE_LABEL_TEXT_COLOR.a, UIFont.Small)
            end
            if UI_TEXTURES.spool then
                local leftRect = self:getCassetteSpoolRect(1)
                local rightRect = self:getCassetteSpoolRect(2)
                self:DrawTextureAngle(UI_TEXTURES.spool, leftRect.x + (leftRect.w / 2), leftRect.y + (leftRect.h / 2), tonumber(self._nmLeftSpoolAngle) or 0.0)
                self:DrawTextureAngle(UI_TEXTURES.spool, rightRect.x + (rightRect.w / 2), rightRect.y + (rightRect.h / 2), tonumber(self._nmRightSpoolAngle) or 0.0)
            end
        end
    end
end

function WalkmanWindow:render()
    if not UI_TEXTURES.close and getTexture then
        UI_TEXTURES.close = getTexture(CLOSE_TEXTURE_PATH)
    end
    if not UI_TEXTURES.stopButton and getTexture then
        UI_TEXTURES.stopButton = getTexture(STOP_BUTTON_TEXTURE_PATH)
    end
    if not UI_TEXTURES.loopIconNone and getTexture then
        UI_TEXTURES.loopIconNone = getTexture(LOOP_ICON_NONE_TEXTURE_PATH)
    end
    if not UI_TEXTURES.loopIconSong and getTexture then
        UI_TEXTURES.loopIconSong = getTexture(LOOP_ICON_SONG_TEXTURE_PATH)
    end
    if not UI_TEXTURES.loopIconAlbum and getTexture then
        UI_TEXTURES.loopIconAlbum = getTexture(LOOP_ICON_ALBUM_TEXTURE_PATH)
    end
    ISPanel.render(self)
    local loopIconTexture = self:getLoopIconTexture()
    if loopIconTexture and self:shouldShowLoopIcon() then
        local loopIconRect = self:getLoopIconRect()
        self:drawTextureScaled(loopIconTexture, loopIconRect.x, loopIconRect.y, loopIconRect.w, loopIconRect.h, LOOP_ICON_ALPHA, 1.0, 1.0, 1.0)
    end
    if self.isPlayButtonDown == true and UI_TEXTURES.stopButton then
        local stopRect = self:getStopButtonRect()
        self:drawTextureScaled(UI_TEXTURES.stopButton, stopRect.x, stopRect.y, stopRect.w, stopRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if UI_TEXTURES.close then
        local closeRect = self:getCloseRect()
        self:drawTextureScaled(UI_TEXTURES.close, closeRect.x, closeRect.y, closeRect.w, closeRect.h, 1.0, 1.0, 1.0, 1.0)
    end
    if self:shouldShowVolumeLabel() then
        local labelRect = self:getVolumeLabelRect()
        self:drawText(self:getVolumeLabelText(), labelRect.x, labelRect.y, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    end
    local lidEdgeState = self:getLidEdgeRenderState()
    if lidEdgeState.texture and lidEdgeState.visible == true then
        self:drawTextureScaled(lidEdgeState.texture, lidEdgeState.x, lidEdgeState.y, lidEdgeState.w, lidEdgeState.h, 1.0, 1.0, 1.0, 1.0)
    end
    if self:shouldShowLidIngressZone() then
        local ingressRect = self:getLidIngressZoneRect()
        self:drawRectBorder(ingressRect.x, ingressRect.y, ingressRect.w, ingressRect.h, LID_INGRESS_BORDER.a, LID_INGRESS_BORDER.r, LID_INGRESS_BORDER.g, LID_INGRESS_BORDER.b)
    end
    local lidState = self:getLidRenderState()
    if lidState.texture then
        self:drawTextureScaled(lidState.texture, lidState.x, lidState.y, lidState.w, lidState.h, 1.0, 1.0, 1.0, 1.0)
    end
end

