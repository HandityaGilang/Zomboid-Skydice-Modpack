local utils = require("ss.utils")

local color = utils.color
local getPColor = utils.fn.getPColor

local stats = {}
stats._reverse = {}
stats._values = {}

local baseRuler = { 75, 50, 25, 10 }
local baseRulerN = { 25, 50, 75, 90 }
------------
-- Health --
------------
table.insert(stats._values, "health")
stats.health = {}
stats.health.name = "health"
stats.health.type = "simple,postive"
stats.health.shown = true

stats.health.ruler = { 80, 60, 40, 25 }

stats.health.valueFn = function(player)
    return round(player:getBodyDamage():getHealth())
end
---------------
-- Endurance --
---------------
table.insert(stats._values, "endurance")
stats.endurance = {}
stats.endurance.name = "endurance"
stats.endurance.type = "simple,postive"
stats.endurance.shown = true

stats.endurance.ruler = baseRuler

stats.endurance.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.ENDURANCE) * 100)
end
-------------
-- Hunger --
-------------
table.insert(stats._values, "hunger")
stats.hunger = {}
stats.hunger.name = "hunger"
stats.hunger.type = "simple,postive"
stats.hunger.shown = true

stats.hunger.ruler = { 85, 75, 55, 30 }

stats.hunger.valueFn = function(player)
    return round((1 - player:getStats():get(CharacterStat.HUNGER)) * 100)
end
-------------
-- Thirst --
-------------
table.insert(stats._values, "thirst")
stats.thirst = {}
stats.thirst.name = "thirst"
stats.thirst.type = "simple,postive"
stats.thirst.shown = true

stats.thirst.ruler = { 88, 75, 30, 16 }

stats.thirst.valueFn = function(player)
    return round((1 - player:getStats():get(CharacterStat.THIRST)) * 100)
end
-------------
-- Fatigue --
-------------
table.insert(stats._values, "fatigue")
stats.fatigue = {}
stats.fatigue.name = "fatigue"
stats.fatigue.type = "simple,negative"
stats.fatigue.shown = true

stats.fatigue.ruler = { 60, 70, 80, 90 }

stats.fatigue.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.FATIGUE) * 100)
end
-------------
--   Rest  --
-------------
table.insert(stats._values, "rest")
stats.rest = {}
stats.rest.name = "rest"
stats.rest.type = "simple,postive"
stats.rest.shown = stats.fatigue.shown
stats._reverse.rest = "fatigue"

stats.rest.ruler = { 40, 30, 20, 10 }

stats.rest.valueFn = function(player)
    return 100 - stats.fatigue.valueFn(player)
end
--------------
--   Happy  --
--------------
table.insert(stats._values, "happy")
stats.happy = {}
stats.happy.name = "happy"
stats.happy.type = "simple,postive"
stats.happy.shown = true

stats.happy.ruler = { 80, 55, 40, 20 }

stats.happy.valueFn = function(player)
    return round((100 - player:getStats():get(CharacterStat.UNHAPPINESS)))
end

----------------
--   UnHappy  --
----------------
table.insert(stats._values, "unhappy")
stats.unhappy = {}
stats.unhappy.name = "unhappy"
stats.unhappy.type = "simple,negative"
stats.unhappy.shown = stats.happy.shown
stats._reverse.unhappy = "happy"

stats.unhappy.ruler = { 20, 45, 60, 80 }

stats.unhappy.valueFn = function(player)
    return 100 - stats.happy.valueFn(player)
end
----------------
--   Boredom  --
----------------
table.insert(stats._values, "boredom")
stats.boredom = {}
stats.boredom.name = "boredom"
stats.boredom.type = "simple,negative"
stats.boredom.shown = true

stats.boredom.ruler = baseRulerN

stats.boredom.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.BOREDOM))
end
----------------
--    Pain    --
----------------
table.insert(stats._values, "pain")
stats.pain = {}
stats.pain.name = "pain"
stats.pain.type = "simple,negative"
stats.pain.shown = true

stats.pain.ruler = { 10, 20, 50, 75 }

