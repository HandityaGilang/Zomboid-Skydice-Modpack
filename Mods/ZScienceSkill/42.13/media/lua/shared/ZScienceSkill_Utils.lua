ZScienceSkill = ZScienceSkill or {}
local logger = zdk.Logger.new("ZScienceSkill")

function ZScienceSkill.getPlayerZSData(player)
    local modData = player:getModData()
    modData.ZScienceSkill = modData.ZScienceSkill or {}
    local pzsData = modData.ZScienceSkill

    -- migrate old data
    if modData.researchedSpecimens then
        pzsData.researchedSpecimens = modData.researchedSpecimens
        modData.researchedSpecimens = nil
    end

    if modData.researchedPlants then
        pzsData.researchedPlants = modData.researchedPlants
        modData.researchedPlants = nil
    end

    return pzsData
end

-- only sets key to true, caller is responsible for client/server sync
function ZScienceSkill.setResearched(player, key, flag)
    if not player or not key then return false end

    local pzsData = ZScienceSkill.getPlayerZSData(player)
    pzsData.researchedSpecimens = pzsData.researchedSpecimens or {}

    if flag == false then
        pzsData.researchedSpecimens[key] = nil
    else
        if pzsData.researchedSpecimens[key] then
            return false
        else
            pzsData.researchedSpecimens[key] = true
            return true
        end
    end
end

function ZScienceSkill.isCombatPerk(perk)
    local perkObj = PerkFactory.getPerk(perk)
    if not perkObj then return false end
    
    local parent = perkObj:getParent()
    return parent == Perks.Combat or parent == Perks.Firearm
          or perk == Perks.Combat or   perk == Perks.Firearm
end

-- Get fluid type string from item if it has a fluid container
function ZScienceSkill.getFluidType(item)
    if not item or not item.getFluidContainer then return end

    local fc = item:getFluidContainer()
    if fc and fc:getPrimaryFluid() then
        return fc:getPrimaryFluid():getFluidTypeString()
    end
    return nil
end

-- Get the research key for a specimen (uses 'key' field if present, otherwise fullType)
function ZScienceSkill.getSpecimenResearchKey(fullType)
    if not fullType then return end

    local config = ZScienceSkill.Data.specimens[fullType]
    if type(config) == "table" and config.key then
        return config.key
    end
    return fullType
end

-- returns nil only if any of the input params is nil, otherwise returns strict boolean
local function isSpecimenResearched(player, fullType)
    if not player or not fullType then return end

    local pzsData = ZScienceSkill.getPlayerZSData(player)
    if not pzsData.researchedSpecimens then return false end

    local researchKey = ZScienceSkill.getSpecimenResearchKey(fullType)
    return pzsData.researchedSpecimens[researchKey] or false
end

-- returns nil only if any of the input params is nil, otherwise returns strict boolean
local function isFluidResearched(player, fluidType)
    return isSpecimenResearched(player, "Fluid:" .. fluidType)
end

local function isLiteratureReadOnce(player, fullType)
    return isSpecimenResearched(player, fullType)
end

function ZScienceSkill.getItemFullType(item)
    if not item then return end
    if item.getFullType then return item:getFullType() end
    if item.getScriptObjectFullType then return item:getScriptObjectFullType() end
    return nil
end

-- mostly a copy of ISInventoryPane:isLiteratureRead, but adapted for both client and server use
-- startPage is optional
-- returns true/false/nil
function ZScienceSkill.isLiteratureRead(playerObj, item, startPage)
    if not playerObj then return end

    if not item then return end
    if not item:IsLiterature() then return end

    -- next is a copy of ISInventoryPane:isLiteratureRead(playerObj, item)
    local modData = item:hasModData() and item:getModData() or nil
    if modData ~= nil then
        if (modData.literatureTitle)      and playerObj:isLiteratureRead(modData.literatureTitle)         then return true end
        if (modData.printMedia ~= nil)    and playerObj:isPrintMediaRead(modData.printMedia.title)        then return true end
        if (modData.learnedRecipe ~= nil) and playerObj:getKnownRecipes():contains(modData.learnedRecipe) then return true end
    end

    local skillBook = SkillBook[item:getSkillTrained()]
    if (skillBook ~= nil) and (item:getMaxLevelTrained() < playerObj:getPerkLevel(skillBook.perk) + 1) then return true end
    if item:getNumberOfPages() > 0 then
        local fullType = ZScienceSkill.getItemFullType(item)
        local startPage = startPage or playerObj:getAlreadyReadPages(fullType) or 0 -- take startPage into account
        if startPage == item:getNumberOfPages() then return true end
    end
    if (item:getLearnedRecipes() ~= nil) and playerObj:getKnownRecipes():containsAll(item:getLearnedRecipes()) then return true end

    return false
