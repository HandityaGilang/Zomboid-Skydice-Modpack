-- WMI_WashingSubmenus.lua
-- This script defines a new independent right-click submenu for washing clothes

require "ISUI/ISWorldObjectContextMenu"
require "TimedActions/ISWashClothing"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "ISUI/WMI_Compat_TABAS"

-- Small no-op action used to wait for MP inventory container updates (e.g., after bag -> main inventory transfers).
-- It lets us "retry" selecting the correct item instance before queuing ISWashClothing.
local WMI_WaitForInvUpdate = ISBaseTimedAction:derive("WMI_WaitForInvUpdate")

function WMI_WaitForInvUpdate:isValid()
    return true
end

function WMI_WaitForInvUpdate:start()
    -- No-op
end

function WMI_WaitForInvUpdate:update()
    -- No-op
end

function WMI_WaitForInvUpdate:stop()
    ISBaseTimedAction.stop(self)
end

function WMI_WaitForInvUpdate:perform()
    ISBaseTimedAction.perform(self)
end

function WMI_WaitForInvUpdate:new(character, maxTime)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = maxTime or 1
    return o
end

-- Compatibility helper: Project Zomboid Build 42.13+ changed InventoryItem:hasTag to use ItemTag enums.
-- Try enum first (newer builds), then string (older builds).
local function WMI_HasTag(item, tagString, tagEnum)
    -- Return false for nil items
    if not item then return false end
    -- Newer builds: hasTag(ItemTag.X)
    if tagEnum ~= nil then
        local ok, res = pcall(item.hasTag, item, tagEnum)
        if ok then return res end
    end
    -- Older builds: hasTag("TagName")
    local ok, res = pcall(item.hasTag, item, tagString)
    if ok then return res end
    return false
end

-- Compatibility helper: Build 42.14 renamed Clothing dirtiness accessors (get/set Dirtyness -> Dirtiness).
-- This keeps the mod working on 42.12/42.13 and 42.14+ without branching on build numbers.
local function WMI_GetDirtiness(item)
    -- Return 0 for nil items or items that don't expose dirtiness.
    if not item then return 0 end

    -- Newer builds (42.14+): item:getDirtiness()
    if item.getDirtiness then
        local ok, val = pcall(item.getDirtiness, item)
        if ok and val ~= nil then return val end
    end

    -- Older builds (<= 42.13): item:getDirtyness()
    if item.getDirtyness then
        local ok, val = pcall(item.getDirtyness, item)
        if ok and val ~= nil then return val end
    end

    return 0
end




-- Local copy of vanilla predicate used by legacy (42.13 / 42.14) soap-list building.
-- Keep it above WMI_BuildSoapList so the function is in scope when the fallback path runs.
local function predicateCleaningLiquid(item)
	if not item then return false end
	return item:hasComponent(ComponentType.FluidContainer)
		and (item:getFluidContainer():contains(Fluid.Bleach) or item:getFluidContainer():contains(Fluid.CleaningLiquid))
		and (item:getFluidContainer():getAmount() >= ZomboidGlobals.CleanBloodBleachAmount)
end

-- Compatibility helper: Build 42.15 removed the explicit `soapList` constructor argument from ISWashClothing:new(...).
-- Route WMI calls to the correct signature without duplicating build-specific code at each call site.
local function WMI_IsB4215Plus()
    if not getGameVersion then return false end
    local version = tostring(getGameVersion() or "")
    local major, minor = string.match(version, "^(%d+)%.(%d+)")
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    return (major > 42) or (major == 42 and minor >= 15)
end

