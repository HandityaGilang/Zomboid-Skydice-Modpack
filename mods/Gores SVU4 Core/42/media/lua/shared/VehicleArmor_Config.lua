--========================================================
-- VEHICLE ARMOR CONFIG  (B42.19)
-- Shared between client and server.
--
-- Changes from previous version:
--   • FuelUse is now per-grade (Install, Repair, Uninstall)
--     rather than a single flat value.
--   • Install recipes rebalanced across all four grades.
--   • WeldingRods added as Apocalypse install ingredient.
--   • Repair recipes rebalanced; no WeldingRods in repairs
--     to encourage patching over reinstalling.
--   • Uninstall returns are now fixed flat values rather
--     than a percentage of install cost.
--   • ArmorDurability table added for damage system.
--========================================================

VehicleArmorConfig = {}

----------------------------------------------------------
-- GRADE ORDER (drives UI tab order)
----------------------------------------------------------
VehicleArmorConfig.Grades = {
    "Scrap",
    "Standard",
    "Reinforced",
    "Apocalypse",
}

----------------------------------------------------------
-- COMPATIBLE VEHICLE PARTS
-- Shared source of truth for UI / future systems.
-- Gameplay support remains part-id based, so modded
-- vehicles using these IDs can be detected automatically.
----------------------------------------------------------
VehicleArmorConfig.AllowedParts = {
    EngineDoor       = true,
    Hood             = true,
    TruckBed         = true,
    TruckBedOpen     = true,
    TrunkDoor        = true,
    DoorFrontLeft    = true,
    DoorFrontRight   = true,
    DoorRearLeft     = true,
    DoorRearRight    = true,
    Windshield       = true,
    WindshieldFront  = true,
    WindshieldRear   = true,
    RearWindshield   = true,
    WindowFrontLeft  = true,
    WindowFrontRight = true,
    WindowRearLeft   = true,
    WindowRearRight  = true,
    HeadlightLeft    = true,
    HeadlightRight   = true,
    GasTank          = true,
    TrailerTrunk     = true,
    TrailerAnimalFood = true,
    TrailerAnimalEggs = true,
    KI5TRTrunk       = true,
    KI5TRCLTrunk     = true,
    KI5TRCMTrunk     = true,
    KI5TRCSTrunk     = true,
}

----------------------------------------------------------
-- VEHICLE PART DISPLAY LABELS
----------------------------------------------------------
VehicleArmorConfig.PartLabels = {
    EngineDoor       = "Hood",
    Hood             = "Hood",
    TruckBed         = "Truck Bed",
    TruckBedOpen     = "Truck Bed",
    TrunkDoor        = "Trunk Door",
    DoorFrontLeft    = "Front Left Door",
    DoorFrontRight   = "Front Right Door",
    DoorRearLeft     = "Rear Left Door",
    DoorRearRight    = "Rear Right Door",
    Windshield       = "Front Windshield",
    WindshieldFront  = "Front Windshield",
    WindshieldRear   = "Rear Windshield",
    RearWindshield   = "Rear Windshield",
    WindowFrontLeft  = "Front Left Window",
    WindowFrontRight = "Front Right Window",
    WindowRearLeft   = "Rear Left Window",
    WindowRearRight  = "Rear Right Window",
    HeadlightLeft    = "Left Headlight",
    HeadlightRight   = "Right Headlight",
    GasTank          = "Gas Tank",
    TrailerTrunk     = "Trailer Storage",
    TrailerAnimalFood = "Animal Food Trailer",
    TrailerAnimalEggs = "Animal Egg Trailer",
    KI5TRTrunk       = "Trailer Trunk Body",
    KI5TRCLTrunk     = "Trailer Trunk Body",
    KI5TRCMTrunk     = "Trailer Trunk Body",
    KI5TRCSTrunk     = "Trailer Trunk Body",
}

function VehicleArmorConfig.isAllowedPart(partId)
    return partId ~= nil
       and VehicleArmorConfig.AllowedParts ~= nil
       and VehicleArmorConfig.AllowedParts[partId] == true
