-- Build brush: pick a piece from the palette, drag it across tiles,
-- confirm to build for everyone. Floors paint every dragged tile (line
-- rastered like the zone brush), walls and fences paint the dragged line
-- only, facing picked per segment axis. Mouse-to-tile conversion and the
-- tile outlines follow AegisClearing.lua. The server does the actual
-- building (server/Aegis_Builder.lua), the client only collects tiles.
require "Aegis/AegisTheme"
require "Aegis/AegisWidgets"

AegisBuilder = AegisBuilder or {}

local MAX_TILES = 400

-- every sprite name below is taken from the vanilla B42 build entity
-- scripts (media/scripts/generated/entities) or vanilla lua, no guesses
local CATALOG = {
    {
        id = "floors", label = "UI_Aegis_BuilderFloors", mode = "floor",
        pieces = {
            { label = "Wood floor 1", sprite = "carpentry_02_58" },
            { label = "Wood floor 2", sprite = "carpentry_02_57" },
            { label = "Wood floor 3", sprite = "carpentry_02_56" },
            { label = "White tile", sprite = "floors_interior_tilesandwood_01_0" },
            { label = "Checker tile", sprite = "floors_interior_tilesandwood_01_5" },
            { label = "Brick floor", sprite = "floors_exterior_tilesandstone_01_6" },
            { label = "Metal floor", sprite = "constructedobjects_01_86" },
            { label = "Gravel", sprite = "blends_street_01_55" },
            { label = "Asphalt", sprite = "floors_exterior_street_01_16" },
            { label = "Dirt", sprite = "blends_natural_01_64" },
        },
    },
    {
        id = "walls", label = "UI_Aegis_BuilderWalls", mode = "wall",
        pieces = {
            { label = "Wood wall 1", w = "walls_exterior_wooden_01_44", n = "walls_exterior_wooden_01_45" },
            { label = "Wood wall 2", w = "walls_exterior_wooden_01_40", n = "walls_exterior_wooden_01_41" },
            { label = "Wood wall 3", w = "walls_exterior_wooden_01_24", n = "walls_exterior_wooden_01_25" },
            { label = "Wood wall frame", w = "carpentry_02_100", n = "carpentry_02_101" },
            { label = "Log wall", w = "carpentry_02_80", n = "carpentry_02_81" },
            { label = "Stone wall", w = "walls_logs_96", n = "walls_logs_97" },
            { label = "Brick wall 1", w = "walls_exterior_house_01_20", n = "walls_exterior_house_01_21" },
            { label = "Brick wall 2", w = "walls_exterior_house_01_4", n = "walls_exterior_house_01_5" },
            { label = "Metal wall 1", w = "constructedobjects_01_64", n = "constructedobjects_01_65" },
            { label = "Metal wall 2", w = "constructedobjects_01_48", n = "constructedobjects_01_49" },
        },
    },
    {
        id = "frames", label = "UI_Aegis_BuilderFrames", mode = "wall",
        pieces = {
            { label = "Wood window frame 1", w = "walls_exterior_wooden_01_52", n = "walls_exterior_wooden_01_53" },
            { label = "Wood window frame 2", w = "walls_exterior_wooden_01_32", n = "walls_exterior_wooden_01_33" },
            { label = "Brick window frame", w = "walls_exterior_house_01_12", n = "walls_exterior_house_01_13" },
            { label = "Metal window frame", w = "constructedobjects_01_56", n = "constructedobjects_01_57" },
            { label = "Stone window frame", w = "walls_logs_104", n = "walls_logs_105" },
            { label = "Log window frame", w = "walls_logs_48", n = "walls_logs_49" },
            { label = "Wood door frame", w = "walls_exterior_wooden_01_34", n = "walls_exterior_wooden_01_35" },
            { label = "Brick door frame", w = "walls_exterior_house_01_14", n = "walls_exterior_house_01_15" },
            { label = "Metal door frame", w = "constructedobjects_01_58", n = "constructedobjects_01_59" },
            { label = "Stone door frame", w = "walls_logs_106", n = "walls_logs_107" },
        },
    },
    {
        id = "fences", label = "UI_Aegis_BuilderFences", mode = "wall",
        pieces = {
            { label = "Wood fence 1", w = "carpentry_02_40", n = "carpentry_02_41" },
            { label = "Wood fence 2", w = "carpentry_02_44", n = "carpentry_02_45" },
            { label = "Wood fence 3", w = "carpentry_02_48", n = "carpentry_02_49" },
            { label = "Log fence", w = "crafted_04_116", n = "crafted_04_115" },
            { label = "Stick fence", w = "crafted_04_124", n = "crafted_04_123" },
            { label = "Metal fence 1", w = "constructedobjects_01_82", n = "constructedobjects_01_81" },
            { label = "Metal fence 2", w = "constructedobjects_01_83", n = "constructedobjects_01_80" },
            { label = "Big wire fence", w = "fencing_01_58", n = "fencing_01_57" },
            { label = "Barbed wire", w = "fencing_01_20", n = "fencing_01_21" },
            { label = "Sandbags", w = "carpentry_02_12", n = "carpentry_02_13" },
        },
    },
}

