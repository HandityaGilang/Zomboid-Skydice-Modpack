--[[
    Recipes.lua - Cigarette Pack Recipe Handlers
    
    Manages persistence of partial cigarettes when adding/removing from packs.
    Stores smoke progress in pack's ModData and restores when taking out.
]]

require 'Core'

TrueSmoking.Recipes = TrueSmoking.Recipes or {}

--------------------------------------------------------------------------------
-- Pack Recipe Handlers
--------------------------------------------------------------------------------

--- Check if a cigarette can be added to a pack
-- @param item InventoryItem The item to check
-- @return boolean True if item can be added
function TrueSmoking.Recipes.canAddToPack(item)
    if not item then return false end
    
    if instanceof(item, 'Drainable') and item:hasTag(ItemTag.PACKED) then
        local useDelta = item:getUseDelta()
        return useDelta and useDelta < 1
    end
    
    return true
end

--- Add a cigarette to pack, preserving partial smoke data
-- Recipe callback for OnCreate
-- @param items RecipeData
-- @param result InventoryItem
-- @param player IsoPlayer
function TrueSmoking.Recipes.addToPack(items, result, player)
    local usedItems = items:getAllInputItems()
    local pack, cig = nil, nil
    
    -- Find pack and cigarette in recipe inputs
    for i = 0, usedItems:size() - 1 do
        local item = usedItems:get(i)
        if item then
            local fullType = item:getFullType()
            if fullType == 'Base.CigarettePack' then
                pack = item
                -- Restore pack charge
                if pack:getUseDelta() < 1 then
                    pack:setUsedDelta(pack:getCurrentUsesFloat() + pack:getUseDelta())
                end
            elseif fullType == 'Base.CigaretteSingle' then
                cig = item
            end
        end
    end
    
    -- Store partial smoke data in pack
    if cig and pack then
        local cigData = cig:getModData()
        if cigData.OriginalSmokeLength and cigData.SmokeLength and 
           cigData.SmokeLength < cigData.OriginalSmokeLength then
            
            local packData = pack:getModData()
            packData.Cigs = packData.Cigs or {}
            
            packData.Cigs[cig:getID()] = {
                OriginalSmokeLength = cigData.OriginalSmokeLength,
                SmokeLength = cigData.SmokeLength,
            }
            
            TrueSmoking.debug('Stored partial cig in pack: ' .. cigData.SmokeLength .. '/' .. cigData.OriginalSmokeLength)
        end
    end
end

--- Take a cigarette from pack, restoring partial smoke data
-- Recipe callback for OnCreate
-- @param items RecipeData
-- @param result InventoryItem
-- @param player IsoPlayer
function TrueSmoking.Recipes.takeFromPack(items, result, player)
    local usedItems = items:getAllInputItems()
    local outputItems = items:getAllCreatedItems()
    local pack = nil
    
    -- Find pack with stored cig data
    for i = 0, usedItems:size() - 1 do
        local item = usedItems:get(i)
        if item and item:getFullType() == 'Base.CigarettePack' then
            if item:getModData().Cigs then
                pack = item
                break
            end
        end
    end
    
    -- Restore partial smoke data to output cigarette
    if pack then
        for i = 0, outputItems:size() - 1 do
            local cig = outputItems:get(i)
            if cig and cig:getFullType() == 'Base.CigaretteSingle' then
                local packData = pack:getModData().Cigs
                
                -- Get first stored cig data
                for cigId, cigInfo in pairs(packData) do
                    cig:getModData().OriginalSmokeLength = cigInfo.OriginalSmokeLength
                    cig:getModData().SmokeLength = cigInfo.SmokeLength
                    
                    TrueSmoking.debug('Restored partial cig from pack: ' .. cigInfo.SmokeLength .. '/' .. cigInfo.OriginalSmokeLength)
                    
                    packData[cigId] = nil
                    break
                end
                break
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Global Function Aliases (for recipe compatibility)
--------------------------------------------------------------------------------

--- Alias for recipe file compatibility
TrueSmoking.takeACigarette = TrueSmoking.Recipes.takeFromPack
TrueSmoking.addToPack = TrueSmoking.Recipes.addToPack
TrueSmoking.canAddToPack = TrueSmoking.Recipes.canAddToPack