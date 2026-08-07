require "GIPT/GIPT_Constants"

local CARDINAL = { {-1, 0}, {1, 0}, {0, -1}, {0, 1} }
local STORAGE_FIELDS = { "fluidType", "amount", "capacity", "initialized", "playerSupplied" }

local function objectAtSquare(square, predicate)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if predicate(obj) then return obj end
    end
    return nil
end

local function addUnique(list, seen, obj)
    if not obj then return end
    local key = tostring(obj)
    if seen[key] then return end
    seen[key] = true
    table.insert(list, obj)
end

function GIPT.findPropaneObject(square, wantedClass, wantedRole)
    return objectAtSquare(square, function(obj)
        local role = GIPT.getObjectRole(obj)
        if not role then return false end
        if wantedClass and GIPT.getTankClass(obj) ~= wantedClass then return false end
        if wantedRole and role ~= wantedRole then return false end
        return true
    end)
end

function GIPT.hasPropaneObject(square, wantedClass, wantedRole)
    return GIPT.findPropaneObject(square, wantedClass, wantedRole) ~= nil
end

local function findObjectBySpriteIndex(square, wantedIndex)
    return objectAtSquare(square, function(obj)
        local sprite = obj and obj:getSprite()
        return sprite and GIPT.getSpriteIndex(sprite:getName()) == wantedIndex
    end)
end

local function findObjectBySpriteName(square, wantedName)
    if not wantedName then return nil end
    return objectAtSquare(square, function(obj)
        local sprite = obj and obj:getSprite()
        return sprite and sprite:getName() == wantedName
    end)
end

local function largeAnchorFromObject(obj)
    local info = GIPT.getLargeTankSpriteInfo(obj)
    local square = obj and obj:getSquare()
    if not info or not square then return nil end
    return {
        anchorX = square:getX() - info.gridX,
        anchorY = square:getY() - info.gridY,
        z = square:getZ(),
        family = info.family,
        spriteGrid = info.spriteGrid,
        width = info.width or 4,
        height = info.height or 4,
    }
end

local function largeKey(anchorX, anchorY, z, family)
    return tostring(anchorX) .. ":" .. tostring(anchorY) .. ":" .. tostring(z) .. ":" .. tostring(family)
end

local function expectedLargeIndex(family, gridX, gridY)
    return family * 16 + gridX * 4 + (3 - gridY)
end

local function collectLargeTankTiles(anchorX, anchorY, z, family, spriteGrid, width, height)
    local found, seen = {}, {}
    width, height = tonumber(width) or 4, tonumber(height) or 4
    for gridX = 0, width - 1 do
        for gridY = 0, height - 1 do
            local square = getCell():getGridSquare(anchorX + gridX, anchorY + gridY, z)
            local obj
            if spriteGrid and spriteGrid.getSprite then
                local ok, expectedSprite = pcall(function() return spriteGrid:getSprite(gridX, gridY) end)
                local expectedName = ok and expectedSprite and expectedSprite:getName()
                obj = findObjectBySpriteName(square, expectedName)
            end
            if not obj and width == 4 and height == 4 then
                obj = findObjectBySpriteIndex(square, expectedLargeIndex(family, gridX, gridY))
            end
            addUnique(found, seen, obj)
        end
    end
    return found
end

local function cabinetOwnerCandidates(cabinet)
    local square = cabinet and cabinet:getSquare()
    if not square then return {} end
    local candidates = {}
    for _, offset in ipairs(CARDINAL) do
        local near = getCell():getGridSquare(square:getX() + offset[1], square:getY() + offset[2], square:getZ())
        local tankTile = GIPT.findPropaneObject(near, "LARGE", "tankTile")
        if tankTile then
            local anchor = largeAnchorFromObject(tankTile)
            if anchor then
                local key = largeKey(anchor.anchorX, anchor.anchorY, anchor.z, anchor.family)
                local candidate = candidates[key]
                if not candidate then
                    candidate = anchor
                    candidate.key = key
                    candidate.contacts = 0
                    candidates[key] = candidate
                end
                candidate.contacts = candidate.contacts + 1
            end
        end
    end
    local out = {}
    for _, candidate in pairs(candidates) do table.insert(out, candidate) end
    return out
