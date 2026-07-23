local json = require("ss.json")
local utils = require("ss.utils")
local stats = require("ss.stats")
local color = utils.color
local saveConfig = utils.fn.saveConfig

local getBarTitile = utils.fn.getBarTitile
local listContains = utils.fn.listContains
local getOptName = utils.fn.getOptName
local getPColor = utils.fn.getPColor


local getStrWidth = utils.fn.getStrWidth
local getTempertueStr = utils.fn.getTempertueStr
local to_upper = utils.fn.to_upper


local SSBar = ISPanel:derive("SSBar")

local function getReverseStat(value)
    local tbl = stats._reverse

    if tbl[value] then return tbl[value] end

    for k, v in pairs(tbl) do
        if v == value then
            return k
        end
    end
    return nil
end

function SSBar:drawTextWithShadow(text, x, y)
    self:drawText(text, x + 1, y, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x, y + 1, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x - 1, y, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x, y - 1, 0.0, 0.0, 0.0, 0.66, self.font)

    self:drawText(text, x + 1, y + 1, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x + 1, y - 1, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x - 1, y + 1, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x - 1, y - 1, 0.0, 0.0, 0.0, 0.66, self.font)

    self:drawText(text, x, y, 1.0, 1.0, 1.0, 1.0, self.font)
end

function SSBar:drawRuler(x, y, p)
    local ruler_width = 4
    local c = self.backgroundColor
    local w, h

    if not self.config.isVertical then
        x, y = x + p*self.barLength, y
        w, h = 2, ruler_width
    else
        x, y = x, y + (1-p)*self.barLength
        w, h = ruler_width, 2
    end


    self:drawRectStatic(x - 1, y - 1, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x - 1, y + h, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y - 1, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y + h, 1, 1, c.a, c.r, c.g, c.b)

    self:drawRectStatic(x - 1, y    , 1, h, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y    , 1, h, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x    , y - 1, w, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x    , y + h, w, 1, c.a, c.r, c.g, c.b)

    self:drawRectStatic(x , y , w, h, 1.0, 1.0, 1.0, 1.0)
end

function SSBar:getBarColor(value, isNegative, ruler)
    if ruler == nil then
        ruler = {75, 50, 25, 10}
    end
    -- value in range [0, 100]
    -- ivalue is 0 or 100
    local c = color.green
    if isNegative then 
        value = 100 - value 
        ruler = {
            100 - ruler[1],
            100 - ruler[2],
            100 - ruler[3],
            100 - ruler[4]
        }
    end

    if value > ruler[1] then
        c = getPColor(color.yellow, color.green, (value - ruler[1]) / (100 - ruler[1]))
    elseif value > ruler[2] then
        c = getPColor(color.orangeyellow, color.yellow, (value - ruler[2]) / (ruler[1] - ruler[2]))
    elseif value > ruler[3] then
        c = getPColor(color.orange, color.orangeyellow, (value - ruler[3]) / (ruler[2] - ruler[3]))
    elseif value > ruler[4] then
        c = getPColor(color.red, color.orange, (value - ruler[4]) / (ruler[3] - ruler[4]))
    else
        c = color.red
    end
    return c

end