local function WMI_NewWashAction(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
    if WMI_IsB4215Plus() then
        -- 42.15+: soaps are fetched internally by vanilla.
        return ISWashClothing:new(playerObj, sink, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
    end

    -- 42.13 / 42.14: keep the legacy constructor shape.
    return ISWashClothing:new(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap, returnContainer, waterOverride)
end

-- Compatibility helper: Build 42.15 changed soap lists from Lua tables to Java lists.
-- Keep one code path that works on 42.13/42.14 and 42.15+.
local function WMI_IsJavaList(list)
    return list and list.size and list.get
end

local function WMI_SoapListCount(list)
    if not list then return 0 end
    if WMI_IsJavaList(list) then
        local ok, size = pcall(list.size, list)
        if ok and size then return size end
        return 0
    end
    return #list
end

local function WMI_BuildSoapList(playerInv)
    if playerInv and playerInv.getSoapList then
        local ok, soaps = pcall(playerInv.getSoapList, playerInv, nil, true)
        if ok and soaps then
            return soaps
        end
    end

    -- Fallback for older builds that still use Lua tables.
    local soapList = {}

    local barList = playerInv:getItemsFromType("Soap2", true)
    if barList and barList.size then
        for i = 0, barList:size() - 1 do
            soapList[#soapList + 1] = barList:get(i)
        end
    end

    local bottleList = playerInv:getAllEvalRecurse(predicateCleaningLiquid)
    if bottleList and bottleList.size then
        for i = 0, bottleList:size() - 1 do
            soapList[#soapList + 1] = bottleList:get(i)
        end
    end

    return soapList
end

local function WMI_GetSoapRemaining(soapList)
    if not soapList then return 0 end
    if ISWashClothing and ISWashClothing.GetSoapRemaining then
        local ok, value = pcall(ISWashClothing.GetSoapRemaining, soapList)
        if ok and value ~= nil then return value end
    end

    -- Fallback for older Lua-table soap lists.
    local total = 0
    for _, soap in ipairs(soapList) do
        if instanceof(soap, "DrainableComboItem") then
            total = total + soap:getCurrentUses()
        elseif soap.getFluidContainer and soap:getFluidContainer() and soap:getFluidContainer():contains(Fluid.CleaningLiquid) then
            total = total + (soap:getFluidContainer():getAmount() * 10)
        end
    end
    return total
end

-- Optional debug logger (off unless WS.debug is true)
WS = WS or {}
WS.debug = false
function WS.log(...)
    if not WS.debug then return end
    local t = {}
    for i=1, select("#", ...) do t[#t+1] = tostring(select(i, ...)) end
    print("[WMI] " .. table.concat(t, " "))
end

local function getItemResult(inputItem)
    return itemTransformations[inputItem] or "Unknown Item"
end

-- ISWorldObjectContextMenu = {}
-- ISWorldObjectContextMenu.fetchVars = {}
-- ISWorldObjectContextMenu.fetchSquares = {}
-- ISWorldObjectContextMenu.tooltipPool = {}
-- ISWorldObjectContextMenu.tooltipsUsed = {}

-- local function predicateBleach(item)		-- CHANGED comment because not used
	-- if not item then return false end
	-- return item:hasComponent(ComponentType.FluidContainer) and	item:getFluidContainer():contains(Fluid.Bleach) and (item:getFluidContainer():getAmount() >= ZomboidGlobals.CleanBloodBleachAmount)
-- end

local function onWashClothing2(playerObj, sink, soapList, washList, singleClothing, noSoap, context)
	ISWorldObjectContextMenu.onWashClothing(playerObj, sink, soapList, washList, singleClothing, noSoap)
	context:closeAll()
end

local function onWashClothing3(playerObj, sink, soapList, washList, singleClothing, noSoap, closeCtx)
    -- Build 42.13+ / MP-safe chain:
    -- 1) Walk adjacent to the sink.
    -- 2) If an item is inside an equipped bag, transfer it to main inventory first.
    -- 3) After the transfer completes, queue ISWashClothing.
    -- 4) If the item does NOT transform (no ItemAfterCleaning), return it back to the original container.
    -- 5) If the item DOES transform (ItemAfterCleaning), let the patched ISWashClothing return the clean result to the original container.

    if sink and sink.getSquare then
        luautils.walkAdj(playerObj, sink:getSquare())
    end

    local playerInv = playerObj:getInventory()

    -- Queue ISWashClothing right after an inventory transfer completes.
    -- This is more MP-safe than calling ISWashClothing directly on items still inside bags.
	local WMI_AfterWait_QueueWash

	local function WMI_InsertAfter(queue, afterAction, action)
		local insertIndex = 1
		local i = queue:indexOf(afterAction)
		if i ~= -1 then
			insertIndex = i + 1
		end
		table.insert(queue.queue, insertIndex, action)
		return insertIndex
	end

	local function WMI_ScheduleInvRetry(afterAction, transferAction)
		local attempt = tonumber(transferAction.wmiRetryAttempt) or 0
		attempt = attempt + 1
		transferAction.wmiRetryAttempt = attempt

		if attempt > 20 then
			if WS and WS.debug then
				print("[WMI] AfterTransfer -> inventory not updated after retries, aborting chain")
			end
			ISTimedActionQueue.clear(playerObj)
			return
		end

		local waitAction = WMI_WaitForInvUpdate:new(playerObj, 1)
		waitAction.wmiTransferAction = transferAction
		waitAction:setOnComplete(WMI_AfterWait_QueueWash, waitAction)

		local queue = ISTimedActionQueue.getTimedActionQueue(playerObj)
		if queue and queue.queue then
			WMI_InsertAfter(queue, afterAction, waitAction)
		else
			ISTimedActionQueue.add(waitAction)
		end
	end

	local function WMI_QueueWashAfter(afterAction, transferAction)
		-- IMPORTANT: in a listen-server/coop host, isServer() can be true in the client Lua state.
		-- Only skip this callback on a dedicated server (server-only Lua, no client).
		if isServer and isServer() and (not isClient or not isClient()) then return end

		if not transferAction or not transferAction.item then
			ISTimedActionQueue.clear(playerObj)
			return
		end

		-- Cancel the chain if the player is no longer adjacent to the sink
		if transferAction.wmiRequireAdjSink and sink and sink.getSquare then
			local sqChr = playerObj:getSquare()
			local sqSink = sink:getSquare()
			if not sqChr or not sqSink
				or sqChr:getZ() ~= sqSink:getZ()
				or math.abs(sqChr:getX() - sqSink:getX()) > 1
				or math.abs(sqChr:getY() - sqSink:getY()) > 1
			then
				ISTimedActionQueue.clear(playerObj)
				return
			end
		end

		-- Find the actual instance now present in the main inventory.
		-- For stackables, the transfer may split and create a new item with a different id.
		local itemToWash = transferAction.item
		local expectedFullType = transferAction.wmiExpectedFullType
		local beforeIds = transferAction.wmiBeforeInvIds

		if beforeIds and expectedFullType then
			local items = playerInv:getItems()
			for i = 0, items:size() - 1 do
				local it = items:get(i)
				if it and it:getFullType() == expectedFullType and not beforeIds[it:getID()] then
					itemToWash = it
					break
				end
			end
		end

		-- If the client hasn't received the container update yet (common in MP),
		-- wait a tick and retry instead of aborting the whole chain.
		if not playerInv:contains(itemToWash) then
			if WS and WS.debug then
				print("[WMI] AfterTransfer -> item not yet in main inventory (retry scheduled) type=" .. tostring(expectedFullType or (itemToWash and itemToWash:getFullType())))
			end
			WMI_ScheduleInvRetry(afterAction, transferAction)
			return
		end

		-- For items that transform (ItemAfterCleaning), let the patched ISWashClothing
		-- move the clean result to the original container.
		local wmiReturnContainer = nil
		if transferAction.wmiWillTransform then
			wmiReturnContainer = transferAction.wmiOriginalContainer
		end

		local washAction = WMI_NewWashAction(
			playerObj, sink, soapList, itemToWash,
			transferAction.wmiBloodAmount, transferAction.wmiDirtAmount, transferAction.wmiNoSoap,
			wmiReturnContainer
		)

		local queue = ISTimedActionQueue.getTimedActionQueue(playerObj)
		if not queue or not queue.queue then
			ISTimedActionQueue.add(washAction)
			if (not transferAction.wmiWillTransform) and transferAction.wmiOriginalContainer
				and transferAction.wmiOriginalContainer ~= playerInv
			then
				local backTransfer = ISInventoryTransferAction:new(playerObj, itemToWash, playerInv, transferAction.wmiOriginalContainer)
				backTransfer:setAllowMissingItems(true)
				ISTimedActionQueue.add(backTransfer)
			end
			return
		end

		local insertIndex = WMI_InsertAfter(queue, afterAction, washAction)

		-- For non-transforming items, return the same item to its original container after washing
		if (not transferAction.wmiWillTransform) and transferAction.wmiOriginalContainer
			and transferAction.wmiOriginalContainer ~= playerInv
		then
			local backTransfer = ISInventoryTransferAction:new(playerObj, itemToWash, playerInv, transferAction.wmiOriginalContainer)
			backTransfer:setAllowMissingItems(true)
			table.insert(queue.queue, insertIndex + 1, backTransfer)
		end
	end

	WMI_AfterWait_QueueWash = function(waitAction)
		local transferAction = waitAction and waitAction.wmiTransferAction
		if not transferAction then
			ISTimedActionQueue.clear(playerObj)
			return
		end
		WMI_QueueWashAfter(waitAction, transferAction)
	end

	function WMI_AfterTransfer_QueueWash(transferAction)
		WMI_QueueWashAfter(transferAction, transferAction)
	end

	-- Normalize washList: allow a single InventoryItem to be passed in.
    if washList and type(washList) ~= "table" then
        washList = { washList }
    end
    if not washList then
        if closeCtx and closeCtx.closeAll then closeCtx:closeAll() end
        return
    end

    for _, item in ipairs(washList) do
        if item then
            local originalContainer = item:getContainer()
            local isFromBag = originalContainer and originalContainer ~= playerInv

            -- Compute wash amounts defensively (some items may not expose blood/dirt methods)
            local bloodAmount = 0
            local dirtAmount = 0
            if item.getBloodLevel then
                bloodAmount = item:getBloodLevel() or 0
            end
            -- Dirtiness accessor was renamed in 42.14 (Dirtyness -> Dirtiness).
            dirtAmount = WMI_GetDirtiness(item)

            if isFromBag then
                -- Snapshot main inventory ids before transfer to detect a newly created instance (stack split)
                local beforeIds = {}
                local invItems = playerInv:getItems()
                for i = 0, invItems:size() - 1 do
                    local it = invItems:get(i)
                    beforeIds[it:getID()] = true
                end

                local xfer = ISInventoryTransferAction:new(playerObj, item, originalContainer, playerInv)

                -- IMPORTANT: do NOT allow missing items here. If the transfer is skipped in MP,
                -- ISWashClothing may receive a nil item on the server and the action will be rejected.
                xfer:setAllowMissingItems(false)

                -- Store data needed by the on-complete callback (client-side)
                xfer.wmiOriginalContainer = originalContainer
                xfer.wmiWillTransform = (not instanceof(item, "Clothing")) and item.getItemAfterCleaning and (item:getItemAfterCleaning() ~= nil)
                xfer.wmiRequireAdjSink = true
                xfer.wmiBloodAmount = bloodAmount
                xfer.wmiDirtAmount = dirtAmount
                xfer.wmiNoSoap = noSoap
                xfer.wmiExpectedFullType = item:getFullType()
                xfer.wmiBeforeInvIds = beforeIds

                xfer:setOnComplete(WMI_AfterTransfer_QueueWash, xfer)
                ISTimedActionQueue.add(xfer)
            else
                -- Item already in main inventory: wash directly
                ISTimedActionQueue.add(WMI_NewWashAction(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap))
            end
        end
    end

    -- Close the visible context menu (important for nested submenus)
    if closeCtx and closeCtx.closeAll then closeCtx:closeAll() end
