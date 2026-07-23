local FaceManager_Server = require("CharacterCustomisation/FaceManager_Server")
local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

local function _getFaceManager()
	if _useLocalSingleplayerPath() then
		return FaceManager_Local
	end
	return FaceManager_Server
end

local function doBodyHair(player, data, manager)
	if data.bodyHair or not data.bodyHairGrowthEnabled or data.GrowTimer.bodyHair == 0 then return false end

	data.GrowTimer.bodyHair = data.GrowTimer.bodyHair - 1

	if data.GrowTimer.bodyHair <= 0 then
		manager.AddPlayerBodyHair(player)
		data.GrowTimer.bodyHair = SandboxVars.SPNCharCustom.BodyHairGrowth * 24
	end
end

local function doHeadStubble(player, data, manager)
	if data.stubbleHead or not data.bodyHairGrowthEnabled or data.GrowTimer.stubbleHead == 0 then return false end

	data.GrowTimer.stubbleHead = data.GrowTimer.stubbleHead - 1

	if data.GrowTimer.stubbleHead <= 0 then
		manager.AddPlayerStubble(player, false)
		data.GrowTimer.stubbleHead = SandboxVars.SPNCharCustom.StubbleHeadGrowth * 24
	end
end

local function doBeardStubble(player, data, manager)
	if player:isFemale() or data.stubbleBeard or not data.bodyHairGrowthEnabled or data.GrowTimer.stubbleBeard == 0 then return false end

	data.GrowTimer.stubbleBeard = data.GrowTimer.stubbleBeard - 1

	if data.GrowTimer.stubbleBeard <= 0 then
		manager.AddPlayerStubble(player, true)
		data.GrowTimer.stubbleBeard = SandboxVars.SPNCharCustom.StubbleBeardGrowth * 24
	end
end

local function GrowPlayerBodyHair(player, manager)
	if not player or player:isDead() then return end

	local data = player:getModData().SPNCharCustom
	if not data then
		print(player:getUsername() .. " does not have data")
		return
	end

	doBodyHair(player, data, manager)
	doHeadStubble(player, data, manager)
	doBeardStubble(player, data, manager)
end

local function EveryHours()
	if isClient() then return end

	local manager = _getFaceManager()

	if not isServer() then
		GrowPlayerBodyHair(getPlayer(), manager)
		return
	end

	local players = getOnlinePlayers()
	if players:isEmpty() then return end

	for i = 0, players:size() - 1 do
		GrowPlayerBodyHair(players:get(i), manager)
	end
end

Events.EveryHours.Add(EveryHours)