function SSBar:prepareBarInfo()
    local barInfo = {}
    -- title, valueText, color, percent, type, name, ruler

    local bars = {}
    for _, name in ipairs(stats._values) do
        if not stats._reverse[name] then 
            if self.config.shownConfig[name] then
                if self.config.toggleStats[name] then
                    name = getReverseStat(name) or name
                end
                table.insert(bars, stats[name])
            end
        end
    end

    for _, bar in ipairs(bars) do
        local title = getBarTitile(to_upper(bar.name))
        local name = bar.name
        local _type = bar.type

        local value = nil
        local percent = 1
        local text = "-"
        local c = color.black

        local ruler = nil
        if bar.ruler then
            ruler = {bar.ruler[1], bar.ruler[2], bar.ruler[3], bar.ruler[4]}
        end

        if bar.valueFn then value = bar.valueFn(self.player) end

        if string.sub(_type, 1, 6) == "simple" then
            local valueFlow = nil
            if value then
                if value > 100 then
                    valueFlow, value = round(value - 100), 100
                end
                percent = value / 100
            end
            if value then 
                c = self:getBarColor(value, string.sub(_type, -8) == "negative", ruler)
            end

            if value then text = tostring(value) end
            if valueFlow then text = text .. "(" .. valueFlow .. ")" end
            text = text .. " / 100"
        end
        if string.sub(_type, 1, 5) == "plain" then
            local vs = bar.vs

            local v1 = vs[1] or 0
            local v2 = vs[2] or 100
            local v3 = vs[3] or 100

            if string.find(_type, "pg") and vs ~= nil then
                if value < v1 then
                    percent = 0
                elseif value > v3 then
                    percent = 1
                else
                    percent = (value - v1) / (v3 - v1)
                end

            end
            if string.find(_type, "bg") and vs ~= nil then
                local vmin = v1 + (v2 - v1) * 0.3
                local vmax = v2 + (v3 - v2) * 0.7
                if value > vmax then
                    c = color.red
                elseif value > v2 then
                    local p = (value - v2) / (vmax - v2)
                    c = getPColor(color.green, color.red, p)
                elseif value > vmin then
                    local p = (v2 - value) / (v2 - vmin)
                    c = getPColor(color.green, color.blue, p)
                else
                    c = color.blue
                end
            end

            if value then text = tostring(value) end
        end
        if _type == "temp" then
            if value then
                if name == "bodytemp" then
                    text = getTempertueStr(value)
                else
                    text = tostring(value)
                end
            end

        end

    
        -- if _type == "custom" then pass end
        if bar.percentFn then percent = bar.percentFn(self.player) or percent end
        if bar.textFn then text = bar.textFn(self.player) or text end
        if bar.colorFn then c = bar.colorFn(self.player) or c end

        table.insert(barInfo, { title, text, c, percent, _type, name, ruler})
    end
    self.barInfo = barInfo

    -- update moveWithMouse
    if self.config.locked then
        self.moveWithMouse = false
    else
        self.moveWithMouse = true
    end

end

function SSBar:adjustWindowSize()
    local count = #self.barInfo

    -- init var 
    self.titleLength = 20
    self.textLength  = 20

    -- code add by updating UI when fontSize changes
    self.font = utils.font[self.config.fontSize] or utils.font.Small
    self.config.barWidth = utils.fn.lineHight(utils.font[self.config.fontSize]) or 20

    for _, i in ipairs(self.barInfo) do
        local title = i[1]
        local text = i[2]
        local len = getStrWidth(self.font, title)
        if len > self.titleLength then self.titleLength = len end
        len = getStrWidth(self.font, text)
        if len > self.textLength then self.textLength = len end
    end

    -- barlength decided by fontSize and barInc
    if not self.config.locked then 
        --when bar isnt locked,the shortest bar would changed by self.titleLength and self.textLength
        if self.config.barInc < self.titleLength + self.textLength then
            self.config.barInc = self.titleLength + self.textLength
        end
    end
    self.barLength = self.config.barInc

    local w = self.barLength + 6
    local h = (self.config.barWidth + 3) * count + 3

    if self.config.isVertical then
        w = h
        h = self.barLength + self.config.barWidth + 9
    end

    self:setWidth(w)
    self:setHeight(h)
end

function SSBar:optClick(name)
    self.config.shownConfig[name] = not self.config.shownConfig[name]
    self:prepareBarInfo()
    self:adjustWindowSize()
    saveConfig(self.config, self.playerNum)
end

function SSBar:optClickToggle(name)
    self.config.toggleStats[name] = not self.config.toggleStats[name]
    self:prepareBarInfo()
    self:adjustWindowSize()
    saveConfig(self.config, self.playerNum)
end

function SSBar:optClickVertical()
    self.config.isVertical = not self.config.isVertical
    self:adjustWindowSize()
    saveConfig(self.config, self.playerNum)
