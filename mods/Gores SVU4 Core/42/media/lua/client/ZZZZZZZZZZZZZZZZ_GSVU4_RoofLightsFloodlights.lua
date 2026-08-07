--========================================================
--
-- Vehicle-part spotlight control plus coloured-bulb picker UI.
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.RoofLightFlood = GSVU4.RoofLightFlood or {}

local Flood = GSVU4.RoofLightFlood
Flood.Tick = 0
Flood.ColorPanelInstance = Flood.ColorPanelInstance or nil


local function getTextSafe(key, fallback)
    if getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= key then return value end
    end
    return fallback or key
end

local function itemFullType(item)
    if not item then return nil end
    if item.getFullType then
        local ok, value = pcall(function() return item:getFullType() end)
        if ok and value then return tostring(value) end
    end
    local moduleName = "Base"
    if item.getModule then
        local ok, value = pcall(function() return item:getModule() end)
        if ok and value then moduleName = tostring(value) end
    end
    if item.getType then
        local ok, value = pcall(function() return item:getType() end)
        if ok and value then return moduleName .. "." .. tostring(value) end
    end
    return nil
end

local function findInventoryItemByFullType(playerObj, fullType)
    if not playerObj or not fullType or not playerObj.getInventory then return nil end
    local inv = playerObj:getInventory()
    if not inv or not inv.getItems then return nil end
    local items = inv:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if itemFullType(item) == fullType then return item end
    end
    return nil
end

local function removeInventoryItem(item)
    if not item then return false end
    local container = item.getContainer and item:getContainer() or nil
    if container and container.Remove then
        local ok = pcall(function() container:Remove(item) end)
        if ok then return true end
    end
    return false
end


local function countInventoryItemsByFullType(playerObj, fullType)
    if not playerObj or not fullType or not playerObj.getInventory then return 0 end
    local inv = playerObj:getInventory()
    if not inv or not inv.getItems then return 0 end
    local items = inv:getItems()
    if not items then return 0 end
    local count = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if itemFullType(item) == fullType then count = count + 1 end
    end
    return count
end

local function consumeInventoryItemsByFullType(playerObj, fullType, amount)
    local remaining = math.ceil(tonumber(amount) or 0)
    if remaining <= 0 then return true end
    while remaining > 0 do
        local item = findInventoryItemByFullType(playerObj, fullType)
        if not item then return false end
        if not removeInventoryItem(item) then return false end
        remaining = remaining - 1
    end
    return true
end

local function getRoofLightColorDef(colorKey)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.getColorDef then
        return GSVU4.RoofLights.getColorDef(colorKey)
    end
    return nil
end

-- Forward declarations.
local roofLightsInstalled
local roofLightsActive
local applyVehiclePartLight
local addVehicleArgs
local openRoofLightColorPanel
local setRoofLightColor

local DIRECTION_ROWS = {
    { upgradeId = "RoofLights",      partId = "GSVU4RoofLights",      label = "Front" },
    { upgradeId = "RoofLightsLeft",  partId = "GSVU4RoofLightsLeft",  label = "Left" },
    { upgradeId = "RoofLightsRight", partId = "GSVU4RoofLightsRight", label = "Right" },
    { upgradeId = "RoofLightsRear",  partId = "GSVU4RoofLightsRear",  label = "Rear" },
}

local function getDirectionRow(upgradeId)
    for _, row in ipairs(DIRECTION_ROWS) do
        if row.upgradeId == upgradeId or row.partId == upgradeId then
            return row
        end
    end
    return DIRECTION_ROWS[1]
end

local function getCurrentColorKey(vehicle, upgradeId)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.getVehicleColorKey then
        local ok, value = pcall(function() return GSVU4.RoofLights.getVehicleColorKey(vehicle, upgradeId) end)
        if ok and value then return tostring(value) end
    end
    return "WarmWhite"
end

