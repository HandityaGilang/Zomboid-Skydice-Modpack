--[[
    SmokableItem.lua - Smokable Object Handler (Refactored)

    Manages the active smoking state for a single cigarette/cigar/pipe.
    Handles burn rate calculations, stat buffering, and nicotine puff events.

    This is a cleaner version of Smokable.lua using the new architecture.
]]

require 'TimedActions/ISBaseTimedAction'
require 'Core'
require 'Data'
require 'Visuals'

--------------------------------------------------------------------------------
-- Smokable Class
--------------------------------------------------------------------------------

SmokableItem = {}
SmokableItem.__index = SmokableItem

-- Global alias for external mod compatibility
Smokable = SmokableItem

-- Auto put-out retry configuration
SmokableItem.PUT_OUT_RETRY_INTERVAL = 3.0  -- Seconds between retry attempts
SmokableItem.PUT_OUT_RETRY_MAX = 0         -- Max retries (0 = unlimited)

--------------------------------------------------------------------------------
-- Local Helpers
--------------------------------------------------------------------------------

--- Find item in any container on the player by ID (main inventory or worn containers)
-- Returns the item if found (handles MP sync where object references change)
-- @param player IsoPlayer
-- @param itemId number The item's ID
-- @return InventoryItem|nil The item if found, nil otherwise
local function findItemInPlayerContainers(player, itemId)
    if not player or not itemId then return nil end

    -- Check main inventory first
    local item = player:getInventory():getItemById(itemId)
    if item then return item end

    -- Check worn containers (backpacks, bags, etc.)
    local worn = player:getWornItems()
    for i = 0, worn:size() - 1 do
        local wornItem = worn:get(i).item
        if wornItem and wornItem:IsInventoryContainer() then
            item = wornItem:getInventory():getItemById(itemId)
            if item then return item end
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

--- Create a new SmokableItem instance
-- @param player IsoPlayer
-- @param item InventoryItem
-- @return SmokableItem
function SmokableItem:new(player, item)
    local obj = setmetatable({}, self)
    obj:init(item, player)
    return obj
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

--- Initialize smokable with item data
-- @param item InventoryItem - Must be an actual smokable item (not a pack)
-- @param player IsoPlayer
function SmokableItem:init(item, player)
    -- Validate we have an item
    if not item then
        TrueSmoking.debug('SmokableItem:init - No item provided')
        return false
    end

    -- Refresh item reference for MP compatibility
    -- Use helper to find item in any player container (main inventory or worn containers like backpacks)
    if isClient() and item:getID() then
        local refreshedItem = TrueSmoking.getItemFromPlayerContainers(player, item:getID())
        if not refreshedItem then
            TrueSmoking.debug('SmokableItem:init - Item reference lost, cannot initialize')
            return false
        end
        item = refreshedItem
    end

    -- Packs should be converted to cigarettes by LightSmoke before reaching here
    -- If we still get a pack, fail gracefully
    if instanceof(item, 'Drainable') then
        -- TrueSmoking.debug('SmokableItem:init - Received Drainable (pack) instead of cigarette, this should not happen')
        return false
    end

    self.item = item
    self.itemId = item:getID()  -- Store ID for MP reference refresh
    self.itemFullType = item:getFullType()
    self.customEatSound = item:getCustomEatSound() or ''
    self.onEat = item:getOnEat() or false

    -- Resolve player for MP
    self.player = isClient() and getPlayerByOnlineID(player:getOnlineID()) or player

    -- Load smokable config
    local config = self:loadConfig()
    if not config then
        TrueSmoking.debug('SmokableItem:init - Failed to load config')
        return false
    end
    for k, v in pairs(config) do
        self[k] = v
    end

    -- Load item stats
    local stats = self:extractItemStats()
    for k, v in pairs(stats) do
        self[k] = v
        self['original' .. k:sub(1, 1):upper() .. k:sub(2)] = v
    end

    -- Runtime state
    self.canDrop = self.conditions and self.conditions.canDrop or false
    self.replaceOnUse = item:getModData().replaceOnUse or false
    self.smokePercent = self.smokeLength / self.originalSmokeLength
    self.smokeLit = false
    self.puffPercent = 0.0
    self.burnRate = ZombRandFloat(self.burnMax * 0.75, self.burnMax * 1.15)
    self.hasRolledForDrop = false

    -- Auto put-out retry state
    self.putOutRetryNext = nil
    self.putOutRetryCount = 0

    -- Passive puffing state
    self.puffTimeMark = os.time()
    self.nextPuffTime = self:calculateNextPuffTime()

    return true  -- Success