end

function SSBar:optClickRuler()
    self.config.isRulerOn = not self.config.isRulerOn
    saveConfig(self.config, self.playerNum)
end

function SSBar:optClickOpacity(f)
    self.config.opacity = f
    self.opacity = self.config.opacity
    self:prepareBarInfo()
    saveConfig(self.config, self.playerNum)
end
    

-- locked opt
--function SSBar:optLocked()
--    self.config.locked = not self.config.isRulerOn
--    saveConfig(self.config, self.playerNum)
--end

-- save fontSize config and update UI
function SSBar:optClickFont(size)
    self.config.fontSize = tostring(size) or "Small"
    self:prepareBarInfo()
    self:adjustWindowSize()
    saveConfig(self.config, self.playerNum)
end

function SSBar:drawTempBar(percent, i)
    -- horizontal bar, maybe there is an vertical one
    local gradientTex = getTexture("media/ui/BodyInsulation/heatbar_horz")
    local highlightTex = getTexture("media/ui/BodyInsulation/gradient_highlight")
    local radius = 20
    local darkAlpha = 1 - self.opacity

    if darkAlpha > 0.8 then
        darkAlpha = 0.77
    end
    darkAlpha = math.floor(darkAlpha * 10) / 10

    local barw = self.config.barWidth
    local barl = self.barLength
    local y = (barw + 3) * i - barw

    -- draw heatbar
    self:drawTextureScaled(gradientTex, 3, y, barl, barw, 1.0, 1.0, 1.0, 1.0)

    -- draw stat
    local valOffset = percent * barl
    valOffset = round(PZMath.clampFloat(valOffset, radius, barl - radius))
    if valOffset > radius then
        self:drawTextureScaled(nil, 3, y, valOffset - radius, barw, darkAlpha, 0.0, 0.0, 0.0)
    end
    if valOffset < barl - radius then
        self:drawTextureScaled(nil, 3 + valOffset + radius, y, barl - valOffset - radius, barw, darkAlpha, 0.0, 0.0, 0.0)
    end
    local highlightTexX = round(PZMath.clampFloat(valOffset - radius + 3, 3, 3 + barl - radius * 2))
    self:drawTextureScaled(highlightTex, highlightTexX, y, 2 * radius, barw, darkAlpha, 0.0, 0.0, 0.0)
end

function SSBar:getHoverBar(barWidth)
    local x = getMouseX()
    local y = getMouseY()
    local bar = {
        x = self.x,
        y = self.y,
        w = self.width,
        h = self.height,
    }
    if x <= bar.x or y <= bar.y or x >= bar.x + bar.w or y >= bar.y + bar.h then return nil end
    x = x - bar.x
    y = y - bar.y

    local xp = 0
    local index = 1
    while xp < bar.w do
        xp = xp + 3
        if x >= xp and x <= xp + barWidth then
            return index, x, y
        end
        index = index + 1
        xp = xp + barWidth
    end
    return nil
end

function SSBar:renderHBars()

    local barInfo = self.barInfo
    -- title, valueText, color, percent, _type, name, ruler

    for i, v in ipairs(barInfo) do
        local title = v[1]
        local valueText = v[2]
        local c = v[3]
        local percent = v[4]
        local _type = v[5]
        local ruler = v[7]

        local rectw = round(percent * self.barLength)
        local y = (self.config.barWidth + 3) * i - self.config.barWidth
        local textX = self.barLength - getStrWidth(self.font, valueText) - 6

        if _type == "temp" then
            self:drawTempBar(percent, i)
        else
            self:drawRectStatic(3, y, rectw, self.config.barWidth, self.opacity, c[1], c[2], c[3])
            if ruler and self.config.isRulerOn then
                if i ~= 1 then
                    self:drawRectStatic(3, y-2, self.barLength, 1, 0.66, 1.0, 1.0, 1.0)
                    self:drawRectStatic(3, y-1, self.barLength, 1, 0.66, 0.0, 0.0, 0.0)
                end
                for _, r in ipairs(ruler) do
                    self:drawRuler(3, y, r/100.0)
                end
            end
        end
        self:drawTextWithShadow(title, 6, y)
        self:drawTextWithShadow(valueText, textX, y)

    end
    