stats.pain.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.PAIN))
end
----------------
--    Panic   --
----------------
table.insert(stats._values, "panic")
stats.panic = {}
stats.panic.name = "panic"
stats.panic.type = "simple,negative"
stats.panic.shown = true

stats.panic.ruler = { 6, 30, 65, 80 }

stats.panic.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.PANIC))
end
----------------
--    Stress  --
----------------
table.insert(stats._values, "stress")
stats.stress = {}
stats.stress.name = "stress"
stats.stress.type = "simple,negative"
stats.stress.shown = true

stats.stress.ruler = baseRulerN

stats.stress.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.STRESS) * 100)
end
----------------
--  Sickness  --
----------------

table.insert(stats._values, "sickness")
stats.sickness = {}
stats.sickness.name = "sickness"
stats.sickness.type = "simple,negative"
stats.sickness.shown = true

stats.sickness.ruler = baseRulerN

stats.sickness.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.SICKNESS) * 100)
end
----------------
--    Anger   --
----------------
table.insert(stats._values, "anger")
stats.anger = {}
stats.anger.name = "anger"
stats.anger.type = "simple,negative"
stats.anger.shown = false

stats.anger.ruler = { 10, 25, 50, 75 }

stats.anger.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.ANGER) * 100)
end
----------------
--    Sanity  --
----------------
table.insert(stats._values, "sanity")
stats.sanity = {}
stats.sanity.name = "sanity"
stats.sanity.type = "simple,positive"
stats.sanity.shown = false

stats.sanity.ruler = baseRuler

stats.sanity.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.SANITY) * 100)
end
----------------
--   Proteins  --
----------------
table.insert(stats._values, "proteins")
stats.proteins = {}
stats.proteins.name = "proteins"
stats.proteins.type = "custom"

stats.proteins.shown = false


stats.proteins.valueFn = function(player)
    return round(player:getNutrition():getProteins(), 1)
end
stats.proteins.textFn = function(player)
    local value = stats.proteins.valueFn(player)
    local valueText = tostring(round(value, 1))
    if value >= 50 and value <= 300 then
        valueText = valueText .. "(x1.5)"
    elseif value <= -300 then
        valueText = valueText .. "(x0.7)"
    end
    return valueText
end
stats.proteins.colorFn = function(player)
    -- -500 -300 50 300 1000
    local value = stats.proteins.valueFn(player)
    if value < -300 then
        return color.red
    elseif value < 50 then
        return getPColor(color.red, color.green, (value + 300) / 350)
    elseif value < 300 then
        return color.green
    elseif value < 700 then
        return getPColor(color.green, color.yellow, (value - 300) / 400)
    else
        return getPColor(color.yellow, color.red, (value - 700) / 300)
    end
end
stats.proteins.percentFn = function(player)
    return (stats.proteins.valueFn(player) + 500) / 1500
end
-----------------
--   Calories  --
-----------------
table.insert(stats._values, "calories")
stats.calories = {}
stats.calories.name = "calories"
stats.calories.type = "plain,bg"
stats.calories.vs = { -2000, 1000, 3500 }
stats.calories.shown = false


stats.calories.valueFn = function(player)
    return round(player:getNutrition():getCalories(), 1)
end
----------------------
--   Carbohydrates  --
----------------------
table.insert(stats._values, "carbohydrates")
stats.carbohydrates = {}
stats.carbohydrates.name = "carbohydrates"
stats.carbohydrates.type = "plain,pg"
stats.carbohydrates.vs = { -500, 0, 1000 }
stats.carbohydrates.shown = false


stats.carbohydrates.valueFn = function(player)
    return round(player:getNutrition():getCarbohydrates(), 1)
end
----------------
--   Lipids  --
----------------
table.insert(stats._values, "lipids")
stats.lipids = {}
stats.lipids.name = "lipids"
stats.lipids.type = "plain,pg"
stats.lipids.vs = { -500, 0, 1000 }
stats.lipids.shown = false


stats.lipids.valueFn = function(player)
    return round(player:getNutrition():getLipids(), 1)
end
------------------
--   Dirtiness  --
------------------
table.insert(stats._values, "dirtiness")
stats.dirtiness = {}
stats.dirtiness.name = "dirtiness"
stats.dirtiness.type = "custom"
stats.dirtiness.shown = false

