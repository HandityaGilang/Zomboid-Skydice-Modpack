local applyItemDetails = require "gameNight - applyItemDetails"
--local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler

-- Register game pieces
gamePieceAndBoardHandler.registerTypes({
	"Base.BattleShip_GameStand_Open", "Base.BattleShip_Peg_Red", "Base.BattleShip_Peg_White",
    "Base.BattleShip_Ship_Battleship", "Base.BattleShip_Ship_Carrier", "Base.BattleShip_Ship_Destroyer",
    "Base.BattleShip_Ship_Submarine", "Base.BattleShip_Ship_PatrolBoat"
})

-- Register special properties for each item using custom textures
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_GameStand_Open", { noRotate = true, actions = { lock=true }, category = "GameBoard", textureSize = {649,870},})
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Peg_Red", { noRotate = true, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Peg_White", { noRotate = true, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Ship_Battleship", { actions = { turnShip=true }, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Ship_Carrier", { actions = { turnShip=true }, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Ship_Destroyer", { actions = { turnShip=true }, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Ship_Submarine", { actions = { turnShip=true }, })
gamePieceAndBoardHandler.registerSpecial("Base.BattleShip_Ship_PatrolBoat", { actions = { turnShip=true }, })

function gamePieceAndBoardHandler.turnShip(gamePiece, player)
    local current = gamePiece:getModData()["gameNight_rotation"] or 0

    local states = {[0]=90,[90]=180,[180]=270,[270]=0}
    local state = states[current]

    if not state then
        local closest = false
        for id,angle in pairs(states) do
            if (not closest) or (closest and math.abs(angle-current) < states[closest]) then
                closest = id
            end
        end
        state = states[closest]
    end

    gamePieceAndBoardHandler.playSound(gamePiece, player)
    gamePieceAndBoardHandler.pickupAndPlaceGamePiece(player, gamePiece, {gamePieceAndBoardHandler.setModDataValue, gamePiece, "gameNight_rotation", state})
end