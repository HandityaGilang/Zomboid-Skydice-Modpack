
local function LSWardrobeData()

	local playerObj = getPlayer()
	local playerData = playerObj:getModData()
	local item

	--CASUAL
	if playerObj:hasModData()
		and playerData.CasualClothes ~= nil
	then
	else
		playerData.CasualClothes = {}
	end
	
	if #playerObj:getModData().CasualClothes < 1 then
		playerData.CasualClothes = {}
		if playerData.CasualClothes0 then item = playerData.CasualClothes0; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes1 then item = playerData.CasualClothes1; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes2 then item = playerData.CasualClothes2; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes3 then item = playerData.CasualClothes3; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes4 then item = playerData.CasualClothes4; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes5 then item = playerData.CasualClothes5; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes6 then item = playerData.CasualClothes6; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes7 then item = playerData.CasualClothes7; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes8 then item = playerData.CasualClothes8; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes9 then item = playerData.CasualClothes9; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes10 then item = playerData.CasualClothes10; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes11 then item = playerData.CasualClothes11; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes12 then item = playerData.CasualClothes12; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes13 then item = playerData.CasualClothes13; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes14 then item = playerData.CasualClothes14; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes15 then item = playerData.CasualClothes15; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes16 then item = playerData.CasualClothes16; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes17 then item = playerData.CasualClothes17; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes18 then item = playerData.CasualClothes18; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes19 then item = playerData.CasualClothes19; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes20 then item = playerData.CasualClothes20; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes21 then item = playerData.CasualClothes21; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes22 then item = playerData.CasualClothes22; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes23 then item = playerData.CasualClothes23; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes24 then item = playerData.CasualClothes24; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes25 then item = playerData.CasualClothes25; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes26 then item = playerData.CasualClothes26; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes27 then item = playerData.CasualClothes27; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes28 then item = playerData.CasualClothes28; table.insert(playerData.CasualClothes, item); end	
		if playerData.CasualClothes29 then item = playerData.CasualClothes29; table.insert(playerData.CasualClothes, item); end
		if playerData.CasualClothes30 then item = playerData.CasualClothes30; table.insert(playerData.CasualClothes, item); end
	end

	--FORMAL
	if playerObj:hasModData()
		and playerData.FormalClothes ~= nil
	then
	else
		playerData.FormalClothes = {}
	end
	
	if #playerObj:getModData().FormalClothes < 1 then
		playerData.FormalClothes = {}
		if playerData.FormalClothes0 then item = playerData.FormalClothes0; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes1 then item = playerData.FormalClothes1; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes2 then item = playerData.FormalClothes2; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes3 then item = playerData.FormalClothes3; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes4 then item = playerData.FormalClothes4; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes5 then item = playerData.FormalClothes5; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes6 then item = playerData.FormalClothes6; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes7 then item = playerData.FormalClothes7; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes8 then item = playerData.FormalClothes8; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes9 then item = playerData.FormalClothes9; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes10 then item = playerData.FormalClothes10; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes11 then item = playerData.FormalClothes11; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes12 then item = playerData.FormalClothes12; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes13 then item = playerData.FormalClothes13; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes14 then item = playerData.FormalClothes14; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes15 then item = playerData.FormalClothes15; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes16 then item = playerData.FormalClothes16; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes17 then item = playerData.FormalClothes17; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes18 then item = playerData.FormalClothes18; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes19 then item = playerData.FormalClothes19; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes20 then item = playerData.FormalClothes20; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes21 then item = playerData.FormalClothes21; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes22 then item = playerData.FormalClothes22; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes23 then item = playerData.FormalClothes23; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes24 then item = playerData.FormalClothes24; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes25 then item = playerData.FormalClothes25; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes26 then item = playerData.FormalClothes26; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes27 then item = playerData.FormalClothes27; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes28 then item = playerData.FormalClothes28; table.insert(playerData.FormalClothes, item); end	
		if playerData.FormalClothes29 then item = playerData.FormalClothes29; table.insert(playerData.FormalClothes, item); end
		if playerData.FormalClothes30 then item = playerData.FormalClothes30; table.insert(playerData.FormalClothes, item); end
	end

	--GYM
	if playerObj:hasModData()
		and playerData.GymClothes ~= nil
	then
	else
		playerData.GymClothes = {}
	end
	
	if #playerObj:getModData().GymClothes < 1 then
		playerData.GymClothes = {}
		if playerData.GymClothes0 then item = playerData.GymClothes0; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes1 then item = playerData.GymClothes1; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes2 then item = playerData.GymClothes2; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes3 then item = playerData.GymClothes3; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes4 then item = playerData.GymClothes4; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes5 then item = playerData.GymClothes5; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes6 then item = playerData.GymClothes6; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes7 then item = playerData.GymClothes7; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes8 then item = playerData.GymClothes8; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes9 then item = playerData.GymClothes9; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes10 then item = playerData.GymClothes10; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes11 then item = playerData.GymClothes11; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes12 then item = playerData.GymClothes12; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes13 then item = playerData.GymClothes13; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes14 then item = playerData.GymClothes14; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes15 then item = playerData.GymClothes15; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes16 then item = playerData.GymClothes16; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes17 then item = playerData.GymClothes17; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes18 then item = playerData.GymClothes18; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes19 then item = playerData.GymClothes19; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes20 then item = playerData.GymClothes20; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes21 then item = playerData.GymClothes21; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes22 then item = playerData.GymClothes22; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes23 then item = playerData.GymClothes23; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes24 then item = playerData.GymClothes24; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes25 then item = playerData.GymClothes25; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes26 then item = playerData.GymClothes26; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes27 then item = playerData.GymClothes27; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes28 then item = playerData.GymClothes28; table.insert(playerData.GymClothes, item); end	
		if playerData.GymClothes29 then item = playerData.GymClothes29; table.insert(playerData.GymClothes, item); end
		if playerData.GymClothes30 then item = playerData.GymClothes30; table.insert(playerData.GymClothes, item); end
	end

	--SLEEP
	if playerObj:hasModData()
		and playerData.SleepClothes ~= nil
	then
	else
		playerData.SleepClothes = {}
	end
	
	if #playerObj:getModData().SleepClothes < 1 then
		playerData.SleepClothes = {}
		if playerData.SleepClothes0 then item = playerData.SleepClothes0; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes1 then item = playerData.SleepClothes1; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes2 then item = playerData.SleepClothes2; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes3 then item = playerData.SleepClothes3; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes4 then item = playerData.SleepClothes4; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes5 then item = playerData.SleepClothes5; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes6 then item = playerData.SleepClothes6; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes7 then item = playerData.SleepClothes7; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes8 then item = playerData.SleepClothes8; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes9 then item = playerData.SleepClothes9; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes10 then item = playerData.SleepClothes10; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes11 then item = playerData.SleepClothes11; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes12 then item = playerData.SleepClothes12; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes13 then item = playerData.SleepClothes13; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes14 then item = playerData.SleepClothes14; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes15 then item = playerData.SleepClothes15; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes16 then item = playerData.SleepClothes16; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes17 then item = playerData.SleepClothes17; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes18 then item = playerData.SleepClothes18; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes19 then item = playerData.SleepClothes19; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes20 then item = playerData.SleepClothes20; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes21 then item = playerData.SleepClothes21; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes22 then item = playerData.SleepClothes22; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes23 then item = playerData.SleepClothes23; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes24 then item = playerData.SleepClothes24; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes25 then item = playerData.SleepClothes25; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes26 then item = playerData.SleepClothes26; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes27 then item = playerData.SleepClothes27; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes28 then item = playerData.SleepClothes28; table.insert(playerData.SleepClothes, item); end	
		if playerData.SleepClothes29 then item = playerData.SleepClothes29; table.insert(playerData.SleepClothes, item); end
		if playerData.SleepClothes30 then item = playerData.SleepClothes30; table.insert(playerData.SleepClothes, item); end
	end

	--PARTY
	if playerObj:hasModData()
		and playerData.PartyClothes ~= nil
	then
	else
		playerData.PartyClothes = {}
	end
	
	if #playerObj:getModData().PartyClothes < 1 then
		playerData.PartyClothes = {}
		if playerData.PartyClothes0 then item = playerData.PartyClothes0; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes1 then item = playerData.PartyClothes1; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes2 then item = playerData.PartyClothes2; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes3 then item = playerData.PartyClothes3; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes4 then item = playerData.PartyClothes4; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes5 then item = playerData.PartyClothes5; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes6 then item = playerData.PartyClothes6; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes7 then item = playerData.PartyClothes7; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes8 then item = playerData.PartyClothes8; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes9 then item = playerData.PartyClothes9; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes10 then item = playerData.PartyClothes10; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes11 then item = playerData.PartyClothes11; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes12 then item = playerData.PartyClothes12; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes13 then item = playerData.PartyClothes13; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes14 then item = playerData.PartyClothes14; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes15 then item = playerData.PartyClothes15; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes16 then item = playerData.PartyClothes16; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes17 then item = playerData.PartyClothes17; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes18 then item = playerData.PartyClothes18; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes19 then item = playerData.PartyClothes19; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes20 then item = playerData.PartyClothes20; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes21 then item = playerData.PartyClothes21; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes22 then item = playerData.PartyClothes22; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes23 then item = playerData.PartyClothes23; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes24 then item = playerData.PartyClothes24; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes25 then item = playerData.PartyClothes25; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes26 then item = playerData.PartyClothes26; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes27 then item = playerData.PartyClothes27; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes28 then item = playerData.PartyClothes28; table.insert(playerData.PartyClothes, item); end	
		if playerData.PartyClothes29 then item = playerData.PartyClothes29; table.insert(playerData.PartyClothes, item); end
		if playerData.PartyClothes30 then item = playerData.PartyClothes30; table.insert(playerData.PartyClothes, item); end
	end

	--SUMMER
	if playerObj:hasModData()
		and playerData.SummerClothes ~= nil
	then
	else
		playerData.SummerClothes = {}
	end

	if #playerObj:getModData().SummerClothes < 1 then
		playerData.SummerClothes = {}
		if playerData.SummerClothes0 then item = playerData.SummerClothes0; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes1 then item = playerData.SummerClothes1; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes2 then item = playerData.SummerClothes2; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes3 then item = playerData.SummerClothes3; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes4 then item = playerData.SummerClothes4; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes5 then item = playerData.SummerClothes5; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes6 then item = playerData.SummerClothes6; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes7 then item = playerData.SummerClothes7; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes8 then item = playerData.SummerClothes8; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes9 then item = playerData.SummerClothes9; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes10 then item = playerData.SummerClothes10; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes11 then item = playerData.SummerClothes11; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes12 then item = playerData.SummerClothes12; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes13 then item = playerData.SummerClothes13; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes14 then item = playerData.SummerClothes14; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes15 then item = playerData.SummerClothes15; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes16 then item = playerData.SummerClothes16; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes17 then item = playerData.SummerClothes17; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes18 then item = playerData.SummerClothes18; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes19 then item = playerData.SummerClothes19; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes20 then item = playerData.SummerClothes20; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes21 then item = playerData.SummerClothes21; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes22 then item = playerData.SummerClothes22; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes23 then item = playerData.SummerClothes23; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes24 then item = playerData.SummerClothes24; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes25 then item = playerData.SummerClothes25; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes26 then item = playerData.SummerClothes26; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes27 then item = playerData.SummerClothes27; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes28 then item = playerData.SummerClothes28; table.insert(playerData.SummerClothes, item); end	
		if playerData.SummerClothes29 then item = playerData.SummerClothes29; table.insert(playerData.SummerClothes, item); end
		if playerData.SummerClothes30 then item = playerData.SummerClothes30; table.insert(playerData.SummerClothes, item); end
	end

	--WINTER
	if playerObj:hasModData()
		and playerData.WinterClothes ~= nil
	then
	else
		playerData.WinterClothes = {}
	end

	if #playerObj:getModData().WinterClothes < 1 then
		playerData.WinterClothes = {}
		if playerData.WinterClothes0 then item = playerData.WinterClothes0; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes1 then item = playerData.WinterClothes1; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes2 then item = playerData.WinterClothes2; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes3 then item = playerData.WinterClothes3; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes4 then item = playerData.WinterClothes4; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes5 then item = playerData.WinterClothes5; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes6 then item = playerData.WinterClothes6; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes7 then item = playerData.WinterClothes7; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes8 then item = playerData.WinterClothes8; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes9 then item = playerData.WinterClothes9; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes10 then item = playerData.WinterClothes10; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes11 then item = playerData.WinterClothes11; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes12 then item = playerData.WinterClothes12; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes13 then item = playerData.WinterClothes13; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes14 then item = playerData.WinterClothes14; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes15 then item = playerData.WinterClothes15; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes16 then item = playerData.WinterClothes16; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes17 then item = playerData.WinterClothes17; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes18 then item = playerData.WinterClothes18; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes19 then item = playerData.WinterClothes19; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes20 then item = playerData.WinterClothes20; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes21 then item = playerData.WinterClothes21; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes22 then item = playerData.WinterClothes22; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes23 then item = playerData.WinterClothes23; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes24 then item = playerData.WinterClothes24; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes25 then item = playerData.WinterClothes25; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes26 then item = playerData.WinterClothes26; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes27 then item = playerData.WinterClothes27; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes28 then item = playerData.WinterClothes28; table.insert(playerData.WinterClothes, item); end	
		if playerData.WinterClothes29 then item = playerData.WinterClothes29; table.insert(playerData.WinterClothes, item); end
		if playerData.WinterClothes30 then item = playerData.WinterClothes30; table.insert(playerData.WinterClothes, item); end
	end

	--WORK
	if playerObj:hasModData()
		and playerData.WorkClothes ~= nil
	then
	else
		playerData.WorkClothes = {}
	end
	
	if #playerObj:getModData().WorkClothes < 1 then
		playerData.WorkClothes = {}
		if playerData.WorkClothes0 then item = playerData.WorkClothes0; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes1 then item = playerData.WorkClothes1; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes2 then item = playerData.WorkClothes2; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes3 then item = playerData.WorkClothes3; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes4 then item = playerData.WorkClothes4; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes5 then item = playerData.WorkClothes5; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes6 then item = playerData.WorkClothes6; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes7 then item = playerData.WorkClothes7; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes8 then item = playerData.WorkClothes8; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes9 then item = playerData.WorkClothes9; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes10 then item = playerData.WorkClothes10; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes11 then item = playerData.WorkClothes11; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes12 then item = playerData.WorkClothes12; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes13 then item = playerData.WorkClothes13; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes14 then item = playerData.WorkClothes14; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes15 then item = playerData.WorkClothes15; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes16 then item = playerData.WorkClothes16; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes17 then item = playerData.WorkClothes17; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes18 then item = playerData.WorkClothes18; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes19 then item = playerData.WorkClothes19; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes20 then item = playerData.WorkClothes20; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes21 then item = playerData.WorkClothes21; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes22 then item = playerData.WorkClothes22; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes23 then item = playerData.WorkClothes23; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes24 then item = playerData.WorkClothes24; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes25 then item = playerData.WorkClothes25; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes26 then item = playerData.WorkClothes26; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes27 then item = playerData.WorkClothes27; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes28 then item = playerData.WorkClothes28; table.insert(playerData.WorkClothes, item); end	
		if playerData.WorkClothes29 then item = playerData.WorkClothes29; table.insert(playerData.WorkClothes, item); end
		if playerData.WorkClothes30 then item = playerData.WorkClothes30; table.insert(playerData.WorkClothes, item); end
	end

	--COMBAT
	if playerObj:hasModData()
		and playerData.CombatClothes ~= nil
	then
	else
		playerData.CombatClothes = {}
	end
	
	if #playerObj:getModData().CombatClothes < 1 then
		playerData.CombatClothes = {}
		if playerData.CombatClothes0 then item = playerData.CombatClothes0; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes1 then item = playerData.CombatClothes1; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes2 then item = playerData.CombatClothes2; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes3 then item = playerData.CombatClothes3; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes4 then item = playerData.CombatClothes4; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes5 then item = playerData.CombatClothes5; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes6 then item = playerData.CombatClothes6; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes7 then item = playerData.CombatClothes7; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes8 then item = playerData.CombatClothes8; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes9 then item = playerData.CombatClothes9; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes10 then item = playerData.CombatClothes10; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes11 then item = playerData.CombatClothes11; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes12 then item = playerData.CombatClothes12; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes13 then item = playerData.CombatClothes13; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes14 then item = playerData.CombatClothes14; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes15 then item = playerData.CombatClothes15; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes16 then item = playerData.CombatClothes16; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes17 then item = playerData.CombatClothes17; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes18 then item = playerData.CombatClothes18; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes19 then item = playerData.CombatClothes19; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes20 then item = playerData.CombatClothes20; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes21 then item = playerData.CombatClothes21; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes22 then item = playerData.CombatClothes22; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes23 then item = playerData.CombatClothes23; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes24 then item = playerData.CombatClothes24; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes25 then item = playerData.CombatClothes25; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes26 then item = playerData.CombatClothes26; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes27 then item = playerData.CombatClothes27; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes28 then item = playerData.CombatClothes28; table.insert(playerData.CombatClothes, item); end	
		if playerData.CombatClothes29 then item = playerData.CombatClothes29; table.insert(playerData.CombatClothes, item); end
		if playerData.CombatClothes30 then item = playerData.CombatClothes30; table.insert(playerData.CombatClothes, item); end
	end

end

Events.OnCreatePlayer.Add(LSWardrobeData);
