---@diagnostic disable: undefined-field, inject-field, param-type-mismatch, duplicate-set-field
--//////////////////////////////////////////////////--
--    Reactive Sound Events - Radio Markers
--    Client-side map marker system for radio intel
--//////////////////////////////////////////////////--

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISWorldMap"

local Utils                       = require "ReactiveSE/ReactiveSE_Utils"
local Config                      = require "ReactiveSE/ReactiveSE_Config"
local ModOptions                  = require "ReactiveSE/ReactiveSE_ModOptions"

local ReactiveSE_RadioMarkers     = {}

--//////////////////////////////////////////////////--
--          Configuration                           --
--//////////////////////////////////////////////////--

local WRITING_TOOLS               = {
    ["Base.Pencil"] = true,
    ["Base.RedPen"] = true,
    ["Base.GreenPen"] = true,
    ["Base.BluePen"] = true,
    ["Base.Pen"] = true,
    ["Base.PenMultiColor"] = true,
    ["Base.PencilSpiffo"] = true,
    ["Base.PenSpiffo"] = true,
    ["Base.PenFancy"] = true,
    ["Base.Crayons"] = true,
    ["Base.MarkerRed"] = true,
    ["Base.MarkerGreen"] = true,
    ["Base.MarkerBlue"] = true,
    ["Base.MarkerBlack"] = true,
}

local PENDING_INTEL_TIMEOUT       = 1 -- Hours before pending intel expires
local MARKER_PROXIMITY_CLEAR      = 50 -- Tiles distance to auto-clear marker
local MARKER_ICON_SIZE            = 64 -- Size of marker icon on map

--//////////////////////////////////////////////////--
--          State                                   --
--//////////////////////////////////////////////////--

local pendingIntel                = nil
local pendingIntelTime            = 0
local initialized                 = false
local textureCache                = {}

-- Mapping of scene types to their specific marker textures
local SCENE_TYPE_TEXTURES         = {
    ["Gunfight"]     = "media/ui/intelGunfight.png",
    ["Gunshot"]      = "media/ui/intelGunshot.png",
    ["Scream"]       = "media/ui/intelScream.png",
    ["VehicleCrash"] = "media/ui/intelVehicleCrash.png",
    ["Zombie"]       = "media/ui/intelZombie.png",
}

local DEFAULT_MARKER_TEXTURE      = "media/ui/intelMarker.png"
local DEFAULT_MARKER_TEXTURE_ICON = "media/ui/intelMarkerIcon.png"

--//////////////////////////////////////////////////--
--          Internal Helpers                        --
--//////////////////////////////////////////////////--

---Gets the marker texture for a specific scene type
---@param sceneType string|nil The scene type (e.g., "Gunfight", "Zombie")
---@return Texture|nil
local function getMarkerTexture(sceneType)
    local texturePath = (sceneType and SCENE_TYPE_TEXTURES[sceneType]) or DEFAULT_MARKER_TEXTURE

    if not textureCache[texturePath] then
        textureCache[texturePath] = getTexture(texturePath)
    end

    return textureCache[texturePath]
end

---Finds a valid writing tool in the player's inventory
---@param player IsoPlayer
---@return InventoryItem|nil
local function findWritingTool(player)
    if not player then return nil end

    local inventory = player:getInventory()
    if not inventory then return nil end

    for itemType, _ in pairs(WRITING_TOOLS) do
        local item = inventory:getFirstTypeRecurse(itemType)
        if item then
            return item
        end
    end

    return nil
end

---Checks if an item is a radio/walkie talkie
---@param item InventoryItem
---@return boolean
local function isRadioItem(item)
    if not item then return false end

    local itemType = item:getType()
    if itemType then
        local typeLower = string.lower(itemType)
        if string.find(typeLower, "walkie") or
            string.find(typeLower, "radio") then
            return true
        end
    end

    return false
end

---Checks if player is in a vehicle with a working radio
---@param player IsoPlayer
---@return boolean
local function isPlayerInVehicleWithRadio(player)
    if not player then return false end

    local vehicle = player:getVehicle()
    if not vehicle then return false end

    local radio = vehicle:getPartById("Radio")
    if radio then
        local deviceData = radio:getDeviceData()
        if deviceData then
            return true
        end
    end

    return false
end

