-- CDCarryingCase_OnCreate.lua
-- Fills the CD Carrying Case with 2-3 random CDs when spawned as loot.
-- Mirrors CassetteCase_OnCreate.lua's deferred-fill flow so it survives
-- the case being created before its container is fully wired.

local DEBUG = false
local function log(msg)
    if DEBUG then
        local side = isServer() and "S" or (isClient() and "C" or "SP")
        print(string.format("[TCCDCase][%s] %s", side, msg))
    end
end

local MIN_CDS = 2
local MAX_CDS = 3

local function pickTargetCount()
    return ZombRand(MIN_CDS, MAX_CDS + 1) -- 2 or 3
end

-- Items we never want to drop into the carrying case even if their
-- name happens to start with "CD_".
local NAME_BLACKLIST = {
    ["CDCarryingCase"] = true,
    ["CDCase"] = true,
}

local function isCDAlbumItem(scriptItem)
    if not scriptItem then return false end
    local name = scriptItem.getName and scriptItem:getName() or nil
    if not name then return false end
    -- All album-pack CD items follow the "CD_<Album>CD" naming convention.
    if not name:find("^CD_") then return false end
    if NAME_BLACKLIST[name] then return false end
    return true
end

local function resolveCaseAndContainer(containerOrItem)
    if not containerOrItem then return nil, nil end

    if containerOrItem.getFullType and containerOrItem.getItemContainer then
        local ft = containerOrItem:getFullType()
        if ft and ft:lower():find("cdcarryingcase", 1, true) then
            return containerOrItem, containerOrItem:getItemContainer()
        end
    end

    if containerOrItem.getContainingItem then
        local maybeItem = containerOrItem:getContainingItem()
        if maybeItem and maybeItem.getFullType and maybeItem.getItemContainer then
            local ft = maybeItem:getFullType()
            if ft and ft:lower():find("cdcarryingcase", 1, true) then
                return maybeItem, maybeItem:getItemContainer()
            end
        end
    end

    return nil, nil
end

local function getCDPool()
    local pool = {}
    local seen = {}

    -- Scan every loaded item script for CD album items (name starts with "CD_").
    -- This works regardless of which CD-pack mods are installed and runs
    -- entirely server-side (SWTCCDAlbums is populated client-side only).
    local allItems = getAllItems and getAllItems() or nil
    if allItems and allItems.size and allItems.get then
        local count = allItems:size()
        for i = 0, count - 1 do
            local sItem = allItems:get(i)
            if isCDAlbumItem(sItem) then
                local ft = sItem.getFullName and sItem:getFullName() or nil
                if ft and not seen[ft] then
                    table.insert(pool, ft)
                    seen[ft] = true
                end
            end
        end
    end

    return pool
end

local function fillCDCase(container, targetCount)
    if not container or not container.AddItem then return false end
    local containingItem = container.getContainingItem and container:getContainingItem() or nil
    if containingItem and containingItem.getModData then
        local md = containingItem:getModData()
        if md.tc_cdcase_filled then
            log("Fill skipped: already filled.")
            return true
        end
    end

    local pool = getCDPool()
    if #pool == 0 then
        log("Fill aborted: empty CD pool.")
        return false
    end

    local count = targetCount or pickTargetCount()

    -- Normalize: clear distribution-injected items so we hit the exact target.
    if container.getItems then
        local items = container:getItems()
        if items then
            for idx = items:size() - 1, 0, -1 do
                local it = items:get(idx)
                if it then container:Remove(it) end
            end
        end
    end

    log(string.format("Filling CD case: target=%d pool=%d", count, #pool))
    local added = 0
    for _ = 1, count do
        local ft = pool[ZombRand(1, #pool + 1)]
        if ft then
            container:AddItem(ft)
            added = added + 1
        end
    end

    if containingItem and containingItem.getModData then
        local md = containingItem:getModData()
        md.tc_cdcase_filled = true
        md.tc_cdcase_pending = nil
    end

    log(string.format("Fill complete. Added=%d", added))

    if containingItem and containingItem.sendModData then
        containingItem:sendModData()
    end
    if container.setDirty then container:setDirty(true) end
    if container.requestSync then container:requestSync() end
    return true
end

TCCDCase_Fill = fillCDCase

local pendingCases = {}

function CDCarryingCase_OnCreate(containerOrItem)
    if not containerOrItem then return end
    -- Run on server / singleplayer only; never on a pure client.
    if isClient() and not isServer() then return end

    log("OnCreate fired.")
    local caseItem, container = resolveCaseAndContainer(containerOrItem)
    if not (caseItem and caseItem.getModData) then
        log("OnCreate: could not resolve case; skipping.")
        return
    end

    local md = caseItem:getModData()
    if md.tc_cdcase_filled then
        log("OnCreate: already filled; skipping.")
        return
    end
    if md.tc_cdcase_pending then
        log("OnCreate: already pending; skipping.")
        return
    end
    if not md.tc_cdcase_target then
        md.tc_cdcase_target = pickTargetCount()
    end
    if md.tc_cdcase_wait == nil then
        md.tc_cdcase_wait = 30
    end

    -- If container already has items (distribution-filled), normalize now.
    if container and container.getItems then
        local items = container:getItems()
        if items and items:size() > 0 then
            log("OnCreate: container already filled; normalizing to target.")
            fillCDCase(container, md.tc_cdcase_target)
            md.tc_cdcase_filled = true
            md.tc_cdcase_pending = nil
            md.tc_cdcase_target = nil
            md.tc_cdcase_wait = nil
            return
        end
    end

    md.tc_cdcase_pending = true
    table.insert(pendingCases, caseItem)
    log("OnCreate: container empty/not-ready, queued pending.")
end

local function onTickCheckPending()
    if #pendingCases == 0 then return end
    for i = #pendingCases, 1, -1 do
        local item = pendingCases[i]
        if not item or (item.getModData and item:getModData().tc_cdcase_filled) then
            table.remove(pendingCases, i)
        else
            local container = item.getItemContainer and item:getItemContainer() or nil
            if container and container.AddItem then
                local md = item.getModData and item:getModData() or nil
                local target = md and md.tc_cdcase_target or nil
                local wait = md and md.tc_cdcase_wait or 0
                local currentCount = 0
                if container.getItems then
                    local items = container:getItems()
                    if items then currentCount = items:size() end
                end

                if currentCount > 0 then
                    log("Pending fill: container already has items; normalizing.")
                    fillCDCase(container, target)
                    if md then
                        md.tc_cdcase_filled = true
                        md.tc_cdcase_target = nil
                        md.tc_cdcase_wait = nil
                    end
                    if container.setDirty then container:setDirty(true) end
                    if container.requestSync then container:requestSync() end
                    if item.sendModData then item:sendModData() end
                    table.remove(pendingCases, i)
                elseif wait > 0 then
                    if md then md.tc_cdcase_wait = wait - 1 end
                else
                    log("Pending fill: container still empty after wait; filling now.")
                    fillCDCase(container, target)
                    if md then
                        md.tc_cdcase_target = nil
                        md.tc_cdcase_wait = nil
                    end
                    table.remove(pendingCases, i)
                end
            end
        end
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(onTickCheckPending)
end
