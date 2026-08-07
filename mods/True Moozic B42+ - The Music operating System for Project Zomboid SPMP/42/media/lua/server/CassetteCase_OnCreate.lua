-- CassetteCase_OnCreate.lua
-- Fills CassetteCase with random cassettes when spawned as loot

if not TCMusicModDetector then
    pcall(function() require "TCMusicModDetector" end)
end

local DEBUG = false
local function log(msg)
    if DEBUG then
        local side = isServer() and "S" or (isClient() and "C" or "SP")
        print(string.format("[TCCassetteCase][%s] %s", side, msg))
    end
end

local function resolveCaseAndContainer(containerOrItem)
    if not containerOrItem then return nil, nil end

    -- If we were handed the item itself.
    if containerOrItem.getFullType and containerOrItem.getItemContainer then
        local ft = containerOrItem:getFullType()
        if ft and ft:lower():find("cassettecase", 1, true) then
            return containerOrItem, containerOrItem:getItemContainer()
        end
    end

    -- If we were handed a container whose containing item is the case.
    if containerOrItem.getContainingItem then
        local maybeItem = containerOrItem:getContainingItem()
        if maybeItem and maybeItem.getFullType and maybeItem.getItemContainer then
            local ft = maybeItem:getFullType()
            if ft and ft:lower():find("cassettecase", 1, true) then
                return maybeItem, maybeItem:getItemContainer()
            end
        end
    end

    return nil, nil
end

local function getCassettePool()
    local pool = {}

    if TCMusicModDetector and TCMusicModDetector.GetAllCassettes then
        local all = TCMusicModDetector.GetAllCassettes()
        if all and #all > 0 then
            for _, entry in ipairs(all) do
                local ft = entry and entry.fullType or nil
                if ft and ft:lower():find("cassette", 1, true) and not ft:lower():find("cassettecase", 1, true) then
                    if getScriptManager():FindItem(ft) then
                        table.insert(pool, ft)
                    end
                end
            end
        end
    end

    if #pool == 0 then
        table.insert(pool, "Tsarcraft.CassetteMainTheme")
    end

    return pool
end

local TARGET_CASE_ITEMS = 15

local function pickTargetCount()
    return TARGET_CASE_ITEMS
end

local function fillCassetteCase(container, targetCount)
    if not container or not container.AddItem then return false end
    local containingItem = container.getContainingItem and container:getContainingItem() or nil
    if containingItem and containingItem.getModData then
        local md = containingItem:getModData()
        if md.tc_cassettecase_filled then
            log("Fill skipped: already filled.")
            return true
        end
    end

    local cassettePool = getCassettePool()
    log("Cassette pool size: " .. tostring(#cassettePool))
    local cassetteCount = targetCount or pickTargetCount()

    -- Always normalize to exact target count.
    if container.getItems then
        local items = container:getItems()
        if items then
            for idx = items:size() - 1, 0, -1 do
                local it = items:get(idx)
                if it then
                    container:Remove(it)
                end
            end
        end
    end

    log(string.format("Filling cassette case: target=%d", cassetteCount))
    local added = 0
    for i = 1, cassetteCount do
        local cassetteType = cassettePool[ZombRand(1, #cassettePool + 1)]
        if cassetteType then
            container:AddItem(cassetteType)
            added = added + 1
        end
    end

    if containingItem and containingItem.getModData then
        local md = containingItem:getModData()
        md.tc_cassettecase_filled = true
        md.tc_cassettecase_pending = nil
    end

    log(string.format("Fill complete. Added=%d", added))

    -- Ensure clients see the filled container in MP
    if containingItem then
        if containingItem.sendModData then
            containingItem:sendModData()
        end
    end
    if container.setDirty then
        container:setDirty(true)
    end
    if container.requestSync then
        container:requestSync()
    end
    return true
end

TCCassetteCase_Fill = fillCassetteCase
local pendingCases = {}

function CassetteCase_OnCreate(containerOrItem)
    if not containerOrItem then return end
    if isClient() and not isServer() then return end
    log("OnCreate fired.")
    local caseItem, container = resolveCaseAndContainer(containerOrItem)
    if caseItem and caseItem.getModData then
        local md = caseItem:getModData()
        if md.tc_cassettecase_filled then
            log("OnCreate: already filled; skipping.")
            return
        end
        if md.tc_cassettecase_pending then
            log("OnCreate: already pending; skipping.")
            return
        end
        if not md.tc_cassettecase_target then
            md.tc_cassettecase_target = pickTargetCount()
        end
        if md.tc_cassettecase_wait == nil then
            md.tc_cassettecase_wait = 30
        end
    end

    if caseItem and caseItem.getModData then
        -- If container already has items (distribution-filled), mark as filled and exit.
        if container and container.getItems then
            local items = container:getItems()
            if items and items:size() > 0 then
                local md = caseItem:getModData()
                md.tc_cassettecase_target = TARGET_CASE_ITEMS
                log("OnCreate: container already filled; normalizing to target.")
                fillCassetteCase(container, md.tc_cassettecase_target)
                md.tc_cassettecase_filled = true
                md.tc_cassettecase_pending = nil
                md.tc_cassettecase_target = nil
                md.tc_cassettecase_wait = nil
                return
            end
        end

        local md = caseItem:getModData()
        md.tc_cassettecase_pending = true
        table.insert(pendingCases, caseItem)
        log("OnCreate: container empty or not ready, queued pending.")
    else
        log("OnCreate: could not resolve case container; skipping.")
    end
end

local function onTickCheckPending()
    if #pendingCases == 0 then return end
    for i = #pendingCases, 1, -1 do
        local item = pendingCases[i]
        if not item or (item.getModData and item:getModData().tc_cassettecase_filled) then
            table.remove(pendingCases, i)
        else
            local container = item.getItemContainer and item:getItemContainer() or nil
            if container and container.AddItem then
                local md = item.getModData and item:getModData() or nil
                local target = md and md.tc_cassettecase_target or nil
                local wait = md and md.tc_cassettecase_wait or 0
                local currentCount = 0
                if container.getItems then
                    local items = container:getItems()
                    if items then
                        currentCount = items:size()
                    end
                end

                if currentCount > 0 then
                    log("Pending fill: container already has items; normalizing to target.")
                    fillCassetteCase(container, target or TARGET_CASE_ITEMS)
                    if md then
                        md.tc_cassettecase_filled = true
                        md.tc_cassettecase_target = nil
                        md.tc_cassettecase_wait = nil
                    end
                    if container.setDirty then
                        container:setDirty(true)
                    end
                    if container.requestSync then
                        container:requestSync()
                    end
                    if item.sendModData then
                        item:sendModData()
                    end
                    table.remove(pendingCases, i)
                elseif wait > 0 then
                    if md then
                        md.tc_cassettecase_wait = wait - 1
                    end
                else
                    log("Pending fill: container empty after wait; filling now.")
                    fillCassetteCase(container, target)
                    if md then
                        md.tc_cassettecase_target = nil
                        md.tc_cassettecase_wait = nil
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

