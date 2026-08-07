local TABAS_ImprovedTubMenu = {}

local TABAS_BathTransformDefs = require("TABAS_BathTransformDefs")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_MoveUtils = require("TABAS_MoveUtils")
local TABAS_Utils = require("TABAS_Utils")

local COLOR_RED = "<RGB:1,0.5,0.5>"
local TUB_MODE = TABAS_BathTransformDefs.TUB_MODE
local SHOWER_MODE = TABAS_BathTransformDefs.SHOWER_MODE

local function requiresTooltipText(playerObj, skills, items)
    local playerInv = playerObj:getInventory()
    local lineBreaks = " <LINE> "
    local text = ""
    local notEnough = false
    if skills then
        for k,reqLevel in pairs(skills) do
            local skillName = getText("IGUI_perks_" .. k)
            local curLevel = playerObj:getPerkLevel(Perks[k])
            if skillName and curLevel then
                text = text .. lineBreaks .. " * " .. skillName .. ": " .. tostring(curLevel) .. " / " .. tostring(reqLevel)
                notEnough = notEnough or (curLevel < reqLevel)
            end
        end
    end
    if items then
        for k,req in pairs(items) do
            local name
            local count = 0
            local reqCount

            if type(k) == "number" and type(req) == "table" then
                reqCount = req.count or 1
                if req.kind == "tag" then
                    name = req.name or tostring(req.tag)
                    count = playerInv:getCountEvalRecurse(function(item)
                        return item and item:hasTag(req.tag) and (not req.predicate or req.predicate(item))
                    end)
                elseif req.kind == "item" then
                    name = getItemNameFromFullType(req.fullType)
                    if not name then name = req.fullType end
                    if req.fullType == "Base.CleaningLiquid" and reqCount < 1 then
                        count = playerInv:getCountEvalRecurse(TABAS_Utils.predicateCleaningLiquid)
                    else
                        count = playerInv:getCountTypeRecurse(req.fullType)
                    end
                end
            else
                reqCount = req
                name = getItemNameFromFullType(k)
                if not name then name = k end
                if k == "Base.CleaningLiquid" and reqCount < 1 then
                    count = playerInv:getCountEvalRecurse(TABAS_Utils.predicateCleaningLiquid)
                else
                    count = playerInv:getCountTypeRecurse(k)
                end
            end
            text = text .. lineBreaks .. " - " .. name .. ": " .. tostring(count) .. " / " .. tostring(reqCount)
            notEnough = notEnough or (count < reqCount)
        end
    end
    return " <BR> " .. getText("ContextMenu_Require", text), notEnough
end

