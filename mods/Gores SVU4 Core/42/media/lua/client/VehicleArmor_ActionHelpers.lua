--========================================================
-- VEHICLE ARMOR ACTION HELPERS
-- Shared XP, audio, and zombie-attraction sound helpers
-- for install / repair / uninstall timed actions.
--========================================================

require "VehicleArmor_Config"

----------------------------------------------------------
-- XP HELPERS
----------------------------------------------------------
function VehicleArmor_AddXP(character, perk, amount)
    if not character or not perk or not amount or amount <= 0 then return end
    if not character.getXp then return end

    local mult = 1.0
    if VehicleArmorConfig and VehicleArmorConfig.getXPRewardMultiplier then
        mult = VehicleArmorConfig.getXPRewardMultiplier()
    end

    local finalAmount = amount * mult
    if finalAmount <= 0 then return end

    local xpObj = character:getXp()
    if xpObj and xpObj.AddXP then
        xpObj:AddXP(perk, finalAmount)
    end
end

function VehicleArmor_AddMetalWeldingXP(character, amount)
    if not Perks or not Perks.MetalWelding then return end
    VehicleArmor_AddXP(character, Perks.MetalWelding, amount)
end

function VehicleArmor_AddMechanicsXP(character, amount)
    if not Perks or not Perks.Mechanics then return end
    VehicleArmor_AddXP(character, Perks.Mechanics, amount)
end

function VehicleArmor_GetArmorInstallXP(grade)
    local xp = {
        Scrap      = 0,
        Standard   = 8,
        Reinforced = 14,
        Apocalypse = 25,
    }

    return xp[grade] or 0
end

function VehicleArmor_GetArmorInstallMechanicsXP(grade)
    local xp = {
        Scrap      = 1,
        Standard   = 2,
        Reinforced = 3,
        Apocalypse = 5,
    }

    return xp[grade] or 1
end

function VehicleArmor_GetArmorRepairXP(grade, missingHP)
    local base = {
        Scrap      = 0,
        Standard   = 2,
        Reinforced = 3,
        Apocalypse = 4,
    }

    local amount = base[grade] or 0
    if amount <= 0 then return 0 end
    local ratio = math.max(0.1, math.min(1.0, (missingHP or 0) / 100))
    return math.max(1, math.ceil(amount * ratio))
end

function VehicleArmor_GetArmorRepairMechanicsXP(grade, missingHP)
    local base = {
        Scrap      = 1,
        Standard   = 1,
        Reinforced = 2,
        Apocalypse = 3,
    }

    local ratio = math.max(0.1, math.min(1.0, (missingHP or 0) / 100))
    return math.max(1, math.ceil((base[grade] or 1) * ratio))
end

function VehicleArmor_GetArmorUninstallXP(grade)
    local xp = {
        Scrap      = 0,
        Standard   = 1,
        Reinforced = 2,
        Apocalypse = 3,
    }

    return xp[grade] or 0
end

function VehicleArmor_GetArmorUninstallMechanicsXP(grade)
    local xp = {
        Scrap      = 1,
        Standard   = 1,
        Reinforced = 1,
        Apocalypse = 2,
    }

    return xp[grade] or 1
end

----------------------------------------------------------
-- AUDIO HELPERS
----------------------------------------------------------
function VehicleArmor_StartWeldingSound(action)
    if not action or not action.character then return end

    if action.character.playSound then
        action.weldingSound = action.character:playSound("BlowTorch")
    end
end

function VehicleArmor_StopWeldingSound(action)
    if not action or not action.character then return end
    if not action.weldingSound then return end

    if action.character.stopOrTriggerSound then
        action.character:stopOrTriggerSound(action.weldingSound)
    end

    action.weldingSound = nil
end

----------------------------------------------------------
-- SOUND HELPERS
----------------------------------------------------------
function VehicleArmor_MakeWorldSound(character, vehicle, radius, volume)
    if not character then return end

    local x, y, z

    if vehicle then
        x = vehicle:getX()
        y = vehicle:getY()
        z = vehicle:getZ()
    else
        x = character:getX()
        y = character:getY()
        z = character:getZ()
    end

    radius = radius or 20
    volume = volume or 10

    if addSound then
        addSound(character, x, y, z, radius, volume)
    end
end

function VehicleArmor_GetSoundRadius(actionType, grade)
    if VehicleArmorConfig and VehicleArmorConfig.getSoundRadius then
        return VehicleArmorConfig.getSoundRadius(actionType, grade)
    end

    return 20
end

function VehicleArmor_GetSoundVolume(actionType)
    if not VehicleArmorConfig
    or not VehicleArmorConfig.Sound
    or not VehicleArmorConfig.Sound[actionType]
    then
        return 10
    end

    return VehicleArmorConfig.Sound[actionType].Volume or 10
end


----------------------------------------------------------
-- POSITION / IMMERSION HELPERS (SVU4 Phase 1e)
----------------------------------------------------------
function VehicleArmor_IsCharacterInVehicle(character)
    if not character or not character.getVehicle then return false end
    local ok, veh = pcall(function() return character:getVehicle() end)
    return ok and veh ~= nil
end

function VehicleArmor_IsCharacterNearVehicle(character, vehicle, maxDist)
    if not character or not vehicle then return false end
    maxDist = maxDist or 5.0
    if not character.getX or not vehicle.getX then return true end
    local dx = character:getX() - vehicle:getX()
    local dy = character:getY() - vehicle:getY()
    return ((dx * dx) + (dy * dy)) <= (maxDist * maxDist)
