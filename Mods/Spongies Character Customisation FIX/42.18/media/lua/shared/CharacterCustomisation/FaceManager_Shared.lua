
	-- ----------------------------------------------------------------------
	-- -- functions for adding and removing customisation items ingame
	-- ----------------------------------------------------------------------

local FaceManager_Shared = {}

	-- -----------------------------------------
	-- -- UTILITY
	-- -----------------------------------------

function FaceManager_Shared.CreateItem(type, texture)

	-- local item = InventoryItemFactory.CreateItem(type) --b41
	local item = instanceItem(type) --b42

	FaceManager_Shared.SetItemTexture(item, texture)
	return item
end

function FaceManager_Shared.SetItemTexture(item, texture)
	if item == nil then return end
	if item:getVisual() == nil then return end
	item:getVisual():setBaseTexture(texture)
	item:getVisual():setTextureChoice(texture)
end

function FaceManager_Shared.GetMuscleLevel(level)
	if level == nil then return 0 end
	if level <= 5 then return 	0 end
	if level <= 8 then return 	1 end
	if level <= 10 then return 	2 end
	return 0
end

local function _safeVisualBlood(visual, part)
    if not visual then return 0 end

    local ok, value = pcall(function()
        return visual:getBlood(part)
    end)

    if not ok or value == nil then return 0 end
    return tonumber(value) or 0
end

local function _safeVisualDirt(visual, part)
    if not visual then return 0 end

    local ok, value = pcall(function()
        return visual:getDirt(part)
    end)

    if not ok or value == nil then return 0 end
    return tonumber(value) or 0
end

local function _getBodyPartIndex(part)
    if not part then return 0 end

    local ok, value = pcall(function()
        return part:index()
    end)

    if ok and value ~= nil then
        return tonumber(value) or 0
    end

    return 0
end

local function _readSnapshotValue(snapshot, bucketName, part)
    if type(snapshot) ~= "table" then return 0 end

    local bucket = snapshot[bucketName]
    if type(bucket) ~= "table" then return 0 end

    local index = _getBodyPartIndex(part)
    return tonumber(bucket[tostring(index)] or bucket[index] or 0) or 0
end

function FaceManager_Shared.BuildBloodAndDirtSnapshot(sourceVisual)
    local snapshot = {
        blood = {},
        dirt = {},
    }

    if not sourceVisual then return snapshot end
    if not BloodBodyPartType or not BloodBodyPartType.MAX then return snapshot end

    for index = 0, BloodBodyPartType.MAX:index() - 1 do
        local part = BloodBodyPartType.FromIndex(index)
        local key = tostring(index)

        snapshot.blood[key] = _safeVisualBlood(sourceVisual, part)
        snapshot.dirt[key] = _safeVisualDirt(sourceVisual, part)
    end

    return snapshot
end

function FaceManager_Shared.GetBloodAndDirtVisual(player, bodyVisualSnapshot)
    if type(bodyVisualSnapshot) == "table" then
        return {
            getBlood = function(_, part)
                return _readSnapshotValue(bodyVisualSnapshot, "blood", part)
            end,

            getDirt = function(_, part)
                return _readSnapshotValue(bodyVisualSnapshot, "dirt", part)
            end,
        }
    end

    if player and player.getHumanVisual then
        local humanVisual = player:getHumanVisual()
        if humanVisual then return humanVisual end
    end

    if player and player.getVisual then
        return player:getVisual()
    end

    return nil
end

local function _itemHasTag(item, tag)
    if not item or not tag or not item.hasTag then return false end

    local ok, value = pcall(function()
        return item:hasTag(tag)
    end)

    return ok and value == true
end

local function _itemUsesBodyLocation(item, bodyLocation)
    if not item or not bodyLocation or not item.getBodyLocation then return false end

    local ok, value = pcall(function()
        return item:getBodyLocation()
    end)

    return ok and value == bodyLocation
end

function FaceManager_Shared.IsBloodAndDirtSyncItem(item)
    if _itemHasTag(item, SPNCC.ItemTag.CanHaveBlood) then
        return true
    end

    -- Face overlays sit directly on the body and should follow the body's blood/dirt state.
    if _itemHasTag(item, SPNCC.ItemTag.Face) then
        return true
    end

    if _itemUsesBodyLocation(item, SPNCC.ItemBodyLocation.Face) then
        return true
    end

    if _itemUsesBodyLocation(item, SPNCC.ItemBodyLocation.Face_Model) then
        return true
    end

    return false
