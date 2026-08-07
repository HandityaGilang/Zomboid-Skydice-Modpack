local TABAS_MoveUtils = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

local TABAS_Dirs = {
    S = {
        front = "S",
        side  = {"E","W"},
        diagF = {"SE","SW"},
        walkTo  = {"E","W","SE","SW"},
        adj3  = {"S","E","W"},
    },
    E = {
        front = "E",
        side  = {"N","S"},
        diagF = {"NE","SE"},
        walkTo  = {"N","S","NE","SE"},
        adj3  = {"E","N","S"},
    },
    N = {
        front = "N",
        side  = {"E","W"},
        diagF = {"NE","NW"},
        walkTo  = {"E","W","NE","NW"},
        adj3  = {"N","E","W"},
    },
    W = {
        front = "W",
        side  = {"N","S"},
        diagF = {"NW","SW"},
        walkTo  = {"N","S","NW","SW"},
        adj3  = {"W","N","S"},
    },
}

--------------------- Find Square Helper ---------------------

local function isBlocksPlacement(square)
    if not square then return true end
    local props = square:getProperties()
    return props and props:has("BlocksPlacement") or false
end

local function isHoppableTubEdge(sq, adj)
    if adj:isWindowBlockedTo(sq) then return false end
    if adj:isDoorBlockedTo(sq) then return false end
    if adj:isStairBlockedTo(sq) then return false end
    if adj:isWallTo(sq) and not adj:isHoppableTo(sq) then return false end
    return true
end

local function splitNearFarByPlayer(playerObj, sqA, sqB)
    if sqA and sqB then
        if sqA:DistToProper(playerObj) <= sqB:DistToProper(playerObj) then
            return sqA, sqB
        else
            return sqB, sqA
        end
    end
    return sqA or sqB, nil
end

local function getAdjacentTubSquares(playerObj, baseSq, facing)
    local dirs = TABAS_Dirs[facing]
    if not dirs then return end

    local frontSq = baseSq:getAdjacentSquare(IsoDirections[facing])

    local sideA  = baseSq:getAdjacentSquare(IsoDirections[dirs.side[1]])
    local sideB  = baseSq:getAdjacentSquare(IsoDirections[dirs.side[2]])
    local diagA  = baseSq:getAdjacentSquare(IsoDirections[dirs.diagF[1]])
    local diagB  = baseSq:getAdjacentSquare(IsoDirections[dirs.diagF[2]])

    local nearSide, farSide = splitNearFarByPlayer(playerObj, sideA, sideB)
    local nearDiag, farDiag = splitNearFarByPlayer(playerObj, diagA, diagB)

    local choices = {
        {nearSide, baseSq},
        {nearDiag, frontSq},
        {farSide, baseSq},
        {farDiag, frontSq},
    }
    return choices
end

function TABAS_MoveUtils.findPrepareSquare(playerObj, object, facing)
    local baseSq = object:getSquare()
    if not baseSq then return nil end

    local dirs = TABAS_Dirs[facing]
    local front = baseSq:getAdjacentSquare(IsoDirections[dirs.front])
    local sideA = baseSq:getAdjacentSquare(IsoDirections[dirs.side[1]])
    local sideB = baseSq:getAdjacentSquare(IsoDirections[dirs.side[2]])
    local diagA = baseSq:getAdjacentSquare(IsoDirections[dirs.diagF[1]])
    local diagB = baseSq:getAdjacentSquare(IsoDirections[dirs.diagF[2]])

    local nearSide, farSide = splitNearFarByPlayer(playerObj, sideA, sideB)
    local nearDiag, farDiag = splitNearFarByPlayer(playerObj, diagA, diagB)

    local choices = { front, nearSide, nearDiag, farDiag, farSide}

    for i=1, #choices do
        local sq = choices[i]
        if sq and sq:canStand() and not baseSq:isBlockedTo(sq) and not isBlocksPlacement(sq) then
            return sq
        end
    end

    for i=1, #choices do
        local sq = choices[i]
        if sq and sq:canStand() and not baseSq:isBlockedTo(sq) then
            return sq
        end
    end

    return nil
end

function TABAS_MoveUtils.findPrepareAndTargetSquare(playerObj, object, facing, needClosest, ignoreBlocksPlacement)
    if not playerObj or not object or not facing then return nil, nil end

    local baseSq = object:getSquare()
    if not baseSq then return nil, nil end

    local choices = getAdjacentTubSquares(playerObj, baseSq, facing)
    if not choices then return nil, nil end

    local bestSq, bestTarget = nil, nil
    local bestDist = 1e9

    for i=1, #choices do
        local sq = choices[i][1]
        local targetSq = choices[i][2]

        if sq and targetSq and sq:canStand() and isHoppableTubEdge(sq, targetSq) then
            if (ignoreBlocksPlacement or not isBlocksPlacement(sq)) then
                if needClosest then
                    local dist = sq:DistToProper(playerObj)
                    if dist < bestDist then
                        bestDist = dist
                        bestSq = sq
                        bestTarget = targetSq
                    end
                else
                    return sq, targetSq
                end
            end
        end
    end

    return bestSq, bestTarget
end

function TABAS_MoveUtils.walkToAdjTub(playerObj, object, keepActions, allowedInner)
    if not playerObj or not object then return false end

    local baseSq = object:getSquare()
    local facing = object:getFacing()
    if not baseSq or not facing then return false end

    if not keepActions then
        ISTimedActionQueue.clear(playerObj)
    end

    -- Default keeps the player in place when already inside the tub,
    -- but callers can explicitly force an exit-side reposition with false.
    if allowedInner == nil then
        allowedInner = true
    end
    if allowedInner then
        local curSq = playerObj:getCurrentSquare()
        if curSq == baseSq or curSq == baseSq:getAdjacentSquare(facing) then
            return true
        end
    end

    local adjSq = TABAS_MoveUtils.findPrepareAndTargetSquare(playerObj, object, tostring(facing), true, true)
    if adjSq then
        local dx = math.abs(adjSq:getX() + 0.5 - playerObj:getX())
        local dy = math.abs(adjSq:getY() + 0.5 - playerObj:getY())
        if dx <= 0.5 and dy <= 0.5 and playerObj:getSquare():canReachTo(adjSq) then
            return true
        end

        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, adjSq))
        return true
    end
    return false
end

function TABAS_MoveUtils.walkToTarget(playerObj, square)
    local diffX = math.abs(square:getX() + 0.5 - playerObj:getX())
    local diffY = math.abs(square:getY() + 0.5 - playerObj:getY())
    if diffX <= 0.05 and diffY <= 0.05 then
        return true
    end
      if square ~= nil then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, square))
        return true
    else
        return false
    end
end

function TABAS_MoveUtils.onEnterTheTub(playerObj, baseSq, prepSq, targetSq, tfc_Base)
    if not baseSq or not prepSq then return false end
    if not targetSq or not prepSq:isHoppableTo(targetSq) then return false end
    if TABAS_BathingUtils.isWaterTooHot(tfc_Base) then
        TABAS_BathingUtils.sayTooHot(playerObj)
        return false
    end

    ISTimedActionQueue.add(TABAS_ClimbOverTubEdge:new(playerObj, prepSq, targetSq, tfc_Base))
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, targetSq))
    if baseSq ~= targetSq then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, baseSq))
    end
    return true
end

function TABAS_MoveUtils.onExitTheTub(playerObj, baseSq, prepSq, targetSq)
    if not baseSq or not prepSq then return false end
    if targetSq and baseSq ~= targetSq then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, targetSq))
    end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, prepSq))
    return true
end

return TABAS_MoveUtils
