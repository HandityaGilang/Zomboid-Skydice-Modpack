local TABAS_Iso = {}

local TABAS_Sprites = require("TABAS_Sprites")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function TABAS_Iso.getSpritesTable(k1, k2, k3, k4, k5, k6)
    TABAS_Sprites.ensureIndexes()

    if k1 == nil then return nil end

    local t = TABAS_Sprites
    -- Kahlua's debugger can trip over a numeric for-loop inside a vararg function.
    local keys = { k1, k2, k3, k4, k5, k6 }
    local i = 1
    while i <= 6 do
        local k = keys[i]
        if k == nil then return t end
        if type(t) ~= "table" then return nil end
        t = t[k]
        if t == nil then return nil end
        i = i + 1
    end
    return t
end

 ----------------- For Objects -----------------

 function TABAS_Iso.getBathingObjectFromWorldObjects(worldObjects)
     if not worldObjects then return end
     local square
     for i=1, #worldObjects do
        local wo = worldObjects[i]
         if wo and wo:getSquare() then
             square = wo:getSquare()
             local object, type = TABAS_Iso.findBathingObjectOnSquare(square)
             if object and type then
                 return object, type
             end
         end
     end
 end

function TABAS_Iso.findBathingObjectOnSquare(square)
    if not square then return nil, nil end

    local maps = TABAS_Iso.getSpritesTable("Index", "ModelTypeBySprite")
    if not maps then return nil, nil end

    local types = {"Bathtub", "Shower"}
    for i=1, square:getObjects():size() do
        local object = square:getObjects():get(i-1)
        if not object:isFloor() then
            local spriteName = object:getSpriteName()
            if spriteName then
                for j=1, #types do
                    local type = types[j]
                    local map = maps[type]
                    if map and map[spriteName] ~= nil then
                        return object, type
                    end
                end
            end
        end
    end
    return nil, nil
end

function TABAS_Iso.getObjectFacing(object)
    local props = object:getSprite():getProperties()
    local facing = props:has("Facing") and props:get("Facing") or nil
    if not facing then
        facing = object:getModData().facing
    end
    return facing
end

function TABAS_Iso.isBathObject(object)
    if not object or not instanceof(object, "IsoObject") then return false end
    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    local map = TABAS_Iso.getSpritesTable("Index", "ModelTypeBySprite", "Bathtub")
    return map and (map[spriteName] ~= nil)
end

function TABAS_Iso.isBathFaucet(object)
    if not object or not instanceof(object, "IsoObject") then return false end
    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    local maps = TABAS_Iso.getSpritesTable("Index", "BathPartBySprite")
    return maps and (maps[spriteName] == "faucet")
end

function TABAS_Iso.isBathWithShower(object)
    if not object or not instanceof(object, "IsoObject") then return false end
    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    local maps = TABAS_Iso.getSpritesTable("Index", "BathWithShowerSprite")
    return maps and (maps[spriteName] == true)
end

function TABAS_Iso.isShowerObject(object, allowedOnBath)
    if not object or not instanceof(object, "IsoObject") then return false end
    local spriteName = object:getSpriteName()
    if not spriteName then return false end

    if allowedOnBath and TABAS_Iso.isBathWithShower(object) then
        return true
    end
    local map = TABAS_Iso.getSpritesTable("Index", "ModelTypeBySprite", "Shower")
    return map and (map[spriteName] ~= nil)
end

function TABAS_Iso.isTubFluidContainer(object)
    if not instanceof(object, "FluidContainer") then return false end
    local name = object:getContainerName()
    return name and name == TFC_Utils.FluidContainerName
end


function TABAS_Iso.getBathObjectOnSquare(square)
    for i=1, square:getObjects():size() do
        local object = square:getObjects():get(i-1)
        if TABAS_Iso.isBathObject(object) then
            return object
        end
    end
    return nil
end

function TABAS_Iso.getBathObjectAt(x, y, z)
    local square = getCell():getGridSquare(x, y, z)
    if square then
        return TABAS_Iso.getBathObjectOnSquare(square)
    end
end

function TABAS_Iso.getShowerObjectOnSquare(square, allowedOnBath)
    for i=1, square:getObjects():size() do
        local object = square:getObjects():get(i-1)
        if TABAS_Iso.isShowerObject(object, false) then
            return object
        end
        if allowedOnBath and TABAS_Iso.isBathFaucet(object) then
            return object
        end
    end
    return nil
end

function TABAS_Iso.getShowerObjectAt(x, y, z, allowedOnBath)
    local square = getCell():getGridSquare(x, y, z)
    if square then
        return TABAS_Iso.getShowerObjectOnSquare(square, allowedOnBath)
    end
