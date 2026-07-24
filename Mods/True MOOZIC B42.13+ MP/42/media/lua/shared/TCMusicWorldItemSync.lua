if not TCMusic then TCMusic = {} end

local pendingInventorySync = {}
local pendingWorldSync = {}

local function isTrueMusicPortable(fullType)
    return TCMusic and ((TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]) or (TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]))
end

local function applyDeviceStateFromModData(item)
    if not item then return false end
    local md = item:getModData()
    md.tcmusic = md.tcmusic or {}
    md.tcmusic.isPlaying = false
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

local function syncWorldItemOnAdded(obj)
    if not obj or not instanceof(obj, "IsoWorldInventoryObject") then return end
    local item = obj:getItem()
    if not item or not instanceof(item, "Radio") then return end
    local fullType = item.getFullType and item:getFullType() or nil
    if not isTrueMusicPortable(fullType) then
        return
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
                    end
                    obj:transmitModData()
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
