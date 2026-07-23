require "DAMN_Armor_Shared";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************
--v2.0.0

CAM79 = CAM79 or {};

function CAM79.activeArmor(player, vehicle)

        --

        for i, tirePart in ipairs ({"TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight"})
        do
            if vehicle:getPartById(tirePart) then
                local part = vehicle:getPartById(tirePart)
                local inventoryItem = part:getInventoryItem();
                    if inventoryItem and inventoryItem:getFullType() == "Base.79camaroGhostTire3" then
                        local tireCond = 20;
                           if part:getCondition() < tireCond then
                            DAMN.Armor:setPartCondition(part, tireCond);
                        end
                    end
            end
        end
   
		--

			local protection = vehicle:getPartById("DAMNBumperFront")
			local inventoryItem = protection:getInventoryItem();
			local part = vehicle:getPartById("EngineDoor")
				if part and protection and part:getInventoryItem() and inventoryItem and part:getModData()
				then 
					if inventoryItem:getFullType() ~= "Base.79camaroBumperFront0" then
						local partCond = tonumber(part:getModData().saveCond)
						if protection:getCondition() > 0 and partCond
						then
							if part:getCondition() < partCond
							then
								DAMN.Armor:setPartCondition(part, partCond);
								local cond = protection:getCondition() - (ZombRandBetween(0,100) <= 50 and ZombRandBetween(0,4) or 0);
								DAMN.Armor:setPartCondition(protection, cond);
							end
						end
					elseif inventoryItem:getFullType() == "Base.79camaroBumperFront0" then
						local partCond = tonumber(part:getModData().saveCond)
						if protection:getCondition() > 0 and partCond
						then
							if part:getCondition() < partCond
							then
								DAMN.Armor:setPartCondition(part, partCond);
								local cond = protection:getCondition() - ZombRandBetween(1,12);
								DAMN.Armor:setPartCondition(protection, cond);
							end
						end
					end
					else
						local part = vehicle:getPartById("Engine")
							if protection and inventoryItem and part and part:getModData()
							then
								if inventoryItem:getFullType() ~= "Base.79camaroBumperFront0" then
									local partCond = tonumber(part:getModData().saveCond)
									if protection:getCondition() > 0 and partCond
									then
										if part:getCondition() < partCond
										then
											DAMN.Armor:setPartCondition(part, partCond);
											local cond = protection:getCondition() - ZombRandBetween(1,3);
											DAMN.Armor:setPartCondition(protection, cond);
										end
									end
								end
							end
				end

		--

        local protection = vehicle:getPartById("DAMNBumperRear")
        local inventoryItem = protection:getInventoryItem();
        local part = vehicle:getPartById("TrunkDoor")
            if part and protection and inventoryItem and part:getModData()
            then 
                local partCond = tonumber(part:getModData().saveCond)
                if protection:getCondition() > 0 and partCond
                then
                    if part:getCondition() < partCond
                    then
                        DAMN.Armor:setPartCondition(part, partCond);
                        local cond = protection:getCondition() - ZombRandBetween(1,9);
                        DAMN.Armor:setPartCondition(protection, cond);
                    end
                end
            end	

		--

			for partId, armorPartId in pairs({
				["WindowFrontLeft"] = "DAMNFrontLeftArmor",
				["WindowFrontRight"] = "DAMNFrontRightArmor",
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
				["HeadlightLeft"] = "DAMNBumperFront",
				["HeadlightRight"] = "DAMNBumperFront",
				["HeadlightRearLeft"] = "DAMNBumperRear",
				["HeadlightRearRight"] = "DAMNBumperRear",
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

			local protection = vehicle:getPartById("DAMNWindshieldArmor")
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

		for i, freezeState in ipairs ({"DAMNSpareTire", "CAM79Roofrack"})
				do
					if vehicle:getPartById(freezeState) then
						local part = vehicle:getPartById(freezeState)
						local freezeCond = tonumber(part:getModData().saveCond)
					    	if freezeCond and part:getCondition() < freezeCond then
					    		DAMN.Armor:setPartCondition(part, freezeCond)
							end
					end
			end

		--

			local protection = vehicle:getPartById("DAMNWindshieldRearArmor")
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

        --temp tire fix

			for i, tempPart in ipairs ({"TireFrontLeft", "TireFrontRight", "TireRearLeft", "TireRearRight"})
				do
					if vehicle:getPartById(tempPart) then
						local part = vehicle:getPartById(tempPart)
					    	if part:getContainerContentAmount() < 1 then
								DAMN.Parts:setContainerAmount(part, DAMN.Armor["tireCTISPressure"]);
							end
					end
			end

end

DAMN.Armor:add("Base.79camaro", CAM79.activeArmor);
DAMN.Armor:add("Base.79camaroRS", CAM79.activeArmor);
DAMN.Armor:add("Base.79camaroZ28", CAM79.activeArmor);
DAMN.Armor:add("Base.79camaroGhost", CAM79.activeArmor);