if not TCMusic then TCMusic = {} end

local pendingInventorySync = {}
local pendingWorldSync = {}

local function isTrueMusicPortable(fullType)
    return TCMusic and ((TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]) or (TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]))
end

-- True when this item is the LOCAL player's currently-playing portable device;
-- inventory syncs must not force-stop it.
local function isLocalActivePortable(item)
    if not item or not item.getID then return false end
    local player = getPlayer and getPlayer() or nil
    if not player then return false end
    if not player:getModData().tcmusicid then return false end
    local pid = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(player) or nil
    if not pid then return false end
    local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
    local row = nowPlay and nowPlay[pid] or nil
    return row ~= nil and row.itemid ~= nil and tostring(row.itemid) == tostring(item:getID())
end

local function applyDeviceStateFromModData(item)
    if not item then return false end
    local md = item:getModData()
    md.tcmusic = md.tcmusic or {}
    if not isLocalActivePortable(item) then
        md.tcmusic.isPlaying = false
    end
    if md.tcmusic.headphoneType == nil and md.tm_headphoneType ~= nil then
        md.tcmusic.headphoneType = md.tm_headphoneType
    end

    local deviceData = item:getDeviceData()
    if not deviceData then return false end

    if md.tcmusic.headphoneType ~= nil and md.tcmusic.headphoneType >= 0 then
        local hpType = md.tcmusic.headphoneItemFullType
        if hpType == nil and md.tm_hasHeadphones then
            hpType = "Base.Headphones"
        end
        if hpType and deviceData.getHeadphoneType and deviceData.addHeadphones and deviceData:getHeadphoneType() < 0 then
            local hpItem = instanceItem and instanceItem(hpType) or nil
            if hpItem then
                deviceData:addHeadphones(hpItem)
            end
        end
    end
    if md.tcmusic.batteryHas ~= nil and deviceData.setHasBattery then
        deviceData:setHasBattery(md.tcmusic.batteryHas)
    end
    if md.tcmusic.batteryPower ~= nil and deviceData.setPower then
        deviceData:setPower(md.tcmusic.batteryPower)
    end
    return true
end

local function isWalkman(fullType)
    return TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]
end

------------------------------------------------------------
-- HiFi deck state (md.hifiCD / hifiTape / hifiVinyl).
-- Same problem class as tcmusic: the placed HiFi's IsoRadio is client-
-- local, so raw transmitModData is dropped and the inserted CD/tape/vinyl
-- never reaches the server or survives a chunk reload / pickup. These
-- helpers ride the decks along every item<->radio copy, and syncHiFiSlot
-- pushes deck changes through the server (setHiFiSubtable) which stamps
-- the floor item - the only thing the server persists.
------------------------------------------------------------
local HIFI_SLOTS = { "hifiCD", "hifiTape", "hifiVinyl" }

-- Jukebox-style live-state reconcile. The shared now_play table (global
-- ModData, synced to every client) is the ground truth for "a song is
-- playing at this tile" - that's why the jukebox never desyncs. A rebuilt
-- placed device must adopt the live row, or its UI shows power-off /
-- "Play" while the tile keeps blaring with no working Stop button.
function TCMusic.applyNowPlayRowToDevice(radio)
    if not radio or not radio.getModData or not radio.getX then return end
    local tm = ModData.getOrCreate("trueMusicData")
    local nowPlay = tm and tm["now_play"]
    if not nowPlay then return end
    local x, y, z = radio:getX(), radio:getY(), radio:getZ()
    local row = nil
    for _, r in pairs(nowPlay) do
        if type(r) == "table" and tonumber(r.x) == tonumber(x) and tonumber(r.y) == tonumber(y)
            and (r.z == nil or tonumber(r.z) == tonumber(z)) then
            row = r
            break
        end
    end
    if not row then return end
    local md = radio:getModData()
    md.tcmusic = md.tcmusic or {}
    if not md.tcmusic.mediaItem and row.musicName then
        md.tcmusic.mediaItem = row.musicName
    end
    if row.isPlaying == true then
        md.tcmusic.isPlaying = true
        md.tcmusic.turnedOn = true
        if row.startId then md.tcmusic.startId = row.startId end
        local dd = radio.getDeviceData and radio:getDeviceData() or nil
        if dd then
            if dd.setIsTurnedOn then dd:setIsTurnedOn(true) end
            if row.volume ~= nil and dd.setDeviceVolume then dd:setDeviceVolume(row.volume) end
        end
    end
