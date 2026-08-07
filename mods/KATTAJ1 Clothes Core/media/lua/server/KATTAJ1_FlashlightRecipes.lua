
-- When creating item in result box of crafting panel.
function Recipe.OnCreate.KATTAJ1_RemoveFlashlightBattery(items, result, player)
	for i=0, items:size()-1 do
		local item = items:get(i)
		-- we found the battery, we change his used delta according to the battery
		if item:getType() == "KATTAJ1_TacticalFlashlight" then
			result:setUsedDelta(item:getUsedDelta());
			-- then we empty the torch used delta (his energy)
			item:setUsedDelta(0);
		end
	end
end

-- Return true if recipe is valid, false otherwise
function Recipe.OnTest.KATTAJ1_InsertFlashlightBattery(sourceItem, result)
	if sourceItem:getType() == "KATTAJ1_TacticalFlashlight" then
		return sourceItem:getUsedDelta() == 0; -- Only allow the battery inserting if the flashlight has no battery left in it.
	end
	return true -- the battery
end

-- When creating item in result box of crafting panel.
function Recipe.OnCreate.KATTAJ1_InsertFlashlightBattery(items, result, player)
  for i=0, items:size()-1 do
	-- we found the battery, we change his used delta according to the battery
	if items:get(i):getType() == "Battery" then
		result:setUsedDelta(items:get(i):getUsedDelta());
	end
  end
end

function Recipe.OnCreate.KATTAJ1_DismantleFlashlight(items, result, player)
	for i=1,items:size() do
		local item = items:get(i-1)
		if item:getType() == "KATTAJ1_TacticalFlashlight" then
			if item:getUsedDelta() > 0 then
				local battery = player:getInventory():AddItem("Base.Battery")
				if battery then
					battery:setUsedDelta(item:getUsedDelta())
				end
			end
			break
		end
	end
end

