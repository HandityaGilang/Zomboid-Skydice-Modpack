

	local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")

	local FemaleHeads = {
		{
		name = "Stella",						
		id = "Base.FemaleHead01",
		},
		{
		name = "Susan",						
		id = "Base.FemaleHead02",
		},
		{
		name = "Hana",						
		id = "Base.FemaleHeadAsian",
		},
		{
		name = "Naomi",						
		id = "Base.FemaleHeadAsian2",
		},
		{
		name = "Nia",						
		id = "Base.FemaleHeadAfro",
		},
		{
		name = "Dalila",						
		id = "Base.FemaleHeadAfro2",
		},
		{
		name = "Poppy",						
		id = "Base.FemaleHeadBrit",
		},
		{
		name = "Alice",						
		id = "Base.FemaleHeadCute",
		},
		{
		name = "Aurora",						
		id = "Base.FemaleHeadCute2",
		},
		{
		name = "Lily",						
		id = "Base.FemaleHeadFriendly",
		},
		{
		name = "Julia",						
		id = "Base.FemaleHeadWideMouth",
		},
		{
		name = "Madelyn",						
		id = "Base.FemaleHeadLong",
		},
		{
		name = "Stacey",						
		id = "Base.FemaleRounderEyes",
		},
		{
		name = "Anne",						
		id = "Base.FemaleSadEyes",
		},
		{
		name = "Stella(Old)",						
		id = "Base.FemaleHead01",
		textureOffset = 5,	
		},
		{
		name = "Susan(Old)",						
		id = "Base.FemaleHead02",
		textureOffset = 5,	
		},
		{
		name = "Hana(Old)",						
		id = "Base.FemaleHeadAsian",
		textureOffset = 5,	
		},
		{
		name = "Naomi(Old)",						
		id = "Base.FemaleHeadAsian2",
		textureOffset = 5,	
		},
		{
		name = "Nia(Old)",						
		id = "Base.FemaleHeadAfro",
		textureOffset = 5,	
		},
		{
		name = "Dalila(Old)",						
		id = "Base.FemaleHeadAfro2",
		textureOffset = 5,	
		},
		{
		name = "Poppy(Old)",						
		id = "Base.FemaleHeadBrit",
		textureOffset = 5,	
		},
		{
		name = "Alice(Old)",						
		id = "Base.FemaleHeadCute",
		textureOffset = 5,	
		},
		{
		name = "Aurora(Old)",						
		id = "Base.FemaleHeadCute2",
		textureOffset = 5,	
		},
		{
		name = "Lily(Old)",						
		id = "Base.FemaleHeadFriendly",
		textureOffset = 5,	
		},
		{
		name = "Julia(Old)",						
		id = "Base.FemaleHeadWideMouth",
		textureOffset = 5,	
		},
		{
		name = "Madelyn(Old)",						
		id = "Base.FemaleHeadLong",
		textureOffset = 5,	
		},
		{
		name = "Stacey(Old)",						
		id = "Base.FemaleRounderEyes",
		textureOffset = 5,	
		},
		{
		name = "Anne(Old)",						
		id = "Base.FemaleSadEyes",
		textureOffset = 5,	
		},
	}	
	local MaleHeads = {
		
		{
		name = "Hui",						
		id = "Base.MaleHeadAsian",
		sort = "c"
		},
		{
		name = "Stan",						
		id = "Base.MaleHeadAsian2",
		sort = "c"
		},
		{
		name = "Lamar",						
		id = "Base.MaleHeadAfro",
		sort = "c"
		},
		{
		name = "Dan",						
		id = "Base.MaleHeadBrit",
		sort = "c"
		},
		{
		name = "Alfred",						
		id = "Base.MaleHeadSadEyes",
		sort = "c"
		},
		{
		name = "Ronnie",						
		id = "Base.MaleHeadCute",
		sort = "c"
		},		
		{
		name = "Hui(Old)",						
		id = "Base.MaleHeadAsian",
		textureOffset = 5,	
		sort = "c"
		},
		{
		name = "Stan(Old)",						
		id = "Base.MaleHeadAsian2",
		textureOffset = 5,	
		sort = "c"
		},
		{
		name = "Lamar(Old)",						
		id = "Base.MaleHeadAfro",
		textureOffset = 5,	
		sort = "c"
		},
		{
		name = "Dan(Old)",						
		id = "Base.MaleHeadBrit",
		textureOffset = 5,	
		sort = "c"
		},
		{
		name = "Alfred (Old)",						
		id = "Base.MaleHeadSadEyes",
		textureOffset = 5,	
		sort = "c"
		},
		{
		name = "Ronnie(Old)",						
		id = "Base.MaleHeadCute",
		textureOffset = 5,	
		sort = "c"
		},

	}


	for i, v in ipairs(FemaleHeads) do
		SPNCC_Data.AddFemaleFaceData(v)
	end
	for i, v in ipairs(MaleHeads) do
		SPNCC_Data.AddMaleFaceData(v)
	end



