require "TimedActions/ISInventoryTransferUtil"

SkateboardMenu ={};
SkateboardMenu.typesTable = {"Skateboard"}
SkateboardEquipping = false

local function SkateboardMenu_isSkateboardType(typeString)
    return typeString and string.find(typeString, "^Skateboard")
end

function SkateboardMenu.isSkateboardItem(item)
    return item ~= nil and SkateboardMenu_isSkateboardType(item:getType())
end

local function SkateboardMenu_hasSkateboardInteractionTarget(pzPlayer)
    if not pzPlayer then
        return false
    end

    local currentItem = pzPlayer:getPrimaryHandItem()
    if currentItem and currentItem.isEquipped and not currentItem:isEquipped() then
        currentItem = nil
    end

    if SkateboardMenu.isSkateboardItem(currentItem) then
        return true
    end

    local sq = pzPlayer:getSquare()
    if not sq then
        return false
    end

    local items = SkateboardMenu.getItems(sq)
    for _, worldObj in ipairs(items) do
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if SkateboardMenu.isSkateboardItem(item) then
                return true
            end
        end
    end

    return false
end

local function SkateboardMenu_queueTransfer(pzPlayer, inventoryItem, destContainer)
    if not (pzPlayer and inventoryItem and destContainer) then
        return false
    end

    local srcContainer = inventoryItem:getContainer()
    if not srcContainer or srcContainer == destContainer then
        return false
    end

    if ISInventoryTransferUtil and ISInventoryTransferUtil.newInventoryTransferAction then
        local action = ISInventoryTransferUtil.newInventoryTransferAction(pzPlayer, inventoryItem, srcContainer, destContainer)
        if action then
            action.maxTime = 0
            action.useProgressBar = false
            action.stopOnWalk = false
            action.stopOnRun = false
            ISTimedActionQueue.add(action)
            return true
        end
    end

    return false
end

local function SkateboardMenu_anyPlayerHasSkateboardEquipped()
    local playerCount = getNumActivePlayers and getNumActivePlayers() or 1

    if not playerCount or playerCount <= 0 then
        local playerObj = getSpecificPlayer(0)
        return playerObj and SkateboardMenu.isSkateboardItem(playerObj:getPrimaryHandItem()) or false
    end

    for playerIndex = 0, playerCount - 1 do
        local playerObj = getSpecificPlayer(playerIndex)
        if playerObj and SkateboardMenu.isSkateboardItem(playerObj:getPrimaryHandItem()) then
            return true
        end
    end

    return false
end

local function SkateboardMenu_removeSkateboardEventsIfUnused()
    if not SkateboardMenu_anyPlayerHasSkateboardEquipped() then
        Events.OnPlayerUpdate.Remove(UpdateSkateboardFlag)
        Events.OnPlayerUpdate.Remove(UpdateSkateboardAudio)
    end
end

function SkateboardMenu.resetPlayerState(pzPlayer, options)
    if not pzPlayer then return end

    SkateboardEquipping = false

    pzPlayer:setVariable("SkateboardHeld", false)
    pzPlayer:setVariable("SkateboardActive", false)
    pzPlayer:setVariable("SkateboardRolling", false)
    pzPlayer:setVariable("SkateboardRollingTimestamp", "0")
    pzPlayer:setVariable("SkateboardToHandPlayed", "false")
    pzPlayer:setVariable("IdleToAimPlaying", false)
    pzPlayer:setVariable("SkateboardWalkSpeed", 1.0)
    pzPlayer:setVariable("SkateboardRunSpeed", 1.0)
    pzPlayer:setVariable("SkateboardSpeed", 1.0)
    pzPlayer:setIgnoreAutoVault(false)

    local emitter = pzPlayer:getEmitter()
    if emitter then
        if emitter:isPlaying('SkateboardRolling') then
            emitter:stopSoundByName('SkateboardRolling')
        end
        if emitter:isPlaying('SkateboardToHand') then
            emitter:stopSoundByName('SkateboardToHand')
        end
    end

    if not (options and options.preserveBlock) then
        pzPlayer:setBlockMovement(false)
    end

    SkateboardMenu_removeSkateboardEventsIfUnused()
end

