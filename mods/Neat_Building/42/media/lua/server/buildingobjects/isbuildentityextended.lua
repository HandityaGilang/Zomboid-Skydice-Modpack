ISBuildEntityExtended = {}
local sprites = {}

local function getCursorSprite(type)
    if not sprites[type] then
        sprites[type] = IsoSprite.new()
        sprites[type]:LoadSingleTexture("BuildTileCursor_Floor_" .. type .. "_0")
    end
    return sprites[type]
end

local function getOnlyFloorSprite()
    if not sprites["OnlyFloor"] then
        sprites["OnlyFloor"] = IsoSprite.new()
        sprites["OnlyFloor"]:LoadSingleTexture("BuildTileCursor_OnlyFloor_0")
    end
    return sprites["OnlyFloor"]
end

local function renderEntityEdges(self, x, y, z, square, directions)
    local occupiedTiles = self:getOccupiedTiles(square)
    local occupiedSet = {}
    for _, tile in ipairs(occupiedTiles) do
        local key = tile:getX() .. "," .. tile:getY() .. "," .. tile:getZ()
        occupiedSet[key] = true
    end

    local time = getTimestampMs() % 2000
    local progress = 0.5 + 0.5 * math.sin((time / 2000) * math.pi)
    local alpha = 0.2 + progress * 0.6
    
    local isValid = self:isValid(square)
    local color = isValid and {r = 0.7, g = 0.7, b = 0.9} or {r = 0.9, g = 0.7, b = 0.7}

    for _, tile in ipairs(occupiedTiles) do
        local tileX, tileY, tileZ = tile:getX(), tile:getY(), tile:getZ()

        if directions.north then
            local northKey = tileX .. "," .. (tileY - 1) .. "," .. tileZ
            if not occupiedSet[northKey] then
                local edgeSprite = getCursorSprite("N")
                edgeSprite:RenderGhostTileColor(tileX, tileY, tileZ, color.r, color.g, color.b, alpha)
            end
        end

        if directions.west then
            local westKey = (tileX - 1) .. "," .. tileY .. "," .. tileZ
            if not occupiedSet[westKey] then
                local edgeSprite = getCursorSprite("W")
                edgeSprite:RenderGhostTileColor(tileX, tileY, tileZ, color.r, color.g, color.b, alpha)
            end
        end

        if directions.south then
            local southKey = tileX .. "," .. (tileY + 1) .. "," .. tileZ
            if not occupiedSet[southKey] then
                local edgeSprite = getCursorSprite("S")
                edgeSprite:RenderGhostTileColor(tileX, tileY, tileZ, color.r, color.g, color.b, alpha)
            end
        end

        if directions.east then
            local eastKey = (tileX + 1) .. "," .. tileY .. "," .. tileZ
            if not occupiedSet[eastKey] then
                local edgeSprite = getCursorSprite("E")
                edgeSprite:RenderGhostTileColor(tileX, tileY, tileZ, color.r, color.g, color.b, alpha)
            end
        end
    end
end

-- Check Frame if in square
-- ------------------------------------------------------------
-- B42 compatibility: IsoSpriteProperties API differs between builds.
-- Some builds expose props:has("Key"), older builds expose props:Is("Key").
-- This helper supports both to avoid nil-call errors during placement rendering.
-- ------------------------------------------------------------
local function nb_propsHas(props, key)
    if not props then return false end
    local fn = props.has or props.Is or props.is
    if fn then
        return fn(props, key)
    end
    return false
end

local function hasFrameInSquare(square, north, checkType)
    for i = 0, square:getSpecialObjects():size() - 1 do
        local item = square:getSpecialObjects():get(i)
        if instanceof(item, "IsoThumpable") and item:getNorth() == north then
            if checkType == "window" and item:isWindow() then
                return true
            elseif checkType == "door" and item:isDoorFrame() then
                return true
            end
        end
    end
    
    for i = 0, square:getObjects():size() - 1 do
        local obj = square:getObjects():get(i)
        if instanceof(obj, 'IsoObject') then
            local sprite = obj:getSprite()
            
            if checkType == "window" then
                if (north and sprite and nb_propsHas(sprite:getProperties(), "WindowN")) or (not north and sprite and nb_propsHas(sprite:getProperties(), "WindowW")) then
                    return true
                end
            elseif checkType == "door" then
                if (north and sprite and nb_propsHas(sprite:getProperties(), "DoorWallN")) or (not north and sprite and nb_propsHas(sprite:getProperties(), "DoorWallW")) then
                    return true
                end
            end
        end
    end
    
    return false
