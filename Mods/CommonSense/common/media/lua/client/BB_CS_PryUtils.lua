-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

BB_CS_PryUtils = {}

---@param item InventoryItem
function BB_CS_PryUtils.PredicateNotBroken(item)
	return not item:isBroken()
end

---@param playerObj IsoPlayer
---@param override boolean|nil
---@return InventoryItem|nil
function BB_CS_PryUtils.GetPryingTool(playerObj, override)

    if override then return nil end
    if not playerObj then return nil end

    local playerInv = playerObj:getInventory()
    local pryingTool = nil

	for _, tool in pairs(CommonSense.PryingTools) do
        pryingTool = playerInv:getFirstTypeEvalRecurse(tool, BB_CS_PryUtils.PredicateNotBroken)
        if pryingTool then break end
  	end

    return pryingTool
end

---@param obj IsoObject
---@return boolean
function BB_CS_PryUtils.IsReinforcedDoor(obj)
    if not instanceof(obj, "IsoDoor") then return false end --[[@cast obj IsoDoor]]
    local sprite = obj:getSprite()
    local spriteName = sprite and sprite:getName() or ""
    local maxHealth = obj.getMaxHealth and obj:getMaxHealth() or 0
    return sprite and (spriteName == "fixtures_doors_01_32" 
    or spriteName == "fixtures_doors_01_33" 
    or spriteName == "location_community_police_01_4" 
    or spriteName == "location_community_police_01_5"
    or maxHealth >= 2000)
end

---@param priableObject IsoObject
---@param getSoundType boolean
---@return string
function BB_CS_PryUtils.GetProperSound(priableObject, getSoundType)

    if #buildUtil.getGarageDoorObjects(priableObject) > 0 then
        if getSoundType then return "Metal" end
        return "PrisonMetalDoorBlocked"
    else
        if getSoundType then return "Wooden" end
        return "BeginRemoveBarricadePlank"
    end
end

---@param worldobjects IsoObject[]
---@param priableObject GameEntity
---@param playerObj IsoPlayer
---@param pryingTool InventoryItem
function BB_CS_PryUtils.PryDoorOrWindowOpen(worldobjects, priableObject, playerObj, pryingTool)

    local toolID = pryingTool:getFullType()
    local toolContainer = nil

    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, pryingTool)
    
    if not playerObj:hasEquipped(toolID) then
        toolContainer = pryingTool:getContainer()
        ISInventoryPaneContextMenu.equipWeapon(pryingTool, true, true, playerObj:getPlayerNum())
    end

    luautils.walkAdjWindowOrDoor(playerObj, priableObject:getSquare(), priableObject, true)
    ISTimedActionQueue.add(BB_CS_PryTimedAction:PryDoorOrWindow(worldobjects, priableObject, playerObj, toolContainer, 190))
end

---@param vehicle BaseVehicle
---@param vehiclePart VehiclePart
---@param playerObj IsoPlayer
---@param pryingTool InventoryItem
function BB_CS_PryUtils.PryVehicleOpen(vehicle, vehiclePart, playerObj, pryingTool)

    local toolID = pryingTool:getFullType()
    local toolContainer = nil

    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, pryingTool)

    if not playerObj:hasEquipped(toolID) then
        toolContainer = pryingTool:getContainer()
        ISInventoryPaneContextMenu.equipWeapon(pryingTool, true, true, playerObj:getPlayerNum())
    end
    
    ISTimedActionQueue.add(BB_CS_PryTimedAction:PryVehicleDoor(vehicle, vehiclePart, playerObj, toolContainer, 190))
end

---@param playerObj IsoPlayer
---@param failBoost integer
---@return boolean
function BB_CS_PryUtils.PrySuccessfully(playerObj, failBoost)

    if playerObj:hasTrait(CharacterTrait.BURGLAR) then
        return (ZombRand(10) > 1)
    end

    local succeedChance = ZombRand(100)
    local strengthLevel = playerObj:getPerkLevel(Perks.Strength)
    local failChance = ((180 / strengthLevel) + failBoost) * SandboxVars.CommonSense.PryingChanceMultiplier

    return (succeedChance > failChance)
end
