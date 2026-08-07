require "TimedActions/ISBaseTimedAction"

UpdateTerminal = ISBaseTimedAction:derive("UpdateTerminal")

function UpdateTerminal:isValid()
	return true
end

function UpdateTerminal:waitToStart()
	self.character:faceThisObject(self.terminal)
	return self.character:shouldBeTurning()
end

function UpdateTerminal:update()
	self.character:faceThisObject(self.terminal)
end

function UpdateTerminal:start()
	self:setOverrideHandModels(nil, nil)
end

function UpdateTerminal:stop()
	ISBaseTimedAction.stop(self)
end

function UpdateTerminal:perform()
	ISBaseTimedAction.perform(self)
end

function UpdateTerminal:complete()
	local index = self.terminal:getObjectIndex()
	local stationControl = self.terminal:getModData()['StationControl']
	local thisSquare = self.terminal:getSquare()
	local spr = self.terminal:getSprite():getName()  
	sledgeDestroy(self.terminal)
	self.terminal:getSquare():transmitRemoveItemFromSquare(self.terminal)            

	self.terminal = IsoThumpable.new(getCell(), thisSquare, spr, false, ISWoodenContainer:new(spr, nil))  
	self.terminal:setIsContainer(true)
	self.terminal:getContainer():setType("securityterminal")
	self.terminal:getContainer():setCapacity(50)
	self.terminal:getModData()['StationControl'] = stationControl
	
	thisSquare:transmitAddObjectToSquare(self.terminal, index)
	thisSquare:transmitModdata()

	local tempGlobalPlaylist = {}
	for k,v in pairs(GlobalMusic) do
		tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
	end

	local maxMusic = SandboxVars.TrueMusicRadio.TMRMusicTerminalFilledAmount

	if maxMusic == 6 then
		maxMusic = 0
		self.terminal:getModData()['LoadedCapacity'] = 0
	elseif maxMusic == 5 then
		maxMusic = ZombRand(1,111)
		self.terminal:getModData()['LoadedCapacity'] = ZombRand(1,111)
	elseif maxMusic == 4 then
		maxMusic = ZombRand(75,111)
		self.terminal:getModData()['LoadedCapacity'] = ZombRand(75,111)
	elseif maxMusic == 3 then
		maxMusic = ZombRand(25,75)
		self.terminal:getModData()['LoadedCapacity'] = ZombRand(25,75)
	elseif maxMusic == 2 then
		maxMusic = ZombRand(10,25)
		self.terminal:getModData()['LoadedCapacity'] = ZombRand(10,25)
	elseif maxMusic == 1 then
		maxMusic = ZombRand(1,10)
		self.terminal:getModData()['LoadedCapacity'] = ZombRand(1,10)
	end
				
	local canEject = SandboxVars.TrueMusicRadio.TMRTerminalEjectsMusic
	if not canEject then
		self.terminal:getModData()['LoadedCapacity'] = 0
	end
	self.terminal:transmitModData()

	local musicItems = 0
	while musicItems < maxMusic do
		local musicItem = "Tsarcraft." .. tempGlobalPlaylist[ZombRand(1, #tempGlobalPlaylist+1)]
		local addItem = instanceItem(musicItem)
		self.terminal:getContainer():AddItem(addItem)
		sendAddItemToContainer(self.terminal:getContainer(), addItem)
		musicItems = musicItems + 1
	end

	self.terminal:sync()
	return true
end

function UpdateTerminal:new(character, terminal)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.terminal = terminal
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 10
	return o
end