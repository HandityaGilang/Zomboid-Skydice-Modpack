local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")

local FaceManager_Local = {}

FaceManager_Local.modversion = 2

local function _safeField(obj, key, default)
	if obj == nil then return default end
	local ok, value = pcall(function() return obj[key] end)
	if ok and value ~= nil then return value end
	return default
end

local function _isJavaList(value)
	if value == nil then return false end
	return type(value) ~= "table" and type(value.size) == "function" and type(value.get) == "function"
end

local function _toPlainFace(face)
	if face == nil then
		return { name = "DefaultFace", id = "", texture = 0 }
	end

	local name = _safeField(face, "name", "DefaultFace")
	local id = _safeField(face, "id", "")
	local texture = tonumber(_safeField(face, "texture", 0)) or 0

	if not name or name == "" then
		name = "DefaultFace"
	end

	if name == "DefaultFace" or id == "DefaultFace" then
		id = ""
	end

	if id == nil then
		id = ""
	end

	return {
		name = name,
		id = id,
		texture = texture,
	}
end

local function _toPlainBodyDetailList(details)
	local result = {}
	if details == nil then return result end

	if _isJavaList(details) then
		for i = 0, details:size() - 1 do
			local entry = details:get(i)
			local name = _safeField(entry, "name", nil)
			local id = _safeField(entry, "id", nil)
			if name and id then
				result[#result + 1] = {
					name = name,
					id = id,
					texture = tonumber(_safeField(entry, "texture", 0)) or 0,
				}
			end
		end
		return result
	end

	if type(details) == "table" then
		for _, entry in pairs(details) do
			if entry ~= nil then
				local name = _safeField(entry, "name", nil)
				local id = _safeField(entry, "id", nil)
				if name and id then
					result[#result + 1] = {
						name = name,
						id = id,
						texture = tonumber(_safeField(entry, "texture", 0)) or 0,
					}
				end
			end
		end
	end

	return result
end

local function _sandbox()
	return SandboxVars and SandboxVars.SPNCharCustom or {}
end

local function _createGrowTimer()
	local sandbox = _sandbox()
	return {
		stubbleHead = (sandbox.StubbleHeadGrowth or 0) * 24,
		stubbleBeard = (sandbox.StubbleBeardGrowth or 0) * 24,
		bodyHair = (sandbox.BodyHairGrowth or 0) * 24,
	}
end

local function _getData(player)
	if not player then return nil end
	local moddata = player:getModData()
	if not moddata.SPNCharCustom then
		return FaceManager_Local.CreatePlayerData(player)
	end
	return moddata.SPNCharCustom
end

function FaceManager_Local.SetPlayerFace(player, name, id, texture, sendData)
	FaceManager_Local.RemovePlayerFace(player, false)
	if name == "DefaultFace" or id == "" then return nil end

	local item = FaceManager_Local.AddItem(player, id, texture)
	FaceManager_Local.SetDataValue(player, "face", { name = name, id = id, texture = texture }, sendData)
	return item
end

function FaceManager_Local.RemovePlayerFace(player, sendData)
	FaceManager_Local.RemoveWornItemsWithTag(player, SPNCC.ItemTag.Face)
	FaceManager_Local.SetDataValue(player, "face", { name = "DefaultFace", id = "", texture = 0 }, sendData)
end

function FaceManager_Local.AddPlayerBodyDetail(player, name, id, texture, setData)
	local item = FaceManager_Local.AddItem(player, id, texture)
	local data = _getData(player)
	if setData and data then
		data.bodyDetails = _toPlainBodyDetailList(data.bodyDetails)
		data.bodyDetails[#data.bodyDetails + 1] = {
			name = name,
			id = id,
			texture = texture,
		}
	end
	return item
end

function FaceManager_Local.SetPlayerBodyDetails(player, details, sendData)
	local plainDetails = _toPlainBodyDetailList(details)
	FaceManager_Local.ClearPlayerBodyDetails(player, false)

	for _, v in ipairs(plainDetails) do
		FaceManager_Local.AddPlayerBodyDetail(player, v.name, v.id, v.texture, false)
	end

	FaceManager_Local.SetDataValue(player, "bodyDetails", plainDetails, sendData)
end

function FaceManager_Local.ClearPlayerBodyDetails(player, sendData)
	FaceManager_Local.RemoveWornItemsWithTag(player, SPNCC.ItemTag.BodyDetail)
	FaceManager_Local.SetDataValue(player, "bodyDetails", {}, sendData)
end

