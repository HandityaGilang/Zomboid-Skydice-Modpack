require "ISUI/ISCollapsableWindow"

TMVinylAlbumInspectWindow = TMVinylAlbumInspectWindow or ISCollapsableWindow:derive("TMVinylAlbumInspectWindow")
TMVinylAlbumInspectWindow.instances = TMVinylAlbumInspectWindow.instances or {}

local function _getItem(v)
    if instanceof(v, "InventoryItem") then
        return v
    end
    if type(v) == "table" and v.items and v.items[1] and instanceof(v.items[1], "InventoryItem") then
        return v.items[1]
    end
    return nil
end

local function _startsWith(s, prefix)
    return type(s) == "string" and type(prefix) == "string" and string.sub(s, 1, #prefix) == prefix
end

local function _splitFullType(fullType)
    local moduleName, itemName = string.match(tostring(fullType or ""), "^(.-)%.(.+)$")
    return moduleName, itemName
end

local function _isVinylAlbumItem(item)
    if not item or not item.getType then
        return false
    end
    local shortType = item:getType()
    return _startsWith(shortType, "VinylAlbum")
end

local function _matchingVinylFullType(albumItem)
    local fullType = albumItem and albumItem.getFullType and albumItem:getFullType() or nil
    local moduleName, itemName = _splitFullType(fullType)
    if not moduleName or not itemName or not _startsWith(itemName, "VinylAlbum") then
        return nil
    end
    local suffix = string.sub(itemName, #"VinylAlbum" + 1)
    local vinylName = "Vinyl" .. suffix
    local vinylFullType = moduleName .. "." .. vinylName
    if getScriptManager() and getScriptManager():FindItem(vinylFullType) then
        return vinylFullType
    end
    return nil
end

local function _ensureAlbumState(item)
    local md = item:getModData()
    md.tmVinylAlbum = md.tmVinylAlbum or {}
    local state = md.tmVinylAlbum

    if not state.baseDisplayName or state.baseDisplayName == "" then
        local current = item:getDisplayName() or "Vinyl Album"
        state.baseDisplayName = string.gsub(current, "%s*%(%s*Empty%s*%)$", "")
    end
    if not state.matchingVinylFullType or state.matchingVinylFullType == "" then
        state.matchingVinylFullType = _matchingVinylFullType(item)
    end
    if state.empty == nil then
        local current = item:getDisplayName() or ""
        state.empty = (string.find(current, "%(%s*Empty%s*%)") ~= nil)
    else
        state.empty = (state.empty == true or state.empty == "true" or state.empty == 1 or state.empty == "1")
    end
    return state
end

local function _syncAlbumStateToServer(albumItem, state, args)
    if not isClient() or not sendClientCommand or not albumItem or not state then
        return
    end
    if not albumItem.getID then
        return
    end
    local payload = {
        albumItemId = albumItem:getID(),
        empty = state.empty == true,
        baseDisplayName = state.baseDisplayName,
        matchingVinylFullType = state.matchingVinylFullType,
    }
    if args then
        for k, v in pairs(args) do
            payload[k] = v
        end
    end
    sendClientCommand("truemusic", "setVinylAlbumState", payload)
end

local function _setItemDisplayName(item, name)
    if not item or not name then
        return
    end
    pcall(function()
        if item.setName then
            item:setName(name)
        elseif item.setCustomName then
            item:setCustomName(name)
        end
    end)
end

local function _applyAlbumDisplayState(item)
    local state = _ensureAlbumState(item)
    local base = state.baseDisplayName or "Vinyl Album"
    local label = state.empty and (base .. " (Empty)") or base
    _setItemDisplayName(item, label)
    if item.transmitModData then
        pcall(function() item:transmitModData() end)
    end
end

local function _findMatchingVinylInInventory(playerObj, fullType)
    if not playerObj or not playerObj.getInventory or not fullType then
        return nil
    end
    local inv = playerObj:getInventory()
    if not inv then
        return nil
    end
    local items = inv:getItems()
    if not items then
        return nil
    end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == fullType then
            return it
        end
    end
    return nil
end

local function _isItemInPlayerInventory(playerObj, item)
    if not playerObj or not item or not item.getContainer then
        return false
    end
    local container = item:getContainer()
    return container ~= nil and container == playerObj:getInventory()
end

local function _removeVinylFromAlbum(playerObj, albumItem)
    if not playerObj or not albumItem then
        return
    end
    if not _isItemInPlayerInventory(playerObj, albumItem) then
        return
    end
    local state = _ensureAlbumState(albumItem)
    if state.empty then
        return
    end
    local fullType = state.matchingVinylFullType
    if not fullType or fullType == "" then
        return
    end
    local inv = playerObj:getInventory()
    if not inv then
        return
    end
    if isClient() then
        state.empty = true
        _applyAlbumDisplayState(albumItem)
        _syncAlbumStateToServer(albumItem, state, { grantVinyl = true, vinylFullType = fullType })
        return
    end
    local created = inv:AddItem(fullType)
    if created then
        state.empty = true
        _applyAlbumDisplayState(albumItem)
    end
end

local function _insertVinylIntoAlbum(playerObj, albumItem, vinylItem)
    if not playerObj or not albumItem or not vinylItem then
        return
    end
    if not _isItemInPlayerInventory(playerObj, albumItem) then
        return
    end
    local state = _ensureAlbumState(albumItem)
    if not state.empty then
        return
    end
    local fullType = state.matchingVinylFullType
    if not fullType or vinylItem:getFullType() ~= fullType then
        return
    end
    local inv = playerObj:getInventory()
    if not inv then
        return
    end
    if isClient() then
        state.empty = false
        _applyAlbumDisplayState(albumItem)
        _syncAlbumStateToServer(albumItem, state, {
            consumeVinylItemId = vinylItem.getID and vinylItem:getID() or nil,
            consumeVinylFullType = fullType,
        })
        return
    end
    inv:DoRemoveItem(vinylItem)
    state.empty = false
    _applyAlbumDisplayState(albumItem)
end

local function _tryTexture(path)
    if not path or path == "" then
        return nil
    end
    local tex = getTexture(path)
    if tex then
        return tex
    end
    return nil
end

local function _resolveAlbumTexture(item)
    if not item then
        return nil
    end

    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    local fullType = item.getFullType and item:getFullType() or nil
    local _, itemName = _splitFullType(fullType)
    local suffix = nil
    if itemName and _startsWith(itemName, "VinylAlbum") then
        suffix = string.sub(itemName, #"VinylAlbum" + 1)
    end

    -- 1) Try HR path variants first.
    if suffix and suffix ~= "" then
        local hrName = "VinylAlbum_" .. suffix .. ".png"
        local tex = _tryTexture("HR/" .. hrName)
            or _tryTexture("media/textures/HR/" .. hrName)
        if tex then
            return tex
        end
    end

    -- 2) Try world texture based on world static model short name.
    if scriptItem and scriptItem.getWorldStaticModel then
        local worldModel = scriptItem:getWorldStaticModel() or ""
        local _, modelName = _splitFullType(worldModel)
        modelName = modelName or worldModel
        if modelName and modelName ~= "" then
            local tex = _tryTexture("WorldItems/" .. modelName)
                or _tryTexture("media/textures/WorldItems/" .. modelName .. ".png")
            if tex then
                return tex
            end
        end
    end

    -- 3) If model texture is random-roll based, infer world texture from icon roll.
    if scriptItem and scriptItem.getIcon then
        local icon = tostring(scriptItem:getIcon() or "")
        local roll = string.match(icon, "^TCAlbum(%d+)$")
        if not roll then
            roll = string.match(icon, "^TCVinylrecord(%d+)$")
        end
        if roll then
            local tex = _tryTexture("WorldItems/Vinyl/TCVinylrecord" .. tostring(roll))
                or _tryTexture("media/textures/WorldItems/Vinyl/TCVinylrecord" .. tostring(roll) .. ".png")
            if tex then
                return tex
            end
        end
    end

    -- 4) Default/base album fallback should use the world album texture.
    local baseAlbumWorld = _tryTexture("Zomboid/WorldItems/World_TMZomboid_Album")
        or _tryTexture("media/textures/Zomboid/WorldItems/World_TMZomboid_Album.png")
    if baseAlbumWorld then
        return baseAlbumWorld
    end

    -- 5) Final fallback to item icon textures.
    if item.getTex then
        local t = item:getTex()
        if t then
            return t
        end
    end

    return _tryTexture("Item_TMZomboid_VinylAlbum")
        or _tryTexture("Item_TMVinylalbum_uv")
        or _tryTexture("Item_TCVinylrecord3")
        or _tryTexture("media/textures/Item_TCVinylrecord3.png")
