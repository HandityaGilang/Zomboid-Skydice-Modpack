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

local function _endsWith(s, suffix)
    return type(s) == "string" and type(suffix) == "string" and suffix ~= "" and string.sub(s, -#suffix) == suffix
end

local function _splitFullType(fullType)
    local moduleName, itemName = string.match(tostring(fullType or ""), "^(.-)%.(.+)$")
    return moduleName, itemName
end

local function _resolveFlip(item)
    if not item or not item.getFullType then
        return nil
    end

    local fullType = item:getFullType()
    local moduleName, itemName = _splitFullType(fullType)
    if not moduleName or not itemName then
        return nil
    end

    local label = nil
    if _startsWith(itemName, "Cassette") then
        label = "Flip Cassette"
    elseif _startsWith(itemName, "Vinyl") and not _startsWith(itemName, "VinylAlbum") then
        label = "Flip Vinyl"
    else
        return nil
    end

    local targetName = nil
    if _endsWith(itemName, "SideB") then
        targetName = string.sub(itemName, 1, #itemName - #"SideB")
    else
        targetName = itemName .. "SideB"
    end

    local targetFullType = moduleName .. "." .. targetName
    if not getScriptManager() or not getScriptManager():FindItem(targetFullType) then
        return nil
    end

    return {
        label = label,
        targetFullType = targetFullType,
    }
end

local function _flipMediaItem(playerObj, item, targetFullType)
    if not playerObj or not item or not targetFullType then
        return
    end

    local inv = playerObj:getInventory()
    local container = item:getContainer()
    if not inv or container ~= inv then
        return
    end

    local created = inv:AddItem(targetFullType)
    if not created then
        return
    end

    inv:DoRemoveItem(item)
end

local function _onFillInventoryContext(playerIndex, context, items)
    local playerObj = getSpecificPlayer(playerIndex)
    if not playerObj then
        return
    end

    local mediaItem = nil
    local count = 0
    if type(items) == "table" then
        for _, v in ipairs(items) do
            local item = _getItem(v)
            if item then
                local flip = _resolveFlip(item)
                if flip then
                    mediaItem = item
                    count = count + 1
                end
            end
        end
    else
        local item = _getItem(items)
        if item and _resolveFlip(item) then
            mediaItem = item
            count = 1
        end
    end

    if count ~= 1 or not mediaItem then
        return
    end

    local flip = _resolveFlip(mediaItem)
    if not flip then
        return
    end

    context:addOption(flip.label, playerObj, _flipMediaItem, mediaItem, flip.targetFullType)
end

Events.OnFillInventoryObjectContextMenu.Add(_onFillInventoryContext)