local function SkateboardMenu_shouldCleanupPlayer(pzPlayer)
    if not pzPlayer then return false end

    local hasSkateboardEquipped = SkateboardMenu.isSkateboardItem(pzPlayer:getPrimaryHandItem())
    if SkateboardEquipping then
        return false
    end
    if hasSkateboardEquipped then
        return false
    end

    if pzPlayer:getVariableBoolean("SkateboardActive") then
        return true
    end

    if pzPlayer:getVariableBoolean("SkateboardHeld") then
        return true
    end

    if pzPlayer:isIgnoreAutoVault() then
        return true
    end

    return false
end

function SkateboardMenu.failSafeCleanup(player)
    if SkateboardMenu_shouldCleanupPlayer(player) then
        SkateboardMenu.resetPlayerState(player)
    end
end

local function SkateboardMenu_getInventoryItem(rawItem)
    if instanceof(rawItem, "InventoryItem") then
        return rawItem
    end
    if rawItem and rawItem.getItem then
        return rawItem:getItem()
    end
    return nil
end

local function SkateboardMenu_dropInstant(pzPlayer, rawItem)
    local inventoryItem = SkateboardMenu_getInventoryItem(rawItem)
    if not pzPlayer or not inventoryItem then
        return false
    end

    if not SkateboardMenu.isSkateboardItem(inventoryItem) then
        return false
    end

    local queue = ISTimedActionQueue.getTimedActionQueue(pzPlayer)
    if queue then
        queue:clearQueue()
    end

    inventoryItem:setJobDelta(0)
    inventoryItem:setJobType(nil)

    local hotbar = getPlayerHotbar and getPlayerHotbar(pzPlayer:getPlayerNum()) or nil
    if hotbar and hotbar:isItemAttached(inventoryItem) then
        hotbar:removeItem(inventoryItem, true)
    end

    pzPlayer:removeWornItem(inventoryItem)
    if pzPlayer:getPrimaryHandItem() == inventoryItem or pzPlayer:getSecondaryHandItem() == inventoryItem then
        pzPlayer:removeFromHands(inventoryItem)
    end

    SkateboardMenu.resetPlayerState(pzPlayer, { preserveBlock = true })

    pzPlayer:setBlockMovement(true)
    TinyTimer(100, function()
        if pzPlayer then
            pzPlayer:setBlockMovement(false)
        end
    end)

    local floorContainer = ISInventoryPage and ISInventoryPage.floorContainer
        and ISInventoryPage.floorContainer[pzPlayer:getPlayerNum() + 1]
    if floorContainer then
        SkateboardMenu_queueTransfer(pzPlayer, inventoryItem, floorContainer)
    end

    ISInventoryPage.renderDirty = true

    return true
end

SkateboardMenu.dropSkateboard = function(worldobjects,items,player)
    local pzPlayer = getSpecificPlayer(player)
    if not pzPlayer then return end

    local handled = false
    local actualItems = items
    if ISInventoryPane and ISInventoryPane.getActualItems then
        actualItems = ISInventoryPane.getActualItems(items)
    end
    if type(actualItems) ~= "table" then
        actualItems = { actualItems }
    end
    for _, item in ipairs(actualItems) do
        if SkateboardMenu_dropInstant(pzPlayer, item) then
            handled = true
        end
    end

    if not handled then
        ISInventoryPaneContextMenu.onDropItems(items,player)
    end
end