-- custom pieces come from the sprite inspector, stored client side in the
-- admin's own Zomboid/Lua folder, line format C|sprite|label (same file
-- pattern as the weather presets in AegisPageWorld.lua)
local CUSTOM_FILE = "AegisCustomPieces.txt"
local customCache = nil

local function loadCustom()
    if customCache then return customCache end
    customCache = {}
    -- append writer first: creates folder and file without touching
    -- content, a bare getFileReader throws on a fresh Lua folder
    pcall(function()
        local w = getFileWriter(CUSTOM_FILE, true, true)
        if w then w:close() end
    end)
    pcall(function()
        local reader = getFileReader(CUSTOM_FILE, true)
        if not reader then return end
        local line = reader:readLine()
        while line ~= nil do
            local sprite, label = string.match(line, "^C|([^|]+)|([^|]*)$")
            if sprite then
                table.insert(customCache, { sprite = sprite, label = label ~= "" and label or sprite })
            end
            line = reader:readLine()
        end
        reader:close()
    end)
    return customCache
end

local function writeCustom()
    pcall(function()
        local w = getFileWriter(CUSTOM_FILE, true, false)
        if not w then return end
        for _, p in ipairs(customCache or {}) do
            w:write("C|" .. p.sprite .. "|" .. p.label .. "\n")
        end
        w:close()
    end)
end

-- called by the inspector on world click; duplicates are kept once,
-- returns true only when the piece is new
function AegisBuilder.addCustom(sprite)
    if type(sprite) ~= "string" or sprite == "" then return false end
    sprite = sprite:gsub("|", "")
    local list = loadCustom()
    for _, p in ipairs(list) do
        if p.sprite == sprite then return false end
    end
    local label = sprite
    if #label > 26 then label = label:sub(1, 26) end
    table.insert(list, { sprite = sprite, label = label })
    writeCustom()
    return true
end

function AegisBuilder.removeCustomAt(idx)
    local list = loadCustom()
    if not list[idx] then return end
    table.remove(list, idx)
    writeCustom()
end

-- the custom category only exists while pieces are stored; mode "object"
-- paints like floors but builds plain world objects server side
local function categories()
    local cats = {}
    for _, cat in ipairs(CATALOG) do table.insert(cats, cat) end
    local custom = loadCustom()
    if #custom > 0 then
        table.insert(cats, { id = "custom", label = "UI_Aegis_BuilderCustom", mode = "object", pieces = custom })
    end
    return cats
end

local function playerLevel()
    local p = getPlayer()
    return p and math.floor(p:getZ()) or 0
end

local function mouseTile()
    local z = playerLevel()
    local zoom = getCore():getZoom(0)
    local wx = IsoUtils.XToIso(getMouseX() * zoom, getMouseY() * zoom, z)
    local wy = IsoUtils.YToIso(getMouseX() * zoom, getMouseY() * zoom, z)
    return math.floor(wx), math.floor(wy)
end

