require "TimedActions/ISTimedActionQueue"
require "BasementBuilder/BasementBuilder_Core"
require "BasementBuilder/BasementBuilder_DigAction"

BasementBuilder = BasementBuilder or {}
BasementBuilderStartCursor = BasementBuilderStartCursor or {}

function BasementBuilder.ensureStartCursorClass()
    if BasementBuilderStartCursor and BasementBuilderStartCursor.new then
        return true
    end

    require "BuildingObjects/ISBuildingObject"
    if not ISBuildingObject then
        return false
    end

    BasementBuilderStartCursor = ISBuildingObject:derive("BasementBuilderStartCursor")

    function BasementBuilderStartCursor.exitCursorKey(key)
        local cell = getCell()
        local playerId = 0
        local drag = cell and cell:getDrag(playerId) or nil
        if not drag or drag.Type ~= "BasementBuilderStartCursor" then
            return
        end

        local disable = not key
        if not disable then
            disable = getCore():isKey("Run", key) or getCore():isKey("Interact", key)
        end

        if disable then
            cell:setDrag(nil, playerId)
        end
    end

    function BasementBuilderStartCursor:create(x, y, z, north, sprite)
        local square = getCell():getGridSquare(x, y, z)
        getCell():setDrag(nil, self.player)
        if not square or not self:isValid(square) then
            return
        end

        local shovel = self.getShovel and self.getShovel(self.character) or nil
        if not shovel then
            return
        end

        ISTimedActionQueue.add(BasementBuilderDigAction:new(self.character, square, "start", x, y, shovel, self.styleId, self.palette))
    end

    function BasementBuilderStartCursor:isValid(square)
        if not square then
            return false
        end
        local valid = BasementBuilder._safeCanStartBasement(square)
        return valid == true
    end

    function BasementBuilderStartCursor:render(x, y, z, square)
        local good = self:isValid(square)
        local hc = good and getCore():getGoodHighlitedColor() or getCore():getBadHighlitedColor()
        local template = BasementBuilder.getStarterTemplate()

        for level = 0, 2 do
            local cellX = x + template.stairs.x
            local cellY = y + template.stairs.y - level
            self:getFloorCursorSprite():RenderGhostTileColor(cellX, cellY, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
        end
    end

    function BasementBuilderStartCursor:new(character, getShovelFn, stylePreset)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:init()
        stylePreset = stylePreset or (BasementBuilder.getWallStylePresets and BasementBuilder.getWallStylePresets()[1]) or nil
        o.character = character
        o.player = character:getPlayerNum()
        o.noNeedHammer = true
        o.skipBuildAction = true
        o.dragNilAfterPlace = true
        o.skipWalk2 = true
        o.getShovel = getShovelFn
        o.stylePreset = stylePreset
        o.styleId = stylePreset and stylePreset.id or nil
        o.palette = stylePreset and stylePreset.palette or nil
        local previewFloor = "carpentry_02_57"
        o:setSprite(previewFloor)
        o:setNorthSprite(previewFloor)
        return o
    end

    if not BasementBuilderStartCursor._bbEventsRegistered then
        BasementBuilderStartCursor._bbEventsRegistered = true
        Events.OnKeyPressed.Add(BasementBuilderStartCursor.exitCursorKey)
        Events.OnKeyKeepPressed.Add(BasementBuilderStartCursor.exitCursorKey)
        Events.OnRightMouseDown.Add(BasementBuilderStartCursor.exitCursorKey)
    end

    return true
end

BasementBuilder.ensureStartCursorClass()