end


function ISWorldObjectContextMenu.compareRequiredWater(item1, item2)
	return ISWashClothing.GetRequiredWater(item1) < ISWashClothing.GetRequiredWater(item2)
end

local function getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

-- Helper for creating inventory sub-options
local function createInventorySubOption(label, list, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, parentMenu)
    if #list == 0 then return end
    local soapRequired, waterRequired = 0, 0
    local washListPart, washPart = {}, false
    for _, item in ipairs(list) do
        soapRequired = soapRequired + ISWashClothing.GetRequiredSoap(item)
        waterRequired = waterRequired + ISWashClothing.GetRequiredWater(item)
        if waterRemaining < waterRequired then
            if #washListPart > 0 then washPart = true end
        else
            table.insert(washListPart, item)
        end
    end
    if washPart then
        soapRequired = 0
        waterRequired = 0
        for _, item in ipairs(washListPart) do
            soapRequired = soapRequired + ISWashClothing.GetRequiredSoap(item)
            waterRequired = waterRequired + ISWashClothing.GetRequiredWater(item)
        end
    end
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    if WMI_GetSoapRemaining(soapList) < soapRequired then
        tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
        tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
        noSoap = true
    else
        tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
        noSoap = false
    end
    if waterRemaining < waterRequired then
        tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
    else
        tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
    end
    for _, item in ipairs(washListPart) do
        tooltip.description = tooltip.description .. " <RGB:1,1,1> <LINE> " .. getText("ContextMenu_WashClothing", item:getDisplayName())
    end

	local option = parentMenu:addOption(label .. " (" .. tostring(#washListPart) .. "/" .. tostring(#list) .. ")", playerObj, onWashClothing3, sink, soapList, washListPart, nil, noSoap, closeCtx)
    option.toolTip = tooltip
    if waterRemaining < waterRequired then option.notAvailable = true end
end

-- Helper for creating bag sub-options
-- createBagSubOption("ContextMenu_All") .. " " .. getText("IGUI_PlayerStats_Type"), washListData.bagItems, playerObj, sink, soapList, context, noSoap, waterRemaining, bagsSubMenu)
local function createBagSubOption(label, list, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, parentMenu)
	local soapRequired, waterRequired = 0, 0
	local soapRequiredPart, waterRequiredPart = 0, 0

	local washListPart = {}
	local washPart = false
	local washInBags = false
	for _, item in ipairs(list) do
		soapRequired = soapRequired + ISWashClothing.GetRequiredSoap(item)
		waterRequired = waterRequired + ISWashClothing.GetRequiredWater(item)
		if waterRemaining < waterRequired then
			if #washListPart > 0 then washPart = true end
		else
			table.insert(washListPart, item)
			soapRequiredPart = soapRequired
			waterRequiredPart = waterRequired
		end
	end
	if washPart then
		soapRequired = soapRequiredPart
		waterRequired = waterRequiredPart
	end
	local tooltip = ISWorldObjectContextMenu.addToolTip()
	if WMI_GetSoapRemaining(soapList) < soapRequired then
		tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
		tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
	else
		tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
	end
	if waterRemaining < waterRequired then
		tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
	else
		tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
	end

	for _, item in ipairs(washListPart) do
		tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("ContextMenu_WashClothing", item:getDisplayName())
	end

	local option = parentMenu:addOption(label .. " (" .. tostring(#washListPart) .. "/" .. tostring(#list) .. ")", playerObj, onWashClothing3, sink, soapList, washListPart, nil, noSoap, closeCtx)
	option.toolTip = tooltip
	if waterRemaining < waterRequired then
		option.notAvailable = true
	end
end

-- Closes the real root context after triggering vanilla wash-yourself
local function _onWashYourselfAndClose(playerObj, sink, soapList, closeCtx)
    ISWorldObjectContextMenu.onWashYourself(playerObj, sink, soapList)
    if closeCtx and closeCtx.closeAll then closeCtx:closeAll() end
end

-- Build the submenu for clothing that can be washed
local function createWashSubmenu(context, worldobjects, playerObj, sink, closeCtx)
	-- Be permissive: only block if BOTH buildings exist and differ (rivers/wells may have no building).
	local _sq = sink and sink.getSquare and sink:getSquare() or nil
	local _bA = _sq and _sq.getBuilding and _sq:getBuilding() or nil
	local _bB = playerObj and playerObj.getBuilding and playerObj:getBuilding() or nil
	if _bA and _bB and _bA ~= _bB then return end

    local playerInv = playerObj:getInventory()
	local washYourself = false
	local washEquipment = false
	local washInBags = false
	-- local washList = {} -- CHANGED: new types
	local washListData = {}
	washListData.invItems = {}
	washListData.clothing = {}
	washListData.weapon = {}

	washListData.equipped = {}
	washListData.unequipped = {}
	washListData.clothingEquipped = {}
	washListData.clothingEquippedBloody = {}
	-- washListData.clothingUnequipped = {}
	-- washListData.weaponEquipped = {}
	-- washListData.weaponUnequipped = {}

	washListData.bagItems = {}
	washListData.bagClothing = {}
	washListData.bagWeapons = {}

	local soapList = WMI_BuildSoapList(playerInv)
	local noSoap = true

	washYourself = ISWashYourself.GetRequiredWater(playerObj) > 0


	local clothingInventory = playerInv:getItemsFromCategory("Clothing")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		-- Wasn't able to reproduce the wash 'Blooo' bug, don't know the exact cause so here's a fix...
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) and not WMI_HasTag(item, "BreakWhenWet", ItemTag and ItemTag.BREAK_WHEN_WET) then
			if washEquipment == false then
				washEquipment = true
			end
			if playerObj:isEquipped(item) then
                table.insert(washListData.equipped, item)
				table.insert(washListData.clothingEquipped, item)
				if item:hasBlood() then
					table.insert(washListData.clothingEquippedBloody, item)
				end
            else
                table.insert(washListData.unequipped, item)
				-- table.insert(washListData.clothingUnequipped, item)
            end

			-- table.insert(washListData.clothing, item)
			table.insert(washListData.invItems, item)
		end
	end
	
	-- local dirtyRagInventory = playerInv:getAllTag("CanBeWashed", ArrayList.new()) -- CHANGED COMMENT because NEW SUBMENU FOR RAGS
	-- for i=0, dirtyRagInventory:size() - 1 do
		-- local item = dirtyRagInventory:get(i)	
			-- if washEquipment == false then
				-- washEquipment = true
			-- end
			-- table.insert(washList, item)
	-- end
	
    local weaponInventory = playerInv:getItemsFromCategory("Weapon")
    for i=0, weaponInventory:size() - 1 do
        local item = weaponInventory:get(i)
        if item:hasBlood() then
            if washEquipment == false then
                washEquipment = true
            end
            -- table.insert(washList, item) -- CHANGED: new types
			if playerObj:isEquipped(item) then
                table.insert(washListData.equipped, item)
				-- table.insert(washListData.weaponEquipped, item)
            else
                table.insert(washListData.unequipped, item)
				-- table.insert(washListData.weaponUnequipped, item)
            end

			table.insert(washListData.weapon, item)
			table.insert(washListData.invItems, item)
        end
	end

	local containerInventory = playerInv:getItemsFromCategory("Container")
	for i=0, containerInventory:size() - 1 do
		local item = containerInventory:get(i)
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) then
			washEquipment = true
			-- if playerObj:isEquipped(item) then
                -- table.insert(washListData.equipped, item)
				-- table.insert(washListData.clothingEquipped, item)
				-- if item:hasBlood() then
					-- table.insert(washListData.clothingEquippedBloody, item)
				-- end
            -- else
                -- table.insert(washListData.unequipped, item)
				-- -- table.insert(washListData.clothingUnequipped, item)
            -- end

			-- table.insert(washListData.clothing, item)
			table.insert(washListData.invItems, item)
		end
		
		local container = containerInventory:get(i)
		if playerObj:isEquipped(container) and container:getInventory() then
			local itemsInBag = container:getInventory():getItems()
			for j = 0, itemsInBag:size() - 1 do
				local item = itemsInBag:get(j)
				if item and (item:hasBlood() or item:hasDirt()) and not item:isHidden() and not WMI_HasTag(item, "BreakWhenWet", ItemTag and ItemTag.BREAK_WHEN_WET) then
					table.insert(washListData.bagItems, item)
					if item:IsClothing() or item:IsInventoryContainer() then
						table.insert(washListData.bagClothing, item)
					elseif item:IsWeapon() then
						table.insert(washListData.bagWeapons, item)
					end
					washInBags = true
				end
			end
		end
	end
	
	-- Sort clothes from least-bloody to most-bloody.
	table.sort(washListData.equipped, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.unequipped, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.clothingEquipped, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.clothingEquippedBloody, ISWorldObjectContextMenu.compareRequiredWater)
	-- table.sort(washListData.clothingUnequipped, ISWorldObjectContextMenu.compareRequiredWater)
	-- table.sort(washListData.weaponEquipped, ISWorldObjectContextMenu.compareRequiredWater)
	-- table.sort(washListData.weaponUnequipped, ISWorldObjectContextMenu.compareRequiredWater)
	-- table.sort(washListData.clothing, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.weapon, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.invItems, ISWorldObjectContextMenu.compareRequiredWater)

	table.sort(washListData.bagItems, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.bagClothing, ISWorldObjectContextMenu.compareRequiredWater)
	table.sort(washListData.bagWeapons, ISWorldObjectContextMenu.compareRequiredWater)


	if washYourself or washEquipment or washInBags then
		local mainOption = context:addOption(getText("ContextMenu_Wash"), nil, nil);
		mainOption.iconTexture = getTexture("media/textures/Item_Bucket_Water.png")
		local mainSubMenu = ISContextMenu:getNew(context)
		context:addSubMenu(mainOption, mainSubMenu)
	
--		if #soapList < 1 then
--			mainOption.notAvailable = true;
--			local tooltip = ISWorldObjectContextMenu.addToolTip();
--			tooltip:setName("Need soap.");
--			mainOption.toolTip = tooltip;
--			return;
--		end
		local soapRemaining = 0;
		if WMI_SoapListCount(soapList) >= 1 then
			soapRemaining = WMI_GetSoapRemaining(soapList)
		end
		local waterRemaining = sink:getFluidAmount()
	
		if washYourself then
			local soapRequired = ISWashYourself.GetRequiredSoap(playerObj)
			local waterRequired = ISWashYourself.GetRequiredWater(playerObj)
			local option = mainSubMenu:addOption(getText("ContextMenu_Yourself"), playerObj, _onWashYourselfAndClose, sink, soapList, closeCtx)
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			if soapRemaining < soapRequired then
				tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
				tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
			else
				tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
			end
			if waterRemaining < waterRequired then
				tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
			else
				tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
			end
			local visual = playerObj:getHumanVisual()
			local bodyBlood = 0
			local bodyDirt = 0
			for i=1,BloodBodyPartType.MAX:index() do
				local part = BloodBodyPartType.FromIndex(i-1)
				bodyBlood = bodyBlood + visual:getBlood(part)
				bodyDirt = bodyDirt + visual:getDirt(part)
			end
			if bodyBlood > 0 then
				tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(bodyBlood / BloodBodyPartType.MAX:index() * 100) .. " %"
			end
			if bodyDirt > 0 then
				tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(bodyDirt / BloodBodyPartType.MAX:index() * 100) .. " %"
			end
			option.toolTip = tooltip
			if waterRemaining < 1 then
				option.notAvailable = true
			end
		end
		
		if washEquipment then
		
			-- if #washList > 1 then -- CHANGED
			if #washListData.invItems > 0 then
				local invOption = mainSubMenu:addOption(getText("ContextMenu_MoveToInventory"), playerObj, nil)
				-- Inventory submenu (vanilla style: build submenu in the same root 'context')
				-- parent menu is still 'mainSubMenu', but the instance map belongs to 'context'
						-- local invSubMenu = ISContextMenu:getNew(mainSubMenu)   -- wrong
						-- mainSubMenu:addSubMenu(invOption, invSubMenu)          -- wrong
				local invSubMenu = ISContextMenu:getNew(context)       -- root = tmp context
				context:addSubMenu(invOption, invSubMenu)

			
				-- Using function createInventorySubOption(label, list, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, parentMenu)
				createInventorySubOption(getText("ContextMenu_All") .. " " .. getText("IGUI_PlayerStats_Type"), washListData.invItems, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- EQUIPPED
				createInventorySubOption(getText("Tooltip_item_Equipped"):lower():gsub("^%l", string.upper), washListData.equipped, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- UNEQUIPPED
				createInventorySubOption(getText("Tooltip_item_Unequipped"):lower():gsub("^%l", string.upper), washListData.unequipped, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- WEAPONS
				createInventorySubOption(getText("IGUI_SearchMode_Categories_JunkWeapons"), washListData.weapon, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- CLOTHING EQUIPPED
				createInventorySubOption(getText("IGUI_ItemCat_Clothing") .. " " .. getText("Tooltip_item_Equipped"), washListData.clothingEquipped, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- CLOTHING EQUIPPED (BLOOD ONLY)
				-- WMI: This targets only equipped clothing that has blood (useful for Fear of Blood trait).
				createInventorySubOption(getText("IGUI_ItemCat_Clothing") .. " " .. getText("Tooltip_item_Equipped") .. " (" .. getText("IGUI_ClothingName_Bloody") .. ")", washListData.clothingEquippedBloody, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, invSubMenu)
				
				-- FULL ITEM LIST
				for i,item in ipairs(washListData.invItems) do
					if i > 30 then break end
					local soapRequired = ISWashClothing.GetRequiredSoap(item)
					local waterRequired = ISWashClothing.GetRequiredWater(item)
					local tooltip = ISWorldObjectContextMenu.addToolTip();
					if (soapRemaining < soapRequired) then
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
						noSoap = true;
					else
						tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
						-- tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
						noSoap = false;
					end
					if waterRemaining < waterRequired then
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
					else
						tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
					end
					-- Clothing / containers: getBloodLevel() already 0..100
					if (item:IsClothing() or item:IsInventoryContainer()) and (item:getBloodLevel() > 0) then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel()) .. " %"
					end
					-- Weapons: getBloodLevel() is 0..1 → scale to 0..100
					if item:IsWeapon() and (item:getBloodLevel() > 0) then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel() * 100) .. " %"
					end
					local dirt = WMI_GetDirtiness(item)
					if item:IsClothing() and dirt > 0 then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(dirt) .. " %"
					end
					local option = invSubMenu:addOption(getText("ContextMenu_WashClothing", item:getDisplayName()), playerObj, onWashClothing3, sink, soapList, { item }, nil, noSoap, closeCtx);
					option.toolTip = tooltip;
					option.itemForTexture = item
					if (waterRemaining < waterRequired) then
						option.notAvailable = true;
					end
				end
			end
		end
			
		-- ITEMS IN EQUIPPED BACKPACKS
		if washInBags then
			if #washListData.bagItems > 0 then
				local bagsOption = mainSubMenu:addOption(getText("ContextMenu_BagsEquipped"), playerObj, nil)
				-- Bags equipped submenu (vanilla style)
						-- local bagsSubMenu = ISContextMenu:getNew(mainSubMenu)  -- wrong
						-- mainSubMenu:addSubMenu(bagsOption, bagsSubMenu)        -- wrong
				local bagsSubMenu = ISContextMenu:getNew(context)      -- root = tmp context
				context:addSubMenu(bagsOption, bagsSubMenu)
			
				-- Using function createBagSubOption(label, list, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, parentMenu)
				createBagSubOption((getText("ContextMenu_All") .. " " .. getText("IGUI_PlayerStats_Type")), washListData.bagItems, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, bagsSubMenu)
				if #washListData.bagClothing > 0 then
					createBagSubOption(getText("IGUI_ItemCat_Clothing"), washListData.bagClothing, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, bagsSubMenu)
				end
				if #washListData.bagWeapons > 0 then
					createBagSubOption(getText("IGUI_SearchMode_Categories_JunkWeapons"), washListData.bagWeapons, playerObj, sink, soapList, closeCtx, noSoap, waterRemaining, soapRemaining, bagsSubMenu)
				end
				
				-- FULL ITEM LIST (Equipped bags)
				for i,item in ipairs(washListData.bagItems) do
					if i > 30 then break end
					local soapRequired = ISWashClothing.GetRequiredSoap(item)
					local waterRequired = ISWashClothing.GetRequiredWater(item)
					local tooltip = ISWorldObjectContextMenu.addToolTip();
					if (soapRemaining < soapRequired) then
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
						noSoap = true;
					else
						tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("IGUI_Washing_Soap") .. ": " .. tostring(soapRemaining) .. " / " .. tostring(soapRequired) .. " <LINE> "
						-- tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
						noSoap = false;
					end
					if waterRemaining < waterRequired then
						tooltip.description = tooltip.description .. " <RGB:1,0.5,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
					else
						tooltip.description = tooltip.description .. " <RGB:0.5,1,0.5> " .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.floor(waterRemaining)) .. " / " .. tostring(waterRequired)
					end
					if (item:IsClothing() or item:IsInventoryContainer()) and (item:getBloodLevel() > 0) then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel()) .. " %"
					end
					if item:IsWeapon() and (item:getBloodLevel() > 0) then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel() * 100) .. " %"
					end
					local dirt = WMI_GetDirtiness(item)
					if item:IsClothing() and dirt > 0 then
						tooltip.description = tooltip.description .. " <RGB:1,1,1> " .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(dirt) .. " %"
					end
					local option = bagsSubMenu:addOption(getText("ContextMenu_WashClothing", item:getDisplayName()), playerObj, onWashClothing3, sink, soapList, { item }, nil, noSoap, closeCtx);
					option.toolTip = tooltip;
					option.itemForTexture = item
					if (waterRemaining < waterRequired) then
						option.notAvailable = true;
					end
				end
		
			end
		end
	end
end

-- === Submenu lookup helpers (instanceMap-aware, language-agnostic) =============================

local function _tr(key)
    local ok, val = pcall(getText, key)
    return ok and val or nil
end

-- Get submenu table from an option using root instanceMap
local function getSubMenuFromOption(rootContext, opt)
    if not rootContext or not opt then return nil end
    local id = opt.subOption
    if not id then return nil end
    return rootContext:getSubMenu(id) -- mapped via instanceMap
end

local function _getSubMenuFromOption(rootContext, opt)
    return getSubMenuFromOption(rootContext, opt)
end

-- Find the water-source submenu (child of e.g. "Fregadero industrial")
local function findWaterSubMenuSmart(context)
    if not context or not context.options then return nil end
    local tWash   = _tr("ContextMenu_Wash")
    local tDrink  = _tr("ContextMenu_Drink")
    local tFill   = _tr("ContextMenu_Fill")
    local tRefill = _tr("ContextMenu_Refill")

    -- Pass 1: submenu that contains BOTH Drink and Fill/Refill
    for _, opt in ipairs(context.options) do
        local sub = getSubMenuFromOption(context, opt)
        if sub and sub.options then
            local hasDrink, hasFill = false, false
            for __, ch in ipairs(sub.options) do
                hasDrink = hasDrink or (ch.name == tDrink)
                hasFill  = hasFill or (ch.name == tFill or ch.name == tRefill)
            end
            if hasDrink and hasFill then return sub, opt end
        end
    end

    -- Pass 2: submenu that contains Wash + (Drink or Fill/Refill)
    for _, opt in ipairs(context.options) do
        local sub = getSubMenuFromOption(context, opt)
        if sub and sub.options then
            local hasWash, hasWater = false, false
            for __, ch in ipairs(sub.options) do
                hasWash  = hasWash or (ch.name == tWash)
                hasWater = hasWater or (ch.name == tDrink or ch.name == tFill or ch.name == tRefill)
            end
            if hasWash and hasWater then return sub, opt end
        end
    end

    -- Fallback: none found
    return nil, nil
end

-- Find the existing vanilla "Wash" option inside a given submenu
local function findVanillaWashOption(waterSubMenu)
    local tWash = _tr("ContextMenu_Wash")
    if not waterSubMenu or not waterSubMenu.options then return nil end
    for _, ch in ipairs(waterSubMenu.options) do
        if ch.name == tWash then return ch end
    end
    return nil
end

-- Accept only water (clean or tainted) as valid wash sources
local function _isWaterObject(o)
    if not o then return false end

    -- World sources (sinks, wells, etc.)
    if o.hasWater then
        local okHas, has = pcall(function() return o:hasWater() end)
        if okHas and has then return true end
    end

    -- Fluid-based sources (items on ground, buckets, pots, barrels, etc.)
    local okAmt, amt = false, nil
    if o.getFluidAmount then
        okAmt, amt = pcall(function() return o:getFluidAmount() end)
    end

    local okFC, fc = false, nil
    if o.getFluidContainer then
        okFC, fc = pcall(function() return o:getFluidContainer() end)
    end

    if okFC and fc and okAmt and type(amt) == "number" and amt >= 1 then
        -- Fast path: container contains water
        if fc.contains then
            local okW, hasW = pcall(function() return fc:contains(Fluid.Water) end)
            local okT, hasT = pcall(function() return fc:contains(Fluid.TaintedWater) end)
            if (okW and hasW) or (okT and hasT) then return true end
        end

        -- Fallback: some containers expose a single fluidType
        if fc.getFluidType then
            local okFT, ft = pcall(function() return fc:getFluidType() end)
            if okFT and (ft == Fluid.Water or ft == Fluid.TaintedWater) then return true end
        end
    end

    -- Note: Do NOT call o:getFluidType() here.
    -- Some non-water objects (e.g. modded fluid containers) may expose getFluidAmount/getFluidContainer,
    -- but calling getFluidType() on the root object can throw in some setups (and will spam errors).
    return false
end

-- Collect all water-capable objects on/near the clicked tile (deduped)
local function _collectWaterObjects(worldobjects)
    local list, seen, candidateSquares = {}, {}, {}
    for _, wobj in ipairs(worldobjects or {}) do
        if _isWaterObject(wobj) and not seen[wobj] then
            seen[wobj] = true; table.insert(list, wobj)
        end
        local sq = wobj.getSquare and wobj:getSquare() or nil
        if sq then candidateSquares[sq] = true end
    end
    for sq,_ in pairs(candidateSquares) do
        if sq.getObjects then
            local arr = sq:getObjects()
            for i=0, arr:size()-1 do
                local o = arr:get(i)
                if _isWaterObject(o) and not seen[o] then
                    seen[o] = true; table.insert(list, o)
                end
            end
        end
    end
    return list
end

-- Given a root context and a worldobject, find that object's submenu:
-- 1) try exact match by display name ("Chrome Sink", "Toilet", ...)
-- 2) fallback: first submenu that has Drink + Fill/Refill
local function _findWaterSubMenuForObject(context, obj)
    if not context then return nil, nil end
    local name = getMoveableDisplayName(obj) -- "Chrome Sink", etc.
    if name then
        for _, opt in ipairs(context.options or {}) do
            if opt.name == name and opt.subOption then
                return context:getSubMenu(opt.subOption), opt
            end
        end
    end
    -- Fallback: scan for a submenu that contains both Drink and Fill/Refill
    local tDrink  = _tr("ContextMenu_Drink")
    local tFill   = _tr("ContextMenu_Fill")
    local tRefill = _tr("ContextMenu_Refill")
    for _, opt in ipairs(context.options or {}) do
        local sub = getSubMenuFromOption(context, opt)
        if sub and sub.options then
            local hasDrink, hasFill = false, false
            for __, ch in ipairs(sub.options) do
                hasDrink = hasDrink or (ch.name == tDrink)
                hasFill  = hasFill  or (ch.name == tFill or ch.name == tRefill)
            end
            if hasDrink and hasFill then return sub, opt end
        end
    end
    return nil, nil
