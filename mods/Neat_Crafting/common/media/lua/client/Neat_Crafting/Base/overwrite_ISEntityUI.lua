-- Debug print removed: avoid console noise when the override file is loaded.
-- ------------------------------------------------------------
-- ModOptions toggle (default ON)
-- If disabled, restore vanilla Crafting UI + context menu hooks.
-- ------------------------------------------------------------
require "Neat_Crafting/NC_ModOptions"


local function NC_HasReachablePlayerSquare(_player)
    return _player and _player.getSquare and _player:getSquare() ~= nil
end


local NC_neatUIWarningPrinted = false

local function NC_CheckNeatUIDependency(context)
    local missing = {}

    if not (ISXuiSkin and ISXuiSkin.build) then
        table.insert(missing, "ISXuiSkin.build")
    end
    if not ISTableLayout then
        table.insert(missing, "ISTableLayout")
    end
    if not NIScrollView then
        table.insert(missing, "NIScrollView")
    end
    if not (XuiManager and XuiManager.GetDefaultSkin) then
        table.insert(missing, "XuiManager.GetDefaultSkin")
    end

    if #missing == 0 then
        return true
    end

    if not NC_neatUIWarningPrinted then
        NC_neatUIWarningPrinted = true
        print("[Neat Crafting] ERROR: NeatUI Framework is missing or loaded after Neat Crafting. Missing: " .. table.concat(missing, ", ") .. ". Recommended load order: NeatUI Framework -> Neat Crafting -> Neat Crafting addons.")
    end

    print("[Neat Crafting] Cannot open Neat Crafting UI from " .. tostring(context) .. " because NeatUI Framework is not ready.")
    return false
end

-- Cache vanilla functions once (so we can restore them)
ISEntityUI._NC_old_OpenWindow = ISEntityUI._NC_old_OpenWindow or ISEntityUI.OpenWindow
ISEntityUI._NC_old_OpenHandcraftWindow = ISEntityUI._NC_old_OpenHandcraftWindow or ISEntityUI.OpenHandcraftWindow
ISInventoryPaneContextMenu._NC_old_doRecipeList = ISInventoryPaneContextMenu._NC_old_doRecipeList or ISInventoryPaneContextMenu.doRecipeList
local function createWindow(_player, _windowInstance, _isoObject)
    local playerNum = _player:getPlayerNum()
    local x = getMouseX() + 10
    local y = getMouseY() + 10
    local adjustPos = true
    local width = 0
    local height = 0
    
    local windowKey = _windowInstance.xuiStyleName or "Default"

    ISEntityUI.CloseWindows()

    if ISEntityUI.players[playerNum] and ISEntityUI.players[playerNum].windows[windowKey] then
        if ISEntityUI.players[playerNum].windows[windowKey].instance then
            ISEntityUI.players[playerNum].windows[windowKey].instance:close()
        end
        if ISEntityUI.players[playerNum].windows[windowKey].x and ISEntityUI.players[playerNum].windows[windowKey].y then
            x = ISEntityUI.players[playerNum].windows[windowKey].x
            y = ISEntityUI.players[playerNum].windows[windowKey].y
            adjustPos = false
        end
        if ISEntityUI.players[playerNum].windows[windowKey].width and ISEntityUI.players[playerNum].windows[windowKey].height then
            width = ISEntityUI.players[playerNum].windows[windowKey].width
            height = ISEntityUI.players[playerNum].windows[windowKey].height
        end
    else
        ISEntityUI.players[playerNum] = ISEntityUI.players[playerNum] or {}
        ISEntityUI.players[playerNum].windows = ISEntityUI.players[playerNum].windows or {}
        ISEntityUI.players[playerNum].windows[windowKey] = {}
    end

    _windowInstance:initialise()
    _windowInstance:instantiate()
    _windowInstance:setX(x)
    _windowInstance:setY(y)
    _windowInstance:setVisible(true)
    if _windowInstance.calculateLayout then
        _windowInstance:calculateLayout(width,height)
    end
    _windowInstance:addToUIManager()

    ISEntityUI.players[playerNum].windows[windowKey].instance = _windowInstance
    ISEntityUI.players[playerNum].windows[windowKey].playerObj = _player
    ISEntityUI.players[playerNum].windows[windowKey].entityObj = _isoObject

    --if adjustPos and instanceof(_isoObject, "IsoObject") then
    if adjustPos then
        local x = (getCore():getScreenWidth()/2) - (_windowInstance:getWidth()/2)
        local y = (getCore():getScreenHeight()/2) - (_windowInstance:getHeight()/2)
        _windowInstance:setX(x)
        _windowInstance:setY(y)
        ISEntityUI.players[playerNum].windows[windowKey].x = x
        ISEntityUI.players[playerNum].windows[windowKey].y = y
    end

    if JoypadState.players[playerNum+1] then
        if getFocusForPlayer(playerNum) then getFocusForPlayer(playerNum):setVisible(false) end
        if getPlayerInventory(playerNum) then getPlayerInventory(playerNum):close() end
        if getPlayerLoot(playerNum) then getPlayerLoot(playerNum):close() end
        setJoypadFocus(playerNum, _windowInstance)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- TODO: Need to finish the XUI stuff