end

function TCMusic.copyHiFiSlots(fromMd, toMd, stopPlaying)
    if not fromMd or not toMd then return end
    for i = 1, #HIFI_SLOTS do
        local slot = HIFI_SLOTS[i]
        local src = fromMd[slot]
        -- Only copy decks with content; never clobber the destination's
        -- data with an empty table (merge principle - same as tcmusic).
        if src and (src.cdType or src.mediaItem) then
            local dst = {}
            for k, v in pairs(src) do dst[k] = v end
            if stopPlaying then dst.isPlaying = false end
            toMd[slot] = dst
        end
    end
end

-- Push one deck's state to the server + mirror it onto the linked floor
-- item locally. Placed (IsoObject) devices only.
function TCMusic.syncHiFiSlot(device, slot)
    if not device or not slot or not device.getModData then return end
    local md = device:getModData()
    if not md then return end
    local data = md[slot]

    -- Mirror onto the co-located device world item (stale-ID safe).
    local sq = device.getSquare and device:getSquare() or nil
    local wobjs = sq and sq.getWorldObjects and sq:getWorldObjects() or nil
    if wobjs then
        local link = md.RadioItemID and tostring(md.RadioItemID) or nil
        local target = nil
        for i = 0, wobjs:size() - 1 do
            local wobj = wobjs:get(i)
            local item = wobj and wobj.getItem and wobj:getItem() or nil
            if item and item.getFullType and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[item:getFullType()] then
                if link and item.getID and (tostring(item:getID()) == link or (tostring(item:getID()) .. "tm") == link) then
                    target = item
                    break
                end
                target = target or item
            end
        end
        if target then
            local imd = target:getModData()
            if data and (data.cdType or data.mediaItem) then
                local cp = {}
                for k, v in pairs(data) do cp[k] = v end
                cp.isPlaying = false
                imd[slot] = cp
            else
                imd[slot] = nil
            end
        end
    end

    if isClient() and sendClientCommand and device.getX then
        local args = {
            x = device:getX(), y = device:getY(), z = device:getZ(),
            radioItemID = md.RadioItemID, slot = slot,
        }
        if data and (data.cdType or data.mediaItem) then
            args.data = data
        else
            args.clear = true
        end
        sendClientCommand(getPlayer(), 'truemusic', 'setHiFiSubtable', args)
    elseif device.transmitModData then
        -- SP / host: local object is authoritative.
        device:transmitModData()
    end
end

local function markPendingInventory(item)
    if not item or not item.getID then return end
    pendingInventorySync[item:getID()] = { item = item, ticks = 30 }
end

local function markPendingWorld(obj)
    if not obj then return end
    pendingWorldSync[obj] = { obj = obj, ticks = 30 }
end

