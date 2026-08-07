NB_BuildRecipeCode = NB_BuildRecipeCode or {}
NB_BuildRecipeCode.PartFloors = {}
NB_BuildRecipeCode.Floors = {}
NB_BuildRecipeCode.WindowWall = {}
NB_BuildRecipeCode.BigGate = {}
NB_BuildRecipeCode.NewWall = {}


-- ----------------------------------------------------------------------------------------------------- --
-- Server-side safety helpers (integrated from XP_NB NB_BuildRecipeCode_SPatch.lua)
-- ----------------------------------------------------------------------------------------------------- --

local function NB_safeCall(fn, ...)
    -- Call a function safely; return nil on error.
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local function NB_hasFlag(props, flag)
    -- Guard: some flags don't exist in certain builds (nil) or are client-only.
    if not props or flag == nil then return false end

    -- Prefer the native flag-aware APIs when available.
    if props.hasFlagType then
        return NB_safeCall(function() return props:hasFlagType(flag) end) or false
    end
    if props.is then
        return NB_safeCall(function() return props:is(flag) end) or false
    end

    -- On B42.13 we may have a synthetic Is() mapping to :has(string).
    if props.Is then
        return NB_safeCall(function() return props:Is(flag) end) or false
    end

    -- Last resort: try :has(...) directly.
    if props.has then
        return NB_safeCall(function() return props:has(flag) end) or false
    end

    return false
end