-- ----------------------------------------------------------------------------------------------------- --
function ISEntityUI.OpenWindow(_player, _entity)
    if not NC_CheckNeatUIDependency("ISEntityUI.OpenWindow") then
        if ISEntityUI._NC_old_OpenWindow then
            return ISEntityUI._NC_old_OpenWindow(_player, _entity)
        end
        return
    end

    if not ISEntityUI.CanOpenWindowFor(_player, _entity) then return end
	
    if not ISEntityUI.CanPlayerUseEntity(_player, _entity) then
        log(DebugType.CraftLogic, "Object already in use by other player.")
        if isClient() then
            getPlayer():Say(getText("IGUI_ObjectAlreadyUsedSayMessage"));
        end
        return;
    end

    local customFunction = ISEntityUI.GetCustomOpenWindowFunc(_entity)
    if customFunction and customFunction~=ISEntityUI.OpenWindow then
        customFunction(_player, _entity)
        return
    end

    -- TODO: Remake the Drying UI
    local windowClass = ISEntityUI.GetWindowClass(_entity)
    if windowClass then
        local dryingCraftLogicComponent = _entity:getComponent(ComponentType.DryingCraftLogic)
        if dryingCraftLogicComponent then
            windowClass = ISEntityWindow
        elseif windowClass == ISEntityWindow or windowClass == ISEntityTabWindow then
            windowClass = NC_EntityWindow
        end
        
        local skin = ISEntityUI.GetEntityUiSkin(_entity)
        local windowStyle = ISEntityUI.GetWindowStyleName(_entity)
        local windowInstance = ISXuiSkin.build(skin, windowStyle, windowClass, 0, 0, 60, 30, _player, _entity, ISEntityUI.GetEntityUiStyle(_entity))
        createWindow(_player, windowInstance, _entity)
    end
end

-- Resolve the first actual CraftRecipe from the current filtered output.
-- Newer Build 42 recipe lists may contain entry tables/group headers instead of plain CraftRecipe objects.
local function NC_ResolveFirstFilteredCraftRecipe(filteredRecipes)
    if not filteredRecipes then
        return nil
    end

    for _, entry in ipairs(filteredRecipes) do
        if entry then
            if entry.entryType == "recipe" and entry.recipe then
                return entry.recipe
            end

            -- Backward compatibility with older flat lists that may still return the recipe directly.
            if instanceof and instanceof(entry, "CraftRecipe") then
                return entry
            end
        end
    end

    return nil
end

