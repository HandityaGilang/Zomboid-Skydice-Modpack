require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_Storage"
require "TimedActions/ISDestroyStuffAction"
require "TimedActions/ISDismantleAction"
require "Moveables/ISMoveablesAction"
require "Moveables/ISMoveableSpriteProps"
require "ISUI/ISDisassembleMenu"

local function protectionEnabled()
    return SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.IndestructibleInstallations == true
end

local function adminDestructionAllowed(character)
    local developerAccess = false
    if getDebug then
        local ok, value = pcall(getDebug)
        developerAccess = ok and value == true
    end
    if getCore then
        local ok, value = pcall(function() return getCore():getDebug() end)
        developerAccess = developerAccess or (ok and value == true)
    end
    if not developerAccess then return false end
    -- In multiplayer, developer tools also require admin access. In
    -- single-player, accessLevel is normally empty.
    if isClient and isClient() then
        local level = character and character.getAccessLevel and tostring(character:getAccessLevel() or "") or ""
        return level == "admin"
    end
    return true
end

local function isProtectedObject(obj)
    if not protectionEnabled() or not obj then return false end
    local sprite=obj:getSprite(); if not sprite or not GIPT.isPropaneSpriteName(sprite:getName()) then return false end
    return GIPT.getTankClass(obj)=="LARGE"
end

GIPT.isProtectedInstallationObject = isProtectedObject

local function isLargeMoveableSpriteName(name)
    local index = GIPT.getSpriteIndex(name)
    return index ~= nil and index >= 0 and index <= 71
end

-- Prevent the rotate cursor from drawing a misleading multi-tile footprint for
-- protected industrial installations. The action was already rejected later;
-- this blocks it at cursor selection instead.
if ISMoveableSpriteProps and not ISMoveableSpriteProps.GIPT_LargeRotateCursorPatched then
    ISMoveableSpriteProps.GIPT_LargeRotateCursorPatched = true
    local originalCanManuallyRotate = ISMoveableSpriteProps.canManuallyRotate
    ISMoveableSpriteProps.canManuallyRotate = function(self)
        if protectionEnabled() and isLargeMoveableSpriteName(self and self.spriteName) then return false end
        return originalCanManuallyRotate(self)
    end
end

local function notify(character)
    if character and HaloTextHelper then
        HaloTextHelper.addText(character, "This propane installation is protected.")
    end
end

local function worldSelectionContainsProtected(worldObjects)
    if not worldObjects then return false end
    for _, wo in ipairs(worldObjects) do
        if isProtectedObject(wo) then return true end
        local square = wo and wo:getSquare()
        if square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                if isProtectedObject(objects:get(i)) then return true end
            end
        end
    end
    return false
end

local function protectObject(obj)
    if not isProtectedObject(obj) then return end
    if obj.setMaxHealth then pcall(function() obj:setMaxHealth(1000000) end) end
    if obj.setHealth then pcall(function() obj:setHealth(1000000) end) end
    if obj.setCanBeBurned then pcall(function() obj:setCanBeBurned(false) end) end
    if obj.setCanBurn then pcall(function() obj:setCanBurn(false) end) end
    if obj.setIsThumpable then pcall(function() obj:setIsThumpable(false) end) end
    local md = obj:getModData()
    md.GIPT_Protected = true
end

local expected = {}
local installations = {}

local function copyPrimitiveTable(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for key, value in pairs(source) do
        local valueType = type(value)
        if valueType == "number" or valueType == "string" or valueType == "boolean" then
            result[key] = value
        end
    end
    return result
end

local function keyFor(x, y, z, spriteName)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z) .. ":" .. tostring(spriteName)
end

local function installationKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function squareHasSprite(square, spriteName)
    if not square then return false end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local sprite = obj and obj:getSprite()
        if sprite and sprite:getName() == spriteName then return true end
    end
    return false
end

local function squareIsBurning(square)
    if not square then return false end
    if square.isBurning then
        local ok, result = pcall(function() return square:isBurning() end)
        if ok and result then return true end
    end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and instanceof(obj, "IsoFire") then return true end
    end
    return false
