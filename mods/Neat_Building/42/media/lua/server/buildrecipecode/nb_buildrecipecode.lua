NB_BuildRecipeCode = NB_BuildRecipeCode or {}
NB_BuildRecipeCode.PartFloors = {}
NB_BuildRecipeCode.Floors = {}
NB_BuildRecipeCode.WindowWall = {}
NB_BuildRecipeCode.BigGate = {}
NB_BuildRecipeCode.NewWall = {}

function NB_BuildRecipeCode.PartFloors.OnCreate(params)
    local thumpable = params.thumpable
	local square = thumpable:getSquare()
	local objects = square:getObjects()

	-- remove removable objects
	local rug = nil
	for i=objects:size()-1, 0, -1 do
		local object = objects:get(i)
		if object and object ~= thumpable then
			local objProps = object:getProperties()

			local shouldRemove = objProps and (object:getProperties():Is(IsoFlagType.canBeRemoved)
			or object:getProperties():Is(IsoFlagType.noStart)
			-- not to clear solidfloor
			or (object:getProperties():Is(IsoFlagType.vegitation) and object:getType() ~= IsoObjectType.tree) and not object:getProperties():Is(IsoFlagType.solidfloor)
			or object:getProperties():Is(IsoFlagType.taintedWater))
			shouldRemove = shouldRemove
			or (object:getTextureName() ~= nil and (string.contains(object:getTextureName(), "blends_grassoverlays")))

			if object:getTextureName() ~= nil and string.contains(object:getTextureName(), "floors_rugs") then
				rug = object
				shouldRemove = false
			end

			if shouldRemove then
				square:transmitRemoveItemFromSquare(object)
				square:RemoveTileObject(object)
			end
		end
	end

	if rug ~= nil then
		-- ensure floor under rug
		local rugIndex = objects:indexOf(rug)
		local floorIndex = objects:indexOf(thumpable)
		if rugIndex < floorIndex then
			-- swap position
			objects:set(rugIndex, thumpable)
			objects:set(floorIndex, rug)
		end
	end

	square:EnsureSurroundNotNull()
	square:RecalcProperties()

	DesignationZoneAnimal.addNewRoof(square:getX(), square:getY(), square:getZ())
	square:getCell():checkHaveRoof(square:getX(), square:getY())

	-- ensure square exists below, connect and recalc
	for z = square:getZ()-1, 0, -1 do
		local below = getCell():getGridSquare(square:getX(), square:getY(), z)
		if below == nil then
			below = IsoGridSquare.getNew(getCell(), nil, square:getX(), square:getY(), z)
			getCell():ConnectNewSquare(below, false)
		end
		below:EnsureSurroundNotNull()
		below:RecalcAllWithNeighbours(true)
	end

	-- clear water/erosion
	square:disableErosion()
	local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
	sendServerCommand('erosion', 'disableForSquare', args)

	-- clear cached visibility/lights/flag square as dirty
	invalidateLighting()
	square:setSquareChanged()
	thumpable:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_ADD)
end

function NB_BuildRecipeCode.Floors.OnCreate(params)
    -- only change it to remove floor overlay
    local thumpable = params.thumpable;
	local square = thumpable:getSquare();
	local objects = square:getObjects();

	-- remove removable objects
    local rug = nil;
    for i=objects:size()-1, 0, -1 do
        local object = objects:get(i);
        if object and object ~= thumpable then
            local objProps = object:getProperties();

            local shouldRemove = objProps and (object:getProperties():Is(IsoFlagType.canBeRemoved) 
            or object:getProperties():Is(IsoFlagType.solidfloor) 
            or object:getProperties():Is(IsoFlagType.noStart) 
            or (object:getProperties():Is(IsoFlagType.vegitation) and object:getType() ~= IsoObjectType.tree) 
            or object:getProperties():Is(IsoFlagType.taintedWater)
            or object:getProperties():Is(IsoFlagType.FloorOverlay))
            
            shouldRemove = shouldRemove 
            or (object:getTextureName() ~= nil and (string.contains(object:getTextureName(), "blends_grassoverlays")))

            if object:getTextureName() ~= nil and string.contains(object:getTextureName(), "floors_rugs") then
                rug = object;
                shouldRemove = false;
            end

            if shouldRemove then
                square:transmitRemoveItemFromSquare(object)
                square:RemoveTileObject(object);
            end
        end
    end

	if rug ~= nil then
		-- ensure floor under rug
		local rugIndex = objects:indexOf(rug);
		local floorIndex = objects:indexOf(thumpable);
		if rugIndex < floorIndex then
			-- swap position
			objects:set(rugIndex, thumpable);
			objects:set(floorIndex, rug);
		end
	end

	square:EnsureSurroundNotNull();
	square:RecalcProperties();

	DesignationZoneAnimal.addNewRoof(square:getX(), square:getY(), square:getZ());
	square:getCell():checkHaveRoof(square:getX(), square:getY());

	-- ensure square exists below, connect and recalc
	for z = square:getZ()-1, 0, -1 do
		local below = getCell():getGridSquare(square:getX(), square:getY(), z);
		if below == nil then
			below = IsoGridSquare.getNew(getCell(), nil, square:getX(), square:getY(), z);
			getCell():ConnectNewSquare(below, false);
		end
		below:EnsureSurroundNotNull();
		below:RecalcAllWithNeighbours(true);
	end

	-- clear water/erosion
	square:clearWater();
	square:disableErosion();
	local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
	sendServerCommand('erosion', 'disableForSquare', args)

	-- clear cached visibility/lights/flag square as dirty
	invalidateLighting();
	square:setSquareChanged();
	thumpable:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_ADD);
