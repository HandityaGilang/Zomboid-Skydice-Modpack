require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["ScrabbleBox"] = {}

gameNightDistro.gameNightBoxes["ScrabbleBox"] = {
    rolls = 1,
    items = {
        "ScrabbleTiles", 9999,
		"ScrabbleBoard", 9999
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}