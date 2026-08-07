if isClient() then return end

local TFC_Base = require("TubFluidContainer/TABAS_TubFluidContainerBase")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local BathSaltDefs = require("TABAS_BathSaltDefs")

local STubFluidContainer = TFC_Base:derive("STubFluidContainer")
local WATER_MODDATA_SYNC_COOLDOWN_MS = 400
local FLUID_SYNC_COOLDOWN_MS = 400
local TFC_RUNTIME_STATE = {}

local function getRuntimeState(x, y, z)
    local id = TFC_Utils.getIdByCoords(x, y, z)
    local state = TFC_RUNTIME_STATE[id]
    if not state then
        state = {
            sprites = {},
        }
        TFC_RUNTIME_STATE[id] = state
    end
    return state
end

local function clearRuntimeState(x, y, z)
    local id = TFC_Utils.getIdByCoords(x, y, z)
    TFC_RUNTIME_STATE[id] = nil
end

function STubFluidContainer:new(x, y, z, _bathObject)
    local o = TFC_Base.new(self, x, y, z, _bathObject)
    o._runtime = getRuntimeState(x, y, z)
    for k, v in pairs(o.sprites or {}) do
        if o._runtime.sprites[k] == nil then
            o._runtime.sprites[k] = v
        end
    end
    o.sprites = o._runtime.sprites
    return o
end

function STubFluidContainer:init()
    TFC_Base.init(self)
end

function STubFluidContainer:initNew()
    -- Check and assign the sprite table name. And set Linked if necessary.
end


--------------------- Handle Global Data  ---------------------
function STubFluidContainer:registerData()
    local gData = GetTFCSystemData()
    local changed = false
    local id = TFC_Utils.getIdByCoords(self.x, self.y, self.z)

    -- -------- main --------
    local data = gData.Registered[id]
    if not data then
        data = {}
        gData.Registered[id] = data
        changed = true
        TFC_Utils.noise("TFC Registered", id)
    else
        if data.isLinked == true then
            TFC_Utils.noise("TFC Registered", "conflict: main square is marked linked. Abort.", id)
            return
        end
    end

    local extraKeys = TFC_Utils.getRegisteredExtraKeys()
    for i = 1, #extraKeys do
        local k = extraKeys[i]
        local v = self[k]

        if k == "linkedX" or k == "linkedY" then
            if not self:hasLinked() then
                v = nil
            end
        end

        if data[k] ~= v then
            data[k] = v
            changed = true
        end
    end

    local dataKeys = TFC_Utils.getRegisteredKeys()
    for i = 1, #dataKeys do
        local k = dataKeys[i]
        local v = self:getWaterData(k)
        if v ~= nil and data[k] ~= v then
            data[k] = v
            changed = true
        end
    end

    -- -------- linked --------
    if self:hasLinked() then
        local lid = TFC_Utils.getIdByCoords(self.linkedX, self.linkedY, self.z)
        local ldata = gData.Registered[lid]

        if not ldata then
            ldata = {}
            gData.Registered[lid] = ldata
            changed = true
            TFC_Utils.noise("TFC Registered(linked)", lid)
        else
            if ldata.isLinked == true and ldata.mainId ~= nil and ldata.mainId ~= id then
                TFC_Utils.noise("TFC Registered", "conflict: linked square already owned by other main. Abort.", "lid="..lid, "have="..tostring(ldata.mainId), "want="..id)
                return
            end
        end

        local linkedKeys = TFC_Utils.getRegisteredLinkedKeys()
        for i = 1, #linkedKeys do
            local k = linkedKeys[i]
            local v = (k == "isLinked") and true or id
            if ldata[k] ~= v then
                ldata[k] = v
                changed = true
            end
        end
    end

    if changed then
        TransmitTFCSystemData("registerData")
    end
end

