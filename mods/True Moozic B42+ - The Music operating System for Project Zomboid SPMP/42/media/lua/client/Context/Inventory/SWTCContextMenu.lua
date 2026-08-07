require "RadioCom/SWTCPlayerWindow"

ISInventoryMenuElements = ISInventoryMenuElements or {}

function ISInventoryMenuElements.ContextCustomCD()
    local self = ISMenuElement.new()
    self.invMenu = ISContextManager.getInstance().getInventoryMenu()
    
    function self.init()
    end
    
     function self.isSupportedDevice(_item)
        if not instanceof(_item, "Radio") then
            return false
        end
        
        local itemType = _item:getFullType()
        
        local supportedTypes = {
            "Base.CDplayer",
            "Tsarcraft.TM_CDPlayer_Blue",
            "Tsarcraft.TM_CDPlayer_Purple",
            "Tsarcraft.TM_CDPlayer_Red",
            "Tsarcraft.TM_CDPlayer_Black",
            "Tsarcraft.TM_CDPlayer_Green",
            "Tsarcraft.TM_CDPlayer_Orange",
            "Tsarcraft.TM_CDPlayer_White",
            "Tsarcraft.TM_CDPlayer_TrueMoozic",
        }
        
        for _, supportedType in ipairs(supportedTypes) do
            if itemType == supportedType then
                return true
            end
        end
        
        return false
    end
    
    function self.createMenu(_item)
        if getCore():getGameMode() == "Tutorial" then
            return
        end
        
        local isOurDevice = false
        if instanceof(_item, "Radio") then
            local itemType = _item:getFullType()
            local ourTypes = {
                "Base.CDplayer",
                "Tsarcraft.TM_CDPlayer_Blue",
                "Tsarcraft.TM_CDPlayer_Purple",
                "Tsarcraft.TM_CDPlayer_Red",
                "Tsarcraft.TM_CDPlayer_Black",
                "Tsarcraft.TM_CDPlayer_Green",
                "Tsarcraft.TM_CDPlayer_Orange",
                "Tsarcraft.TM_CDPlayer_White",
                "Tsarcraft.TM_CDPlayer_TrueMoozic",
                "TM_CDTEST.TM_CDPlayer",
            }
            for _, t in ipairs(ourTypes) do
                if itemType == t then
                    isOurDevice = true
                    break
                end
            end
        end
        
        if isOurDevice then
            if self.invMenu.context.removeOptionByName then
                self.invMenu.context:removeOptionByName(getText("IGUI_DeviceOptions"))
            end
            
            if _item:getContainer():getType() == "floor" then
                local square = _item:getWorldItem():getSquare()
                local _obj = nil
                for i=0, square:getObjects():size()-1 do
                    local tObj = square:getObjects():get(i)
                    if instanceof(tObj, "IsoRadio") then
                        if tObj:getModData().RadioItemID == _item:getID() then
                            _obj = tObj
                            break
                        end
                    end
                end
                if _obj ~= nil then
                    self.invMenu.context:addOption(getText("IGUI_SWTC_OpenPlayerWindow"), self.invMenu, self.openPanel, _obj)
                end
            else
                local player = self.invMenu.player
                local isAccessible = false
                
                if player:getPrimaryHandItem() == _item or 
                   player:getSecondaryHandItem() == _item then
                    isAccessible = true
                end
                if not isAccessible and _item:getAttachedSlot() > -1 then
                    local hotbar = getPlayerHotbar(player:getPlayerNum())
                    if hotbar and hotbar:isInHotbar(_item) then
                        isAccessible = true
                    end
                end
                
                if isAccessible then
                    self.invMenu.context:addOption(getText("IGUI_SWTC_OpenPlayerWindow"), self.invMenu, self.openPanel, _item)
                end
            end
        elseif self.isSupportedDevice(_item) then
            if _item:getContainer():getType() == "floor" then
                local square = _item:getWorldItem():getSquare()
                local _obj = nil
                for i=0, square:getObjects():size()-1 do
                    local tObj = square:getObjects():get(i)
                    if instanceof(tObj, "IsoRadio") then
                        if tObj:getModData().RadioItemID == _item:getID() then
                            _obj = tObj
                            break
                        end
                    end
                end
                if _obj ~= nil then
                    self.invMenu.context:addOption(getText("IGUI_SWTC_OpenPlayerWindow"), self.invMenu, self.openPanel, _obj)
                end
            else
                local player = self.invMenu.player
                local isAccessible = false
                
                if player:getPrimaryHandItem() == _item or 
                   player:getSecondaryHandItem() == _item then
                    isAccessible = true
                end
                if not isAccessible and _item:getAttachedSlot() > -1 then
                    local hotbar = getPlayerHotbar(player:getPlayerNum())
                    if hotbar and hotbar:isInHotbar(_item) then
                        isAccessible = true
                    end
                end
                if isAccessible then
                    self.invMenu.context:addOption(getText("IGUI_SWTC_OpenPlayerWindow"), self.invMenu, self.openPanel, _item)
                end
            end
        end
    end
    
    function self.openPanel(_p, _item)
        if CustomHotbarHandler and CustomHotbarHandler.handleCustomMusicPlayerActivation then
            CustomHotbarHandler.handleCustomMusicPlayerActivation(_item, _p.player, _item.getAttachedSlot and _item:getAttachedSlot() or -1)
        else
        SWTCPlayerWindow.activate(_p.player, _item)
    end
end
    function self.openChineseLCDTestPanel(_p)
        if SWTCCLCDWindow then
            local lcdWin = SWTCLCDWindow:new(200, 200, 300, 40)
            lcdWin:addToUIManager()
        end
    end    
    return self
end 