end

local function GAA_SafeCall(obj, methodName)
    if not obj or not methodName then return nil end
    local fn = obj[methodName]
    if not fn then return nil end
    local ok, result = pcall(function()
        return fn(obj)
    end)
    if ok then return result end
    return nil
end

local function GAA_NormaliseItemId(value)
    if not value then return "" end
    return tostring(value):lower()
end

local function GAA_GetVehiclePartItemText(part)
    if not part then return "" end

    local item = GAA_SafeCall(part, "getInventoryItem")
    if item then
        local fullType = GAA_SafeCall(item, "getFullType")
        local itemType = GAA_SafeCall(item, "getType")
        local name = GAA_SafeCall(item, "getName")
        local display = GAA_SafeCall(item, "getDisplayName")

        return table.concat({
            tostring(fullType or ""),
            tostring(itemType or ""),
            tostring(name or ""),
            tostring(display or ""),
        }, " ")
    end

    local itemType = GAA_SafeCall(part, "getItemType")
    if itemType then
        return tostring(itemType)
    end

    return ""
end

function VehicleArmorConfig.getSmartPartLabel(partId, part, vehicle)
    if not partId then return "" end

    -- KI5/DAMN trailer doors and hard lids normally use the normal
    -- vehicle part ID "TrunkDoor" with different installed item types.
    -- Keep armour behaviour part-id based, but make the UI label reflect
    -- what is actually installed on that vehicle.
    if tostring(partId) == "TrunkDoor" then
        if not part and vehicle and vehicle.getPartById then
            local ok, result = pcall(function()
                return vehicle:getPartById(partId)
            end)
            if ok then part = result end
        end

        local itemText = GAA_NormaliseItemId(GAA_GetVehiclePartItemText(part))

        if itemText ~= "" then
            if itemText:find("rolldoor") or itemText:find("roll door") then
                return "Cargo Roll Door"
            end

            if itemText:find("splitdoorsramp") or itemText:find("split doors ramp") or itemText:find("split doors/ramp") then
                return "Split Doors / Ramp"
            end

            if itemText:find("splitdoors") or itemText:find("split doors") then
                return "Split Doors"
            end

            if itemText:find("m101") and (itemText:find("trunkdoor") or itemText:find("trunk lid") or itemText:find("lid")) then
                return "M101 Trunk Lid"
            end

            if itemText:find("trunkdoor") or itemText:find("trunk lid") or itemText:find("lid") then
                return "Trailer Lid"
            end

            if itemText:find("tailgate") then
                return "Tailgate"
            end

            if itemText:find("door") then
                return "Trailer Door"
            end
        end
    end

    return VehicleArmorConfig.getPartLabel(partId)
end

function VehicleArmorConfig.getPartLabel(partId)
    if not partId then return "" end

    if VehicleArmorConfig.PartLabels
    and VehicleArmorConfig.PartLabels[partId]
    then
        return VehicleArmorConfig.PartLabels[partId]
    end

    local label = tostring(partId)
        :gsub("Window", "")
        :gsub("Door", "")
        :gsub("(%u)", " %1")
        :gsub("^%s+", "")

    if tostring(partId):find("Window") then
        return label .. " Window"
    end

    if tostring(partId):find("Door") then
        return label .. " Door"
    end

    return tostring(partId)
end

----------------------------------------------------------
-- PART TYPE HELPERS
----------------------------------------------------------
function VehicleArmorConfig.isHeadlightPart(partId)
    return partId ~= nil and tostring(partId):find("Headlight") ~= nil
end

function VehicleArmorConfig.isGasTankPart(partId)
    return partId == "GasTank"
end

function VehicleArmorConfig.getPartRecipeGroup(partId)
    if VehicleArmorConfig.isHeadlightPart(partId) then
        return "Headlight"
    end

    if VehicleArmorConfig.isGasTankPart(partId) then
        return "GasTank"
    end

    return "Body"
end

