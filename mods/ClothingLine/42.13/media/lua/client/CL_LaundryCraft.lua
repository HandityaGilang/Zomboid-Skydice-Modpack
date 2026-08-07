
--all code for placing/removing clotheslines objects. Context code is located in CL_CraftContext

CL = CL or {}

CL.craftTextureNames = {
    CL_LaundryCraft_0 = "CL_LaundryCraft_1",
    CL_LaundryCraft_1 = "CL_LaundryCraft_0",
    CL_LaundryCraft_2 = "CL_LaundryCraft_3",
    CL_LaundryCraft_3 = "CL_LaundryCraft_2",

}
CL.craftSwapNames = {
    CL_LaundryCraft_0 = "appliances_laundry_01_26",
    CL_LaundryCraft_1 = "appliances_laundry_01_27",
    CL_LaundryCraft_2 = "appliances_laundry_01_28",
    CL_LaundryCraft_3 = "appliances_laundry_01_29",
}
CL.reverseCraftSwapNames = {
    ["appliances_laundry_01_26"] = "CL_LaundryCraft_0",
    ["appliances_laundry_01_27"] = "CL_LaundryCraft_1",
    ["appliances_laundry_01_28"] = "CL_LaundryCraft_2",
    ["appliances_laundry_01_29"] = "CL_LaundryCraft_3",
}

CL.wireNames = {
["appliances_laundry_01_30"] = true,
["appliances_laundry_01_31"] = true,
}
local nsTex = {
    appliances_laundry_01_28 = "CL_LaundryCraft_2",
    appliances_laundry_01_29 = "CL_LaundryCraft_3",
    appliances_laundry_01_31 = "wire",
    CL_LaundryCraft_2 = "appliances_laundry_01_28",
    CL_LaundryCraft_3 = "appliances_laundry_01_29",

}
local weTex = {
    appliances_laundry_01_26 = "CL_LaundryCraft_0",
    appliances_laundry_01_27 = "CL_LaundryCraft_1",
    appliances_laundry_01_30 = "wire",
    CL_LaundryCraft_0 = "appliances_laundry_01_26",
    CL_LaundryCraft_1 = "appliances_laundry_01_27",

}

--logic for searching for clothesline objects.
--matches an object sprite to its direction N/S or W/E then searches them in a 24 tile length
--it makes a table of objects and empty squares then makes a "grid" out of them for placement returned as a table
local SearchAllDirectionsForObjects = function(object)
    CLDebug("SearchAllDirections: Run")
   
local texture = object:getTextureName()
local tofind = CL.craftTextureNames[texture]
local square = object:getSquare()
local grid = {} --table of objects and eventually empty squares between them
local x = square:getX() --assemble coordinates to get adjacent square
local y = square:getY()
local z = square:getZ()
local newSqu --will be adjacent square
local squares = {} --tabvle of empty squares
local first,last = -100,100 --numbers to track index for removal
local objCount = 0 --number to track how many objects are found, table length was unreliable
    if weTex[texture] or nsTex[texture] then --check if item matches the directions tables at all
        CLDebug("SearchAllDirections: texture found, searching directions")
        for i = -12, 12 do
            if weTex[texture] then  --if matches then seraches east and west
               -- CLDebug("SearchAllDirections: searching W/E")
                newSqu = getSquare(x+i,y,z)
                if newSqu then
                   -- CLDebug("SearchAllDirections: searching W/E, square found")
                    local objs = newSqu:getObjects()
                    for n = 0 ,objs:size()-1 do
                        local obj = objs:get(n)
                        local tex = obj:getTextureName()
                        if weTex[tex] then
                          --  if tofind and not string.find(tofind,tex) then break end
                            CLDebug("SearchAllDirections: searching W/E, object found, adding to table...")
                            if first == -100 then first = i
                            else last = i
                            end
                          --  CLDebug("SearchAllDirections: "..tex.." found, adding to grid table...")
                            objCount = objCount+1
                            grid[i] = obj
                            if objCount >= 2 then break end
                        elseif first > -100 and tex and not string.find(tex,"wall") and not nsTex[tex] then  squares[i] = newSqu--CLDebug("SearchAllDirections: empty square found, adding to squares table...")
                        end
                    end
                end
            elseif nsTex[texture] then --if matches then searches north and south
                CLDebug("SearchAllDirections: searching N/S")
                newSqu = getSquare(x,y+i,z)
                if newSqu then
                    local objs = newSqu:getObjects()
                    for n = 0 ,objs:size()-1 do
                        local obj = objs:get(n)
                        local tex = obj:getTextureName()
                        if nsTex[tex] then
                          --  if tofind and not string.find(tofind,tex) then break end
                            if first == -100 then first = i
                            else last = i
                            end
                           -- CLDebug("SearchAllDirections: "..tex.." found, adding to grid table...")
                            objCount = objCount+1
                            grid[i] = obj
                            if objCount >= 2 then break end
                        elseif first > -100 and tex and not string.find(tex,"wall") and not weTex[tex] then  squares[i] = newSqu
                        end
                    end
                end
            
            end
        end
    else CLDebug("SearchAllDirections: texture match not found returning nil...") return nil
    end
--object counter made because table amount unreliable
if objCount < 2 then CLDebug("SearchAllDirections:  not enough objects found to make line, returning nil...") return nil end

--comparing both of the tables and deleteting squares outside of the clothesline
    for i,squ in pairs(squares)do
        if i < first then squares[i] = nil
        elseif i > last then squares[i] = nil
        elseif squares[i] and not grid[i] then grid[i] = squ end
    end

    return grid