SkateboardMenu.onKeyPressed = function(key)
	local E_KEY = Keyboard.KEY_E
	local H_KEY = Keyboard.KEY_H
	local Z_KEY = Keyboard.KEY_Z
	local pzPlayer = getSpecificPlayer(0)
	local options = PZAPI.ModOptions:getOptions("SkateboardMod")
	local OllieKeybind = options:getOption("SkateboardOllieButton"):getValue()
	local EquipKeybind = options:getOption("SkateboardEquipButton"):getValue()
	-- local emitter = pzPlayer:getEmitter()
	-- if emitter:isPlaying("SkateboardDropping") then
	-- 	emitter:stopSoundByName("SkateboardDropping")
	-- end
	if key == OllieKeybind and pzPlayer:getVariableBoolean("SkateboardActive") then
		ISTimedActionQueue.add(SkateboardTrickOllie:new(pzPlayer))
		return
	end
	-- if key == Z_KEY then
	-- 	pzPlayer:setNoClip(true)
	-- 	print("noClip: " ..tostring(pzPlayer:isNoClip()))
	-- end
	-- if key == H_KEY then
	-- 	pzPlayer:setNoClip(false)
	-- 	print("noClip: " ..tostring(pzPlayer:isNoClip()))
	-- end
	-- if key == H_KEY then
	-- 	local sound = emitter:playSound("SkateboardDropping")
	-- 	emitter:setVolume(sound, 0.10)
	-- 	-- local categories = GameSounds.getCategories()
	-- 	-- for i=1,categories:size() do
	-- 	-- 	print("category: " ..tostring(categories:get(i-1)))
	-- 	-- 	local category = categories:get(i-1)
	-- 	-- 	if category == "Skateboard" then
	-- 	-- 		local sounds = GameSounds.getSoundsInCategory(category)
	-- 	-- 		for i=1,sounds:size() do
	-- 	-- 			local gameSound = sounds:get(i-1)
	-- 	-- 			local volume = gameSound:getUserVolume()
	-- 	-- 			print("gameSound name: " ..tostring(gameSound:getName()))
	-- 	-- 			print("gameSound volume: " ..tostring(volume))
	-- 	-- 		end
	-- 	-- 	end
	-- 		-- local sounds = GameSounds.getSoundsInCategory(categories:get(i-1))
	-- 		-- for i=1,sounds:size() do
	-- 		-- 	local gameSound = sounds:get(i-1)
	-- 		-- 	local volume = gameSound:getUserVolume()
	-- 		-- 	print("gameSound name: " ..tostring(gameSound:getName()))
	-- 		-- 	print("gameSound category: " ..tostring(gameSound:getCategory()))
	-- 		-- end
	-- end
	if key ~= EquipKeybind then return end
    if not pzPlayer then return end
    if not SkateboardMenu_hasSkateboardInteractionTarget(pzPlayer) then
        return
    end
	local midSq = pzPlayer:getSquare()
    local squares = {}
    table.insert(squares,midSq)
    table.insert(squares,midSq:getN())
    table.insert(squares,midSq:getS())
    table.insert(squares,midSq:getE())
    table.insert(squares,midSq:getW())

    for i,sq in ipairs(squares) do
        local door = sq:getIsoDoor()
        if door then
            if door:getSquare() == midSq or door:isAdjacentToSquare(midSq) then
                return
            end
        end
    end
    local currentItem = pzPlayer:getPrimaryHandItem()
    if SkateboardMenu.isSkateboardItem(currentItem) then
        SkateboardMenu.dropSkateboard(nil, {currentItem}, 0)
    else
        local sq = pzPlayer:getSquare()
        local items = SkateboardMenu.getItems(sq)
        local closestSkateboard = nil
        local closestSkateboardDistance = 1000
        for i, worldObj in ipairs(items) do
            if instanceof(worldObj, "IsoWorldInventoryObject") then
                local item = worldObj:getItem()
                if SkateboardMenu.isSkateboardItem(item) then -- only unfolded version
                    local dist = SkateboardMenu.getDistance2D(worldObj:getWorldPosX(), worldObj:getWorldPosY(), sq:getX(), sq:getY())
                    if dist < closestSkateboardDistance then
                        closestSkateboard = worldObj
                        closestSkateboardDistance = dist
                    end
                end
            end
        end
        if closestSkateboard then
			SkateboardEquipping = true
			pzPlayer:setBlockMovement(true)
			TinyTimer(300, function()
				pzPlayer:setBlockMovement(false)
				SkateboardEquipping = false
			end)
            SkateboardMenu.equipSkateboard({closestSkateboard}, 0, closestSkateboard)
        end
    end
end