end

function GIPT.getCabinetOwner(cabinet)
    if GIPT.getObjectRole(cabinet) ~= "dispenser" then return nil end
    local candidates = cabinetOwnerCandidates(cabinet)
    local md = cabinet:getModData()
    local data = md and md.GIPT

    -- A cabinet only belongs to a tank while it is physically touching one.
    -- Never follow saved controller coordinates after either piece is moved.
    if #candidates == 0 then return nil end

    if data and data.tankFamily ~= nil and data.controllerX ~= nil then
        local preferred = largeKey(data.controllerX, data.controllerY, data.controllerZ, data.tankFamily)
        for _, candidate in ipairs(candidates) do
            if candidate.key == preferred then return candidate end
        end
    end

    local square = cabinet:getSquare()
    table.sort(candidates, function(a, b)
        if a.contacts ~= b.contacts then return a.contacts > b.contacts end
        local acx, acy = a.anchorX + ((a.width or 4) - 1) / 2, a.anchorY + ((a.height or 4) - 1) / 2
        local bcx, bcy = b.anchorX + ((b.width or 4) - 1) / 2, b.anchorY + ((b.height or 4) - 1) / 2
        local ad = (square:getX() - acx) ^ 2 + (square:getY() - acy) ^ 2
        local bd = (square:getX() - bcx) ^ 2 + (square:getY() - bcy) ^ 2
        if ad ~= bd then return ad < bd end
        return a.key < b.key
    end)
    return candidates[1]
end

local function collectLargeCabinets(anchorX, anchorY, z, family, width, height)
    local found, seen = {}, {}
    width, height = tonumber(width) or 4, tonumber(height) or 4
    for x = anchorX - 1, anchorX + width do
        for y = anchorY - 1, anchorY + height do
            local onPerimeter = x == anchorX - 1 or x == anchorX + width or y == anchorY - 1 or y == anchorY + height
            if onPerimeter then
                local square = getCell():getGridSquare(x, y, z)
                if square then
                    local objects = square:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if GIPT.getObjectRole(obj) == "dispenser" then
                            local owner = GIPT.getCabinetOwner(obj)
                            if owner and owner.anchorX == anchorX and owner.anchorY == anchorY and owner.z == z and owner.family == family then
                                addUnique(found, seen, obj)
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

local SMALL_INFO = {
    -- World offsets follow the two Melos sprite assemblies: 72/73 runs north,
    -- while 74/75 runs east. Installation IDs keep touching pairs independent.
    [72] = { lead = 72, partner = 73, dx = 0, dy = -1, tag = "72_73" },
    [73] = { lead = 72, partner = 72, dx = 0, dy = 1, tag = "72_73" },
    [74] = { lead = 74, partner = 75, dx = 1, dy = 0, tag = "74_75" },
    [75] = { lead = 74, partner = 74, dx = -1, dy = 0, tag = "74_75" },
}

local function findSmallPartner(clicked, info)
    local square = clicked and clicked:getSquare()
    if not square or not info then return nil end

    local preferredSquare = getCell():getGridSquare(square:getX() + info.dx, square:getY() + info.dy, square:getZ())
    local preferred = findObjectBySpriteIndex(preferredSquare, info.partner)
    if preferred then return preferred end

    local clickedData = clicked:getModData() and clicked:getModData().GIPT
    for _, offset in ipairs(CARDINAL) do
        local near = getCell():getGridSquare(square:getX() + offset[1], square:getY() + offset[2], square:getZ())
        local candidate = findObjectBySpriteIndex(near, info.partner)
        if candidate then
            local candidateData = candidate:getModData() and candidate:getModData().GIPT
            if clickedData and candidateData and clickedData.installationID and clickedData.installationID == candidateData.installationID then
                return candidate
            end
        end
    end
    -- Do not attach an incomplete tank to an arbitrary neighbouring tank.
    return nil
end

