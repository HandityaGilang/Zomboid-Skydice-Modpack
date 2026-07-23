require 'TimedActions/ISBaseTimedAction'
require 'Utils'

Smokable = Smokable or {}
Smokable.__index = Smokable

function Smokable:new(item, player)
    local obj = {}
    setmetatable(obj, self)
    obj:init(item, player)
    return obj
end

function Smokable:init(item, player)
    self.item = item

    if instanceof(item, 'Drainable') then
        self.item = instanceItem('Base.CigaretteSingle')
        self.cigPack = item
    end

    self.player = player
    self.table = TrueSmoking:getPlayerReference(player)

    local data = self:getObject(self.item)
    for k, v in pairs(data) do
        self[k] = v
    end

    self.canDrop = self.conditions and self.conditions.canDrop or false

    if self.visualItem then
        self.table.visualItem = instanceItem(self.visualItem)
    else
        local hasVisualItem = self:getVisualItem(self.item)
        if hasVisualItem then
            self.table.visualItem = hasVisualItem
        end
    end
    print('TRUESMOKING::Custom Eat Sound' .. tostring(self.item:getCustomEatSound() or ''))
    self.onEat = self.item:getOnEat() or false

    local stats = self:getItemStats(self.item)
    stats.foodSick = data.foodSick or 0
    for k, v in pairs(stats) do
        self[k] = v
        local originalKey = 'original' .. k:sub(1, 1):upper() .. k:sub(2)
        self[originalKey] = v
    end

    self.replaceOnUse = self.item:getModData().replaceOnUse or false

    self.smokePercent = self.smokeLength / self.originalSmokeLength
    self.smokeLit = false
    self.puffPercent = 0.0
    self.burnRate = ZombRandFloat(self.burnMax * 0.75, self.burnMax * 1.15)
    self.hasRolledForDrop = false
end

function Smokable:getItemStats(item)
    return {
        stress = item:getStressChange() or -5,
        boredom = item:getBoredomChange() or 0,
        unhappyness = item:getUnhappyChange() or 0,
        fatigue = item:getFatigueChange() or 0,
        thirst = item:getThirstChange() or 0,
        hunger = item:getHungChange() or 0,
        pain = item:getPainReduction() or 0,
        endurance = item:getEnduranceChange() or 0,
        reduceFoodSick = item:getReduceFoodSickness() or 0,
    }
end