end

function FaceManager_Shared.SyncBloodOnNewItem(player, item)
    if not FaceManager_Shared.IsBloodAndDirtSyncItem(item) then return false end

    local itemVisual = item and item.getVisual and item:getVisual() or nil
    local sourceVisual = FaceManager_Shared.GetBloodAndDirtVisual(player)

    if not itemVisual or not sourceVisual then return false end

    local changed = FaceManager_Shared.AddBloodAndDirtToItem(itemVisual, sourceVisual)

    if changed then
        item:synchWithVisual()
    end

    return changed
end

function FaceManager_Shared.AddBloodAndDirtToBodyPart(item1, item2, part)
	local conditionChanged = false
	-- blood
	local item1Blood = item1:getBlood(part)
	local item2Blood = item2:getBlood(part)
	if item1Blood ~= item2Blood then
		item1:setBlood(part, item2Blood)
		conditionChanged = true
	end
	-- print(part)
	-- print(tostring(item1Blood) .. " | " .. tostring(item2Blood))
	-- print(tostring(item1:getBlood(part)) .. " | " .. tostring(item2:getBlood(part)))

	-- dirt
	local item1Dirt = item1:getDirt(part)
	local item2Dirt = item2:getDirt(part)
	if item1Dirt ~= item2Dirt then
		item1:setDirt(part, item2Dirt)
		conditionChanged = true
	end
	return conditionChanged
end

function FaceManager_Shared.AddBloodAndDirtToItem(item1, item2)
	local conditionChanged = false
	for i=1,BloodBodyPartType.MAX:index() do
		local part = BloodBodyPartType.FromIndex(i-1)
		if FaceManager_Shared.AddBloodAndDirtToBodyPart(item1, item2, part) then conditionChanged = true end
	end
	return conditionChanged
end



function FaceManager_Shared.OpenCharacterCustomisationWindow(player, hideCancelButton)
	local data = player:getModData().SPNCharCustom
	if not data then return nil end

	local CharCustomWindow = CharacterCustomisationPanel_Ingame:new()
	CharCustomWindow.hideCancelButton = hideCancelButton
	CharCustomWindow:initialise()
	CharCustomWindow:addToUIManager()

	CharCustomWindow:setX( (getCore():getScreenWidth()/2) - (CharCustomWindow:getWidth()/2) )
	CharCustomWindow:setY( (getCore():getScreenHeight()/2) - (CharCustomWindow:getHeight()/2) )
	
	CharCustomWindow:OpenMenu(player)

	--pause the game so the player doesnt get jumped by zombies
	if not isClient() and not isServer() and UIManager.getSpeedControls() then
		UIManager.getSpeedControls():SetCurrentGameSpeed(0)
		UIManager.setShowPausedMessage(false)
	end
	
	return CharCustomWindow
end


	-- -----------------------------------------
	-- -- GETTERS
	-- -----------------------------------------
function FaceManager_Shared.GetWornPlayerFace(player)
    for i=0, player:getWornItems():size()-1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item:hasTag(SPNCC.ItemTag.Face) then return item end
    end
    return nil
end
function FaceManager_Shared.GetWornItemsWithTag(player, tag)
	local items = {}
    for i=0, player:getWornItems():size()-1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item:hasTag(tag) then 
			table.insert(items, item) 
		end
    end
	return items
end
function FaceManager_Shared.GetWornBloodSyncItems(player)
    local items = {}

    if not player or not player.getWornItems then return items end

    local wornItems = player:getWornItems()
    if not wornItems then return items end

    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)

        if FaceManager_Shared.IsBloodAndDirtSyncItem(item) then
            table.insert(items, item)
        end
    end

    return items
end

function FaceManager_Shared.GetFirstWornItemWithTag(player, tag)
    for i=0, player:getWornItems():size()-1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item:hasTag(tag) then 
			return item
		end
    end
end
function FaceManager_Shared.GetWornItem(player, bodylocation)
    return player:getWornItem(bodylocation)
end
function FaceManager_Shared.GetWornItemWithTag(player, tag)
    for i=0, player:getWornItems():size()-1 do
        local item = player:getWornItems():getItemByIndex(i)
        if item:hasTag(tag) then return item end
    end
	return nil
end
function FaceManager_Shared.GetInventoryItemsWithTag(player, tag)
	local items = {}
	player:getInventory():getAllTagEval(tag, function(item) table.insert(items, item) end)
	return items
end


return FaceManager_Shared