local function screenProjection(wx, wy, z)
    local ok, anchorX, anchorY = pcall(function()
        return isoToScreenX(0, wx, wy, z), isoToScreenY(0, wx, wy, z)
    end)
    if not ok then return nil end
    local zoom = getCore():getZoom(0)
    local baseX = IsoUtils.XToScreen(wx, wy, z, 0)
    local baseY = IsoUtils.YToScreen(wx, wy, z, 0)
    return function(px, py)
        return anchorX + (IsoUtils.XToScreen(px, py, z, 0) - baseX) / zoom,
            anchorY + (IsoUtils.YToScreen(px, py, z, 0) - baseY) / zoom
    end
end

local function drawTile(el, tx, ty, z, a, color)
    local project = screenProjection(tx, ty, z)
    if not project then return end
    local corners = {
        { tx, ty }, { tx + 1, ty }, { tx + 1, ty + 1 }, { tx, ty + 1 },
    }
    for i = 1, 4 do
        local p, q = corners[i], corners[i % 4 + 1]
        local x1, y1 = project(p[1], p[2])
        local x2, y2 = project(q[1], q[2])
        el:drawLine2(x1, y1, x2, y2, a, color.r, color.g, color.b)
    end
end

-- ==================================================================
-- Editor: fullscreen over the world with a compact palette card
-- ==================================================================
AegisBuilderEditor = ISPanel:derive("AegisBuilderEditor")
AegisBuilderEditor.instance = nil

local PAL_W = 240
local ROW_H = 40

function AegisBuilder.start()
    if AegisBuilderEditor.instance then return end
    if not Aegis.canSee("tools") then return end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local o = ISPanel:new(0, 0, sw, sh)
    setmetatable(o, AegisBuilderEditor)
    AegisBuilderEditor.__index = AegisBuilderEditor
    o.background = false
    o.dragging = false
    o.cats = categories()
    o.catIdx = 1
    o.pieceIdx = 1
    o.tiles = {}      -- key "x|y" -> { x, y, z, n = bool or nil }
    o.count = 0
    o:initialise()
    o:addToUIManager()
    o:setAlwaysOnTop(true)
    o:setWantKeyEvents(true)
    AegisBuilderEditor.instance = o
    if AegisWindow.instance then AegisWindow.instance:setVisible(false) end
    return o
end

