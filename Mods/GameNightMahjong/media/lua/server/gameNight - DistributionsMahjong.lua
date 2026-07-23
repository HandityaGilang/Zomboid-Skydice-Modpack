require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["MahjongBox"] = {}

gameNightDistro.gameNightBoxes["MahjongBox"] = {
    rolls = 1,
    items = {
        "MahjongTiles", 9999,
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}