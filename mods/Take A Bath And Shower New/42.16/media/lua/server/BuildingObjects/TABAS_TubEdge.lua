local TABAS_TubEdge = {}

local TABAS_Iso = require("TABAS_Iso")
local TABAS_Utils = require("TABAS_Utils")

local EDGE_NAME       = "TubEdge"
local EDGE_HOPPABLE_N = "tabas_fixtures_bathroom_01_0"
local EDGE_HOPPABLE_W = "tabas_fixtures_bathroom_01_1"
local EDGE_BLOCKED_N  = "tabas_fixtures_bathroom_01_2"
local EDGE_BLOCKED_W  = "tabas_fixtures_bathroom_01_3"
local EDGE_SPRITES = {
	[EDGE_HOPPABLE_N] = true,
	[EDGE_HOPPABLE_W] = true,
	[EDGE_BLOCKED_N] = true,
	[EDGE_BLOCKED_W] = true,
}

local ADJ_DIRS = { IsoDirections.N, IsoDirections.S, IsoDirections.E, IsoDirections.W }
local EDGE_WALL_DIR_BY_SPRITE = {
	[EDGE_HOPPABLE_N] = IsoDirections.N,
	[EDGE_BLOCKED_N] = IsoDirections.N,
	[EDGE_HOPPABLE_W] = IsoDirections.W,
	[EDGE_BLOCKED_W] = IsoDirections.W,
}

-------------------- Utilities --------------------

local function isSolidishSq(sq)
	return sq and (sq:isSolid() or sq:isSolidTrans()) or false
end

local function isHoppableSprite(spriteName)
	return spriteName == EDGE_HOPPABLE_N or spriteName == EDGE_HOPPABLE_W
end

local function isBlockedSprite(spriteName)
	return spriteName == EDGE_BLOCKED_N or spriteName == EDGE_BLOCKED_W
end

local function getKeyXYZ(x, y, z)
	return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function getEdgeWallDir(spriteName)
	return EDGE_WALL_DIR_BY_SPRITE[spriteName]
end

function TABAS_TubEdge.isTubEdgeObject(obj)
	if not obj then return false end
	if obj:getName() == EDGE_NAME then
		return true
	end

	local spr = obj:getSprite()
	local props = spr and spr:getProperties()
	if props and props:has("CustomName") and props:get("CustomName") == EDGE_NAME then
		return true
	end

	local spriteName = spr and spr:getName()
	return spriteName and EDGE_SPRITES[spriteName] == true or false
end

local function hasBathObjectAtSquare(sq)
	if not sq then return false end
	local objs = sq:getObjects()
	for i=0, objs:size() - 1 do
		local obj = objs:get(i)
		if obj and TABAS_Iso.isBathObject(obj) then
			return true
		end
	end
	return false
end

local function getWallAdjSquare(sq, wallDir)
	if not sq or not wallDir then return nil end
	if wallDir ~= IsoDirections.N and wallDir ~= IsoDirections.W then
		return nil
	end
	return sq:getAdjacentSquare(wallDir)
end

local function isPureWallObjectForDir(obj, wallDir)
	if not obj or TABAS_TubEdge.isTubEdgeObject(obj) then return false end

	local props = obj:getProperties()
	if not props then return false end

	if wallDir == IsoDirections.N then
		if not props:has("WallN") then return false end
		if props:has("WindowN") or props:has("DoorWallN") or props:has("doorN") or props:has("HoppableN") then
			return false
		end
	elseif wallDir == IsoDirections.W then
		if not props:has("WallW") then return false end
		if props:has("WindowW") or props:has("DoorWallW") or props:has("doorW") or props:has("HoppableW") then
			return false
		end
	else
		return false
	end

	return true
end

local function hasPureWallOnSquareForDir(sq, wallDir)
	if not sq then return false end

	local adjSq = getWallAdjSquare(sq, wallDir)
	if not adjSq then return false end
	if not sq:isWallTo(adjSq) then return false end
	if sq:isWindowTo(adjSq) then return false end
	if sq:isHoppableTo(adjSq) then return false end

	local objs = sq:getObjects()
	for i = 0, objs:size() - 1 do
		local obj = objs:get(i)
		if isPureWallObjectForDir(obj, wallDir) then
			return true
		end
	end
	return false
