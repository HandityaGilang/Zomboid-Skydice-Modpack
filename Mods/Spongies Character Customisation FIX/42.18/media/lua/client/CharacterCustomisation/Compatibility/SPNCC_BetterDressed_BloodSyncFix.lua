-- SPNCC + Better Dressed multiplayer blood/dirt sync compatibility fix
-- Prevents endless Better Dressed update requests caused by SPNCC blood sync refreshes.

local FIX = {}
FIX.installed = false
FIX.lastSignature = {}
FIX.installAttempts = 0

local function _normMod(id)
    return tostring(id or ""):lower():gsub("[_%-%s/\\]", "")
end

local function _isModActive(wantId)
    local mods = getActivatedMods()
    if not mods then return false end

    wantId = _normMod(wantId)

    for i = 0, mods:size() - 1 do
        local raw = tostring(mods:get(i) or "")
        if _normMod(raw) == wantId then
            return true
        end
    end

    return false
end

local function _isBetterDressedActive()
    return _isModActive("EURY_TRANSMOG")
        or _isModActive("BetterDressed")
        or _isModActive("Better Dressed - Transmog")
end

local function _isMultiplayerClient()
    return isClient and isClient()
end

local function _safeNumber(callback)
    local ok, value = pcall(callback)
    if not ok or value == nil then return 0 end

    value = tonumber(value) or 0

    -- Keep the signature stable against tiny float noise.
    return math.floor((value * 100) + 0.5)
end

local function _getItemFullType(item)
    if not item then return "" end

    if item.getFullType then
        local ok, value = pcall(function()
            return item:getFullType()
        end)
        if ok and value then return tostring(value) end
    end

    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    if scriptItem and scriptItem.getFullName then
        local ok, value = pcall(function()
            return scriptItem:getFullName()
        end)
        if ok and value then return tostring(value) end
    end

    return tostring(item)
end

local function _getBodyLocation(item)
    if not item then return "" end

    if item.getBodyLocation then
        local ok, value = pcall(function()
            return item:getBodyLocation()
        end)
        if ok and value then return tostring(value) end
    end

    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    if scriptItem and scriptItem.getBodyLocation then
        local ok, value = pcall(function()
            return scriptItem:getBodyLocation()
        end)
        if ok and value then return tostring(value) end
    end

    return ""
end

local function _appendVisualCondition(parts, item)
    if not item or not item.getVisual then return end

    local visual = item:getVisual()
    if not visual then return end

    if not BloodBodyPartType or not BloodBodyPartType.MAX then return end

    local maxIndex = BloodBodyPartType.MAX:index()
    for idx = 0, maxIndex - 1 do
        local part = BloodBodyPartType.FromIndex(idx)

        local blood = _safeNumber(function()
            return visual:getBlood(part)
        end)

        local dirt = _safeNumber(function()
            return visual:getDirt(part)
        end)

        parts[#parts + 1] = tostring(idx) .. ":" .. tostring(blood) .. ":" .. tostring(dirt)
    end
end

local function _buildBetterDressedRelevantSignature(player)
    if not player or not player.getWornItems then return nil end
    if not TransmogDE or not TransmogDE.isTransmoggable then return nil end

    local wornItems = player:getWornItems()
    if not wornItems then return nil end

    local entries = {}

    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)

        if item
            and TransmogDE.isTransmoggable(item)
            and (not TransmogDE.isTransmogItem or not TransmogDE.isTransmogItem(item)) then

            local parts = {}

            parts[#parts + 1] = "id=" .. tostring(item.getID and item:getID() or "")
            parts[#parts + 1] = "type=" .. _getItemFullType(item)
            parts[#parts + 1] = "loc=" .. _getBodyLocation(item)

            local md = item.getModData and item:getModData() or nil
            local tmog = md and md.Transmog or nil
            if tmog then
                parts[#parts + 1] = "to=" .. tostring(tmog.transmogTo or "")
                parts[#parts + 1] = "child=" .. tostring(tmog.childId or "")
            end

            _appendVisualCondition(parts, item)

            entries[#entries + 1] = table.concat(parts, "|")
        end
    end

    table.sort(entries)
    return table.concat(entries, "||")
end

local function _installBetterDressedPatch()
    if FIX.installed then return true end
    if not _isMultiplayerClient() then return true end
    if not _isBetterDressedActive() then return true end

    if not TransmogNet or not TransmogNet.requestUpdate then return false end
    if not TransmogDE then return false end

    if TransmogNet.__SPNCC_BetterDressed_BloodSyncFix then
        FIX.installed = true
        return true
    end

    FIX.installed = true
    TransmogNet.__SPNCC_BetterDressed_BloodSyncFix = true

    local originalRequestUpdate = TransmogNet.requestUpdate

    TransmogNet.requestUpdate = function(player, ...)
        if not player or not player.getPlayerNum then
            return originalRequestUpdate(player, ...)
        end

        local playerNum = player:getPlayerNum() or 0
        local signature = _buildBetterDressedRelevantSignature(player)

        if signature == nil then
            return originalRequestUpdate(player, ...)
        end

        if FIX.lastSignature[playerNum] == nil then
            FIX.lastSignature[playerNum] = signature
            return originalRequestUpdate(player, ...)
        end

        if FIX.lastSignature[playerNum] == signature then
            return
        end

        FIX.lastSignature[playerNum] = signature
        return originalRequestUpdate(player, ...)
    end

    return true
end

local function _installBetterDressedPatchRetry()
    if _installBetterDressedPatch() then
        Events.OnPlayerUpdate.Remove(_installBetterDressedPatchRetry)
        return
    end

    FIX.installAttempts = FIX.installAttempts + 1
    if FIX.installAttempts > 600 then
        Events.OnPlayerUpdate.Remove(_installBetterDressedPatchRetry)
    end
end

local function _installBetterDressedPatchOnGameStart()
    if not _installBetterDressedPatch() then
        Events.OnPlayerUpdate.Add(_installBetterDressedPatchRetry)
    end
end

Events.OnGameStart.Add(_installBetterDressedPatchOnGameStart)