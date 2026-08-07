require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_Storage"

GIPT.ADMIN_LARGE_TANK_FAMILIES = {
    [0] = { label = "Blue", cabinetE = 64, cabinetS = 65 },
    [1] = { label = "Red", cabinetE = 66, cabinetS = 67 },
    [2] = { label = "Green", cabinetE = 68, cabinetS = 69 },
    [3] = { label = "Weathered", cabinetE = 70, cabinetS = 71 },
}

local function spriteName(index)
    return GIPT.SPRITE_PREFIX .. tostring(index)
end

function GIPT.canUseAdminInstallationPlacement(player)
    if not player then return false end
    if isMultiplayer() then return GIPT.isAdmin(player) end

    local developerAccess = false
    if isDebugEnabled then
        local ok, value = pcall(isDebugEnabled)
        developerAccess = ok and value == true
    end
    if developerAccess then return true end

    if player.isBuildCheat then
        local ok, value = pcall(function() return player:isBuildCheat() end)
        if ok and value then return true end
    end
    return false
end

-- E is the 2 x 4 tank grid with the cabinet on its south end.
-- S is the 4 x 2 tank grid with the cabinet on its east end.
function GIPT.getAdminLargeInstallationLayout(x, y, z, family, orientation)
    family = math.floor(tonumber(family) or -1)
    local familyInfo = GIPT.ADMIN_LARGE_TANK_FAMILIES[family]
    if not familyInfo then return nil end
    orientation = orientation == "S" and "S" or "E"

    local pieces = {}
    if orientation == "E" then
        for gridX = 0, 1 do
            for gridY = 0, 3 do
                local index = family * 16 + gridX * 4 + (3 - gridY)
                table.insert(pieces, {
                    x = x + gridX,
                    y = y + gridY,
                    z = z,
                    spriteIndex = index,
                    spriteName = spriteName(index),
                    role = "tank",
                })
            end
        end
        table.insert(pieces, {
            x = x,
            y = y + 4,
            z = z,
            spriteIndex = familyInfo.cabinetE,
            spriteName = spriteName(familyInfo.cabinetE),
            role = "cabinet",
        })
        return {
            family = family,
            orientation = orientation,
            anchorX = x,
            anchorY = y,
            z = z,
            width = 2,
            height = 5,
            pieces = pieces,
        }
    end

    for gridY = 0, 1 do
        for gridX = 0, 3 do
            local index = family * 16 + 8 + gridY * 4 + gridX
            table.insert(pieces, {
                x = x + gridX,
                y = y + gridY,
                z = z,
                spriteIndex = index,
                spriteName = spriteName(index),
                role = "tank",
            })
        end
    end
    table.insert(pieces, {
        x = x + 4,
        y = y,
        z = z,
        spriteIndex = familyInfo.cabinetS,
        spriteName = spriteName(familyInfo.cabinetS),
        role = "cabinet",
    })
    return {
        family = family,
        orientation = orientation,
        anchorX = x,
        anchorY = y,
        z = z,
        width = 5,
        height = 2,
        pieces = pieces,
    }
end

local function objectBlocksAdminPlacement(square, object)
    if not object then return false end
    if square:getFloor() == object then return false end
    if instanceof(object, "IsoWorldInventoryObject") then return false end

    local properties = object.getProperties and object:getProperties()
    if properties and properties:has(IsoFlagType.canBeRemoved) then return false end
    return true
end

function GIPT.isAdminInstallationSquareClear(square)
    if not square or not square:getFloor() then return false end
    if square:has(IsoFlagType.water) then return false end
    if square:isVehicleIntersecting() then return false end
    if not square:isFreeOrMidair(true) then return false end

    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        if objectBlocksAdminPlacement(square, objects:get(i)) then return false end
    end
    return true
end

function GIPT.validateAdminLargeInstallation(x, y, z, family, orientation)
    local layout = GIPT.getAdminLargeInstallationLayout(x, y, z, family, orientation)
    if not layout then return false, "Unknown tank style." end

    for _, piece in ipairs(layout.pieces) do
        local square = getCell():getGridSquare(piece.x, piece.y, piece.z)
        if not GIPT.isAdminInstallationSquareClear(square) then
            return false, string.format("The installation footprint is blocked at %d, %d.", piece.x, piece.y)
        end
        if not getSprite(piece.spriteName) then
            return false, "A required industrial-tank sprite is unavailable."
        end
    end
    return true, nil, layout
end

local function removePlacedObject(object)
    local square = object and object:getSquare()
    if not square then return end
    if isServer() and square.transmitRemoveItemFromSquareOnClients then
        pcall(function() square:transmitRemoveItemFromSquareOnClients(object) end)
    end
    pcall(function() square:RemoveTileObject(object) end)
    pcall(function() square:RecalcProperties() end)
    pcall(function() square:RecalcAllWithNeighbours(true) end)
end

local function placeMoveablePiece(piece)
    require "Moveables/ISMoveableSpriteProps"
    local square = getCell():getGridSquare(piece.x, piece.y, piece.z)
    local sprite = getSprite(piece.spriteName)
    if not square or not sprite then return nil end

    local props = ISMoveableSpriteProps.new(sprite)
    if not props or not props.isMoveable then return nil end
    local item = props:instanceItem(piece.spriteName)
    if not item then return nil end
    return props:placeMoveableInternal(square, item, piece.spriteName)
end

function GIPT.placeAdminLargeInstallation(x, y, z, family, orientation)
    if isClient() then return false, "Installation placement must be performed by the server." end

    local valid, reason, layout = GIPT.validateAdminLargeInstallation(x, y, z, family, orientation)
    if not valid then return false, reason end

    local placed = {}
    for _, piece in ipairs(layout.pieces) do
        local object = placeMoveablePiece(piece)
        if not object then
            for i = #placed, 1, -1 do removePlacedObject(placed[i]) end
            return false, "The installation could not be completed and was rolled back."
        end
        local md = object:getModData()
        md.GIPT_AdminPlaced = true
        table.insert(placed, object)
        if buildUtil and buildUtil.setHaveConstruction then
            pcall(function() buildUtil.setHaveConstruction(object:getSquare(), true) end)
        end
    end

    local controller, installationID = GIPT.ensureInstallation(layout.anchorX, layout.anchorY, layout.z)
    if not controller then
        for i = #placed, 1, -1 do removePlacedObject(placed[i]) end
        return false, "The tank controller could not be initialised and placement was rolled back."
    end

    local data = GIPT.ensureTankData(controller)
    data = GIPT.setTankFluid(data, GIPT.FLUID_EMPTY, 0, controller) or data
    GIPT.syncGasolineCabinets(controller, data)

    for _, object in ipairs(placed) do
        local md = object:getModData()
        md.GIPT_AdminPlaced = true
        if object.transmitModData then pcall(function() object:transmitModData() end) end
    end
    if controller.transmitModData then pcall(function() controller:transmitModData() end) end

    return true, "Complete large tank installation placed empty.", controller, installationID
end
