-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

local OnShowRadialMenuOutside = ISVehicleMenu.showRadialMenuOutside

---@param playerObj IsoPlayer
local function showRadialMenuOutsideCrowbar(playerObj)

    if not SandboxVars.CommonSense.PryingMechanic then return end
    if not SandboxVars.CommonSense.PryVehicleDoors then return end

	local vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
    if not vehicle then return end

	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    local pryingTool = BB_CS_PryUtils.GetPryingTool(playerObj)
    if not menu or not pryingTool then return end

    local doorPart = vehicle:getUseablePart(playerObj)

    if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() then

        local isHood = (doorPart:getId() == "EngineDoor")
        if not doorPart:getDoor():isLocked() or isHood then return end

        menu:addSlice(getText("ContextMenu_CS_PryOpen"), getTexture("media/ui/vehicles/PryOpen.png"), BB_CS_PryUtils.PryVehicleOpen, vehicle, doorPart, playerObj, pryingTool)
    end
end

---@param playerObj IsoPlayer
function ISVehicleMenu.showRadialMenuOutside(playerObj)

	if playerObj:getVehicle() then return end

	OnShowRadialMenuOutside(playerObj)
    showRadialMenuOutsideCrowbar(playerObj)
end