end

--- Load configuration for this smokable type
-- @return table Config with all burn/effect parameters
function SmokableItem:loadConfig()
    local fullType = self.item:getFullType()
    local opt = TrueSmoking.Options

    -- Ensure sandbox options are loaded (critical for MP where timing can vary)
    if not opt.Global or not opt.Category then
        TrueSmoking.loadSandboxOptions()
    end

    -- Fallback defaults if options still not loaded
    local g = opt.Global or {
        burnMin = 0.000125,
        burnMax = 0.000300,
        burnSpeed = 0.0025,
        burnSpeedDecay = 0.10,
        puffFactor = 1.35,
        walkingFactor = 1.0,
        runningFactor = 1.15,
        sprintingFactor = 1.35,
        decayRate = 0.995,
    }
    local cat = opt.Category or {
        Cigarette = 1.0,
        RolledCigarette = 0.9,
        Cigarillo = 0.75,
        Cigar = 0.50,
        Pipe = 0.40,
        Can = 0.60,
    }

    -- Start with registered config or empty
    local registered = TrueSmoking.SmokableObjects[fullType]
    local cfg = registered and TrueSmoking.deepCopy(registered) or {}

    -- Determine category multiplier
    local categoryMult = cat.Cigarette or 1.0
    if fullType:find('Cigar$') and not fullType:find('Cigarillo') then
        categoryMult = cat.Cigar or 0.50
    elseif fullType:find('Cigarillo') then
        categoryMult = cat.Cigarillo or 0.75
    elseif fullType:find('Pipe') or fullType:find('CanPipe') then
        categoryMult = cat.Pipe or 0.40
    elseif fullType:find('Can') then
        categoryMult = cat.Can or 0.60
    elseif fullType:find('RolledCigarette') then
        categoryMult = cat.RolledCigarette or cat.Rolled or 0.9
    end

    -- Default values
    local defaults = {
        smokeLength = opt.SmokeLength or 1.0,
        burnMin = g.burnMin * categoryMult,
        burnMax = g.burnMax * categoryMult,
        burnSpeed = g.burnSpeed,
        burnSpeedDecay = g.burnSpeedDecay,
        decayRate = g.decayRate,
        puffFactor = g.puffFactor,
        walkingFactor = g.walkingFactor,
        runningFactor = g.runningFactor,
        sprintingFactor = g.sprintingFactor,
        effectMultiplier = 1,
        nicotineContent = 100,
        conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
        visualItem = 'Mask_Cigarette',
        callback = false,
    }

    for k, v in pairs(defaults) do
        if cfg[k] == nil then cfg[k] = v end
    end

    cfg.fullType = fullType
    cfg.originalSmokeLength = cfg.smokeLength

    -- Restore saved progress
    local saved = self.item:getModData().SmokeLength
    if saved then
        cfg.smokeLength = saved
    end

    -- SmokingSoundsOverhaul compatibility
    if getActivatedMods():contains('\\SmokingSoundsOverhaul') then
        cfg.puffFactor = cfg.puffFactor / 2
    end

    -- Persist to item
    self.item:getModData().SmokeLength = cfg.smokeLength
    self.item:getModData().OriginalSmokeLength = cfg.originalSmokeLength
    sendClientCommand(self.player, 'TrueSmoking', 'updateItemData', { self.item, self.item:getModData() })

    return cfg
end

