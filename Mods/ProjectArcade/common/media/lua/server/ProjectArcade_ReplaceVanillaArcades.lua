ProjectArcade_ReplaceVanillaArcades = ProjectArcade_ReplaceVanillaArcades or {}

ProjectArcade_ReplaceVanillaArcades.Config = {
    modDataRoot = "ProjectArcade_ReplacedVanillaArcades",
 
    customBases = { 0, 4, 8, 12, 16 },
	
    pinballReplacements = {
        ["recreational_01_24"] = { "pa_pinballs_4", "pa_pinballs_0" }, -- head south
        ["recreational_01_25"] = { "pa_pinballs_5", "pa_pinballs_1" }, -- tail south
		["recreational_01_26"] = { "pa_pinballs_6", "pa_pinballs_2" }, -- tail east
		["recreational_01_27"] = { "pa_pinballs_7", "pa_pinballs_3" }, -- head east
    },

    pinballPairs = {
        ["recreational_01_24"] = { tailSprite = "recreational_01_25", tailDx = 0, tailDy = -1 },
        ["recreational_01_27"] = { tailSprite = "recreational_01_26", tailDx = -1, tailDy = 0 },
    },

}

local function log(msg)
    print("[ProjectArcade_ReplaceVanillaArcades] " .. tostring(msg))
end

local function isVanillaArcadeSprite(name)
    if not name then return false end
    return name == "recreational_01_16" or name == "recreational_01_17"
        or name == "recreational_01_18" or name == "recreational_01_19"
        or name == "recreational_01_20" or name == "recreational_01_21"
        or name == "recreational_01_22" or name == "recreational_01_23"
end

local function isPinballSprite(name)
    return name == "recreational_01_24" or name == "recreational_01_25"
        or name == "recreational_01_26" or name == "recreational_01_27"
end

local function isCustomArcadeSprite(name)
    
    return name and string.sub(name, 1, 10) == "pa_arcades"
end

local function getFacingIndexFromVanilla(name)
    if name == "recreational_01_16" or name == "recreational_01_20" then return 0 end 
    if name == "recreational_01_17" or name == "recreational_01_21" then return 1 end 
    if name == "recreational_01_18" or name == "recreational_01_22" then return 2 end 
    if name == "recreational_01_19" or name == "recreational_01_23" then return 3 end 
    return 0
end



local function spriteForCustom(base, facingIndex)
    return "pa_arcades_" .. tostring(base + facingIndex)
end

local function getStateRoot()
    return ModData.getOrCreate(ProjectArcade_ReplaceVanillaArcades.Config.modDataRoot)
end

local function getKey(x, y, z)
    return tostring(x) .. "_" .. tostring(y) .. "_" .. tostring(z)
end