function TABAS_ImprovedTubMenu.doImproveTubMenu(player, faucetObj, tubObj, hasTfc, context, isDebug)
    local improvedMenu = context:addOption(getText("ContextMenu_TABAS_ImproveTub"))
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(improvedMenu, subMenu)
    improvedMenu.iconTexture = getTexture("media/ui/Icons/tabas_improveTub.png")
    local tooltip = ISWorldObjectContextMenu.addToolTip()

    if hasTfc then
        improvedMenu.notAvailable = true
        tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_RequiredToEmpty")
        improvedMenu.toolTip = tooltip
        return
    end

    local playerObj = getSpecificPlayer(player)
	local playerInv = playerObj:getInventory()
    local bathtubDefsBySprite = TABAS_Iso.getSpritesTable("Index", "BathtubDefBySprite")
    local currentTubDef = bathtubDefsBySprite and bathtubDefsBySprite[faucetObj:getSpriteName()]
    local modelType = currentTubDef and currentTubDef.modelType or TABAS_Iso.getSpriteModelType("Bathtub", faucetObj:getSpriteName())
    if not currentTubDef or not modelType then return end

    local isImproved = currentTubDef.isImproved
    local isClean = currentTubDef.isClean
    local notEnough = false
    local text = ""

    if TABAS_BathTransformDefs.canUseBathtubTransform(TUB_MODE.INSTALL, currentTubDef) then
        local def = TABAS_BathTransformDefs.getBathtubModeDef(TUB_MODE.INSTALL)
        if not def then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken)
        local consumeItem = playerInv:getFirstTypeRecurse("TABAS.WallShowerPacked") or playerInv:getFirstTypeRecurse("Base.Mov_WallShower")
        local showerParts = consumeItem and consumeItem:getFullType() or "Base.Mov_WallShower"
        local items = {
            {
                kind = "tag",
                name = getItemNameFromFullType("Base.PipeWrench"),
                tag = ItemTag.PIPE_WRENCH,
                count = 1,
                predicate = TABAS_Utils.predicateNotBroken,
            },
            {
                kind = "item",
                fullType = showerParts,
                count = 1,
            },
        }
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onBathtubTransform, faucetObj, tubObj, TUB_MODE.INSTALL, tool, consumeItem, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, def.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    else
        local uninstallDef = TABAS_BathTransformDefs.getBathtubModeDef(TUB_MODE.UNINSTALL)
        if not uninstallDef then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken)
        local items = {
            {
                kind = "tag",
                name = getItemNameFromFullType("Base.PipeWrench"),
                tag = ItemTag.PIPE_WRENCH,
                count = 1,
                predicate = TABAS_Utils.predicateNotBroken,
            },
        }
        local option1 = subMenu:addOption(getText(uninstallDef.textKey), player, TABAS_ImprovedTubMenu.onBathtubTransform, faucetObj, tubObj, TUB_MODE.UNINSTALL, tool, nil, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(uninstallDef.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, uninstallDef.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option1.notAvailable = true
        end
        option1.toolTip = tooltip

        local disassembleDef = TABAS_BathTransformDefs.getBathtubModeDef(TUB_MODE.DISASSEMBLE)
        if not disassembleDef then return end
        local option2 = subMenu:addOption(getText(disassembleDef.textKey), player, TABAS_ImprovedTubMenu.onBathtubTransform, faucetObj, tubObj, TUB_MODE.DISASSEMBLE, tool, nil, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(disassembleDef.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, disassembleDef.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option2.notAvailable = true
        end
        option2.toolTip = tooltip
    end

    -- Clean Tub
    if TABAS_BathTransformDefs.canUseBathtubTransform(TUB_MODE.CLEAN, currentTubDef) then
        local def = TABAS_BathTransformDefs.getBathtubModeDef(TUB_MODE.CLEAN)
        if not def then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.CLEAN_STAINS, TABAS_Utils.predicateCleanStainsTool)
        local cleaner = playerInv:getFirstEvalRecurse(TABAS_Utils.predicateCleaningLiquid)
        local items = {
            {
                kind = "tag",
                name = tool and tool:getDisplayName() or "Cleaning Tool",
                tag = ItemTag.CLEAN_STAINS,
                count = 1,
                predicate = TABAS_Utils.predicateCleanStainsTool,
            },
            {
                kind = "item",
                fullType = "Base.CleaningLiquid",
                count = round(ZomboidGlobals.CleanBloodBleachAmount, 1),
            },
        }
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onBathtubTransform,  faucetObj, tubObj, TUB_MODE.CLEAN, tool, nil, cleaner)
        option.iconTexture = getTexture(def.icon)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)
 
        text, notEnough = requiresTooltipText(playerObj, nil, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end

    -- Revert Tub
    if isDebug then
        TABAS_ImprovedTubMenu.doTubDebugModelMenu(player, faucetObj, tubObj, subMenu, modelType)
    end
end

function TABAS_ImprovedTubMenu.onBathtubTransform(player, faucetObj, tubObj, mode, tool, consumeItem, cleaner)
    if not TABAS_BathTransformDefs.getBathtubModeDef(mode) then return end
    local playerObj = getSpecificPlayer(player)
    local faucetSq = faucetObj:getSquare()
    local tubSq = tubObj:getSquare()
    if not faucetSq or not tubSq or not tool then return end

    if luautils.walk(playerObj, faucetSq, true) then
        local toolCont = tool:getContainer()
        local extraCont = consumeItem and consumeItem:getContainer() or cleaner and cleaner:getContainer() or nil

        ISWorldObjectContextMenu.transferIfNeeded(playerObj, tool)
        if consumeItem then
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, consumeItem)
        end
        if cleaner then
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, cleaner)
        end

        ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player)
        if cleaner then
            ISInventoryPaneContextMenu.equipWeapon(cleaner, false, false, player)
        end

        ISTimedActionQueue.add(TABAS_ImprovedTubAction:new(playerObj, faucetSq, tubSq, mode, tool, consumeItem, cleaner))

        if toolCont then ISCraftingUI.ReturnItemToContainer(playerObj, tool, toolCont) end
        if extraCont and consumeItem then ISCraftingUI.ReturnItemToContainer(playerObj, consumeItem, extraCont) end
        if extraCont and cleaner then ISCraftingUI.ReturnItemToContainer(playerObj, cleaner, extraCont) end
    end