function STubFluidContainer:unregisterData()
    local removed = false
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(self.x, self.y, self.z)
    if gData.Registered[id] then
        gData.Registered[id] = nil
        removed = true
        TFC_Utils.noise("TFC Unregistered", id)
    end

    if self:hasLinked() and self.linkedX and self.linkedY then
        local lid = TFC_Utils.getIdByCoords(self.linkedX, self.linkedY, self.z)
        if gData.Registered[lid] then
            gData.Registered[lid] = nil
            removed = true
            TFC_Utils.noise("TFC Unregistered(linked)", lid)
        end
    end
    if removed then
        TransmitTFCSystemData("unregisterData")
    end
end

function STubFluidContainer:triggerActivate(playerObj, state, activate)
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(self.x, self.y, self.z)
    local data = gData.Activated[id] or {}
    data.x = self.x
    data.y = self.y
    data.z = self.z
    data.facing = self.facing
    data._lastState = data.state or nil
    data.state = state
    data.activate = activate
    data.owner = playerObj:getOnlineID()
    data.ownerName = playerObj:getUsername()
    gData.Activated[id] = data
    TransmitTFCSystemData("triggerActivate")
end

--------------------- Object Mod Data  ---------------------

function STubFluidContainer:initObjectModData()
    local capacity = self.fluidContainer:getCapacity()
    local rainCatcher = self.fluidContainer:isQualifiesForMetaStorage()
    local currentTime = TABAS_GameTimes.Calendar:getTimeInMillis() or 0
    local idealTemp = self:getBathData("idealTemperature") or 40.0

    local bTransmit = false

    self:setWaterData("lastUpdate", currentTime, bTransmit)
    self:setWaterData("capacity", capacity, bTransmit)
    self:setWaterData("amount", 0, bTransmit)
    self:setWaterData("temperature", 0, bTransmit)
    self:setWaterData("rainCatcher", rainCatcher, bTransmit)
    self:setWaterData("dirtyLevel", 0, bTransmit)
    self:setWaterData("bathSalt", false, bTransmit)
    self:setWaterData("linkedX", self.linkedX, bTransmit)
    self:setWaterData("linkedY", self.linkedY, bTransmit)
    self:setWaterData("facing", self.facing, bTransmit)
    self.tfcObject:transmitModData()

    if self.linkedTfcObject then
        self:setLinkedWaterData("facing", self.facing, bTransmit)
        self.linkedTfcObject:transmitModData()
    end

    -- to bath object
    self:setBathData("idealTemperature", idealTemp, bTransmit)
    self.bathObject:transmitModData()
end

--------------------- Water Object Create and Remove ---------------------

local function removeObject(object)
    local square = object:getSquare()
    if not square then return end

    square:transmitRemoveItemFromSquareOnClients(object)
    if object:isExistInTheWorld() then square:RemoveTileObject(object) end
end

local function removeTfcObject(tfcObject, bathObject)
    if tfcObject then
        removeObject(tfcObject)
    end
    if bathObject:haveSpecialTooltip() then
        bathObject:setSpecialTooltip(false)
        bathObject:sync()
    end
end

function STubFluidContainer:remove()
    if isClient() then return end
    self:removeFluidContainer()
    removeTfcObject(self.tfcObject, self.bathObject)
    if self:hasLinked() then
        removeTfcObject(self.linkedTfcObject, self.linkedBathObject)
    end
    self:unregisterData()
    clearRuntimeState(self.x, self.y, self.z)
end

local function createTfcObject(bathObject, square, spriteName)
    if not square then return end
    local exsiting = TFC_Utils.getTfcObject(square:getX(), square:getY(), square:getZ())
    if exsiting then return exsiting end

    local tfcObject = IsoObject.new(square, spriteName, TFC_Utils.Name)
    square:AddSpecialObject(tfcObject)
    tfcObject:setSpecialTooltip(true)
    if not bathObject:haveSpecialTooltip() then
        bathObject:setSpecialTooltip(true)
        bathObject:sync()
    end
    return tfcObject
end