roofLightsInstalled = function(vehicle, upgradeId)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.isInstalled then
        local ok, result = pcall(function() return GSVU4.RoofLights.isInstalled(vehicle, upgradeId) end)
        if ok then return result == true end
    end
    if not vehicle or not vehicle.getModData then return false end
    local vdata = vehicle:getModData()
    local up = vdata and vdata.gUpgrades or nil
    if not up then return false end
    if upgradeId then
        return up[upgradeId] ~= nil and up[upgradeId].grade ~= nil
    end
    return (up.RoofLights and up.RoofLights.grade ~= nil)
        or (up.RoofLightsLeft and up.RoofLightsLeft.grade ~= nil)
        or (up.RoofLightsRight and up.RoofLightsRight.grade ~= nil)
        or (up.RoofLightsRear and up.RoofLightsRear.grade ~= nil)
end

local function roofLightPartExists(vehicle, upgradeId)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.hasLightPart then
        local ok, result = pcall(function() return GSVU4.RoofLights.hasLightPart(vehicle, upgradeId) end)
        if ok then return result == true end
    end
    if not vehicle or not vehicle.getPartById then return false end
    local partId = nil
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.getPartIdForUpgrade then
        local ok, v = pcall(function() return GSVU4.RoofLights.getPartIdForUpgrade(upgradeId) end)
        if ok then partId = v end
    end
    partId = partId or "GSVU4RoofLights"
    local ok, part = pcall(function() return vehicle:getPartById(partId) end)
    return ok and part ~= nil
end

local function roofLightDirectionUsable(vehicle, upgradeId)
    return roofLightsInstalled(vehicle, upgradeId) and roofLightPartExists(vehicle, upgradeId)
end

roofLightsActive = function(vehicle)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.isActive then
        local ok, result = pcall(function() return GSVU4.RoofLights.isActive(vehicle) end)
        if ok then return result == true end
    end
    if not roofLightsInstalled(vehicle) then return false end
    local vdata = vehicle:getModData()
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofLights
    return upgrade ~= nil and upgrade.active == true
end

applyVehiclePartLight = function(vehicle, active)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applyLightActive then
        local ok, result = pcall(function() return GSVU4.RoofLights.applyLightActive(vehicle, active == true) end)
        if ok then return result == true end

    end
    return false
end

local function applySingleVehiclePartLight(vehicle, targetUpgradeId, active, forceRebuild)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applySingleLight then
        local ok, result = pcall(function()
            return GSVU4.RoofLights.applySingleLight(vehicle, targetUpgradeId, active == true, forceRebuild == true)
        end)
        if ok then return result == true end

    end
    return applyVehiclePartLight(vehicle, active)
end

local function iterateVehicles(callback)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end
    if vehicles.size and vehicles.get then
        for i = 0, vehicles:size() - 1 do
            local okV, vehicle = pcall(function() return vehicles:get(i) end)
            if okV and vehicle then callback(vehicle) end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do callback(vehicle) end
    end
end

addVehicleArgs = function(args, vehicle)
    args = args or {}
    if vehicle then
        if vehicle.getId then local ok, v = pcall(function() return vehicle:getId() end); if ok then args.vehicleId = v end end
        if vehicle.getOnlineID then local ok, v = pcall(function() return vehicle:getOnlineID() end); if ok then args.vehicleOnlineId = v end end
        if vehicle.getX then local ok, v = pcall(function() return vehicle:getX() end); if ok then args.vehicleX = v end end
        if vehicle.getY then local ok, v = pcall(function() return vehicle:getY() end); if ok then args.vehicleY = v end end
        if vehicle.getZ then local ok, v = pcall(function() return vehicle:getZ() end); if ok then args.vehicleZ = v end end
    end
    return args
end