function FaceManager_Local.AddPlayerStubble(player, isBeard, sendData)
	FaceManager_Local.SetPlayerStubble(player, isBeard, false, sendData)
end

function FaceManager_Local.RemovePlayerStubble(player, isBeard, sendData)
	FaceManager_Local.SetPlayerStubble(player, isBeard, true, sendData)
end

function FaceManager_Local.SetPlayerStubble(player, isBeard, isRemove, sendData)
	local id = ""
	local bodylocation = nil
	local key = ""

	if isBeard then
		id = SPNCC_Data.StubbleBeard
		bodylocation = SPNCC.ItemBodyLocation.StubbleBeard
		key = "stubbleBeard"
	else
		id = SPNCC_Data.StubbleHead
		bodylocation = SPNCC.ItemBodyLocation.StubbleHead
		key = "stubbleHead"
	end

	FaceManager_Local.SetDataValue(player, key, not isRemove, sendData)

	if isRemove then
		FaceManager_Local.RemoveItemAtBodyLocation(player, bodylocation)
	else
		FaceManager_Local.AddItem(player, id, player:getHumanVisual():getSkinTextureIndex())
	end
end

function FaceManager_Local.AddPlayerBodyHair(player, sendData)
	local id = player:isFemale() and SPNCC_Data.BodyHair[2] or SPNCC_Data.BodyHair[1]
	FaceManager_Local.AddItem(player, id, player:getHumanVisual():getSkinTextureIndex())
	FaceManager_Local.SetDataValue(player, "bodyHair", true, sendData)
end

function FaceManager_Local.RemovePlayerBodyHair(player, sendData)
	FaceManager_Local.RemoveItemAtBodyLocation(player, SPNCC.ItemBodyLocation.BodyHair)
	FaceManager_Local.SetDataValue(player, "bodyHair", false, sendData)
end

function FaceManager_Local.SetPlayerMuscle(player)
	local data = _getData(player)
	if data == nil then return end

	FaceManager_Local.RemovePlayerMuscle(player)

	local level = player:getPerkLevel(Perks.Strength)
	local muscleLevel = FaceManager_Shared.GetMuscleLevel(level)

	if muscleLevel ~= 0 and data.muscleVisuals then
		FaceManager_Local.AddPlayerMuscle(player, muscleLevel)
	end
end

function FaceManager_Local.AddPlayerMuscle(player, muscleLevel)
	if muscleLevel <= 0 then return nil end

	local id = player:isFemale() and SPNCC_Data.Muscle[2] or SPNCC_Data.Muscle[1]

	local textureOffset = 0
	if muscleLevel == 2 then
		textureOffset = 5
	end

	local texture = player:getHumanVisual():getSkinTextureIndex() + textureOffset
	return FaceManager_Local.AddItem(player, id, texture)
end

function FaceManager_Local.RemovePlayerMuscle(player)
	FaceManager_Local.RemoveItemAtBodyLocation(player, SPNCC.ItemBodyLocation.Muscle)
end

function FaceManager_Local.SyncBlood(player)
	local itemsWithBlood = FaceManager_Shared.GetWornItemsWithTag(player, SPNCC.ItemTag.CanHaveBlood)
	if #itemsWithBlood == 0 then return end

	local playerVisual = player:getVisual()
	for _, item in ipairs(itemsWithBlood) do
		FaceManager_Shared.AddBloodAndDirtToItem(item:getVisual(), playerVisual)
		item:synchWithVisual()
	end

	FaceManager_Local.OnClothingUpdated(player)
end

function FaceManager_Local.SetDataValue(player, key, value, sendData)
	local data = _getData(player)
	if not data then return end
	data[key] = value
end

function FaceManager_Local.CreatePlayerData(player)
	local moddata = player:getModData()
	moddata.SPNCharCustom = {}
	local data = moddata.SPNCharCustom

	local sandbox = _sandbox()

	data.version = FaceManager_Local.modversion
	data.hasCustomised = false
	data.face = { name = "DefaultFace", id = "", texture = 0 }
	data.bodyDetails = {}
	data.bodyHair = false
	data.stubbleHead = false
	data.stubbleBeard = false
	data.muscleVisuals = sandbox.MuscleVisuals ~= 2
	data.bodyHairGrowthEnabled = sandbox.BodyHairGrowthEnabled ~= 2
	data.GrowTimer = _createGrowTimer()

	return data
end

