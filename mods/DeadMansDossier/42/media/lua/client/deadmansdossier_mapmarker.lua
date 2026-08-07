--
-- Dead Man's Dossier — Map Marker Module
-- Renders colored stash markers on the ISWorldMap.
-- Patches ISWorldMap.render and ISWorldMap.createChildren.
--

require "deadmansdossier_shared"

local TAG = "[DeadMansDossier]"

-- Active markers: tierKey -> { x, y, label }
DeadMansDossier.activeMarkers = DeadMansDossier.activeMarkers or {}

-- Whether stash markers are visible (toggle)
DeadMansDossier.markersVisible = true

-- Marker colors per tier (r, g, b, a as 0-1 floats)
local MARKER_COLORS = {
    Police      = { r = 0.2, g = 0.4, b = 1.0, a = 0.9 },   -- blue
    Military    = { r = 0.2, g = 0.8, b = 0.2, a = 0.9 },   -- green
    Medical     = { r = 1.0, g = 0.2, b = 0.2, a = 0.9 },   -- red
    Firefighter = { r = 1.0, g = 0.6, b = 0.1, a = 0.9 },   -- orange
    Ranger      = { r = 0.6, g = 0.4, b = 0.2, a = 0.9 },   -- brown
}

-- Marker square size in pixels at 1x zoom
local MARKER_SIZE = 8

-- X-mark arm length in pixels at 1x zoom
local X_SIZE = 10

-- ---------------------------------------------------------------------------
-- Public API: add / remove markers
-- ---------------------------------------------------------------------------
function DeadMansDossier.addStashMarker(tierKey, x, y, label)
    DeadMansDossier.activeMarkers[tierKey] = { x = x, y = y, label = label or "" }
    print(TAG .. " Map marker added: " .. tierKey .. " at (" .. x .. ", " .. y .. ")")
end

function DeadMansDossier.removeStashMarker(tierKey)
    if DeadMansDossier.activeMarkers[tierKey] then
        DeadMansDossier.activeMarkers[tierKey] = nil
        print(TAG .. " Map marker removed: " .. tierKey)
    end
end

-- ---------------------------------------------------------------------------
-- Public API: open world map centered on a stash location
-- ---------------------------------------------------------------------------
function DeadMansDossier.openStashMap(playerNum, tierKey)
    local marker = DeadMansDossier.activeMarkers[tierKey]
    if not marker then
        print(TAG .. " openStashMap: no active marker for tier " .. tostring(tierKey))
        return
    end

    -- Ensure markers are visible when opening via stash map
    DeadMansDossier.markersVisible = true

    -- Open the world map centered on the stash coordinates
    -- ISWorldMap.ShowWorldMap(playerNum, centerX, centerY, zoom)
    if ISWorldMap and ISWorldMap.ShowWorldMap then
        print(TAG .. " Opening world map for " .. tierKey .. " stash at (" .. marker.x .. ", " .. marker.y .. ")")
        ISWorldMap.ShowWorldMap(playerNum, marker.x, marker.y, 18.0)
    else
        print(TAG .. " ISWorldMap not available")
    end
end

-- ---------------------------------------------------------------------------
-- Patched: has the render/createChildren been patched already?
-- ---------------------------------------------------------------------------
local renderPatched = false
local childrenPatched = false

-- ---------------------------------------------------------------------------
-- Render patch: draw colored squares + label on the world map
-- ---------------------------------------------------------------------------
local originalRender = nil

local function patchedRender(self)
    -- Call original render first
    if originalRender then
        originalRender(self)
    end

    if not DeadMansDossier.markersVisible then return end

    local markers = DeadMansDossier.activeMarkers
    if not markers then return end

    for tierKey, marker in pairs(markers) do
        local color = MARKER_COLORS[tierKey] or { r = 1, g = 1, b = 1, a = 0.9 }

        -- Convert world coordinates to screen coordinates
        -- ISWorldMap uses worldToUIX/worldToUIY for coordinate conversion
        local screenX = self.mapAPI:worldToUIX(marker.x, marker.y)
        local screenY = self.mapAPI:worldToUIY(marker.x, marker.y)

        -- Draw X mark at stash location
        local half = X_SIZE / 2
        -- Diagonal lines forming an X (drawn as thin rects)
        for i = -half, half do
            self:drawRect(screenX + i - 1, screenY + i - 1, 3, 3,
                color.a, color.r, color.g, color.b)
            self:drawRect(screenX + i - 1, screenY - i - 1, 3, 3,
                color.a, color.r, color.g, color.b)
        end

        -- Draw a filled center dot
        local dotSize = MARKER_SIZE / 2
        self:drawRect(screenX - dotSize, screenY - dotSize, dotSize * 2, dotSize * 2,
            color.a, color.r, color.g, color.b)

        -- Draw label text below the marker
        if marker.label and marker.label ~= "" then
            local labelText = tierKey .. ": " .. marker.label
            self:drawTextCentre(labelText, screenX, screenY + half + 4,
                color.r, color.g, color.b, color.a, UIFont.Small)
        end
    end
end

-- ---------------------------------------------------------------------------
-- CreateChildren patch: add toggle button
-- ---------------------------------------------------------------------------
local originalCreateChildren = nil

local function patchedCreateChildren(self)
    if originalCreateChildren then
        originalCreateChildren(self)
    end

    -- Add a toggle button for stash markers
    local btnWidth = 140
    local btnHeight = 20
    local btnX = self:getWidth() - btnWidth - 10
    local btnY = 10

    local btn = ISButton:new(btnX, btnY, btnWidth, btnHeight, getText("IGUI_DMD_MarkersOn"), self, function(target)
        DeadMansDossier.markersVisible = not DeadMansDossier.markersVisible
        if DeadMansDossier.markersVisible then
            target.title = getText("IGUI_DMD_MarkersOn")
        else
            target.title = getText("IGUI_DMD_MarkersOff")
        end
    end)
    btn:initialise()
    btn:instantiate()
    btn.borderColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 }
    btn.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 }
    btn.textColor = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 }
    self:addChild(btn)
    self.dmdMarkerToggleBtn = btn
end

-- ---------------------------------------------------------------------------
-- Apply patches to ISWorldMap
-- ---------------------------------------------------------------------------
local function applyPatches()
    if not ISWorldMap then return false end

    if not renderPatched and ISWorldMap.render then
        originalRender = ISWorldMap.render
        ISWorldMap.render = patchedRender
        renderPatched = true
        print(TAG .. " ISWorldMap.render patched for stash markers")
    end

    if not childrenPatched and ISWorldMap.createChildren then
        originalCreateChildren = ISWorldMap.createChildren
        ISWorldMap.createChildren = patchedCreateChildren
        childrenPatched = true
        print(TAG .. " ISWorldMap.createChildren patched for toggle button")
    end

    return renderPatched
end

-- Try to apply patches immediately (ISWorldMap may already be loaded)
applyPatches()

-- Also try on main menu enter, in case ISWorldMap loads later
local function onMainMenuEnter()
    applyPatches()
end
Events.OnMainMenuEnter.Add(onMainMenuEnter)

print(TAG .. " MapMarker module loaded")
