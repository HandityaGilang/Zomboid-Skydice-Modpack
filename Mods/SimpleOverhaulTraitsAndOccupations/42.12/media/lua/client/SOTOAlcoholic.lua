---------------------------------
-- SOTO ALCOHOLIC TRAIT SYSTEM --
---------------------------------

require "TimedActions/ISDrinkFluidAction"

local SOTOSbvars = SandboxVars.SOTO;

local AlcoStage1 = 144 -- 24 hours (in 10-minute ticks) — safe craving
local AlcoStage2 = 288 -- 48 hours — mild withdrawal
local AlcoStage3 = 576 -- 96 hours — strong withdrawal & potential trait removal

local AlcoBaseRemoveTicks = 6480 -- Ticks removed per full alcohol drink * strength

---------------------
-- ALCOHOLIC TRAIT --
---------------------
local function SOAlcoholicTrait()
	local player = getPlayer()

	if player:HasTrait("SOAlcoholic") then

	local AlcoRemovable = SOTOSbvars.AlcoholicRemovable == true
	local AlcoRemoveHoursMIN = SOTOSbvars.AlcoholicHoursToRemoveMin --or 1032
	local AlcoRemoveHoursMAX = SOTOSbvars.AlcoholicHoursToRemoveMax --or 1128

	local AlcoRemoveTicksMIN = AlcoRemoveHoursMIN * 6
	local AlcoRemoveTicksMAX = AlcoRemoveHoursMAX * 6


	local modData = player:getModData()
	modData.AlcoholicTimeSinceLastDrink = modData.AlcoholicTimeSinceLastDrink or 0
	local ticks = modData.AlcoholicTimeSinceLastDrink	

	modData.AlcoholicTimeSinceLastDrink = math.min(modData.AlcoholicTimeSinceLastDrink + 1, AlcoRemoveTicksMAX)

	if not player:isAsleep() then
		-- slowly decrease SleepingTabletDelta to make alcohol resistance
		local delta = player:getSleepingTabletDelta()
		if delta > 0 then
			player:setSleepingTabletDelta(math.max(0, delta - 0.00015))
		end
	end

	-- Debug
	--print(string.format("SleepingTabletDelta: %.10f", player:getSleepingTabletDelta()))
	--print(string.format("SleepingTabletEffect: %.2f", player:getSleepingTabletEffect()))

	if AlcoRemovable then
		local randomThreshold = AlcoRemoveTicksMIN + ZombRand(AlcoRemoveTicksMAX - AlcoRemoveTicksMIN)
		if ticks >= randomThreshold then
			player:getTraits():remove("SOAlcoholic")
			modData.AlcoholicTimeSinceLastDrink = 0
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_soalcoholic"), false, HaloTextHelper.getColorGreen())
			getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50)
			--print("ALCOHOLIC TRAIT REMOVED")
		end
	end	
	-- Debug	
	--print("ALCOHOLIC TIMER: " .. ticks .. " ticks (" .. math.floor(ticks / 6) .. " hours)")
	--print(string.format("AlcoRemoveHoursMIN: %.0f", AlcoRemoveHoursMIN))
	--print(string.format("AlcoRemoveHoursMAX: %.0f", AlcoRemoveHoursMAX))
	end
end

local function SOAlcoholicDropWeapons(player, ticks)

	if player:HasTrait("SOAlcoholic") then
	--	if ticks >= AlcoStage3 and 
		if ZombRand(1001) == 0 then
			if player:getSecondaryHandItem() ~= nil or player:getPrimaryHandItem() ~= nil then
            player:setHaloNote(getText("I drop items!"), 255,255,255,300);
				player:dropHandItems();
			end
		end
	end			
end
--Events.OnWeaponSwingHitPoint.Add(SOAlcoholicDropWeapons);

local function SOAlcoholicInsomnia(player, ticks)
    --local player = getPlayer()
	if not player then return end
	
	if player:HasTrait("SOAlcoholic") then
		if player:isAsleep() and ticks >= AlcoStage3 then
			forceAwakechance = ZombRand(21);
			-- print(string.format("forceAwakechance: %.0f", forceAwakechance))
			if forceAwakechance == 0 then
				player:forceAwake();
			end
		end
	end
end
--Events.EveryHours.Add(SOAlcoholicInsomnia)

