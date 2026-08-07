local TABAS_ImprovedTubMenu = {}

local TABAS_Iso = require("TABAS_Iso")
local TABAS_MoveUtils = require("TABAS_MoveUtils")
local TABAS_Utils = require("TABAS_Utils")

local COLOR_RED = "<RGB:1,0.5,0.5>"
local TUB_MODE_INSTALL = "install"
local TUB_MODE_UNINSTALL = "uninstall"
local TUB_MODE_DISASSEMBLE = "disassemble"
local SHOWER_MODE_UPGRADE = "upgrade"
local SHOWER_MODE_UNINSTALL = "uninstall"
local SHOWER_MODE_IMPROVE = "improve"

local function tagRequirement(name, tag, count, predicate)
    return {
        kind = "tag",
        name = name,
        tag = tag,
        count = count or 1,
        predicate = predicate,
    }
end

local function itemRequirement(fullType, count)
    return {
        kind = "item",
        fullType = fullType,
        count = count or 1,
    }
end

local TUB_MODE_DEFS = {
    [TUB_MODE_INSTALL] = {
        textKey = "ContextMenu_TABAS_InstallShower",
        tooltipKey = "ContextMenu_TABAS_InstallShower_tooltip",
        skills = {["Woodwork"] = 3},
        getData = function(playerInv)
            local tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken)
            local consumeItem = playerInv:getFirstTypeRecurse("TABAS.WallShowerPacked") or playerInv:getFirstTypeRecurse("Base.Mov_WallShower")
            local showerParts = consumeItem and consumeItem:getFullType() or "Base.Mov_WallShower"
            return {
                tool = tool,
                consumeItem = consumeItem,
                items = {
                    tagRequirement(getItemNameFromFullType("Base.PipeWrench"), ItemTag.PIPE_WRENCH, 1, TABAS_Utils.predicateNotBroken),
                    itemRequirement(showerParts, 1),
                },
            }
        end,
    },
    [TUB_MODE_UNINSTALL] = {
        textKey = "ContextMenu_TABAS_UninstallShower",
        tooltipKey = "ContextMenu_TABAS_UninstallShower_tooltip",
        skills = {["Woodwork"] = 3},
        getData = function(playerInv)
            return {
                tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken),
                items = {
                    tagRequirement(getItemNameFromFullType("Base.PipeWrench"), ItemTag.PIPE_WRENCH, 1, TABAS_Utils.predicateNotBroken),
                },
            }
        end,
    },
    [TUB_MODE_DISASSEMBLE] = {
        textKey = "ContextMenu_TABAS_DisassembleShower",
        tooltipKey = "ContextMenu_TABAS_DisassembleShower_tooltip",
        skills = {["Woodwork"] = 3, ["MetalWelding"] = 1},
        getData = function(playerInv)
            return {
                tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken),
                items = {
                    tagRequirement(getItemNameFromFullType("Base.PipeWrench"), ItemTag.PIPE_WRENCH, 1, TABAS_Utils.predicateNotBroken),
                },
            }
        end,
    },
}

local SHOWER_MODE_DEFS = {
    [SHOWER_MODE_UPGRADE] = {
        textKey = "ContextMenu_TABAS_UpgradeShower",
        tooltipKey = "ContextMenu_TABAS_UpgradeShower_tooltip",
        skills = {["Woodwork"] = 3},
        getData = function(playerInv)
            return {
                tool = playerInv:getFirstTagEvalRecurse(ItemTag.HAMMER, TABAS_Utils.predicateNotBroken),
                materials = {
                    ["Plank"] = 2,
                    ["MetalPipe"] = 1,
                },
                items = {
                    tagRequirement(getItemNameFromFullType("Base.Hammer"), ItemTag.HAMMER, 1, TABAS_Utils.predicateNotBroken),
                    itemRequirement("Base.Plank", 2),
                    itemRequirement("Base.MetalPipe", 1),
                },
            }
        end,
    },
    [SHOWER_MODE_UNINSTALL] = {
        textKey = "ContextMenu_TABAS_UninstallShower",
        tooltipKey = "ContextMenu_TABAS_UninstallShower_tooltip2",
        skills = {["Woodwork"] = 3},
        getData = function(playerInv)
            return {
                tool = playerInv:getFirstTagEvalRecurse(ItemTag.PIPE_WRENCH, TABAS_Utils.predicateNotBroken),
                items = {
                    tagRequirement(getItemNameFromFullType("Base.PipeWrench"), ItemTag.PIPE_WRENCH, 1, TABAS_Utils.predicateNotBroken),
                },
            }
        end,
    },
    [SHOWER_MODE_IMPROVE] = {
        textKey = "ContextMenu_TABAS_ImproveShower",
        tooltipKey = "ContextMenu_TABAS_ImproveShower_tooltip",
        skills = {["Woodwork"] = 1},
        getData = function(playerInv)
            return {
                tool = playerInv:getFirstTagEvalRecurse(ItemTag.SAW, TABAS_Utils.predicateNotBroken),
                items = {
                    tagRequirement(getItemNameFromFullType("Base.Saw"), ItemTag.SAW, 1, TABAS_Utils.predicateNotBroken),
                },
            }
        end,
    },
}

