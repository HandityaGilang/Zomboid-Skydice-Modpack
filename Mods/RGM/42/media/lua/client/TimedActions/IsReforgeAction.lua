
require "TimedActions/ISBaseTimedAction"
RGMManager = RGMManager or {}

-- B42: getDrainableUsesInt throws RuntimeException (logged as error even in pcall).
-- getDrainableUses doesn't exist. Always use item count instead.
local function itemIsDrainable(_item)
    return false
end

local function isMagazineItem(item)
    return not instanceof(item, "HandWeapon")
        and not instanceof(item, "InventoryContainer")
        and not instanceof(item, "Clothing")
        and type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
        and type(item.getMaxAmmo) == "function" and (item:getMaxAmmo() or 0) > 0
end

local function isFlashlightItem(item)
    return type(item.getDisplayCategory) == "function"
        and item:getDisplayCategory() == "LightSource"
        and Modifiers.Flashlights ~= nil
end

local function isValidTinkeredItem(item)
    return instanceof(item, "HandWeapon")
        or instanceof(item, "InventoryContainer")
        or (instanceof(item, "Clothing") and not RGMManager.isJewelry(item))
        or isMagazineItem(item)
        or isFlashlightItem(item)
end

local RGM_TRAIT_MAP = {
    ["rgm:reforger"] = function() return RGM and RGM.CharacterTrait and RGM.CharacterTrait.TINKERER end,
    ["rgm:loodoman"] = function() return RGM and RGM.CharacterTrait and RGM.CharacterTrait.LOODOMAN end,
}

local function hasTraitSafe(player, traitName)
    local getObj = RGM_TRAIT_MAP[traitName]
    if getObj then
        local traitObj = getObj()
        if traitObj then
            local ok, result = pcall(function() return player:hasTrait(traitObj) end)
            return ok and result or false
        end
    end
    local ok, result = pcall(function() return player:HasTrait(traitName) end)
    return ok and result or false
end

-- Apply Loodoman gambler effect: 7.77% legendary, 77.77% bad (checked in that order)
-- Uses getRandomModifier with biased tweaker so sandbox rarity settings still apply
local function applyLoodomanEffect(newModifier, modList, item, rarityTweaker)
    if not modList then return newModifier end
    local roll = ZombRand(10000)
    if roll < 777 then  -- 7.77% legendary
        return RGMManager.getRandomModifier(item, modList, rarityTweaker * 0.05)
    elseif roll < 8554 then  -- 77.77% bad
        return RGMManager.getRandomModifier(item, modList, rarityTweaker * 8.0)
    end
    return newModifier
end

local function colorMatch(a, b)
    if not a or not b then return false end
    if a == b then return true end
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

-- B42: addText(char, text, color) removed; use addBadText / addGoodText / addText(char, text)
local function showHaloText(character, item, fontColor)
    if not item or not fontColor then return end
    if colorMatch(fontColor, RarityColors.bad) or colorMatch(fontColor, RarityColors.shitty) then
        pcall(function() HaloTextHelper.addBadText(character, item:getName()) end)
    elseif colorMatch(fontColor, RarityColors.legendary) or colorMatch(fontColor, RarityColors.insane)
        or colorMatch(fontColor, RarityColors.epic) or colorMatch(fontColor, RarityColors.great)
        or colorMatch(fontColor, RarityColors.rare) then
        pcall(function() HaloTextHelper.addGoodText(character, item:getName()) end)
    else
        pcall(function() HaloTextHelper.addText(character, item:getName()) end)
    end
end

ISReforgeAction = ISBaseTimedAction:derive("ISReforgeAction")

function ISReforgeAction:isValid()
	local characterInventory = self.character:getInventory()
	local tinkeringItemType = self.tinkeringItem:getType()
	local tinkerCost = SandboxVars.RGM.TinkerCost
	if TinkerItemQuantityNecessary[tinkeringItemType] then
		tinkerCost = TinkerItemQuantityNecessary[tinkeringItemType]*tinkerCost
	end
	local hasEnough = RGM_isLeatherworkItem(tinkeringItemType)
		and RGM_countLeatherUses(characterInventory) >= tinkerCost
		or RGM_countItemUses(characterInventory, tinkeringItemType) >= tinkerCost
	return characterInventory:contains(self.tinkeredItem)
		and hasEnough
		and isValidTinkeredItem(self.tinkeredItem)
		and (RGM_playerHasTinkerKnowledge(self.character)
			or (self.character:getPerkLevel(Perks.Tinkering) > 2 and self.character:getPerkLevel(Perks.Maintenance) > 2)
			or hasTraitSafe(self.character, "rgm:loodoman")
			or hasTraitSafe(self.character, "rgm:reforger"))
