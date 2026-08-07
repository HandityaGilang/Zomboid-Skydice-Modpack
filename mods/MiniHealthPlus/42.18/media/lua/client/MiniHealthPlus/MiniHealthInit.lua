require "MiniHealthPlus/MHP_ModOptions"
require "MiniHealthPlus/ISMiniHealth"
require "MiniHealthPlus/MiniHealthTreatments"

TwisTonFire_MHP = TwisTonFire_MHP or {}
local MHP = TwisTonFire_MHP
local MHPPanel = MHP.MiniHealthPanel or MHP.ISMiniHealth
local MiniHealthTreatment = MHP.MiniHealthTreatment

local mhpHandle = nil

-- Performance throttle state
local MHP_UpdateTick = 0

local MHP_HEALTH_UPDATE_INTERVAL = 8
local MHP_VISIBILITY_REFRESH_INTERVAL = 8
local MHP_BCI_IDLE_REFRESH_INTERVAL = 8
local MHP_MAP_VISIBILITY_INTERVAL = 12
local MHP_OPTIONS_SAFETY_INTERVAL = 120

local MHP_LastBCIIdleRefreshTick = -9999
local MHP_LastHealthUpdateTick = -9999
local MHP_LastVisibilityRefreshTick = -9999
local MHP_LastMapVisibilityTick = -9999
local MHP_LastOptionsApplyTick = -9999

local MHP_OptionsDirty = true
local MHP_ForceFullRefresh = true

local function MHP_ShouldRun(lastTick, interval, force)
    return force or ((MHP_UpdateTick - lastTick) >= interval)
end

local function isBCIIdleActiveForCurrentPanel()
	if mhpHandle == nil or mhpHandle.showBCIAvatarOnIdle ~= true then
		return false
	end

	return type(TwisTonFire_MHP_IsBetterCharacterInfoActive) == "function"
		and TwisTonFire_MHP_IsBetterCharacterInfoActive() == true
end

local function isMiniHealthEnabled()
	if type(TwisTonFire_MHP_IsDisabled) == "function" then
		return TwisTonFire_MHP_IsDisabled() ~= true
	end
	return true
end

local function shouldOnlyShowTreatmentNeeded()
	if type(TwisTonFire_MHP_ShouldOnlyShowTreatmentNeeded) == "function" then
		return TwisTonFire_MHP_ShouldOnlyShowTreatmentNeeded() == true
	end
	return false
end

local function playerNeedsTreatment(playerObj)
	if MHPPanel and MHPPanel.playerNeedsTreatment then
		return MHPPanel.playerNeedsTreatment(playerObj) == true
	end
	return true
end

local function applyGameModOptions(force, visibilityRefresh)
	if mhpHandle == nil then
		return false
	end

	force = force == true
	visibilityRefresh = visibilityRefresh == true

	local safetyRefresh = MHP_ShouldRun(MHP_LastOptionsApplyTick, MHP_OPTIONS_SAFETY_INTERVAL, false)
	local optionsRefresh = force or MHP_OptionsDirty or safetyRefresh

	if not optionsRefresh and not visibilityRefresh then
		return false
	end

	mhpHandle:refreshGameModOptionVisibility(
		isMiniHealthEnabled(),
		shouldOnlyShowTreatmentNeeded()
	)

	if optionsRefresh then
		MHP_OptionsDirty = false
		MHP_LastOptionsApplyTick = MHP_UpdateTick
	end

	return true
end

function TwisTonFire_MHP_RequestFullRefresh()
	MHP_OptionsDirty = true
	MHP_ForceFullRefresh = true
end

function MHP_RequestFullRefresh()
	TwisTonFire_MHP_RequestFullRefresh()
end

function TwisTonFire_MHP_RefreshModOptions()
	TwisTonFire_MHP_RequestFullRefresh()
	applyGameModOptions(true)

	if mhpHandle ~= nil and mhpHandle.syncWorldMapVisibility then
		mhpHandle:syncWorldMapVisibility()
	end
end