local function syncWorldItemFromIsoRadio(obj)
    if not obj or not instanceof(obj, "IsoRadio") then return end
    local md = obj:getModData()
    if not md or not md.RadioItemID then return end
    local square = obj:getSquare()
    if not square or not square.getWorldObjects then return end

    local link = tostring(md.RadioItemID)
    local worldObjects = square:getWorldObjects()
    for i = 0, worldObjects:size() - 1 do
        local worldObj = worldObjects:get(i)
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if item and item.getID then
                local itemId = tostring(item:getID())
                if itemId == link or (itemId .. "tm") == link then
                    local itemMd = item:getModData()
                    if md.tcmusic then
                        itemMd.tcmusic = md.tcmusic
                    else
                        itemMd.tcmusic = itemMd.tcmusic or {}
                    end
                    itemMd.tcmusic.deviceType = "InventoryItem"
                    itemMd.tcmusic.isPlaying = false

                    local deviceData = obj:getDeviceData()
                    if deviceData then
                        if itemMd.tcmusic then
                            if deviceData.getHeadphoneType then
                                local hpFromWorld = deviceData:getHeadphoneType()
                                local hpBefore = itemMd.tcmusic.headphoneType
                                if hpBefore == nil and itemMd.tm_headphoneType ~= nil then
                                    hpBefore = itemMd.tm_headphoneType
                                end
                                -- Walkman world deviceData can transiently report -1; don't clobber a valid saved value.
                                local hpFinal = hpFromWorld
                                if hpFinal == nil or hpFinal < 0 then
                                    if hpBefore ~= nil then
                                        hpFinal = hpBefore
                                    else
                                        hpFinal = -1
                                    end
                                end
                                itemMd.tcmusic.headphoneType = hpFinal
                                if hpFinal >= 0 and not itemMd.tcmusic.headphoneItemFullType then
                                    itemMd.tcmusic.headphoneItemFullType = "Base.Headphones"
                                end
                                itemMd.tm_headphoneType = hpFinal
                                itemMd.tm_hasHeadphones = hpFinal >= 0
                            end
                            if deviceData.getHasBattery then
                                if itemMd.tcmusic.batteryHas == nil then
                                    itemMd.tcmusic.batteryHas = deviceData:getHasBattery()
                                end
                            end
                            if deviceData.getPower then
                                if itemMd.tcmusic.batteryPower == nil then
                                    itemMd.tcmusic.batteryPower = deviceData:getPower()
                                end
                            end
                        end
                        item:setDeviceData(deviceData)
                        if itemMd.tcmusic and itemMd.tcmusic.headphoneType ~= nil and deviceData.setHeadphoneType then
                            deviceData:setHeadphoneType(itemMd.tcmusic.headphoneType)
                        end
                        if itemMd.tcmusic then
                            if itemMd.tcmusic.batteryHas ~= nil and deviceData.setHasBattery then
                                deviceData:setHasBattery(itemMd.tcmusic.batteryHas)
                            end
                            if itemMd.tcmusic.batteryPower ~= nil and deviceData.setPower then
                                deviceData:setPower(itemMd.tcmusic.batteryPower)
                            end
                        end
                    end
                    -- Avoid calling setIsTurnedOn on inventory deviceData without a square (MP NPE)
                    -- HiFi decks (CD/tape/vinyl) ride along onto the picked-up item.
                    TCMusic.copyHiFiSlots(md, itemMd, true)
                    return
                end
            end
        end
    end
end

Events.OnObjectAboutToBeRemoved.Add(syncWorldItemFromIsoRadio)

local function syncWorldInventoryItemOnRemoved(obj)
    if not obj or not instanceof(obj, "IsoWorldInventoryObject") then return end
    local item = obj:getItem()
    if not item or not instanceof(item, "Radio") then return end
    local fullType = item.getFullType and item:getFullType() or nil
    if not (TCMusic and ((TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]) or (TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]))) then
        return
    end

    local md = item:getModData()
    md.tcmusic = md.tcmusic or {}
    md.tcmusic.deviceType = "InventoryItem"
    md.tcmusic.isPlaying = false

    local deviceData = item:getDeviceData()
    if deviceData then
    if md.tcmusic.headphoneType == nil and deviceData.getHeadphoneType then
        md.tcmusic.headphoneType = deviceData:getHeadphoneType()
        md.tm_headphoneType = md.tcmusic.headphoneType
        if md.tcmusic.headphoneType and md.tcmusic.headphoneType >= 0 and not md.tcmusic.headphoneItemFullType then
            md.tcmusic.headphoneItemFullType = "Base.Headphones"
        end
    end
        if md.tcmusic.batteryHas == nil and deviceData.getHasBattery then
            md.tcmusic.batteryHas = deviceData:getHasBattery()
        end
        if md.tcmusic.batteryPower == nil and deviceData.getPower then
            md.tcmusic.batteryPower = deviceData:getPower()
        end
    end