--- Extract stat values from item
-- @return table Stat values
function SmokableItem:extractItemStats()
    local item = self.item
    return {
        stress = item:getStressChange() or -5,
        boredom = item:getBoredomChange() or 0,
        unhappiness = item:getUnhappyChange() or 0,
        fatigue = item:getFatigueChange() or 0,
        thirst = item:getThirstChange() or 0,
        hunger = item:getHungChange() or 0,
        pain = item:getPainReduction() or 0,
        endurance = item:getEnduranceChange() or 0,
        reduceFoodSick = item:getFoodSicknessChange() or 0,
    }
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

--- Light the smokable
function SmokableItem:light()
    if not self.smokeLit then
        self.smokeLit = true
        if self.burnRate == 0 then
            self.burnRate = ZombRandFloat(self.burnMin, self.burnMax)
        end
    end

    if not ISTimedActionQueue.hasActionType(self.player, 'LightSmoke') then
        ISTimedActionQueue.add(LightSmoke:new(self.player, self.item))
    end
end

--- Start smoking (called after lighting completes)
-- @param player IsoPlayer
-- @param item InventoryItem
-- @return SmokableItem self or nil if initialization failed
function SmokableItem:start(player, item)
    if not self:init(item, player) then
        TrueSmoking.debug('SmokableItem:start - Initialization failed, cannot start smoking')
        return nil
    end

    if not self.smokeLit then
        self.smokeLit = true
        if self.burnRate == 0 then
            self.burnRate = ZombRandFloat(self.burnMin, self.burnMax)
        end
    end

    -- Use Data helper to ensure TrueSmoking moddata is initialized
    local data = TrueSmoking.Data.getSmoking(self.player)
    if not data then
        TrueSmoking.debug('SmokableItem:start - Failed to get smoking data')
        return nil
    end
    data.isSmoking = true
    data.takingPuff = false
    sendClientCommand(self.player, 'TrueSmoking', 'updatePlayerData', { { isSmoking = true, takingPuff = false } })

    return self
end

--- Take a puff
function SmokableItem:puff()
    local data = TrueSmoking.Data.getSmoking(self.player)
    if data and data.isSmoking and self.smokeLit and not ISTimedActionQueue.hasActionType(self.player, 'TakePuff') then
        ISTimedActionQueue.add(TakePuff:new(self.player, self.item, self.customEatSound, self.itemFullType))
        -- Reset passive puff timer after taking a puff
        self:resetPuffTimer()
    end
end

--- Calculate random time until next passive puff (in seconds)
-- @return number Seconds until next passive puff
function SmokableItem:calculateNextPuffTime()
    local cfg = TrueSmoking.Config
    local minTime = cfg and cfg.PassivePuffMinTime or 15
    local maxTime = cfg and cfg.PassivePuffMaxTime or 45
    -- Ensure min <= max
    if minTime > maxTime then
        minTime, maxTime = maxTime, minTime
    end
    return ZombRandFloat(minTime, maxTime)
end

--- Reset the passive puff timer (called after taking a puff)
function SmokableItem:resetPuffTimer()
    self.puffTimeMark = os.time()
    self.nextPuffTime = self:calculateNextPuffTime()
end

--- Check if player can auto-puff (not busy with non-smoking actions)
-- @return boolean True if player can auto-puff
function SmokableItem:canAutoPuff()
    -- Don't interrupt other actions - only auto-puff if queue is empty or only has smoking actions
    local queue = ISTimedActionQueue.getTimedActionQueue(self.player)
    if queue and queue.queue then
        for i = 1, #queue.queue do
            local action = queue.queue[i]
            if action and action.Type then
                local actionType = tostring(action.Type)
                -- Skip smoking-related actions
                if actionType ~= 'TakePuff' and actionType ~= 'LightSmoke' and actionType ~= 'PutOut' then
                    return false
                end
            end
        end
    end

    -- Also check if player is currently performing a non-smoking action
    local current = queue and queue.current
    if current and current.Type then
        local currentType = tostring(current.Type)
        if currentType ~= 'TakePuff' and currentType ~= 'LightSmoke' and currentType ~= 'PutOut' then
            return false
        end
    end

    return true
end

