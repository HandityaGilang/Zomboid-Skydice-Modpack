-- Step 1: Add context to rightclick menu.
-- Step 2: Get repair working
-- Step 3: filter to engine parts (Should add a tag?)
-- Step 4: Add repair data
-- Step 5: pick random repair method and display it (Lower part condition = more available methods? Also with higher mechanic skill?). Save method in moddata for persistence

--local predicateUseCounterCount = 0;
--local function predicateUseCounter(item)
--	return not item:isBroken() and item:getCurrentUses() >= predicateUseCounterCount
--end



local function predicateNotBroken(item)
	return not item:isBroken()
end

local function predicateHasTag(item,details)
	return not item:hasTag(details.tag);
end

local function predicateUseCounter(item, details)
	return not item:isBroken() and item:getCurrentUses() >= details.useCount
end


local function comparatorDrainableUsesInt(item1, item2)
	return item1:getCurrentUses() - item2:getCurrentUses()
end

local function calculateChance(playerLevel,levelRequired, timesRepaired)
	local failure = 0;
	local failureLow = 80
	local failureSkilled = 20
	
	levelRequired = levelRequired + (timesRepaired / 2);
	
	if playerLevel < levelRequired then
		failure = playerLevel / levelRequired; -- 0 ~ 1 scaler
		failure = failureLow + (failure * (failureSkilled-failureLow))
	else
		failure = (playerLevel - levelRequired) / (10-levelRequired) --0~1 scale depending on how much closer you are to level 10
		failure = (1-failure) * failureSkilled
	end

	failure = math.min(math.max(failure, 5), 100) -- 5% chance of failure no matter how good you are. 
	return math.floor(100.5-failure);
end



local function GetItem(itemList,character)

	if itemList.tag ~= nil then
		if itemList.uses ~= nil then
			--predicateUseCounterCount = itemList.uses;
			local foundItem = character:getInventory():getFirstTagEvalArgRecurse(itemList.tag, predicateUseCounter, {useCount = itemList.uses})
			-- return best qualifying item if we can't find one that works. 
			return foundItem or character:getInventory():getBestEvalArgRecurse(predicateHasTag, comparatorDrainableUsesInt, {tag = itemList.tag, useCount = itemList.uses})			
			
		elseif itemList.count ~= nil then
			-- return number of items instead of exact item. 
			return character:getInventory():getCountTypeEval(itemList.tag,predicateNotBroken)
		end
		-- Normal single item search. 
		return character:getInventory():getFirstTagEvalRecurse(itemList.tag, predicateNotBroken)
	end

	
	--print("Looking for ", itemList.name);
	if itemList.name ~= nil then
		if itemList.uses ~= nil then
			--predicateUseCounterCount = itemList.uses;
			local foundItem = character:getInventory():getFirstTypeEvalArgRecurse(itemList.name, predicateUseCounter, {useCount = itemList.uses})
			-- return best qualifying item if we can't find one that works. 
			return foundItem or character:getInventory():getBestTypeEvalRecurse(itemList.name, comparatorDrainableUsesInt)			
		elseif itemList.count ~= nil then
			-- return number of items instead of exact item. 
			return character:getInventory():getCountTypeEval(itemList.name,predicateNotBroken)
		end
		-- Normal single item search. 
		return character:getInventory():getFirstTypeEvalRecurse(itemList.name, predicateNotBroken)
	end

	if itemList.fluid ~= nil then
		local bestFound = nil
		local bestAmountFound = 0;

		local invList = character:getInventory():getItems()
		for i=0, invList:size() - 1 do
			local invItem = invList:get(i)
			-- Find all fluid containers, add as options if they have fluid.
			if invItem:getFluidContainer() then
				local amountFound = invItem:getFluidContainer():getSpecificFluidAmount(Fluid.Get(itemList.fluid));
				if amountFound > itemList.amount then
					return invItem;
				elseif amountFound > bestAmountFound then
					bestAmountFound = amountFound
					bestFound = invItem;
				end
			end
		end	
		return bestFound;
	end
	
	
	return nil;
end


