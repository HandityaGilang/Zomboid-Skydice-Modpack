-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

---@param player integer
---@param context ISContextMenu
---@param worldobjects IsoObject[]
---@param test boolean
local function onFillWorldObjectContextMenuPryOpen(player, context, worldobjects, test)
    if not SandboxVars.CommonSense.PryingMechanic then return end

    local playerObj = getSpecificPlayer(player)
    local pryingTool = BB_CS_PryUtils.GetPryingTool(playerObj)
    if not pryingTool then return end

    local priableObject = nil --[[@as IsoDoor|IsoWindow|nil]]
    for _, obj in ipairs(worldobjects) do
        if ISWorldObjectContextMenu.isThumpDoor(obj) then
            priableObject = obj
            break
        end
    end

    -- Look for objects around player in case they are trying to pry open something not visible at the square click.
    -- THANKS B42 =3
    local fetch = ISWorldObjectContextMenu.fetchVars
    if not priableObject and fetch and fetch.clickedSquare then
        local clickedSqX = fetch.clickedSquare:getX()
        local clickedSqY = fetch.clickedSquare:getY()
        local clickedSqZ = fetch.clickedSquare:getZ()

        for dx = -1, 1 do
            for dy = -1, 1 do
                local sq = getCell():getGridSquare(clickedSqX + dx, clickedSqY + dy, clickedSqZ)
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size()-1 do
                        local obj = objs:get(i)
                        if ISWorldObjectContextMenu.isThumpDoor(obj) then
                            priableObject = obj
                            break
                        end
                    end
                end
            end
            if priableObject then break end
        end
    end
	if not priableObject then return end

    local isReinforcedDoor = BB_CS_PryUtils.IsReinforcedDoor(priableObject)
    if isReinforcedDoor and not SandboxVars.CommonSense.PrySafeDoors then return end

    local canPryOpenReinforcedDoors = false
    if SandboxVars.CommonSense.PrySafeDoors then canPryOpenReinforcedDoors = true end
    if canPryOpenReinforcedDoors then
        local strengthLevel = playerObj:getPerkLevel(Perks.Strength)
        if strengthLevel < SandboxVars.CommonSense.ReinforcedDoorLevel then
            canPryOpenReinforcedDoors = false
        end
    end

    local isSmashed = priableObject.isSmashed and priableObject:isSmashed()
    --local couldBeOpen = priableObject.couldBeOpen and priableObject:couldBeOpen(playerObj)
    
    if instanceof(priableObject, "IsoDoor")
    and SandboxVars.CommonSense.PryBuildingDoors
    and not priableObject:IsOpen()
    and not priableObject:isBarricaded()
    and priableObject:isLocked() then --[[@cast priableObject IsoDoor]]
    
        local isGarage = false
        local garageDoorObjects = buildUtil.getGarageDoorObjects(priableObject)
        if garageDoorObjects then
            for _=1, #garageDoorObjects do
                if not SandboxVars.CommonSense.PryGarageDoors then return end
                isGarage = true
                break
            end
        end
        
        local submenu = BB_CS_Utils.getSubMenuByName(context, getText("Door")) or context
        local option = submenu:addOptionOnTop(getText("ContextMenu_CS_PryOpen_Door"), worldobjects, BB_CS_PryUtils.PryDoorOrWindowOpen, priableObject, playerObj, pryingTool)
        option.iconTexture = getTexture("media/ui/vehicles/PryOpen.png")
        local description = getText("Tooltip_CS_PryOpenDoor")

        if isReinforcedDoor and not canPryOpenReinforcedDoors then
            description = string.format(getText("Tooltip_CS_CantPryOpenRDoor"), SandboxVars.CommonSense.ReinforcedDoorLevel)
            option.notAvailable = true
        end

        BB_CS_Utils.addTooltip(description, option)
        return

    elseif instanceof(priableObject, "IsoWindow")
    and SandboxVars.CommonSense.PryWindows
    and not priableObject:IsOpen()
    and not isSmashed
    and priableObject:isLocked() then --[[@cast priableObject IsoWindow]]

        local submenu = BB_CS_Utils.getSubMenuByName(context, getText("Window")) or context
        local option = submenu:addOptionOnTop(getText("ContextMenu_CS_PryOpen_Window"), worldobjects, BB_CS_PryUtils.PryDoorOrWindowOpen, priableObject, playerObj, pryingTool)
        option.iconTexture = getTexture("media/ui/vehicles/PryOpen.png")
        local description = getText("Tooltip_CS_PryOpenWindow")

        if priableObject:isPermaLocked() or priableObject:isBarricaded() then
            description = getText("Tooltip_CS_CantPryOpenWindow")
            option.notAvailable = true
        end

        BB_CS_Utils.addTooltip(description, option)
        return
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenuPryOpen)