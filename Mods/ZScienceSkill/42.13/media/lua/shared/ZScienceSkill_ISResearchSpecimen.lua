require "TimedActions/ISBaseTimedAction"
require "ZScienceSkill/Data"

ISResearchSpecimen = ISBaseTimedAction:derive("ISResearchSpecimen")

local SEARCH_RADIUS = 1

-- Check if object is a microscope
local function isMicroscope(obj)
    local props = obj and obj.getProperties and obj:getProperties()
    return props and props.get and props:get("CustomName") == "Microscope"
end

-- Find a microscope within radius of player
local function findNearbyMicroscope(character)
    local sq = character:getSquare()
    if not sq then return nil end
    
    local sx, sy, sz = sq:getX(), sq:getY(), sq:getZ()
    
    for x = sx - SEARCH_RADIUS, sx + SEARCH_RADIUS do
        for y = sy - SEARCH_RADIUS, sy + SEARCH_RADIUS do
            local checkSq = getCell():getGridSquare(x, y, sz)
            if checkSq then
                for i = 0, checkSq:getObjects():size() - 1 do
                    local obj = checkSq:getObjects():get(i)
                    if isMicroscope(obj) then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

-- Get all accessible inventories for a character (main + equipped bags + hand-held bags + reachable containers)
-- can be removed in favor of using ISInventoryPaneContextMenu.getContainers() directly
local function getAccessibleInventories(character)
    local containers = ISInventoryPaneContextMenu.getContainers(character)
    local tbl = {}
    for i = 0, containers:size() - 1 do
        local cont = containers:get(i)
        table.insert(tbl, cont)
    end
    return tbl
end

-- Check if character has item in any accessible inventory
local function characterHasItem(character, item)
    if not item then return false end
    
    local inventories = getAccessibleInventories(character)
    for _, inv in ipairs(inventories) do
        if isClient() then
            if inv:containsID(item:getID()) then return true end
        else
            if inv:contains(item) then return true end
        end
    end
    return false
end

-- Find item by ID in any accessible inventory
local function findItemById(character, itemId)
    local inventories = getAccessibleInventories(character)
    for _, inv in ipairs(inventories) do
        local found = inv:getItemById(itemId)
        if found then return found end
    end
    return nil
end

function ISResearchSpecimen:isValid()
    -- Check if item is in any accessible inventory (main + equipped bags)
    if not characterHasItem(self.character, self.item) then
        return false
    end
    if ISResearchSpecimen.isResearched(self.character, self.item) then
        return false
    end
    if not findNearbyMicroscope(self.character) then
        HaloTextHelper.addBadText(self.character, getText("Tooltip_NeedMicroscope"))
        return false
    end
    if self.character:tooDarkToRead() then
        HaloTextHelper.addBadText(self.character, getText("ContextMenu_TooDark"))
        return false
    end
    return true
end

function ISResearchSpecimen:isUsingTimeout()
    return false
end

function ISResearchSpecimen:start()
    if isClient() and self.item then
        self.item = findItemById(self.character, self.item:getID())
    end
    
    self.item:setJobType(getText("ContextMenu_ResearchSpecimen"))
    self.item:setJobDelta(0.0)
    self:setActionAnim(CharacterActionAnims.Craft)
    self:setOverrideHandModels(nil, self.item)
    self.character:setReading(true)
    self.character:reportEvent("EventRead")
end

function ISResearchSpecimen:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISResearchSpecimen:stop()
    self.item:setJobDelta(0.0)
    self.character:setReading(false)
    ISBaseTimedAction.stop(self)
end

if ISResearchRecipe.sendShowText then
    ISResearchSpecimen.sendShowText = ISResearchRecipe.sendShowText
else
    print "[?] ISResearchSpecimen: ISResearchRecipe.sendShowText not found, show text will not be sent to clients"
end