end

local function hasConflictingWallForEdge(sq, spriteName)
	local wallDir = getEdgeWallDir(spriteName)
	return wallDir and hasPureWallOnSquareForDir(sq, wallDir) or false
end

local function hasBlockedEdgeOnSquare(sq)
	if not sq then return false end
	local objs = sq:getSpecialObjects()
	for i=objs:size() - 1, 0, -1 do
		local obj = objs:get(i)
		if obj and obj:getName() == EDGE_NAME then
			local sn = obj:getSpriteName()
			if isBlockedSprite(sn) then
				return true
			end
		end
	end
	return false
end

local function hasBlockedEdgeNearby(sq)
	if not sq then return false end
	return hasBlockedEdgeOnSquare(sq)
		or hasBlockedEdgeOnSquare(sq:getAdjacentSquare(IsoDirections.N))
		or hasBlockedEdgeOnSquare(sq:getAdjacentSquare(IsoDirections.S))
		or hasBlockedEdgeOnSquare(sq:getAdjacentSquare(IsoDirections.E))
		or hasBlockedEdgeOnSquare(sq:getAdjacentSquare(IsoDirections.W))
end

-- Excluding bathDir (this is your “other 3 directions” rule).
local function hasOtherDirHoppable(sq, bathDir)
	if not sq then return false end
	for _, dir in ipairs(ADJ_DIRS) do
		if dir ~= bathDir then
			local other = sq:getAdjacentSquare(dir)
			if other and sq:isHoppableTo(other) then
				return true
			end
		end
	end
	return false
end

local function getInitialSolidJudgeSquare(targetSq, spriteName)
	if not targetSq then return nil end
	if not hasBathObjectAtSquare(targetSq) then
		return targetSq
	end

	local wallDir = getEdgeWallDir(spriteName)
	if not wallDir then return targetSq end
	return targetSq:getAdjacentSquare(wallDir) or targetSq
end

local function shouldPlaceForSolidChange(targetSq, bathDir)
	return (not isSolidishSq(targetSq)) or hasOtherDirHoppable(targetSq, bathDir)
end

local function shouldRemoveForSolidChange(targetSq, bathDir)
	return isSolidishSq(targetSq) and (not hasOtherDirHoppable(targetSq, bathDir))
end

local function shouldPlaceForInitialCreate(targetSq, spriteName)
    local judgeSq = getInitialSolidJudgeSquare(targetSq, spriteName)
    return judgeSq and (not isSolidishSq(judgeSq)) or false
end

local function getHoppableTargetForBathDir(eventSq, bathDir)
	if not eventSq then return nil end
	if bathDir == IsoDirections.N then
		return eventSq, EDGE_HOPPABLE_N
	elseif bathDir == IsoDirections.S then
		return eventSq:getAdjacentSquare(IsoDirections.S), EDGE_HOPPABLE_N
	elseif bathDir == IsoDirections.W then
		return eventSq, EDGE_HOPPABLE_W
	elseif bathDir == IsoDirections.E then
		return eventSq:getAdjacentSquare(IsoDirections.E), EDGE_HOPPABLE_W
	end
	return nil
end

local function getCrossSquares(baseSq)
	if not baseSq then return {} end
	return {
		baseSq,
		baseSq:getAdjacentSquare(IsoDirections.N),
		baseSq:getAdjacentSquare(IsoDirections.S),
		baseSq:getAdjacentSquare(IsoDirections.E),
		baseSq:getAdjacentSquare(IsoDirections.W),
	}
end

-------------------- Edge operations --------------------
local function hasEdgeSpriteOnSquare(sq, spriteName)
	if not sq then return false end
	local objs = sq:getSpecialObjects()
	for i = 0, objs:size() - 1 do
		local obj = objs:get(i)
		if obj and obj:getName() == EDGE_NAME and obj:getSpriteName() == spriteName then
			return true
		end
	end
	return false
end

