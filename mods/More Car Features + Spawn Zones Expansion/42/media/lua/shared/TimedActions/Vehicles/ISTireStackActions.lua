ISTireStackActions = ISBaseTimedAction:derive("ISTireStackActions")

function ISTireStackActions:isValid()
	return self.square:getObjectWithSprite(self.name) == self.stack 
		and self.character:getPerkLevel(Perks.Strength) >= 2 
		and ((isClient() and self.character:getInventory():containsID(self.tool:getID())) 
			or self.character:getInventory():contains(self.tool)) 
		and self.tool and not self.tool:isBroken();
end

function ISTireStackActions:waittostart()
	self.character:faceThisObject(self.stack)
	return self.character:shouldBeTurning()
end

function ISTireStackActions:start()
	self:setOverrideHandModels(self.tool, nil)
	self:setActionAnim("SawLog")
end

function ISTireStackActions:update()
	self.character:faceThisObject(self.stack)

	self.tool:setJobDelta(self:getJobDelta())

	self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function ISTireStackActions:stop()
	self.tool:setJobDelta(0.0)

	ISBaseTimedAction.stop(self)
end

function ISTireStackActions:perform()
	self.tool:setJobDelta(0.0)

	ISBaseTimedAction.perform(self)
end

function ISTireStackActions:complete()
	local charInv = self.character:getInventory()
	local removedTirePieces = charInv:AddItems("Base.TirePiece", 4*self.count)
	sendAddItemsToContainer(charInv, removedTirePieces);

	--one of these aughta sync it for MP
	self.square:transmitRemoveItemFromSquare(self.stack)
	self.square:RemoveTileObject(self.stack)
	self.square:removeFromWorld()
	self.square:removeFromSquare()
	self.square:setSquare(nil)
	self.square:RecalcProperties()
	self.square:RecalcAllWithNeighbours(true)

	return true
end

function ISTireStackActions:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end

	return (300 - self.character:getPerkLevel(Perks.Strength) * 10) * self.count
end

local function tireStackCount(name)
	if luautils.stringEnds(name, "_49") or luautils.stringEnds(name, "_48") or 
		luautils.stringEnds(name, "_152") or luautils.stringEnds(name, "_160") then
		return 1
	elseif luautils.stringEnds(name, "_50") or luautils.stringEnds(name, "_40") or luautils.stringEnds(name, "_41") or 
		luautils.stringEnds(name, "_153") or luautils.stringEnds(name, "_161") or 
		luautils.stringEnds(name, "_155") or luautils.stringEnds(name, "_163") or 
		luautils.stringEnds(name, "_154") or luautils.stringEnds(name, "_162") then
		return 2
	elseif luautils.stringEnds(name, "_51") or luautils.stringEnds(name, "_42") or luautils.stringEnds(name, "_43") or 
		luautils.stringEnds(name, "_139") or luautils.stringEnds(name, "_147") or 
		luautils.stringEnds(name, "_141") or luautils.stringEnds(name, "_149") or 
		luautils.stringEnds(name, "_140") or luautils.stringEnds(name, "_148") then
		return 3
	elseif luautils.stringEnds(name, "_52") or luautils.stringEnds(name, "_45") or luautils.stringEnds(name, "_44") or 
		luautils.stringEnds(name, "_136") or luautils.stringEnds(name, "_144") or 
		luautils.stringEnds(name, "_138") or luautils.stringEnds(name, "_146") or 
		luautils.stringEnds(name, "_137") or luautils.stringEnds(name, "_145") then
		return 4
	end
	return 0
end

function ISTireStackActions:new(character, stack, tool)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.tool = tool
	o.stack = stack
	o.square = o.stack:getSquare()
	o.name = o.stack:getTextureName()
	o.count = tireStackCount(o.name)
	o.maxTime = o:getDuration()
	return o
end

