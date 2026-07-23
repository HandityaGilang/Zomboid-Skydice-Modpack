--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"


ISInstallEnginePart = ISBaseTimedAction:derive("ISInstallEnginePart")

function ISInstallEnginePart.calculateInstallationChance(chr, levelRequired)
	local failure = 0;
	local failureLow = 80
	local failureSkilled = 20
	
	local playerLevel = chr:getPerkLevel(Perks.Mechanics);
	if playerLevel < levelRequired then
		failure = playerLevel / levelRequired; -- 0 ~ 1 scaler
		failure = failureLow + (failure * (failureSkilled-failureLow))
	else
		failure = (playerLevel - levelRequired) / (10-levelRequired) --0~1 scale depending on how much closer you are to level 10
		failure = (1-failure) * failureSkilled
	end

	failure = math.min(math.max(failure, 0), 100)
	return failure;
end

function ISInstallEnginePart.calculateInstallationTime(chr, levelRequired)
	local playerLevel = chr:getPerkLevel(Perks.Mechanics);
	local time = 300 * levelRequired; -- About 6 seconds per level, so about 36 seconds for very complex things with no skill? 
	time = time / math.max(0.7,playerLevel); -- give them a boost for level 0. 
	return math.max(200,time); -- min 200 even for very simple things. (4 seconds)
end

function ISInstallEnginePart:isValid()
	if self.character:isMechanicsCheat() then return true; end
	
	return true
	--[[
	if isClient() and self.item then
	    return self.vehicle:canInstallPart(self.character, self.part) and self.character:getInventory():containsID(self.item:getID());
	else
	    return self.vehicle:canInstallPart(self.character, self.part) and self.character:getInventory():contains(self.item);
	end
	--]]	
--			and
--			self.vehicle:isInArea(self.part:getArea(), self.character)
end

function ISInstallEnginePart:waitToStart()
	if self.character:isMechanicsCheat() then return false; end
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISInstallEnginePart:update()
	self.character:faceThisObject(self.vehicle)
	--self.item:setJobDelta(self:getJobDelta())

    self.character:setMetabolicTarget(Metabolics.MediumWork);
end

function ISInstallEnginePart:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
	--self.item:setJobType(getText("IGUI_Install"))
	self:setActionAnim("VehicleWorkOnMid")
end

function ISInstallEnginePart:stop()
	--self.item:setJobDelta(0)
	ISBaseTimedAction.stop(self)
end

function ISInstallEnginePart:perform()
    local pdata = getPlayerData(self.character:getPlayerNum());
    if pdata ~= nil then
       	pdata.playerInventory:refreshBackpacks();
        pdata.lootInventory:refreshBackpacks();
    end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISInstallEnginePart:complete()
	--self.item:setJobDelta(0)

	--local perksTable = VehicleUtils.getPerksTableForChr(self.part:getTable("install").skills, self.character)
   	if self.vehicle then
		local failure = ISInstallEnginePart.calculateInstallationChance(self.character, self.engineSlot.skill)
   		if not instanceof(self.playerItem, "InventoryItem") then
   			print('item is nil')
    			return
    		end
				
			self.character:removeFromHands(self.playerItem)
			self.character:getInventory():DoRemoveItem(self.playerItem)
			sendRemoveItemFromContainer(self.character:getInventory(),self.playerItem)
    		
			local engine = self.vehicle:getPartById("Engine")
			engine:getItemContainer():AddItem(self.playerItem)
			self.engineMechanics:updateParts();
    		
			if ZombRand(100) < failure then
    			self.playerItem:setCondition(self.playerItem:getCondition() - ZombRand(failure));
    			--playServerSound("PZ_MetalSnap", self.character:getCurrentSquare());
				self.character:playSoundLocal("PZ_MetalSnap");
    		end
			addXp(self.character, Perks.Mechanics, self.engineSlot.skill * 0.05 * self.playerItem:getCondition());
			
    	else
    		print('no such vehicle id=',self.vehicle)
    	end

	return true
end

function ISInstallEnginePart:getDuration()
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
        return 1
    end
	return self.maxTime;
end

function ISInstallEnginePart:new(character, engineMechanics, vehicle, engineSlot, playerItem)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = vehicle
	o.engineMechanics = engineMechanics;
	o.engineSlot = engineSlot
	o.playerItem = playerItem
	o.maxTime = ISInstallEnginePart.calculateInstallationTime(character, engineSlot.skill)
	o.workTime = o.maxTime;
	o.jobType = getText("Tooltip_Vehicle_Installing", playerItem:getDisplayName());
	return o
end

