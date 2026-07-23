--[[
    LightSmoke.lua - Timed Action for Lighting a Smokable
    
    Handles the animation and state transition for lighting
    a cigarette, cigar, pipe, etc.
]]

require 'TimedActions/ISBaseTimedAction'
require 'Core'
require 'Data'

LightSmoke = ISBaseTimedAction:derive('LightSmoke')

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

function LightSmoke:isValidStart()
    return true
end

function LightSmoke:isValid()
    return true
end

function LightSmoke:waitToStart()
    return false
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function predicateNotEmpty(item)
    return item:getCurrentUsesFloat() > 0
end

function LightSmoke:getRequiredItem()
    if not self.item or not self.item:getRequireInHandOrInventory() then
        return nil
    end

    local types = self.item:getRequireInHandOrInventory()
    for i = 1, types:size() do
        local fullType = moduleDotType(self.item:getModule(), types:get(i - 1))
        local item = self.character:getInventory():getFirstTypeEvalRecurse(fullType, predicateNotEmpty)
        if item then
            return item
        end
    end
    return nil
end

function LightSmoke:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 220
end

--------------------------------------------------------------------------------
-- Action Lifecycle
--------------------------------------------------------------------------------

function LightSmoke:start()
    -- Refresh item reference for MP
    -- Use helper to find item in any player container (main inventory or worn containers like backpacks)
    if self.item and self.item:getID() then
        self.item = TrueSmoking.getItemFromPlayerContainers(self.character, self.item:getID())
    end

    -- Refresh pack reference for MP (critical for packs)
    if self.cigPack and self.cigPack:getID() then
        self.cigPack = TrueSmoking.getItemFromPlayerContainers(self.character, self.cigPack:getID())
    end

    -- Validate that we have a valid item to work with
    local workingItem = self.item or self.cigPack
    if not workingItem then
        TrueSmoking.debug('LightSmoke:start - No valid item reference found after MP refresh, aborting')
        self:forceStop()
        return
    end

    -- If smoking from a pack, create actual cigarette item
    if self.cigPack then
        if isClient() then
            -- MP: Send command to server to create cigarette (handles pack usage too)
            sendClientCommand(self.character, 'TrueSmoking', 'createCigaretteFromPack', {
                packId = self.cigPack:getID(),
                cigType = 'Base.CigaretteSingle'
            })
            TrueSmoking.debug('LightSmoke:start - Requested server to create cigarette from pack')
        else
            -- SP: Create cigarette directly
            self.cigarette = self.character:getInventory():AddItem('Base.CigaretteSingle')
            if self.cigarette then
                -- Transfer partial smoke data from pack if any
                local packData = self.cigPack:getModData()
                if packData.Cigs then
                    for cigId, cigInfo in pairs(packData.Cigs) do
                        self.cigarette:getModData().OriginalSmokeLength = cigInfo.OriginalSmokeLength
                        self.cigarette:getModData().SmokeLength = cigInfo.SmokeLength
                        packData.Cigs[cigId] = nil
                        break
                    end
                end
                -- Reduce pack uses
                self.cigPack:setUsedDelta(self.cigPack:getCurrentUsesFloat() - self.cigPack:getUseDelta())
                TrueSmoking.debug('LightSmoke:start - SP: Created cigarette from pack')
            end
        end
    end

    -- Get custom eat sound
    if workingItem and workingItem.getCustomEatSound then
        self.eatSound = workingItem:getCustomEatSound() or ''
    end

    -- Consume lighter uses if needed
    if workingItem and workingItem:getRequireInHandOrInventory() and not (self.carLighter or self.openFlame) then
        local lighter = self:getRequiredItem()
        if lighter then
            self.lighter = lighter
            lighter:setUsedDelta(lighter:getCurrentUsesFloat() - lighter:getUseDelta())
            lighter:syncItemFields()
        end
    end

    -- Check for custom item sound (HGO, other mods with custom sounds)
    local hasCustomSound = self.eatSound and self.eatSound ~= ''

    -- Play SSO lighting sound if available (only if no custom item sound)
    if not hasCustomSound and not self.carLighter and not self.openFlame then
        local ssoActive = getActivatedMods():contains('\\SmokingSoundsOverhaul')
            and SmokingSoundsOverhaul and SmokingSoundsOverhaul.getLightingSound

        if ssoActive then
            local lightingSound = SmokingSoundsOverhaul:getLightingSound(self.character, self.lighter)
            if lightingSound and lightingSound ~= '' then
                self.lightingAudio = self.character:getEmitter():playSound(lightingSound)
            end
        end
    end

    -- Play item eat sound (smoking inhale) - custom sounds or default
    if self.eatSound ~= '' then
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
    end

    -- Set job type
    if workingItem:getCustomMenuOption() then
        workingItem:setJobType(workingItem:getCustomMenuOption())
    else
        workingItem:setJobType(getText('ContextMenu_Eat'))
    end

    -- Set hand models
    local primary = self.character:getPrimaryHandItem()
    self:setOverrideHandModels(primary, workingItem)

    -- Set animation
    self:setAnimVariable('FoodType', workingItem:getEatType())
    self:setActionAnim(CharacterActionAnims.Eat)

    TrueSmoking.debug('LightSmoke:start - Animation started')
