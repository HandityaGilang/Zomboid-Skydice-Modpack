---First require this so that these modules can be called on as needed.
local applyItemDetails = require "gameNight - applyItemDetails"
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler

--- Card Table
local scrabbleTiles = {}
scrabbleTiles.tiles = {}
scrabbleTiles.one = {"J","K","Q","X","Z"}
scrabbleTiles.two = {"B","Blank","C","F","H","M","P","V","W","Y"}
scrabbleTiles.three = {"G"}
scrabbleTiles.four = {"D","L","S","U"}
scrabbleTiles.six = {"N","R","T"}
scrabbleTiles.eight = {"O"}
scrabbleTiles.nine = {"A","I"}
scrabbleTiles.twelve = {"E"}

for _, t in pairs(scrabbleTiles.one) do
	table.insert(scrabbleTiles.tiles, t)
end

for i=1, 2 do
	for _, t in pairs(scrabbleTiles.two) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

for i=1, 3 do
	for _, t in pairs(scrabbleTiles.three) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

for i=1, 4 do
	for _, t in pairs(scrabbleTiles.four) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

for i=1, 6 do
	for _, t in pairs(scrabbleTiles.six) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

for i=1, 8 do
for _, t in pairs(scrabbleTiles.eight) do
	table.insert(scrabbleTiles.tiles, t)
end
end

for i=1, 9 do
	for _, t in pairs(scrabbleTiles.nine) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

for i=1, 12 do
	for _, t in pairs(scrabbleTiles.twelve) do
		table.insert(scrabbleTiles.tiles, t)
	end
end

table.sort(scrabbleTiles.tiles)

deckActionHandler.addDeck("ScrabbleTiles", scrabbleTiles.tiles)
gamePieceAndBoardHandler.registerTypes({"Base.ScrabbleBoard"})

gamePieceAndBoardHandler.registerSpecial(
	"Base.ScrabbleBoard",{ category = "GameBoard", textureSize = {800,800}, actions = { lock=true } },
	"Base.ScrabbleTiles",{ alternateStackRendering = { func="DrawTextureCardFace", moveSound = "pieceMove", depth = 5 } }
	)
	