function VehicleArmorConfig.getInstallRecipe(partId, grade)
    local group = VehicleArmorConfig.getPartRecipeGroup(partId)
    return VehicleArmorConfig.Install
       and VehicleArmorConfig.Install[group]
       and VehicleArmorConfig.Install[group][grade]
end

function VehicleArmorConfig.getRepairRecipe(partId, grade)
    local group = VehicleArmorConfig.getPartRecipeGroup(partId)
    return VehicleArmorConfig.Repair
       and VehicleArmorConfig.Repair[group]
       and VehicleArmorConfig.Repair[group][grade]
end

function VehicleArmorConfig.getUninstallReturn(partId, grade)
    local group = VehicleArmorConfig.getPartRecipeGroup(partId)
    return VehicleArmorConfig.UninstallReturn
       and VehicleArmorConfig.UninstallReturn[group]
       and VehicleArmorConfig.UninstallReturn[group][grade]
end

function VehicleArmorConfig.isGradeAllowedForPart(partId, grade)
    return VehicleArmorConfig.getInstallRecipe(partId, grade) ~= nil
end

----------------------------------------------------------
-- WEIGHT ADDED TO VEHICLE MASS (kg per armoured part)
----------------------------------------------------------
VehicleArmorConfig.Weight = {
    Body = {
        Scrap      = 15,
        Standard   = 25,
        Reinforced = 45,
        Apocalypse = 65,
    },

    -- Headlight armor should be much lighter than full body panels.
    Headlight = {
        Scrap      = 2,
        Standard   = 4,
        Reinforced = 7,
        Apocalypse = 10,
    },

    -- GasTank armor is larger/heavier than headlight armor but
    -- still separate from normal body-panel balance.
    GasTank = {
        Standard   = 20,
        Reinforced = 35,
    },
}

----------------------------------------------------------
-- DAMAGE PROTECTION MULTIPLIER
-- Fraction of incoming damage that passes THROUGH the
-- armour and reaches the vehicle part underneath.
-- Lower = more protection.
--   1.00 = nothing absorbed  (Scrap is cosmetic)
--   0.20 = 80% absorbed      (Apocalypse)
----------------------------------------------------------
VehicleArmorConfig.Protection = {
    -- Fraction of incoming damage that reaches the vehicle part.
    -- Example: 0.85 means 85% passes through, 15% is absorbed.
    Scrap      = 0.85, -- light improvised protection
    Standard   = 0.65, -- practical welded panel
    Reinforced = 0.40, -- heavy layered armour
    Apocalypse = 0.20, -- extreme late-game protection
}

----------------------------------------------------------
-- ARMOR DURABILITY MULTIPLIER
-- Applied to the absorbed portion of a hit when
-- calculating armour panel HP loss.
-- > 1.0 = panel degrades faster (Scrap falls apart quick)
-- < 1.0 = panel is tough       (Apocalypse takes punishment)
----------------------------------------------------------
VehicleArmorConfig.ArmorDurability = {
    -- Applied to absorbed damage when reducing armour HP.
    -- Scrap helps, but breaks down quickly.
    -- Apocalypse absorbs a lot and degrades more slowly.
    Scrap      = 1.60,
    Standard   = 1.20,
    Reinforced = 0.95,
    Apocalypse = 0.65,
}

----------------------------------------------------------
-- BLOWTORCH FUEL CONSUMED PER ACTION (per grade)
-- More layers = more gas needed.
-- Apocalypse never exceeds one full torch per panel.
--
--   Install:   Scrap=1  Standard=2  Reinforced=3  Apocalypse=4
--   Repair:    Scrap=1  Standard=1  Reinforced=2  Apocalypse=2
--   Uninstall: Scrap=1  Standard=1  Reinforced=2  Apocalypse=2
----------------------------------------------------------
VehicleArmorConfig.FuelUse = {
    Install = {
        Scrap      = 0,
        Standard   = 1,
        Reinforced = 2,
        Apocalypse = 3,
    },
    Repair = {
        Scrap      = 0,
        Standard   = 1,
        Reinforced = 2,
        Apocalypse = 2,
    },
    Uninstall = {
        Scrap      = 0,
        Standard   = 1,
        Reinforced = 2,
        Apocalypse = 2,
    },
    InstallByPart = {
        Headlight = {
            Scrap      = 0,
            Standard   = 1,
            Reinforced = 2,
            Apocalypse = 2,
        },
        GasTank = {
            Standard   = 1,
            Reinforced = 2,
        },
    },
}