local function describeSmall(clicked)
    local square = clicked and clicked:getSquare()
    local sprite = clicked and clicked:getSprite()
    local index = sprite and GIPT.getSpriteIndex(sprite:getName())
    local info = index and SMALL_INFO[index]
    if not square or not info then return nil end

    local partner = findSmallPartner(clicked, info)
    local lead = index == info.lead and clicked or partner
    if not lead then lead = clicked end
    local leadSquare = lead:getSquare()
    local objects, seen = {}, {}
    addUnique(objects, seen, lead)
    addUnique(objects, seen, partner)
    return {
        tankClass = "SMALL",
        anchorX = leadSquare:getX(),
        anchorY = leadSquare:getY(),
        z = leadSquare:getZ(),
        pairTag = info.tag,
        objects = objects,
        controller = lead,
    }
end

local function describeLarge(clicked)
    local role = GIPT.getObjectRole(clicked)
    local square = clicked and clicked:getSquare()
    if not square then return nil end

    local anchor
    if role == "tankTile" then
        anchor = largeAnchorFromObject(clicked)
    elseif role == "dispenser" then
        anchor = GIPT.getCabinetOwner(clicked)
        if not anchor then
            return {
                tankClass = "LARGE",
                anchorX = square:getX(),
                anchorY = square:getY(),
                z = square:getZ(),
                family = nil,
                standaloneCabinet = true,
                objects = { clicked },
                controller = clicked,
            }
        end
    end
    if not anchor then return nil end

    local objects, seen = {}, {}
    local tankTiles = collectLargeTankTiles(anchor.anchorX, anchor.anchorY, anchor.z, anchor.family, anchor.spriteGrid, anchor.width, anchor.height)
    for _, obj in ipairs(tankTiles) do addUnique(objects, seen, obj) end
    local cabinets = collectLargeCabinets(anchor.anchorX, anchor.anchorY, anchor.z, anchor.family, anchor.width, anchor.height)
    for _, obj in ipairs(cabinets) do addUnique(objects, seen, obj) end

    local controllerSquare = getCell():getGridSquare(anchor.anchorX, anchor.anchorY, anchor.z)
    local controller
    if anchor.spriteGrid and anchor.spriteGrid.getSprite then
        local ok, anchorSprite = pcall(function() return anchor.spriteGrid:getSprite(0, 0) end)
        controller = findObjectBySpriteName(controllerSquare, ok and anchorSprite and anchorSprite:getName())
    end
    if not controller then
        controller = findObjectBySpriteIndex(controllerSquare, expectedLargeIndex(anchor.family, 0, 0))
    end
    if not controller then
        for _, obj in ipairs(tankTiles) do
            if not controller then
                controller = obj
            else
                local a, b = obj:getSquare(), controller:getSquare()
                if a:getX() < b:getX() or (a:getX() == b:getX() and a:getY() < b:getY()) then controller = obj end
            end
        end
    end
    controller = controller or clicked

    return {
        tankClass = "LARGE",
        anchorX = anchor.anchorX,
        anchorY = anchor.anchorY,
        z = anchor.z,
        family = anchor.family,
        objects = objects,
        controller = controller,
    }
end

function GIPT.getInstallationDescriptor(x, y, z)
    local clicked = GIPT.findPropaneObject(getCell():getGridSquare(x, y, z))
    if not clicked then return nil end
    if GIPT.getTankClass(clicked) == "SMALL" then return describeSmall(clicked) end
    return describeLarge(clicked)
end

function GIPT.collectConnectedObjects(x, y, z)
    local descriptor = GIPT.getInstallationDescriptor(x, y, z)
    return descriptor and descriptor.objects or {}
end

function GIPT.findGroupAnchor(x, y, z)
    local descriptor = GIPT.getInstallationDescriptor(x, y, z)
    if not descriptor then return x, y end
    return descriptor.anchorX, descriptor.anchorY
end

