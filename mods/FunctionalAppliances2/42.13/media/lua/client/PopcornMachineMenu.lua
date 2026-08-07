FAPopcornMachine = FAPopcornMachine or {}

FAPopcornMachine.doBuildMenu = function(player, menu, square, PopcornMachine)
	if ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		PopcornMachine:getContainer():setCustomTemperature(1.5)
	else
		PopcornMachine:getContainer():setCustomTemperature(1)
	end

	PopcornMachine:getContainer():requestSync()
	
	local spriteName = PopcornMachine:getSprite():getName()
	local soundFile = "PopcornMachine_sound"

	menu:addOption(FA.translation.usepopcornmachine,
				  nil,	
				  FAPopcornMachine.onUsePopcornMachine,
				  getSpecificPlayer(player),
				  PopcornMachine,
				  soundFile)
end

FAPopcornMachine.onUsePopcornMachine = function(junk, player, PopcornMachine, soundFile)
	if not FA.walkToFront(player, PopcornMachine) then
		return
	end

	local square = PopcornMachine:getSquare()
	local inv = player:getInventory()
	local instantPopcorn = inv:FindAndReturn("Base.Popcorn")

	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(FA.translation.sayneedagenerator)
		return
	end

	if instantPopcorn then
		ISTimedActionQueue.add(UsePopcornMachine:new(player, PopcornMachine, soundFile, squareToTurn))
	else
		player:Say(FA.translation.sayneedpopcornkernels)
	end
end