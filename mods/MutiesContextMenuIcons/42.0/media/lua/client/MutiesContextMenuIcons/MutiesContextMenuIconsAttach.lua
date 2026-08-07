local originalISHotbarDoMenuFromInventory = ISHotbar.doMenuFromInventory;
function ISHotbar.doMenuFromInventory(playerNum, item, context)
    originalISHotbarDoMenuFromInventory(playerNum, item, context);
    local option = context:getOptionFromName(getText("ContextMenu_Attach"));
    if not option then return context end
    option.iconTexture = getTexture("media/ui/icons/Insert Link.png");
end

local originalISHotbarDoMenu = ISHotbar.doMenu
function ISHotbar.doMenu(hotbar, slotIndex)
    originalISHotbarDoMenu(hotbar, slotIndex);
    local context = getPlayerContextMenu(hotbar.playerNum);
    if not context then return end
    local option = context:getOptionFromName(getText("ContextMenu_Attach"));
    if not option then return end
    option.iconTexture = getTexture("media/ui/icons/Insert Link.png");
end