end

function TABAS_Iso.getSpriteModelType(key, spriteName)
    local maps = TABAS_Iso.getSpritesTable("Index", "ModelTypeBySprite")
    local map = maps and maps[key]
    return map and map[spriteName] or nil
end

function TABAS_Iso.getGridExtensionBath(object, _facing)
    if not TABAS_Iso.isBathObject(object) then return nil, nil end
    local props = object:getProperties()
    local facing = _facing or props:has("Facing") and props:get("Facing")
    local isExtension = props:has("IsGridExtensionTile")
    local dir
    if facing == "S" then
        if isExtension then dir = IsoDirections.N else dir = IsoDirections.S end
    elseif facing == "E" then
        if isExtension then dir = IsoDirections.W else dir = IsoDirections.E end
    elseif facing == "W" then
        if isExtension then dir = IsoDirections.E else dir = IsoDirections.W end
    elseif facing == "N" then
        if isExtension then dir = IsoDirections.S else dir = IsoDirections.N end
    end
    local square = object:getSquare():getAdjacentSquare(dir)
    for i=1, square:getObjects():size() do
        local innerObj = square:getObjects():get(i-1)
        if TABAS_Iso.isBathObject(innerObj) then
            return innerObj, square
        end
    end
    return nil, nil
end

function TABAS_Iso.getFullyBathObject(object)
    local linkedObj = TABAS_Iso.getGridExtensionBath(object)
    if TABAS_Iso.isBathFaucet(object) then
        return object, linkedObj
    else
        return linkedObj, object
    end
end

-- Available in both faucet and tub. (client only) 
function TABAS_Iso.getTfcBaseOnBathObject(object)
    if isServer() then return nil end
    if not TABAS_Iso.isBathObject(object) then return nil end

    local square = object:getSquare()
    if not square then return nil end

    if TABAS_Iso.isBathFaucet(object) then
        return TFC_Utils.getTfcBaseOnClient(square:getX(), square:getY(), square:getZ(), object)
    end
    local mainId = TFC_Utils.getRegisterdIdFromSquare(square, true)
    if mainId then
        local x, y, z = TFC_Utils.getCoordsById(mainId)
        local bathSq = getCell():getGridSquare(x, y, z)
        local bathObj = TABAS_Iso.getBathObjectOnSquare(bathSq)
        if bathObj and TABAS_Iso.isBathFaucet(bathObj) then
            return TFC_Utils.getTfcBaseOnClient(x, y, z, bathObj)
        end
    end
    -- local facing = TABAS_Iso.getObjectFacing(object)
    -- local extObj = facing and TABAS_Iso.getGridExtensionBath(object, facing) or nil
    -- if extObj then
    --     local faucetObj, _ = TABAS_Iso.getFullyBathObject(extObj)
    --     if faucetObj then
    --         local fsq = faucetObj:getSquare()
    --         if fsq then
    --             return TFC_Utils.getTfcBaseOnClient(fsq:getX(), fsq:getY(), fsq:getZ(), faucetObj)
    --         end
    --     end
    -- end
    return nil
end

-- function TABAS_Iso.getHeatSouce(square)
--     if isClient() or not square then return end
--     if not square then return end

--     local objs = square:getObjects()
--     for i=0, objs:size()-1 do
--         local obj = objs:get(i)
--         if instanceof(obj, "IsoHeatSource") and obj:getName() == "TABAS_HeatSource" then
--             return obj
--         end
--     end
-- end

-- function TABAS_Iso.addHeatSource(square, temperature)
--     if isClient() or not square then return end

--     local heatSource = IsoHeatSource.new(square:getX(), square:getY(), square:getZ(), 1, temperature)
--     heatSource:setName("TABAS_HeatSource")
--     square:getCell():addHeatSource(heatSource)
-- end

-- function TABAS_Iso.removeHeatSource(square)
--     if isClient() or not square then return end

--     local heatSource = TABAS_Iso.getHeatSouce(square)
--     if heatSource then
--         square:getCell():removeHeatSource(heatSource)
--     end
-- end

function TABAS_Iso.canHot(object)
    if not SandboxVars.TakeABathAndShower.WaterTemperatureConcept then
        return true
    end
    local square = object:getSquare()
    local roomID = square:getRoomID() or 1
    if roomID > 1 then
        return getWorld():isHydroPowerOn() or square:haveElectricity()
    else
        return square:haveElectricity()
    end
end

return TABAS_Iso