local function ensureEdgeObject(spriteName, sq, ignoreBlocked)
	if not sq or not sq:TreatAsSolidFloor() then return end

	-- A bathtub pair often attempts to place the same edge twice during load.
	-- Skip expensive blocked/wall checks when the edge already exists.
	if hasEdgeSpriteOnSquare(sq, spriteName) then
		return
	end

	if not ignoreBlocked and hasBlockedEdgeNearby(sq) then return end
	if hasConflictingWallForEdge(sq, spriteName) then return end

	local edgeObj = IsoObject.new(getWorld():getCell(), sq, spriteName)
	edgeObj:setName(EDGE_NAME)
	sq:AddSpecialObject(edgeObj)
	edgeObj:transmitCompleteItemToClients()
	sq:RecalcPropertiesIfNeeded()

	if TABAS_Utils.DEBUG_ENABLE then
		TABAS_Utils.debugPrint("Tub Edge Create", string.format("%s at %d,%d,%d", tostring(spriteName), sq:getX(), sq:getY(), sq:getZ()))
	end
end

local function removeTubEdgesFromSquare(sq, predicate)
	if not sq then return false end
	local objs = sq:getSpecialObjects()
	if not objs then return false end

	local removed = false
	for i = objs:size() - 1, 0, -1 do
		local obj = objs:get(i)
		if obj and obj:getName() == EDGE_NAME then
			local spriteName = obj:getSpriteName()
			if predicate(spriteName) then
				sq:transmitRemoveItemFromSquare(obj)
				removed = true
				if TABAS_Utils.DEBUG_ENABLE then
					TABAS_Utils.debugPrint("Tub Edge Remove", string.format("%s at %d,%d,%d", tostring(spriteName), sq:getX(), sq:getY(), sq:getZ()))
				end
			end
		end
	end
	return removed
end

function TABAS_TubEdge.removeTubEdgeAtSquare(sq, removeBlocked)
	return removeTubEdgesFromSquare(sq, function(spriteName)
		return isHoppableSprite(spriteName) or (removeBlocked and isBlockedSprite(spriteName))
	end)
end

function TABAS_TubEdge.removeTubEdgeAtSquareByWallDir(sq, wallDir)
	if not wallDir then return false end
	return removeTubEdgesFromSquare(sq, function(spriteName)
		return getEdgeWallDir(spriteName) == wallDir
	end)
end

-- Remove hoppable edges around bath square (bath removal only).
function TABAS_TubEdge.removeTubEdgeAround(baseSq, removeBlocked)
	for _, sq in ipairs(getCrossSquares(baseSq)) do
		TABAS_TubEdge.removeTubEdgeAtSquare(sq, removeBlocked)
	end
end

