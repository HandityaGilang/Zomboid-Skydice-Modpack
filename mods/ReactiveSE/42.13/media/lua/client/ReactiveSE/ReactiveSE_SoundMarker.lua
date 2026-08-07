---@diagnostic disable: undefined-field, inject-field, param-type-mismatch, return-type-mismatch, undefined-doc-name
--//////////////////////////////////////////////////--
--    Reactive Sound Events - Sound Marker
--    Visual indicator for sound event direction
--//////////////////////////////////////////////////--

require "ISUI/ISUIElement"

ReactiveSE_SoundMarker = ISUIElement:derive("ReactiveSE_SoundMarker")

-- Constants
ReactiveSE_SoundMarker.iconSize = 64
ReactiveSE_SoundMarker.clickableSize = 64

-- Textures (loaded once)
ReactiveSE_SoundMarker.textureBG = nil
ReactiveSE_SoundMarker.texturePointer = nil
ReactiveSE_SoundMarker.eventTextures = {}
ReactiveSE_SoundMarker.eventTexturesColored = {}

--//////////////////////////////////////////////////--
--          Initialization                         --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:initialise()
    ISUIElement.initialise(self)
    self:addToUIManager()
    self.moveWithMouse = true
    self:setVisible(false)
end

---Creates a new sound marker
---@param duration number Duration in game time
---@param posX number World X position of sound
---@param posY number World Y position of sound
---@param player IsoPlayer
---@param screenX number|nil Initial screen X position
---@param screenY number|nil Initial screen Y position
---@return ReactiveSE_SoundMarker
function ReactiveSE_SoundMarker:new(duration, posX, posY, player, screenX, screenY)
    -- Load textures if not already loaded
    if not ReactiveSE_SoundMarker.textureBG then
        ReactiveSE_SoundMarker.textureBG = getTexture("media/ui/eventPointerBase.png")
    end
    if not ReactiveSE_SoundMarker.texturePointer then
        ReactiveSE_SoundMarker.texturePointer = getTexture("media/ui/eventPointer.png")
    end

    -- Load event icons
    local events = { "Animal", "Gunfight", "Gunshot", "Scream", "VehicleCrash", "Weather", "Zombie" }
    for _, evt in ipairs(events) do
        -- Standard icons
        if not ReactiveSE_SoundMarker.eventTextures[evt] then
            local path = "media/ui/intel" .. evt .. ".png"
            ReactiveSE_SoundMarker.eventTextures[evt] = getTexture(path)
        end

        -- Colored icons
        if not ReactiveSE_SoundMarker.eventTexturesColored[evt] then
            local path = "media/ui/intel" .. evt .. "Color.png"
            ReactiveSE_SoundMarker.eventTexturesColored[evt] = getTexture(path)
        end
    end

    -- Default screen position: top center
    screenX = screenX or (getCore():getScreenWidth() / 2) - (ReactiveSE_SoundMarker.iconSize / 2)
    screenY = screenY or (ReactiveSE_SoundMarker.iconSize / 2)

    local o = {}
    o = ISUIElement:new(screenX, screenY, ReactiveSE_SoundMarker.iconSize, ReactiveSE_SoundMarker.iconSize)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.posX = posX or 0
    o.posY = posY or 0
    o.duration = duration or 30
    o.angle = 0
    o.eventType = nil
    o.distanceToPoint = 1000
    o.maxRange = 600
    o.visible = true
    o.mouseOver = false
    o.moving = false
    o.lastUpdateTime = -1

    o:initialise()
    return o
end

--//////////////////////////////////////////////////--
--          Angle Calculation                      --
--//////////////////////////////////////////////////--

---Calculates the angle from marker to target position
function ReactiveSE_SoundMarker:setAngleFromPoint()
    if not self.posX or not self.posY or not self.player then return end

    local playerX = self.player:getX()
    local playerY = self.player:getY()

    local dx = self.posX - playerX
    local dy = self.posY - playerY

    -- Isometric projection adjustment for screen coordinates
    local screen_dx = (dx - dy) * 0.5
    local screen_dy = (dx + dy) * 0.25

    local radians = math.atan2(screen_dy, screen_dx)
    -- Add 180 degrees to point TOWARD the target instead of away from it
    local degrees = (math.deg(radians) + 180 + 360) % 360
    self.angle = degrees
