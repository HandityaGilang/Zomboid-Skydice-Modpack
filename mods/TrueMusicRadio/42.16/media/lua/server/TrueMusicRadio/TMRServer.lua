TMRadioServer = {}

TMRadioServer.PlaylistTerminalA = {}
TMRadioServer.PlaylistTerminalB = {}
TMRadioServer.PlaylistTerminalC = {}
TMRadioServer.PlaylistTerminalD = {}
TMRadioServer.PlaylistTerminalE = {}
TMRadioServer.PlaylistTerminalMTV = {}

TMRadioServer.Channels = {}

TMRadioServer.Blacklist = { "Test" }

TMRadioServer.BlacklistThemeSongs = {
	"CassetteMainTheme",
	"VinylMainTheme",
}

TMRadioServer.BlacklistTCCacheMPSongs = {
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

TMRadioServer.BlacklistHolidaySongs = {
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

TMRadioServer.prettyName = function(displayName)
	-- From True Music Jukebox written by Burryaga
	-- Example: Cassette - Michael Cassette - My Name Is Michael Cassette
	prettyName = displayName:gsub("Vinyl %-", "", 1) -- Remove first instance of the word Vinyl followed by a hyphen.
	prettyName = prettyName:gsub("Cassette %-", "", 1) -- Remove first instance of the word Cassette followed by a hyphen.
	prettyName = prettyName:gsub("Vinyl", "", 1) -- Remove first instance of the word Vinyl (if no "Vinyl -" found, this will be found).
	prettyName = prettyName:gsub("Cassette", "", 1) -- Remove first instance of the word Cassette (same as above for cassettes).
	prettyName = prettyName:gsub("^%s*(.-)%s*$", "%1") -- Remove leading and trailing whitespace.
	return prettyName --> Michael Cassette - My Name Is Michael Cassette
end

TMRadioServer.CreatePlaylist = function()
	local tempGlobalPlaylist = {}

	for k,v in pairs(GlobalMusic) do
		tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
	end

	if SandboxVars.TrueMusicRadio.TMRExcludeThemeSongs then
		for k,v in pairs(TMRadioServer.BlacklistThemeSongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if SandboxVars.TrueMusicRadio.TMRExcludeTCCacheMPSongs then
		for k,v in pairs(TMRadioServer.BlacklistTCCacheMPSongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if SandboxVars.TrueMusicRadio.TMRExcludeHolidaySongs then
		for k,v in pairs(TMRadioServer.BlacklistHolidaySongs) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end
	if TMRadioServer.Blacklist ~= nil and #TMRadioServer.Blacklist > 0 then
		for k,v in pairs(TMRadioServer.Blacklist) do
			for index = #tempGlobalPlaylist, 1, -1 do 
				value = tempGlobalPlaylist[index]
				if value == v then 
					table.remove(tempGlobalPlaylist, index)
					break
				end
			end
		end
	end

	if #tempGlobalPlaylist < 3 then
		print("TMRadio Server: created a new GlobalTrueMusic playlist but there were no music mods loaded")
	else
		print("TMRadio Server: created a new GlobalTrueMusic playlist")
	end

	return tempGlobalPlaylist
end

TMRadioServer.SendServerCommandToClients = function(command, args)
	if not isClient() and not isServer() then
		triggerEvent("OnServerCommand", "TMRadio", command, args) -- Singleplayer
	else
		sendServerCommand("TMRadio", command, args) -- Multiplayer
	end
end

TMRadioServer.Play = function(player, args)
	if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end
	if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
		TMRadioServer.PlaylistTerminalC = ModData.getOrCreate("TMRadioC")
	end
	if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
		TMRadioServer.PlaylistTerminalD = ModData.getOrCreate("TMRadioD")
	end
	if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
		TMRadioServer.PlaylistTerminalE = ModData.getOrCreate("TMRadioE")
	end
	if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
		TMRadioServer.PlaylistTerminalMTV = ModData.getOrCreate("TMRadioMTV")
	end
	if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	end
	if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	end
	if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
		TMRadioServer.PlaylistTerminalC = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioC", TMRadioServer.PlaylistTerminalC)
	end
	if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
		TMRadioServer.PlaylistTerminalD = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioD", TMRadioServer.PlaylistTerminalD)
	end
	if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
		TMRadioServer.PlaylistTerminalE = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioE", TMRadioServer.PlaylistTerminalE)
	end
	if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
		TMRadioServer.PlaylistTerminalMTV = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
	end
	if not TMRadioServer.Channels[args.channel] then
		--print("TMRadio: adding channel to channel list")
		TMRadioServer.Channels[args.channel] = args.number

		if SandboxVars.TrueMusicRadio.TMRRadioSongAnnouncements then
			local songName = nil
			if args.channel == SandboxVars.TrueMusicRadio.TMRChannel1 then	
    				songName = TMRadioServer.PlaylistTerminalA[args.number]
			elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel2 then
    				songName = TMRadioServer.PlaylistTerminalB[args.number]
			elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel3 then
    				songName = TMRadioServer.PlaylistTerminalC[args.number]
			elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel4 then
    				songName = TMRadioServer.PlaylistTerminalD[args.number]
			elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel5 then
    				songName = TMRadioServer.PlaylistTerminalE[args.number]
			elseif args.channel == SandboxVars.TrueMusicRadio.TMRMTV then
    				songName = TMRadioServer.PlaylistTerminalMTV[args.number]
			end
			local musicItem = "Tsarcraft." .. songName
			local displayName = getItemNameFromFullType(musicItem)
			local prettyName = TMRadioServer.prettyName(displayName)
			DynamicRadio.OnNewSong(args.channel, prettyName)
		end
	else
		--print("TMRadio: song already attached to current channel list, send it to the client")
		args.number = TMRadioServer.Channels[args.channel]
	end
	ModData.add("TMRadioChannels", TMRadioServer.Channels)
	print("TMRadio Server: Sending play to clients")
	TMRadioServer.SendServerCommandToClients("Play", args)
end

TMRadioServer.Stop = function(player, args)
	print("TMRadio Server: Sending stop to clients")
	TMRadioServer.SendServerCommandToClients("Stop", args)
end

TMRadioServer.PlayNext = function(player, args)
	if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
	end
	if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
	end
	if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
		TMRadioServer.PlaylistTerminalC = ModData.getOrCreate("TMRadioC")
	end
	if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
		TMRadioServer.PlaylistTerminalD = ModData.getOrCreate("TMRadioD")
	end
	if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
		TMRadioServer.PlaylistTerminalE = ModData.getOrCreate("TMRadioE")
	end
	if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
		TMRadioServer.PlaylistTerminalMTV = ModData.getOrCreate("TMRadioMTV")
	end
	if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
		TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	end
	if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
		TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	end
	if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
		TMRadioServer.PlaylistTerminalC = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioC", TMRadioServer.PlaylistTerminalC)
	end
	if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
		TMRadioServer.PlaylistTerminalD = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioD", TMRadioServer.PlaylistTerminalD)
	end
	if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
		TMRadioServer.PlaylistTerminalE = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioE", TMRadioServer.PlaylistTerminalE)
	end
	if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
		TMRadioServer.PlaylistTerminalMTV = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
	end
	TMRadioServer.Channels[args.channel] = args.number
	ModData.add("TMRadioChannels", TMRadioServer.Channels)
	print("TMRadio Server: Sending playnext to clients")
	TMRadioServer.SendServerCommandToClients("PlayNext", args)

	if SandboxVars.TrueMusicRadio.TMRRadioSongAnnouncements then
		local songName = nil
		if args.channel == SandboxVars.TrueMusicRadio.TMRChannel1 then	
    			songName = TMRadioServer.PlaylistTerminalA[args.number]
		elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel2 then
    			songName = TMRadioServer.PlaylistTerminalB[args.number]
		elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel3 then
    			songName = TMRadioServer.PlaylistTerminalC[args.number]
		elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel4 then
    			songName = TMRadioServer.PlaylistTerminalD[args.number]
		elseif args.channel == SandboxVars.TrueMusicRadio.TMRChannel5 then
    			songName = TMRadioServer.PlaylistTerminalE[args.number]
		elseif args.channel == SandboxVars.TrueMusicRadio.TMRMTV then
    			songName = TMRadioServer.PlaylistTerminalMTV[args.number]
		end
		local musicItem = "Tsarcraft." .. songName
		local displayName = getItemNameFromFullType(musicItem)
		local prettyName = TMRadioServer.prettyName(displayName)
		DynamicRadio.OnNewSong(args.channel, prettyName)
	end
end

TMRadioServer.UpdatePlaylistTerminalA = function(player, args)
	if args.request == true then
		--print("TMRadio Server: Client requesting A")
		if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
			--print("TMRadio Server: A not found, pull from moddata")
			TMRadioServer.PlaylistTerminalA = ModData.getOrCreate("TMRadioA")
		end
		if TMRadioServer.PlaylistTerminalA == nil or #TMRadioServer.PlaylistTerminalA == 0 then
			--print("TMRadio Server: A still not found, create default list")
			TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating A from client")
		TMRadioServer.PlaylistTerminalA = args
	end
	ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
	--ModData.transmit("TMRadioA", TMRadioServer.PlaylistTerminalA)	
	print("Server: updated A send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalA", TMRadioServer.PlaylistTerminalA)
end

TMRadioServer.UpdatePlaylistTerminalB = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting B")
		if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
			--print("TMRadio Server: B not found, pull from moddata")
			TMRadioServer.PlaylistTerminalB = ModData.getOrCreate("TMRadioB")
		end
		if TMRadioServer.PlaylistTerminalB == nil or #TMRadioServer.PlaylistTerminalB == 0 then
			--print("TMRadio Server: B still not found, create default list")
			TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating B from client")
		TMRadioServer.PlaylistTerminalB = args
	end
	ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
	--ModData.transmit("TMRadioB", TMRadioServer.PlaylistTerminalB)
	print("TMRadio Server: updated B send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalB", TMRadioServer.PlaylistTerminalB)
end

TMRadioServer.UpdatePlaylistTerminalC = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting C")
		if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
			--print("TMRadio Server: C not found, pull from moddata")
			TMRadioServer.PlaylistTerminalC = ModData.getOrCreate("TMRadioC")
		end
		if TMRadioServer.PlaylistTerminalC == nil or #TMRadioServer.PlaylistTerminalC == 0 then
			--print("TMRadio Server: C still not found, create default list")
			TMRadioServer.PlaylistTerminalC = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating C from client")
		TMRadioServer.PlaylistTerminalC = args
	end
	ModData.add("TMRadioC", TMRadioServer.PlaylistTerminalC)
	--ModData.transmit("TMRadioC", TMRadioServer.PlaylistTerminalC)
	print("TMRadio Server: updated C send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalC", TMRadioServer.PlaylistTerminalC)
end

TMRadioServer.UpdatePlaylistTerminalD = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting D")
		if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
			--print("TMRadio Server: D not found, pull from moddata")
			TMRadioServer.PlaylistTerminalD = ModData.getOrCreate("TMRadioD")
		end
		if TMRadioServer.PlaylistTerminalD == nil or #TMRadioServer.PlaylistTerminalD == 0 then
			--print("TMRadio Server: D still not found, create default list")
			TMRadioServer.PlaylistTerminalD = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating D from client")
		TMRadioServer.PlaylistTerminalD = args
	end
	ModData.add("TMRadioD", TMRadioServer.PlaylistTerminalD)
	--ModData.transmit("TMRadioD", TMRadioServer.PlaylistTerminalD)
	print("TMRadio Server: updated D send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalD", TMRadioServer.PlaylistTerminalD)
end

TMRadioServer.UpdatePlaylistTerminalE = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting E")
		if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
			--print("TMRadio Server: E not found, pull from moddata")
			TMRadioServer.PlaylistTerminalE = ModData.getOrCreate("TMRadioE")
		end
		if TMRadioServer.PlaylistTerminalE == nil or #TMRadioServer.PlaylistTerminalE == 0 then
			--print("TMRadio Server: E still not found, create default list")
			TMRadioServer.PlaylistTerminalE = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating E from client")
		TMRadioServer.PlaylistTerminalE = args
	end
	ModData.add("TMRadioE", TMRadioServer.PlaylistTerminalE)
	--ModData.transmit("TMRadioE", TMRadioServer.PlaylistTerminalE)
	print("TMRadio Server: updated E send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalE", TMRadioServer.PlaylistTerminalE)
end

TMRadioServer.UpdatePlaylistTerminalMTV = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting MTV")
		if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
			--print("TMRadio Server: MTV not found, pull from moddata")
			TMRadioServer.PlaylistTerminalMTV = ModData.getOrCreate("TMRadioMTV")
		end
		if TMRadioServer.PlaylistTerminalMTV == nil or #TMRadioServer.PlaylistTerminalMTV == 0 then
			--print("TMRadio Server: MTV still not found, create default list")
			TMRadioServer.PlaylistTerminalMTV = TMRadioServer.CreatePlaylist()
		end
	else
		--print("TMRadio Server: Updating MTV from client")
		TMRadioServer.PlaylistTerminalMTV = args
	end
	ModData.add("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
	--ModData.transmit("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
	print("TMRadio Server: updated MTV send to clients")
	TMRadioServer.SendServerCommandToClients("UpdatePlaylistTerminalMTV", TMRadioServer.PlaylistTerminalMTV)
end

TMRadioServer.UpdateChannels = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting channels")
		TMRadioServer.Channels = ModData.getOrCreate("TMRadioChannels")
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] > #TMRadioServer.PlaylistTerminalA then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] = ZombRand(1, #TMRadioServer.PlaylistTerminalA)
		end
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] > #TMRadioServer.PlaylistTerminalB then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] = ZombRand(1, #TMRadioServer.PlaylistTerminalB)
		end
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] > #TMRadioServer.PlaylistTerminalC then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] = ZombRand(1, #TMRadioServer.PlaylistTerminalC)
		end
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] > #TMRadioServer.PlaylistTerminalD then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] = ZombRand(1, #TMRadioServer.PlaylistTerminalD)
		end
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] > #TMRadioServer.PlaylistTerminalE then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] = ZombRand(1, #TMRadioServer.PlaylistTerminalE)
		end
		if TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRMTV] == nil or TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRMTV] > #TMRadioServer.PlaylistTerminalMTV then
			TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRMTV] = ZombRand(1, #TMRadioServer.PlaylistTerminalMTV)
		end
		print("TMRadio Server: Updated channels send to clients")
		--print(SandboxVars.TrueMusicRadio.TMRChannel1/1000 .. "FM: " ..  TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel1])
		--print(SandboxVars.TrueMusicRadio.TMRChannel2/1000 .. "FM: " ..  TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel2])
		--print(SandboxVars.TrueMusicRadio.TMRChannel3/1000 .. "FM: " ..  TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel3])
		--print(SandboxVars.TrueMusicRadio.TMRChannel4/1000 .. "FM: " ..  TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel4])
		--print(SandboxVars.TrueMusicRadio.TMRChannel5/1000 .. "FM: " ..  TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel5])
		ModData.add("TMRadioChannels", TMRadioServer.Channels)
		TMRadioServer.SendServerCommandToClients("UpdateChannels", TMRadioServer.Channels)
	end