function STubFluidContainer:create()
    if not self.bathObject then
        TFC_Utils.noise("create invalid",  "not bathObject or not sprites table key!")
        return
    end
    local t = self:getSpritesTable()
    if not t then
        TFC_Utils.noise("create invalid",  "not bathObject or not sprites table key!")
        return
    end
    -- create tfc objects
    self.tfcObject = createTfcObject(self.bathObject, self:getSquare(), t.faucet.empty)
    self:addFluidContainer(SandboxVars.TakeABathAndShower.TubWaterCapacity)
    self.tfcObject:transmitCompleteItemToClients()

    if self:hasLinked() then
        self.linkedTfcObject = createTfcObject(self.linkedBathObject, self:getLinkedSquare(), t.tub.empty)
        self.linkedTfcObject:transmitCompleteItemToClients()
        self:setLinkedWaterData("facing", self.facing)
        self:setLinkedWaterData("isLinked", true)
    end

    -- md for Object
    self:initObjectModData()

    -- register to global (include linked minimal)
    self:registerData()
end

--------------------- Fluid Container  ---------------------

function STubFluidContainer:addFluidContainer(capacity)
    if not self.tfcObject or self.tfcObject:hasComponent(ComponentType.FluidContainer) then return end

    local square = self:getSquare()
    local component = ComponentType.FluidContainer:CreateComponent()
    local tubWaterCapacity = capacity
    component:setCapacity(tubWaterCapacity)
    component:setContainerName(TFC_Utils.FluidContainerName)

    GameEntityFactory.AddComponent(self.tfcObject, true, component)
    buildUtil.setHaveConstruction(square, true)
    self.fluidContainer = self.tfcObject:getComponent(ComponentType.FluidContainer)
    -- for rainCatcher
    if SandboxVars.TakeABathAndShower.TubRainCollect and square:isOutside() then
        component:setRainCatcher(0.5)
    end
    self.fluidContainer = component
end

function STubFluidContainer:removeFluidContainer()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return end
    GameEntityFactory.RemoveComponent(self.tfcObject, fluidContainer)
    self.fluidContainer = nil
end

function STubFluidContainer:transmitWaterModData(force)
    if isClient() then return false end
    if not self.tfcObject or not self.tfcObject:isExistInTheWorld() then return false end

    local nowMs = getTimestampMs()
    local runtime = self._runtime or getRuntimeState(self.x, self.y, self.z)
    if (not force) and runtime.lastWaterModDataSyncMs and (nowMs - runtime.lastWaterModDataSyncMs < WATER_MODDATA_SYNC_COOLDOWN_MS) then
        return false
    end

    runtime.lastWaterModDataSyncMs = nowMs
    self.tfcObject:transmitModData()
    return true
end

function STubFluidContainer:syncFluidContainer(force)
    if isClient() then return end
    local nowMs = getTimestampMs()
    local runtime = self._runtime or getRuntimeState(self.x, self.y, self.z)
    if (not force) and runtime.lastFluidSyncMs and (nowMs - runtime.lastFluidSyncMs < FLUID_SYNC_COOLDOWN_MS) then
        return
    end
    runtime.lastFluidSyncMs = nowMs

    if self.tfcObject and self.tfcObject:isExistInTheWorld() then
        self.tfcObject:sync()
    end
    if self.linkedTfcObject and self.linkedTfcObject:isExistInTheWorld() then
        self.linkedTfcObject:sync()
    end
end

function STubFluidContainer:syncWaterState(force)
    self:transmitWaterModData(force)
    self:syncFluidContainer(force)
end

function STubFluidContainer:addFluid(fluid, amount, temperature, noSync)
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return end

    if not fluidContainer:canAddFluid(fluid) then return end
    fluidContainer:addFluid(fluid, amount)
    self:updateWaterSprite()
    if temperature then
        self:adjustTemperature(amount, temperature)
    end
    local newAmount = round(self:getAmount(), 2)

    self:setWaterData("amount", newAmount, false)
    if not noSync then
        self:syncWaterState(false)
    end
end

function STubFluidContainer:removeFluid(amount)
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return end
    local currentAmount = self:getAmount()
    if not amount then
        amount = currentAmount
    end
    fluidContainer:removeFluid(amount)
    self:updateWaterSprite()
    local newAmount = round(self:getAmount(), 2)

    self:setWaterData("amount", newAmount, false)
    if newAmount <= 0 then
        self:setWaterData("dirtyLevel", 0, false)
        self:setWaterData("bathSalt", nil, false)
    end
    self:syncWaterState(newAmount <= 0)
