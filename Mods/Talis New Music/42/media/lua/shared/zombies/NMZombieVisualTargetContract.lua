NMZombieVisualTargetContract = NMZombieVisualTargetContract or {}

NMZombieVisualTargetContract.NetCommand = "zombie_visual_targets"
NMZombieVisualTargetContract.ModDataKey = "nmZombieWalkmanProof"
NMZombieVisualTargetContract.SelectionSource = "server_ledger"
NMZombieVisualTargetContract.PublishIntervalTicks = 90
NMZombieVisualTargetContract.RepublishIntervalTicks = 180
NMZombieVisualTargetContract.ClientCacheTtlTicks = 270
NMZombieVisualTargetContract.NearbyRadius = 30
NMZombieVisualTargetContract.MaxTargetsPerPlayer = 96

local function safeNumber(value, fallback)
    local number = tonumber(value)
    if number == nil then
        return tonumber(fallback) or 0
    end
    return number
end

function NMZombieVisualTargetContract.getZombieId(zombie)
    if zombie and zombie.getOnlineID then
        local onlineId = safeNumber(zombie:getOnlineID(), -1)
        if onlineId >= 0 then
            return tostring(math.floor(onlineId))
        end
    end
    if zombie and zombie.getObjectID then
        local objectId = safeNumber(zombie:getObjectID(), -1)
        if objectId >= 0 then
            return tostring(math.floor(objectId))
        end
    end
    return tostring(zombie or "")
end

function NMZombieVisualTargetContract.isTargetZombieId(zombieId)
    local text = tostring(zombieId or "")
    if text == "" then
        return false
    end
    local total = 0
    for i = 1, #text do
        total = (total + string.byte(text, i) * i) % 2147483647
    end
    return (total % 2) == 0
end

function NMZombieVisualTargetContract.shouldTargetZombie(zombie)
    return NMZombieVisualTargetContract.isTargetZombieId(NMZombieVisualTargetContract.getZombieId(zombie))
end

function NMZombieVisualTargetContract.buildLookup(ids)
    local lookup = {}
    if type(ids) ~= "table" then
        return lookup
    end
    for i = 1, #ids do
        local zombieId = tostring(ids[i] or "")
        if zombieId ~= "" then
            lookup[zombieId] = true
        end
    end
    return lookup
end

function NMZombieVisualTargetContract.buildRecordLookup(records)
    local lookup = {}
    if type(records) ~= "table" then
        return lookup
    end
    for i = 1, #records do
        local record = records[i]
        if type(record) == "table" then
            local zombieId = tostring(record.zombieId or "")
            if zombieId ~= "" then
                lookup[zombieId] = {
                    zombieId = zombieId,
                    variantId = tostring(record.variantId or ""),
                    fullType = tostring(record.fullType or ""),
                    attachmentLocation = tostring(record.attachmentLocation or ""),
                    modelAttachmentName = tostring(record.modelAttachmentName or "")
                }
            end
        end
    end
    return lookup
end

function NMZombieVisualTargetContract.getRecordSignature(records)
    if type(records) ~= "table" or #records == 0 then
        return ""
    end
    local parts = {}
    for i = 1, #records do
        local record = records[i]
        if type(record) == "table" then
            parts[#parts + 1] = table.concat({
                tostring(record.zombieId or ""),
                tostring(record.variantId or ""),
                tostring(record.fullType or ""),
                tostring(record.attachmentLocation or ""),
                tostring(record.modelAttachmentName or "")
            }, "|")
        end
    end
    return table.concat(parts, ",")
end

return NMZombieVisualTargetContract
