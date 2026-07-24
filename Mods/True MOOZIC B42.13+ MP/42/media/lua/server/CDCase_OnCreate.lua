-- CDCase_OnCreate.lua
-- Server-side: when a CD Case spawns, fill it with a single random CD album
-- (stored in modData, not as a sub-container) and rename the item to
-- "CD Case - <Album>" or "CD Case - empty".

local DEBUG = false
local function log(msg)
    if DEBUG then
        local side = isServer() and "S" or (isClient() and "C" or "SP")
        print(string.format("[TCCDCase][%s] %s", side, msg))
    end
end

local NAME_BLACKLIST = {
    ["CDCarryingCase"] = true,
    ["CDCase"] = true,
}

local function isCDAlbumScriptItem(scriptItem)
    if not scriptItem then return false end
    local name = scriptItem.getName and scriptItem:getName() or nil
    if not name then return false end
    if not name:find("^CD_") then return false end
    if NAME_BLACKLIST[name] then return false end
    return true
end

local function getCDAlbumPool()
    local pool = {}
    local seen = {}
    local allItems = getAllItems and getAllItems() or nil
    if allItems and allItems.size and allItems.get then
        for i = 0, allItems:size() - 1 do
            local s = allItems:get(i)
            if isCDAlbumScriptItem(s) then
                local ft = s.getFullName and s:getFullName() or nil
                if ft and not seen[ft] then
                    table.insert(pool, ft)
                    seen[ft] = true
                end
            end
        end
    end
    return pool
end

local function getAlbumDisplayName(fullType)
    if not fullType then return nil end
    local sm = getScriptManager()
    if sm and sm.FindItem then
        local s = sm:FindItem(fullType)
        if s and s.getDisplayName then
            local dn = s:getDisplayName()
            if dn and dn ~= "" then return dn end
        end
    end
    return fullType
end

local function baseDisplayName()
    return getTextOrNull("IGUI_TM_CDCase_Name") or "CD Case"
end

local function emptyLabel()
    return baseDisplayName() .. " - " .. (getTextOrNull("IGUI_TM_CDCase_Empty") or "empty")
end

local function albumLabel(albumFullType)
    local dn = getAlbumDisplayName(albumFullType) or "?"
    return baseDisplayName() .. " - " .. tostring(dn)
end

-- Public: rename a CD Case item according to its modData state.
function TC_CDCase_UpdateName(item)
    if not item or not item.setName then return end
    local md = item.getModData and item:getModData() or nil
    if md and md.tc_cdcase_album and md.tc_cdcase_album ~= "" then
        item:setName(albumLabel(md.tc_cdcase_album))
    else
        item:setName(emptyLabel())
    end
    if item.sendModData then item:sendModData() end
end

local pendingCases = {}

local function fillNow(caseItem)
    if not caseItem or not caseItem.getModData then return end
    local md = caseItem:getModData()
    if md.tc_cdcase_filled then return end

    local pool = getCDAlbumPool()
    if #pool == 0 then
        -- No CD-pack mods loaded; mark empty and rename.
        md.tc_cdcase_album = nil
        md.tc_cdcase_filled = true
        md.tc_cdcase_pending = nil
        TC_CDCase_UpdateName(caseItem)
        log("Fill: no CD album pool; marked empty.")
        return
    end

    local pick = pool[ZombRand(1, #pool + 1)]
    md.tc_cdcase_album = pick
    md.tc_cdcase_filled = true
    md.tc_cdcase_pending = nil
    TC_CDCase_UpdateName(caseItem)
    log("Fill: picked album " .. tostring(pick))
end

function CDCase_OnCreate(item)
    if not item then return end
    if isClient() and not isServer() then return end

    -- Resolve the inventory item (PZ may pass either the item or a container).
    local caseItem = item
    if caseItem.getContainingItem and not (caseItem.getFullType and caseItem:getFullType():lower():find("cdcase", 1, true)) then
        local maybe = caseItem:getContainingItem()
        if maybe then caseItem = maybe end
    end
    if not caseItem.getModData or not caseItem.getFullType then return end
    local ft = caseItem:getFullType() or ""
    if not ft:lower():find("cdcase", 1, true) or ft:lower():find("cdcarryingcase", 1, true) then
        return
    end

    local md = caseItem:getModData()
    if md.tc_cdcase_filled then
        TC_CDCase_UpdateName(caseItem)
        return
    end
    if md.tc_cdcase_pending then return end

    -- Try filling immediately. If the item DB isn't ready yet, defer.
    local pool = getCDAlbumPool()
    if #pool > 0 then
        fillNow(caseItem)
    else
        md.tc_cdcase_pending = true
        md.tc_cdcase_wait = 30
        table.insert(pendingCases, caseItem)
        log("OnCreate: pool empty, deferred.")
    end
end

local function onTickCheckPending()
    if #pendingCases == 0 then return end
    for i = #pendingCases, 1, -1 do
        local item = pendingCases[i]
        local md = item and item.getModData and item:getModData() or nil
        if not md or md.tc_cdcase_filled then
            table.remove(pendingCases, i)
        else
            local wait = md.tc_cdcase_wait or 0
            local pool = getCDAlbumPool()
            if #pool > 0 then
                fillNow(item)
                table.remove(pendingCases, i)
            elseif wait > 0 then
                md.tc_cdcase_wait = wait - 1
            else
                -- Give up; mark empty so we don't keep retrying.
                md.tc_cdcase_filled = true
                md.tc_cdcase_pending = nil
                TC_CDCase_UpdateName(item)
                table.remove(pendingCases, i)
            end
        end
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(onTickCheckPending)
end