end

Events.OnObjectAboutToBeRemoved.Add(syncWorldInventoryItemOnRemoved)

------------------------------------------------------------
-- Deferred object-modData transmit. Calling obj:transmitModData() in the
-- same tick the object is created (OnObjectAdded fires inside
-- AddTileObject, BEFORE transmitAddObjectToSquare has told the server the
-- object exists) makes the server log "ObjectModDataPacket.parse: object
-- is null" and DROP the packet - the device-to-item link (RadioItemID)
-- then never reaches the server or other clients. Waiting ~1.5s lets the
-- add-object packet land first.
------------------------------------------------------------
local deferredTransmits = {}
local deferredCount = 0

function TCMusic.deferTransmitObjectModData(obj, ticks)
    if not obj or not obj.transmitModData then return end
    if not isClient() then return end
    deferredCount = deferredCount + 1
    deferredTransmits[deferredCount] = { obj = obj, ticks = ticks or 90 }
end

local function pumpDeferredTransmits()
    if deferredCount == 0 then return end
    local i = 1
    while i <= deferredCount do
        local entry = deferredTransmits[i]
        entry.ticks = entry.ticks - 1
        if entry.ticks <= 0 then
            local obj = entry.obj
            if obj and obj.getSquare and obj:getSquare() then
                obj:transmitModData()
            end
            deferredTransmits[i] = deferredTransmits[deferredCount]
            deferredTransmits[deferredCount] = nil
            deferredCount = deferredCount - 1
        else
            i = i + 1
        end
    end
end

Events.OnTick.Add(pumpDeferredTransmits)

local function syncWorldItemOnAdded(obj)
    if not obj or not instanceof(obj, "IsoWorldInventoryObject") then return end
    local item = obj:getItem()
    if not item or not instanceof(item, "Radio") then return end
    local fullType = item.getFullType and item:getFullType() or nil
    if not isTrueMusicPortable(fullType) then
        return
    end
    -- Dropping / placing the local player's actively-playing portable:
    -- stop the hand/character emitter and clear the portable now_play row so
    -- the sound doesn't keep following the player after the device is on the ground.
    local player = getPlayer and getPlayer() or nil
    if player and isLocalActivePortable(item) then
        local pmd = player:getModData()
        if pmd.tcmusicid then
            player:getEmitter():stopSound(pmd.tcmusicid)
            pmd.tcmusicid = nil
        end
        local pid = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(player) or nil
        local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
        if pid and nowPlay then
            nowPlay[pid] = nil
        end
        if isClient() and TCMusic.transmitNowPlay then
            TCMusic.transmitNowPlay(player)
        end
    end
    local md = item:getModData()
    md.tcmusic = md.tcmusic or {}
    md.tcmusic.isPlaying = false

    local deviceData = item:getDeviceData()
    if deviceData then
        if md.tcmusic.headphoneType == nil and deviceData.getHeadphoneType then
            md.tcmusic.headphoneType = deviceData:getHeadphoneType()
            if md.tcmusic.headphoneType and md.tcmusic.headphoneType >= 0 and not md.tcmusic.headphoneItemFullType then
                md.tcmusic.headphoneItemFullType = "Base.Headphones"
            end
        end
        if md.tcmusic.batteryHas == nil and deviceData.getHasBattery then
            md.tcmusic.batteryHas = deviceData:getHasBattery()
        end
        if md.tcmusic.batteryPower == nil and deviceData.getPower then
            md.tcmusic.batteryPower = deviceData:getPower()
        end
    end
    applyDeviceStateFromModData(item)
    markPendingWorld(obj)
end

Events.OnObjectAdded.Add(syncWorldItemOnAdded)