end

--//////////////////////////////////////////////////--
--          Pointer Geometry                       --
--//////////////////////////////////////////////////--

---Calculates rotated pointer vertices
function ReactiveSE_SoundMarker:calcPointer(offset, angle, stretch, tex, centerX, centerY)
    local width = tex:getWidth() * stretch
    local height = tex:getHeight()

    local hw = width / 2
    local hh = height / 2

    local cosA = math.cos(angle)
    local sinA = math.sin(angle)

    local offsetX = math.cos(angle) * offset
    local offsetY = math.sin(angle) * offset

    local cx = self.x + centerX + offsetX
    local cy = self.y + centerY + offsetY

    local x1 = cx - cosA * hw + sinA * hh
    local y1 = cy - sinA * hw - cosA * hh

    local x2 = cx + cosA * hw + sinA * hh
    local y2 = cy + sinA * hw - cosA * hh

    local x3 = cx + cosA * hw - sinA * hh
    local y3 = cy + sinA * hw + cosA * hh

    local x4 = cx - cosA * hw - sinA * hh
    local y4 = cy - sinA * hw + cosA * hh

    return x1, y1, x2, y2, x3, y3, x4, y4
end

--//////////////////////////////////////////////////--
--          Rendering                              --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:render()
    if not self.visible or self.duration <= 0 then return end

    self:setAngleFromPoint()

    local size = ReactiveSE_SoundMarker.iconSize
    local halfSize = size / 2

    -- Get colors from ModOptions
    local modConfig = require "ReactiveSE/ReactiveSE_ModOptions"
    local baseColor = modConfig.BaseColor or { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    local baseOpacity = modConfig.BaseOpacity or 0.7
    local arrowColor = modConfig.ArrowColor or { r = 1, g = 1, b = 1, a = 1 }

    -- Draw base circle with custom color and opacity
    if ReactiveSE_SoundMarker.textureBG then
        self:drawTextureScaled(
            ReactiveSE_SoundMarker.textureBG,
            0, 0,
            size, size,
            baseOpacity, baseColor.r, baseColor.g, baseColor.b
        )
    end

    -- Draw rotated pointer with custom color
    local tex = ReactiveSE_SoundMarker.texturePointer
    if tex then
        -- Arrow faces north (up), so subtract 90 degrees to align with angle calculation
        local angle = math.rad((self.angle or 0) - 90)

        local hw = halfSize
        local hh = halfSize

        local cosA = math.cos(angle)
        local sinA = math.sin(angle)

        -- Center point (absolute screen coordinates for getRenderer)
        local cx = self.x + halfSize
        local cy = self.y + halfSize

        -- Calculate rotated quad vertices
        local x1 = cx - cosA * hw + sinA * hh
        local y1 = cy - sinA * hw - cosA * hh

        local x2 = cx + cosA * hw + sinA * hh
        local y2 = cy + sinA * hw - cosA * hh

        local x3 = cx + cosA * hw - sinA * hh
        local y3 = cy + sinA * hw + cosA * hh

        local x4 = cx - cosA * hw - sinA * hh
        local y4 = cy - sinA * hw + cosA * hh

        -- Render rotated pointer with custom color
        getRenderer():render(tex, x1, y1, x2, y2, x3, y3, x4, y4,
            arrowColor.r, arrowColor.g, arrowColor.b, arrowColor.a, nil)
    end

    -- Event Icon Overlay
    if self.eventType then
        local iconTex = nil
        local useColor = modConfig.UseColoredIcons

        local defaultColor = { r = 1, g = 1, b = 1, a = 1 }

        -- Mapping defaults if config is missing (safety)
        if self.eventType == "Animal" then
            defaultColor = { r = 0.667, g = 0.890, b = 0.663, a = 1 }
        elseif self.eventType == "VehicleCrash" then
            defaultColor = { r = 0.988, g = 0.910, b = 0.596, a = 1 }
        elseif self.eventType == "Weather" then
            defaultColor = { r = 0.651, g = 0.769, b = 0.878, a = 1 }
        else
            defaultColor = { r = 0.910, g = 0.725, b = 0.725, a = 1 } -- Hostile default for others
        end

        local eventColor = modConfig["Color" .. self.eventType] or defaultColor

        if useColor == nil then useColor = false end

        if useColor then
            iconTex = ReactiveSE_SoundMarker.eventTexturesColored[self.eventType]
            if not iconTex then
                iconTex = ReactiveSE_SoundMarker.eventTextures[self.eventType]
            end
        else
            iconTex = ReactiveSE_SoundMarker.eventTextures[self.eventType]
        end

        if iconTex then
            local smallSize = size * 0.65
            local iconSize = size * 0.6

            local offset = size * 0.65

            local iconX = offset
            local iconY = offset

            -- Background Circle
            if ReactiveSE_SoundMarker.textureBG then
                self:drawTextureScaled(
                    ReactiveSE_SoundMarker.textureBG,
                    iconX, iconY,
                    smallSize, smallSize,
                    1,
                    eventColor.r, eventColor.g, eventColor.b
                )
            end

            -- Icon (Centered)
            local centerOffset = (smallSize - iconSize) / 2
            self:drawTextureScaled(iconTex, iconX + centerOffset, iconY + centerOffset, iconSize, iconSize, 1, 1, 1, 1)
        end
    end

    ISUIElement.render(self)
end

--//////////////////////////////////////////////////--
--          Update                                 --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:update(posX, posY)
    local timeStamp = getTimeInMillis()
    if (self.lastUpdateTime + 50 >= timeStamp) then
        return
    end
    self.lastUpdateTime = timeStamp

    posX = posX or self.posX
    posY = posY or self.posY

    if posX and posY and self.player then
        self.distanceToPoint = IsoUtils.DistanceTo(posX, posY, self.player:getX(), self.player:getY())
    end

    if self.duration > 0 then
        self.posX = posX
        self.posY = posY
        self:setAngleFromPoint()
        self:setVisible(true)
    else
        self:setVisible(false)
    end
end

--//////////////////////////////////////////////////--
--          Duration Management                    --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:setDuration(value)
    self.duration = value
    if value <= 0 then
        self:setVisible(false)
    end
end

function ReactiveSE_SoundMarker:getDuration()
    return self.duration
end

function ReactiveSE_SoundMarker:setDistance(dist)
    self.distanceToPoint = dist
end

function ReactiveSE_SoundMarker:setEventType(type)
    self.eventType = type
end

--//////////////////////////////////////////////////--
--          Mouse Handling (Draggable)             --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:onMouseDown(x, y)
    if not self.moveWithMouse then return true end
    if not self:getIsVisible() then return end
    if not self:isMouseOver() then return end

    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
end

function ReactiveSE_SoundMarker:onMouseUp(x, y)
    if not self.moveWithMouse then return end
    if not self:getIsVisible() then return end

    self.moving = false
    if ISMouseDrag.tabPanel then ISMouseDrag.tabPanel:onMouseUp(x, y) end
    ISMouseDrag.dragView = nil
end

function ReactiveSE_SoundMarker:onMouseUpOutside(x, y)
    if not self.moveWithMouse then return end
    if not self:getIsVisible() then return end
    self.moving = false
    ISMouseDrag.dragView = nil
end

function ReactiveSE_SoundMarker:onMouseMove(dx, dy)
    if not self.moveWithMouse then return end
    self.mouseOver = true

    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()

        -- Save position to player mod data
        if self.player then
            self.player:getModData()["RSE_markerPlacement"] = { self.x, self.y }
        end
    end
end

function ReactiveSE_SoundMarker:onMouseMoveOutside(dx, dy)
    if not self.moveWithMouse then return end
    self.mouseOver = false

    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()

        if self.player then
            self.player:getModData()["RSE_markerPlacement"] = { self.x, self.y }
        end
    end
end

function ReactiveSE_SoundMarker:onMouseDoubleClick(x, y)
    -- Double-click to dismiss
    self:setDuration(0)
end

--//////////////////////////////////////////////////--
--          Player Access                          --
--//////////////////////////////////////////////////--

function ReactiveSE_SoundMarker:getPlayer()
    return self.player
end

return ReactiveSE_SoundMarker
