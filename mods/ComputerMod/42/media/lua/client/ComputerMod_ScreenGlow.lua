ComputerModScreenGlow = ComputerModScreenGlow or {}
ComputerModScreenGlow.lights = ComputerModScreenGlow.lights or {}
ComputerModScreenGlow.objects = ComputerModScreenGlow.objects or setmetatable({}, {__mode = "k"})

local glowR = 0.02
local glowG = 0.38
local glowB = 0.10
local glowRadius = 2

local computerSprites = {
    appliances_com_01_72 = true,
    appliances_com_01_73 = true,
    appliances_com_01_74 = true,
    appliances_com_01_75 = true,
    appliances_com_01_76 = true,
    appliances_com_01_77 = true,
    appliances_com_01_78 = true,
    appliances_com_01_79 = true
}

local computerScreenOnSprites = {
    appliances_com_01_76 = true,
    appliances_com_01_77 = true,
    appliances_com_01_78 = true,
    appliances_com_01_79 = true
}

local function getSpriteName(object)
    local sprite = object and object.getSprite and object:getSprite() or nil
    return sprite and sprite.getName and sprite:getName() or nil
end

local function isComputerObject(object)
    local spriteName = getSpriteName(object)
    local key = spriteName and string.lower(tostring(spriteName)) or ""
    return computerSprites[key] == true
end

local function getObjectKey(object)
    local data = object and object.getModData and object:getModData() or nil
    if data and data.ComputerModMachineID and tostring(data.ComputerModMachineID) ~= "" then
        return "id:" .. tostring(data.ComputerModMachineID)
    end
    local square = object and object.getSquare and object:getSquare() or nil
    if square then
        return "sq:" .. tostring(square:getX()) .. ":" .. tostring(square:getY()) .. ":" .. tostring(square:getZ())
    end
    return nil
end

local function getSquareKey(square)
    if not square then return nil end
    return "sq:" .. tostring(square:getX()) .. ":" .. tostring(square:getY()) .. ":" .. tostring(square:getZ())
end

local function markSquareDirty(square)
    if not square then return end
    if square.setRecalcLightTime then
        pcall(function() square:setRecalcLightTime(-1) end)
    end
    if square.RecalcAllWithNeighbours then
        pcall(function() square:RecalcAllWithNeighbours(true) end)
    end
end

function ComputerModScreenGlow.removeObject(objectOrKey, forgetObject)
    local registeredKey = type(objectOrKey) ~= "string" and ComputerModScreenGlow.objects[objectOrKey] or nil
    if forgetObject == true and type(objectOrKey) ~= "string" then
        ComputerModScreenGlow.objects[objectOrKey] = nil
    end
    local key = type(objectOrKey) == "string" and objectOrKey or getObjectKey(objectOrKey) or registeredKey
    if not key then return end
    local entry = ComputerModScreenGlow.lights[key]
    if not entry then return end
    if entry.light then
        if entry.light.setActive then
            pcall(function() entry.light:setActive(false) end)
        end
        local cell = getCell and getCell() or nil
        if cell and cell.removeLamppost then
            pcall(function() cell:removeLamppost(entry.light) end)
        end
    end
    ComputerModScreenGlow.lights[key] = nil
    markSquareDirty(entry.square)
end

local function buildLight(square)
    if not square or not IsoLightSource or not IsoLightSource.new then return nil end
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local ok, light = pcall(function() return IsoLightSource.new(x, y, z, glowR, glowG, glowB, glowRadius) end)
    if ok and light then return light end
    ok, light = pcall(function() return IsoLightSource.new(x, y, z, glowR, glowG, glowB, glowRadius, 100000) end)
    if ok and light then return light end
    ok, light = pcall(function() return IsoLightSource.new(x, y, z, glowR, glowG, glowB, glowRadius, 0) end)
    if ok and light then return light end
    return nil
end

