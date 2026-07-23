require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["Whodunit_Box"] = {}

gameNightDistro.gameNightBoxes["Whodunit_Box"] = {
    rolls = 1,
    items = {
        "WhodunitCards", 9999,
        "WhodunitBoard", 9999,

        "Dice", 9999, "Dice", 9999,

        "Base.WhodunitPlum", 9999, "Base.WhodunitWhite", 9999,
        "Base.WhodunitScarlet", 9999, "Base.WhodunitPeacock", 9999,
        "Base.WhodunitGreen", 9999, "Base.WhodunitMustard", 9999,

        "Base.WhodunitCandlestick", 9999, "Base.WhodunitKnife", 9999,
        "Base.WhodunitRope", 9999, "Base.WhodunitPistol", 9999,
        "Base.WhodunitWrench", 9999, "Base.WhodunitLeadpipe", 9999,
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}

