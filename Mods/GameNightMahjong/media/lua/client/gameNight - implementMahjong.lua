---First require this so that these modules can be called on as needed.
local applyItemDetails = require "gameNight - applyItemDetails"
local deckActionHandler = applyItemDetails.deckActionHandler
local gamePieceAndBoardHandler = applyItemDetails.gamePieceAndBoardHandler

--- Card Table
local mahjongTiles = {}
mahjongTiles.tiles = {}
mahjongTiles.suits = {"Bamboo", "Coin", "Character"}
mahjongTiles.values = {"1","2","3","4","5","6","7","8","9"}

for i=1, 4 do
	for _, s in pairs(mahjongTiles.suits) do -- for each suit
		for _, v in pairs(mahjongTiles.values) do -- for each value
			table.insert(mahjongTiles.tiles, s.." "..v) -- put suit and value together to match texture
		end
	end
end

mahjongTiles.specialTiles = {"Dragon Green", "Dragon Red", "Dragon White", "Wind East", "Wind West", "Wind North", "Wind South"}
mahjongTiles.seasonsFlowers = {"Season Spring", "Season Summer", "Season Autumn", "Season Winter", "Flower Plum", "Flower Orchid", "Flower Chrysanthemum", "Flower Bamboo"}


for i=1, 4 do
	for _, special in pairs(mahjongTiles.specialTiles) do
		table.insert(mahjongTiles.tiles, special)
	end
end

for _, season in pairs(mahjongTiles.seasonsFlowers) do
	table.insert(mahjongTiles.tiles, season)
end

deckActionHandler.addDeck("MahjongTiles", mahjongTiles.tiles)
gamePieceAndBoardHandler.registerSpecial("Base.MahjongTiles", 
	{ alternateStackRendering = {func="DrawTextureCardFace", rgb = { 0.0 , 0.0 , 1.0 } }, moveSound = "pieceMove", sideTexture = "sideTexture" }
	)

