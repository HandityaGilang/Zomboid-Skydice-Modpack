require "ISUI/ISUIElement"
require "ISUI/ISButton"
pcall(require, "MHP_Sandbox")

TwisTonFire_MHP = TwisTonFire_MHP or {}
local MHP = TwisTonFire_MHP

MHP.MiniHealthPanel = MHP.MiniHealthPanel or ISPanel:derive("TTF_MHP_MiniHealthPanel")
MHP.ISMiniHealth = MHP.MiniHealthPanel

local MHPPanel = MHP.MiniHealthPanel


local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local MHP_CONFIG_FILE = "MiniHealthPlus_conf.ini"

local MHP_BODY_PART_TEXTURE_KEYS = {
	[0] = "left_hand",
	[1] = "right_hand",
	[2] = "left_forearm",
	[3] = "right_forearm",
	[4] = "left_upper_arm",
	[5] = "right_upper_arm",
	[6] = "upper_torso",
	[7] = "lower_torso",
	[8] = "head",
	[9] = "neck",
	[10] = "groin",
	[11] = "left_thigh",
	[12] = "right_thigh",
	[13] = "left_shin",
	[14] = "right_shin",
	[15] = "left_foot",
	[16] = "right_foot",
}

local COLORS = {
	none = Color.new(0,0,0,0),
	untreated = Color.new(1,0,0,1),
	bandaged = Color.new(0.78,0.69,0.6,1),
	healed = Color.new(0.53,0.84,1,1),
	stitchReady = Color.new(0.80,0.64,1,1),
	dirty = Color.new(1,0.57,0.11,1),

	strain = {r=1, g=0.57, b=0.11}
}

local MHP_BLINK_SPEED_PRESETS = { 6, 8, 10, 14, 18 }

local MHP_BLINK_SPEED_TEXT_KEYS = {
	[6] = "UI_MHP_AnimationSpeed_VeryFast",
	[8] = "UI_MHP_AnimationSpeed_Fast",
	[10] = "UI_MHP_AnimationSpeed_Normal",
	[14] = "UI_MHP_AnimationSpeed_Slow",
	[18] = "UI_MHP_AnimationSpeed_VerySlow",
}

local function MHP_HasHiddenWoundState(bodyPart)
	return bodyPart:getScratchTime() > 0
		or bodyPart:getCutTime() > 0
		or bodyPart:getBiteTime() > 0
		or bodyPart:getBleedingTime() > 0
		or bodyPart:getDeepWoundTime() > 0
		or bodyPart:getBurnTime() > 0
		or bodyPart:getFractureTime() > 0
		or bodyPart:isInfectedWound()
		or bodyPart:haveGlass()
		or bodyPart:haveBullet()
end

local function MHP_HasUnderlyingWound(bodyPart)
	return bodyPart:HasInjury()
		or bodyPart:getDeepWoundTime() > 0
		or bodyPart:haveGlass()
		or bodyPart:haveBullet()
		or bodyPart:isInfectedWound()
		or bodyPart:getFractureTime() > 0
end

local function MHP_CanInspectStitches(bodyPart)
	if not bodyPart:stitched() then
		return false
	end

	-- Fresh stitches should not get the special color yet.
	if bodyPart:getStitchTime() <= 40 then
		return false
	end

	-- Never suggest stitch inspection in obviously bad states.
	if bodyPart:isInfectedWound()
	or bodyPart:haveGlass()
	or bodyPart:haveBullet() then
		return false
	end

	return true
end

local function MHP_HasSafeRemovableTreatment(bodyPart)
	local hasBandage = bodyPart:bandaged()
	local hasSplint = bodyPart:getSplintFactor() > 0

	-- Generic safe-remove blue is only for bandages / splints.
	if not hasBandage and not hasSplint then
		return false
	end

	-- If stitches are involved, do not reuse the generic blue state.
	if bodyPart:stitched() or bodyPart:getStitchTime() > 0 then
		return false
	end

	if hasBandage and bodyPart:getBandageLife() <= 0 then
		return false
	end

	if hasSplint and bodyPart:getFractureTime() > 0 then
		return false
	end

	return not MHP_HasUnderlyingWound(bodyPart)
end

local function MHP_BodyPartNeedsTreatment(bodyPart, includeStitchInspect)
	if not bodyPart then
		return false
	end

	local hasBandage = bodyPart:bandaged()
	local hasSplint = bodyPart:getSplintFactor() > 0
	local hasStitch = bodyPart:stitched()

	local hasDeepWound =
		bodyPart:getDeepWoundTime() > 0
		or bodyPart:deepWounded()

	local hasForeignObject =
		bodyPart:haveGlass()
		or bodyPart:haveBullet()

	local hasBasicWound =
		bodyPart:scratched()
		or bodyPart:getScratchTime() > 0
		or bodyPart:isCut()
		or bodyPart:getCutTime() > 0
		or bodyPart:bitten()
		or bodyPart:getBiteTime() > 0
		or bodyPart:bleeding()
		or bodyPart:getBleedingTime() > 0
		or bodyPart:isBurnt()
		or bodyPart:getBurnTime() > 0

	if hasBandage and bodyPart:getBandageLife() <= 0 then
		return true
	end

	if hasForeignObject then
		return true
	end

	if hasDeepWound and not hasStitch then
		return true
	end

	if hasStitch and not hasBandage then
		return true
	end

	if bodyPart:getFractureTime() > 0 and not hasSplint then
		return true
	end

	if bodyPart:isInfectedWound() and not hasBandage then
		return true
	end

	if hasBasicWound and not hasBandage then
		return true
	end

	if includeStitchInspect ~= false and MHP_CanInspectStitches(bodyPart) then
		return true
	end

	return false
end

function MHPPanel.playerNeedsTreatment(playerObj)
	if not playerObj then
		return false
	end

	if playerObj.isDead and playerObj:isDead() then
		return false
	end

	local bodyDamage = playerObj:getBodyDamage()
	if not bodyDamage then
		return false
	end

	local bodyParts = bodyDamage:getBodyParts()
	if not bodyParts then
		return false
	end

	for i = 0, 16 do
		if MHP_BodyPartNeedsTreatment(bodyParts:get(i), false) then
			return true
		end
	end

	return false
end

local function MHP_BodyPartNeedsDisplayAttention(bodyPart, includeStrains, showSafeRemoveIndicator, showStitchInspectIndicator)
	if not bodyPart then
		return false
	end

	if MHP_BodyPartNeedsTreatment(bodyPart, false) then
		return true
	end

	if showSafeRemoveIndicator == true and MHP_HasSafeRemovableTreatment(bodyPart) then
		return true
	end

	if showStitchInspectIndicator == true and MHP_CanInspectStitches(bodyPart) then
		return true
	end

	-- Muscle strain display attention is threshold-based and handled by the panel instance.
	-- Any stiffness > 0 must not count as permanent attention, otherwise BCI idle gets hidden too early.

	return false
end

function MHPPanel.playerNeedsDisplayAttention(playerObj, includeStrains)
	if not playerObj then
		return false
	end

	if playerObj.isDead and playerObj:isDead() then
		return false
	end

	local bodyDamage = playerObj:getBodyDamage()
	if not bodyDamage then
		return false
	end

	local bodyParts = bodyDamage:getBodyParts()
	if not bodyParts then
		return false
	end

	local showSafeRemoveIndicator = true
	if type(MHP_SB_IsSafeRemoveIndicatorEnabled) == "function" then
		showSafeRemoveIndicator = MHP_SB_IsSafeRemoveIndicatorEnabled() == true
	end

	local showStitchInspectIndicator = true
	if type(MHP_SB_IsStitchInspectIndicatorEnabled) == "function" then
		showStitchInspectIndicator = MHP_SB_IsStitchInspectIndicatorEnabled() == true
	end

	for i = 0, 16 do
		if MHP_BodyPartNeedsDisplayAttention(bodyParts:get(i), includeStrains == true, showSafeRemoveIndicator, showStitchInspectIndicator) then
			return true
		end
	end

	return false
end

local function MHP_IsBCIInfoTabView(viewName)
	if not viewName then
		return false
	end

	if xpSystemText and xpSystemText.info and viewName == xpSystemText.info then
		return true
	end

	return tostring(viewName):lower() == "info"
end

local function MHP_IsInUIManager(ui)
	if not ui or not UIManager or not UIManager.getUI then
		return false
	end

	local javaObj = ui.javaObject or ui.javaObj or ui
	if not javaObj then
		return false
	end

	local uiList = UIManager.getUI()
	if not uiList then
		return false
	end

	for i = 0, uiList:size() - 1 do
		local entry = uiList:get(i)
		if entry == javaObj or entry == ui then
			return true
		end
	end

	return false
end

local function MHP_AddToUIManagerOnce(ui)
	if not ui then
		return
	end

	if not MHP_IsInUIManager(ui) and ui.addToUIManager then
		ui:addToUIManager()
	end

	ui.removed = false
end

local function MHP_ApplyMiniHealthZOrder(ui, shouldBeOnTop)
	if not ui then
		return
	end

	shouldBeOnTop = shouldBeOnTop == true

	if ui.setAlwaysOnTop then
		ui:setAlwaysOnTop(shouldBeOnTop)
	end

	if shouldBeOnTop and ui.bringToTop then
		ui:bringToTop()
	end
end

local function MHP_GetOwnerAlwaysOnTop(ownerPanel)
	return ownerPanel and ownerPanel.alwaysOnTopUI == true
end

local function MHP_ApplyBCIPopupZOrder(popup, ownerPanel)
	local shouldBeOnTop = MHP_GetOwnerAlwaysOnTop(ownerPanel or (popup and popup._MHP_MiniHealthOwnerPanel))
	MHP_ApplyMiniHealthZOrder(popup, shouldBeOnTop)
end

local function MHP_SetBCIKeepOpenWithCharacterInfo(popup, keepOpen)
    if not popup then
        return
    end

    if type(popup.setKeepOpenWithCharacterInfo) == "function" then
        popup:setKeepOpenWithCharacterInfo(keepOpen == true)
        return
    end

    popup._TTF_BCI_KeepOpenWithCharacterInfo = keepOpen == true
end

local function MHP_GetBCIKeepOpenWithCharacterInfo(popup)
    if not popup then
        return false
    end

    if type(popup.isKeepOpenWithCharacterInfo) == "function" then
        return popup:isKeepOpenWithCharacterInfo() == true
    end

    return popup._TTF_BCI_KeepOpenWithCharacterInfo == true
end

local function MHP_IsMiniHealthOwnedBCIPopup(popup)
    if not popup then
        return false
    end

    local ownerPanel = popup._MHP_MiniHealthOwnerPanel
    if not ownerPanel then
        return false
    end

    return popup._MHP_OpenedAsIdleAvatar == true
        and MHP_GetBCIKeepOpenWithCharacterInfo(popup) == true
        and ownerPanel.enabled == true
        and ownerPanel.showBCIAvatarOnIdle == true
        and type(TwisTonFire_MHP_IsBetterCharacterInfoActive) == "function"
        and TwisTonFire_MHP_IsBetterCharacterInfoActive() == true
end

