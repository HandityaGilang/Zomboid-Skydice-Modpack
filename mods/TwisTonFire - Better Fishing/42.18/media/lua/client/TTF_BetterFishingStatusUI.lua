-- TwisTonFire — Better Fishing Status UI
-- Minimal icon-only fishing helper UI.

require "ISUI/ISPanel"
require "ISUI/ISImage"
require "Fishing/FishingUtils"

TTF_BetterFishingStatusUI = TTF_BetterFishingStatusUI or {}
TTF_BetterFishingStatusUI.instances = TTF_BetterFishingStatusUI.instances or {}

local BASE_ICON_W = 48
local BASE_ICON_H = 32
local BASE_PAD = 6
local BASE_GAP = 6
local UPDATE_MS = 150
local POS_FILE = "TTF_BetterFishingStatusUI_pos.txt"

local ICON_TEXTURE_DIRS = {
    "media/ui/",
}

local COLOR_NONE = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
local COLOR_GOOD = { r = 0.1, g = 1.0, b = 0.1, a = 1.0 }
local COLOR_BAD  = { r = 1.0, g = 0.1, b = 0.1, a = 1.0 }

local ICONS = {
    {
        id = "bonus",
        textureFile = "ttf_bonustime.png",
        tooltipKey = "UI_TTF_BF_Status_BonusTime_TT",
        fallback = "Bonus Time\nGreen: You are currently inside the configured fishing bonus time window.\nWhite: You are outside the bonus time window.",
    },
    {
        id = "shore",
        textureFile = "ttf_shoredetection.png",
        tooltipKey = "UI_TTF_BF_Status_Shore_TT",
        fallback = "Shore Detection\nRed: Your current aim position is detected as near shore.\nWhite: Your current aim position is not near shore.",
    },
    {
        id = "weather",
        textureFile = "ttf_weather.png",
        tooltipKey = "UI_TTF_BF_Status_Weather_TT",
        fallback = "Weather Detection\nGreen: Current weather improves fishing.\nWhite: Current weather has no effect.\nRed: Current weather makes fishing worse.",
    },
    {
        id = "bait",
        textureFile = "ttf_bait.png",
        tooltipKey = "UI_TTF_BF_Status_Bait_TT",
        fallback = "Bait Detection\nGreen: Your equipped fishing rod has valid bait attached.\nRed: Your equipped fishing rod has no valid bait attached.",
    },
}

local function getTooltipText(key, fallback)
    if getTextOrNull then
        local text = getTextOrNull(key)
        if text and text ~= key then
            return text
        end
    end

    return fallback
end

local function loadIconTexture(fileName)
    for _, dir in ipairs(ICON_TEXTURE_DIRS) do
        local path = dir .. fileName
        local ok, texture = pcall(getTexture, path)

        if ok and texture then
            return texture, path
        end
    end

    print("TTF_BetterFishingStatusUI: Missing icon texture: " .. tostring(fileName))
    return nil, nil
end

local function isStatusUIDisabled()
    local options = rawget(_G, "TTF_BetterFishingOptions")

    if options and type(options.isStatusUIDisabled) == "function" then
        return options.isStatusUIDisabled() == true
    end

    return false
end

local function getStatusUIScalePercent()
    local options = rawget(_G, "TTF_BetterFishingOptions")

    if options and type(options.getUIScalePercent) == "function" then
        return tonumber(options.getUIScalePercent()) or 100
    end

    return 100
end

local function getScaledLayout()
    local percent = getStatusUIScalePercent()
    local scale = math.max(0.5, math.min(2.0, percent / 100))

    return {
        scale = scale,
        iconW = math.max(1, math.floor(BASE_ICON_W * scale + 0.5)),
        iconH = math.max(1, math.floor(BASE_ICON_H * scale + 0.5)),
        pad = math.max(1, math.floor(BASE_PAD * scale + 0.5)),
        gap = math.max(1, math.floor(BASE_GAP * scale + 0.5)),
    }
end

local function getWindowSizeFromLayout(layout)
    local width = (layout.pad * 2) + (layout.iconW * 4) + (layout.gap * 3)
    local height = (layout.pad * 2) + layout.iconH

    return width, height
end

