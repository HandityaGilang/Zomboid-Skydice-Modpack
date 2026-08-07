local TABAS_ReEquipItemsMenu = {}

local MAX_PREP_SEARCH_DISTANCE = 6

local TABAS_ReEquipItemsUtils = require("TABAS_ReEquipItemsUtils")

local function getStoredEntryName(playerObj, stored)
    local entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(stored)
    if not entry then return nil end

    local item = entry.itemId and playerObj:getInventory():getItemById(entry.itemId) or nil
    if item then
        return item:getName()
    end

    local fullType = entry.fullType
    if fullType and getScriptManager() then
        local scriptItem = getScriptManager():FindItem(fullType)
        if scriptItem and scriptItem.getDisplayName then
            return scriptItem:getDisplayName()
        end
    end

    return fullType or entry.type or tostring(entry.itemId)
end

local function appendStoredEntries(lines, playerObj, list, prefix)
    if not list then return end
    prefix = prefix or " - "
    for _, stored in ipairs(list) do
        local name = getStoredEntryName(playerObj, stored)
        if name then
            lines[#lines + 1] = prefix .. name
        end
    end
end

local function buildStoredItemsDebugText(playerObj, equippedItems)
    if not isDebugEnabled() then return "" end
    if not (playerObj and equippedItems) then return "" end

    local lines = {}
    appendStoredEntries(lines, playerObj, equippedItems.WornClothes)
    if equippedItems.Secondary then
        appendStoredEntries(lines, playerObj, { equippedItems.Secondary })
    end
    if equippedItems.Primary then
        appendStoredEntries(lines, playerObj, { equippedItems.Primary })
    end
    appendStoredEntries(lines, playerObj, equippedItems.HotbarAttachedItems, " * ")

    if #lines == 0 then
        return ""
    end

    return " <LINE> <LINE> " .. getText("ContextMenu_TABAS_ReEquipItems_DebugItems") .. " <LINE> " .. table.concat(lines, " <LINE> ")
end

function TABAS_ReEquipItemsMenu.createMenu(player, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local md = playerObj:getModData()
    if not md or md.tabas_IsBathing then return end
    local equippedItems = TABAS_ReEquipItemsUtils.pruneStoredEntries(playerObj)
    if not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then return end

    local mainOption = context:addOption(getText("ContextMenu_TABAS_ReEquipItems"), playerObj, TABAS_ReEquipItemsMenu.onReEquipItems)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOption, subMenu)
    mainOption.iconTexture = getTexture("media/ui/Icons/tabas_reequip_main.png")

    local reEquipOption = subMenu:addOption(getText("ContextMenu_TABAS_ReEquipItems_Reequip"), playerObj, TABAS_ReEquipItemsMenu.onReEquipItems)
    reEquipOption.iconTexture = getTexture("media/ui/Icons/tabas_reequip_action.png")
    local reEquipTooltip = ISWorldObjectContextMenu.addToolTip()
    local debugText = buildStoredItemsDebugText(playerObj, equippedItems)
    reEquipTooltip.description = getText("ContextMenu_TABAS_ReEquipItems_tooltip") .. debugText
    reEquipOption.toolTip = reEquipTooltip

    local discardOption = subMenu:addOption(getText("ContextMenu_TABAS_ReEquipItems_Discard"), playerObj, TABAS_ReEquipItemsMenu.onDiscardStoredItems)
    local discardTooltip = ISWorldObjectContextMenu.addToolTip()
    discardTooltip.description = getText("ContextMenu_TABAS_ReEquipItems_Discard_tooltip") .. debugText
    discardOption.toolTip = discardTooltip
    discardOption.iconTexture = getTexture("media/ui/Icons/tabas_reequip_discard.png")
end

function TABAS_ReEquipItemsMenu.onReEquipItems(playerObj)
    if not TABAS_ReEquipItemsUtils.canRun(playerObj, MAX_PREP_SEARCH_DISTANCE) then
        return
    end

    local prepSq = TABAS_ReEquipItemsUtils.getPrepSquare(playerObj)
    if TABAS_ReEquipItemsUtils.needsPrepWalk(playerObj) or TABAS_ReEquipItemsUtils.shouldReturnToPrepSquare(playerObj) then
        if prepSq and not luautils.walk(playerObj, prepSq, true) then
            return
        end
        ISTimedActionQueue.queueActions(playerObj, TABAS_ReEquipItemsUtils.queueAll)
        return
    end

    TABAS_ReEquipItemsUtils.queueAll(playerObj)
end

function TABAS_ReEquipItemsMenu.onDiscardStoredItems(playerObj)
    if not playerObj then return end

    local md = playerObj:getModData()
    md.tabas_EquippedItems = nil
    playerObj:transmitModData()
end

Events.OnFillWorldObjectContextMenu.Add(TABAS_ReEquipItemsMenu.createMenu)

return TABAS_ReEquipItemsMenu