local function MHP_IsMiniHealthTaggedBCIPopup(popup)
	if not popup then
		return false
	end

	return popup._MHP_OpenedAsIdleAvatar == true
		or popup._MHP_MiniHealthOwnerPanel ~= nil
		or popup._MHP_SettingsButton ~= nil
end

local function MHP_GetBCIPopupPlayerNum(popup)
	if not popup then
		return 0
	end

	return tonumber(popup.playerNum or popup.playerIndex or 0) or 0
end

local function MHP_AddTaggedBCIPopup(result, seen, popup, playerIndex)
	if not MHP_IsMiniHealthTaggedBCIPopup(popup) then
		return
	end

	if playerIndex ~= nil and MHP_GetBCIPopupPlayerNum(popup) ~= playerIndex then
		return
	end

	if seen[popup] then
		return
	end

	seen[popup] = true
	table.insert(result, popup)
end

local function MHP_GetTaggedBCIPopups(playerIndex)
	local result = {}
	local seen = {}

	local api = TTF_BCI_FloatingAvatarUI
	if api and api._instances then
		if playerIndex ~= nil then
			MHP_AddTaggedBCIPopup(result, seen, api._instances[playerIndex], playerIndex)
		else
			for _, popup in pairs(api._instances) do
				MHP_AddTaggedBCIPopup(result, seen, popup, nil)
			end
		end
	end

	local uiList = UIManager and UIManager.getUI and UIManager.getUI() or nil
	if uiList then
		for i = uiList:size() - 1, 0, -1 do
			MHP_AddTaggedBCIPopup(result, seen, uiList:get(i), playerIndex)
		end
	end

	return result
end

local function MHP_ForceRemoveBCIPopup(popup)
	if not popup then
		return
	end

	local playerNum = MHP_GetBCIPopupPlayerNum(popup)

	if popup._MHP_SettingsButton then
		local button = popup._MHP_SettingsButton

		pcall(function()
			button:setVisible(false)
		end)

		if popup.removeChild then
			pcall(function()
				popup:removeChild(button)
			end)
		end

		popup._MHP_SettingsButton = nil
	end

	if popup.setCapture then
		pcall(function()
			popup:setCapture(false)
		end)
	end

	if popup._resizingMode and popup._endResize then
		pcall(function()
			popup:_endResize()
		end)
	end

	if popup._draggingHeader and popup._endDragWindow then
		pcall(function()
			popup:_endDragWindow()
		end)
	end

	local originalClosePopup = popup._MHP_OriginalClosePopup

	popup._MHP_OpenedAsIdleAvatar = false
	MHP_SetBCIKeepOpenWithCharacterInfo(popup, false)
	popup._MHP_MiniHealthOwnerPanel = nil

	local closedByBCI = false

	if type(originalClosePopup) == "function" then
		local ok, err = pcall(originalClosePopup, popup)

		if ok then
			closedByBCI = true
		else
			print("[Mini Health Plus] BCI original closePopup failed: " .. tostring(err))
		end

	elseif type(popup.closePopup) == "function" then
		local ok, err = pcall(popup.closePopup, popup)

		if ok then
			closedByBCI = true
		else
			print("[Mini Health Plus] BCI closePopup failed: " .. tostring(err))
		end
	end

	if not closedByBCI then
		if popup.setAlwaysOnTop then
			popup:setAlwaysOnTop(false)
		end

		if popup.setVisible then
			popup:setVisible(false)
		end

		if popup.removeFromUIManager then
			popup:removeFromUIManager()
		end
	end

	if TTF_BCI_FloatingAvatarUI
	and TTF_BCI_FloatingAvatarUI._instances
	and TTF_BCI_FloatingAvatarUI._instances[playerNum] == popup then
		TTF_BCI_FloatingAvatarUI._instances[playerNum] = nil
	end
end

local function MHP_EnforceSingleBCIIdleAvatar(playerIndex, keepPopup)
	playerIndex = playerIndex or 0

	local popups = MHP_GetTaggedBCIPopups(playerIndex)

	for _, popup in ipairs(popups) do
		if popup ~= keepPopup then
			MHP_ForceRemoveBCIPopup(popup)
		end
	end

	if keepPopup and TTF_BCI_FloatingAvatarUI and TTF_BCI_FloatingAvatarUI._instances then
		TTF_BCI_FloatingAvatarUI._instances[playerIndex] = keepPopup
	end
end

local function MHP_IsCharacterInfoInfoTabOpen(playerNum)
	local info = getPlayerInfoPanel and getPlayerInfoPanel(playerNum or 0) or nil
	if not info or not info.getIsVisible or not info:getIsVisible() or not info.panel then
		return false
	end

	local activeView = info.panel.getActiveView and info.panel:getActiveView() or nil
	local infoView = nil

	if info.panel.getView and xpSystemText and xpSystemText.info then
		infoView = info.panel:getView(xpSystemText.info)
	end

	return activeView ~= nil and infoView ~= nil and activeView == infoView
end

local function MHP_RestoreBCIPopupAfterCharacterInfoToggle(popup)
	if not popup then
		return
	end

	if popup.setVisible then
		popup:setVisible(true)
	end

	MHP_AddToUIManagerOnce(popup)
	MHP_ApplyBCIPopupZOrder(popup, popup._MHP_MiniHealthOwnerPanel)
end

local function MHP_PatchBCICharacterInfoCloseGuard()
	if not TTF_BCI_FloatingAvatarUI then
		return
	end

	if not ISCharacterInfoWindow then
		return
	end

	if ISCharacterInfoWindow._MHP_BCIKeepAvatarPatch then
		return
	end

	local originalToggleView = ISCharacterInfoWindow.toggleView
	if type(originalToggleView) ~= "function" then
		return
	end

	function ISCharacterInfoWindow:toggleView(viewName)
		local playerNum = self.playerNum or 0
		local popup = TTF_BCI_FloatingAvatarUI
			and TTF_BCI_FloatingAvatarUI._instances
			and TTF_BCI_FloatingAvatarUI._instances[playerNum]
			or nil

		local keepAvatarOpen = MHP_IsBCIInfoTabView(viewName)
			and MHP_IsMiniHealthOwnedBCIPopup(popup)

		if keepAvatarOpen then
			_G.__MHP_BCI_SuppressCharacterInfoClose = true

			local ok, result = pcall(originalToggleView, self, viewName)

			_G.__MHP_BCI_SuppressCharacterInfoClose = false

			MHP_RestoreBCIPopupAfterCharacterInfoToggle(popup)

			if not ok then
				print("[Mini Health Plus] BCI Character Info toggle guard failed: " .. tostring(result))
				return
			end

			return result
		end

		return originalToggleView(self, viewName)
	end

	ISCharacterInfoWindow._MHP_BCIKeepAvatarPatch = true
end

local function MHP_GetBCIFloatingAvatarAPI()
	if type(TwisTonFire_MHP_IsBetterCharacterInfoActive) ~= "function"
	or not TwisTonFire_MHP_IsBetterCharacterInfoActive() then
		return nil
	end

	if not TTF_BCI_FloatingAvatarUI then
		pcall(require, "TTF_BCI_FloatingAvatarUI")
	end

	if TTF_BCI_FloatingAvatarUI
	and TTF_BCI_FloatingAvatarUI.openForPlayer
	and TTF_BCI_FloatingAvatarUI.destroyForPlayer then
		MHP_PatchBCICharacterInfoCloseGuard()
		return TTF_BCI_FloatingAvatarUI
	end

	return nil
end

local MHP_BCI_SETTINGS_BUTTON_SIZE = 24
local MHP_BCI_SETTINGS_BUTTON_OFFSET = 5

local function MHP_UpdateBCISettingsButtonVisibility(popup)
	if not popup or not popup._MHP_SettingsButton then
		return
	end

	local button = popup._MHP_SettingsButton
	local hovering = false

	if popup.isMouseOver and popup:isMouseOver() then
		hovering = true
	end

	if not hovering and button.isMouseOver and button:isMouseOver() then
		hovering = true
	end

	if not hovering and popup.getMouseX and popup.getMouseY then
		local mx = popup:getMouseX()
		local my = popup:getMouseY()
		local w = popup.getWidth and popup:getWidth() or popup.width or 0
		local h = popup.getHeight and popup:getHeight() or popup.height or 0

		hovering = mx >= 0 and my >= 0 and mx <= w and my <= h
	end

	button:setVisible(hovering == true)

	if hovering and button.bringToTop then
		button:bringToTop()
	end
end

local function MHP_AttachBCISettingsButton(popup, ownerPanel)
	if not popup or not ownerPanel then
		return
	end

	local buttonSize = MHP_BCI_SETTINGS_BUTTON_SIZE
	local buttonOffset = MHP_BCI_SETTINGS_BUTTON_OFFSET

	if popup._MHP_SettingsButton then
		popup._MHP_SettingsButton:setX(buttonOffset)
		popup._MHP_SettingsButton:setY(buttonOffset)
		popup._MHP_SettingsButton:setWidth(buttonSize)
		popup._MHP_SettingsButton:setHeight(buttonSize)
		popup._MHP_SettingsButton:setVisible(false)

		MHP_UpdateBCISettingsButtonVisibility(popup)
		return
	end

	local button = ISButton:new(buttonOffset, buttonOffset, buttonSize, buttonSize, "", ownerPanel, function(target)
		if target and target.openSettingsFromBCIAvatar then
			target:openSettingsFromBCIAvatar(popup)
		end
	end)

	button:initialise()
	button:instantiate()
	button.borderColor = {r=0.8, g=0.8, b=0.8, a=0.55}
	button.backgroundColor = {r=0, g=0, b=0, a=0.35}
	button.backgroundColorMouseOver = {r=0.2, g=0.2, b=0.2, a=0.75}
	button:setImage(getTexture("media/ui/inventoryPanes/Button_Gear.png"))
	button:setVisible(false)

	popup:addChild(button)

	popup._MHP_SettingsButton = button
	MHP_UpdateBCISettingsButtonVisibility(popup)
end