--- Idle puff - handles both passive puffing and keep-lit functionality
-- Only auto-puffs when player isn't busy with other actions (except smoking-related ones)
function SmokableItem:idlePuff()
    if not self.smokeLit then return end

    local cfg = TrueSmoking.Config
    if not cfg then return end

    -- Check passive puffing first (timed auto-puffs)
    if cfg.PassivePuffing then
        local timeDiff = os.difftime(os.time(), self.puffTimeMark or os.time())
        local nextPuff = self.nextPuffTime or self:calculateNextPuffTime()
        if timeDiff >= nextPuff then
            if self:canAutoPuff() then
                self:puff()
            end
            return
        end
    end

    -- Check keep-lit (puff when ember is dying)
    if cfg.KeepLit and self.burnRate < 0.00001 then
        if self:canAutoPuff() then
            self:puff()
        end
    end
end

--- Put out the smokable
function SmokableItem:putOut()
    local data = TrueSmoking.Data.getSmoking(self.player)
    if data and data.isSmoking and not ISTimedActionQueue.hasActionType(self.player, 'PutOut') then
        ISTimedActionQueue.add(PutOut:new(self.player, self.item, self.smokeLength, self.customEatSound,
            self.itemFullType))
    end
end

--- Remove fully consumed item without animation
function SmokableItem:removeConsumedItem()
    if not self.player or not self.item then return end
    
    -- Clear retry state
    self.putOutRetryNext = nil
    self.putOutRetryCount = 0
    
    -- Remove visual (SP only: in MP, server handles via removeVisualItem command)
    if not isClient() and not isServer() then
        local worn = self.player:getWornItem(TrueSmoking.registries.mask)
        if worn then
            self.player:removeWornItem(worn)
        end
    end
    sendClientCommand(self.player, 'TrueSmoking', 'removeVisualItem', { TrueSmoking.Options })
    
    -- Stop smoking state
    self:stop()

    -- Remove consumed item (check main inventory and worn containers like bags)
    TrueSmoking.removeItemFromPlayerContainers(self.player, self.item)
    
    -- Replace with butt/empty container if applicable (server-side for MP)
    -- Read from ModData (pipes/bongs store replaceOnUse there)
    local onUse = self.item:getModData().replaceOnUse or self.item:getReplaceOnUseFullType()
    if onUse and onUse ~= '' then
        sendClientCommand(self.player, 'TrueSmoking', 'replaceItem', { onUse })
    end
    
    -- Check for mask re-equip
    TrueSmoking.checkForMaskAndEquip(self.player)
end

--- Stop smoking completely
function SmokableItem:stop()
    self.smokeLit = false
    self.hasDropped = false
    
    -- Clear retry state
    self.putOutRetryNext = nil
    self.putOutRetryCount = 0

    local player = self.player or getPlayer()
    local data = TrueSmoking.Data.getSmoking(player)
    if data then
        data.isSmoking = false
        data.takingPuff = false
    end
    sendClientCommand(player, 'TrueSmoking', 'updatePlayerData', { { isSmoking = false, takingPuff = false } })
end

--------------------------------------------------------------------------------
-- Update Loop
--------------------------------------------------------------------------------