function ComputerModScreenGlow.addObject(object)
    if not object or not isComputerObject(object) then return false end
    local key = getObjectKey(object)
    local square = object.getSquare and object:getSquare() or nil
    if not key or not square then return false end
    local squareKey = getSquareKey(square)
    if squareKey and squareKey ~= key then
        ComputerModScreenGlow.removeObject(squareKey)
    end
    local existing = ComputerModScreenGlow.lights[key]
    if existing and existing.x == square:getX() and existing.y == square:getY() and existing.z == square:getZ() then
        return true
    end
    ComputerModScreenGlow.removeObject(key)
    local light = buildLight(square)
    if not light then return false end
    local cell = getCell and getCell() or nil
    if not cell or not cell.addLamppost then return false end
    local ok = pcall(function() cell:addLamppost(light) end)
    if not ok then return false end
    if light.setActive then
        pcall(function() light:setActive(true) end)
    end
    ComputerModScreenGlow.lights[key] = {
        light = light,
        square = square,
        x = square:getX(),
        y = square:getY(),
        z = square:getZ()
    }
    markSquareDirty(square)
    return true
end

function ComputerModScreenGlow.syncObject(object, forcePowerOn)
    if not object then return end
    if not isComputerObject(object) then
        ComputerModScreenGlow.removeObject(object, true)
        return
    end
    local objectKey = getObjectKey(object)
    if objectKey then
        ComputerModScreenGlow.objects[object] = objectKey
    end
    local data = object.getModData and object:getModData() or nil
    if data and data.ComputerModNetworkTerminal == true then
        ComputerModScreenGlow.removeObject(object, true)
        return
    end
    local powerOn = forcePowerOn
    if powerOn == nil and data and data.ComputerModPowerOn ~= nil then
        powerOn = data and data.ComputerModPowerOn == true
    end
    if powerOn == nil then
        local spriteName = getSpriteName(object)
        local key = spriteName and string.lower(tostring(spriteName)) or ""
        powerOn = computerScreenOnSprites[key] == true
    end
    if powerOn == true then
        ComputerModScreenGlow.addObject(object)
    else
        ComputerModScreenGlow.removeObject(object)
    end
end

function ComputerModScreenGlow.syncSquare(square)
    if not square or not square.getObjects then return end
    local objects = square:getObjects()
    if not objects then return end
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        if isComputerObject(object) then
            ComputerModScreenGlow.syncObject(object)
        end
    end
end

function ComputerModScreenGlow.syncKnownComputers()
    local activeKeys = {}
    for object, storedKey in pairs(ComputerModScreenGlow.objects) do
        local square = object and object.getSquare and object:getSquare() or nil
        if square and isComputerObject(object) then
            ComputerModScreenGlow.syncObject(object)
            local currentKey = getObjectKey(object)
            if currentKey then
                ComputerModScreenGlow.objects[object] = currentKey
                activeKeys[currentKey] = true
            end
        else
            ComputerModScreenGlow.objects[object] = nil
            if storedKey then
                ComputerModScreenGlow.removeObject(storedKey)
            end
        end
    end
    for key in pairs(ComputerModScreenGlow.lights) do
        if not activeKeys[key] then
            ComputerModScreenGlow.removeObject(key)
        end
    end
end

function ComputerModScreenGlow.onObjectAdded(object)
    ComputerModScreenGlow.syncObject(object)
end

function ComputerModScreenGlow.onObjectRemoved(object)
    ComputerModScreenGlow.removeObject(object, true)
end

if not ComputerModScreenGlow.eventsInstalled then
    ComputerModScreenGlow.eventsInstalled = true
    if Events.LoadGridsquare then
        Events.LoadGridsquare.Add(ComputerModScreenGlow.syncSquare)
    end
    if Events.OnObjectAdded then
        Events.OnObjectAdded.Add(ComputerModScreenGlow.onObjectAdded)
    end
    if Events.OnObjectAboutToBeRemoved then
        Events.OnObjectAboutToBeRemoved.Add(ComputerModScreenGlow.onObjectRemoved)
    end
    if Events.EveryTenMinutes then
        Events.EveryTenMinutes.Add(ComputerModScreenGlow.syncKnownComputers)
    elseif Events.EveryOneMinute then
        Events.EveryOneMinute.Add(ComputerModScreenGlow.syncKnownComputers)
    end
end
