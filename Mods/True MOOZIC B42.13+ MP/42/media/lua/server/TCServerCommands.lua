

if isClient() then return end

pcall(require, "TCStartWithDevice")
local TrueMCommands = {}
local PROBE = false
if PROBE then
    print("[TMDBG][BOOT][Server] TCServerCommands probe=" .. tostring(PROBE))
end

local function probe(msg)
    if PROBE then
        print("[TMDBG][ServerCmd] " .. tostring(msg))
    end
end

local function stringifyArgs(args)
    if not args then return "{}" end
    local out = {}
    for k, v in pairs(args) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
    end
    table.sort(out)
    return "{" .. table.concat(out, ", ") .. "}"
end

local function findPlayerInventoryItemById(player, itemId)
    if not player or not itemId then return nil, nil end
    local inv = player:getInventory()
    local items = inv and inv:getItems() or nil
    if not items then return inv, nil end
    local wanted = tonumber(itemId)
    if not wanted then return inv, nil end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getID and tonumber(it:getID()) == wanted then
            return inv, it
        end
    end
    return inv, nil
end

local function getNowPlayTable()
    local md = ModData.getOrCreate("trueMusicData")
    md["now_play"] = md["now_play"] or {}
    return md["now_play"]
end

local function resolveWorldMusicId(args)
    if args and args.radioItemID ~= nil and tostring(args.radioItemID) ~= "" then
        return "W:" .. tostring(args.radioItemID)
    end
    
    if args and args.x ~= nil and args.y ~= nil and args.z ~= nil and args.musicId and string.match(tostring(args.musicId), '^#') then
        return "W:C:" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end
    if args and args.musicId and tostring(args.musicId) ~= "" then
        return tostring(args.musicId)
    end
    if args and args.x ~= nil and args.y ~= nil and args.z ~= nil then
        return "#" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end
    return nil
end

local function isMalformedWorldArgs(args)
    if not args then return false end
    local hasCoords = (args.x ~= nil and args.y ~= nil and args.z ~= nil)
    local hasRadioItem = (args.radioItemID ~= nil and tostring(args.radioItemID) ~= "")
    local hasFallback = (args.musicId and string.match(tostring(args.musicId), '^#'))
    return hasCoords and (not hasRadioItem) and (not hasFallback)
end

local function clearLegacyWorldKeys(nowPlay, keepMusicId, args)
    if not nowPlay or not args then return end
    local keep = keepMusicId and tostring(keepMusicId) or nil
    local radioItemID = args.radioItemID and tostring(args.radioItemID) or nil
    local legacyCoordId = nil
    if args.x ~= nil and args.y ~= nil and args.z ~= nil then
        legacyCoordId = "#" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end

    if legacyCoordId and legacyCoordId ~= keep then
        nowPlay[legacyCoordId] = nil
    end

    if radioItemID then
        for k, row in pairs(nowPlay) do
            if k ~= keep and string.sub(tostring(k), 1, 1) == "#" then
                local rowItem = row and row.itemid and tostring(row.itemid) or nil
                if rowItem == radioItemID then
                    nowPlay[k] = nil
                end
            end
        end
    end
end

local function hasJukeboxSourceAt(args)
    
    return true
end

local function clearWorldStateAndTransmit(musicId, args)
    if not musicId then return end
    local nowPlay = getNowPlayTable()
    nowPlay[musicId] = nil
    clearLegacyWorldKeys(nowPlay, musicId, args)
    ModData.transmit("trueMusicData")
end

