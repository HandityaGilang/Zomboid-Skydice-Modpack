require "Foraging/forageDefinitions"
require "Foraging/forageSystem"

Events.onAddForageDefs.Add(function()

    -- Bees
    local Honeybee = {
        type                = "Hold.Honeybee",          --item type including module
        minCount            = 1,                        --minimum amount of items to pick up
        maxCount            = 2,                        --maximum amount of items to pick up
        skill               = 0,                        --skill level required to see the item
        perks               = { "Husbandry" },          --perks required - can be multiple perks, skill level will be averaged
        xp                  = 5,                        --xp reward on pickup - divide by 3 for spotting xp - is awarded to all perks required
        recipes             = {},                       --recipes required to see the item
        traits              = {},                       --traits required to see the item
        itemTags            = {},                       --itemTags required to see the item (digPlow etc)
        categories          = { "Insects" },            --categories the item is a part of
        rainChance          = -30,                      --rain chance modifier (percent)
        hasRainedChance     = 15,                       --after rain chance modifier (percent)
        snowChance          = -30,                      --snow chance modifier (percent)
        dayChance           = 30,                       --day chance modifier (percent)
        nightChance         = -30,                      --night chance modifier (percent)
        zones = {                                       --zones where the item can be found
            Forest      	= 25,
            DeepForest  	= 35,
            PHForest  		= 15,                        --Acidic Forest
            PRForest  		= 35,                        --Primary Forest
            BirchForest  	= 25,
            OrganicForest  	= 35,
            Vegitation  	= 25,
            FarmLand    	= 25,
            Farm        	= 15,
            TrailerPark 	= 5,
            TownZone    	= 1,
            Nav             = 2,                        --Road
            ForagingNav 	= 2,                        --Road
        },
        months              = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },    --months when the item can be found
        validMonths         = {},                       --months when the item can be found
        bonusMonths         = {4, 5, 6, 7},            --months when the item is more common (must be in months)
        malusMonths         = {1, 2, 11, 12},           --months when the item is less common (must be in months)
        spawnFuncs          = {},                       --custom spawn function when item is picked up

        forceOutside        = true,                     --item must be outside
        isOnWater           = false,                    --item can be on water
        forceOnWater        = false,                    --item must be on water
        canBeAboveFloor     = false,                    --does nothing, ignored
        doIsoMarkerSprite   = nil,                      --use a custom sprite/sprites for IsoMarker
        canBeOnTreeSquare   = true,                     --can occupy the same square as an IsoTree
        poisonChance        = 0,                        --percent chance the item is poisoned
        poisonPowerMin      = 0,                        --minimum amount of poison to apply
        poisonPowerMax      = 0,                        --maximum amount of poison to apply
        poisonDetectionLevel= 0,                        --level required to detect the poison
        itemSizeModifier    = 1.0,                      --increase or decrease item weight in vision radius checking
        isItemOverrideSize  = true,                    --use only itemSizeModifier in vision radius checking - not the real item weight
    }

    local Zombee = {
        type                = "Hold.Zombee",            --item type including module
        minCount            = 1,                        --minimum amount of items to pick up
        maxCount            = 2,                        --maximum amount of items to pick up
        skill               = 0,                        --skill level required to see the item
        perks               = { "Husbandry" },          --perks required - can be multiple perks, skill level will be averaged
        xp                  = 5,                        --xp reward on pickup - divide by 3 for spotting xp - is awarded to all perks required
        recipes             = {},                       --recipes required to see the item
        traits              = {},                       --traits required to see the item
        itemTags            = {},                       --itemTags required to see the item (digPlow etc)
        categories          = { "Insects" },            --categories the item is a part of
        rainChance          = 0,                     --rain chance modifier (percent)
        hasRainedChance     = 0,                       --after rain chance modifier (percent)
        snowChance          = 0,                     --snow chance modifier (percent)
        dayChance           = 10,                       --day chance modifier (percent)
        nightChance         = 18,                     --night chance modifier (percent)
        zones = {                                       --zones where the item can be found
            Forest      	= 15,
            DeepForest  	= 25,
            PHForest  		= 15,                        --Acidic Forest
            PRForest  		= 30,                        --Primary Forest
            BirchForest  	= 28,
            OrganicForest  	= 20,
            Vegitation  	= 20,
            FarmLand    	= 25,
            Farm        	= 15,
            TrailerPark 	= 10,
            TownZone    	= 20,
            Nav             = 5,                       --Road
            ForagingNav 	= 5,                       --Road
        },
        months              = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },    --months when the item can be found
        validMonths         = {},                       --months when the item can be found
        bonusMonths         = {4, 5, 6, 7},            --months when the item is more common (must be in months)
        malusMonths         = {1, 2, 11, 12},         --months when the item is less common (must be in months)
        spawnFuncs          = {},                       --custom spawn function when item is picked up
        
        forceOutside        = false,                     --item must be outside
        isOnWater           = false,                    --item can be on water
        forceOnWater        = false,                    --item must be on water
        canBeAboveFloor     = false,                    --does nothing, ignored
        doIsoMarkerSprite   = nil,                      --use a custom sprite/sprites for IsoMarker
        canBeOnTreeSquare   = true,                     --can occupy the same square as an IsoTree
        poisonChance        = 0,                        --percent chance the item is poisoned
        poisonPowerMin      = 0,                        --minimum amount of poison to apply
        poisonPowerMax      = 0,                        --maximum amount of poison to apply
        poisonDetectionLevel= 0,                        --level required to detect the poison
        itemSizeModifier    = 1.0,                      --increase or decrease item weight in vision radius checking
        isItemOverrideSize  = true,                    --use only itemSizeModifier in vision radius checking - not the real item weight
    }

    local Bumblebee = {
        type                = "Hold.Bumblebee",         --item type including module
        minCount            = 1,                        --minimum amount of items to pick up
        maxCount            = 2,                        --maximum amount of items to pick up
        skill               = 0,                        --skill level required to see the item
        perks               = { "Husbandry" },          --perks required - can be multiple perks, skill level will be averaged
        xp                  = 5,                        --xp reward on pickup - divide by 3 for spotting xp - is awarded to all perks required
        recipes             = {},                       --recipes required to see the item
        traits              = {},                       --traits required to see the item
        itemTags            = {},                       --itemTags required to see the item (digPlow etc)
        categories          = { "Insects" },            --categories the item is a part of
        rainChance          = -30,                     --rain chance modifier (percent)
        hasRainedChance     = 15,                       --after rain chance modifier (percent)
        snowChance          = -30,                     --snow chance modifier (percent)
        dayChance           = 30,                       --day chance modifier (percent)
        nightChance         = -30,                     --night chance modifier (percent)
        zones = {                                       --zones where the item can be found
            Forest      	= 25,
            DeepForest  	= 35,
            PHForest  		= 15,                        --Acidic Forest
            PRForest  		= 35,                        --Primary Forest
            BirchForest  	= 25,
            OrganicForest  	= 35,
            Vegitation  	= 25,
            FarmLand    	= 25,
            Farm        	= 15,
            TrailerPark 	= 5,
            TownZone    	= 1,
            Nav             = 2,                       --Road
            ForagingNav 	= 2,                       --Road
        },
        months              = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },    --months when the item can be found
        validMonths         = {},                       --months when the item can be found
        bonusMonths         = {1, 2, 3, 11, 12},            --months when the item is more common (must be in months)
        malusMonths         = {4, 5, 6, 7},         --months when the item is less common (must be in months)
        spawnFuncs          = {},                       --custom spawn function when item is picked up
        
        forceOutside        = true,                     --item must be outside
        isOnWater           = false,                    --item can be on water
        forceOnWater        = false,                    --item must be on water
        canBeAboveFloor     = false,                    --does nothing, ignored
        doIsoMarkerSprite   = nil,                      --use a custom sprite/sprites for IsoMarker
        canBeOnTreeSquare   = true,                     --can occupy the same square as an IsoTree
        poisonChance        = 0,                        --percent chance the item is poisoned
        poisonPowerMin      = 0,                        --minimum amount of poison to apply
        poisonPowerMax      = 0,                        --maximum amount of poison to apply
        poisonDetectionLevel= 0,                        --level required to detect the poison
        itemSizeModifier    = 1.0,                      --increase or decrease item weight in vision radius checking
        isItemOverrideSize  = true,                    --use only itemSizeModifier in vision radius checking - not the real item weight
    }

    local WildHoneyComb = {
        type                = "Hold.WildHoneyComb",         --item type including module
        minCount            = 1,                        --minimum amount of items to pick up
        maxCount            = 2,                        --maximum amount of items to pick up
        skill               = 0,                        --skill level required to see the item
        perks               = { "Husbandry" },          --perks required - can be multiple perks, skill level will be averaged
        xp                  = 5,                        --xp reward on pickup - divide by 3 for spotting xp - is awarded to all perks required
        recipes             = {},                       --recipes required to see the item
        traits              = {},                       --traits required to see the item
        itemTags            = {},                       --itemTags required to see the item (digPlow etc)
        categories          = { "Insects" },            --categories the item is a part of
        rainChance          = -30,                     --rain chance modifier (percent)
        hasRainedChance     = 15,                       --after rain chance modifier (percent)
        snowChance          = -30,                     --snow chance modifier (percent)
        dayChance           = 30,                       --day chance modifier (percent)
        nightChance         = -30,                     --night chance modifier (percent)
        zones = {                                       --zones where the item can be found
            Forest      	= 25,
            DeepForest  	= 35,
            PHForest  		= 15,                        --Acidic Forest
            PRForest  		= 35,                        --Primary Forest
            BirchForest  	= 25,
            OrganicForest  	= 35,
            Vegitation  	= 25,
            FarmLand    	= 25,
            Farm        	= 15,
            TrailerPark 	= 5,
            TownZone    	= 1,
            Nav             = 2,                       --Road
            ForagingNav 	= 2,                       --Road
        },
        months              = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },    --months when the item can be found
        validMonths         = {},                       --months when the item can be found
        bonusMonths         = {1, 2, 3, 11, 12},            --months when the item is more common (must be in months)
        malusMonths         = {4, 5, 6, 7},         --months when the item is less common (must be in months)
        spawnFuncs          = {},                       --custom spawn function when item is picked up
        
        forceOutside        = true,                     --item must be outside
        isOnWater           = false,                    --item can be on water
        forceOnWater        = false,                    --item must be on water
        canBeAboveFloor     = false,                    --does nothing, ignored
        doIsoMarkerSprite   = nil,                      --use a custom sprite/sprites for IsoMarker
        canBeOnTreeSquare   = true,                     --can occupy the same square as an IsoTree
        poisonChance        = 0,                        --percent chance the item is poisoned
        poisonPowerMin      = 0,                        --minimum amount of poison to apply
        poisonPowerMax      = 0,                        --maximum amount of poison to apply
        poisonDetectionLevel= 0,                        --level required to detect the poison
        itemSizeModifier    = 1.0,                      --increase or decrease item weight in vision radius checking
        isItemOverrideSize  = true,                    --use only itemSizeModifier in vision radius checking - not the real item weight
    }

    -- B42.13+ is stricter when validating forage item scripts. Guard these additions
    -- so a missing or malformed item script cannot break world loading.
    local function safeAddForageItemDef(itemDef)
        if not itemDef or not itemDef.type then
            return
        end

        local scriptItem = ScriptManager.instance:FindItem(itemDef.type)
        if not scriptItem or scriptItem:getObsolete() then
            print("[ShelterHold:Beehive] Skipping forage item definition for missing item " .. tostring(itemDef.type))
            return
        end

        local ok, itemObj = pcall(instanceItem, itemDef.type)
        if ok and itemObj then
            forageSystem.addItemDef(itemDef)
        else
            print("[ShelterHold:Beehive] Skipping forage item definition for invalid item " .. tostring(itemDef.type))
        end
    end

    safeAddForageItemDef(Honeybee)
    safeAddForageItemDef(Zombee)
    safeAddForageItemDef(Bumblebee)
    safeAddForageItemDef(WildHoneyComb)

    forageSystem.generateLootTable()

end)