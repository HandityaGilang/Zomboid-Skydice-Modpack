require "DAMN_Armor_Shared";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************
--v2.0.0

PRS82 = PRS82 or {};

function PRS82.activeArmor(player, vehicle)

		--

        local protection = vehicle:getPartById("DAMNBumperFront")
        local inventoryItem = protection:getInventoryItem();
        local part = vehicle:getPartById("EngineDoor")
            if part and protection and part:getInventoryItem() and inventoryItem and part:getModData()
            then 
                if inventoryItem:getFullType() ~= "Base.82porsche911turboBumperFront0" and inventoryItem:getFullType() ~= "Base.82porsche911RWBBumperFront1" then
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
                elseif inventoryItem:getFullType() == "Base.82porsche911turboBumperFront0" or inventoryItem:getFullType() == "Base.82porsche911RWBBumperFront1" then
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
                    local protection = vehicle:getPartById("DAMNBumperFront")
                    local inventoryItem = protection:getInventoryItem();
                    local part = vehicle:getPartById("Engine")
                        if protection and inventoryItem and part and part:getModData()
                        then
                            if inventoryItem:getFullType() ~= "Base.82porsche911turboBumperFront0" and inventoryItem:getFullType() ~= "Base.82porsche911RWBBumperFront1" then
                                local partCond = tonumber(part:getModData().saveCond)
                                if protection:getCondition() > 0 and partCond
                                then
                                    if part:getCondition() < partCond
                                    then
                                        KI5:sendVehicleCommandWrapper(player, part, "setPartCondition", {
                                            condition = partCond
                                        })
                                        local cond = protection:getCondition() - ZombRandBetween(1,4);
                                        KI5:sendVehicleCommandWrapper(player, protection, "setPartCondition", {
                                            condition = cond
                                        })
                                    end
                                end
                            end
                        end
            end

		--

			local protection = vehicle:getPartById("DAMNBumperRear")
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
				["WindowFrontLeft"] = "DAMNFrontLeftArmor",
				["WindowFrontRight"] = "DAMNFrontRightArmor",
                ["WindowRearLeft"] = "DAMNRearLeftArmor",
				["WindowRearRight"] = "DAMNRearRightArmor",
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

		for i, freezeState in ipairs ({"DAMNSpareTireTrunk", "PRS82Roofrack",})
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
end

DAMN.Armor:add("Base.82porsche911turbo", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911rwb", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911sc", PRS82.activeArmor);
DAMN.Armor:add("Base.82porsche911targa", PRS82.activeArmor);