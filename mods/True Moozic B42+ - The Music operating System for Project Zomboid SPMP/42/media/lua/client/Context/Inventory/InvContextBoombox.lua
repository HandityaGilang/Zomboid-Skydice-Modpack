require "TCMusicDefenitions"
ISInventoryMenuElements = ISInventoryMenuElements or {};
function ISInventoryMenuElements.ContextBoombox()
    local self = ISMenuElement.new();
    self.invMenu = ISContextManager.getInstance().getInventoryMenu();
    function self.init()
    end
    function self.createMenu(_item)
        if getCore():getGameMode() == "Tutorial" then
            return;
        end
        if not _item or not instanceof(_item, "Radio") then
            return;
        end
        local itemType = _item.getFullType and _item:getFullType() or "";
        local container = _item.getContainer and _item:getContainer() or nil;
        local isWalkman = TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[itemType] or false;
        local isBoombox = TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[itemType] or false;
        if isWalkman or isBoombox then
            if container and self.invMenu.player and container == self.invMenu.player:getInventory() then
                if isBoombox then
                    local player = self.invMenu.player;
                    local inHand = (player:getPrimaryHandItem() == _item) or (player:getSecondaryHandItem() == _item);
                    local attachedBack = _item.getAttachedSlotType and _item:getAttachedSlotType() == "Back";
                    if not inHand and not attachedBack then
                        return;
                    end
                end
                local context = self.invMenu.context;
                local deviceOptionText = getText("IGUI_DeviceOptions");
                if context.getOptionFromName and context:getOptionFromName(deviceOptionText) then
                    local opt = context:getOptionFromName(deviceOptionText);
                    if context.removeOptionTsar then
                        context:removeOptionTsar(opt);
                    elseif context.removeOption then
                        context:removeOption(opt);
                    end
                end
                if context.addOptionOnTop then
                    context:addOptionOnTop(deviceOptionText, self.invMenu, self.openPanel, _item);
                else
                    context:addOption(deviceOptionText, self.invMenu, self.openPanel, _item);
                end
            end
        elseif container and container.getType and container:getType() == "floor" then
            if isWalkman then
                return
            end
            local worldItem = _item.getWorldItem and _item:getWorldItem() or nil;
            local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil;
            if square and square.getObjects then
                local objs = square:getObjects();
                local link = tostring(_item.getID and _item:getID() or 0) .. "tm";
                for i = 0, objs:size() - 1 do
                    local tObj = objs:get(i);
                    if instanceof(tObj, "IsoRadio") then
                        local md = tObj.getModData and tObj:getModData() or {};
                        if md.RadioItemID == link then
                            local context = self.invMenu.context;
                            local deviceOptionText = getText("IGUI_DeviceOptions");
                            if context.getOptionFromName then
                                local existingOpt = context:getOptionFromName(deviceOptionText);
                                if existingOpt then
                                    if context.removeOption then
                                        context:removeOption(existingOpt);
                                    end
                                end
                            end
                            context:addOptionOnTop(deviceOptionText, self.invMenu, self.openPanel, tObj);
                            break;
                        end
                    end
                end
            end
        end
    end
    function self.openPanel(_p, _item)
        if ISRadioWindow and ISRadioWindow.activate then
            ISRadioWindow.activate(_p.player, _item, true);
        end
    end
    return self;
end
if ISInventoryMenuElements.ContextBoombox then
    Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
        local boomboxContext = ISInventoryMenuElements.ContextBoombox();
        if type(items) == "table" then
            for _, v in ipairs(items) do
                local item = v;
                if not instanceof(v, "InventoryItem") then
                    item = v.items and v.items[1] or nil;
                end
                if item then
                    boomboxContext:createMenu(item);
                end
            end
        else
            boomboxContext:createMenu(items);
        end
    end);
end