end

local function getTblPerks(tbl, bRandomPerk)
    local result = {}
    if type(tbl) == "number" then
        result[Perks.Science] = tbl
    elseif type(tbl) == "table" then
        for perk, xp in pairs(tbl) do -- 'perk' can be either string (perk name) or the Perk object itself
            if not ZScienceSkill.NON_PERK_KEYWORDS[perk] then
                if type(perk) == "string" then
                    if perk == "randomPerk" then
                        perk = bRandomPerk and ZScienceSkill.getRandomPerk()
                    else
                        perk = Perks[perk]
                    end
                end
                if perk then
                    result[perk] = xp
                end
            end
        end
    else
        logger:error("Invalid perks data: expected number or table, got type=%s, value=%s", type(tbl), tbl)
    end
    return result
end

-- SSOT
-- player is optional
function ZScienceSkill.getItemStatus(item, player)
    local fullType = ZScienceSkill.getItemFullType(item)
    if not fullType then return end
    
    local data = {}
    if ZScienceSkill.Data.literature[fullType] then
        table.insert(data, {
            type       = "literature",
            researched = ZScienceSkill.isLiteratureRead(player, item),
            perks      = getTblPerks(ZScienceSkill.Data.literature[fullType], false),
        })
    end
    if ZScienceSkill.Data.literatureReadOnce[fullType] then
        table.insert(data, {
            type       = "literatureReadOnce",
            researched = isLiteratureReadOnce(player, fullType),
            perks      = getTblPerks(ZScienceSkill.Data.literatureReadOnce[fullType], false),
        })
    end
    if ZScienceSkill.Data.specimens[fullType]then
        table.insert(data, {
            type       = "specimen",
            researched = isSpecimenResearched(player, fullType),
            perks      = getTblPerks(ZScienceSkill.Data.specimens[fullType], false),
        })
    end
                    
    local fluidType = ZScienceSkill.getFluidType(item)
    if fluidType and ZScienceSkill.Data.fluids[fluidType] then
        table.insert(data, {
            type       = "fluid",
            researched = isFluidResearched(player, fluidType),
            perks      = getTblPerks(ZScienceSkill.Data.fluids[fluidType], false),
        })
    end

    if #data == 0 then return nil end

    local result = {
        total = #data,
        data = data,
    }

    if player then
        result.researched = 0
        for _, entry in ipairs(data) do
            if entry.researched then
                result.researched = result.researched + 1
            end
        end
    end

    return result
end

function ZScienceSkill.getRandomPerk()
    if not Perks.fromIndex or not Perks.getMaxIndex then return nil end

    for i = 1, 20 do
        local perk = Perks.fromIndex(ZombRand(1, Perks.getMaxIndex()))
        if perk and perk:getParent() ~= Perks.None then
            return perk
        end
    end
end

-- add XP to Science perk based on ZScienceSkill.Data tables
function ZScienceSkill.addXpFromTable(character, tbl, key, item)
    if type(tbl) ~= "table" then
        print("[?] ZScienceSkill: table expected for XP data, got type=" .. type(tbl) .. ", tbl=" .. tostring(tbl) .. ", key=" .. tostring(key))
        return false
    end

    local val = tbl[key]
    if not val then
        print("[?] ZScienceSkill: no XP data for key=" .. tostring(key))
        return false
    end

    local mult = 1.0
    if item and ZItemTiers and ZItemTiers.GetItemTierIndex0 then
        local tierIdx0 = ZItemTiers.GetItemTierIndex0(item)
        if type(tierIdx0) == "number" then
            mult = mult + 0.1 * tierIdx0 -- add 10% XP per tier, so tier 0 = no bonus, tier 1 = +10%, tier 2 = +20%, etc.
        end
    end

    if type(val) == "number" then
        addXp(character, Perks.Science, val * mult)
        return true
    end
    if type(val) == "table" then
        for perk, xp in pairs(val) do -- 'perk' can be either string (perk name) or the Perk object itself
            if not ZScienceSkill.NON_PERK_KEYWORDS[perk] then
                if type(perk) == "string" then
                    if perk == "randomPerk" then
                        perk = ZScienceSkill.getRandomPerk()
                    else
                        perk = Perks[perk]
                    end
                end
                if perk and type(xp) == "number" then
                    addXp(character, perk, xp * mult)
                end
            end
        end
        return true
    end

    print("[?] ZScienceSkill: invalid XP data for specimen: type=" .. type(val) .. ", value=" .. tostring(val) .. ", key=" .. tostring(key))
    return false