-------------------- (creates both Blocked + Hoppable) --------------------
function TABAS_TubEdge.createTubEdge(baseSq, facingDir, isFaucet, ignoreBlocked)
	if not baseSq then return end

	local function placeHoppable(spriteName, sq)
		if not sq then return end
		if not sq:TreatAsSolidFloor() then return end
	
		if shouldPlaceForInitialCreate(sq, spriteName) then
			ensureEdgeObject(spriteName, sq, ignoreBlocked)
		elseif not hasConflictingWallForEdge(sq, spriteName) then
			-- Immediately after OnLoad.
			TABAS_TubEdge.pendingAddEnsure(sq, spriteName, nil, "initial", ignoreBlocked, sq)
		end
	end

	local function placeBlocked(spriteName, sq)
		if not sq then return end
		ensureEdgeObject(spriteName, sq, true) -- ignoreBlocked ALWAYS for Blocked
	end

	if isFaucet then
		if facingDir == IsoDirections.N then
			placeBlocked(EDGE_BLOCKED_N,  baseSq:getAdjacentSquare(IsoDirections.S))
			placeHoppable(EDGE_HOPPABLE_W, baseSq:getAdjacentSquare(IsoDirections.E))
			placeHoppable(EDGE_HOPPABLE_W, baseSq)
		elseif facingDir == IsoDirections.W then
			placeHoppable(EDGE_HOPPABLE_N, baseSq)
			placeHoppable(EDGE_HOPPABLE_N, baseSq:getAdjacentSquare(IsoDirections.S))
			placeBlocked(EDGE_BLOCKED_W,  baseSq:getAdjacentSquare(IsoDirections.E))
		elseif facingDir == IsoDirections.S then
			placeBlocked(EDGE_BLOCKED_N,  baseSq)
			placeHoppable(EDGE_HOPPABLE_W, baseSq)
			placeHoppable(EDGE_HOPPABLE_W, baseSq:getAdjacentSquare(IsoDirections.E))
		elseif facingDir == IsoDirections.E then
			placeHoppable(EDGE_HOPPABLE_N, baseSq)
			placeHoppable(EDGE_HOPPABLE_N, baseSq:getAdjacentSquare(IsoDirections.S))
			placeBlocked(EDGE_BLOCKED_W,  baseSq)
		end
	else
		if facingDir == IsoDirections.N then
			placeBlocked(EDGE_BLOCKED_N,  baseSq)
			placeHoppable(EDGE_HOPPABLE_W, baseSq)
			placeHoppable(EDGE_HOPPABLE_W, baseSq:getAdjacentSquare(IsoDirections.E))
		elseif facingDir == IsoDirections.W then
			placeHoppable(EDGE_HOPPABLE_N, baseSq:getAdjacentSquare(IsoDirections.S))
			placeHoppable(EDGE_HOPPABLE_N, baseSq)
			placeBlocked(EDGE_BLOCKED_W,  baseSq)
		elseif facingDir == IsoDirections.S then
			placeBlocked(EDGE_BLOCKED_N,  baseSq:getAdjacentSquare(IsoDirections.S))
			placeHoppable(EDGE_HOPPABLE_W, baseSq:getAdjacentSquare(IsoDirections.E))
			placeHoppable(EDGE_HOPPABLE_W, baseSq)
		elseif facingDir == IsoDirections.E then
			placeHoppable(EDGE_HOPPABLE_N, baseSq)
			placeHoppable(EDGE_HOPPABLE_N, baseSq:getAdjacentSquare(IsoDirections.S))
			placeBlocked(EDGE_BLOCKED_W,  baseSq:getAdjacentSquare(IsoDirections.E))
		end
	end
end

-- For MapObjects.OnLoad / OnLoad helper
function TABAS_TubEdge.initTubEdgeAtBathObject(bathObj, doCleanup, ignoreBlocked)
	if not bathObj then return end
	if not TABAS_Iso.isBathObject(bathObj) then return end

	local sq = bathObj:getSquare()
	if not sq then return end

	local spriteName = bathObj:getSpriteName()
	if not spriteName then return end

	local maps = TABAS_Iso.getSpritesTable("Index", "BathPartBySprite")
	if not maps then return end

	local part = maps[spriteName] -- "tub" or "faucet"
	if part ~= "tub" and part ~= "faucet" then return end

	if doCleanup then
		TABAS_TubEdge.removeTubEdgeAround(sq, true)
	end

	local facing = bathObj:getFacing()
	TABAS_TubEdge.createTubEdge(sq, facing, part == "faucet", ignoreBlocked == true)
end

-------------------- Pending --------------------
-- (re-evaluate after world updates / net delay)
-- ==================== Pending (split) ====================

TABAS_TubEdge.pendingEnsure = TABAS_TubEdge.pendingEnsure or {}
TABAS_TubEdge.pendingReeval = TABAS_TubEdge.pendingReeval or {}
TABAS_TubEdge.pendingBathRebuild = TABAS_TubEdge.pendingBathRebuild or {}

