--[[
    TakePuff.lua - Timed Action for Taking a Puff

    Handles the animation and stat application for puffing
    on a lit smokable. Supports continuous puffing via held key.
]]

require 'TimedActions/ISBaseTimedAction'
require 'Core'
require 'Data'

TakePuff = ISBaseTimedAction:derive('TakePuff')

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

function TakePuff:isValid()
    return self.data and self.data.isSmoking
end

function TakePuff:waitToStart()
    return false
end

--------------------------------------------------------------------------------
-- Action Lifecycle
--------------------------------------------------------------------------------

function TakePuff:start()
    -- Refresh item reference for MP (CRITICAL: item stored in constructor on client becomes invalid on server)
    -- Use helper to find item in any player container (main inventory or worn containers like backpacks)
    if self.item and self.item:getID() then
        self.item = TrueSmoking.getItemFromPlayerContainers(self.character, self.item:getID())
    end
    
    -- Hide progress bar if option is set
    if TrueSmoking.Config and (TrueSmoking.Config.HidePuffActionBar or TrueSmoking.Config.HideAllActionBars) then
        self.action:setUseProgressBar(false)
    end

    self.timer = os.time()

    -- Set animation (check for SmokingSoundsOverhaul mod)
    local anim = CharacterActionAnims.Eat
    if getActivatedMods():contains('\\SmokingSoundsOverhaul') then
        anim = 'smoke_quiet'
    end
    self:setActionAnim(anim)
    self:setAnimVariable('FoodType', self.item:getEatType())

    -- Mark puff in progress
    self.data.takingPuff = true

    -- Check for custom item sound first (HGO, other mods with custom sounds)
    local customSound = self.item and self.item.getCustomEatSound and self.item:getCustomEatSound()
    local hasCustomSound = customSound and customSound ~= ''

    -- SSO is only used if item doesn't have its own custom sound
    local ssoActive = not hasCustomSound
        and getActivatedMods():contains('\\SmokingSoundsOverhaul')
        and SmokingSoundsOverhaul and SmokingSoundsOverhaul.getPuffSound

    if hasCustomSound then
        -- Use item's custom sound (HGO bongs, etc.)
        self.eatSound = customSound
        self.eatAudio = self.character:getEmitter():playSound(customSound)
        self.usingSSOSound = false
    elseif ssoActive then
        -- Use SSO puff sound
        local gender = self.character:isFemale()
        local ssoSound = SmokingSoundsOverhaul:getPuffSound(gender)
        if ssoSound and ssoSound ~= '' then
            self.eatSound = ssoSound
            self.eatAudio = self.character:getEmitter():playSound(ssoSound)
            self.usingSSOSound = true  -- Flag to prevent looping/early cutoff
        end
    elseif self.eatSound ~= '' then
        -- Use default item eat sound
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
        self.usingSSOSound = false
    end

    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', { self.data })
end

function TakePuff:update()
    local curTime = os.time()

    -- Remove visual item mid-animation (synced with hand reaching mouth)
    if not self.visualItemFlag and self.timer then
        local shouldRemoveNow = os.difftime(curTime, self.timer) > self.visualItemTimer
        
        -- For items with no visual, update hand models immediately
        if not self.hasVisual then
            shouldRemoveNow = true
        end
        
        if shouldRemoveNow then
            -- Remove visual (if it exists)
            -- SP only: in MP, server handles via removeVisualItem command
            -- (setWornItem auto-sends SyncClothingPacket which causes race conditions in MP)
            if not isClient() and not isServer() then
                local worn = self.character:getWornItem(TrueSmoking.registries.mask)
                if worn then
                    self.character:removeWornItem(worn)
                end
            end
            sendClientCommand(self.character, 'TrueSmoking', 'removeVisualItem', { TrueSmoking.Options })
            self.visualItemFlag = true

            -- Update hand model
            local primary = self.character:getPrimaryHandItem()
            self:setOverrideHandModels(primary, self.item)
        end
    end

    -- Loop audio (but not SSO sounds - they play once)
    if self.eatSound ~= '' and self.eatAudio ~= 0 and not self.usingSSOSound then
        if not self.character:getEmitter():isPlaying(self.eatAudio) then
            self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
        end
    end

    local ref = TrueSmoking.getPlayerRef(self.character)

    -- Continuous puffing - reset job if key held
    if self:getJobDelta() >= 0.98 then
        if ref and ref.smokable and ref.smokable.smokeLength > 0 then
            if (self.data.holdingPuffKey or self.data.B_HELD) and not self.endAction then
                self.LongJobDelta = self.LongJobDelta + self:getJobDelta()
                self:resetJobDelta()
            end
        end
    end
