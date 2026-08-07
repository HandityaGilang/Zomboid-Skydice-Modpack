-- TwisTonFire — Better Fishing Reload Bait QoL
-- Short press Reload: attach the first valid bait.
-- Hold Reload: open a radial menu with available bait choices.

pcall(require, "ISUI/ISRadialMenu")
pcall(require, "ISUI/ISInventoryPaneContextMenu")
pcall(require, "Fishing/FishingUtils")
pcall(require, "Fishing/fishing_properties")
pcall(require, "TimedActions/Fishing/TimedActions/AIAttachLureAction")

TTF_BetterFishingReloadBait = TTF_BetterFishingReloadBait or {}

local STATE = {
    keyPressedMS = nil,
    radialWasVisible = false,

    pendingQuickBait = false,
    pendingPlayerNum = 0,
    pendingNotBeforeMS = 0,
    pendingUntilMS = 0,
    pendingTickRegistered = false,
}

local HOLD_DELAY_MS = 500
local REBAIT_DELAY_AFTER_FISH_MS = 600
local PENDING_REBAIT_TIMEOUT_MS = 3000

local onPendingReloadBaitTick = nil

local function getTextSafe(key, fallback)
    if getTextOrNull then
        local text = getTextOrNull(key)
        if text and text ~= key then
            return text
        end
    end

    return fallback
end

local function isValidFishingRod(item)
    if not item then return false end

    local okBroken, isBroken = pcall(function()
        return item:isBroken()
    end)

    if okBroken and isBroken then
        return false
    end

    if not ItemTag or not ItemTag.FISHING_ROD then
        return false
    end

    local okTag, hasTag = pcall(function()
        return item:hasTag(ItemTag.FISHING_ROD)
    end)

    return okTag and hasTag == true
end

local function getEquippedRod(playerObj)
    if not playerObj then return nil end

    local item = playerObj:getPrimaryHandItem()
    if isValidFishingRod(item) then
        return item
    end

    return nil
end

local function rodHasBait(rod)
    if not rod then return false end

    local modData = rod:getModData()
    local lure = modData and modData.fishing_Lure

    return lure ~= nil and lure ~= ""
end

local function tableHasAnyEntry(t)
    if type(t) ~= "table" then
        return false
    end

    for _ in pairs(t) do
        return true
    end

    return false
end

local function ensureLureIndex()
    if type(Fishing) ~= "table" then return false end
    if type(Fishing.lure) ~= "table" then return false end

    if type(Fishing.lure.All) ~= "table" or not tableHasAnyEntry(Fishing.lure.All) then
        if type(Fishing.IndexAllLures) ~= "function" then
            return false
        end

        local ok, err = pcall(Fishing.IndexAllLures)
        if not ok then
            print("TTF_BetterFishingReloadBait: Failed to index fishing lures: " .. tostring(err))
            return false
        end
    end

    return type(Fishing.lure.All) == "table"
end

local function getLureData(fullType)
    if not ensureLureIndex() then return nil end
    if not fullType then return nil end
    if not Fishing.lure or not Fishing.lure.All then return nil end

    return Fishing.lure.All[fullType]
end

local function isValidBaitItem(item)
    if not item then return false end
    if not ensureLureIndex() then return false end

    local fullType = item:getFullType()
    local lureData = getLureData(fullType)

    if not lureData then
        return false
    end

    if instanceof and instanceof(item, "Food") then
        local okCooked, cooked = pcall(function()
            return item:isCooked()
        end)

        if okCooked and cooked then
            return false
        end

        -- Food bait with 0 or positive HungChange is already depleted.
        -- Vanilla may fail to remove these correctly in MP after repeated bait usage.
        local amount = tonumber(lureData.amountOfFoodHunger) or -1
        if amount > 0 then
            local okHung, hung = pcall(function()
                return item:getHungChange()
            end)

            if okHung and tonumber(hung) and tonumber(hung) >= 0 then
                return false
            end
        end
    end

    return true
