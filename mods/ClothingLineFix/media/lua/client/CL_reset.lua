 CL = require "CL_Drying"
 CL.textureNames = CL.textureNames
        CL.clotheslineGrid = {}
        CL.resetClothesLineContext = function(player, context, worldobjects)
            local clothesline = nil 
            
            clothesline = CL.searchForClotheslines(worldobjects)
            if clothesline then
                local resetOption = context:addOption("Make this functional",clothesline,CL.resetProps)
                
            end   
        end
        CL.resetProps = function(obj)
            CL.findclotheslineTiles(obj)
            for o,_ in pairs(CL.clotheslineGrid) do
                o:createContainersFromSpriteProperties()
                o:transmitCompleteItemToClients()
                o:transmitCompleteItemToServer()
            end
            CL.clotheslineGrid = {}
            
            
            
        end

        CL.findclotheslineTiles = function(clothesline)
            
            --All of these functions search each tile in the given direction and stop when the desired object is not found

            local function findWest(gridSquare)
                local localFindWest = findWest
                local found = false
                local dir = gridSquare:getAdjacentSquare(IsoDirections.W)
                if CL.searchForClotheslinesArray(dir:getObjects()) then
                    localFindWest(dir)
                    found = true

                end
                return found
            end
            local function findNorth(gridSquare)
                local localFindNorth = findNorth
                local found = false
                local dir = gridSquare:getAdjacentSquare(IsoDirections.N)
                    if CL.searchForClotheslinesArray(dir:getObjects())  then
                        localFindNorth(dir)
                        found = true
                    end
                return found
            end
            local function findEast(gridSquare)
                local localFindEast = findEast
                local found = false
                local dir = gridSquare:getAdjacentSquare(IsoDirections.E)
                    if CL.searchForClotheslinesArray(dir:getObjects())  then
                        localFindEast(dir)
                        found = true
                    end
                return found
            end
            local function findSouth(gridSquare)
                local localFindSouth = findSouth
                local found = false
                local dir = gridSquare:getAdjacentSquare(IsoDirections.S)
                    if CL.searchForClotheslinesArray(dir:getObjects())  then
                        localFindSouth(dir)
                        found = true
                    end
                return found
            end
            --This is a combination of all of the directional functions
            local function findalldirections(gridSquare)
                if not findWest(gridSquare) or findEast(gridSquare) then
                    if not findNorth(gridSquare) or findSouth(gridSquare) then
                        return
                    end
                end
            end
            -- this is where we actually call to search all directions
            if clothesline then
                local gridSquare = clothesline:getSquare()
                if gridSquare then
                    findalldirections(gridSquare)
                end
            end

        end
        -- this searches my list of clotheslines and compares to the tile objects for a match this one is specifically made for the arrays returned by getobjects and returns a boolean
        CL.searchForClotheslinesArray = function(array)
                local found = false
                for i = 0, array:size() - 1 do
                   
                    local obj = array:get(i)
                    local textureName = obj:getTextureName();
                    if textureName and CL.textureNames[textureName] then
                        CL.clotheslineGrid[obj] = true;
                        found = true
                    end
                end
            return found
        end
        --this is the same as above but returns the actual object
        CL.searchForClotheslines = function(table)
            for _,i in pairs(table) do
                local obj = i
                local textureName = obj:getTextureName();
                if textureName and CL.textureNames[textureName] then
                    CL.clotheslineGrid[obj] = true;
                    return obj
                end
            end
            return false
        end



            --where the context option is added to the game
        Events.OnFillWorldObjectContextMenu.Add(CL.resetClothesLineContext)



