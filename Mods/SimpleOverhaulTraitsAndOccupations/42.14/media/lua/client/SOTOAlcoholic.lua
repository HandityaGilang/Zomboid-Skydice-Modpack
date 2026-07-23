---------------------------------
-- SOTO ALCOHOLIC TRAIT SYSTEM --
---------------------------------

require "TimedActions/ISDrinkFluidAction"

local SOTOSbvars = SandboxVars.SOTO

local AlcoStage1 = 144 -- 24h
local AlcoStage2 = 288 -- 48h
local AlcoStage3 = 576 -- 96h

local AlcoBaseRemoveTicks = 6480

---------------------
-- ALCOHOLIC MAIN --
---------------------
local function SOTOAlcoholicMain()
	local player = getPlayer()
	if not player or not player:hasTrait(SOTO.CharacterTrait.ALCOHOLIC) then return end

	local AlcoRemovable = SOTOSbvars.AlcoholicRemovable == true
	local AlcoRemoveHoursMIN = SOTOSbvars.AlcoholicHoursToRemoveMin -- or 1032
	local AlcoRemoveHoursMAX = SOTOSbvars.AlcoholicHoursToRemoveMax -- or 1128

	local AlcoRemoveTicksMIN = AlcoRemoveHoursMIN * 6
	local AlcoRemoveTicksMAX = AlcoRemoveHoursMAX * 6

	local modData = player:getModData()
	modData.AlcoholicTimeSinceLastDrink = modData.AlcoholicTimeSinceLastDrink or 0

	local ticks = modData.AlcoholicTimeSinceLastDrink
	modData.AlcoholicTimeSinceLastDrink =
	math.min(modData.AlcoholicTimeSinceLastDrink + 1, AlcoRemoveTicksMAX)
		
	--print(string.format("AlcoholicTSLD: %.10f", modData.AlcoholicTimeSinceLastDrink))

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
		local randomThreshold =
		AlcoRemoveTicksMIN + ZombRand(AlcoRemoveTicksMAX - AlcoRemoveTicksMIN)

		if ticks >= randomThreshold then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.ALCOHOLIC)
		player:getCharacterTraits():add(SOTO.CharacterTrait.FORMER_ALCOHOLIC)

		modData.AlcoholicTimeSinceLastDrink = 0
		modData.FormerAlcoholicRelapseChance = 100
		modData.FormerAlcoholicDaysSober = 0

		--HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholic"), false, HaloTextHelper.getColorGreen())
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_formeralcoholic"), false, HaloTextHelper.getColorGreen())

		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.5)
				--print("FORMER ALCOHOLIC NOW")
		end
	end
	-- Debug	
	--print("ALCOHOLIC TIMER: " .. ticks .. " ticks (" .. math.floor(ticks / 6) .. " hours)")
	--print(string.format("AlcoRemoveHoursMIN: %.0f", AlcoRemoveHoursMIN))
	--print(string.format("AlcoRemoveHoursMAX: %.0f", AlcoRemoveHoursMAX))
end

-----------------------
-- WITHDRAWAL FX --
-----------------------
local function SOAlcoholicEffects(player, ticks)
	if not player:hasTrait(SOTO.CharacterTrait.ALCOHOLIC) then return end

	local head = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Head"))
	local painEffect = player:getPainEffect()
	local currentHeadPain = head:getPain()

	if ticks >= AlcoStage1 and ticks < AlcoStage2 then
	SOAddBoredom(player, 100, 0.05)

	elseif ticks >= AlcoStage2 and ticks < AlcoStage3 then
	SOAddThirst(player, 50, 0.00001)
	SOAddBoredom(player, 100, 0.05)
	SOAddUnhappiness(player, 100, 0.025)

	elseif ticks >= AlcoStage3 then
	SOAddThirst(player, 50, 0.00001)
	SOAddFatigue(player, 50, 0.00001)
	SOAddStress(player, 100, 0.00035)
	SOAddBoredom(player, 100, 0.05)

		if painEffect <= 0 then
			if currentHeadPain <= (player:getModData().AlcoholicPainThreshold or 50) then
			SOAddPain(player, 100, "Head", 5)
			end
		end

		if player:getStats():get(CharacterStat.FOOD_SICKNESS) <= (player:getModData().AlcoholicSicknessThreshold or 50) then
		SOAddFoodSickness(player, 100, 1)
		end
	end
end

