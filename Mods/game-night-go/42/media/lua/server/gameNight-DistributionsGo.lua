require "Items/SuburbsDistributions"

local gameNightDistro = require("gameNight-Distributions.lua")
gameNightDistro.proceduralDistGameNight.itemsToAdd["GoBoard"] = {}
gameNightDistro.gameNightBoxes["GoBoard"] = { GoStonesBlack = 1, GoStonesWhite = 1, }