-- Called by Java networking on server in MP to apply action effects
-- This is where XP and ModData changes should happen for proper MP sync
function ISResearchSpecimen:complete()
    self.item:setJobDelta(0.0)

    -- learn all of the learnable recipes in the item - as in vanilla ISResearchRecipe
    if self.scriptItem then
        if isServer() and self.sendShowText then
            self:sendShowText()
        end

        self.scriptItem:researchRecipes(self.character);
        --PF_Recipes
        sendSyncPlayerFields(self.character, 0x00000001);
    end

    local status = ZScienceSkill.getItemStatus(self.item, self.character)
    if not status then return true end
    if status.researched == status.total then return true end -- already fully researched, nothing to do

    local fullType
    local fluidType

    for _, entry in ipairs(status.data) do
        if not entry.researched then
            if entry.type == "fluid" then
                fluidType = ZScienceSkill.getFluidType(self.item)
                if not fluidType then
                    print("[?] ISResearchSpecimen: could not determine fluid type for item " .. ZScienceSkill.getItemFullType(self.item))
                    return true
                end
                break
            elseif entry.type == "specimen" then
                fullType = self.item:getFullType()
                break
            else
                print("[?] ISResearchSpecimen: unknown research type '" .. tostring(entry.type) .. "' for item " .. ZScienceSkill.getItemFullType(self.item))
                -- continue checking other entries
            end
        end
    end

    local researchKey

    if fluidType then
        researchKey = "Fluid:" .. fluidType
        -- Grant XP for each perk defined for this fluid
        ZScienceSkill.addXpFromTable(self.character, ZScienceSkill.Data.fluids, fluidType, self.item)
    elseif fullType then
        -- Regular specimen
        researchKey = ZScienceSkill.getSpecimenResearchKey(fullType)
        ZScienceSkill.addXpFromTable(self.character, ZScienceSkill.Data.specimens, fullType, self.item)
    else
        print("[?] ISResearchSpecimen: could not determine research key for item " .. ZScienceSkill.getItemFullType(self.item))
        return true
    end
    
    -- Update ModData
    ZScienceSkill.setResearched(self.character, researchKey)
    
    if fullType then
        -- Trait unlock mechanic:
        -- vanilla.lua declares:
        --   * ZScienceSkill.Data.traits[CharacterTrait.X] = required unique specimens
        --   * ZScienceSkill.Data.specimens[fullType].trait = CharacterTrait.X
        local specimenCfg = ZScienceSkill.Data.specimens and ZScienceSkill.Data.specimens[fullType]
        local trait       = type(specimenCfg) == "table" and specimenCfg.trait or nil
        local required    = trait and ZScienceSkill.Data.traits and ZScienceSkill.Data.traits[trait] or nil

        if trait and required and required > 0 then
            local pzsData = ZScienceSkill.getPlayerZSData(self.character)

            -- Back-compat: old saves tracked herbalist plants in `researchedPlants`.
            if trait == CharacterTrait.HERBALIST and pzsData.researchedPlants and not pzsData.researchedTraitSpecimens then
                pzsData.researchedTraitSpecimens = {}
            end

            local traitKey = tostring(trait) -- "base:herbalist"
            pzsData.researchedTraitSpecimens = pzsData.researchedTraitSpecimens or {}
            pzsData.researchedTraitSpecimens[traitKey] = pzsData.researchedTraitSpecimens[traitKey] or {}

            if trait == CharacterTrait.HERBALIST and pzsData.researchedPlants and not table.isempty(pzsData.researchedPlants) then
                -- If we haven't migrated yet, seed the new structure from old data.
                if table.isempty(pzsData.researchedTraitSpecimens[traitKey]) then
                    for fullTypeKey, _ in pairs(pzsData.researchedPlants) do
                        pzsData.researchedTraitSpecimens[traitKey][fullTypeKey] = true
                    end
                end
            end

            if not pzsData.researchedTraitSpecimens[traitKey][fullType] then
                pzsData.researchedTraitSpecimens[traitKey][fullType] = true
            end

            -- Count unique specimens researched for this trait
            local count = 0
            for _ in pairs(pzsData.researchedTraitSpecimens[traitKey]) do
                count = count + 1
            end

            local hasTrait = self.character:hasTrait(trait)

            if count >= required and not hasTrait then
                self.character:getCharacterTraits():add(trait)
                self.character:applyCharacterTraitsRecipes()

                -- Sync recipes (0x01) and traits (0x02) to client
                local syncMask = 0x00000003
                sendSyncPlayerFields(self.character, syncMask)

                ZScienceSkill.Notifications.traitUnlocked(self.character, trait)
            elseif not hasTrait then
                ZScienceSkill.Notifications.traitProgress(self.character, trait, count, required)
            end
        end
    end
    
    -- Sync ModData from server to client
    self.character:transmitModData()
    
    return true