local function ensureMiniHealthForPlayer(playerObj)
	if not playerObj then
		return
	end

	local force = MHP_ForceFullRefresh == true
	local enabled = isMiniHealthEnabled()

	if not enabled then
		applyGameModOptions(force)
		return
	end

	local idx = playerObj:getPlayerNum()
	local createdOrChanged = false

	if mhpHandle == nil then
		if MiniHealthTreatment and MiniHealthTreatment.restoreOwnContextMenu then
			MiniHealthTreatment.restoreOwnContextMenu()
		end

		mhpHandle = MHPPanel:new(idx, playerObj, true)
		MHP.handle = mhpHandle
		mhpHandle:initialize()
		mhpHandle:instantiate()
		mhpHandle:createChildren()
		mhpHandle:applyLayout()
		mhpHandle:centerOnScreen()
		mhpHandle:initConfig()

		createdOrChanged = true

	elseif mhpHandle:getPlayerIsDead() == true then
		mhpHandle:setPlayer(idx, playerObj)
		createdOrChanged = true

	elseif mhpHandle:getPlayer() ~= playerObj then
		mhpHandle:setPlayer(idx, playerObj)
		createdOrChanged = true
	end

	local bciIdleActive = isBCIIdleActiveForCurrentPanel()

	local fastNormalVisibilityRefresh = false
	local fastBCIIdleVisibilityRefresh = false

	if not bciIdleActive then
		fastNormalVisibilityRefresh = MHP_ShouldRun(
			MHP_LastVisibilityRefreshTick,
			MHP_VISIBILITY_REFRESH_INTERVAL,
			force or createdOrChanged
		)
	else
		fastBCIIdleVisibilityRefresh = MHP_ShouldRun(
			MHP_LastBCIIdleRefreshTick,
			MHP_BCI_IDLE_REFRESH_INTERVAL,
			force or createdOrChanged
		)
	end

	if fastNormalVisibilityRefresh then
		MHP_LastVisibilityRefreshTick = MHP_UpdateTick
	end

	if fastBCIIdleVisibilityRefresh then
		MHP_LastBCIIdleRefreshTick = MHP_UpdateTick
	end

	applyGameModOptions(
		force or createdOrChanged,
		fastNormalVisibilityRefresh or fastBCIIdleVisibilityRefresh
	)
end

local function onCreatePlayer(idx, player)
	TwisTonFire_MHP_RequestFullRefresh()
	ensureMiniHealthForPlayer(player)
end

local function onPlayerDeath(player)
	if mhpHandle ~= nil and player == mhpHandle:getPlayer() then
		mhpHandle:setPlayerIsDead(true)
		TwisTonFire_MHP_RequestFullRefresh()
		applyGameModOptions(true)
	end
end

local function onSave()
	if mhpHandle ~= nil then
		mhpHandle:writeConfig()
	end
end

local function onResolutionChange()
	if mhpHandle ~= nil then
		mhpHandle:checkNewResolution()

		if mhpHandle.syncWorldMapVisibility then
			mhpHandle:syncWorldMapVisibility()
		end
	end
end

local function onPlayerUpdate(player)
	if not player then
		return
	end

	MHP_UpdateTick = MHP_UpdateTick + 1

	local force = MHP_ForceFullRefresh == true

	if MHP_ShouldRun(MHP_LastHealthUpdateTick, MHP_HEALTH_UPDATE_INTERVAL, force) then
		MHP_LastHealthUpdateTick = MHP_UpdateTick
		ensureMiniHealthForPlayer(player)
	end

	if mhpHandle ~= nil
	and mhpHandle.syncWorldMapVisibility
	and MHP_ShouldRun(MHP_LastMapVisibilityTick, MHP_MAP_VISIBILITY_INTERVAL, force) then
		MHP_LastMapVisibilityTick = MHP_UpdateTick
		mhpHandle:syncWorldMapVisibility()
	end

	MHP_ForceFullRefresh = false
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnSave.Add(onSave)
Events.OnResolutionChange.Add(onResolutionChange)
Events.OnPlayerUpdate.Add(onPlayerUpdate)