local function setElementBounds(element, x, y, width, height)
    if not element then return end

    if element.setX then element:setX(x) else element.x = x end
    if element.setY then element:setY(y) else element.y = y end
    if element.setWidth then element:setWidth(width) else element.width = width end
    if element.setHeight then element:setHeight(height) else element.height = height end

    element.x = x
    element.y = y
    element.width = width
    element.height = height
end

local function getDefaultPosition(width, height)
    local core = getCore and getCore() or nil
    local screenW = core and core:getScreenWidth() or 1920

    local x = math.floor((screenW - width) / 2)
    local y = 80

    return x, y
end

local function clampUiPosition(x, y, width, height)
    local core = getCore and getCore() or nil
    local screenW = core and core:getScreenWidth() or 1920
    local screenH = core and core:getScreenHeight() or 1080

    local maxX = math.max(0, screenW - width)
    local maxY = math.max(0, screenH - height)

    x = math.max(0, math.min(tonumber(x) or 0, maxX))
    y = math.max(0, math.min(tonumber(y) or 0, maxY))

    return math.floor(x), math.floor(y)
end

local function loadSavedPosition(width, height)
    local reader = getFileReader(POS_FILE, false)

    if reader then
        local rawX = reader:readLine()
        local rawY = reader:readLine()
        reader:close()

        local x = tonumber(rawX)
        local y = tonumber(rawY)

        if x and y then
            return clampUiPosition(x, y, width, height)
        end

        print("TTF_BetterFishingStatusUI: Invalid position file, using default position.")
    end

    local defaultX, defaultY = getDefaultPosition(width, height)
    return clampUiPosition(defaultX, defaultY, width, height)
end

local function savePosition(ui)
    if not ui then return end

    local x, y = clampUiPosition(ui:getX(), ui:getY(), ui:getWidth(), ui:getHeight())

    ui:setX(x)
    ui:setY(y)

    local writer = getFileWriter(POS_FILE, true, false)
    if not writer then
        print("TTF_BetterFishingStatusUI: Could not write position file.")
        return
    end

    writer:write(tostring(x) .. "\n")
    writer:write(tostring(y) .. "\n")
    writer:close()
end

local function getLocalPlayerIndex(player)
    if not player then return nil end
    if not getNumActivePlayers or not getSpecificPlayer then return nil end

    for i = 0, getNumActivePlayers() - 1 do
        local localPlayer = getSpecificPlayer(i)
        if localPlayer and localPlayer == player then
            return i
        end
    end

    return nil
end

local function getPlayerKey(player)
    return getLocalPlayerIndex(player)
end

local function isLocalPlayer(player)
    return getLocalPlayerIndex(player) ~= nil
end

local function isValidFishingRod(item)
    if not item then return false end

    local okBroken, isBroken = pcall(function()
        return item:isBroken()
    end)

    if okBroken and isBroken then
        return false
    end

    if not ItemTag or not ItemTag.FISHING_ROD then
        return false
    end

    local okTag, hasTag = pcall(function()
        return item:hasTag(ItemTag.FISHING_ROD)
    end)

    return okTag and hasTag == true
end

local function getEquippedRod(player)
    if not player then return nil end

    local item = player:getPrimaryHandItem()
    if isValidFishingRod(item) then
        return item
    end

    return nil
end

local function getConfiguredNumber(id, default)
    local getter = rawget(_G, "BF_GetNum")
    if type(getter) == "function" then
        local ok, value = pcall(getter, id, default)
        if ok and type(value) == "number" then
            return value
        end
    end

    local sandboxVars = rawget(_G, "SandboxVars")
    local bf = sandboxVars and sandboxVars.TWF_BF
    if type(bf) == "table" and type(bf[id]) == "number" then
        return bf[id]
    end

    return default
end

local function isHourInsideWindow(hour, startHour, endHour)
    if startHour <= endHour then
        return hour >= startHour and hour <= endHour
    end

    return hour >= startHour or hour <= endHour
end

local function isBonusTime()
    local currentHour = math.floor(math.floor(GameTime.getInstance():getTimeOfDay() * 3600) / 3600)

    local morningStart = getConfiguredNumber("TwF_MornStart", 4)
    local morningEnd   = getConfiguredNumber("TwF_MornEnd", 6)
    local eveningStart = getConfiguredNumber("TwF_EveStart", 18)
    local eveningEnd   = getConfiguredNumber("TwF_EveEnd", 20)

    return isHourInsideWindow(currentHour, morningStart, morningEnd)
        or isHourInsideWindow(currentHour, eveningStart, eveningEnd)
