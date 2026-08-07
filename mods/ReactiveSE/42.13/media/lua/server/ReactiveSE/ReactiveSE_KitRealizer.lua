--//////////////////////////////////////////////////--
--    Reactive Sound Events - Kit Realizer
--    Physically adds items to the zombie/world based on the Virtual Kit
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"
local SubKits = require "ReactiveSE/ReactiveSE_SubKits"
local CorpseSanitizer = require "ReactiveSE/ReactiveSE_CorpseSanitizer"

local ReactiveSE_KitRealizer = {}

--//////////////////////////////////////////////////--
--          Configuration                         --
--//////////////////////////////////////////////////--

-- Ammo configuration by scarcity (Enum index 1-4)
local AMMO_CONFIG = {
    [1] = { -- None
        clipChance = 0,
        clipFillPercent = 0,
        looseAmmoChance = 0,
        looseAmmoCountMin = 0,
        looseAmmoCountMax = 0
    },
    [2] = { -- Scarce
        clipChance = 0.2,
        clipFillPercent = 0.3,
        looseAmmoChance = 0.05,
        looseAmmoCountMin = 2,
        looseAmmoCountMax = 7
    },
    [3] = { -- Normal
        clipChance = 0.5,
        clipFillPercent = 0.6,
        looseAmmoChance = 0.15,
        looseAmmoCountMin = 3,
        looseAmmoCountMax = 11
    },
    [4] = { -- Abundant
        clipChance = 0.8,
        clipFillPercent = 0.9,
        looseAmmoChance = 0.35,
        looseAmmoCountMin = 5,
        looseAmmoCountMax = 13
    }
}

-- Mapping from Item AttachmentType to Body Location
local ATTACHMENT_MAP = {
    ["RIFLE"] = "Rifle On Back",
    ["HOLSTER"] = "Holster Right",
    ["HOLSTER_LEFT"] = "Holster Left",
    ["HOLSTER_RIGHT"] = "Holster Right",
    ["BIG_WEAPON"] = "Big Weapon On Back",
    ["KNIFE"] = "Belt Right",
    ["SMALL_BELT_RIGHT"] = "Belt Right",
    ["SMALL_BELT_LEFT"] = "Belt Left",
    ["BEDROLL"] = "Bedroll Bottom",
    ["GUITAR"] = "Guitar",
    ["GUITAR_ACOUSTIC"] = "Guitar Acoustic",
    ["PAN"] = "Pan On Back",
    ["SAUCEPAN"] = "Saucepan Back",
    ["RACKET"] = "Racket On Back",
    ["SHOVEL"] = "Shovel Back",
    ["BIG_BLADE"] = "Blade On Back",
    ["NIGHTSTICK"] = "Nightstick Right"
}

-- Mapping from Backpack Item Type to ItemBodyLocation
local BACKPACK_LOCATION_MAP = {
    ["Base.Bag_Satchel"] = ItemBodyLocation.SATCHEL,
    ["Base.Bag_Satchel_Leather"] = ItemBodyLocation.SATCHEL,
    ["Base.Bag_Satchel_Medical"] = ItemBodyLocation.SATCHEL,
    ["Base.Bag_Satchel_Military"] = ItemBodyLocation.SATCHEL,
    ["Base.Bag_Schoolbag"] = ItemBodyLocation.BACK,
    ["Base.Bag_DuffelBag"] = ItemBodyLocation.BACK,
    ["Base.Bag_NormalHikingBag"] = ItemBodyLocation.BACK,
    ["Base.Bag_BigHikingBag"] = ItemBodyLocation.BACK,
    ["Base.Bag_ALICEpack"] = ItemBodyLocation.BACK,
    ["Base.Bag_Military"] = ItemBodyLocation.BACK,
    ["Base.Bag_ALICEpack_Army"] = ItemBodyLocation.BACK,
    ["Base.Bag_ALICEpack_DesertCamo"] = ItemBodyLocation.BACK
}

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Resolves the best body location for an item based on its AttachmentType
---@param item InventoryItem
---@param defaultLoc string
---@return string location
local function getAttachmentLocation(item, defaultLoc)
    if not item then return defaultLoc end

    local attType = item:getAttachmentType()
    if attType then
        local key = tostring(attType)
        if ATTACHMENT_MAP[key] then
            Utils.LogInfo("  [KitRealizer] AttachmentType: " .. key .. " -> " .. ATTACHMENT_MAP[key])
            return ATTACHMENT_MAP[key]
        end
    end

    return defaultLoc
