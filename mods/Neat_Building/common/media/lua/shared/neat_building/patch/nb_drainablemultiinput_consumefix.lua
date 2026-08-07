-- NB_DrainableMultiInput_ConsumeFix.lua
-- Build 42.13.x workaround + MP selection helper (server-authoritative inventory).
--
-- 1) UsesPartial (drainable) bug workaround:
--    When an InputScript is normalized to amount 1 but has per-item scaling (getIntAmount(fullType) > getIntAmount()),
--    vanilla may consume too few "uses" on drainables (e.g., Twine consuming 1 use instead of 2).
--    This patch runs on SP + MP server (never on MP clients) and applies an extra ItemUser.UseItem() pass
--    right after the build recipe has consumed inputs.
--
-- 2) MP selection enforcement:
--    Client UI can select alternative items (e.g., Rag Dirty vs Rag, Twine, etc.). In MP, the server may otherwise
--    auto-pick the first viable alternative. We store the client's selection and, on server, attempt to apply it
--    to BuildLogic before the build craft action starts.

if isClient() and (not isServer()) then
    -- Inventory is authoritative on SP/server; never modify items on MP clients.
    return
end

local function _safeCall(fn, ...)
    -- Call a function safely; return nil on error.
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local NB_DEBUG = false

local function dprint(...)
    -- Debug print (avoid ':' in text because print() may truncate messages containing ':').
    if NB_DEBUG then
        print(...)
    end
end


local function _toJavaArrayList(listObj)
    -- Convert a Lua table/KahluaTableImpl (or a Java List) into a java.util.ArrayList.
    -- BuildLogic:setContainers() expects an ArrayList on B42.13+.
    if not listObj then return nil end

    -- If it already looks like a Java List/ArrayList, keep it.
    local hasSize = _safeCall(function() return listObj.size and listObj:size() end)
    if hasSize ~= nil then
        return listObj
    end

    -- Try to build a java.util.ArrayList from a Lua table.
    if type(listObj) == "table" then
            if (not ArrayList) or (not ArrayList.new) then return nil end
        local al = ArrayList.new()
        -- Prefer array part (ipairs) first.
        for _, v in ipairs(listObj) do
            if v ~= nil then
                al:add(v)
            end
        end
        -- If ipairs found nothing, fall back to pairs.
        if _safeCall(function() return al:size() end) == 0 then
            for _, v in pairs(listObj) do
                if v ~= nil then
                    al:add(v)
                end
            end
        end
        return al
    end

    -- Unknown type; give up.
    return nil
end

