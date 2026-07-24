require "TCMusicClientFunctions"

TCMusic.oldISRadioWindow_activate = ISRadioWindow.activate
function ISRadioWindow.activate(_player, _item, bol)
    if _player == getPlayer() then
        if instanceof(_item, "Radio") then
            if TCMusic.ItemMusicPlayer[_item:getFullType()] then
                local attachedBack = _item.getAttachedSlotType and _item:getAttachedSlotType() == "Back";
                if _player:getSecondaryHandItem() == _item or _player:getPrimaryHandItem() == _item or attachedBack then
                    ISTCBoomboxWindow.activate(_player, _item)
                else
                    -- If the item is a boombox and not in hand, avoid vanilla window
                    -- to prevent null-square power checks.
                    return
                end
            elseif TCMusic.WalkmanPlayer[_item:getFullType()] then
                ISTCBoomboxWindow.activate(_player, _item)
            else
                TCMusic.oldISRadioWindow_activate(_player, _item, bol)
            end
        elseif instanceof(_item, "IsoWaveSignal") then
            local itemSquare = _item.getSquare and _item:getSquare() or nil
            if not itemSquare or not itemSquare.getWorldObjects then
                return
            end
            if not _item:getSprite() or not TCMusic.WorldMusicPlayer[_item:getSprite():getName()] then
                for i = 0, itemSquare:getWorldObjects():size()-1 do
                    local itemObj = itemSquare:getWorldObjects():get(i)
                    if instanceof(itemObj:getItem(), "Radio") then
                        local itemID = itemObj:getItem():getID()
                        local radioItemID = _item:getModData().RadioItemID
                        if itemID == radioItemID then
                            if TCMusic.WorldMusicPlayer[itemObj:getItem():getFullType()] then
                                invItem = itemObj:getItem()
                                square = itemObj:getSquare()
                                square:transmitRemoveItemFromSquare(_item)
                                square:RecalcProperties()
                                square:RecalcAllWithNeighbours(true)
                                local radio = IsoRadio.new(getCell(), square, getSprite(TCMusic.WorldMusicPlayer[invItem:getFullType()]))
                                square:AddTileObject(radio)
                                if invItem:getModData().tcmusic then
                                    radio:getModData().tcmusic = {}
                                    for k, v in pairs(invItem:getModData().tcmusic) do
                                        radio:getModData().tcmusic[k] = v
                                    end
                                else
                                    radio:getModData().tcmusic = {}
                                end
                                radio:getModData().tcmusic.itemid = square:getX() * 1000000 + square:getY() * 1000 + square:getZ()
                                radio:getModData().tcmusic.deviceType = "IsoObject"
                                radio:getModData().tcmusic.isPlaying = false
                                radio:getModData().RadioItemID = invItem:getID()
                                radio:getDeviceData():setIsTurnedOn(false)
                                radio:getDeviceData():setPower(invItem:getDeviceData():getPower())
                                radio:getDeviceData():setDeviceVolume(invItem:getDeviceData():getDeviceVolume())
                                local invMd = invItem:getModData()
                                if invMd and invMd.tcmusic and invMd.tcmusic.batteryHas ~= nil then
                                    if invMd.tcmusic.batteryHas then
                                        radio:getDeviceData():setHasBattery(true)
                                        if invMd.tcmusic.batteryPower ~= nil then
                                            radio:getDeviceData():setPower(invMd.tcmusic.batteryPower)
                                        end
                                    else
                                        radio:getDeviceData():setHasBattery(false)
                                    end
                                else
                                    if invItem:getDeviceData():getIsBatteryPowered() and invItem:getDeviceData():getHasBattery() then
                                        radio:getDeviceData():setPower(invItem:getDeviceData():getPower())
                                    else
                                        radio:getDeviceData():setHasBattery(false)
                                    end
                                end
                                if invItem:getDeviceData() and radio:getDeviceData() and invItem:getDeviceData().getHeadphoneType and radio:getDeviceData().setHeadphoneType then
                                    local hpType = invItem:getDeviceData():getHeadphoneType()
                                    radio:getDeviceData():setHeadphoneType(hpType)
                                end
                                if isClient() then
                                    radio:transmitCompleteItemToServer()
                                end
                                ISTCBoomboxWindow.activate(_player, radio)
                                return
                            elseif TCMusic.WalkmanPlayer[itemObj:getItem():getFullType()] then
                                -- Allow UI for walkman on ground; playback is blocked in UI.
                                ISTCBoomboxWindow.activate(_player, _item)
                                return
                            else
                                TCMusic.oldISRadioWindow_activate(_player, _item, bol)
                                return
                            end
                        end
                    end
                end
            else
                for i = 0, itemSquare:getWorldObjects():size()-1 do
                    local itemObj = itemSquare:getWorldObjects():get(i)
                    if instanceof(itemObj:getItem(), "Radio") then
                        local itemID = itemObj:getItem():getID()
                        local radioItemID = _item:getModData().RadioItemID
                        if itemID == radioItemID then
                            if TCMusic.WorldMusicPlayer[itemObj:getItem():getFullType()] then
                                ISTCBoomboxWindow.activate(_player, _item)
                                return
                            end
                        end
                    end
                end
            end
            TCMusic.oldISRadioWindow_activate(_player, _item, bol)
        else
            TCMusic.oldISRadioWindow_activate(_player, _item, bol)
        end
    end
end