end

---Spawns ammo for a weapon based on scarcity settings
---@param container ItemContainer
---@param weapon InventoryItem|HandWeapon
---@param scarcityIndex number
local function spawnWeaponAmmo(container, weapon, scarcityIndex)
    if not container or not weapon or not instanceof(weapon, "HandWeapon") then return end
    if not weapon:isRanged() then return end

    local config = AMMO_CONFIG[scarcityIndex] or AMMO_CONFIG[2] -- Default to Scarce
    local ammoType = weapon:getAmmoType()

    if not ammoType then return end

    -- 1. Handle Clip/Magazine content
    local clipChance = config.clipChance * 100
    if ZombRand(100) < clipChance then
        local maxAmmo = weapon:getMaxAmmo()
        local clipFillPercent = config.clipFillPercent
        local fillAmount = Utils.Floor(maxAmmo * clipFillPercent)

        if weapon:getMagazineType() then
            local magType = weapon:getMagazineType()
            local mag = Utils.SafeAddItem(container, magType)
            if mag then
                mag:setCurrentAmmoCount(fillAmount)
            end
        else
            weapon:setCurrentAmmoCount(fillAmount)
        end
    else
        -- Empty gun
        weapon:setCurrentAmmoCount(0)
    end

    -- 2. Loose Ammo
    local looseAmmoChance = config.looseAmmoChance
    if ZombRand(100) < (looseAmmoChance * 100) then
        local ammoTypeStr = ammoType:toString()
        local minCount = config.looseAmmoCountMin
        local maxCount = config.looseAmmoCountMax + 1
        local count = ZombRand(minCount, maxCount)
        container:AddItems(ammoTypeStr, count)
        Utils.LogInfo("  [KitRealizer] Top-up: " .. count .. " loose rounds of " .. ammoTypeStr)
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Helper to visually equip an item on an entity (Zombie or Corpse)
---@param deadBody IsoDeadBody
---@param location ItemBodyLocation
---@param item InventoryItem
local function equipOnEntity(deadBody, location, item)
    if not deadBody or not item then return end

    local wornItems = deadBody:getWornItems()
    Utils.LogInfo("  [KitRealizer] WornItems: " .. tostring(wornItems))
    if wornItems then
        wornItems:setItem(location, item)
        Utils.LogInfo("  [KitRealizer] Equipped item: " .. tostring(item) .. " at " .. tostring(location))
    end
end

---Helper to visually attach an item on an IsoDeadBody
---@param deadBody IsoDeadBody
---@param location string
---@param item InventoryItem
local function attachOnEntity(deadBody, location, item)
    if not deadBody or not item then return end

    local attachedItems = deadBody:getAttachedItems()
    Utils.LogInfo("  [KitRealizer] AttachedItems: " .. tostring(attachedItems))
    if attachedItems then
        attachedItems:setItem(location, item)
        Utils.LogInfo("  [KitRealizer] Attached item: " .. tostring(item) .. " at " .. tostring(location))
    end
end