function ISEntityUI.OpenHandcraftWindow(_player, _isoObject, _queryOverride, _ignoreFindSurface, recipeData, itemString)

    if not NC_CheckNeatUIDependency("ISEntityUI.OpenHandcraftWindow") then
        if ISEntityUI._NC_old_OpenHandcraftWindow then
            return ISEntityUI._NC_old_OpenHandcraftWindow(_player, _isoObject, _queryOverride, _ignoreFindSurface, recipeData, itemString)
        end
        return
    end

    if (not _isoObject) and (not _ignoreFindSurface) and NC_HasReachablePlayerSquare(_player) then
        _isoObject = ISEntityUI.FindCraftSurface(_player, 1)
    end

    local skin = XuiManager.GetDefaultSkin()
    local windowStyle = "HandcraftWindow"

    local windowInstance = ISXuiSkin.build(skin, windowStyle, NC_HandcraftWindow, 0, 0, 60, 30, _player, _isoObject, _queryOverride)
    
    createWindow(_player, windowInstance, _isoObject)
    windowInstance:bringToTop()

    local searchComponent = windowInstance.header.searchComponent

    -- Newer vanilla paths may call this directly with a CraftRecipe instead of the older wrapper table.
    if recipeData and instanceof and instanceof(recipeData, "CraftRecipe") then
        windowInstance.HandCraftPanel.logic:setRecipe(recipeData)
        return
    end
    
    if recipeData and recipeData.recipe and recipeData.list then
        local contextRecipe = recipeData.recipe
        local teachRecipeList = recipeData.list
        
        local recipeNames = {}
        for i = 0, teachRecipeList:size() - 1 do
            local recipe = teachRecipeList:get(i)
            local craftRecipe = getScriptManager():getCraftRecipe(recipe)
            if craftRecipe then
                table.insert(recipeNames, craftRecipe:getTranslationName())
            end
        end
        
        if #recipeNames > 0 then
            windowInstance.HandCraftPanel:filterRecipeListMultiple(recipeNames)
        end
        
        windowInstance.HandCraftPanel.logic:setRecipe(contextRecipe)
        return
    end
        
    if itemString then
        searchComponent:setSearchMode("InputName")
        searchComponent:setSearchText(itemString)
        searchComponent:performSearch()

        local filteredRecipes = windowInstance.HandCraftPanel.filterBar:getFilteredRecipes()
        local firstCraftRecipe = NC_ResolveFirstFilteredCraftRecipe(filteredRecipes)
        if firstCraftRecipe then
            windowInstance.HandCraftPanel.logic:setRecipe(firstCraftRecipe)
        end
    end
end

-- temp override doRecipeList
function ISInventoryPaneContextMenu.doRecipeList(context, text, recipeItem, recipes, playerObj, isLiterature)
    local usedOption = context:addOption(text, recipeItem, nil);
    if isLiterature and playerObj:tooDarkToRead() then
        usedOption.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip();
        tooltip.description = getText("ContextMenu_TooDark");
        usedOption.toolTip = tooltip;
        return;
    end
    local usedMenu =  ISContextMenu:getNew(context)
    context:addSubMenu(usedOption, usedMenu)
    
    local favRecipeList = {}
    local otherRecipeList = {}
    local badRecipeList = {}
    for i=0, recipes:size()-1 do
        local recipe = recipes:get(i)
        -- Debug print removed: this loop can run once per recipe in the context menu.
        local craftRecipe = getScriptManager():getCraftRecipe(recipe)
        local buildRecipe = getScriptManager():getBuildableRecipe(recipe)
        
        if craftRecipe then
            if craftRecipe:isFavourite(playerObj) then
                table.insert(favRecipeList, recipe)
            elseif (craftRecipe:characterHasRequiredSkills(playerObj) or craftRecipe:couldBenefitFromRecipeAtHand(playerObj))
            and (playerObj:isRecipeActuallyKnown(craftRecipe) or not craftRecipe:needToBeLearn()) then
                table.insert(otherRecipeList, recipe)
            else
                table.insert(badRecipeList, recipe)
            end
        elseif buildRecipe then
            if buildRecipe:isFavourite(playerObj) then
                table.insert(favRecipeList, recipe)
            elseif (buildRecipe:characterHasRequiredSkills(playerObj) or buildRecipe:couldBenefitFromRecipeAtHand(playerObj))
            and (playerObj:isRecipeActuallyKnown(buildRecipe) or not buildRecipe:needToBeLearn()) then
                table.insert(otherRecipeList, recipe)
            else
                table.insert(badRecipeList, recipe)
            end
        else
            if playerObj:isRecipeActuallyKnown(recipes:get(i)) then
                table.insert(otherRecipeList, recipes:get(i))
            else
                table.insert(badRecipeList, recipe)
            end
        end
    end
    
    table.sort(favRecipeList, function(a, b) return string.sort(Translator.getRecipeName(b), Translator.getRecipeName(a)) end);
    table.sort(otherRecipeList, function(a, b) return string.sort(Translator.getRecipeName(b), Translator.getRecipeName(a)) end);
    table.sort(badRecipeList, function(a, b) return string.sort(Translator.getRecipeName(b), Translator.getRecipeName(a)) end);

    for i, v in pairs(favRecipeList) do
        local subOption
        local buildRecipe = getScriptManager():getBuildableRecipe(v)
        local craftRecipe = getScriptManager():getCraftRecipe(v)
        if buildRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenBuildWindow, nil, "*", false, buildRecipe )
        elseif craftRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenHandcraftWindow, nil, "*", false, {recipe = craftRecipe, list = recipes} )
        end
        if subOption and getRecipeIcon(v) then
             subOption.iconTexture = getRecipeIcon(v)
        end
        subOption.goodColor = true
    end

    for i, v in pairs(otherRecipeList) do
        local subOption
        local buildRecipe = getScriptManager():getBuildableRecipe(v)
        local craftRecipe = getScriptManager():getCraftRecipe(v)
        if buildRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenBuildWindow, nil, "*", false, buildRecipe )
        elseif craftRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenHandcraftWindow, nil, "*", false, {recipe = craftRecipe, list = recipes} )
        elseif doesSeasonRecipeExist(v) then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISInventoryPaneContextMenu.showGrowingSeasons)
        elseif doesMiscRecipeExist(v) then
            subOption =  usedMenu:addOption(getText(Translator.getRecipeName(v)))
            if ISLiteratureUI.miscRecipes[v] and ISLiteratureUI.miscRecipes[v].tooltip then
                local tooltip = ISInventoryPaneContextMenu.addToolTip();
                tooltip.description = getText(ISLiteratureUI.miscRecipes[v].tooltip);
                subOption.toolTip = tooltip;
            end
        end
        if subOption and getRecipeIcon(v) then
             subOption.iconTexture = getRecipeIcon(v)
        end
    end

    for i, v in pairs(badRecipeList) do
        local subOption
        local buildRecipe = getScriptManager():getBuildableRecipe(v)
        local craftRecipe = getScriptManager():getCraftRecipe(v)
        if buildRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenBuildWindow, nil, "*", false, buildRecipe )
            subOption.badColor = true
        elseif craftRecipe then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISEntityUI.OpenHandcraftWindow, nil, "*", false, {recipe = craftRecipe, list = recipes} )
            subOption.badColor = true
        elseif doesSeasonRecipeExist(v) then
            subOption = usedMenu:addOption(Translator.getRecipeName(v), playerObj, ISInventoryPaneContextMenu.showGrowingSeasons)
            subOption.badColor = true
        elseif doesMiscRecipeExist(v) then
            subOption =  usedMenu:addOption(getText(Translator.getRecipeName(v)))
            if ISLiteratureUI.miscRecipes[v] and ISLiteratureUI.miscRecipes[v].tooltip then
                local tooltip = ISInventoryPaneContextMenu.addToolTip();
                tooltip.description = getText(ISLiteratureUI.miscRecipes[v].tooltip);
                subOption.toolTip = tooltip;
            end
            subOption.badColor = true
        end
        if subOption and getRecipeIcon(v) then
             subOption.iconTexture = getRecipeIcon(v)
        end
    end
