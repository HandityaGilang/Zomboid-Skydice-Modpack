require 'TimedActions/ISInventoryTransferAction';

local SOTOSbvars = SandboxVars.SOTO;

-- Transfering speed affected by traits
local oldISInventoryTransferAction_new = ISInventoryTransferAction.new
function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
  local o = oldISInventoryTransferAction_new(self, character, item, srcContainer, destContainer, time)
  
  if character:HasTrait("Dextrous") and character:HasTrait("GasManagement") then
    o.maxTime = o.maxTime * 0.8  -- 0.5 * 0.8 = 0.4 or -60% transfer speed
  end
  if character:HasTrait("GasManagement") and not character:HasTrait("Dextrous") then
    o.maxTime = o.maxTime * 0.75 -- just -25% transfer speed
  end
  if character:HasTrait("AllThumbs") then
--	o.maxTime = o.maxTime * 0.5 -- 4.0 * 0.5 = 2.0 or +100% transfer speed
	o.maxTime = o.maxTime * 0.375 -- 4.0 * 0.375 = 1.5 or +50% transfer speed	
  end
  
  return o
end

local oldISInventoryTransferAction_update = ISInventoryTransferAction.update
function ISInventoryTransferAction:update()

	local player = self.character;
	local speedcontrol = UIManager.getSpeedControls();
	local gamespeed = speedcontrol:getCurrentGameSpeed();	
	
    if player:HasTrait("AllThumbs") and not player:HasTrait("Dextrous") then
		if gamespeed == 1 then		
		player:getModData().AllThumbsTransferredValue = player:getModData().AllThumbsTransferredValue + 0.01;
		end
		if gamespeed == 2 then		
		player:getModData().AllThumbsTransferredValue = player:getModData().AllThumbsTransferredValue + 0.05;
		end	
		if gamespeed == 3 then		
		player:getModData().AllThumbsTransferredValue = player:getModData().AllThumbsTransferredValue + 0.2;
		end		
		if gamespeed == 4 then		
		player:getModData().AllThumbsTransferredValue = player:getModData().AllThumbsTransferredValue + 0.4;
		end			
	end
	oldISInventoryTransferAction_update(self);	
end

local oldISInventoryTransferAction_perform = ISInventoryTransferAction.perform;
function ISInventoryTransferAction:perform()
	-- Weight transfer idea taken from the Evolving Traits World mod (with permission)
	local player = self.character;
	local item = self.item;
	local itemWeight = item:getWeight();

    if player:HasTrait("Disorganized") and not player:HasTrait("Organized") then
		if itemWeight >= 10 then itemWeight = 10 end
		player:getModData().DisorganizedTransferredValue = player:getModData().DisorganizedTransferredValue + itemWeight;
	end
	oldISInventoryTransferAction_perform(self);
end		