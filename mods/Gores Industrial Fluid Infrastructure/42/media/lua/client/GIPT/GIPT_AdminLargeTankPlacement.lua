require "ISUI/ISContextMenu"
require "GIPT/GIPT_AdminLargeTank"

-- ISBuildingObject lives in vanilla's server Lua tree and is not available
-- during the early client-directory loading pass.  Build the cursor class only
-- after the world-side building framework has been loaded.
local CursorClass = nil

local function notify(player, text)
    if player and HaloTextHelper then HaloTextHelper.addText(player, tostring(text or "")) end
end

local function ensureCursorClass()
    if CursorClass then return CursorClass end

    if not ISBuildingObject then
        pcall(require, "BuildingObjects/ISBuildingObject")
    end
    if not ISBuildingObject then return nil end

    local cls = ISBuildingObject:derive("GIPT_AdminLargeTankCursor")

    function cls:isValid(square)
        if not square then return false end
        local valid = GIPT.validateAdminLargeInstallation(
            square:getX(), square:getY(), square:getZ(), self.family, self.orientation
        )
        return valid == true
    end

    function cls:render(x, y, z, square)
        local valid, _, layout = GIPT.validateAdminLargeInstallation(x, y, z, self.family, self.orientation)
        layout = layout or GIPT.getAdminLargeInstallationLayout(x, y, z, self.family, self.orientation)
        if not layout then return end

        for _, piece in ipairs(layout.pieces) do
            local sprite = getSprite(piece.spriteName)
            if sprite then
                if valid then sprite:RenderGhostTile(piece.x, piece.y, piece.z)
                else sprite:RenderGhostTileRed(piece.x, piece.y, piece.z) end
            end
        end
    end

    function cls:create(x, y, z, north, sprite)
        local player = getSpecificPlayer(self.player)
        if not GIPT.canUseAdminInstallationPlacement(player) then
            notify(player, "Admin installation placement is unavailable.")
            return
        end

        local valid, reason = GIPT.validateAdminLargeInstallation(x, y, z, self.family, self.orientation)
        if not valid then
            notify(player, reason or "The installation footprint is blocked.")
            return
        end

        if isClient() then
            sendClientCommand(player, GIPT.MODULE, "AdminPlaceLargeInstallation", {
                x = x,
                y = y,
                z = z,
                family = self.family,
                orientation = self.orientation,
            })
            return
        end

        local ok, message = GIPT.placeAdminLargeInstallation(x, y, z, self.family, self.orientation)
        notify(player, message or (ok and "Installation placed." or "Installation placement failed."))
    end

    function cls:rotateKey(key)
        if getCore():isKey("Rotate building", key) then
            self.orientation = self.orientation == "E" and "S" or "E"
        end
    end

    function cls:rotateMouse(x, y)
        -- Rotation is deliberately controlled only by the normal Rotate Building key.
    end

    function cls:onJoypadPressButton(joypadIndex, joypadData, button)
        if button == Joypad.RBumper or button == Joypad.LBumper then
            self.orientation = self.orientation == "E" and "S" or "E"
            return
        end
        return ISBuildingObject.onJoypadPressButton(self, joypadIndex, joypadData, button)
    end

    function cls:new(player, family)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:init()
        o.character = player
        o.player = player:getPlayerNum()
        o.family = math.floor(tonumber(family) or 0)
        o.orientation = "E"
        o.skipBuildAction = true
        o.skipWalk2 = true
        o.noNeedHammer = true
        o.canBeAlwaysPlaced = true
        o.dragNilAfterPlace = true
        o.isTileCursor = true
        o:setSprite(GIPT.SPRITE_PREFIX .. tostring(o.family * 16 + 3))
        return o
    end

    GIPT_AdminLargeTankCursor = cls
    CursorClass = cls
    return CursorClass
end

local function beginAdminPlacement(playerNum, family)
    local player = getSpecificPlayer(playerNum)
    if not GIPT.canUseAdminInstallationPlacement(player) then return end

    local cls = ensureCursorClass()
    if not cls then
        notify(player, "The vanilla building cursor is not ready. Reopen the menu and try again.")
        return
    end
    getCell():setDrag(cls:new(player, family), playerNum)
end

local function addAdminPlacementMenu(playerNum, context, worldObjects)
    local player = getSpecificPlayer(playerNum)
    if not GIPT.canUseAdminInstallationPlacement(player) then return end

    local root = context:addOption("Industrial Fluid Infrastructure (Admin)")
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(root, menu)

    local placeRoot = menu:addOption("Place complete large tank installation")
    local styles = ISContextMenu:getNew(menu)
    menu:addSubMenu(placeRoot, styles)

    for family = 0, 3 do
        local info = GIPT.ADMIN_LARGE_TANK_FAMILIES[family]
        local option = styles:addOption(info.label .. " tank", playerNum, beginAdminPlacement, family)
        option.toolTip = ISToolTip:new()
        option.toolTip:initialise()
        option.toolTip.description = "Places all 8 tank tiles and the matching cabinet as one empty installation. Press the Rotate Building key to switch between the 2 x 5 and 5 x 2 footprints."
    end
end

-- Pre-create the class once vanilla's world-side building framework is ready.
-- The menu callback also retries, covering Lua reloads and unusual load orders.
Events.OnGameStart.Add(ensureCursorClass)
Events.OnFillWorldObjectContextMenu.Add(addAdminPlacementMenu)