end

-- ------------------------------------------------------------
-- Apply toggle after our overrides are defined
-- ------------------------------------------------------------
ISEntityUI._NC_new_OpenWindow = ISEntityUI.OpenWindow
ISEntityUI._NC_new_OpenHandcraftWindow = ISEntityUI.OpenHandcraftWindow
ISInventoryPaneContextMenu._NC_new_doRecipeList = ISInventoryPaneContextMenu.doRecipeList

local function NC_applyNeatCraftingUiToggle(enabled)
    if enabled then
        -- Enable Neat Crafting UI overrides
        if ISEntityUI._NC_new_OpenWindow then ISEntityUI.OpenWindow = ISEntityUI._NC_new_OpenWindow end
        if ISEntityUI._NC_new_OpenHandcraftWindow then ISEntityUI.OpenHandcraftWindow = ISEntityUI._NC_new_OpenHandcraftWindow end
        if ISInventoryPaneContextMenu._NC_new_doRecipeList then ISInventoryPaneContextMenu.doRecipeList = ISInventoryPaneContextMenu._NC_new_doRecipeList end
    else
        -- Restore vanilla behavior
        if ISEntityUI._NC_old_OpenWindow then ISEntityUI.OpenWindow = ISEntityUI._NC_old_OpenWindow end
        if ISEntityUI._NC_old_OpenHandcraftWindow then ISEntityUI.OpenHandcraftWindow = ISEntityUI._NC_old_OpenHandcraftWindow end
        if ISInventoryPaneContextMenu._NC_old_doRecipeList then ISInventoryPaneContextMenu.doRecipeList = ISInventoryPaneContextMenu._NC_old_doRecipeList end
    end
end

-- Register toggle callback (applies immediately)
NC_RegisterUiToggleCallback(NC_applyNeatCraftingUiToggle)