local function ParseItemText(itemList, repairItem)
	-- Todo: Get displayname for translation. 
	--local tip = itemList.name or itemList.tag or itemList.fluid
	local itemByName = itemList.name and getItem(itemList.name); 
	local tip = itemByName and itemByName:getDisplayName() or itemList.name;
	
	tip = tip or itemList.tag -- Todo: Add some translation system for tags.
	tip = tip or itemList.fluid and Fluid.Get(itemList.fluid):getDisplayName();
	
	local itemValid = repairItem ~= nil;

	if itemList.uses ~= nil then
		local playerUses = repairItem and repairItem:getCurrentUses() or 0
		tip = tip .. " (Uses ".. playerUses .. "/" .. itemList.uses .. ")"
		if playerUses < itemList.uses then
			itemValid = false;
		end
	elseif itemList.count ~= nil then
		tip = tip .. " (Count ".. repairItem .. "/" .. itemList.count .. ")"
		if repairItem < itemList.count then
			itemValid = false;
		end
	elseif itemList.degrade ~= nil then
		tip = tip .. " (Degrade ".. tostring(itemList.degrade*100) .."% chance)"
	elseif itemList.fluid ~= nil then
		local amountFound = 0;
		if repairItem then
			amountFound = repairItem:getFluidContainer():getSpecificFluidAmount(Fluid.Get(itemList.fluid));
		end
		tip = tip .. " (Amount ".. amountFound .. "/" .. itemList.amount .. ")"
	elseif itemList.keep ~= nil then
		tip = tip .. " (Keep)"
	end
	

	if itemValid then
		return true, "<GHC>"..tip
	else
		return false, "<BHC>"..tip
	end

end



local function RepairPartSelect(item, playerObj, failureModeIndex, repairIndex)
-- 
	local modData = item:getModData();
	local repair = PartFailureModes[modData.MSC_failureMode[failureModeIndex] ].methods[repairIndex];
	
	for y = 1, #repair.items do
		local itemList = repair.items[y];
		local item = GetItem(itemList,playerObj);

		if itemList.uses ~= nil then
			item:setCurrentUses(item:getCurrentUses()-itemList.uses); 
		elseif itemList.degrade ~= nil then
			if ZombRandFloat(0,1) < itemList.degrade then
				item:setCondition(item:getCondition()-1); 
			end
		elseif itemList.count ~= nil then
			playerObj:getInventory():RemoveAll(itemList.name,itemList.count)
		elseif itemList.fluid ~= nil then
			--print("Removing ", itemList.amount, " fluid");
			local fluid = Fluid.Get(itemList.fluid);
			local container = item:getFluidContainer();
			container:adjustSpecificFluidAmount(fluid,container:getSpecificFluidAmount(fluid) - itemList.amount)
		elseif itemList.keep ~= nil then
			-- Do nothing!
		else
			item:Remove();
		end
	end
	table.remove(modData.MSC_failureMode,failureModeIndex);
	
	if ZombRand(100) < calculateChance(playerObj:getPerkLevel(Perks.FromString(repair.skill)), repair.difficulty, item:getTimesRepaired()) then
		item:setCondition(item:getCondition()+math.min(30,ZombRand(40)+10));
		addXp(playerObj,Perks.FromString(repair.skill), 3)
	else
		playerObj:playSoundLocal("PZ_MetalSnap");
		item:setCondition(item:getCondition()-ZombRand(20));
		item:setTimesRepaired(item:getTimesRepaired()+1);
		addXp(playerObj,Perks.FromString(repair.skill), 1)
	end
end

-- all the perks are: Agility, Cooking, Melee, Crafting, Fitness, Strength, Blunt, Axe, Sprinting, Lightfoot, Nimble, Sneak, Woodwork, Aiming, Reloading, Farming, 
-- Survivalist, Fishing, Trapping, Passiv, Firearm, PlantScavenging, Doctor, Electricity, Blacksmith, MetalWelding, Melting, Mechanics, Spear, Maintenance, SmallBlade, 
-- LongBlade, SmallBlunt, Combat,

