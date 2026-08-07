require "TimedActions/ISFitnessAction"

local default_update = ISFitnessAction.update
local default_stop = ISFitnessAction.stop
local default_start = ISFitnessAction.start
local default_exeLooped = ISFitnessAction.exeLooped

local currentExercise = nil
local perk_boost_map = {
    [1] = 1.75,
    [2] = 2,
    [3] = 2.25,
}

function ISFitnessAction:exeLooped()
	player=self.character;
	boredom=player:getStats():get(CharacterStat.BOREDOM)
	unhappyness=player:getStats():get(CharacterStat.UNHAPPINESS)
	stress=player:getStats():get(CharacterStat.STRESS)
	StressFromCigarettes=player:getStats():get(CharacterStat.NICOTINE_WITHDRAWAL)
	anger=player:getStats():get(CharacterStat.ANGER)
	
	if not getActivatedMods():contains("DynamicTraits") then
		player:getStats():remove(CharacterStat.BOREDOM, (0.33*SandboxVars.FWOFitness.BoredomMultiplier))
		player:getStats():remove(CharacterStat.UNHAPPINESS, (0.33*SandboxVars.FWOFitness.UnhappynessMultiplier))
		player:getStats():remove(CharacterStat.STRESS , 0.004 );
	--	if stress < 0 then
	--		player:getStats():setStress(0);
	--	end
		player:getStats():remove(CharacterStat.NICOTINE_WITHDRAWAL ,  0.0004);
	--	if StressFromCigarettes < 0 then
	--		player:getStats():setStressFromCigarettes(0);
	--	end
		player:getStats():remove(CharacterStat.ANGER , 0.004);
	end 
	
	default_exeLooped(self)
end

local function calcMulExe(player, perkType, perkLvl, PercRegNum)
	local mulXP = 1
	local playerFitness = player:getFitness()
	--print(perkType)
	if SandboxVars.FWOFitness.InitialPerkBonus then
		local perkBoost = player:getXp():getPerkBoost(perkType)

		if perk_boost_map[perkBoost] then
            mulXP = mulXP * perk_boost_map[perkBoost]
        end
		--print("1 InitialPerkBonus xp: ", mulXP)
	end
	if SandboxVars.FWOFitness.currentExerciseRegularityBonus and currentExercise ~= nil then
		mulXP = mulXP + ((playerFitness:getRegularity(currentExercise)-SandboxVars.FWOFitness.currentExerciseOffset)*SandboxVars.FWOFitness.currentExerciseRate)/100
		--print("2 currentExe xp: ", mulXP)
	end
	if SandboxVars.FWOFitness.AverageExerciseRegularityBonus then
		mulXP = mulXP + ((PercRegNum/100) * SandboxVars.FWOFitness.AverageExerciseRegularityBonus)
		--print("3 Average xp: ", mulXP)
	end
	if SandboxVars.FWOFitness.LevelBonus then
		mulXP = mulXP + ((perkLvl) * SandboxVars.FWOFitness.LevelBonus)
		--print("4 LevelBonus xp: ", mulXP)
	end	
	if SandboxVars.FWOFitness.SpaceOutExercise then	
		if perkType == Perks.Strength then 		
			if playerFitness:getCurrentExeStiffnessTimer("arms") < 60 and playerFitness:getCurrentExeStiffnessTimer("arms") > 0   then
				mulXP = mulXP * SandboxVars.FWOFitness.SpaceOutExerciseNegative
				--print("5 tired xp: ", mulXP)
			end	
		elseif	perkType == Perks.Fitness then
			if (playerFitness:getCurrentExeStiffnessTimer("legs") < 60 and playerFitness:getCurrentExeStiffnessTimer("legs") > 0) or (playerFitness:getCurrentExeStiffnessTimer("abs") < 60 and playerFitness:getCurrentExeStiffnessTimer("abs") > 0 ) then
				mulXP = mulXP * SandboxVars.FWOFitness.SpaceOutExerciseNegative
				--print("5 tired xp: ", mulXP)
			end
		end
	end
	if SandboxVars.FWOFitness.RestedBonus then
		if playerFitness:onGoingStiffness() then
			mulXP = mulXP * SandboxVars.FWOFitness.RestedBonusNegative
			--print("6 stiff xp: ", mulXP)
		end
	end
	if SandboxVars.FWOFitness.XPMultiplier then
		mulXP = mulXP * SandboxVars.FWOFitness.XPMultiplier
	end
	if currentExercise == nil then
		mulXP = mulXP * SandboxVars.FWOFitness.PassiveMultiplier
	end

	player:getXp():addXpMultiplier(perkType,mulXP,perkLvl,10)
end
	
local function CheckRegularity()
	local sumAverage = 0
	--print("CheckRegularity")

	for playerIndex=0,getNumActivePlayers()-1 do
		local character = getSpecificPlayer(playerIndex)
		if character and not character:isDead() then
	
			local count = 0
			for k,v in pairs(FitnessExercises.exercisesType) do
				count = count + 1
				sumAverage = sumAverage + character:getFitness():getRegularity(k)
			end		
			sumAverage = math.ceil(sumAverage*100)/100
			local totAverage = math.ceil((sumAverage/count)*100)/100
		
			calcMulExe(character, Perks.Strength, character:getPerkLevel(Perks.Strength), totAverage)
			calcMulExe(character, Perks.Fitness, character:getPerkLevel(Perks.Fitness), totAverage)
		end--alive
	end--for
end	

local function checkRegularityPlayer(self)
	local sumAverage = 0
	character=self.character
	
	local count = 0
	for k,v in pairs(FitnessExercises.exercisesType) do
		count = count + 1
		sumAverage = sumAverage + character:getFitness():getRegularity(k)
	end		
	sumAverage = math.ceil(sumAverage*100)/100
	local totAverage = math.ceil((sumAverage/count)*100)/100
	
	calcMulExe(character, Perks.Strength, character:getPerkLevel(Perks.Strength), totAverage)
	calcMulExe(character, Perks.Fitness, character:getPerkLevel(Perks.Fitness), totAverage)
end

local function disableMultiplier(self)
	for playerIndex=0,getNumActivePlayers()-1 do
		local character = getSpecificPlayer(playerIndex)
		if character and not character:isDead() then
			character:getXp():getMultiplierMap():remove(Perks.Fitness);
			character:getXp():getMultiplierMap():remove(Perks.Strength);
--			character:getStats():save();
		end
	end
end

function ISFitnessAction:start() 
	currentExercise = self.exercise
	checkRegularityPlayer(self)
	default_start(self)
end

function ISFitnessAction:stop()	
	currentExercise = nil
	checkRegularityPlayer(self)
	default_stop(self)
end


Events.OnGameStart.Add(CheckRegularity)
Events.OnConnected.Add(CheckRegularity)

Events.OnDisconnect.Add(disableMultiplier)
Events.OnSave.Add(disableMultiplier)
--Events.OnPostSave.Add(disableMultiplier)

Events.EveryTenMinutes.Add(CheckRegularity)