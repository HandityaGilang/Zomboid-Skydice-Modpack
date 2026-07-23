if isServer() and not isClient() then return end

DCS_dprint("[DCS] DCS_Tracking_Vehicle.lua LOADED — ISInstallVehiclePart=" .. tostring(ISInstallVehiclePart ~= nil) .. " complete=" .. tostring(ISInstallVehiclePart and ISInstallVehiclePart.complete ~= nil))

local VEHICLE_PART_GROUPS = {
    HeadlightLeft = "Headlight",
    HeadlightRight = "Headlight",
    HeadlightRearLeft = "Headlight",
    HeadlightRearRight = "Headlight",
    TireFrontLeft = "Tire",
    TireFrontRight = "Tire",
    TireRearLeft = "Tire",
    TireRearRight = "Tire",
    BrakeFrontLeft = "Brake",
    BrakeFrontRight = "Brake",
    BrakeRearLeft = "Brake",
    BrakeRearRight = "Brake",
    SuspensionFrontLeft = "Suspension",
    SuspensionFrontRight = "Suspension",
    SuspensionRearLeft = "Suspension",
    SuspensionRearRight = "Suspension",
    Battery = "Battery",
    GasTank = "GasTank",
    Muffler = "Muffler",
    EngineDoor = "Hood",
    Windshield = "Windshield",
    WindshieldRear = "Windshield",
    WindowFrontLeft = "Window",
    WindowFrontRight = "Window",
    WindowMiddleLeft = "Window",
    WindowMiddleRight = "Window",
    WindowRearLeft = "Window",
    WindowRearRight = "Window",
    DoorFrontLeft = "Door",
    DoorFrontRight = "Door",
    DoorMiddleLeft = "Door",
    DoorMiddleRight = "Door",
    DoorRearLeft = "Door",
    DoorRearRight = "Door",
    DoorRear = "Door",
    TrunkDoor = "Trunk",
    SeatFrontLeft = "Seat",
    SeatFrontRight = "Seat",
    SeatMiddleLeft = "Seat",
    SeatMiddleRight = "Seat",
    SeatRearLeft = "Seat",
    SeatRearRight = "Seat",
    Radio = "Radio",
}

local lastVehiclePos = {}
local vehicleDistFrac = {}
local vehicleDistAccumulator = {}
local VEHICLE_REPORT_CHUNK = 10
local lastVehicleResetDay = ""

local function onVehicleTick()
    local player = getPlayer and getPlayer() or nil
    if not player then return end
    if not player:isLocalPlayer() then return end
    if player:isDead() then return end

    local vehicle = player:getVehicle()
    if not vehicle then
        lastVehiclePos[player:getPlayerNum()] = nil
        return
    end

    local id = player:getPlayerNum()
    local px = player:getX()
    local py = player:getY()

    local today = os.date("!%Y%m%d")
    if today ~= lastVehicleResetDay then
        lastVehicleResetDay = today
        lastVehiclePos = {}
        vehicleDistFrac = {}
        vehicleDistAccumulator = {}
        return
    end

    if not lastVehiclePos[id] then
        lastVehiclePos[id] = { x = px, y = py }
        return
    end

    local lx, ly = lastVehiclePos[id].x, lastVehiclePos[id].y
    local dx, dy = px - lx, py - ly
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0.1 and dist < 10 then
        lastVehiclePos[id] = { x = px, y = py }

        vehicleDistFrac[id] = (vehicleDistFrac[id] or 0) + dist
        local tiles = math.floor(vehicleDistFrac[id])
        if tiles >= 1 then
            vehicleDistFrac[id] = vehicleDistFrac[id] - tiles

            if DCS_Sync and DCS_Sync.getTodayChallenges then
                for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
                    if ch.type == "vehicleDistance" and not DCS_Sync.isCompleted(ch.id) then
                        DCS_Sync.addLocalProgress(ch.id, tiles)
                    end
                end
            end

            vehicleDistAccumulator[id] = (vehicleDistAccumulator[id] or 0) + tiles
            while vehicleDistAccumulator[id] >= VEHICLE_REPORT_CHUNK do
                vehicleDistAccumulator[id] = vehicleDistAccumulator[id] - VEHICLE_REPORT_CHUNK
                local today = os.date("!%Y%m%d")
                if DCS_Sync and DCS_Sync.getTodayChallenges then
                    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
                        if ch.type == "vehicleDistance" and not DCS_Sync.isCompleted(ch.id) then
                            sendClientCommand(player, "DailyChallengeSystem", "reportChallengeProgress", {
                                challengeId = ch.id,
                                day = today,
                                amount = VEHICLE_REPORT_CHUNK,
                            })
                        end
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(onVehicleTick)

