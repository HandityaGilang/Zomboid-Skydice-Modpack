if isClient() then return end

local TMSpeakerCommands = {}

------------------------------------------------------------------
-- Constants
------------------------------------------------------------------
local WIRE_ITEM_TYPE   = "Tsarcraft.WireBundle"
local WIRE_MAX_FT      = 200
local WIRE_FT_PER_TILE = 5
local MAX_CONNECT_RANGE = 30

-- Server-side sprite to item type mapping (never trust client)
local SPEAKER_ITEM_MAP = {
    ["recreational_01_76"] = "Base.Mov_WoodSpeakerCabinet",
    ["recreational_01_77"] = "Base.Mov_WoodSpeakerCabinet",
    ["recreational_01_78"] = "Base.Mov_WoodSpeakerCabinet",
    ["recreational_01_79"] = "Base.Mov_WoodSpeakerCabinet",
    ["recreational_01_80"] = "Base.Mov_BlackSpeakerCabinet",
    ["recreational_01_81"] = "Base.Mov_BlackSpeakerCabinet",
    ["recreational_01_82"] = "Base.Mov_BlackSpeakerCabinet",
    ["recreational_01_83"] = "Base.Mov_BlackSpeakerCabinet",
}

local SPEAKER_SPRITES = {}
for k, _ in pairs(SPEAKER_ITEM_MAP) do SPEAKER_SPRITES[k] = true end

local SPEAKER_ITEM_TYPES = {
    ["Base.Speaker"] = true,
}

local VINYL_SPRITES = {
    ["tsarcraft_music_01_63"] = true,
    ["tsarcraft_music_01_36"] = true,
}

local MASTER_DEVICE_FULLTYPES = {
    ["Tsarcraft.TCVinylplayer"]                   = true,
    ["Tsarcraft.TM_HiFiStereo"]                     = true,
}

------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------
local function getShortSprite(sname)
    if not sname then return nil end
    return string.match(sname, "[^.]+$") or sname
end

local function getSpriteName(obj)
    if not obj then return nil end
    if obj.getSprite then
        local spr = obj:getSprite()
        if spr and spr.getName then return spr:getName() end
    end
    if obj.getName then return obj:getName() end
    return nil
end

local function isSpeakerSprite(sname)
    if not sname then return false end
    if SPEAKER_SPRITES[sname] then return true end
    local short = getShortSprite(sname)
    return short and SPEAKER_SPRITES[short] or false
end

local function isVinylSprite(sname)
    if not sname then return false end
    if VINYL_SPRITES[sname] then return true end
    local short = getShortSprite(sname)
    return short and VINYL_SPRITES[short] or false
end

local function isMasterDevice(obj)
    if not obj then return false end
    local sname = getSpriteName(obj)
    if isVinylSprite(sname) then return true end
    if instanceof(obj, "IsoWorldInventoryObject") then
        local it = obj:getItem()
        if it and it.getFullType then
            return MASTER_DEVICE_FULLTYPES[it:getFullType()] == true
        end
    end
    return false
end

local function masterExistsAt(x, y, z)
    local sq = getSquare(x, y, z)
    if not sq then return false end
    local objects = sq:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            if isMasterDevice(objects:get(i)) then return true end
        end
    end
    local wobjs = sq:getWorldObjects()
    if wobjs then
        for i = 0, wobjs:size() - 1 do
            if isMasterDevice(wobjs:get(i)) then return true end
        end
    end
    return false
end

local function tileDistance(x1, y1, x2, y2)
    return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
end

-- Find a tile speaker object at position
local function findTileSpeakerAt(x, y, z, spriteName)
    local sq = getSquare(x, y, z)
    if not sq then return nil end
    local objects = sq:getObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        local sname = getSpriteName(o)
        if spriteName and sname == spriteName then return o end
        if isSpeakerSprite(sname) then return o end
    end
    return nil
end

-- Find an item speaker (IsoWorldInventoryObject) at position
local function findItemSpeakerAt(x, y, z)
    local sq = getSquare(x, y, z)
    if not sq then return nil end
    local wobjs = sq:getWorldObjects()
    if not wobjs then return nil end
    for i = 0, wobjs:size() - 1 do
        local o = wobjs:get(i)
        if instanceof(o, "IsoWorldInventoryObject") then
            local it = o:getItem()
            if it and it.getFullType and SPEAKER_ITEM_TYPES[it:getFullType()] then
                return o
            end
        end
    end
    return nil
end

