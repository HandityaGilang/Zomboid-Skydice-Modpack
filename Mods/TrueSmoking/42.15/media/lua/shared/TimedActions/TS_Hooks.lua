--[[
    TS_Hooks.lua - Vanilla Action Hooks

    Patches vanilla timed actions to integrate TrueSmoking:
    - ISEatFoodAction / ISTakePillAction → LightSmoke redirect
    - ISUnequipAction / ISWearClothing → Visual item management
]]

require 'TimedActions/ISClothingExtraAction'
require 'TimedActions/ISWearClothing'
require 'TimedActions/ISUnequipAction'
require 'TimedActions/ISEatFoodAction'
require 'TimedActions/ISTakePillAction'
require 'Core'
require 'Data'

--------------------------------------------------------------------------------
-- Smokable Detection
--------------------------------------------------------------------------------

local HOOKABLE_FUNCS = {
    'cigarettes',
    'RecipeCodeOnEat.consumeNicotine',
    'OnEat_Cigarettes',
    'OnEat_Cigarillo',
    'OnEat_Cigar',
    'OnEat_WeedSmoke',
    'OnEat_WeedJoint',
    'OnEat_WeedPipe',
    'OnEat_HempCigarillo',
    'OnEat_Tobacco',
    'OnEat_Weed',
    'OnSmoke_Blunt',
    'OnSmoke_Cannabis',
    'OnSmoke_CannaCigar',
    'OnSmoke_Spliff',
    'OnSmoke_Cigar',
}

--- Check if onEat function should be hooked
-- @param onEat string
-- @return boolean
local function isHookable(onEat)
    for _, func in ipairs(HOOKABLE_FUNCS) do
        if onEat == func then
            return true
        end
    end
    return false
end

--- Setup item for TrueSmoking hook
-- @param item InventoryItem
local function setupSmokableHook(item)
    local replace = item:getReplaceOnUseFullType()
    if replace and replace ~= '' then
        item:getModData().replaceOnUse = replace
        item:setReplaceOnUse(nil)
    end
    item:getModData().modOnEat = 'OnEat_Hook'
end

--------------------------------------------------------------------------------
-- ISTakePillAction Hook
--------------------------------------------------------------------------------

local originalPillActionNew = ISTakePillAction.new
function ISTakePillAction:new(character, item)
    local o = originalPillActionNew(self, character, item)

    local onEat = item:getOnEat() or ''
    local hasSmokableTag = item:hasTag(ItemTag.SMOKABLE)
    local data = TrueSmoking.Data.getSmoking(character)

    if item:getFullType() == 'Base.TobaccoChewing' then
        return o
    end

    if (isHookable(onEat) or hasSmokableTag) and not ISTimedActionQueue.hasActionType(character, 'LightSmoke') then
        TrueSmoking.debug('ISTakePillAction:new - Checking item: ' .. tostring(item:getFullType()))

        if not data.isSmoking then
            TrueSmoking.debug('ISTakePillAction:new - Hooking: ' .. onEat)
            setupSmokableHook(item)
            return LightSmoke:new(character, item)
        end
    end

    return o
end

--------------------------------------------------------------------------------
-- ISEatFoodAction Hook
--------------------------------------------------------------------------------

local originalFoodActionNew = ISEatFoodAction.new
function ISEatFoodAction:new(character, item, percentage)
    local o = originalFoodActionNew(self, character, item, percentage)

    local onEat = item:getOnEat() or ''
    local hasSmokableTag = item:hasTag(ItemTag.SMOKABLE)
    local data = TrueSmoking.Data.getSmoking(character)

    if item:getFullType() == 'Base.TobaccoChewing' then
        return o
    end

    if (isHookable(onEat) or hasSmokableTag) and not ISTimedActionQueue.hasActionType(character, 'LightSmoke') then
        TrueSmoking.debug('ISEatFoodAction:new - Checking item: ' .. tostring(item:getFullType()))

        if not data.isSmoking then
            TrueSmoking.debug('ISEatFoodAction:new - Hooking: ' .. onEat)
            setupSmokableHook(item)
            return LightSmoke:new(character, item)
        end
    end

    return o
end

--------------------------------------------------------------------------------
-- ISUnequipAction Hook
--------------------------------------------------------------------------------

local originalUnequipNew = ISUnequipAction.new
function ISUnequipAction:new(character, item, maxTime)
    local o = originalUnequipNew(self, character, item, maxTime)

    local data = TrueSmoking.Data.getSmoking(character)

    -- Instant unequip for visual smoke items
    if item:getBodyLocation() == TrueSmoking.registries.mask and data.isSmoking then
        o.maxTime = 1
    end

    return o
end

local originalUnequipComplete = ISUnequipAction.complete
function ISUnequipAction:complete()
    originalUnequipComplete(self)

    local data = TrueSmoking.Data.getSmoking(self.character)
    local ref = TrueSmoking.getPlayerRef(self.character)

    -- Put out smoke if visual item is unequipped while smoking
    if self.item:getBodyLocation() == TrueSmoking.registries.mask and data.isSmoking then
        if ref and ref.smokable then
            ref.smokable:putOut()
        end
    end

    return true
end

--------------------------------------------------------------------------------
-- ISWearClothing Hook
--------------------------------------------------------------------------------

local originalClothingComplete = ISWearClothing.complete
function ISWearClothing:complete()
    local rtn = originalClothingComplete(self)

    local data = TrueSmoking.Data.getSmoking(self.character)

    -- Clear mask flag when equipped
    if self.item == data.mask then
        data.mask = false
    end

    return rtn
end

local SMOKING_BLOCKERS = {
    Mask = true,
    MaskEyes = true,
    MaskFull = true,
    FullHat = true,
    FullSuitHead = true,
    SCBA = true,
    SCBAnotank = true,
}

local originalClothingNew = ISWearClothing.new
function ISWearClothing:new(character, item)
    local o = originalClothingNew(self, character, item)

    local bodyLoc = item:getBodyLocation()
    local data = TrueSmoking.Data.getSmoking(character)

    -- Stop smoking when equipping blocking headgear
    if SMOKING_BLOCKERS[bodyLoc] and not item:hasTag(ItemTag.CAN_EAT) and data.isSmoking then
        data.isSmoking = false
        sendClientCommand(character, 'TrueSmoking', 'updatePlayerData', { { isSmoking = false } })
    end

    return o
end

--------------------------------------------------------------------------------
-- ISClothingExtraAction Hook (minimal)
--------------------------------------------------------------------------------

local originalExtraActionNew = ISClothingExtraAction.new
function ISClothingExtraAction:new(character, item, extra)
    return originalExtraActionNew(self, character, item, extra)
end
