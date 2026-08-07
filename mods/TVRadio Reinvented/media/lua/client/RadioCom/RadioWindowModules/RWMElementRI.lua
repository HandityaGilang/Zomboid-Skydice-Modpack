-- **thank you** turbotutone

--require "ISUI/ISCollapsableWindow"

RWMElementRI = ISPanelJoypad:derive("RWMElementRI");

function RWMElementRI:initialise()
    ISPanel.initialise(self)
end

function RWMElementRI:createChildren()
    --self.labelName = ISLabel:new(4,2,self.fontheightMed+2,"device",1,1,1,1,UIFont.Medium, true);
    --self:addChild(self.labelName);

    --ISButton:new (x, y, width, height, title, clicktarget, onclick, onmousedown, allowMouseUpProcessing)
--    self.headerButton = ISButton:new(0, 0, self.width,self.fontheightMed+2,self.titleText or "Title",self, nil);
--    self.headerButton:initialise();
--    self.headerButton:setFont(UIFont.Small);
--    self.headerButton.backgroundColor = {r=0, g=0, b=0, a=0.0};
--    self.headerButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0};
--   self.headerButton.borderColor = {r=1.0, g=1.0, b=1.0, a=0};
    --self.headerButton:setImage(self.buttonTexture);
    --self.headerButton:forceImageSize(self.width, self.fontheightMed+2);
 --   self:addChild(self.headerButton);

    if self.subpanel then
        self.subpanel:setY(0);
        self.subpanel:setWidth(self:getWidth());
        self.subpanel:initialise();
        self.subpanel:setVisible(self.isExpanded);
		self.subpanel.borderColor = {r=1.0, g=1.0, b=1.0, a=0};
        self:addChild(self.subpanel);
    end
   self:calculateHeights();
end

function RWMElementRI:calculateHeights()
 
	self:setHeight(self.subpanel:getHeight())
 --[[
	self.height = self.headerButton:getHeight();
    if self.subpanel then
        self.subpanel:setVisible(self.isExpanded);
        if self.isExpanded then
            self.height = self.height + self.subpanel:getHeight();
        end
    end
    self:setHeight( self.height );]]--
end

function RWMElementRI:clear()
    self.drawJoypadFocus = false;
    if self.subpanel and self.subpanel.clear then
        self.subpanel:clear();
        self:calculateHeights();
    end
end

function RWMElementRI:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    if self.subpanel and self.subpanel.readFromObject then
        local success = self.subpanel:readFromObject( _player, _deviceObject, _deviceData, _deviceType );
        self:calculateHeights();
        return success;
    end
end

function RWMElementRI:prerender()
    ISPanel.prerender(self);
    if self.buttonTexture then
        self:drawTextureScaled(self.buttonTexture, 0, 0,self.width,self.fontheightMed+2, 0, 0, 0, 0);
    end
    --ISPanel.prerender(self);
    --self:drawTextureScaledAspect(self.image, (self.width / 2) - (self.forcedWidthImage / 2), (self.height / 2) - (self.forcedHeightImage / 2),self.forcedWidthImage,self.forcedHeightImage, self.textureColor.r, self.textureColor.g, self.textureColor.b, alpha);
    --ISUIElement:drawTextureScaled(texture, x, y, w, h, a, r, g, b)
end

function RWMElementRI:render()
    ISPanel.render(self);
    if self.drawJoypadFocus then
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0);
        self:drawRectBorder(1, 1, self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
    end
end

function RWMElementRI:setFocus(_playerNum, _radioParent)
    --print("setFocus RMWELEMENT");
    self.playerNum = _playerNum;
    self.radioParent = _radioParent;
    if self.subpanel then
        self.subpanel:setFocus(_playerNum, _radioParent, self);
    end
    setJoypadFocus(self.playerNum, self);
end

function RWMElementRI:onGainJoypadFocus(joypadData)
    self.drawJoypadFocus = true;
end

function RWMElementRI:onLoseJoypadFocus(joypadData)
    self.drawJoypadFocus = false;
    if self.subpanel then
        self.subpanel:clearJoypadFocus(joypadData);
        if self.subpanel.focusElement then
            local child = self.subpanel.focusElement;
            if child and child.isCombobox and child.expanded then
                child:setJoypadFocused(false);
            end
            self.subpanel.focusElement = nil;
        end
    end
end

function RWMElementRI:onJoypadDirUp(joypadData)
	
	self.subpanel:onJoypadDirUp()
end

function RWMElementRI:onJoypadDirDown(joypadData)

	self.subpanel:onJoypadDirDown()
end

function RWMElementRI:onJoypadDirLeft(joypadData)
    
	self.subpanel:onJoypadDirLeft()
end

function RWMElementRI:onJoypadDirRight(joypadData)

	self.subpanel:onJoypadDirRight()
end

function RWMElementRI:onJoypadDown(button)

	self.subpanel:onJoypadDown(button)
end

function RWMElementRI:getAPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getAPrompt then
        return self.subpanel:getAPrompt();
    end
    return nil;
end
function RWMElementRI:getBPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getBPrompt then
        return self.subpanel:getBPrompt();
    end
    return nil;
end
function RWMElementRI:getXPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getXPrompt then
        return self.subpanel:getXPrompt();
    end
    return nil;
end
function RWMElementRI:getYPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getYPrompt then
        return self.subpanel:getYPrompt();
    end
    return nil;
end
function RWMElementRI:getLBPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getLBPrompt then
        return self.subpanel:getLBPrompt();
    end
    return nil;
end
function RWMElementRI:getRBPrompt()
    if self.subpanel and self.subpanel:getIsVisible() and self.subpanel.getRBPrompt then
        return self.subpanel:getRBPrompt();
    end
    return nil;
end

function RWMElementRI:isValidPrompt()
    if self.subpanel then
        return self.subpanel:isValidPrompt();
    end
    return true;
end

function RWMElementRI:new (x, y, width, height, subpanel, title, radioParent)
    local o = {}
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = false;
    o.backgroundColor = {r=0, g=0, b=0, a=0.0};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0};
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.fontheight = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ");
    o.fontheightMed = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ");
    o.buttonTexture = getTexture("media/ui/XpSystemUI/tab_unselected.png");
    o.subpanel = subpanel;
    if o.subpanel and o.subpanel.setParent then
        o.subpanel:setParent( self );
    end
    o.titleText = title;
    o.isExpanded = true;
    o.radioParent = radioParent;
    o.overrideBPrompt = true;
    o.isJoypadWindow = false;
    return o
end

