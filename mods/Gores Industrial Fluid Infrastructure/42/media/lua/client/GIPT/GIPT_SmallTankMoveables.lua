require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_Storage"
require "GIPT/GIPT_NativeSmallTank"
require "Moveables/ISMoveableSpriteProps"
require "Moveables/ISMoveablesAction"
require "TimedActions/ISDismantleAction"
require "ISUI/ISDisassembleMenu"

local function actionTarget(action)
    if not action then return nil end
    if action.moveProps and action.moveProps.object then return action.moveProps.object end
    return action.object or action.item or action.thumpable
end

local function isSmallSpriteName(name)
    local index = GIPT.getSpriteIndex(name)
    return index ~= nil and index >= 72 and index <= 75
end

local function isSmallMoveProps(moveProps, obj)
    if obj and GIPT.getTankClass(obj) == "SMALL" then return true end
    return moveProps and isSmallSpriteName(moveProps.spriteName)
end

local function findSmallObject(moveProps, square, obj)
    if obj and GIPT.getTankClass(obj) == "SMALL" then return obj end
    if moveProps and moveProps.object and GIPT.getTankClass(moveProps.object) == "SMALL" then return moveProps.object end
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local candidate = objects:get(i)
        if GIPT.getTankClass(candidate) == "SMALL" then return candidate end
    end
    return nil
end

local function smallTankContainsFluid(obj)
    if not obj or GIPT.getTankClass(obj) ~= "SMALL" or not obj:getSquare() then return false end
    if GIPT.isNativeSmallTankMoveCleanup and GIPT.isNativeSmallTankMoveCleanup(obj) then return false end
    return GIPT.smallTankHasAnyFluid(obj) == true
end

GIPT.smallTankContainsFluid = smallTankContainsFluid

local function inventoryContainerEmpty(obj)
    if not obj or not obj.getContainer then return true end
    local ok, container = pcall(function() return obj:getContainer() end)
    if not ok or not container then return true end
    local okEmpty, empty = pcall(function() return container:isEmpty() end)
    return okEmpty and empty == true
end

local function blockedMoveMode(mode)
    return mode == "pickup" or mode == "rotate" or mode == "scrap"
end

local function notify(character)
    if character and HaloTextHelper then
        HaloTextHelper.addText(character, "Drain the compact tank before moving or dismantling it.")
    end
end

local function objectsFromGrid(grid)
    local objects = {}
    if not grid then return objects end
    for _, member in ipairs(grid) do
        if member.object then table.insert(objects, member.object) end
    end
    return objects
end

local function clearMoveIdentity(obj)
    if not obj then return end
    local objectData = obj:getModData()
    objectData.GIPT = nil
    objectData.GIPT_Protected = nil
    objectData.GIPT_Indestructible = nil
end

local function finishCleanup()
    if GIPT.endNativeSmallTankMoveCleanup then GIPT.endNativeSmallTankMoveCleanup() end
end