stats.dirtiness.valueFn = function(player)
    local visual = player:getHumanVisual()
    local v = 0
    for i = 1, BloodBodyPartType.MAX:index() do
        local part = BloodBodyPartType.FromIndex(i - 1)
        v = v + visual:getBlood(part) + visual:getDirt(part)
    end
    return v / (BloodBodyPartType.MAX:index() * 2)
end
stats.dirtiness.percentFn = stats.dirtiness.valueFn
stats.dirtiness.colorFn = function(player)
    local p = stats.dirtiness.percentFn(player)
    local c = color.white
    if p < 0.5 then
        c = getPColor(color.green, color.yellow, p * 2)
    else
        c = getPColor(color.yellow, color.red, (p * 2 - 1))
    end
    return c
end
stats.dirtiness.textFn = function(player)
    local value = stats.dirtiness.valueFn(player)
    return tostring(round(value * 100, 1)) .. " %"
end
------------------
--   Cleanliness  --
------------------
table.insert(stats._values, "cleanliness")
stats.cleanliness = {}
stats.cleanliness.name = "cleanliness"
stats.cleanliness.type = "custom"
stats.cleanliness.shown = stats.dirtiness.shown
stats._reverse.cleanliness = "dirtiness"

stats.cleanliness.valueFn = function(player)
    return 1 - stats.dirtiness.valueFn(player)
end
stats.cleanliness.percentFn = stats.cleanliness.valueFn
stats.cleanliness.colorFn = function(player)
    local p = stats.cleanliness.percentFn(player)
    local c = color.white
    if p > 0.5 then
        c = getPColor(color.yellow, color.green, p * 2 - 1)
    else
        c = getPColor(color.red, color.yellow, (p * 2))
    end
    return c
end
stats.cleanliness.textFn = function(player)
    local value = stats.cleanliness.valueFn(player)
    return tostring(round(value * 100, 1)) .. " %"
end
----------------
--   Weight  --
----------------
table.insert(stats._values, "weight")
stats.weight = {}
stats.weight.name = "weight"
stats.weight.type = "custom"
stats.weight.shown = true

stats.weight.valueFn = function(player)
    return round(player:getNutrition():getWeight(), 1)
end
stats.weight.percentFn = function()
    return 1
end
stats.weight.colorFn = function(player)
    local value = stats.weight.valueFn(player)
    if value > 100 then
        return color.red
    elseif value > 85 then
        return getPColor(color.green, color.red, (value - 85) / 15)
    elseif value > 75 then
        return color.green
    elseif value > 50 then
        return getPColor(color.blue, color.green, (value - 50) / 25)
    else
        return color.blue
    end
end
stats.weight.textFn = function(player)
    local value = stats.weight.valueFn(player)
    local valueText = "-"
    valueText = tostring(value) .. " kg"
    if player:getNutrition():isIncWeight() or player:getNutrition():isIncWeightLot() or player:getNutrition():isDecWeight() then
        if player:getNutrition():isIncWeight() and not player:getNutrition():isIncWeightLot() then
            valueText = valueText .. "  +"
        end
        if player:getNutrition():isIncWeightLot() then
            valueText = valueText .. "  ++"
        end
        if player:getNutrition():isDecWeight() then
            valueText = valueText .. "  -"
        end
    end
    return valueText
end
------------------------
--   Weight_Capacity  --
------------------------
table.insert(stats._values, "weight_capacity")
stats.weight_capacity = {}
stats.weight_capacity.name = "weight_capacity"
stats.weight_capacity.type = "custom"
stats.weight_capacity.shown = true

stats.weight_capacity.valueFn = function(player)
    return round(player:getInventoryWeight(), 2)
end
stats.weight_capacity.percentFn = function(player)
    local p = player:getInventoryWeight() / player:getMaxWeight()
    if p > 1 then
        return 1
    else
        return p
    end
end
stats.weight_capacity.textFn = function(player)
    return tostring(round(player:getInventoryWeight(), 2)) .. " / " .. tostring(round(player:getMaxWeight(), 2))