setRoofLightColor = function(vehicle, colorKey, playerObj, targetUpgradeId)
    targetUpgradeId = tostring(targetUpgradeId or "RoofLights")
    if not vehicle or not roofLightDirectionUsable(vehicle, targetUpgradeId) then

        return
    end
    local def = getRoofLightColorDef(colorKey)
    if not def then return end

    local currentKey = getCurrentColorKey(vehicle, targetUpgradeId)
    if tostring(currentKey) == tostring(colorKey) then return end

    local neededBulbs = tonumber(def.itemCount) or 1
    if def.itemType and countInventoryItemsByFullType(playerObj, def.itemType) < neededBulbs then
        if playerObj and playerObj.Say then playerObj:Say("Missing " .. tostring(neededBulbs) .. " " .. tostring(def.label or "coloured bulb") .. " bulbs.") end
        return
    end

    -- Apply an immediate client-side preview while the server confirms the change.
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.setVehicleColor then
        pcall(function() GSVU4.RoofLights.setVehicleColor(vehicle, colorKey, targetUpgradeId) end)
    end
    applySingleVehiclePartLight(vehicle, targetUpgradeId, roofLightsActive(vehicle), true)

    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "SetRoofLightColor", addVehicleArgs({ colorKey = tostring(colorKey or "WarmWhite"), targetUpgradeId = targetUpgradeId }, vehicle))
    else
        if def.itemType then
            consumeInventoryItemsByFullType(playerObj, def.itemType, neededBulbs)
        end
        if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.setVehicleColor then
            pcall(function() GSVU4.RoofLights.setVehicleColor(vehicle, colorKey, targetUpgradeId) end)
        end
        applySingleVehiclePartLight(vehicle, targetUpgradeId, roofLightsActive(vehicle), true)
    end
end

