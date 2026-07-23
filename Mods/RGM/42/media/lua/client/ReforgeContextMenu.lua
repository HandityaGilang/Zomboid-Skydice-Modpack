
RGMManager = RGMManager or {}
if RGMManager.ReforgeMenuLoaded then return end
RGMManager.ReforgeMenuLoaded = true

-- B42: FixingManager API changed; wrap calls defensively
local function getTinkeringItemFromFixes(player, item)
    if not FixingManager then return nil end

    local ok, fixingList = pcall(function() return FixingManager.getFixes(item) end)
    if not ok or not fixingList then return nil end

    local tinkerCost = SandboxVars.RGM.TinkerCost

    local ok2, size = pcall(function() return fixingList:size() end)
    if not ok2 then return nil end

    for i=0, size-1 do
        local fixing = fixingList:get(i)
        if not fixing then break end

        local fixers
        local ok3, _ = pcall(function() fixers = fixing:getFixers() end)
        if not ok3 or not fixers then break end

        for j=0, fixers:size()-1 do
            local fixer = fixers:get(j);
            if fixer then
                local fixerName
                local ok4, _ = pcall(function() fixerName = fixer:getFixerName() end)
                if ok4 and fixerName then
                    local fixerItems = player:getInventory():getItemsFromType(fixerName)
                    if fixerItems and fixerItems:size() > 0 then
                        for k=0, fixerItems:size()-1 do
                            local fixerItem = fixerItems:get(k)
                            local fixerItemType = fixerItem:getType()
                            if fixerItemType == item:getType() then break end
                            local itemCost = TinkerItemQuantityNecessary[fixerItemType] and TinkerItemQuantityNecessary[fixerItemType]*tinkerCost or tinkerCost
                            if RGM_countItemUses(player:getInventory(), fixerItemType) >= itemCost then
                                return fixerItem
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function getTinkeringItem(player, item)
    -- First try weapon-specific fixers
    local result = getTinkeringItemFromFixes(player, item)
    if result then return result end

    -- Fall back to generic tinkering consumables
    -- B42: drainable API throws RuntimeException; always use item count
    local tinkerCost = SandboxVars.RGM.TinkerCost
    for k, v in pairs(PossibleTinkeringItems) do
        local tinkeringItem = player:getInventory():getItemFromType(v)
        if tinkeringItem then
            local tinkeringItemType = tinkeringItem:getType()
            local itemCost = TinkerItemQuantityNecessary[tinkeringItemType] and TinkerItemQuantityNecessary[tinkeringItemType]*tinkerCost or tinkerCost
            if RGM_countItemUses(player:getInventory(), tinkeringItemType) >= itemCost then
                return tinkeringItem
            end
        end
    end
    return nil
end

-- Returns leather strips (clean or dirty) from player inventory if enough are available in total.
local function getLeatherworkItem(player)
    local tinkerCost = SandboxVars.RGM.TinkerCost
    local itemCost = (TinkerItemQuantityNecessary["LeatherStrips"] or 1) * tinkerCost
    local inv = player:getInventory()
    if RGM_countLeatherUses(inv) >= itemCost then
        for _, itemType in ipairs(LeatherworkTinkeringItems) do
            local item = inv:getItemFromType(itemType)
            if item then return item end
        end
    end
    return nil
end

ISInventoryPaneContextMenu.onReforge = function(playerObj, item, tinkeringItem)
    if tinkeringItem then
        ISInventoryPaneContextMenu.equipWeapon(item, true, false, playerObj:getPlayerNum())
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, tinkeringItem)
        ISTimedActionQueue.add(ISReforgeAction:new(playerObj, item, tinkeringItem));
    end
end

