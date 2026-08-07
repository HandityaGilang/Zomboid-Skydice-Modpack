CL = CL or {}
CL.ClothesLineSprite = {}
-- loading sprite names into tables. more complex system possibly planned: all sprites made into single ones with chance of which side, coloring and visual type applied from itemdata
--appliances_laundry_01_26,27,30 face south/north ; appliances_laundry_01_28,29,31 face east/west ; 26,27,28,29 are end pieces, only get 1 clothing ; 30,31 are center pieces , they get 2 pieces
for i=26,31 do
    CL.ClothesLineSprite["appliances_laundry_01_" .. i] = {}
end
--create a table for the 2 clothing sprites, only added to middle pieces
CL.ClothesLineSprite["appliances_laundry_01_30"].double = {}
CL.ClothesLineSprite["appliances_laundry_01_31"].double = {}
for i=26,32,1 do
    table.insert(CL.ClothesLineSprite,"appliances_laundry_01_" .. i)
end
for i=0,7 do --single south facing clothing pieces that don't overlap on 26
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_26"],"clothingLineTiles_" .. i)
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_30"],"clothingLineTiles_" .. i)
end
for i=8,15 do --single south facing clothing pieces that only fit on 27
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_27"],"clothingLineTiles_" .. i)
end
for i=16,23 do--single east facing clothing pieces that only fit on 28
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_28"],"clothingLineTiles_" .. i)

end
for i=24,31 do --single east facing clothing pieces that don't overlap on 29
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_29"],"clothingLineTiles_" .. i)
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_31"],"clothingLineTiles_" .. i)
end
for i=32,39 do --double south facing sprites for center line 30
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_30"].double,"clothingLineTiles_" .. i)
end
for i=40,47 do --double east facing sprites for center line 31
    table.insert(CL.ClothesLineSprite["appliances_laundry_01_31"].double,"clothingLineTiles_" .. i)
end
--looks through table of clothesline objects and updates their sprite based on container fullness
function CL.UpdateSprite()
    if CL.ClothesLinesInSquare then
        for obj in pairs(CL.ClothesLinesInSquare)do
            if obj:getSquare() ~= nil and obj:getOverlaySprite() == nil then
                
                local spriteName = CL.RandomSprite(obj) 
                obj:setOverlaySprite(spriteName,true)
            end
            if obj:getOverlaySprite() ~= nil and obj:getItemContainer() ~= nil and obj:getItemContainer():getItems():size() == 0 then
                obj:setOverlaySprite(nil)
            end
        end
    end
end
--picks a sprite from CL.ClothesLineSprite, based on container type/fullness then does a roll from the right list
function CL.RandomSprite(obj)
    if obj:getItemContainer() ~= nil then 
        local container = obj:getItemContainer():getItems()
        local amount = container:size()
        local spritename = obj:getTextureName()
        local list = nil
        if amount > 0 then
            for line in pairs(CL.ClothesLineSprite)do
                if spritename == line then
                    if amount > 1 then
                        list = CL.ClothesLineSprite[line].double
                    else list = CL.ClothesLineSprite[line]

                    end
                end
            end
            if list ~= nil then
                local roll = ZombRand(1,#list)
                if list.double then roll = roll-1 end
                return list[roll]
            end
        end
    end
    return nil
    
end
 
--adds the sprite overlay update to check ever ingame minute
 Events.EveryOneMinute.Add(CL.UpdateSprite)

 return CL