end

local function isNearShoreAtAim(player)
    if not Fishing or not Fishing.Utils then return false end
    if not Fishing.Utils.getAimCoords or not Fishing.Utils.isNearShore then return false end

    local okAim, x, y = pcall(Fishing.Utils.getAimCoords, player)
    if not okAim or not x or not y then
        return false
    end

    local okShore, result = pcall(Fishing.Utils.isNearShore, x, y)
    return okShore and result == true
end

local function getWeatherColor()
    if not Fishing or not Fishing.Utils or not Fishing.Utils.getWeatherParams then
        return COLOR_NONE
    end

    local ok, data = pcall(Fishing.Utils.getWeatherParams)
    if not ok or type(data) ~= "table" then
        return COLOR_NONE
    end

    local coeff = tonumber(data.coeff) or 1.0

    if coeff > 1.0001 then
        return COLOR_GOOD
    elseif coeff < 0.9999 then
        return COLOR_BAD
    end

    return COLOR_NONE
end

local function hasValidBait(rod)
    if not rod then return false end

    local modData = rod:getModData()
    local lure = modData and modData.fishing_Lure

    if lure == nil or lure == "" then
        return false
    end

    if Fishing and Fishing.lure and Fishing.lure.All then
        return Fishing.lure.All[lure] ~= nil
    end

    return true
end

TTF_BetterFishingStatusWindow = ISPanel:derive("TTF_BetterFishingStatusWindow")
local StatusWindow = TTF_BetterFishingStatusWindow

function StatusWindow:initialise()
    ISPanel.initialise(self)

    self.icons = {}

    for index, iconData in ipairs(ICONS) do
        local x = self.pad + ((index - 1) * (self.iconW + self.gap))
        local texture = loadIconTexture(iconData.textureFile)

        local image = ISImage:new(x, self.pad, self.iconW, self.iconH, texture)
        image.autoScale = true
        image.noAspect = false
        image.mouseovertext = getTooltipText(iconData.tooltipKey, iconData.fallback)

        image.backgroundColor.r = COLOR_NONE.r
        image.backgroundColor.g = COLOR_NONE.g
        image.backgroundColor.b = COLOR_NONE.b
        image.backgroundColor.a = COLOR_NONE.a

        if not texture then
            image.name = "?"
            image.doBorder = true
            print("TTF_BetterFishingStatusUI: Icon texture missing for " .. tostring(iconData.textureFile))
        end

        self:addChild(image)
        self.icons[iconData.id] = image
    end
end

function StatusWindow:setIconColor(id, color)
    local icon = self.icons and self.icons[id]
    if not icon or not color then return end

    icon.backgroundColor.r = color.r
    icon.backgroundColor.g = color.g
    icon.backgroundColor.b = color.b
    icon.backgroundColor.a = color.a
end

function StatusWindow:updateIndicators()
    local rod = getEquippedRod(self.player)

    if not rod then
        TTF_BetterFishingStatusUI.hide(self.player)
        return
    end

    self:setIconColor("bonus", isBonusTime() and COLOR_GOOD or COLOR_NONE)
    self:setIconColor("shore", isNearShoreAtAim(self.player) and COLOR_BAD or COLOR_NONE)
    self:setIconColor("weather", getWeatherColor())
    self:setIconColor("bait", hasValidBait(rod) and COLOR_GOOD or COLOR_BAD)
end

function StatusWindow:prerender()
    if isStatusUIDisabled() then
        TTF_BetterFishingStatusUI.hide(self.player)
        return
    end

    self:applyScaleIfNeeded()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local now = getTimestampMs()
    if now - (self.lastUpdateMs or 0) >= UPDATE_MS then
        self.lastUpdateMs = now
        self:updateIndicators()
    end
end

function StatusWindow:hideTooltips()
    if not self.icons then return end

    for _, icon in pairs(self.icons) do
        if icon.tooltipUI and icon.tooltipUI:getIsVisible() then
            icon.tooltipUI:setVisible(false)
            icon.tooltipUI:removeFromUIManager()
        end
    end