--------------------------
-- FORMER RELAPSE CORE --
--------------------------
local function SOFormerAlcoholicRelapseCheck(player, rollback)
	local modData = player:getModData()

	modData.FormerAlcoholicRelapseChance =
	math.min(100, (modData.FormerAlcoholicRelapseChance or 100) + rollback)

	local roll = ZombRand(100)

	--print("RELAPSE ROLL "..roll.." / "..modData.FormerAlcoholicRelapseChance)

	if roll < modData.FormerAlcoholicRelapseChance then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.FORMER_ALCOHOLIC)
		player:getCharacterTraits():add(SOTO.CharacterTrait.ALCOHOLIC)

		modData.AlcoholicTimeSinceLastDrink = 0
		modData.FormerAlcoholicRelapseChance = 0

		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholic"), true, HaloTextHelper.getColorRed())

		--getSoundManager():PlaySound("ZombieSurprisedPlayer", false, 0):setVolume(0.8)
	end
end

---------------------
-- TIMERS --
---------------------
local function SOTOAlcoholicEveryMinute()
	local player = getPlayer()
	if not player then return end

	local modData = player:getModData()
	local ticks = modData.AlcoholicTimeSinceLastDrink or 0

	SOAlcoholicEffects(player, ticks)

	--if player:hasTrait(SOTO.CharacterTrait.FORMER_ALCOHOLIC) then	
		--print("RELAPSE CHANCE " .. modData.FormerAlcoholicRelapseChance)
	--end
	
end

local function SOTOAlcoholicEveryHour()
	local player = getPlayer()
	if not player then return end

	local modData = player:getModData()

	if player:hasTrait(SOTO.CharacterTrait.ALCOHOLIC) then
		modData.AlcoholicSicknessThreshold = ZombRand(46)
		modData.AlcoholicPainThreshold = ZombRand(46)

		--print(string.format("AlcoholicSicknessThreshold : %.0f", modData.AlcoholicSicknessThreshold))	
		--print(string.format("AlcoholicPainThreshold : %.0f", modData.AlcoholicPainThreshold))				
	end

	if player:hasTrait(SOTO.CharacterTrait.FORMER_ALCOHOLIC) then
		modData.FormerAlcoholicDaysSober =
		(modData.FormerAlcoholicDaysSober or 0) + 1

		if modData.FormerAlcoholicDaysSober >= 24 then
			modData.FormerAlcoholicDaysSober = 0
			modData.FormerAlcoholicRelapseChance =
			math.max(5, (modData.FormerAlcoholicRelapseChance or 100) - 1)
		end
	end
end

-- DRINK ACTION OVERRIDES
-- REMEMBER ALCOHOL STRENGTH
local oldStart = ISDrinkFluidAction.start
	function ISDrinkFluidAction:start(...)
	oldStart(self, ...)
	if self.character and self.fluidContainer then
		self.originalAlcoholStrength =
		self.fluidContainer:getProperties():getAlcohol() or 0
	end
end
-- FULL CONSUMPTION
local oldPerform = ISDrinkFluidAction.perform
function ISDrinkFluidAction:perform(...)
	oldPerform(self, ...)

	local player = self.character
	local strength = self.originalAlcoholStrength or 0
	if strength <= 0 then return end

	local modData = player:getModData()

	if player:hasTrait(SOTO.CharacterTrait.ALCOHOLIC) then
		local removeTicks = math.floor(AlcoBaseRemoveTicks * strength)
		if modData.AlcoholicTimeSinceLastDrink >= AlcoStage3 then
		removeTicks = removeTicks * 4
		end
		modData.AlcoholicTimeSinceLastDrink =
		math.max(0, modData.AlcoholicTimeSinceLastDrink - removeTicks)
	end

	if player:hasTrait(SOTO.CharacterTrait.FORMER_ALCOHOLIC) then
		local rollback = math.floor(strength * 100)
		--print("rollback: " .. rollback)
		SOFormerAlcoholicRelapseCheck(player, rollback)
	end
end
-- PARTIAL CONSUMPTION
local oldStop = ISDrinkFluidAction.stop
function ISDrinkFluidAction:stop(...)
	oldStop(self, ...)

	local player = self.character
	local strength = self.originalAlcoholStrength or 0
	local percent = self:getJobDelta() or 0
	if strength <= 0 then return end

	if percent <= 5 then
		--print("PLEASE NO")
		return
	end
	
	if player:hasTrait(SOTO.CharacterTrait.FORMER_ALCOHOLIC) then
		local rollback = math.floor(strength * percent * 100)
		--print("rollback: " .. rollback)
		SOFormerAlcoholicRelapseCheck(player, rollback)
	end
end

-- EVENTS
Events.EveryOneMinute.Add(SOTOAlcoholicEveryMinute)
Events.EveryHours.Add(SOTOAlcoholicEveryHour)
Events.EveryTenMinutes.Add(SOTOAlcoholicMain)