-- The original compact sprites carried the vanilla propane-barbecue marker.
-- Existing saves can therefore still contain IsoBarbecue instances even after
-- the corrected tile definitions are installed. These narrow fallbacks keep
-- the normal skill, tool, inventory-space and placement checks while ignoring
-- only that obsolete built-in propane-tank state.
if ISMoveableSpriteProps and not ISMoveableSpriteProps.GIPT_CompactTankPatched then
    ISMoveableSpriteProps.GIPT_CompactTankPatched = true

    local originalCanPickUpInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
    ISMoveableSpriteProps.canPickUpMoveableInternal = function(self, character, square, obj, isMulti)
        local allowed = originalCanPickUpInternal(self, character, square, obj, isMulti)
        if allowed or not isSmallMoveProps(self, obj) then return allowed end

        local target = findSmallObject(self, square, obj)
        if not target or smallTankContainsFluid(target) then return false end
        if not self.isMoveable or not instanceof(square, "IsoGridSquare") then return false end
        if not inventoryContainerEmpty(target) then return false end

        self.yOffsetCursor = target:getRenderYOffset()
        if (not isMulti or self.isForceSingleItem)
            and not character:getInventory():hasRoomFor(character, self.weight) then
            return false
        end

        if character and instanceof(character, "IsoGameCharacter") then
            -- B42.19 defines the Wrench moveables tool without an associated
            -- perk. Pairing it with PickUpLevel therefore creates an impossible
            -- skill requirement. Compact tanks intentionally require only a wrench.
            local hasTool = not self.pickUpTool or self:hasTool(character, "pickup") ~= nil
            return hasTool
        end
        return true
    end

    local originalPickUpViaCursor = ISMoveableSpriteProps.pickUpMoveableViaCursor
    ISMoveableSpriteProps.pickUpMoveableViaCursor = function(self, character, square, origSpriteName, moveCursor)
        -- Keep the vanilla multi-tile pickup pipeline. It already creates one
        -- Moveables.Moveable item for ForceSingleItem grids and synchronises the
        -- timed-action queue correctly. We only clear the old empty installation
        -- identity before vanilla transfers object data into the inventory item.
        if not self or not isSmallSpriteName(self.spriteName) then
            return originalPickUpViaCursor(self, character, square, origSpriteName, moveCursor)
        end

        local target = findSmallObject(self, square, nil)
        if not target or smallTankContainsFluid(target) then
            notify(character)
            return false
        end

        local grid = self:getSpriteGridInfo(square, true)
        if not grid or #grid == 0 then return false end
        for _, member in ipairs(grid) do
            if not member.object or GIPT.getTankClass(member.object) ~= "SMALL" then return false end
            if smallTankContainsFluid(member.object) or not inventoryContainerEmpty(member.object) then return false end
        end

        local objects = objectsFromGrid(grid)
        for _, obj in ipairs(objects) do clearMoveIdentity(obj) end

        local cleanupStarted = GIPT.beginNativeSmallTankMoveCleanup
            and GIPT.beginNativeSmallTankMoveCleanup(objects)
        if not cleanupStarted then return false end

        local ok, result = pcall(originalPickUpViaCursor, self, character, square, origSpriteName, moveCursor)
        finishCleanup()
        if not ok then error(result) end
        return result
    end

    local originalCanRotate = ISMoveableSpriteProps.canRotateMoveable
    ISMoveableSpriteProps.canRotateMoveable = function(self, square, obj, origProps)
        local allowed = originalCanRotate(self, square, obj, origProps)
        if allowed then return true end
        if not isSmallMoveProps(self, obj) or not origProps or not isSmallMoveProps(origProps, obj) then return false end
        if not self.isMoveable or not self.isMultiSprite or not origProps.isMoveable or not origProps.isMultiSprite then return false end

        local ok, result = pcall(function()
            local origGrid = origProps:getSpriteGridInfo(square, true)
            if not origGrid or #origGrid == 0 then return false end
            for _, member in ipairs(origGrid) do
                if not member.object or smallTankContainsFluid(member.object) then return false end
                if not inventoryContainerEmpty(member.object) then return false end
                if member.square:has("IsTableTop") or member.object:isSatChair() then return false end
            end

            local anchorSquare = self:findOriginalSquare(origGrid, self.sprite)
            local targetGrid = self:getSpriteGridInfo(anchorSquare, false)
            if not targetGrid then return false end

            local firstSquare = origGrid[1].square
            local spriteGrid = self.sprite and self.sprite:getSpriteGrid()
            if spriteGrid and self:isWallBetweenParts(spriteGrid, firstSquare:getX(), firstSquare:getY(), firstSquare:getZ()) then
                return false
            end

            for _, targetMember in ipairs(targetGrid) do
                local covered = false
                for _, originalMember in ipairs(origGrid) do
                    if targetMember.square == originalMember.square then
                        covered = true
                        break
                    end
                end
                if not covered and not self:canPlaceMoveableInternal(nil, targetMember.square, nil) then
                    return false
                end
            end
            return true
        end)
        return ok and result == true
    end

    local originalRotateViaCursor = ISMoveableSpriteProps.rotateMoveableViaCursor
    ISMoveableSpriteProps.rotateMoveableViaCursor = function(self, character, square, origSpriteName, moveCursor)
        if not self or not isSmallSpriteName(self.spriteName) or not isSmallSpriteName(origSpriteName) then
            return originalRotateViaCursor(self, character, square, origSpriteName, moveCursor)
        end

        local origProps = ISMoveableSpriteProps.new(origSpriteName)
        local origGrid = origProps and origProps:getSpriteGridInfo(square, true) or nil
        if not origGrid or #origGrid == 0 then return false end
        for _, member in ipairs(origGrid) do
            if not member.object or GIPT.getTankClass(member.object) ~= "SMALL" then return false end
            if smallTankContainsFluid(member.object) or not inventoryContainerEmpty(member.object) then
                notify(character)
                return false
            end
        end

        local anchorSquare = self:findOriginalSquare(origGrid, self.sprite)
        local objects = objectsFromGrid(origGrid)
        for _, obj in ipairs(objects) do clearMoveIdentity(obj) end

        local cleanupStarted = GIPT.beginNativeSmallTankMoveCleanup
            and GIPT.beginNativeSmallTankMoveCleanup(objects)
        if not cleanupStarted then return false end

        local ok, result = pcall(originalRotateViaCursor, self, character, square, origSpriteName, moveCursor)
        finishCleanup()
        if not ok then error(result) end

        -- OnObjectAdded is intentionally suppressed during the move. Recreate a
        -- fresh empty native component on the newly rotated controller now.
        if anchorSquare then
            local placedGrid = self:getSpriteGridInfo(anchorSquare, true)
            if placedGrid then
                for _, member in ipairs(placedGrid) do
                    if member.object and GIPT.getTankClass(member.object) == "SMALL" then
                        GIPT.ensureNativeSmallTank(member.object, true)
                        GIPT.ensureTankData(member.object)
                        break
                    end
                end
            end
        end
        return result
    end

    local originalCanScrapInternal = ISMoveableSpriteProps.canScrapObjectInternal
    ISMoveableSpriteProps.canScrapObjectInternal = function(self, result, obj)
        local allowed = originalCanScrapInternal(self, result, obj)
        if allowed or not isSmallMoveProps(self, obj) then return allowed end
        return obj ~= nil and not smallTankContainsFluid(obj) and inventoryContainerEmpty(obj)
    end