end

local function getOrCreateInstallation(anchorX, anchorY, z)
    local id = installationKey(anchorX, anchorY, z)
    local installation = installations[id]
    if not installation then
        installation = {
            id = id,
            anchorX = anchorX,
            anchorY = anchorY,
            z = z,
            pieces = {},
            fireActive = false,
            clearScans = 0,
        }
        installations[id] = installation
    end
    return installation
end

local function rememberObject(obj)
    if not isProtectedObject(obj) then return end
    local square = obj:getSquare()
    local sprite = obj:getSprite()
    if not square or not sprite then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local anchorX, anchorY = GIPT.findGroupAnchor(x, y, z)
    local installation = getOrCreateInstallation(anchorX, anchorY, z)
    local spriteName = sprite:getName()
    local pieceKey = keyFor(x, y, z, spriteName)
    local entry = expected[pieceKey]
    if not entry then
        entry = {
            x = x,
            y = y,
            z = z,
            spriteName = spriteName,
            installationID = installation.id,
        }
        expected[pieceKey] = entry
    else
        entry.installationID = installation.id
    end

    -- Preserve the authoritative per-object state before fire can replace the
    -- tile. The controller carries fluidType, amount and capacity; every piece
    -- also carries its installation identity and role. Without this snapshot a
    -- recreated controller is treated as a brand-new legacy propane tank.
    local objectData = obj:getModData()
    entry.giptData = copyPrimitiveTable(objectData and objectData.GIPT)
    if obj.getPipedFuelAmount then
        local ok, value = pcall(function() return obj:getPipedFuelAmount() end)
        if ok and value ~= nil then entry.pipedFuelAmount = value end
    end

    installation.pieces[pieceKey] = entry
end

local function restoreEntry(entry)
    local square = getCell():getGridSquare(entry.x, entry.y, entry.z)
    if not square or squareHasSprite(square, entry.spriteName) then return true end
    local sprite = getSprite(entry.spriteName)
    if not sprite then return false end
    local obj = IsoObject.new(getCell(), square, sprite)
    square:AddTileObject(obj)

    local objectData = obj:getModData()
    objectData.GIPT = copyPrimitiveTable(entry.giptData)
    if entry.pipedFuelAmount ~= nil and obj.setPipedFuelAmount then
        pcall(function() obj:setPipedFuelAmount(entry.pipedFuelAmount) end)
    end

    protectObject(obj)
    if obj.transmitModData then pcall(function() obj:transmitModData() end) end
    if obj.transmitCompleteItemToServer and isClient() then
        pcall(function() obj:transmitCompleteItemToServer() end)
    end
    triggerEvent("OnObjectAdded", obj)
    return true
end

local function installationHasFire(installation)
    for _, entry in pairs(installation.pieces) do
        local square = getCell():getGridSquare(entry.x, entry.y, entry.z)
        if square and squareIsBurning(square) then return true end
    end
    return false
end

local function restoreInstallation(installation)
    local allRestored = true
    for _, entry in pairs(installation.pieces) do
        local square = getCell():getGridSquare(entry.x, entry.y, entry.z)
        if square and not squareHasSprite(square, entry.spriteName) then
            if not restoreEntry(entry) then allRestored = false end
        end
    end
    if allRestored then
        local controller = GIPT.findPropaneObject(getCell():getGridSquare(installation.anchorX, installation.anchorY, installation.z))
        if controller then
            local data = GIPT.ensureTankData(controller)
            -- Reapply the restored controller state to the cabinet bridge. This
            -- is especially important for gasoline, whose vanilla pump amount
            -- lives separately from the controller's modData.
            GIPT.syncGasolineCabinets(controller, data)
        end
    end
    return allRestored
end