local function MHP_PatchBCIPopupForMiniHealth(popup, ownerPanel)
	if not popup or not ownerPanel then
		return
	end

	popup._MHP_OpenedAsIdleAvatar = true
	MHP_SetBCIKeepOpenWithCharacterInfo(popup, true)
	popup._MHP_MiniHealthOwnerPanel = ownerPanel
	MHP_ApplyBCIPopupZOrder(popup, ownerPanel)

	if popup._MHP_MiniHealthPatchApplied then
		return
	end

	local originalClosePopup = popup.closePopup
	if type(originalClosePopup) == "function" then
		popup._MHP_OriginalClosePopup = originalClosePopup

		function popup:closePopup(...)
			if MHP_IsMiniHealthOwnedBCIPopup(self) then
				local playerNum = self.playerNum or 0

				if _G.__MHP_BCI_SuppressCharacterInfoClose == true
				or MHP_IsCharacterInfoInfoTabOpen(playerNum) then
					MHP_RestoreBCIPopupAfterCharacterInfoToggle(self)
					return
				end
			end

			return originalClosePopup(self, ...)
		end
	end

		local originalPrerender = popup.prerender
	if type(originalPrerender) == "function" then
		popup._MHP_OriginalPrerender = originalPrerender

		function popup:prerender(...)
			MHP_UpdateBCISettingsButtonVisibility(self)

			if MHP_IsMiniHealthOwnedBCIPopup(self)
			and MHP_IsCharacterInfoInfoTabOpen(self.playerNum or 0)
			and getPlayerInfoPanel then
				local originalGetPlayerInfoPanel = getPlayerInfoPanel
				local playerNum = self.playerNum or 0

				getPlayerInfoPanel = function(requestedPlayerNum)
					if (requestedPlayerNum or 0) == playerNum then
						return nil
					end

					return originalGetPlayerInfoPanel(requestedPlayerNum)
				end

				local ok, result = pcall(originalPrerender, self, ...)

				getPlayerInfoPanel = originalGetPlayerInfoPanel

				MHP_UpdateBCISettingsButtonVisibility(self)

				if not ok then
					print("[Mini Health Plus] BCI Avatar prerender guard failed: " .. tostring(result))
					return
				end

				return result
			end

			local result = originalPrerender(self, ...)
			MHP_UpdateBCISettingsButtonVisibility(self)
			return result
		end
	end

	local originalSwitchBackToCharacterInfo = popup.switchBackToCharacterInfo
	if type(originalSwitchBackToCharacterInfo) == "function" then
		popup._MHP_OriginalSwitchBackToCharacterInfo = originalSwitchBackToCharacterInfo

		function popup:switchBackToCharacterInfo(...)
			if MHP_IsMiniHealthOwnedBCIPopup(self) then
				local playerNum = self.playerNum or 0
				local info = getPlayerInfoPanel and getPlayerInfoPanel(playerNum) or nil

				if info and info.toggleView then
					_G.__MHP_BCI_SuppressCharacterInfoClose = true

					local ok, err = pcall(function()
						info:toggleView(xpSystemText.info)
					end)

					_G.__MHP_BCI_SuppressCharacterInfoClose = false

					if not ok then
						print("[Mini Health Plus] BCI Avatar right-click Character Info open failed: " .. tostring(err))
					end
				end

				MHP_RestoreBCIPopupAfterCharacterInfoToggle(self)
				return
			end

			return originalSwitchBackToCharacterInfo(self, ...)
		end
	end

	popup._MHP_MiniHealthPatchApplied = true
end

local function MHP_OpenBCIIdleAvatar(
    playerIndex,
    playerObj,
    ownerPanel
)
    local api = MHP_GetBCIFloatingAvatarAPI()

    if not api then
        return nil
    end

    playerIndex =
        playerIndex
        or (
            playerObj
            and playerObj.getPlayerNum
            and playerObj:getPlayerNum()
        )
        or 0

    playerObj =
        playerObj
        or getSpecificPlayer(playerIndex)

    if not playerObj then
        return nil
    end

    if playerObj.isDead and playerObj:isDead() then
        MHP_EnforceSingleBCIIdleAvatar(
            playerIndex,
            nil
        )

        return nil
    end

    local existing =
        api._instances
        and api._instances[playerIndex]
        or nil

    if not existing then
        local taggedPopups =
            MHP_GetTaggedBCIPopups(playerIndex)

        existing = taggedPopups[1]

        if existing and api._instances then
            api._instances[playerIndex] = existing
        end
    end

    if existing then
        local characterChanged =
            existing.char ~= playerObj

        existing.char = playerObj

        if characterChanged
        and existing.refreshAvatarModelFromCharacter then
            existing:refreshAvatarModelFromCharacter()
        end

        MHP_PatchBCIPopupForMiniHealth(
            existing,
            ownerPanel
        )

        MHP_AddToUIManagerOnce(existing)
        existing:setVisible(true)

        MHP_AttachBCISettingsButton(
            existing,
            ownerPanel
        )

        MHP_ApplyBCIPopupZOrder(
            existing,
            ownerPanel
        )

        MHP_EnforceSingleBCIIdleAvatar(
            playerIndex,
            existing
        )

        return existing
    end

    MHP_EnforceSingleBCIIdleAvatar(
        playerIndex,
        nil
    )

    local info =
        getPlayerInfoPanel
        and getPlayerInfoPanel(playerIndex)
        or nil

    local originalInfoClose =
        info
        and info.close
        or nil

    if info
    and type(originalInfoClose) == "function" then
        info.close = function()
        end
    end

    local popup =
        api.openForPlayer(
            playerIndex,
            playerObj,
            {
                persistActive = false,
                suppressCharacterInfoClose = true,
                keepOpenWithCharacterInfo = true,
            }
        )

    if info
    and type(originalInfoClose) == "function" then
        info.close = originalInfoClose
    end

    if popup then
        MHP_PatchBCIPopupForMiniHealth(
            popup,
            ownerPanel
        )

        MHP_AttachBCISettingsButton(
            popup,
            ownerPanel
        )

        MHP_ApplyBCIPopupZOrder(
            popup,
            ownerPanel
        )

        MHP_EnforceSingleBCIIdleAvatar(
            playerIndex,
            popup
        )
    else
        MHP_EnforceSingleBCIIdleAvatar(
            playerIndex,
            nil
        )
    end

    return popup
end

local function MHP_CloseBCIIdleAvatar(playerIndex, forceCloseAny)
	local api = MHP_GetBCIFloatingAvatarAPI()
	if not api then
		return
	end

	playerIndex = playerIndex or 0

	local taggedPopups = MHP_GetTaggedBCIPopups(playerIndex)
	for _, popup in ipairs(taggedPopups) do
		MHP_ForceRemoveBCIPopup(popup)
	end

	local tracked = api._instances and api._instances[playerIndex] or nil
	if tracked and (forceCloseAny == true or MHP_IsMiniHealthTaggedBCIPopup(tracked)) then
		MHP_ForceRemoveBCIPopup(tracked)
	end

	if api._instances then
		local trackedAfterClose = api._instances[playerIndex]

		if trackedAfterClose
		and (forceCloseAny == true or MHP_IsMiniHealthTaggedBCIPopup(trackedAfterClose)) then
			api._instances[playerIndex] = nil
		end
	end
end

local function MHP_StrainsThresholdReached(strain, stiffness)
	if not strain then
		return false
	end

	stiffness = tonumber(stiffness) or 0

	return stiffness >= (strain.nextStage or 5)
		or stiffness < (strain.prevStage or -1)
end

local function MHP_UpdateStrainThresholdState(strain, stiffness)
	if not strain then
		return
	end

	stiffness = tonumber(stiffness) or 0

	if stiffness >= 15 then
		strain.nextStage = 100000
		strain.prevStage = 15
	elseif stiffness >= 10 then
		strain.nextStage = 15
		strain.prevStage = 10
	elseif stiffness >= 5 then
		strain.nextStage = 10
		strain.prevStage = 5
	else
		strain.nextStage = 5
		strain.prevStage = -1
	end
end

local MHP_BCI_PANEL_FADE_FRAMES = 24

-- How long Mini Health Plus stays active after muscle strain reached 0 again.
-- 240 frames are roughly a few seconds and prevent fast BCI avatar flickering.
local MHP_STRAIN_IDLE_RETURN_FRAMES = 240
local MHP_STRAIN_BCI_ACTIVE_THRESHOLD = 0.10

local MHP_FRAME_MS = 1000 / 60

local function MHP_GetNowMS()
	if type(getTimestampMs) == "function" then
		return getTimestampMs()
	end

	if type(getTimeInMillis) == "function" then
		return getTimeInMillis()
	end

	return (getTimestamp() or 0) * 1000
end

local function MHP_FramesToMS(frames)
	return math.max(0, math.floor(((tonumber(frames) or 0) * MHP_FRAME_MS) + 0.5))
end

local function MHP_SetTimedFlag(panel, fieldName, frames)
	if not panel then
		return
	end

	panel[fieldName] = MHP_GetNowMS() + MHP_FramesToMS(frames)
end

local function MHP_ExtendTimedFlag(panel, fieldName, frames)
	if not panel then
		return
	end

	local untilMS = MHP_GetNowMS() + MHP_FramesToMS(frames)
	panel[fieldName] = math.max(tonumber(panel[fieldName]) or 0, untilMS)
end

local function MHP_IsTimedFlagActive(panel, fieldName)
	if not panel then
		return false
	end

	local untilMS = tonumber(panel[fieldName]) or 0
	if untilMS <= 0 then
		return false
	end

	if untilMS > MHP_GetNowMS() then
		return true
	end

	panel[fieldName] = 0
	return false
end

local function MHP_ClearStrainTimers(panel)
	if not panel then
		return
	end

	panel.strainAttentionTimer = 0
	panel.strainIdleReturnTimer = 0
	panel.strainAttentionUntilMS = 0
	panel.strainIdleReturnUntilMS = 0
end

local function MHP_IsStrainRelevantForBCI(stiffness)
	stiffness = tonumber(stiffness) or 0
	return stiffness >= MHP_STRAIN_BCI_ACTIVE_THRESHOLD
end

local function MHP_GetStrainAttentionDuration(stiffness)
	stiffness = tonumber(stiffness) or 0

	if stiffness >= 15 then
		return 420
	elseif stiffness >= 10 then
		return 300
	elseif stiffness >= 5 then
		return 210
	end

	return 150
end

local function MHP_StrainsShouldStayVisible(stiffness)
	stiffness = tonumber(stiffness) or 0
	return stiffness >= 10
end

local function MHP_SoftWakePanel(panel, minimumAlpha)
	if not panel then
		return
	end

	minimumAlpha = minimumAlpha or 0.45
	panel.alpha = math.max(panel.alpha or 0, minimumAlpha)
end

local function MHP_UpdatePanelHideTimer(panel)
	if not panel then
		return
	end

	local now = MHP_GetNowMS()
	local last = tonumber(panel.hideTimerLastMS) or now

	panel.hideTimerLastMS = now

	if panel.alwaysShow == true
	or panel.forceVisibleForBCIAttention == true
	or panel.isHover == true
	or (panel.settingsPanel and panel.settingsPanel:getOpen()) then
		panel.hideTimerFrameCarry = 0
		return
	end

	local hideTimer = tonumber(panel.hideTimer) or 0
	if hideTimer <= 0 then
		panel.hideTimer = 0
		panel.hideTimerFrameCarry = 0
		return
	end

	local elapsedMS = math.max(0, now - last)
	if elapsedMS <= 0 then
		return
	end

	local frames = (tonumber(panel.hideTimerFrameCarry) or 0) + (elapsedMS / MHP_FRAME_MS)
	local elapsedFrames = math.floor(frames)

	panel.hideTimerFrameCarry = frames - elapsedFrames

	if elapsedFrames > 0 then
		panel.hideTimer = math.max(hideTimer - elapsedFrames, 0)
	end
end

local function MHP_NormalizeBlinkStyle(style)
	return "pulse"
end

local function MHP_ClampBlinkSpeed(speed)
	speed = math.floor((tonumber(speed) or 14) + 0.5)

	local best = MHP_BLINK_SPEED_PRESETS[1]
	local bestDelta = math.abs(speed - best)

	for i = 2, #MHP_BLINK_SPEED_PRESETS do
		local candidate = MHP_BLINK_SPEED_PRESETS[i]
		local delta = math.abs(speed - candidate)

		if delta < bestDelta then
			best = candidate
			bestDelta = delta
		end
	end

	return best
