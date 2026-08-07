require "TimedActions/ISTimedActionQueue"
require "BasementBuilder/BasementBuilder_Core"
require "BasementBuilder/BasementBuilder_DigAction"
require "BasementBuilder/BasementBuilder_Environment"
require "BasementBuilder/BasementBuilder_MaterialPicker"

BasementBuilder_ContextMenu = BasementBuilder_ContextMenu or {}

local getShovel
local getHammer

local function predicateNotBroken(item)
    return item and not item:isBroken()
end

local function getPlayer(playerNum)
    return getSpecificPlayer(playerNum)
end

local function getSquareFromWorldObjects(worldobjects)
    if not worldobjects then
        return nil
    end

    for _, object in ipairs(worldobjects) do
        if object and object.getSquare then
            local square = object:getSquare()
            if square then
                return square
            end
        end
    end

    return nil
end

local function hasItem(playerObj, fullType, count)
    if not playerObj then return false end
    local itemCount = playerObj:getInventory():getItemCount(fullType, true)
    return itemCount >= count
end

local function isRainActive()
    local climateManager = getClimateManager()
    return climateManager and climateManager.getPrecipitationIntensity
        and climateManager:getPrecipitationIntensity() > 0
end

local function getBedFromWorldObjects(worldobjects)
    if not worldobjects then
        return nil
    end

    for _, object in ipairs(worldobjects) do
        if object and object.getProperties then
            local props = object:getProperties()
            if props and (props:has("BedType") or props:has(IsoFlagType.bed)) then
                return object
            end
        end
    end

    return nil
end

local function getStartCostLines(playerObj)
    local lines = {
        getText("ContextMenu_BB_Need"),
        "1x " .. getText("ContextMenu_BB_UsableShovel"),
        "1x Hammer",
        "1x Empty Sandbag",
        "1x " .. getItemNameFromFullType("BasementBuilder.BasementStarterKit"),
    }

    local missing = {}
    if not getShovel(playerObj) then
        table.insert(missing, getText("ContextMenu_BB_UsableShovel"))
    end
    if not getHammer(playerObj) then
        table.insert(missing, "Hammer")
    end
    if not hasItem(playerObj, "Base.EmptySandbag", 1) then
        local have = playerObj and playerObj:getInventory():getItemCount("Base.EmptySandbag", true) or 0
        table.insert(missing, "Empty Sandbag " .. tostring(have) .. "/1")
    end
    if not hasItem(playerObj, "BasementBuilder.BasementStarterKit", 1) then
        table.insert(missing, getItemNameFromFullType("BasementBuilder.BasementStarterKit"))
    end

    return lines, missing
end

local function getExpandCostLines(playerObj)
    local lines = {
        getText("ContextMenu_BB_Need"),
        "1x " .. getText("ContextMenu_BB_UsableShovel"),
        tostring(BasementBuilder.EXPAND_LOG_COST) .. "x " .. getText("ContextMenu_BB_Log"),
        tostring(BasementBuilder.EXPAND_NAIL_COST) .. "x " .. getText("ContextMenu_BB_Nails"),
    }

    local missing = {}
    if not getShovel(playerObj) then
        table.insert(missing, getText("ContextMenu_BB_UsableShovel"))
    end
    if not hasItem(playerObj, "Base.Log", BasementBuilder.EXPAND_LOG_COST) then
        local have = playerObj and playerObj:getInventory():getItemCount("Base.Log", true) or 0
        table.insert(missing, getText("ContextMenu_BB_Log") .. " " .. tostring(have) .. "/" .. tostring(BasementBuilder.EXPAND_LOG_COST))
    end
    if not hasItem(playerObj, "Base.Nails", BasementBuilder.EXPAND_NAIL_COST) then
        local have = playerObj and playerObj:getInventory():getItemCount("Base.Nails", true) or 0
        table.insert(missing, getText("ContextMenu_BB_Nails") .. " " .. tostring(have) .. "/" .. tostring(BasementBuilder.EXPAND_NAIL_COST))
    end

    return lines, missing
end

local function canUseStarter(playerObj)
    if not playerObj then return false end
    return getShovel(playerObj)
        and getHammer(playerObj)
        and hasItem(playerObj, "Base.EmptySandbag", 1)
        and hasItem(playerObj, "BasementBuilder.BasementStarterKit", 1)
end

getShovel = function(playerObj)
    return BasementBuilder.getDigTool(playerObj)
end

getHammer = function(playerObj)
    if not playerObj then return nil end
    local hammerTypes = { "Hammer", "BallPeenHammer" }
    for _, hammerType in ipairs(hammerTypes) do
        local hammer = playerObj:getInventory():getFirstTypeEvalRecurse(hammerType, predicateNotBroken)
        if hammer then
            return hammer
        end
    end
    return nil
end