end

function STubFluidContainer:adjustAmount(amount)
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return end

    fluidContainer:adjustAmount(amount)
    self:updateWaterSprite()
    local newAmount = round(self:getAmount(), 2)
    self:setWaterData("amount", newAmount, false)
    self:syncWaterState(false)
end

function STubFluidContainer:getFillFluid()
    local bathSaltType = self:getWaterData("bathSalt")
    local bathSaltFluid = bathSaltType and BathSaltDefs.getFluid(bathSaltType) or nil
    if bathSaltFluid then
        return bathSaltFluid
    end
    return Fluid.Water
end

function STubFluidContainer:addWater(amount)
    local prevAmount = round(self:getAmount(), 2)
    local temperature = TFC_Utils.DefaultTemperature
    if TABAS_Iso.canHot(self.bathObject) then
        temperature = self:getBathData("idealTemperature") or 40.0
    end
    self:addFluid(self:getFillFluid(), amount, temperature, true)
    local dirtChanged = self:diluteDirtyLevel(prevAmount)
    if dirtChanged then
        self:updateWaterSprite()
    end
    self:updateLastUpdate()
    self:syncWaterState(false)
end

function STubFluidContainer:updateLastUpdate()
    local currentTime = TABAS_GameTimes.Calendar:getTimeInMillis()
    self:setWaterData("lastUpdate", currentTime, false)
end

--------------------- Water Temperature ---------------------

function STubFluidContainer:setWaterTemperature(temperature, noTransmit)
    local newTemperature = round(temperature, 4)
    local changed = self:setWaterData("temperature", newTemperature, false)
    self:updateHotSteamOverlay()
    if changed and not noTransmit then
        self:transmitWaterModData(false)
    end
end

function STubFluidContainer:adjustTemperature(addedAmount, targetTempe)
    if not SandboxVars.TakeABathAndShower.WaterTemperatureConcept then return TFC_Utils.DefaultTemperature end
    local currentTempe = self:getWaterTemperature()
    targetTempe = targetTempe and targetTempe or TFC_Utils.DefaultTemperature
    if currentTempe == targetTempe then return end

    if currentTempe >= targetTempe - 0.1 and currentTempe <= targetTempe + 0.1 then
        self:setWaterTemperature(targetTempe, true)
        -- TFC_Utils.noise("Adjust Temperature", "new temperature: ".. targetTempe)
        return
    end
    local currentAmount = round(self:getAmount(), 2)
    local old = currentTempe * currentAmount
    local new = targetTempe * addedAmount
    local total = currentAmount + addedAmount
    local culcedTempe = (old + new) / total
    -- TFC_Utils.noise("Adjust Temperature", "new temperature: ".. culcedTempe)
    self:setWaterTemperature(culcedTempe, true)
end

function STubFluidContainer:waterToDirt(amount)
    if not SandboxVars.TakeABathAndShower.TubWaterGetDirty then
        self:setWaterData("dirtyLevel", 0, true)
        return
    end
    if not self:hasFluidContainer() then return end
    local dirtLvl = self:getWaterData("dirtyLevel")
    local newDirtLvl = round(dirtLvl + amount, 2)
    self:setWaterData("dirtyLevel", newDirtLvl, true)
    if newDirtLvl < 20 then return end

    if not self:getWaterData("bathSalt") then
        self:replaceWater(Fluid.TaintedWater)
    else
        self:updateWaterSprite()
    end
end

function STubFluidContainer:diluteDirtyLevel(prevAmount)
    local dirtyLevel = self:getWaterData("dirtyLevel") or 0
    if dirtyLevel <= 0 then return false end

    local newAmount = round(self:getAmount(), 2)
    if not prevAmount or prevAmount <= 0 or newAmount <= prevAmount then
        return false
    end

    local dilutedDirtyLevel = round(dirtyLevel * (prevAmount / newAmount), 2)
    if dilutedDirtyLevel < 0 then
        dilutedDirtyLevel = 0
    end

    -- Filling can dilute the visible/comfort-level dirtiness, but once water has
    -- become tainted we keep that fluid state instead of restoring plain Water.
    return self:setWaterData("dirtyLevel", dilutedDirtyLevel, false)
