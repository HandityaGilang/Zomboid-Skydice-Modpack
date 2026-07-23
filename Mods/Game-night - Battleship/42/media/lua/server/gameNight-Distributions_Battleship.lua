require "Items/SuburbsDistributions"

local gameNightDistro = require("gameNight-Distributions.lua")

gameNightDistro.proceduralDistGameNight.itemsToAdd["BattleShip_Box"] = {}
gameNightDistro.gameNightBoxes["BattleShip_Box"] = {
    BattleShip_GameStand = 2,
    BattleShip_Ship_Battleship = 2, BattleShip_Ship_Carrier = 2, BattleShip_Ship_Destroyer = 2,
    BattleShip_Ship_Submarine = 2, BattleShip_Ship_PatrolBoat = 2,
    BattleShip_Peg_White = 168, BattleShip_Peg_Red = 84,
}


gameNightDistro.proceduralDistGameNight.itemsToAdd["BattleShip_GameStand"] = { chanceFactor = 0.0001,}