end

TMRadioServer.UpdateBlacklist = function(player, args) 
	if args.request == true then
		--print("TMRadio Server: Client requesting E")
		if TMRadioServer.Blacklist == nil or #TMRadioServer.Blacklist == 0 then
			--print("TMRadio Server: blacklist not found, pull from moddata")
			TMRadioServer.Blacklist = ModData.getOrCreate("TMRadioBlacklist")
		end
		if TMRadioServer.Blacklist == nil or #TMRadioServer.Blacklist == 0 then
			--print("TMRadio Server: blacklist still not found, nothing to send")
		end
	else
		--print("TMRadio Server: Updating blacklist from client")
		TMRadioServer.Blacklist = args
	end
	ModData.add("TMRadioBlacklist", TMRadioServer.Blacklist)
	--ModData.transmit("TMRadioBlacklist", TMRadioServer.Blacklist)
	print("TMRadio Server: updated blacklist send to clients")
	TMRadioServer.SendServerCommandToClients("UpdateBlacklist", TMRadioServer.Blacklist)
end

TMRadioServer.EjectMedia = function(player, args) 
	--print("TMRadio Server: Ejecting Media from Terminal")
	if args then
		local item = instanceItem(args.media)
		player:getInventory():AddItem(item);
		sendAddItemToContainer(player:getInventory(), item);
	end