end

if ISMoveablesAction and not ISMoveablesAction.GIPT_SmallTankStatePatched then
    ISMoveablesAction.GIPT_SmallTankStatePatched = true

    local originalIsValid = ISMoveablesAction.isValid
    ISMoveablesAction.isValid = function(self)
        if blockedMoveMode(self.mode) and smallTankContainsFluid(actionTarget(self)) then
            -- Vanilla invalid-action branches call stop() before returning false.
            -- Doing the same keeps the Java action and Lua queue in sync.
            self:stop()
            return false
        end
        return originalIsValid(self)
    end

    local originalStart = ISMoveablesAction.start
    ISMoveablesAction.start = function(self)
        if blockedMoveMode(self.mode) and smallTankContainsFluid(actionTarget(self)) then
            notify(self.character)
            self:forceStop()
            self:stop()
            return
        end
        return originalStart(self)
    end

    local originalComplete = ISMoveablesAction.complete
    ISMoveablesAction.complete = function(self)
        if blockedMoveMode(self.mode) and smallTankContainsFluid(actionTarget(self)) then
            notify(self.character)
            self:stop()
            return false
        end
        return originalComplete(self)
    end
end

if ISDismantleAction and not ISDismantleAction.GIPT_SmallTankStatePatched then
    ISDismantleAction.GIPT_SmallTankStatePatched = true
    local originalIsValid = ISDismantleAction.isValid
    ISDismantleAction.isValid = function(self)
        if smallTankContainsFluid(self.thumpable) then
            self:stop()
            return false
        end
        return originalIsValid(self)
    end

    if ISDismantleAction.start then
        local originalStart = ISDismantleAction.start
        ISDismantleAction.start = function(self)
            if smallTankContainsFluid(self.thumpable) then
                notify(self.character)
                self:forceStop()
                self:stop()
                return
            end
            return originalStart(self)
        end
    end
end

if ISDisassembleMenu and not ISDisassembleMenu.GIPT_SmallTankStatePatched then
    ISDisassembleMenu.GIPT_SmallTankStatePatched = true
    local originalDisassemble = ISDisassembleMenu.disassemble
    ISDisassembleMenu.disassemble = function(playerObj, data)
        if data and smallTankContainsFluid(data.object) then
            notify(playerObj)
            return
        end
        return originalDisassemble(playerObj, data)
    end
end