local function chooseRandomBase()
    local bases = ProjectArcade_ReplaceVanillaArcades.Config.customBases
    
    local idx = ZombRand(#bases) + 1
    return bases[idx]
end

local function findVanillaArcadeObjectOnSquare(square)
    if not square then return nil end

    
    local objs = square:getObjects()
    if objs then
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            local spr = obj and obj.getSprite and obj:getSprite() or nil
            local name = spr and spr:getName() or nil

            if isPinballSprite(name) then
                
            elseif isCustomArcadeSprite(name) then
                
            elseif isVanillaArcadeSprite(name) then
                return obj
            end
        end
    end

    local sobjs = square:getSpecialObjects()
    if sobjs then
        for i = 0, sobjs:size() - 1 do
            local obj = sobjs:get(i)
            local spr = obj and obj.getSprite and obj:getSprite() or nil
            local name = spr and spr:getName() or nil

            if isPinballSprite(name) then
                
            elseif isCustomArcadeSprite(name) then
                
            elseif isVanillaArcadeSprite(name) then
                return obj
            end
        end
    end

    return nil
end

local function removeObjectFromSquare(square, obj)
    if not square or not obj then return end
 
    square:transmitRemoveItemFromSquare(obj)
   
    if instanceof(obj, "IsoWorldInventoryObject") then
        obj:removeFromWorld()
        obj:removeFromSquare()
        obj:setSquare(nil)
    end
end

local function spawnCustomArcade(square, spriteName)
    if not square or not spriteName then return end

    local cell = square:getCell()
    local spr = getSprite(spriteName)
    if not spr then
        log("Sprite not found: " .. tostring(spriteName))
        return
    end

    local obj = IsoObject.new(cell, square, spr)
    square:AddSpecialObject(obj)
    obj:transmitCompleteItemToServer()
end

local function getSpriteNameFromObj(obj)
    local spr = obj and obj.getSprite and obj:getSprite() or nil
    return spr and spr:getName() or nil
end

local function findFirstObjectBySprite(square, spriteName)
    if not square or not spriteName then return nil end
    local objs = square:getObjects()
    if objs then
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            if getSpriteNameFromObj(obj) == spriteName then
                return obj
            end
        end
    end
    local sobjs = square:getSpecialObjects()
    if sobjs then
        for i = 0, sobjs:size() - 1 do
            local obj = sobjs:get(i)
            if getSpriteNameFromObj(obj) == spriteName then
                return obj
            end
        end
    end
    return nil
end

local function removeFirstBySprite(square, spriteName)
    local obj = findFirstObjectBySprite(square, spriteName)
    if obj then
        removeObjectFromSquare(square, obj)
        return true
    end
    return false
end

local function spawnCustomObject(square, spriteName)
    if not square or not spriteName then return end
    local cell = square:getCell()
    local spr = getSprite(spriteName)
    if not spr then
        log("Sprite not found: " .. tostring(spriteName))
        return
    end
    local obj = IsoObject.new(cell, square, spr)
    square:AddSpecialObject(obj)
    obj:transmitCompleteItemToServer()
end

local function choosePinballSetIndex()
    -- returns 1 or 2
    return ZombRand(2) + 1
end

local function getPinballHeadSquareAndHeadSprite(square, foundSprite)
    -- If we're on a tail, compute head square.
    if foundSprite == "recreational_01_25" then
        return square:getS(), "recreational_01_24" -- tail south is NORTH of head => head is SOUTH of tail
    elseif foundSprite == "recreational_01_26" then
        return square:getE(), "recreational_01_27" -- tail east is WEST of head => head is EAST of tail
    end
    -- If already on a head:
    if foundSprite == "recreational_01_24" or foundSprite == "recreational_01_27" then
        return square, foundSprite
    end
    return nil, nil
end

local function tryReplaceVanillaPinball(square)
    local sb = SandboxVars and SandboxVars.ProjectArcade
    local optPin = sb and sb.ReplaceVanillaPinballsOnLoad
    if not optPin then return false end

    -- Detect if this square has any of the 4 vanilla pinball sprites
    local spriteFound = nil
    local objs = square:getObjects()
    if objs then
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            local name = getSpriteNameFromObj(obj)
            if isPinballSprite(name) then
                spriteFound = name
                break
            end
        end
    end
    if not spriteFound then
        local sobjs = square:getSpecialObjects()
        if sobjs then
            for i = 0, sobjs:size() - 1 do
                local obj = sobjs:get(i)
                local name = getSpriteNameFromObj(obj)
                if isPinballSprite(name) then
                    spriteFound = name
                    break
                end
            end
        end
    end
    if not spriteFound then return false end

    -- Normalize to head square
    local headSquare, headSprite = getPinballHeadSquareAndHeadSprite(square, spriteFound)
    if not headSquare or not headSprite then return false end

    -- Determine tail square from head
    local pair = ProjectArcade_ReplaceVanillaArcades.Config.pinballPairs[headSprite]
    if not pair then return false end

    local tailSquare = headSquare:getCell():getGridSquare(
        headSquare:getX() + pair.tailDx,
        headSquare:getY() + pair.tailDy,
        headSquare:getZ()
    )
    if not tailSquare then return false end

    -- Persist set choice per HEAD square (same idea as arcades)
    local hx, hy, hz = headSquare:getX(), headSquare:getY(), headSquare:getZ()
    local key = getKey(hx, hy, hz)

    local root = getStateRoot()
    local state = root[key] or {}

    local setIdx = state.pinballSet
    if setIdx ~= 1 and setIdx ~= 2 then
        setIdx = choosePinballSetIndex()
        state.pinballSet = setIdx
        root[key] = state
        ModData.add(ProjectArcade_ReplaceVanillaArcades.Config.modDataRoot, root)
        ModData.transmit(ProjectArcade_ReplaceVanillaArcades.Config.modDataRoot)
    end

    -- Compute custom sprites from your table
    local repl = ProjectArcade_ReplaceVanillaArcades.Config.pinballReplacements
    local customHead = repl[headSprite] and repl[headSprite][setIdx] or nil
    local customTail = repl[pair.tailSprite] and repl[pair.tailSprite][setIdx] or nil
    if not customHead or not customTail then
        log("Pinball replacement missing for head/tail. head=" .. tostring(headSprite) .. " tail=" .. tostring(pair.tailSprite))
        return false
    end

    -- Remove vanilla pieces (idempotent)
    removeFirstBySprite(headSquare, headSprite)
    removeFirstBySprite(tailSquare, pair.tailSprite)

    -- Spawn custom pieces
    spawnCustomObject(headSquare, customHead)
    spawnCustomObject(tailSquare, customTail)

    log(string.format("Replaced pinball %s/%s -> %s/%s at %d,%d,%d (set=%d)",
        tostring(headSprite), tostring(pair.tailSprite),
        tostring(customHead), tostring(customTail),
        hx, hy, hz, setIdx
    ))

    return true
end

function ProjectArcade_ReplaceVanillaArcades.onLoadGridsquare(square)
    if not square then return end

    if tryReplaceVanillaPinball(square) then
        return
    end

    local obj = findVanillaArcadeObjectOnSquare(square)

    if not obj then return end

    local spr = obj:getSprite()
    local vanillaName = spr and spr:getName() or nil
    if not vanillaName or not isVanillaArcadeSprite(vanillaName) then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local key = getKey(x, y, z)

    local root = getStateRoot()
    local state = root[key] or {}

    
    local chosenBase = state.base
    if not chosenBase then
        chosenBase = chooseRandomBase()
        state.base = chosenBase
        root[key] = state
        ModData.add(ProjectArcade_ReplaceVanillaArcades.Config.modDataRoot, root)
        ModData.transmit(ProjectArcade_ReplaceVanillaArcades.Config.modDataRoot)
    end

    local facingIndex = getFacingIndexFromVanilla(vanillaName)
    local customSprite = spriteForCustom(chosenBase, facingIndex)

    
    removeObjectFromSquare(square, obj)
    spawnCustomArcade(square, customSprite)

    log(string.format(
        "Replaced %s -> %s at %d,%d,%d (base=%d facing=%d)",
        tostring(vanillaName), tostring(customSprite),
        x, y, z, chosenBase, facingIndex
    ))
end

function ProjectArcade_ReplaceVanillaArcades.init()
    local sb = SandboxVars and SandboxVars.ProjectArcade
    local optArc = sb and sb.ReplaceVanillaArcadesOnLoad
    local optPin = sb and sb.ReplaceVanillaPinballsOnLoad

    if not optArc and not optPin then
        log("Init: Both ReplaceVanillaArcadesOnLoad and ReplaceVanillaPinballsOnLoad are OFF. Not registering LoadGridsquare hook.")
        return
    end

    Events.LoadGridsquare.Add(ProjectArcade_ReplaceVanillaArcades.onLoadGridsquare)
    log("Init: Replacement hook registered (arcades=" .. tostring(optArc) .. ", pinballs=" .. tostring(optPin) .. ").")
end

Events.OnSGlobalObjectSystemInit.Add(ProjectArcade_ReplaceVanillaArcades.init)

log("Script loaded.")