function Smokable:getObject(item)
    local fullType = item:getFullType()
    print('TRUESMOKING::Looking for: ' .. fullType)

    local ob = TrueSmoking.SmokableObjects[fullType]
    local o = ob and TrueSmoking.deepCopy(ob) or {}

    local g = TrueSmoking.Options.Global
    local cat = TrueSmoking.Options.Category

    -- Determine base smoke length (from SmokableObjects or global fallback)
    local baseLength = o.smokeLength or TrueSmoking.Options.SmokeLength

    -- Determine category burn multiplier
    local categoryMult = cat.Cigarette -- default
    if fullType:find("Cigar$") and not fullType:find("Cigarillo") then
        categoryMult = cat.Cigar
    elseif fullType:find("Cigarillo") then
        categoryMult = cat.Cigarillo
    elseif fullType:find("Pipe") or fullType:find("CanPipe") then
        categoryMult = cat.Pipe
    elseif fullType:find("Can") then
        categoryMult = cat.Can
    elseif fullType:find("Rolled") then
        categoryMult = cat.RolledCigarette
    end

    -- Recipe-based fallbacks (vanilla OnEat system)
    local onEat = item:getOnEat() or ""
    local recipeDefaults = {
        ["RecipeCodeOnEat.cigarettes"] = {
            smokeLength     = TrueSmoking.Options.CigaretteLength or baseLength,
            nicotineContent = 100,
            visualItem      = "Mask_Cigarette",
        },
        ["RecipeCodeOnEat.cigarillo"] = {
            smokeLength     = TrueSmoking.Options.CigarilloLength or baseLength,
            nicotineContent = 150,
            visualItem      = "Mask_Cigarillo",
            categoryMult    = cat.Cigarillo,
        },
        ["RecipeCodeOnEat.cigar"] = {
            smokeLength     = TrueSmoking.Options.CigarLength or baseLength,
            nicotineContent = 300,
            visualItem      = "Mask_Cigar",
            categoryMult    = cat.Cigar,
        },
    }

    local recipe = recipeDefaults[onEat]
    if recipe then
        for k, v in pairs(recipe) do
            if o[k] == nil then o[k] = v end
        end
        if recipe.categoryMult then categoryMult = recipe.categoryMult end
    end

    -- Final defaults (only applied if not set by modder or recipe)
    local defaults = {
        smokeLength     = baseLength,
        burnMin         = g.burnMin * categoryMult,
        burnMax         = g.burnMax * categoryMult,
        burnSpeed       = g.burnSpeed,
        burnSpeedDecay  = g.burnSpeedDecay,
        decayRate       = g.decayRate,
        puffFactor      = g.puffFactor,
        walkingFactor   = g.walkingFactor,
        runningFactor   = g.runningFactor,
        sprintingFactor = g.sprintingFactor,
        effectMultiplier = 1.0,
        nicotineContent = 40,
        conditions      = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
        visualItem      = "Mask_Cigarette",
        callback        = TrueSmoking.OnEat_Tobacco,
    }

    -- Apply defaults only where missing
    for k, v in pairs(defaults) do
        if o[k] == nil then
            o[k] = v
        end
    end

    -- Final setup
    o.fullType = fullType

    o.originalSmokeLength = o.smokeLength

    -- Load saved progress from modData (partially smoked cigs)
    local savedSmoke = self:getSavedSmokeLength(item)
    if savedSmoke then
        o.smokeLength = savedSmoke
    end

    -- Compatibility with SmokingSoundsOverhaul (halves puff burn to prevent double-puff bug)
    if getActivatedMods():contains('\\SmokingSoundsOverhaul') then
        o.puffFactor = o.puffFactor / 2
    end

    -- Save to item modData for persistence
    local modData = item:getModData()
    modData.SmokeLength = o.smokeLength
    modData.OriginalSmokeLength = o.originalSmokeLength

    return o
end

function Smokable:getSavedSmokeLength(item)
    local modData = item:getModData()
    if modData.SmokeLength then
        return modData.SmokeLength
    else
        return false
    end
end

function Smokable:equipVisualItem()
    if not TrueSmoking.Options.ManageHeadGear then return end
    if not self.player:getWornItem('Mask_Smoke') and self.table.visualItem then
        self.player:setWornItem(self.table.visualItem:getBodyLocation(), self.table.visualItem)
    elseif self.player:getWornItem('Mask_Smoke') then
        self.player:removeWornItem(self.player:getWornItem('Mask_Smoke'))
        self:equipVisualItem()
    end
end

function Smokable:removeVisualItem()
    if not TrueSmoking.Options.ManageHeadGear then return end
    if self.player:getWornItem('Mask_Smoke') then
        self.player:removeWornItem(self.player:getWornItem('Mask_Smoke'))
    end
end

function Smokable:getVisualItem(item)
    if not TrueSmoking.Options.ManageHeadGear then return false end

    local OnEat_Defaults = {
        ['OnEat_Cigarettes'] = 'Mask_Cigarette',
        ['OnEat_Cigarillo'] = 'Mask_Cigarillo',
        ['OnEat_Cigar'] = 'Mask_Cigar',
    }

    local typeMatches = {
        ['smokingpipe'] = 'Mask_Pipe',
        ['joint'] = 'Mask_Cigarette',
        ['blunt'] = 'Mask_Cigarillo',
        ['spliff'] = 'Mask_Cigarillo',
        ['can'] = false,
        ['bong'] = false,
    }

    local itemType = item:getFullType():lower()

    for pattern, itemName in pairs(typeMatches) do
        if itemType:find(pattern) then
            return itemName and instanceItem(itemName) or false
        end
    end

    for key, value in pairs(OnEat_Defaults) do
        if item:getOnEat() == key then return instanceItem(value) end
    end

    return false