function FaceManager_Local.SetCustomisation(player, clientData)
	local data = _getData(player)
	if not data then return end

	clientData = clientData or {}

	data.hasCustomised = true
	data.face = _toPlainFace(clientData.face)
	data.bodyDetails = _toPlainBodyDetailList(clientData.bodyDetails)
	data.muscleVisuals = (clientData.muscleVisuals ~= false)
	data.bodyHairGrowthEnabled = (clientData.bodyHairGrowth == true)

	FaceManager_Local.RefreshCustomisation(player)
end

function FaceManager_Local.SetCustomisationNewCharacter(player, clientData)
	local data = FaceManager_Local.CreatePlayerData(player)
	clientData = clientData or {}

	data.hasCustomised = true
	data.face = _toPlainFace(clientData.face)
	data.bodyDetails = _toPlainBodyDetailList(clientData.bodyDetails)
	data.bodyHair = (clientData.bodyHair == true)
	data.stubbleHead = (clientData.stubbleHead == true)
	data.stubbleBeard = (clientData.stubbleBeard == true)
	data.muscleVisuals = (clientData.muscleVisuals ~= false)
	data.bodyHairGrowthEnabled = (clientData.bodyHairGrowth == true)
	data.GrowTimer = _createGrowTimer()

	FaceManager_Local.RefreshCustomisation(player)
end

function FaceManager_Local.RefreshCustomisation(player)
	local data = _getData(player)
	if not data then return end

	data.face = _toPlainFace(data.face)
	data.bodyDetails = _toPlainBodyDetailList(data.bodyDetails)
	data.muscleVisuals = (data.muscleVisuals ~= false)
	data.bodyHair = (data.bodyHair == true)
	data.stubbleHead = (data.stubbleHead == true)
	data.stubbleBeard = (data.stubbleBeard == true)
	data.bodyHairGrowthEnabled = (data.bodyHairGrowthEnabled == true)
	data.GrowTimer = data.GrowTimer or _createGrowTimer()

	FaceManager_Local.SetPlayerMuscle(player)
	FaceManager_Local.SetPlayerFace(player, data.face.name, data.face.id, data.face.texture, false)
	FaceManager_Local.SetPlayerBodyDetails(player, data.bodyDetails, false)

	FaceManager_Local.RemoveItemAtBodyLocation(player, SPNCC.ItemBodyLocation.BodyHair)
	FaceManager_Local.RemoveItemAtBodyLocation(player, SPNCC.ItemBodyLocation.StubbleBeard)
	FaceManager_Local.RemoveItemAtBodyLocation(player, SPNCC.ItemBodyLocation.StubbleHead)

	if data.stubbleBeard then
		FaceManager_Local.AddPlayerStubble(player, true, false)
	end
	if data.stubbleHead then
		FaceManager_Local.AddPlayerStubble(player, false, false)
	end
	if data.bodyHair then
		FaceManager_Local.AddPlayerBodyHair(player, false)
	end

	FaceManager_Local.SyncRemoveCustomisation(player)
	FaceManager_Local.OnClothingUpdated(player)
end

function FaceManager_Local.OnPlayerJoin(player)
	local data = player:getModData().SPNCharCustom
	local isNewCharacter = (data == nil) or (not data.hasCustomised)

	if not isNewCharacter then
		FaceManager_Local.CheckData(player, data)
	else
		data = FaceManager_Local.CreatePlayerData(player)

		local visual = player:getHumanVisual()
		if visual then
			if visual:getBodyHairIndex() == 0 then
				visual:setBodyHairIndex(-1)
				data.bodyHair = true
			end

			if visual:hasBodyVisualFromItemType("Base.F_Hair_Stubble") or visual:hasBodyVisualFromItemType("Base.M_Hair_Stubble") then
				visual:removeBodyVisualFromItemType("Base.F_Hair_Stubble")
				visual:removeBodyVisualFromItemType("Base.M_Hair_Stubble")
				data.stubbleHead = true
			end

			if visual:hasBodyVisualFromItemType("Base.M_Beard_Stubble") then
				visual:removeBodyVisualFromItemType("Base.M_Beard_Stubble")
				data.stubbleBeard = true
			end
		end
	end

	FaceManager_Local.RefreshCustomisation(player)

	if isNewCharacter then
		FaceManager_Shared.OpenCharacterCustomisationWindow(player, true)
	end
end