end

function MHPPanel.getBlinkStyleDisplayTextFor(style)
	style = MHP_NormalizeBlinkStyle(style)

	if style == "pulse" then
		return getText("UI_MHP_AnimationStyle_Pulse")
	end

	return getText("UI_MHP_AnimationStyle_Blink")
end

function MHPPanel.getBlinkSpeedDisplayTextFor(speed)
	speed = MHP_ClampBlinkSpeed(speed)
	return getText(MHP_BLINK_SPEED_TEXT_KEYS[speed] or "UI_MHP_AnimationSpeed_Normal")
end

function MHPPanel:getBlinkStyleDisplayText()
	return MHPPanel.getBlinkStyleDisplayTextFor(self.blinkStyle)
end

function MHPPanel:getBlinkSpeedDisplayText()
	return MHPPanel.getBlinkSpeedDisplayTextFor(self.blinkSpeed)
end

function MHPPanel:setBlinkStyle(style)
	self.blinkStyle = MHP_NormalizeBlinkStyle(style)
end

function MHPPanel:setBlinkSpeed(speed)
	self.blinkSpeed = MHP_ClampBlinkSpeed(speed)
end

function MHPPanel:getBlinkOverlayAlpha()
	local speed = MHP_ClampBlinkSpeed(self.blinkSpeed)
	local cycle = self.blinkTime / (speed * 1.9)

	-- Base pulse from 0..1..0
	local baseWave = (math.sin(cycle - (math.pi / 2)) + 1) * 0.5

	-- Shape the curve:
	-- slow gentle build-up, stronger finish near the peak
	local slowBuild = baseWave * baseWave
	local peakBoost = slowBuild * slowBuild * slowBuild
	local shaped = (slowBuild * 0.72) + (peakBoost * 0.28)

	-- Keep a little visibility even at the low point
	return 0.18 + (0.82 * shaped)
end

function MHPPanel:new(playerIndex,player,enabled)
	local bw = 120
	local bh = 271

	local mhpHandle = {}
	mhpHandle = ISPanel:new(25, getCore():getScreenHeight() - bh - 25, bw, bh)
	setmetatable(mhpHandle, self)
	self.__index = self

	mhpHandle.playerIndex = playerIndex
	mhpHandle.player = player
	mhpHandle.player_isDead = false
	mhpHandle.isFemale = player:isFemale()

	mhpHandle.blinkStyle = "pulse"
	mhpHandle.blinkSpeed = 14

	mhpHandle.alpha = 1.0
	mhpHandle.bgAlpha = 0
	mhpHandle.blinkTime = 0
	mhpHandle.blinkAlpha = 0
	mhpHandle.isHover = false
	mhpHandle.baseWidth = bw
	mhpHandle.baseHeight = bh

	mhpHandle.canHide = false
	mhpHandle.hideTimer = 100
	mhpHandle.hideTimerLastMS = MHP_GetNowMS()
	mhpHandle.hideTimerFrameCarry = 0
	mhpHandle.health = 0
	mhpHandle.previousHealth = nil
	mhpHandle.healthColor = {r=1,g=1,b=1,a=1}
	mhpHandle.infopanel = getPlayerInfoPanel(player:getPlayerNum())

	mhpHandle.moveWithMouse = true

	mhpHandle.dragging = false
	mhpHandle.dragDistance = 0
	mhpHandle.dragThreshold = 4
	mhpHandle.clickCancelThreshold = 2
	mhpHandle.mouseDownScreenX = 0
	mhpHandle.mouseDownScreenY = 0
	mhpHandle.mouseDownPanelX = 0
	mhpHandle.mouseDownPanelY = 0
	mhpHandle.mouseDownLocalX = 0
	mhpHandle.mouseDownLocalY = 0
	mhpHandle.suppressClickUntilRelease = false

	mhpHandle.resizing = false
	mhpHandle.resizeStartMouseX = 0
	mhpHandle.resizeStartWidth = 0
	mhpHandle.resizeGripSize = 16

	mhpHandle.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.5}
	mhpHandle.borderColor = {r=0.4, g=0.4, b=0.4, a=1}

	mhpHandle.outlineTex = {
		[false] = getTexture("media/ui/male/mhp-Outline.png"),
		[true] = getTexture("media/ui/female/mhp-Outline.png")
	}

	mhpHandle.outlineTexSmall = {
		[false] = getTexture("media/ui/male/mhp-outline_small.png"),
		[true] = getTexture("media/ui/female/mhp-outline_small.png")
	}

	mhpHandle.backgroundTex = {
		[false] = getTexture("media/ui/male/mhp-background.png"),
		[true] = getTexture("media/ui/female/mhp-background.png")
	}

	mhpHandle.CONFIG_VERSION = 1
	mhpHandle.alwaysShow = false
	mhpHandle.showHpBar = false
	mhpHandle.showStrains = true
	mhpHandle.showHoverBackground = true
	mhpHandle.uiScale = 1.0
	mhpHandle.settingsPanel = nil
	mhpHandle.lastWrittenConfig = nil
	mhpHandle.enabled = enabled == true
	mhpHandle.onlyShowTreatmentNeeded = false
	mhpHandle.forceHiddenByGameOption = false
	mhpHandle.needsTreatment = false
	mhpHandle.needsDisplayAttention = false
	mhpHandle.showBCIAvatarOnIdle = false
	mhpHandle.strainAttentionTimer = 0
	mhpHandle.strainIdleReturnTimer = 0
	mhpHandle.strainAttentionUntilMS = 0
	mhpHandle.strainIdleReturnUntilMS = 0
	mhpHandle.forceVisibleForBCIAttention = false
	mhpHandle.bciTransitionTimer = 0
	mhpHandle.lastShouldShowMiniHealth = false
	mhpHandle:setVisible(enabled == true)

	return mhpHandle
end

function MHPPanel:getBaseBodyHeight()
	return 271
end

function MHPPanel:getBaseBodyZoneWidth()
	return 120
end

function MHPPanel:getBaseBodyWidth()
	return self.isFemale and 88 or 96
end

function MHPPanel:getHpBarGap()
	return 3
end

function MHPPanel:getHpBarOuterWidth()
	return 14
end

function MHPPanel:getHpBarInnerWidth()
	return 10
end

function MHPPanel:getHpBarRightPadding()
	return 3
end

function MHPPanel:getBasePanelWidth()
	if self.showHpBar then
		return 140
	end

	return 120
end

local MHP_MINI_GEAR_BUTTON_SIZE = 24

function MHPPanel:getScaledBodyWidth()
	return math.floor(self:getBaseBodyWidth() * self.uiScale + 0.5)
end

function MHPPanel:getScaledPanelWidth()
	return math.floor(self:getBasePanelWidth() * self.uiScale + 0.5)
end

function MHPPanel:getScaledPanelHeight()
	return math.floor(self:getBaseBodyHeight() * self.uiScale + 0.5)
end

function MHPPanel:getBodyDrawX()
	local baseOffset = (self:getBaseBodyZoneWidth() - self:getBaseBodyWidth()) / 2
	return math.floor(baseOffset * self.uiScale + 0.5)
end

function MHPPanel:setScale(scale)
	scale = tonumber(scale) or 1.0
	scale = math.max(0.5, math.min(2.0, scale))
	self.uiScale = scale
	self:applyLayout()
end

function MHPPanel:getOutlineTexture()
	local minScale = 0.5
	local maxScale = 2.0
	local switchAfterPercent = 0.25

	local smallOutlineThreshold = maxScale - ((maxScale - minScale) * switchAfterPercent)
	local isSmallScale = self.uiScale <= smallOutlineThreshold

	if isSmallScale and self.outlineTexSmall then
		local smallTex = self.outlineTexSmall[self.isFemale]
		if smallTex then
			return smallTex
		end
	end

	if self.outlineTex then
		return self.outlineTex[self.isFemale]
	end

	return nil
end

function MHPPanel:isInResizeCorner(x, y)
	if not self.moveWithMouse then
		return false
	end

	local grip = self.resizeGripSize or 16
	return x >= (self:getWidth() - grip) and y >= (self:getHeight() - grip)
end

function MHPPanel:updateResizeFromMouse()
	local dx = self:getMouseX() - self.resizeStartMouseX
	local newWidth = self.resizeStartWidth + dx
	local newScale = newWidth / self:getBasePanelWidth()

	self:setScale(newScale)
	self:syncAttachedPanels()
end

function MHPPanel:syncAttachedPanels()
end

function MHPPanel:isInGearButtonArea(x, y)
	if not self.gearButton or not self.topPanel or not self.topPanel:isVisible() then
		return false
	end

	return x >= self.gearButton:getX()
		and x < self.gearButton:getX() + self.gearButton:getWidth()
		and y >= self.gearButton:getY()
		and y < self.gearButton:getY() + self.gearButton:getHeight()
end

function MHPPanel:toggleHoverBackground(selected)
	self.showHoverBackground = selected
	if not selected then
		self.bgAlpha = 0
	end
end

function MHPPanel:applyLayout()
	local width = self:getScaledPanelWidth()
	local height = self:getScaledPanelHeight()
	local gearSize = MHP_MINI_GEAR_BUTTON_SIZE
	local topH = math.max(gearSize, getTextManager():getFontHeight(UIFont.Small) - 1)

	self.baseWidth = width
	self.baseHeight = height

	self:setWidth(width)
	self:setHeight(height)

	if self.topPanel then
		self.topPanel:setX(0)
		self.topPanel:setY(0)
		self.topPanel:setWidth(width)
		self.topPanel:setHeight(topH)
	end

	if self.gearButton then
		self.gearButton:setX(0)
		self.gearButton:setY(0)
		self.gearButton:setWidth(gearSize)
		self.gearButton:setHeight(gearSize)
	end

	self:checkNewResolution()
end

function MHPPanel:initialize()
	ISUIElement.initialise(self)

    self.cacheColor = Color.new(  1.0,  1.0, 1.0, 1.0 )

	-- ==== Body injuries init ====

	self.mhpBodyParts = {}

	for i = 0,16 do
		local textureKey = MHP_BODY_PART_TEXTURE_KEYS[i]

		local limb = {
			texture = {
				[false] = getTexture("media/ui/male/mhp_bodydamage_"..textureKey..".png"),
				[true] = getTexture("media/ui/female/mhp_bodydamage_"..textureKey..".png")
			},
			color = Color.new(0,1,0,1),
			alpha = 1.0,
			doBlink = false,
			blinkTime = 0,
			state = nil,
		}
		table.insert(self.mhpBodyParts, limb);
	end

	-- ==== Body strains init ====

	self.mhpBodyStrains = {}

	for i = 0,16 do
		local textureKey = MHP_BODY_PART_TEXTURE_KEYS[i]

		local limb = {
			texture = {
				[false] = getTexture("media/ui/male/mhp_stiffness_"..textureKey..".png"),
				[true] = getTexture("media/ui/female/mhp_stiffness_"..textureKey..".png")
			},
			color = Color.new(0,1,0,1),
			strainAlpha = 1.0,
			renderAlpha = 1.0,
			colorMultiplier = 1,
			r = 1,
			g = 0.57,
			b = 0.11,
			blinkTime = 79,
			nextStage = 5,
			prevStage = -1,
			state = nil,
		}
		table.insert(self.mhpBodyStrains, limb);
	end