-- idea: Improper repairs might increase later repair difficulty? 
PartFailureModes = {
{name = "Small Dent", methods = {
	{name = "Weld Dent", skill = "MetalWelding", difficulty = 2, items = {{name = "BlowTorch", uses = 1}, {name = "WeldingRods", uses = 1}, {tag = "WeldingMask", keep = true }, }, },
	{name = "Hammer Dent", skill = "Mechanics", difficulty = 2, items = { {name = "Hammer", degrade = 0.5}, }, },
},},
{name = "Large Dent", methods = {
	{name = "Weld Dent", skill = "MetalWelding", difficulty = 3, items = {{name = "BlowTorch", uses = 1}, {name = "WeldingRods", uses = 1},  {tag = "WeldingMask", keep = true }, },},
	{name = "Hammer Dent", skill = "Mechanics", difficulty = 3, items = {{name = "Hammer", degrade = 0.5}, }, },
},},
{name = "Small Hole", methods = {
	{name = "Weld Hole", skill = "MetalWelding", difficulty = 4, items = {{name = "BlowTorch", uses = 1}, {name = "WeldingRods", uses = 1}, { name = "SmallSheetMetal"},  {tag = "WeldingMask", keep = true }, }, },
	{name = "Glue Plate", skill = "Mechanics", difficulty = 4, items = {{name = "Glue", uses = 1}, {name = "SmallSheetMetal"}, }, },
},},
{name = "Large Hole", methods = {
	{name = "Weld Hole", skill = "MetalWelding", difficulty = 6,items = {{name = "BlowTorch", uses = 1}, {name = "WeldingRods", uses = 1}, {name = "SheetMetal"},  {tag = "WeldingMask", keep = true }, }, },
	{name = "Glue Plate", skill = "Mechanics", difficulty = 6,items = {{name = "Glue", uses = 1}, {name = "SheetMetal"}, }, },
},},

{name = "Bent", methods = {
	{name = "Heat Bend", skill = "MetalWelding", difficulty = 6, items = {{name = "BlowTorch", uses = 3}, }, },
	{name = "Hammer Bend",  skill = "Mechanics", difficulty = 6, items = {{name = "Hammer", degrade = 0.5}, },},
},},


-- Todo: add bearing items and tags to items
{name = "Bearings worn out", requiresTag = "EnginePartBearing", methods = {
	{name = "Oil", skill = "Maintenance", difficulty = 2, items = {{fluid = "MotorOil", amount = 0.5},},},
	--{name = "Replace", skill = "Maintenance", difficulty = 2, items = {{name = "Bearing"},},},
},},


{name = "Electrical Issue", requiresTag = "EnginePartElectrical", methods = {
	{name = "Replace Parts", skill = "Electricity", difficulty = 3, items = {{name = "ElectronicsScrap", count = 2},},},
},},

{name = "Burnt Wiring", requiresTag = "EnginePartElectrical", methods = {
	{name = "Replace Wires", skill = "Electricity", difficulty = 4, items = {{name = "ElectronicsScrap", count = 3},}, }, -- Switch to electrical wiring? Kinda rare. Maybe just add wire option. 
},},


-- Todo: add acetone support if damns lib is enabled. 
{name = "Gunked up", methods = {
	{name = "Clean with Gasoline", skill = "Maintenance", difficulty = 1, items = {{fluid = "Petrol", amount = 0.5}, {name = "Toothbrush", keep = true }, },},
	{name = "Clean with Cleaning Fluid", skill = "Maintenance", difficulty = 1, items = {{fluid = "CleaningLiquid", amount = 0.1}, {name = "Toothbrush", keep = true }, }, },
},},

{name = "Missing Bolts", methods = {
	{name = "Replace Bolts", skill = "Mechanics", difficulty = 2, items = {{name = "NutsBolts", count = 2}, }, },
},},

{name = "Stripped Bolts", methods = {
	{name = "Remove and Replace Bolts", skill = "Mechanics", difficulty = 6, items = {{name = "NutsBolts", count = 2}, }, },
},},

}