end

function StatusWindow:destroy()
    self:hideTooltips()
    self:setVisible(false)
    self:removeFromUIManager()
end

function StatusWindow:new(player)
    local layout = getScaledLayout()
    local width, height = getWindowSizeFromLayout(layout)

    local x, y = loadSavedPosition(width, height)

    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.uiScale = layout.scale
    o.iconW = layout.iconW
    o.iconH = layout.iconH
    o.pad = layout.pad
    o.gap = layout.gap

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.35 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.25 }
    o.moveWithMouse = true
    o.lastUpdateMs = 0

    return o
end

function StatusWindow:applyScaleIfNeeded()
    local layout = getScaledLayout()

    if self.uiScale == layout.scale then
        return
    end

    self.uiScale = layout.scale
    self.iconW = layout.iconW
    self.iconH = layout.iconH
    self.pad = layout.pad
    self.gap = layout.gap

    local width, height = getWindowSizeFromLayout(layout)
    self.width = width
    self.height = height

    if self.setWidth then self:setWidth(width) end
    if self.setHeight then self:setHeight(height) end

    local x, y = clampUiPosition(self:getX(), self:getY(), width, height)
    self:setX(x)
    self:setY(y)

    for index, iconData in ipairs(ICONS) do
        local icon = self.icons and self.icons[iconData.id]

        if icon then
            local iconX = self.pad + ((index - 1) * (self.iconW + self.gap))
            setElementBounds(icon, iconX, self.pad, self.iconW, self.iconH)
        end
    end
end

function StatusWindow:onMouseUp(x, y)
    ISPanel.onMouseUp(self, x, y)
    savePosition(self)
end

function StatusWindow:onMouseUpOutside(x, y)
    if ISPanel.onMouseUpOutside then
        ISPanel.onMouseUpOutside(self, x, y)
    end

    savePosition(self)
end

function TTF_BetterFishingStatusUI.show(player)
    if not player or not isLocalPlayer(player) then return end
    if isStatusUIDisabled() then
        TTF_BetterFishingStatusUI.hide(player)
        return
    end
    local key = getPlayerKey(player)
    if key == nil then return end

    local ui = TTF_BetterFishingStatusUI.instances[key]

    if not ui then
        ui = StatusWindow:new(player)
        ui:initialise()

        -- Do not call ui:instantiate() here.
        -- The icon children are added during initialise(), and addChild() already creates the java object.
        -- Calling instantiate() again would recreate the java object and remove the child icons visually.
        ui:addToUIManager()
        ui:setVisible(true)

        pcall(function()
            ui:setAlwaysOnTop(true)
        end)

        TTF_BetterFishingStatusUI.instances[key] = ui
    else
        ui.player = player
        ui:setVisible(true)
        ui:bringToTop()
    end

    ui:updateIndicators()
end

function TTF_BetterFishingStatusUI.hide(player)
    local key = getPlayerKey(player)
    if key == nil then return end

    local ui = TTF_BetterFishingStatusUI.instances[key]
    if not ui then return end

    ui:destroy()
    TTF_BetterFishingStatusUI.instances[key] = nil
end

function TTF_BetterFishingStatusUI.refresh(player)
    if not player or not isLocalPlayer(player) then return end

    if isStatusUIDisabled() then
        TTF_BetterFishingStatusUI.hide(player)
        return
    end

    if getEquippedRod(player) then
        TTF_BetterFishingStatusUI.show(player)
    else
        TTF_BetterFishingStatusUI.hide(player)
    end
end

local function onEquipPrimary(player, inventoryItem)
    if not isLocalPlayer(player) then return end
    TTF_BetterFishingStatusUI.refresh(player)
end

local function onGameStart()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            TTF_BetterFishingStatusUI.refresh(player)
        end
    end
end

local function onCreatePlayer(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if player then
        TTF_BetterFishingStatusUI.refresh(player)
    end
end

local function onPlayerDeath(player)
    if not isLocalPlayer(player) then return end
    TTF_BetterFishingStatusUI.hide(player)
end

Events.OnEquipPrimary.Add(onEquipPrimary)
Events.OnGameStart.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)