end

-- Only treat as water submenu if it's clearly water-capable:
--   has Wash  OR  (has Drink AND has Fill/Refill)
local function _iterWaterSubmenus(context)
    local tDrink  = getText("ContextMenu_Drink")  or "Drink"
    local tFill   = getText("ContextMenu_Fill")   or "Fill"
    local tRefill = getText("ContextMenu_Refill") or "Refill"
    local tWash   = getText("ContextMenu_Wash")   or "Wash"

    local out = {}
    for _, top in ipairs(context.options or {}) do
        local sub = _getSubMenuFromOption(context, top)
        if sub and sub.options then
            local hasDrink, hasFill, hasWash = false, false, false
            for __, ch in ipairs(sub.options) do
                local n = ch.name
                hasDrink = hasDrink or (n == tDrink)
                hasFill  = hasFill  or (n == tFill or n == tRefill)
                hasWash  = hasWash  or (n == tWash)
            end
            if hasWash or (hasDrink and hasFill) then
                table.insert(out, { sub = sub, top = top })
            end
        end
    end
    return out
end

-- Try to extract the actual water object referenced by this submenu.
-- 1) Prefer Drink/Fill/Refill (stable)
-- 2) Fallback: scan ANY option for a userdata param exposing getFluidAmount()
local function _getWaterObjectFromSubmenu(sub)
    if not sub or not sub.options then return nil end
    local tDrink  = getText("ContextMenu_Drink")  or "Drink"
    local tFill   = getText("ContextMenu_Fill")   or "Fill"
    local tRefill = getText("ContextMenu_Refill") or "Refill"

    -- Pass 1: look into Drink/Fill/Refill actions
    for _, ch in ipairs(sub.options) do
        if ch.name == tDrink or ch.name == tFill or ch.name == tRefill then
            for i = 1, 6 do
                local p = ch["param"..i]
                if p and type(p) == "userdata" and p.getFluidAmount and _isWaterObject(p) then
                    return p
                end
            end
        end
    end

    -- Pass 2 (fallback): scan every option for a water-capable userdata
	-- Fallback (only accept real water)
	for _, ch in ipairs(sub.options) do
		for i = 1, 6 do
			local p = ch["param"..i]
			if p and type(p)=="userdata" and p.getFluidAmount and _isWaterObject(p) then
				return p
			end
		end
	end
    return nil