end

function TakePuff:stop()
    ISBaseTimedAction.stop(self)

    -- Stop audio (but let SSO sounds finish naturally)
    if not self.usingSSOSound and self.character:getEmitter():isPlaying(self.eatAudio) then
        self.character:getEmitter():stopSound(self.eatAudio)
    end

    -- Handle coughing
    self:tryCough()

    -- Clear puff state
    self.data.takingPuff = false
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', { { takingPuff = false } })

    -- Re-equip visual if it was removed during the puff animation
    if self.visualItemFlag and self.hasVisual then
        -- SP only: in MP, server handles via equipVisualItem command
        if not isClient() and not isServer() then
            local mask = TrueSmoking.Visuals.createMask(self.item)
            if mask then
                self.character:setWornItem(TrueSmoking.registries.mask, mask)
            end
        end
        -- Server sync for MP
        local fullType = self.item and self.item:getFullType() or self.fullType
        sendClientCommand(self.character, 'TrueSmoking', 'equipVisualItem',
            { fullType = fullType, options = TrueSmoking.Options })
    end
end

function TakePuff:perform()
    -- Stop audio if game speed is fast-forwarded (but let SSO sounds finish)
    if TrueSmoking.getGameSpeedMultiplier() > 1 and not self.usingSSOSound then
        if self.character:getEmitter():isPlaying(self.eatAudio) then
            self.character:getEmitter():stopSound(self.eatAudio)
        end
    end

    -- Handle coughing
    self:tryCough()

    -- Clear puff state
    self.data.takingPuff = false
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', { { takingPuff = false } })

    -- SP only: in MP, server handles via equipVisualItem command
    if not isClient() and not isServer() then
        local mask = TrueSmoking.Visuals.createMask(self.item)
        if mask then
            self.character:setWornItem(TrueSmoking.registries.mask, mask)
        end
    end

    ISBaseTimedAction.perform(self)
end

function TakePuff:complete()
    self.data.takingPuff = false
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', { { takingPuff = false } })
    -- Send fullType string instead of item object for proper MP serialization
    local fullType = self.item and self.item:getFullType() or self.fullType
    sendClientCommand(self.character, 'TrueSmoking', 'equipVisualItem',
        { fullType = fullType, options = TrueSmoking.Options })


    return true
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function TakePuff:tryCough()
    if not TrueSmoking.Options.Coughing then return end

    local coughChance = 100
    local threshold

    if self.character:hasTrait(CharacterTrait.SMOKER) then
        threshold = TrueSmoking.Options.CoughingChanceSmoker
    else
        threshold = TrueSmoking.Options.CoughingChanceNonSmoker
    end

    if ZombRand(coughChance) <= threshold then
        self.character:triggerCough()
    end
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function TakePuff:new(character, item, eatSound, fullType)
    local o = ISBaseTimedAction.new(self, character)

    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = true

    o.character = character
    o.data = TrueSmoking.Data.getSmoking(character)
    o.item = item
    o.eatSound = eatSound or ''
    o.fullType = fullType
    o.eatAudio = 0
    o.maxTime = 220
    o.visualItemAnimLength = 3.7
    o.visualItemTimer = 0.7
    o.visualItemFlag = false
    o.LongJobDelta = 0
    o.JobFactor = o.visualItemTimer / o.maxTime
    
    -- Check if this item has a visual mask (false for bongs/cans)
    o.hasVisual = item and TrueSmoking.Visuals.getMaskType(item) ~= false

    return o
end
