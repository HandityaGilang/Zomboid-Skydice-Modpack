-- TMSpeakerWire.lua
-- Right-click inventory context menu for merging wire bundles

local WIRE_ITEM_TYPE  = "Tsarcraft.WireBundle"
local WIRE_MAX_FT     = 200

local function getWireRemaining(wireItem)
    if not wireItem then return 0 end
    local md = wireItem:getModData()
    if md.tmWireFt == nil then md.tmWireFt = WIRE_MAX_FT end
    return md.tmWireFt
end

local function nameWireBundle(wireItem, ft)
    if ft <= 0 then
        wireItem:setName((getText("IGUI_TMSpeaker_WireName") or "Speaker Wire Bundle") .. " (" .. (getText("IGUI_TMSpeaker_Empty") or "empty") .. ")")
    else
        wireItem:setName((getText("IGUI_TMSpeaker_WireName") or "Speaker Wire Bundle") .. " (" .. tostring(ft) .. "ft)")
    end
end

-- Merge: pull wire from other bundles into this one (up to 200ft)
local function mergeWire(playerObj, targetItem)
    if not playerObj or not targetItem then return end
    local inv = playerObj:getInventory()
    if not inv then return end

    local targetMd = targetItem:getModData()
    local targetFt = targetMd.tmWireFt or WIRE_MAX_FT
    if targetFt >= WIRE_MAX_FT then
        if playerObj.Say then
            playerObj:Say(getText("IGUI_TMSpeaker_WireFull") or "Wire bundle is already full")
        end
        return
    end

    -- Get all other wire bundles sorted lowest-first
    local allItems = inv:getItemsFromFullType(WIRE_ITEM_TYPE)
    if not allItems or allItems:size() == 0 then return end

    local others = {}
    for i = 0, allItems:size() - 1 do
        local it = allItems:get(i)
        if it ~= targetItem then
            local ft = getWireRemaining(it)
            if ft > 0 then
                table.insert(others, { item = it, ft = ft })
            end
        end
    end
    table.sort(others, function(a, b) return a.ft < b.ft end)

    if #others == 0 then
        if playerObj.Say then
            playerObj:Say(getText("IGUI_TMSpeaker_NoOtherWire") or "No other wire to merge")
        end
        return
    end

    local space = WIRE_MAX_FT - targetFt
    local totalAdded = 0

    for _, entry in ipairs(others) do
        if space <= 0 then break end
        local take = math.min(entry.ft, space)
        local newFt = entry.ft - take
        local wireMd = entry.item:getModData()
        wireMd.tmWireFt = newFt
        totalAdded = totalAdded + take
        space = space - take
        if newFt <= 0 then
            inv:Remove(entry.item)
        else
            nameWireBundle(entry.item, newFt)
        end
    end

    targetMd.tmWireFt = targetFt + totalAdded
    nameWireBundle(targetItem, targetMd.tmWireFt)

    if playerObj.Say then
        local msg = getText("IGUI_TMSpeaker_MergeResult") or "Merged %1ft (%2ft total)"
        msg = msg:gsub("%%1", tostring(totalAdded)):gsub("%%2", tostring(targetMd.tmWireFt))
        playerObj:Say(msg)
    end
end

------------------------------------------------------------------
-- Inventory context menu
------------------------------------------------------------------
local function onFillInventoryMenu(playerNum, context, items)
    if not items then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    -- Find the wire bundle item from the items list
    local wireItem = nil
    for _, v in ipairs(items) do
        local item = v
        if not instanceof(item, "InventoryItem") then
            if type(v) == "table" and v.items then
                for _, sub in ipairs(v.items) do
                    if instanceof(sub, "InventoryItem") and sub:getFullType() == WIRE_ITEM_TYPE then
                        item = sub
                        break
                    end
                end
            end
        end
        if instanceof(item, "InventoryItem") and item:getFullType() == WIRE_ITEM_TYPE then
            wireItem = item
            break
        end
    end

    if not wireItem then return end

    local ft = getWireRemaining(wireItem)

    -- Update name on right-click so it always shows current footage
    nameWireBundle(wireItem, ft)

    -- Merge option: only show if bundle is not full and other bundles exist
    if ft < WIRE_MAX_FT then
        local inv = playerObj:getInventory()
        local allItems = inv:getItemsFromFullType(WIRE_ITEM_TYPE)
        local otherCount = 0
        local otherFt = 0
        if allItems then
            for i = 0, allItems:size() - 1 do
                local it = allItems:get(i)
                if it ~= wireItem then
                    local eFt = getWireRemaining(it)
                    if eFt > 0 then
                        otherCount = otherCount + 1
                        otherFt = otherFt + eFt
                    end
                end
            end
        end
        if otherCount > 0 then
            local canAdd = math.min(otherFt, WIRE_MAX_FT - ft)
            local label = (getText("ContextMenu_MergeWire") or "Merge wire bundles") .. " (+" .. tostring(canAdd) .. "ft)"
            context:addOption(label, playerObj, mergeWire, wireItem)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryMenu)