---Takes a processed VirtualKit and spawns items on the IsoDeadBody
---@param deadBody IsoDeadBody
---@param virtualKit table
---@param settings table
function ReactiveSE_KitRealizer.Realize(deadBody, virtualKit, settings)
    if not deadBody then return end

    local inv = deadBody:getContainer()

    if not inv then
        Utils.LogInfo("  [KitRealizer] Error: No inventory/container found for deadBody.")
        return
    end

    -- 1. Backpack
    local backpackItem = nil
    if virtualKit.backpack then
        backpackItem = Utils.SafeAddItem(inv, virtualKit.backpack)
        if backpackItem then
            local targetLoc = BACKPACK_LOCATION_MAP[virtualKit.backpack] or ItemBodyLocation.BACK
            equipOnEntity(deadBody, targetLoc, backpackItem)
            Utils.LogInfo("  [KitRealizer] Equipped backpack: " .. virtualKit.backpack .. " at " .. tostring(targetLoc))
        end
    end

    -- Container for SubKits: Backpack if exists, else Inventory (Pockets)
    local subKitContainer
    if backpackItem then
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i) --[[@as InventoryItem|InventoryContainer]]
            Utils.LogInfo("  [KitRealizer] Checking item: " .. tostring(it:getFullType()))
            if instanceof(it, "InventoryContainer") then
                Utils.LogInfo("  [KitRealizer] Found container: " .. tostring(it:getFullType()))
                Utils.LogInfo("  [KitRealizer] Checking for match: " ..
                    tostring(backpackItem:getFullType()) .. " == " .. tostring(it:getFullType()))
                if it:getFullType() == backpackItem:getFullType() then
                    subKitContainer = it:getInventory()

                    CorpseSanitizer.ClearContainer(subKitContainer)

                    Utils.LogInfo("  [KitRealizer] SubKit Container set to BACKPACK internal inventory: " ..
                        tostring(it:getFullType()))
                    break
                end
            end
        end
    else
        subKitContainer = inv
    end

    -- 2. Primary Weapon (If not stolen/nil)
    if virtualKit.primaryWeapon then
        local item = Utils.SafeAddItem(inv, virtualKit.primaryWeapon)
        if item then
            local location = getAttachmentLocation(item, "Rifle On Back")
            attachOnEntity(deadBody, location, item)

            local scarcity = settings.ammoScarcity or 2
            spawnWeaponAmmo(inv, item, scarcity)

            -- Apply WorldTier Condition Modifier
            local tier = WorldTier.GetWorldTier()
            local mod = WorldTier.GetModifiers(tier)
            local condPer = ZombRandFloat(0.1, mod.weaponConditionMod or 1.0)
            local condition = item:getConditionMax() * condPer
            item:setCondition(Utils.Floor(condition))
            Utils.LogInfo("  [KitRealizer] Added Primary: " ..
                virtualKit.primaryWeapon .. " (Cond: " .. string.format("%.2f", condPer) .. ")")
        end
    end

    -- 3. Sidearm
    if virtualKit.sidearm then
        local item = Utils.SafeAddItem(inv, virtualKit.sidearm)
        if item then
            local location = getAttachmentLocation(item, "Belt Left")
            attachOnEntity(deadBody, location, item)

            local scarcity = settings.ammoScarcity or 2
            spawnWeaponAmmo(inv, item, scarcity)

            -- Apply WorldTier Condition Modifier
            local tier = WorldTier.GetWorldTier()
            local mod = WorldTier.GetModifiers(tier)
            local condPer = ZombRandFloat(0.1, mod.weaponConditionMod or 1.0)
            local condition = item:getConditionMax() * condPer
            item:setCondition(Utils.Floor(condition))
            Utils.LogInfo("  [KitRealizer] Added Sidearm: " ..
                virtualKit.sidearm .. " (Cond: " .. string.format("%.2f", condPer) .. ")")
        end
    end

    -- 4. Extras (Armor, Utils)
    for i = 1, #virtualKit.extraItems do
        local type = virtualKit.extraItems[i]
        local item = Utils.SafeAddItem(inv, type)
        -- Auto-equip clothing/armor/radio
        if item and (item:IsClothing() or instanceof(item, "Clothing")) then
            local loc = item:getBodyLocation()
            equipOnEntity(deadBody, loc, item)
        end
    end

    -- 5. SubKits
    for i = 1, #virtualKit.subKitItems do
        local type = virtualKit.subKitItems[i]
        local valid = true
        if not backpackItem then
            if not SubKits.IsPocketable(type) then
                valid = false
            end
        end

        if valid then
            local item = Utils.SafeAddItem(subKitContainer, type)

            -- Handle Water Filling
            if item and SubKits.GetCategory(type) == "Water" then
                if instanceof(item, "DrainableComboItem") then
                    local randomLevel = ZombRandFloat(0.0, 1.0)
                    item:setUseDelta(randomLevel)
                    Utils.LogInfo(string.format("  [KitRealizer] Water Filling: %s -> %.2f", type, randomLevel))
                end
            end
        end
    end
end

return ReactiveSE_KitRealizer