--- Main update tick (called from OnPlayerUpdate)
-- @param player IsoPlayer
function SmokableItem:update(player)
    local targetPlayer = self.player or player
    local data = TrueSmoking.Data.getSmoking(targetPlayer)

    if not data or not data.isSmoking or not self.itemId then return end

    -- Check item still exists (in main inventory or worn containers like backpacks)
    -- Use ID-based lookup to handle MP sync where object references change
    local currentItem = findItemInPlayerContainers(targetPlayer, self.itemId)
    if not currentItem then
        self.smokeLit = false
        data.isSmoking = false
        sendClientCommand(targetPlayer, 'TrueSmoking', 'updatePlayerData', { { isSmoking = false } })
        return
    end
    -- Refresh item reference if it changed (handles MP inventory sync)
    if currentItem ~= self.item then
        TrueSmoking.debug('SmokableItem:update - Refreshed stale item reference (MP sync)')
        self.item = currentItem
    end

    if not self.smokeLit then
        -- Check if we need to retry putting out a fully consumed item
        if TrueSmoking.Config and TrueSmoking.Config.AutoPutOut and 
           self.smokeLength == 0 and 
           self.item and 
           self.putOutRetryNext and 
           os.time() >= self.putOutRetryNext then
            
            -- Only retry if there's no PutOut action currently queued
            if not ISTimedActionQueue.hasActionType(self.player, 'PutOut') then
                TrueSmoking.debug('SmokableItem:update - Retrying AutoPutOut (attempt #' .. (self.putOutRetryCount + 1) .. ')')
                self:putOut()
                
                -- Schedule next retry
                self.putOutRetryCount = self.putOutRetryCount + 1
                if SmokableItem.PUT_OUT_RETRY_MAX > 0 and self.putOutRetryCount >= SmokableItem.PUT_OUT_RETRY_MAX then
                    TrueSmoking.debug('SmokableItem:update - Max retries reached, clearing retry state')
                    self.putOutRetryNext = nil
                else
                    self.putOutRetryNext = os.time() + SmokableItem.PUT_OUT_RETRY_INTERVAL
                end
            else
                -- PutOut is queued, clear retry state
                TrueSmoking.debug('SmokableItem:update - PutOut action detected, clearing retry state')
                self.putOutRetryNext = nil
                self.putOutRetryCount = 0
            end
        end
        return
    end

    -- Calculate burn rate based on activity
    local gameSpeed = TrueSmoking.getGameSpeedMultiplier()
    local cond = self.conditions

    local isWalking = self.player:isWalking() and cond.walking
    local isRunning = self.player:isRunning() and cond.running
    local isSprinting = self.player:isSprinting() and cond.sprinting
    local isStrafing = self.player:isStrafing() and cond.strafing
    local isReading = ISTimedActionQueue.hasActionType(self.player, 'ISReadABook')

    local targetBurnRate
    if data.takingPuff then
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
        targetBurnRate = nil -- Idle decay
    end

    -- Apply burn rate changes
    if targetBurnRate then
        local speed = self.burnSpeed
        if self.burnRate > self.burnMax then
            speed = speed * self.burnSpeedDecay
        end
        self.burnRate = self.burnRate + (targetBurnRate - self.burnRate) * speed * gameSpeed
    else
        self.burnRate = self.burnRate * (self.decayRate ^ gameSpeed)
    end

    -- Update smoke state
    self.puffPercent = self.burnRate * gameSpeed / self.originalSmokeLength
    self.smokeLength = self.smokeLength - self.burnRate * gameSpeed
    self.smokePercent = self.smokeLength / self.originalSmokeLength

    -- Buffer stat changes BEFORE clamping to 0 (so last puff counts)
    self:bufferStats()

    -- Buffer vanilla tobacco effects (smoker trait, nicotine withdrawal, etc.)
    self:bufferTobaccoEffects()

    -- Buffer nicotine puff
    if TrueSmoking.Options.UseNicotineSystem and
        self.onEat == 'RecipeCodeOnEat.consumeNicotine' and
        self.puffPercent > 0 and self.nicotineContent then
        local smokingData = data
        smokingData.puffBuffer = smokingData.puffBuffer or {}
        table.insert(smokingData.puffBuffer, {
            nicotineContent = self.nicotineContent,
            puffPercent = self.puffPercent,
        })
    end

    -- Run callbacks
    if self.callback then self.callback(self) end

    -- Handle relighting / burnout
    if TrueSmoking.Options.SmokeRelighting and self.burnRate < 0.0000025 then
        self.burnRate = 0
        self.smokeLit = false
    elseif not TrueSmoking.Options.SmokeRelighting and self.burnRate < self.burnMin then
        self.burnRate = self.burnMin
    end

    -- Finished smoking - clamp AFTER buffering stats
    if self.smokeLength <= 0 then
        self.smokeLength = 0
        self.smokeLit = false
        
        -- Save final state
        self.item:getModData().SmokeLength = 0
        
        -- Force putOut to consume the item
        if TrueSmoking.Config.AutoPutOut then
            self:putOut()
            -- Initialize retry mechanism in case putOut gets cancelled
            self.putOutRetryNext = os.time() + SmokableItem.PUT_OUT_RETRY_INTERVAL
            self.putOutRetryCount = 0
            TrueSmoking.debug('SmokableItem:update - Cigarette consumed, AutoPutOut initiated with retry fallback')
        else
            -- If AutoPutOut is disabled, still need to remove the item
            self:removeConsumedItem()
        end
    else
        -- Save progress (only if not fully consumed)
        self.item:getModData().SmokeLength = self.smokeLength
        
        -- Auto-puff to keep lit
        self:idlePuff()
    end
