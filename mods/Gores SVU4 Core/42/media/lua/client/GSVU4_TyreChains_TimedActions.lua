-- =============================================================================
-- Gore's SVU4 Core - Tyre Chains Timed Actions
-- Four tyre-point welding-style action chain for install/remove/repair.
-- =============================================================================
require "TimedActions/ISBaseTimedAction"
pcall(require, "TimedActions/ISPathFindAction")
require "GoresSVU4TyreChains/GSVU4_TyreChains_Config"

local TC = GSVU4_TyreChains

GSVU4_TyreChainsTimedAction = ISBaseTimedAction:derive("GSVU4_TyreChainsTimedAction")

local function sendNoisePulse(character, vehicle)
    if not TC or not TC.sendVehicleCommand then return end
    TC.sendVehicleCommand("NoisePulse", character, vehicle)
end

function GSVU4_TyreChainsTimedAction:isValid()
    if not self.character or not self.vehicle then return false end
    if self.command == "Install" and TC.isInstalled(self.vehicle) then return false end
    if self.command ~= "Install" and not TC.isInstalled(self.vehicle) then return false end
    return true
end

function GSVU4_TyreChainsTimedAction:waitToStart()
    if self.character and self.vehicle and self.character.faceThisObject then
        self.character:faceThisObject(self.vehicle)
    end
    return false
end

function GSVU4_TyreChainsTimedAction:update()
    if self.character and self.vehicle and self.character.faceThisObject then
        self.character:faceThisObject(self.vehicle)
    end
end

function GSVU4_TyreChainsTimedAction:start()
    if self.setActionAnim then
        pcall(function() self:setActionAnim("BlowTorch") end)
    end
    if self.setOverrideHandModels then
        pcall(function() self:setOverrideHandModels(nil, nil) end)
    end

    if self.character and self.character.Say and self.pointLabel then
        -- Keep staged-action feedback brief.
        pcall(function() self.character:Say(self.actionLabel .. ": " .. self.pointLabel) end)
    end

    sendNoisePulse(self.character, self.vehicle)
end

function GSVU4_TyreChainsTimedAction:stop()
    ISBaseTimedAction.stop(self)
end

function GSVU4_TyreChainsTimedAction:perform()
    sendNoisePulse(self.character, self.vehicle)

    if self.isFinalStage and TC.sendVehicleCommand then
        TC.sendVehicleCommand(self.command, self.character, self.vehicle)

        -- The server owns the actual install/remove/repair state, but the
        -- client needs a retry window so visual packs can catch the incoming
        -- modData sync and reassert chain models.
        if TC.requestVisualRefresh then
            pcall(function() TC.requestVisualRefresh(self.vehicle, (TC.Config and TC.Config.VisualRefreshRetryFrames) or 240) end)
        end
        if GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
            pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(self.vehicle, "TyreChains", "Standard") end)
        end
        if GSVU4Core and GSVU4Core.ReassertInstalledArmorAfterUpgrade then
            pcall(function()
                GSVU4Core.ReassertInstalledArmorAfterUpgrade(self.vehicle, 4, 12)
            end)
        elseif VehicleArmorVisuals and VehicleArmorVisuals.ForceInstalled then
            pcall(function() VehicleArmorVisuals.ForceInstalled(self.vehicle) end)
        end
    end

    ISBaseTimedAction.perform(self)
end

function GSVU4_TyreChainsTimedAction:new(character, vehicle, command, time, pointLabel, isFinalStage, actionLabel, pointId)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = vehicle
    o.command = command
    o.maxTime = time or 60
    o.pointLabel = pointLabel or "tyre"
    o.pointId = pointId
    o.isFinalStage = isFinalStage == true
    o.actionLabel = actionLabel or "Working on tyre chains"
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true
    return o
end

local function tryQueueMoveToTyrePoint(character, vehicle, point)
    if not character or not vehicle or not point or not point.id then return end
    if not ISTimedActionQueue or not ISPathFindAction then return end
    if not vehicle.getPartById then return end

    local part = vehicle:getPartById(point.id)
    if not part then return end

    local area = nil
    if part.getArea then
        local ok, result = pcall(function() return part:getArea() end)
        if ok then area = result end
    end

    if not area then return end

    local action = nil
    if ISPathFindAction.pathToVehicleArea then
        local ok, result = pcall(function()
            return ISPathFindAction:pathToVehicleArea(character, vehicle, area)
        end)
        if ok then action = result end
    end

    if action then
        ISTimedActionQueue.add(action)
    end
end

function GSVU4_TyreChains.queueTimedVehicleAction(character, vehicle, command, totalTime, actionLabel)
    if not ISTimedActionQueue or not GSVU4_TyreChainsTimedAction then
        if TC.sendVehicleCommand then TC.sendVehicleCommand(command, character, vehicle) end
        return
    end

    local points = TC.Config.TyreActionPoints
    local count = TC.Config.ActionTyrePointCount or 4
    local perStage = math.max(1, math.floor((totalTime or 240) / count))

    for i = 1, count do
        local point = points[i] or { label = "tyre " .. tostring(i), id = nil }
        local isFinal = i == count

        -- Try to walk to the actual tyre part area before each welding-style stage.
        -- If the vanilla path helper is unavailable, the action still runs and faces the car.
        tryQueueMoveToTyrePoint(character, vehicle, point)

        ISTimedActionQueue.add(GSVU4_TyreChainsTimedAction:new(
            character,
            vehicle,
            command,
            perStage,
            point.label,
            isFinal,
            actionLabel,
            point.id
        ))
    end
end
