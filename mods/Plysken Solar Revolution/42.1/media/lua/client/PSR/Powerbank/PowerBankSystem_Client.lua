--[[
    "psr_powerbank" client system — B42 rewrite (CGlobalObjects API)
--]]

---@class PSR
local PSR = require "PSR/Utilities"
local PowerBank = require "PSR/Powerbank/PowerBankObject_Client"

---@class PowerbankSystem_Client : PowerbankSystem
local PBSystem = require("PSR/PowerBankSystem_Shared"):new({})
PBSystem.__index = PBSystem

function PBSystem:initSystem()
    PSR.PBSystem_Client = self
    if isClient() then
        Events.EveryTenMinutes.Add(PBSystem.updateBanksForClient)
        Events.EveryOneMinute.Add(PBSystem.updateSpritesLocal)
        Events.OnContainerUpdate.Add(PBSystem.onContainerUpdate)
    end
    Events.EveryDays.Add(PBSystem.resetAcceptItemFunction.addItems)
end

function PBSystem:noise(message)
    if self.wantNoise then print("PSR_Client: " .. message) end
end

---Wrap a global object's mod data with PowerBank methods. Safe to call multiple times.
---@param globalObject table
---@return PowerBankObject_Client
function PBSystem:wrapGlobalObject(globalObject)
    local pb = globalObject:getModData()
    if getmetatable(pb) ~= PowerBank then
        pb.x = globalObject:getX()
        pb.y = globalObject:getY()
        pb.z = globalObject:getZ()
        pb.luaSystem = self
        setmetatable(pb, PowerBank)
    end
    return pb
end

---@param x number
---@param y number
---@param z number
---@return PowerBankObject_Client?
function PBSystem:getLuaObjectAt(x, y, z)
    local go = self.system:getObjectAt(x, y, z)
    if go then return self:wrapGlobalObject(go) end
end

---@param i number  (1-indexed)
---@return PowerBankObject_Client
function PBSystem:getLuaObjectByIndex(i)
    return self:wrapGlobalObject(self.system:getObjectByIndex(i - 1))
end

---@return number
function PBSystem:getLuaObjectCount()
    return self.system:getObjectCount()
end

---@param square IsoGridSquare
---@return PowerBankObject_Client?
function PBSystem:getLuaObjectOnSquare(square)
    if not square then return end
    return self:getLuaObjectAt(square:getX(), square:getY(), square:getZ())
end

---Send a command to the server system.
---@param player IsoPlayer
---@param commandName string
---@param args table
function PBSystem:sendCommand(player, commandName, args)
    self.system:sendCommand(commandName, player, args)
end

---@param x number
---@param y number
---@param z number
function PBSystem:newLuaObjectAt(x, y, z)
    self:noise("adding luaObject " .. x .. "," .. y .. "," .. z)
    local globalObject = self.system:newObject(x, y, z)
    self.processNewLua:addItem(x, y, z)
    return self:wrapGlobalObject(globalObject)
end

do
    local o = PSR.delayedProcess:new{maxTimes=999}

    function o.process()
        if not o.data then return o:stop() end
        for i = #o.data, 1, -1 do
            local gen = o.data[i]:getGenerator()
            if gen then
                local isoPb = PBSystem.instance:getIsoObjectOnSquare(o.data[i])
                if isoPb then
                    local c = isoPb:getContainer()
                    if c then
                        c:setAcceptItemFunction("AcceptItemFunction.PSR_Batteries")
                        gen:getCell():addToProcessIsoObjectRemove(gen)
                    end
                end
                table.remove(o.data, i)
            end
        end
        if #o.data == 0 or o.times <= 1 then o:stop() return end
        o.times = o.times - 1
    end

    function o:addItem(x, y, z)
        local square = getSquare(x, y, z)
        if not square then return end
        if not self.data then
            self.data = {}
            self:start()
        end
        self.times = self.maxTimes
        table.insert(self.data, square)
    end

    PBSystem.processNewLua = o
end

do
    local o = PSR.delayedProcess:new{maxTimes=999}

    function o.process()
        if not o.data then return o:stop() end
        for i = #o.data, 1, -1 do
            local obj = o.data[i]
            if obj:getObjectIndex() == -1 then
                table.remove(o.data, i)
            else
                local container = obj:getContainer()
                if container == nil then
                    table.remove(o.data, i)
                elseif container:getAcceptItemFunction() == nil then
                    PBSystem.instance:noise("Container reset")
                    container:setAcceptItemFunction("AcceptItemFunction.PSR_Batteries")
                    triggerEvent("OnContainerUpdate", obj)
                    table.remove(o.data, i)
                    local players = IsoPlayer.getPlayers()
                    for j = 0, players:size() - 1 do
                        local player = players:get(j)
                        if player ~= nil and player:getZ() == obj:getZ()
                            and IsoUtils.DistanceToSquared(player:getX(), player:getY(), obj:getX() + 0.5, obj:getY() + 0.5) <= 4 then
                            ISTimedActionQueue.clear(player)
                        end
                    end
                else
                    table.remove(o.data, i)
                end
            end
        end
        if #o.data == 0 or o.times <= 1 then return o:stop() end
        o.times = o.times - 1
    end

    function o.addItems()
        o.data = {}
        for i = 1, PBSystem.instance:getLuaObjectCount() do
            local isoObject = PBSystem.instance:getLuaObjectByIndex(i):getIsoObject()
            if isoObject then
                table.insert(o.data, isoObject)
            end
        end
        if #o.data > 0 then
            o.times = o.maxTimes
            o:start()
        else
            o.data = nil
        end
    end

    PBSystem.resetAcceptItemFunction = o
end

