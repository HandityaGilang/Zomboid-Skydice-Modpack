require "Items/SuburbsDistributions"

local gameNightDistro = require "gameNight - Distributions"

gameNightDistro.proceduralDistGameNight.itemsToAdd["BattleShip_Box"] = {}
gameNightDistro.gameNightBoxes["BattleShip_Box"] = {
    rolls = 1,
    items = {
        "BattleShip_GameStand_Closed", 9999, "BattleShip_GameStand_Closed", 9999
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}


gameNightDistro.proceduralDistGameNight.itemsToAdd["BattleShip_GameStand_Open"] = { chanceFactor = 0.0001,}
gameNightDistro.gameNightBoxes["BattleShip_GameStand_Open"] = {
    rolls = 1,
    items = {
        "BattleShip_Ship_Battleship", 9999,
        "BattleShip_Ship_Carrier", 9999,
        "BattleShip_Ship_Destroyer", 9999,
        "BattleShip_Ship_Submarine", 9999,
        "BattleShip_Ship_PatrolBoat", 9999,
    },
    junk = { rolls = 1, items = {} }, fillRand = 0,
}

for i=1, 84 do
    table.insert(gameNightDistro.gameNightBoxes["BattleShip_GameStand_Open"].items,"BattleShip_Peg_White")
    table.insert(gameNightDistro.gameNightBoxes["BattleShip_GameStand_Open"].items,9999)
end

for i=1, 42 do
    table.insert(gameNightDistro.gameNightBoxes["BattleShip_GameStand_Open"].items,"BattleShip_Peg_Red")
    table.insert(gameNightDistro.gameNightBoxes["BattleShip_GameStand_Open"].items,9999)
end