function VehicleArmorConfig.getInstallFuelUse(partId, grade)
    local group = VehicleArmorConfig.getPartRecipeGroup and VehicleArmorConfig.getPartRecipeGroup(partId) or "Body"
    local byPart = VehicleArmorConfig.FuelUse and VehicleArmorConfig.FuelUse.InstallByPart and VehicleArmorConfig.FuelUse.InstallByPart[group]
    if byPart and byPart[grade] ~= nil then return byPart[grade] end
    return VehicleArmorConfig.FuelUse and VehicleArmorConfig.FuelUse.Install and VehicleArmorConfig.FuelUse.Install[grade] or 0
end

----------------------------------------------------------
-- INSTALL MATERIAL COSTS
--
-- All values must be whole numbers.
-- Body panels are more expensive than headlight covers.
-- Apocalypse requires WeldingRods (Base.WeldingRods) as
-- a hard gate — rare vanilla item, not craftable easily.
--
-- Body progression philosophy:
--   Scrap      — free and dirty, day-one viable
--   Standard   — sheets + screws, "plates bolted on"
--   Reinforced — sheets + bars + screws, structural
--   Apocalypse — sheets + bars + screws + rods, Mad Max spikes
--
-- Headlight progression philosophy:
--   Scrap      — loose scrap over the lens
--   Standard   — scrap cage with screws
--   Reinforced — sheet + bar frame with screws
--   Apocalypse — pure bar cage with a welding rod
----------------------------------------------------------
VehicleArmorConfig.Install = {

    Body = {
        Scrap      = { scrap=3, screws=4 },
        Standard   = { sheets=2, screws=4 },
        Reinforced = { sheets=3, bars=3, screws=8 },
        Apocalypse = { sheets=3, bars=6, screws=8, rods=0.2 },
    },

    Headlight = {
        Scrap      = { scrap=1, screws=2 },
        Standard   = { scrap=1, screws=4 },
        Reinforced = { sheets=1, bars=1, screws=4 },
        Apocalypse = { bars=2, screws=6, rods=0.1 },
    },

    -- Gas tank armor is deliberately limited to Standard
    -- and Reinforced: enough protection to matter, without
    -- improvised scrap or extreme apocalypse-tier fuel tanks.
    GasTank = {
        Standard   = { sheets=2, bars=1, screws=4 },
        Reinforced = { sheets=3, bars=3, screws=6 },
    },
}

----------------------------------------------------------
-- REPAIR MATERIAL COSTS  (base: full 0 -> 100 repair)
-- Scaled by missing HP before consumption so a barely-
-- damaged panel is cheap to fix.
--
-- No WeldingRods in any repair recipe — patching, not
-- fabricating. Keeps rods scarce and encourages players
-- to maintain panels rather than strip and redo.
--
-- Any repair recipe that uses screws requires exactly
-- half the screws used by its matching install recipe.
----------------------------------------------------------
VehicleArmorConfig.Repair = {

    Body = {
        Scrap      = { scrap=2 },
        Standard   = { sheets=1, screws=2 },
        Reinforced = { sheets=2, bars=2,  screws=4 },
        Apocalypse = { sheets=2, bars=3,  screws=4 },
    },

    Headlight = {
        Scrap      = { scrap=1 },
        Standard   = { scrap=1, screws=2 },
        Reinforced = { bars=1,  screws=2 },
        Apocalypse = { bars=1,  screws=3 },
    },

    GasTank = {
        Standard   = { sheets=1, screws=2 },
        Reinforced = { sheets=2, bars=2, screws=3 },
    },
}

