--[[
    PutOut.lua - Timed Action for Putting Out a Smokable
    
    Handles the animation and state transition for putting out
    or saving a partially-smoked cigarette/cigar.
]]

require 'TimedActions/ISBaseTimedAction'
require 'Core'
require 'Data'

PutOut = ISBaseTimedAction:derive('PutOut')

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

function PutOut:isValid()
    return self.item ~= nil
end

function PutOut:waitToStart()
    local char = self.character
    if char:isStrafing() or char:isRunning() or char:isSprinting() 
        or char:isAiming() or char:isAsleep() or char:isPerformingAnAction() then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Action Lifecycle
--------------------------------------------------------------------------------

function PutOut:start()
    -- Refresh item reference for MP (CRITICAL: item stored in constructor on client becomes invalid on server)
    -- Use helper to find item in any player container (main inventory or worn containers like backpacks)
    if self.item and self.item:getID() then
        self.item = TrueSmoking.getItemFromPlayerContainers(self.character, self.item:getID())
    end
    
    -- Hide progress bar if option is set
    if TrueSmoking.Config and TrueSmoking.Config.HideAllActionBars then
        self:setUseProgressBar(false)
    end
    
    self.timer = os.time()
    
    -- Set animation
    self:setActionAnim(CharacterActionAnims.Eat)
    self:setAnimVariable('FoodType', self.item:getEatType())
    self:setOverrideHandModels(nil, nil)

    -- Play sound
    if self.eatSound ~= '' then
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
    end
end

function PutOut:update()
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
            sendClientCommand(self.character, 'TrueSmoking', 'removeVisualItem', { TrueSmoking.Options })
            self.visualItemFlag = true
            
            -- Update hand model
            local primary = self.character:getPrimaryHandItem()
            self:setOverrideHandModels(primary, self.item)
        end
    end

    -- Loop audio
    if self.eatSound ~= '' and self.eatAudio ~= 0 then
        if not self.character:getEmitter():isPlaying(self.eatAudio) then
            self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
        end
    end
end

function PutOut:stop()
    local ref = TrueSmoking.getPlayerRef(self.character)

    -- Remove visual (SP only: in MP, server handles via removeVisualItem command)
    if not isClient() and not isServer() then
        local worn = self.character:getWornItem(TrueSmoking.registries.mask)
        if worn then
            self.character:removeWornItem(worn)
        end
    end

    -- Stop smokable
    if ref and ref.smokable then
        ref.smokable:stop()
    end

    -- Sync state to server (action interrupted, don't handle item persistence)
    sendClientCommand(self.character, 'TrueSmoking', 'removeVisualItem', { TrueSmoking.Options })
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', {
        { isSmoking = false, takingPuff = false }
    })

    ISBaseTimedAction.stop(self)
end

function PutOut:perform()
    TrueSmoking.debug('PutOut:perform - Putting out smoke')
    
    local ref = TrueSmoking.getPlayerRef(self.character)
    
    -- Remove visual (SP only: in MP, server handles via removeVisualItem command)
    if not isClient() and not isServer() then
        local worn = self.character:getWornItem(TrueSmoking.registries.mask)
        if worn then
            self.character:removeWornItem(worn)
        end
    end
    
    -- Stop smokable
    if ref and ref.smokable then
        ref.smokable:stop()
    end
    
    -- Check for mask re-equip (shemagh, etc.)
    TrueSmoking.checkForMaskAndEquip(self.character)
    
    ISBaseTimedAction.perform(self)
end

function PutOut:complete()
    -- Re-fetch item on server if needed (belt-and-suspenders)
    -- Use helper to find item in any player container (main inventory or worn containers like backpacks)
    if isServer() and self.item and self.item:getID() then
        self.item = TrueSmoking.getItemFromPlayerContainers(self.character, self.item:getID())
    end

    TrueSmoking.debug('PutOut:complete - Item reference valid: ' .. tostring(self.item ~= nil))

    -- Handle item persistence
    if self.item then
        if self.smokeLength > 0 then
            -- Save remaining length
            self.item:getModData().SmokeLength = self.smokeLength
            sendClientCommand(self.character, 'TrueSmoking', 'updateItemData', {
                self.item,
                { SmokeLength = self.smokeLength }
            })
        else
            -- Fully consumed - replace with butt/empty container
            -- Read from ModData (pipes/bongs store replaceOnUse there)
            local onUse = self.item:getModData().replaceOnUse or self.item:getReplaceOnUseFullType()

            -- Remove consumed item from whatever container it's in
            TrueSmoking.removeItemFromPlayerContainers(self.character, self.item)

            -- Server-side replacement for MP compatibility
            if onUse and onUse ~= '' then
                sendClientCommand(self.character, 'TrueSmoking', 'replaceItem', { onUse })
            end
        end
    end

    -- Sync state
    sendClientCommand(self.character, 'TrueSmoking', 'removeVisualItem', { TrueSmoking.Options })
    sendClientCommand(self.character, 'TrueSmoking', 'updatePlayerData', { 
        { isSmoking = false, takingPuff = false } 
    })
    
    TrueSmoking.debug('PutOut:complete - State synced')
    return true
end

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function PutOut:new(character, item, smokeLength, eatSound, fullType)
    local o = ISBaseTimedAction.new(self, character)

    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = true

    o.character = character
    o.data = TrueSmoking.Data.getSmoking(character)
    o.item = item
    o.maxTime = 120
    o.smokeLength = smokeLength
    o.fullType = fullType

    o.eatSound = eatSound or ''
    o.eatAudio = 0

    o.visualItemTimer = 0.7
    o.visualItemFlag = false
    
    -- Check if this item has a visual mask (false for bongs/cans)
    o.hasVisual = item and TrueSmoking.Visuals.getMaskType(item) ~= false

    return o
end
