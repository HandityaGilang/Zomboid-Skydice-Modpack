if getActivatedMods():contains('\\jiggasGreenfireMod') then
    function SmokeHalfWeed(char)
        if char == nil then return end
        if getActivatedMods():contains("jiggasAddictionMod") then
            if char:getModData().potcount == nil then
                char:getModData().potcount = 0;
            end
            char:getModData().potcount = (char:getModData().potcount) + 1;
            if char:getModData().potcount > 3 then
                char:getModData().potcount = 3;
            end
        end
        char:getModData().gotstoned = 3;
        if char:getModData().stonedamt == nil then
            char:getModData().stonedamt = 0;
        end
        char:getModData().stonedamt = (char:getModData().stonedamt) + 1;
    end

    -- Partial versions for gradual effect application
    function SmokeKiefPartial(char, percent)
        if char == nil then return end
        if getActivatedMods():contains("jiggasAddictionMod") then
            if char:getModData().potcount == nil then
                char:getModData().potcount = 0;
            end
            char:getModData().potcount = (char:getModData().potcount) + percent * 2;
            if char:getModData().potcount > 3 then
                char:getModData().potcount = 3;
            end
        end
        char:getModData().gotstoned = 3;
        if char:getModData().stonedamt == nil then
            char:getModData().stonedamt = 0;
        end
        char:getModData().stonedamt = (char:getModData().stonedamt) + percent * 4;
    end

    function SmokeHashPartial(char, percent)
        if char == nil then return end
        if getActivatedMods():contains("jiggasAddictionMod") then
            if char:getModData().potcount == nil then
                char:getModData().potcount = 0;
            end
            char:getModData().potcount = (char:getModData().potcount) + percent * 3;
            if char:getModData().potcount > 3 then
                char:getModData().potcount = 3;
            end
        end
        char:getModData().gotstoned = 3;
        if char:getModData().stonedamt == nil then
            char:getModData().stonedamt = 0;
        end
        char:getModData().stonedamt = (char:getModData().stonedamt) + percent * 8;
    end

    function SmokeWeedPartial(char, percent)
        if char == nil then return end
        if getActivatedMods():contains("jiggasAddictionMod") then
            if char:getModData().potcount == nil then
                char:getModData().potcount = 0;
            end
            char:getModData().potcount = (char:getModData().potcount) + percent * 1;
            if char:getModData().potcount > 3 then
                char:getModData().potcount = 3;
            end
        end
        char:getModData().gotstoned = 3;
        if char:getModData().stonedamt == nil then
            char:getModData().stonedamt = 0;
        end
        char:getModData().stonedamt = (char:getModData().stonedamt) + percent * 2;
    end

    function SmokeHalfWeedPartial(char, percent)
        if char == nil then return end
        if getActivatedMods():contains("jiggasAddictionMod") then
            if char:getModData().potcount == nil then
                char:getModData().potcount = 0;
            end
            char:getModData().potcount = (char:getModData().potcount) + percent * 1;
            if char:getModData().potcount > 3 then
                char:getModData().potcount = 3;
            end
        end
        char:getModData().gotstoned = 3;
        if char:getModData().stonedamt == nil then
            char:getModData().stonedamt = 0;
        end
        char:getModData().stonedamt = (char:getModData().stonedamt) + percent * 1;
    end

    local itemConfigs = {
        ['Greenfire.Blunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 3)
                local bonus = 0
                local stonerbonus = 0
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll == 1 then
                        bonus = 90
                    else
                        bonus = 40
                        smokedhalf = true
                    end
                else
                    if diceroll ~= 3 then
                        stonerbonus = 20 + 10 / 3
                        if traits.Lucky then stonerbonus = 40 elseif traits.Unlucky then stonerbonus = 10 end
                    else
                        stonerbonus = 20 / 3
                        smokedhalf = true
                        if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 20 / 3 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Weed" }
                    halfItem = "Greenfire.HalfBlunt"
                else
                    smokeTypes = { "Kief" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 20 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.MixedBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 3)
                local bonus = 0
                local stonerbonus = 10 / 3 + 5
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Smoker then
                    if diceroll == 1 then
                        bonus = 45
                    else
                        bonus = 20
                        smokedhalf = true
                    end
                end
                if traits.Stoner then
                    if traits.Lucky then
                        stonerbonus = 20
                        if smokedhalf then stonerbonus = 7.5 end
                    elseif traits.Unlucky then
                        stonerbonus = 5
                        if smokedhalf then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "HalfWeed" }
                    halfItem = "Greenfire.HalfMixedBlunt"
                else
                    smokeTypes = { "Weed" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfMixedBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 20
                local stonerbonus = 10 / 3 + 5
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 7.5 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "HalfWeed" }, halfItem = nil }
            end
        },
        ['Greenfire.KiefBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 6)
                local bonus = 0
                local stonerbonus = 40 + 20 / 3
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll == 6 then
                        bonus = 80
                    else
                        bonus = 80
                        smokedhalf = true
                    end
                else
                    if diceroll >= 5 then
                        if traits.Lucky then stonerbonus = 80 elseif traits.Unlucky then stonerbonus = 20 end
                    else
                        smokedhalf = true
                        stonerbonus = 40 / 3
                        if traits.Lucky then stonerbonus = 30 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Kief" }
                    halfItem = "Greenfire.HalfKiefBlunt"
                else
                    smokeTypes = { "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfKiefBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 80
                local stonerbonus = 40 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 30 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Kief" }, halfItem = nil }
            end
        },
        ['Greenfire.HashBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 24)
                local bonus = 0
                local stonerbonus = 70
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll >= 22 then
                        bonus = 70
                    else
                        bonus = 70
                        smokedhalf = true
                    end
                else
                    if diceroll >= 21 then
                        if traits.Lucky then stonerbonus = 70 elseif traits.Unlucky then stonerbonus = 30 end
                    else
                        smokedhalf = true
                        stonerbonus = 20
                        if traits.Lucky then stonerbonus = 45 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Kief", "Weed" }
                    halfItem = "Greenfire.HalfHashBlunt"
                else
                    smokeTypes = { "Hash", "Kief" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfHashBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 70
                local stonerbonus = 20
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 45 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Kief", "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.SpaceBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 100)
                local bonus = 50
                local stonerbonus = 0
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll ~= 100 then
                        smokedhalf = true
                    end
                end
                diceroll = ZombRand(1, 24)
                if traits.Stoner then
                    if diceroll >= 22 then
                        stonerbonus = 50
                    else
                        smokedhalf = true
                        stonerbonus = 100 / 3
                        if traits.Lucky then stonerbonus = 50 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Hash", "Hash" }
                    halfItem = "Greenfire.HalfSpaceBlunt"
                else
                    smokeTypes = { "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfSpaceBlunt'] = {
            sicknessMultiplier = 7,
            thirstBase = 0.125,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 50
                local stonerbonus = 100 / 3
                if traits.Lucky then stonerbonus = 50 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash" }, halfItem = nil }
            end
        },
        ['Greenfire.Joint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 3)
                local bonus = 0
                local stonerbonus = 11 + 2 / 3
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll ~= 1 then
                        bonus = 45
                    else
                        bonus = 20
                        smokedhalf = true
                    end
                else
                    if traits.Lucky then stonerbonus = 20 elseif traits.Unlucky then stonerbonus = 0 end
                end
                if smokedhalf then
                    smokeTypes = { "HalfWeed" }
                    halfItem = "Greenfire.HalfJoint"
                else
                    smokeTypes = { "Weed" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfJoint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 20
                local stonerbonus = 10 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 7.5 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "HalfWeed" }, halfItem = nil }
            end
        },
        ['Greenfire.KiefJoint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 12)
                local bonus = 0
                local stonerbonus = 35
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll >= 11 then
                        bonus = 85
                    else
                        bonus = 35
                        smokedhalf = true
                    end
                else
                    if diceroll >= 7 then
                        if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 15 end
                    else
                        smokedhalf = true
                        stonerbonus = 10
                        if traits.Lucky then stonerbonus = 22.5 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Weed", "HalfWeed" }
                    halfItem = "Greenfire.HalfKiefJoint"
                else
                    smokeTypes = { "Kief", "Weed" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfKiefJoint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 35
                local stonerbonus = 10
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 22.5 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed", "HalfWeed" }, halfItem = nil }
            end
        },
        ['Greenfire.HashJoint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 48)
                local bonus = 0
                local stonerbonus = 75
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll >= 42 then
                        bonus = 75
                    else
                        bonus = 75
                        smokedhalf = true
                    end
                else
                    if diceroll >= 37 then
                        if traits.Lucky then stonerbonus = 58 + 1 / 3 elseif traits.Unlucky then stonerbonus = 25 end
                    else
                        smokedhalf = true
                        stonerbonus = 10 + 2 / 3
                        if traits.Lucky then stonerbonus = 37.5 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Kief", "HalfWeed" }
                    halfItem = "Greenfire.HalfHashJoint"
                else
                    smokeTypes = { "Weed", "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfHashJoint'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 75
                local stonerbonus = 10 + 2 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 37.5 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Kief", "HalfWeed" }, halfItem = nil }
            end
        },
        ['Greenfire.WeedBong'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 20 / 3
                if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.ShakeBong'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 20 / 3
                if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.WeedPipe'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 20 / 3
                if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.ShakePipe'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 20 / 3
                if traits.Lucky then stonerbonus = 15 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.KiefBong'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 80
                local stonerbonus = 10 + 10 / 3
                if traits.Lucky then stonerbonus = 30 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Kief" }, halfItem = nil }
            end
        },
        ['Greenfire.KiefPipe'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 80
                local stonerbonus = 10 + 10 / 3
                if traits.Lucky then stonerbonus = 30 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Kief" }, halfItem = nil }
            end
        },
        ['Greenfire.HashBong'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 60
                local stonerbonus = 20 + 20 / 3
                if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash" }, halfItem = nil }
            end
        },
        ['Greenfire.HashPipe'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.1,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 60
                local stonerbonus = 20 + 20 / 3
                if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash" }, halfItem = nil }
            end
        },
        ['Greenfire.Spliff'] = {
            sicknessMultiplier = 0,
            thirstBase = 0.05,
            hasFatigueHunger = false,
            extraSickIfNotSmoker = 7,
            compute = function(traits)
                local bonus = 20
                local stonerbonus = 10 / 3
                if traits.Lucky then stonerbonus = 15 / 2 elseif traits.Unlucky then stonerbonus = 0 end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "HalfWeed" }, halfItem = nil }
            end
        },
        ['Greenfire.CannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 24)
                local bonus = 70
                local stonerbonus = 70
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll < 22 then
                        smokedhalf = true
                    end
                else
                    if diceroll >= 21 then
                        if traits.Lucky then stonerbonus = 70 elseif traits.Unlucky then stonerbonus = 30 end
                    else
                        smokedhalf = true
                        stonerbonus = 20
                        if traits.Lucky then stonerbonus = 45 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Kief", "Weed" }
                    halfItem = "Greenfire.HalfCannaCigar"
                else
                    smokeTypes = { "Kief", "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 70
                local stonerbonus = 20
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 45 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Weed", "Kief" }, halfItem = nil }
            end
        },
        ['Greenfire.PreCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 100)
                local bonus = 60
                local stonerbonus = 60
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll < 94 then
                        smokedhalf = true
                    end
                else
                    if diceroll >= 86 then
                        if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 40 end
                    else
                        smokedhalf = true
                        stonerbonus = 80 / 3
                        if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Hash" }
                    halfItem = "Greenfire.HalfPreCannaCigar"
                else
                    smokeTypes = { "Hash", "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfPreCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 60
                local stonerbonus = 80 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 60 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash" }, halfItem = nil }
            end
        },
        ['Greenfire.DelCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 100)
                local bonus = 50
                local stonerbonus = 50
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll ~= 100 then
                        smokedhalf = true
                    end
                end
                diceroll = ZombRand(1, 24)
                if traits.Stoner then
                    if diceroll < 22 then
                        smokedhalf = true
                        stonerbonus = 100 / 3
                        if traits.Lucky then stonerbonus = 50 elseif traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Hash", "Weed" }
                    halfItem = "Greenfire.HalfDelCannaCigar"
                else
                    smokeTypes = { "Kief", "Hash", "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfDelCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 60
                local stonerbonus = 100 / 3
                if traits.Stoner then
                    if traits.Lucky then stonerbonus = 50 elseif traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash", "Weed" }, halfItem = nil }
            end
        },
        ['Greenfire.ResCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local diceroll = ZombRand(1, 100)
                local bonus = 40
                local stonerbonus = 40
                local smokedhalf = false
                local smokeTypes = {}
                local halfItem = nil
                if not traits.Stoner then
                    if diceroll ~= 100 then
                        smokedhalf = true
                    end
                end
                if traits.Stoner then
                    if diceroll < 99 then
                        smokedhalf = true
                        if traits.Unlucky then stonerbonus = 0 end
                    end
                end
                if smokedhalf then
                    smokeTypes = { "Kief", "Hash" }
                    halfItem = "Greenfire.HalfResCannaCigar"
                else
                    smokeTypes = { "Hash", "Hash", "Hash" }
                end
                return {
                    bonus = bonus,
                    stonerbonus = stonerbonus,
                    smokedhalf = smokedhalf,
                    smokeTypes = smokeTypes,
                    halfItem =
                        halfItem
                }
            end
        },
        ['Greenfire.HalfResCannaCigar'] = {
            sicknessMultiplier = 14,
            thirstBase = 0.15,
            hasFatigueHunger = true,
            extraSickIfNotSmoker = 0,
            compute = function(traits)
                local bonus = 40
                local stonerbonus = 40
                if traits.Stoner then
                    if traits.Unlucky then stonerbonus = 0 end
                end
                return { bonus = bonus, stonerbonus = stonerbonus, smokedhalf = false, smokeTypes = { "Hash", "Kief" }, halfItem = nil }
            end
        }
    }

    local function computeItemConfig(typ, character)
        local baseConfig = itemConfigs[typ]
        if not baseConfig then return nil end
        local traits = {
            Stoner = character:HasTrait("Stoner"),
            Lucky = character:HasTrait("Lucky"),
            Unlucky = character:HasTrait("Unlucky"),
            Smoker = character:HasTrait("Smoker")
        }
        local computed = baseConfig.compute(traits)
        return {
            bonus = computed.bonus,
            stonerbonus = computed.stonerbonus,
            smokedhalf = computed.smokedhalf,
            smokeTypes = computed.smokeTypes,
            halfItem = computed.halfItem,
            sicknessMultiplier = baseConfig.sicknessMultiplier,
            thirstBase = baseConfig.thirstBase,
            hasFatigueHunger = baseConfig.hasFatigueHunger,
            extraSickIfNotSmoker = baseConfig.extraSickIfNotSmoker
        }
    end

    function OnEat_WeedPartial(smokable)
        local character = smokable.player
        local food = smokable.item
        local percent = smokable.puffPercent
        if character == nil or percent <= 0 or percent > 1 then return end
        local modData = character:getModData()
        if modData.smokePartialData == nil then modData.smokePartialData = {} end
        local itemID = food:getID()
        local data = modData.smokePartialData[itemID]
        if data == nil then
            data = { totalPercent = 0 }
            modData.smokePartialData[itemID] = data
        end
        if not data.rolled then
            local typ = food:getFullType()
            local config = computeItemConfig(typ, character)
            if config == nil then
                return
            end
            data.bonus = config.bonus
            data.stonerbonus = config.stonerbonus
            data.smokedhalf = config.smokedhalf
            data.smokeTypes = config.smokeTypes
            data.halfItem = config.halfItem
            data.sicknessMultiplier = config.sicknessMultiplier
            data.thirstBase = config.thirstBase
            data.hasFatigueHunger = config.hasFatigueHunger
            data.extraSickIfNotSmoker = config.extraSickIfNotSmoker
            data.rolled = true
        end

        local partialMap = {
            Weed = SmokeWeedPartial,
            HalfWeed = SmokeHalfWeedPartial,
            Kief = SmokeKiefPartial,
            Hash = SmokeHashPartial
        }

        local stoned_before = modData.stonedamt or 0
        for _, stype in ipairs(data.smokeTypes) do
            partialMap[stype](character, percent)
        end
        local stoned_after = modData.stonedamt or 0
        local added_stoned = stoned_after - stoned_before

        local applyBonus = 0
        if not character:HasTrait("Stoner") then
            applyBonus = data.bonus * percent
        else
            applyBonus = data.stonerbonus * percent
        end

        character:getBodyDamage():setBoredomLevel(math.max(character:getBodyDamage():getBoredomLevel() - applyBonus, 0))
        character:getBodyDamage():setUnhappynessLevel(math.max(
            character:getBodyDamage():getUnhappynessLevel() - applyBonus, 0))
        character:getStats():setStress(math.max(character:getStats():getStress() - applyBonus, 0))

        local thirst = character:getStats():getThirst()
        if thirst < 0.4 then
            local add = data.thirstBase * percent
            thirst = thirst + add
            if thirst > 0.4 then thirst = 0.4 end
            character:getStats():setThirst(thirst)
        end

        local sick = character:getBodyDamage():getFoodSicknessLevel()
        sick = sick - data.sicknessMultiplier * added_stoned / 2
        if sick < 0 then sick = 0 end
        character:getBodyDamage():setFoodSicknessLevel(sick)

        if not character:HasTrait("Smoker") then
            sick = character:getBodyDamage():getFoodSicknessLevel() + data.extraSickIfNotSmoker * percent
            if sick > 100 then sick = 100 end
            character:getBodyDamage():setFoodSicknessLevel(sick)
        end

        if getActivatedMods():contains("jiggasAddictionMod") then
            modData.cigsmoked = true
        end

        if not character:HasTrait("Stoner") and data.hasFatigueHunger then
            local fatigue = character:getStats():getFatigue()
            local fatigueDelta = 0
            if fatigue < 0.6 then
                fatigueDelta = 0.6
            elseif fatigue >= 0.6 and fatigue < 0.8 then
                fatigueDelta = 0.05
            elseif fatigue >= 0.8 and fatigue < 1 then
                fatigueDelta = 0.025
            end
            fatigue = fatigue + fatigueDelta * percent
            if fatigue > 1 then fatigue = 1 end
            character:getStats():setFatigue(fatigue)

            local hunger = character:getStats():getHunger()
            local hungerDelta = 0
            if hunger < 0.4 then hungerDelta = 0.1 end
            character:getStats():setHunger(hunger + hungerDelta * percent)
        end

        if character:HasTrait("Smoker") then
            SmokerRelief(character, percent) -- Assuming SmokerRelief now accepts optional percent param for partial effect
        end

        data.totalPercent = data.totalPercent + percent
        if data.totalPercent >= 1 then
            modData.smokePartialData[itemID] = nil
        end
    end

    Events.OnCreatePlayer.Add(function()
        local smokableObjects = {}

        -- Common settings
        local common = {
            burnMin = 0.000165,
            burnMax = 0.000295,
            burnSpeed = 0.0030,
            burnSpeedDecay = 0.20,
            decayRate = 0.994,
            callback = OnEat_WeedPartial,
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            idleFactor = TrueSmoking.Options.IdleFactor,
            walkingFactor = TrueSmoking.Options.WalkingFactor,
            runningFactor = TrueSmoking.Options.RunningFactor,
            sprintingFactor = TrueSmoking.Options.SprintingFactor,
            puffFactor = TrueSmoking.Options.PuffFactor
        }

        -- Blunts and Joints (no color variants)
        local items = {
            { name = 'Blunt',             visual = 'Mask_Cigar',     length = 2.0 },
            { name = 'HalfBlunt',         visual = 'Mask_Cigar',     length = 1.0 },
            { name = 'MixedBlunt',        visual = 'Mask_Cigar',     length = 2.0 },
            { name = 'HalfMixedBlunt',    visual = 'Mask_Cigar',     length = 1.0 },
            { name = 'KiefBlunt',         visual = 'Mask_Cigar',     length = 2.5 },
            { name = 'HalfKiefBlunt',     visual = 'Mask_Cigar',     length = 1.25 },
            { name = 'HashBlunt',         visual = 'Mask_Cigar',     length = 3.0 },
            { name = 'HalfHashBlunt',     visual = 'Mask_Cigar',     length = 1.5 },
            { name = 'SpaceBlunt',        visual = 'Mask_Cigar',     length = 4.0 },
            { name = 'HalfSpaceBlunt',    visual = 'Mask_Cigar',     length = 2.0 },
            { name = 'Joint',             visual = 'Mask_Cigarette', length = 1.0 },
            { name = 'HalfJoint',         visual = 'Mask_Cigarette', length = 0.5 },
            { name = 'KiefJoint',         visual = 'Mask_Cigarette', length = 1.2 },
            { name = 'HalfKiefJoint',     visual = 'Mask_Cigarette', length = 0.6 },
            { name = 'HashJoint',         visual = 'Mask_Cigarette', length = 1.5 },
            { name = 'HalfHashJoint',     visual = 'Mask_Cigarette', length = 0.75 },
            { name = 'Spliff',            visual = 'Mask_Cigarette', length = 1.5 },
            { name = 'CannaCigar',        visual = 'Mask_Cigar',     length = 4.0 },
            { name = 'HalfCannaCigar',    visual = 'Mask_Cigar',     length = 2.0 },
            { name = 'PreCannaCigar',     visual = 'Mask_Cigar',     length = 4.5 },
            { name = 'HalfPreCannaCigar', visual = 'Mask_Cigar',     length = 2.25 },
            { name = 'DelCannaCigar',     visual = 'Mask_Cigar',     length = 5.0 },
            { name = 'HalfDelCannaCigar', visual = 'Mask_Cigar',     length = 2.5 },
            { name = 'ResCannaCigar',     visual = 'Mask_Cigar',     length = 5.5 },
            { name = 'HalfResCannaCigar', visual = 'Mask_Cigar',     length = 2.75 }
        }

        for _, item in ipairs(items) do
            smokableObjects['Greenfire.' .. item.name] = {
                visualItem = item.visual,
                smokeLength = item.length,
                burnMin = common.burnMin,
                burnMax = common.burnMax,
                burnSpeed = common.burnSpeed,
                burnSpeedDecay = common.burnSpeedDecay,
                decayRate = common.decayRate,
                callback = common.callback,
                conditions = common.conditions,
                idleFactor = common.idleFactor,
                walkingFactor = common.walkingFactor,
                runningFactor = common.runningFactor,
                sprintingFactor = common.sprintingFactor,
                puffFactor = common.puffFactor
            }
        end

        -- Pipes (no color variants, Mask_Pipe)
        local pipe_loads = {
            { type = 'Weed',  length = 1.2 },
            { type = 'Shake', length = 1.2 },
            { type = 'Kief',  length = 1.5 },
            { type = 'Hash',  length = 1.8 }
        }

        for _, load in ipairs(pipe_loads) do
            smokableObjects['Greenfire.' .. load.type .. 'Pipe'] = {
                visualItem = 'Mask_Pipe',
                smokeLength = load.length,
                burnMin = common.burnMin,
                burnMax = common.burnMax,
                burnSpeed = common.burnSpeed,
                burnSpeedDecay = common.burnSpeedDecay,
                decayRate = common.decayRate,
                callback = common.callback,
                conditions = common.conditions,
                idleFactor = common.idleFactor,
                walkingFactor = common.walkingFactor,
                runningFactor = common.runningFactor,
                sprintingFactor = common.sprintingFactor,
                puffFactor = common.puffFactor
            }
        end

        -- Bongs (with color variants, Mask_Pipe)
        local bong_colors = { '', 'red', 'persianpink', 'arabiangold', 'blue', 'green', 'purple', 'orange', 'yellow',
            'white', 'black' } -- Add more colors as needed to reach 24

        local bong_loads = {
            { type = 'Weed',  length = 0.8 },
            { type = 'Shake', length = 0.8 },
            { type = 'Kief',  length = 1.0 },
            { type = 'Hash',  length = 1.2 }
        }

        for _, color in ipairs(bong_colors) do
            local suffix = (color == '' and '' or '_' .. color)
            for _, load in ipairs(bong_loads) do
                local key = 'Greenfire.' .. load.type .. 'Bong' .. suffix
                smokableObjects[key] = {
                    visualItem = 'Mask_Pipe',
                    smokeLength = load.length,
                    burnMin = common.burnMin,
                    burnMax = common.burnMax,
                    burnSpeed = common.burnSpeed,
                    burnSpeedDecay = common.burnSpeedDecay,
                    decayRate = common.decayRate,
                    callback = common.callback,
                    conditions = common.conditions,
                    idleFactor = common.idleFactor,
                    walkingFactor = common.walkingFactor,
                    runningFactor = common.runningFactor,
                    sprintingFactor = common.sprintingFactor,
                    puffFactor = common.puffFactor
                }
            end
        end

        TrueSmoking:setSmokableObjects(smokableObjects)
    end)
end