----------------------------------------------------------
-- UNINSTALL RETURNS
-- Fixed flat values — predictable so players can plan.
-- Rods are NOT returned (consumed in the weld).
-- Headlights return scrap only, scaling 0/1/2/3.
--
-- Body:
--   Scrap      = 1 scrap
--   Standard   = 1 sheet
--   Reinforced = 2 sheets
--   Apocalypse = 2 sheets, 1 bar
--
-- Headlight:
--   Scrap      = 0
--   Standard   = 1 scrap
--   Reinforced = 2 scrap
--   Apocalypse = 3 scrap
----------------------------------------------------------
VehicleArmorConfig.UninstallReturn = {

    Body = {
        Scrap      = { scrap=1 },
        Standard   = { sheets=1 },
        Reinforced = { sheets=2 },
        Apocalypse = { sheets=2, bars=1 },
    },

    Headlight = {
        Scrap      = {},
        Standard   = { scrap=1 },
        Reinforced = { scrap=2 },
        Apocalypse = { scrap=3 },
    },

    GasTank = {
        Standard   = { sheets=1 },
        Reinforced = { sheets=2, bars=1 },
    },
}

----------------------------------------------------------
-- TIMED-ACTION DURATION (game ticks)
-- Used as the base for install time.
-- Repair time is derived from this scaled by missing HP.
----------------------------------------------------------
VehicleArmorConfig.Time = {
    Scrap      = 150,
    Standard   = 250,
    Reinforced = 350,
    Apocalypse = 500,
}

----------------------------------------------------------
-- Skill level requirements for installing each grade
-- Repairs and uninstall actions intentionally do not use
-- these requirements so existing armor can still be maintained.
----------------------------------------------------------
VehicleArmorConfig.LevelRequirements = {
    Scrap = {
        Mechanics = 1,
    },

    Standard = {
        MetalWelding = 3,
        Mechanics    = 2,
    },

    Reinforced = {
        MetalWelding = 5,
        Mechanics    = 4,
    },

    Apocalypse = {
        MetalWelding = 7,
        Mechanics    = 6,
    },
}

----------------------------------------------------------
-- Welding noise settings
-- Radius controls how far zombies may hear the work.
-- Volume controls the strength/priority of the world sound.
----------------------------------------------------------
VehicleArmorConfig.Sound = VehicleArmorConfig.Sound or {}

VehicleArmorConfig.Sound.Install = {
    Radius = {
        Scrap      = 18,
        Standard   = 22,
        Reinforced = 26,
        Apocalypse = 32,
    },
    Volume = 10,
}

VehicleArmorConfig.Sound.Repair = {
    Radius = {
        Scrap      = 12,
        Standard   = 15,
        Reinforced = 18,
        Apocalypse = 22,
    },
    Volume = 8,
}

VehicleArmorConfig.Sound.Uninstall = {
    Radius = {
        Scrap      = 14,
        Standard   = 18,
        Reinforced = 22,
        Apocalypse = 26,
    },
    Volume = 9,
}


----------------------------------------------------------
-- SANDBOX OPTIONS
----------------------------------------------------------
VehicleArmorConfig.SandboxPrefix = "GoresSVU4Core"

