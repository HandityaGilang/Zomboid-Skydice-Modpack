require "Items/SuburbsDistributions"

local gameNightDistro = require("gameNight-Distributions.lua")

gameNightDistro.proceduralDistGameNight.itemsToAdd["Whodunit_Box"] = {}

gameNightDistro.gameNightBoxes["Whodunit_Box"] = {

    WhodunitCards = 1, WhodunitBoard = 1,

    Dice = 2,

    WhodunitPlum = 1, WhodunitWhite = 1,
    WhodunitScarlet = 1, WhodunitPeacock = 1,
    WhodunitGreen = 1, WhodunitMustard = 1,

    WhodunitCandlestick = 1, WhodunitKnife = 1,
    WhodunitRope = 1, WhodunitPistol = 1,
    WhodunitWrench = 1, WhodunitLeadpipe = 1,
}