end
--removes the wires between to clotheslines requiring one of them as an input
        function CL.removewire(obj)
            local square = obj:getSquare()
            local player = getPlayer()
            local inventory = player:getInventory()

           local wirelist = SearchAllDirectionsForObjects(obj)
            if not  wirelist then 
                CLDebug("WiresNotFound in wirelist")
                return 
                end
           for _,tWire in pairs(wirelist)do
            if not instanceof(tWire,"IsoGridSquare") then
                local container = tWire:getItemContainer():getItems()
                local texture = tWire:getTextureName()
                local sq = tWire:getSquare()
                if CL.reverseCraftSwapNames[texture]then
                    CLDebug("Texture "..texture.. " swapped to ".. CL.reverseCraftSwapNames[texture])
                    tWire:setSpriteFromName(CL.reverseCraftSwapNames[texture])
                    if container:size() > 0 then
                        for i =0,container:size()-1 do
                            local item = container:get(i)
                        -- local rand = ZombRand(0,100)
                            sq:AddWorldInventoryItem(item,0,0,0)
                        end
                    end
                    tWire:clearAttachedAnimSprite()
                    tWire:removeAllContainers()
                    --tWire:transmitUpdatedSpriteToClients()
                elseif CL.wireNames[texture] then 
                    if container:size() > 0 then
                        for i =0,container:size()-1 do
                            local item = container:get(i)
                        --  local rand = ZombRand(0,100)
                            sq:AddWorldInventoryItem(item,0,0,0)
                        end
                    end
                    tWire:removeFromSquare()
                end
        
            end
            end
            
            local removal = #wirelist-1
            if removal > 0 then
                CLDebug("Wires Removed: " ..removal)
                end
                if removal > 10 then
                    inventory:AddItem("Base.Wire")
                    local wire = instanceItem("Base.Wire")
                    wire:setUses(removal - 10)
                    inventory:addItem(wire)
                else local wire = instanceItem("Base.Wire")
                    wire:setUses(removal)
                    inventory:addItem(wire)
                end
        end
        


        


--places wires and replaces tiles with a data set returned by CL.searchForClotheslinesArray that is two separate tables
        CL.setProps = function(data)
            local player = getPlayer()
            CLDebug("CL.setProps: run")
            local toBePlaced,toBechanged = data[1],data[2]
            local sprite
            local lastSquare
            local count = 0
            for _,obj in pairs(toBechanged)do
                if weTex[obj:getTextureName()] or nsTex[obj:getTextureName()] then
                    sprite = weTex[obj:getTextureName()] or nsTex[obj:getTextureName()]
                    obj:setSprite(getSprite(sprite))
                    obj:createContainersFromSpriteProperties()
                    obj:getContainer():setExplored(true)
                    CL.ClothesLinesInSquare[obj] = true
                    count = count +1
                    if string.find(sprite,"appliances_laundry_01_27") then 
                        lastSquare = getSquare(obj:getX()-1,obj:getY(),obj:getZ())
                    elseif string.find(sprite,"appliances_laundry_01_28") then
                        lastSquare = getSquare(obj:getX(),obj:getY()-1,obj:getZ())
                    end
                    CLDebug("CL.setProps: tile changed to wired tile")
                end
            end
            if sprite then
                local tbl
                if weTex[sprite] then tbl = weTex
                elseif nsTex[sprite] then tbl = nsTex end
                
                if tbl and sprite then

                    local removeWire = #toBePlaced-1
                    for i,sq in pairs(toBePlaced)do
                        if sq ~= lastSquare then
                            for name,val in pairs(tbl)do
                                if val == "wire" then
                                    local obj = IsoObject.getNew(sq, name, name, false)
                                    sq:AddTileObject(obj)
                                    CL.ClothesLinesInSquare[obj] = true
                                    obj:createContainersFromSpriteProperties()
                                    obj:getContainer():setExplored(true)
                                    CLDebug("CL.setProps: wires added to world")
                                    
                                   
                                    count = count +1
                                end
                            end
                        end
                    end
                    for i=0,count do
                        player:getInventory():getFirstTypeRecurse("Base.Wire"):UseAndSync()
                    end
                end
            end
        end


--searches for clotheslines, using SearchAllDirectionsForObjects and splitting the results into two separate tables
        CL.searchForClotheslinesArray = function(obj)
            CLDebug("searchForClotheslinesArray: Run")
          local grid = SearchAllDirectionsForObjects(obj)
          if not grid then return nil end
          local toBeadded = {}
          local pieces = {}
          for _,piece in pairs(grid)do
            if not instanceof(piece, "IsoGridSquare") and CL.craftSwapNames[piece:getTextureName()]then
                CLDebug("searchForClotheslinesArray: object found, adding to own table...")
                table.insert(pieces,piece)
                elseif instanceof(piece, "IsoGridSquare") then
                  --  CLDebug("searchForClotheslinesArray: square found, adding to own table...")
                    table.insert(toBeadded,piece)
            end
          end
          return {toBeadded,pieces}
        end
        --initial search to see if the context is on a clothesline
        CL.searchForClotheslines = function(table)
            CLDebug("searchForClotheslines: run")
            for _,i in pairs(table) do
                local obj = i
                local textureName = obj:getTextureName();
                if textureName and CL.craftTextureNames[textureName] then
                    CLDebug("searchForClotheslines: texture name match")
                    return obj
                end
            end
            return false
        end

