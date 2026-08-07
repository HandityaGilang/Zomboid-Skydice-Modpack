local Ladders = {
    idN = 26476542,
    idS = 26476543,
    idW = 26476544,
    idE = 26476545,
    idExitN = 26476546,
    idExitW = 26476547,
    climbSheetTopN = 'TopOfLadderN',
    climbSheetTopS = 'TopOfLadderS',
    climbSheetTopW = 'TopOfLadderW',
    climbSheetTopE = 'TopOfLadderE',
    exitN = 'LadderExitN',
    exitW = 'LadderExitW',
}

Ladders.topSprites = {
    [Ladders.climbSheetTopN] = true,
    [Ladders.climbSheetTopS] = true,
    [Ladders.climbSheetTopW] = true,
    [Ladders.climbSheetTopE] = true,
}

Ladders.wallByTop = {
    [IsoFlagType.climbSheetTopN] = { flag = IsoFlagType.WallN, dx = 0, dy = 0 },
    [IsoFlagType.climbSheetTopS] = { flag = IsoFlagType.WallN, dx = 0, dy = 1 },
    [IsoFlagType.climbSheetTopW] = { flag = IsoFlagType.WallW, dx = 0, dy = 0 },
    [IsoFlagType.climbSheetTopE] = { flag = IsoFlagType.WallW, dx = 1, dy = 0 },
}

Ladders.spriteByTop = {
    [IsoFlagType.climbSheetTopN] = Ladders.climbSheetTopN,
    [IsoFlagType.climbSheetTopS] = Ladders.climbSheetTopS,
    [IsoFlagType.climbSheetTopW] = Ladders.climbSheetTopW,
    [IsoFlagType.climbSheetTopE] = Ladders.climbSheetTopE,
}

Ladders.exitByTop = {
    [IsoFlagType.climbSheetTopS] = { name = Ladders.exitN, dx = 0, dy = 1 },
    [IsoFlagType.climbSheetTopE] = { name = Ladders.exitW, dx = 1, dy = 0 },
}

Ladders.topByClimbSheet = {
    [IsoFlagType.climbSheetN] = IsoFlagType.climbSheetTopN,
    [IsoFlagType.climbSheetS] = IsoFlagType.climbSheetTopS,
    [IsoFlagType.climbSheetW] = IsoFlagType.climbSheetTopW,
    [IsoFlagType.climbSheetE] = IsoFlagType.climbSheetTopE,
}

local exitNSet = { [Ladders.exitN] = true }
local exitWSet = { [Ladders.exitW] = true }

local function removeSprites(square, names)
    if not square then return end
    local objects = square:getObjects()
    for i = objects:size() - 1, 0, -1 do
        local object = objects:get(i)
        if names[object:getTextureName()] then
            square:transmitRemoveItemFromSquare(object)
        end
    end
end

function Ladders.hasWall(square, topFlag)
    local wall = Ladders.wallByTop[topFlag]
    local sq = getSquare(square:getX() + wall.dx, square:getY() + wall.dy, square:getZ())
    if not sq then
        return false
    end
    if sq:has(wall.flag) then
        return true
    end
    return sq:has(IsoFlagType.WallNW)
end

