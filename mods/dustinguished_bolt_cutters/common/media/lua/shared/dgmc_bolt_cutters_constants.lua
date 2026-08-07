-- we can send indices to the server instead of strings
---@enum AnimIndices
local animIndices = 
{
	lowAnimIndex = 1,
	midAnimIndex = 2,
	highAnimIndex = 3
}

---@enum StrengthIndices
local strengthIndices =
{
	easyIndex = 1,
	mediumIndex = 2,
	hardIndex = 3
}

---@enum ResourceIndices
local resourceIndices =
{
	wire = 1,
	steelBarFull = 2,
	steelBarHalf = 3,
	ironBarFull = 4,
	ironBarHalf = 5
}

local constants =
{
	module = "DGMC_Bolt_Cutters",

	commands =
	{
		garage = "D",
		gate = "G",
		fence = "F",
		shutter = "S"
	},

	sandbox = 
	{
		allowGarageDoors = "Allow_Garage_Doors",
		allowFenceGates = "Allow_Fence_Gates",
		allowFences = "Allow_Fences",
		fenceWireChance = "Fence_Wire_Chance",
		allowShutters = "Allow_Shutters",
		easyStrengthReq = "Easy_Strength_Req",
		mediumStrengthReq = "Medium_Strength_Req",
		hardStrengthReq = "Hard_Strength_Req",
		baseDuration = "Base_Duration",
		baseMuscleStrain = "Base_Muscle_Strain",
		debugLogging = "Debug_Logging",
	},

	anims = 
	{
		"BlowTorchFloor",
		"BlowTorchMid",
		"BlowTorch"
	},

	resources = 
	{
		"Base.Wire",
		"Base.SteelBar",
		"Base.SteelBarHalf",
		"Base.IronBar",
		"Base.IronBarHalf"
	},

	animIndices = animIndices,
	strengthIndices = strengthIndices,
	resourceIndices = resourceIndices
}

return constants