function BasementBuilder_ContextMenu.startUseStarterWithPalette(playerObj, palette)
    if not playerObj then
        return
    end
    require "BasementBuilder/BasementBuilder_StartCursor"
    if BasementBuilder and BasementBuilder.ensureStartCursorClass then
        BasementBuilder.ensureStartCursorClass()
    end
    if not BasementBuilderStartCursor or not BasementBuilderStartCursor.new then
        return
    end
    local stylePreset = {
        id = nil,
        label = "Custom",
        palette = palette or {},
    }
    local cursor = BasementBuilderStartCursor:new(playerObj, getShovel, stylePreset)
    if not cursor then
        return
    end
    getCell():setDrag(cursor, playerObj:getPlayerNum())
end

function BasementBuilder_ContextMenu.onUseStarter(worldobjects, playerNum)
    local playerObj = getPlayer(playerNum)
    if not playerObj then
        return
    end
    BasementBuilder.openMaterialPicker(playerObj, BasementBuilder_ContextMenu.startUseStarterWithPalette)
end

function BasementBuilder_ContextMenu.onExpand(worldobjects, playerNum, square, targetX, targetY)
    local playerObj = getPlayer(playerNum)
    if not playerObj then
        return
    end
    local shovel = getShovel(playerObj)
    if not shovel then
        return
    end
    ISTimedActionQueue.add(BasementBuilderDigAction:new(playerObj, square, "expand", targetX, targetY, shovel))
end

function BasementBuilder_ContextMenu.onFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getPlayer(playerNum)
    if not playerObj then return end
    if not hasItem(playerObj, "BasementBuilder.BasementStarterKit", 1) then
        return
    end

    local option = context:addOption(getText("ContextMenu_BB_UseStarterKit"), items, BasementBuilder_ContextMenu.onUseStarter, playerNum)
    local enoughMaterials = canUseStarter(playerObj)
    if not enoughMaterials then
        option.notAvailable = true
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        local desc = {}
        local costLines, missing = getStartCostLines(playerObj)
        for _, line in ipairs(costLines) do
            table.insert(desc, line)
        end
        if #missing > 0 then
            table.insert(desc, "")
            table.insert(desc, getText("ContextMenu_BB_Missing"))
            for _, line in ipairs(missing) do
                table.insert(desc, line)
            end
        end
        toolTip.description = table.concat(desc, " <LINE> ")
        option.toolTip = toolTip
    end
end

function BasementBuilder_ContextMenu.onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local playerObj = getPlayer(playerNum)
    if not playerObj then return end
    local clickedSquare = getSquareFromWorldObjects(worldobjects)
    local currentSquare = playerObj:getCurrentSquare()
    local square = nil

    if clickedSquare and clickedSquare:getZ() < 0 then
        square = clickedSquare
    elseif currentSquare and currentSquare:getZ() < 0 then
        square = currentSquare
    else
        square = clickedSquare or currentSquare
    end

    if not square then
        return
    end

    if square:getZ() >= 0 then
        return
    end

    local data = BasementBuilder.getSaveData()
    local basementCount = 0
    for _, _ in pairs(data.basements or {}) do
        basementCount = basementCount + 1
    end
    local basement = BasementBuilder.findBasementByCell(square:getX(), square:getY(), square:getZ())
    if not basement then
        return
    end

    local bed = getBedFromWorldObjects(worldobjects)
    if bed and isRainActive() then
        context:addOption(getText("ContextMenu_Sleep"), bed, ISWorldObjectContextMenu.onSleep, playerNum)
    end

    local options = {
        { label = getText("ContextMenu_BB_ExpandNorth"), x = square:getX(), y = square:getY() - 1 },
        { label = getText("ContextMenu_BB_ExpandSouth"), x = square:getX(), y = square:getY() + 1 },
        { label = getText("ContextMenu_BB_ExpandWest"), x = square:getX() - 1, y = square:getY() },
        { label = getText("ContextMenu_BB_ExpandEast"), x = square:getX() + 1, y = square:getY() },
    }

    for _, entry in ipairs(options) do
        local valid, _, reason = BasementBuilder._safeCanExpandFrom(square, entry.x, entry.y)
        local option = context:addOption(entry.label, worldobjects, BasementBuilder_ContextMenu.onExpand, playerNum, square, entry.x, entry.y)
        local enoughMaterials = getShovel(playerObj)
            and hasItem(playerObj, "Base.Log", BasementBuilder.EXPAND_LOG_COST)
            and hasItem(playerObj, "Base.Nails", BasementBuilder.EXPAND_NAIL_COST)
        if not valid or not enoughMaterials then
            option.notAvailable = true
            local toolTip = ISWorldObjectContextMenu.addToolTip()
            local desc = {}
            if not valid then
                table.insert(desc, BasementBuilder.getFailureText(reason))
            end
            local costLines, missing = getExpandCostLines(playerObj)
            for _, line in ipairs(costLines) do
                table.insert(desc, line)
            end
            if #missing > 0 then
                table.insert(desc, "")
                table.insert(desc, getText("ContextMenu_BB_Missing"))
                for _, line in ipairs(missing) do
                    table.insert(desc, line)
                end
            end
            toolTip.description = table.concat(desc, " <LINE> ")
            option.toolTip = toolTip
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BasementBuilder_ContextMenu.onFillInventoryObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(BasementBuilder_ContextMenu.onFillWorldObjectContextMenu)
