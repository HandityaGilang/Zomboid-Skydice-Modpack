-- InvContextCDCase.lua
-- Right-click options for the TM_CDCase:
--   * Right-click the CD case (with a CD inside) → "Take CD out (Album)"
--   * Right-click a CD album (any "CD_*" item) → "Put in CD case" if the
--     player is carrying an empty TM_CDCase.

local CDCASE_FT = "Tsarcraft.TM_CDCase"

local function isCDAlbumFullType(ft)
    if type(ft) ~= "string" or ft == "" then return false end
    local _, name = ft:match("^([^%.]+)%.(.+)$")
    if not name then name = ft end
    return name:find("^CD_") ~= nil and name ~= "CDCase" and name ~= "CDCarryingCase"
end

local function getAlbumDisplayName(albumFt)
    if not albumFt then return nil end
    local sm = getScriptManager and getScriptManager() or nil
    if sm and sm.FindItem then
        local s = sm:FindItem(albumFt)
        if s and s.getDisplayName then
            local dn = s:getDisplayName()
            if dn and dn ~= "" then return dn end
        end
    end
    return albumFt
end

-- Rename the case according to its (client-side) modData. TC_CDCase_UpdateName
-- lives in a server/ file, so it is nil on MP clients — replicate it here.
local function updateCaseNameLocal(caseItem)
    if not caseItem then return end
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
        return
    end
    local md = caseItem.getModData and caseItem:getModData() or nil
    local base = getTextOrNull("IGUI_TM_CDCase_Name") or "CD Case"
    local albumFt = md and md.tc_cdcase_album or nil
    if albumFt and albumFt ~= "" then
        local label = base .. " - " .. tostring(getAlbumDisplayName(albumFt) or albumFt)
        local snap = md.tc_cdcase_scratch
        if snap and snap.tier and snap.tier > 0 and TCMusic and TCMusic.getScratchLabel then
            label = label .. (TCMusic.getScratchLabel(snap.tier) or "")
        end
        caseItem:setName(label)
    else
        caseItem:setName(base .. " - " .. (getTextOrNull("IGUI_TM_CDCase_Empty") or "empty"))
    end
end

-- MP: the taken-out CD is created server-side and broadcast; the arriving
-- client copy can lose the scratch modData/label. Watch for it and re-apply
-- the snapshot we saved locally, then push it back with syncItemFields.
local pendingScratchRestore = {}
local pendingScratchCount = 0

local function processPendingScratchRestore()
    if pendingScratchCount <= 0 then return end
    local plr = getPlayer()
    if not plr then return end
    local inv = plr:getInventory()
    for key, entry in pairs(pendingScratchRestore) do
        entry.ticks = entry.ticks - 1
        local done = entry.ticks <= 0
        if not done and inv then
            local items = inv:getItemsFromFullType(entry.fullType)
            if items then
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    local md = it and it:getModData() or nil
                    if md and not md.TMScratchRolled then
                        if TCMusic and TCMusic.applyScratchSnapshot then
                            TCMusic.applyScratchSnapshot(it, entry.snap)
                        end
                        if TCMusic and TCMusic.safeSyncItem then TCMusic.safeSyncItem(it) elseif isClient() and it.syncItemFields then it:syncItemFields() end
                        done = true
                        break
                    end
                end
            end
        end
        if done then
            pendingScratchRestore[key] = nil
            pendingScratchCount = pendingScratchCount - 1
        end
    end
end

Events.OnTick.Add(processPendingScratchRestore)

local function queueScratchRestore(fullType, snap)
    if not fullType then return end
    local key = fullType .. ":" .. tostring(getTimestampMs())
    pendingScratchRestore[key] = { fullType = fullType, snap = snap, ticks = 600 }
    pendingScratchCount = pendingScratchCount + 1
end

local function findEmptyCDCaseInInventory(plr)
    if not plr then return nil end
    local inv = plr:getInventory()
    if not inv or not inv.getItems then return nil end
    local items = inv:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and it:getFullType() == CDCASE_FT then
            local md = it.getModData and it:getModData() or nil
            local stored = md and md.tc_cdcase_album or nil
            if not stored or stored == "" then
                return it
            end
        end
    end
    return nil
end