local CLEAN_TUB_DEF = {
    textKey = "ContextMenu_TABAS_CleanTub",
    tooltipKey = "ContextMenu_TABAS_CleanTub_tooltip",
    icon = "media/ui/Icons/tabas_cleantub.png",
    getData = function(playerInv)
        return {
            cleaner = playerInv:getFirstEvalRecurse(TABAS_Utils.predicateCleaningLiquid),
            tool = playerInv:getFirstTagEvalRecurse(ItemTag.CLEAN_STAINS, TABAS_Utils.predicateNotBrokenSponge),
            items = {
                tagRequirement(getItemNameFromFullType("Base.Sponge"), ItemTag.CLEAN_STAINS, 1, TABAS_Utils.predicateNotBrokenSponge),
                itemRequirement("Base.CleaningLiquid", round(ZomboidGlobals.CleanBloodBleachAmount, 1)),
            },
        }
    end,
}

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
    local modelType = TABAS_Iso.getSpriteModelType("Bathtub", faucetObj:getSpriteName())
    if not modelType then return end

    local isImproved = string.find(modelType, "Improved")
    local isClean = string.find(modelType, "Clean")
    local notEnough = false
    local text = ""

    if isImproved then
        local def = TUB_MODE_DEFS[TUB_MODE_INSTALL]
        local data = def.getData(playerInv)
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedTub, faucetObj, tubObj, TUB_MODE_INSTALL, data.tool, data.consumeItem)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, def.skills, data.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    else
        local uninstallDef = TUB_MODE_DEFS[TUB_MODE_UNINSTALL]
        local uninstallData = uninstallDef.getData(playerInv)
        local option1 = subMenu:addOption(getText(uninstallDef.textKey), player, TABAS_ImprovedTubMenu.onImprovedTub, faucetObj, tubObj, TUB_MODE_UNINSTALL, uninstallData.tool, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(uninstallDef.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, uninstallDef.skills, uninstallData.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option1.notAvailable = true
        end
        option1.toolTip = tooltip

        local disassembleDef = TUB_MODE_DEFS[TUB_MODE_DISASSEMBLE]
        local disassembleData = disassembleDef.getData(playerInv)
        local option2 = subMenu:addOption(getText(disassembleDef.textKey), player, TABAS_ImprovedTubMenu.onImprovedTub, faucetObj, tubObj, TUB_MODE_DISASSEMBLE, disassembleData.tool, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(disassembleDef.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, disassembleDef.skills, disassembleData.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option2.notAvailable = true
        end
        option2.toolTip = tooltip
    end

    -- Clean Tub
    if not isClean then
        local data = CLEAN_TUB_DEF.getData(playerInv)
        local option = subMenu:addOption(getText(CLEAN_TUB_DEF.textKey), player, TABAS_ImprovedTubMenu.onCleanTub,  faucetObj, tubObj, data.tool, data.cleaner)
        option.iconTexture = getTexture(CLEAN_TUB_DEF.icon)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(CLEAN_TUB_DEF.tooltipKey)
 
        text, notEnough = requiresTooltipText(playerObj, nil, data.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end
    -- Revert Tub
    if isDebug and (isImproved or isClean) then
        local option = subMenu:addDebugOption(getText("ContextMenu_TABAS_RevertTub"), player, TABAS_ImprovedTubMenu.onRevertTub, faucetObj, tubObj)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_TABAS_RevertTub_tooltip")
        option.toolTip = tooltip
    end
end

function TABAS_ImprovedTubMenu.onImprovedTub(player, faucetObj, tubObj, mode, pipeWrench, wallShower)
    if not TUB_MODE_DEFS[mode] then return end
    local playerObj = getSpecificPlayer(player)
    if not pipeWrench then return end
    if TABAS_MoveUtils.walkToAdjTub(playerObj, faucetObj, true) then
        local cont = pipeWrench:getContainer()

        ISWorldObjectContextMenu.transferIfNeeded(playerObj, pipeWrench)
        ISInventoryPaneContextMenu.equipWeapon(pipeWrench, true, false, player)
        ISTimedActionQueue.add(TABAS_ImprovedTubAction:new(playerObj, faucetObj, tubObj, mode, wallShower))

        if cont then ISCraftingUI.ReturnItemToContainer(playerObj, pipeWrench, cont) end
    end
end

function TABAS_ImprovedTubMenu.onCleanTub(player, faucetObj, tubObj, sponge, bleach)
    local playerObj = getSpecificPlayer(player)
    if not bleach or not sponge then return end
	if TABAS_MoveUtils.walkToAdjTub(playerObj, faucetObj, true) then
        local cont1 = bleach:getContainer()
        local cont2 = sponge:getContainer()

        ISWorldObjectContextMenu.transferIfNeeded(playerObj, bleach)
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, sponge)
        ISInventoryPaneContextMenu.equipWeapon(sponge, true, false, player)
        ISInventoryPaneContextMenu.equipWeapon(bleach, false, false, player)
		ISTimedActionQueue.add(TABAS_CleanTub:new(playerObj, faucetObj, tubObj, bleach))

        if cont1 then ISCraftingUI.ReturnItemToContainer(playerObj, bleach, cont1) end
        if cont2 then ISCraftingUI.ReturnItemToContainer(playerObj, sponge, cont2) end
	end
end

function TABAS_ImprovedTubMenu.onRevertTub(player, faucetObj, tubObj)
    local sq = faucetObj:getSquare()
    local sq2 = tubObj:getSquare()
    if not sq or not sq2 then return end

    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = faucetObj:getObjectIndex(),
        lx = sq2:getX(), ly = sq2:getY(), lindex = tubObj:getObjectIndex()
    }
    sendClientCommand("tabas_object", "revertTub", args)
end

function TABAS_ImprovedTubMenu.doImproveShowerMenu(player, showerObj, context)
    local showerType = TABAS_Iso.getSpriteModelType("Shower", showerObj:getSpriteName())
    if showerType == nil then return end

    local improvedMenu = context:addOption(getText("ContextMenu_TABAS_ImproveShower"))
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(improvedMenu, subMenu)
    -- improvedMenu.iconTexture = getTexture("media/ui/Icons/tabas_ImproveShower.png")
    local tooltip = ISWorldObjectContextMenu.addToolTip()

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local text = ""
    local notEnough = false
    if showerType == "Wall" then
        local def = SHOWER_MODE_DEFS[SHOWER_MODE_UPGRADE]
        local data = def.getData(playerInv)
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE_UPGRADE, data.tool, data.materials)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)

        text, notEnough = requiresTooltipText(playerObj, def.skills, data.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    else
        local def = SHOWER_MODE_DEFS[SHOWER_MODE_UNINSTALL]
        local data = def.getData(playerInv)
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE_UNINSTALL, data.tool, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)
        text, notEnough = requiresTooltipText(playerObj, def.skills, data.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end

    if showerType == "Deluxe" then
        local def = SHOWER_MODE_DEFS[SHOWER_MODE_IMPROVE]
        local data = def.getData(playerInv)
        local option = subMenu:addOption(getText(def.textKey), player, TABAS_ImprovedTubMenu.onImprovedShower, showerObj, SHOWER_MODE_IMPROVE, data.tool, nil)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText(def.tooltipKey)
        text, notEnough = requiresTooltipText(playerObj, def.skills, data.items)
        tooltip.description = tooltip.description .. text

        if notEnough then
            option.notAvailable = true
        end
        option.toolTip = tooltip

    elseif showerType == "Improved Deluxe" and (isDebugEnabled() or isAdmin()) then
        local option = subMenu:addOption(getText("ContextMenu_TABAS_RevertShower"), player, TABAS_ImprovedTubMenu.onRevertShower, showerObj)
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_TABAS_RevertShower_tooltip")

        local facing = TABAS_Iso.getObjectFacing(showerObj)
        if facing and (facing == "N" or facing == "W") then
            tooltip.description = getText("ContextMenu_TABAS_RevertShower_InvaledFacing")
            option.notAvailable = true
        end
        option.toolTip = tooltip
    end
end

function TABAS_ImprovedTubMenu.onImprovedShower(player, showerObj, mode, tool, items)
    if not SHOWER_MODE_DEFS[mode] then return end
    local playerObj = getSpecificPlayer(player)
    local cont
    if not tool then return end
    if luautils.walk(playerObj, showerObj:getSquare(), true) then
        cont = tool:getContainer()
        if tool then
            ISWorldObjectContextMenu.transferIfNeeded(playerObj, tool)
            ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player)
        end

        ISTimedActionQueue.add(TABAS_ImprovedShowerAction:new(playerObj, showerObj, mode, items))

        if tool then ISCraftingUI.ReturnItemToContainer(playerObj, tool, cont) end
    end
end

function TABAS_ImprovedTubMenu.onRevertShower(player, obj)
    local sq = obj:getSquare()
    if not sq then return end

    local args = {x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = obj:getObjectIndex()}
    sendClientCommand("tabas_object", "revertShower", args)
end

return TABAS_ImprovedTubMenu
