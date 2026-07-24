require "ISHotbar"
require "TCMusicDefenitions"
require "RadioCom/ISTCBoomboxWindow"
require "RadioCom/SWTCPlayerWindow"

TCBoomboxHotbarHandler = {}
CustomHotbarHandler = {}
CustomHotbarHandler.openWindows = {}

local originalISHotbar_ActivateSlot = ISHotbar.activateSlot
local originalISHotbar_EquipItem = ISHotbar.equipItem

function ISHotbar:activateSlot(slotIndex)
    local item = self.attachedItems[slotIndex]
    if not item then return end

    if item:getAttachedSlot() ~= slotIndex then
        return
    end

    if CustomHotbarHandler.isCustomCDPlayer(item) then
        CustomHotbarHandler.handleCustomMusicPlayerActivation(item, self.chr, slotIndex)
        return
    end

    if TCBoomboxHotbarHandler.isCustomMusicPlayer(item) then
		return originalISHotbar_ActivateSlot(self, slotIndex)
    end
	
    originalISHotbar_ActivateSlot(self, slotIndex)
end

function ISHotbar:equipItem(item)
    return originalISHotbar_EquipItem(self, item)
end


function TCBoomboxHotbarHandler.isCustomMusicPlayer(item)
    return TCMusic.WalkmanPlayer[item:getFullType()]
end

function TCBoomboxHotbarHandler.isBoombox(item)
    return TCMusic.ItemMusicPlayer[item:getFullType()]
end

function CustomHotbarHandler.isCustomCDPlayer(item)
    if not CustomCDMusic or not CustomCDMusic.CustomDevices then return false end
    return CustomCDMusic.CustomDevices[item:getFullType()]
end

function CustomHotbarHandler.handleCustomMusicPlayerActivation(item, character, slotIndex)
    local itemId = tostring(item:getID())
    local itemType = item:getFullType()
    
    if item:isActivated() and not CustomHotbarHandler.openWindows[itemId] then
        item:setActivated(false)
    end

    local targetState = not item:isActivated()

    local function onOpen(character, item)
        local window = SWTCPlayerWindow.activate(character, item)
        CustomHotbarHandler.openWindows[itemId] = window
        local originalClose = window.close
        window.close = function(self)
            CustomHotbarHandler.openWindows[itemId] = nil
            originalClose(self)
        end
    end

    local function onClose(character, item)
        if CustomHotbarHandler.openWindows[itemId] then
            CustomHotbarHandler.openWindows[itemId]:close()
            CustomHotbarHandler.openWindows[itemId] = nil
        end
    end

    ISTimedActionQueue.add(
        ISMusicPlayerToggleAnimAction:new(
            character, item, targetState,
            targetState and onOpen or nil,
            (not targetState) and onClose or nil,
            slotIndex
        )
    )
end

if not getPlayer() then
    return
end

local player = getPlayer()
local primaryHand = player:getPrimaryHandItem()
local secondaryHand = player:getSecondaryHandItem()
local backItem = player:getClothingItem_Back()

local itemsToCheck = {primaryHand, secondaryHand, backItem}
for _, item in ipairs(itemsToCheck) do
    if item then
        local itemType = item:getType()
        if itemType == "CDplayer" or itemType == "TM_CDPlayer" then
            if not SWTCPlayerWindow.isActive(player, item) then
            end
        end
    end
end
