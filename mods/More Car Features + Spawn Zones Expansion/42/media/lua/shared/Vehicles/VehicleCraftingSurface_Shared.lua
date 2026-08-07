vehicleCraftSurf = vehicleCraftSurf or {}

function vehicleCraftSurf.isCharacterInRangeVehicleHood(player)
	local vehicle = player:getNearVehicle()
	if not player:getVehicle() and vehicle and vehicle:getScript():getPartById("EngineDoor") and vehicle:getSpeed2D() < 0.1 then
		local hoodPart = vehicle:getPartById("EngineDoor")
		if hoodPart and hoodPart:getDoor() and hoodPart:getInventoryItem() and not hoodPart:getDoor():isOpen() then
			local dir = MoreCarFeatures.getVehicleDir(vehicle)
			local hoodArea = vehicle:getAreaCenter(hoodPart:getArea())
			local hx, hy = (hoodArea:getX() - math.cos(dir)), (hoodArea:getY() - math.sin(dir))
			local dx = hx - player:getX()
			local dy = hy - player:getY()
			local dist = math.sqrt(dx*dx + dy*dy)
			if dist < 1.3 then
				return {hx, hy}
			end
		end
	end
	return false
end

function vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(player)
	local vehicle = player:getNearVehicle()
	if not player:getVehicle() and vehicle and vehicle:getSpeed2D() < 0.1 then
		local trunkDoor = vehicle:getPartById("TrunkDoor") or vehicle:getPartById("DoorRear") or vehicle:getPartById("TrunkDoorOpened")		--Closed Off Trunk Lids (if have)
		local trunkBed = vehicle:getPartById("TruckBedOpen") or vehicle:getPartById("TrailerTrunk")		--Some Trailers and Some Pickups that are opened up
		if trunkDoor then
			if Vehicles.ContainerAccess.TruckBed(vehicle, trunkDoor, player) then
				local dir = MoreCarFeatures.getVehicleDir(vehicle)
				local trunkArea = vehicle:getAreaCenter(trunkDoor:getArea())
				local hx, hy = (trunkArea:getX() + math.cos(dir)), (trunkArea:getY() + math.sin(dir))
				return {hx, hy}
			end
		elseif trunkBed then
			if Vehicles.ContainerAccess.TruckBedOpen(vehicle, trunkBed, player) then
				local trunkArea = vehicle:getAreaCenter(trunkBed:getArea())
				local hx, hy = trunkArea:getX(), trunkArea:getY()
				return {hx, hy}
			end
		end
	end
	return false
end

function vehicleCraftSurf.canPerformCurrentRecipeREMAKE(logic, player)
	local recipe = logic:getRecipe()
	if not logic:areAllInputItemsSatisfied() then
		return false
	elseif not recipe:isCanWalk() and player:isPlayerMoving() then
		return false
	elseif recipe:needToBeLearn() and not (player:isRecipeKnown(recipe, true) and (recipe:characterHasRequiredSkills(player) or (recipe:couldBenefitFromRecipeAtHand(player) and recipe:validateBenefitFromRecipeAtHand(player, logic:getContainers())))) then
		return false
	elseif not recipe:canBeDoneInDark() and player:tooDarkToRead() then
		return false
	elseif recipe:requiresSpecificWorkstation() then
		return false
	end
	return true
end

function ISHandcraftAction:start()
	--log(DebugType.CraftLogic, "ISHandcraftAction.start")
	if self.craftRecipe then showDebugInfoInChat("CRAFT \'"..self.craftRecipe:getName().."\'") end
	self.logic = HandcraftLogic.new(self.character, self.craftBench, self.isoObject);
	self.logic:setContainers(self.containers);
	self.logic:setRecipe(self.craftRecipe);
	self.logic:setTargetVariableInputRatio(self.variableInputRatio);
	if self.manualInputs then
		if isClient() then
			self:fixManualInputs()
		end
		self.logic:setManualSelectInputs(true);
		self.logic:clearManualInputs();
		
		--log(DebugType.CraftLogic, "-= reading manual inputs =-")
		for inputIndex, items in pairs(self.manualInputs) do
			local inputScript = self.craftRecipe:getIOForIndex(inputIndex);
			if (not inputScript) or (not self.logic:setManualInputsFor(inputScript, items)) then
				log(DebugType.CraftLogic, "ISHandcraftAction.start -> failed to set manual input items for recipe.")
			end
		end

		-- This call is required so CraftRecipeData.CachedData.addAppliedData() is called for manualInputs.
		-- Without it, the CraftRecipeData.getAllInputItems() call below won't return manualInputs.
		self.logic:canPerformCurrentRecipe()

		self.faceVehicle = false
		if not self.logic:canPerformCurrentRecipe() then
			if vehicleCraftSurf.canPerformCurrentRecipeREMAKE(self.logic, self.character) 
			and self.craftRecipe:isAnySurfaceCraft() 
			and not self.logic:isCharacterInRangeOfWorkbench() 
			and (vehicleCraftSurf.isCharacterInRangeVehicleHood(self.character) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.character))
			then
				self.faceVehicle = true
			elseif not isClient() and not self.force then
				log(DebugType.CraftLogic, "ISHandcraftAction.start -> canPerformCurrentRecipe failed.")
				self:forceStop();
				return;
			end
		end
	end

	if self.items then
		if isClient() then
			self:fixMovedItems(self.items)
		end
    else
		-- populate with what recipe has now filled
		if self.logic:getRecipeData() then
			self.items = self.logic:getRecipeData():getAllInputItems()
		end
	end

	self:clearItemsProgressBar(true);
	
    if self.actionScript then
        self:setActionAnim(self.actionScript:getActionAnim());
        if self.actionScript:getAnimVarKey() then
            self:setAnimVariable(self.actionScript:getAnimVarKey(), self.actionScript:getAnimVarVal());
        end
		if self.actionScript:getSound() ~= nil and self.actionScript:getSoundTime() == ActionSoundTime.ACTION_START then
			self.sound = self.character:playSound(self.actionScript:getSound());
		end
    end

    -- sitting stuff
    if self.actionScript and self.actionScript:isCantSit() == true and self.character:isSitOnGround() then
        self.character:setSitOnGround(false)
    end

    self:setOverrideHandModels(self.logic:getModelHandOne(), self.logic:getModelHandTwo());

	if self.onStartFunc then
		self.onStartFunc(self.onStartTarget, self);
	end
end

local ISHandcraftActionUpdate = ISHandcraftAction.update
function ISHandcraftAction:update()
	ISHandcraftActionUpdate(self)

	if self.faceVehicle then
		local faceDir = vehicleCraftSurf.isCharacterInRangeVehicleHood(self.character) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.character)
		if faceDir then
			self.character:faceLocationF(faceDir[1], faceDir[2])
		else
			ISHandcraftAction.stop(self)
			ISTimedActionQueue.clear(self.character)
		end
	end
end