end

local function getAllAvailableBaits(playerObj)
    local result = {}
    if not playerObj then return result end

    local inv = playerObj:getInventory()
    if not inv then return result end

    local items = inv:getAllEvalRecurse(function(_item)
        return true
    end, ArrayList.new())

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if isValidBaitItem(item) then
            table.insert(result, item)
        end
    end

    table.sort(result, function(a, b)
        return tostring(a:getDisplayName()) < tostring(b:getDisplayName())
    end)

    return result
end

local function getUniqueBaits(playerObj)
    local allBaits = getAllAvailableBaits(playerObj)
    local unique = {}
    local seen = {}

    for _, item in ipairs(allBaits) do
        local fullType = item:getFullType()

        if not seen[fullType] then
            seen[fullType] = {
                item = item,
                count = 1,
            }
            table.insert(unique, seen[fullType])
        else
            seen[fullType].count = seen[fullType].count + 1
        end
    end

    return unique
end

local function isFishingIdle(playerObj)
    if not playerObj then return false end
    if not Fishing or not Fishing.ManagerInstances then return true end

    local key = playerObj:getPlayerNum()
    if isMultiplayer and isMultiplayer() then
        key = playerObj:getUsername()
    end

    local manager = Fishing.ManagerInstances[key] or Fishing.ManagerInstances[playerObj:getPlayerNum()]
    if not manager then return true end
    if not manager.states or not manager.states["None"] then return true end

    return manager.state == manager.states["None"]
end

local function hasQueuedActions(playerObj)
    if not playerObj or not ISTimedActionQueue then return false end

    local queue = ISTimedActionQueue.queues[playerObj]
    return queue and queue.queue and #queue.queue > 0
end

local function getFishingManager(playerObj)
    if not playerObj then return nil end
    if not Fishing or not Fishing.ManagerInstances then return nil end

    local key = playerObj:getPlayerNum()
    if isMultiplayer and isMultiplayer() then
        key = playerObj:getUsername()
    end

    return Fishing.ManagerInstances[key] or Fishing.ManagerInstances[playerObj:getPlayerNum()]
end

local function isManagerInState(manager, stateName)
    if not manager or not manager.states then return false end
    return manager.states[stateName] ~= nil and manager.state == manager.states[stateName]
end

local function isFishingStateBusy(playerObj)
    local manager = getFishingManager(playerObj)
    if not manager then return false end

    if isManagerInState(manager, "None") or isManagerInState(manager, "Idle") then
        return false
    end

    -- After catching a fish, PickupFish can remain for a very short time.
    -- If the action queue is already empty, we treat it as safe.
    if isManagerInState(manager, "PickupFish") and not hasQueuedActions(playerObj) then
        return false
    end

    return true
end

local function canAcceptReloadInput(playerObj)
    if not playerObj or playerObj:isDead() then return false end

    if UIManager.getSpeedControls()
            and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
        return false
    end

    if getCell():getDrag(playerObj:getPlayerNum()) then
        return false
    end

    local rod = getEquippedRod(playerObj)
    if not rod then return false end
    if rodHasBait(rod) then return false end

    return true
end

local function canAttachBaitNow(playerObj)
    if not canAcceptReloadInput(playerObj) then return false end
    if hasQueuedActions(playerObj) then return false end
    if isFishingStateBusy(playerObj) then return false end

    return true
end

local function canUseReloadBait(playerObj)
    return canAttachBaitNow(playerObj)
end

local function findInventoryItemByID(playerObj, itemID)
    if not playerObj or not itemID then return nil end

    local inv = playerObj:getInventory()
    if not inv then return nil end

    local direct = inv:getItemById(itemID)
    if direct then return direct end

    local items = inv:getAllEvalRecurse(function(item)
        return item and item:getID() == itemID
    end, ArrayList.new())

    if items and items:size() > 0 then
        return items:get(0)
    end

    return nil