end

function MHPPanel:createChildren()
	local btnWid = MHP_MINI_GEAR_BUTTON_SIZE
	local btnHgt = MHP_MINI_GEAR_BUTTON_SIZE

	self.topPanel = ISPanel:new(0, 0, self:getWidth(), btnHgt)
	self.topPanel.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.0}
	self.topPanel.borderColor = {r=0.0, g=0.0, b=0.0, a=0.0}
	self:addChild(self.topPanel)
	self.topPanel:setVisible(false)

	self.topPanel.onMouseDown = function(panel, x, y)
		if panel.parent:isInGearButtonArea(x, y) then
			return false
		end
		return panel.parent:onMouseDown(x, y)
	end

	self.topPanel.onMouseMove = function(panel, dx, dy)
		if panel.parent.moving or panel.parent.resizing then
			return panel.parent:onMouseMove(dx, dy)
		end
		return ISPanel.onMouseMove(panel, dx, dy)
	end

	self.topPanel.onMouseMoveOutside = function(panel, dx, dy)
		if panel.parent.moving or panel.parent.resizing then
			return panel.parent:onMouseMoveOutside(dx, dy)
		end
		return ISPanel.onMouseMoveOutside(panel, dx, dy)
	end

	self.topPanel.onMouseUp = function(panel, x, y)
		if panel.parent:isInGearButtonArea(x, y) then
			return false
		end
		return panel.parent:onMouseUp(x, y)
	end

	self.topPanel.onMouseUpOutside = function(panel, x, y)
		return panel.parent:onMouseUpOutside(x, y)
	end

	self.topPanel.onRightMouseUp = function(panel, x, y)
		return panel.parent:onRightMouseUp(x, y)
	end

	self.gearButton = ISButton:new(0, 0, btnWid, btnHgt, "", self, MHPPanel.onGearButton)
	self.gearButton:initialise()
	self.gearButton.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
	self.gearButton:setImage(getTexture("media/ui/inventoryPanes/Button_Gear.png"))
	self.topPanel:addChild(self.gearButton)

	self:applyLayout()
end

function MHPPanel:ensureSettingsPanel()
	if self.settingsPanel then
		return self.settingsPanel
	end

	self:addSettingsPanel()
	return self.settingsPanel
end

function MHPPanel:addSettingsPanel()
	if self.settingsPanel then
		return self.settingsPanel
	end

	local x, y, width = self:settingsPanelPos()

	local panel = ISMhpSettings:new(x, y, width, self)
	panel:initialise()
	panel:instantiate()
	panel:createChildren()
	panel:populateOptions()
	panel:addToUIManager()
	panel:setOpen(false, 0, 0, 0)

	self.settingsPanel = panel
	return panel
end

function MHPPanel:settingsPanelPos()
	local width = 240
	local panelHeight = 0

	if self.settingsPanel then
		self.settingsPanel:refreshLayout()
		width = self.settingsPanel:getWidth()
		panelHeight = self.settingsPanel:getHeight()
	end

	local x = self:getX() + self:getWidth() + 8
	local y = self:getY()

	local screenW = getCore():getScreenWidth()
	local screenH = getCore():getScreenHeight()

	if x + width > screenW then
		x = self:getX() - width - 8
	end
	if x < 0 then
		x = 0
	end

	if y + panelHeight > screenH then
		y = screenH - panelHeight
	end
	if y < 0 then
		y = 0
	end

	return x, y, width
end

function MHPPanel:onGearButton()
	if self.player_isDead then
		return
	end

	local panel = self:ensureSettingsPanel()	
	if not panel then
		return
	end

	local x, y, width = self:settingsPanelPos()

	if panel:getOpen() == false then
		panel:setOpen(true, x, y, width)
	else
		panel:setOpen(false, 0, 0, 0)
	end
end

function MHPPanel:openSettingsFromBCIAvatar(avatarWindow)
	if self.player_isDead then
		return
	end

	local panel = self:ensureSettingsPanel()
	if not panel then
		return
	end

	if panel:getOpen() == true then
		panel:setOpen(false, 0, 0, 0)
		return
	end

	local x, y, width = self:settingsPanelPos()

	if avatarWindow then
		panel:refreshLayout()
		width = panel:getWidth()

		x = avatarWindow:getX() + avatarWindow:getWidth() + 8
		y = avatarWindow:getY()

		local screenW = getCore():getScreenWidth()
		local screenH = getCore():getScreenHeight()
		local panelH = panel:getHeight()

		if x + width > screenW then
			x = avatarWindow:getX() - width - 8
		end

		if x < 0 then
			x = 0
		end

		if y + panelH > screenH then
			y = screenH - panelH
		end

		if y < 0 then
			y = 0
		end
	end

	panel:setOpen(true, x, y, width)
end

function MHPPanel:toggleAlwaysShow(selected)
	self.alwaysShow = selected == true

	if self.alwaysShow then
		self.hideTimer = math.max(self.hideTimer or 0, 10)
		self.alpha = 1.0
		return
	end

	if self.forceVisibleForBCIAttention ~= true
	and self.needsWakeAttention ~= true then
		self.hideTimer = 0
	end
end

function MHPPanel:toggleHpBar(selected)
	self.showHpBar = selected
	self:applyLayout()
end

function MHPPanel:toggleStrains(selected)
	self.showStrains = selected == true

	if self.showStrains then
		if self.enabled == true then
			self:refreshStrainAttentionState()
		end
		return
	end

	MHP_ClearStrainTimers(self)

	if self.mhpBodyStrains then
		for _, strain in ipairs(self.mhpBodyStrains) do
			strain.strainAlpha = 0
			strain.renderAlpha = 0
			strain.blinkTime = 79
			MHP_UpdateStrainThresholdState(strain, 0)
		end
	end

	self.needsDisplayAttention = MHPPanel.playerNeedsDisplayAttention(self.player, false) == true
	self.needsWakeAttention = self.needsTreatment == true

	if self.alwaysShow ~= true
	and self.forceVisibleForBCIAttention ~= true
	and self.needsWakeAttention ~= true then
		self.hideTimer = 0
	end
end

function MHPPanel:toggleBCIAvatarOnIdle(selected)
	local enabled = selected == true

	if self.showBCIAvatarOnIdle == enabled then
		if not enabled then
			MHP_CloseBCIIdleAvatar(self.playerIndex, true)
		end

		return
	end

	self.showBCIAvatarOnIdle = enabled
	self.bciTransitionTimer = 0
	self.forceVisibleForBCIAttention = false

	if not enabled then
		MHP_CloseBCIIdleAvatar(self.playerIndex, true)
	end

	if self.enabled == true then
		self:refreshGameModOptionVisibility(self.enabled, self.onlyShowTreatmentNeeded)
	end
end

function MHPPanel:refreshStrainAttentionState()
	if self.showStrains ~= true then
		MHP_ClearStrainTimers(self)
		return false
	end

	if not self.player or self.player_isDead == true then
		MHP_ClearStrainTimers(self)
		return false
	end

	local bodyDamage = self.player:getBodyDamage()
	if not bodyDamage then
		return false
	end

	local bodyParts = bodyDamage:getBodyParts()
	if not bodyParts then
		return false
	end

	local active = false
	local hasActiveStrain = false

	for i = 1, #self.mhpBodyStrains do
		local bodyPart = bodyParts:get(i - 1)
		local strain = self.mhpBodyStrains[i]

		if bodyPart and strain then
			local stiffness = bodyPart:getStiffness()

			-- Important for BCI transition:
			-- Any active muscle strain keeps Mini Health Plus visible.
			if MHP_IsStrainRelevantForBCI(stiffness) then
				hasActiveStrain = true
				active = true
			end

			-- Thresholds may wake the Mini Health UI, but visual blink frames should not
			-- keep the BCI idle avatar blocked from returning.
			if MHP_StrainsThresholdReached(strain, stiffness) then
				local duration = MHP_GetStrainAttentionDuration(stiffness)

				MHP_ExtendTimedFlag(self, "strainAttentionUntilMS", duration)
				self.hideTimer = math.max(self.hideTimer or 0, duration)
				MHP_SoftWakePanel(self, 0.55)

				strain.blinkTime = 16
			end

			if MHP_StrainsShouldStayVisible(stiffness) then
				active = true
			end

			MHP_UpdateStrainThresholdState(strain, stiffness)
		end
	end

	if hasActiveStrain then
		MHP_SetTimedFlag(self, "strainIdleReturnUntilMS", MHP_STRAIN_IDLE_RETURN_FRAMES)
		active = true
	elseif MHP_IsTimedFlagActive(self, "strainIdleReturnUntilMS") then
		active = true
	end

	if MHP_IsTimedFlagActive(self, "strainAttentionUntilMS") then
		active = true
	end

	return active
end

function MHPPanel:toggleLock(selected)
	self.moveWithMouse = selected

	if not selected then
		self.moving = false
		self.dragging = false
		self.dragDistance = 0
		self.resizing = false
		self:setCapture(false)
	end
end

function MHPPanel:isWorldMapOpen()
	local inst = rawget(_G, "ISWorldMap_instance")
	if inst and inst.isVisible then
		local ok, visible = pcall(inst.isVisible, inst)
		return ok and visible == true
	end
	return false
end

function MHPPanel:addToUIManagerOnce()
	MHP_AddToUIManagerOnce(self)
end

function MHPPanel:applyAlwaysOnTopState()
	local shouldBeOnTop = self.enabled == true
		and self.forceHiddenByGameOption ~= true
		and self.alwaysOnTopUI == true
		and self.hiddenForWorldMap ~= true

	MHP_ApplyMiniHealthZOrder(self, shouldBeOnTop)
end

function MHPPanel:setHiddenForWorldMap(hidden)
	hidden = hidden == true

	if self.hiddenForWorldMap == hidden then
		if not hidden then
			self:applyAlwaysOnTopState()
		end
		return
	end

	self.hiddenForWorldMap = hidden

	if hidden then
		self:setAlwaysOnTop(false)
		self:setVisible(false)
		return
	end

	if self.enabled == true and self.forceHiddenByGameOption ~= true then
		self:setVisible(true)
	end

	self:applyAlwaysOnTopState()
end

function MHPPanel:syncWorldMapVisibility()
	self:setHiddenForWorldMap(self:isWorldMapOpen())
end

function MHPPanel:toggleAlwaysOnTopUI(selected)
	self.alwaysOnTopUI = selected == true
	self:syncWorldMapVisibility()
	self:applyAlwaysOnTopState()
end