end

function VehicleArmor_CanStartOrContinueAction(character, vehicle, partId)
    if not character or not vehicle then return false end
    if VehicleArmor_IsCharacterInVehicle(character) then return false end
    if not VehicleArmor_IsCharacterNearVehicle(character, vehicle, 5.5) then return false end
    if partId and vehicle.getPartById and not vehicle:getPartById(partId) then return false end
    return true
end

function VehicleArmor_GetWorkAreaForPart(vehicle, partId)
    if vehicle and vehicle.getPartById and partId then
        local part = vehicle:getPartById(partId)
        if part and part.getArea then
            local ok, area = pcall(function() return part:getArea() end)
            if ok and area and tostring(area) ~= "" then return tostring(area) end
        end
    end

    local id = tostring(partId or "")
    if id:find("Engine", 1, true) or id:find("Hood", 1, true) or id:find("Windshield", 1, true) or id:find("Headlight", 1, true) then
        return "Engine"
    end
    if id:find("Trunk", 1, true) or id:find("TruckBed", 1, true) or id:find("Rear", 1, true) then
        return "TruckBed"
    end
    if id:find("Left", 1, true) or id:find("L", 1, true) then
        return "SeatFrontLeft"
    end
    if id:find("Right", 1, true) or id:find("R", 1, true) then
        return "SeatFrontRight"
    end
    return "Engine"
end

function VehicleArmor_QueueExitVehicleIfNeeded(character)
    if not VehicleArmor_IsCharacterInVehicle(character) then return false end

    if require then pcall(require, "Vehicles/TimedActions/ISExitVehicle") end

    if ISExitVehicle and ISExitVehicle.new and ISTimedActionQueue then
        ISTimedActionQueue.add(ISExitVehicle:new(character))
        return true
    end

    -- Fallback for builds where ISExitVehicle is not exposed in this context.
    if character and character.exitVehicle then
        pcall(function() character:exitVehicle() end)
        return true
    end

    if character and character.Say then character:Say("I need to get out first.") end
    return false
end


----------------------------------------------------------
-- FACE VEHICLE TIMED ACTION (SVU4 Phase 1m)
----------------------------------------------------------
if require then pcall(require, "TimedActions/ISBaseTimedAction") end

ISFaceVehicleArmor = ISFaceVehicleArmor or ISBaseTimedAction:derive("ISFaceVehicleArmor")

function ISFaceVehicleArmor:isValid()
    if not self.character or not self.vehicle then return false end
    if VehicleArmor_IsCharacterInVehicle(self.character) then return false end
    return VehicleArmor_IsCharacterNearVehicle(self.character, self.vehicle, 6.0)
end

function ISFaceVehicleArmor:update()
    if not self.character or not self.vehicle then return end

    if self.character.faceThisObject then
        pcall(function() self.character:faceThisObject(self.vehicle) end)
        return
    end

    if self.character.faceLocation and self.vehicle.getX and self.vehicle.getY then
        pcall(function() self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY()) end)
        return
    end
end

function ISFaceVehicleArmor:start()
    self:setActionAnim("Loot")
    if self.character and self.vehicle then
        if self.character.faceThisObject then
            pcall(function() self.character:faceThisObject(self.vehicle) end)
        elseif self.character.faceLocation and self.vehicle.getX and self.vehicle.getY then
            pcall(function() self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY()) end)
        end
    end
end

function ISFaceVehicleArmor:stop()
    ISBaseTimedAction.stop(self)
end

function ISFaceVehicleArmor:perform()
    if self.character and self.vehicle then
        if self.character.faceThisObject then
            pcall(function() self.character:faceThisObject(self.vehicle) end)
        elseif self.character.faceLocation and self.vehicle.getX and self.vehicle.getY then
            pcall(function() self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY()) end)
        end
    end
    ISBaseTimedAction.perform(self)
end

function ISFaceVehicleArmor:new(character, vehicle, partId)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.vehicle = vehicle
    o.partId = partId
    o.maxTime = 8
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    return o
end

function VehicleArmor_QueueFaceVehicleAction(character, vehicle, partId)
    if not character or not vehicle or not ISTimedActionQueue then return false end
    if not ISFaceVehicleArmor or not ISFaceVehicleArmor.new then return false end
    ISTimedActionQueue.add(ISFaceVehicleArmor:new(character, vehicle, partId))
    return true
end

function VehicleArmor_QueueVehicleArmorAction(character, vehicle, partId, action)
    if not character or not vehicle or not action then return false end

    -- Phase 1f: allow actions started from inside a vehicle by queuing an exit first.
    -- The timed action is still invalid while seated, so if the exit fails the action cancels safely.
    VehicleArmor_QueueExitVehicleIfNeeded(character)

    local area = VehicleArmor_GetWorkAreaForPart(vehicle, partId)
    local queuedWalk = false

    if ISPathFindAction and ISPathFindAction.pathToVehicleArea then
        local ok, walkAction = pcall(function()
            return ISPathFindAction:pathToVehicleArea(character, vehicle, area)
        end)
        if ok and walkAction then
            ISTimedActionQueue.add(walkAction)
            queuedWalk = true
        end
    end

    -- Face the vehicle after pathing, before the actual weld/repair/uninstall action starts.
    -- This prevents armour work from starting while the character is looking away from the car.
    VehicleArmor_QueueFaceVehicleAction(character, vehicle, partId)

    ISTimedActionQueue.add(action)
    return true, queuedWalk, area
end