end

function LightSmoke:update()
    -- Loop audio if needed
    if self.eatSound ~= '' and self.eatAudio ~= 0 then
        if not self.character:getEmitter():isPlaying(self.eatAudio) then
            self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
        end
    end
end

function LightSmoke:stop()
    TrueSmoking.debug('LightSmoke:stop - Action interrupted')
    ISBaseTimedAction.stop(self)
end

function LightSmoke:perform()
    TrueSmoking.debug('LightSmoke:perform - Starting smoke')

    local ref = TrueSmoking.getPlayerRef(self.character)

    -- Stop audio
    if self.eatAudio ~= 0 and self.character:getEmitter():isPlaying(self.eatAudio) then
        self.character:stopOrTriggerSound(self.eatAudio)
    end

    -- Determine the cigarette item to smoke
    local itemToSmoke = nil

    if self.cigPack then
        -- Smoking from pack - get the created cigarette
        if isClient() then
            -- MP: Retrieve cigarette ID from ModData (set by server command)
            local data = TrueSmoking.Data.getSmoking(self.character)
            local pendingId = data and data.pendingCigaretteId
            if pendingId then
                itemToSmoke = self.character:getInventory():getItemById(pendingId)
                data.pendingCigaretteId = nil  -- Clear after use
            end

            -- Fallback: search for newly added cigarette if ID lookup fails
            if not itemToSmoke then
                itemToSmoke = self.character:getInventory():getFirstType('Base.CigaretteSingle')
            end

            if not itemToSmoke then
                TrueSmoking.debug('LightSmoke:perform - MP: Could not find created cigarette, aborting')
                return
            end
        else
            -- SP: Use cigarette created in start()
            itemToSmoke = self.cigarette
            if not itemToSmoke then
                TrueSmoking.debug('LightSmoke:perform - SP: Cigarette not created, aborting')
                return
            end
        end
    else
        -- Smoking a single item directly (not from pack)
        if self.item and self.item:getID() then
            itemToSmoke = TrueSmoking.getItemFromPlayerContainers(self.character, self.item:getID())
        end
        if not itemToSmoke then
            TrueSmoking.debug('LightSmoke:perform - No valid item reference found, aborting')
            return
        end
    end

    TrueSmoking.debug('LightSmoke:perform - Using item: ' .. tostring(itemToSmoke:getFullType()))

    -- Create and start smokable with the actual cigarette item
    local Smokable = require 'SmokableItem'
    ref.smokable = Smokable:new(self.character, itemToSmoke)

    -- Start smoking (this sets isSmoking = true and initializes the smoking state)
    ref.smokable = ref.smokable:start(self.character, itemToSmoke)

    -- Check if smokable initialization failed
    if not ref.smokable then
        TrueSmoking.debug('LightSmoke:perform - Failed to create smokable, aborting')
        return
    end

    -- Equip visual (SP only: in MP, server handles via equipVisualItem command)
    if not isClient() and not isServer() then
        local visual = TrueSmoking.Visuals.createMask(itemToSmoke)
        if visual then
            self.character:setWornItem(TrueSmoking.registries.mask, visual)
        end
    end

    ISBaseTimedAction.perform(self)
end

function LightSmoke:complete()
    TrueSmoking.debug('LightSmoke:complete - Syncing state')

    -- Pack usage is now handled in start() (SP) or by server command (MP)
    -- No need to handle it here

    -- Get the actual item being smoked for visual sync
    local ref = TrueSmoking.getPlayerRef(self.character)
    local fullType = 'Base.CigaretteSingle'  -- Default
    if ref and ref.smokable and ref.smokable.item then
        fullType = ref.smokable.item:getFullType()
    elseif self.item and not self.cigPack then
        fullType = self.item:getFullType()
    end

    sendClientCommand(self.character, 'TrueSmoking', 'equipVisualItem', {
        fullType = fullType,
        options = TrueSmoking.Options
    })
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', {
        { isSmoking = true, takingPuff = false }
    })

    return true
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function LightSmoke:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    
    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = true
    o.forceProgressBar = false
    o.ignoreHandsWounds = true
    o.isEating = true
    
    o.character = character
    o.item = item
    o.maxTime = o:getDuration()
    
    -- Handle drainable items (packs)
    if instanceof(item, 'Drainable') then
        o.cigPack = item
    end
    
    -- Audio
    o.eatSound = ''
    o.eatAudio = 0
    
    -- Check for alternative light sources
    o.carLighter = item:hasTag(ItemTag.SMOKABLE) 
        and character:getVehicle() 
        and character:getVehicle():canLightSmoke(character)
    
    o.openFlame = false
    if not isServer() and item:hasTag(ItemTag.SMOKABLE) then
        o.openFlame = ISInventoryPaneContextMenu.hasOpenFlame(character)
    end
    
    return o
end