--Above is just for getting rubber from these things instead of whole wheels. Maybe combine the 2 into full tire items in the future?
if true then return end
--Unbalance since tire stacks weigh 1/10th of what they should be, need to fix that 
--also commented out "Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.TireStackActions)" in MoreCarFeatures_VehicleUI.lua
--also also moved craftRecipeTireStacks.txt into personal mod backup folder
--also also also leftovers in MISCMoreCarFeatures.lua

local function addTireStackType(name)
	if luautils.stringEnds(name, "_49") then
		return "location_business_machinery_01_50"
	elseif luautils.stringEnds(name, "_48") then
		return "location_business_machinery_01_50"
	elseif luautils.stringEnds(name, "_50") then
		return "location_business_machinery_01_51"
	elseif luautils.stringEnds(name, "_40") then
		return "location_business_machinery_01_42"
	elseif luautils.stringEnds(name, "_41") then
		return "location_business_machinery_01_43"
	elseif luautils.stringEnds(name, "_51") then
		return "location_business_machinery_01_52"
	elseif luautils.stringEnds(name, "_42") then
		return "location_business_machinery_01_45"
	elseif luautils.stringEnds(name, "_43") then
		return "location_business_machinery_01_44"
	elseif luautils.stringEnds(name, "_52") then
		return nil
	elseif luautils.stringEnds(name, "_45") then
		return nil
	elseif luautils.stringEnds(name, "_44") then
		return nil
	end
end

local function takeTireStackType(name)
	if luautils.stringEnds(name, "_49") then
		return nil
	elseif luautils.stringEnds(name, "_48") then
		return nil
	elseif luautils.stringEnds(name, "_50") then
		return "location_business_machinery_01_48"
	elseif luautils.stringEnds(name, "_40") then
		return "location_business_machinery_01_49"
	elseif luautils.stringEnds(name, "_41") then
		return "location_business_machinery_01_48"
	elseif luautils.stringEnds(name, "_51") then
		return "location_business_machinery_01_50"
	elseif luautils.stringEnds(name, "_42") then
		return "location_business_machinery_01_40"
	elseif luautils.stringEnds(name, "_43") then
		return "location_business_machinery_01_41"
	elseif luautils.stringEnds(name, "_52") then
		return "location_business_machinery_01_51"
	elseif luautils.stringEnds(name, "_45") then
		return "location_business_machinery_01_42"
	elseif luautils.stringEnds(name, "_44") then
		return "location_business_machinery_01_43"
	end
end

