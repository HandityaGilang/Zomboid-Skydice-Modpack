CL = CL or {}
--table of tile objects that are actively tracked
CL.ClothesLinesInSquare = {}
--table of tiles that i want to modify
CL.textureNames = {
    ["appliances_laundry_01_26"] = true,
    ["appliances_laundry_01_27"] = true,
    ["appliances_laundry_01_28"] = true,
    ["appliances_laundry_01_29"] = true,
    ["appliances_laundry_01_30"] = true,
    ["appliances_laundry_01_31"] = true,
    ["clothesHorse_0"] = true,
    ["clothesHorse_2"] = true
}
--sets item wetness, called in everytenminutes
function CL.updateItems(item,container,cell,wetness)
    if wetness > 100 then wetness = 100 end
    item:setWetness(wetness)
end


function CL.loadGridsquare(square) --makes table of all clothesline within the loaded gridsquare
    if square:getObjects() then                 
        local objects = square:getObjects();
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i);
            local textureName = obj:getTextureName();
            if textureName and CL.textureNames[textureName] then
                local itemContainer = obj:getItemContainer()
                itemContainer:setOnlyAcceptCategory("Clothing")
                CL.ClothesLinesInSquare[obj] = true;
                if obj:getSquare():getRoom() then       
                    obj:getModData().isIndoors = true; -- adds moddata for time tracking purposes
                else    obj:getModData().isIndoors = nil;
                end
                obj:transmitModData()
            end
        end
        
    end
end

function CL.OnObjectAdded(object) --add new objects to clothesline table when they are placed
    local textureName = object:getTextureName();
    if textureName and CL.textureNames[textureName] then
        CL.ClothesLinesInSquare[object] = true;
        local itemContainer = object:getItemContainer()
        itemContainer:setOnlyAcceptCategory("Clothing")
       -- CL.ToBeEmptied[object] = true
        if object:getSquare():getRoom() then
            object:getModData().isIndoors = true;
        else    object:getModData().isIndoors = nil;
        end
        CL.UpdateSprite()
        object:transmitModData()
    end
end



Events.LoadGridsquare.Add(CL.loadGridsquare)
Events.OnObjectAdded.Add(CL.OnObjectAdded)
return CL