end

function ISReforgeAction:start()
    self:setActionAnim(CharacterActionAnims.Craft)
end

function ISReforgeAction:stop()
	ISBaseTimedAction.stop(self)
end

-- Determine item category and sub-type for the roll
local function getItemArgs(tinkeredItem)
    local isWeapon = instanceof(tinkeredItem, "HandWeapon")
    if isWeapon then
        return { itemCategory = "weapon", isRanged = tinkeredItem:isRanged() }
    elseif instanceof(tinkeredItem, "InventoryContainer") then
        return { itemCategory = "container" }
    elseif instanceof(tinkeredItem, "Clothing") and not RGMManager.isJewelry(tinkeredItem) then
        local bodyLoc = type(tinkeredItem.getBodyLocation) == "function" and tinkeredItem:getBodyLocation() or nil
        local bodyLocStr = bodyLoc and tostring(bodyLoc) or ""
        local isShoe = bodyLocStr == "Shoes"
            or bodyLocStr:lower():find("shoe") ~= nil
            or bodyLocStr:lower():find("boot") ~= nil
        return { itemCategory = "clothing", isShoe = isShoe }
    elseif isMagazineItem(tinkeredItem) then
        return { itemCategory = "magazine" }
    elseif isFlashlightItem(tinkeredItem) then
        return { itemCategory = "flashlight" }
    end
    return nil
end

local function consumeMaterials(character, tinkeringItem)
    local tinkeringItemType = tinkeringItem:getType()
    local tinkerCost = SandboxVars.RGM.TinkerCost
    local cost = TinkerItemQuantityNecessary[tinkeringItemType] and TinkerItemQuantityNecessary[tinkeringItemType]*tinkerCost or tinkerCost

    local chanceToNotConsumeItem = character:getPerkLevel(Perks.Tinkering) * 3
    if hasTraitSafe(character, "rgm:reforger") or hasTraitSafe(character, "rgm:loodoman") then
        chanceToNotConsumeItem = chanceToNotConsumeItem + 20
    end

    if ZombRand(1000) > chanceToNotConsumeItem * 10 then
        character:removeFromHands(tinkeringItem)
        if RGM_isLeatherworkItem(tinkeringItemType) then
            RGM_consumeLeatherUses(character:getInventory(), cost)
        else
            RGM_consumeItemUses(character:getInventory(), tinkeringItemType, cost)
        end
    end
end

