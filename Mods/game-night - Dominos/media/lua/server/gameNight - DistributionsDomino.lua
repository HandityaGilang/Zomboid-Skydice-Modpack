require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["DominosBox"] = {}

gameNightDistro.gameNightBoxes["DominosBox"] = {
    rolls = 1,
    items = {
        "Domino_6_6", 9999,
        "Domino_5_6", 9999,
        "Domino_4_6", 9999,
        "Domino_3_6", 9999,
        "Domino_2_6", 9999,
        "Domino_1_6", 9999,
        "Domino_0_6", 9999,
        "Domino_5_5", 9999,
        "Domino_4_5", 9999,
        "Domino_3_5", 9999,
        "Domino_2_5", 9999,
        "Domino_1_5", 9999,
        "Domino_0_5", 9999,
        "Domino_4_4", 9999,
        "Domino_3_4", 9999,
        "Domino_2_4", 9999,
        "Domino_1_4", 9999,
        "Domino_0_4", 9999,
        "Domino_3_3", 9999,
        "Domino_2_3", 9999,
        "Domino_1_3", 9999,
        "Domino_0_3", 9999,
        "Domino_2_2", 9999,
        "Domino_1_2", 9999,
        "Domino_0_2", 9999,
        "Domino_1_1", 9999,
        "Domino_0_1", 9999,
        "Domino_0_0", 9999,
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}