local function SOAlcoholicEffects(player, ticks)

	if player:HasTrait("SOAlcoholic") then

		local head = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Head"))
		local painEffect = player:getPainEffect()
		local currentHeadPain = head:getPain()

		if ticks >= AlcoStage1 and ticks < AlcoStage2 then
			-- Stage 1: safe craving
			SOAddBoredom(player, 100, 0.05)

		elseif ticks >= AlcoStage2 and ticks < AlcoStage3 then
			-- Stage 2: medium withdrawal
			SOAddThirst(player, 50, 0.00001)
			SOAddBoredom(player, 100, 0.05)
			SOAddUnhappyness(player, 100, 0.025)

		elseif ticks >= AlcoStage3 then
			-- Stage 3: full withdrawal
			SOAddThirst(player, 50, 0.00001)
			SOAddFatigue(player, 50, 0.00001)
			SOAddStress(player, 100, 0.00035)
			SOAddBoredom(player, 100, 0.05)

			if painEffect <= 0 then
				if currentHeadPain <= (player:getModData().AlcoholicPainThreshold or 50) then
					SOAddPain(player, 100, "Head", 5)
				end		
			end

			if player:getBodyDamage():getFoodSicknessLevel() <= (player:getModData().AlcoholicSicknessThreshold or 50) then
				SOAddFoodSickness(player, 100, 1)
			end
		end
	end
end

local function SOAlcoholicEveryMinute()
    local player = getPlayer()
    if not player or not player:HasTrait("SOAlcoholic") then return end

    local modData = player:getModData()
    local ticks = modData.AlcoholicTimeSinceLastDrink or 0

    SOAlcoholicEffects(player, ticks)
end

local function SOAlcoholicEveryHour()
	local player = getPlayer()
	if not player or not player:HasTrait("SOAlcoholic") then return end

	local modData = player:getModData()

	modData.AlcoholicSicknessThreshold = ZombRand(46) -- 45
	modData.AlcoholicPainThreshold = ZombRand(46) -- 45

	--print(string.format("AlcoholicSicknessThreshold : %.0f", modData.AlcoholicSicknessThreshold))	
	--print(string.format("AlcoholicPainThreshold : %.0f", modData.AlcoholicPainThreshold))		
end

-------------------------------
-- REMEMBER ALCOHOL STRENGTH --
-------------------------------
local oldStart = ISDrinkFluidAction.start
function ISDrinkFluidAction:start(...)
	oldStart(self, ...)
	if self.character:HasTrait("SOAlcoholic") and self.fluidContainer then
		self.originalAlcoholStrength = self.fluidContainer:getProperties():getAlcohol() or 0
	end
end

----------------------
-- FULL CONSUMPTION --
----------------------
local oldPerform = ISDrinkFluidAction.perform
function ISDrinkFluidAction:perform(...)
	oldPerform(self, ...)
	local player = self.character
	local strength = self.originalAlcoholStrength or 0
	if not player:HasTrait("SOAlcoholic") or strength <= 0 then return end

	local modData = player:getModData()
	local removeTicks = math.floor(AlcoBaseRemoveTicks * strength)
	if modData.AlcoholicTimeSinceLastDrink >= AlcoStage3 then
		removeTicks = removeTicks * 4
	end

	modData.AlcoholicTimeSinceLastDrink = math.max(0, modData.AlcoholicTimeSinceLastDrink - removeTicks)

	--player:Say("Alcohol taken. (entire portion)")
	--print(string.format("ALCOHOL DRANK - FULL: AlcoholStrength=%.2f, RemoveTicks=%d", strength, removeTicks))
end

-------------------------
-- PARTIAL CONSUMPTION --
-------------------------
local oldStop = ISDrinkFluidAction.stop
function ISDrinkFluidAction:stop(...)
	oldStop(self, ...)
	local player = self.character
	local strength = self.originalAlcoholStrength or 0
	local percent = self:getJobDelta() or 0
	if not player:HasTrait("SOAlcoholic") or strength <= 0 then return end

	local modData = player:getModData()
	local removeTicks = math.floor(AlcoBaseRemoveTicks * strength * percent)
	if modData.AlcoholicTimeSinceLastDrink >= AlcoStage3 then
		removeTicks = removeTicks * 3
	end

	modData.AlcoholicTimeSinceLastDrink = math.max(0, modData.AlcoholicTimeSinceLastDrink - removeTicks)

	--player:Say("Alcohol taken. (partially)")
	--print(string.format("ALCOHOL DRANK - PARTIAL: AlcoholStrength=%.2f, JobDelta=%.2f, RemoveTicks=%d", strength, percent, removeTicks))
end

------------
-- EVENTS --
------------
Events.EveryOneMinute.Add(SOAlcoholicEveryMinute)
Events.EveryHours.Add(SOAlcoholicEveryHour)
Events.EveryTenMinutes.Add(SOAlcoholicTrait)