function ISReforgeAction:perform()
    local itemArgs = getItemArgs(self.tinkeredItem)
    if not itemArgs then
        ISBaseTimedAction.perform(self)
        return
    end

    if isClient() or not RGMManager.getRandomModifier then
        -- MP: server does the roll AND consumes materials server-side (authoritative inventory)
        itemArgs.itemId            = self.tinkeredItem:getID()
        itemArgs.hasLoodoman       = hasTraitSafe(self.character, "rgm:loodoman")
        itemArgs.hasReforger       = hasTraitSafe(self.character, "rgm:reforger")
        itemArgs.hasTinkerer       = itemArgs.hasReforger or itemArgs.hasLoodoman
        itemArgs.tinkeringItemType = self.tinkeringItem:getType()
        print("[RGM] CLIENT Reforge: sending request to server, item=" .. tostring(self.tinkeredItem:getDisplayName()) .. " id=" .. tostring(itemArgs.itemId) .. " category=" .. tostring(itemArgs.itemCategory))
        sendClientCommand(self.character, "RGM", "Reforge", itemArgs)
    else
        -- SP: consume and roll locally
        consumeMaterials(self.character, self.tinkeringItem)
        print("[RGM] SP Reforge: rolling locally, item=" .. tostring(self.tinkeredItem:getDisplayName()) .. " category=" .. tostring(itemArgs.itemCategory))
        local rarityTweaker = (itemArgs.itemCategory == "weapon")
            and RGMManager.getRarityTweakerForPlayer(self.character, self.tinkeredItem)
            or 1
        if itemArgs.itemCategory == "weapon" and (hasTraitSafe(self.character, "rgm:reforger") or hasTraitSafe(self.character, "rgm:loodoman")) then
            rarityTweaker = rarityTweaker - 0.07
        end

        local newModifier, usedModList
        if itemArgs.itemCategory == "weapon" then
            usedModList = itemArgs.isRanged and Modifiers.Ranged or Modifiers.Melee
            newModifier = RGMManager.getRandomModifier(self.tinkeredItem, usedModList, rarityTweaker)
        elseif itemArgs.itemCategory == "container" and Modifiers.Containers then
            usedModList = Modifiers.Containers
            newModifier = RGMManager.getRandomModifier(self.tinkeredItem, usedModList, rarityTweaker)
        elseif itemArgs.itemCategory == "clothing" then
            if itemArgs.isShoe and Modifiers.Footwear then
                usedModList = Modifiers.Footwear
            elseif not itemArgs.isShoe and Modifiers.Clothing then
                usedModList = Modifiers.Clothing
            end
            if usedModList then
                newModifier = RGMManager.getRandomModifier(self.tinkeredItem, usedModList, rarityTweaker)
            end
        elseif itemArgs.itemCategory == "magazine" and Modifiers.Magazine then
            usedModList = Modifiers.Magazine
            newModifier = RGMManager.getRandomModifier(self.tinkeredItem, usedModList, rarityTweaker)
        elseif itemArgs.itemCategory == "flashlight" and Modifiers.Flashlights then
            usedModList = Modifiers.Flashlights
            newModifier = RGMManager.getRandomModifier(self.tinkeredItem, usedModList, rarityTweaker)
        end

        if not newModifier then
            ISBaseTimedAction.perform(self)
            return
        end

        if hasTraitSafe(self.character, "rgm:loodoman") then
            newModifier = applyLoodomanEffect(newModifier, usedModList, self.tinkeredItem, rarityTweaker)
        end

        RGMManager.awardTinkeringXP(self.character, newModifier, 1)
        self.tinkeredItem:getModData().modifier = newModifier

        if itemArgs.itemCategory == "weapon" then
            RGMManager.applyModifierStatsToItem(self.tinkeredItem, newModifier)
        elseif itemArgs.itemCategory == "container" then
            RGMManager.applyContainerStats(self.tinkeredItem)
        elseif itemArgs.itemCategory == "clothing" then
            RGMManager.applyClothingStats(self.tinkeredItem)
        elseif itemArgs.itemCategory == "magazine" then
            RGMManager.applyMagazineStats(self.tinkeredItem)
        elseif itemArgs.itemCategory == "flashlight" then
            RGMManager.applyFlashlightStats(self.tinkeredItem)
        end

        if SandboxVars.RGM.DynamicTinkerer and not hasTraitSafe(self.character, "rgm:reforger") then
            if RarityColors.epic and newModifier.fontColor == RarityColors.epic
                or RarityColors.insane and newModifier.fontColor == RarityColors.insane
                or RarityColors.legendary and newModifier.fontColor == RarityColors.legendary
                or RarityColors.rare and newModifier.fontColor == RarityColors.rare then
                local n = self.character:getModData().itemsTinkered
                self.character:getModData().itemsTinkered = n and n + 1 or 1
            end
            if self.character:getPerkLevel(Perks.Tinkering) + self.character:getPerkLevel(Perks.Maintenance) >= 8 then
                if self.character:getModData().itemsTinkered and self.character:getModData().itemsTinkered >= 15 then
                    pcall(function() self.character:getTraits():add(RGM.CharacterTrait.TINKERER) end)
                    self.character:getModData().itemsTinkered = nil
                end
            end
        end

        showHaloText(self.character, self.tinkeredItem, newModifier.fontColor)
    end

    ISBaseTimedAction.perform(self)
end