end


function NB_BuildRecipeCode.BigGate.OnCreate(params)
    local thumpable = params.thumpable
    local garageDoor = IsoDoor.new(getCell(), thumpable:getSquare(), thumpable:getSprite(), thumpable:getNorth())

    garageDoor:setName(thumpable:getName())
    garageDoor:setModData(copyTable(thumpable:getModData()))
    garageDoor:setKeyId(thumpable:getKeyId())
    garageDoor:setIsLocked(false)
    garageDoor:setLockedByKey(false)
    garageDoor:setHealth(thumpable:getHealth())

    thumpable:getSquare():AddSpecialObject(garageDoor)

    thumpable:getSquare():transmitRemoveItemFromSquare(thumpable)
end

function NB_BuildRecipeCode.WindowWall.OnCreate(params)
    local thumpable = params.thumpable
    local window = IsoWindow.new(getCell(), thumpable:getSquare(), thumpable:getSprite(), thumpable:getNorth())
	-- window:setIsLocked(false)
    
    thumpable:getSquare():AddSpecialObject(window)
	-- remove WindowFrame
    thumpable:getSquare():transmitRemoveItemFromSquare(thumpable)

	--TODO:Corner miss
    --not sure how to make it trans and keep the window without IsoWindow
end

function NB_BuildRecipeCode.NewWall.OnCreate(params)
    -- [Note]It only deal with the corner for now,and only replace it
    local thumpable = params.thumpable
    local spriteConfig = thumpable:getSpriteConfig()
    local cornerSprite = spriteConfig:getObjectInfo():getScript():getCornerSprite()
    if not cornerSprite then return end
    
    local square = thumpable:getSquare()
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local north = thumpable:getNorth()
    
    -- Get other face sprite
    local sameSuiteSprites = {}
    local objectInfo = spriteConfig:getObjectInfo()
    for faceId = 0, 1 do  -- only work for faceW faceN
        local masterTileInfo = objectInfo:getFace(faceId):getMasterTileInfo()
        if masterTileInfo and masterTileInfo:getSpriteName() then
            sameSuiteSprites[masterTileInfo:getSpriteName()] = true
        end
    end
    
    -- Get Corner
    local adjX, adjY, cornerX, cornerY = x + 1, y - 1, x + 1, y
    if not north then
        adjX, adjY, cornerX, cornerY = x - 1, y + 1, x, y + 1
    end

    local adjSquare = getCell():getGridSquare(adjX, adjY, z)
    if not adjSquare then return end

    -- find and replace corner,the corner must be WallSE
    for i = 0, adjSquare:getSpecialObjects():size() - 1 do
        local item = adjSquare:getSpecialObjects():get(i)
        if instanceof(item, "IsoThumpable") and item:getNorth() ~= north and sameSuiteSprites[item:getSprite():getName()] then
            local cornerSquare = getCell():getGridSquare(cornerX, cornerY, z)
            if cornerSquare then
                for j = cornerSquare:getSpecialObjects():size() - 1, 0, -1 do
                    local object = cornerSquare:getSpecialObjects():get(j)
                    if object and object:getSprite() and object:getSprite():getProperties():Is(IsoFlagType.WallSE) then
                        
                        local newCorner = IsoThumpable.new(getCell(), cornerSquare, cornerSprite, false, nil)
                        newCorner:setCorner(true)
                        newCorner:setCanBarricade(false)
                        
                        local replacedIndex = cornerSquare:transmitRemoveItemFromSquare(object)
                        cornerSquare:AddSpecialObject(newCorner, replacedIndex)
                        cornerSquare:RecalcAllWithNeighbours(true)
                        newCorner:transmitCompleteItemToClients()
                        return
                    end
                end
            end
            return
        end
    end
end