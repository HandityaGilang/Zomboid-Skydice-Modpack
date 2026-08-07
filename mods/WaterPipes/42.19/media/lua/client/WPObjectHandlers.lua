local function checkForAddition(square)
    local x, y, z = square:getX(), square:getY(), square:getZ()

    local isoBarrel = WPIso.GetBarrel(square)
    if isoBarrel then
        local w, wmax = WPIso.GetWaterStatus(isoBarrel)
        local bid
        local building = square:getBuilding()
        if building then
            local def = building:getDef()
            bid = def:getIDString()
        end
        WPVirtual.BarrelAdd(x, y, z, wmax * 100, bid)
        return
    end

    local isoPump = WPIso.GetPump(square)
    if isoPump then
        local spriteName = isoPump:getSprite():getName()
        local sprite = getSprite(spriteName)
        local object = IsoClothingDryer.new(square:getCell(), square, sprite)
        object:setActivated(false)
        object:setMovedThumpable(true)
        object:createContainersFromSpriteProperties()

        object:transmitCompleteItemToClients()
        square:AddSpecialObject(object)

        isoPump:getModData().silentRemove = true
        square:transmitRemoveItemFromSquare(isoPump)

        WPVirtual.PumpAdd(x, y, z)
        return
    end

    -- Valves, flowmeters and sprinklers now register server-side in their
    -- BuildRecipeCode.OnCreate hooks (works in MP). Here we only handle NEW pipe
    -- creation + auto-connect. The gmd.Pipes guard prevents this from re-firing when an
    -- overlay (valve/flowmeter/sprinkler) is built on an already-registered pipe.
    local isoPipe = WPIso.GetPipe(square)
    if isoPipe then
        local gmd = GetWPModData()
        local alreadyPipe = gmd and gmd.Pipes and gmd.Pipes[WPUtils.Coords2Id(x, y, z)]
        if not alreadyPipe then
            local pipeSpriteName = isoPipe:getSprite():getName()
            local sprite = getSprite(pipeSpriteName)
            local object = IsoObject.new(square:getCell(), square, sprite)
            square:transmitRemoveItemFromSquare(isoPipe)
            square:AddSpecialObject(object)
            object:transmitCompleteItemToClients()
            WPIso.BuildPipe(square)
        end
    end
end

local function checkForRemoval(square)
    local x, y, z = square:getX(), square:getY(), square:getZ()

    local isoBarrel = WPIso.GetBarrel(square)
    if not isoBarrel then
        WPVirtual.BarrelRemove(x, y, z)
    end

    local isoPump = WPIso.GetPump(square)
    if not isoPump then
        WPVirtual.PumpRemove(x, y, z)
    end

    local isoSprinkler = WPIso.GetSprinkler(square)
    if not isoSprinkler then
        WPVirtual.SprinklerRemove(x, y, z)
    end

    local isoPipe = WPIso.GetPipe(square)
    if not isoPipe then
        WPVirtual.PipeRemove(x, y, z)
    end

    local isoValve = WPIso.GetValve(square)
    if not isoValve then
        WPVirtual.ValveRemove(x, y, z)
    end

    local isoFlowmeter = WPIso.GetFlowmeter(square)
    if not isoFlowmeter then
        WPVirtual.FlowmeterRemove(x, y, z)
    end
end

local function onObjectAboutToBeRemoved(object)
    if object:getModData().silentRemove then return end
    local square = object:getSquare()
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    if WPIso.IsPump(object) then
        WPVirtual.PumpRemove(x, y, z)
    elseif WPIso.IsPipe(object) then
        WPVirtual.PipeRemove(x, y, z)
    elseif WPIso.IsValve(object) then
        WPVirtual.ValveRemove(x, y, z)
    elseif WPIso.IsFlowmeter(object) then
        WPVirtual.FlowmeterRemove(x, y, z)
    elseif WPIso.IsBarrel(object) then
        WPVirtual.BarrelRemove(x, y, z)
    elseif WPIso.IsSprinkler(object) then
        WPVirtual.SprinklerRemove(x, y, z)
    end
end


LuaEventManager.AddEvent("OnBuildActionPerform")

local function onObjectBuild(data)
    local square = data.square
    if not square then return end

    checkForAddition(square)
end

LuaEventManager.AddEvent("OnMoveablesActionComplete")

local function onObjectMove(data)
    local square = data.square
    if not square then return end

    local mode = data.mode
    if not mode then return end

    if mode == "place" then
        checkForAddition(square)
    elseif mode == "pickup" then
        checkForRemoval(square)
    end
end

Events.OnBuildActionPerform.Remove(onObjectBuild)
Events.OnBuildActionPerform.Add(onObjectBuild)

Events.OnMoveablesActionComplete.Remove(onObjectMove)
Events.OnMoveablesActionComplete.Add(onObjectMove)

Events.OnObjectAboutToBeRemoved.Remove(onObjectAboutToBeRemoved)
Events.OnObjectAboutToBeRemoved.Add(onObjectAboutToBeRemoved)
