local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

local BloodWasJustSynced = false
local pending = false
local pendingTicks = 0

local function _safeGetBlood(visual, part)
    local ok, value = pcall(function()
        return visual:getBlood(part)
    end)
    if not ok or value == nil then return 0 end
    return tonumber(value) or 0
end

local function _safeGetDirt(visual, part)
    local ok, value = pcall(function()
        return visual:getDirt(part)
    end)
    if not ok or value == nil then return 0 end
    return tonumber(value) or 0
end

local function _visualsNeedBloodSync(itemVisual, playerVisual)
    if not itemVisual or not playerVisual then return false end
    if not BloodBodyPartType or not BloodBodyPartType.MAX then return false end

    local maxIndex = BloodBodyPartType.MAX:index()
    for idx = 0, maxIndex - 1 do
        local part = BloodBodyPartType.FromIndex(idx)

        if math.abs(_safeGetBlood(itemVisual, part) - _safeGetBlood(playerVisual, part)) > 0.001 then
            return true
        end

        if math.abs(_safeGetDirt(itemVisual, part) - _safeGetDirt(playerVisual, part)) > 0.001 then
            return true
        end
    end

    return false
end

local function _needsBloodSync(player)
    if not player then return false end

    local playerVisual = FaceManager_Shared.GetBloodAndDirtVisual(player)
    if not playerVisual then return false end

    local itemsWithBlood = FaceManager_Shared.GetWornBloodSyncItems(player)
    if not itemsWithBlood or #itemsWithBlood == 0 then return false end

    for _, item in ipairs(itemsWithBlood) do
        local itemVisual = item and item.getVisual and item:getVisual() or nil

        if _visualsNeedBloodSync(itemVisual, playerVisual) then
            return true
        end
    end

    return false
end

local function _runSync()
    pending = false
    pendingTicks = 0

    local player = getPlayer()
    if not player then return end

    if not _needsBloodSync(player) then
        return
    end

    if _useLocalSingleplayerPath() then
        BloodWasJustSynced = true
        FaceManager_Local.SyncBlood(player)
    else
        sendClientCommand(player, "SPNCC", "SyncBlood", {})
    end
end

local function _tick()
	if not pending then
		Events.OnPlayerUpdate.Remove(_tick)
		return
	end

	pendingTicks = pendingTicks - 1
	if pendingTicks > 0 then return end

	Events.OnPlayerUpdate.Remove(_tick)
	_runSync()
end

local function SyncBloodOnClothingUpdated(player)
    local localPlayer = getPlayer()
    if not player or not localPlayer then return end

    if player ~= localPlayer then
        return
    end

    if BloodWasJustSynced then
        BloodWasJustSynced = false
        return
    end

    if pending then return end

    pending = true
    pendingTicks = 10
    Events.OnPlayerUpdate.Add(_tick)
end

Events.OnClothingUpdated.Add(SyncBloodOnClothingUpdated)