VehicleArmorConfig.SandboxDefaults = {
    ArmorDurabilityMultiplier = 1.0,
    ScrapProtectionPercent      = 15,
    StandardProtectionPercent   = 35,
    ReinforcedProtectionPercent = 60,
    ApocalypseProtectionPercent = 80,
    MaterialCostMultiplier    = 1.0,
    XPRewardMultiplier        = 1.0,
    SoundRadiusMultiplier     = 1.0,
    ArmorWeightMultiplier     = 1.0,
    GasLeakRateMultiplier     = 1.0,
    EnableSkillRequirements   = true,
    EnableArmorWeight         = true,
    EnableAdminLogs           = true,
    MultiInstallMode          = 3, -- 1 single only, 2 one-grade batch, 3 mixed-grade batch
    MaxQueuedActions          = 3, -- 1=3, 2=5, 3=10, 4=unlimited
    EnableScrapArmorGrade     = true,
    EnableStandardArmorGrade  = true,
    EnableReinforcedArmorGrade = true,
    EnableApocalypseArmorGrade = true,
    GasTankPunctureDamage     = 20,
    GasTankLeakClearCondition = 90,

    -- Random survivor armor: old world vehicles can spawn with
    -- one or more worn armor panels already installed.
    EnableRandomSurvivorArmor = false,
    RandomArmorScrapChance = 8.0,
    RandomArmorStandardChance = 4.0,
    RandomArmorReinforcedChance = 2.0,
    RandomArmorApocalypseChance = 0.5,
    RandomArmorMinHealth = 10,
    RandomArmorMaxHealth = 65,
    RandomArmorMaxPanels = 1,
}

function VehicleArmorConfig.getSandboxOption(name)
    local defaults = VehicleArmorConfig.SandboxDefaults or {}
    local default = defaults[name]

    if SandboxVars
    and SandboxVars[VehicleArmorConfig.SandboxPrefix]
    and SandboxVars[VehicleArmorConfig.SandboxPrefix][name] ~= nil
    then
        return SandboxVars[VehicleArmorConfig.SandboxPrefix][name]
    end

    if getSandboxOptions then
        local options = getSandboxOptions()
        if options and options.getOptionByName then
            local option = options:getOptionByName(
                VehicleArmorConfig.SandboxPrefix .. "." .. tostring(name)
            )

            if option and option.getValue then
                local ok, value = pcall(function()
                    return option:getValue()
                end)

                if ok and value ~= nil then
                    return value
                end
            end
        end
    end

    return default
end

function VehicleArmorConfig.getSandboxNumber(name)
    local value = tonumber(VehicleArmorConfig.getSandboxOption(name))
    if value == nil then
        return tonumber(VehicleArmorConfig.SandboxDefaults[name]) or 1.0
    end
    return value
end

function VehicleArmorConfig.getSandboxBool(name)
    local value = VehicleArmorConfig.getSandboxOption(name)

    if value == true or value == "true" or value == 1 or value == "1" then
        return true
    end

    if value == false or value == "false" or value == 0 or value == "0" then
        return false
    end

    return VehicleArmorConfig.SandboxDefaults[name] == true
end

function VehicleArmorConfig.getArmorDurabilityMultiplier()
    return VehicleArmorConfig.getSandboxNumber("ArmorDurabilityMultiplier")
end

function VehicleArmorConfig.getProtectionPercent(grade)
    local keyByGrade = {
        Scrap      = "ScrapProtectionPercent",
        Standard   = "StandardProtectionPercent",
        Reinforced = "ReinforcedProtectionPercent",
        Apocalypse = "ApocalypseProtectionPercent",
    }

    local key = keyByGrade[grade]
    if not key then return 0 end

    return math.max(0, math.min(100, VehicleArmorConfig.getSandboxNumber(key)))
end

function VehicleArmorConfig.getProtectionMultiplier(grade)
    local absorbed = VehicleArmorConfig.getProtectionPercent(grade)
    return math.max(0, math.min(1, 1 - (absorbed / 100)))
end

function VehicleArmorConfig.refreshProtectionFromSandbox()
    VehicleArmorConfig.Protection = VehicleArmorConfig.Protection or {}

    for _, grade in ipairs(VehicleArmorConfig.Grades or {}) do
        VehicleArmorConfig.Protection[grade] = VehicleArmorConfig.getProtectionMultiplier(grade)
    end
end

function VehicleArmorConfig.getMaterialCostMultiplier()
    return VehicleArmorConfig.getSandboxNumber("MaterialCostMultiplier")
end

function VehicleArmorConfig.getXPRewardMultiplier()
    return VehicleArmorConfig.getSandboxNumber("XPRewardMultiplier")
end