end
stats.weight_capacity.colorFn = function(player)
    local p = player:getInventoryWeight() / player:getMaxWeight()
    if p < 1 then
        return color.green
    elseif p < 1.25 then
        return getPColor(color.green, color.yellow, (p - 1) / 0.25)
    elseif p < 1.5 then
        return getPColor(color.yellow, color.orange, (p - 1.25) / 0.25)
    elseif p < 1.75 then
        return getPColor(color.orange, color.red, (p - 1.5) / 0.25)
    else
        return color.red
    end
end
----------------
--   bodytemp  --
----------------
table.insert(stats._values, "bodytemp")
stats.bodytemp = {}
stats.bodytemp.name = "bodytemp"
stats.bodytemp.type = "temp"
stats.bodytemp.shown = true

stats.bodytemp.valueFn = function(player)
    local thermos = player:getBodyDamage():getThermoregulator()
    return round(thermos:getCoreTemperature(), 1)
end
stats.bodytemp.percentFn = function(player)
    local thermos = player:getBodyDamage():getThermoregulator()
    return thermos:getCoreTemperatureUI()
end
stats.bodytemp.colorFn = function(player)
    local p = stats.bodytemp.percentFn(player)
    if p > 0.75 then
        return getPColor(color.yellow, color.red, (p - 0.75) * 4)
    elseif p > 0.5 then
        return getPColor(color.green, color.yellow, (p - 0.5) * 4)
    elseif p > 0.25 then
        return getPColor(color.cyan, color.green, (p - 0.25) * 4)
    else
        return getPColor(color.blue, color.cyan, p * 4)
    end
end
----------------
--   bodyheatgen  --
----------------
table.insert(stats._values, "bodyheatgen")
stats.bodyheatgen = {}
stats.bodyheatgen.name = "bodyheatgen"
stats.bodyheatgen.type = "temp"
stats.bodyheatgen.shown = false

stats.bodyheatgen.valueFn = function(player)
    local thermos = player:getBodyDamage():getThermoregulator()
    return round(thermos:getMetabolicRateReal(), 1)
end
stats.bodyheatgen.percentFn = function(player)
    local thermos = player:getBodyDamage():getThermoregulator()
    return thermos:getHeatGenerationUI()
end
stats.bodyheatgen.colorFn = function(player)
    local p = stats.bodyheatgen.percentFn(player)
    if p > 0.75 then
        return getPColor(color.yellow, color.red, (p - 0.75) * 4)
    elseif p > 0.5 then
        return getPColor(color.green, color.yellow, (p - 0.5) * 4)
    elseif p > 0.25 then
        return getPColor(color.cyan, color.green, (p - 0.25) * 4)
    else
        return getPColor(color.blue, color.cyan, p * 4)
    end
end
----------------
--   Wetness  --
----------------
table.insert(stats._values, "wetness")
stats.wetness = {}
stats.wetness.name = "wetness"
stats.wetness.type = "simple,negative"
stats.wetness.shown = false

stats.wetness.ruler = { 20, 40, 65, 85 }

stats.wetness.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.WETNESS))
end
--------------------
--  Intoxication  --
--------------------
table.insert(stats._values, "intoxication")
stats.intoxication = {}
stats.intoxication.name = "intoxication"
stats.intoxication.type = "simple,negative"
stats.intoxication.shown = true

stats.intoxication.ruler = { 10, 25, 50, 75 }

stats.intoxication.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.INTOXICATION))
end
----------------
--   Poison   --
----------------
table.insert(stats._values, "poison")
stats.poison = {}
stats.poison.name = "poison"
stats.poison.type = "simple,negative"
stats.poison.shown = false

stats.poison.ruler = { 5, 20, 50, 75 }

stats.poison.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.POISON))
end
---------------------
--  Food_Sickness  --
---------------------
table.insert(stats._values, "food_sickness")
stats.food_sickness = {}
stats.food_sickness.name = "food_sickness"
stats.food_sickness.type = "simple,negative"
stats.food_sickness.shown = false

stats.food_sickness.ruler = baseRulerN

stats.food_sickness.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.FOOD_SICKNESS))
end
------------------------
--  Zombie_Infection  --
------------------------
table.insert(stats._values, "zombie_infection")
stats.zombie_infection = {}
stats.zombie_infection.name = "zombie_infection"
stats.zombie_infection.type = "simple,negative"
stats.zombie_infection.shown = true