end

function Smokable:light()
    if not ISTimedActionQueue.hasActionType(self.player, 'LightSmoke') then
        ISTimedActionQueue.add(LightSmoke:new(self.player))
    end
end

function Smokable:start()
    if not self.table.isSmoking then
        self.table.isSmoking = true
        if not TrueSmoking.Config.HideMoodles then
            self.table.SmokingMoodle:start()
        end
        local function updateWrapper()
            self:update()
        end
        Events.OnPlayerUpdate.Add(updateWrapper)
        self.updateWrapper = updateWrapper
        self:equipVisualItem()
        if self.cigPack then
            self.cigPack:setUsedDelta(self.cigPack:getCurrentUsesFloat() - self.cigPack:getUseDelta())
        else
            self.player:getInventory():Remove(self.item)
        end
    end

    if not self.smokeLit then
        self.smokeLit = true
        self.puffTimeMark = os.time()
        self.table.lightingEatSound = ''

        if self.burnRate == 0 then
            self.burnRate = ZombRandFloat(self.burnMin,
                self.burnMax)
        end
    end
end

function Smokable:putOut()
    if self.table.isSmoking and not ISTimedActionQueue.hasActionType(self.player, 'PutOut') then
        ISTimedActionQueue.add(PutOut:new(self.player))
    end
end

function Smokable:stop()
    self.table.isSmoking = false
    self.table.visualItem = false
    self.table.takingPuff = false
    self.smokeLit = false
    self.hasDropped = false
    self.dropState = false

    if not TrueSmoking.Config.HideMoodles then
        self.table.SmokingMoodle:stop()
    end

    self:removeVisualItem()

    if self.updateWrapper then
        Events.OnPlayerUpdate.Remove(self.updateWrapper)
        self.updateWrapper = nil
    end

    TrueSmoking:checkForMaskAndEquip(self.player)

    if self.item then
        local onUse = self.replaceOnUse
        if onUse and onUse ~= '' and self.smokeLength <= 0 then
            print('TRUESMOKING::adding item: ' .. self.replaceOnUse)
            TrueSmoking.addOnUseItem(self.player)
        end

        if self.smokeLength > 0 then
            self.player:getInventory():AddItem(self.item)
            self.player:getModData().Smokable = false
        end

        if self.smokeLength <= 0 then
            self.item:getModData().SmokeLength = 0
            self.player:getModData().Smokable = false
        end
    end
end

function Smokable:dropSmoke()
    local dropX, dropY, dropZ = ISTransferAction.GetDropItemOffset(self.player, self.player:getCurrentSquare(), self
        .item)
    self.player:getCurrentSquare():AddWorldInventoryItem(self.item, dropX, dropY, dropZ)
    self.item = false
    self.player:getModData().Smokable = false
    self:stop()
end

function Smokable:checkDropConditions()
    local state = TrueSmoking.getPlayerState(self.player)
    local dropStates = { ['CollideWithWallState'] = true }

    local ClimbFenceOutcome = self.player:GetVariable("ClimbFenceOutcome")
    local bumpType = self.player:getBumpType()
    local bumpTypes = { ['left'] = true, ['right'] = true }

    local result = ClimbFenceOutcome == 'fall' or dropStates[state] or bumpTypes[bumpType] or false

    return result
end

