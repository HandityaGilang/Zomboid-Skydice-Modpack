--[[
local KittyEquipmentData = {}
KittyEquipmentData.ALLOWED_ITEMS = {

    head = {
        ["Base.Animal_CAT_FORCE_ONE_HAT"] = true,
        ["Base.Animal_CAT_FORCE_ONE_HELMET"] = true,
    },

    face = {
        ["Base.Animal_CAT_COLLAR"] = true,
        ["Base.Animal_CAT_BOWTIE"] = true,
        ["Base.PlaceholderFaceItem"] = true,
    },

    vest = {
        ["Base.Animal_CAT_FORCE_ONE_VEST"] = true,
    },

    backpack = {
        ["Base.CAT_FORCE_ONE_BACKPACK"] = true,
    },

    accessory = {
        ["Base.PlaceholderAccessoryItem"] = true,
    },

    fannypack = {
        ["Base.PlaceholderFannyPackItem"] = true,
    },

    paws = {
        ["Base.PlaceholderPawItem"] = true,
    },

    socks = {
        ["Base.PlaceholderSockItem"] = true,
    },
}

function KittyEquipmentData.isItemAllowedInSlot(item, slotID)
    if not item or not slotID then return false end

    local fullType = item:getFullType()
    local allowedItems = KittyEquipmentData.ALLOWED_ITEMS[slotID]
    if not allowedItems then
        return false
    end

    local isAllowed = allowedItems[fullType] == true

    return isAllowed
end

function KittyEquipmentData.getAllowedItemsForSlot(slotID)
    return KittyEquipmentData.ALLOWED_ITEMS[slotID] or {}
end

return KittyEquipmentData
--]]