SkateboardMenu.addWorldContext = function(player, context, worldobjects, test)
	local pzPlayer = getSpecificPlayer(player)
        local current_weapon = pzPlayer:getPrimaryHandItem()
        if SkateboardMenu.isSkateboardItem(current_weapon) then
		context:addOption("Hop off skateboard",worldobjects,SkateboardMenu.dropSkateboard,{current_weapon},player)
		return
	end

	local origSq= worldobjects[1]:getSquare();
	local items = {}
	if instanceof(origSq, "IsoGridSquare") then
		items = SkateboardMenu.getItems(origSq)
		items = appendTables(items, SkateboardMenu.getItems(origSq:getN()))
		items = appendTables(items, SkateboardMenu.getItems(origSq:getS()))
		items = appendTables(items, SkateboardMenu.getItems(origSq:getW()))
		items = appendTables(items, SkateboardMenu.getItems(origSq:getE()))
	else
		return
	end

	local skateboards = {}
	local skateboardCount = 0
	local closestSkateboard = nil
	local closestSkateboardDistance = 1000
	for i,v in ipairs(items) do
		if instanceof(v, "IsoWorldInventoryObject") then
			 if instanceof (v:getItem(),"InventoryContainer") then
				local type = v:getItem():getItemContainer():getType()
				for ti,tv in ipairs(SkateboardMenu.typesTable) do
					if tv == type then
						table.insert(skateboards,v)
						skateboardCount = skateboardCount + 1
					end
				end
			end
		end
	end
	if skateboardCount > 0 then
		for i,v in ipairs(skateboards)do
			local distance = SkateboardMenu.getDistance2D(v:getWorldPosX(),v:getWorldPosY(),pzPlayer:getSquare():getX(),pzPlayer:getSquare():getY())
			if distance < closestSkateboardDistance then
				closestSkateboard = v
				closestSkateboardDistance = distance
			end
		end
		local label = "Hop on skateboard"
		local selectOption = context:addOption(label,worldobjects,SkateboardMenu.equipSkateboard,player,closestSkateboard)
	end
end

SkateboardMenu.hopOnSkateboard = function(worldobjects,player,item,container)
	local pzPlayer = getSpecificPlayer(player)
	local item_world = item:getWorldItem()

	if item_world then
		SkateboardMenu.equipSkateboard(worldobjects,player,item_world)
	else
		ISTimedActionQueue.add(ISEquipHeavyItem:new(pzPlayer, item, 4))
	end
end

SkateboardMenu.equipSkateboard = function(worldobjects, player, worldObj)
    local pzPlayer = getSpecificPlayer(player)
    if not pzPlayer or not worldObj then return end

    local sqP = pzPlayer:getSquare()
    local sqC = worldObj:getSquare()
    if not (sqP and sqC) then return end

    local sx, sy = sqC:getX(), sqC:getY()
    pzPlayer:faceLocation(sx, sy)

    local d = SkateboardMenu.getDistance2D(sqP:getX(), sqP:getY(), sx, sy)
    if d > 1.5 then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(pzPlayer, sqC))
    end

    -- 1) Transfer the world item into the player's inventory before equipping.
    local invItem = worldObj:getItem()
    if not invItem then return end
    if invItem:getContainer() ~= pzPlayer:getInventory() then
        SkateboardMenu_queueTransfer(pzPlayer, invItem, pzPlayer:getInventory())
    end

    -- 2) Equip in both hands; mark to bypass the hop-on injection.
    SkateboardEquipping = true
    ISTimedActionQueue.add(ISEquipWeaponAction:new(pzPlayer, invItem, 0, true, true))

    -- 3) Arm stance/audio on the next tick so hands are populated.
    TinyTimer(50, function()
        if pzPlayer then
            Events.OnPlayerUpdate.Add(UpdateSkateboardFlag)
            Events.OnPlayerUpdate.Add(UpdateSkateboardAudio)
        end
        SkateboardEquipping = false
    end)
end


SkateboardMenu.getItems = function(square)
	local items ={}
	local squares ={}
	if instanceof(square, "IsoGridSquare") == false then return items end
	table.insert(squares,square)
	table.insert(squares,square:getN())
	table.insert(squares,square:getS())
	table.insert(squares,square:getE())
	table.insert(squares,square:getW())
	for si,s in ipairs(squares) do
		for ii,i in ipairs(s:getLuaTileObjectList()) do
			table.insert(items,i)
		end
	end
	return items
end

local originalAttachItem = ISAttachItemHotbar.animEvent

function ISAttachItemHotbar:animEvent(event)
    if SkateboardMenu.isSkateboardItem(self.item) then
        self.character:setVariable("SkateboardHeld", true)
    end
    originalAttachItem(self, event)
end

local originalDetachItem = ISDetachItemHotbar.animEvent

function ISDetachItemHotbar:animEvent(event)
    if SkateboardMenu.isSkateboardItem(self.item) then
        SkateboardMenu.resetPlayerState(self.character)
        self.character:setVariable("SkateboardHeld", false)
    end
    originalDetachItem(self, event)
end

local originalEquipItem = ISEquipWeaponAction.start