local function addReforgeOption(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    local item
    if items[1].items then
        item = items[1].items[1]
    else
        item = items[1]
    end

    local isBag = instanceof(item, "InventoryContainer")
    local function clothingHasStats(it)
        local hasScratch = type(it.getScratchDefense)      == "function" and (it:getScratchDefense()      or 0) > 0
        local hasBite    = type(it.getBiteDefense)         == "function" and (it:getBiteDefense()         or 0) > 0
        local hasBullet  = type(it.getBulletDefense)       == "function" and (it:getBulletDefense()       or 0) > 0
        local hasNoise   = type(it.getNoiseMod)            == "function" and (it:getNoiseMod()            or 1) ~= 1
        local hasSpeed   = type(it.getRunSpeedModifier)    == "function" and (it:getRunSpeedModifier()    or 1) ~= 1
        local hasCombat  = type(it.getCombatSpeedModifier) == "function" and (it:getCombatSpeedModifier() or 1) ~= 1
        local hasCond    = type(it.getConditionMax)        == "function" and (it:getConditionMax()        or 0) > 0
        return hasScratch or hasBite or hasBullet or hasNoise or hasSpeed or hasCombat or hasCond
    end
    local isClothing = not isBag and instanceof(item, "Clothing")
        and not RGMManager.isJewelry(item)
        and clothingHasStats(item)
    local isWeapon = instanceof(item, "HandWeapon")
    local isFlashlight = type(item.getDisplayCategory) == "function"
        and item:getDisplayCategory() == "LightSource"
        and Modifiers.Flashlights ~= nil
    local isMagazine = not isWeapon and not isBag and not isClothing and not isFlashlight
        and type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
        and type(item.getMaxAmmo) == "function" and (item:getMaxAmmo() or 0) > 0

    local tinkeringItem = nil
    local shouldShow = false

    if isFlashlight and SandboxVars.RGM.ItemsTinkerable then
        shouldShow = true
        tinkeringItem = getTinkeringItem(player, item)
    elseif isBag and SandboxVars.RGM.ItemsTinkerable and SandboxVars.RGM.ClothingModifiers then
        shouldShow = true
        tinkeringItem = getLeatherworkItem(player)
    elseif isClothing and SandboxVars.RGM.ItemsTinkerable and SandboxVars.RGM.ClothingModifiers then
        shouldShow = true
        tinkeringItem = getLeatherworkItem(player)
    elseif isMagazine and SandboxVars.RGM.ItemsTinkerable and Modifiers.Magazine then
        shouldShow = true
        tinkeringItem = getTinkeringItem(player, item)
    elseif isWeapon
        and (not SandboxVars.RGM.IgnoreIrrelevantWeapons or not RGMManager.IrrelevantWeapons[item:getScriptItem():getFullName()])
        and (not item:isRanged() or (SandboxVars.RGM.ItemsTinkerable and not getActivatedMods():contains("WeaponModifiersRealistic")))
    then
        shouldShow = true
        tinkeringItem = getTinkeringItem(player, item)
    end

    if shouldShow then
        local function hasTrait(traitObj)
            if not traitObj then return false end
            local ok, r = pcall(function() return player:hasTrait(traitObj) end)
            return ok and r or false
        end
        local hasRecipeOrSkill = RGM_playerHasTinkerKnowledge(player)
            or (player:getPerkLevel(Perks.Tinkering) > 2 and player:getPerkLevel(Perks.Maintenance) > 2)
            or (RGM and hasTrait(RGM.CharacterTrait and RGM.CharacterTrait.TINKERER))
            or (RGM and hasTrait(RGM.CharacterTrait and RGM.CharacterTrait.LOODOMAN))

        local tinkerOption
        if not tinkeringItem or not hasRecipeOrSkill then
            tinkerOption = context:addOption(getText("ContextMenu_Tinker"), player, ISInventoryPaneContextMenu.onReforge, item)
            tinkerOption.notAvailable = true
        else
            local tinkeringItemType = tinkeringItem:getType()
            local cost = TinkerItemQuantityNecessary[tinkeringItemType]
                and TinkerItemQuantityNecessary[tinkeringItemType] * SandboxVars.RGM.TinkerCost
                or SandboxVars.RGM.TinkerCost
            tinkerOption = context:addOption(getText("ContextMenu_TinkerWith").." "..cost.." "..tinkeringItem:getName(), player, ISInventoryPaneContextMenu.onReforge, item, tinkeringItem)
            tinkerOption.notAvailable = false
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addReforgeOption)