end

-- Deep-clone a submenu tree from one context to another, fixing subOption mappings.
local function _cloneSubmenuTree(srcRoot, srcSub, dstRoot, dstSub)
    if not (srcRoot and srcSub and srcSub.options and dstRoot and dstSub) then
        if WS and WS.log then WS.log("clone: invalid args") end
        return
    end
    if WS and WS.log then WS.log("clone -> src items = " .. tostring(#srcSub.options)) end

    for _, child in ipairs(srcSub.options) do
        -- Recreate the option in the destination submenu.
        local newOpt = dstSub:addOption(child.name, child.target, child.onSelect,
                                        child.param1, child.param2, child.param3,
                                        child.param4, child.param5, child.param6)

        -- Copy presentation flags (icon, tooltip, notAvailable, itemForTexture)
        newOpt.iconTexture   = child.iconTexture
        newOpt.notAvailable  = child.notAvailable
        newOpt.toolTip       = child.toolTip
        newOpt.itemForTexture = child.itemForTexture

        if child.subOption then
            -- Source child submenu (lives under srcRoot's instance map)
            local srcChildSub = srcRoot:getSubMenu(child.subOption)
            if srcChildSub and srcChildSub.options and #srcChildSub.options > 0 then
                -- Create a NEW submenu under the destination root, attach to newOpt
                local newSub = ISContextMenu:getNew(dstRoot)
                dstRoot:addSubMenu(newOpt, newSub)
                if WS and WS.log then WS.log("clone -> created submenu for '" .. tostring(child.name) .. "'") end
                -- Recurse
                _cloneSubmenuTree(srcRoot, srcChildSub, dstRoot, newSub)
            end
        end
    end

    dstSub:calcHeight()
    dstSub:setWidth(dstSub:calcWidth())
end

-- Public helper used by compatibility shims (e.g., TABAS bathtubs) that have their own container submenu.
function WS.WMI_BuildWashMenu(targetMenu, worldobjects, playerObj, sink, closeCtx)
    -- targetMenu: ISContextMenu to receive the "Wash" option
    -- worldobjects: world objects array from context
    -- playerObj: IsoPlayer
    -- sink: water source IsoObject
    -- closeCtx: root context menu (used to close after wash-yourself)
    createWashSubmenu(targetMenu, worldobjects, playerObj, sink, closeCtx)
end

-- Replace vanilla "Wash" submenu contents IN-PLACE with the modded Wash submenu
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldobjects, test)
    if test then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    -- Enumerate ALL water submenus present in this context
    local entries = _iterWaterSubmenus(context)
    if #entries == 0 then
        if WS and WS.log then WS.log("no water submenus") end
        return
    end
	if WS and WS.log then WS.log("water submenus found=", #entries) end

    local processed = {} -- avoid double-injecting the same submenu table
    local tWash = _tr("ContextMenu_Wash")

    for _, e in ipairs(entries) do
        local waterSubMenu = e.sub
        local washOpt = findVanillaWashOption(waterSubMenu)
        if washOpt and washOpt.subOption then
            local washSub = getSubMenuFromOption(context, washOpt)
            if washSub and not processed[washSub] then
                -- Extract the right waterObject from THIS submenu
                local waterObject = _getWaterObjectFromSubmenu(waterSubMenu)
                if waterObject and _isWaterObject(waterObject) then
					if WS and WS.log then WS.log("[probe] amount=" .. tostring(waterObject:getFluidAmount())) end
					-- Build modded Wash in a TEMP context and deep-clone its children into the vanilla washSub
					local tmp = ISContextMenu:getNew(context)
					createWashSubmenu(tmp, worldobjects, playerObj, waterObject, context)

					-- Find the modded "Wash" we just built inside tmp and CLONE its children
					local modWashOpt = nil
					for _, opt in ipairs(tmp.options or {}) do
						if opt.name == tWash then modWashOpt = opt; break end
					end
					if modWashOpt and modWashOpt.subOption then
						local modWashSub = tmp:getSubMenu(modWashOpt.subOption)
						if modWashSub and modWashSub.options then
							--Before cloning, list the children names of the modWashSub
							if WS and WS.log then
								local names = {}
								for _,ch in ipairs(modWashSub.options or {}) do table.insert(names, ch.name) end
								WS.log("modWashSub children before cloning -> " .. table.concat(names, ", "))
							end
							-- Clear destination and rebuild in the REAL root context (context)
							washSub.options, washSub.numOptions = {}, 1
							--After cloning, list the children names of the modWashSub
							_cloneSubmenuTree(tmp, modWashSub, context, washSub)
							if WS and WS.log then
								local names = {}
								for _,ch in ipairs(modWashSub.options or {}) do table.insert(names, ch.name) end
								WS.log("modWashSub children after clearing (about to clone) -> " .. table.concat(names, ", "))
							end
							washOpt.iconTexture = getTexture("media/textures/Item_Bucket_Water.png")
							processed[washSub] = true
							if WS and WS.log then WS.log("injected Wash (deep-cloned) in one submenu") end
						end
					end
                end
            end
        end
    end
end)