local originalEquipWeaponActionNew = ISEquipWeaponAction.new

function ISEquipWeaponAction:new(character, item, maxTime, primary, twoHands)
    if SkateboardMenu and SkateboardMenu.isSkateboardItem and SkateboardMenu.isSkateboardItem(item) then
        local action = originalEquipWeaponActionNew(self, character, item, 0, primary, twoHands)
        action.maxTime = 0
        action.useProgressBar = false
        action.stopOnWalk = false
        action.stopOnRun = false
        return action
    end
    return originalEquipWeaponActionNew(self, character, item, maxTime, primary, twoHands)
end

function ISEquipWeaponAction:start()
    local pzPlayer = self.character
    if SkateboardMenu.isSkateboardItem(self.item) then
        if SkateboardEquipping == true then
            SkateboardEquipping = false
            originalEquipItem(self)
            return
        end
        ISTimedActionQueue.add(SkateboardHopOnAction:new(self.item, pzPlayer))
        Events.OnPlayerUpdate.Add(UpdateSkateboardFlag)
        Events.OnPlayerUpdate.Add(UpdateSkateboardAudio)
        return
    end
    originalEquipItem(self)
end

local originalUnequipItem = ISUnequipAction.start

function ISUnequipAction:start()
    if SkateboardMenu.isSkateboardItem(self.item) then
        SkateboardMenu.resetPlayerState(self.character)
    end
    originalUnequipItem(self)
end

local originalDropItem = ISInventoryPaneContextMenu.dropItem

function ISInventoryPaneContextMenu.dropItem(item, player)
    local pzPlayer = getSpecificPlayer(player)
    if SkateboardMenu_dropInstant(pzPlayer, item) then
        return
    end
    originalDropItem(item, player)
end

local originalUnequipItemContext = ISInventoryPaneContextMenu.unequipItem

function ISInventoryPaneContextMenu.unequipItem(item, player)
    local pzPlayer = getSpecificPlayer(player)
    if SkateboardMenu_dropInstant(pzPlayer, item) then
        return
    end
    originalUnequipItemContext(item, player)
end

local originalTransferAction = ISInventoryTransferAction.new

function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
	local newTime = time
    if SkateboardMenu.isSkateboardItem(item) then
        self.maxTime = 0
        newTime = 0
    end
	return originalTransferAction(self, character, item, srcContainer, destContainer, newTime)
end

SkateboardMenu.initSkateboard = function()
    local player = getSpecificPlayer(0)
    local options = PZAPI.ModOptions:getOptions("SkateboardMod")
    local speedMultSlow = options:getOption("SpeedMultSlow"):getValue()
    local speedMultFast = options:getOption("SpeedMultFast"):getValue()
    local primaryItem = player:getPrimaryHandItem()
    if not SkateboardMenu.isSkateboardItem(primaryItem) then
        SkateboardMenu.resetPlayerState(player)
        return
    end
    player:setVariable("SkateboardActive", true)
    player:setIgnoreAutoVault(true)
    player:setVariable("SkateboardHeld", true)
    Events.OnPlayerUpdate.Add(UpdateSkateboardFlag)
    Events.OnPlayerUpdate.Add(UpdateSkateboardAudio)
    player:setVariable("IdleToAimPlaying", false)
    player:setVariable("SkateboardWalkSpeed", speedMultSlow)
    player:setVariable("SkateboardRunSpeed", speedMultFast)
    player:setVariable("SkateboardRolling", false)
    player:setVariable("SkateboardRollingTimestamp", "0")
end

SkateboardMenu.getDistance2D = function(_x1, _y1, _x2, _y2)
	return math.sqrt(math.abs(_x2 - _x1)^2 + math.abs(_y2 - _y1)^2);
end

function appendTables(t1, t2)
    for _, value in ipairs(t2) do
        table.insert(t1, value)
    end
	return t1
end

Events.OnKeyPressed.Add(SkateboardMenu.onKeyPressed)
Events.OnFillWorldObjectContextMenu.Add(SkateboardMenu.addWorldContext)
Events.OnPreFillInventoryObjectContextMenu.Add(SkateboardMenu.addInventoryContext)
Events.OnGameStart.Add(SkateboardMenu.initSkateboard);
Events.OnGameStart.Add(UpdateSkateboardFlag);
Events.OnPlayerUpdate.Add(SkateboardMenu.failSafeCleanup)
