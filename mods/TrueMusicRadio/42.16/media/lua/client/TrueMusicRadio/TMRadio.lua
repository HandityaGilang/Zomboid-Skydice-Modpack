require "TCMusicDefenitions"
require "TMRSound"

TMRadio = {}

TMRadio.soundCache = {}

TMRadio.cacheSize = 50	-- number of devices to keep in cache

TMRadio.PlaylistTerminalA = {}
TMRadio.PlaylistTerminalB = {}
TMRadio.PlaylistTerminalC = {}
TMRadio.PlaylistTerminalD = {}
TMRadio.PlaylistTerminalE = {}
TMRadio.PlaylistTerminalMTV = {}

TMRadio.Channels = {}

TMRadio.SongNames = {}

TMRadio.Blacklist = { "Test" }

TMRadio.BlacklistThemeSongs = {
	"CassetteMainTheme",
	"VinylMainTheme",
}

TMRadio.BlacklistTCCacheMPSongs = {
	"CassetteACDCHighwayToHell(1979)",
	"CassetteAirSupplyMakingLoveOutOfNothingAtAll(1983)",
	"CassetteAlabamaChristmasInDixie(1985)",
	"CassetteAliceCooperPoison(1989)",
	"CassetteBeeGeesStayinAlive(1977)",
	"CassetteBlondieCallMe(1978)",
	"CassetteBlondieHeartOfGlass(1976)",
	"CassetteBobbyDarinDreamLover(1987)",
	"CassetteBonJoviLivinOnAPrayer(1986)",
	"CassetteBonJoviYouGiveLoveABadName(1986)",
	"CassetteBoneyMRasputin(1978)",
	"CassetteBonnieTylerHoldingOutForAHero(1984)",
	"CassetteBonnieTylerTotalEclipseOfTheHeart(1983)",
	"CassetteBryanAdamsIDoItForYou(1991)",
	"CassetteCharleyPrideKissAnAngelGoodMorning(1971)",
	"CassetteCyndiLauperTimeAfterTime(1983)",
	"CassetteDeadOrAliveYouSpinMeRound(1984)",
	"CassetteDepecheModePersonalJesus(1989)",
	"CassetteDollyPartonHardCandyChristmas(1982)",
	"CassetteFlattAndScruggsFoggyMountainBreakdown(1968)",
	"CassetteForeignerIWantToKnowWhatLoveIs(1984)",
	"CassetteGeorgeBensonNothingsGonnaChange(1985)",
	"CassetteIsraelKamakawiwooleOverTheRainbow(1990)",
	"CassetteJohnDenverTakeMeHomeCountryRoads(1971)",
	"CassetteJonaLewieStopTheCavalry(1978)",
	"CassetteJoseFelicianoFelizNavidad(1970)",
	"CassetteJourneyDontStopBelievin(1981)",
	"CassetteKennyLogginsDangerZone(1986)",
	"CassetteKissIWasMadeForLovinYou(1979)",
	"CassetteLindaRonstadtAndAaronNevilleDontKnowMuch(1989)",
	"CassetteMetallicaNothingElseMatters(1991)",
	"CassetteMetallicaTheUnforgiven(1991)",
	"CassetteMichaelJacksonBillieJean(1982)",
	"CassetteNirvanaSmellsLikeTeenSpirit(1991)",
	"CassettePaulEngemannPushItToTheLimit(1983)",
	"CassettePaulaAbdulStraightUp(1988)",
	"CassettePepeShadilay(1986)",
	"CassetteQueen39(1975)",
	"CassetteQueenWeAreTheChampions(1977)",
	"CassetteQueenWeWillRockYou(1977)",
	"CassetteREMLosingMyReligion(1991)",
	"CassetteRandyTravisDeeperThanTheHoller(1988)",
	"CassetteRandyTravisOldTimeChristmas(1989)",
	"CassetteScottMcKenzieSanFrancisco(1967)",
	"CassetteSnapRhythmIsADancer(1992)",
	"CassetteSurvivorEyeOfTheTiger(1982)",
	"CassetteTheB52sLoveShack(1989)",
	"CassetteTheBeatlesComeTogether(1969)",
	"CassetteTheBeatlesEleanorRigby(1966)",
	"CassetteThePoguesFairytaleOfNewYork(1987)",
	"CassetteTheTemptationsPapaWasARollingStone(1972)",
	"CassetteTheWeatherGirlsItsRainingMen(1983)",
	"CassetteTotoAfrica(1982)",
	"CassetteTotoHoldTheLine(1978)",
	"CassetteWhamLastChristmas(1984)",
	"CassetteWhitneyHoustonIWillAlwaysLoveYou(1992)",
	"VinylACDCHighwayToHell(1979)",
	"VinylAirSupplyMakingLoveOutOfNothingAtAll(1983)",
	"VinylAlabamaChristmasInDixie(1985)",
	"VinylAliceCooperPoison(1989)",
	"VinylAndyWilliamsItsTheMostWonderfulTimeOfTheYear(1963)",
	"VinylBeeGeesStayinAlive(1977)",
	"VinylBennyGoodmanThatsAPlenty(1931)",
	"VinylBillHaleyRockAroundTheClock(1955)",
	"VinylBingCrosbyIWillBeHomeForChristmas(1943)",
	"VinylBingCrosbyWhiteChristmas(1942)",
	"VinylBingCrosbyWinterWonderland(1945)",
	"VinylBlondieCallMe(1978)",
	"VinylBlondieHeartOfGlass(1976)",
	"VinylBobbyDarinBrandNewHouse(1958)",
	"VinylBobbyDarinDreamLover(1987)",
	"VinylBobbyDarinHallelujahILoveHerSo(1956)",
	"VinylBobbyHelmsJingleBellRock(1957)",
	"VinylBoneyMRasputin(1978)",
	"VinylBootsRandolphYaketySax(1963)",
	"VinylBrendaLeeRockinAroundTheChristmasTree(1958)",
	"VinylDeanMartinWalkingInAWinterWonderland(1959)",
	"VinylEarthaKittSantaBaby(1953)",
	"VinylElvisPresleyBlueChristmas(1957)",
	"VinylElvisPresleyJailhouseRock(1958)",
	"VinylEnricoCarusoUnaFurtivaLagrima(1904)",
	"VinylGeneAutryFrostyTheSnowMan(1951)",
	"VinylGuyMitchellHeartacheByTheNumbers50s(1959)",
	"VinylHankWilliamsLovesickBlues(1949)",
	"VinylJohnFaheySteelGuitarRag(1965)",
	"VinylJohnnyHortonNorthToAlaska(1965)",
	"VinylJudyGarlandHaveYourselfAMerryLittleChristmas(1944)",
	"VinylKirstenFlagstadDieWalkure(1938)",
	"VinylLightninHopkinsJackstropperBlues(1950)",
	"VinylMelCarterHoldMeThrillMeKissMe(1965)",
	"VinylNatKingColeTheChristmasSong(1961)",
	"VinylRickyNelsonTravellinMan(1961)",
	"VinylRighteousBrothersUnchainedMelody(1965)",
	"VinylRobertJohnsonWalkingBlues(1936)",
	"VinylThurlRavenscroftYoureAMeanOneMrGrinch(1966)",
}

TMRadio.BlacklistHolidaySongs = {
	"CassetteAlabamaChristmasInDixie(1985)",
	"CassetteDollyPartonHardCandyChristmas(1982)",
	"CassetteJoseFelicianoFelizNavidad(1970)",
	"CassetteRandyTravisOldTimeChristmas(1989)",
	"CassetteWhamLastChristmas(1984)",
	"VinylAlabamaChristmasInDixie(1985)",
	"VinylAndyWilliamsItsTheMostWonderfulTimeOfTheYear(1963)",
	"VinylBingCrosbyIWillBeHomeForChristmas(1943)",
	"VinylBingCrosbyWhiteChristmas(1942)",
	"VinylBingCrosbyWinterWonderland(1945)",
	"VinylBobbyHelmsJingleBellRock(1957)",
	"VinylBrendaLeeRockinAroundTheChristmasTree(1958)",
	"VinylDeanMartinWalkingInAWinterWonderland(1959)",
	"VinylEarthaKittSantaBaby(1953)",
	"VinylElvisPresleyBlueChristmas(1957)",
	"VinylGeneAutryFrostyTheSnowMan(1951)",
	"VinylJudyGarlandHaveYourselfAMerryLittleChristmas(1944)",
	"VinylNatKingColeTheChristmasSong(1961)",
	"VinylThurlRavenscroftYoureAMeanOneMrGrinch(1966)",
}

-- for checking b42 mods loaded
TMRadio.activatedMods = {}

local mods = getActivatedMods()
for i = 0, mods:size() - 1 do
    local shortId = string.match(mods:get(i), "\\(.+)$")
    TMRadio.activatedMods[shortId] = true
end

-- then if i want to test against it:
--if TMRadio.activatedMods["TheModId"] then
--    ...
--end

-------------------
-- PLAY NEW SONG --
-------------------