end

function ISResearchSpecimen:perform()
    self.character:setReading(false)
    self.item:setJobDelta(0.0)
    
    -- Sync item with server
    syncItemFields(self.character, self.item)
    
    ISBaseTimedAction.perform(self)
end

function ISResearchSpecimen:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    
    local baseTime = 300
    local scienceLevel = self.character:getPerkLevel(Perks.Science)
    local reduction = 1 - (scienceLevel * 0.05)
    return baseTime * reduction
end

function ISResearchSpecimen:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.item = item
    o.scriptItem = item:getScriptItem() -- for recipe research, is in vanilla ISResearchRecipe
    o.ignoreHandsWounds = true
    o.maxTime = o:getDuration()
    o.caloriesModifier = 0.5
    o.forceProgressBar = true
    return o
end

function ISResearchSpecimen.isResearched(character, item)
    local status = ZScienceSkill.getItemStatus(item, character)
    if not status then return end -- return nil if item has no research status (not a valid specimen)

    return status.researched == status.total
end

function ISResearchSpecimen.isSpecimen(item)
    -- Check item type
    if ZScienceSkill.Data.specimens[item:getFullType()] then return true end
    
    -- Check fluid type
    local fluidType = ZScienceSkill.getFluidType(item)
    if fluidType and ZScienceSkill.Data.fluids and ZScienceSkill.Data.fluids[fluidType] then return true end
    
    return false
end

-- Helper function to add menu option (enabled or disabled)
local function addMenuOption(context, item, playerObj, disableReason, cb)
    if not item then return end
    
    local option
    if disableReason then
        option = context:addOption(getText("ContextMenu_ResearchSpecimen"), nil, nil)
        option.notAvailable = true
        local tooltip = ISToolTip:new()
        tooltip:setName(getText(disableReason))
        option.toolTip = tooltip
    else
        option = context:addOption(getText("ContextMenu_ResearchSpecimen"), playerObj, cb, item)
    end
    
    local scriptItem = item.getScriptItem and item:getScriptItem()
    if scriptItem and scriptItem.getNormalTexture then
        option.iconTexture = scriptItem:getNormalTexture()
    end
    
    return option
end

-- Context menu hook
local function onFillInventoryContextMenu(player, context, items)
    local playerObj = getSpecificPlayer(player)
    
    for _, v in ipairs(items) do
        local item = v
        if not instanceof(v, "InventoryItem") then
            item = v.items[1]
        end

        if ISResearchSpecimen.isSpecimen(item) then
            local disableReason = nil
            if ISResearchSpecimen.isResearched(playerObj, item) then
                break -- Don't show option for already researched specimens
            elseif playerObj:tooDarkToRead() then
                disableReason = "ContextMenu_TooDark"
            elseif not findNearbyMicroscope(playerObj) then
                disableReason = "Tooltip_NeedMicroscope"
            end
            
            local cb = function(pl, itm)
                    ISTimedActionQueue.add(ISResearchSpecimen:new(pl, itm))
            end
            
            addMenuOption(context, item, playerObj, disableReason, cb)
            break
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)