end

local function findFirstBaitOfType(playerObj, fullType)
    if not playerObj or not fullType then return nil end

    local baits = getAllAvailableBaits(playerObj)
    for _, item in ipairs(baits) do
        if item and item:getFullType() == fullType then
            return item
        end
    end

    return nil
end

local function attachBait(playerObj, rod, bait)
    if not playerObj or not rod or not bait then return end

    local rodID = rod:getID()
    local baitID = bait:getID()
    local baitFullType = bait:getFullType()

    -- Re-resolve items right before queueing the action.
    -- This avoids stale item references after fishing/pickup/inventory sync in MP.
    rod = getEquippedRod(playerObj) or findInventoryItemByID(playerObj, rodID)
    bait = findInventoryItemByID(playerObj, baitID) or findFirstBaitOfType(playerObj, baitFullType)

    if not rod or not bait then return end
    if not isValidFishingRod(rod) then return end
    if rodHasBait(rod) then return end
    if not isValidBaitItem(bait) then return end
    if not AIAttachLureAction then return end
    if not ISInventoryPaneContextMenu then return end

    -- Do not equip the bait into secondary hand.
    -- Food bait with reduced hunger can get into a bad MP hand/inventory state after fishing.
    -- AIAttachLureAction only needs rod and lure to be present in the player's inventory.
    if ISInventoryPaneContextMenu.transferIfNeeded then
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bait)
    end

    ISTimedActionQueue.add(AIAttachLureAction:new(playerObj, rod, bait))
end

local function attachFirstBait(playerObj)
    if not canUseReloadBait(playerObj) then return end

    local rod = getEquippedRod(playerObj)
    local baits = getAllAvailableBaits(playerObj)

    if #baits == 0 then
        playerObj:setHaloNote(getTextSafe("UI_TTF_BF_NoValidBait", "No valid bait found."))
        return
    end

    attachBait(playerObj, rod, baits[1])
end

local function unregisterPendingTick()
    if STATE.pendingTickRegistered and onPendingReloadBaitTick then
        Events.OnTick.Remove(onPendingReloadBaitTick)
    end

    STATE.pendingTickRegistered = false
end

local function clearPendingQuickBait()
    STATE.pendingQuickBait = false
    STATE.pendingPlayerNum = 0
    STATE.pendingNotBeforeMS = 0
    STATE.pendingUntilMS = 0

    unregisterPendingTick()
end

local function registerPendingTick()
    if STATE.pendingTickRegistered then return end
    if not onPendingReloadBaitTick then return end

    Events.OnTick.Add(onPendingReloadBaitTick)
    STATE.pendingTickRegistered = true
end

local function scheduleQuickBait(playerObj, delayMS)
    if not playerObj then return end
    if not canAcceptReloadInput(playerObj) then return end

    local now = getTimestampMs()

    STATE.pendingQuickBait = true
    STATE.pendingPlayerNum = playerObj:getPlayerNum()
    STATE.pendingNotBeforeMS = now + (delayMS or 0)
    STATE.pendingUntilMS = now + PENDING_REBAIT_TIMEOUT_MS

    registerPendingTick()
end

onPendingReloadBaitTick = function()
    if not STATE.pendingQuickBait then
        clearPendingQuickBait()
        return
    end

    local now = getTimestampMs()

    if now > STATE.pendingUntilMS then
        clearPendingQuickBait()
        return
    end

    if now < STATE.pendingNotBeforeMS then
        return
    end

    local playerObj = getSpecificPlayer(STATE.pendingPlayerNum or 0)
    if not playerObj then
        clearPendingQuickBait()
        return
    end

    if not canAcceptReloadInput(playerObj) then
        clearPendingQuickBait()
        return
    end

    if not canAttachBaitNow(playerObj) then
        return
    end

    clearPendingQuickBait()
    attachFirstBait(playerObj)
