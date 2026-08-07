require "ISUI/ISPanel"

SWTClcdbar = ISPanel:derive("SWTClcdbar");

function SWTClcdbar:new(x, y, charWidth)
    local fontHeight = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ")
    local charH = fontHeight + 4 
    local charW = getCore():getOptionFontSizeReal() >= 4 and 21 or 14
    local w = (charWidth * charW) + 4
    local h = charH + 4
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.charW = charW
    o.charH = charH
    o.lcdwidth = charWidth
    o.isOn = true
    o.text = ""
    o.textCache = ""
    o.doScroll = false
    o.pos = 0
    o.posCounter = 0
    o.background = true;
    o.backgroundColor = {r=0, g=0, b=0, a=1.0};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.gridColor = {r=0.0, g=0.3, b=0.0, a=1};
    o.greyCol = { r=0.4,g=0.4,b=0.4,a=1};
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.ledColor = { r=1, g=1, b=1 , a=1};
    o.ledTextColor = { r=0, g=0, b=0, a=1 };
    o.lcdback = getCore():getOptionFontSizeReal() >= 4 and getTexture("media/ui/LCD_Display/LCD_Background_Large.png") or getTexture("media/ui/LCD_Display/LCD_Background_Small.png");
    return o
end

function SWTClcdbar:initialise()
    ISPanel.initialise(self)
end

function SWTClcdbar:createChildren()
end

function SWTClcdbar:getMaxVisibleChars()
    local maxWidth = self.lcdwidth * self.charW
    local avgCharWidth = getTextManager():MeasureStringX(UIFont.Medium, "测A") / 2
    return math.floor(maxWidth / avgCharWidth)
end

function SWTClcdbar:getVisibleText()
    local maxWidth = self.lcdwidth * self.charW
    local text = self.text or ""
    local interval = " *** "
    local startIdx = self.pos + 1
    local curWidth = 0
    local endIdx = startIdx
    local len = text:len()
    local loopText = text .. interval .. text
    local loopLen = len + interval:len() + len
    while endIdx <= startIdx + len + interval:len() do
        local ch = loopText:sub(endIdx, endIdx)
        local chWidth = getTextManager():MeasureStringX(UIFont.Medium, CN)
        if curWidth + chWidth > maxWidth then
            break
        end
        curWidth = curWidth + chWidth
        endIdx = endIdx + 1
    end
    return loopText:sub(startIdx, endIdx - 1)
end

function SWTClcdbar:update()
    ISPanel.update(self)
    local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
    if isPaused then return end

    local lcdW = self.lcdwidth * self.charW
    local textWidth = getTextManager():MeasureStringX(UIFont.Medium, self.text or "")
    local specialKeys = {
        [getText("IGUI_SWTC_NoCD")] = true,
        [getText("IGUI_SWTC_Ready")] = true,
        [getText("IGUI_SWTC_NEED_HEADPHONES")] = true
    }

    if self.isOn and self.doScroll and self.text and self.text ~= "" and textWidth > lcdW and not specialKeys[self.text] then
        local ticks = UIManager.getSecondsSinceLastUpdate()
        self.posCounter = self.posCounter + ticks
        if self.posCounter > 0.35 then
            self.posCounter = 0
            self.pos = self.pos + 1
            if self:getVisibleText() == "" or self.pos >= self.text:len() then
                self.pos = 0
            end
        end
    else
        self.pos = 0
        self.posCounter = 0
    end
end

function SWTClcdbar:prerender()
    ISPanel.prerender(self);
end

function SWTClcdbar:toggleOn( _b )
    if self.isOn~=_b then
        self.isOn = _b;
        self.pos = 0;
    end
end

function SWTClcdbar:renderChar( _pos, _index, _r, _g, _b, _a )
    if self.javaObject ~= nil then
        local yoffset = 0;
        if _index>=32 then
            _index = _index-32;
            yoffset = SWTClcdbar.charH;
        end
        local ind = _index*SWTClcdbar.charW;
        local pos = _pos*SWTClcdbar.charW;
        self.javaObject:DrawSubTextureRGBA(self.lcdfont,
                ind, yoffset, SWTClcdbar.charW, SWTClcdbar.charH,
                pos+2, 2, SWTClcdbar.charW, SWTClcdbar.charH,
                _r, _g, _b, _a);
    end
end

function SWTClcdbar:isSpecial( _char )
    for i=1,#SWTClcdbar.special do
        if SWTClcdbar.special[i]==_char then
            return true;
        end
    end
    return false;
end

function SWTClcdbar:printChar( _pos, _char )
    local index = 0;
    if self:isSpecial(_char) then
        index = string.find(SWTClcdbar.indexes, "%".._char:lower());
    else
        index = string.find(SWTClcdbar.indexes, _char:lower());
    end
    if _char=="." then
        index = 15;
    end
    self:renderChar(_pos, index and index-1 or 0, self.ledTextColor.r, self.ledTextColor.g, self.ledTextColor.b, self.ledTextColor.a);
end

function SWTClcdbar:render()
    ISPanel.render(self)
    if self.isOn then
        self:renderBackground(self.ledColor.r, self.ledColor.g, self.ledColor.b, self.ledColor.a)
    else
        self:renderBackground(self.ledColor.r, self.ledColor.g, self.ledColor.b, 0.5)
    end

    if self.isOn and self.text and self.text ~= "" then
        local lcdX = 4
        local lcdW = self.lcdwidth * self.charW
        local textToShow = self:getVisibleText()
        local textWidth = getTextManager():MeasureStringX(UIFont.Medium, self.text)
        local textY = (self.height - getTextManager():MeasureStringY(UIFont.Medium, textToShow)) / 2

        local specialKeys = {
            [getText("IGUI_SWTC_NoCD")] = true,
            [getText("IGUI_SWTC_Ready")] = true,
            [getText("IGUI_SWTC_NEED_HEADPHONES")] = true
        }

        if textWidth <= lcdW or specialKeys[self.text] then
            local textX = lcdX + lcdW / 2
            self:drawTextCentre(self.text, textX, textY, self.ledTextColor.r, self.ledTextColor.g, self.ledTextColor.b, self.ledTextColor.a, UIFont.Medium)
        else
            self:drawText(textToShow, lcdX, textY, self.ledTextColor.r, self.ledTextColor.g, self.ledTextColor.b, self.ledTextColor.a, UIFont.Medium)
        end
    end
end

function SWTClcdbar:renderBackground(_r, _g, _b, _a)
    assert(type(self.lcdwidth) == "number", "lcdwidth is not a number: "..tostring(self.lcdwidth).." type="..type(self.lcdwidth))
    assert(type(self.charW) == "number", "charW is not a number: "..tostring(self.charW).." type="..type(self.charW))
    assert(type(self.charH) == "number", "charH is not a number: "..tostring(self.charH).." type="..type(self.charH))
    for i=0, self.lcdwidth-1 do
        local pos = i * self.charW
        self:drawTextureScaled(self.lcdback, pos+2, 2, self.charW, self.charH, _a, _r, _g, _b)
    end
end

function SWTClcdbar:setDoScroll(_b)
    self.doScroll = _b
    if not self.doScroll then
        self.pos = 0
        self.posCounter = 0
    end
end

function SWTClcdbar:setTextMode(_b)
    self.textMode = _b;
end

function SWTClcdbar:setText(_text)
    if self.textCache ~= _text then
        self.textCache = _text
        self.text = _text or ""
        self.pos = 0
    end
end
