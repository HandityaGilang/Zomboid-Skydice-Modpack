--- For anyone looking to make a sub-mod check out the original gameNight mod's files:
--- ! SEE: `gameNight - implementUno` or  for a simpler example on adding decks.
--- CATAN includes 'game pieces' rather than *just* cards - scroll to the bottom for more info on those.
--- MONOPOLY includes 'alternative' names/icons for cards that will either have the same name or look the same but operate differently.

local gamePieceAndBoardHandler = require "gameNight - gamePieceAndBoardHandler"

local pieces = {}

local setSize = 6 --- sets are unique pairs of 0 to 6
---parsing through combinations calling registerSpecial
for i=setSize, 0, -1 do
    for ii=setSize, 0, -1 do
        local dominoID = "Base.Domino_"..ii.."_"..i

        table.insert(pieces, dominoID)

        gamePieceAndBoardHandler.registerSpecial(dominoID, {
            actions = { flipPiece=true, turnDomino=true },
            altState="Domino_Flipped", shiftAction = "flipPiece",
            alternateStackRendering = { func="DrawTextureCardFace", depth=6, rgb = {0.98, 0.88, 0.88} }
        })
    end
    setSize=setSize-1
end

gamePieceAndBoardHandler.registerTypes(pieces)


---Define new function under `gamePieceAndBoardHandler`
function gamePieceAndBoardHandler.turnDomino(gamePiece, player)
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