---Starts the mark intel action with automatic pen transfer
---@param player IsoPlayer
---@param pen InventoryItem
---@param intel table
local function startMarkIntelAction(player, pen, intel)
    local MarkIntelAction = require "ReactiveSE/ReactiveSE_MarkIntelAction"

    if pen:getContainer() ~= player:getInventory() then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(
            player, pen, pen:getContainer(), player:getInventory()
        ))
    end

    local action = MarkIntelAction:new(player, pen, intel.x, intel.y, intel.sceneID, intel.sceneType)
    ISTimedActionQueue.add(action)
    Utils.LogInfo("[RadioMarkers] Started mark intel action for " ..
        intel.x .. ", " .. intel.y .. " (" .. (intel.sceneType or "Unknown") .. ")")
end

---Renders intel markers on the world map
---@param worldMap ISWorldMap
local function renderIntelMarkers(worldMap)
    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    local markers = modData.knoxRelayMarkers
    if not markers then return end

    -- Get map API for coordinate conversion
    local mapAPI = worldMap.mapAPI
    if not mapAPI then return end

    local halfSize = MARKER_ICON_SIZE / 2

    for key, marker in pairs(markers) do
        if marker and marker.x and marker.y then
            local tex = getMarkerTexture(marker.sceneType)
            if tex then
                -- Convert world coordinates to screen coordinates using mapAPI
                local screenX = mapAPI:worldToUIX(marker.x, marker.y)
                local screenY = mapAPI:worldToUIY(marker.x, marker.y)

                worldMap:drawTextureScaled(
                    tex,
                    screenX - halfSize,
                    screenY - halfSize,
                    MARKER_ICON_SIZE,
                    MARKER_ICON_SIZE,
                    1.0, 1.0, 1.0, 1.0
                )
            end
        end
    end
end


---Checks proximity to markers and clears nearby ones
---@param player IsoPlayer
local function checkMarkerProximity(player)
    if not player then return end

    local modData = player:getModData()
    local markers = modData.knoxRelayMarkers
    if not markers then return end

    local playerX = player:getX()
    local playerY = player:getY()

    for key, marker in pairs(markers) do
        if marker and marker.x and marker.y then
            local distance = IsoUtils.DistanceTo(playerX, playerY, marker.x, marker.y)
            if distance < MARKER_PROXIMITY_CLEAR then
                markers[key] = nil
                Utils.LogInfo("[RadioMarkers] Cleared marker at " ..
                    marker.x .. ", " .. marker.y .. " (player proximity)")
            end
        end
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                        --
--//////////////////////////////////////////////////--

---Gets the current pending intel
---@return table|nil
function ReactiveSE_RadioMarkers.GetPendingIntel()
    if not pendingIntel then return nil end

    local currentTime = getGameTime():getWorldAgeHours()
    if currentTime - pendingIntelTime > PENDING_INTEL_TIMEOUT then
        pendingIntel = nil
        return nil
    end

    return pendingIntel
end

---Creates a map marker at coordinates
---@param x number World X coordinate
---@param y number World Y coordinate
---@param sceneID string Scene identifier
---@param sceneType string|nil Scene type (e.g., "Gunfight", "Zombie")
function ReactiveSE_RadioMarkers.CreateMapSymbol(x, y, sceneID, sceneType)
    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    modData.knoxRelayMarkers = modData.knoxRelayMarkers or {}

    local key = x .. "_" .. y
    modData.knoxRelayMarkers[key] = {
        x = x,
        y = y,
        sceneID = sceneID,
        sceneType = sceneType,
        created = getGameTime():getWorldAgeHours(),
    }

    pendingIntel = nil

    -- Notify server that this scene was marked by player
    triggerEvent("OnKnoxRelayIntelMarked", sceneID)

    Utils.LogInfo("[RadioMarkers] Created map marker at " .. x .. ", " .. y .. " (" .. (sceneType or "Unknown") .. ")")
end

---Removes a marker by scene ID
---@param sceneID string
function ReactiveSE_RadioMarkers.RemoveMarkerBySceneID(sceneID)
    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    if not modData.knoxRelayMarkers then return end

    for key, marker in pairs(modData.knoxRelayMarkers) do
        if marker.sceneID == sceneID then
            modData.knoxRelayMarkers[key] = nil
            Utils.LogInfo("[RadioMarkers] Removed marker for scene " .. sceneID)
            return
        end
    end
end

---Clears all markers
function ReactiveSE_RadioMarkers.ClearAllMarkers()
    local player = getPlayer()
    if player then
        player:getModData().knoxRelayMarkers = {}
    end
    pendingIntel = nil
    Utils.LogInfo("[RadioMarkers] Cleared all markers")
end

--//////////////////////////////////////////////////--
--          Context Menu                            --
--//////////////////////////////////////////////////--