local function installationID(descriptor)
    if descriptor.tankClass == "SMALL" then
        return "GIPT_SMALL_" .. tostring(descriptor.pairTag or "SINGLE") .. "_" .. descriptor.anchorX .. "_" .. descriptor.anchorY .. "_" .. descriptor.z
    end
    if descriptor.standaloneCabinet then
        return "GIPT_LARGE_CABINET_" .. descriptor.anchorX .. "_" .. descriptor.anchorY .. "_" .. descriptor.z
    end
    return "GIPT_LARGE_" .. tostring(descriptor.family) .. "_" .. descriptor.anchorX .. "_" .. descriptor.anchorY .. "_" .. descriptor.z
end

local function storageRank(obj, controller)
    local data = obj:getModData() and obj:getModData().GIPT
    if not data then return -1 end
    local amount = tonumber(data.amount) or 0
    if obj == controller and amount > 0 then return 40 end
    if amount > 0 then return 30 end
    if obj == controller and data.initialized then return 20 end
    if data.initialized or data.amount ~= nil or data.fluidType ~= nil then return 10 end
    return -1
end

local function copyStorage(source, target)
    if not source or not target then return end
    for _, field in ipairs(STORAGE_FIELDS) do target[field] = source[field] end
end

local function clearStorage(data)
    for _, field in ipairs(STORAGE_FIELDS) do data[field] = nil end
end

local function setValue(data, key, value)
    if data[key] == value then return false end
    data[key] = value
    return true
end

function GIPT.ensureInstallation(x, y, z)
    local descriptor = GIPT.getInstallationDescriptor(x, y, z)
    if not descriptor or not descriptor.controller then return nil end
    local id = installationID(descriptor)

    local source, sourceRank = nil, -1
    for _, obj in ipairs(descriptor.objects) do
        local rank = storageRank(obj, descriptor.controller)
        if rank > sourceRank then source, sourceRank = obj, rank end
    end

    local controllerData = descriptor.controller:getModData()
    controllerData.GIPT = controllerData.GIPT or {}
    if source and source ~= descriptor.controller then
        copyStorage(source:getModData().GIPT, controllerData.GIPT)
    end

    for _, obj in ipairs(descriptor.objects) do
        local md = obj:getModData()
        md.GIPT = md.GIPT or {}
        local data = md.GIPT
        local changed = false
        changed = setValue(data, "version", GIPT.VERSION) or changed
        changed = setValue(data, "installationID", id) or changed
        changed = setValue(data, "tankClass", descriptor.tankClass) or changed
        changed = setValue(data, "controllerX", descriptor.controller:getX()) or changed
        changed = setValue(data, "controllerY", descriptor.controller:getY()) or changed
        changed = setValue(data, "controllerZ", descriptor.controller:getZ()) or changed
        changed = setValue(data, "role", obj == descriptor.controller and "controller" or GIPT.getObjectRole(obj)) or changed
        changed = setValue(data, "tankFamily", descriptor.family) or changed
        changed = setValue(data, "smallPair", descriptor.pairTag) or changed
        changed = setValue(data, "standaloneCabinet", descriptor.standaloneCabinet == true) or changed
        if obj ~= descriptor.controller then
            local hadStorage = data.amount ~= nil or data.fluidType ~= nil or data.capacity ~= nil or data.initialized ~= nil
            clearStorage(data)
            changed = hadStorage or changed
        end
        if changed and obj.transmitModData and not isClient() then
            pcall(function() obj:transmitModData() end)
        end
    end

    return descriptor.controller, id, descriptor.objects
end

function GIPT.resolveTankObject(x, y, z)
    -- Always recalculate the installation. This makes cabinet-first and tank-first
    -- placement equivalent, and discards stale links after a small tank is moved.
    return GIPT.ensureInstallation(x, y, z)
end

function GIPT.distanceOkay(player, x, y, z)
    if not player or player:getZ() ~= z then return false end
    local maxDist = 3
    if SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.InteractionDistance then
        maxDist = tonumber(SandboxVars.GIPT.InteractionDistance) or maxDist
    end
    local dx, dy = player:getX() - x, player:getY() - y
    return dx * dx + dy * dy <= maxDist * maxDist
end