end

function SSBar:renderVBars()
    local barInfo = self.barInfo
    -- title, valueText, color, percent, _type, name

    for i, v in ipairs(barInfo) do
        local c = v[3]
        local percent = v[4]
        local _type = v[5]
        local name = v[6]
        local ruler = v[7]

        if _type == "temp" then percent = 1 end

        local x = (self.config.barWidth + 3) * i - self.config.barWidth
        local recth = round(percent * self.barLength)

        local tex = getTexture("media/ui/ss-" .. name .. ".png")
        if not tex then tex = getTexture("media/ui/ss-unknow.png") end
        self:drawTextureScaled(tex, x, self.barLength + 6, self.config.barWidth, self.config.barWidth, 1.0, 1.0, 1.0, 1.0)

        self:drawRectStatic(x, self.barLength - recth + 3, self.config.barWidth, recth, self.opacity, c[1], c[2], c[3])
        if ruler and self.config.isRulerOn then
            if i ~= 1 then
                self:drawRectStatic(x-1, 3, 1, self.barLength, 0.66, 0.0, 0.0, 0.0)
                self:drawRectStatic(x-2, 3, 1, self.barLength, 0.66, 1.0, 1.0, 1.0)
            end
            for _, r in ipairs(ruler) do
                self:drawRuler(x, 3, r/100.0)
            end
        end
    end

    -- show tooltip
    local index, tooltipx, tooltipy = self:getHoverBar(self.config.barWidth)
    if index then
        local bar = barInfo[index]

        local title = bar[1]
        local valueText = bar[2]

        local tooltip = title .. " : " .. valueText

        if tooltip ~= "" then
            self:drawTextWithShadow(tooltip, tooltipx - 5, tooltipy - self.config.barWidth - 5)
        end
    end

end

function SSBar:prerender()
    ISPanel.prerender(self)
    
    self.timer = self.timer + 1
    if self.timer == 60 then 
        self.timer = 0
        self:adjustWindowSize()
    end

    self:prepareBarInfo()
    -- update bars 60 fps
    if self.config.isVertical then
        self:renderVBars()
    else
        self:renderHBars()
    end

    --if currentTime - self.lastRenderTime >= 0.01666 or self.lastRenderTime == 0 then

    --- 
    --end

    
end

function SSBar:onMouseUp(x, y)
    if self.config.locked then return end
    ISPanel.onMouseUp(self, x, y)
    self.config.pos = { self.x, self.y }
    saveConfig(self.config, self.playerNum)
end