end

--- Buffer stat changes for server to apply
-- Stats are buffered per-tick and sent to server frequently for application.
-- Server is authoritative for stat changes (required for MP compatibility).
-- Buffer is sent every ~1 second via EveryTenSeconds event (see client/Network.lua).
function SmokableItem:bufferStats()
    local player = self.player
    if not player then return end
    
    local pct = self.puffPercent
    if not pct or pct <= 0 then return end
    
    local data = TrueSmoking.Data.getSmoking(player)
    if not data then return end
    
    local buffer = data.statsToApply
    if not buffer then
        data.statsToApply = {}
        buffer = data.statsToApply
    end
    
    local effectMult = self.effectMultiplier or 1.0
    local gameSpeed = TrueSmoking.getGameSpeedMultiplier()
    
    -- Scale factor explanation:
    -- puffPercent is ~0.0001-0.001 per tick at normal burn rates
    -- A cigarette burns over ~5-10 minutes (~3000-6000 ticks at 1x speed)
    -- Item stats like stress = -5 mean "reduce by 5 over full consumption"
    -- We want to deliver ~2-3x the base stats over the smoke duration to overcome regen
    -- 
    -- With baseMult=3.0, effectMult=1-3, over 5000 ticks:
    -- Total effect = sum(pct * baseMult * effectMult) ≈ 1.0 * 3.0 * 1.5 = 4.5x base stats
    local baseMult = 3.0
    
    --- Add a stat delta to the buffer
    -- @param key string Stat name for server (e.g., 'STRESS')
    -- @param original number Item's base stat value (negative = reduce)
    -- @param isIncrease boolean True if this stat should INCREASE (like boredom)
    local function addStat(key, original, isIncrease)
        if not original or original == 0 then return end
        -- original is negative for beneficial effects (stress -5 = reduce by 5)
        local delta = math.abs(original) * pct * effectMult * baseMult * gameSpeed
        if isIncrease then
            -- Stat should increase (detrimental) - use negative buffer value
            buffer[key] = (buffer[key] or 0) - delta
        else
            -- Stat should decrease (beneficial) - use positive buffer value
            buffer[key] = (buffer[key] or 0) + delta
        end
    end
    
    -- Buffer item's base stat effects
    addStat('STRESS', self.originalStress, false)
    addStat('UNHAPPINESS', self.originalUnhappiness, false)
    -- Apply hunger/fatigue reduction multipliers from sandbox options (default 0.25 for subtle effect)
    local hungerMult = TrueSmoking.Options.HungerReduction or 0.25
    local fatigueMult = TrueSmoking.Options.FatigueReduction or 0.25
    addStat('FATIGUE', self.originalFatigue * fatigueMult, false)
    addStat('HUNGER', self.originalHunger * hungerMult, false)
    addStat('THIRST', self.originalThirst, false)
    addStat('BOREDOM', self.originalBoredom, true)  -- Boredom increases
end