local function syncIsoRadioFromWorldItem(obj)
    if not obj or not instanceof(obj, "IsoRadio") then return end
    local md = obj:getModData()
    if not md or not md.RadioItemID then return end
    local square = obj:getSquare()
    if not square or not square.getWorldObjects then return end

    local link = tostring(md.RadioItemID)
    local worldObjects = square:getWorldObjects()
    for i = 0, worldObjects:size() - 1 do
        local worldObj = worldObjects:get(i)
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if item and item.getID then
                local itemId = tostring(item:getID())
                if itemId == link or (itemId .. "tm") == link then
                    local fullType = item.getFullType and item:getFullType() or nil
                    if not isTrueMusicPortable(fullType) then
                        return
                    end
                    local itemMd = item:getModData()
                    itemMd.tcmusic = itemMd.tcmusic or {}
                    if itemMd.tm_headphoneType ~= nil and itemMd.tcmusic.headphoneType == nil then
                        itemMd.tcmusic.headphoneType = itemMd.tm_headphoneType
                    end
                    md.tcmusic = {}
                    for k, v in pairs(itemMd.tcmusic) do
                        md.tcmusic[k] = v
                    end
                    md.tcmusic.deviceType = "IsoObject"
                    md.tcmusic.isWalkman = isWalkman(fullType) and true or false
                    if itemMd.tcmusic.headphoneType == nil then
                        itemMd.tcmusic.headphoneType = -1
                        itemMd.tm_headphoneType = -1
                        md.tcmusic.headphoneType = -1
                    end
                    if itemMd.tcmusic.headphoneType >= 0 and not itemMd.tcmusic.headphoneItemFullType then
                        itemMd.tcmusic.headphoneItemFullType = "Base.Headphones"
                    end
                    itemMd.tm_hasHeadphones = itemMd.tcmusic.headphoneType >= 0
                    if md.tcmusic.headphoneType == nil then
                        md.tcmusic.headphoneType = itemMd.tcmusic.headphoneType
                    end
                    local deviceData = obj:getDeviceData()
                    if deviceData then
                        if md.tcmusic.headphoneType ~= nil and deviceData.setHeadphoneType then
                            deviceData:setHeadphoneType(md.tcmusic.headphoneType)
                        end
                        if md.tcmusic.batteryHas ~= nil and deviceData.setHasBattery then
                            deviceData:setHasBattery(md.tcmusic.batteryHas)
                        end
                        if md.tcmusic.batteryPower ~= nil and deviceData.setPower then
                            deviceData:setPower(md.tcmusic.batteryPower)
                        end
                        if md.tcmusic.turnedOn ~= nil and deviceData.setIsTurnedOn then
                            deviceData:setIsTurnedOn(md.tcmusic.turnedOn == true)
                        end
                        if md.tcmusic.volume ~= nil and deviceData.setDeviceVolume then
                            deviceData:setDeviceVolume(md.tcmusic.volume)
                        end
                    end
                    -- HiFi decks: restore radio decks from the item (chunk
                    -- re-stream rebuild) and vice versa - copyHiFiSlots only
                    -- copies decks WITH content, so both directions are safe.
                    TCMusic.copyHiFiSlots(itemMd, md, true)
                    TCMusic.copyHiFiSlots(md, itemMd, true)
                    -- Deferred: an immediate transmit here races the add-object
                    -- packet and is dropped by the server ("object is null").
                    TCMusic.deferTransmitObjectModData(obj)
                    return
                end
            end
        end
    end
end

Events.OnObjectAdded.Add(syncIsoRadioFromWorldItem)