function AegisBuilderEditor:createChildren()
    local palH = math.min(self.height - 48, 96 + #CATALOG[1].pieces * ROW_H + 96)
    self.palX = 24
    self.palY = math.floor((self.height - palH) / 2)
    self.palH = palH

    local bw = math.floor((PAL_W - 36) / 2)
    self.confirmBtn = AegisButton:new(self.palX + 12, self.palY + palH - 40,
        bw, 30, getText("UI_Aegis_BuilderConfirm"), "check", self, function(page)
            page:apply()
        end)
    self.confirmBtn.style = "gold"
    self:addChild(self.confirmBtn)
    self.cancelBtn = AegisButton:new(self.palX + 24 + bw, self.palY + palH - 40,
        bw, 30, getText("UI_Aegis_BuilderCancel"), "close", self, function(page)
            page:finish()
        end)
    self:addChild(self.cancelBtn)
end

function AegisBuilderEditor:finish()
    self:removeFromUIManager()
    AegisBuilderEditor.instance = nil
    if AegisWindow.instance then AegisWindow.instance:setVisible(true) end
end

function AegisBuilderEditor:category()
    return self.cats[self.catIdx]
end

function AegisBuilderEditor:piece()
    return self:category().pieces[self.pieceIdx]
end

function AegisBuilderEditor:inPalette(x, y)
    return x >= self.palX and x <= self.palX + PAL_W
        and y >= self.palY and y <= self.palY + self.palH
end

function AegisBuilderEditor:clearTiles()
    self.tiles = {}
    self.count = 0
end

function AegisBuilderEditor:addTile(tx, ty, north)
    local key = tx .. "|" .. ty
    local old = self.tiles[key]
    if not old and self.count >= MAX_TILES then
        self:warnLimit()
        return
    end
    if not old then self.count = self.count + 1 end
    self.tiles[key] = { x = tx, y = ty, z = playerLevel(), n = north }
end

function AegisBuilderEditor:warnLimit()
    local now = getTimestampMs()
    if now < (self.warnUntil or 0) then return end
    self.warnUntil = now + 1500
    Aegis.showToast(getText("UI_Aegis_BuilderTooMany", MAX_TILES))
end

-- floors: rasterize from the last sample to the current tile so fast
-- strokes stay gapless, same technique as the zone brush
function AegisBuilderEditor:paintFloor()
    local tx, ty = mouseTile()
    local lx, ly = self.lastX or tx, self.lastY or ty
    local steps = math.max(math.abs(tx - lx), math.abs(ty - ly))
    for i = 0, steps do
        local t = steps == 0 and 0 or i / steps
        self:addTile(math.floor(lx + (tx - lx) * t + 0.5), math.floor(ly + (ty - ly) * t + 0.5))
    end
    self.lastX, self.lastY = tx, ty
end

-- walls and fences: the current drag is one axis-locked segment from the
-- anchor, horizontal runs get the N face, vertical runs the W face
function AegisBuilderEditor:paintLine()
    local tx, ty = mouseTile()
    for key, t in pairs(self.tiles) do
        if t.seg then
            self.tiles[key] = nil
            self.count = self.count - 1
        end
    end
    local ax, ay = self.dragX, self.dragY
    local horizontal = math.abs(tx - ax) >= math.abs(ty - ay)
    if horizontal then
        for x = math.min(ax, tx), math.max(ax, tx) do
            self:addTile(x, ay, true)
            local t = self.tiles[x .. "|" .. ay]
            if t then t.seg = true end
        end
    else
        for y = math.min(ay, ty), math.max(ay, ty) do
            self:addTile(ax, y, false)
            local t = self.tiles[ax .. "|" .. y]
            if t then t.seg = true end
        end
    end
end

-- ghost preview: the piece texture drawn half transparent on the tile.
-- Anchor: tile canvas bottom sits on the diamond's bottom corner, the
-- trim offsets shift the cut texture back into canvas position
local function drawGhost(el, sprite, tx, ty, z, a)
    if not sprite then return end
    local tex = getTexture(sprite)
    if not tex then return end
    local project = screenProjection(tx, ty, z)
    if not project then return end
    local lx = project(tx, ty + 1)
    local rx = project(tx + 1, ty)
    local _, by = project(tx + 1, ty + 1)
    local origW = tex:getWidthOrig()
    if origW <= 0 then return end
    local scale = (rx - lx) / origW
    local x = lx + tex:getOffsetX() * scale
    local y = by - tex:getHeightOrig() * scale + tex:getOffsetY() * scale
    el:drawTextureScaled(tex, x, y, tex:getWidth() * scale, tex:getHeight() * scale, a, 1, 1, 1)
end

-- shared with the restore preview in AegisConstruction.lua, same math
-- keeps both ghosts pixel identical
AegisBuilder.drawGhost = drawGhost
AegisBuilder.drawTile = drawTile

function AegisBuilderEditor:onMouseDown(x, y)
    if self:inPalette(x, y) then
        self:paletteClick(x, y)
        return
    end
    self.dragging = true
    self.lastX, self.lastY = nil, nil
    self.dragX, self.dragY = mouseTile()
end

function AegisBuilderEditor:onMouseUp(x, y)
    self:endDrag()
end

function AegisBuilderEditor:onMouseUpOutside(x, y)
    self:endDrag()
end

function AegisBuilderEditor:endDrag()
    if self.dragging and self:category().mode == "wall" then
        -- the finished segment sticks, the next drag starts a new one
        for _, t in pairs(self.tiles) do t.seg = nil end
    end
    self.dragging = false
    self.lastX, self.lastY = nil, nil
end

function AegisBuilderEditor:onRightMouseDown(x, y)
    if self.count > 0 then
        self:clearTiles()
    else
        self:finish()
    end
end

function AegisBuilderEditor:paletteClick(x, y)
    local relY = y - self.palY
    -- category tabs
    if relY >= 40 and relY < 68 then
        local tabW = math.floor((PAL_W - 24) / #self.cats)
        local idx = math.floor((x - self.palX - 12) / tabW) + 1
        if self.cats[idx] and idx ~= self.catIdx then
            self.catIdx = idx
            self.pieceIdx = 1
            self.scroll = 0
            self:clearTiles()
        end
        return
    end
    -- piece rows
    local listY = 76
    local idx = math.floor((relY - listY) / ROW_H) + 1 + (self.scroll or 0)
    if idx >= 1 and self:category().pieces[idx] then
        -- custom rows carry a remove zone on the right edge
        if self:category().id == "custom" and x >= self.palX + PAL_W - 32 then
            AegisBuilder.removeCustomAt(idx)
            self.cats = categories()
            if not self.cats[self.catIdx] then self.catIdx = 1 end
            self.pieceIdx = 1
            self:clearTiles()
            return
        end
        self.pieceIdx = idx
    end
end

function AegisBuilderEditor:apply()
    if self.count == 0 then
        self:finish()
        return
    end
    if self.count > MAX_TILES then
        self:warnLimit()
        return
    end
    local cat = self:category()
    local piece = self:piece()
    local tiles = {}
    for _, t in pairs(self.tiles) do
        table.insert(tiles, { x = t.x, y = t.y, z = t.z, n = t.n == true })
    end
    local args = { mode = cat.mode, tiles = tiles }
    if cat.mode == "floor" or cat.mode == "object" then
        args.sprite = piece.sprite
    else
        args.spriteW = piece.w
        args.spriteN = piece.n
    end
    sendClientCommand(getPlayer(), AegisShared.MODULE, "builderApply", args)
    Aegis.logAction("tools", string.format("Build brush: %s on %d tiles", piece.label, self.count))
    self:finish()
end

function AegisBuilderEditor:render()
    local c = Aegis.col
    local z = playerLevel()
    if self.dragging then
        if self:category().mode == "wall" then
            self:paintLine()
        else
            self:paintFloor()
        end
    end
    local piece = self:piece()
    local mode = self:category().mode
    local function ghostSprite(north)
        if mode == "wall" then
            if north then return piece.n end
            return piece.w
        end
        return piece.sprite
    end
    for _, t in pairs(self.tiles) do
        drawGhost(self, ghostSprite(t.n), t.x, t.y, t.z, 0.55)
        drawTile(self, t.x, t.y, t.z, 0.9, c.gold)
    end
    local mx, my = getMouseX(), getMouseY()
    if not self:inPalette(mx, my) then
        local tx, ty = mouseTile()
        drawGhost(self, ghostSprite(false), tx, ty, z, 0.4)
        drawTile(self, tx, ty, z, 0.9, c.goldHi)
    end

    -- header card
    local midX = math.floor(self.width / 2)
    local header = getText("UI_Aegis_BuilderTiles", self.count)
    local hint = getText("UI_Aegis_BuilderTooltip")
    local w = math.max(Aegis.strW(UIFont.Medium, header), Aegis.strW(UIFont.Small, hint)) + 48
    Aegis.roundFrame(self, midX - math.floor(w / 2), 24, w, 62, 10, 0.95, c.gold, c.dark)
    Aegis.textCentre(self, header, midX, 32, UIFont.Medium, c.goldHi)
    Aegis.textCentre(self, hint, midX, 36 + Aegis.fontH(UIFont.Medium), UIFont.Small, c.muted)

    self:renderPalette()
end

function AegisBuilderEditor:renderPalette()
    local c = Aegis.col
    local px, py = self.palX, self.palY
    Aegis.shadow(self, px, py, PAL_W, self.palH, 16, 0.5)
    Aegis.roundFrame(self, px, py, PAL_W, self.palH, 10, 0.97, c.gold, c.dark)
    Aegis.text(self, getText("UI_Aegis_Builder"), px + 12, py + 10, UIFont.Medium, c.goldHi)

    -- category tabs
    local tabW = math.floor((PAL_W - 24) / #self.cats)
    for i, cat in ipairs(self.cats) do
        local tx = px + 12 + (i - 1) * tabW
        local active = i == self.catIdx
        if active then
            Aegis.roundRect(self, tx, py + 40, tabW - 4, 26, 6, 1, c.card)
        end
        local label = getText(cat.label)
        Aegis.textCentre(self, label, tx + math.floor((tabW - 4) / 2),
            py + 44, UIFont.Small, active and c.goldHi or c.muted)
    end

    -- piece rows, sprite texture as thumbnail when reachable by name.
    -- Long lists (custom grows with every inspector click) scroll with
    -- the mouse wheel, arrows mark hidden rows
    local listY = py + 76
    local maxRows = math.floor((self.palH - 76 - 52) / ROW_H)
    local pieces = self:category().pieces
    local maxScroll = math.max(0, #pieces - maxRows)
    if (self.scroll or 0) > maxScroll then self.scroll = maxScroll end
    local scroll = self.scroll or 0
    if scroll > 0 then
        Aegis.textCentre(self, "^", px + math.floor(PAL_W / 2), listY - 14, UIFont.Small, c.goldHi)
    end
    if scroll < maxScroll then
        Aegis.textCentre(self, "v", px + math.floor(PAL_W / 2), listY + maxRows * ROW_H - 2, UIFont.Small, c.goldHi)
    end
    for i = scroll + 1, math.min(#pieces, scroll + maxRows) do
        local piece = pieces[i]
        local ry = listY + (i - scroll - 1) * ROW_H
        if i == self.pieceIdx then
            Aegis.roundRect(self, px + 8, ry, PAL_W - 16, ROW_H - 4, 6, 1, c.card)
        end
        local sprite = piece.sprite or piece.w
        local tex = getTexture(sprite)
        if tex then
            self:drawTextureScaledAspect(tex, px + 14, ry + 2, 32, ROW_H - 8, 1, 1, 1, 1)
        end
        local labelW = PAL_W - 54 - 12
        if self:category().id == "custom" then
            labelW = labelW - 20
            -- remove zone, mirrored by the click handling in paletteClick
            Aegis.text(self, "x", px + PAL_W - 26, ry + math.floor((ROW_H - 4 - Aegis.fontH(UIFont.Small)) / 2),
                UIFont.Small, c.danger)
        end
        Aegis.text(self, Aegis.fitText(piece.label, UIFont.Small, labelW), px + 54,
            ry + math.floor((ROW_H - 4 - Aegis.fontH(UIFont.Small)) / 2),
            UIFont.Small, i == self.pieceIdx and c.goldHi or c.text)
    end
end

-- tilesheets keep the rotations of a piece in aligned blocks of four,
-- R walks the block and skips gaps in the sheet
local function rotatedSprite(sprite)
    local base, num = string.match(sprite or "", "^(.-)_(%d+)$")
    if not base then return nil end
    num = tonumber(num)
    local block = math.floor(num / 4) * 4
    for step = 1, 3 do
        local cand = base .. "_" .. (block + (num - block + step) % 4)
        if getTexture(cand) then return cand end
    end
    return nil
end

function AegisBuilderEditor:rotatePiece()
    local cat = self:category()
    local piece = self:piece()
    if not piece then return end
    if cat.mode == "wall" then
        -- walls come as west/north pairs, R swaps the pair
        piece.w, piece.n = piece.n, piece.w
        return
    end
    local turned = rotatedSprite(piece.sprite)
    if turned then piece.sprite = turned end
end

function AegisBuilderEditor:onMouseWheel(del)
    if self:inPalette(getMouseX(), getMouseY()) then
        self.scroll = math.max(0, (self.scroll or 0) + (del > 0 and 1 or -1))
        return true
    end
    return false
end

function AegisBuilderEditor:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE or key == Keyboard.KEY_RETURN or key == Keyboard.KEY_R
end

function AegisBuilderEditor:onKeyPress(key)
    if key == Keyboard.KEY_RETURN then
        self:apply()
        GameKeyboard.eatKeyPress(key)
    elseif key == Keyboard.KEY_ESCAPE then
        self:finish()
        GameKeyboard.eatKeyPress(key)
    elseif key == Keyboard.KEY_R then
        self:rotatePiece()
        GameKeyboard.eatKeyPress(key)
    end
end

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= AegisShared.MODULE then return end
    if command == "builderDone" and args then
        if args.ok then
            Aegis.showToast(getText("UI_Aegis_BuilderDone", args.built or 0))
        else
            Aegis.showToast(getText("UI_Aegis_BuilderTooMany", MAX_TILES))
        end
    end
end)
