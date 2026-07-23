--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISUninstallEnginePart = ISBaseTimedAction:derive("ISUninstallEnginePart")

function ISUninstallEnginePart:isValid()
	return true
	--if self.character:isMechanicsCheat() then return true; end
	--return self.part:getInventoryItem() and self.vehicle:canUninstallPart(self.character, self.part)
end

function ISUninstallEnginePart:waitToStart()
	if self.character:isMechanicsCheat() then return false; end
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISUninstallEnginePart:update()
	self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.MediumWork);
end

function ISUninstallEnginePart:start()
	self:setActionAnim("VehicleWorkOnMid")
end

function ISUninstallEnginePart:stop()
    ISBaseTimedAction.stop(self)
end

function ISUninstallEnginePart:perform()

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISUninstallEnginePart:complete()
	
	--local perksTable = VehicleUtils.getPerksTableForChr(self.part:getTable("install").skills, self.character)
    if self.vehicle then
    	if not self.engineSlot.part then
    		print('no such part '..tostring(self.engineSlot.part))
    		return false
    	end
		
		local failure = ISInstallEnginePart.calculateInstallationChance(self.character, self.engineSlot.skill)

    	-- this is so player don't go over inventory capacity when removing parts
		local engine = self.vehicle:getPartById("Engine")
		engine:getItemContainer():DoRemoveItem(self.engineSlot.part)
		
    	if self.character:getInventory():hasRoomFor(self.character, self.engineSlot.part) then
    		self.character:getInventory():AddItem(self.engineSlot.part);
    		sendAddItemToContainer(self.character:getInventory(), self.engineSlot.part);
    	else
    		local square = self.character:getCurrentSquare()
    		local dropX,dropY,dropZ = ISTransferAction.GetDropItemOffset(self.character, square, self.engineSlot.part)
    		self.character:getCurrentSquare():AddWorldInventoryItem(self.engineSlot.part, dropX, dropY, dropZ);
   			ISInventoryPage.renderDirty = true
   		end

		if ZombRand(100) < failure then
   			self.engineSlot.part:setCondition(self.engineSlot.part:getCondition() - ZombRand(failure)); -- Damage up to failureChance amount. Todo: add sandbox scaler? 
   			--playServerSound("PZ_MetalSnap", self.character:getCurrentSquare());
			self.character:playSoundLocal("PZ_MetalSnap");
   		end
		addXp(self.character, Perks.Mechanics, self.engineSlot.skill * 0.02 * self.engineSlot.part:getCondition()); -- Make adjustable by sandbox?
		
   	else
   		print('no such vehicle id=', self.vehicle)
   	end
	self.engineMechanics:updateParts();
	return true
	
end

function ISUninstallEnginePart:getDuration()
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
        return 1
    end
	return self.workTime-- - (self.character:getPerkLevel(Perks.Mechanics) * (self.workTime/15));
end

function ISUninstallEnginePart:new(character, engineMechanics, vehicle, engineSlot)
	local o = ISBaseTimedAction.new(self, character)
	o.engineMechanics = engineMechanics
	o.vehicle = vehicle
	o.engineSlot = engineSlot
	o.maxTime = ISInstallEnginePart.calculateInstallationTime(character, engineSlot.skill)
	o.workTime = o.maxTime;
	o.jobType = getText("Tooltip_Vehicle_Uninstalling", engineSlot.part:getDisplayName());
	return o
end