function ScanForRepairMethods(item,modData)
	local condition = item:getCondition();
	local repairMethodCount = math.floor((110-condition) / 20); -- First method at 90%, last at 10% 
	modData.MSC_failureMode = modData.MSC_failureMode or {}
	local currentMethodCount = #modData.MSC_failureMode
	--print("Methodcount ", currentMethodCount, " Expected ", repairMethodCount);
	for x = currentMethodCount+1, repairMethodCount do
	-- Pick new method, add to repairmethods. 
		local failureMode = 0;
		-- Find unused method:
		repeat 
			failureMode = ZombRand(#PartFailureModes)+1
			if PartFailureModes[failureMode].requiresTag ~= nil and not item:getScriptItem():hasTag(PartFailureModes[failureMode].requiresTag) then
				failureMode = -1;
			else
				for y = 1, #modData.MSC_failureMode do
					if failureMode == modData.MSC_failureMode[y] then
						failureMode = -1;
						break 
					end
				end
			end
		until failureMode ~= -1
		
		table.insert(modData.MSC_failureMode,failureMode);
		--print("added repair method");
	end
	
	currentMethodCount = #modData.MSC_failureMode
	for x = repairMethodCount+1, currentMethodCount do
		--print("Removing repair method");
		table.remove(modData.MSC_failureMode, ZombRand(#modData.MSC_failureMode)+1);
	end

end

function RepairEnginePartContext(playerIndex, context, items)
	
	local sv = SandboxVars.ProjectSummerCar	
	if sv.RepairPartsBeta == false then
		return 
	end
		
	local item = nil;
	if instanceof(items[1], "InventoryItem") then
		item = items[1];
	else
		item = items[1].items[1]
	end
	print("Item type ", item:getFullType());
	local playerObj = getSpecificPlayer(playerIndex);
	
	-- Using hasTag on the script item, since we changed tags at one point so don't use the currently assigned tags. 
	if item:getScriptItem():hasTag("EnginePart") then 
		-- Todo: Check if broken and refuse repairs?
		if item:getScriptItem():hasTag("EnginePartNoRepair") then
			local repairOption = context:addOption("Can't Be repaired")
			repairOption.notAvailable = true;
			local tooltip = ISToolTip:new();
			tooltip:initialise();
			tooltip:setVisible(false);
			tooltip.description = "This type of part can't be repaired. New ones must be crafted.";
			repairOption.toolTip = tooltip;
			
			-- Add tooltip on why you can't repair it?
			return
		end
		if item:getCondition() == 0 then
			local repairOption = context:addOption("Can't Be repaired")
			repairOption.notAvailable = true;
			local tooltip = ISToolTip:new();
			tooltip:initialise();
			tooltip:setVisible(false);
			tooltip.description = "Broken parts can't be repaired.";
			repairOption.toolTip = tooltip;
			
			-- Add tooltip on why you can't repair it?
			return
		end		
		-- Don't show, or say 'Fully repaired' when no repair options exist?
		
		
		local modData = item:getModData();
		ScanForRepairMethods(item,modData);
				
		if #modData.MSC_failureMode == 0 then
			local repairOption = context:addOption("Fully Repaired")
			repairOption.notAvailable = true;
			return
		end
		
		local repairOption = context:addOption("Repair:")
		local repairMenuContext = ISContextMenu:getNew(context)
		context:addSubMenu(repairOption, repairMenuContext)
		
		
		
		for x = 1, #modData.MSC_failureMode do
			local failureMode = PartFailureModes[modData.MSC_failureMode[x] ];
			local failureOption = repairMenuContext:addOption(failureMode.name, nil, nil)
			local failureMenuContext = ISContextMenu:getNew(repairMenuContext)
			repairMenuContext:addSubMenu(failureOption, failureMenuContext)
			local failureOptionFixable = false;
			
			for y = 1, #failureMode.methods do
				local repairMethod = failureMode.methods[y]; 
				local repairOption = failureMenuContext:addOption(repairMethod.name, item, RepairPartSelect, playerObj, x, y)
				local tooltip = ISToolTip:new();
				tooltip:initialise();
				tooltip:setVisible(false);
				
				local perk = Perks.FromString(repairMethod.skill);
				local chance = calculateChance(playerObj:getPerkLevel(perk), repairMethod.difficulty, item:getTimesRepaired());
				--if chance < 50 then
				--	tooltip.description = tooltip.description .. "<BHC>"
				--else
				--	tooltip.description = tooltip.description .. "<GHC>" 
				--end
				--tooltip.description = tooltip.description .. tostring(playerObj:getPerkLevel(perk)) .. "/" .. tostring(repairMethod.difficulty) .. " " .. perk:getName() .. " <LINE>" 
				
				tooltip.description = "Chance of success: " .. ((chance >= 50) and "<GHC>" or "<BHC>") .. tostring(chance) .. "% <LINE>" .. 
					"<RGB:1,1,1>Skill used: " .. perk:getName() .. " <LINE> "


				tooltip.description = tooltip.description .. "Requirements: <LINE>";
				
				
				
				-- Maybe we shouldn't show the exact difficulty? Or at least not color code it so much? 
				
				
				local isRepairValid = true;
				for z = 1, #repairMethod.items do
					local repairItem = GetItem(repairMethod.items[z],playerObj);
					local itemValid, tooltipText = ParseItemText(repairMethod.items[z],repairItem);
					isRepairValid = isRepairValid and itemValid;
					tooltip.description = tooltip.description .. tooltipText .. " <LINE>" ;
				end
				repairOption.toolTip = tooltip;
				repairOption.notAvailable = not isRepairValid;
				failureOptionFixable = failureOptionFixable or isRepairValid;
			end
			failureOption.notAvailable = not failureOptionFixable;
		end
	end
end

Events.OnFillInventoryObjectContextMenu.Add(RepairEnginePartContext);