end

function TMVinylAlbumInspectWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function TMVinylAlbumInspectWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
end

function TMVinylAlbumInspectWindow:render()
    ISCollapsableWindow.render(self)

    local pad = 10
    local top = self:titleBarHeight() + 6
    local availW = self:getWidth() - (pad * 2)
    local availH = self:getHeight() - top - pad
    if availW <= 1 or availH <= 1 then
        return
    end

    self:drawRect(pad, top, availW, availH, 0.25, 0, 0, 0)

    if self.coverTexture then
        local tw = self.coverTexture:getWidth()
        local th = self.coverTexture:getHeight()
        if tw > 0 and th > 0 then
            local scale = math.min(availW / tw, availH / th)
            local dw = math.floor(tw * scale)
            local dh = math.floor(th * scale)
            local dx = pad + math.floor((availW - dw) / 2)
            local dy = top + math.floor((availH - dh) / 2)
            self:drawTextureScaled(self.coverTexture, dx, dy, dw, dh, 1.0, 1.0, 1.0, 1.0)
            return
        end
    end

    self:drawText("No cover preview available", pad + 8, top + 8, 1, 1, 1, 0.8, UIFont.Small)
end

function TMVinylAlbumInspectWindow:new(x, y, w, h, playerObj, texture, titleText)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.character = playerObj
    o.characterNum = playerObj and playerObj:getPlayerNum() or 0
    o.coverTexture = texture
    o.title = titleText or "Album Cover"
    o.pin = true
    o.resizable = true
    o.collapsable = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 }
    o.minimumWidth = 260
    o.minimumHeight = 260
    return o
