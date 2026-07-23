local applyItemDetails = require("gameNight-applyItemDetails.lua")
--local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceHandler = applyItemDetails.gamePieceHandler

-- Register special properties for each item using custom textures
gamePieceHandler.registerSpecial("Base.BattleShip_GameStand", { noRotate = true, actions = { lock=true }, category = "GameBoard", textureSize = {649,870},})
gamePieceHandler.registerSpecial("Base.BattleShip_Peg_Red", { noRotate = true, })
gamePieceHandler.registerSpecial("Base.BattleShip_Peg_White", { noRotate = true, })
gamePieceHandler.registerSpecial("Base.BattleShip_Ship_Battleship", { actions = { turnShip=true }, })
gamePieceHandler.registerSpecial("Base.BattleShip_Ship_Carrier", { actions = { turnShip=true }, })
gamePieceHandler.registerSpecial("Base.BattleShip_Ship_Destroyer", { actions = { turnShip=true }, })
gamePieceHandler.registerSpecial("Base.BattleShip_Ship_Submarine", { actions = { turnShip=true }, })
gamePieceHandler.registerSpecial("Base.BattleShip_Ship_PatrolBoat", { actions = { turnShip=true }, })

function gamePieceHandler.turnShip(gamePiece, player)
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

    gamePieceHandler.playSound(gamePiece, player)
    gamePieceHandler.pickupAndPlaceGamePiece(player, gamePiece, {gamePieceHandler.setModDataValue, gamePiece, "gameNight_rotation", state})
end