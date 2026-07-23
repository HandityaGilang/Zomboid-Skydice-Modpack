--[[
    Visuals.lua - Visual Item Mapping
    
    Handles mapping smokable items to their visual mask representations.
    Consolidates the duplicate getVisual() functions that existed across
    multiple files into a single source of truth.
]]

require 'Core'

TrueSmoking.Visuals = TrueSmoking.Visuals or {}

--------------------------------------------------------------------------------
-- Visual Item Mapping Tables
--------------------------------------------------------------------------------

-- Maps item fullType to mask item name
local TYPE_TO_MASK = {
    ['Base.CigaretteSingle']      = 'Base.Mask_Cigarette',
    ['Base.CigaretteRolled']      = 'Base.Mask_Cigarette',
    ['Base.Cigarillo']            = 'Base.Mask_Cigarillo',
    ['Base.Cigar']                = 'Base.Mask_Cigar',
    ['Base.SmokingPipe_Tobacco']  = 'Base.Mask_Pipe',
}

-- Maps item type patterns to mask names (for modded items)
local PATTERN_TO_MASK = {
    ['smokingpipe'] = 'Mask_Pipe',
    ['joint']       = 'Mask_Cigarette',
    ['blunt']       = 'Mask_Cigarillo',
    ['spliff']      = 'Mask_Cigarillo',
    ['pipe']        = 'Mask_Pipe',
}

-- Items that should NOT show a visual mask
local NO_VISUAL_PATTERNS = {
    'can',
    'bong',
}

-- OnEat method fallbacks
local ONEAT_TO_MASK = {
    ['RecipeCodeOnEat.consumeNicotine'] = 'Base.Mask_Cigarette',
}

--------------------------------------------------------------------------------
-- Visual Resolution
--------------------------------------------------------------------------------

--- Get the mask item type for a smokable item
-- @param item InventoryItem The smokable being smoked
-- @return string|false Mask item fullType or false if no visual
function TrueSmoking.Visuals.getMaskType(item)
    if not item then return false end
    
    local fullType = item:getFullType()
    
    -- Direct lookup first (fastest)
    if TYPE_TO_MASK[fullType] then
        return TYPE_TO_MASK[fullType]
    end
    
    local lowerType = fullType:lower()
    
    -- Check if item should have no visual
    for _, pattern in ipairs(NO_VISUAL_PATTERNS) do
        if lowerType:find(pattern) then
            return false
        end
    end
    
    -- Pattern matching for modded items
    for pattern, maskName in pairs(PATTERN_TO_MASK) do
        if lowerType:find(pattern) then
            return 'Base.' .. maskName
        end
    end
    
    -- Fallback: check OnEat method
    local onEat = item:getOnEat()
    if onEat and ONEAT_TO_MASK[onEat] then
        return ONEAT_TO_MASK[onEat]
    end
    
    -- Default to cigarette if nothing matched
    return 'Base.Mask_Cigarette'
end

--- Create a mask item instance
-- @param item InventoryItem The smokable being smoked
-- @return InventoryItem|false Mask item instance or false
function TrueSmoking.Visuals.createMask(item)
    local maskType = TrueSmoking.Visuals.getMaskType(item)
    if not maskType then return false end
    return instanceItem(maskType)
end

--------------------------------------------------------------------------------
-- Visual Equipment (requires player)
--------------------------------------------------------------------------------

--- Equip visual mask on player's face
-- @param player IsoPlayer
-- @param item InventoryItem The smokable item
function TrueSmoking.Visuals.equipMask(player, item)
    if not TrueSmoking.Options.ManageHeadGear then return end
    if not player or not item then return end
    -- MP: server handles via equipVisualItem command (setWornItem auto-sends SyncClothingPacket)
    if isClient() then return end

    local mask = TrueSmoking.Visuals.createMask(item)
    if not mask then return end

    local currentMask = player:getWornItem(TrueSmoking.registries.mask)
    if currentMask then
        player:removeWornItem(currentMask)
    end

    -- Use the registered body location to avoid conflicts with other clothing
    player:setWornItem(TrueSmoking.registries.mask, mask)
end

--- Remove visual mask from player's face
-- @param player IsoPlayer
function TrueSmoking.Visuals.removeMask(player)
    if not TrueSmoking.Options.ManageHeadGear then return end
    if not player then return end
    -- MP: server handles via removeVisualItem command
    if isClient() then return end

    local mask = player:getWornItem(TrueSmoking.registries.mask)
    if mask then
        player:removeWornItem(mask)
    end
end