local function _countList(listObj)
    -- Count elements in a Java ArrayList or a Lua table.
    if not listObj then return 0 end

    local n = _safeCall(function()
        return (listObj.size and listObj:size()) or nil
    end)
    if n ~= nil then return n end

    if type(listObj) == "table" then
        -- Try the array-part length first.
        local ok, len = pcall(function() return #listObj end)
        if ok and len and len > 0 then return len end
        -- Fallback: count pairs
        local c = 0
        for _ in pairs(listObj) do c = c + 1 end
        return c
    end

    return 0
end

local function _getScriptFullName(scriptItem, invItem)
    -- Prefer script full name (e.g., "Base.Twine"); fall back to inventory full type.
    local ft = scriptItem and _safeCall(function() return scriptItem:getFullName() end) or nil
    if (not ft) or ft == "" then
        ft = invItem and _safeCall(function() return invItem:getFullType() end) or nil
    end
    return ft
end

-- -------------------------------------------------------------------------------------------------
-- MP sync (client -> server): store chosen alternative items so the server consumes the same ones.
-- -------------------------------------------------------------------------------------------------

-- Per-player selection cache:
-- NB_MP_SELECTION[onlineID][recipeKey][inputIndex] = { fullType = "Base.Twine", itemIDs = {123,456}, t = timestamp }
NB_MP_SELECTION = NB_MP_SELECTION or {}

local function _makeRecipeKeyFromRecipe(recipe)
    -- Prefer modID when available because modName can differ between client/server or be localized.
    local name = _safeCall(function() return recipe and recipe.getName and recipe:getName() end) or ""
    local modID = _safeCall(function() return recipe and recipe.getModID and recipe:getModID() end) or ""
    local modName = _safeCall(function() return recipe and recipe.getModName and recipe:getModName() end) or ""
    local modPart = (modID ~= "" and modID) or modName
    return tostring(name) .. "|" .. tostring(modPart)
end


local function _hasSelectionFor(player, craftRecipe)
    -- Returns true if we have a stored selection for this player+recipe on the server.
    if not isServer() then return false end
    if (not player) or (not craftRecipe) then return false end
    local onlineID = (player.getOnlineID and player:getOnlineID()) or 0
    local recipeKey = _makeRecipeKeyFromRecipe(craftRecipe)
    return NB_MP_SELECTION[onlineID] ~= nil and NB_MP_SELECTION[onlineID][recipeKey] ~= nil
end

local function _storeSelectionFromClient(player, args)
    -- Store selection received from the client so the server can enforce it.
    if (not player) or (not args) then return end

    -- Normalize types because MP command args can arrive as strings or floats.
    local recipeKey = tostring(args.recipeKey or "")
    local inputIndex = tonumber(args.inputIndex)
    if recipeKey == "" or inputIndex == nil then return end

    local normIDs = {}
    if args.itemIDs and type(args.itemIDs) == "table" then
        for _, v in ipairs(args.itemIDs) do
            local n = tonumber(v)
            if n ~= nil then table.insert(normIDs, n) end
        end
    end

    local onlineID = (player.getOnlineID and player:getOnlineID()) or 0
    NB_MP_SELECTION[onlineID] = NB_MP_SELECTION[onlineID] or {}
    NB_MP_SELECTION[onlineID][recipeKey] = NB_MP_SELECTION[onlineID][recipeKey] or {}
    NB_MP_SELECTION[onlineID][recipeKey][inputIndex] = {
        fullType = tostring(args.fullType or ""),
        itemIDs = normIDs,
        t = (getTimestamp and getTimestamp()) or 0,
    }

    dprint("[XP_NB] MP Sync stored selection")
end

local function _onClientCommand(module, command, player, args)
    if module ~= "XP_NB" and module ~= "NB" then return end
    if command ~= "SetBuildInputSelection" then return end
    _storeSelectionFromClient(player, args)
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(_onClientCommand)
end

local function _findViableItemByID(viableList, targetID)
    -- viableList is ArrayList<InventoryItem>
    if not viableList or targetID == nil then return nil end
    local size = _safeCall(function() return viableList:size() end) or 0
    for i = 0, size - 1 do
        local it = viableList:get(i)
        local id = it and _safeCall(function() return it:getID() end) or nil
        if id ~= nil and tonumber(id) == tonumber(targetID) then
            return it
        end
    end
    return nil
end


local function _forEachItemInContainers(containers, fn)
    -- Iterate over InventoryItems in each ItemContainer (Java List/ArrayList or Lua table of containers).
    if (not containers) or (not fn) then return end

    local n = _safeCall(function() return containers.size and containers:size() end)
    if n ~= nil then
        for i = 0, n - 1 do
            local c = containers:get(i)
            local items = c and _safeCall(function() return c:getItems() end) or nil
            if items then
                local sz = _safeCall(function() return items:size() end) or 0
                for j = 0, sz - 1 do
                    local it = items:get(j)
                    if it then fn(it) end
                end
            end
        end
        return
    end

    if type(containers) == "table" then
        for _, c in ipairs(containers) do
            local items = c and _safeCall(function() return c:getItems() end) or nil
            if items then
                local sz = _safeCall(function() return items:size() end) or 0
                for j = 0, sz - 1 do
                    local it = items:get(j)
                    if it then fn(it) end
                end
            end
        end
    end
end

local function _findItemInContainersByID(containers, targetID)
    -- Find an InventoryItem by its getID() by scanning all containers.
    if (not containers) or targetID == nil then return nil end
    local found = nil
    _forEachItemInContainers(containers, function(it)
        if found then return end
        local id = it and _safeCall(function() return it:getID() end) or nil
        if id ~= nil and tonumber(id) == tonumber(targetID) then
            found = it
        end
    end)
    return found
end


local function _applyServerManualSelection(player, logic, craftRecipe)
    -- Server-only: enforce the manual selection for a build action so consumption matches the client choice.
    if not isServer() then return end
    if (not player) or (not logic) or (not craftRecipe) then return end

    local onlineID = (player.getOnlineID and player:getOnlineID()) or 0
    local recipeKey = _makeRecipeKeyFromRecipe(craftRecipe)
    local selByRecipe = NB_MP_SELECTION[onlineID] and NB_MP_SELECTION[onlineID][recipeKey] or nil
    if not selByRecipe then
        dprint("[XP_NB] MP Apply no selection for recipeKey " .. tostring(recipeKey))
        return
    end

    local inputs = _safeCall(function() return craftRecipe:getInputs() end)
    if not inputs then return end

    -- Enable manual selection mode on the server logic.
    _safeCall(function() logic:setManualSelectInputs(true) end)
    _safeCall(function() logic:setShowManualSelectInputs(true) end)

    local viable = _safeCall(function() return logic:getAllViableInputInventoryItems() end)

    for inputIndex, payload in pairs(selByRecipe) do
        local idx = tonumber(inputIndex)
        if idx ~= nil then
            local inputScript = _safeCall(function() return inputs:get(idx) end)

            -- Heuristic: handle 1-based indexes from Lua UIs vs 0-based Java lists.
            if (not inputScript) and idx and idx > 0 then
                inputScript = _safeCall(function() return inputs:get(idx - 1) end)
                if inputScript then
                    idx = idx - 1
                end
            end
            if inputScript then
                _safeCall(function() logic:setManualSelectInputScriptFilter(inputScript) end)

                -- Offer the client-selected alternative inputs (MP server).
                local containers = _safeCall(function() return logic.getContainers and logic:getContainers() end)
                if (not containers) and player and player.getInventory then
                    containers = { player:getInventory() }
                end

                local cur = _safeCall(function() return logic:getSatisfiedInputInventoryItems(inputScript) end)

                local offered = {}
                local function _isOffered(it)
                    for _, o in ipairs(offered) do
                        if o == it then return true end
                    end
                    return false
                end

                local function _offer(it)
                    -- Offer a specific InventoryItem as a manual input for this script filter.
                    if not it then return false end
                    local ok = _safeCall(function() return logic:offerInputItem(it) end)
                    if ok then
                        table.insert(offered, it)
                        return true
                    end
                    return false
                end

                -- First try the exact items selected on the client (by item ID).
                local ids = payload and payload.itemIDs or nil
                if ids and type(ids) == "table" and #ids > 0 then

                    -- For drainables (uses-based), BuildLogic often expects ONE entry per required use.
                    -- If the client only sent one ID but the input needs multiple uses, duplicate the ID up to available uses.
                    local want = tonumber(payload and payload.need) or nil
                    if not want then
                        want = _safeCall(function() return inputScript:getIntAmount(payload.fullType) end)
                            or _safeCall(function() return inputScript:getIntAmount() end)
                            or 1
                    end
                    want = math.ceil(tonumber(want) or 1)

                    local isItemCount2 = true
                    local ic2 = _safeCall(function() return inputScript:isItemCount() end)
                    if ic2 ~= nil then isItemCount2 = ic2 end

                    if (not isItemCount2) and want > #ids and #ids > 0 then
                        local firstIt = (viable and _findViableItemByID(viable, ids[1])) or _findItemInContainersByID(containers, ids[1])
                        local avail = (firstIt and firstIt.getCurrentUses and firstIt:getCurrentUses()) or 0
                        avail = math.floor(tonumber(avail) or 0)
                        local maxCopies = math.min(want, math.max(1, avail))
                        while #ids < maxCopies do
                            table.insert(ids, ids[1])
                        end
                    end

                    for _, id in ipairs(ids) do
                        local invIt = (viable and _findViableItemByID(viable, id)) or _findItemInContainersByID(containers, id)
                        _offer(invIt)
                    end
                end

                -- Fallback: enforce by fullType when item IDs can't be matched (or aren't present).
                if (#offered == 0) and payload and payload.fullType and payload.fullType ~= "" then
                    local ft = payload.fullType
                    local need = _safeCall(function() return inputScript:getIntAmount(ft) end)
                        or _safeCall(function() return inputScript:getIntAmount() end)
                        or 1
                    need = math.ceil(need)

                    local isItemCount = (_safeCall(function() return inputScript:isItemCount() end) ~= false)
                    local offeredItems = 0
                    local offeredUses = 0

                    local function _tryOfferFrom(invIt)
                        if invIt and invIt.getFullType and invIt:getFullType() == ft then
                            if isItemCount then
                                -- Item-count input: each offered item satisfies 1 required unit.
                                local ok = _offer(invIt)
                                if ok then
                                    offeredItems = offeredItems + 1
                                    return offeredItems >= need
                                end
                            else
                                -- Drainable input: offer the SAME item multiple times to represent multiple required uses.
                                local u = (invIt.getCurrentUses and invIt:getCurrentUses()) or 0
                                u = math.floor(tonumber(u) or 0)
                                local remaining = need - offeredUses
                                local times = math.min(u, remaining)
                                for _ = 1, times do
                                    local ok = _offer(invIt)
                                    if ok then
                                        offeredUses = offeredUses + 1
                                    end
                                end
                                return offeredUses >= need
                            end
                        end
                        return false
                    end

                    -- Try whatever BuildLogic currently considers viable first.
                    if viable then
                        for i2 = 0, viable:size() - 1 do
                            if _tryOfferFrom(viable:get(i2)) then break end
                        end
                    end

                    -- If the chosen alternative isn't in the viable list (common when the default alternative is already satisfied),
                    -- scan the synced containers and offer matching items directly.
                    if (isItemCount and offeredItems < need) or ((not isItemCount) and offeredUses < need) then
                        _forEachItemInContainers(containers, function(it)
                            if (isItemCount and offeredItems >= need) or ((not isItemCount) and offeredUses >= need) then return end
                            _tryOfferFrom(it)
                        end)
                    end
                end

                dprint("[XP_NB] apply idx " .. tostring(idx)
                    .. " ft " .. tostring(payload and payload.fullType)
                    .. " ids " .. tostring(payload and payload.itemIDs and #payload.itemIDs or 0)
                    .. " offered " .. tostring(#offered))

                -- Remove previously satisfied items (e.g., default alternative) only after we successfully offered something.
                if #offered > 0 and cur then
                    for j = 0, cur:size() - 1 do
                        local invIt = cur:get(j)
                        if invIt and (not _isOffered(invIt)) then
                            _safeCall(function() logic:removeInputItem(invIt) end)
                        end
                    end
                end
            end
        end
    end
    -- Clean up server-side manual selection flags to avoid leaking state into later recipes.
    if logic then
        _safeCall(function() if logic.setManualSelectInputScriptFilter then logic:setManualSelectInputScriptFilter(nil) end end)
        _safeCall(function() if logic.setShowManualSelectInputs then logic:setShowManualSelectInputs(false) end end)
        _safeCall(function() if logic.setManualSelectInputs then logic:setManualSelectInputs(false) end end)
    end

end



-- -------------------------------------------------------------------------------------------------
-- Drainable extra-use workaround (SP + MP server)
-- -------------------------------------------------------------------------------------------------


-- -------------------------------------------------------------------------------------------------
-- Drainable extra-use workaround (SP + MP server/host)
-- -------------------------------------------------------------------------------------------------

local function _isDrainableInvItem(invItem)
    -- Return true when the InventoryItem behaves like a drainable (has uses).
    -- Using instanceof() is the most reliable in PZ; fall back to method existence checks.
    if not invItem then return false end
    if _safeCall(function() return instanceof(invItem, "DrainableComboItem") end) then
        local u = _safeCall(function() return invItem:getCurrentUses() end) or 0
        return u > 0
    end
    local hasUses = (invItem.getCurrentUses ~= nil) and (_safeCall(function() return invItem:getCurrentUses() end) ~= nil)
    return hasUses
end

local function _snapshotDrainablePreUses(cursor, recipeData)
    -- Capture the "uses" count of any drainable items BEFORE vanilla consumes them.
    -- Recommended insertion point: ISBuildIsoEntity.getSprite() hook, after startCraftAction() created recipeDataInProgress.
    if (not cursor) or (not recipeData) or (not recipeData.inputs) then return end

    cursor._XP_NB_PreDrainable = cursor._XP_NB_PreDrainable or {}

    local inputs = recipeData.inputs
    local sz = _safeCall(function() return inputs:size() end) or 0
    for i = 0, sz - 1 do
        local inputData = inputs:get(i)
        local inputScript = inputData and _safeCall(function() return inputData:getInputScript() end) or nil
        if inputScript and (not _safeCall(function() return inputScript:isKeep() end)) then
            -- Collect items currently selected/satisfied for this input.
            local list = {}
            local dedicatedServer = isServer() and (not isClient())

            -- Try to collect all satisfied items for this input when the API is available.
            -- On some MP server flows getInputItems() may not exist or may throw; avoid calling it in those cases.
            if (not dedicatedServer) and inputData and inputData.getInputItems then
                local items = _safeCall(function() return inputData:getInputItems() end)
                local n = items and (_safeCall(function() return items:size() end) or 0) or 0
                if n > 0 then
                    for j = 0, n - 1 do
                        table.insert(list, items:get(j))
                    end
                end
            end

            -- Fallback (or dedicated): single-item accessors.
            if #list == 0 then
                local one = (inputData and inputData.getFirstInputItem) and _safeCall(function() return inputData:getFirstInputItem() end) or nil
                if (not one) and inputData and inputData.getLastInputItem then
                    one = _safeCall(function() return inputData:getLastInputItem() end)
                end
                if one then table.insert(list, one) end
            end

            -- Store only drainables.
            local pre = { fullType = nil, need = 0, items = {} } -- items: { {id=..., uses=...}, ... }
            for _, invIt in ipairs(list) do
                if _isDrainableInvItem(invIt) then
                    local id = _safeCall(function() return invIt:getID() end)
                    local uses = _safeCall(function() return invIt:getCurrentUses() end) or 0
                    if id ~= nil then
                        table.insert(pre.items, { id = tonumber(id), uses = tonumber(uses) })
                        if not pre.fullType then
                            pre.fullType = _safeCall(function() return invIt:getFullType() end) or nil
                        end
                    end
                end
            end

            if #pre.items > 0 then
                -- Compute the required "units" for this drainable based on the input script and chosen fullType.
                -- Even when the recipe line is 'item 2 [...Twine...]', a drainable should consume 2 uses, not 2 items.
                local ft = pre.fullType or ""
                local need = _safeCall(function() return inputScript:getIntAmount(ft) end)
                    or _safeCall(function() return inputScript:getIntAmount() end)
                    or 0
                pre.need = math.ceil(tonumber(need) or 0)

                cursor._XP_NB_PreDrainable[i] = pre

                if NB_DEBUG then
                    dprint("[XP_NB] preUses idx " .. tostring(i)
                        .. " ft " .. tostring(pre.fullType)
                        .. " need " .. tostring(pre.need)
                        .. " n " .. tostring(#pre.items))
                end
            end
        end
    end
end

local function _fixRecipeDrainables(character, recipeData, cursor)
    -- If we captured pre-uses, compare expected vs (pre - post) and consume missing uses.
    -- This fixes recipes that require e.g. 2 Twine but vanilla consumes only 1 use.
    if (not recipeData) or (not recipeData.inputs) then return end
    if (not ItemUser) or (not ItemUser.UseItem) then return end

    local preByIdx = cursor and cursor._XP_NB_PreDrainable or nil

    local inputs = recipeData.inputs
    local size = _safeCall(function() return inputs:size() end) or 0
    if size <= 0 then return end

    for i = 0, size - 1 do
        local inputData = inputs:get(i)
        local inputScript = inputData and _safeCall(function() return inputData:getInputScript() end) or nil
        if inputScript and (not _safeCall(function() return inputScript:isKeep() end)) then
            local pre = preByIdx and preByIdx[i] or nil

            -- Only attempt the robust fix when we actually captured drainable pre-uses for this input.
            if pre and pre.items and #pre.items > 0 and (pre.need or 0) > 0 then
                -- Build a map of current uses after vanilla consumption.
                local postMap = {}
                local list = {}
                local dedicatedServer = isServer() and (not isClient())

                if (not dedicatedServer) and inputData and inputData.getInputItems then
                    local items = _safeCall(function() return inputData:getInputItems() end)
                    local n = items and (_safeCall(function() return items:size() end) or 0) or 0
                    if n > 0 then
                        for j = 0, n - 1 do
                            table.insert(list, items:get(j))
                        end
                    end
                end

                if #list == 0 then
                    local one = (inputData and inputData.getFirstInputItem) and _safeCall(function() return inputData:getFirstInputItem() end) or nil
                    if (not one) and inputData and inputData.getLastInputItem then
                        one = _safeCall(function() return inputData:getLastInputItem() end)
                    end
                    if one then table.insert(list, one) end
                end

                for _, it in ipairs(list) do
                    if _isDrainableInvItem(it) then
                        local id = _safeCall(function() return it:getID() end)
                        if id ~= nil then
                            postMap[tonumber(id)] = _safeCall(function() return it:getCurrentUses() end) or 0
                        end
                    end
                end

                local totalPre = 0
                local totalPost = 0
                for _, p in ipairs(pre.items) do
                    totalPre = totalPre + (tonumber(p.uses) or 0)
                    totalPost = totalPost + (tonumber(postMap[p.id]) or 0) -- missing = destroyed/removed => 0
                end

                local consumed = totalPre - totalPost
                local extra = (pre.need or 0) - consumed

                if NB_DEBUG then
                    dprint("[XP_NB] drainable check idx " .. tostring(i)
                        .. " ft " .. tostring(pre.fullType)
                        .. " need " .. tostring(pre.need)
                        .. " consumed " .. tostring(consumed)
                        .. " extra " .. tostring(extra))
                end

                if extra > 0 then
                    local keep = (_safeCall(function() return inputScript:isKeep() end) and true or false)
                    local destroy = (_safeCall(function() return inputScript:isDestroy() end) and true or false)

                    -- Consume missing uses, preferring currently-referenced items (postMap keys).
                    local remaining = extra

                    -- Rebuild a concrete list of InventoryItems we can call UseItem() on.
                    local toUse = {}
                    if items and (_safeCall(function() return items:size() end) or 0) > 0 then
                        for j = 0, items:size() - 1 do
                            local it = items:get(j)
                            if _isDrainableInvItem(it) then
                                table.insert(toUse, it)
                            end
                        end
                    end

                    for _, it in ipairs(toUse) do
                        if remaining <= 0 then break end
                        local got = _safeCall(function()
                            return ItemUser.UseItem(it, true, false, remaining, keep, destroy)
                        end) or 0
                        remaining = remaining - got

                        if got > 0 and isServer() and GameServer and GameServer.sendItemStats then
                            _safeCall(function() GameServer.sendItemStats(it) end)
                        end
                    end

                    if NB_DEBUG then
                        dprint("[XP_NB] drainable applied extra " .. tostring(extra - remaining)
                            .. " left " .. tostring(remaining)
                            .. " ft " .. tostring(pre.fullType))
                    end
                end
            else
                -- Fallback (older heuristic): only works when per-type scaling exists (desired > baseReq).
                local invItem = _safeCall(function() return inputData:getFirstInputItem() end)
                if invItem and _isDrainableInvItem(invItem) then
                    local scriptItem = _safeCall(function() return invItem:getScriptItem() end)
                    local fullType = _getScriptFullName(scriptItem, invItem)
                    local baseReq = _safeCall(function() return inputScript:getIntAmount() end) or 0
                    baseReq = math.ceil(baseReq)
                    local desired = fullType and (_safeCall(function() return inputScript:getIntAmount(fullType) end) or baseReq) or baseReq
                    desired = math.ceil(desired)
                    local extra = desired - baseReq
                    if extra > 0 then
                        local keep = (_safeCall(function() return inputScript:isKeep() end) and true or false)
                        local destroy = (_safeCall(function() return inputScript:isDestroy() end) and true or false)
                        local got = _safeCall(function()
                            return ItemUser.UseItem(invItem, true, false, extra, keep, destroy)
                        end) or 0
                        if got > 0 and isServer() and GameServer and GameServer.sendItemStats then
                            _safeCall(function() GameServer.sendItemStats(invItem) end)
                        end
                    end
                end
            end
        end
    end

    -- Clear captured snapshot to avoid leaking state if this cursor object is reused.
    if cursor then
        cursor._XP_NB_PreDrainable = nil
        cursor._XP_NB_PreUsesCaptured = nil
    end
end

local function _patch_ISBuildIsoEntity
()
    -- Patch the server-side build executor so the workaround applies to both SP and MP.
    if not ISBuildIsoEntity or not ISBuildIsoEntity.create then return end
    if ISBuildIsoEntity._XP_NB_DrainableConsumeFixPatched then return end
    ISBuildIsoEntity._XP_NB_DrainableConsumeFixPatched = true

    local _oldCreate = ISBuildIsoEntity.create

	-- Patch getSprite so we can inject selection AFTER startCraftAction() but BEFORE performCurrentRecipe().
	-- Vanilla server flow in ISBuildIsoEntity:create() is: startCraftAction(nil) -> getSprite() -> performCurrentRecipe()
	-- We hook getSprite() because it runs at the perfect time and avoids copying the entire vanilla create() function.
	if not ISBuildIsoEntity._XP_NB_GetSpriteSelectionPatched then
		ISBuildIsoEntity._XP_NB_GetSpriteSelectionPatched = true

		-- Keep current getSprite if another mod already patched it; otherwise fall back to ISBuildingObject.getSprite.
		local _oldGetSprite = ISBuildIsoEntity.getSprite

		ISBuildIsoEntity.getSprite = function(self, ...)
			-- Call original behavior first (sets heading flags, etc.).
			local res
			if _oldGetSprite then
				res = _oldGetSprite(self, ...)
			elseif ISBuildingObject and ISBuildingObject.getSprite then
				res = ISBuildingObject.getSprite(self, ...)
			end

			-- Authority = SP OR MP server/host. Never run inventory logic on pure MP clients.
			local authority = isServer() or (not isClient())
			if authority
				and self
				and self.character
				and self.buildPanelLogic
				and self.craftRecipe
			then
				-- Ensure startCraftAction() already created the in-progress recipe data.
				local inProgress = _safeCall(function()
					return self.buildPanelLogic.getRecipeDataInProgress and self.buildPanelLogic:getRecipeDataInProgress()
				end)

				if inProgress then
					-- MP server: enforce the client-selected alternative inputs once.
					if isServer() and self._XP_NB_PendingApplySelection then
						self._XP_NB_PendingApplySelection = false
						_applyServerManualSelection(self.character, self.buildPanelLogic, self.craftRecipe)
					end

					-- SP + server/host: snapshot drainable uses BEFORE vanilla consumes them.
					if not self._XP_NB_PreUsesCaptured then
						self._XP_NB_PreUsesCaptured = true
						_snapshotDrainablePreUses(self, inProgress)
					end
				end
			end

			return res
		end
	end

    function ISBuildIsoEntity:create(x, y, z, north, sprite)
        -- Ceilings B42 compatibility: if the build cursor was flagged by Neat Building,
        -- create the object on the ceiling level instead of the player's floor level.
        if self and (self.isCeilingBuild or self.ceilingZ) then
            z = self.ceilingZ or ((z or 0) + 1)
        end

        -- MP server: enforce the client-selected alternative inputs before starting the craft action.
        if self and self.character and self.buildPanelLogic and self.craftRecipe then
			-- Ensure BuildLogic has containers + recipe on the server (fixes "consume failed" in MP/coop).
			-- Recommended insertion: inside ISBuildIsoEntity:create wrapper, before _applyServerManualSelection().
			local logic = self.buildPanelLogic

            
			-- Sync accessible containers so the server can actually find materials.
			-- IMPORTANT: BuildLogic:setContainers() expects a Java ArrayList on B42.13+.
			if isServer() and logic and logic.setContainers then
				local containers = nil

				-- Prefer containers captured on the build cursor (Neat Building may supply these).
				if self.containers then
					containers = self.containers
				end

				-- If we don't have any, try the UI helper (works on host/co-op; not present on dedicated server).
				if (not containers) and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getContainers then
					containers = _safeCall(function()
						return ISInventoryPaneContextMenu.getContainers(self.character)
					end)
				end

				-- Fallback: at least the player's main inventory container.
				if (not containers) and self.character and self.character.getInventory then
					containers = { self.character:getInventory() }
				end

				-- Convert to Java ArrayList if needed.
				local javaContainers = _toJavaArrayList(containers)

				if javaContainers then
					_safeCall(function() logic:setContainers(javaContainers) end)
					_safeCall(function() if logic.autoPopulateInputs then logic:autoPopulateInputs() end end)
				else
					dprint("[XP_NB] WARNING: could not convert containers to ArrayList; skipping setContainers()")
				end

				-- Debug: log container/viable counts on server to diagnose "consume failed".
				if NB_DEBUG then
					dprint("[XP_NB] create containers " .. tostring(_countList(javaContainers or containers)))
					local v = _safeCall(function()
						return logic.getAllViableInputInventoryItems and logic:getAllViableInputInventoryItems()
					end)
					dprint("[XP_NB] create viable " .. tostring(_countList(v)))
				end
			end

            -- Sync the selected recipe so performCurrentRecipe() has a recipeDataInProgress to run.
            if isServer() and logic and logic.setRecipe and self.craftRecipe then
                local curRecipe = _safeCall(function() return logic.getRecipe and logic:getRecipe() end)
                if curRecipe ~= self.craftRecipe then
                    _safeCall(function() logic:setRecipe(self.craftRecipe) end)
                    _safeCall(function() logic:autoPopulateInputs() end)
                end
            end

            -- Mark this cursor instance so getSprite() can apply selection after startCraftAction() (server-side),
            -- but only if we actually have a stored selection.
            if isServer() and _hasSelectionFor(self.character, self.craftRecipe) then
                self._XP_NB_PendingApplySelection = true
            end
        end

        -- Run vanilla first (it consumes inputs and creates the entity).
        _oldCreate(self, x, y, z, north, sprite)

        -- Avoid messing with BuildCheat mode (vanilla doesn't consume at all).
        if self and self.character and _safeCall(function() return self.character:isBuildCheat() end) then
            return
        end

        -- Try to access the most useful recipe data handle.
        local logic = self and self.buildPanelLogic or nil
        local recipeData =
            (logic and _safeCall(function() return logic:getRecipeDataInProgress() end))
            or (logic and _safeCall(function() return logic:getRecipeData() end))
            or nil

        if recipeData then
            _fixRecipeDrainables(self.character, recipeData, self)
        end
    end
end

-- Patch as soon as scripts are loaded; also hook GameBoot to be safe with load order.
_patch_ISBuildIsoEntity()
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(_patch_ISBuildIsoEntity)
end