-- Find all unresearched specimens in player's accessible inventories (main + equipped bags)
local function findUnresearchedSpecimens(playerObj)
    local specimens = {}
    local inventories = getAccessibleInventories(playerObj)
    
    for _, inventory in ipairs(inventories) do
        local items = inventory:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local status = ZScienceSkill.getItemStatus(item, playerObj)
            if status and status.researched ~= status.total then
                for _, entry in ipairs(status.data) do
                    if not entry.researched and not entry.type:contains("literature") then
                        specimens[ZScienceSkill.getItemFullType(item)] = {
                            item   = item,
                            status = status,
                        }
                        break
                    end
                end
            end
        end
    end
    
    return specimens
end

-- World object context menu hook (for microscope)
local function onMicroscopeContextMenu(player, context, worldobjects, _test)
    -- Note: 'test' parameter is for controller prompts, but PZ automatically handles this
    -- by checking if menu options were added. No need to check ISWorldObjectContextMenu.Test.
    
    local playerObj = getSpecificPlayer(player)
    
    -- Find microscope in clicked objects
    local microscope = nil
    for _, obj in ipairs(worldobjects) do
        if isMicroscope(obj) then
            microscope = obj
            break
        end
    end
    
    if not microscope then return end
    
    local specimens      = findUnresearchedSpecimens(playerObj)
    local spriteName     = microscope:getSprite() and microscope:getSprite():getName()
    local tex            = spriteName and getTexture(spriteName)
    local microscopeIcon = tex and tex:splitIcon()
    local option         = context:addOption(getText("ContextMenu_ResearchSpecimen"), nil, nil)

    if table.isempty(specimens) then
        option.notAvailable = true
        local tooltip = ISToolTip:new()
        tooltip:setName(getText("Tooltip_NoSpecimens"))
        option.toolTip = tooltip
    elseif playerObj:tooDarkToRead() then
        option.notAvailable = true
        local tooltip = ISToolTip:new()
        tooltip:setName(getText("ContextMenu_TooDark"))
        option.toolTip = tooltip
    else
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(option, subMenu)

        local ntotal = 0
        local itemsPerPerk = {}
        for _, sp in pairs(specimens) do
            ntotal = ntotal + 1
            for _, entry in ipairs(sp.status.data) do
                if not entry.researched then
                    for perk, _ in pairs(entry.perks) do
                        local perkName = perk.getName and perk:getName() or tostring(perk)
                        itemsPerPerk[perkName] = itemsPerPerk[perkName] or {}
                        table.insert(itemsPerPerk[perkName], sp.item)
                    end
                end
            end
        end

        subMenu:addOption(getText("ContextMenu_ResearchAll") .. " (" .. ntotal .. ")", playerObj, function(pl)
            for _, sp in pairs(specimens) do
                ISTimedActionQueue.add(ISResearchSpecimen:new(pl, sp.item))
            end
        end)

        local sortedItemsPerPerk = {}
        for perkName, items in pairs(itemsPerPerk) do
            table.insert(sortedItemsPerPerk, {perkName = perkName, items = items})
        end
        table.sort(sortedItemsPerPerk, function(a, b) return a.perkName < b.perkName end)

        for _, entry in ipairs(sortedItemsPerPerk) do
            local perkName = entry.perkName
            local items    = entry.items
            local count    = #items
            subMenu:addOption(getText("ContextMenu_ResearchPerk", perkName) .. " (" .. count .. ")", playerObj, function(pl)
                for _, item in ipairs(items) do
                    ISTimedActionQueue.add(ISResearchSpecimen:new(pl, item))
                end
            end)
        end
    end
    
    if option and microscopeIcon then
        option.iconTexture = microscopeIcon
    end
end

Events.OnFillWorldObjectContextMenu.Add(onMicroscopeContextMenu)