end

function STubFluidContainer:replaceWater(newFluid)
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return end

    local oldFluid
    local fluids = Fluid.getAllFluids()
    for i=0,fluids:size()-1 do
        oldFluid = fluids:get(i)
        if oldFluid:isCategory(FluidCategory.Water) and fluidContainer:contains(oldFluid) then
            local amount = fluidContainer:getSpecificFluidAmount(oldFluid)
            if amount and amount > 0 then
                fluidContainer:adjustSpecificFluidAmount(oldFluid, 0)
                self:addFluid(newFluid, amount, nil, true)
            end
        end
    end
    self:syncWaterState(true)
end

--------------------- Water Sprite ---------------------

function STubFluidContainer:updateWaterSprite()
    self.sprites.changed = false
    self:setWaterSprite()
    self:updateHotSteamOverlay()

    if self.sprites.changed then
        self.tfcObject:transmitUpdatedSpriteToClients()
        if self.linkedTfcObject then
            self.linkedTfcObject:transmitUpdatedSpriteToClients()
        end
    end
    self:setWaterColor()
end

function STubFluidContainer:getSpritesTable()
    local spriteDir = "sprite" .. self.facing
    self._spritesTableCache = self._spritesTableCache or {}

    local cached = self._spritesTableCache[spriteDir]
    if cached then return cached end

    local t = TABAS_Iso.getSpritesTable(self.sprites.tableKey, spriteDir)
    self._spritesTableCache[spriteDir] = t
    return t
end

function STubFluidContainer:getSpritesPart(part) -- "faucet" or "tub"
    self._spritesPartCache = self._spritesPartCache or {}
    local cached = self._spritesPartCache[part]
    if cached ~= nil then return cached end

    local spriteDir = "sprite" .. self.facing
    local t = TABAS_Iso.getSpritesTable(self.sprites.tableKey, spriteDir)
    local p = t and t[part] or nil

    self._spritesPartCache[part] = p
    return p
end

function STubFluidContainer:resolveSpriteName(sprites, levelKey, bDirty)
    if not sprites then return nil end

    if levelKey == "empty" then
        return sprites.empty
    end

    if bDirty then
        local dirty = sprites.dirty
        local dirtyName = dirty and dirty[levelKey] or nil
        if dirtyName then
            return dirtyName
        end
    end

    return sprites[levelKey]
end

function STubFluidContainer:applySpriteIfChanged(object, spriteName, lastField)
    if not object or not spriteName then return end

    if self.sprites[lastField] == spriteName then
        return
    end
    self.sprites[lastField] = spriteName

    object:setSpriteFromName(spriteName)
end

function STubFluidContainer:setWaterSprite()
    local changed = false
    local levelKey = self:getWaterLevelKey()
    -- levelKey: "empty"|"low"|"halfLow"|"half"|"full"

    if levelKey ~= self.sprites.levelKey then
        self.sprites.levelKey = levelKey
        changed = true
    end

    local bDirty = self:isDirtyWater() or false
    if bDirty ~= (self.sprites.bDirty or false) then
        self.sprites.bDirty = bDirty
        changed = true
    end
    if not changed then return end

    local function updatePart(part, object, lastField)
        if not object then return end
        local sprites = self:getSpritesPart(part)
        local name = self:resolveSpriteName(sprites, levelKey, bDirty)
        self:applySpriteIfChanged(object, name, lastField)
    end

    updatePart("faucet", self.tfcObject, "lastSprite_faucet")
    updatePart("tub", self.linkedTfcObject, "lastSprite_tub")

    self.sprites.changed = true
end

function STubFluidContainer:getFluidColor()
    local bathSaltType = self:getWaterData("bathSalt")
    local bathSaltColor = bathSaltType and BathSaltDefs.getDisplayColor(bathSaltType) or nil
    if bathSaltColor then
        return bathSaltColor
    end

    if self:hasFluid() then
        local color = self.fluidContainer:getColor()
        if color then
            local r = round(color:getRedFloat(), 2)
            local g = round(color:getGreenFloat(), 2)
            local b = round(color:getBlueFloat(), 2)
            return {r=r, g=g, b=b, a=0.5}
        end
    end
    return TFC_Utils.DefaultColors
