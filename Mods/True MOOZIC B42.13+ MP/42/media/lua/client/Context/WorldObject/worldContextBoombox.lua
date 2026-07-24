require "TCMusicDefenitions"
local function isLegacyProxyDisabled(obj)
    --[[ JUKEBOX LIFESTYLES DISABLED
    if not obj or not obj.getModData then return false end
    local md = obj:getModData()
    local tcm = md and md.tcmusic or nil
    return tcm and (false == true or false == true)
    JUKEBOX LIFESTYLES DISABLED --]]
    return false
end

local function isLSJukeboxObject(obj)
    --[[ JUKEBOX LIFESTYLES DISABLED
    if not obj or not obj.getSprite then return false end
    local spr = obj:getSprite()
    local props = spr and spr.getProperties and spr:getProperties() or nil
    return props and props.has and props:has("CustomName") and props:get("CustomName") == "Jukebox"
    JUKEBOX LIFESTYLES DISABLED --]]
    return false
end

local function hasLSJukeboxInContext(worldobjects)
    --[[ JUKEBOX LIFESTYLES DISABLED
    if not worldobjects then return false end
    for _, obj in ipairs(worldobjects) do
        if obj and isLSJukeboxObject(obj) then return true end
        local sq = obj and obj.getSquare and obj:getSquare() or nil
        if sq and sq.getObjects then
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local sqObj = objs:get(i)
                if sqObj and isLSJukeboxObject(sqObj) then
                    return true
                end
            end
        end
    end
    JUKEBOX LIFESTYLES DISABLED --]]
    return false
end

local function ensureIsoRadioForWorldItem(square, item)
    if not square or not item or not instanceof(item, "Radio") then return nil end
    if not (TCMusic and TCMusic.WorldMusicPlayer and item.getFullType) then return nil end

    local fullType = item:getFullType()
    local spriteName = TCMusic.WorldMusicPlayer[fullType]
    if not spriteName then return nil end

    local itemId = item.getID and item:getID() or nil
    if not itemId then return nil end

    local objs = square.getObjects and square:getObjects() or nil
    if objs then
        for i = 0, objs:size() - 1 do
            local tObj = objs:get(i)
            if tObj and instanceof(tObj, "IsoRadio") and tObj.getModData then
                local md = tObj:getModData()
                if md and md.RadioItemID and tonumber(md.RadioItemID) == tonumber(itemId) then
                    return tObj
                end
            end
        end
    end

    local sprite = getSprite(spriteName)
    if not sprite then return nil end
    local radio = IsoRadio.new(getCell(), square, sprite)
    if not radio then return nil end
    square:AddTileObject(radio)

    local itemMd = item:getModData() or {}
    radio:getModData().tcmusic = {}
    if itemMd.tcmusic then
        for k, v in pairs(itemMd.tcmusic) do
            radio:getModData().tcmusic[k] = v
        end
    end
    radio:getModData().tcmusic.deviceType = "IsoObject"
    radio:getModData().tcmusic.isPlaying = false
    radio:getModData().RadioItemID = itemId

    local itemDd = item.getDeviceData and item:getDeviceData() or nil
    local radioDd = radio.getDeviceData and radio:getDeviceData() or nil
    if itemDd and radioDd then
        radioDd:setIsTurnedOn(false)
        if itemDd.getMediaType and radioDd.setMediaType then
            local mt = itemDd:getMediaType()
            if mt ~= nil and mt >= 0 then
                radioDd:setMediaType(mt)
            end
        end
        if itemDd.getDeviceVolume and radioDd.setDeviceVolume then
            radioDd:setDeviceVolume(itemDd:getDeviceVolume())
        end
        if itemMd.tcmusic and itemMd.tcmusic.batteryHas ~= nil and radioDd.setHasBattery then
            radioDd:setHasBattery(itemMd.tcmusic.batteryHas)
        elseif itemDd.getHasBattery and radioDd.setHasBattery then
            radioDd:setHasBattery(itemDd:getHasBattery())
        end
        if itemMd.tcmusic and itemMd.tcmusic.batteryPower ~= nil and radioDd.setPower then
            radioDd:setPower(itemMd.tcmusic.batteryPower)
        elseif itemDd.getPower and radioDd.setPower then
            radioDd:setPower(itemDd:getPower())
        end
        if itemDd.getHeadphoneType and radioDd.setHeadphoneType then
            radioDd:setHeadphoneType(itemDd:getHeadphoneType())
        end
    end

    -- Fallback: ensure media module is available for legacy/malformed deviceData.
    if radioDd and radioDd.getMediaType and radioDd.setMediaType then
        local mt = radioDd:getMediaType()
        if mt == nil or mt < 0 then
            local fullType = item.getFullType and item:getFullType() or nil
            if fullType and fullType:lower():find("vinyl") then
                radioDd:setMediaType(1)
            else
                radioDd:setMediaType(0)
            end
        end
    end

    return radio