end

function TABAS_ImprovedTubMenu.doTubDebugModelMenu(player, faucetObj, tubObj, context, currentModelType)
    if not context or not currentModelType then return end

    local option = context:addDebugOption("Debug: Set Tub Model")
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, subMenu)

    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = "Debug only. Convert this bathtub to any registered model."
    option.toolTip = tooltip

    local debugModelDefs = TABAS_BathTransformDefs.getBathtubDebugModelDefs()
    for i=1, #debugModelDefs do
        local modelDef = debugModelDefs[i]
        local label = modelDef.modelType
        if modelDef.modelType == "Large Deluxe" then
            label = modelDef.modelType .. " [Default]"
        end
        local innerOption = subMenu:addDebugOption(label, player, TABAS_ImprovedTubMenu.onSetTubModel, faucetObj, tubObj, modelDef.modelType)

        if modelDef.modelType == currentModelType then
            innerOption.notAvailable = true
        end
    end
end

function TABAS_ImprovedTubMenu.onSetTubModel(player, faucetObj, tubObj, modelType)
    local sq = faucetObj:getSquare()
    local sq2 = tubObj:getSquare()
    if not sq or not sq2 or not modelType then return end

    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = faucetObj:getObjectIndex(),
        lx = sq2:getX(), ly = sq2:getY(), lindex = tubObj:getObjectIndex(),
        modelType = modelType,
    }
    sendClientCommand("tabas_object", "setTubModel", args)
end