function TrueMCommands.setMediaItemToVehiclePart(player, args)
    probe("setMediaItemToVehiclePart player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    local vehicle = getVehicleById(args.vehicle)
    if vehicle then
        local part = vehicle:getPartById("Radio");
        if part then
            if not part:getModData().tcmusic then
                part:getModData().tcmusic = {}
            end
            if args.mediaItem == "nil" then
                part:getModData().tcmusic.mediaItem = nil;
            else
                part:getModData().tcmusic.mediaItem = args.mediaItem;
            end
            part:getModData().tcmusic.isPlaying = args.isPlaying;
            part:getModData().tcmusic.volume = part:getDeviceData():getDeviceVolume();
            part:getModData().tcmusic.deviceType = "VehiclePart";
            vehicle:transmitPartModData(part);
            vehicle:updateParts();
        end
    else
        noise('no such vehicle id='..tostring(args.vehicle))
    end
end

function TrueMCommands.deleteWO(player, args)
    probe("deleteWO player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    local sqr = getSquare(args.x, args.y, args.z)
    if sqr then
        local objects = sqr:getObjects()
        local objSize = objects:size()
        
        if objSize > 0 then
            for i = 0, objSize - 1 do
                local object = objects:get(i)
                if instanceof(object, "IsoWaveSignal") then
                    local sprite = object:getSprite()
                    if sprite then
                        local name_sprite = sprite:getName()
                        if name_sprite == args.nameSprite then
                            sqr:transmitRemoveItemFromSquare(object)
                            break
                        end
                    end
                end
            end
        end
    else
        noise('no such square')
    end
end

TrueMCommands.OnClientCommand = function(module, command, player, args)
    if module ~= 'truemusic' then
        return
    end
    probe("OnClientCommand module=" .. tostring(module) .. " command=" .. tostring(command) .. " player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    if TrueMCommands[command] then
        args = args or {}
        TrueMCommands[command](player, args)
    else
        probe("unknown-command command=" .. tostring(command))
    end
end

function TrueMCommands.RequestStartDevice(player, _args)
    probe("RequestStartDevice player=" .. tostring(player and player:getUsername()))
    if TCStartWithDevice and TCStartWithDevice.RequestStartDevice then
        TCStartWithDevice.RequestStartDevice(player)
    elseif TCStartWithDevice and TCStartWithDevice.GiveStartDevice then
        TCStartWithDevice.GiveStartDevice(player)
    end
end

function TrueMCommands.setVinylAlbumState(player, args)
    args = args or {}
    probe("setVinylAlbumState player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    local inv, album = findPlayerInventoryItemById(player, args.albumItemId)
    if not inv or not album then
        probe("setVinylAlbumState skipped reason=album-not-found-in-player-inventory albumItemId=" .. tostring(args.albumItemId))
        return
    end

    local md = album:getModData()
    md.tmVinylAlbum = md.tmVinylAlbum or {}
    local state = md.tmVinylAlbum
    if args.baseDisplayName ~= nil then state.baseDisplayName = tostring(args.baseDisplayName) end
    if args.matchingVinylFullType ~= nil then state.matchingVinylFullType = tostring(args.matchingVinylFullType) end
    state.empty = args.empty == true

    local base = state.baseDisplayName or album:getDisplayName() or "Vinyl Album"
    local label = state.empty and (base .. " (Empty)") or base
    if album.setName then
        album:setName(label)
    elseif album.setCustomName then
        album:setCustomName(label)
    end

    if args.grantVinyl and args.vinylFullType and args.vinylFullType ~= "" then
        local added = inv:AddItem(args.vinylFullType)
        if added and sendAddItemToContainer then
            sendAddItemToContainer(inv, added)
        end
        probe("setVinylAlbumState grantVinyl fullType=" .. tostring(args.vinylFullType) .. " added=" .. tostring(added ~= nil))
    end

    if args.consumeVinylItemId or args.consumeVinylFullType then
        local consume = nil
        if args.consumeVinylItemId then
            local _, byId = findPlayerInventoryItemById(player, args.consumeVinylItemId)
            consume = byId
        end
        if (not consume) and args.consumeVinylFullType and args.consumeVinylFullType ~= "" then
            local items = inv:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it and it.getFullType and it:getFullType() == args.consumeVinylFullType then
                    consume = it
                    break
                end
            end
        end
        if consume then
            if sendRemoveItemFromContainer then
                sendRemoveItemFromContainer(inv, consume)
            end
            inv:DoRemoveItem(consume)
            probe("setVinylAlbumState consumeVinyl removed=true")
        else
            probe("setVinylAlbumState consumeVinyl removed=false")
        end
    end

    if album.transmitModData then
        album:transmitModData()
    end
end

function TrueMCommands.setWorldDeviceMedia(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDeviceMedia skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDeviceMedia player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " media=" .. tostring(args.media))
    if not musicId then return end
    
    local nowPlay = getNowPlayTable()
    clearLegacyWorldKeys(nowPlay, musicId, args)
    local row = nowPlay[musicId] or {}
    row.musicName = args.media
    row.timestamp = "update"
    row.x = args.x
    row.y = args.y
    row.z = args.z
    row.itemid = args.radioItemID or row.itemid
    -- Media changes do not start playback.
    row.isPlaying = (args.isPlaying == true)
    nowPlay[musicId] = row
    ModData.transmit("trueMusicData")
end

function TrueMCommands.setWorldDeviceVolume(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDeviceVolume skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDeviceVolume player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " volume=" .. tostring(args.volume))
    if not musicId then return end
    
    local nowPlay = getNowPlayTable()
    clearLegacyWorldKeys(nowPlay, musicId, args)
    local row = nowPlay[musicId]
    if row then
        row.volume = args.volume
        row.timestamp = "update"
        nowPlay[musicId] = row
        ModData.transmit("trueMusicData")
    end
end

function TrueMCommands.setWorldDevicePlayback(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDevicePlayback skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDevicePlayback player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " isPlaying=" .. tostring(args.isPlaying) .. " media=" .. tostring(args.media))
    if not musicId then return end
    
    local nowPlay = getNowPlayTable()
    if args.isPlaying then
        clearLegacyWorldKeys(nowPlay, musicId, args)
        local row = nowPlay[musicId] or {}
        row.isPlaying = true
        row.volume = args.volume or row.volume or 1.0
        row.headphone = false
        row.timestamp = "update"
        row.musicName = args.media or row.musicName
        row.x = args.x
        row.y = args.y
        row.z = args.z
        row.itemid = args.radioItemID or row.itemid
        nowPlay[musicId] = row
    else
        nowPlay[musicId] = nil
        clearLegacyWorldKeys(nowPlay, musicId, args)
    end
    ModData.transmit("trueMusicData")
end

function TrueMCommands.TakeCDOut(player, args)
    args = args or {}
    if not player then return end
    local inv, caseItem = findPlayerInventoryItemById(player, args.caseItemId)
    if not inv or not caseItem then
        probe("TakeCDOut: case not found id=" .. tostring(args.caseItemId))
        return
    end
    local md = caseItem:getModData()
    local albumFt = md and md.tc_cdcase_album or nil
    if not albumFt or albumFt == "" then
        probe("TakeCDOut: case has no album stored")
        return
    end
    -- Validate the album item still exists in the script DB.
    local sm = getScriptManager()
    if sm and sm.FindItem and not sm:FindItem(albumFt) then
        probe("TakeCDOut: album fulltype not found in scripts: " .. tostring(albumFt))
        md.tc_cdcase_album = nil
        if TC_CDCase_UpdateName then TC_CDCase_UpdateName(caseItem) end
        if caseItem.sendModData then caseItem:sendModData() end
        return
    end
    local added = inv:AddItem(albumFt)
    if added and sendAddItemToContainer then
        sendAddItemToContainer(inv, added)
    end
    md.tc_cdcase_album = nil
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
    elseif caseItem.setName then
        caseItem:setName("CD Case - empty")
    end
    if caseItem.sendModData then caseItem:sendModData() end
    probe("TakeCDOut: gave album " .. tostring(albumFt) .. " to " .. tostring(player:getUsername()))
end

local function isCDAlbumFullType(ft)
    if type(ft) ~= "string" or ft == "" then return false end
    local _, name = ft:match("^([^%.]+)%.(.+)$")
    if not name then name = ft end
    return name:find("^CD_") ~= nil and name ~= "CDCase" and name ~= "CDCarryingCase"
end

function TrueMCommands.PutCDIn(player, args)
    args = args or {}
    if not player then return end
    local inv, caseItem = findPlayerInventoryItemById(player, args.caseItemId)
    if not inv or not caseItem then
        probe("PutCDIn: case not found id=" .. tostring(args.caseItemId))
        return
    end
    local _, albumItem = findPlayerInventoryItemById(player, args.albumItemId)
    if not albumItem then
        probe("PutCDIn: album not found id=" .. tostring(args.albumItemId))
        return
    end
    local md = caseItem:getModData()
    if md.tc_cdcase_album and md.tc_cdcase_album ~= "" then
        probe("PutCDIn: case already contains an album; aborting")
        return
    end
    local albumFt = albumItem.getFullType and albumItem:getFullType() or nil
    if not isCDAlbumFullType(albumFt) then
        probe("PutCDIn: item is not a CD album: " .. tostring(albumFt))
        return
    end
    md.tc_cdcase_album = albumFt
    inv:Remove(albumItem)
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
    elseif caseItem.setName then
        caseItem:setName("CD Case - " .. tostring(albumFt))
    end
    if caseItem.sendModData then caseItem:sendModData() end
    probe("PutCDIn: stored " .. tostring(albumFt) .. " in case " .. tostring(args.caseItemId))
end

Events.OnClientCommand.Add(TrueMCommands.OnClientCommand)