---Adds context menu option for marking intel
---@param playerNum number
---@param context ISContextMenu
---@param worldObjects table
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects)
    if #worldObjects == 0 then return end

    if ReactiveSE_Initialize.IsPureClient() then return end

    local radioConfig = Config.Get().radio
    if not radioConfig or radioConfig.mapMarker == false then return end

    local intel = ReactiveSE_RadioMarkers.GetPendingIntel()
    if not intel then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- Check for world radios
    local hasRadio = false
    for i = 1, #worldObjects do
        local obj = worldObjects[i]
        local objSprite = obj:getSprite()
        if objSprite then
            local spriteName = objSprite:getName() or ""
            if string.find(spriteName, "radio") or string.find(spriteName, "Radio") or string.find(spriteName, "appliances_com_01") then
                hasRadio = true
                break
            end
        end
    end

    -- Also check if player is in vehicle with radio
    if not hasRadio then
        hasRadio = isPlayerInVehicleWithRadio(player)
    end

    if not hasRadio then return end

    local optionText = getText("ContextMenu_MarkIntel")
    local option = context:addOption(optionText)
    if ModOptions.MarkIntelIcon then
        option.iconTexture = getTexture(DEFAULT_MARKER_TEXTURE_ICON)
    end

    local pen = findWritingTool(player)

    if not pen then
        option.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_MarkIntel_NeedPen")
        option.toolTip = tooltip
    else
        option.onSelect = function()
            startMarkIntelAction(player, pen, intel)
        end
    end
end

---Handler for inventory item context menu (walkie talkies)
---@param playerNum number
---@param context ISContextMenu
---@param items table
local function onFillInventoryObjectContextMenu(playerNum, context, items)
    -- Mark Intel only works in SP/Host (where scenes spawn)
    if ReactiveSE_Initialize.IsPureClient() then return end

    -- Check if map marking is enabled in config
    local radioConfig = Config.Get().radio
    if not radioConfig or radioConfig.mapMarker == false then return end

    local intel = ReactiveSE_RadioMarkers.GetPendingIntel()
    if not intel then return end

    -- Check if any selected item is a radio
    local hasRadio = false
    for i = 1, #items do
        local item = items[i]
        if not instanceof(item, "InventoryItem") then
            item = item.items and item.items[1]
        end
        if isRadioItem(item) then
            hasRadio = true
            break
        end
    end
    if not hasRadio then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local optionText = getText("ContextMenu_MarkIntel")
    local option = context:addOption(optionText)
    if ModOptions.MarkIntelIcon then
        option.iconTexture = getTexture(DEFAULT_MARKER_TEXTURE_ICON)
    end

    local pen = findWritingTool(player)
    if not pen then
        option.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_MarkIntel_NeedPen")
        option.toolTip = tooltip
    else
        option.onSelect = function()
            startMarkIntelAction(player, pen, intel)
        end
    end
end

--//////////////////////////////////////////////////--
--          Event Handlers                          --
--//////////////////////////////////////////////////--

---Event handler for radio marker broadcast
---@param x number
---@param y number
---@param sceneType string
---@param sceneID string
local function onKnoxRelayMarker(x, y, sceneType, sceneID)
    Utils.LogInfo("[RadioMarkers] Received intel broadcast for " .. x .. ", " .. y)

    pendingIntel = {
        x = x,
        y = y,
        sceneType = sceneType or "Unknown",
        sceneID = sceneID or (x .. "_" .. y),
    }
    pendingIntelTime = getGameTime():getWorldAgeHours()
    Utils.LogInfo("[RadioMarkers] Intel received and stored for marking")
end

---Periodic update to check marker proximity
local function onEveryOneMinute()
    local player = getPlayer()
    if player then
        checkMarkerProximity(player)
    end
end

--//////////////////////////////////////////////////--
--          ISWorldMap Hook                         --
--//////////////////////////////////////////////////--

local originalISWorldMapRender = ISWorldMap.render

---Hooked render function to draw intel markers on map
---@param self ISWorldMap
function ISWorldMap:render()
    originalISWorldMapRender(self)
    renderIntelMarkers(self)
end

--//////////////////////////////////////////////////--
--          Initialization                          --
--//////////////////////////////////////////////////--

---Initializes the marker system
local function initializeMarkers()
    if initialized then return end
    initialized = true

    if Events.OnKnoxRelayMarker then
        Events.OnKnoxRelayMarker.Add(onKnoxRelayMarker)
    end

    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
    Events.EveryOneMinute.Add(onEveryOneMinute)

    Utils.LogInfo("[RadioMarkers] Initialized")
end

Events.OnGameStart.Add(initializeMarkers)

return ReactiveSE_RadioMarkers
