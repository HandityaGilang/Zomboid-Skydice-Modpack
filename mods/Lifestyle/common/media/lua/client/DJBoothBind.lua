--------------------------------------------------------------------------------------------------
--		----	  |			  |			|		 |				|    --    |      ----			--
--		----	  |			  |			|		 |				|    --	   |      ----			--
--		----	  |		-------	   -----|	 ---------		-----          -      ----	   -------
--		----	  |			---			|		 -----		------        --      ----			--
--		----	  |			---			|		 -----		-------	 	 ---      ----			--
--		----	  |		-------	   ----------	 -----		-------		 ---      ----	   -------
--			|	  |		-------			|		 -----		-------		 ---		  |			--
--			|	  |		-------			|	 	 -----		-------		 ---		  |			--
--------------------------------------------------------------------------------------------------

local djboothbinding = false

local DJloopBeat = 0

function DJKeypress(keyNum)

local scratch = {"scratch1","scratch2","scratch3","scratch4","scratch5","scratch6","scratch7","scratch8","scratch9","scratch10","scratch11"};
local idxScratch
local rewind = {"rewind1","rewind2","rewind3","rewind4"};
local idxRewind
local woosh = {"woosh1","woosh2","woosh3","woosh4","woosh5","woosh6"};
local idxWoosh
local impact = {"impact1","impact2","impact3","impact4","impact5"};
local idxImpact
local crowd = {"crowd1","crowd2","crowd3","crowd4"};
local idxCrowd
local war = {"war1","war2","war3","war4"};
local idxWar
local synth = {"synth1","synth2","synth3","synth4"};
local idxSynth
local airhorn = {"airhorn1","airhorn2","airhorn3"};
local idxAirhorn
local siren = {"siren1","siren2","siren3","siren4"};
local idxSiren

	if not getPlayer() then
		return
	end

    if getPlayer() and not getPlayer():getModData().PlayingDJBooth then
	
		if DJloopBeat and
		DJloopBeat ~= 0 then
			--getSoundManager():StopSound(DJloopBeat);
			getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
			--print("loop stop not playing")
		end
	
        return
    end
	if djboothbinding ~= true then
		return
	end
    if getPlayer() and not getPlayer():getModData().DJNotFailstate then
	
		if DJloopBeat and
		DJloopBeat ~= 0 then
			--getSoundManager():StopSound(DJloopBeat);
			getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
			--print("loop stop failstate")
		end
		
        return
    end

	local DJmusicLevel = getPlayer():getPerkLevel(Perks.Music)