TMRadio.PlaySound = function(number, device)
	if not number or not device then
		return
	end

    	local sound = nil
	local deviceData = device:getDeviceData()
    	local t = TMRadio.getData(deviceData)

    	if t then
        	sound = t.sound
    	else
        	sound = TMRSound:new()
    	end

    	if deviceData:isInventoryDevice() then
        	sound:set3D(false)
        	sound:setVolumeModifier(0.6)
    	elseif deviceData:isIsoDevice() then
        	sound:setPosAtObject(device)
        	sound:setVolumeModifier(0.4)
    	elseif deviceData:isVehicleDevice() then
        	local vehiclePart = deviceData:getParent()
        	if vehiclePart then
            		local vehicle = vehiclePart:getVehicle()
            		if vehicle then
                		sound:setEmitter(vehicle:getEmitter()) -- use car's emitter, car radios don't have one
                		if vehicle == getPlayer():getVehicle() then -- player is in the car
                    			sound:set3D(false)
                    			sound:setVolumeModifier(0.8)
                		elseif not TMRadio.VehicleWindowsIntact(vehicle) then
                    			sound:set3D(true)
                    			sound:setVolumeModifier(0.4)
				else
                    			sound:set3D(true)
                    			sound:setVolumeModifier(0.2)
                		end
            		end
        	end
    	end

    	sound:setVolume(deviceData:getDeviceVolume())

	if isClient() then
		if TMRadioClient.PlaylistTerminalA ~= nil and #TMRadioClient.PlaylistTerminalA > 0 then
			--print("Client: getting A from client list")
			TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
		end
		if TMRadioClient.PlaylistTerminalB ~= nil and #TMRadioClient.PlaylistTerminalB > 0 then
			--print("Client: getting B from client list")
			TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
		end
		if TMRadioClient.PlaylistTerminalC ~= nil and #TMRadioClient.PlaylistTerminalC > 0 then
			--print("Client: getting C from client list")
			TMRadio.PlaylistTerminalC = TMRadioClient.PlaylistTerminalC
		end
		if TMRadioClient.PlaylistTerminalD ~= nil and #TMRadioClient.PlaylistTerminalD > 0 then
			--print("Client: getting D from client list")
			TMRadio.PlaylistTerminalD = TMRadioClient.PlaylistTerminalD
		end
		if TMRadioClient.PlaylistTerminalE ~= nil and #TMRadioClient.PlaylistTerminalE > 0 then
			--print("Client: getting E from client list")
			TMRadio.PlaylistTerminalE = TMRadioClient.PlaylistTerminalE
		end
		if TMRadioClient.PlaylistTerminalMTV ~= nil and #TMRadioClient.PlaylistTerminalMTV > 0 then
			--print("Client: getting MTV from client list")
			TMRadio.PlaylistTerminalMTV = TMRadioClient.PlaylistTerminalMTV
		end
		if TMRadioClient.Blacklist ~= nil and #TMRadioClient.Blacklist > 0 then
			--print("Client: getting blacklist from client list")
			TMRadio.Blacklist = TMRadioClient.Blacklist
		end
	end

	if TMRadio.PlaylistTerminalA == nil or #TMRadio.PlaylistTerminalA == 0 then
		--print("Client: A not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if TMRadio.PlaylistTerminalB == nil or #TMRadio.PlaylistTerminalB == 0 then
		--print("Client: B not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end
	if TMRadio.PlaylistTerminalC == nil or #TMRadio.PlaylistTerminalC == 0 then
		--print("Client: C not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalC = ModData.getOrCreate("TMRadioC")
	end
	if TMRadio.PlaylistTerminalD == nil or #TMRadio.PlaylistTerminalD == 0 then
		--print("Client: D not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalD = ModData.getOrCreate("TMRadioD")
	end
	if TMRadio.PlaylistTerminalE == nil or #TMRadio.PlaylistTerminalE == 0 then
		--print("Client: E not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalE = ModData.getOrCreate("TMRadioE")
	end
	if TMRadio.PlaylistTerminalMTV == nil or #TMRadio.PlaylistTerminalMTV == 0 then
		--print("Client: MTV not found in client list, pull from local moddata")
		TMRadio.PlaylistTerminalMTV = ModData.getOrCreate("TMRadioMTV")
	end
	if TMRadio.Blacklist == nil or #TMRadio.Blacklist == 0 then
		--print("Client: Blacklist not found in client list, pull from local moddata")
		TMRadio.Blacklist = ModData.getOrCreate("TMRadioBlacklist")
	end

	if TMRadio.PlaylistTerminalA == nil or #TMRadio.PlaylistTerminalA == 0 then
		--print("Client: A not found in moddata, create default list")
		TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
	end
	if TMRadio.PlaylistTerminalB == nil or #TMRadio.PlaylistTerminalB == 0 then
		--print("Client: B not found in moddata, create default list")
		TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
	end
	if TMRadio.PlaylistTerminalC == nil or #TMRadio.PlaylistTerminalC == 0 then
		--print("Client: C not found in moddata, create default list")
		TMRadio.PlaylistTerminalC = TMRadio.CreatePlaylist()
	end
	if TMRadio.PlaylistTerminalD == nil or #TMRadio.PlaylistTerminalD == 0 then
		--print("Client: D not found in moddata, create default list")
		TMRadio.PlaylistTerminalD = TMRadio.CreatePlaylist()
	end
	if TMRadio.PlaylistTerminalE == nil or #TMRadio.PlaylistTerminalE == 0 then
		--print("Client: E not found in moddata, create default list")
		TMRadio.PlaylistTerminalE = TMRadio.CreatePlaylist()
	end
	if TMRadio.PlaylistTerminalMTV == nil or #TMRadio.PlaylistTerminalMTV == 0 then
		--print("Client: MTV not found in moddata, create default list")
		TMRadio.PlaylistTerminalMTV = TMRadio.CreatePlaylist()
	end

	if TMRadio.Blacklist == nil or #TMRadio.Blacklist == 0 then
		--print("Client: Blacklist not found in moddata, nothing to load")
	end

	local songName = nil

	if deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 then	
		if #TMRadio.PlaylistTerminalA == 0 then
			print("TMRadio: Error processing requested song, playlist A empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalA[number]
		end
	elseif deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 then
		if #TMRadio.PlaylistTerminalB == 0 then
			print("TMRadio: Error processing requested song, playlist B empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalB[number]
		end
	elseif deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 then
		if #TMRadio.PlaylistTerminalC == 0 then
			print("TMRadio: Error processing requested song, playlist C empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalC[number]
		end
	elseif deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 then
		if #TMRadio.PlaylistTerminalD == 0 then
			print("TMRadio: Error processing requested song, playlist D empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalD[number]
		end
	elseif deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 then
		if #TMRadio.PlaylistTerminalE == 0 then
			print("TMRadio: Error processing requested song, playlist E empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalE[number]
		end
	elseif deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV then
		if #TMRadio.PlaylistTerminalMTV == 0 then
			print("TMRadio: Error processing requested song, playlist MTV empty")
			return
		else
    			songName = TMRadio.PlaylistTerminalMTV[number]
		end
	else
		return
	end

	TMRadio.Channels[deviceData:getChannel()] = number

	if songName == nil then
		print("TMRadio: Error processing requested song")
		return
	else
		local musicItem = "Tsarcraft." .. songName
		local displayName = getItemNameFromFullType(musicItem)
		local prettyName = TMRadio.prettyName(displayName)
		if deviceData:getChannel() > 1000 then
			print("TMRadio Channel " .. deviceData:getChannel()/1000 .. "FM: Playing song[" .. number .. "] " .. prettyName)
		else
			print("TMRadio MTV " .. deviceData:getChannel() .. "TV: Playing song[" .. number .. "] " .. prettyName)
		end
		if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRenableRDSDeviceText"):getValue() and SandboxVars.TrueMusicRadio.TMRRadioSongAnnouncements and not isClient() then 
			DynamicRadio.OnNewSong(deviceData:getChannel(), prettyName)
		end
		if not PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRstopMusic"):getValue() then
			sound:play(songName)
		end
	end

	local position = TMRadio.whereAreYou(device)

    	t = t or {}
    	t.device = device
    	t.deviceData = deviceData
    	t.channel = deviceData:getChannel()
    	t.sound = sound
	t.muted = false
	t.x = position.x
	t.y = position.y
	t.z = position.z

    	tickCounter2 = 200

	--print("X: " .. t.x .. " Y: " .. t.y .. " Z: " .. t.z)
	--print("Sound Cache Counter before clean: " .. #TMRadio.soundCache)

	if #TMRadio.soundCache > 0 then
		for index,x in ipairs(TMRadio.soundCache) do
			if x.device == device then
				table.remove(TMRadio.soundCache, index)
			end
		end
	end

    	table.insert( TMRadio.soundCache, 1, t )
    	if #TMRadio.soundCache > TMRadio.cacheSize then
        	for i = TMRadio.cacheSize+1, #TMRadio.soundCache do
            		table.remove(TMRadio.soundCache, i)
        	end
    	end

	print("TMRadio: Soundcache counter after new sound: [" .. #TMRadio.soundCache .. "/" .. TMRadio.cacheSize .. "]")

    	return t
end

--------------------------
-- START ON DEVICE TEXT --
--------------------------

function TMRadio.OnDeviceText(guid, interactCodes, x, y, z, line, device)
    	local radio = nil
	local square = getSquare(x, y, z)
    
    	-- Radio Device: Portable/HAM radio or vehicle radio
	if square then
        	for i = 0, square:getObjects():size()-1 do
        		local item = square:getObjects():get(i)

            		-- Portable/HAM radio or Television
            		--if instanceof(item, "IsoRadio") and item:getDeviceData() ~= nil then
			if (instanceof(item, "IsoRadio") or instanceof(item, "IsoTelevision")) and item:getDeviceData() ~= nil then
               			radio = item
               			break
            		end

            		-- Vehicle radio
            		if instanceof(item, "IsoObject") then
               			local vehicle = square:getVehicleContainer()
                		if vehicle then
                    			local part = vehicle:getPartById("Radio");
                    			if part and part:getDeviceData() then
                      				radio = part
                      				break
                    			end
                		end
			end
            	end
        end

    	if radio == nil and device == nil then
       		return
    	elseif radio == nil then
		radio = device
	end

	local deviceData = radio:getDeviceData()

	if not deviceData:getIsTurnedOn() then
		return
	end

	if deviceData:getDeviceName() == "ValuTech PortaDisc" then
		return
	end

	local radioX = deviceData:getParent():getX()
	local radioY = deviceData:getParent():getY()
	local radioZ = deviceData:getParent():getZ()
	local radioDist = math.sqrt((getPlayer():getX() - radioX) ^ 2 + (getPlayer():getY() - radioY) ^ 2 + (getPlayer():getZ() - radioZ) ^ 2)

	if radioDist > 75 then
		return
	end

	local radioChannel = radio:getDeviceData():getChannel()

	if not radioChannel then
		return
	end

	if not (radioChannel == SandboxVars.TrueMusicRadio.TMRChannel1 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel2 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel3 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel4 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel5 or radioChannel == SandboxVars.TrueMusicRadio.TMRMTV) then
		return
	end

	if SandboxVars.TrueMusicRadio.TMRRadioMoods and line == "[img=music]" then
		local currentUnhappiness = getPlayer():getStats():get(CharacterStat.UNHAPPINESS)
		local currentBoredom = getPlayer():getStats():get(CharacterStat.BOREDOM)
		if currentUnhappiness > 0 then
			local newUnhappiness = math.max(0, currentUnhappiness - 2)
			if isClient() then
				sendClientCommand("TMRadio", "SetStat", {stat = "UNHAPPINESS", amount = newUnhappiness})
			else
				getPlayer():getStats():set(CharacterStat.UNHAPPINESS, newUnhappiness)
			end
		end
		if currentBoredom > 0 then
			local newBoredom = math.max(0, currentBoredom - 2)
			if isClient() then
				sendClientCommand("TMRadio", "SetStat", {stat = "BOREDOM", amount = newBoredom})
			else
				getPlayer():getStats():set(CharacterStat.BOREDOM, newBoredom)
			end
		end
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		if t.device == radio then
			if TMRadio.isPlaying(t) then
				return
			end
		end
	end

	--print("Activated Radio at x: " .. radioX .. " y: " .. radioY .. " z: " .. radioZ)

	local songNumber = TMRadio.ChooseSong(radioChannel)
	if isClient() and not deviceData:isInventoryDevice() then
		local args = {x = radioX, y = radioY, z = radioZ, channel = radioChannel, number = songNumber}
		sendClientCommand("TMRadio", "Play", args)
	else
		if not TMRadio.Channels[radioChannel] then 
			TMRadio.Channels[radioChannel] = songNumber
			TMRadio.PlaySound(songNumber, radio)
		else
			TMRadio.PlaySound(TMRadio.Channels[radioChannel], radio)
		end
	end
end

Events.OnDeviceText.Add(TMRadio.OnDeviceText)

-----------------------------
-- UPDATE RADIO SOUNDCACHE --
-----------------------------

TMRadio.UpdateSoundCache = function(number, channel)
	if not number or not channel then
		return
	end

	TMRadio.Channels[channel] = number

	if #TMRadio.soundCache < 1 then
		return
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		local deviceData = t.device:getDeviceData()
		if deviceData:getChannel() == channel then
			TMRadio.PlaySound(number, t.device)
			--print(channel .. " " .. number)
		end
	end
end

---------------------------
-- INTERACTION OVERRIDES --
---------------------------

-- Thank you Albion for this automatic preset limit adjuster 
local index = __classmetatables[DevicePresets.class].__index

local old_addPreset = index.addPreset
index.addPreset = function(self, ...)
    	local maxPresets = self:getMaxPresets()
    	if self:getPresets():size() >= maxPresets then
        	self:setMaxPresets(maxPresets + 1)
    	end
    	old_addPreset(self, ...)
end

TMRadio.AddOverrides = function()
    	local TMRRWMChannelTV_readPresets = RWMChannelTV.readPresets
    	function RWMChannelTV:readPresets()
    		if self.deviceData and self.deviceData:getDevicePresets() and self.deviceData:getDevicePresets():getPresets() then
			local detectedMPTV = false
			local detectedTMMTV = false
			local detectedEmergencyTV = false
        		self.presets = self.deviceData:getDevicePresets():getPresets()
        		for i = 0, self.presets:size()-1 do
            			local p = self.presets:get(i)
            			self:addComboOption(p:getFrequency(), p:getName())
				--print("Freq: " .. tostring(p:getFrequency()) .. " Name: " .. tostring(p:getName()))
				if p:getName() == "Monty Python TV 24/7" then
					detectedMPTV = true
				end
				if p:getName() == "True Music MTV" then
					detectedTMMTV = true
				end
				if p:getName() == "Emergency TV Station" then
					detectedEmergencyTV = true
				end
        		end
			if not detectedMPTV and TMRadio.activatedMods["MontyPythonTV"] then
				self.deviceData:getDevicePresets():addPreset("Monty Python TV 24/7", 222)
			end
			if not detectedTMMTV and SandboxVars.TrueMusicRadio.ActivateTMRMTV then
				self.deviceData:getDevicePresets():addPreset("True Music MTV", SandboxVars.TrueMusicRadio.TMRMTV)
			end
			if not detectedEmergencyTV and TMRadio.activatedMods["EmergencyTVChannel"] then
				self.deviceData:getDevicePresets():addPreset("Emergency TV Station", 300)
			end
		end
        	TMRRWMChannelTV_readPresets(self)
	end

    	local TMRRWMChannel_doAddPresetButton = RWMChannel.doAddPresetButton
    	function RWMChannel:doAddPresetButton()
		if self.presets and self.deviceData and self.deviceData:getDevicePresets() then
        		if self.presets:size() >= self.deviceData:getDevicePresets():getMaxPresets() then
				self.deviceData:getDevicePresets():setMaxPresets(self.deviceData:getDevicePresets():getMaxPresets() + 1)
			end
		end
        	TMRRWMChannel_doAddPresetButton(self)
	end

    	local TMRRadioAction_performToggleOnOff = ISRadioAction.performToggleOnOff
    	function ISRadioAction:performToggleOnOff()
        	TMRRadioAction_performToggleOnOff(self)
        	local t = TMRadio.getData(self.deviceData)
        	if t then
			if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                		t.muted = false
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can turn it back on
            		end
            		TMRadio.updateVolume(t)
        	elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
			if self.deviceData:getDeviceName() == "ValuTech PortaDisc" then
				return
			end
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
			if isClient() and not self.deviceData:isInventoryDevice() then
				local position = TMRadio.whereAreYou(self.deviceData:getParent())
				local x = position.x
				local y = position.y
				local z = position.z
				local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				if TMRadio.Channels[self.deviceData:getChannel()] > 0 then
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				else
					TMRadio.Channels[self.deviceData:getChannel()] = songNumber
					TMRadio.PlaySound(songNumber, self.deviceData:getParent())
				end
			end
		end
    	end
    
    	local TMRRadioAction_performSetChannel = ISRadioAction.performSetChannel
    	function ISRadioAction:performSetChannel()
		local oldChannel = self.deviceData:getChannel()
		--print("old channel: " .. oldChannel)
		local x = TMRadio.getData(self.deviceData)
		if self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV then
			if x then
                		x.muted = true -- mute sound instead of stopping it, so we can turn it back on
            			TMRadio.updateVolume(x)
			end
		end
        	TMRRadioAction_performSetChannel(self)
		local newChannel = self.deviceData:getChannel()
		--print("new channel: " .. newChannel)
		local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
        	local t = TMRadio.getData(self.deviceData)
		if not isClient() and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
			--print("push to the next song")
			if t then
				TMRadio.UpdateSoundCache(songNumber, self.deviceData:getChannel())
				return
			else
				TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				return
			end
		elseif isClient() and (SandboxVars.TrueMusicRadio.TMRAllowSkipOnServer or getCore():getDebug() or isAdmin()) and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
			print("push to the next song on servers")
			if t then
				local args = {x = t.x, y = t.y, z = t.z, channel = t.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "PlayNext", args)
			end
		elseif t then
			if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                		t.muted = false
			elseif t.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                		t.muted = false
				if isClient() and not self.deviceData:isInventoryDevice() then
					local position = TMRadio.whereAreYou(self.deviceData:getParent())
					local x = position.x
					local y = position.y
					local z = position.z
					local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "Play", args)
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
            		else
                		t.muted = true -- mute sound instead of stopping it, so we can turn it back on
 	           	end
            		TMRadio.updateVolume(t)
		elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
			if isClient() and not self.deviceData:isInventoryDevice() then
				local position = TMRadio.whereAreYou(self.deviceData:getParent())
				local x = position.x
				local y = position.y
				local z = position.z
				local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
				sendClientCommand("TMRadio", "Play", args)
			else
				TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
			end
		end
    	end
    
    	local TMRRadioAction_performSetVolume = ISRadioAction.performSetVolume
    	function ISRadioAction:performSetVolume()
        	if self:isValidSetVolume() then
            		TMRRadioAction_performSetVolume(self)
            		local t = TMRadio.getData(self.deviceData)
            		if t then
                		TMRadio.updateVolume(t)
           		end
        	end
    	end

    	local TMREnterVehicle_perform = ISEnterVehicle.perform
    	function ISEnterVehicle:perform()
        	TMREnterVehicle_perform(self)
		if self.character:getVehicle() then
        		local t = TMRadio.getEmitter(self.character:getVehicle():getEmitter())
        		if t then
            			t.sound:setVolumeModifier(0.8)
            			t.sound:set3D(false)
            			TMRadio.updateVolume(t)
			end
		else
			print("TMRadio: vehicle not found due to mod interaction. Unable to update sound emitter in the vehicle.")
        	end
    	end
    
    	local TMRExitVehicle_perform = ISExitVehicle.perform
    	function ISExitVehicle:perform()
		if self.character:getVehicle() then
        		local t = TMRadio.getEmitter(self.character:getVehicle():getEmitter())
        		if t then
				t.x = self.character:getVehicle():getX()
				t.y = self.character:getVehicle():getY()
				t.z = self.character:getVehicle():getZ()
				if not TMRadio.VehicleWindowsIntact(self.character:getVehicle()) then
            				t.sound:setVolumeModifier(0.4)
            				t.sound:set3D(true)
            				TMRadio.updateVolume(t)
				else
            				t.sound:setVolumeModifier(0.2)
            				t.sound:set3D(true)
            				TMRadio.updateVolume(t)
				end
			end
		else
			print("TMRadio: vehicle not found due to mod interaction. Unable to update sound emitter in the vehicle.")
        	end
        	TMRExitVehicle_perform(self)
    	end

	local TMRRadioWindow_update = ISRadioWindow.update
	function ISRadioWindow:update()
  		ISCollapsableWindow.update(self)
		local maxDist = 5
    		--if not isClient() and self:getIsVisible() then -- might be an issue
    		if self:getIsVisible() then
        		if self.deviceType and self.device and self.player and self.deviceData then
            			if self.deviceType=="InventoryItem" then
					if self.device:isInPlayerInventory() then
						return
					else
						self:close()
         	           			return
					end
            			elseif self.deviceType == "IsoObject" or self.deviceType == "VehiclePart" then
					if self.device:getSquare() then
						local distanceToRadio = math.sqrt((self.player:getX() - self.device:getX()) ^ 2 + (self.player:getY() - self.device:getY()) ^ 2 + (self.player:getZ() - self.device:getZ()) ^ 2)
        		        		if distanceToRadio > maxDist then
							self:close()
        		            			return
						end
					end
           		     	end
        		end
		end
		TMRRadioWindow_update(self)
	end

	local TMRRWMGeneral_setInfoLines = RWMGeneral.setInfoLines
	function RWMGeneral:setInfoLines()
		TMRRWMGeneral_setInfoLines(self)
		--print("general decoration")
		if self.deviceData and PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRenableRDS"):getValue() then
			if not self.deviceData:getIsTelevision() then
				local channel = self.deviceData:getChannel()
				if self.deviceData:getIsTurnedOn() and (channel == SandboxVars.TrueMusicRadio.TMRChannel1 or channel == SandboxVars.TrueMusicRadio.TMRChannel2 or channel == SandboxVars.TrueMusicRadio.TMRChannel3 or channel == SandboxVars.TrueMusicRadio.TMRChannel4 or channel == SandboxVars.TrueMusicRadio.TMRChannel5 or channel == SandboxVars.TrueMusicRadio.TMRMTV) then
					local songName = nil
					if channel == SandboxVars.TrueMusicRadio.TMRChannel1 then	
				    		songName = TMRadio.PlaylistTerminalA[TMRadio.Channels[channel]]
						--print("A: " .. TMRadio.PlaylistTerminalA[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel1]])
					elseif channel == SandboxVars.TrueMusicRadio.TMRChannel2 then
				    		songName = TMRadio.PlaylistTerminalB[TMRadio.Channels[channel]]
						--print("B: " .. TMRadio.PlaylistTerminalB[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel2]])
					elseif channel == SandboxVars.TrueMusicRadio.TMRChannel3 then
				    		songName = TMRadio.PlaylistTerminalC[TMRadio.Channels[channel]]
						--print("C: " .. TMRadio.PlaylistTerminalC[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel3]])
					elseif channel == SandboxVars.TrueMusicRadio.TMRChannel4 then
				    		songName = TMRadio.PlaylistTerminalD[TMRadio.Channels[channel]]
						--print("D: " .. TMRadio.PlaylistTerminalD[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel4]])
					elseif channel == SandboxVars.TrueMusicRadio.TMRChannel5 then
				    		songName = TMRadio.PlaylistTerminalE[TMRadio.Channels[channel]]
						--print("E: " .. TMRadio.PlaylistTerminalE[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel5]])
					elseif channel == SandboxVars.TrueMusicRadio.TMRMTV then
				    		songName = TMRadio.PlaylistTerminalMTV[TMRadio.Channels[channel]]
						--print("MTV: " .. TMRadio.PlaylistTerminalMTV[TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRMTV]])
					end
					if songName then
						TMRadio.SongNames[channel] = songName

						local musicItem = "Tsarcraft." .. songName
						local displayName = getItemNameFromFullType(musicItem)
						local prettyName = TMRadio.prettyName(displayName)
						local lineCount = 0

						--print(channel/1000 .. "FM: " .. prettyName)

						self:addInfoLine("RDS: ", "Now Playing...")
						for pieces in string.gmatch(prettyName, "[^%-]+") do
							for parts in string.gmatch(pieces, "[^%(]+") do
								for ends in string.gmatch(parts, "[^%)]+") do
									local stringNumb = string.len(ends)
									if stringNumb < 30 then
										local result = (TMRadio.getWrappedText(ends, self.width - 20, UIFont.Small)):split("\n")
										stringNumb = string.len(result[1])
										local line1 = string.sub(result[1],1,(stringNumb/2))
										local line2 = string.sub(result[1],((stringNumb/2)+1),stringNumb)
										self:addInfoLine(line1, line2)
										lineCount = lineCount + 1					
									else
										local result = (TMRadio.getWrappedText(ends, self.width - 20, UIFont.Small)):split("\n")
										local halfString1 = result[1]
										local halfStringNumb1 = string.len(halfString1)
										local line1 = string.sub(halfString1,1,(halfStringNumb1/2))
										local line2 = string.sub(halfString1,((halfStringNumb1/2)+1),halfStringNumb1)
										self:addInfoLine(line1, line2)
										lineCount = lineCount + 1

										local halfString2 = result[2]
										if halfString2 ~= nil then
											local halfStringNumb2 = string.len(halfString2)
											local line3 = string.sub(halfString2,1,(halfStringNumb2/2))
											local line4 = string.sub(halfString2,((halfStringNumb2/2)+1),halfStringNumb2)
											self:addInfoLine(line3, line4)
											lineCount = lineCount + 1
										end
									end
								end
							end
						end
						
						while lineCount < 4 do
							self:addInfoLine("", "")
							lineCount = lineCount + 1
						end
					elseif TMRadio.SongNames[channel] ~= nil then
						songName = TMRadio.SongNames[channel]

						local musicItem = "Tsarcraft." .. songName
						local displayName = getItemNameFromFullType(musicItem)
						local prettyName = TMRadio.prettyName(displayName)
						local lineCount = 0

						--print(channel/1000 .. "FM: " .. prettyName)

						self:addInfoLine("RDS: ", "Now Playing...")
						for pieces in string.gmatch(prettyName, "[^%-]+") do
							for parts in string.gmatch(pieces, "[^%(]+") do
								for ends in string.gmatch(parts, "[^%)]+") do
									local stringNumb = string.len(ends)
									if stringNumb < 30 then
										local result = (TMRadio.getWrappedText(ends, self.width - 20, UIFont.Small)):split("\n")
										stringNumb = string.len(result[1])
										local line1 = string.sub(result[1],1,(stringNumb/2))
										local line2 = string.sub(result[1],((stringNumb/2)+1),stringNumb)
										self:addInfoLine(line1, line2)
										lineCount = lineCount + 1					
									else
										local result = (TMRadio.getWrappedText(ends, self.width - 20, UIFont.Small)):split("\n")
										local halfString1 = result[1]
										local halfStringNumb1 = string.len(halfString1)
										local line1 = string.sub(halfString1,1,(halfStringNumb1/2))
										local line2 = string.sub(halfString1,((halfStringNumb1/2)+1),halfStringNumb1)
										self:addInfoLine(line1, line2)
										lineCount = lineCount + 1

										local halfString2 = result[2]
										if halfString2 ~= nil then
											local halfStringNumb2 = string.len(halfString2)
											local line3 = string.sub(halfString2,1,(halfStringNumb2/2))
											local line4 = string.sub(halfString2,((halfStringNumb2/2)+1),halfStringNumb2)
											self:addInfoLine(line3, line4)
											lineCount = lineCount + 1
										end
									end
								end
							end
						end

						while lineCount < 4 do
							self:addInfoLine("", "")
							lineCount = lineCount + 1
						end
					else
						self:addInfoLine("RDS: ", "No Data...")
						self:addInfoLine("", "")
						self:addInfoLine("", "")
						self:addInfoLine("", "")
						self:addInfoLine("", "")
					end
				else
					self:addInfoLine("RDS: ", "No Data...")
					self:addInfoLine("", "")
					self:addInfoLine("", "")
					self:addInfoLine("", "")
					self:addInfoLine("", "")
				end
				--self:addInfoLine("123456789101112", "211101987654321")
			end
		end
	end

	local TMRRWMGeneral_update = RWMGeneral.update
	function RWMGeneral:update()
		TMRRWMGeneral_update(self)
		--print("update decoration")
		if self.deviceData then
			if not self.deviceData:getIsTelevision() then
				local channel = self.deviceData:getChannel()
				if self.deviceData:getIsTurnedOn() and (channel == SandboxVars.TrueMusicRadio.TMRChannel1 or channel == SandboxVars.TrueMusicRadio.TMRChannel2 or channel == SandboxVars.TrueMusicRadio.TMRChannel3 or channel == SandboxVars.TrueMusicRadio.TMRChannel4 or channel == SandboxVars.TrueMusicRadio.TMRChannel5 or channel == SandboxVars.TrueMusicRadio.TMRMTV) then
					--print("Force update")
					ISPanel.update(self)
					self:setInfoLines()
				end
			end
		end
	end

	local TMRRWMGeneral_render = RWMGeneral.render
	function RWMGeneral:render()
    		self.ronin = true
    		self.headerLinesRemaining = 6
    		TMRRWMGeneral_render(self)
    		self.ronin = nil
	end

	local TMRRWMGeneral_drawText = RWMGeneral.drawText
	function RWMGeneral:drawText(text, x, y, r, g, b, a, font)
    		if self.headerLinesRemaining == 0 then
        		x = self.width / 2
    		end
    
    		if TMRRWMGeneral_drawText then  
        		TMRRWMGeneral_drawText(self, text, x, y, r, g, b, a, font)
    		else
        		ISUIElement.drawText(self, text, x, y, r, g, b, a, font)
    		end

    		if self.ronin and self.headerLinesRemaining > 0 then
        		self.headerLinesRemaining = self.headerLinesRemaining - 1
    		end
	end

	local TMRRWMGeneral_drawTextRight = RWMGeneral.drawTextRight
	function RWMGeneral:drawTextRight(text, x, y, r, g, b, a, font)
    		if self.headerLinesRemaining == 0 then
        		x = self.width / 2
    		end
    
    		if TMRRWMGeneral_drawTextRight then  
        		TMRRWMGeneral_drawTextRight(self, text, x, y, r, g, b, a, font)
   		else
        		ISUIElement.drawTextRight(self, text, x, y, r, g, b, a, font)
    		end
	end

	local TMRDropWorldItemAction_perform = ISDropWorldItemAction.perform
	function ISDropWorldItemAction:perform()
		if isClient() then
			if instanceof(self.item, "Radio") then
				local deviceData = self.item:getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(self.item)
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					--print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRDropWorldItemAction_perform(self)
	end

	local TMRInventoryTransferAction_perform = ISInventoryTransferAction.perform
	function ISInventoryTransferAction:perform()
		if isClient() then
			local ignore = false
			if self.srcContainer == self.character:getInventory() and self.destContainer:isInCharacterInventory(self.character) then
				ignore = true
			elseif self.destContainer == self.character:getInventory() and self.srcContainer:isInCharacterInventory(self.character) then
				ignore = true
			elseif self.srcContainer:isInCharacterInventory(self.character) and self.destContainer:isInCharacterInventory(self.character) then
				ignore = true
			end

			if not ignore and instanceof(self.item, "Radio") then
				local deviceData = self.item:getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(self.item)
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					--print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRInventoryTransferAction_perform(self)
	end

	local TMRGrabItemAction_transferItem = ISGrabItemAction.transferItem
	function ISGrabItemAction:transferItem(item)
		if isClient() then
			if instanceof(item:getItem(), "Radio") then
				local deviceData = item:getItem():getDeviceData()
				if deviceData then
 		       	   		local t = TMRadio.getData(deviceData)
					local args = {}
            				if t then
                				args = {x = t.x, y = t.y, z = t.z}
						--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
					else
						local position = TMRadio.whereAreYou(item:getItem())
						local x = position.x
						local y = position.y
						local z = position.z
                				args = {x = x, y = y, z = z}
						--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
					end
					print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
			end
		end

		TMRGrabItemAction_transferItem(self, item)
	end

	local TMRGrabItemAction_perform = ISGrabItemAction.perform
	function ISGrabItemAction:perform()
		if isClient() then
			local queuedItem = table.remove(self.queueList, 1);
			if queuedItem ~= nil then
				for i,item in ipairs(queuedItem.items) do
					self.item = item
					if not self:isValid() then
						self.queueList = {}
						break
					end

					if instanceof(item:getItem(), "Radio") then
						local square = item:getItem():getWorldItem():getSquare()
						local obj = nil
						for i=0, square:getObjects():size()-1 do
							local tObj = square:getObjects():get(i)
							if instanceof(tObj, "IsoRadio") then
								if tObj:getModData().RadioItemID == item:getItem():getID() then
									obj = tObj
									break
								end
							end
						end
						if obj ~= nil then
							local deviceData = obj:getDeviceData();
							if deviceData then
 		       		   				local t = TMRadio.getData(deviceData)
								local args = {}
 	           						if t then
        	        						args = {x = t.x, y = t.y, z = t.z}
									--print("getting position from t: " .. args.x .. " " .. args.y .. " " .. args.z)
								else
									local position = TMRadio.whereAreYou(item:getItem())
									local x = position.x
									local y = position.y
									local z = position.z
                							args = {x = x, y = y, z = z}
									--print("getting position from where are you: " .. args.x .. " " .. args.y .. " " .. args.z)
								end
								print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
								if (args.x + args.y + args.z) ~= 0 then
									sendClientCommand("TMRadio", "Stop", args)
								end
							end
						end
					end
				end
			end
		end

		TMRGrabItemAction_perform(self)
	end

	local TMRMoveableSpriteProps_pickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
	function ISMoveableSpriteProps:pickUpMoveableInternal(character, square, object, sprInstance, spriteName, createItem, rotating)
		if isClient() then
			if object and instanceof(object, "IsoRadio") then
				local deviceData = object:getDeviceData()
              	    		if deviceData and square then
					local args = {x = square:getX(), y = square:getY(), z = square:getZ()}
					--print("TMRadio: Sending stop command to server: " .. args.x .. " " .. args.y .. " " .. args.z)
					if (args.x + args.y + args.z) ~= 0 then
						sendClientCommand("TMRadio", "Stop", args)
					end
				end
                  	end
		end

		return TMRMoveableSpriteProps_pickUpMoveableInternal(self, character, square, object, sprInstance, spriteName, createItem, rotating)
	end

	if TMRadio.activatedMods["TVRadio_ReInvented"] then
	    	local TMRRWMMergedRadio_doTuneInButton = RWMMergedRadio.doTuneInButton
		function RWMMergedRadio:doTuneInButton(button)
			local oldChannel = self.deviceData:getChannel()
			--print("old channel: " .. oldChannel)
			local x = TMRadio.getData(self.deviceData)
			if self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV then
				if x then
                			x.muted = true -- mute sound instead of stopping it, so we can turn it back on
            				TMRadio.updateVolume(x)
				end
			end
        		TMRRWMMergedRadio_doTuneInButton(self, button)
			local newChannel = self.deviceData:getChannel()
			--print("new channel: " .. newChannel)
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
	        	local t = TMRadio.getData(self.deviceData)
			if not isClient() and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				--print("push to the next song")
				if t then
					TMRadio.UpdateSoundCache(songNumber, self.deviceData:getChannel())
					return
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					return
				end
			elseif t then
				if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                			t.muted = false
				elseif t.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
        	        		t.muted = false
					if isClient() and not self.deviceData:isInventoryDevice() then
						local position = TMRadio.whereAreYou(self.deviceData:getParent())
						local x = position.x
						local y = position.y
						local z = position.z
						local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
						sendClientCommand("TMRadio", "Play", args)
					else
						TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					end
        	    		else
                			t.muted = true -- mute sound instead of stopping it, so we can turn it back on
 	           		end
	            		TMRadio.updateVolume(t)
			elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				if isClient() and not self.deviceData:isInventoryDevice() then
					local position = TMRadio.whereAreYou(self.deviceData:getParent())
					local x = position.x
					local y = position.y
					local z = position.z
					local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "Play", args)
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
			end
	    	end

	    	local TMRRWMMergedWalkieTalkie_doTuneInButton = RWMMergedWalkieTalkie.doTuneInButton
		function RWMMergedWalkieTalkie:doTuneInButton(button)
			local oldChannel = self.deviceData:getChannel()
			--print("old channel: " .. oldChannel)
			local x = TMRadio.getData(self.deviceData)
			if self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV then
				if x then
                			x.muted = true -- mute sound instead of stopping it, so we can turn it back on
	            			TMRadio.updateVolume(x)
				end
			end
	        	TMRRWMMergedWalkieTalkie_doTuneInButton(self, button)
			local newChannel = self.deviceData:getChannel()
			--print("new channel: " .. newChannel)
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
        		local t = TMRadio.getData(self.deviceData)
			if not isClient() and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				--print("push to the next song")
				if t then
					TMRadio.UpdateSoundCache(songNumber, self.deviceData:getChannel())
					return
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					return
				end
			elseif t then
				if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                			t.muted = false
				elseif t.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
        	        		t.muted = false
					if isClient() and not self.deviceData:isInventoryDevice() then
						local position = TMRadio.whereAreYou(self.deviceData:getParent())
						local x = position.x
						local y = position.y
						local z = position.z
						local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
						sendClientCommand("TMRadio", "Play", args)
					else
						TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					end
        	    		else
                			t.muted = true -- mute sound instead of stopping it, so we can turn it back on
 	           		end
	            		TMRadio.updateVolume(t)
			elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				if isClient() and not self.deviceData:isInventoryDevice() then
					local position = TMRadio.whereAreYou(self.deviceData:getParent())
					local x = position.x
					local y = position.y
					local z = position.z
					local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "Play", args)
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
			end
	    	end

	    	local TMRRWMMergedCarRadio_doTuneInButton = RWMMergedCarRadio.doTuneInButton
		function RWMMergedCarRadio:doTuneInButton(button)
			local oldChannel = self.deviceData:getChannel()
			--print("old channel: " .. oldChannel)
			local x = TMRadio.getData(self.deviceData)
			if self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV then
				if x then
                			x.muted = true -- mute sound instead of stopping it, so we can turn it back on
	            			TMRadio.updateVolume(x)
				end
			end
	        	TMRRWMMergedCarRadio_doTuneInButton(self, button)
			local newChannel = self.deviceData:getChannel()
			--print("new channel: " .. newChannel)
			local songNumber = TMRadio.ChooseSong(self.deviceData:getChannel())
        		local t = TMRadio.getData(self.deviceData)
			if not isClient() and not isServer() and oldChannel == newChannel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				--print("push to the next song")
				if t then
					TMRadio.UpdateSoundCache(songNumber, self.deviceData:getChannel())
					return
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					return
				end
			elseif t then
				if t.deviceData:getIsTurnedOn() and t.deviceData:getChannel() == t.channel and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                			t.muted = false
				elseif t.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
        	        		t.muted = false
					if isClient() and not self.deviceData:isInventoryDevice() then
						local position = TMRadio.whereAreYou(self.deviceData:getParent())
						local x = position.x
						local y = position.y
						local z = position.z
						local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
						sendClientCommand("TMRadio", "Play", args)
					else
						TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
					end
        	    		else
                			t.muted = true -- mute sound instead of stopping it, so we can turn it back on
 	           		end
	            		TMRadio.updateVolume(t)
			elseif self.deviceData:getIsTurnedOn() and (self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or self.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				if isClient() and not self.deviceData:isInventoryDevice() then
					local position = TMRadio.whereAreYou(self.deviceData:getParent())
					local x = position.x
					local y = position.y
					local z = position.z
					local args = {x = x, y = y, z = z, channel = self.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "Play", args)
				else
					TMRadio.PlaySound(TMRadio.Channels[self.deviceData:getChannel()], self.deviceData:getParent())
				end
			end
	    	end

	    	local TMRRWMMergedTV_doTuneInButton = RWMMergedTV.doTuneInButton
		function RWMMergedTV:doTuneInButton(button)
			if self.deviceData and self.deviceData:getDevicePresets() and self.deviceData:getDevicePresets():getPresets() then
				local detectedMPTV = false
				local detectedTMMTV = false
				local detectedEmergencyTV = false
        			self.presets = self.deviceData:getDevicePresets():getPresets()
        			for i = 0, self.presets:size()-1 do
	            			local p = self.presets:get(i)
            				--self:addComboOption(p:getFrequency(), p:getName())
					--print("Freq: " .. tostring(p:getFrequency()) .. " Name: " .. tostring(p:getName()))
					if p:getName() == "Monty Python TV 24/7" then
						detectedMPTV = true
					end
					if p:getName() == "True Music MTV" then
						detectedTMMTV = true
					end
					if p:getName() == "Emergency TV Station" then
						detectedEmergencyTV = true
					end
        			end
				if not detectedMPTV and TMRadio.activatedMods["MontyPythonTV"] then
					self.deviceData:getDevicePresets():addPreset("Monty Python TV 24/7", 222)
				end
				if not detectedTMMTV and SandboxVars.TrueMusicRadio.ActivateTMRMTV then
					self.deviceData:getDevicePresets():addPreset("True Music MTV", SandboxVars.TrueMusicRadio.TMRMTV)
				end
				if not detectedEmergencyTV and TMRadio.activatedMods["EmergencyTVChannel"] then
					self.deviceData:getDevicePresets():addPreset("Emergency TV Station", 300)
				end
			end
			self.channels = self.deviceData:getDevicePresets():getPresets()
			self.channelMax = self.channels:size()-1
	        	TMRRWMMergedTV_doTuneInButton(self, button)
	    	end

	    	local TMRRWMMergedRadio_doAddPreset = RWMMergedRadio.doAddPreset
		function RWMMergedRadio:doAddPreset()
    			local p = self.presetsList
			if self.deviceData:getDevicePresets():getMaxPresets() < 20 then
				self.deviceData:getDevicePresets():setMaxPresets(20)
    			elseif #p.frequency >= self.deviceData:getDevicePresets():getMaxPresets() then
        			self.deviceData:getDevicePresets():setMaxPresets(self.deviceData:getDevicePresets():getMaxPresets() + 1)
    			end
	        	TMRRWMMergedRadio_doAddPreset(self)
			self.presets = self.deviceData:getDevicePresets():getPresets()
		end

	    	local TMRRWMMergedHAM_doAddPreset = RWMMergedHAM.doAddPreset
		function RWMMergedHAM:doAddPreset()
    			local p = self.presetsList
			if self.deviceData:getDevicePresets():getMaxPresets() < 20 then
				self.deviceData:getDevicePresets():setMaxPresets(20)
    			elseif #p.frequency >= self.deviceData:getDevicePresets():getMaxPresets() then
        			self.deviceData:getDevicePresets():setMaxPresets(self.deviceData:getDevicePresets():getMaxPresets() + 1)
    			end
	        	TMRRWMMergedHAM_doAddPreset(self)
			self.presets = self.deviceData:getDevicePresets():getPresets()
		end

	    	local TMRRWMMergedWalkieTalkie_doAddPreset = RWMMergedWalkieTalkie.doAddPreset
		function RWMMergedWalkieTalkie:doAddPreset()
    			local p = self.presetsList
			if self.deviceData:getDevicePresets():getMaxPresets() < 20 then
				self.deviceData:getDevicePresets():setMaxPresets(20)
    			elseif #p.frequency >= self.deviceData:getDevicePresets():getMaxPresets() then
        			self.deviceData:getDevicePresets():setMaxPresets(self.deviceData:getDevicePresets():getMaxPresets() + 1)
    			end
	        	TMRRWMMergedWalkieTalkie_doAddPreset(self)
			self.presets = self.deviceData:getDevicePresets():getPresets()
		end

	    	local TMRRWMMergedCarRadio_doAddPreset = RWMMergedCarRadio.doAddPreset
		function RWMMergedCarRadio:doAddPreset()
    			local p = self.presetsList
			if self.deviceData:getDevicePresets():getMaxPresets() < 20 then
				self.deviceData:getDevicePresets():setMaxPresets(20)
    			elseif #p.frequency >= self.deviceData:getDevicePresets():getMaxPresets() then
        			self.deviceData:getDevicePresets():setMaxPresets(self.deviceData:getDevicePresets():getMaxPresets() + 1)
    			end
	        	TMRRWMMergedCarRadio_doAddPreset(self)
			self.presets = self.deviceData:getDevicePresets():getPresets()
		end
	end
end

Events.OnGameStart.Add(TMRadio.AddOverrides)

-------------------------------------------
-- ADJUST SOUNDS BASED ON DISTANCE/STATE --
-------------------------------------------

local minRange = 5
local maxRange = 75 --50
local p = nil
local X = 0
local Y = 0
local Z = 0
local dropoffRange = 0
local volumeModifier = 0
local distanceToRadio = 0
local finalVolume = 0
local tickCounter1 = 0
local tickCounter2 = 0
local tickCounter3 = 0
local syncPlaylistRequest = true

function TMRadio.adjustSounds()
        p = getPlayer()
        X = p:getX()
        Y = p:getY()
        Z = p:getZ()

    	-- TODO: tickrates depend on framerate. find something time-based instead
    	if tickCounter2 < 1000 then 
        	tickCounter2=tickCounter2+1
    	else
		local TMRRadiosAttractZombies = SandboxVars.TrueMusicRadio.TMRRadiosAttractZombies 
        	--attract zombies
		if TMRRadiosAttractZombies then
	        	for _,t in ipairs(TMRadio.soundCache) do
        	    		if TMRadio.isPlaying(t) and t.device ~= nil and t.device == t.deviceData:getParent() then
                			local range = t.deviceData:getDeviceVolume() * t.sound.volumeModifier*2.5 * maxRange
					if t.deviceData:isVehicleDevice() then
						--print("call zombies to car")
						local vehicle = t.deviceData:getParent():getVehicle()
						if TMRadio.VehicleWindowsIntact(vehicle) then
							addSound(vehicle, t.x, t.y, t.x, range/4, range/2)
						else
							addSound(vehicle, t.x, t.y, t.z, range, range)
						end
					elseif t.deviceData:isInventoryDevice() then
						if t.device:getContainer() then
							if t.device:getContainer():getType() == "none" and t.deviceData:getHeadphoneType() == -1 then
								--print("call zombies to player without headphones")
								addSound(p, t.x, t.y, t.z, range/4, range/2)
							elseif t.device:getContainer():getType() ~= "none" then
								--print("call zombies to container")
								addSound(container, t.x, t.y, t.z, range/4, range/2)
							end
						end
                			elseif t.device:getSquare() then
						--print("call zombies to world radio")
                    				addSound(t.device, t.x, t.y, t.z, range, range)
					end
                		end
            		end
        	end
        	tickCounter2 = 0
    	end
    	if tickCounter1 < 5 then 
		tickCounter1=tickCounter1+1 
		return 
	end
    	tickCounter1 = 0

	if syncPlaylistRequest == true then
		if isClient() then
			TMRadioClient.UpdatePlaylistFromServer()
		else
			TMRadio.OldPlaylistGlobal = ModData.getOrCreate("TMRadioOldPlaylistGlobal")
			TMRadio.PlaylistGlobal = {}
			for k,v in pairs(GlobalMusic) do
				TMRadio.PlaylistGlobal[#TMRadio.PlaylistGlobal + 1] = k
			end
			if #TMRadio.OldPlaylistGlobal == #TMRadio.PlaylistGlobal then
				print("TMRadio: The current global music list matches old list. Old: " .. #TMRadio.OldPlaylistGlobal .. " New: " .. #TMRadio.PlaylistGlobal)
				TMRadio.Channels = ModData.getOrCreate("TMRadioChannels")
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel1)
				end
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel2)
				end
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel3)
				end
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel4)
				end
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel5)
				end
				if TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRMTV] == nil then
					TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRMTV] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRMTV)
				end
				ModData.add("TMRadioChannels", TMRadio.Channels)
			else
				print("TMRadio: The current global music list doesn't match the old list. Old: " .. #TMRadio.OldPlaylistGlobal .. " New: " .. #TMRadio.PlaylistGlobal .. " Reverting all stations for the update.")
				ModData.add("TMRadioOldPlaylistGlobal", TMRadio.PlaylistGlobal)
				TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
				ModData.add("TMRadioA", TMRadio.PlaylistTerminalA)
				TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
				ModData.add("TMRadioB", TMRadio.PlaylistTerminalB)
				TMRadio.PlaylistTerminalC = TMRadio.CreatePlaylist()
				ModData.add("TMRadioC", TMRadio.PlaylistTerminalC)
				TMRadio.PlaylistTerminalD = TMRadio.CreatePlaylist()
				ModData.add("TMRadioD", TMRadio.PlaylistTerminalD)
				TMRadio.PlaylistTerminalE = TMRadio.CreatePlaylist()
				ModData.add("TMRadioE", TMRadio.PlaylistTerminalE)
				TMRadio.PlaylistTerminalMTV = TMRadio.CreatePlaylist()
				ModData.add("TMRadioMTV", TMRadio.PlaylistTerminalMTV)
				TMRadio.Channels = ModData.getOrCreate("TMRadioChannels")
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel1)
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel2)
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel3)
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel4)
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRChannel5)
				TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRMTV] = TMRadio.ChooseSong(SandboxVars.TrueMusicRadio.TMRMTV)
				ModData.add("TMRadioChannels", TMRadio.Channels)
			end
			--print(SandboxVars.TrueMusicRadio.TMRChannel1/1000 .. "FM: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel1])
			--print(SandboxVars.TrueMusicRadio.TMRChannel2/1000 .. "FM: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel2])
			--print(SandboxVars.TrueMusicRadio.TMRChannel3/1000 .. "FM: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel3])
			--print(SandboxVars.TrueMusicRadio.TMRChannel4/1000 .. "FM: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel4])
			--print(SandboxVars.TrueMusicRadio.TMRChannel5/1000 .. "FM: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRChannel5])
			--print(SandboxVars.TrueMusicRadio.TMRMTV .. "TV: " ..  TMRadio.Channels[SandboxVars.TrueMusicRadio.TMRMTV])
		end
		syncPlaylistRequest = false
	end

	-- check status of soundcache for emitters leaving the distance check, reversed to pull broken bits out
	for index = #TMRadio.soundCache, 1, -1 do 
		t = TMRadio.soundCache[index]  
		if t.device ~= t.deviceData:getParent() then 
               		t.device = t.deviceData:getParent() 
		end
		local position = TMRadio.whereAreYou(t.device, index)
		if (position.x + position.y + position.z) ~= 0 then
			t.x = position.x
			t.y = position.y
			t.z = position.z
		end
		if t.device == nil then
			t.sound:setVolume(0)
			t.muted = true
    	         	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("turned off due to lost device")
		elseif isClient() and t.device:getDeviceData():getParent():getSquare() == nil then
			t.sound:setVolume(0)
			t.muted = true
    	        	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("stopping sound due to loss of parent")
		elseif not t.deviceData:isInventoryDevice() and getSquare(t.x, t.y, t.z) == nil then
			t.sound:setVolume(0)
			t.muted = true
    	        	TMRadio.updateVolume(t)
			t.sound:stop()
			table.remove(TMRadio.soundCache, index)
			--print("stopping sound in container due to loss of square")
		elseif not t.deviceData:isInventoryDevice() and not (t.deviceData:isVehicleDevice() and p:getVehicle()) then
			distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
			if distanceToRadio > 75 then
				t.sound:setVolume(0)
				t.muted = true
    	         		TMRadio.updateVolume(t)
				t.sound:stop()
				table.remove(TMRadio.soundCache, index)
				--print("turned off due to distance: " .. distanceToRadio)
			end
		elseif t.deviceData:isInventoryDevice() then
			if t.device:getContainer() and t.device:getContainer():getType() ~= "none" then
				distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
				if distanceToRadio > 75 then
					t.sound:setVolume(0)
					t.muted = true
     	        	 		TMRadio.updateVolume(t)
					t.sound:stop()
					table.remove(TMRadio.soundCache, index)
					--print("in container turned off due to distance: " .. distanceToRadio)
				end
			end
		end
	end

    	highestVolume = 0

    	for index,t in ipairs(TMRadio.soundCache) do   
        	-- sync states     
        	if t.sound and t.sound:isPlaying() then
            		if not t.deviceData:getIsTurnedOn() and not t.muted then
                		t.muted = true
				--print("muted by tick, was not turned on")
            		end
			if not t.muted and not (t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
                		t.muted = true
				--print("muted by tick, was not on valid TMRadio channel")
			end
			if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRthreeDoff"):getValue() then
             			t.sound:set3D(false)
			elseif t.device.isInPlayerInventory and t.device:isInPlayerInventory() then
             			t.sound:set3D(false)
			elseif t.deviceData:isVehicleDevice() and p:getVehicle() and t.deviceData:getParent():getVehicle() == p:getVehicle() then
           			t.sound:set3D(false)
               		else
               			t.sound:setPos(t.x, t.y, t.z)
				t.sound:set3D(true)
               		end
                	TMRadio.updateVolume(t)
        	end

        	--adjust volume based on distance
        	if TMRadio.isPlaying(t) or (t.deviceData:getParent() ~= nil and t.deviceData:getIsTurnedOn()) then
    			if not t.muted then
        			t.sound:setVolume(t.deviceData:getDeviceVolume())
				if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRmuteMusic"):getValue() then
					t.sound:setVolume(0)
            			elseif t.deviceData:isInventoryDevice() then
                			highestVolume = 1
				elseif t.deviceData:isVehicleDevice() and p:getVehicle() and t.deviceData:getParent():getVehicle() == p:getVehicle() then
           				highestVolume = 1
				else
                			distanceToRadio = math.sqrt((X - t.x) ^ 2 + (Y - t.y) ^ 2 + (Z - t.z) ^ 2)
                			if distanceToRadio < maxRange then
						local environmentModifier = 1
						if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRthreeDoff"):getValue() then
							environmentModifier = environmentModifier * 0.9
							if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRaltThreeD"):getValue() then
								if Z == t.z then
									--print("on the same floor")
								else
									if Z > t.z then
										environmentModifier = environmentModifier * (1 - ((Z - t.z) * 0.15))
									else
										environmentModifier = environmentModifier * (1 - ((t.z - Z) * 0.15))
									end
									if environmentModifier < 0 then 
										environmentModifier = 0
									end
								end
								if p:getVehicle() then
									if not TMRadio.VehicleWindowsIntact(p:getVehicle()) then
										environmentModifier = environmentModifier * 0.9
									else
										environmentModifier = environmentModifier * 0.6
									end
								end
								if p:getSquare() and getSquare(t.x, t.y, t.z) then
									if p:getSquare():isOutside() and getSquare(t.x, t.y, t.z):isOutside() then
										--print("both outside")
									elseif p:getSquare():getBuilding() and getSquare(t.x, t.y, t.z):getBuilding() and p:getSquare():getBuilding() == getSquare(t.x, t.y, t.z):getBuilding() then
										if p:getSquare():getRoom() and getSquare(t.x, t.y, t.z):getRoom() and p:getSquare():getRoom() == getSquare(t.x, t.y, t.z):getRoom() then
											--print("both in same room")
										else
											environmentModifier = environmentModifier * 0.85
										end
									elseif p:getSquare():getBuilding() and getSquare(t.x, t.y, t.z):getBuilding() then
									environmentModifier = environmentModifier * 0.55
									elseif p:getSquare():getBuilding() or getSquare(t.x, t.y, t.z):getBuilding() then
										environmentModifier = environmentModifier * 0.7
									end
								end
							end
						end
						local sliderModifier = PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRvolumeSlider"):getValue() / 10
						--print("Total Environment Modifier: " .. environmentModifier)
                   				dropoffRange = (maxRange-minRange)*0.2 + t.deviceData:getDeviceVolume() * t.sound.volumeModifier*2.5 * (maxRange-minRange)*0.8
                    				volumeModifier = ((minRange + dropoffRange - distanceToRadio) / dropoffRange) * environmentModifier * sliderModifier
                    				if volumeModifier < 0 then 
							volumeModifier = 0 
						end
						--print("Distance: " .. distanceToRadio)
						--print("Total Volume Modifier: " .. volumeModifier)
 	                   			t.sound:setVolume(t.deviceData:getDeviceVolume() * volumeModifier)
        	            			finalVolume = t.deviceData:getDeviceVolume() * t.sound.volumeModifier * volumeModifier
                	    			if finalVolume > highestVolume then 
							highestVolume = finalVolume 
						end
             		      		end
            			end
			end
			-- check to see if the next song needs to play
			if not TMRadio.isPlaying(t) and tickCounter3 > 25 and not PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRstopMusic"):getValue() and (t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				tickCounter3 = 0
				print("TMRadio: Song ended play another")
				local songNumber = TMRadio.ChooseSong(t.deviceData:getChannel())
				if isClient() then
					local args = {x = t.x, y = t.y, z = t.z, channel = t.deviceData:getChannel(), number = songNumber}
					sendClientCommand("TMRadio", "PlayNext", args)
				else
					TMRadio.UpdateSoundCache(songNumber, t.deviceData:getChannel())
				end
			elseif not TMRadio.isPlaying(t) and (t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel1 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel2 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel3 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel4 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRChannel5 or t.deviceData:getChannel() == SandboxVars.TrueMusicRadio.TMRMTV) then
				tickCounter3 = tickCounter3 + 1
			end
        	end
    	end

    	--adjust Zomboid music volume
    	local optionsVolume = getCore():getOptionMusicVolume()/10
    	local optionsVolumeModified = optionsVolume - optionsVolume*highestVolume*10
    	if optionsVolumeModified < 0 then 
		optionsVolumeModified = 0 
	end
    	getSoundManager():setMusicVolume(optionsVolumeModified)
end

Events.OnTick.Add(TMRadio.adjustSounds)

TMRadio.OnMainMenuEnter = function()
    	--reset Zomboid music volume again
    	getSoundManager():setMusicVolume( getCore():getOptionMusicVolume()/10 )
end

Events.OnMainMenuEnter.Add( TMRadio.OnMainMenuEnter )

-------------
-- VARIOUS --
-------------

local vehicleWindows = {
    	"Windshield",
    	"WindshieldRear",
    	"WindowFrontLeft", 
    	"WindowFrontRight", 
    	"WindowMiddleLeft", 
    	"WindowMiddleRight", 
    	"WindowRearLeft", 
    	"WindowRearRight"
}

TMRadio.VehicleWindowsIntact = function(vehicle)
    	for k,v in ipairs(vehicleWindows) do
        	local vehiclePart = vehicle:getPartById(v)
        	if vehiclePart and (not vehiclePart:getInventoryItem() or (vehiclePart:getWindow() and vehiclePart:getWindow():isOpen())) then
            		return false
        	end
   	 end

    	return true
end

TMRadio.updateVolume = function(t)
    	if not t.muted then
        	t.sound:setVolume(t.deviceData:getDeviceVolume())
    	else
        	t.sound:setVolume(0)
    	end
end

TMRadio.isPlaying = function(t)
    	if not t.deviceData:getIsTurnedOn() then 
		return false 
	end
    	if t.muted then 
		return false 
	end
    	if t.sound and t.sound:isPlaying() then 
		return true 
	end
    	return false
end

TMRadio.getData = function(deviceData)
    	for _,t in ipairs(TMRadio.soundCache) do
        	if t.deviceData == deviceData then
            		return t
        	end
    	end
end

TMRadio.getEmitter = function(emitter)
    	for _,t in ipairs(TMRadio.soundCache) do
        	if t.sound.emitter == emitter then
            		return t
        	end
    	end
end

TMRadio.whereAreYou = function(device, index)
	local remove = nil
	local x = nil
	local y = nil
	local z = nil
	local deviceData = device.getDeviceData and device:getDeviceData() or nil

	if not device or not deviceData then
		return
	end

	-- if the radio is part of a vehicle
	if deviceData.isVehicleDevice and deviceData:isVehicleDevice() then
		x = deviceData:getParent():getVehicle():getX()
		y = deviceData:getParent():getVehicle():getY()
		z = deviceData:getParent():getVehicle():getZ()
		--print("location from vehicle")
	end

	-- if the radio is in the player inventory which includes primary and secondary hands and in bags
	if not x and device.isInPlayerInventory and device:isInPlayerInventory() then
		x = getPlayer():getX()
		y = getPlayer():getY()
		z = getPlayer():getZ()
		--print("location from player")
	end

	-- if the radio is in a square on on it's own
	if not x and device.getSquare and device:getSquare() then
		x = device:getX()
		y = device:getY()
		z = device:getZ()
		--print("location from self - has square uses direct getx")
	end
	if not x and device.getSquare and device:getSquare() then
		x = device:getSquare():getX()
		y = device:getSquare():getY()
		z = device:getSquare():getZ()
		--print("location from square - has square uses direct getx through square")
	end

	-- if the radio is in a container like a crate but not a bag on the ground
	if not x and deviceData:isInventoryDevice() then
		if device.getContainer and device:getContainer() and device.getOutermostContainer and device:getOutermostContainer() then
			if device:getOutermostContainer():isVehiclePart() and device:getOutermostContainer():getVehicle() then
				x = device:getOutermostContainer():getVehicle():getX()
				y = device:getOutermostContainer():getVehicle():getY()
				z = device:getOutermostContainer():getVehicle():getZ()
				--print("location from vehicle container")
			elseif device:getOutermostContainer():isCorpse() then
				x = device:getOutermostContainer():getSquare():getX()
				y = device:getOutermostContainer():getSquare():getY()
				z = device:getOutermostContainer():getSquare():getZ()
				--print("location from corpse container")
			elseif device:getOutermostContainer():getParent() then
				if device:getOutermostContainer():getParent():getX() then
					x = t.device:getOutermostContainer():getParent():getX()
					y = t.device:getOutermostContainer():getParent():getY()
					z = t.device:getOutermostContainer():getParent():getZ()
					--print("location from container with a parent")
				end
			elseif device:getOutermostContainer():getSquare() and device:getOutermostContainer():getSquare():getX() then
				x = t.device:getOutermostContainer():getSquare():getX()
				y = t.device:getOutermostContainer():getSquare():getY()
				z = t.device:getOutermostContainer():getSquare():getZ()
				--print("location from container with a square")
			end
		end
	end	

	if not x then
		local t = TMRadio.getData(deviceData)
		if t then 
			x = t.x
			y = t.y
			z = t.z
			--print("unable to get a new location, defaulted to last known location")
		else
			x = 0
			y = 0
			z = 0
			--print("unable to get a new location, defaulted zeros")
		end
	end

	--if x and y and z then
	--	--print("new location: " .. x .. " " .. y .. " " .. z)
	--end
	return {x = x, y = y, z = z}
end

TMRadio.ChooseSong = function(channel)
	if not channel then
		return
	end

	local lastSongNumber = TMRadio.Channels[channel]
	local songNumber = nil

	if channel == SandboxVars.TrueMusicRadio.TMRChannel1 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalA ~= nil and #TMRadioClient.PlaylistTerminalA > 0 then
				--print("Client choosesong: pulling A from client playlist")
				TMRadio.PlaylistTerminalA = TMRadioClient.PlaylistTerminalA
			end
		end
		if TMRadioClient.PlaylistTerminalA == nil or #TMRadio.PlaylistTerminalA == 0 then
			--print("Client choosesong: looking for playlist A in moddata")
			TMRadio.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if TMRadioClient.PlaylistTerminalA == nil or #TMRadio.PlaylistTerminalA == 0 then
			--print("Client choosesong: unable to find playlist A creating new list")
			TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalA > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA + 1)
			end
		end
	elseif channel == SandboxVars.TrueMusicRadio.TMRChannel2 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalB ~= nil and #TMRadioClient.PlaylistTerminalB > 0 then
				--print("Client choosesong: pulling B from client playlist")
				TMRadio.PlaylistTerminalB = TMRadioClient.PlaylistTerminalB
			end
		end
		if TMRadioClient.PlaylistTerminalB == nil or #TMRadio.PlaylistTerminalB == 0 then
			--print("Client choosesong: looking for playlist B in moddata")
			TMRadio.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if TMRadioClient.PlaylistTerminalB == nil or #TMRadio.PlaylistTerminalB == 0 then
			--print("Client choosesong: unable to find playlist B creating new list")
			TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalB > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB + 1)
			end
		end
	elseif channel == SandboxVars.TrueMusicRadio.TMRChannel3 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalC ~= nil and #TMRadioClient.PlaylistTerminalC > 0 then
				--print("Client choosesong: pulling C from client playlist")
				TMRadio.PlaylistTerminalC = TMRadioClient.PlaylistTerminalC
			end
		end
		if TMRadioClient.PlaylistTerminalC == nil or #TMRadio.PlaylistTerminalC == 0 then
			--print("Client choosesong: looking for playlist C in moddata")
			TMRadio.PlaylistTerminalC = ModData.getOrCreate("TMRadioC")
		end
		if TMRadioClient.PlaylistTerminalC == nil or #TMRadio.PlaylistTerminalC == 0 then
			--print("Client choosesong: unable to find playlist C creating new list")
			TMRadio.PlaylistTerminalC = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalC + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalC > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalC + 1)
			end
		end
	elseif channel == SandboxVars.TrueMusicRadio.TMRChannel4 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalD ~= nil and #TMRadioClient.PlaylistTerminalD > 0 then
				--print("Client choosesong: pulling D from client playlist")
				TMRadio.PlaylistTerminalD = TMRadioClient.PlaylistTerminalD
			end
		end
		if TMRadioClient.PlaylistTerminalD == nil or #TMRadio.PlaylistTerminalD == 0 then
			--print("Client choosesong: looking for playlist D in moddata")
			TMRadio.PlaylistTerminalD = ModData.getOrCreate("TMRadioD")
		end
		if TMRadioClient.PlaylistTerminalD == nil or #TMRadio.PlaylistTerminalD == 0 then
			--print("Client choosesong: unable to find playlist D creating new list")
			TMRadio.PlaylistTerminalD = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalD + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalD > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalD + 1)
			end
		end
	elseif channel == SandboxVars.TrueMusicRadio.TMRChannel5 then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalE ~= nil and #TMRadioClient.PlaylistTerminalE > 0 then
				--print("Client choosesong: pulling E from client playlist")
				TMRadio.PlaylistTerminalE = TMRadioClient.PlaylistTerminalE
			end
		end
		if TMRadioClient.PlaylistTerminalE == nil or #TMRadio.PlaylistTerminalE == 0 then
			--print("Client choosesong: looking for playlist E in moddata")
			TMRadio.PlaylistTerminalE = ModData.getOrCreate("TMRadioE")
		end
		if TMRadioClient.PlaylistTerminalE == nil or #TMRadio.PlaylistTerminalE == 0 then
			--print("Client choosesong: unable to find playlist E creating new list")
			TMRadio.PlaylistTerminalE = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalE + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalE > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalE + 1)
			end
		end
	elseif channel == SandboxVars.TrueMusicRadio.TMRMTV then 
		if isClient() then
			--print("Client choosesong: looking for playlist")
			if TMRadioClient.PlaylistTerminalMTV ~= nil and #TMRadioClient.PlaylistTerminalMTV > 0 then
				--print("Client choosesong: pulling MTV from client playlist")
				TMRadio.PlaylistTerminalMTV = TMRadioClient.PlaylistTerminalMTV
			end
		end
		if TMRadioClient.PlaylistTerminalMTV == nil or #TMRadio.PlaylistTerminalMTV == 0 then
			--print("Client choosesong: looking for playlist MTV in moddata")
			TMRadio.PlaylistTerminalMTV = ModData.getOrCreate("TMRadioMTV")
		end
		if TMRadioClient.PlaylistTerminalMTV == nil or #TMRadio.PlaylistTerminalMTV == 0 then
			--print("Client choosesong: unable to find playlist MTV creating new list")
			TMRadio.PlaylistTerminalMTV = TMRadio.CreatePlaylist()
		end
		songNumber = ZombRand(1, #TMRadio.PlaylistTerminalMTV + 1)
		if songNumber == lastSongNumber and #TMRadio.PlaylistTerminalMTV > 1 then
			while songNumber == lastSongNumber do
				songNumber = ZombRand(1, #TMRadio.PlaylistTerminalMTV + 1)
			end
		end
	end
	
	return songNumber
end

TMRadio.CreatePlaylist = function()
	local tempGlobalPlaylist = {}

	for k,v in pairs(GlobalMusic) do
		tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
	end

	if SandboxVars.TrueMusicRadio.TMRExcludeThemeSongs then
		for k,v in pairs(TMRadio.BlacklistThemeSongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					--print("Removing Theme Song: " .. v)
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if SandboxVars.TrueMusicRadio.TMRExcludeTCCacheMPSongs then
		for k,v in pairs(TMRadio.BlacklistTCCacheMPSongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					--print("Removing TCCache Song: " .. v)
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if SandboxVars.TrueMusicRadio.TMRExcludeHolidaySongs then
		for k,v in pairs(TMRadio.BlacklistHolidaySongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					--print("Removing Holiday Song: " .. v)
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if TMRadio.Blacklist ~= nil and #TMRadio.Blacklist > 0 then
		for k,v in pairs(TMRadio.Blacklist) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					--print("Removing Blacklist: " .. v)
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end

	if #tempGlobalPlaylist < 1 then
		print("TMRadio: created a new GlobalTrueMusic playlist but there were no music mods loaded")
	else
		print("TMRadio: created a new GlobalTrueMusic playlist")
	end

	return tempGlobalPlaylist
end

local String = string

function String:trim()
    return self:match("^%s*(.-)%s*$")
end

function String:words()
    return self:gmatch("[^%s]+")
end

TMRadio.prettyName = function(displayName)
	-- From True Music Jukebox written by Burryaga
	-- Example: Cassette - Michael Cassette - My Name Is Michael Cassette
	prettyName = displayName:gsub("Vinyl %-", "", 1) -- Remove first instance of the word Vinyl followed by a hyphen.
	prettyName = prettyName:gsub("Cassette %-", "", 1) -- Remove first instance of the word Cassette followed by a hyphen.
	prettyName = prettyName:gsub("Vinyl", "", 1) -- Remove first instance of the word Vinyl (if no "Vinyl -" found, this will be found).
	prettyName = prettyName:gsub("Cassette", "", 1) -- Remove first instance of the word Cassette (same as above for cassettes).
	prettyName = prettyName:gsub("^%s*(.-)%s*$", "%1") -- Remove leading and trailing whitespace.
	return prettyName --> Michael Cassette - My Name Is Michael Cassette
end

TMRadio.getWrappedText = function(message, limit, fontSize)
	-- Written by Burryaga
    local result = ""
    local width = 0

    local line = ""
    local length = 0

    local lines = 0

    for word in message:words() do

        local dummy = line .. word .. " "

        if getTextManager():MeasureStringX(fontSize, dummy) > limit then
            local length = getTextManager():MeasureStringX(fontSize, line:trim())
            result = result .. line:trim() .. "\n"
            line = word .. " "
            if length > width then width = length end
            lines = lines + 1
        else
            line = dummy
        end

    end

    -- Add the final line.
    result = result .. line:trim()
    
    lines = lines + 1

    length = getTextManager():MeasureStringX(fontSize, line:trim())

    if length > width then width = length end

    return result, width, lines
end

TMRadio.translation = {
	update = getText("UI_TrueMusicRadio_update"),
	revert = getText("UI_TrueMusicRadio_revert"),
	ejectmedia = getText("UI_TrueMusicRadio_ejectmedia"),
	sayaccessblocked = getText("UI_TrueMusicRadio_sayaccessblocked"),
	sayneedsgenerator = getText("UI_TrueMusicRadio_sayneedsgenerator")
}

TMRadio.config = {
	TMRmuteMusic = nil,
	TMRstopMusic = nil,
	TMRenableRDS = nil,
	TMRenableRDSDeviceText = nil,
	TMRthreeDoff = nil,
	TMRaltThreeD = nil,
	TMRterminalEject = nil,
	TMRterminalBlacklist = nil,
	TMRvolumeSlider = nil,
}

TMRadio.loadConfigOptions = function()
	local options = PZAPI.ModOptions:create("TrueMusicRadio", "True Music Radio Options")
	TMRadio.config.TMRmuteMusic = options:addTickBox("TMRmuteMusic", getText("UI_options_TrueMusicRadio_TMRmuteMusic"), false, getText("UI_options_TrueMusicRadio_TMRmuteMusic_tooltip"))
	TMRadio.config.TMRstopMusic = options:addTickBox("TMRstopMusic", getText("UI_options_TrueMusicRadio_TMRstopMusic"), false, getText("UI_options_TrueMusicRadio_TMRstopMusic_tooltip"))
	TMRadio.config.TMRenableRDS = options:addTickBox("TMRenableRDS", getText("UI_options_TrueMusicRadio_TMRenableRDS"), true, getText("UI_options_TrueMusicRadio_TMRenableRDS_tooltip"))
	TMRadio.config.TMRenableRDSDeviceText = options:addTickBox("TMRenableRDSDeviceText", getText("UI_options_TrueMusicRadio_TMRenableRDSDeviceText"), true, getText("UI_options_TrueMusicRadio_TMRenableRDSDeviceText_tooltip"))
	TMRadio.config.TMRthreeDoff = options:addTickBox("TMRthreeDoff", getText("UI_options_TrueMusicRadio_TMRthreeDoff"), false, getText("UI_options_TrueMusicRadio_TMRthreeDoff_tooltip"))
	TMRadio.config.TMRaltThreeD = options:addTickBox("TMRaltThreeD", getText("UI_options_TrueMusicRadio_TMRaltThreeD"), false, getText("UI_options_TrueMusicRadio_TMRaltThreeD_tooltip"))
	TMRadio.config.TMRterminalEject = options:addTickBox("TMRterminalEject", getText("UI_options_TrueMusicRadio_TMRterminalEject"), true, getText("UI_options_TrueMusicRadio_TMRterminalEject_tooltip"))
	TMRadio.config.TMRterminalBlacklist = options:addTickBox("TMRterminalBlacklist", getText("UI_options_TrueMusicRadio_TMRterminalBlacklist"), true, getText("UI_options_TrueMusicRadio_TMRterminalBlacklist_tooltip"))
	TMRadio.config.TMRvolumeSlider = options:addSlider("TMRvolumeSlider", getText("UI_options_TrueMusicRadio_TMRvolumeSlider"), 0, 11, 1, 10, getText("UI_options_TrueMusicRadio_TMRvolumeSlider_tooltip"))
end

-- modoptions examples to pull the data out
-- PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRmuteMusic"):getValue()
-- PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRterminalEject"):getValue()

TMRadio.loadConfigOptions()

TMRadio.RadioSprites = {
	"appliances_radio_01_0",
	"appliances_radio_01_1",
	"appliances_radio_01_2",
	"appliances_radio_01_3",
	"appliances_radio_01_4",
	"appliances_radio_01_5",
	"appliances_radio_01_6",
	"appliances_radio_01_7",
	"appliances_radio_01_8",
	"appliances_radio_01_9",
	"appliances_radio_01_10",
	"appliances_radio_01_11",
	"appliances_radio_01_12",
	"appliances_radio_01_13",
	"appliances_radio_01_14",
	"appliances_radio_01_15",
	"appliances_radio_01_16",
	"appliances_radio_01_17",
	"appliances_radio_01_18",
	"appliances_radio_01_19"
}

TMRadio.mapLoadingRadios = function(radio)
	local deviceData = radio:getDeviceData()

	if not deviceData:getIsTurnedOn() then
		return
	end

	if deviceData:getDeviceName() == "ValuTech PortaDisc" then
		return
	end

	local radioChannel = radio:getDeviceData():getChannel()

	if not radioChannel then
		return
	end

	if not (radioChannel == SandboxVars.TrueMusicRadio.TMRChannel1 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel2 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel3 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel4 or radioChannel == SandboxVars.TrueMusicRadio.TMRChannel5 or radioChannel == SandboxVars.TrueMusicRadio.TMRMTV) then
		return
	end

	for index,t in ipairs(TMRadio.soundCache) do  
		if t.device == radio then
			if TMRadio.isPlaying(t) then
				return
			end
		end
	end

	local radioX = deviceData:getParent():getX()
	local radioY = deviceData:getParent():getY()
	local radioZ = deviceData:getParent():getZ()
	--print("Activated Radio via maploadwithsprite at x: " .. radioX .. " y: " .. radioY .. " z: " .. radioZ)

	local songNumber = TMRadio.ChooseSong(radioChannel)
	if isClient() and not deviceData:isInventoryDevice() then
		local args = {x = radioX, y = radioY, z = radioZ, channel = radioChannel, number = songNumber}
		sendClientCommand("TMRadio", "Play", args)
	else
		if not TMRadio.Channels[radioChannel] then 
			TMRadio.Channels[radioChannel] = songNumber
			TMRadio.PlaySound(songNumber, radio)
		else
			TMRadio.PlaySound(TMRadio.Channels[radioChannel], radio)
		end
	end
end

MapObjects.OnLoadWithSprite(TMRadio.RadioSprites, TMRadio.mapLoadingRadios, 5)