function VehicleArmorConfig.getSoundRadiusMultiplier()
    return VehicleArmorConfig.getSandboxNumber("SoundRadiusMultiplier")
end

function VehicleArmorConfig.getArmorWeightMultiplier()
    if not VehicleArmorConfig.getSandboxBool("EnableArmorWeight") then
        return 0
    end

    return VehicleArmorConfig.getSandboxNumber("ArmorWeightMultiplier")
end

function VehicleArmorConfig.getGasLeakRateMultiplier()
    return VehicleArmorConfig.getSandboxNumber("GasLeakRateMultiplier")
end

function VehicleArmorConfig.getGasTankPunctureDamage()
    return math.max(0, math.min(100, VehicleArmorConfig.getSandboxNumber("GasTankPunctureDamage")))
end

function VehicleArmorConfig.getGasTankLeakClearCondition()
    return math.max(0, math.min(100, VehicleArmorConfig.getSandboxNumber("GasTankLeakClearCondition")))
end

function VehicleArmorConfig.areSkillRequirementsEnabled()
    return VehicleArmorConfig.getSandboxBool("EnableSkillRequirements")
end

function VehicleArmorConfig.areAdminLogsEnabled()
    return VehicleArmorConfig.getSandboxBool("EnableAdminLogs")
end

function VehicleArmorConfig.isRandomSurvivorArmorEnabled()
    return VehicleArmorConfig.getSandboxBool("EnableRandomSurvivorArmor")
end

function VehicleArmorConfig.getRandomSurvivorArmorChance(grade)
    local keyByGrade = {
        Scrap      = "RandomArmorScrapChance",
        Standard   = "RandomArmorStandardChance",
        Reinforced = "RandomArmorReinforcedChance",
        Apocalypse = "RandomArmorApocalypseChance",
    }

    local key = keyByGrade[grade]
    if not key then return 0 end

    return math.max(0, math.min(100, VehicleArmorConfig.getSandboxNumber(key)))
end

function VehicleArmorConfig.getRandomSurvivorArmorHealthRange()
    local minHp = math.floor(math.max(1, math.min(100, VehicleArmorConfig.getSandboxNumber("RandomArmorMinHealth"))) + 0.5)
    local maxHp = math.floor(math.max(1, math.min(100, VehicleArmorConfig.getSandboxNumber("RandomArmorMaxHealth"))) + 0.5)

    if minHp > maxHp then
        minHp, maxHp = maxHp, minHp
    end

    return minHp, maxHp
end

function VehicleArmorConfig.getRandomSurvivorArmorMaxPanels()
    return math.max(1, math.min(32, math.floor(VehicleArmorConfig.getSandboxNumber("RandomArmorMaxPanels") + 0.5)))
end

function VehicleArmorConfig.getArmorWeight(grade, partId)
    local group = VehicleArmorConfig.getPartRecipeGroup
        and VehicleArmorConfig.getPartRecipeGroup(partId)
        or "Body"

    local base = 0

    if VehicleArmorConfig.Weight then
        if type(VehicleArmorConfig.Weight[group]) == "table" then
            base = VehicleArmorConfig.Weight[group][grade] or 0
        elseif VehicleArmorConfig.Weight[grade] then
            -- Legacy fallback for old flat weight tables.
            base = VehicleArmorConfig.Weight[grade] or 0
        end
    end

    return math.floor((base * VehicleArmorConfig.getArmorWeightMultiplier()) + 0.5)
end

function VehicleArmorConfig.getArmorDurability(grade)
    local base = VehicleArmorConfig.ArmorDurability
        and VehicleArmorConfig.ArmorDurability[grade]
        or 1.0

    return base * VehicleArmorConfig.getArmorDurabilityMultiplier()
end

function VehicleArmorConfig.getSoundRadius(actionType, grade)
    local base = 20

    if VehicleArmorConfig.Sound
    and VehicleArmorConfig.Sound[actionType]
    then
        local cfg = VehicleArmorConfig.Sound[actionType]
        if type(cfg.Radius) == "table" then
            base = cfg.Radius[grade] or base
        else
            base = cfg.Radius or base
        end
    end

    return math.floor((base * VehicleArmorConfig.getSoundRadiusMultiplier()) + 0.5)
