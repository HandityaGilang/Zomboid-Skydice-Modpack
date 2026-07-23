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
    	if not self.part then
    		print('no such part '..tostring(self.part))
    		return false
    	end
		
		local failure = ISInstallEnginePart.calculateInstallationChance(self.character, self.skill)

    	-- this is so player don't go over inventory capacity when removing parts
		local engine = self.vehicle:getPartById("Engine")
		if ZombRand(100) < failure then
   			self.part:setCondition(self.part:getCondition() - ZombRand(failure)); -- Damage up to failureChance amount. Todo: add sandbox scaler? 
			self.part:syncItemFields();
			
   			--playServerSound("PZ_MetalSnap", self.character:getCurrentSquare());
			if isServer() then
				playServerSound("PZ_MetalSnap", self.character:getCurrentSquare());
			else
				self.character:playSound("PZ_MetalSnap");
			end

   		end

		engine:getItemContainer():DoRemoveItem(self.part)
		sendRemoveItemFromContainer(engine:getItemContainer(),self.part)
		
    	if self.character:getInventory():hasRoomFor(self.character, self.part) then
    		self.character:getInventory():AddItem(self.part);
    		sendAddItemToContainer(self.character:getInventory(), self.part);
    	else
    		local square = self.character:getCurrentSquare()
    		local dropX,dropY,dropZ = ISTransferAction.GetDropItemOffset(self.character, square, self.part)
    		self.character:getCurrentSquare():AddWorldInventoryItem(self.part, dropX, dropY, dropZ);
   			ISInventoryPage.renderDirty = true
   		end

		addXp(self.character, Perks.Mechanics, self.skill * 0.02 * self.part:getCondition()); -- Make adjustable by sandbox?
		
   	else
   		print('no such vehicle id=', self.vehicle)
   	end
	-- Update engine condition immediately so engine stalls if you remove something important. 
	UpdateEngineCondition(self.vehicle,self.vehicle:getPartById("Engine"));
	return true
end

function ISUninstallEnginePart:getDuration()
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
        return 1
    end
	return ISInstallEnginePart.calculateInstallationTime(self.character, self.skill);
end

function ISUninstallEnginePart:new(character, vehicle, part, skill)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = vehicle
	o.part = part
	o.skill = skill;
	o.maxTime = o:getDuration(); 
	o.jobType = getText("Tooltip_Vehicle_Uninstalling", part:getDisplayName());
	return o
end

