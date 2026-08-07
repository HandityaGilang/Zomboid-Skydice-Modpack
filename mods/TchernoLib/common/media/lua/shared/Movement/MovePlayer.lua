MovePlayer = MovePlayer or {}
MovePlayer.Verbose = false

local lcl = {}--local stuff
lcl.isoGridSquare_base = __classmetatables[IsoGridSquare.class].__index
lcl.isBlockedTo = lcl.isoGridSquare_base.isBlockedTo
lcl.getAdjacentSquare = lcl.isoGridSquare_base.getAdjacentSquare
lcl.testCollideSpecialObjects = lcl.isoGridSquare_base.testCollideSpecialObjects

lcl.isoPlayer_base = __classmetatables[IsoPlayer.class].__index
lcl.getX = lcl.isoPlayer_base.getX
lcl.getY = lcl.isoPlayer_base.getY
lcl.getZ = lcl.isoPlayer_base.getZ
local getCell = getCell
local getWorld = getWorld

--encapsulate all blocking stuff from vanilla (isBlockedTo + getSpecialSolid {+ vehicle}? )
function MovePlayer.isBlockedTo(fromSquare,toSquare)
    if not toSquare or not fromSquare then
        return true 
    elseif lcl.isBlockedTo(fromSquare,toSquare) then
        if MovePlayer.Verbose then print('MovePlayer.isBlockedTo by wall. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
        return true
    else
        local blockingObj = lcl.testCollideSpecialObjects(fromSquare,toSquare)
        if blockingObj then
            if MovePlayer.Verbose then print('MovePlayer.isBlockedTo by Obj '..tostring(blockingObj)..' from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
            return true
        elseif toSquare:isSolidTrans() or toSquare:isSolid() then
            if MovePlayer.Verbose then print('MovePlayer.isBlockedTo by solid on target square.'..' from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
            return true
        end
    end
    if MovePlayer.Verbose then print('MovePlayer.isBlockedTo return false. '..' from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
    return false
end

--works only for straight UP/DOWN/RIGHT/LEFT screen directions (no Z, no diagonal). we need a real algorithm instead of that unsafe sh*t.
function MovePlayer.canTraverseToRecurse(fromSquare,toSquare,easting,southing,ewBlocked,nsBlocked,diagBlockedEasting,diagBlockedSouthing)

    local easwestSquare = lcl.getAdjacentSquare(fromSquare,easting)
    ewBlocked = ewBlocked or MovePlayer.isBlockedTo(fromSquare,easwestSquare)
    if toSquare == easwestSquare then
        local result = not (ewBlocked or diagBlockedEasting)
        if MovePlayer.Verbose then print('MovePlayer.canTraverseToRecurse easting return '..tostring(result)..'. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
        return result
    end
    
    local northsouthSquare = lcl.getAdjacentSquare(fromSquare,southing)
    nsBlocked = nsBlocked or MovePlayer.isBlockedTo(fromSquare,northsouthSquare)
    if toSquare == northsouthSquare then
        local result = not (nsBlocked or diagBlockedSouthing)
        if MovePlayer.Verbose then print('MovePlayer.canTraverseToRecurse northing return '..tostring(result)..'. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
        return result
    end
    
    local diagSquare = nil
    if northsouthSquare then
        diagSquare = lcl.getAdjacentSquare(northsouthSquare,easting)--same as easwestSquare:getAdjacentSquare(southing)
    elseif easwestSquare then
        diagSquare = lcl.getAdjacentSquare(easwestSquare,southing)
    end
    if not diagSquare then
        if MovePlayer.Verbose then print('MovePlayer.canTraverseToRecurse diag return false by missing diag square.') end
        return false
    end
    
    diagBlockedSouthing = diagBlockedSouthing or MovePlayer.isBlockedTo(northsouthSquare,diagSquare)
    diagBlockedEasting = diagBlockedEasting or MovePlayer.isBlockedTo(easwestSquare,diagSquare)
    if toSquare == diagSquare then
        local result = not (ewBlocked or nsBlocked or diagBlockedSouthing or diagBlockedEasting)
        if MovePlayer.Verbose then print('MovePlayer.canTraverseToRecurse diag return '..tostring(result)..'. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
        return result
     end

    return MovePlayer.canTraverseToRecurse(diagSquare,toSquare,easting,southing,ewBlocked,nsBlocked,diagBlockedEasting,diagBlockedSouthing)
end
function MovePlayer.canTraverseTo(fromSquare,toSquare,deltaX,deltaY)
    if fromSquare == toSquare then 
        if MovePlayer.Verbose then print('MovePlayer.canTraverseTo return true for same. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
        return true
    end
    local ewBlocked = false;
    local nsBlocked = false;
    local diagBlockedSouthing = false;
    local diagBlockedEasting = false;
    local easting = nil
    if deltaX > 0 then--East direction of movement
        easting = IsoDirections.E
    else
        easting = IsoDirections.W
    end
    local southing = nil
    if deltaY > 0 then--South direction of movement
        southing = IsoDirections.S
    else
        southing = IsoDirections.N
    end
    
    local result = MovePlayer.canTraverseToRecurse(fromSquare,toSquare,easting,southing,ewBlocked,nsBlocked,diagBlockedEasting,diagBlockedSouthing)
    if MovePlayer.Verbose then print('MovePlayer.canTraverseTo return '..tostring(result)..'. from='..sq2str(fromSquare)..' to='..sq2str(toSquare)) end
    return result
end

function MovePlayer.canDoMoveTo(character,deltaX,deltaY,deltaZ, args)
    if not args or not args.noExtrap then--extrapolate as margin for junky animation or junky animation process
        if deltaX > 0 then deltaX = deltaX +0.05 end
        if deltaX < 0 then deltaX = deltaX -0.05 end
        if deltaY > 0 then deltaY = deltaY +0.05 end
        if deltaY < 0 then deltaY = deltaY -0.05 end
    end
    
    local targetX = lcl.getX(character)+(deltaX or 0)
    local targetY = lcl.getY(character)+(deltaY or 0)
    local targetZ = lcl.getZ(character)+(deltaZ or 0)

    --check destination is not inside a vehicle
    if targetZ < 1. and (not args or not args.noVehicleCheck) then
        local vehicle = character:getNearVehicle()
        if vehicle then--if there is a vehicle around
            if vehicle:isInBounds(targetX,targetY) then
                if MovePlayer.Verbose then print('MovePlayer.isBlockedTo by vehicle.') end
                return false
            end
        end
    end
    
    --check destination is valid
    if not getWorld():isValidSquare(targetX,targetY,targetZ) then
        if MovePlayer.Verbose then print('MovePlayer.isBlockedTo by invalid square.') end
        return false
    end

    --check destination is reachable
    local currentSquare = character:getCurrentSquare();
    if not currentSquare then
        print("MovePlayer.canDoMoveTo invalid player square. WARNING")
        return false;
    end
    
    
    local destSquare = getCell():getGridSquare(targetX, targetY, targetZ)
    if currentSquare == destSquare then return true end
    return MovePlayer.canTraverseTo(currentSquare,destSquare,deltaX or 0,deltaY or 0)
end

