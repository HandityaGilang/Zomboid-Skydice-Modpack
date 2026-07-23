local applyItemDetails = require "gameNight - applyItemDetails"
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler



local card = {
    "mrGreen", "msWhite", "msScarlet", "colMustard", "profPlum", "mrsPeacock",
    "Candlestick", "Knife", "Rope", "Leadpipe", "Pistol", "Wrench",
    "Ballroom", "Billiard Room", "Dining Room", "Greenhouse", "Hall", "Kitchen", "Library", "Lounge", "Study"
}

local cardProper = {
    "Mr. Green", "Ms. White", "Ms. Scarlet", "Col. Mustard", "Prof. Plum", "Mrs. Peacock",
    "Candlestick", "Knife", "Rope", "Leadpipe", "Pistol", "Wrench",
    "Ballroom", "Billiard Room", "Dining Room", "Greenhouse", "Hall", "Kitchen", "Library", "Lounge", "Study"
}

deckActionHandler.addDeck("WhodunitCards", card, cardProper)
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitCards", { actions = { examine=true }, examineScale = 1, textureSize = {100,140} })



gamePieceAndBoardHandler.registerTypes({
    "Base.WhodunitPlum", "Base.WhodunitWhite", "Base.WhodunitScarlet", "Base.WhodunitPeacock", "Base.WhodunitGreen", "Base.WhodunitMustard",
    "Base.WhodunitCandlestick", "Base.WhodunitKnife", "Base.WhodunitRope", "Base.WhodunitPistol","Base.WhodunitWrench", "Base.WhodunitLeadpipe",
    "Base.WhodunitBoard",
})

gamePieceAndBoardHandler.registerSpecial("Base.WhodunitPlum", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitWhite", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitScarlet", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitPeacock", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitGreen", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitMustard", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitCandlestick", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitKnife", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitRope", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitPistol", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitWrench", { noRotate=true, })
gamePieceAndBoardHandler.registerSpecial("Base.WhodunitLeadpipe", { noRotate=true, })

gamePieceAndBoardHandler.registerSpecial("Base.WhodunitBoard", { category = "GameBoard", textureSize = {852,852}, actions = { lock=true }, })