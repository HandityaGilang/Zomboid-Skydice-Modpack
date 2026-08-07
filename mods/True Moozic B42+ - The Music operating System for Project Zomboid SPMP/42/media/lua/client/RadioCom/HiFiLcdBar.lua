require "ISUI/ISPanel"

HiFiLcdBar = ISPanel:derive("HiFiLcdBar")

function HiFiLcdBar:new(x, y, charWidth)
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
    o.doScroll = false
    o.pos = 0
    o.posCounter = 0
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=1.0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.ledColor = {r=1, g=1, b=1, a=1}
    o.ledTextColor = {r=0, g=0, b=0, a=1}
    o.lcdback = getCore():getOptionFontSizeReal() >= 4
        and getTexture("media/ui/LCD_Display/LCD_Background_Large.png")
        or  getTexture("media/ui/LCD_Display/LCD_Background_Small.png")
    return o
end

function HiFiLcdBar:initialise()
    ISPanel.initialise(self)
end

function HiFiLcdBar:createChildren() end

function HiFiLcdBar:setText(t)
    if self.text ~= t then
        self.text = t
        self.pos = 0
        self.posCounter = 0
    end
end

function HiFiLcdBar:setDoScroll(b)
    self.doScroll = b
    if not b then self.pos = 0; self.posCounter = 0 end
end

function HiFiLcdBar:toggleOn(b)
    if self.isOn ~= b then self.isOn = b; self.pos = 0 end
end

function HiFiLcdBar:getVisibleText()
    local maxW = self.lcdwidth * self.charW
    local text = self.text or ""
    local sep = " *** "
    local loop = text .. sep .. text
    local start = self.pos + 1
    local curW = 0
    local endIdx = start
    while endIdx <= #loop do
        local ch = loop:sub(endIdx, endIdx)
        local chW = getTextManager():MeasureStringX(UIFont.Medium, ch)
        if curW + chW > maxW then break end
        curW = curW + chW
        endIdx = endIdx + 1
    end
    return loop:sub(start, endIdx - 1)
end

function HiFiLcdBar:update()
    ISPanel.update(self)
    local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
    if isPaused then return end
    local lcdW = self.lcdwidth * self.charW
    local textW = getTextManager():MeasureStringX(UIFont.Medium, self.text or "")
    if self.isOn and self.doScroll and self.text and self.text ~= "" and textW > lcdW then
        local dt = UIManager.getSecondsSinceLastUpdate()
        self.posCounter = self.posCounter + dt
        if self.posCounter > 0.35 then
            self.posCounter = 0
            self.pos = self.pos + 1
            if self.pos >= #self.text then self.pos = 0 end
        end
    else
        self.pos = 0
        self.posCounter = 0
    end
end

function HiFiLcdBar:prerender()
    ISPanel.prerender(self)
end

function HiFiLcdBar:renderBackground(_r, _g, _b, _a)
    for i = 0, self.lcdwidth - 1 do
        local px = i * self.charW
        self:drawTextureScaled(self.lcdback, px + 2, 2, self.charW, self.charH, _a, _r, _g, _b)
    end
end

function HiFiLcdBar:render()
    ISPanel.render(self)
    if self.isOn then
        self:renderBackground(self.ledColor.r, self.ledColor.g, self.ledColor.b, self.ledColor.a)
    else
        self:renderBackground(self.ledColor.r, self.ledColor.g, self.ledColor.b, 0.5)
    end
    if self.isOn and self.text and self.text ~= "" then
        local lcdX = 4
        local lcdW = self.lcdwidth * self.charW
        local textW = getTextManager():MeasureStringX(UIFont.Medium, self.text)
        local textY = (self.height - getTextManager():MeasureStringY(UIFont.Medium, self.text)) / 2
        if textW <= lcdW then
            self:drawTextCentre(self.text, lcdX + lcdW / 2, textY,
                self.ledTextColor.r, self.ledTextColor.g, self.ledTextColor.b, self.ledTextColor.a, UIFont.Medium)
        else
            local vis = self:getVisibleText()
            self:drawText(vis, lcdX, textY,
                self.ledTextColor.r, self.ledTextColor.g, self.ledTextColor.b, self.ledTextColor.a, UIFont.Medium)
        end
    end
end