function SSBar:onRightMouseUp(x, y)
    if self.config.locked then return end
    ISPanel.onRightMouseUp(self, x, y)
    if not (self.player or {}).getPlayerNum then return end

    local contextMenu = ISContextMenu.get(self.player:getPlayerNum(), getMouseX() + 5, getMouseY() + 5)

    -- contextMenu's subMenu
    local configOpts = contextMenu:addOption("[ " .. getOptName("OPTION") .. " ]", self, nil)
    local configContectMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(configOpts, configContectMenu)

    -- Vertical and Ruler options
    local isv = configContectMenu:addOption(getOptName("VERTICAL"), self, self.optClickVertical)
    isv.checkMark = self.config.isVertical
    local ruler_on = configContectMenu:addOption(getOptName("RULER"), self, self.optClickRuler)
    ruler_on.checkMark = self.config.isRulerOn

    -- locked by option
    --local lock = configContectMenu:addOption(getOptName("LOCKED"), self, self.optLocked)
    --lock.checkMark = self.config.locked

    -- Status Toggle options
    for _, name in ipairs(stats._reverse._values) do
        local opt = configContectMenu:addOption(getOptName("TOG_" .. string.upper(name)), self, self.optClickToggle, name)
        opt.checkMark = self.config.toggleStats[name]
    end


    -- Add mod Status options
    local configModOpts = nil
    local configModContextMenu = nil
    for _, name in ipairs(stats._values) do
        if string.find(string.upper(name), "MOD") then
            if configModOpts == nil or configModContextMenu == nil then
                configModOpts = contextMenu:addOption("[ " .. getOptName("MOD_OPTION") .. " ]", self, nil)
                configModContextMenu = ISContextMenu:getNew(contextMenu)
                contextMenu:addSubMenu(configModOpts, configModContextMenu)
            end
            local om = configModContextMenu:addOption(getBarTitile(string.upper(name)), self, self.optClick, name)
            om.checkMark = self.config.shownConfig[name]
        end
    end

    -- Add Status options
    for _, name in ipairs(stats._values) do
        if not stats._reverse[name] and not string.find(string.upper(name), "MOD")then
            
            if self.config.toggleStats[getReverseStat(name)] then name = getReverseStat(name) end
            local o = contextMenu:addOption(getBarTitile(string.upper(name)), self, self.optClick, name)
            o.checkMark = self.config.shownConfig[name]
        end
    end


    -- Font size options
    local fontGroupOpts = configContectMenu:addOption(getOptName("FONT_SIZE"), self, nil)
    local fontOptsMenu = ISContextMenu:getNew(configContectMenu)
    configContectMenu:addSubMenu(fontGroupOpts, fontOptsMenu)

    -- Add font size options to the submenu using utils font
    for fontSize in pairs(utils.font) do
        local fontOpt = fontOptsMenu:addOption(getOptName("FONT_" .. string.upper(fontSize)), self, self.optClickFont, fontSize)
        fontOpt.checkMark = self.config.fontSize == fontSize
    end

    -- Opacity options
    local OpacityOpts = configContectMenu:addOption(getOptName("OPACITY"), self, nil)
    local OpacityOptsMenu = ISContextMenu:getNew(configContectMenu)
    configContectMenu:addSubMenu(OpacityOpts, OpacityOptsMenu)

    -- Add opacity options to the submenu
    local opacityLevels = {0.11, 0.22, 0.33, 0.44, 0.55, 0.66, 0.77, 0.88, 0.99}
    for _, opacity in ipairs(opacityLevels) do
        local opacityStr = string.format("%.2f", opacity) -- Format opacity as a string with 2 decimal places
        local o = OpacityOptsMenu:addOption(opacityStr, self, self.optClickOpacity, opacity)
        o.checkMark = self.config.opacity == opacity -- Set checkmark if this is the current opacity
    end

end

-- Mouse Wheel control barlength
function SSBar:onMouseWheel(del)

    if self.config.locked then return end

    self.config.barInc = self.config.barInc + del * 2

    -- max barInc
    if self.config.barInc > 600 then
        self.config.barInc = 600
    end

    self:adjustWindowSize()
    
end

function SSBar:handleKey(key)
    if isShiftKeyDown() then
        if key == self.config.toggleKey then
            self.shown = not self.shown
            if self.shown then
                self:setVisible(true)
                self:addToUIManager()
            else
                self:setVisible(false)
                self:removeFromUIManager()
            end
        elseif key == self.config.lockedKey then
            self.config.locked = not self.config.locked
            saveConfig(self.config, self.playerNum)
        end
    end
end


function SSBar:new(player, config)
    local o = ISPanel:new(config.pos[1], config.pos[2], 0, 0)

    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    o.backgroundColor = {r=0, g=0, b=0, a=0.3};

    o.player = player
    o.playerNum = player:getPlayerNum()
    o.config = config
    o.font = utils.font[config.fontSize] or utils.font.Small

    saveConfig(config, o.playerNum)

    o.barInfo     = {}

    o.titleLength = 100
    o.textLength  = 100
    o.barLength   = 210
    o.barInc =  config.barInc
    o.opacity = config.opacity
    o.timer = 0
    o.shown = true
    o:prepareBarInfo()

    o:adjustWindowSize()
    return o
end

return SSBar