function Smokable:update()
    if TrueSmoking.Options.Dropping and self.canDrop then
        if not self.hasRolledForDrop and self:checkDropConditions() then
            self.hasRolledForDrop = true
            local roll = ZombRandFloat(0.0, 100.0)
            local dropChance = self.player:HasTrait('Smoker') and TrueSmoking.Options.DroppingChanceSmoker or
                TrueSmoking.Options.DroppingChanceNonSmoker
            if dropChance >= roll then
                self.hasDropped = true
            end
        end
        if self.hasRolledForDrop and not self:checkDropConditions() then
            self.hasRolledForDrop = false
            if self.hasDropped then
                self.hasDropped = false
                self:dropSmoke()
            end
        end
    end
    if self.smokeLit then
        local gameSpeed = TrueSmoking.getGameSpeedMultiplier()
        local isWalking = self.player:isWalking() and self.conditions['walking']
        local isRunning = self.player:isRunning() and self.conditions['running']
        local isSprinting = self.player:isSprinting() and self.conditions['sprinting']
        local isStrafing = self.player:isStrafing() and self.conditions['strafing']
        local isReading = ISTimedActionQueue.hasActionType(self.player, 'ISReadABook')

        local targetBurnRate
        if self.table.takingPuff then
            targetBurnRate = self.burnMax * self.puffFactor
        elseif isSprinting then
            targetBurnRate = self.burnMin * self.sprintingFactor
        elseif isRunning then
            targetBurnRate = self.burnMin * self.runningFactor
        elseif isWalking or isStrafing then
            targetBurnRate = self.burnMin * self.walkingFactor
        elseif isReading then
            targetBurnRate = self.burnMin * self.walkingFactor * 0.5
        else
            targetBurnRate = nil
        end

        if targetBurnRate then
            local adjustmentSpeed = self.burnSpeed
            local adjustmentSpeedDecay = self.burnSpeedDecay
            if self.burnRate > self.burnMax then
                adjustmentSpeed = adjustmentSpeed * adjustmentSpeedDecay
            end
            self.burnRate = self.burnRate + (targetBurnRate - self.burnRate) * adjustmentSpeed * gameSpeed
        else
            local decayFactor = self.decayRate
            self.burnRate = self.burnRate * (decayFactor ^ gameSpeed)
        end

        self.puffPercent = self.burnRate * gameSpeed / self.originalSmokeLength
        self.smokeLength = self.smokeLength - self.burnRate * gameSpeed
        self.smokePercent = self.smokeLength / self.originalSmokeLength

        TrueSmoking.OnEat_ItemStats(self)

        if TrueSmoking.Options.UseNicotineSystem and self.puffPercent > 0 and self.nicotineContent then
            local nicotineAmount = self.nicotineContent * self.puffPercent
            NicotineSystem:smoke(self.player, nicotineAmount, self.nicotineContent)
        end

        if self.callback then
            self.callback(self)
        end

        for _, func in ipairs(TrueSmoking.Callbacks) do
            func(self)
        end

        self.item:getModData().SmokeLength = self.smokeLength
        self.player:getModData().Smokable = { self.item:getFullType(), self.smokeLength }

        self:idlePuff()
    end

    if TrueSmoking.Options.SmokeRelighting and self.burnRate < 0.0000025 then
        self.burnRate = 0
        self.smokeLit = false
    elseif not TrueSmoking.Options.SmokeRelighting and self.burnRate < self.burnMin then
        self.burnRate = self.burnMin
    end

    if self.smokeLength <= 0 then
        self.smokeLength = 0
        self.smokeLit = false
        if TrueSmoking.Config.AutoPutOut then
            self:putOut()
        end
    end
end

function Smokable:puff()
    if not ISTimedActionQueue.hasActionType(self.player, 'TakePuff') then
        ISTimedActionQueue.add(TakePuff:new(self.player))
    end
end

function Smokable:idlePuff()
    local timeDiff = os.difftime(os.time(), self.puffTimeMark)
    if (TrueSmoking.Config.PassiveSmoking and timeDiff >= self.timeCheck) or (TrueSmoking.Config.KeepLit and self.burnRate < 0.00001 and self.smokeLit) then
        self:puff()
    end
end
