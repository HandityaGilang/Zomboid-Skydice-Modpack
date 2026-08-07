local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")
-- local FM_Presets = require("CharacterCustomisation/FM_Presets")

	-- ----------------------
	-- -- 	MALE FACES
	-- ----------------------
local MaleFaces = {
	--------------------------
	{	name = "Jake",
		id = "Base.Face_Jake",
	},
	--------------------------
	{	name = "Iroquois",
		id = "Base.Face_Iroquois",
	},
	--------------------------
	{	name = "Patrick",
		id = "Base.Face_Patrick",
	},
	--------------------------
	{	name = "Peter",
		id = "Base.Face_Peter",
	},
	--------------------------
	{	name = "Jason",
		id = "Base.Face_Jason",
	},
	--------------------------
	{	name = "Slater",
		id = "Base.Face_Slater",
	},
	--------------------------
	{	name = "Zach",
		id = "Base.Face_Zach",
	},
	--------------------------
	{	name = "Jaeger",
		id = "Base.Face_Jaeger",
	},
	--------------------------
	{	name = "Louis",
		id = "Base.Face_Louis",
	},
}
	-- ----------------------
	-- -- 	FEMALE FACES
	-- ----------------------
local FemaleFaces = {
	--------------------------
	{	name = "Joy",
		id = "Base.Face_Joy",
	},
		--------------------------
	{	name = "Veronica",
		id = "Base.Face_Veronica",
	},
		--------------------------
	{	name = "Alice",
		id = "Base.Face_Alice",
	},
		--------------------------
	{	name = "Sophie",
		id = "Base.Face_Sophie",
	},
			--------------------------
	{	name = "Emily",
		id = "Base.Face_Emily",
	},
			--------------------------
	{	name = "Anna",
		id = "Base.Face_Anna",
	},
			--------------------------
	{	name = "Sammy",
		id = "Base.Face_Sammy",
	},
			--------------------------
	{	name = "Lotte",
		id = "Base.Face_Lotte",
	},
			--------------------------
	{	name = "Lucy",
		id = "Base.Face_Lucy",
	},
}

for i, v in ipairs(MaleFaces) do
	SPNCC_Data.AddMaleFaceData(v)
end
for i, v in ipairs(FemaleFaces) do
	SPNCC_Data.AddFemaleFaceData(v)
end