idxScratch = ZombRand(#scratch) + 1
idxRewind = ZombRand(#rewind) + 1
idxWoosh = ZombRand(#woosh) + 1
idxImpact = ZombRand(#impact) + 1
idxCrowd = ZombRand(#crowd) + 1
idxWar = ZombRand(#war) + 1
idxSynth = ZombRand(#synth) + 1
idxAirhorn = ZombRand(#airhorn) + 1
idxSiren = ZombRand(#siren) + 1
local DJSoundboard = {}
--Numpad 1-9
	DJSoundboard[79] = {mainKeys = scratch[idxScratch], isHoldingShift = "NotDone"} --numpad 1 Scratches, shift is " " for next level
	DJSoundboard[80] = {mainKeys = rewind[idxRewind], isHoldingShift = "NotDone"} --numpad 2 Rewind, shift is " " for next level
	DJSoundboard[81] = {mainKeys = woosh[idxWoosh], isHoldingShift = "NotDone"} --numpad 3 Woosh, shift is " " for next level
	DJSoundboard[75] = {mainKeys = impact[idxImpact], isHoldingShift = "NotDone"} --numpad 4 Impact, shift is " " for next level
	DJSoundboard[76] = {mainKeys = crowd[idxCrowd], isHoldingShift = "NotDone"} --numpad 5 Crowd, shift is " " for next level
	DJSoundboard[77] = {mainKeys = war[idxWar], isHoldingShift = "NotDone"} --numpad 6 War, shift is " " for next level
	DJSoundboard[71] = {mainKeys = synth[idxSynth], isHoldingShift = "NotDone"} --numpad 7 Synth, shift is " " for next level
	DJSoundboard[72] = {mainKeys = airhorn[idxAirhorn], isHoldingShift = "NotDone"} --numpad 8 Airhorn, shift is " " for next level
	DJSoundboard[73] = {mainKeys = siren[idxSiren], isHoldingShift = "NotDone"} --numpad 9 Sirens, shift is " " for next level
--Numpad 1-9
	DJSoundboard[44] = {mainKeys = "electronickick", isHoldingShift = "NotDone"} --numpad 1 Scratches, shift is " " for next level
	DJSoundboard[45] = {mainKeys = "kickdrum", isHoldingShift = "NotDone"} --numpad 2 Rewind, shift is " " for next level
	DJSoundboard[46] = {mainKeys = "safarikick", isHoldingShift = "NotDone"} --numpad 3 Woosh, shift is " " for next level
	DJSoundboard[47] = {mainKeys = "electronicsnaredrum", isHoldingShift = "NotDone"} --numpad 4 Impact, shift is " " for next level
	DJSoundboard[48] = {mainKeys = "snare", isHoldingShift = "NotDone"} --numpad 1 Scratches, shift is " " for next level
	DJSoundboard[49] = {mainKeys = "percussionsnap", isHoldingShift = "NotDone"} --numpad 2 Rewind, shift is " " for next level
	DJSoundboard[50] = {mainKeys = "electronicclap", isHoldingShift = "NotDone"} --numpad 3 Woosh, shift is " " for next level
	DJSoundboard[51] = {mainKeys = "openhat", isHoldingShift = "NotDone"} --numpad 4 Impact, shift is " " for next level

--ENDLOOP
	DJSoundboard[41] = {mainKeys = "NOSOUND", isHoldingShift = "NOSOUND"} --" , this is used to kill the loop
--Numbers 1-9
	DJSoundboard[2] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdrumbeats1"} --1 , shift is "Drum Loop 125BPM" for next level
	DJSoundboard[3] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdrumbeats2"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[4] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdrumbeats3"} --2 , shift is "808 Loop 125BPM" for next level

	DJSoundboard[5] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdreamscape1"} --1 , shift is "Drum Loop 125BPM" for next level
	DJSoundboard[6] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdreamscape3"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[7] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdreamscape2"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[8] = {mainKeys = "NotDone", isHoldingShift = "DJLoopsdreamscape4"} --2 , shift is "808 Loop 125BPM" for next level

	DJSoundboard[9] = {mainKeys = "NotDone", isHoldingShift = "DJLoopselectrobeats1"} --1 , shift is "Drum Loop 125BPM" for next level
	DJSoundboard[10] = {mainKeys = "NotDone", isHoldingShift = "DJLoopselectrobeats2"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[11] = {mainKeys = "NotDone", isHoldingShift = "DJLoopselectrobeats3"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[12] = {mainKeys = "NotDone", isHoldingShift = "DJLoopselectrobeats4"} --2 , shift is "808 Loop 125BPM" for next level

	DJSoundboard[19] = {mainKeys = "NotDone", isHoldingShift = "DJLoopslofi1"} --1 , shift is "Drum Loop 125BPM" for next level
	DJSoundboard[20] = {mainKeys = "NotDone", isHoldingShift = "DJLoopslofi2"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[21] = {mainKeys = "NotDone", isHoldingShift = "DJLoopslofi3"} --2 , shift is "808 Loop 125BPM" for next level
	DJSoundboard[22] = {mainKeys = "NotDone", isHoldingShift = "DJLoopslofi4"} --2 , shift is "808 Loop 125BPM" for next level

    if DJSoundboard[keyNum] ~= nil then

		if (DJmusicLevel >= 8) and
		((keyNum == 19) or (keyNum == 20) or (keyNum == 21) or (keyNum == 22)) and 
		((isKeyDown(54)) or (isKeyDown(42)) or (getPlayer():getModData().DJBoothSwitchDPressed == true)) or
		(keyNum == 41) then
		
			if DJloopBeat and
			DJloopBeat ~= 0 then
				getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
			end
			DJloopBeat = getSpecificPlayer(0):getEmitter():playSound(DJSoundboard[keyNum].isHoldingShift);

		elseif (DJmusicLevel >= 6) and
		((keyNum == 9) or (keyNum == 10) or (keyNum == 11) or (keyNum == 12)) and 
		((isKeyDown(54)) or (isKeyDown(42)) or (getPlayer():getModData().DJBoothSwitchCPressed == true)) or
		(keyNum == 41) then
		
			if DJloopBeat and
			DJloopBeat ~= 0 then
				getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
			end
			DJloopBeat = getSpecificPlayer(0):getEmitter():playSound(DJSoundboard[keyNum].isHoldingShift);

		elseif (DJmusicLevel >= 4) and
		((keyNum == 5) or (keyNum == 6) or (keyNum == 7) or (keyNum == 8)) and 
		((isKeyDown(54)) or (isKeyDown(42)) or (getPlayer():getModData().DJBoothSwitchBPressed == true)) or
		(keyNum == 41) then
		
			if DJloopBeat and
			DJloopBeat ~= 0 then
				getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
			end
			DJloopBeat = getSpecificPlayer(0):getEmitter():playSound(DJSoundboard[keyNum].isHoldingShift);

		elseif (DJmusicLevel >= 2) and
		((keyNum == 2) or (keyNum == 3) or (keyNum == 4)) and 
		((isKeyDown(54)) or (isKeyDown(42)) or (getPlayer():getModData().DJBoothSwitchAPressed == true)) or
		(keyNum == 41) then
		
			if DJloopBeat and
			DJloopBeat ~= 0 then
				--getSoundManager():StopSound(DJloopBeat);
				getSpecificPlayer(0):getEmitter():stopSound(DJloopBeat)
				--print("loop stop")
			end
			
			DJloopBeat = getSpecificPlayer(0):getEmitter():playSound(DJSoundboard[keyNum].isHoldingShift);
            --DJloopBeat = getSoundManager():PlayWorldSound(DJSoundboard[keyNum].isHoldingShift, getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
			--print("loop start")
		else
            getSoundManager():PlayWorldSound(DJSoundboard[keyNum].mainKeys, getSpecificPlayer(0):getSquare(), 1, 5, 1, false)
        end
    end
end

function startDJTick ()
	if getPlayer() and getPlayer():hasModData() then
		getPlayer():getModData().PlayingDJBooth = false
	end
	if djboothbinding == false then
		djboothbinding = true
		Events.OnKeyStartPressed.Add(DJKeypress)
	end
    --Events.OnTick.Add(OnRenderTickClientCheckDJ)
end

Events.OnCreatePlayer.Add(startDJTick)