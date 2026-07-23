require "TimedActions/ISBaseTimedAction"

ISTransferFluid = ISBaseTimedAction:derive("ISTransferFluid")

function ISTransferFluid:isValid()
    if isClient() and self.itemFrom then
        return true
    else
        return FluidContainer.CanTransfer(self.itemFrom:getFluidContainer(),self.itemTo:getFluidContainer()) and 
            self.itemTo:getFluidContainer():getAmount() < self.itemTo:getFluidContainer():getCapacity()
    end
end

function ISTransferFluid:waitToStart()
	--self.character:faceThisObject(self.objectTo)
	--return self.character:shouldBeTurning()
	return false;
end

function ISTransferFluid:update()
	if not self.character:getEmitter():isPlaying(self.sound) then
		self.sound = self.character:playSound("PourWaterIntoObject") -- loop sound on long pours. 
	end


	--self.character:faceThisObject(self.objectTo)
	self.itemFrom:setJobDelta(self:getJobDelta())
	self.itemTo:setJobDelta(self:getJobDelta())
	
	self.character:setMetabolicTarget(Metabolics.LightDomestic);

	if not isClient() then
		-- transfer per update
		local progressAmount = self.addUnits * self:getJobDelta();
		local sourceAmountTarget = self.itemFromStartAmount - progressAmount;
		local amountToTransfer = math.max(0, self.itemFrom:getFluidContainer():getAmount() - sourceAmountTarget);
		self.itemFrom:getFluidContainer():transferTo(self.itemTo:getFluidContainer(), amountToTransfer);
		self.itemFrom:syncItemFields();
		self.itemTo:syncItemFields();
	end
end

function ISTransferFluid:start()
	self.itemFrom:setJobType(self.jobType)
	self.itemTo:setJobType(self.jobType)
	self.itemFrom:setJobDelta(0.0)
	self.itemTo:setJobDelta(0.0)

	self:setAnimVariable("PourType", self.itemFrom:getPourType());
	self:setActionAnim("fill_container_tap");
	--print("transfer from is ", self.transferFrom);
	if self.transferFromEngine == true then
		self:setOverrideHandModels(self.itemTo:getStaticModel(), nil)
	else
		self:setOverrideHandModels(self.itemFrom:getStaticModel(), nil)
	end

	self.sound = self.character:playSound("PourWaterIntoObject")
	--self.character:reportEvent("EventTakeWater"); -- ??
end

function ISTransferFluid:stop()
	self:stopSound()
	self.itemFrom:setJobDelta(0.0)
	self.itemTo:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISTransferFluid:perform()
	self:stopSound()
	self.itemFrom:getContainer():setDrawDirty(true)
	self.itemFrom:setJobDelta(0.0)
	self.itemTo:setJobDelta(0.0)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISTransferFluid:complete()
	if self.addUnits and self.addUnits > 0 then
		local sourceAmountTarget = self.itemFromStartAmount - self.addUnits;
		local amountToTransfer = math.max(0, self.itemFrom:getFluidContainer():getAmount() - sourceAmountTarget);
		self.itemFrom:getFluidContainer():transferTo(self.itemTo:getFluidContainer(), amountToTransfer);
		self.itemFrom:syncItemFields();
		self.itemTo:syncItemFields();
	end

	return true;
end

function ISTransferFluid:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return math.min(math.max(self.addUnits * 48 * 2.0, 48*1.0), 48*7.0); -- 2 second per liter, min 1, max 7 seconds. 
end

function ISTransferFluid:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
end

function ISTransferFluid:new(character, itemFrom, itemTo, transferFromEngine)
	local o = ISBaseTimedAction.new(self, character)
	o.itemFrom = itemFrom
	o.itemTo = itemTo
	o.transferFromEngine = transferFromEngine;
	o.itemFromStartAmount = o.itemFrom:getFluidContainer():getAmount()
	local destCapacity = math.max(0, o.itemTo:getFluidContainer():getCapacity() - o.itemTo:getFluidContainer():getAmount());
	o.addUnits = math.min(destCapacity, o.itemFromStartAmount)
	--print ("Added units ", o.addUnits);
	o.itemFromEndingAmount = o.itemFromStartAmount - o.addUnits
	o.maxTime = o:getDuration()
	--print ("Duration ", o.maxTime);

	o.jobType = transferFromEngine and getText("IGUI_EnginePanel_Action_RemovingFluid") or getText("IGUI_EnginePanel_Action_AddingFluid")
	return o
end    	