end

local function isDiffColorChannel(oldCol, col, thr)
    if not oldCol then return true end
    return math.abs(oldCol.r - col.r) > thr
        or math.abs(oldCol.g - col.g) > thr
        or math.abs(oldCol.b - col.b) > thr
end

function STubFluidContainer:setWaterColor()
    if not self.tfcObject or self:isEmpty() then return end

    local modData = self.tfcObject:getModData()
    local oldCol = modData.colors
    local col = self:getFluidColor() -- {r,g,b,a}
    local thr = 0.05

    if not isDiffColorChannel(oldCol, col, thr) then
        return
    end

    local colorInfo = ColorInfo.new(col.r, col.g, col.b, col.a)
    -- to modData
    modData.colors = {r=col.r, g=col.g, b=col.b, a=col.a}
    self.tfcObject:transmitModData()

    self.tfcObject:setCustomColor(colorInfo)
    self.tfcObject:transmitCustomColorToClients()
    if self.linkedTfcObject then
        self.linkedTfcObject:setCustomColor(colorInfo)
        self.linkedTfcObject:transmitCustomColorToClients()
    end
    TFC_Utils.noise("setWaterColor", string.format("r=%s, g=%s, b=%s, a=%s", col.r, col.g, col.b, col.a))
    local args = {
       x = self.x, y = self.y, z = self.z,
       linkedX= self.linkedX, linkedY = self.linkedY,
       r=col.r, g=col.g, b=col.b, a=col.a
    }
    sendServerCommand("tabas_tfc", "setCustomColor", args)
end

--------------------- Hot Steam Overlay ---------------------

function STubFluidContainer:getSteamSpriteName(part)
    self._steamSpriteCache = self._steamSpriteCache or {}
    local cached = self._steamSpriteCache[part]
    if cached ~= nil then
        return cached
    end

    local sprites = self:getSpritesPart(part)
    local name = sprites and sprites.steam or nil

    self._steamSpriteCache[part] = name
    return name
end

function STubFluidContainer:updateHotSteamOverlay()
    if not self.tfcObject then return end

    local isHotWater = false
    local ratio = self:getRatio() or 0
    if ratio > TFC_Utils.Filled_HalfLow then
        isHotWater = self:isHotWater()
    end

    local curFaucet = isHotWater and self:getSteamSpriteName("faucet") or nil
    local curTub    = (isHotWater and self.linkedTfcObject) and self:getSteamSpriteName("tub") or nil

    local changed = self.sprites.lastSteamOn ~= isHotWater
       or self.sprites.lastSteamSprite_faucet ~= curFaucet
       or self.sprites.lastSteamSprite_tub ~= curTub
    if not changed then return end

    self.sprites.lastSteamOn = isHotWater
    self.sprites.lastSteamSprite_faucet = curFaucet
    self.sprites.lastSteamSprite_tub = curTub

    local function apply(obj, part)
        if not obj then return end

        if isHotWater then
            local steamSprite = self:getSteamSpriteName(part)
            if steamSprite then
                obj:setOverlaySprite(steamSprite)
            else
                obj:setOverlaySprite(nil)
            end
        else
            obj:setOverlaySprite(nil)
        end
    end

    apply(self.tfcObject, "faucet")
    if self.linkedTfcObject then
        apply(self.linkedTfcObject, "tub")
    end

    self.sprites.changed = true
end

--------------------- Bath Salt  ---------------------

function STubFluidContainer:addBathSalt(def)
    if not self:hasFluid() then return end
    local fluidType = def.fluidType
    if fluidType then
        local newFluid = Fluid.Get(fluidType)
        self:replaceWater(newFluid)
        self:setWaterData("bathSalt", def.type, true)
    else
        TFC_Utils.noise("addBathSalt", "This bathSalt def has not fluid type!")
    end
end

return STubFluidContainer
