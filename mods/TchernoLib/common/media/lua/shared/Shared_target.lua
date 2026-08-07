
local function isBlockingMouse(square,args)
    return square and ( square:isSolid()
                    or square:isSolidTrans()
                    or square:TreatAsSolidFloor()
                    or square:Is(IsoFlagType.collideW)
                    or square:Is(IsoFlagType.collideN)
                    or square:Is(IsoFlagType.doorW)--TODO check for open door ?
                    or square:Is(IsoFlagType.doorN)--TODO check for open door ?
                    or (not args or not args.goThroughWindow) and 
                        (square:Is(IsoFlagType.WindowW)
                      or square:Is(IsoFlagType.WindowN))
                    )
end

local function screenCoord2Square(xUI, yUI, zIso)
    local xIso = IsoUtils.XToIso( xUI, yUI, zIso)
    local yIso = IsoUtils.YToIso( xUI, yUI, zIso)
    return getCell():getGridSquare(xIso, yIso, zIso), xIso, yIso
end

--Tchernobill: let's try to detect the mouse-blocking square
--use line of sight on raw square to detect if we must look up
--use grid square Properties to detect if we must look down
function getPlayerMouseSquare(player,args)
    local xUI = Mouse:getX()
    local yUI = Mouse:getY()
    if Portal and Portal.Verbose then print ('getPlayerMouseSquare( '..xUI..' , '..yUI..' )') end
    if not player then player = getPlayer() end
    if not player then return nil end
    local playerSquare = player:getCurrentSquare()
    if not playerSquare then playerSquare = player:getSquare() end
    if not playerSquare then return end
    local zIso = playerSquare:getZ()
    local rawSquare,xIso,yIso = screenCoord2Square(xUI,yUI,zIso)
    
    --ugly stuff to avoid recomputing the square
    if rawSquare and args then
        args.rawSquare = rawSquare
        args.rawIsoX = xIso
        args.rawIsoY = yIso
        args.rawIsoZ = zIso
    end
    
    --todo use line of sight to detect if we must look up?
    local mustLookUp = false
    local square = rawSquare
    local dist = nil
    local minZ = 0

    --use grid square Properties to detect if we must look down
    if not square or (args and args.onlyLowerSquare) or not isBlockingMouse(square,args) then
        local zBlocking = zIso
        square = nil
        while zBlocking >= minZ and (not square or not isBlockingMouse(square,args)) do
            zBlocking = zBlocking - 1
            local lowerSquare = nil
            lowerSquare, xIso, yIso = screenCoord2Square(xUI,yUI,zBlocking)--get square visualy below
            if Portal and Portal.Verbose then print ('MouseSquare '..sq2str(square)..' has no floor. => '..sq2str(lowerSquare)) end
            if lowerSquare then
                square = lowerSquare
                zIso = zBlocking
            end--look down
        end
    end
    if square then
        if args then
            args.lastSquare = square
            args.lastIsoX = xIso
            args.lastIsoY = yIso
            args.lastIsoZ = zIso
        end
        if (not args or not args.isNotRequiredToSee) and not square:isCanSee(IsoPlayer.getPlayerIndex()) then
            if Portal and Portal.Verbose then print ('MouseSquare '..sq2str(square)..' inhibited by LOS.') end
            return nil
        end
    end
    return square
end

function getPlayerMouseIsoPosition(player,args)
    if args == nil then args = {} end
    local resultSquare = getPlayerMouseSquare(player,args)
    if args.lastIsoX and args.lastIsoY and args.lastIsoZ then
        return IsoPosition:new(args.lastIsoX, args.lastIsoY, args.lastIsoZ)
    else
        return nil
    end
end

--just a precise position with same (base) interface as a square without load requirement
IsoPosition = {}
function IsoPosition:new(x,y,z)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.z = z;
    return o;
end
function IsoPosition:getX() return self.x end
function IsoPosition:getY() return self.y end
function IsoPosition:getZ() return self.z end