function TABAS_ImprovedTubMenu.doImproveShowerMenu(player, showerObj, context)
    local showerDefsBySprite = TABAS_Iso.getSpritesTable("Index", "ShowerDefBySprite")
    local currentShowerDef = showerDefsBySprite and showerDefsBySprite[showerObj:getSpriteName()]
    local modelType = currentShowerDef and currentShowerDef.modelType or TABAS_Iso.getSpriteModelType("Shower", showerObj:getSpriteName())
    if not currentShowerDef or not modelType then return end

    local improvedMenu = context:addOption(getText("ContextMenu_TABAS_ImproveShower"))
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(improvedMenu, subMenu)
    -- improvedMenu.iconTexture = getTexture("media/ui/Icons/tabas_ImproveShower.png")
    local tooltip = ISWorldObjectContextMenu.addToolTip()

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local text = ""
    local notEnough = false
    if TABAS_BathTransformDefs.canUseShowerTransform(SHOWER_MODE.UPGRADE, currentShowerDef) then
        local def = TABAS_BathTransformDefs.getShowerModeDef(SHOWER_MODE.UPGRADE)
        if not def then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.HAMMER, TABAS_Utils.predicateNotBroken)
        local materials = {
            ["Plank"] = 2,
            ["MetalPipe"] = 1,
        }
        local progressItem = playerInv:getFirstTypeRecurse("Base.Plank") or playerInv:getFirstTypeRecurse("Base.MetalPipe")
        local items = {
            {
                kind = "tag",
                name = getItemNameFromFullType("Base.Hammer"),
                tag = ItemTag.HAMMER,
                count = 1,
                predicate = TABAS_Utils.predicateNotBroken,
            },
            {
                kind = "item",
                fullType = "Base.Plank",
                count = 2,
            },
            {
                kind = "item",
                fullType = "Base.MetalPipe",
                count = 1,
            },
        }
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE.UPGRADE, tool, progressItem, materials)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, def.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    else
        local def = TABAS_BathTransformDefs.getShowerModeDef(SHOWER_MODE.UNINSTALL)
        if not def then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken)
        local items = {
            {
                kind = "tag",
                name = getItemNameFromFullType("Base.PipeWrench"),
                tag = ItemTag.PIPE_WRENCH,
                count = 1,
                predicate = TABAS_Utils.predicateNotBroken,
            },
        }
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE.UNINSTALL, tool, nil, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)
        text, notEnough = requiresTooltipText(playerObj, def.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end

    if TABAS_BathTransformDefs.canUseShowerTransform(SHOWER_MODE.IMPROVE, currentShowerDef) then
        local def = TABAS_BathTransformDefs.getShowerModeDef(SHOWER_MODE.IMPROVE)
        if not def then return end
        local tool = playerInv:getFirstTagEvalRecurse(ItemTag.SAW, TABAS_Utils.predicateNotBroken)
        local items = {
            {
                kind = "tag",
                name = getItemNameFromFullType("Base.Saw"),
                tag = ItemTag.SAW,
                count = 1,
                predicate = TABAS_Utils.predicateNotBroken,
            },
        }
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE.IMPROVE, tool, nil, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)
        text, notEnough = requiresTooltipText(playerObj, def.skills, items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end

    if isDebugEnabled() or isAdmin() then
        TABAS_ImprovedTubMenu.doShowerDebugModelMenu(player, showerObj, subMenu, modelType)
    end
end

function TABAS_ImprovedTubMenu.onImprovedShower(player, showerObj, mode, tool, progressItem, materials)
    if not TABAS_BathTransformDefs.getShowerModeDef(mode) then return end
    local playerObj = getSpecificPlayer(player)
    local square = showerObj:getSquare()
    if not square then return end

    local cont
    if not tool then return end
    if luautils.walk(playerObj, showerObj:getSquare(), true) then
        cont = tool:getContainer()
        if tool then
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, tool)
            ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player)
        end

        ISTimedActionQueue.add(TABAS_ImprovedShowerAction:new(playerObj, square, mode, progressItem, materials))

        if tool then ISCraftingUI.ReturnItemToContainer(playerObj, tool, cont) end
    end
end

function TABAS_ImprovedTubMenu.doShowerDebugModelMenu(player, showerObj, context, currentModelType)
    if not context or not currentModelType then return end

    local facing = TABAS_Iso.getObjectFacing(showerObj)
    if not facing then return end

    local option = context:addDebugOption("Debug: Set Shower Model")
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, subMenu)

    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = "Debug only. Convert this shower to any registered model."
    option.toolTip = tooltip

    local debugModelDefs = TABAS_BathTransformDefs.getShowerDebugModelDefs()
    for i=1, #debugModelDefs do
        local modelDef = debugModelDefs[i]
        local label = modelDef.modelType
        local spriteName = modelDef["sprite" .. facing]
        local innerOption = subMenu:addDebugOption(label, player, TABAS_ImprovedTubMenu.onSetShowerModel, showerObj, spriteName)

        if modelDef.modelType == currentModelType or not spriteName then
            innerOption.notAvailable = true
        end
    end
end

function TABAS_ImprovedTubMenu.onSetShowerModel(player, obj, spriteName)
    local sq = obj:getSquare()
    if not sq or not spriteName then return end

    local args = {x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = obj:getObjectIndex(), spriteName = spriteName}
    sendClientCommand("tabas_object", "setShowerModel", args)
end

return TABAS_ImprovedTubMenu
