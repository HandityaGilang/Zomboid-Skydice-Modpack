
local SOTOSbvars = SandboxVars.SOTO;

-- REMOVE SUNDAY DRIVER
function SOTOremoveSundayDriver()
    local player = getPlayer()
    
    if player:HasTrait("SundayDriver") then

        if player:getModData().SundayDriverMinsWhileDriving == nil then
            player:getModData().SundayDriverMinsWhileDriving = 0
        end

        -- Настройки в **часах**
        local SundayDriverHoursToRemoveMin = SOTOSbvars.SundayDriverHoursToRemoveMin -- Например, 60 (это 60 часов)
        local SundayDriverHoursToRemoveMax = SOTOSbvars.SundayDriverHoursToRemoveMax -- Например, 80 (это 80 часов)

        -- Конвертируем **часы** в **минуты**
        local SundayDriverMinsToRemoveMin = SundayDriverHoursToRemoveMin * 60
        local SundayDriverMinsToRemoveMax = SundayDriverHoursToRemoveMax * 60
        local SundayDriverMinsToRemoveDiff = SundayDriverMinsToRemoveMax - SundayDriverMinsToRemoveMin
        local SundayDriverMinsToRemove = SundayDriverMinsToRemoveMin + ZombRand(SundayDriverMinsToRemoveDiff)

        -- Коррекция для FastLearner и SlowLearner
        if player:HasTrait("FastLearner") then
            SundayDriverMinsToRemove = SundayDriverMinsToRemove * 0.7
        elseif player:HasTrait("SlowLearner") then
            SundayDriverMinsToRemove = SundayDriverMinsToRemove * 1.3
        end

        -- Если игрок за рулем и не спит, учитываем время вождения
        if player:isDriving() and not player:isAsleep() then
            local vehicle = player:getVehicle()
            if vehicle:getCurrentSpeedKmHour() >= 10 then
                player:getModData().SundayDriverMinsWhileDriving = player:getModData().SundayDriverMinsWhileDriving + 1
            end
        end

        -- Удаление трейта после достижения нужного времени
        if player:getModData().SundayDriverMinsWhileDriving >= SundayDriverMinsToRemove then
            if SOTOSbvars.SundayDriverRemovable then
                player:getTraits():remove("SundayDriver")
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SundayDriver"), false, HaloTextHelper.getColorGreen())
                getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50)
                player:getModData().SundayDriverMinsWhileDriving = 0
            end
        end

        -- Ограничиваем значение от 0 до максимального
        if player:getModData().SundayDriverMinsWhileDriving > SundayDriverMinsToRemoveMax then
            player:getModData().SundayDriverMinsWhileDriving = SundayDriverMinsToRemoveMax
        elseif player:getModData().SundayDriverMinsWhileDriving < 0 then
            player:getModData().SundayDriverMinsWhileDriving = 0
        end
    end
end


-- REMOVE SMOKER TRAIT
function SOTOremoveSmoker()

	local player = getPlayer();

	if player:HasTrait("Smoker") then

		if player:getModData().SmokerHoursNotSmoking == nil then
			player:getModData().SmokerHoursNotSmoking = 0;
		end		
	
		-- Smoker Hours Data
		local SmokerHoursToRemoveMin = SOTOSbvars.SmokerHoursToRemoveMin; -- 672
		local SmokerHoursToRemoveMax = SOTOSbvars.SmokerHoursToRemoveMax; -- 768
		local SmokerHoursToRemoveDiff = SmokerHoursToRemoveMax - SmokerHoursToRemoveMin;	
		local SmokerHoursToRemove = SmokerHoursToRemoveMin + ZombRand(SmokerHoursToRemoveDiff); -- 28-32 days
		local SmokerHoursSinceLastSmoke = player:getTimeSinceLastSmoke();		

		if SmokerHoursSinceLastSmoke >= 10 then
			player:getModData().SmokerHoursNotSmoking = player:getModData().SmokerHoursNotSmoking + 1;
			else
				player:getModData().SmokerHoursNotSmoking = player:getModData().SmokerHoursNotSmoking - 3;
		end
		if player:getModData().SmokerHoursNotSmoking > 768 then
			player:getModData().SmokerHoursNotSmoking = 768;	
			elseif player:getModData().SmokerHoursNotSmoking < 0 then
				player:getModData().SmokerHoursNotSmoking = 0;
		end

		if player:getModData().SmokerHoursNotSmoking >= SmokerHoursToRemove and player:HasTrait("Smoker") then
			if SOTOSbvars.SmokerRemovable == true then
				player:setTimeSinceLastSmoke(0);
				player:getStats():setStressFromCigarettes(0);
				player:getTraits():remove("Smoker");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), false, HaloTextHelper.getColorGreen());
				getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
			end
		end	
	--	print("SmokerHoursToRemove: " .. SmokerHoursToRemove);
	--	print("SmokerHoursSinceLastSmoke: " .. SmokerHoursSinceLastSmoke);	
	--	print("SmokerHoursNotSmoking: " .. player:getModData().SmokerHoursNotSmoking);		
	end
end

function SOTOItemsTransfer(player)
	local player = getPlayer();

	if player:HasTrait("AllThumbs") then
		local AllThumbsValueToRemove = SOTOSbvars.AllThumbsValueToRemove -- 37500	

		if player:getModData().AllThumbsTransferredValue == nil then
			player:getModData().AllThumbsTransferredValue = 0;
		end		
	
		if player:getModData().AllThumbsTransferredValue >= AllThumbsValueToRemove then
			if SOTOSbvars.AllThumbsRemovable == true then
				player:getTraits():remove("AllThumbs");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen());
				getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
			end
		end	
		--	print("AllThumbsValueToRemove: " .. AllThumbsValueToRemove);
		--	print("AllThumbsTransferredValue: " .. player:getModData().AllThumbsTransferredValue);	
	end

	if player:HasTrait("Disorganized") then
		local DisorganizedValueToRemove = SOTOSbvars.DisorganizedValueToRemove -- 37500		
	
		if player:getModData().DisorganizedTransferredValue == nil then
			player:getModData().DisorganizedTransferredValue = 0;
		end			
		if player:getModData().DisorganizedTransferredValue >= DisorganizedValueToRemove then
			if SOTOSbvars.DisorganizedRemovable == true then
				player:getTraits():remove("Disorganized");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen());
				getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);	
			end
		end		
		--	print("DisorganizedValueToRemove: " .. DisorganizedValueToRemove);
		--	print("DisorganizedTransferredValue: " .. player:getModData().DisorganizedTransferredValue);	
	end
	
end

Events.EveryHours.Add(SOTOremoveSmoker);
Events.EveryOneMinute.Add(SOTOremoveSundayDriver);
Events.EveryOneMinute.Add(SOTOItemsTransfer);