local lastUninstallPartId = nil
local lastInstallPartId = nil

if ISUninstallVehiclePart and ISUninstallVehiclePart.perform then
    local originalUninstallPerform = ISUninstallVehiclePart.perform
    local originalUninstallStart = ISUninstallVehiclePart.start

    function ISUninstallVehiclePart:start()
        if originalUninstallStart then
            originalUninstallStart(self)
        end

        if not self.character then return end
        if not self.character:isLocalPlayer() then return end

        local partId = self.part and self.part.getId and self.part:getId() or nil
        if partId then
            lastUninstallPartId = partId
            DCS_dprint("[DCS] ISUninstallVehiclePart:start — saved partId=" .. partId)
        end
    end

    function ISUninstallVehiclePart:perform()
        lastInstallPartId = nil

        originalUninstallPerform(self)
    end

    Events.OnMechanicActionDone.Add(function(chr, success)
        if not chr then return end
        if not chr:isLocalPlayer() then return end
        if not lastUninstallPartId then return end

        local partId = lastUninstallPartId
        lastUninstallPartId = nil

        if not success then
            print("[DCS] OnMechanicActionDone: uninstall FAILED for part=" .. partId)
            return
        end

        local partGroup = VEHICLE_PART_GROUPS[partId] or partId
        local today = os.date("!%Y%m%d")

        DCS_dprint("[DCS] OnMechanicActionDone: uninstall SUCCESS partId=" .. partId .. " partGroup=" .. partGroup)

        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "vehiclePartRemove"
            and not DCS_Sync.isCompleted(ch.id) then
                if not ch.targetPart or ch.targetPart == partGroup then
                    DCS_dprint("[DCS] Vehicle part remove match: " .. ch.id .. " part=" .. partId .. " group=" .. partGroup)
                    sendClientCommand(chr, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end)

    DCS_dprint("[DCS] Vehicle uninstall tracking registered via perform() + OnMechanicActionDone")
else
    print("[DCS] WARNING: ISUninstallVehiclePart not found — vehicle part removal tracking disabled")
end

if ISInstallVehiclePart and ISInstallVehiclePart.perform then
    local originalInstallPerform = ISInstallVehiclePart.perform
    local originalInstallStart = ISInstallVehiclePart.start

    function ISInstallVehiclePart:start()
        if originalInstallStart then
            originalInstallStart(self)
        end

        if not self.character then return end
        if not self.character:isLocalPlayer() then return end

        local partId = self.part and self.part.getId and self.part:getId() or nil
        if partId then
            lastInstallPartId = partId
            DCS_dprint("[DCS] ISInstallVehiclePart:start — saved partId=" .. partId)
        end
    end

    function ISInstallVehiclePart:perform()
        lastUninstallPartId = nil

        originalInstallPerform(self)
    end

    Events.OnMechanicActionDone.Add(function(chr, success)
        if not chr then return end
        if not chr:isLocalPlayer() then return end
        if not lastInstallPartId then return end

        local partId = lastInstallPartId
        lastInstallPartId = nil

        if not success then
            DCS_dprint("[DCS] OnMechanicActionDone: install FAILED for part=" .. partId)
            return
        end

        local partGroup = VEHICLE_PART_GROUPS[partId] or partId
        local today = os.date("!%Y%m%d")

        DCS_dprint("[DCS] OnMechanicActionDone: install SUCCESS partId=" .. partId .. " partGroup=" .. partGroup)

        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "vehiclePartInstall"
            and not DCS_Sync.isCompleted(ch.id) then
                if not ch.targetPart or ch.targetPart == partGroup then
                    DCS_dprint("[DCS] Vehicle part install match: " .. ch.id .. " part=" .. partId .. " group=" .. partGroup)
                    sendClientCommand(chr, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end)

    DCS_dprint("[DCS] Vehicle install tracking registered via start() + OnMechanicActionDone")
else
    print("[DCS] WARNING: ISInstallVehiclePart.perform not found")
end