local function syncInventoryRadioState(container)
    if not container then return end
    local player = getPlayer and getPlayer() or nil
    if not player or container ~= player:getInventory() then return end

    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and instanceof(item, "Radio") then
            local fullType = item.getFullType and item:getFullType() or nil
            if isTrueMusicPortable(fullType) then
                local md = item:getModData()
                md.tcmusic = md.tcmusic or {}
                if not isLocalActivePortable(item) then
                    md.tcmusic.isPlaying = false
                end

                local deviceData = item:getDeviceData()
                if deviceData then
                    if md.tcmusic.headphoneType == nil and deviceData.getHeadphoneType then
                        md.tcmusic.headphoneType = deviceData:getHeadphoneType()
                        if md.tcmusic.headphoneType and md.tcmusic.headphoneType >= 0 and not md.tcmusic.headphoneItemFullType then
                            md.tcmusic.headphoneItemFullType = "Base.Headphones"
                        end
                    end
                    if md.tcmusic.batteryHas == nil and deviceData.getHasBattery then
                        md.tcmusic.batteryHas = deviceData:getHasBattery()
                    end
                    if md.tcmusic.batteryPower == nil and deviceData.getPower then
                        md.tcmusic.batteryPower = deviceData:getPower()
                    end
                end
                applyDeviceStateFromModData(item)
                markPendingInventory(item)
            end
        end
    end
end

if Events and Events.OnContainerUpdate then
    Events.OnContainerUpdate.Add(syncInventoryRadioState)
end

local function processPendingSync()
    for id, entry in pairs(pendingInventorySync) do
        if entry.item then
            local fullType = entry.item.getFullType and entry.item:getFullType() or nil
            if isTrueMusicPortable(fullType) then
                local md = entry.item:getModData()
                md.tcmusic = md.tcmusic or {}
                local deviceData = entry.item:getDeviceData()
                if deviceData then
                    if md.tcmusic.headphoneType == nil and deviceData.getHeadphoneType then
                        md.tcmusic.headphoneType = deviceData:getHeadphoneType()
                        if md.tcmusic.headphoneType and md.tcmusic.headphoneType >= 0 and not md.tcmusic.headphoneItemFullType then
                            md.tcmusic.headphoneItemFullType = "Base.Headphones"
                        end
                    end
                    if md.tcmusic.batteryHas == nil and deviceData.getHasBattery then
                        md.tcmusic.batteryHas = deviceData:getHasBattery()
                    end
                    if md.tcmusic.batteryPower == nil and deviceData.getPower then
                        md.tcmusic.batteryPower = deviceData:getPower()
                    end
                end
                if isWalkman(fullType) and md.tcmusic.headphoneType ~= nil then
                    -- Walkman deviceData is rebuilt later; keep reapplying headphoneType longer
                    if deviceData and deviceData.setHeadphoneType then
                        deviceData:setHeadphoneType(md.tcmusic.headphoneType)
                    end
                end
                applyDeviceStateFromModData(entry.item)
            end
        end
        entry.ticks = entry.ticks - 1
        if entry.ticks <= 0 then
            pendingInventorySync[id] = nil
        end
    end
    for obj, entry in pairs(pendingWorldSync) do
        local item = entry.obj and entry.obj.getItem and entry.obj:getItem() or nil
        if item then
            local fullType = item.getFullType and item:getFullType() or nil
            if isTrueMusicPortable(fullType) then
                local md = item:getModData()
                md.tcmusic = md.tcmusic or {}
                local deviceData = item:getDeviceData()
                if deviceData then
                    if md.tcmusic.headphoneType == nil and deviceData.getHeadphoneType then
                        md.tcmusic.headphoneType = deviceData:getHeadphoneType()
                        if md.tcmusic.headphoneType and md.tcmusic.headphoneType >= 0 and not md.tcmusic.headphoneItemFullType then
                            md.tcmusic.headphoneItemFullType = "Base.Headphones"
                        end
                    end
                    if md.tcmusic.batteryHas == nil and deviceData.getHasBattery then
                        md.tcmusic.batteryHas = deviceData:getHasBattery()
                    end
                    if md.tcmusic.batteryPower == nil and deviceData.getPower then
                        md.tcmusic.batteryPower = deviceData:getPower()
                    end
                end
                applyDeviceStateFromModData(item)
            end
        end
        entry.ticks = entry.ticks - 1
        if entry.ticks <= 0 then
            pendingWorldSync[obj] = nil
        end
    end

end

Events.OnTick.Add(processPendingSync)
