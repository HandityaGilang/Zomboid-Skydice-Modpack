require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_GrabCorpse = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_GrabCorpse")
local Handler = ISLootWindowObjectControlHandler_GrabCorpse
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end

    if not self.object then return false end
    if not instanceof(self.object, "IsoDeadBody") then return false end
    if self.object:isAnimal() then return false end
    if not self.playerObj then return false end
    if self.playerObj:getVehicle() then return false end
    return true
end

function Handler:getControl()
    if not self.control then
        self:createIconControl()
    end
    return self.control
end

function Handler:createIconControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight, buttonHeight, "", self, Handler.perform)
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Background.png"), 0, 0, btn.width, btn.height, alpha, 0.6, 0.3, 0.1)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Border.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_GrabCorpse.png"), 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end

end

function Handler:handleJoypadContextMenu(context)

end

function Handler:perform()
    if not self.object then return end
    if not self.playerObj then return end

    ISWorldObjectContextMenu.onGrabCorpseItem(nil, self.object, self.playerNum)
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = false
    return o
end