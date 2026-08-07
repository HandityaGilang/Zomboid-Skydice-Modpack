require "ShelterHold/Hold_BeehiveCompat"

Hold_CraftRecipeCode = Hold_CraftRecipeCode or {}
Hold_CraftRecipeCode.OnCreate = {}

function Hold_CraftRecipeCode.OnCreate.ModifyHiveFrameUses(craftRecipeData, character)
	local inputItems = craftRecipeData:getAllConsumedItems()
	local targetItem = nil
	for i = 0, inputItems:size() - 1 do
		local item = inputItems:get(i)
		if HoldBeehiveCompat.isHiveFrame(item) then
			targetItem = item
		end
	end

	local createdItems = craftRecipeData:getAllCreatedItems()

	for i = 0, createdItems:size() - 1 do
		local item = createdItems:get(i)

		if HoldBeehiveCompat.isHiveFrame(item) then
			item:setCurrentUsesFloat(0.0)
			if targetItem then
				item:setCondition(targetItem:getCondition())
			end
		end
	end
end

function Hold_CraftRecipeCode.OnCreate.Add2HoneytoFood(craftRecipeData, character)
	local inputItems = craftRecipeData:getAllConsumedItems()
	local hungChange = 0
	local calories = 0
	local carbohydrates = 0
	local unhappiness = 0
	local thirstChange = 0
	local lipids = 0
	local proteins = 0
	for i = 0, inputItems:size() - 1 do
		local item = inputItems:get(i)
		if item and item:isFood() then
			hungChange = item:getHungChange()
			calories = item:getCalories()
			carbohydrates = item:getCarbohydrates()
			unhappiness = item:getUnhappyChange()
			thirstChange = item:getThirstChange()
			lipids = item:getLipids()
			proteins = item:getProteins()
		end
	end

	local createdItems = craftRecipeData:getAllCreatedItems()

	for i = 0, createdItems:size() - 1 do
		local item = createdItems:get(i)

		if item and item:isFood() then
			item:setHungChange(hungChange - 0.05)
			item:setCalories(calories + 200)
			item:setCarbohydrates(carbohydrates + 60)
			item:setUnhappyChange(unhappiness)
			item:setThirstChange(thirstChange)
			item:setLipids(lipids)
			item:setProteins(proteins)
		end
	end
end


function Hold_CraftRecipeCode.OnCreate.MaintenanceWeapon(craftRecipeData, character)
	local item = craftRecipeData:getFirstInputItemWithFlag("Prop1")
	local skill = craftRecipeData:getRecipe():getHighestRelevantSkillLevel(character)
	local timesRepaired = item:getHaveBeenRepaired()
	local head = item:hasHeadCondition()

	-- FIXME:dont know what kind of weapon use TimesHeadRepaired ,maybe later update?
	local timesHeadRepaired = math.floor(item:getTimesHeadRepaired())
	local realTimesRepaired
	if head and timesHeadRepaired then
		realTimesRepaired = timesHeadRepaired
	elseif timesRepaired then
		realTimesRepaired = timesRepaired
	end

	local failChance = 25 - (skill * 2) + realTimesRepaired * 3
	if ZombRand(100) >= failChance then
		if head and timesHeadRepaired and timesHeadRepaired > 0 then
			item:setTimesHeadRepaired(timesRepaired -1)
		elseif timesRepaired and timesRepaired > 0 then
			item:setHaveBeenRepaired(timesRepaired - 1)
		end
	end

	item:syncItemFields()
end