-- kind: "initial" or "solidRemoved"
-- placeSq : targetSq
-- judgeSq : eventSq
function TABAS_TubEdge.pendingAddEnsure(placeSq, spriteName, bathDir, kind, ignoreBlocked, judgeSq)
    if not placeSq or not spriteName then return end

    local k = "ensure:" .. getKeyXYZ(placeSq:getX(), placeSq:getY(), placeSq:getZ()) .. "|" .. tostring(spriteName)
    local e = TABAS_TubEdge.pendingEnsure[k]
    if e then
        e.retry = math.max(e.retry or 0, 10)
        return
    end

    judgeSq = judgeSq or placeSq

    TABAS_TubEdge.pendingEnsure[k] = {
        -- where to place/remove
        x = placeSq:getX(), y = placeSq:getY(), z = placeSq:getZ(),
        sprite = spriteName,

        -- how to judge
        jx = judgeSq:getX(), jy = judgeSq:getY(), jz = judgeSq:getZ(),
        bathDir = bathDir, -- needed for solidRemoved logic
        kind = kind or "initial",
        ignoreBlocked = ignoreBlocked == true,
        retry = 10,
    }
end

-- mode: "added" or "removed"  (eventSq based)
function TABAS_TubEdge.pendingAddReevalEventSq(x, y, z, mode)
    local k = "reeval:" .. getKeyXYZ(x,y,z) .. "|" .. tostring(mode or "added")
    local e = TABAS_TubEdge.pendingReeval[k]
    if e then
        e.retry = math.max(e.retry or 0, 10)
        return
    end
    TABAS_TubEdge.pendingReeval[k] = { x=x, y=y, z=z, mode=mode or "added", retry=10 }
end

function TABAS_TubEdge.pendingAddBathRebuildSq(x, y, z)
	local k = "bathRebuild:" .. getKeyXYZ(x, y, z)
	local e = TABAS_TubEdge.pendingBathRebuild[k]
	if e then
		e.retry = math.max(e.retry or 0, 10)
		return
	end
	TABAS_TubEdge.pendingBathRebuild[k] = { x = x, y = y, z = z, retry = 10 }
end

local function processPendingEnsure()
    local cell = getWorld():getCell()
    if not cell then return end

    for k, v in pairs(TABAS_TubEdge.pendingEnsure) do
        local sq = cell:getGridSquare(v.x, v.y, v.z)
        if sq then
            if v.kind == "initial" then
                if shouldPlaceForInitialCreate(sq, v.sprite) then
                    ensureEdgeObject(v.sprite, sq, v.ignoreBlocked)
                end
			elseif v.kind == "solidRemoved" then
				local judgeSq = cell:getGridSquare(v.jx, v.jy, v.jz)
				if judgeSq and shouldPlaceForSolidChange(judgeSq, v.bathDir) then
					ensureEdgeObject(v.sprite, sq, v.ignoreBlocked)
				end
			end
        end

        v.retry = (v.retry or 0) - 1
        if v.retry <= 0 then
            TABAS_TubEdge.pendingEnsure[k] = nil
        end
    end
end

local function processPendingReeval()
    local cell = getWorld():getCell()
    if not cell then return end

    for k, v in pairs(TABAS_TubEdge.pendingReeval) do
        local eventSq = cell:getGridSquare(v.x, v.y, v.z)
        if eventSq then
            TABAS_TubEdge.onSolidChangedAtSquare(eventSq, v.mode)
        end

        v.retry = (v.retry or 0) - 1
        if v.retry <= 0 then
            TABAS_TubEdge.pendingReeval[k] = nil
        end
    end
end

local function rebuildTubEdgesNearSquare(centerSq)
	local seen = {}

	for _, sq in ipairs(getCrossSquares(centerSq)) do
		if sq then
			local objs = sq:getObjects()
			for j = 0, objs:size() - 1 do
				local obj = objs:get(j)
				if obj and not seen[obj] and TABAS_Iso.isBathObject(obj) then
					seen[obj] = true
					TABAS_TubEdge.initTubEdgeAtBathObject(obj, false, true)
				end
			end
		end
	end
end

local function processPendingBathRebuild()
	local cell = getWorld():getCell()
	if not cell then return end

	for k, v in pairs(TABAS_TubEdge.pendingBathRebuild) do
		local sq = cell:getGridSquare(v.x, v.y, v.z)
		if sq then
			rebuildTubEdgesNearSquare(sq)
		end

		v.retry = (v.retry or 0) - 1
		if v.retry <= 0 then
			TABAS_TubEdge.pendingBathRebuild[k] = nil
		end
	end