-- Shared apply logic for both ReforgeResult and ItemModifierAssigned
local function applyModifierFromServerCommand(args)
    if not args or not args.itemId then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    local inv = player:getInventory()
    if not inv then return end
    local item = (type(inv.getItemById) == "function" and inv:getItemById(args.itemId))
              or (type(inv.getItemFromID) == "function" and inv:getItemFromID(args.itemId))
    if not item then
        print("[RGM] CLIENT: item " .. tostring(args.itemId) .. " not found")
        return
    end

    -- Update modData immediately so checkItem sees the new modifier (no revert)
    if args.modifier then
        item:getModData().modifier = args.modifier
        item:getModData().modifierChecked = true
    end

    -- Apply stats + localized name on the client
    local modifier = item:getModData() and item:getModData().modifier
    if modifier then
        if instanceof(item, "HandWeapon") then
            pcall(function() RGMManager.applyModifierStatsToItem(item, modifier) end)
        elseif instanceof(item, "InventoryContainer") then
            pcall(function() RGMManager.applyContainerStats(item) end)
        elseif instanceof(item, "Clothing") and not RGMManager.isJewelry(item) then
            pcall(function() RGMManager.applyClothingStats(item) end)
        elseif type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
            and not instanceof(item, "HandWeapon") then
            pcall(function() RGMManager.applyMagazineStats(item) end)
        elseif type(item.getDisplayCategory) == "function"
            and item:getDisplayCategory() == "LightSource" then
            pcall(function() RGMManager.applyFlashlightStats(item) end)
        end
    end

    -- Mirror material consumption visually so drainable items (e.g. DuctTape) update
    -- without needing a full inventory re-sync. Server is authoritative; this is display only.
    if args.consumedItemType and args.consumedCost then
        if RGM_isLeatherworkItem(args.consumedItemType) then
            RGM_consumeLeatherUses(inv, args.consumedCost)
        else
            RGM_consumeItemUses(inv, args.consumedItemType, args.consumedCost)
        end
    end

    if args.colorCat == "red" then
        pcall(function() HaloTextHelper.addBadText(player, item:getName()) end)
    elseif args.colorCat == "green" then
        pcall(function() HaloTextHelper.addGoodText(player, item:getName()) end)
    else
        pcall(function() HaloTextHelper.addText(player, item:getName()) end)
    end

    print("[RGM] CLIENT applied: item=" .. tostring(item:getDisplayName()) .. " colorCat=" .. tostring(args.colorCat))
end

-- MP: server commands → client updates item data immediately
local function onServerCommand(module, command, args)
    if module ~= "RGM" then return end
    if command == "ReforgeResult" then
        print("[RGM] CLIENT ReforgeResult: modifier=" .. tostring(args and args.modifierName) .. " colorCat=" .. tostring(args and args.colorCat))
        applyModifierFromServerCommand(args)
    elseif command == "ItemModifierAssigned" then
        print("[RGM] CLIENT ItemModifierAssigned: item=" .. tostring(args and args.itemId) .. " colorCat=" .. tostring(args and args.colorCat))
        applyModifierFromServerCommand(args)
    end
end
Events.OnServerCommand.Add(onServerCommand)

function ISReforgeAction:new(character, tinkeredItem, tinkeringItem)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.tinkeredItem = tinkeredItem
	o.tinkeringItem = tinkeringItem
	o.stopOnWalk = true
	o.stopOnRun = true
	o.stopOnAim = false
    local isWeapon = instanceof(tinkeredItem, "HandWeapon")
	o.maxTime = math.floor(500 * (isWeapon and RGMManager.getRarityTweakerForPlayer(character, tinkeredItem) or 1))

	o.useProgressBar = true
	if o.character:isTimedActionInstant() then
		o.maxTime = 1;
	else
		local hasReforger = hasTraitSafe(o.character, "rgm:reforger")
		local hasLoodoman = hasTraitSafe(o.character, "rgm:loodoman")
		if hasReforger and hasLoodoman then
			o.maxTime = math.floor(o.maxTime / 6)
		elseif hasReforger or hasLoodoman then
			o.maxTime = math.floor(o.maxTime / 3)
		end
	end
	return o
end
