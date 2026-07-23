require "DAMN_Armor_Shared";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************
--v2.0.0

PRS82 = PRS82 or {};

function PRS82.activeArmor(player, vehicle)

		--

			local protection = vehicle:getPartById("PRS82FrontBumper")
			local inventoryItem = protection:getInventoryItem();
			local part = vehicle:getPartById("EngineDoor")
				if part and protection and inventoryItem and part:getModData()
				then 
						local partCond = tonumber(part:getModData().saveCond)
						if protection:getCondition() > 0 and partCond
						then
							if part:getCondition() < partCond
							then
								DAMN.Armor:setPartCondition(part, partCond);
								local cond = protection:getCondition() - (ZombRandBetween(0,100) <= 65 and ZombRandBetween(0,5) or 0);
								DAMN.Armor:setPartCondition(protection, cond);
							end
						end
				else
					local protection = vehicle:getPartById("PRS82FrontBumper")
					local inventoryItem = protection:getInventoryItem();
					local part = vehicle:getPartById("Engine")
						if protection and inventoryItem and part and part:getModData()
						then
								local partCond = tonumber(part:getModData().saveCond)
								if protection:getCondition() > 0 and partCond
								then
									if part:getCondition() < partCond
									then
										DAMN.Armor:setPartCondition(part, partCond);
										local cond = protection:getCondition() - ZombRandBetween(1,4);
										DAMN.Armor:setPartCondition(protection, cond);
									end
								end
						end
				end

		--

			local protection = vehicle:getPartById("PRS82RearBumper")
				if protection 
				then
				    local part = vehicle:getPartById("TrunkDoor")
				    if part and protection and part:getInventoryItem() and protection:getInventoryItem() and part:getModData()
				    then 
				        local partCond = tonumber(part:getModData().saveCond)
				        if protection:getCondition() > 0 and partCond and part:getCondition() < partCond
				        then
				            DAMN.Armor:setPartCondition(part, partCond);
				            local cond = protection:getCondition() - (ZombRandBetween(0,100) <= 75 and ZombRandBetween(0,5) or 0);
				            DAMN.Armor:setPartCondition(protection, cond);
				        end
				    end
				end

		--

			for partId, armorPartId in pairs({
				["WindowFrontLeft"] = "PRS82FrontLeftArmor",
				["WindowFrontRight"] = "PRS82FrontRightArmor",
                ["WindowRearLeft"] = "PRS82RearLeftArmor",
				["WindowRearRight"] = "PRS82RearRightArmor",
			}) do
				local part = vehicle:getPartById(partId);
				local protection = vehicle:getPartById(armorPartId);
				if protection and protection:getInventoryItem() and part and part:getModData()
				then
					local partCond = tonumber(part:getModData().saveCond);
					if protection:getCondition() > 0 and partCond and part:getCondition() < partCond
					then
						DAMN.Armor:setPartCondition(part, partCond);
                        local cond = protection:getCondition() - ZombRandBetween(0,2)
						DAMN.Armor:setPartCondition(protection, cond);
					end
				end
			end

		--

			for partId, armorPartId in pairs({
				["HeadlightLeft"] = "PRS82FrontBumper",
				["HeadlightRight"] = "PRS82FrontBumper",
				["HeadlightRearLeft"] = "PRS82RearBumper",
				["HeadlightRearRight"] = "PRS82RearBumper",
			}) do
				local part = vehicle:getPartById(partId);
				local protection = vehicle:getPartById(armorPartId);
				if protection and protection:getInventoryItem() and part and part:getModData()
				then
					local partCond = tonumber(part:getModData().saveCond);
					if protection:getCondition() > 0 and partCond and part:getCondition() < partCond
					then
						DAMN.Armor:setPartCondition(part, partCond);
					end
				end
			end

		--

			local protection = vehicle:getPartById("PRS82WindshieldArmor")
			local part = vehicle:getPartById("Windshield")
			if protection and protection:getInventoryItem() and part and part:getModData()
			then
				local partCond = tonumber(part:getModData().saveCond)
				if protection:getCondition() > 0 and partCond
				then
					if part:getCondition() < partCond
					then
						DAMN.Armor:setPartCondition(part, partCond);
						local cond = protection:getCondition() - (ZombRandBetween(0,100) <= 65 and ZombRandBetween(0,3) or 0)
						DAMN.Armor:setPartCondition(protection, cond);
					end
				end
			end

		--

		for i, freezeState in ipairs ({"PRS82Spare", "PRS82Roofrack",})
				do
					if vehicle:getPartById(freezeState) then
						local part = vehicle:getPartById(freezeState)
						local freezeCond = tonumber(part:getModData().saveCond)
					    	if freezeCond and part:getCondition() < freezeCond then
					    		DAMN.Armor:setPartCondition(part, freezeCond);
							end
					end
			end

		--

			local protection = vehicle:getPartById("PRS82WindshieldRearArmor")
			local part = vehicle:getPartById("WindshieldRear")
			if protection and protection:getInventoryItem() and part and part:getModData()
			then
				local partCond = tonumber(part:getModData().saveCond)
				if protection:getCondition() > 0 and partCond
				then
					if part:getCondition() < partCond
					then
						DAMN.Armor:setPartCondition(part, partCond);
						local cond = protection:getCondition() - (ZombRandBetween(0,100) <= 65 and ZombRandBetween(0,3) or 0)
						DAMN.Armor:setPartCondition(protection, cond);
					end
				end
			end
end

DAMN.Armor:add("Base.82porsche911turbo", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911rwb", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911sc", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911targa", PRS82.activeArmor);