function FaceManager_Local.ConvertData(player, data)
	if data.version == 1 and data.GrowTimer then
		data.GrowTimer.stubbleHead = (data.GrowTimer.stubbleHead or 0) * 24
		data.GrowTimer.stubbleBeard = (data.GrowTimer.stubbleBeard or 0) * 24
		data.GrowTimer.bodyHair = (data.GrowTimer.bodyHair or 0) * 24
	end

	data.face = _toPlainFace(data.face)
	data.bodyDetails = _toPlainBodyDetailList(data.bodyDetails)
	data.bodyHair = (data.bodyHair == true)
	data.stubbleHead = (data.stubbleHead == true)
	data.stubbleBeard = (data.stubbleBeard == true)
	data.muscleVisuals = (data.muscleVisuals ~= false)
	data.bodyHairGrowthEnabled = (data.bodyHairGrowthEnabled == true)
	data.GrowTimer = data.GrowTimer or _createGrowTimer()
	data.version = FaceManager_Local.modversion
end

function FaceManager_Local.CheckData(player, data)
	local sandbox = _sandbox()

	if sandbox.MuscleVisuals ~= 3 then
		data.muscleVisuals = sandbox.MuscleVisuals == 1
	end

	if sandbox.BodyHairGrowthEnabled ~= 3 then
		data.bodyHairGrowthEnabled = sandbox.BodyHairGrowthEnabled == 1
	end

	if data.version ~= FaceManager_Local.modversion then
		FaceManager_Local.ConvertData(player, data)
	end

	data.face = _toPlainFace(data.face)
	data.bodyDetails = _toPlainBodyDetailList(data.bodyDetails)
	data.bodyHair = (data.bodyHair == true)
	data.stubbleHead = (data.stubbleHead == true)
	data.stubbleBeard = (data.stubbleBeard == true)
	data.muscleVisuals = (data.muscleVisuals ~= false)
	data.bodyHairGrowthEnabled = (data.bodyHairGrowthEnabled == true)
	data.GrowTimer = data.GrowTimer or _createGrowTimer()

	local growTimer = data.GrowTimer
	local math_min = math.min

	growTimer.stubbleHead = math_min(growTimer.stubbleHead or 0, (sandbox.StubbleHeadGrowth or 0) * 24)
	growTimer.stubbleBeard = math_min(growTimer.stubbleBeard or 0, (sandbox.StubbleBeardGrowth or 0) * 24)
	growTimer.bodyHair = math_min(growTimer.bodyHair or 0, (sandbox.BodyHairGrowth or 0) * 24)
end

function FaceManager_Local.AddItem(player, id, texture)
	local item = FaceManager_Shared.CreateItem(id, texture)
	if not item then return nil end

	local bodyLocation = item:getBodyLocation()
	if (bodyLocation == nil or bodyLocation == "") and item:getScriptItem() and item:getScriptItem().getBodyLocation then
		bodyLocation = item:getScriptItem():getBodyLocation()
	end
	if bodyLocation == nil or bodyLocation == "" then
		print("[SPNCC Override] Local AddItem aborted: missing BodyLocation for item " .. tostring(id))
		return nil
	end

	FaceManager_Shared.SyncBloodOnNewItem(player, item)
	player:getInventory():AddItem(item)

	local ok = pcall(function()
		player:setWornItem(bodyLocation, item)
	end)

	if not ok then
		player:getInventory():Remove(item)
		print("[SPNCC Override] Local AddItem aborted: failed to wear item " .. tostring(id) .. " at BodyLocation " .. tostring(bodyLocation))
		return nil
	end

	return item
end

function FaceManager_Local.RemoveItem(player, item)
	if not item then return end
	player:getWornItems():remove(item)
	player:getInventory():Remove(item)
end

function FaceManager_Local.OnClothingUpdated(player)
	triggerEvent("OnClothingUpdated", player)
	player:resetModel()
end

function FaceManager_Local.SyncRemoveCustomisation(player)
	return
end

function FaceManager_Local.RemoveItems(player, items)
	if not items then return end
	for _, item in pairs(items) do
		FaceManager_Local.RemoveItem(player, item)
	end
end

function FaceManager_Local.RemoveItemsWithTag(player, tag)
	local items = FaceManager_Shared.GetInventoryItemsWithTag(player, tag)
	FaceManager_Local.RemoveItems(player, items)
end

function FaceManager_Local.RemoveWornItemsWithTag(player, tag)
	local items = FaceManager_Shared.GetWornItemsWithTag(player, tag)
	FaceManager_Local.RemoveItems(player, items)
end

function FaceManager_Local.RemoveItemAtBodyLocation(player, location)
	local item = player:getWornItem(location)
	FaceManager_Local.RemoveItem(player, item)
end

return FaceManager_Local