-- Find online player by username
local function findPlayerByUsername(username)
    if not username then return nil end
    local players = getOnlinePlayers()
    if not players then return nil end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and p:getUsername() == username then return p end
    end
    return nil
end

------------------------------------------------------------------
-- Wire helpers (server-side, operates on player inventory)
------------------------------------------------------------------
local function getWireRemaining(wireItem)
    if not wireItem then return 0 end
    local md = wireItem:getModData()
    if md.tmWireFt == nil then md.tmWireFt = WIRE_MAX_FT end
    return md.tmWireFt
end

local function nameWireBundle(wireItem, ft)
    if ft <= 0 then
        wireItem:setName("Speaker Wire Bundle (empty)")
    else
        wireItem:setName("Speaker Wire Bundle (" .. tostring(ft) .. "ft)")
    end
end

local function getAllWireSorted(player)
    local inv = player:getInventory()
    if not inv then return {} end
    local items = inv:getItemsFromFullType(WIRE_ITEM_TYPE)
    if not items or items:size() == 0 then return {} end
    local list = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local ft = getWireRemaining(it)
        table.insert(list, { item = it, ft = ft })
    end
    table.sort(list, function(a, b) return a.ft < b.ft end)
    return list
end

local function getTotalWire(player)
    local sorted = getAllWireSorted(player)
    local total = 0
    for _, entry in ipairs(sorted) do total = total + entry.ft end
    return total, sorted
end

local function consumeWire(player, ftNeeded)
    local sorted = getAllWireSorted(player)
    local remaining = ftNeeded
    local inv = player:getInventory()
    for _, entry in ipairs(sorted) do
        if remaining <= 0 then break end
        local take = math.min(entry.ft, remaining)
        local newFt = entry.ft - take
        local wireMd = entry.item:getModData()
        wireMd.tmWireFt = newFt
        remaining = remaining - take
        if newFt <= 0 then
            inv:Remove(entry.item)
        else
            nameWireBundle(entry.item, newFt)
        end
    end
    return remaining <= 0
end