local function setRoofLightsActive(vehicle, active, playerObj)
    if not vehicle then return end
    if not roofLightsInstalled(vehicle) then
        if playerObj and playerObj.Say then playerObj:Say("Roof Lighting System is not installed.") end

        return
    end

    local vdata = vehicle:getModData()
    vdata.gUpgrades = vdata.gUpgrades or {}
    vdata.gRoofLightToggleActive = active == true
    for _, upgradeId in ipairs({ "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }) do
        if vdata.gUpgrades[upgradeId] then
            vdata.gUpgrades[upgradeId].active = active == true
        end
    end

    applyVehiclePartLight(vehicle, active == true)
    if roofLightDirectionUsable(vehicle, "RoofLightsRear") then
        applySingleVehiclePartLight(vehicle, "RoofLightsRear", active == true, true)
    end

    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "SetRoofLightsActive", addVehicleArgs({ active = active == true }, vehicle))
    else
        if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
    end
end

function GSVU4_ToggleRoofLights(playerObj, vehicle)
    if not vehicle then return end
    local newState = not roofLightsActive(vehicle)

    setRoofLightsActive(vehicle, newState, playerObj)
end

--========================================================
-- Bulb picker panel UI
--========================================================

pcall(require, "ISUI/ISPanel")
pcall(require, "ISUI/ISButton")
pcall(require, "ISUI/ISLabel")

GSVU4RoofLightColorPicker = ISPanel:derive("GSVU4RoofLightColorPicker")

function GSVU4RoofLightColorPicker:new(x, y, width, height, playerObj, vehicle)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerObj = playerObj
    o.vehicle = vehicle
    o.backgroundColor = {r=0, g=0, b=0, a=0.88}
    o.borderColor = {r=1, g=1, b=1, a=0.18}
    o.moveWithMouse = true
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.selectedKeys = {}
    o.rows = {}
    for _, row in ipairs(DIRECTION_ROWS) do
        o.selectedKeys[row.upgradeId] = getCurrentColorKey(vehicle, row.upgradeId)
    end
    return o
end

function GSVU4RoofLightColorPicker:initialise()
    ISPanel.initialise(self)
end

function GSVU4RoofLightColorPicker:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    if Flood.ColorPanelInstance == self then Flood.ColorPanelInstance = nil end
end

function GSVU4RoofLightColorPicker:getColorOrder()
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.ColorOrder then
        return GSVU4.RoofLights.ColorOrder
    end
    return { "WarmWhite" }
end

function GSVU4RoofLightColorPicker:getColorIndex(colorKey)
    local order = self:getColorOrder()
    for i, key in ipairs(order) do
        if tostring(key) == tostring(colorKey) then return i end
    end
    return 1
end

function GSVU4RoofLightColorPicker:cycleColor(upgradeId, delta)
    if not roofLightDirectionUsable(self.vehicle, upgradeId) then return end
    local order = self:getColorOrder()
    if #order == 0 then return end
    local currentKey = self.selectedKeys[upgradeId] or "WarmWhite"
    local index = self:getColorIndex(currentKey)
    index = index + delta
    if index < 1 then index = #order end
    if index > #order then index = 1 end
    self.selectedKeys[upgradeId] = order[index]
    self:refreshRows()
end

function GSVU4RoofLightColorPicker:applyColor(upgradeId)
    if not self.vehicle or not self.playerObj then return end
    if not roofLightDirectionUsable(self.vehicle, upgradeId) then return end
    local selected = self.selectedKeys[upgradeId] or "WarmWhite"
    setRoofLightColor(self.vehicle, selected, self.playerObj, upgradeId)
    self:refreshRows()
end

function GSVU4RoofLightColorPicker:createRow(y, rowDef)
    local upgradeId = tostring(rowDef and rowDef.upgradeId or "RoofLights")
    local label = tostring(rowDef and rowDef.label or upgradeId)
    local row = {}
    row.def = { upgradeId = upgradeId, label = label }

    row.label = ISLabel:new(16, y + 6, 20, label .. ":", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(row.label)

    row.value = ISLabel:new(110, y + 6, 20, "", 0.75, 0.9, 1.0, 1, UIFont.Small, true)
    self:addChild(row.value)

    row.prev = ISButton:new(self.width - 210, y + 1, 28, 22, "<", self, function(panel) panel:cycleColor(upgradeId, -1) end)
    row.prev:initialise()
    row.prev:instantiate()
    self:addChild(row.prev)

    row.next = ISButton:new(self.width - 178, y + 1, 28, 22, ">", self, function(panel) panel:cycleColor(upgradeId, 1) end)
    row.next:initialise()
    row.next:instantiate()
    self:addChild(row.next)

    row.apply = ISButton:new(self.width - 142, y, 120, 24, getTextSafe("ContextMenu_GSVU4_RoofLightApply", "Apply Bulb"), self,
        function(panel) panel:applyColor(upgradeId) end)
    row.apply:initialise()
    row.apply:instantiate()
    self:addChild(row.apply)

    self.rows[upgradeId] = row
end

function GSVU4RoofLightColorPicker:refreshRows()
    for _, rowDef in ipairs(DIRECTION_ROWS) do
        local row = self.rows[rowDef.upgradeId]
        if row then
            local installed = roofLightsInstalled(self.vehicle, rowDef.upgradeId)
            local hasPart = roofLightPartExists(self.vehicle, rowDef.upgradeId)
            local usable = installed and hasPart
            local selectedKey = self.selectedKeys[rowDef.upgradeId] or "WarmWhite"
            local currentKey = getCurrentColorKey(self.vehicle, rowDef.upgradeId)
            local def = getRoofLightColorDef(selectedKey) or { label = selectedKey }
            local statusText = ""
            if not installed then
                statusText = " (Not Installed)"
            elseif not hasPart then
                statusText = " (Missing Light Part)"
            end
            local changed = tostring(selectedKey) ~= tostring(currentKey)
            row.value:setName(tostring(def.label or selectedKey) .. statusText)
            if row.prev.setEnable then row.prev:setEnable(usable) else row.prev.enable = usable end
            if row.next.setEnable then row.next:setEnable(usable) else row.next.enable = usable end
            if row.apply.setEnable then row.apply:setEnable(usable and changed) else row.apply.enable = usable and changed end
            if not usable then
                row.value.r, row.value.g, row.value.b = 0.8, 0.5, 0.5
            elseif changed then
                row.value.r, row.value.g, row.value.b = 1.0, 0.9, 0.4
            else
                row.value.r, row.value.g, row.value.b = 0.75, 0.9, 1.0
            end
        end
    end
end

function GSVU4RoofLightColorPicker:createChildren()
    ISPanel.createChildren(self)

    local title = getTextSafe("ContextMenu_GSVU4_RoofLightPicker", "Roof Light Bulb Picker")
    self.titleLabel = ISLabel:new(16, 12, 24, title, 1, 1, 1, 1, UIFont.Medium, true)
    self:addChild(self.titleLabel)

    self.infoLabel = ISLabel:new(16, 38, 20,
        getTextSafe("ContextMenu_GSVU4_RoofLightPickerInfo", "Set a separate bulb colour for Front, Left, Right and Rear."),
        0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self:addChild(self.infoLabel)

    local y = 70
    for _, rowDef in ipairs(DIRECTION_ROWS) do
        self:createRow(y, rowDef)
        y = y + 32
    end

    self.noteLabel = ISLabel:new(16, y + 4, 20,
        getTextSafe("ContextMenu_GSVU4_RoofLightPickerNote", "Applying a coloured bulb consumes one matching bulb item. Warm White is the free default."),
        0.75, 0.75, 0.75, 1, UIFont.Small, true)
    self:addChild(self.noteLabel)

    self.closeButton = ISButton:new(self.width - 110, self.height - 34, 90, 24, getText("UI_Close"), self, GSVU4RoofLightColorPicker.onClose)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    self:refreshRows()
end

openRoofLightColorPanel = function(playerObj, vehicle)
    if not playerObj or not vehicle or not roofLightsInstalled(vehicle) then return end
    if Flood.ColorPanelInstance then
        Flood.ColorPanelInstance:onClose()
    end

    local core = getCore and getCore() or nil
    local screenW = core and core:getScreenWidth() or 1920
    local screenH = core and core:getScreenHeight() or 1080
    local width, height = 430, 250
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local panel = GSVU4RoofLightColorPicker:new(x, y, width, height, playerObj, vehicle)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    panel:setVisible(true)
    Flood.ColorPanelInstance = panel
end

--========================================================
-- Radial menu integration
--========================================================

local function getInteractVehicleOutside(playerObj)
    if not playerObj then return nil end
    local vehicle = nil
    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
        local ok, v = pcall(function() return ISVehicleMenu.getVehicleToInteractWith(playerObj) end)
        if ok and v then vehicle = v end
    end
    if not vehicle and ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith2 then
        local ok, v = pcall(function() return ISVehicleMenu.getVehicleToInteractWith2(playerObj) end)
        if ok and v then vehicle = v end
    end
    if not vehicle and playerObj.getNearVehicle then
        local ok, v = pcall(function() return playerObj:getNearVehicle() end)
        if ok and v then vehicle = v end
    end
    return vehicle
end

local function addRoofLightsSlice(menu, playerObj, vehicle)
    if not menu or not vehicle or not roofLightsInstalled(vehicle) then return end
    local active = roofLightsActive(vehicle)
    local label = active
        and getTextSafe("ContextMenu_GSVU4_RoofLightsOff", "Roof Lights Off")
        or getTextSafe("ContextMenu_GSVU4_RoofLightsOn", "Roof Lights On")
    menu:addSlice(label, getTexture("Item_LightBulb"), GSVU4_ToggleRoofLights, playerObj, vehicle)

    local pickerLabel = getTextSafe("ContextMenu_GSVU4_RoofLightPicker", "Roof Light Bulb Picker")
    menu:addSlice(pickerLabel, getTexture("Item_LightBulb"), openRoofLightColorPanel, playerObj, vehicle)
end

local function installRadialHooks()
    if not ISVehicleMenu then pcall(require, "ISUI/ISVehicleMenu") end

    if ISVehicleMenu and ISVehicleMenu.showRadialMenu and not Flood.InsideHooked then
        Flood.InsideHooked = true
        local originalInside = ISVehicleMenu.showRadialMenu
        function ISVehicleMenu.showRadialMenu(playerObj)
            originalInside(playerObj)
            local vehicle = playerObj and playerObj.getVehicle and playerObj:getVehicle() or nil
            local menu = playerObj and getPlayerRadialMenu and getPlayerRadialMenu(playerObj:getPlayerNum()) or nil
            addRoofLightsSlice(menu, playerObj, vehicle)
        end
    end

    if ISVehicleMenu and ISVehicleMenu.showRadialMenuOutside and not Flood.OutsideHooked then
        Flood.OutsideHooked = true
        local originalOutside = ISVehicleMenu.showRadialMenuOutside
        function ISVehicleMenu.showRadialMenuOutside(playerObj)
            originalOutside(playerObj)
            local vehicle = getInteractVehicleOutside(playerObj)
            local menu = playerObj and getPlayerRadialMenu and getPlayerRadialMenu(playerObj:getPlayerNum()) or nil
            addRoofLightsSlice(menu, playerObj, vehicle)
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" then return end
    if command ~= "RoofLightsActiveState" and command ~= "RoofLightColorState" then return end
    local active = args and args.active == true
    iterateVehicles(function(vehicle)
        if not vehicle or not roofLightsInstalled(vehicle) then return end
        local ok = false
        if args and args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
            local ran, id = pcall(function() return vehicle:getOnlineID() end)
            ok = ran and tostring(id) == tostring(args.vehicleOnlineId)
        end
        if not ok and args and args.vehicleId ~= nil and vehicle.getId then
            local ran, id = pcall(function() return vehicle:getId() end)
            ok = ran and tostring(id) == tostring(args.vehicleId)
        end
        if ok then
            local vdata = vehicle:getModData()
            if command == "RoofLightColorState" then
                local targetUpgradeId = tostring((args and args.targetUpgradeId) or "RoofLights")
                if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.setVehicleColor then
                    pcall(function() GSVU4.RoofLights.setVehicleColor(vehicle, args and args.colorKey or "WarmWhite", targetUpgradeId) end)
                end

                applySingleVehiclePartLight(vehicle, targetUpgradeId, roofLightsActive(vehicle), true)
            elseif vdata and vdata.gUpgrades then
                for _, upgradeId in ipairs({ "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }) do
                    if vdata.gUpgrades[upgradeId] then vdata.gUpgrades[upgradeId].active = active end
                end
                vdata.gRoofLightToggleActive = active

                applyVehiclePartLight(vehicle, active)
            end
            if Flood.ColorPanelInstance and Flood.ColorPanelInstance.vehicle == vehicle then
                Flood.ColorPanelInstance:refreshRows()
            end
        end
    end)
end

local function onPlayerUpdate(playerObj)
    Flood.Tick = (Flood.Tick or 0) + 1
    if (Flood.Tick % 30) ~= 0 then return end
    iterateVehicles(function(vehicle)
        if roofLightsInstalled(vehicle) then
            local active = roofLightsActive(vehicle)
            applyVehiclePartLight(vehicle, active)
            -- Rear emitter visibility is more fragile in B42; force its own refresh
            -- so it does not silently stay dark after colour/toggle changes.
            if roofLightDirectionUsable(vehicle, "RoofLightsRear") then
                applySingleVehiclePartLight(vehicle, "RoofLightsRear", active, true)
            end
        end
    end)
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnServerCommand.Add(onServerCommand)
Events.OnGameStart.Add(installRadialHooks)
Events.OnGameBoot.Add(installRadialHooks)