function PBSystem.canConnectPanelTo(panel)
    local options = {}
    local sq = panel:getSquare()
    if not sq then return options end
    if not sq:isOutside() then
        options.inside = true
        return options
    end
    local x = panel:getX()
    local y = panel:getY()
    local z = panel:getZ()
    local abs = math.abs
    local jSystem = PBSystem.instance.system
    for i = 0, jSystem:getObjectCount() - 1 do
        local pb = PBSystem.instance:wrapGlobalObject(jSystem:getObjectByIndex(i))
        local dx, dy = pb.x - x, pb.y - y
        if dx*dx + dy*dy <= 400.0 and abs(z - pb.z) <= 3 then
            pb:updateFromIsoObject()
            local isConnected
            for _, ipanel in ipairs(pb.panels or {}) do
                if x == ipanel.x and y == ipanel.y and z == ipanel.z then
                    isConnected = true
                    break
                end
            end
            table.insert(options, { pb, pb.x - x, pb.y - y, isConnected })
        end
    end
    return options
end

function PBSystem.getGeneratorsInAreaInfo(luaPb, area)
    local DistanceToSquared = IsoUtils.DistanceToSquared
    local generators = 0
    for ix = luaPb.x - area.radius, luaPb.x + area.radius do
        for iy = luaPb.y - area.radius, luaPb.y + area.radius do
            for iz = luaPb.z - area.levels, luaPb.z + area.levels do
                local sq = getSquare(ix, iy, iz)
                local generator = sq and luaPb.luaSystem:getValidBackupOnSquare(sq)
                if generator and DistanceToSquared(luaPb.x, luaPb.y, luaPb.z, ix, iy, iz) <= area.distance then
                    generators = generators + 1
                end
            end
        end
    end
    return generators
end

-- OnContainerUpdate fires with the IsoObject (parent), not the ItemContainer
function PBSystem.onContainerUpdate(isoObject)
    if not isoObject then return end
    local pb = PBSystem.instance:getLuaObjectAt(isoObject:getX(), isoObject:getY(), isoObject:getZ())
    if not pb then return end
    local itemContainer = isoObject:getContainer()
    if not itemContainer then return end
    local batteries, capacity, charge = 0, 0, 0
    local items = itemContainer:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local maxCap = item:getModData().PSR_maxCapacity
        if maxCap then
            local cond = item:getCondition()
            if cond > 0 then
                batteries = batteries + 1
                local cap = maxCap * (1 - math.pow((1 - (cond / 100)), 6))
                capacity = capacity + cap
                charge = charge + cap * item:getCurrentUsesFloat()
            end
        end
    end
    pb.batteries = batteries
    pb.maxcapacity = capacity
    pb.charge = charge
    pb:updateSprite()
end

-- Sprite-only fallback: re-reads local container each minute in case OnContainerUpdate didn't fire
function PBSystem.updateSpritesLocal()
    for i = 1, PBSystem.instance:getLuaObjectCount() do
        local pb = PBSystem.instance:getLuaObjectByIndex(i)
        local isopb = pb:getIsoObject()
        if isopb then
            local itemContainer = isopb:getContainer()
            if itemContainer then
                local batteries, capacity, charge = 0, 0, 0
                local items = itemContainer:getItems()
                for v = 0, items:size() - 1 do
                    local item = items:get(v)
                    local maxCap = item:getModData().PSR_maxCapacity
                    if maxCap then
                        local cond = item:getCondition()
                        if cond > 0 then
                            batteries = batteries + 1
                            local cap = maxCap * (1 - math.pow((1 - (cond / 100)), 6))
                            capacity = capacity + cap
                            charge = charge + cap * item:getCurrentUsesFloat()
                        end
                    end
                end
                pb.batteries = batteries
                pb.maxcapacity = capacity
                pb.charge = charge
                pb:updateSprite()
            end
        end
    end
end

---NOTE (suivi docs/RISKS.md 2026-06-19) : peut tourner avant réception des données serveur ; idéalement piloter par commande. Inoffensif (lecture modData en retard d'un tick au pire).
function PBSystem.updateBanksForClient()
    for i = 1, PBSystem.instance:getLuaObjectCount() do
        local pb = PBSystem.instance:getLuaObjectByIndex(i)
        local isopb = pb:getIsoObject()
        if isopb then
            pb:fromModData(isopb:getModData())
            pb:updateSprite()
            pb:updateGenerator()
            local itemContainer = isopb:getContainer()
            if itemContainer then
                local mc = pb.maxcapacity or 0
                local delta = mc > 0 and (pb.charge or 0) / mc or 0
                local items = itemContainer:getItems()
                for v = 0, items:size() - 1 do
                    local item = items:get(v)
                    if item:getModData().PSR_maxCapacity then
                        item:setCurrentUsesFloat(delta)
                    end
                end
            end
        end
    end
end

function PBSystem:OnChunkLoaded(wx, wy)
    local globalObjects = self.system:getObjectsInChunk(wx, wy)
    for i = 1, globalObjects:size() do
        self:wrapGlobalObject(globalObjects:get(i - 1))
    end
    self.system:finishedWithList(globalObjects)
end

---B42 registration — called by Events.OnCGlobalObjectSystemInit
function PBSystem.OnCGlobalObjectSystemInit()
    local jSystem = CGlobalObjects.registerSystem("psr_powerbank")

    local o = jSystem:getModData()
    setmetatable(o, PBSystem)
    o.system = jSystem
    o.wantNoise = getDebug()
    PBSystem.instance = o
    o:initSystem()
end

Events.OnCGlobalObjectSystemInit.Add(PBSystem.OnCGlobalObjectSystemInit)

return PBSystem