function MHPPanel:prerender()
	local bodyX = self:getBodyDrawX()
	local bodyW = self:getScaledBodyWidth()
	local bodyH = self:getScaledPanelHeight()
	local settingsOpen = self.settingsPanel and self.settingsPanel:getOpen() or false

	self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a * self.bgAlpha, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
	self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a * self.bgAlpha, self.borderColor.r, self.borderColor.g, self.borderColor.b)

	local backgroundTex = self.backgroundTex and self.backgroundTex[self.isFemale] or nil
	if backgroundTex then
		self:drawTextureScaled(backgroundTex, bodyX, 0, bodyW, bodyH, 0.5 * self.alpha, 0, 0, 0)
	end

	local outlineColor = (self.health / 80) - 0.2
	local outlineTex = self:getOutlineTexture()
	if outlineTex then
		self:drawTextureScaled(outlineTex, bodyX, 0, bodyW, bodyH, 1 * self.alpha, 1, outlineColor, outlineColor)
	end

	if self:isMouseOver() or settingsOpen then
		self.isHover = true
		self.bgAlpha = self.showHoverBackground and 1 or 0
		self.hideTimer = 30
		self.alpha = 1
		if self.topPanel then
			self.topPanel:setVisible(true)
		end
	else
		self.isHover = false
		self.bgAlpha = 0
		if self.topPanel then
			self.topPanel:setVisible(false)
		end
	end
end

function MHPPanel:render()
	local bp
	local blinking = 0
	local bodyX = self:getBodyDrawX()
	local bodyW = self:getScaledBodyWidth()
	local bodyH = self:getScaledPanelHeight()

	for i = 1, #self.mhpBodyParts do
		bp = self.mhpBodyParts[i]

		if bp.doBlink then
			bp.alpha = self.blinkAlpha
			blinking = blinking + 1
		end

		if bp.alpha > 0 and self.alpha > 0 then
			self:drawTextureScaled(bp.texture[self.isFemale], bodyX, 0, bodyW, bodyH, bp.alpha * self.alpha, bp.color:getRedFloat(), bp.color:getGreenFloat(), bp.color:getBlueFloat())
		end

		if not self.player_isDead and self.showStrains then
			local st = self.mhpBodyStrains[i]

			if st.blinkTime <= 78 then
				st.blinkTime = st.blinkTime + 1
				st.blinkAlpha = math.abs(math.sin(st.blinkTime / 10))
			end

			if st.blinkTime < 78 then
				st.renderAlpha = st.strainAlpha * st.blinkAlpha
			elseif bp.doBlink then
				st.renderAlpha = st.strainAlpha * (1 - self.blinkAlpha)
			else
				st.renderAlpha = st.strainAlpha
			end

			if st.strainAlpha > 0 and self.alpha > 0 then
				self:drawTextureScaled(st.texture[self.isFemale], bodyX, 0, bodyW, bodyH, st.renderAlpha * self.alpha, st.r, st.g, st.b)
			end
		end
	end

	if blinking > 0 then
		self.blinkTime = self.blinkTime + 1
		self.blinkAlpha = self:getBlinkOverlayAlpha()
	else
		self.blinkTime = 0
		self.blinkAlpha = 0
	end

	if self.showHpBar then
		local bodyZoneW = self:getBaseBodyZoneWidth()
		local baseBodyH = self:getBaseBodyHeight()

		local outerX = math.floor((bodyZoneW + self:getHpBarGap()) * self.uiScale + 0.5)
		local outerY = math.floor((baseBodyH - 4) * self.uiScale + 0.5)
		local outerW = math.max(2, math.floor(self:getHpBarOuterWidth() * self.uiScale + 0.5))
		local outerH = math.floor((baseBodyH - 7) * self.uiScale + 0.5)

		local innerX = math.floor((bodyZoneW + self:getHpBarGap() + 2) * self.uiScale + 0.5)
		local innerY = math.floor((baseBodyH - 6) * self.uiScale + 0.5)
		local innerW = math.max(2, math.floor(self:getHpBarInnerWidth() * self.uiScale + 0.5))
		local hpHeight = (self.health / 100) * ((baseBodyH - 11) * self.uiScale)

		self:drawRectStatic(outerX, outerY, outerW, -outerH, 0.5 * self.alpha, 0, 0, 0)
		self:drawRectStatic(innerX, innerY, innerW, -hpHeight, 1 * self.alpha, self.healthColor.r, self.healthColor.g, self.healthColor.b)
	end

	if self.moveWithMouse and (self.isHover or self.resizing) then
		local gripAlpha = 0.85
		local gx = self:getWidth() - 11
		local gy = self:getHeight() - 11

		self:drawRectStatic(gx + 4, gy + 8, 5, 1, gripAlpha, 1, 1, 1)
		self:drawRectStatic(gx + 2, gy + 6, 7, 1, gripAlpha, 1, 1, 1)
		self:drawRectStatic(gx + 0, gy + 4, 9, 1, gripAlpha, 1, 1, 1)
	end

	MHP_UpdatePanelHideTimer(self)

	if not self.isHover then
		if self.hideTimer <= 0 then
			self.alpha = math.max(self.alpha - 0.05, 0)
		else
			self.alpha = math.min(self.alpha + 0.05, 1)
		end
	end
end


function MHPPanel:update()
	local bodyDamage = self.player:getBodyDamage()
	local bodyParts = bodyDamage:getBodyParts()

	local showSafeRemoveIndicator = true
	if type(MHP_SB_IsSafeRemoveIndicatorEnabled) == "function" then
		showSafeRemoveIndicator = MHP_SB_IsSafeRemoveIndicatorEnabled()
	end

	local showStitchInspectIndicator = true
	if type(MHP_SB_IsStitchInspectIndicatorEnabled) == "function" then
		showStitchInspectIndicator = MHP_SB_IsStitchInspectIndicatorEnabled()
	end

	local injuries = 0
	local treated = 0
	local needsTreatment = false
	local needsDisplayAttention = false
	local hasActiveStrain = false

	for i = 1, #self.mhpBodyParts do
		local bodyPart = bodyParts:get(i - 1)
		local limb = self.mhpBodyParts[i]

		if MHP_BodyPartNeedsTreatment(bodyPart, false) then
			needsTreatment = true
		end

		if MHP_BodyPartNeedsDisplayAttention(bodyPart, false, showSafeRemoveIndicator, showStitchInspectIndicator) then
			needsDisplayAttention = true
		end
		local hasBandage = bodyPart:bandaged()
		local hasSplint = bodyPart:getSplintFactor() > 0
		local hasStitch = bodyPart:stitched()
		local hasDisplayedTreatment = hasBandage or hasSplint or hasStitch
		local hasFracture = bodyPart:getFractureTime() > 0

		local hasOtherWound =
			bodyPart:scratched()
			or bodyPart:deepWounded()
			or bodyPart:getDeepWoundTime() > 0
			or bodyPart:bitten()
			or bodyPart:bleeding()
			or bodyPart:isBurnt()
			or bodyPart:isCut()
			or bodyPart:haveGlass()
			or bodyPart:haveBullet()
			or bodyPart:isInfectedWound()

		local hasActiveInjury = MHP_HasUnderlyingWound(bodyPart)
		local isHealedButStillTreated = MHP_HasSafeRemovableTreatment(bodyPart)
		local canInspectStitches = MHP_CanInspectStitches(bodyPart)

		if hasActiveInjury or hasDisplayedTreatment then
			limb.alpha = 1.0

			if hasActiveInjury then
				injuries = injuries + 1
			end

			if hasBandage and bodyPart:getBandageLife() <= 0 then
				limb.color = COLORS.dirty

				if hasActiveInjury and (hasBandage or hasSplint or hasStitch) then
					treated = treated - 1
				end
			elseif isHealedButStillTreated and showSafeRemoveIndicator then
				limb.color = COLORS.healed
			elseif canInspectStitches and showStitchInspectIndicator then
				limb.color = COLORS.stitchReady
			elseif hasBandage or hasSplint then
				limb.color = COLORS.bandaged

				if hasActiveInjury then
					treated = treated + 1
				end
			else
				limb.color = COLORS.untreated
			end
		else
			limb.alpha = 0
			limb.doBlink = false
			limb.color = COLORS.none
		end

		local shouldBlink =
			(
				hasOtherWound
				and not hasBandage
			)
			or (
				(
					bodyPart:getDeepWoundTime() > 0
					or bodyPart:haveBullet()
					or bodyPart:haveGlass()
				) and hasBandage
			)
			or (
				hasFracture
				and not hasSplint
			)

		if shouldBlink then
			limb.doBlink = true

			if hasActiveInjury and (hasBandage or hasSplint) and not isHealedButStillTreated then
				treated = treated - 1
			end
		elseif hasActiveInjury or hasDisplayedTreatment then
			limb.doBlink = false
			limb.alpha = 1.0
		end

		if self.showStrains then
			local strain = self.mhpBodyStrains[i]
			local stiffness = bodyPart:getStiffness()

			if stiffness > 0 then
				strain.strainAlpha = math.min((stiffness / 5), 1)
			else
				strain.strainAlpha = 0
			end

			if MHP_IsStrainRelevantForBCI(stiffness) then
				hasActiveStrain = true
				needsDisplayAttention = true
			end

			if stiffness >= 5 then
				strain.colorMultiplier = math.min((20 - stiffness) / 15, 1)
				strain.g = COLORS.strain.g * strain.colorMultiplier
				strain.b = COLORS.strain.b * strain.colorMultiplier
			else
				strain.g = 0.87
				strain.b = 0
			end

			if MHP_StrainsThresholdReached(strain, stiffness) then
					local duration = MHP_GetStrainAttentionDuration(stiffness)

					MHP_ExtendTimedFlag(self, "strainAttentionUntilMS", duration)
					self.hideTimer = math.max(self.hideTimer or 0, duration)
					MHP_SoftWakePanel(self, 0.55)

					strain.blinkTime = 16
			end

			if strain.blinkTime <= 15 then
				strain.blinkTime = strain.blinkTime + 1
			elseif strain.blinkTime <= 78 then
				strain.blinkTime = strain.blinkTime + 1
			end

			if strain.blinkTime < 78
				or MHP_StrainsShouldStayVisible(stiffness) then
				needsDisplayAttention = true
			end

			MHP_UpdateStrainThresholdState(strain, stiffness)
		end
	end

	local needsWakeAttention = needsTreatment == true

	if self.showStrains == true then
		if hasActiveStrain == true
		or MHP_IsTimedFlagActive(self, "strainIdleReturnUntilMS")
		or MHP_IsTimedFlagActive(self, "strainAttentionUntilMS") then
			needsWakeAttention = true
		end
	end

	local totalHealth = bodyDamage:getHealth()
	local previousHealth = tonumber(self.previousHealth)

	if previousHealth == nil then
		self.previousHealth = totalHealth
	elseif math.abs(totalHealth - previousHealth) >= 0.01 then
		local healthWentDown = totalHealth < previousHealth

		self.previousHealth = totalHealth

		if healthWentDown then
			self.hideTimer = math.max(self.hideTimer or 0, 40)
			MHP_SoftWakePanel(self, 0.45)

		elseif self.needsWakeAttention == true then
			self.hideTimer = math.max(self.hideTimer or 0, 10)
		end
	end

	self.health = math.ceil(totalHealth)

	local t = math.max(0, math.min(1, totalHealth / 100))
	local badColor = getCore():getBadHighlitedColor()
	local goodColor = getCore():getGoodHighlitedColor()

	self.healthColor.r = badColor:getR() + (goodColor:getR() - badColor:getR()) * t
	self.healthColor.g = badColor:getG() + (goodColor:getG() - badColor:getG()) * t
	self.healthColor.b = badColor:getB() + (goodColor:getB() - badColor:getB()) * t
	self.healthColor.a = 1
	local previousNeedsTreatment = self.needsTreatment == true
	local previousNeedsDisplayAttention = self.needsDisplayAttention == true

	self.needsTreatment = needsTreatment
	self.needsDisplayAttention = needsDisplayAttention
	self.needsWakeAttention = needsWakeAttention
	MHP_UpdatePanelHideTimer(self)

	local attentionChanged =
		previousNeedsTreatment ~= self.needsTreatment
		or previousNeedsDisplayAttention ~= self.needsDisplayAttention

	if attentionChanged
	and (
		self.showBCIAvatarOnIdle == true
		or self.alwaysShow ~= true
		or self.onlyShowTreatmentNeeded == true
	) then
		if type(TwisTonFire_MHP_RequestFullRefresh) == "function" then
			TwisTonFire_MHP_RequestFullRefresh()
		end
	end

	if self.alwaysShow then
		self.hideTimer = 10
		self.alpha = 1.0

	elseif self.forceVisibleForBCIAttention == true then
		self.hideTimer = math.max(self.hideTimer or 0, 10)
		MHP_SoftWakePanel(self, 0.45)

	elseif self.forceHiddenByGameOption ~= true and self.needsWakeAttention == true then
		self.hideTimer = math.max(self.hideTimer or 0, 10)
		MHP_SoftWakePanel(self, 0.45)
	end
