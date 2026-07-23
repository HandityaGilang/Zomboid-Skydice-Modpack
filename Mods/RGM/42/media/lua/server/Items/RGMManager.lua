RGMManager = RGMManager or {}
if RGMManager.ServerLoaded then return end
RGMManager.ServerLoaded = true

RGMManager.testMode = RGMManager.testMode or false

-- Collect all "xp <PerkName>" bonuses from worn items in one pass.
-- Returns a table {["xp Axe"]=0.3, ...} or false if no bonuses.
function RGMManager.getWornXpBonuses(player)
    local worn = player:getWornItems()
    local bonuses = false
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        local item  = entry and type(entry.getItem) == "function" and entry:getItem() or nil
        if item then
            local mod = item:getModData().modifier
            if mod and mod.statsMultipliers then
                for key, val in pairs(mod.statsMultipliers) do
                    if key:sub(1, 3) == "xp " then
                        if not bonuses then bonuses = {} end
                        bonuses[key] = (bonuses[key] or 0) + val
                    end
                end
            end
        end
    end
    return bonuses
end

-- TODO better modifier chances for special "zones".
-- TODO Tinkering Workshop item. (craftable at level 6 Maintenance & level 3 Metalworking)
-- TODO modifiers on cooking pans, overwriting the recipe

DefaultModifier = {
        modifierName = getText("Tooltip_modifier_standard"),
        statsMultipliers = {
            damage = 1,
            speed = 1,
            ["critical chance"] = 0,
            ["minimum range"] = 1,
            ["maximum range"] = 1,
            knockback = 1,
            ["endurance cost"] = 1, 
            ["durability"] = 1,
            weight = 1, -- custom weight doesn't work
            accuracy = 1,
            ["sound radius"] = 1,
            recoil = 1,
            ["reload time"] = 1,
            ["aim time"] = 1,
            experience = 1
        },
        fontColor = {1, 1, 1},
}
-- Ordered array: {rarity, chance%}. Order matters — cumulative sum goes best→worst.
-- Chances must add up to 100.
RGMManager.rarityChances = {
    {"legendary", 1},
    {"insane",    2},
    {"epic",      4},
    {"great",     8},
    {"good",     16},
    {"common",   40},
    {"bad",      25},
    {"shitty",    4},
}

RGMManager.IrrelevantWeapons = {
    ["Base.Pen"] = 1,
    ["Base.RedPen"] = 1,
    ["Base.BluePen"] = 1,
    ["Base.Pencil"] = 1,
    ["Base.Spoon"] = 1,
    ["Base.Fork"] = 1,
    ["Base.SmashedBottle"] = 1,
    ["Base.Plank"] = 1,
    ["Base.MetalBar"] = 1,
    ["Base.MetalPipe"] = 1,
    ["Base.FishingRod"] = 1,
    ["Base.FishingRodBreak"] = 1,
    ["Base.CraftedFishingRod"] = 1,
    ["Base.Pan"] = 1,
    ["Base.Saucepan"] = 1,
    ["Base.GridlePan"] = 1,

    -- explosives failsafe
    ["Base.Molotov"] = 1,
    ["Base.Aerosolbomb"] = 1,
    ["Base.AerosolbombTriggered"] = 1,
    ["Base.AerosolbombSensorV1"] = 1,
    ["Base.AerosolbombSensorV2"] = 1,
    ["Base.AerosolbombSensorV3"] = 1,
    ["Base.AerosolbombRemote"] = 1,
    ["Base.FlameTrap"] = 1,
    ["Base.FlameTrapTriggered"] = 1,
    ["Base.FlameTrapSensorV1"] = 1,
    ["Base.FlameTrapSensorV2"] = 1,
    ["Base.FlameTrapSensorV3"] = 1,
    ["Base.FlameTrapRemote"] = 1,
    ["Base.SmokeBomb"] = 1,
    ["Base.SmokeBombTriggered"] = 1,
    ["Base.SmokeBombSensorV1"] = 1,
    ["Base.SmokeBombSensorV2"] = 1,
    ["Base.SmokeBombSensorV3"] = 1,
    ["Base.SmokeBombRemote"] = 1,
    ["Base.NoiseTrap"] = 1,
    ["Base.NoiseTrapTriggered"] = 1,
    ["Base.NoiseTrapSensorV1"] = 1,
    ["Base.NoiseTrapSensorV2"] = 1,
    ["Base.NoiseTrapSensorV3"] = 1,
    ["Base.NoiseTrapRemote"] = 1,
    ["Base.Grenade"] = 1,

}

-- stats that stay changed even after quitting and reloading : damage, max range 

-- stats that need to be updated when reloading game : min range, attack speed, crit chance, knockback/knockdown, durability, endurance.

RGMManager.CurrentModifierChance = 10
RGMManager.CurrentRarityTweaker = 1


local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- function RGMManager.getRandomModifierRealistic(_item, _modifierList , rarityTweaker)
--     if _item:isRanged() then return DefaultModifier end
--     local chance = ZombRand(10000)
--     local itemCategory = nil
--     local testItemCategory  = nil
--     local itemCategories = _item:getCategories()
--     for i = 0, itemCategories:size()-1 do
--         testItemCategory = itemCategories:get(i)
--         if AcceptableCategories[testItemCategory] then 
--             itemCategory = testItemCategory
--         end
--     end
--     if not itemCategory or not _modifierList[itemCategory] then return DefaultModifier end
--     chance = chance * RGMManager.CurrentRarityTweaker * rarityTweaker
--     local rarityChances = RGMManager.rarityChances
--     local rarityChanceCumulated = 0
    