--- Buffer vanilla tobacco/smoker trait effects for server application
-- Mimics vanilla cigarette behavior from RecipeCodeOnEat.consumeNicotineLogic()
-- Buffers stat deltas per-tick, sent to server frequently for application.
function SmokableItem:bufferTobaccoEffects()
    local player = self.player
    if not player then return end
    
    local pct = self.puffPercent
    if not pct or pct <= 0 then return end
    
    local effectMult = self.effectMultiplier or 1.0
    local gameSpeed = TrueSmoking.getGameSpeedMultiplier()
    
    local data = TrueSmoking.Data.getSmoking(player)
    if not data then return end
    
    local buffer = data.statsToApply
    if not buffer then
        data.statsToApply = {}
        buffer = data.statsToApply
    end
    
    -- Vanilla reference (RecipeCodeOnEat.consumeNicotineLogic):
    -- For Smokers:
    --   stats.add(UNHAPPINESS, stressChange * percent) -- stressChange is negative, so reduces
    --   stats.add(STRESS, stressChange * percent)      -- stressChange is negative, so reduces
    --   stats.remove(NICOTINE_WITHDRAWAL, 0.51 * percent)
    --   player.setTimeSinceLastSmoke(withdrawal / 0.51)
    --
    -- For Non-Smokers:
    --   stats.add(FOOD_SICKNESS, foodSickness * percent)
    
    -- Smoker multiplier: stronger effects for trait holders
    -- Tuned to deliver meaningful impact over ~5-10 minute smoke duration
    local smokerMult = 1.55 * effectMult * gameSpeed
    
    if player:hasTrait(CharacterTrait.SMOKER) then
        -- Reduce unhappiness (vanilla stressChange is typically -5)
        local unhappyDelta = 5 * pct * smokerMult
        buffer['UNHAPPINESS'] = (buffer['UNHAPPINESS'] or 0) + unhappyDelta
        
        -- Reduce stress (0-1 scale, so smaller values)
        local stressDelta = 1 * pct * smokerMult
        buffer['STRESS'] = (buffer['STRESS'] or 0) + stressDelta
        
        -- Reduce nicotine withdrawal (max is 0.51)
        local withdrawalDelta = 0.51 * pct * smokerMult
        buffer['NICOTINE_WITHDRAWAL'] = (buffer['NICOTINE_WITHDRAWAL'] or 0) + withdrawalDelta
        
        -- Buffer timeSinceLastSmoke reduction
        local timeDelta = 10.0 * pct * smokerMult
        buffer['TIME_SINCE_LAST_SMOKE'] = (buffer['TIME_SINCE_LAST_SMOKE'] or 0) + timeDelta
    else
        -- Non-smoker: reset withdrawal/timer (flags for server)
        buffer['RESET_NICOTINE_WITHDRAWAL'] = true
        buffer['RESET_TIME_SINCE_LAST_SMOKE'] = true
        
        -- Apply food sickness if item causes it (non-smokers get sick)
        if self.originalReduceFoodSick and self.originalReduceFoodSick > 0 then
            local sickDelta = self.originalReduceFoodSick * pct * effectMult * gameSpeed
            buffer['FOOD_SICKNESS'] = (buffer['FOOD_SICKNESS'] or 0) - sickDelta  -- Negative = increase
        end
    end
end

--- Get current stats for moodle display
-- @return table Stats snapshot
function SmokableItem:getStats()
    return {
        stress = self.stress,
        boredom = self.boredom,
        unhappiness = self.unhappiness,
        fatigue = self.fatigue,
        thirst = self.thirst,
        hunger = self.hunger,
        pain = self.pain,
        endurance = self.endurance,
        reduceFoodSick = self.reduceFoodSick,
        originalStress = self.originalStress,
        originalBoredom = self.originalBoredom,
        originalUnhappiness = self.originalUnhappiness,
        originalFatigue = self.originalFatigue,
        originalThirst = self.originalThirst,
        originalHunger = self.originalHunger,
        originalPain = self.originalPain,
        originalEndurance = self.originalEndurance,
        originalReduceFoodSick = self.originalReduceFoodSick,
        effectMultiplier = self.effectMultiplier,
        puffPercent = self.puffPercent,
        smokeLit = self.smokeLit,
    }
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

Events.OnPlayerUpdate.Add(function(player)
    local ref = TrueSmoking.getPlayerRef(player)
    if ref and ref.smokable and ref.smokable.update then
        ref.smokable:update(player)
    end
end)

return SmokableItem
