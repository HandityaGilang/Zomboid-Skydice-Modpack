--========================================================
-- Gore's SVU4 Core - Close Button + KI5 Full Block UI
--========================================================

require "GoresSVU4Core/GSVU4_KI5FullBlock"

local function getWindowVehicle(window)
    if not window then return nil end
    return window.vehicle or window.targetVehicle or window.car
end

local function isBlockedWindow(window)
    local vehicle = getWindowVehicle(window)
    local key = tostring(vehicle or "no-vehicle")

    if window
    and window.gsvu4FullBlockCacheKey == key
    and window.gsvu4FullBlockCacheValue ~= nil
    then
        return window.gsvu4FullBlockCacheValue == true
    end

    local blocked = GSVU4_KI5FullBlock
       and GSVU4_KI5FullBlock.IsBlocked
       and GSVU4_KI5FullBlock.IsBlocked(vehicle) == true

    if window then
        window.gsvu4FullBlockCacheKey = key
        window.gsvu4FullBlockCacheValue = blocked == true
    end

    return blocked == true
end

local function blockedMessage(window)
    local vehicle = getWindowVehicle(window)
    if GSVU4_KI5FullBlock and GSVU4_KI5FullBlock.GetBlockedMessage then
        return GSVU4_KI5FullBlock.GetBlockedMessage(vehicle)
    end
    return "SVU4 armor disabled for KI5 vehicles."
end

local function selectedPartHasArmor(window)
    if not window or not window.vehicle or not window.selectedPart then return false end
    local partId = window.selectedPart.partId
    if not partId then return false end

    local md = window.vehicle:getModData()
    return md and md.gArmor and md.gArmor[partId] ~= nil
end

local function closeWindow(window)
    if not window then return end
    if window.setVisible then window:setVisible(false) end
    if window.removeFromUIManager then window:removeFromUIManager() end
end

local function addCloseButton(window)
    if not window or window.gsvu4CloseButton or not ISButton then return end

    local w = window.width or 1040
    local btn = ISButton:new(w - 30, 6, 24, 22, "X", window, function(target)
        closeWindow(target)
    end)

    btn:initialise()
    btn:instantiate()
    btn.tooltip = "Close"
    btn.backgroundColor = {r=0.18, g=0.18, b=0.18, a=0.9}
    btn.backgroundColorMouseOver = {r=0.45, g=0.12, b=0.10, a=0.95}
    window:addChild(btn)
    window.gsvu4CloseButton = btn
end

local function drawBlockedNotice(window)
    if not window or not isBlockedWindow(window) or not window.drawTextCentre then return end

    local x, y, w, h = 300, 154, 330, 160
    if window.detailBox then
        x = window.detailBox:getX()
        y = window.detailBox:getY()
        w = window.detailBox:getWidth()
    end

    local cy = y + 92
    window:drawRect(x + 10, cy - 56, w - 20, 112, 0.88, 0.08, 0.08, 0.08)
    window:drawRectBorder(x + 10, cy - 56, w - 20, 112, 0.9, 0.75, 0.35, 0.2)

    window:drawTextCentre("SVU4 ARMOR DISABLED", x + (w / 2), cy - 38, 1.0, 0.36, 0.25, 1.0, UIFont.Medium)
    window:drawTextCentre("KI5 / DAMN vehicle detected.", x + (w / 2), cy - 10, 0.95, 0.95, 0.95, 1.0, UIFont.Small)
    window:drawTextCentre("Use the vehicle's native", x + (w / 2), cy + 12, 0.95, 0.85, 0.55, 1.0, UIFont.Small)
    window:drawTextCentre("armor system instead.", x + (w / 2), cy + 30, 0.95, 0.85, 0.55, 1.0, UIFont.Small)
end

local function setButtonEnabled(btn, enabled, tooltip)
    if not btn then return end
    if btn.setEnable then
        btn:setEnable(enabled)
    else
        btn.enable = enabled
    end
    if tooltip then btn.tooltip = tooltip end
end

local function updateBlockedButtons(window)
    if not window then return end

    if not isBlockedWindow(window) then
        return
    end

    local msg = blockedMessage(window)

    -- Install Missing is always an install action.
    setButtonEnabled(window.installAllButton, false, msg)

    -- The selected action button is install only when the selected part has no armor.
    -- If armor already exists, the original button is normally uninstall/confirm uninstall,
    -- which we leave available so legacy SVU4 armor can be removed.
    if window.actionButton and not selectedPartHasArmor(window) then
        setButtonEnabled(window.actionButton, false, msg)
        if window.actionButton.setTitle then window.actionButton:setTitle("Install Disabled") end
    end
end

local function sayBlocked(window)
    local msg = blockedMessage(window)
    if window and window.character and window.character.Say then
        window.character:Say("SVU4 armor disabled for KI5 vehicles.")
    end
    if HaloTextHelper and getPlayer then
        HaloTextHelper.addText(getPlayer(), "SVU4 armor disabled for KI5 vehicles", HaloTextHelper.getColorRed())
    end
end

local function wrapMethod(classTable, name, wrapper)
    if not classTable or not classTable[name] or classTable["gsvu4CloseKi5Wrapped_" .. name] then return end
    local old = classTable[name]
    classTable[name] = function(self, ...)
        return wrapper(old, self, ...)
    end
    classTable["gsvu4CloseKi5Wrapped_" .. name] = true
end

local function installPatch()
    if not VehicleArmorWindow then return end

    wrapMethod(VehicleArmorWindow, "createChildren", function(old, self, ...)
        local result = old(self, ...)
        addCloseButton(self)
        updateBlockedButtons(self)
        return result
    end)

    wrapMethod(VehicleArmorWindow, "prerender", function(old, self, ...)
        local result = old(self, ...)
        if self.gsvu4CloseButton then
            local w = self.width or 1040
            self.gsvu4CloseButton:setX(w - 30)
        end
        updateBlockedButtons(self)
        drawBlockedNotice(self)
        return result
    end)

    wrapMethod(VehicleArmorWindow, "onInstallAllButtonClick", function(old, self, ...)
        if isBlockedWindow(self) then
            sayBlocked(self)
            return nil
        end
        return old(self, ...)
    end)

    wrapMethod(VehicleArmorWindow, "onActionButtonClick", function(old, self, ...)
        if isBlockedWindow(self) and not selectedPartHasArmor(self) then
            sayBlocked(self)
            return nil
        end
        return old(self, ...)
    end)
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(installPatch) end
if Events and Events.OnLoad then Events.OnLoad.Add(installPatch) end