end

-------------------- Core --------------------
-- mode: "added" (solid-ish object added) / "removed" (solid-ish object removed)
function TABAS_TubEdge.onSolidChangedAtSquare(eventSq, mode)
    if not eventSq then return end

    for _, bathDir in ipairs(ADJ_DIRS) do
        local bathSq = eventSq:getAdjacentSquare(bathDir)
        if bathSq and hasBathObjectAtSquare(bathSq) then

            local targetSq, sprite = getHoppableTargetForBathDir(eventSq, bathDir)
            if targetSq and sprite then
                if mode == "added" then
                    if shouldRemoveForSolidChange(eventSq, bathDir) then
                        if TABAS_TubEdge.removeTubEdgeAtSquare(targetSq, false) then
                            targetSq:RecalcPropertiesIfNeeded()
                        end
                    end

                elseif mode == "removed" then
                    TABAS_TubEdge.pendingAddEnsure(targetSq, sprite, bathDir, "solidRemoved", true, eventSq)
                end
            end
        end
    end
end

-------------------- Events --------------------

local function onObjectAdded(object)
	if not object or not instanceof(object, "IsoObject") then return end

	-- Bath object: create edges around it (ignoreBlocked=true here, consistent with your earlier usage).
	if TABAS_Iso.isBathObject(object) then
		local spriteName = object:getSpriteName()
		if not spriteName then return end

		local maps = TABAS_Iso.getSpritesTable("Index", "BathPartBySprite")
		local sq = object:getSquare()
		if not maps or not sq then return end

		local facing = object:getFacing()
		local part = maps[spriteName]
		if part == "faucet" then
			TABAS_TubEdge.createTubEdge(sq, facing, true, true)
		elseif part == "tub" then
			TABAS_TubEdge.createTubEdge(sq, facing, false, true)
		end
		return
	end

	local sq = object:getSquare()
	if sq then
		local removed = false
		if isPureWallObjectForDir(object, IsoDirections.N) then
			removed = TABAS_TubEdge.removeTubEdgeAtSquareByWallDir(sq, IsoDirections.N) or removed
		end
		if isPureWallObjectForDir(object, IsoDirections.W) then
			removed = TABAS_TubEdge.removeTubEdgeAtSquareByWallDir(sq, IsoDirections.W) or removed
		end
		if removed then
			sq:RecalcPropertiesIfNeeded()
		end
	end

	-- Solid-ish added: may require removing hoppable edges near adjacent bathtubs.
	local props = object:getProperties()
	if props and (props:has(IsoFlagType.solid) or props:has(IsoFlagType.solidtrans)) then
		if sq then
			TABAS_TubEdge.onSolidChangedAtSquare(sq, "added")
		end
	end
end

local function onObjectAboutToBeRemoved(object)
	if not object or not instanceof(object, "IsoObject") then return end

	-- Bath object removed: remove hoppable edges around the bath square.
	if TABAS_Iso.isBathObject(object) then
		local sq = object:getSquare()
		if sq then
			TABAS_TubEdge.removeTubEdgeAround(sq, true)
		end
		return
	end

	local sq = object:getSquare()
	if sq then
		if isPureWallObjectForDir(object, IsoDirections.N) or isPureWallObjectForDir(object, IsoDirections.W) then
			TABAS_TubEdge.pendingAddBathRebuildSq(sq:getX(), sq:getY(), sq:getZ())
		end
	end

	-- Solid-ish removed: may require recreating hoppable edges (queued).
	local props = object:getProperties()
	if props and (props:has(IsoFlagType.solid) or props:has(IsoFlagType.solidtrans)) then
		if sq then
			TABAS_TubEdge.onSolidChangedAtSquare(sq, "removed")
		end
	end
end

Events.OnObjectAdded.Add(onObjectAdded)
Events.OnObjectAboutToBeRemoved.Add(onObjectAboutToBeRemoved)
Events.OnTick.Add(processPendingEnsure)
Events.OnTick.Add(processPendingReeval)
Events.OnTick.Add(processPendingBathRebuild)

return TABAS_TubEdge