local function protectNearby(player)
    if not protectionEnabled() or not player then return end
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), player:getZ()

    -- Continuously snapshot every complete connected installation while it is
    -- intact. This gives fire recovery the full expected layout before pieces
    -- begin disappearing.
    for x = px - 12, px + 12 do
        for y = py - 12, py + 12 do
            local sq = getCell():getGridSquare(x, y, pz)
            if sq then
                local objects = sq:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    protectObject(obj)
                    rememberObject(obj)
                end
            end
        end
    end

    -- Fire is tracked for the whole connected installation. Once any footprint
    -- square burns, every missing piece becomes eligible for restoration. This
    -- avoids the old timing hole where only tiles whose own square happened to
    -- be burning during a scan were remembered.
    for _, installation in pairs(installations) do
        if installation.z == pz
            and math.abs(installation.anchorX - px) <= 16
            and math.abs(installation.anchorY - py) <= 16 then

            if installationHasFire(installation) then
                installation.fireActive = true
                installation.clearScans = 0
            elseif installation.fireActive then
                installation.clearScans = installation.clearScans + 1

                -- Require several clear scans so recreated tiles are not placed
                -- back into the tail end of the same fire and destroyed again.
                if installation.clearScans >= 6 then
                    if restoreInstallation(installation) then
                        installation.fireActive = false
                        installation.clearScans = 0
                    end
                end
            end
        end
    end
end

local blockedText = { "disassemble", "dismantle", "destroy", "pick up", "pickup", "grab", "rotate" }

local function shouldBlockOption(option, allowDestroy)
    local name = string.lower(tostring(option and option.name or ""))
    for _, token in ipairs(blockedText) do
        if string.find(name, token, 1, true) then
            if allowDestroy and token == "destroy" then return false end
            return true
        end
    end
    return false
end

local function removeBlockedOptions(menu, allowDestroy)
    if not menu or not menu.options then return end
    for i = #menu.options, 1, -1 do
        local option = menu.options[i]
        if shouldBlockOption(option, allowDestroy) then
            table.remove(menu.options, i)
        elseif option and option.subOption then
            removeBlockedOptions(option.subOption, allowDestroy)
        end
    end
end

local function onContextMenu(playerNum, context, worldObjects)
    if protectionEnabled() and worldSelectionContainsProtected(worldObjects) then
        removeBlockedOptions(context, adminDestructionAllowed(getSpecificPlayer(playerNum)))
    end
end
Events.OnFillWorldObjectContextMenu.Add(onContextMenu)

local function actionTarget(action)
    if not action then return nil end
    if action.moveProps and action.moveProps.object then return action.moveProps.object end
    return action.object or action.item or action.thumpable
end

local function blockedMoveMode(mode)
    return mode == "pickup" or mode == "scrap" or mode == "rotate" or mode == "repair"
end