--     for rarity, rarityChance in pairs(rarityChances) do
--         rarityChanceCumulated = rarityChanceCumulated + rarityChance
--         if chance < rarityChanceCumulated*100 then
--             return _modifierList[itemCategory][rarity][ZombRand(1 , #_modifierList[itemCategory][rarity])]
--         end
--     end
--     return DefaultModifier
-- end

function RGMManager.getRandomModifier(_item, modifierList, rarityTweaker)
        local function filteredBucket(bucket)
            if not _item or not bucket then return bucket end
            local filtered = {}
            for _, mod in ipairs(bucket) do
                if not mod.filter or mod.filter(_item) then
                    table.insert(filtered, mod)
                end
            end
            return filtered
        end

        local chance = ZombRand(10000)
        chance = chance * RGMManager.CurrentRarityTweaker * rarityTweaker
        local rarityChances = RGMManager.rarityChances
        local rarityChanceCumulated = 0
        for _, entry in ipairs(rarityChances) do
            local rarity, rarityChance = entry[1], entry[2]
            rarityChanceCumulated = rarityChanceCumulated + rarityChance
            if chance < rarityChanceCumulated*100 then
                if RGMManager.testMode then print(round(chance, 2).." < "..rarityChanceCumulated.. " : Applying [ ".. rarity .." ] modifier.") end
                local bucket = filteredBucket(modifierList[rarity])
                if not bucket or #bucket == 0 then return DefaultModifier end
                return bucket[ZombRand(1, #bucket + 1)]
            end
        end
        local shitty = filteredBucket(modifierList.shitty)
        if shitty and #shitty > 0 then return shitty[ZombRand(1, #shitty + 1)] end
        local bad = filteredBucket(modifierList.bad)
        if bad and #bad > 0 then return bad[ZombRand(1, #bad + 1)] end
        return DefaultModifier
end

function RGMManager.changeWeaponModifiersFromContainer(_container, _containerObj)
    if not _container then return end
    local containerItems = type(_container.getItems) == "function" and _container:getItems() or nil
    if not containerItems then return end
    local sz = type(containerItems.size) == "function" and containerItems:size() or nil
    if not sz then return end
    for i = 0, sz - 1 do
        local item = containerItems:get(i)
        RGMManager.checkItem(item, _containerObj, 1, 1)
    end
end

function RGMManager.checkWeaponModifiersFromAllPossibleContainers(_containerObj)
    
    -- _containerObj:transmitModData();
    if _containerObj:getContainerCount() and _containerObj:getContainerCount() > 1 then
        for containerindex = 0, _containerObj:getContainerCount() do
            RGMManager.changeWeaponModifiersFromContainer(_containerObj:getContainerByIndex(containerindex), _containerObj);
        end
    else
        if _containerObj:getItemContainer() then
            RGMManager.changeWeaponModifiersFromContainer(_containerObj:getItemContainer(), _containerObj)
        else
            RGMManager.changeWeaponModifiersFromContainer(_containerObj:getContainer(), _containerObj)
        end
    end
end

function RGMManager.checkAllInventories(_iSInventoryPage)

    local containerObj;
    for i, v in ipairs(_iSInventoryPage.backpacks) do
        -- iso objects (chests, shelves, etc.)
		if v.inventory:getParent() then
			containerObj = v.inventory:getParent();
			if  instanceof(containerObj, "IsoObject")
                and (containerObj:getContainer() or containerObj:getItemContainer())
                then
                RGMManager.checkWeaponModifiersFromAllPossibleContainers(containerObj)
            end
        end
        -- Vehicle parts: gloveboxes, trunks, seats, etc.
        if v.inventory:getVehiclePart() then
            containerObj = v.inventory:getVehiclePart();
            if  instanceof(containerObj, "VehiclePart")
                and containerObj:getItemContainer()
                then
                RGMManager.changeWeaponModifiersFromContainer(containerObj:getItemContainer(), containerObj)
            end
        end
        -- Direct scan: player/character inventory (getParent() returns IsoPlayer which has
        -- no getContainer()/getItemContainer(), so the iso objects branch above misses it)
        if v.inventory and type(v.inventory.getItems) == "function" then
            RGMManager.changeWeaponModifiersFromContainer(v.inventory, nil)
        end
    end
end

local function checkWeaponModifiersOnRefreshEnd(_iSInventoryPage, _state)
    
    if _state == "end" then
        RGMManager.checkAllInventories(_iSInventoryPage);
    end
end

local function checkWeaponModifiersOnFill(roomtype, containertype, container)
    if not container or type(container) == "string" then return end
    if not instanceof(container, "IsoObject") then return end
    local explored = type(container.isExplored) == "function" and container:isExplored()
    local looted   = type(container.isHasBeenLooted) == "function" and container:isHasBeenLooted()
    if explored or looted then return end
    local parent = type(container.getParent) == "function" and container:getParent() or nil
    RGMManager.changeWeaponModifiersFromContainer(container, parent)
end


function RGMManager.updateModifierChance(...)
    RGMManager.testMode = isDebugEnabled and isDebugEnabled() or false
    local WMSandboxSettings = SandboxVars.RGM
    if not WMSandboxSettings then return end
    local startDay    = WMSandboxSettings.StartDay or 2
    local peakDay     = WMSandboxSettings.PeakDay or 60
    local gameTime    = GameTime and GameTime:getInstance()
    local worldAgeDays = gameTime and math.floor(gameTime:getWorldAgeHours()/24 + 0.5) or 1
    local originalChance = WMSandboxSettings.OriginalModifierChance or 50
    local maxChance      = WMSandboxSettings.MaxModifierChance or 50
    if worldAgeDays < startDay then
        RGMManager.CurrentModifierChance = originalChance
    elseif worldAgeDays >= peakDay then
        RGMManager.CurrentModifierChance = maxChance
    else
        RGMManager.CurrentModifierChance = math.floor(originalChance + (maxChance - originalChance) * (worldAgeDays - startDay) / (peakDay - startDay) + 0.5)
    end
    local originalTweaker = WMSandboxSettings.StartRarityTweaker or 1
    local maxTweaker      = WMSandboxSettings.PeakRarityTweaker or 1
    if worldAgeDays < startDay then
        RGMManager.CurrentRarityTweaker = originalTweaker
    elseif worldAgeDays >= peakDay then
        RGMManager.CurrentRarityTweaker = maxTweaker
    else
        RGMManager.CurrentRarityTweaker = math.floor(originalTweaker + (maxTweaker - originalTweaker) * (worldAgeDays - startDay) / (peakDay - startDay) + 0.5)
    end
end



-- Detect which XP perk is appropriate for a clothing/footwear item
function RGMManager.getClothingXPPerk(_item)
    if not _item then return nil end
    local scriptName = ""
    local si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
    if si and type(si.getName) == "function" then
        scriptName = si:getName():lower()
    end
    local bodyLoc = type(_item.getBodyLocation) == "function" and _item:getBodyLocation() or nil
    local loc = bodyLoc and tostring(bodyLoc):lower() or ""

    local function pick(t) return t[ZombRand(1,#t + 1)] end

    -- Footwear (by script name then generic fallback)
    -- Physical perks (Fitness/Sprinting/Nimble/Strength/Lightfoot) excluded — passive gains only.
    if loc:find("shoe") or loc:find("boot") then
        if scriptName:find("work") or scriptName:find("steel") or scriptName:find("rigger") or scriptName:find("mechanic") then
            return pick({"Mechanics","Maintenance"})
        elseif scriptName:find("rubber") or scriptName:find("wader") or scriptName:find("farm") then
            return pick({"Farming","Husbandry","PlantScavenging"})
        elseif scriptName:find("hike") or scriptName:find("trail") or scriptName:find("outdoor") or scriptName:find("trek") then
            return pick({"Tracking","PlantScavenging"})
        elseif scriptName:find("hunt") or scriptName:find("camo") or scriptName:find("stealth") then
            return pick({"Sneak","Tracking"})
        end
        return nil  -- combat/running/generic shoes: no active-skill XP perk
    end

    -- Clothing: match by script name (profession patterns)
    local namePatterns = {
        -- Medical
        { pats={"doctor","medical","nurse","lab","scrub","surgi","hospit","pharma","medic","clinical"},
          perks={"Doctor","Maintenance"} },
        -- Firefighter
        { pats={"firefighter","fireman","firedepart"},
          perks={"Doctor","Axe"} },
        -- Mechanic
        { pats={"mechanic","coverall","boilersuit"},
          perks={"Mechanics","Maintenance"} },
        -- Electrician
        { pats={"electric","wiring","technician","engineer"},
          perks={"Electricity","Mechanics","Maintenance"} },
        -- Chef / Kitchen
        { pats={"chef","cook","apron","kitchen","culinary","bistro"},
          perks={"Cooking","Butchering","SmallBlade"} },
        -- Farmer / Agriculture
        { pats={"farm","agricultur","garden","plaid","ranch","livestock"},
          perks={"Farming","Husbandry","PlantScavenging"} },
        -- Police / Law enforcement
        { pats={"police","sheriff","officer","deputy","swat","cop","securi","guard"},
          perks={"Aiming","Reloading","Blunt","SmallBlunt"} },
        -- Military
        { pats={"military","army","soldier","combat","tactical"},
          perks={"Aiming","Reloading","LongBlade"} },
        -- Hunter / Camouflage
        { pats={"hunter","camo","camouflage","ghillie","woodland","hunting"},
          perks={"Trapping","Tracking","PlantScavenging","Sneak","Spear"} },
        -- Ranger / Scout
        { pats={"ranger","scout","sniper","recon"},
          perks={"Tracking","Aiming","Sneak","PlantScavenging","Spear"} },
        -- Fishing
        { pats={"fish","wader","angl"},
          perks={"Fishing","Tracking","Spear"} },
        -- Logger / Carpenter
        { pats={"logger","carpenter","lumber","lumberjack"},
          perks={"Woodwork","Axe","Maintenance","Carving"} },
        -- Tailor
        { pats={"tailor","sew","fashion","dressmaker"},
          perks={"Tailoring","Maintenance"} },
        -- Welder / Blacksmith
        { pats={"weld","forge","smith","blacksmith","metalwork","foundry"},
          perks={"MetalWelding","Blacksmith","Masonry","Maintenance"} },
        -- Butcher
        { pats={"butcher","slaughter"},
          perks={"Butchering","Axe","SmallBlade","Blunt"} },
        -- Miner / Construction
        { pats={"miner","mining","construction","hardhat","hard_hat","builder","mason"},
          perks={"Mechanics","Masonry"} },
        -- Ninja / Stealth
        { pats={"ninja","stealth","assassin","spy","thief"},
          perks={"Sneak","SmallBlade"} },
        -- Knight / Swordsman
        { pats={"knight","warrior","samurai","sword","fencer","duel"},
          perks={"LongBlade","Blunt"} },
        -- Overalls (generic workwear)
        { pats={"overall"},
          perks={"Mechanics","Woodwork","Farming","Maintenance"} },
        -- Pottery / Ceramics
        { pats={"potter","ceramic","clay"},
          perks={"Pottery","Masonry"} },
        -- Glassmaking
        { pats={"glassblow","glazier"},
          perks={"Glassmaking","Masonry"} },
        -- Carving
        { pats={"carv","sculpt","woodwork"},
          perks={"Carving","Woodwork"} },
        -- Flint / Primitive
        { pats={"flint","knap","primitive","tribal"},
          perks={"FlintKnapping","Tracking","Trapping"} },
        -- Husbandry
        { pats={"husbandry","livestock","cowboy","ranch"},
          perks={"Husbandry","Farming","Axe"} },
        -- Gunsmith / Shooting range
        { pats={"gunsmith","shooter","marksman","rifleman"},
          perks={"Aiming","Reloading","Maintenance"} },
        -- Boxer / Brawler
        { pats={"boxer","brawler","martial","karate","judo"},
          perks={"Blunt","SmallBlunt"} },
        -- Spearman
        { pats={"spear","lance","polearm"},
          perks={"Spear","Tracking"} },
    }
    for _, entry in ipairs(namePatterns) do
        for _, pat in ipairs(entry.pats) do
            if scriptName:find(pat) then
                return pick(entry.perks)
            end
        end
    end

    return nil
end

-- Roll an XP modifier for profession-themed clothing.
-- Scales by rarity: common +10% → insane +40% → legendary +50%.
-- bad/shitty rarities produce no XP modifier.
function RGMManager.rollClothingXPModifier(_item, rarityTweaker)
    local perkName = RGMManager.getClothingXPPerk(_item)
    if not perkName then return nil end

    -- Roll rarity
    local chance = ZombRand(10000)
    chance = chance * RGMManager.CurrentRarityTweaker * (rarityTweaker or 1)
    local cumulated = 0
    local rolledRarity = nil
    for _, entry in ipairs(RGMManager.rarityChances) do
        local rarity, rarityChance = entry[1], entry[2]
        cumulated = cumulated + rarityChance
        if chance < cumulated * 100 then
            rolledRarity = rarity
            break
        end
    end

    local xpTiers = {
        legendary = { key = "xp_Training",    bonus = 0.50, color = RarityColors.legendary },
        insane    = { key = "xp_Master",      bonus = 0.40, color = RarityColors.insane    },
        epic      = { key = "xp_Expert",      bonus = 0.30, color = RarityColors.epic      },
        great     = { key = "xp_Experienced", bonus = 0.20, color = RarityColors.great     },
        good      = { key = "xp_Practiced",   bonus = 0.15, color = RarityColors.good      },
        common    = { key = "xp_Student",     bonus = 0.10, color = RarityColors.common    },
    }

    local tier = xpTiers[rolledRarity]
    if not tier then return nil end  -- bad/shitty → no XP modifier

    return {
        modifierName     = "IGUI_modifier_name_" .. tier.key .. " IGUI_modifier_xp_perk_" .. perkName,
        statsMultipliers = { ["xp " .. perkName] = tier.bonus },
        fontColor        = tier.color,
    }
end

local MILITARY_CLOTHING_PATS = {"military","army","soldier","combat","tactical","police","sheriff","officer","deputy","swat","cop"}

-- Legendary military/police clothing: +30% Aiming & Reloading XP + defensive stats
function RGMManager.rollMilitaryEliteModifier(_item, rarityTweaker)
    local si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
    local scriptName = si and type(si.getName) == "function" and si:getName():lower() or ""
    local isMilitary = false
    for _, pat in ipairs(MILITARY_CLOTHING_PATS) do
        if scriptName:find(pat) then isMilitary = true; break end
    end
    if not isMilitary then return nil end

    local chance = ZombRand(10000)
    chance = chance * RGMManager.CurrentRarityTweaker * (rarityTweaker or 1)
    local cumulated = 0
    local isLegendary = false
    for _, entry in ipairs(RGMManager.rarityChances) do
        local rarity, rarityChance = entry[1], entry[2]
        cumulated = cumulated + rarityChance
        if chance < cumulated * 100 then
            isLegendary = (rarity == "legendary")
            break
        end
    end
    if not isLegendary then return nil end

    return {
        modifierName     = getText('IGUI_modifier_name_TacticalElite'),
        statsMultipliers = {
            ["xp Aiming"]    = 0.30,
            ["xp Reloading"] = 0.30,
            ["combat speed"] = 1.10,
            ["durability"]   = 1.30,
            ["scratch defense"] = 10,
            ["bite defense"]    = 7,
            ["bullet defense"]  = 5,
        },
        fontColor = {1.0, 0.55, 0.1},
    }
end

function RGMManager.checkItem(_item, _containerObj, playerRarityTweaker, _modifierChanceTweaker)
    local modifier = nil
    if _item then
        if instanceof(_item, "InventoryContainer") then
            if _item:getInventory() then
                RGMManager.changeWeaponModifiersFromContainer(_item:getInventory(), nil)
            end
            if _item:getItemContainer() then
                RGMManager.changeWeaponModifiersFromContainer(_item:getItemContainer(), nil)
            end
            local RGMSandboxSettings = SandboxVars.RGM
            if RGMSandboxSettings and RGMSandboxSettings.ClothingModifiers
                and Modifiers.Containers
            then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                                        -- first time: save original stats, roll modifier, apply
                    -- In B42, capacity lives in ItemContainer.getCapacity(), not InventoryItem.getItemCapacity()
                    local inv = type(_item.getInventory) == "function" and _item:getInventory() or nil
                    local baseCap = nil
                    if inv and type(inv.getCapacity) == "function" then
                        baseCap = inv:getCapacity()
                    end
                    if (baseCap == nil or baseCap <= 0) and type(_item.getItemCapacity) == "function" then
                        local c = _item:getItemCapacity()
                        if c and c > 0 then baseCap = c end
                    end
                    _item:getModData().scriptStats = {
                        ItemCapacity    = baseCap,
                        WeightReduction = type(_item.getWeightReduction) == "function" and _item:getWeightReduction() or nil,
                        Weight          = (type(_item.getActualWeight) == "function" and _item:getActualWeight())
                                       or (type(_item.getWeight)       == "function" and _item:getWeight())
                                       or nil,
                    }
                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if ZombRand(10000) < modifierChanceForThisItem * 100 then
                        local modifier = RGMManager.getRandomModifier(_item, Modifiers.Containers, playerRarityTweaker)
                        if modifier and modifier ~= DefaultModifier then
                            _item:getModData().modifier = modifier
                        end
                    end
                    _item:getModData().scriptStats = _item:getModData().scriptStats or {}
                    _item:getModData().scriptStats.ScriptName = _item:getScriptItem() and _item:getScriptItem():getDisplayName() or _item:getDisplayName()
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    if assignedMod then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                end -- not isClient()
                end -- not modifierChecked
                -- re-apply name and stats (handles save/load and server sync resets)
                RGMManager.applyContainerStats(_item)
            end
        elseif instanceof(_item, "Clothing") then
            if RGMManager.isJewelry(_item) then return end
            -- Skip items with no scratch/bite/bullet defense AND no noise/speed/condition stats
            -- (accessories like glasses, watches with no game-relevant stats)
            do
                local hasScratch  = type(_item.getScratchDefense)      == "function" and (_item:getScratchDefense()      or 0) > 0
                local hasBite     = type(_item.getBiteDefense)         == "function" and (_item:getBiteDefense()         or 0) > 0
                local hasBullet   = type(_item.getBulletDefense)       == "function" and (_item:getBulletDefense()       or 0) > 0
                local hasNoise    = type(_item.getNoiseMod)            == "function" and (_item:getNoiseMod()            or 1) ~= 1
                local hasSpeed    = type(_item.getRunSpeedModifier)    == "function" and (_item:getRunSpeedModifier()    or 1) ~= 1
                local hasCombat   = type(_item.getCombatSpeedModifier) == "function" and (_item:getCombatSpeedModifier() or 1) ~= 1
                local hasCond     = type(_item.getConditionMax)        == "function" and (_item:getConditionMax()        or 0) > 0
                if not (hasScratch or hasBite or hasBullet or hasNoise or hasSpeed or hasCombat or hasCond) then
                    return
                end
            end
            local RGMSandboxSettings = SandboxVars.RGM
            if not RGMSandboxSettings then return end

            local bodyLoc = type(_item.getBodyLocation) == "function" and _item:getBodyLocation() or nil
            local bodyLocStr = bodyLoc and tostring(bodyLoc) or ""
            local isShoe = bodyLocStr == "Shoes"
                or bodyLocStr:lower():find("shoe") ~= nil
                or bodyLocStr:lower():find("boot") ~= nil
            local _rawItemType = type(_item.getType) == "function" and tostring(_item:getType()) or ""
            local isGlasses = _rawItemType == "Glasses_Normal" or _rawItemType == "Glasses_Reading"

            if isGlasses and RGMSandboxSettings.ClothingModifiers and Modifiers.Glasses then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                    local rawCond = type(_item.getConditionMax) == "function" and _item:getConditionMax() or nil
                    local _si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
                    _item:getModData().scriptStats = {
                        ScriptName   = (_si and _si:getDisplayName()) or _item:getDisplayName(),
                        ConditionMax = rawCond or 10,
                    }
                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if ZombRand(10000) < modifierChanceForThisItem * 100 then
                        local modifier = RGMManager.getRandomModifier(_item, Modifiers.Glasses, playerRarityTweaker)
                        if modifier and modifier ~= DefaultModifier then
                            _item:getModData().modifier = modifier
                        end
                    end
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    if assignedMod then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                end -- not isClient()
                end -- not modifierChecked
                RGMManager.applyClothingStats(_item, Modifiers.Glasses)
            elseif isShoe and RGMSandboxSettings.ClothingModifiers and Modifiers.Footwear then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                    local rawNoise = type(_item.getNoiseMod)         == "function" and _item:getNoiseMod()         or nil
                    local rawSpeed = type(_item.getRunSpeedModifier) == "function" and _item:getRunSpeedModifier() or nil
                    local rawCond  = type(_item.getConditionMax)     == "function" and _item:getConditionMax()     or nil
                    _item:getModData().scriptStats = {
                        ScriptName       = _item:getScriptItem() and _item:getScriptItem():getDisplayName() or _item:getDisplayName(),
                        NoiseMod         = (rawNoise and rawNoise ~= 0) and rawNoise or 1.0,
                        RunSpeedModifier = (rawSpeed and rawSpeed ~= 0) and rawSpeed or 1.0,
                        ConditionMax     = rawCond or 10,
                    }
                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if ZombRand(10000) < modifierChanceForThisItem * 100 then
                        local modifier = nil
                        if RGMSandboxSettings.ClothingXPModifiers and ZombRand(100) < 50 then
                            modifier = RGMManager.rollClothingXPModifier(_item, playerRarityTweaker)
                        end
                        if not modifier then
                            modifier = RGMManager.getRandomModifier(_item, Modifiers.Footwear, playerRarityTweaker)
                        end
                        if modifier and modifier ~= DefaultModifier then
                            _item:getModData().modifier = modifier
                        end
                    end
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    if assignedMod then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                end -- not isClient()
                end -- not modifierChecked
                RGMManager.applyClothingStats(_item, Modifiers.Footwear)

            elseif not isShoe and RGMSandboxSettings.ClothingModifiers and Modifiers.Clothing then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                    local rawNoise   = type(_item.getNoiseMod)         == "function" and _item:getNoiseMod()         or nil
                    local rawSpeed   = type(_item.getRunSpeedModifier) == "function" and _item:getRunSpeedModifier() or nil
                    local rawCond    = type(_item.getConditionMax)     == "function" and _item:getConditionMax()     or nil
                    local rawScratch = type(_item.getScratchDefense)      == "function" and _item:getScratchDefense()      or nil
                    local rawBite    = type(_item.getBiteDefense)         == "function" and _item:getBiteDefense()         or nil
                    local rawBullet  = type(_item.getBulletDefense)       == "function" and _item:getBulletDefense()       or nil
                    local rawCombat  = type(_item.getCombatSpeedModifier) == "function" and _item:getCombatSpeedModifier() or nil
                    _item:getModData().scriptStats = {
                        ScriptName          = _item:getScriptItem() and _item:getScriptItem():getDisplayName() or _item:getDisplayName(),
                        NoiseMod            = (rawNoise and rawNoise ~= 0) and rawNoise or 1.0,
                        RunSpeedModifier    = (rawSpeed and rawSpeed ~= 0) and rawSpeed or 1.0,
                        ConditionMax        = rawCond or 10,
                        ScratchDefense      = rawScratch or 0,
                        BiteDefense         = rawBite or 0,
                        BulletDefense       = rawBullet or 0,
                        CombatSpeedModifier = (rawCombat and rawCombat ~= 0) and rawCombat or 1.0,
                    }
                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if ZombRand(10000) < modifierChanceForThisItem * 100 then
                        local modifier = nil
                        if RGMSandboxSettings.ClothingXPModifiers and ZombRand(100) < 65 then
                            modifier = RGMManager.rollMilitaryEliteModifier(_item, playerRarityTweaker)
                            if not modifier then
                                modifier = RGMManager.rollClothingXPModifier(_item, playerRarityTweaker)
                            end
                        end
                        if not modifier then
                            modifier = RGMManager.getRandomModifier(_item, Modifiers.Clothing, playerRarityTweaker)
                        end
                        if modifier and modifier ~= DefaultModifier then
                            _item:getModData().modifier = modifier
                        end
                    end
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    if assignedMod then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                end -- not isClient()
                end -- not modifierChecked
                RGMManager.applyClothingStats(_item, Modifiers.Clothing)
            end
        elseif type(_item.getDisplayCategory) == "function" and _item:getDisplayCategory() == "LightSource" then
            if Modifiers.Flashlights then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                    _item:getModData().scriptStats = {
                        ScriptName           = (_item:getScriptItem() and _item:getScriptItem():getDisplayName()) or _item:getDisplayName(),
                        LightDistance        = type(_item.getLightDistance)        == "function" and _item:getLightDistance()        or nil,
                        LightStrength        = type(_item.getLightStrength)        == "function" and _item:getLightStrength()        or nil,
                        UseDelta             = type(_item.getUseDelta)             == "function" and _item:getUseDelta()             or nil,
                        ConditionLowerChance = type(_item.getConditionLowerChance) == "function" and _item:getConditionLowerChance() or nil,
                        ConditionMax         = type(_item.getConditionMax)         == "function" and _item:getConditionMax()         or nil,
                    }
                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if ZombRand(10000) < modifierChanceForThisItem * 100 then
                        local modifier = RGMManager.getRandomModifier(_item, Modifiers.Flashlights, playerRarityTweaker)
                        if modifier and modifier ~= DefaultModifier then
                            _item:getModData().modifier = modifier
                        end
                    end
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    if assignedMod then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                end -- not isClient()
                end -- not modifierChecked
                RGMManager.applyFlashlightStats(_item)
            end
        elseif type(_item.getAmmoType) == "function" and _item:getAmmoType() ~= nil
            and type(_item.getMaxAmmo) == "function" and (_item:getMaxAmmo() or 0) > 0
            and not (type(_item.isRanged) == "function" and _item:isRanged()) then
            -- Magazine / clip item
            local RGMSandboxSettings = SandboxVars.RGM
            if RGMSandboxSettings and Modifiers.Magazine then
                if not _item:getModData().modifierChecked then
                if not isClient() then
                    local freshMaxAmmo = _item:getMaxAmmo()
                    local si = _item:getScriptItem()
                    local freshScriptName = (si and si:getDisplayName()) or _item:getDisplayName()
                    -- Use script item weight as base (unaffected by our setActualWeight calls)
                    local freshWeight = (si and type(si.getWeight)=="function" and si:getWeight())
                                     or (type(_item.getWeight)=="function" and _item:getWeight())
                                     or nil
                    _item:getModData().scriptStats = {
                        ScriptName = freshScriptName,
                        MaxAmmo    = freshMaxAmmo,
                        Weight     = freshWeight,
                    }
                    print("[RGM] SERVER mag NEW: item=" .. tostring(_item:getDisplayName()) .. " freshMaxAmmo=" .. tostring(freshMaxAmmo) .. " existingMod=" .. tostring(_item:getModData().modifier and _item:getModData().modifier.modifierName))
                    -- MP fix: if this magazine was just ejected from a weapon, restore its saved modifier
                    -- instead of rolling a new one. ISInsertMagazine now transmits rgm_lastMagMod to server.
                    local restoredFromEject = false
                    local magType = type(_item.getType) == "function" and _item:getType() or nil
                    if magType and _containerObj then
                        local scanInv = (type(_containerObj.getInventory) == "function" and _containerObj:getInventory())
                                     or (type(_containerObj.getItemContainer) == "function" and _containerObj:getItemContainer())
                        local scanItems = scanInv and type(scanInv.getItems) == "function" and scanInv:getItems()
                        if scanItems then
                            for k = 0, scanItems:size() - 1 do
                                local wpn = scanItems:get(k)
                                if wpn and instanceof(wpn, "HandWeapon") and wpn:isRanged()
                                    and type(wpn.getMagazineType) == "function" and wpn:getMagazineType() == magType
                                    and wpn:getModData().rgm_lastMagMod
                                then
                                    local savedMod = wpn:getModData().rgm_lastMagMod
                                    _item:getModData().modifier = savedMod
                                    -- scriptStats.MaxAmmo already correct from fresh item's getMaxAmmo() above;
                                    -- do NOT overwrite with rgm_lastMagBase which may be the post-modifier value.
                                    wpn:getModData().rgm_lastMagMod  = nil
                                    wpn:getModData().rgm_lastMagBase = nil
                                    if type(wpn.transmitModData) == "function" then wpn:transmitModData() end
                                    restoredFromEject = true
                                    print("[RGM] SERVER mag eject restore: item=" .. tostring(_item:getDisplayName()) .. " modifier=" .. tostring(savedMod.modifierName) .. " translationChecked=" .. tostring(savedMod.translationChecked))
                                    break
                                end
                            end
                        end
                    end
                    if not restoredFromEject then
                        local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                        if ZombRand(10000) < modifierChanceForThisItem * 100 then
                            local modifier = RGMManager.getRandomModifier(_item, Modifiers.Magazine, playerRarityTweaker)
                            if modifier and modifier ~= DefaultModifier then
                                _item:getModData().modifier = modifier
                                print("[RGM] SERVER mag: rolled new modifier=" .. tostring(modifier.modifierName))
                            end
                        end
                    end
                    _item:getModData().modifierChecked = true
                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                    local assignedMod = _item:getModData().modifier
                    -- Notify only for genuinely new modifiers; restored eject doesn't need halo text
                    if assignedMod and not restoredFromEject then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, assignedMod) end
                    -- Cache on matching weapons in same container for the "picked up and immediately inserted" case.
                    if assignedMod and not restoredFromEject then
                        local base = (_item:getModData().scriptStats or {}).MaxAmmo or _item:getMaxAmmo()
                        if magType then
                            local scanInv = (_containerObj and type(_containerObj.getInventory) == "function" and _containerObj:getInventory())
                                         or (_containerObj and type(_containerObj.getItemContainer) == "function" and _containerObj:getItemContainer())
                            local scanItems = scanInv and type(scanInv.getItems) == "function" and scanInv:getItems()
                            if scanItems then
                                for ci = 0, scanItems:size() - 1 do
                                    local wpn = scanItems:get(ci)
                                    if wpn and instanceof(wpn, "HandWeapon") and wpn:isRanged()
                                        and type(wpn.getMagazineType) == "function" and wpn:getMagazineType() == magType
                                    then
                                        wpn:getModData().rgm_lastMagMod  = assignedMod
                                        wpn:getModData().rgm_lastMagBase = base
                                    end
                                end
                            end
                        end
                    end
                end -- not isClient()
                end -- not modifierChecked
                -- Migrate legacy Tactical magazine modifiers → Extended of same rarity.
                -- Tactical had a weight reduction bonus that proved ineffective for loaded mags.
                do
                    local mod = _item:getModData().modifier
                    if mod and mod.statsMultipliers and mod.statsMultipliers["weight"] then
                        local fc = mod.fontColor
                        local function colorEq(a, b)
                            return a and b and a[1]==b[1] and a[2]==b[2] and a[3]==b[3]
                        end
                        if Modifiers and Modifiers.Magazine then
                            for _, rarityList in pairs(Modifiers.Magazine) do
                                for _, candidate in ipairs(rarityList) do
                                    if colorEq(candidate.fontColor, fc)
                                        and candidate.statsMultipliers
                                        and not candidate.statsMultipliers["weight"]
                                    then
                                        _item:getModData().modifier = candidate
                                        _item:getModData().translationChecked = nil
                                        -- Restore original weight (undo setWeight/setCustomWeight from old code)
                                        local origW = (_item:getModData().scriptStats or {}).Weight
                                        if origW and origW > 0 then
                                            pcall(function() _item:setWeight(origW) end)
                                            pcall(function() _item:setActualWeight(origW) end)
                                            pcall(function() _item:setCustomWeight(false) end)
                                        end
                                        if type(_item.transmitModData)=="function" then _item:transmitModData() end
                                        print("[RGM] migrated Tactical→Extended: " .. tostring(candidate.modifierName))
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                -- re-apply on every scan (handles save/load resets)
                local mod = _item:getModData().modifier
                -- Try translation; only works in client-Lua context where getText() returns real strings.
                -- In server-Lua context getText() returns the raw IGUI key, so resolveModifierName
                -- will fail silently (translationChecked stays nil). That is expected.
                if mod and not mod.translationChecked then
                    mod = RGMManager.resolveModifierName(_item) or mod
                end
                if mod and mod.statsMultipliers then
                    local pct = mod.statsMultipliers["max ammo pct"] or 1
                    if pct ~= 1 then
                        local base = (_item:getModData().scriptStats or {}).MaxAmmo or 0
                        local currentMax = _item:getMaxAmmo()
                        if base > 0 then
                            local newMax = math.max(1, math.floor(base * pct + 0.5))
                            if newMax ~= currentMax then
                                local ok = pcall(function() _item:setMaxAmmo(newMax) end)
                                if ok and not isClient() then
                                    -- Push MaxAmmo change to clients in dedicated MP
                                    if type(_item.transmitModData) == "function" then _item:transmitModData() end
                                end
                                if type(_item.getCurrentAmmo) == "function" then
                                    local cur = _item:getCurrentAmmo()
                                    if cur and cur > newMax then
                                        pcall(function() _item:setCurrentAmmo(newMax) end)
                                    end
                                end
                            end
                        end
                        -- update display name only when translated
                        if mod.translationChecked then
                            local si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
                            local base2 = (_item:getModData().scriptStats or {}).ScriptName
                                or (si and type(si.getDisplayName) == "function" and si:getDisplayName() or nil)
                            if base2 then
                                local expectedName = base2 .. " [" .. mod.modifierName .. "]"
                                if _item:getName() ~= expectedName then
                                    _item:setName(expectedName)
                                    _item:setCustomName(true)
                                    print("[RGM] mag re-apply setName -> " .. tostring(expectedName) .. " isClient=" .. tostring(isClient()))
                                end
                            end
                        end
                        -- Update rgm_lastMagMod on matching weapons in the same container.
                        -- Uses item:getContainer() so it works even when _containerObj is nil.
                        local magType = type(_item.getType) == "function" and _item:getType() or nil
                        local itemCont = magType and type(_item.getContainer) == "function" and _item:getContainer() or nil
                        if itemCont then
                            local contItems = type(itemCont.getItems) == "function" and itemCont:getItems() or nil
                            if contItems then
                                for ci = 0, contItems:size() - 1 do
                                    local wpn = contItems:get(ci)
                                    if wpn and instanceof(wpn, "HandWeapon") and wpn:isRanged()
                                        and type(wpn.getMagazineType) == "function" and wpn:getMagazineType() == magType
                                    then
                                        wpn:getModData().rgm_lastMagMod  = mod
                                        wpn:getModData().rgm_lastMagBase = base > 0 and base or _item:getMaxAmmo()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif instanceof(_item, "HandWeapon") and _item:getSwingAnim() ~= "Throw" then
            if not _item:getModData().modifierChecked then
                if isClient() then
                    -- clients must not roll new modifiers; wait for server modData sync
                    local existingMod = _item:getModData().modifier
                    if existingMod and existingMod.modifierName ~= getText("Tooltip_modifier_standard") then
                        RGMManager.applyModifierStatsToItem(_item, existingMod)
                    end
                    return nil
                end
                                local RGMSandboxSettings = SandboxVars.RGM
                if not RGMSandboxSettings.IgnoreIrrelevantWeapons or not RGMManager.IrrelevantWeapons[_item:getScriptItem():getFullName()] then

                    local modifierChanceForThisItem = RGMManager.CurrentModifierChance * _modifierChanceTweaker
                    if modifierChanceForThisItem ~= 0 then
                        if _containerObj and instanceof(_containerObj, "IsoDeadBody") and _containerObj:getAttachedItems():contains(_item) and RGMSandboxSettings.AttachedWeaponsChanceMultiplier ~= 0 then
                            modifierChanceForThisItem = modifierChanceForThisItem * RGMSandboxSettings.AttachedWeaponsChanceMultiplier
                        end

                        if _item:isRanged() then
                            if RGMSandboxSettings.RangedWeaponsChanceMultiplier then
                                modifierChanceForThisItem = modifierChanceForThisItem * RGMSandboxSettings.RangedWeaponsChanceMultiplier
                                if ZombRand(10000) < modifierChanceForThisItem*100 then
                                    modifier = RGMManager.getRandomModifier(_item, Modifiers.Ranged, playerRarityTweaker)
                                end
                            end
                        else
                            if ZombRand(10000) < modifierChanceForThisItem*100 then
                                modifier = RGMManager.getRandomModifier(_item, Modifiers.Melee, playerRarityTweaker)
                            end
                        end
                    end
                    
                end
                -- COMMENTED CODE BELOW IS FOR TESTING PURPOSES
                        -- if modifier and modifier.statsMultipliers then
                        --         modifier.statsMultipliers = {
                        --             damage = 2,
                        --             ["attack speed"] = 2,
                        --             ["critical chance"] = 2,
                        --             ["minimum range"] = 0.5,
                        --             ["maximum range"] = 2,
                        --             knockback = 2,
                        --             ["endurance cost"] = 0.5, 
                        --             ["durability"] = 2,
                        --             weight = 2, -- custom weight doesn't work
                        --             accuracy = 2,
                        --             ["sound radius"] = 2,
                        --             recoil = 2,
                        --             ["reload time"] = 2,
                        --             ["aim time"] = 2,
                        --             experience = 2
                        --         }
                        -- end
                if modifier and modifier.modifierName ~= getText("Tooltip_modifier_standard") then
                    _item:getModData().modifier = modifier
                    RGMManager.applyModifierStatsToItem(_item, modifier)
                end
                _item:getModData().modifierChecked = true
                if type(_item.transmitModData) == "function" then _item:transmitModData() end
                if modifier then RGMManager.notifyPlayerModifierAssigned(_containerObj, _item, modifier) end
                return modifier
            else
                local modifier = _item:getModData().modifier
                if modifier and modifier.modifierName ~= getText("Tooltip_modifier_standard") then
                    RGMManager.applyModifierStatsToItem(_item, modifier)
                end
                return nil
            end
        end
    end
end
--RGMManager.applyModifierStatsToItem(getPlayer():getPrimaryHandItem(), getPlayer():getPrimaryHandItem():getModData().modifier)


function RGMManager.checkSquareFloorForWeaponModifiers(_square)
    if not _square then return; end

    local worldObjects = _square:getWorldObjects()
    if worldObjects:size() == 0 then return; end
    for i = 0, worldObjects:size()-1 do
        local object = worldObjects:get(i);
        if object and instanceof(object, "IsoWorldInventoryObject") then
            -- print(getPlayer():getSquare():getWorldObjects():get(0):getItem())
            local item = object:getItem()
            if RGMManager.testMode then print("Item detected: "..item:getName()) end
            RGMManager.checkItem(item, nil, 1, 1)
        end
    end
end

local function checkZombieInventoryOnDeath(zombie)
    if not zombie then return end
    local inv = type(zombie.getInventory) == "function" and zombie:getInventory() or nil
    if not inv then return end
    RGMManager.changeWeaponModifiersFromContainer(inv, zombie)
end

Events.LoadGridsquare.Add(RGMManager.checkSquareFloorForWeaponModifiers)
Events.ReuseGridsquare.Add(RGMManager.checkSquareFloorForWeaponModifiers)
Events.OnRefreshInventoryWindowContainers.Add(checkWeaponModifiersOnRefreshEnd);
Events.OnFillContainer.Add(checkWeaponModifiersOnFill);
Events.OnZombieDead.Add(checkZombieInventoryOnDeath);


Events.OnGameStart.Add(RGMManager.updateModifierChance);
Events.OnServerStarted.Add(RGMManager.updateModifierChance);
Events.EveryDays.Add(RGMManager.updateModifierChance);
Events.OnDusk.Add(RGMManager.updateModifierChance);
Events.OnDawn.Add(RGMManager.updateModifierChance);
Events.OnPostDistributionMerge.Add(RGMManager.updateModifierChance);

-- Calculate rarity tweaker from player skill levels (server-side, no trait access in B42)
local function getRarityTweakerForPlayerServer(player, item, hasTinkerer)
    local weaponLevel = 0
    if type(item.isRanged) == "function" and item:isRanged() then
        weaponLevel = math.floor((player:getPerkLevel(Perks.Aiming)*2 + player:getPerkLevel(Perks.Reloading)) / 3 + 0.5)
    else
        local perk = type(item.getPerk) == "function" and tostring(item:getPerk()) or nil
        if     perk == "Axe"        then weaponLevel = player:getPerkLevel(Perks.Axe)
        elseif perk == "LongBlade"  then weaponLevel = player:getPerkLevel(Perks.LongBlade)
        elseif perk == "SmallBlade" then weaponLevel = player:getPerkLevel(Perks.SmallBlade)
        elseif perk == "SmallBlunt" then weaponLevel = player:getPerkLevel(Perks.SmallBlunt)
        elseif perk == "Blunt"      then weaponLevel = player:getPerkLevel(Perks.Blunt)
        elseif perk == "Spear"      then weaponLevel = player:getPerkLevel(Perks.Spear)
        end
    end
    local maintenanceLevel = player:getPerkLevel(Perks.Maintenance)
    local tinkeringLevel   = player:getPerkLevel(Perks.Tinkering)
    local tweaker = 1 - weaponLevel*0.005 - maintenanceLevel*0.01 - tinkeringLevel*0.03
    if hasTinkerer then tweaker = tweaker - 0.07 end
    return tweaker
end

-- Scan one player's inventory on the server side with craft-specific chance multipliers.
-- Unprocessed items (modifierChecked=false) get a modifier rolled here.
-- Already-processed items just get their stats re-applied (via checkItem else branch).
local function RGMManager_scanPlayerInventoryServer(player)
    local rgm = SandboxVars.RGM
    if not rgm then return end
    local craftMult = rgm.ChanceMultiplierForCraftedItems or 0.75
    local inv = type(player.getInventory) == "function" and player:getInventory() or nil
    if not inv then return end
    local items = type(inv.getItems) == "function" and inv:getItems() or nil
    if not items then return end
    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if item then
            if instanceof(item, "HandWeapon") and item:getSwingAnim() ~= "Throw" then
                local rarityTweaker = getRarityTweakerForPlayerServer(player, item, false)
                RGMManager.checkItem(item, player, rarityTweaker + 0.1, craftMult)
            elseif instanceof(item, "InventoryContainer") then
                RGMManager.checkItem(item, player, 1, craftMult)
            elseif instanceof(item, "Clothing") then
                RGMManager.checkItem(item, player, 1, craftMult)
            elseif type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil then
                RGMManager.checkItem(item, player, 1, craftMult)
                -- Save Extended modifier on matching weapons in player inventory.
                -- This lets ISEjectMagazine restore it when PZ creates a new item on eject.
                -- If the weapon is destroyed with a loaded mag, both are lost — fair game design.
                local mod = item:getModData().modifier
                if mod then
                    local magType = type(item.getType) == "function" and item:getType() or nil
                    if magType then
                        for k = 0, items:size() - 1 do
                            local wpn = items:get(k)
                            if wpn and instanceof(wpn, "HandWeapon") and wpn:isRanged()
                                and type(wpn.getMagazineType) == "function" and wpn:getMagazineType() == magType
                            then
                                wpn:getModData().rgm_lastMagMod  = mod
                                wpn:getModData().rgm_lastMagBase = (item:getModData().scriptStats or {}).MaxAmmo or item:getMaxAmmo()
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Re-apply modifier stats to player inventory on connect (MP/SP reconnect).
-- Also handles unprocessed crafted items using craft-specific chance multipliers.
local function RGMManager_reapplyPlayerInventory(playerIndex, player)
    if not player then return end
    RGMManager_scanPlayerInventoryServer(player)
    local worn = type(player.getWornItems) == "function" and player:getWornItems() or nil
    if worn then
        for i = 0, worn:size() - 1 do
            local entry = worn:get(i)
            local wornItem = entry and type(entry.getItem) == "function" and entry:getItem() or nil
            if wornItem then RGMManager.checkItem(wornItem, nil, 1, 1) end
        end
    end
end

-- Server-side EveryOneMinute scan: picks up newly crafted items in player inventories
-- (bags, clothing, weapons) that OnFillContainer never sees, and rolls their modifiers.
-- Clients never call checkItem rolling logic (isClient() guard in checkItem).
local function RGMManager_checkAllPlayerInventoriesServer()
    if isClient() then return end
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then return end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            RGMManager_scanPlayerInventoryServer(player)
        end
    end
end

Events.OnCreatePlayer.Add(RGMManager_reapplyPlayerInventory)
Events.EveryOneMinute.Add(RGMManager_checkAllPlayerInventoriesServer)


-- Send ItemModifierAssigned to the owning player for immediate client-side update.
-- Called whenever the server assigns a new modifier to an item in a player's inventory.
local function colorEq(a, b)
    if not a or not b then return false end
    return a == b or (a[1] == b[1] and a[2] == b[2] and a[3] == b[3])
end

function RGMManager.notifyPlayerModifierAssigned(player, item, modifier)
    if not player or not instanceof(player, "IsoPlayer") then return end
    if not item or not modifier then return end
    local colorCat = "white"
    local fc = modifier.fontColor
    if fc then
        if colorEq(fc, RarityColors.bad) or colorEq(fc, RarityColors.shitty) then
            colorCat = "red"
        elseif colorEq(fc, RarityColors.legendary) or colorEq(fc, RarityColors.insane)
            or colorEq(fc, RarityColors.epic) or colorEq(fc, RarityColors.great) then
            colorCat = "green"
        end
    end
    print("[RGM] SERVER notifying player=" .. tostring(player:getUsername()) .. " item=" .. tostring(item:getDisplayName()) .. " modifier=" .. tostring(modifier.modifierName))
    sendServerCommand(player, "RGM", "ItemModifierAssigned", {
        itemId   = item:getID(),
        colorCat = colorCat,
        modifier = modifier,
    })
end

-- MP: handle client "Reforge" command — roll modifier server-side, transmit to all clients
local function applyLoodomanEffectServer(newModifier, modList, item, rarityTweaker)
    if not modList then return newModifier end
    local roll = ZombRand(10000)
    if roll < 777 then
        return RGMManager.getRandomModifier(item, modList, rarityTweaker * 0.05)
    elseif roll < 8554 then
        return RGMManager.getRandomModifier(item, modList, rarityTweaker * 8.0)
    end
    return newModifier
end

local function onClientCommand_Reforge(player, args)
    if not player or not args or not args.itemId then return end

    local inv = player:getInventory()
    local item = (type(inv.getItemById) == "function" and inv:getItemById(args.itemId))
              or (type(inv.getItemFromID) == "function" and inv:getItemFromID(args.itemId))
    if not item then
        print("[RGM] SERVER Reforge: item " .. tostring(args.itemId) .. " not found in " .. tostring(player:getUsername()) .. " inventory")
        return
    end
    print("[RGM] SERVER Reforge: player=" .. tostring(player:getUsername()) .. " item=" .. tostring(item:getDisplayName()) .. " category=" .. tostring(args.itemCategory))

    -- Consume tinkering materials server-side so the removal persists across reconnects.
    -- Track what was consumed so the client can mirror the visual state.
    local consumedItemType, consumedCost
    local tinkeringItemType = args.tinkeringItemType
    if tinkeringItemType then
        local tinkerCost = SandboxVars.RGM.TinkerCost
        local cost = TinkerItemQuantityNecessary[tinkeringItemType]
            and TinkerItemQuantityNecessary[tinkeringItemType] * tinkerCost
            or tinkerCost
        local chanceToNotConsume = player:getPerkLevel(Perks.Tinkering) * 3
        if args.hasTinkerer then chanceToNotConsume = chanceToNotConsume + 20 end
        if ZombRand(1000) > chanceToNotConsume * 10 then
            if RGM_isLeatherworkItem(tinkeringItemType) then
                RGM_consumeLeatherUses(inv, cost)
            else
                RGM_consumeItemUses(inv, tinkeringItemType, cost)
            end
            consumedItemType = tinkeringItemType
            consumedCost     = cost
        end
    end

    local itemCategory = args.itemCategory or "weapon"
    local rarityTweaker = (itemCategory == "weapon")
        and getRarityTweakerForPlayerServer(player, item, args.hasTinkerer)
        or 1

    local newModifier, usedModList
    if itemCategory == "weapon" then
        usedModList = args.isRanged and Modifiers.Ranged or Modifiers.Melee
    elseif itemCategory == "container" then
        usedModList = Modifiers.Containers
    elseif itemCategory == "clothing" then
        usedModList = args.isShoe and Modifiers.Footwear or Modifiers.Clothing
    elseif itemCategory == "magazine" then
        usedModList = Modifiers.Magazine
    elseif itemCategory == "flashlight" then
        usedModList = Modifiers.Flashlights
    end

    if not usedModList then return end
    newModifier = RGMManager.getRandomModifier(item, usedModList, rarityTweaker)
    if not newModifier then return end

    if args.hasLoodoman then
        newModifier = applyLoodomanEffectServer(newModifier, usedModList, item, rarityTweaker)
    end

    item:getModData().modifier = newModifier
    item:getModData().modifierChecked = true

    if itemCategory == "weapon" then
        RGMManager.applyModifierStatsToItem(item, newModifier)
    elseif itemCategory == "container" then
        RGMManager.applyContainerStats(item)
    elseif itemCategory == "clothing" then
        RGMManager.applyClothingStats(item)
    elseif itemCategory == "magazine" then
        RGMManager.applyMagazineStats(item)
    elseif itemCategory == "flashlight" then
        RGMManager.applyFlashlightStats(item)
    end

    if type(item.transmitModData) == "function" then
        item:transmitModData()
    end

    RGMManager.awardTinkeringXP(player, newModifier, 1)

    -- DynamicTinkerer: track high-rarity reforges and unlock TINKERER trait in MP
    local rgm = SandboxVars.RGM
    if rgm and rgm.DynamicTinkerer and not args.hasReforger then
        local fc = newModifier.fontColor
        local isHighRarity = fc and (
            fc == RarityColors.epic or fc == RarityColors.insane or
            fc == RarityColors.legendary or fc == RarityColors.rare)
        if isHighRarity then
            local md = player:getModData()
            md.itemsTinkered = (md.itemsTinkered or 0) + 1
        end
        if player:getPerkLevel(Perks.Tinkering) + player:getPerkLevel(Perks.Maintenance) >= 8 then
            local md = player:getModData()
            if md.itemsTinkered and md.itemsTinkered >= 15 then
                if RGM and RGM.CharacterTrait and RGM.CharacterTrait.TINKERER then
                    pcall(function() player:getTraits():add(RGM.CharacterTrait.TINKERER) end)
                end
                md.itemsTinkered = nil
            end
        end
    end

    -- Determine color category for halo text
    local colorCat = "white"
    local fc = newModifier.fontColor
    if fc then
        if colorEq(fc, RarityColors.bad) or colorEq(fc, RarityColors.shitty) then
            colorCat = "red"
        elseif colorEq(fc, RarityColors.legendary) or colorEq(fc, RarityColors.insane)
            or colorEq(fc, RarityColors.epic) or colorEq(fc, RarityColors.great) then
            colorCat = "green"
        end
    end
    print("[RGM] SERVER Reforge: rolled=" .. tostring(newModifier.modifierName) .. " colorCat=" .. colorCat)
    sendServerCommand(player, "RGM", "ReforgeResult", {
        itemId           = args.itemId,
        colorCat         = colorCat,
        modifierName     = newModifier.modifierName,
        modifier         = newModifier,
        consumedItemType = consumedItemType,
        consumedCost     = consumedCost,
    })
end

local function onClientCommand(module, command, player, args)
    if module ~= "RGM" then return end
    if command == "Reforge" then
        onClientCommand_Reforge(player, args)
    end
end
Events.OnClientCommand.Add(onClientCommand)

return RGMManager