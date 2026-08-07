require "BasementBuilder/BasementBuilder_Core"
require "Farming/SFarmingSystem"
require "RainBarrel/SRainBarrelSystem"
require "Camping/SCampfireSystem"

BasementBuilder_EnvironmentServer = BasementBuilder_EnvironmentServer or {}

local bbEnvServer = BasementBuilder_EnvironmentServer

local function bbEnvServerLog(message)
    -- print("[BasementBuilder][Env][Server] " .. tostring(message))
end

local function forceExteriorFromSquare(luaObject)
    if not luaObject or not luaObject.getSquare then
        return
    end

    local square = luaObject:getSquare()
    if not square then
        return
    end

    if BasementBuilder.isBasementSquare(square) then
        luaObject.exterior = false
    else
        luaObject.exterior = square:isOutside()
    end
end

function bbEnvServer.patchRainBarrels()
    if bbEnvServer.rainBarrelsPatched or not SRainBarrelSystem then
        return
    end

    SRainBarrelSystem.checkRain = function(self)
        if not RainManager.isRaining() then
            return
        end

        for i = 1, self:getLuaObjectCount() do
            local luaObject = self:getLuaObjectByIndex(i)
            if luaObject and luaObject.waterAmount < luaObject.waterMax then
                local square = luaObject:getSquare()
                local isExterior = false
                if square and not BasementBuilder.isBasementSquare(square) then
                    isExterior = square:isOutside()
                end
                luaObject.exterior = isExterior
                if square and BasementBuilder.isBasementSquare(square) then
                    bbEnvServerLog("rain barrel skip fill at " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()))
                end
                if isExterior then
                    local addAmount = 1 * RainCollectorBarrel.waterScale
                    luaObject.waterAmount = math.min(luaObject.waterMax, luaObject.waterAmount + addAmount)
                    luaObject.taintedWater = true
                    local isoObject = luaObject:getIsoObject()
                    if isoObject then
                        self:noise('added rain to barrel at '..luaObject.x..","..luaObject.y..","..luaObject.z..' waterAmount='..luaObject.waterAmount)
                        isoObject:addFluid(FluidType.TaintedWater, addAmount)
                        isoObject:transmitModData()
                    end
                end
            end
        end
    end

    bbEnvServer.rainBarrelsPatched = true
end

function bbEnvServer.onWaterAmountChange(object, prevAmount)
    if not object then
        return
    end

    local square = object:getSquare()
    if not square or not BasementBuilder.isBasementSquare(square) then
        return
    end

    local prev = prevAmount or 0
    local current = object:getFluidAmount()
    if current <= prev then
        return
    end

    bbEnvServerLog("revert rain barrel fill at " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()) .. " " .. tostring(prev) .. " -> " .. tostring(current))

    object:emptyFluid()
    if prev > 0 then
        if object:isTaintedWater() then
            object:addFluid(FluidType.TaintedWater, prev)
        else
            object:addFluid(FluidType.Water, prev)
        end
    end
    object:transmitModData()

    if SRainBarrelSystem and SRainBarrelSystem.instance then
        local luaObject = SRainBarrelSystem.instance:getLuaObjectAt(object:getX(), object:getY(), object:getZ())
        if luaObject then
            luaObject.waterAmount = prev
            luaObject.exterior = false
        end
    end
end

function bbEnvServer.patchCampfires()
    if bbEnvServer.campfiresPatched or not SCampfireSystem then
        return
    end

    local originalLowerFirelvl = SCampfireSystem.lowerFirelvl
    SCampfireSystem.lowerFirelvl = function(self)
        for i = 1, self:getLuaObjectCount() do
            forceExteriorFromSquare(self:getLuaObjectByIndex(i))
        end
        return originalLowerFirelvl(self)
    end

    bbEnvServer.campfiresPatched = true
end

function bbEnvServer.patchFarming()
    if bbEnvServer.farmingPatched or not SFarmingSystem then
        return
    end

    local originalCheckPlantSquare = SFarmingSystem.checkPlantSquare
    SFarmingSystem.checkPlantSquare = function(self, luaObject)
        originalCheckPlantSquare(self, luaObject)
        forceExteriorFromSquare(luaObject)
    end

    local originalChangeHealth = SFarmingSystem.changeHealth
    SFarmingSystem.changeHealth = function(self)
        for i = 1, self:getLuaObjectCount() do
            forceExteriorFromSquare(self:getLuaObjectByIndex(i))
        end
        return originalChangeHealth(self)
    end

    bbEnvServer.farmingPatched = true
end

function bbEnvServer.updateExistingObjects()
    if SFarmingSystem and SFarmingSystem.instance then
        for i = 1, SFarmingSystem.instance:getLuaObjectCount() do
            forceExteriorFromSquare(SFarmingSystem.instance:getLuaObjectByIndex(i))
        end
    end

    if SRainBarrelSystem and SRainBarrelSystem.instance then
        for i = 1, SRainBarrelSystem.instance:getLuaObjectCount() do
            forceExteriorFromSquare(SRainBarrelSystem.instance:getLuaObjectByIndex(i))
        end
    end

    if SCampfireSystem and SCampfireSystem.instance then
        for i = 1, SCampfireSystem.instance:getLuaObjectCount() do
            forceExteriorFromSquare(SCampfireSystem.instance:getLuaObjectByIndex(i))
        end
    end
end

function bbEnvServer.applyPatches()
    bbEnvServer.patchRainBarrels()
    bbEnvServer.patchCampfires()
    bbEnvServer.patchFarming()
    bbEnvServer.updateExistingObjects()
    bbEnvServerLog("patches applied")
end

function bbEnvServer.onGameStart()
    bbEnvServerLog("OnGameStart fired")
    bbEnvServer.applyPatches()
end

Events.OnGameStart.Add(bbEnvServer.applyPatches)
Events.OnGameStart.Add(bbEnvServer.onGameStart)
Events.EveryTenMinutes.Add(bbEnvServer.updateExistingObjects)
Events.OnWaterAmountChange.Add(bbEnvServer.onWaterAmountChange)

bbEnvServerLog("environment file loaded")
bbEnvServer.applyPatches()