stats.zombie_infection.ruler = { 5, 15, 40, 70 }

stats.zombie_infection.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.ZOMBIE_INFECTION))
end
--------------------
--  Zombie_Fever  --
--------------------
table.insert(stats._values, "zombie_fever")
stats.zombie_fever = {}
stats.zombie_fever.name = "zombie_fever"
stats.zombie_fever.type = "simple,negative"
stats.zombie_fever.shown = true

stats.zombie_fever.ruler = { 10, 25, 50, 75 }

stats.zombie_fever.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.ZOMBIE_FEVER))
end
---------------------------
--  Nicotine_Withdrawal  --
---------------------------
table.insert(stats._values, "nicotine_withdrawal")
stats.nicotine_withdrawal = {}
stats.nicotine_withdrawal.name = "nicotine_withdrawal"
stats.nicotine_withdrawal.type = "custom"
stats.nicotine_withdrawal.shown = true

stats.nicotine_withdrawal.valueFn = function(player)
    return player:getStats():get(CharacterStat.NICOTINE_WITHDRAWAL)
end
stats.nicotine_withdrawal.percentFn = function(player)
    return stats.nicotine_withdrawal.valueFn(player) / 0.51
end
stats.nicotine_withdrawal.textFn = function(player)
    return tostring(round(stats.nicotine_withdrawal.percentFn(player) * 100)) .. " / 100"
end
stats.nicotine_withdrawal.colorFn = function(player)
    local p = stats.nicotine_withdrawal.percentFn(player)
    if p < 0.25 then
        return color.green
    elseif p < 0.5 then
        return getPColor(color.green, color.yellow, (p - 0.25) * 4)
    elseif p < 0.75 then
        return getPColor(color.yellow, color.orange, (p - 0.5) * 4)
    else
        return getPColor(color.orange, color.red, (p - 0.75) * 4)
    end
end
----------------
--   Fitness  --
----------------
table.insert(stats._values, "fitness")
stats.fitness = {}
stats.fitness.name = "fitness"
stats.fitness.type = "custom"
stats.fitness.shown = false

stats.fitness.valueFn = function(player)
    return player:getStats():get(CharacterStat.FITNESS)
end
stats.fitness.percentFn = function(player)
    return (stats.fitness.valueFn(player) + 1) / 2
end
stats.fitness.textFn = function(player)
    local v = round(stats.fitness.valueFn(player) * 100)
    if v > 0 then
        return "+" .. tostring(v) .. " / 100"
    end
    return tostring(v) .. " / 100"
end
stats.fitness.colorFn = function(player)
    local p = stats.fitness.percentFn(player)
    if p > 0.5 then
        return getPColor(color.green, color.cyan, (p - 0.5) * 2)
    else
        return getPColor(color.red, color.green, p * 2)
    end
end
----------------
--   Morale   --
----------------
table.insert(stats._values, "morale")
stats.morale = {}
stats.morale.name = "morale"
stats.morale.type = "simple,postive"
stats.morale.shown = false

stats.morale.ruler = baseRuler

stats.morale.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.MORALE) * 100)
end
------------------
--  Discomfort  --
------------------
table.insert(stats._values, "discomfort")
stats.discomfort = {}
stats.discomfort.name = "discomfort"
stats.discomfort.type = "simple,negative"
stats.discomfort.shown = false

stats.discomfort.ruler = baseRulerN

stats.discomfort.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.DISCOMFORT))
end
----------------
--  Idleness  --
----------------
table.insert(stats._values, "idleness")
stats.idleness = {}
stats.idleness.name = "idleness"
stats.idleness.type = "simple,negative"
stats.idleness.shown = false

stats.idleness.ruler = baseRulerN

stats.idleness.valueFn = function(player)
    return round(player:getStats():get(CharacterStat.IDLENESS) * 100)
end
---------------

stats._reverse._values = {}
for k, v in pairs(stats._reverse) do
    if k ~= "_values" then
        table.insert(stats._reverse._values, v)
    end
end

-- SIMPLESTATUS_STATS = stats
return stats