end

-- ===== Handle player death =====

function MHPPanel:getPlayer()
	return self.player
end

function MHPPanel:setPlayerIsDead(isDead)
	self.player_isDead = isDead

	if self.settingsPanel and self.settingsPanel:getOpen() then
		self.settingsPanel:setOpen(false, 0, 0, 0)
	end
end

function MHPPanel:getPlayerIsDead()
	return self.player_isDead
end

function MHPPanel:setPlayer(playerIndex,player)
	self.playerIndex = playerIndex
	self.player = player
	self.isFemale = player:isFemale();
	self:setPlayerIsDead(false)
	self.infopanel = getPlayerInfoPanel(player:getPlayerNum())
	self:applyLayout()
	self:checkNewResolution()
end

-- ===== Handle screen resolution change =====
function MHPPanel:checkNewResolution()
	local screenH = getCore():getScreenHeight()
	local screenW = getCore():getScreenWidth()

	local posX = self:getX()
	local posY = self:getY()
	local width = self:getWidth()
	local height = self:getHeight()

	if posX + width > screenW then
		posX = screenW - width
	end

	if posY + height > screenH then
		posY = screenH - height
	end

	if posX < 0 then
		posX = 0
	end

	if posY < 0 then
		posY = 0
	end

	self:setX(posX)
	self:setY(posY)
end

function MHPPanel:centerOnScreen()
	local screenW = getCore():getScreenWidth()
	local screenH = getCore():getScreenHeight()

	local x = math.floor((screenW - self:getWidth()) / 2)
	local y = math.floor((screenH - self:getHeight()) / 2)

	if x < 0 then x = 0 end
	if y < 0 then y = 0 end

	self:setX(x)
	self:setY(y)
	self:checkNewResolution()
end

-- ===== Open health panel (and prevent it if moving the mini panel) =====

function MHPPanel:onMouseDown(x, y)
	if self:isInResizeCorner(x, y) then
		self.resizing = true
		self.dragging = false
		self.dragDistance = 0
		self.suppressClickUntilRelease = true
		self.resizeStartMouseX = self:getMouseX()
		self.resizeStartWidth = self:getWidth()
		self:setCapture(true)
		return true
	end

	self.dragging = false
	self.dragDistance = 0
	self.suppressClickUntilRelease = false

	self.mouseDownLocalX = x
	self.mouseDownLocalY = y
	self.mouseDownPanelX = self:getX()
	self.mouseDownPanelY = self:getY()

	self.moving = self.moveWithMouse == true

	if self.moving then
		self:bringToTop()
		self:setCapture(true)
	end

	return true
end

function MHPPanel:updateDragFromMouse(dx, dy, mouseOver)
	self.mouseOver = mouseOver

	if self.resizing then
		self:updateResizeFromMouse()
		return true
	end

	if not self.moving then
		return true
	end

	self.dragDistance = self.dragDistance + math.max(math.abs(dx), math.abs(dy))

	if self.dragDistance >= self.clickCancelThreshold then
		self.suppressClickUntilRelease = true
	end

	if self.dragDistance >= self.dragThreshold then
		self.dragging = true
	end

	local correctionX = self:getMouseX() - self.mouseDownLocalX
	local correctionY = self:getMouseY() - self.mouseDownLocalY

	if correctionX == 0 and correctionY == 0 then
		return true
	end

	local newX = self:getX() + correctionX
	local newY = self:getY() + correctionY

	local maxX = math.max(0, getCore():getScreenWidth() - self:getWidth())
	local maxY = math.max(0, getCore():getScreenHeight() - self:getHeight())

	if newX < 0 then newX = 0 end
	if newY < 0 then newY = 0 end
	if newX > maxX then newX = maxX end
	if newY > maxY then newY = maxY end

	self:setX(newX)
	self:setY(newY)

	if newX ~= self.mouseDownPanelX or newY ~= self.mouseDownPanelY then
		self.suppressClickUntilRelease = true
		self.dragging = true
	end

	return true
end

function MHPPanel:onMouseMove(dx, dy)
	return self:updateDragFromMouse(dx, dy, true)
end

function MHPPanel:onMouseMoveOutside(dx, dy)
	return self:updateDragFromMouse(dx, dy, false)
end

function MHPPanel:onMouseUp(x, y)
	if self.resizing then
		self.resizing = false
		self.moving = false
		self:setCapture(false)
		self:writeConfig()
		return true
	end

	local panelMoved = (self:getX() ~= self.mouseDownPanelX) or (self:getY() ~= self.mouseDownPanelY)
	local shouldOpenHealth = (not self.dragging) and (not self.suppressClickUntilRelease) and (not panelMoved)

	self.moving = false
	self:setCapture(false)

	if panelMoved or self.dragging then
		self:writeConfig()
	elseif shouldOpenHealth and not self.player_isDead then
		getSoundManager():playUISound("UISelectListItem")
		self.infopanel:toggleView(getText("IGUI_XP_Health"))
	end

	self.dragging = false
	self.dragDistance = 0
	self.suppressClickUntilRelease = false

	return true
end

function MHPPanel:onMouseUpOutside(x, y)
	if self.resizing then
		self.resizing = false
		self.moving = false
		self:setCapture(false)
		self:writeConfig()
		return true
	end

	local panelMoved = (self:getX() ~= self.mouseDownPanelX) or (self:getY() ~= self.mouseDownPanelY)

	self.moving = false
	self:setCapture(false)

	if panelMoved or self.dragging then
		self:writeConfig()
	end

	self.dragging = false
	self.dragDistance = 0
	self.suppressClickUntilRelease = false

	return true
end

MHPPanel.haveDamagePart = function (player)
	local result = {}
	local bodyParts = getSpecificPlayer(player):getBodyDamage():getBodyParts()

	for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
		local bodyPart = bodyParts:get(i)

		if bodyPart:scratched()
		or bodyPart:deepWounded()
		or bodyPart:getDeepWoundTime() > 0
		or bodyPart:bitten()
		or bodyPart:getFractureTime() > 0
		or bodyPart:stitched()
		or bodyPart:bleeding()
		or bodyPart:isBurnt()
		or bodyPart:isCut()
		or bodyPart:haveGlass()
		or bodyPart:haveBullet()
		or bodyPart:isInfectedWound()
		or bodyPart:bandaged()
		or bodyPart:getSplintFactor() > 0 then
			table.insert(result, bodyPart)
		end
	end

	return result
end

MHPPanel.getInjuryType = function(bodyPart)
	local text = ""
	local redText = true
	local isHealedButStillTreated = MHP_HasSafeRemovableTreatment(bodyPart)
	local canInspectStitches = MHP_CanInspectStitches(bodyPart)

	if bodyPart:bleeding() then
		text = getText("IGUI_health_Bleeding")
	end
	if bodyPart:scratched() then
		text = getText("IGUI_health_Scratched")
	end
	if bodyPart:isCut() then
		text = getText("IGUI_health_Cut")
	end
	if bodyPart:bitten() then
		text = getText("IGUI_health_Bitten")
	end
	if bodyPart:getFractureTime() > 0 and bodyPart:getSplintFactor() == 0 then
		text = getText("IGUI_health_Fracture")
	end
	if bodyPart:getSplintFactor() > 0 then
		text = getText("IGUI_health_Splinted")
		redText = false
	end
	if bodyPart:bandaged() and bodyPart:getBandageLife() > 0 then
		text = getText("IGUI_health_Bandaged")
		redText = false
	end
	if bodyPart:bandaged() and bodyPart:getBandageLife() <= 0 then
		text = getText("IGUI_health_DirtyBandage")
		redText = false
	end

	if bodyPart:getBurnTime() > 0 and not bodyPart:bandaged() then
		text = getText("IGUI_health_Burned")
	end
	if bodyPart:stitched() then
		text = getText("IGUI_health_Stitched")
	end
	if bodyPart:isInfectedWound() and not bodyPart:bandaged() then
		text = text .. " - " .. getText("IGUI_health_Infected")
	end

	if bodyPart:getDeepWoundTime() > 0 then
		if bodyPart:bandaged() or bodyPart:stitched() then
			text = text .. " - " .. getText("IGUI_health_DeepWound")
			redText = true
		else
			text = getText("IGUI_health_DeepWound")
		end
	end
	if bodyPart:haveGlass() then
		if bodyPart:bandaged() or bodyPart:stitched() then
			text = text .. " - " .. getText("IGUI_health_LodgedGlassShards")
		else
			text = getText("IGUI_health_LodgedGlassShards")
		end
	end
	if bodyPart:haveBullet() then
		if bodyPart:bandaged() or bodyPart:stitched() then
			text = text .. " - " .. getText("IGUI_health_LodgedBullet")
		else
			text = getText("IGUI_health_LodgedBullet")
		end
	end

	if isHealedButStillTreated or canInspectStitches then
		redText = false
	end

	return text, redText
end

-- ===== Context menu ====
local contextMenu = nil

function MHPPanel:canOpenContextMenu()
	if self.player_isDead then
		return false
	end

	if not self.player then
		return false
	end

	if self.playerIndex == nil then
		return false
	end

	local livePlayer = getSpecificPlayer(self.playerIndex)
	if not livePlayer then
		return false
	end

	if livePlayer.isDead and livePlayer:isDead() then
		return false
	end

	if getPlayerContextMenu(self.playerIndex) == nil then
		return false
	end

	return true
end

function MHPPanel:onRightMouseUp(x, y, ...)
	if not self:canOpenContextMenu() then
		return true
	end

	self:showContextMenu(self, x, y)
	return true
end