end

function TCFillContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then
        return true;
    end
    if getCore():getGameMode() == "LastStand" then
        return;
    end
    if test then
        return ISWorldObjectContextMenu.setTest();
    end
    local playerObj = getSpecificPlayer(player);
    if not playerObj then
        return;
    end
    --[[ JUKEBOX LIFESTYLES DISABLED
    if hasLSJukeboxInContext(worldobjects) then
        return;
    end
    JUKEBOX LIFESTYLES DISABLED --]]
    local playerNum = playerObj:getPlayerNum();
    if playerObj:getVehicle() then
        return;
    end
    local squares = {};
    local doneSquare = {};
    for i, v in ipairs(worldobjects or {}) do
        if v and v.getSquare and v:getSquare() and not doneSquare[v:getSquare()] then
            doneSquare[v:getSquare()] = true;
            table.insert(squares, v:getSquare());
        end
    end
    if #squares == 0 then
        return false;
    end
    local worldObjects = {};
    if JoypadState.players[playerNum + 1] then
        for _, square in ipairs(squares) do
            if square and square.getWorldObjects then
                local squareObjects = square:getWorldObjects();
                for i = 1, squareObjects:size() do
                    local worldObject = squareObjects:get(i - 1);
                    if worldObject then
                        table.insert(worldObjects, worldObject);
                    end
                end
            end
        end
    else
        local squares2 = {};
        for k, v in pairs(squares) do
            squares2[k] = v;
        end
        local radius = 1;
        for _, square in ipairs(squares2) do
            if square and context.x and context.y and square.getZ then
                local success, worldX, worldY = pcall(function()
                    return screenToIsoX(playerNum, context.x, context.y, square:getZ()), screenToIsoY(playerNum, context.x, context.y, square:getZ());
                end);
                if success then
                    if ISWorldObjectContextMenu.getSquaresInRadius then
                        ISWorldObjectContextMenu.getSquaresInRadius(worldX, worldY, square:getZ(), radius, doneSquare, squares);
                    end
                end
            end
        end
        for _, square in pairs(squares) do
            if square and square.getWorldObjects then
                local squareObjects = square:getWorldObjects();
                for i = 1, squareObjects:size() do
                    local worldObject = squareObjects:get(i - 1);
                    if worldObject then
                        table.insert(worldObjects, worldObject);
                    end
                end
            end
        end
    end
    if #worldObjects == 0 then
        return false;
    end
    local itemList = {};
    for _, worldObject in ipairs(worldObjects) do
        local itemName = "???";
        if worldObject and instanceof(worldObject, "IsoWorldInventoryObject") then
            local success, name = pcall(function()
                if worldObject.getName and worldObject:getName() then
                    return worldObject:getName();
                elseif worldObject.getItem and worldObject:getItem() and worldObject:getItem().getName and worldObject:getItem():getName() then
                    return worldObject:getItem():getName();
                else
                    return "???";
                end
            end);
            if success then
                itemName = name or "???";
            end
        end
        if not itemList[itemName] then
            itemList[itemName] = {};
        end
        table.insert(itemList[itemName], worldObject);
    end
    local walkmanIsoObj = nil
    for name, items in pairs(itemList) do
        local item = items[1] and items[1].getItem and items[1]:getItem() or nil;
        local square = items[1] and items[1].getSquare and items[1]:getSquare() or nil;
        if item and instanceof(item, "Radio") then
            local itemType = nil;
            local success, typeResult = pcall(function()
                return item.getFullType and item:getFullType() or "";
            end);
            if success then
                itemType = typeResult;
            end
            local obj = nil;
            if square and square.getObjects then
                local objs = square:getObjects();
                local itemID = nil;
                local success, idResult = pcall(function()
                    return item.getID and item:getID() or 0;
                end);
                if success then
                    itemID = idResult;
                end
                local link = itemID;
                for i = 0, objs:size() - 1 do
                    local tObj = objs:get(i);
                    if instanceof(tObj, "IsoRadio") then
                        local md = nil;
                        local success, modData = pcall(function()
                            return tObj.getModData and tObj:getModData() or {};
                        end);
                        if success then
                            md = modData;
                        end
                        local radioItemID = md and md.RadioItemID and tonumber(md.RadioItemID) or nil;
                        if radioItemID and radioItemID == link then
                            obj = tObj;
                            break;
                        end
                    end
                end
            end
            if (not obj) and square then
                obj = ensureIsoRadioForWorldItem(square, item)
            end
            if obj then -- legacy jukebox proxy path removed
                if TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[itemType] then
                    walkmanIsoObj = obj
                else
                    local deviceOptionText = getText("IGUI_DeviceOptions")
                    if context.getOptionFromName then
                        local existingOpt = context:getOptionFromName(deviceOptionText)
                        if existingOpt and context.removeOption then
                            context:removeOption(existingOpt)
                        end
                    end
                    context:addOptionOnTop(deviceOptionText, playerObj, function(pl, obj)
                        if ISRadioWindow and ISRadioWindow.activate then
                            ISRadioWindow.activate(pl, obj, true);
                        end
                    end, obj);
                end
            end
        end
    end
    if walkmanIsoObj then
        local deviceOptionText = getText("IGUI_DeviceOptions")
        if context.getOptionFromName then
            local existingOpt = context:getOptionFromName(deviceOptionText)
            if existingOpt and context.removeOption then
                context:removeOption(existingOpt)
            end
        end
        context:addOptionOnTop(deviceOptionText, playerObj, function(pl, obj)
            if ISRadioWindow and ISRadioWindow.activate then
                ISRadioWindow.activate(pl, obj, true);
            end
        end, walkmanIsoObj);
    end
end
if TCFillContextMenu then
    Events.OnFillWorldObjectContextMenu.Add(TCFillContextMenu);
end

local function TCRemoveDuplicateWalkmanOptions(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then
        return true;
    end
    if not context or not worldobjects or not TCMusic or not TCMusic.WalkmanPlayer then
        return;
    end
    local hasWalkman = false;
    for _, obj in ipairs(worldobjects) do
        if obj and instanceof(obj, "IsoWorldInventoryObject") then
            local item = obj.getItem and obj:getItem() or nil;
            if item and item.getFullType and TCMusic.WalkmanPlayer[item:getFullType()] then
                hasWalkman = true;
                break;
            end
        end
    end
    if not hasWalkman then return; end

    local deviceOptionText = getText("IGUI_DeviceOptions");
    local options = context.options or {};
    local kept = false;
    for i = #options, 1, -1 do
        local opt = options[i];
        if opt and opt.name == deviceOptionText then
            if kept then
                if context.removeOption then
                    context:removeOption(opt);
                end
            else
                kept = true;
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(TCRemoveDuplicateWalkmanOptions);