end

local function _openInspectWindow(playerObj, albumItem)
    if not playerObj or not albumItem then
        return
    end
    local playerNum = playerObj:getPlayerNum()
    local existing = TMVinylAlbumInspectWindow.instances[playerNum]
    if existing then
        existing:close()
        TMVinylAlbumInspectWindow.instances[playerNum] = nil
    end

    local tex = _resolveAlbumTexture(albumItem)
    local titleText = albumItem:getDisplayName() or "Album Cover"
    local sw = getCore() and getCore():getScreenWidth() or 1920
    local sh = getCore() and getCore():getScreenHeight() or 1080
    local win = TMVinylAlbumInspectWindow:new(
        math.max(20, math.floor(sw * 0.5) - 220),
        math.max(20, math.floor(sh * 0.5) - 220),
        440,
        440,
        playerObj,
        tex,
        titleText
    )
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setVisible(true)
    TMVinylAlbumInspectWindow.instances[playerNum] = win
end

local function _onFillInventoryContext(playerIndex, context, items)
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then
        return
    end

    local albumItem = nil
    local albumCount = 0
    if type(items) == "table" then
        for _, v in ipairs(items) do
            local item = _getItem(v)
            if item and _isVinylAlbumItem(item) then
                albumItem = item
                albumCount = albumCount + 1
            end
        end
    else
        local item = _getItem(items)
        if item and _isVinylAlbumItem(item) then
            albumItem = item
            albumCount = 1
        end
    end

    if albumCount ~= 1 or not albumItem then
        return
    end
    if not _isItemInPlayerInventory(playerObj, albumItem) then
        return
    end

    local state = _ensureAlbumState(albumItem)
    _applyAlbumDisplayState(albumItem)

    if not state.empty then
        context:addOption("Remove Vinyl", playerObj, _removeVinylFromAlbum, albumItem)
    else
        local insertOption = context:addOption("Insert Vinyl", playerObj, nil)
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(insertOption, subMenu)

        local matching = _findMatchingVinylInInventory(playerObj, state.matchingVinylFullType)
        if matching then
            subMenu:addOption(matching:getDisplayName(), playerObj, _insertVinylIntoAlbum, albumItem, matching)
        else
            local na = subMenu:addOption("No matching vinyl in inventory", playerObj, nil)
            na.notAvailable = true
        end
    end

    context:addOption("Inspect Cover", playerObj, _openInspectWindow, albumItem)
end

Events.OnFillInventoryObjectContextMenu.Add(_onFillInventoryContext)