function MHPPanel:showContextMenu(miniHealth, x, y)
	if not miniHealth or not miniHealth:canOpenContextMenu() then
		return
	end

	local existingContext = getPlayerContextMenu(miniHealth.playerIndex)
	if not existingContext then
		return
	end

	local contextMenu = ISContextMenu.get(
		miniHealth.playerIndex,
		miniHealth:getX() + x,
		miniHealth:getY() + y
	)

	if not contextMenu then
		return
	end

	local MiniHealthTreatment = MHP.MiniHealthTreatment
	if not MiniHealthTreatment or not MiniHealthTreatment.doBodyPartContextMenu then
		contextMenu:addOption(getText("UI_MHP_NoActionAvailable"), nil, nil)
		return
	end

	local bodyPartDamaged = MHPPanel.haveDamagePart(miniHealth.playerIndex)

	if #bodyPartDamaged > 0 then
		for i, v in ipairs(bodyPartDamaged) do
			local injuryType, redText = MHPPanel.getInjuryType(v)
			local bodyPartOption = contextMenu:addOption(BodyPartType.getDisplayName(v:getType()) .. " (" .. injuryType .. ")", miniHealth, nil)
			bodyPartOption.notAvailable = redText

			local bodyPartSubMenu = ISContextMenu:getNew(contextMenu)
			contextMenu:addSubMenu(bodyPartOption, bodyPartSubMenu)

			MiniHealthTreatment:doBodyPartContextMenu(v, bodyPartSubMenu)
		end
	else
		contextMenu:addOption(getText("UI_MHP_NoActionAvailable"), nil, nil)
	end
end


-- ===== Config =====

function MHPPanel:refreshGameModOptionVisibility(enabled, onlyShowTreatmentNeeded)
	enabled = enabled == true
	onlyShowTreatmentNeeded = onlyShowTreatmentNeeded == true

	self.enabled = enabled
	self.onlyShowTreatmentNeeded = onlyShowTreatmentNeeded
	self.needsTreatment = MHPPanel.playerNeedsTreatment(self.player)

	local staticDisplayAttention = MHPPanel.playerNeedsDisplayAttention(self.player, false)
	local strainDisplayAttention = self:refreshStrainAttentionState()

	self.needsDisplayAttention = staticDisplayAttention == true or strainDisplayAttention == true
	self.needsWakeAttention = self.needsTreatment == true or strainDisplayAttention == true

	local bciModActive = type(TwisTonFire_MHP_IsBetterCharacterInfoActive) == "function"
		and TwisTonFire_MHP_IsBetterCharacterInfoActive() == true

	local bciIdleActive = self.showBCIAvatarOnIdle == true and bciModActive == true

	if bciIdleActive then
		MHP_EnforceSingleBCIIdleAvatar(
			self.playerIndex,
			TTF_BCI_FloatingAvatarUI
				and TTF_BCI_FloatingAvatarUI._instances
				and TTF_BCI_FloatingAvatarUI._instances[self.playerIndex]
				or nil
		)
	else
		self.forceVisibleForBCIAttention = false
		self.bciTransitionTimer = 0
	end

	local playerDead = self.player_isDead == true
		or (self.player and self.player.isDead and self.player:isDead())

	local worldMapOpen = self:isWorldMapOpen()
	local canShowAnything = enabled and not playerDead and not worldMapOpen

	if not canShowAnything then
		MHP_CloseBCIIdleAvatar(self.playerIndex, bciIdleActive == true)

		if self.settingsPanel and self.settingsPanel:getOpen() then
			self.settingsPanel:setOpen(false, 0, 0, 0)
		end

		self.forceVisibleForBCIAttention = false
		self.forceHiddenByGameOption = enabled
		self.lastShouldShowMiniHealth = false
		self.bciTransitionTimer = 0
		self.hiddenForWorldMap = false
		self:setAlwaysOnTop(false)
		self:setVisible(false)
		self:removeFromUIManager()
		return
	end

	local shouldShowMiniHealth = true
	local shouldShowIdleAvatar = false

	if bciIdleActive then
		if onlyShowTreatmentNeeded then
			shouldShowMiniHealth = self.needsTreatment == true
		else
			shouldShowMiniHealth = self.needsDisplayAttention == true
		end

		shouldShowIdleAvatar = not shouldShowMiniHealth

	elseif onlyShowTreatmentNeeded then
		shouldShowMiniHealth = self.needsTreatment == true
	end

	self.forceVisibleForBCIAttention = bciIdleActive == true and shouldShowMiniHealth == true
	self.forceHiddenByGameOption = enabled and not shouldShowMiniHealth
	self.lastShouldShowMiniHealth = shouldShowMiniHealth

	if shouldShowMiniHealth then
		MHP_CloseBCIIdleAvatar(self.playerIndex, bciIdleActive == true)

		self.bciTransitionTimer = 0
		self.forceHiddenByGameOption = false
		self:setVisible(true)
		self:addToUIManagerOnce()
		self:syncWorldMapVisibility()
		self:applyAlwaysOnTopState()

		local forceWakeForTreatmentMode =
			onlyShowTreatmentNeeded == true
			and self.needsTreatment == true

		if self.forceVisibleForBCIAttention or forceWakeForTreatmentMode then
			self.hideTimer = math.max(self.hideTimer or 0, 16)
			MHP_SoftWakePanel(self, 0.55)
		end

		return
	end

	if shouldShowIdleAvatar then
		self.bciTransitionTimer = 0
		self.forceVisibleForBCIAttention = false
		self.hiddenForWorldMap = false
		self:setAlwaysOnTop(false)
		self:setVisible(false)
		self:removeFromUIManager()

		MHP_OpenBCIIdleAvatar(self.playerIndex, self.player, self)
		return
	end

	MHP_CloseBCIIdleAvatar(self.playerIndex, bciIdleActive == true)

	if self.settingsPanel and self.settingsPanel:getOpen() then
		self.settingsPanel:setOpen(false, 0, 0, 0)
	end

	self.forceVisibleForBCIAttention = false
	self.hiddenForWorldMap = false
	self:setAlwaysOnTop(false)
	self:setVisible(false)
	self:removeFromUIManager()
end

function MHPPanel:onModOptionsApply(enabled)
	self:refreshGameModOptionVisibility(enabled, self.onlyShowTreatmentNeeded)
end

function MHPPanel:initConfig()
	local isFirstRun = self:readConfig() == true

	if isFirstRun then
		self.alwaysShow = true
		self.hideTimer = 10
		self.alpha = 1.0

		self:applyLayout()
		self:centerOnScreen()
		self:writeConfig(true)
	end

	self:syncWorldMapVisibility()
	self:applyAlwaysOnTopState()
end

function MHPPanel:readConfig()
	local function parseBool(value)
		if value == "true" then
			return true
		elseif value == "false" then
			return false
		end
		return nil
	end

	local fileStream, readLine, splitLine, failed, readConfigVersion
	failed = true
	readConfigVersion = false

	local loadedX = nil
	local loadedY = nil
	local loadedScale = nil

	fileStream = getFileReader(MHP_CONFIG_FILE, true)
	if fileStream ~= nil then
		print("ISMiniHealth(): config file for reading...")
		readLine = fileStream:readLine()

		if readLine ~= nil then
			failed = false

			while readLine ~= nil do
				splitLine = string.split(readLine, "=")
				if splitLine ~= nil and #splitLine == 2 then
					local key = splitLine[1]
					local value = splitLine[2]

					if not readConfigVersion then
						if key == "CONFIG_VERSION" and tonumber(value) == self.CONFIG_VERSION then
							readConfigVersion = true
							print("ISMiniHealth(): Read CONFIG_VERSION as current version:", value, self.CONFIG_VERSION)
						else
							print("ISMiniHealth(): Read CONFIG_VERSION as incorrect version:", value, self.CONFIG_VERSION)
							failed = true
							break
						end
					else
						if key == "pos_x" then
							loadedX = tonumber(value)

						elseif key == "pos_y" then
							loadedY = tonumber(value)

						elseif key == "alwaysOnTopUI" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.alwaysOnTopUI = parsed
							end

						elseif key == "alwaysShow" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.alwaysShow = parsed
							end

						elseif key == "showHpBar" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.showHpBar = parsed
							end

						elseif key == "showStrains" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.showStrains = parsed
							end

						elseif key == "moveWithMouse" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.moveWithMouse = parsed
							end

						elseif key == "showHoverBackground" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.showHoverBackground = parsed
							end

						elseif key == "showBCIAvatarOnIdle" then
							local parsed = parseBool(value)
							if parsed ~= nil then
								self.showBCIAvatarOnIdle = parsed
							end

						elseif key == "blinkStyle" then
							self:setBlinkStyle(value)

						elseif key == "blinkSpeed" then
							self:setBlinkSpeed(value)

						elseif key == "uiScale" then
							loadedScale = tonumber(value)
						end
					end
				else
					print("ISMiniHealth(): Could not parse line: ", splitLine)
				end

				readLine = fileStream:readLine()
			end
		else
			print("ISMiniHealth():: Failed to read config file...")
		end

		fileStream:close()
		print("ISMiniHealth(): Closed config file.")
	else
		print("ISMiniHealth(): Failed to open config file for reading...")
	end

	if loadedScale == nil or loadedScale < 0.5 or loadedScale > 2.0 then
		loadedScale = 1.0
	end

	self.uiScale = loadedScale
	self:applyLayout()

	if loadedX ~= nil then
		self:setX(loadedX)
	end

	if loadedY ~= nil then
		self:setY(loadedY)
	end

	self:checkNewResolution()
	self.lastWrittenConfig = nil
	return failed
end

function MHPPanel:buildConfigString()
	return table.concat({
		"CONFIG_VERSION=" .. tostring(self.CONFIG_VERSION) .. "\n",
		"pos_x=" .. tostring(self:getX()) .. "\n",
		"pos_y=" .. tostring(self:getY()) .. "\n",
		"alwaysOnTopUI=" .. tostring(self.alwaysOnTopUI == true) .. "\n",
		"alwaysShow=" .. tostring(self.alwaysShow == true) .. "\n",
		"showHpBar=" .. tostring(self.showHpBar == true) .. "\n",
		"showStrains=" .. tostring(self.showStrains == true) .. "\n",
		"moveWithMouse=" .. tostring(self.moveWithMouse == true) .. "\n",
		"showHoverBackground=" .. tostring(self.showHoverBackground == true) .. "\n",
		"showBCIAvatarOnIdle=" .. tostring(self.showBCIAvatarOnIdle == true) .. "\n",
		"uiScale=" .. tostring(self.uiScale) .. "\n",
		"blinkStyle=" .. tostring(self.blinkStyle or "pulse") .. "\n",
		"blinkSpeed=" .. tostring(MHP_ClampBlinkSpeed(self.blinkSpeed)) .. "\n"
	})
end

function MHPPanel:writeConfig(force)
	local configText = self:buildConfigString()

	if force ~= true and self.lastWrittenConfig == configText then
		return true
	end

	local fileStream = getFileWriter(MHP_CONFIG_FILE, true, false)
	if fileStream == nil then
		return false
	end

	fileStream:write(configText)
	fileStream:close()

	self.lastWrittenConfig = configText
	return true
end