local function findBestWire(player)
    local sorted = getAllWireSorted(player)
    if #sorted == 0 then return nil, 0 end
    return sorted[#sorted].item, sorted[#sorted].ft
end

local function createWireBundle(player, ft)
    local inv = player:getInventory()
    if not inv then return nil end
    local newItem = instanceItem(WIRE_ITEM_TYPE)
    if not newItem then return nil end
    local md = newItem:getModData()
    md.tmWireFt = ft
    nameWireBundle(newItem, ft)
    inv:AddItem(newItem)
    sendAddItemToContainer(inv, newItem)
    return newItem
end

local function recoverWire(player, ftToRecover)
    if ftToRecover <= 0 or not player then return end
    local remaining = ftToRecover
    local wireItem, wireFt = findBestWire(player)
    if wireItem then
        local space = WIRE_MAX_FT - wireFt
        if space > 0 then
            local add = math.min(remaining, space)
            local wireMd = wireItem:getModData()
            wireMd.tmWireFt = wireFt + add
            nameWireBundle(wireItem, wireFt + add)
            remaining = remaining - add
        end
    end
    while remaining > 0 do
        local add = math.min(remaining, WIRE_MAX_FT)
        createWireBundle(player, add)
        remaining = remaining - add
    end
end

-- Clear speaker modData connection fields
local function clearSpeakerConnection(speakerObj)
    local spMd = speakerObj:getModData()
    if spMd.tmspeaker then
        spMd.tmspeaker.connected = false
        spMd.tmspeaker.masterX = nil
        spMd.tmspeaker.masterY = nil
        spMd.tmspeaker.masterZ = nil
        spMd.tmspeaker.masterType = nil
        spMd.tmspeaker.masterName = nil
        spMd.tmspeaker.vinylX = nil
        spMd.tmspeaker.vinylY = nil
        spMd.tmspeaker.vinylZ = nil
        spMd.tmspeaker.wireUsed = nil
        spMd.tmspeaker.connectedBy = nil
    end
    if speakerObj.transmitModData then speakerObj:transmitModData() end
end

------------------------------------------------------------------
-- Command: pickupSpeaker
-- Server derives itemType from sprite whitelist (no client trust)
------------------------------------------------------------------
function TMSpeakerCommands.pickupSpeaker(player, args)
    local sqr = getSquare(args.x, args.y, args.z)
    if not sqr then return end
    local objects = sqr:getObjects()
    if not objects then return end
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local sprite = object:getSprite()
        if sprite then
            local name_sprite = sprite:getName()
            if name_sprite == args.nameSprite then
                -- Derive item type server-side from sprite whitelist
                local short = getShortSprite(name_sprite)
                local itemType = SPEAKER_ITEM_MAP[short]
                if not itemType then return end  -- unknown sprite, reject

                -- Auto-disconnect if connected, recover wire to original connector
                local md = object:getModData()
                if md and md.tmspeaker and md.tmspeaker.connected then
                    local wireUsed = md.tmspeaker.wireUsed or 0
                    local connectedBy = md.tmspeaker.connectedBy
                    local targetPlayer = findPlayerByUsername(connectedBy) or player
                    if wireUsed > 0 then
                        recoverWire(targetPlayer, wireUsed)
                    end
                    -- Broadcast disconnect to all clients
                    sendServerCommand('tmspeaker', 'speakerDisconnected', {
                        speakerX = args.x, speakerY = args.y, speakerZ = args.z,
                        isTileSpeaker = true,
                    })
                end

                -- Remove from world FIRST (prevents race condition)
                sqr:transmitRemoveItemFromSquare(object)

                -- Then add to player inventory
                if player and player:getInventory() then
                    local inv = player:getInventory()
                    local added = inv:AddItem(itemType)
                    if added then
                        sendAddItemToContainer(inv, added)
                    end
                end
                break
            end
        end
    end
end

------------------------------------------------------------------
-- Command: connectSpeaker
-- Server-authoritative: validates distance, wire, device existence
------------------------------------------------------------------
function TMSpeakerCommands.connectSpeaker(player, args)
    if not player or not args then return end

    local isTile = args.isTileSpeaker
    local speakerObj
    if isTile then
        speakerObj = findTileSpeakerAt(args.speakerX, args.speakerY, args.speakerZ, args.speakerSprite)
    else
        speakerObj = findItemSpeakerAt(args.speakerX, args.speakerY, args.speakerZ)
    end

    if not speakerObj then
        sendServerCommand(player, 'tmspeaker', 'connectResult', {
            success = false, msg = "Speaker not found", isTileSpeaker = isTile,
        })
        return
    end

    -- Check already connected
    local spMd = speakerObj:getModData()
    if spMd and spMd.tmspeaker and spMd.tmspeaker.connected then
        sendServerCommand(player, 'tmspeaker', 'connectResult', {
            success = false, msg = "Speaker already connected", isTileSpeaker = isTile,
        })
        return
    end

    -- Validate device exists
    if not masterExistsAt(args.deviceX, args.deviceY, args.deviceZ) then
        sendServerCommand(player, 'tmspeaker', 'connectResult', {
            success = false, msg = "Device not found", isTileSpeaker = isTile,
        })
        return
    end

    -- Validate distance
    local dist = tileDistance(args.speakerX, args.speakerY, args.deviceX, args.deviceY)
    if dist > MAX_CONNECT_RANGE then
        sendServerCommand(player, 'tmspeaker', 'connectResult', {
            success = false, msg = "Device too far away", isTileSpeaker = isTile,
        })
        return
    end

    -- Calculate and validate wire
    local ftNeeded = dist * WIRE_FT_PER_TILE
    local totalFt = getTotalWire(player)
    if totalFt < ftNeeded then
        sendServerCommand(player, 'tmspeaker', 'connectResult', {
            success = false,
            msg = "Not enough wire (" .. tostring(ftNeeded) .. "ft needed, have " .. tostring(totalFt) .. "ft)",
            isTileSpeaker = isTile,
        })
        return
    end

    -- Consume wire from player inventory
    consumeWire(player, ftNeeded)

    -- Set modData on speaker
    spMd.tmspeaker = spMd.tmspeaker or {}
    spMd.tmspeaker.masterX = args.deviceX
    spMd.tmspeaker.masterY = args.deviceY
    spMd.tmspeaker.masterZ = args.deviceZ
    spMd.tmspeaker.masterType = args.deviceType
    spMd.tmspeaker.masterName = args.deviceName
    spMd.tmspeaker.vinylX = args.deviceX
    spMd.tmspeaker.vinylY = args.deviceY
    spMd.tmspeaker.vinylZ = args.deviceZ
    spMd.tmspeaker.wireUsed = ftNeeded
    spMd.tmspeaker.connected = true
    spMd.tmspeaker.connectedBy = player:getUsername()
    if speakerObj.transmitModData then speakerObj:transmitModData() end

    -- Respond to requesting player
    sendServerCommand(player, 'tmspeaker', 'connectResult', {
        success = true,
        speakerX = args.speakerX, speakerY = args.speakerY, speakerZ = args.speakerZ,
        deviceX = args.deviceX, deviceY = args.deviceY, deviceZ = args.deviceZ,
        deviceType = args.deviceType, deviceName = args.deviceName,
        isTileSpeaker = isTile, ftUsed = ftNeeded,
    })

    -- Broadcast to all clients so they start emitters
    sendServerCommand('tmspeaker', 'speakerConnected', {
        speakerX = args.speakerX, speakerY = args.speakerY, speakerZ = args.speakerZ,
        deviceX = args.deviceX, deviceY = args.deviceY, deviceZ = args.deviceZ,
        deviceType = args.deviceType,
        isTileSpeaker = isTile,
    })
end

------------------------------------------------------------------
-- Command: disconnectSpeaker
-- Server-authoritative: recovers wire to requesting player
------------------------------------------------------------------
function TMSpeakerCommands.disconnectSpeaker(player, args)
    if not player or not args then return end

    local isTile = args.isTileSpeaker
    local speakerObj
    if isTile then
        speakerObj = findTileSpeakerAt(args.speakerX, args.speakerY, args.speakerZ, args.speakerSprite)
    else
        speakerObj = findItemSpeakerAt(args.speakerX, args.speakerY, args.speakerZ)
    end

    if not speakerObj then return end
    local spMd = speakerObj:getModData()
    if not spMd or not spMd.tmspeaker or not spMd.tmspeaker.connected then return end

    local wireRecovered = spMd.tmspeaker.wireUsed or 0
    if wireRecovered > 0 then
        recoverWire(player, wireRecovered)
    end

    clearSpeakerConnection(speakerObj)

    -- Respond to requesting player
    sendServerCommand(player, 'tmspeaker', 'disconnectResult', {
        success = true,
        speakerX = args.speakerX, speakerY = args.speakerY, speakerZ = args.speakerZ,
        isTileSpeaker = isTile, wireRecovered = wireRecovered,
    })

    -- Broadcast to all clients
    sendServerCommand('tmspeaker', 'speakerDisconnected', {
        speakerX = args.speakerX, speakerY = args.speakerY, speakerZ = args.speakerZ,
        isTileSpeaker = isTile,
    })
end

------------------------------------------------------------------
-- Command: autoDisconnectSpeaker
-- Called when client detects master device removed
-- Recovers wire to the ORIGINAL connector if online
------------------------------------------------------------------
function TMSpeakerCommands.autoDisconnectSpeaker(player, args)
    if not args then return end

    local isTile = args.isTileSpeaker
    local speakerObj
    if isTile then
        speakerObj = findTileSpeakerAt(args.speakerX, args.speakerY, args.speakerZ, args.speakerSprite)
    else
        speakerObj = findItemSpeakerAt(args.speakerX, args.speakerY, args.speakerZ)
    end

    if not speakerObj then return end
    local spMd = speakerObj:getModData()
    if not spMd or not spMd.tmspeaker or not spMd.tmspeaker.connected then return end

    -- Verify master is truly gone server-side
    local vx = spMd.tmspeaker.masterX or spMd.tmspeaker.vinylX
    local vy = spMd.tmspeaker.masterY or spMd.tmspeaker.vinylY
    local vz = spMd.tmspeaker.masterZ or spMd.tmspeaker.vinylZ
    if vx and vy and vz and masterExistsAt(vx, vy, vz) then
        return  -- Master still exists, reject
    end

    -- Recover wire to original connector if online, otherwise to requesting player
    local wireUsed = spMd.tmspeaker.wireUsed or 0
    if wireUsed > 0 then
        local connectedBy = spMd.tmspeaker.connectedBy
        local targetPlayer = findPlayerByUsername(connectedBy) or player
        recoverWire(targetPlayer, wireUsed)
    end

    clearSpeakerConnection(speakerObj)

    -- Broadcast to all clients
    sendServerCommand('tmspeaker', 'speakerDisconnected', {
        speakerX = args.speakerX, speakerY = args.speakerY, speakerZ = args.speakerZ,
        isTileSpeaker = isTile,
    })
end

------------------------------------------------------------------
-- Dispatcher
------------------------------------------------------------------
TMSpeakerCommands.OnClientCommand = function(module, command, player, args)
    if module == 'tmspeaker' and TMSpeakerCommands[command] then
        TMSpeakerCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(TMSpeakerCommands.OnClientCommand)