function ISTireStackActions:isValid()
	local object = self.square:getObjectWithSprite(self.name)
	if object ~= self.stack then
		return false
	end

	local TireStackMD = self.stack:getModData().TireStackContents
	if self.TakeOrAdd == "Add" then
		if not (#TireStackMD < 4) then
			return false
		end
	else
		local tireStillThere = false
		for i = #TireStackMD, 1, -1 do
			if TireStackMD[i][1] == self.tire then
				tireStillThere = true
				break
			end
		end
		if not tireStillThere then
			return false
		end
	end

	return true
end

function ISTireStackActions:waittostart()
	self.character:faceThisObject(self.stack)
	return self.character:shouldBeTurning()
end

function ISTireStackActions:start()
	self:setOverrideHandModels(nil, nil)
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
end

function ISTireStackActions:update()
	self.character:faceThisObject(self.stack)

	if self.TakeOrAdd == "Add" then
		self.tire:setJobDelta(self:getJobDelta())
	end

	self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function ISTireStackActions:stop()
	if self.TakeOrAdd == "Add" then
		self.tire:setJobDelta(0.0)
	end

	ISBaseTimedAction.stop(self)
end

function ISTireStackActions:perform()
	if self.TakeOrAdd == "Add" then
		self.tire:setJobDelta(0.0)
	end

	ISBaseTimedAction.perform(self)
end

function ISTireStackActions:complete()
	if not self.stack then return false end
	local charInv = self.character:getInventory()
	local TireStackMD = self.stack:getModData().TireStackContents
	if self.TakeOrAdd == "Add" then
		local tireToMD = {self.tire:getScriptItem():getFullName(), self.tire:getCondition(), math.max(self.tire:getItemCapacity(), 0), self.tire:getMaxCapacity()}

		self.character:removeFromHands(self.tire)
		charInv:Remove(self.tire)
		sendRemoveItemFromContainer(charInv, self.tire)

		table.insert(self.stack:getModData().TireStackContents, tireToMD)
		TireStackMD = self.stack:getModData().TireStackContents

		self.stack:removeFromWorld()
		self.stack:removeFromSquare()
		self.stack:setSquare(nil)

		local newSpriteName = addTireStackType(self.name)
		self.javaObject = IsoObject.new(self.square, newSpriteName)
		self.javaObject:setSpriteFromName(newSpriteName)
		self.square:AddTileObject(self.javaObject)
		self.javaObject:transmitCompleteItemToClients()
		self.javaObject:getModData().TireStackContents = TireStackMD
		self.javaObject:transmitModData()

	else
		for i = #TireStackMD, 1, -1 do
			if TireStackMD[i][1] == self.tire then
				local removedTire = instanceItem(self.tire)
				removedTire:setCondition(TireStackMD[i][2])
				removedTire:setItemCapacity(TireStackMD[i][3])
				charInv:AddItem(removedTire)
				sendAddItemToContainer(charInv, removedTire)

				table.remove(self.stack:getModData().TireStackContents, i)
				TireStackMD = self.stack:getModData().TireStackContents

				self.stack:removeFromWorld()
				self.stack:removeFromSquare()
				self.stack:setSquare(nil)

				local newSpriteName = takeTireStackType(self.name)
				self.javaObject = IsoObject.new(self.square, newSpriteName)
				self.javaObject:setSpriteFromName(newSpriteName)
				self.square:AddTileObject(self.javaObject)
				self.javaObject:transmitCompleteItemToClients()
				self.javaObject:getModData().TireStackContents = TireStackMD
				self.javaObject:transmitModData()

				break
			end
		end

	end

	return true
end

function ISTireStackActions:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end

	local maxTime = 200 - self.character:getPerkLevel(Perks.Strength) * 10

	if self.TakeOrAdd == "Take" then	--Longer action if tire is lower in the stack, ha ha
		maxTime = maxTime * (#self.stack:getModData().TireStackContents / self.stackOrder)
	end

	if self.character:hasTrait(CharacterTrait.DEXTROUS) then
		maxTime = maxTime / 2
	elseif self.character:hasTrait(CharacterTrait.ALL_THUMBS) or self.character:isWearingAwkwardGloves() then
		maxTime = maxTime * 2
	end

	return maxTime
end

function ISTireStackActions:new(character, stack, tire, TakeOrAdd, stackOrder)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stack = stack
	o.name = stack:getTextureName()
	o.square = stack:getSquare()
	o.tire = tire
	o.TakeOrAdd = TakeOrAdd
	o.stackOrder = stackOrder or 4
	o.maxTime = o:getDuration()
	return o
end


MoreCarFeatures = MoreCarFeatures or {}
function MoreCarFeatures.randomizedTireStackContents(stackType)
	local TireStackMD = {}
	for j=stackType.numTires, 1, -1 do
		local rand = newrandom()
		local tireQualityChance = rand:random(1, 100)
		local tireTypeChance = rand:random(1, 100)
		local tireConditionChance = rand:random(1, 100)
		if stackType.positioning == "M" then	--Neatly Stacked Tires == Better
			tireQualityChance = tireQualityChance + 70
			tireTypeChance = tireTypeChance + 50
			tireConditionChance = math.min(tireConditionChance + 60, 100)
		end
		local tire
		if tireQualityChance < 70 then
			local tireCapacityChance = rand:random(1, 30)
			if tireTypeChance < 50 then
				tire = {"Base.OldTire1", tireConditionChance, tireCapacityChance, 30}
			elseif tireTypeChance < 80 then
				tire = {"Base.OldTire2", tireConditionChance, tireCapacityChance, 30}
			else
				tire = {"Base.OldTire3", tireConditionChance, tireCapacityChance, 30}
			end
		elseif tireQualityChance < 100 then
			local tireCapacityChance = rand:random(1, 35)
			if tireTypeChance < 50 then
				tire = {"Base.NormalTire1", tireConditionChance, tireCapacityChance, 35}
			elseif tireTypeChance < 80 then
				tire = {"Base.NormalTire2", tireConditionChance, tireCapacityChance, 35}
			else
				tire = {"Base.NormalTire3", tireConditionChance, tireCapacityChance, 35}
			end
		else
			local tireCapacityChance = rand:random(1, 40)
			if tireTypeChance < 50 then
				tire = {"Base.ModernTire1", tireConditionChance, tireCapacityChance, 40}
			elseif tireTypeChance < 80 then
				tire = {"Base.ModernTire2", tireConditionChance, tireCapacityChance, 40}
			else
				tire = {"Base.ModernTire3", tireConditionChance, tireCapacityChance, 40}
			end
		end
		table.insert(TireStackMD, tire)
	end
	return TireStackMD
end


if isServer() then
	local function onClientCommand(playerObj, module, command, args)
		if module == 'MoreCarFeatures' and command == 'SyncTireStackMD' then
			if not (args.nameTireStack and args.x and args.y and args.z) then return end
			local square = getCell():getGridSquare(args.x, args.y, args.z)
			if not square then return end
			local object = square:getObjectWithSprite(args.nameTireStack)
			if object and not object:getModData().TireStackContents then
				object:getModData().TireStackContents = MoreCarFeatures.randomizedTireStackContents(stackType)
				object:transmitModData()
			end
		end
	end
	Events.OnClientCommand.Add(onClientCommand)
--elseif isClient() then
--	local function onServerCommand(module, command, args)
--		if module == 'MoreCarFeatures' and command == 'SyncTireStackMD' then
--		end
--	end
--	Events.OnServerCommand.Add(onServerCommand)
end
--print( getPlayer():getSquare():getObjectWithSprite("location_business_machinery_01_48") )
--getPlayer():getInventory():AddItem(instanceItem("Moveables.".."location_business_machinery_01_48"))


local ISMoveableSpritePropsPlaceMoveable = ISMoveableSpriteProps.placeMoveable
function ISMoveableSpriteProps:placeMoveable( _character, _square, _origSpriteName, _forceAllow )
	if _origSpriteName and luautils.stringStarts(_origSpriteName, "location_business_machinery_01") and (_origSpriteName:contains("_4") or _origSpriteName:contains("_5")) then
		local tireStack = self:findInInventory( _character, _origSpriteName )
		local transferMD
		if tireStack then
			transferMD = tireStack:getModData().TireStackContents or {}
		end

		ISMoveableSpritePropsPlaceMoveable(self,  _character, _square, _origSpriteName, _forceAllow )

		local object = _square:getObjectWithSprite(_origSpriteName)
		if object and transferMD then
			object:getModData().TireStackContents = transferMD
			object:transmitModData()
		end

		return
	end

	ISMoveableSpritePropsPlaceMoveable(self,  _character, _square, _origSpriteName, _forceAllow )
end

local ISMoveableSpritePropsPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
function ISMoveableSpriteProps:pickUpMoveableInternal( _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )
	local transferMD
	if _object and _spriteName and luautils.stringStarts(_spriteName, "location_business_machinery_01") and (_spriteName:contains("_4") or _spriteName:contains("_5")) then
		transferMD = _object:getModData().TireStackContents or {}
	end

	local item = ISMoveableSpritePropsPickUpMoveableInternal(self,  _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )

	if item and transferMD then
		item:getModData().TireStackContents = transferMD
	end

	return item
end