end

TMRadioServer.SetStat = function(player, args) 
	--print("TMRadio Server: Changing player stats")
	if args then
		local stat = args.stat
		local amount = args.amount
		if stat == "BOREDOM" then
			player:getStats():set(CharacterStat.BOREDOM, amount)
		elseif stat == "UNHAPPINESS" then
			player:getStats():set(CharacterStat.UNHAPPINESS, amount)
		end
	end
end

TMRadioServer.OnClientCommand = function(module, command, player, args)
    	if not (module == "TMRadio" and TMRadioServer[command]) then
		return
	end
	--print("TMRadio Server: Getting a " .. command .. " from a client.")
	TMRadioServer[command](player, args)
end

Events.OnClientCommand.Add(TMRadioServer.OnClientCommand)

TMRadioServer.OnReceiveGlobalModData = function(module, args)
	if not args then
		return
	end
	
    	if module == "TMRadioA" then
		TMRadioServer.PlaylistTerminalA = args
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
		ModData.transmit("TMRadioA", TMRadioServer.PlaylistTerminalA)	
	elseif module == "TMRadioB" then
		TMRadioServer.PlaylistTerminalB = args
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
		ModData.transmit("TMRadioB", TMRadioServer.PlaylistTerminalB)	
	elseif module == "TMRadioC" then
		TMRadioServer.PlaylistTerminalC = args
		ModData.add("TMRadioC", TMRadioServer.PlaylistTerminalC)
		ModData.transmit("TMRadioC", TMRadioServer.PlaylistTerminalC)
	elseif module == "TMRadioD" then
		TMRadioServer.PlaylistTerminalD = args
		ModData.add("TMRadioD", TMRadioServer.PlaylistTerminalD)
		ModData.transmit("TMRadioD", TMRadioServer.PlaylistTerminalD)
	elseif module == "TMRadioE" then
		TMRadioServer.PlaylistTerminalE = args
		ModData.add("TMRadioE", TMRadioServer.PlaylistTerminalE)
		ModData.transmit("TMRadioE", TMRadioServer.PlaylistTerminalE)	
	elseif module == "TMRadioMTV" then
		TMRadioServer.PlaylistTerminalMTV = args
		ModData.add("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
		ModData.transmit("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)	
	elseif module == "TMRadioBlacklist" then
		TMRadioServer.Blacklist = args
		ModData.add("TMRadioBlacklist", TMRadioServer.Blacklist)
		ModData.transmit("TMRadioBlacklist", TMRadioServer.Blacklist)	
	end
end

Events.OnReceiveGlobalModData.Add(TMRadioServer.OnReceiveGlobalModData)

TMRadioServer.OnServerStarted = function() 
	TMRadioServer.OldPlaylistGlobal = ModData.getOrCreate("TMRadioOldPlaylistGlobal")
	TMRadioServer.PlaylistGlobal = {}
	for k,v in pairs(GlobalMusic) do
		TMRadioServer.PlaylistGlobal[#TMRadioServer.PlaylistGlobal + 1] = k
	end
	if #TMRadioServer.OldPlaylistGlobal == #TMRadioServer.PlaylistGlobal then
		print("TMRadioServer: The current global music list matches old list. Old: " .. #TMRadioServer.OldPlaylistGlobal .. " New: " .. #TMRadioServer.PlaylistGlobal)
	else
		print("TMRadioServer: The current global music list doesn't match the old list. Old: " .. #TMRadioServer.OldPlaylistGlobal .. " New: " .. #TMRadioServer.PlaylistGlobal .. " Reverting all stations for the update.")
		ModData.add("TMRadioOldPlaylistGlobal", TMRadioServer.PlaylistGlobal)
		TMRadioServer.PlaylistTerminalA = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioA", TMRadioServer.PlaylistTerminalA)
		TMRadioServer.PlaylistTerminalB = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioB", TMRadioServer.PlaylistTerminalB)
		TMRadioServer.PlaylistTerminalC = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioC", TMRadioServer.PlaylistTerminalC)
		TMRadioServer.PlaylistTerminalD = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioD", TMRadioServer.PlaylistTerminalD)
		TMRadioServer.PlaylistTerminalE = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioE", TMRadioServer.PlaylistTerminalE)
		TMRadioServer.PlaylistTerminalMTV = TMRadioServer.CreatePlaylist()
		ModData.add("TMRadioMTV", TMRadioServer.PlaylistTerminalMTV)
		TMRadioServer.Channels = ModData.getOrCreate("TMRadioChannels")
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel1] = ZombRand(1, #TMRadioServer.PlaylistTerminalA)
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel2] = ZombRand(1, #TMRadioServer.PlaylistTerminalB)
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel3] = ZombRand(1, #TMRadioServer.PlaylistTerminalC)
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel4] = ZombRand(1, #TMRadioServer.PlaylistTerminalD)
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRChannel5] = ZombRand(1, #TMRadioServer.PlaylistTerminalE)
		TMRadioServer.Channels[SandboxVars.TrueMusicRadio.TMRMTV] = ZombRand(1, #TMRadioServer.PlaylistTerminalMTV)
		ModData.add("TMRadioChannels", TMRadioServer.Channels)
	end
end

Events.OnServerStarted.Add(TMRadioServer.OnServerStarted)

return TMRadioServer