end

local function centerRadialMenu(playerNum, menu)
    local x = getPlayerScreenLeft(playerNum)
    local y = getPlayerScreenTop(playerNum)
    local w = getPlayerScreenWidth(playerNum)
    local h = getPlayerScreenHeight(playerNum)

    x = x + w / 2
    y = y + h / 2

    menu:setX(x - menu:getWidth() / 2)
    menu:setY(y - menu:getHeight() / 2)
end

local function showBaitRadial(playerObj)
    if not canUseReloadBait(playerObj) then return end

    local playerNum = playerObj:getPlayerNum()
    local rod = getEquippedRod(playerObj)
    local baits = getUniqueBaits(playerObj)

    if #baits == 0 then
        playerObj:setHaloNote(getTextSafe("UI_TTF_BF_NoValidBait", "No valid bait found."))
        return
    end

    local menu = getPlayerRadialMenu(playerNum)
    menu:clear()
    centerRadialMenu(playerNum, menu)

    for _, data in ipairs(baits) do
        local item = data.item
        local text = item:getDisplayName()

        if data.count and data.count > 1 then
            text = text .. "\nx" .. tostring(data.count)
        end

        menu:addSlice(text, item:getTex(), attachBait, playerObj, rod, item)
    end

    menu:addToUIManager()
end

local function isReloadKey(key)
    return getCore() and getCore():isKey("ReloadWeapon", key)
end

local function onKeyStartPressed(key)
    if not isReloadKey(key) then return end

    local playerObj = getSpecificPlayer(0)
    if not canAcceptReloadInput(playerObj) then return end

    local radialMenu = getPlayerRadialMenu(0)

    if getCore():getOptionRadialMenuKeyToggle() and radialMenu:isReallyVisible() then
        STATE.radialWasVisible = true
        radialMenu:removeFromUIManager()
        return
    end

    STATE.keyPressedMS = getTimestampMs()
    STATE.radialWasVisible = false
end

local function onKeyKeepPressed(key)
    if not isReloadKey(key) then return end

    local playerObj = getSpecificPlayer(0)
    if not canAcceptReloadInput(playerObj) then return end
    if STATE.radialWasVisible then return end
    if not STATE.keyPressedMS then return end

    local radialMenu = getPlayerRadialMenu(0)
    local delay = HOLD_DELAY_MS

    if getCore():getOptionReloadRadialInstant() then
        delay = 0
    end

    if getTimestampMs() - STATE.keyPressedMS >= delay and not radialMenu:isReallyVisible() then
        if canAttachBaitNow(playerObj) then
            showBaitRadial(playerObj)
        end
    end
end

local function onKeyPressed(key)
    if not isReloadKey(key) then return end

    local playerObj = getSpecificPlayer(0)
    if not STATE.keyPressedMS then return end

    local radialMenu = getPlayerRadialMenu(0)

    if radialMenu:isReallyVisible() or STATE.radialWasVisible then
        STATE.keyPressedMS = nil

        if not getCore():getOptionRadialMenuKeyToggle() then
            radialMenu:removeFromUIManager()
        end

        return
    end

    local pressedMS = STATE.keyPressedMS
    STATE.keyPressedMS = nil

    if getCore():getOptionReloadRadialInstant() then return end

    if getTimestampMs() - pressedMS < HOLD_DELAY_MS then
        if canAttachBaitNow(playerObj) then
            attachFirstBait(playerObj)
        elseif canAcceptReloadInput(playerObj) then
            scheduleQuickBait(playerObj, REBAIT_DELAY_AFTER_FISH_MS)
        end
    end
end

local function onGameStart()
    Events.OnKeyStartPressed.Add(onKeyStartPressed)
    Events.OnKeyKeepPressed.Add(onKeyKeepPressed)
    Events.OnKeyPressed.Add(onKeyPressed)
end

Events.OnGameStart.Add(onGameStart)