end

local function renderMissingFrameIndicator(self, x, y, z, square)
    local frameType = nil
    
    -- Need WallFrame
    if self.previousStages and self.previousStages:size() > 0 then
        local foundPreviousStage = false
        for i = 0, self.previousStages:size() - 1 do
            for j = 0, square:getSpecialObjects():size() - 1 do
                local stageName = string.lower(self.previousStages:get(i))
                local object = square:getSpecialObjects():get(j)
                local objectName = object:getName()
                if objectName and stageName == string.lower(objectName) then
                    if instanceof(object, "IsoThumpable") and object:getNorth() == self.north then
                        foundPreviousStage = true
                        break
                    end
                end
            end
            if foundPreviousStage then
                break
            end
        end
        
        if not foundPreviousStage then
            frameType = "wall"
        end
    end
    
    -- Need WindowFrame
    if not frameType and self.needWindowFrame then
        if not hasFrameInSquare(square, self.north, "window") then
            frameType = "window"
        end
    end
    
    -- Need DoorFrame
    if not frameType and not self.dontNeedFrame then
        local face = self:getFace()
        if face then
            local tileInfo = face:getTileInfo(0, 0, 0)
            if tileInfo and tileInfo:getSpriteName() then
                local sprite = getSprite(tileInfo:getSpriteName())
                local isDoor = sprite and (sprite:getType() == IsoObjectType.doorW or sprite:getType() == IsoObjectType.doorN)

                if isDoor and not hasFrameInSquare(square, self.north, "door") then
                    frameType = "door"
                end
            end
        end
    end
 
    if not frameType then return end

    local face = self:getFace()
    local faceName = face:getFaceName()
    local spriteType = nil
    
    if frameType == "wall" then
        spriteType = (faceName == "w") and "MissFrame_Wall_W_0" or "MissFrame_Wall_N_0"
    elseif frameType == "window" then
        spriteType = (faceName == "w" or not self.north) and "MissFrame_Window_W_0" or "MissFrame_Window_N_0"
    elseif frameType == "door" then
        spriteType = (faceName == "w" or not self.north) and "MissFrame_Door_W_0" or "MissFrame_Door_N_0"
    end
    
    if spriteType then
        if not sprites[spriteType] then
            sprites[spriteType] = IsoSprite.new()
            sprites[spriteType]:LoadSingleTexture(spriteType)
        end
        
        local time = getTimestampMs() % 2000
        local progress = 0.5 + 0.5 * math.sin((time / 2000) * math.pi)
        local alpha = 0.1 + progress * 0.9
        
        sprites[spriteType]:RenderGhostTileColor(x, y, z, 0.9, 0.7, 0.7, alpha)
    end
end

local original_ISBuildIsoEntityRender = nil
if not original_ISBuildIsoEntityRender then 
    original_ISBuildIsoEntityRender = ISBuildIsoEntity.render
end

ISBuildIsoEntity.render = function(self, x, y, z, square)

    renderEntityEdges(self, x, y, z, square, {north = true, west = true, south = false, east = false})

    original_ISBuildIsoEntityRender(self, x, y, z, square)

    renderEntityEdges(self, x, y, z, square, {north = false, west = false, south = true, east = true})

    renderMissingFrameIndicator(self, x, y, z, square)
end

local original_ISBuildIsoEntityRenderFloorGrid = nil
if not original_ISBuildIsoEntityRenderFloorGrid then 
    original_ISBuildIsoEntityRenderFloorGrid = ISBuildIsoEntity.renderFloorGrid
end

function ISBuildIsoEntity:renderFloorGrid(x, y, z)
    if not self.drawFloorGrid then return end
    
    local onlyFloorSprite = getOnlyFloorSprite()
    local square = getCell():getGridSquare(x, y, z)
    if not square then return end

    local occupiedTiles = self:getOccupiedTiles(square)
    if not occupiedTiles or #occupiedTiles == 0 then return end

    local time = getTimestampMs() % 2000
    local progress = 0.5 + 0.5 * math.sin((time / 2000) * math.pi)
    local alpha = 0.3 + progress * 0.7

    local isValid = self:isValid(square)
    local color = isValid and {r = 0.7, g = 0.7, b = 0.9} or {r = 0.9, g = 0.7, b = 0.7}

    for _, tile in ipairs(occupiedTiles) do
        local tileX, tileY, tileZ = tile:getX(), tile:getY(), tile:getZ()
        onlyFloorSprite:RenderGhostTileColor(tileX, tileY, tileZ, color.r, color.g, color.b, alpha)
    end
end