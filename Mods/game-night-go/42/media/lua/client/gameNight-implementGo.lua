local applyItemDetails = require("gameNight-applyItemDetails.lua")
local gamePieceHandler = applyItemDetails.gamePieceHandler

gamePieceHandler.registerTypes({"Base.GoBoard","Base.GoStonesBlack","Base.GoStonesWhite"})

gamePieceHandler.registerSpecial("Base.GoBoard",
		{
			category = "GameBoard", textureSize = {740,800}, actions = { lock=true, flipPiece=true },
			alternateStackRendering = { func="DrawTextureCardFace", sideTexture="GoBoardSide", depth=12, rgb = {0.79, 0.66, 0.15}},
			altState="GoBoard_Back", shiftAction = "flipPiece",
		}
)

gamePieceHandler.registerSpecial("Base.GoStonesBlack",
		{
			weight = 0.003, shiftAction = "takeOneOffStack", canStack = 180, noRotate=true,
			alternateStackRendering = {func="DrawTextureRoundFace", sideTexture="Black_Stone_Texture", depth = 2, rgb = {0.2, 0.2, 0.2}},
		}
)

gamePieceHandler.registerSpecial("Base.GoStonesWhite",
		{
			weight = 0.003, shiftAction = "takeOneOffStack", canStack = 180, noRotate=true,
			alternateStackRendering = {func="DrawTextureRoundFace", sideTexture="White_Stone_Texture", depth = 2, rgb = {0.9, 0.9, 0.9}},
		}
)

	
	
	