function Ladders.getTopOfLadder(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if Ladders.topSprites[object:getTextureName()] then
            return object
        end
    end
    return nil
end

function Ladders.removeTopOfLadder(square)
    if not square then return end
    removeSprites(square, Ladders.topSprites)
    removeSprites(getSquare(square:getX() + 1, square:getY(), square:getZ()), exitWSet)
    removeSprites(getSquare(square:getX(), square:getY() + 1, square:getZ()), exitNSet)
end

function Ladders.addTopOfLadder(square, topFlag)
    if not square then return nil end
    if Ladders.hasWall(square, topFlag) then
        Ladders.removeTopOfLadder(square)
        return nil
    end

    Ladders.removeTopOfLadder(square)
    local object = IsoObject.new(getCell(), square, Ladders.spriteByTop[topFlag])
    square:transmitAddObjectToSquare(object, -1)

    local exit = Ladders.exitByTop[topFlag]
    if exit then
        local exitSquare = getSquare(square:getX() + exit.dx, square:getY() + exit.dy, square:getZ())
        if exitSquare then
            local exitObject = IsoObject.new(getCell(), exitSquare, exit.name)
            exitSquare:transmitAddObjectToSquare(exitObject, -1)
        end
    end

    return object
end

function Ladders.makeLadderClimbable(square, directionFlag)
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local topFlag = Ladders.topByClimbSheet[directionFlag]
    local topSquare = square

    while true do
        z = z + 1
        local aboveSquare = getSquare(x, y, z)
        if not aboveSquare or aboveSquare:TreatAsSolidFloor() or aboveSquare:has('RoofGroup') then break end
        if aboveSquare:has(directionFlag) then
            Ladders.removeTopOfLadder(topSquare)
            topSquare = aboveSquare
        elseif not Ladders.hasWall(aboveSquare, topFlag) then
            Ladders.removeTopOfLadder(topSquare)
            topSquare = aboveSquare
            break
        else
            Ladders.removeTopOfLadder(aboveSquare)
            break
        end
    end

    local topObject = Ladders.addTopOfLadder(topSquare, topFlag)
    Ladders.chooseAnimVar(topSquare, topObject)
end

function Ladders.makeLadderClimbableFromTop(square)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ() - 1

    local belowSquare = getSquare(x, y, z)
    if belowSquare then
        Ladders.makeLadderClimbableFromBottom(getSquare(x - 1, y, z))
        Ladders.makeLadderClimbableFromBottom(getSquare(x + 1, y, z))
        Ladders.makeLadderClimbableFromBottom(getSquare(x, y - 1, z))
        Ladders.makeLadderClimbableFromBottom(getSquare(x, y + 1, z))
    end
end

function Ladders.makeLadderClimbableFromBottom(square)
    if not square then return end

    local props = square:getProperties()
    for directionFlag in pairs(Ladders.topByClimbSheet) do
        if props:has(directionFlag) then
            Ladders.makeLadderClimbable(square, directionFlag)
            return
        end
    end
end

function Ladders.chooseAnimVar(square, topObject)
    if not topObject then
        Ladders.player:clearVariable('ClimbLadder')
        return
    end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local sprite = objects:get(i):getTextureName()
        if Ladders.excludeAnimTiles[sprite] then
            Ladders.player:clearVariable('ClimbLadder')
            return
        end
    end

    Ladders.player:setVariable('ClimbLadder', true)
end

function Ladders.OnKeyPressed(key)
    if key == getCore():getKey('Interact') then
        local player = getPlayer()
        if not player or player:isDead() then return end
        if MainScreen.instance:isVisible() then return end

        Ladders.player = player

        local square = player:getSquare()
        Ladders.makeLadderClimbableFromTop(square)
        Ladders.makeLadderClimbableFromBottom(square)
    end
end

Ladders.ISMoveablesAction = {
    perform = ISMoveablesAction.perform,
}

function ISMoveablesAction:perform()
    Ladders.ISMoveablesAction.perform(self)

    if self.mode == 'pickup' then
        Ladders.removeTopOfLadder(getSquare(self.square:getX(), self.square:getY(), self.square:getZ() + 1))
    end
end

require 'TimedActions/ISDestroyStuffAction'
Ladders.ISDestroyStuffAction = {
    perform = ISDestroyStuffAction.perform,
}

function ISDestroyStuffAction:perform()
    if self.item:haveSheetRope() then
        Ladders.removeTopOfLadder(self.item:getSquare())
    end
    return Ladders.ISDestroyStuffAction.perform(self)
end

Ladders.northLadderTiles = {
    'location_sewer_01_33', 'industry_railroad_05_21', 'industry_railroad_05_37',
    'edit_ddd_RUS_decor_house_01_17', 'edit_ddd_RUS_decor_house_01_18',
    'edit_ddd_RUS_industry_crane_01_76', 'edit_ddd_RUS_industry_crane_01_77',
    'A1 Wall_49', 'A1 Wall_81', 'A1_CULT_37', 'aaa_RC_14', 'trelai_tiles_01_31',
    'trelai_tiles_01_39', 'industry_crane_rus_76', 'industry_crane_rus_77',
}

Ladders.southLadderTiles = {
    'location_sewer_01_49', 'industry_railroad_05_57', 'industry_railroad_05_59',
}

Ladders.westLadderTiles = {
    'industry_02_86', 'location_sewer_01_32', 'industry_railroad_05_20', 'industry_railroad_05_36',
    'walls_commercial_03_0',
    'edit_ddd_RUS_decor_house_01_16', 'edit_ddd_RUS_decor_house_01_19', 'edit_ddd_RUS_industry_crane_01_72',
    'edit_ddd_RUS_industry_crane_01_73', 'rus_industry_crane_ddd_01_24', 'rus_industry_crane_ddd_01_25',
    'A1 Wall_48', 'A1 Wall_80', 'A1_CULT_36', 'aaa_RC_6', 'trelai_tiles_01_30', 'trelai_tiles_01_38',
    'industry_crane_rus_72', 'industry_crane_rus_73',
}

Ladders.eastLadderTiles = {
    'location_sewer_01_48', 'industry_railroad_05_56', 'industry_railroad_05_58',
}

Ladders.WoodenLadderTiles = {
    'industry_railroad_05_56', 'industry_railroad_05_57',
}
Ladders.SteelLadderTiles = {
    'industry_railroad_05_58', 'industry_railroad_05_59',
}

for index = 1, 62 do
    local name = 'basement_objects_02_' .. index
    if index % 2 == 0 then
        Ladders.westLadderTiles[#Ladders.westLadderTiles + 1] = name
    else
        Ladders.northLadderTiles[#Ladders.northLadderTiles + 1] = name
    end
end

Ladders.holeTiles = {
    'floors_interior_carpet_01_24',
}

Ladders.poleTiles = {
    'recreational_sports_01_32', 'recreational_sports_01_33',
}

Ladders.excludeAnimTiles = {}
for _, name in ipairs(Ladders.poleTiles) do
    Ladders.excludeAnimTiles[name] = true
end

Ladders.customSprites = {
    { name = Ladders.climbSheetTopN, id = Ladders.idN, flags = {
        IsoFlagType.collideN, IsoFlagType.transparentN, IsoFlagType.cutN,
        IsoFlagType.climbSheetTopN, IsoFlagType.HoppableN, IsoFlagType.canPathN,
        IsoFlagType.WallNTrans, IsoFlagType.EntityScript,
    } },
    { name = Ladders.climbSheetTopS, id = Ladders.idS, flags = {
        IsoFlagType.climbSheetTopS, IsoFlagType.EntityScript,
    } },
    { name = Ladders.climbSheetTopW, id = Ladders.idW, flags = {
        IsoFlagType.collideW, IsoFlagType.transparentW, IsoFlagType.cutW,
        IsoFlagType.climbSheetTopW, IsoFlagType.HoppableW, IsoFlagType.canPathW,
        IsoFlagType.WallWTrans, IsoFlagType.EntityScript,
    } },
    { name = Ladders.climbSheetTopE, id = Ladders.idE, flags = {
        IsoFlagType.climbSheetTopE, IsoFlagType.EntityScript,
    } },
    { name = Ladders.exitN, id = Ladders.idExitN, flags = {
        IsoFlagType.collideN, IsoFlagType.transparentN, IsoFlagType.cutN,
        IsoFlagType.HoppableN, IsoFlagType.canPathN, IsoFlagType.WallNTrans,
        IsoFlagType.EntityScript,
    } },
    { name = Ladders.exitW, id = Ladders.idExitW, flags = {
        IsoFlagType.collideW, IsoFlagType.transparentW, IsoFlagType.cutW,
        IsoFlagType.HoppableW, IsoFlagType.canPathW, IsoFlagType.WallWTrans,
        IsoFlagType.EntityScript,
    } },
}

function Ladders.setLadderClimbingFlags(manager)
    for _, name in ipairs(Ladders.northLadderTiles) do
        manager:getSprite(name):getProperties():set(IsoFlagType.climbSheetN)
    end

    for _, name in ipairs(Ladders.southLadderTiles) do
        manager:getSprite(name):getProperties():set(IsoFlagType.climbSheetS)
        manager:getSprite(name):getProperties():set("IsMoveAble")
		manager:getSprite(name):getProperties():set("CanBreak")
		manager:getSprite(name):getProperties():set("BlocksPlacement")
        manager:getSprite(name):getProperties():set("MoveType","WallObject")
        manager:getSprite(name):getProperties():set("PickUpTool","Crowbar")
        manager:getSprite(name):getProperties():set("PlaceTool","Hammer")
        manager:getSprite(name):getProperties():set("PickUpLevel","2")
        manager:getSprite(name):getProperties():set("PickUpWeight","30")
        manager:getSprite(name):getProperties():set("Facing","South")
		
    end

    for _, name in ipairs(Ladders.WoodenLadderTiles) do
		manager:getSprite(name):getProperties():set("CustomName", "Ladder")
		manager:getSprite(name):getProperties():set("GroupName", "Wooden")
	end
	
    for _, name in ipairs(Ladders.SteelLadderTiles) do
		manager:getSprite(name):getProperties():set("CustomName", "Ladder")
		manager:getSprite(name):getProperties():set("GroupName", "Steel")
	end
	
    for _, name in ipairs(Ladders.westLadderTiles) do
        manager:getSprite(name):getProperties():set(IsoFlagType.climbSheetW)
    end

    for _, name in ipairs(Ladders.eastLadderTiles) do
        manager:getSprite(name):getProperties():set(IsoFlagType.climbSheetE)
		manager:getSprite(name):getProperties():set("IsMoveAble")
		manager:getSprite(name):getProperties():set("CanBreak")
		manager:getSprite(name):getProperties():set("BlocksPlacement")
        manager:getSprite(name):getProperties():set("MoveType","WallObject")
        manager:getSprite(name):getProperties():set("PickUpTool","Crowbar")
        manager:getSprite(name):getProperties():set("PlaceTool","Hammer")
        manager:getSprite(name):getProperties():set("PickUpLevel","2")
		manager:getSprite(name):getProperties():set("PickUpWeight","30")
        manager:getSprite(name):getProperties():set("Facing","East")
    end

    for _, name in ipairs(Ladders.holeTiles) do
        local props = manager:getSprite(name):getProperties()
        props:set(IsoFlagType.climbSheetTopW)
        props:set(IsoFlagType.HoppableW)
        props:unset(IsoFlagType.solidfloor)
    end

    for _, name in ipairs(Ladders.poleTiles) do
        manager:getSprite(name):getProperties():set(IsoFlagType.climbSheetW)
    end

    for _, def in ipairs(Ladders.customSprites) do
        local sprite = manager:AddSprite(def.name, def.id)
        sprite:setName(def.name)
        local props = sprite:getProperties()
        for _, flag in ipairs(def.flags) do
            props:set(flag)
        end
        props:CreateKeySet()
    end
end

Events.OnKeyPressed.Add(Ladders.OnKeyPressed)
Events.OnLoadedTileDefinitions.Add(Ladders.setLadderClimbingFlags)

return Ladders