end

--[[
function ZScienceSkill.cloneItem(newFullId, srcFullId, ...)
    local a = newFullId:split("\\.")
    if #a ~= 2 then return logger:error("Invalid newFullId '%s'", newFullId) end
    local newModId, newItemId = a[1], a[2]

    local existingItem = getItem(newFullId)
    if existingItem then return logger:error("Item '%s' already exists: %s", newFullId, existingItem) end

    local srcItem = getItem(srcFullId)
    if not srcItem then return logger:error("Source item '%s' not found", srcFullId) end

    -- cloneItemType creates new item in the same Module, we need our own
    if not createNewScriptItem           then return logger:error("createNewScriptItem() is not available") end
    if not srcItem.getLoadedScriptBodies then return logger:error("Source item '%s' does not have getLoadedScriptBodies()", srcFullId) end

    local srcScriptBodies = srcItem:getLoadedScriptBodies()
    if not srcScriptBodies or srcScriptBodies:size() ~= 2 then return end

    local srcScriptBody = srcScriptBodies:get(1)
    if type(srcScriptBody) ~= "string" or not luautils.stringStarts(srcScriptBody, "item") then return end

    local replaces = {...}
    if #replaces % 2 ~= 0 then
        logger:error("Uneven number of replace arguments, expected pairs of (from, to), got %d", #replaces)
        return nil
    end
    local newBody = srcScriptBody
    for i = 1, #replaces, 2 do
        local from, to = replaces[i], replaces[i + 1]
        newBody = newBody:gsub(from, to)
    end
    newBody = "imports { Base }\n" .. newBody
    logger:debug("Cloning item '%s' from '%s' with body:\n%s", newFullId, srcFullId, newBody)

    local displayName = getItemNameFromFullType(newFullId)
    local newItem = createNewScriptItem(newModId, newItemId, displayName, newFullId, srcItem:getIcon())
    if not newItem      then return logger:error("Failed to create new item '%s'", newFullId) end
    if not newItem.Load then return logger:error("Cloned item type does not have Load() method") end

    newItem:Load(newItem:getName(), newBody)
    logger:info("Cloned item '%s' from '%s' : %s", newFullId, srcFullId, newItem)

    return newItem
end

function ZScienceSkill.copyRecipeInputs(dstFullId, srcFullId, ...)
    local srcRecipe = ScriptManager.instance:getCraftRecipe(srcFullId)
    if not srcRecipe then return logger:error("Source recipe '%s' not found", srcFullId) end

    local dstRecipe = ScriptManager.instance:getCraftRecipe(dstFullId)
    if not dstRecipe then return logger:error("Destination recipe '%s' not found", dstFullId) end

    dstRecipe:getInputs():clear()
    local srcInputs = srcRecipe:getInputs()
    local newInputs = "{ inputs {\n"
    for i = 0, srcInputs:size() - 1 do
        local input = srcInputs:get(i)
        local line = input:getOriginalLine()
        if not line then return logger:error("Input %d of recipe '%s' does not have original line", i, dstFullId) end

        newInputs = newInputs .. "\t" .. line .. ",\n"
    end
    newInputs = newInputs .. "\n} }"

    local replaces = {...}
    if #replaces % 2 ~= 0 then
        logger:error("Uneven number of replace arguments, expected pairs of (from, to), got %d", #replaces)
        return nil
    end
    for i = 1, #replaces, 2 do
        local from, to = replaces[i], replaces[i + 1]
        newInputs = newInputs:gsub(from, to)
    end

    logger:debug("Copied inputs from recipe '%s' to '%s' with new inputs:\n%s", srcFullId, dstFullId, newInputs)
    dstRecipe:Load(dstRecipe:getName(), newInputs)

    return dstRecipe
end
]]--