local function takeCDOut(player, caseItem)
    if not player or not caseItem then return end
    local id = caseItem.getID and caseItem:getID() or nil
    if not id then return end

    if isClient() then
        sendClientCommand(player, "truemusic", "TakeCDOut", { caseItemId = tostring(id) })
        -- Mirror the server-side change locally: B42 has no server->client
        -- inventory-item modData push, and mismatched item copies break the
        -- case (stale "filled" state blocks putting a new CD in).
        local mdLocal = caseItem:getModData()
        -- Watch for the arriving CD and re-apply its scratch state locally.
        if mdLocal.tc_cdcase_album and mdLocal.tc_cdcase_album ~= "" then
            queueScratchRestore(mdLocal.tc_cdcase_album, mdLocal.tc_cdcase_scratch)
        end
        mdLocal.tc_cdcase_album = nil
        mdLocal.tc_cdcase_scratch = nil
        updateCaseNameLocal(caseItem)
        return
    end

    local md = caseItem:getModData()
    local albumFt = md and md.tc_cdcase_album or nil
    if not albumFt or albumFt == "" then return end
    local sm = getScriptManager()
    if sm and sm.FindItem and not sm:FindItem(albumFt) then return end
    local inv = player:getInventory()
    if inv then
        local added = inv:AddItem(albumFt)
        -- Restore the scratch state (data + name label) captured at put-in.
        if added and TCMusic and TCMusic.applyScratchSnapshot then
            TCMusic.applyScratchSnapshot(added, md.tc_cdcase_scratch)
        end
    end
    md.tc_cdcase_album = nil
    md.tc_cdcase_scratch = nil
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
    elseif caseItem.setName then
        caseItem:setName((getTextOrNull("IGUI_TM_CDCase_Name") or "CD Case") .. " - " .. (getTextOrNull("IGUI_TM_CDCase_Empty") or "empty"))
    end
end

local function putCDInCase(player, albumItem, caseItem)
    if not player or not albumItem or not caseItem then return end
    local albumId = albumItem.getID and albumItem:getID() or nil
    local caseId = caseItem.getID and caseItem:getID() or nil
    if not albumId or not caseId then return end

    if isClient() then
        sendClientCommand(player, "truemusic", "PutCDIn", {
            caseItemId  = tostring(caseId),
            albumItemId = tostring(albumId),
        })
        -- Mirror the server-side change locally (see takeCDOut). The album
        -- item itself is removed by the server broadcast.
        local mdLocal = caseItem:getModData()
        local ftLocal = albumItem.getFullType and albumItem:getFullType() or nil
        if ftLocal and isCDAlbumFullType(ftLocal) then
            mdLocal.tc_cdcase_album = ftLocal
            if TCMusic and TCMusic.captureScratchSnapshot then
                mdLocal.tc_cdcase_scratch = TCMusic.captureScratchSnapshot(albumItem)
            end
            updateCaseNameLocal(caseItem)
        end
        return
    end

    local md = caseItem:getModData()
    if md.tc_cdcase_album and md.tc_cdcase_album ~= "" then return end
    local albumFt = albumItem.getFullType and albumItem:getFullType() or nil
    if not isCDAlbumFullType(albumFt) then return end
    md.tc_cdcase_album = albumFt
    if TCMusic and TCMusic.captureScratchSnapshot then
        md.tc_cdcase_scratch = TCMusic.captureScratchSnapshot(albumItem)
    end
    local inv = player:getInventory()
    if inv and inv.Remove then inv:Remove(albumItem) end
    if TC_CDCase_UpdateName then TC_CDCase_UpdateName(caseItem) end
end

local function onFillContext(player, context, items)
    if not items then return end
    local plr = getSpecificPlayer(player)
    if not plr then return end

    for _, v in ipairs(items) do
        local item = v
        if not instanceof(item, "InventoryItem") and type(v) == "table" and v.items then
            item = v.items[1]
        end
        if item and item.getFullType then
            local ft = item:getFullType()

            if ft == CDCASE_FT then
                local md = item.getModData and item:getModData() or nil
                local albumFt = md and md.tc_cdcase_album or nil
                if albumFt and albumFt ~= "" then
                    local dn = getAlbumDisplayName(albumFt) or albumFt
                    local label = (getTextOrNull("ContextMenu_TM_CDCase_TakeOut") or "Take CD out") .. " (" .. dn .. ")"
                    context:addOption(label, plr, takeCDOut, item)
                end
                return

            elseif isCDAlbumFullType(ft) then
                local emptyCase = findEmptyCDCaseInInventory(plr)
                if emptyCase then
                    local label = getTextOrNull("ContextMenu_TM_CDCase_PutIn") or "Put in CD case"
                    context:addOption(label, plr, putCDInCase, item, emptyCase)
                end
                return
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillContext)