local function NB_snapshotSquareObjects(square)
    -- Copy square:getObjects() into a plain Lua array to avoid concurrent modification.
    local out = {}
    if not square then return out end
    local objs = square:getObjects()
    if not objs then return out end

    for i = 0, objs:size() - 1 do
        out[#out + 1] = objs:get(i)
    end
    return out
end

local function NB_rugToTopIfNeeded(square, rugObj)
    -- Keep rug object last in the render stack (NB behavior).
    if not (square and rugObj) then return end
    local objs = square:getObjects()
    if not objs then return end

    -- Remove by object reference if present, then re-add to end.
    NB_safeCall(function()
        if objs:contains(rugObj) then
            objs:remove(rugObj)
            objs:add(rugObj)
        end
    end)
end

local function NB_sideEffects_PartFloors(square)
    -- Side effects after placing partial floors.
    -- Some methods are client-only; guard them so MP/dedicated doesn't throw.
    if not square then return end

    if square.disableErosion then
        NB_safeCall(function() square:disableErosion() end)
    end
    if square.invalidateLighting then
        NB_safeCall(function() square:invalidateLighting() end)
    end
    if square.RecalcProperties then
        NB_safeCall(function() square:RecalcProperties() end)
    end
    if square.RecalcAllWithNeighbours then
        NB_safeCall(function() square:RecalcAllWithNeighbours(true) end)
    end

    -- Mirror vanilla erosion disable on server.
    if sendServerCommand then
        NB_safeCall(sendServerCommand, "erosion", "disableForSquare",
            { x = square:getX(), y = square:getY(), z = square:getZ() })
    end
end

local function NB_sideEffects_Floors(square)
    -- Replicate NB original side-effects for Floors.OnCreate (+ erosion command like vanilla).
    -- Many of these helpers are client-only; guard them for MP/dedicated safety.
    if not square then return end

    if square.clearWater then
        NB_safeCall(function() square:clearWater() end)
    end
    if square.disableErosion then
        NB_safeCall(function() square:disableErosion() end)
    end

    if square.invalidateLighting then
        NB_safeCall(function() square:invalidateLighting() end)
    end
    if square.RecalcProperties then
        NB_safeCall(function() square:RecalcProperties() end)
    end
    if square.EnsureSurroundNotNull then
        NB_safeCall(function() square:EnsureSurroundNotNull() end)
    end
    if square.FixStackableObjects then
        NB_safeCall(function() square:FixStackableObjects() end)
    end
    if square.RecalcAllWithNeighbours then
        NB_safeCall(function() square:RecalcAllWithNeighbours(true) end)
    end

    local cell = getCell and getCell() or nil
    if cell and square.getZ and square:getZ() > 0 then
        local below = cell:getGridSquare(square:getX(), square:getY(), square:getZ() - 1)
        if below then
            if below.EnsureSurroundNotNull then NB_safeCall(function() below:EnsureSurroundNotNull() end) end
            if below.RecalcAllWithNeighbours then NB_safeCall(function() below:RecalcAllWithNeighbours(true) end) end
        end
    end

    if sendServerCommand then
        NB_safeCall(sendServerCommand, "erosion", "disableForSquare",
            { x = square:getX(), y = square:getY(), z = square:getZ() })
    end
end

local function NB_resolveTargetSquare(params)
	if not params then return nil end

	-- Direct square reference (if provided by the caller).
	if params.square then
		return params.square
	end

	-- Thumpable reference (classic build recipes).
	if params.thumpable and params.thumpable.getSquare then
		local sq = params.thumpable:getSquare()
		if sq then return sq end
	end

	-- Raw coordinates (some build/crafting flows pass these).
	if params.x ~= nil and params.y ~= nil and params.z ~= nil then
		local x = tonumber(params.x)
		local y = tonumber(params.y)
		local z = tonumber(params.z)
		if x and y and z then
			return getCell():getGridSquare(x, y, z)
		end
	end

	-- Last resort: if we have a thumpable but it isn't on a square yet, try its coords.
	if params.thumpable then
		local t = params.thumpable
		local x = t.getX and t:getX() or nil
		local y = t.getY and t:getY() or nil
		local z = t.getZ and t:getZ() or nil
		if x ~= nil and y ~= nil and z ~= nil then
			return getCell():getGridSquare(x, y, z)
		end
	end

	return nil
end

function NB_BuildRecipeCode.PartFloors.OnCreate(params)
    -- Safe server-side implementation:
    -- - Avoid iterating a live Java list while removing objects.
    -- - Keep property checks compatible across B42.12.x and B42.13.x.
    local square = NB_resolveTargetSquare(params)
    local thumpable = params and params.thumpable or nil
    if not square then return end

    local snapshot = NB_snapshotSquareObjects(square)

    -- Find rug object (NB behavior).
    local rugObj = nil
    for _, obj in ipairs(snapshot) do
        local props = obj and obj.getProperties and obj:getProperties() or nil
        if NB_hasFlag(props, IsoFlagType.rug) then
            rugObj = obj
            break
        end
    end

    -- Remove only floor overlays safely.
    for _, obj in ipairs(snapshot) do
        if obj and obj ~= rugObj and obj ~= thumpable then
            local props = obj.getProperties and obj:getProperties() or nil
            if NB_hasFlag(props, IsoFlagType.FloorOverlay) then
                square:transmitRemoveItemFromSquare(obj)
            end
        end
    end

    NB_rugToTopIfNeeded(square, rugObj)
    NB_sideEffects_PartFloors(square)
end

function NB_BuildRecipeCode.Floors.OnCreate(params)
    -- Safe server-side implementation:
    -- - Avoid iterating a live Java list while removing objects.
    -- - Keep property checks compatible across B42.12.x and B42.13.x.
    local square = NB_resolveTargetSquare(params)
    local thumpable = params and params.thumpable or nil
    if not square then return end

    local snapshot = NB_snapshotSquareObjects(square)

    -- Find rug object (NB behavior).
    local rugObj = nil
    for _, obj in ipairs(snapshot) do
        local props = obj and obj.getProperties and obj:getProperties() or nil
        if NB_hasFlag(props, IsoFlagType.rug) then
            rugObj = obj
            break
        end
    end

    -- Remove overlays & floors safely.
    for _, obj in ipairs(snapshot) do
        if obj and obj ~= rugObj and obj ~= thumpable then
            local props = obj.getProperties and obj:getProperties() or nil
            if NB_hasFlag(props, IsoFlagType.FloorOverlay) or NB_hasFlag(props, IsoFlagType.floor) then
                square:transmitRemoveItemFromSquare(obj)
            end
        end
    end

    NB_rugToTopIfNeeded(square, rugObj)
    NB_sideEffects_Floors(square)
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
    -- Safe server-side implementation:
    -- - Keep property checks compatible across B42.12.x and B42.13.x.
    -- - Avoid relying on APIs that may be client-only.
    local thumpable = params and params.thumpable
    local square = thumpable and thumpable.getSquare and thumpable:getSquare() or nil
    if not square then return end

    local spriteConfig = thumpable.getSpriteConfig and thumpable:getSpriteConfig() or nil
    local objInfo = spriteConfig and spriteConfig.getObjectInfo and spriteConfig:getObjectInfo() or nil
    local script = objInfo and objInfo.getScript and objInfo:getScript() or nil
    local cornerSprite = script and script.getCornerSprite and script:getCornerSprite() or nil
    if not cornerSprite then return end

    -- Detect which corner type is present on the square (NW or SE).
    local cornerType = nil
    local specials = square.getSpecialObjects and square:getSpecialObjects() or nil
    if specials then
        for i = specials:size() - 1, 0, -1 do
            local object = specials:get(i)
            if instanceof(object, "IsoThumpable") then
                local sp = object.getSprite and object:getSprite() or nil
                local props = sp and sp.getProperties and sp:getProperties() or nil
                if NB_hasFlag(props, IsoFlagType.WallSE) then
                    cornerType = "SE"
                    break
                elseif NB_hasFlag(props, IsoFlagType.WallNW) then
                    cornerType = "NW"
                    break
                end
            end
        end
    end

    local cell = getCell and getCell() or nil
    if not cell then return end

    local cornerSquare = nil
    if cornerType == "NW" then
        -- Prefer the north tile when building a north wall; otherwise use the west tile.
        cornerSquare = (params and params.north and cell:getGridSquare(square:getX() - 1, square:getY(), square:getZ()))
            or cell:getGridSquare(square:getX(), square:getY() - 1, square:getZ())
    elseif cornerType == "SE" then
        cornerSquare = cell:getGridSquare(square:getX(), square:getY(), square:getZ())
    end

    if not cornerSquare then return end

    local cornerSpecials = cornerSquare.getSpecialObjects and cornerSquare:getSpecialObjects() or nil
    if not cornerSpecials then return end

    -- Replace the corner wall object with the correct corner sprite.
    for i = cornerSpecials:size() - 1, 0, -1 do
        local object = cornerSpecials:get(i)
        if instanceof(object, "IsoThumpable") then
            local cfg = object.getSpriteConfig and object:getSpriteConfig() or nil
            if cfg and (cfg:getId() == "WallNW" or cfg:getId() == "WallSE") then
                local cornerObject = IsoThumpable.new(cell, cornerSquare, cornerSprite, false, nil)

                -- Preserve NB corner settings when the APIs exist.
                if cornerObject and cornerObject.setCorner then
                    NB_safeCall(function() cornerObject:setCorner(true) end)
                end
                if cornerObject and cornerObject.setCanBarricade then
                    NB_safeCall(function() cornerObject:setCanBarricade(false) end)
                end

                local replacedIndex = cornerSquare:transmitRemoveItemFromSquare(object)

                -- Add the new corner at the same position if the API supports an index.
                if cornerSquare.AddSpecialObject then
                    if replacedIndex ~= nil then
                        NB_safeCall(function() cornerSquare:AddSpecialObject(cornerObject, replacedIndex) end)
                    else
                        NB_safeCall(function() cornerSquare:AddSpecialObject(cornerObject) end)
                    end
                end

                if cornerSquare.RecalcProperties then NB_safeCall(function() cornerSquare:RecalcProperties() end) end
                if cornerSquare.RecalcAllWithNeighbours then NB_safeCall(function() cornerSquare:RecalcAllWithNeighbours(true) end) end
                if cornerSquare.transmitCompleteItemToClients then NB_safeCall(function() cornerSquare:transmitCompleteItemToClients() end) end
            end
        end
    end
end