local function installPatches()
    if ISDestroyCursor and not ISDestroyCursor.GIPT_CanDestroyPatched then
        ISDestroyCursor.GIPT_CanDestroyPatched = true
        ISDestroyCursor.GIPT_OriginalCanDestroy = ISDestroyCursor.canDestroy
        ISDestroyCursor.canDestroy = function(self, object)
            if isProtectedObject(object) and not adminDestructionAllowed(self.character) then return false end
            return ISDestroyCursor.GIPT_OriginalCanDestroy(self, object)
        end

        ISDestroyCursor.GIPT_OriginalCreate = ISDestroyCursor.create
        ISDestroyCursor.create = function(self, x, y, z, north, sprite)
            local objects = self:getObjectList()
            local target = objects and objects[self.objectIndex]
            if isProtectedObject(target) and not adminDestructionAllowed(self.character) then notify(self.character); return end
            return ISDestroyCursor.GIPT_OriginalCreate(self, x, y, z, north, sprite)
        end
    end

    if ISDestroyStuffAction and not ISDestroyStuffAction.GIPT_ProtectionPatched then
        ISDestroyStuffAction.GIPT_ProtectionPatched = true
        ISDestroyStuffAction.GIPT_OriginalIsValid = ISDestroyStuffAction.isValid
        ISDestroyStuffAction.isValid = function(self)
            if isProtectedObject(self.item) and not adminDestructionAllowed(self.character) then
                self:stop()
                return false
            end
            return ISDestroyStuffAction.GIPT_OriginalIsValid(self)
        end
        ISDestroyStuffAction.GIPT_OriginalStart = ISDestroyStuffAction.start
        ISDestroyStuffAction.start = function(self)
            if isProtectedObject(self.item) and not adminDestructionAllowed(self.character) then
                notify(self.character)
                self:forceStop()
                self:stop()
                return
            end
            return ISDestroyStuffAction.GIPT_OriginalStart(self)
        end
        ISDestroyStuffAction.GIPT_OriginalComplete = ISDestroyStuffAction.complete
        ISDestroyStuffAction.complete = function(self)
            if isProtectedObject(self.item) and not adminDestructionAllowed(self.character) then
                notify(self.character)
                self:stop()
                return false
            end
            return ISDestroyStuffAction.GIPT_OriginalComplete(self)
        end
    end

    if ISDismantleAction and not ISDismantleAction.GIPT_ProtectionPatched then
        ISDismantleAction.GIPT_ProtectionPatched = true
        ISDismantleAction.GIPT_OriginalIsValid = ISDismantleAction.isValid
        ISDismantleAction.isValid = function(self)
            if isProtectedObject(self.thumpable) then
                self:stop()
                return false
            end
            return ISDismantleAction.GIPT_OriginalIsValid(self)
        end
    end

    -- B42 moveable furniture pipeline. This is the authoritative block for
    -- cabinet pickup, rotation and the Disassemble menu's scrap action.
    if ISMoveablesAction and not ISMoveablesAction.GIPT_ProtectionPatched then
        ISMoveablesAction.GIPT_ProtectionPatched = true
        ISMoveablesAction.GIPT_OriginalIsValid = ISMoveablesAction.isValid
        ISMoveablesAction.isValid = function(self)
            local target = actionTarget(self)
            if blockedMoveMode(self.mode) and isProtectedObject(target) then
                self:stop()
                return false
            end
            return ISMoveablesAction.GIPT_OriginalIsValid(self)
        end
        ISMoveablesAction.GIPT_OriginalStart = ISMoveablesAction.start
        ISMoveablesAction.start = function(self)
            local target = actionTarget(self)
            if blockedMoveMode(self.mode) and isProtectedObject(target) then
                notify(self.character)
                self:forceStop()
                self:stop()
                return
            end
            return ISMoveablesAction.GIPT_OriginalStart(self)
        end
        ISMoveablesAction.GIPT_OriginalComplete = ISMoveablesAction.complete
        ISMoveablesAction.complete = function(self)
            local target = actionTarget(self)
            if blockedMoveMode(self.mode) and isProtectedObject(target) then
                notify(self.character)
                self:stop()
                return false
            end
            return ISMoveablesAction.GIPT_OriginalComplete(self)
        end
    end

    -- Filter protected pieces before vanilla builds the Disassemble submenu.
    if ISDisassembleMenu and not ISDisassembleMenu.GIPT_ProtectionPatched then
        ISDisassembleMenu.GIPT_ProtectionPatched = true
        ISDisassembleMenu.GIPT_OriginalCreateMenu = ISDisassembleMenu.createMenu
        ISDisassembleMenu.createMenu = function(worldObjects, context, playerObj)
            if not protectionEnabled() then
                return ISDisassembleMenu.GIPT_OriginalCreateMenu(worldObjects, context, playerObj)
            end
            local filtered = {}
            for _, obj in ipairs(worldObjects or {}) do
                if not isProtectedObject(obj) then table.insert(filtered, obj) end
            end
            return ISDisassembleMenu.GIPT_OriginalCreateMenu(filtered, context, playerObj)
        end
        ISDisassembleMenu.GIPT_OriginalDisassemble = ISDisassembleMenu.disassemble
        ISDisassembleMenu.disassemble = function(playerObj, data)
            if data and isProtectedObject(data.object) then notify(playerObj); return end
            return ISDisassembleMenu.GIPT_OriginalDisassemble(playerObj, data)
        end
    end
end

local tick = 0
local function onTick()
    installPatches()
    tick = tick + 1
    if tick < 60 then return end
    tick = 0
    protectNearby(getPlayer())
end
Events.OnTick.Add(onTick)
Events.OnGameStart.Add(installPatches)
