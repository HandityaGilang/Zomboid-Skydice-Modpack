require "RadioCom/HiFiWindow"

ISInventoryMenuElements = ISInventoryMenuElements or {}

function ISInventoryMenuElements.ContextHiFiStereo()
    local self = ISMenuElement.new()
    self.invMenu = ISContextManager.getInstance().getInventoryMenu()

    local HIFI_TYPES = {
        "Tsarcraft.TM_HiFiStereo",
    }

    local function isHiFiDevice(item)
        if not instanceof(item, "Radio") then return false end
        local ft = item:getFullType()
        for _, t in ipairs(HIFI_TYPES) do
            if ft == t then return true end
        end
        return false
    end

    function self.init() end

    function self.createMenu(_item)
        if getCore():getGameMode() == "Tutorial" then return end
        if not isHiFiDevice(_item) then return end

        -- Remove default device options for our HiFi
        if self.invMenu.context.removeOptionByName then
            self.invMenu.context:removeOptionByName(getText("IGUI_DeviceOptions"))
        end

        if _item:getContainer():getType() == "floor" then
            local square = _item:getWorldItem():getSquare()
            local _obj = nil
            for i = 0, square:getObjects():size() - 1 do
                local tObj = square:getObjects():get(i)
                if instanceof(tObj, "IsoRadio") then
                    if tObj:getModData().RadioItemID == _item:getID() then
                        _obj = tObj
                        break
                    end
                end
            end
            if _obj then
                self.invMenu.context:addOption("Open HiFi Stereo", self.invMenu, self.openPanel, _obj)
            end
        else
            local player = self.invMenu.player
            local isAccessible = false
            if player:getPrimaryHandItem() == _item or player:getSecondaryHandItem() == _item then
                isAccessible = true
            end
            if isAccessible then
                self.invMenu.context:addOption("Open HiFi Stereo", self.invMenu, self.openPanel, _item)
            end
        end
    end

    function self.openPanel(_p, _item)
        HiFiWindow.activate(_p.player, _item)
    end

    return self
end