end


----------------------------------------------------------
-- ADMIN / SANDBOX CONTROL HELPERS
----------------------------------------------------------
function VehicleArmorConfig.getMultiInstallMode()
    local raw = VehicleArmorConfig.getSandboxOption("MultiInstallMode")
    local value = tonumber(raw) or tonumber(VehicleArmorConfig.SandboxDefaults.MultiInstallMode) or 3

    if value <= 1 then return "single" end
    if value == 2 then return "grade" end
    return "multi"
end

function VehicleArmorConfig.getMultiInstallModeLabel()
    local mode = VehicleArmorConfig.getMultiInstallMode()
    if mode == "single" then return "Single install only" end
    if mode == "grade" then return "Batch, one grade only" end
    return "Full multi-install"
end

function VehicleArmorConfig.getMaxQueuedActions()
    local raw = VehicleArmorConfig.getSandboxOption("MaxQueuedActions")
    local value = tonumber(raw) or tonumber(VehicleArmorConfig.SandboxDefaults.MaxQueuedActions) or 3

    if value <= 1 then return 3 end
    if value == 2 then return 5 end
    if value == 3 then return 10 end
    return nil -- unlimited
end

function VehicleArmorConfig.getMaxQueuedActionsLabel()
    local maxActions = VehicleArmorConfig.getMaxQueuedActions()
    if not maxActions then return "Unlimited" end
    return tostring(maxActions)
end

function VehicleArmorConfig.isArmorGradeEnabled(grade)
    local keyByGrade = {
        Scrap      = "EnableScrapArmorGrade",
        Standard   = "EnableStandardArmorGrade",
        Reinforced = "EnableReinforcedArmorGrade",
        Apocalypse = "EnableApocalypseArmorGrade",
    }

    local key = keyByGrade[grade]
    if not key then return false end
    return VehicleArmorConfig.getSandboxBool(key)
end

function VehicleArmorConfig.getFirstEnabledArmorGrade()
    for _, grade in ipairs(VehicleArmorConfig.Grades or {}) do
        if VehicleArmorConfig.isArmorGradeEnabled(grade) then
            return grade
        end
    end

    return nil
end

function VehicleArmorConfig.areAnyArmorGradesEnabled()
    return VehicleArmorConfig.getFirstEnabledArmorGrade() ~= nil
end


if not VehicleArmorConfig.GSVU4_AdminSandboxWrapped then
    local GSVU4_OriginalGetInstallRecipe = VehicleArmorConfig.getInstallRecipe
    function VehicleArmorConfig.getInstallRecipe(partId, grade)
        if not VehicleArmorConfig.isArmorGradeEnabled(grade) then
            return nil
        end
        return GSVU4_OriginalGetInstallRecipe(partId, grade)
    end

    local GSVU4_OriginalIsGradeAllowedForPart = VehicleArmorConfig.isGradeAllowedForPart
    function VehicleArmorConfig.isGradeAllowedForPart(partId, grade)
        if not VehicleArmorConfig.isArmorGradeEnabled(grade) then
            return false
        end
        if GSVU4_OriginalIsGradeAllowedForPart then
            return GSVU4_OriginalIsGradeAllowedForPart(partId, grade)
        end
        return VehicleArmorConfig.getInstallRecipe(partId, grade) ~= nil
    end

    local GSVU4_OriginalRandomSurvivorArmorChance = VehicleArmorConfig.getRandomSurvivorArmorChance
    function VehicleArmorConfig.getRandomSurvivorArmorChance(grade)
        if not VehicleArmorConfig.isArmorGradeEnabled(grade) then
            return 0
        end
        return GSVU4_OriginalRandomSurvivorArmorChance(grade)
    end

    VehicleArmorConfig.GSVU4_AdminSandboxWrapped = true
end

return VehicleArmorConfig
