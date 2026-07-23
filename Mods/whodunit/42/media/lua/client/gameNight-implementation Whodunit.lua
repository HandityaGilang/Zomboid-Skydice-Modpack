local applyItemDetails = require("gameNight-applyItemDetails.lua")
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceHandler = applyItemDetails.gamePieceHandler



local card = {
    "mrGreen", "msWhite", "msScarlet", "colMustard", "profPlum", "mrsPeacock",
    "Candlestick", "Knife", "Rope", "Leadpipe", "Pistol", "Wrench",
    "Ballroom", "Billiard Room", "Dining Room", "Greenhouse", "Hall", "Kitchen", "Library", "Lounge", "Study"
}

local cardProper = {
    ["mrGreen"] = "Mr. Green",
    ["msWhite"] = "Ms. White",
    ["msScarlet"] = "Ms. Scarlet",
    ["colMustard"] = "Col. Mustard",
    ["profPlum"] = "Prof. Plum",
    ["mrsPeacock"] = "Mrs. Peacock",
    ["Candlestick"] = "Candlestick",
    ["Knife"] = "Knife",
    ["Rope"] = "Rope",
    ["Leadpipe"] = "Leadpipe",
    ["Pistol"] = "Pistol",
    ["Wrench"] = "Wrench",
    ["Ballroom"] = "Ballroom",
    ["Billiard Room"] = "Billiard Room",
    ["Dining Room"] = "Dining Room",
    ["Greenhouse"] = "Greenhouse",
    ["Hall"] = "Hall",
    ["Kitchen"] = "Kitchen",
    ["Library"] = "Library",
    ["Lounge"] = "Lounge",
    ["Study"] = "Study"
}

deckActionHandler.addDeck("WhodunitCards", card, cardProper)
gamePieceHandler.registerSpecial("Base.WhodunitCards", { actions = { examine=true }, examineScale = 1, textureSize = {100,140} })

gamePieceHandler.registerSpecial("Base.WhodunitPlum", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitWhite", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitScarlet", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitPeacock", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitGreen", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitMustard", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitCandlestick", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitKnife", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitRope", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitPistol", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitWrench", { noRotate=true, })
gamePieceHandler.registerSpecial("Base.WhodunitLeadpipe", { noRotate=true, })

gamePieceHandler.registerSpecial("Base.WhodunitBoard", { category = "GameBoard", textureSize = {852,852}, actions = { lock=true }, })