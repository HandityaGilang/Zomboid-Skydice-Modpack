local env = _G.NMContextMenusEnv
setfenv(1, env)

function computeDistanceSq(player, square)
    if not (player and square and player.getX and player.getY and player.getZ and square.getX and square.getY and square.getZ) then
        return 999999999
    end
    local dx = (tonumber(player:getX()) or 0) - (tonumber(square:getX()) or 0)
    local dy = (tonumber(player:getY()) or 0) - (tonumber(square:getY()) or 0)
    local dz = (tonumber(player:getZ()) or 0) - (tonumber(square:getZ()) or 0)
    return (dx * dx) + (dy * dy) + ((dz * dz) * 4.0)
end

function stableTargetKey(item, fallback)
    local ft = item and item.getFullType and tostring(item:getFullType() or "") or "unknown"
    local id = item and item.getID and tostring(item:getID() or "") or ""
    if id == "" then
        id = tostring(fallback or "")
    end
    return ft .. "|" .. id
end

function sortTargetsStable(left, right)
    local dl = tonumber(left and left.distance) or 999999999
    local dr = tonumber(right and right.distance) or 999999999
    if dl ~= dr then
        return dl < dr
    end
    local nl = tostring(left and left.displayName or "")
    local nr = tostring(right and right.displayName or "")
    if nl ~= nr then
        return nl < nr
    end
    return tostring(left and left.stableKey or "") < tostring(right and right.stableKey or "")
end

function collectLooseMediaInsertTargets(player, mediaItem)
    local fullType = mediaItem and mediaItem.getFullType and tostring(mediaItem:getFullType() or "") or ""
    local carrier = NMMediaContract.resolveMediaCarrier(fullType)
    local canonical = NMMediaContract.resolveMediaCanonical and NMMediaContract.resolveMediaCanonical(fullType) or fullType
    local deviceTargets = {}
    local containerTargets = {}
    local seenDevices = {}
    local seenContainers = {}

    local inv = player and player.getInventory and player:getInventory() or nil
    if inv then
        local all = {}
        NMInventoryHelpers.collectItemsRecursive(inv, all)
        for i = 1, #all do
            local it = all[i]
            local profile = it and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(it) or nil
            if profile and profile.isMediaContainerOnly ~= true and tostring(profile.supportedCarrier or "") == tostring(carrier or "") then
                local key = stableTargetKey(it, "inv")
                if not seenDevices[key] then
                    seenDevices[key] = true
                    deviceTargets[#deviceTargets + 1] = {
                        category = "device",
                        item = it,
                        profile = profile,
                        distance = 0,
                        displayName = tostring(it.getDisplayName and it:getDisplayName() or key),
                        stableKey = key
                    }
                end
            elseif profile and profile.isMediaContainerOnly == true and tostring(profile.supportedCarrier or "") == tostring(carrier or "") then
                local bound = NMMediaContract.resolveContainerMediaBinding and NMMediaContract.resolveContainerMediaBinding(it:getFullType()) or nil
                local accepted = false
                if NMMediaContract and NMMediaContract.areMediaEquivalent then
                    accepted = NMMediaContract.areMediaEquivalent(bound, canonical)
                else
                    accepted = tostring(bound or "") == tostring(canonical or "")
                end
                if accepted then
                    local key = stableTargetKey(it, "inv")
                    if not seenContainers[key] then
                        seenContainers[key] = true
                        containerTargets[#containerTargets + 1] = {
                            category = "container",
                            item = it,
                            profile = profile,
                            distance = 0,
                            displayName = tostring(it.getDisplayName and it:getDisplayName() or key),
                            stableKey = key
                        }
                    end
                end
            end
        end
    end

    local cell = getCell and getCell() or nil
    local square = player and player.getSquare and player:getSquare() or nil
    if cell and square then
        local px, py, pz = square:getX(), square:getY(), square:getZ()
        local radius = 2
        for x = px - radius, px + radius do
            for y = py - radius, py + radius do
                local s = cell:getGridSquare(x, y, pz)
                if s and s.getWorldObjects then
                    local objs = s:getWorldObjects()
                    if objs then
                        for i = 0, objs:size() - 1 do
                            local obj = objs:get(i)
                            local it = obj and obj.getItem and obj:getItem() or nil
                            local profile = it and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(it) or nil
                            if profile and profile.isMediaContainerOnly ~= true and tostring(profile.supportedCarrier or "") == tostring(carrier or "") then
                                local key = stableTargetKey(it, tostring(x) .. ":" .. tostring(y))
                                if not seenDevices[key] then
                                    seenDevices[key] = true
                                    deviceTargets[#deviceTargets + 1] = {
                                        category = "device",
                                        item = it,
                                        profile = profile,
                                        distance = computeDistanceSq(player, s),
                                        displayName = tostring(it.getDisplayName and it:getDisplayName() or key),
                                        stableKey = key
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(deviceTargets, sortTargetsStable)
    table.sort(containerTargets, sortTargetsStable)
    return deviceTargets, containerTargets
end
