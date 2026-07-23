require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["GoBoard"] = {}

gameNightDistro.gameNightBoxes["GoBoard"] = {
    rolls = 1,
    items = {
        "GoStonesBlack", 9999,
        "GoStonesWhite", 9999,
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}