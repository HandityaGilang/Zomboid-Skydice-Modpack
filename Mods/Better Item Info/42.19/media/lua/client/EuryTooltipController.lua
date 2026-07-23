require "ISUI/ISToolTipInv"

local EuryTooltipController = _G.EuryTooltipController or {}
_G.EuryTooltipController = EuryTooltipController
_G.EuryTooltipController_Active = true

EuryTooltipController.providers = EuryTooltipController.providers or {}
EuryTooltipController.backgroundAlpha = EuryTooltipController.backgroundAlpha or 0.9
EuryTooltipController.originalRender = EuryTooltipController.originalRender or ISToolTipInv.render

function EuryTooltipController:registerProvider(id, provider)
    if not id or not provider then return end
    provider.id = id
    self.providers[id] = provider
end

function EuryTooltipController:getOrderedProviders()
    local providers = {}
    for _, provider in pairs(self.providers) do
        table.insert(providers, provider)
    end
    table.sort(providers, function(a, b)
        local ap = a.priority or 100
        local bp = b.priority or 100
        if ap == bp then
            return tostring(a.id or "") < tostring(b.id or "")
        end
        return ap < bp
    end)
    return providers
end

function EuryTooltipController:getContext(panel)
    if not panel then return nil end
    local item = panel.item
    local tooltip = panel.tooltip
    if not item or not tooltip then return nil end

    return {
        panel = panel,
        item = item,
        tooltip = tooltip,
        rowCache = {},
    }
end

function EuryTooltipController:findOwnerProvider(ctx)
    if not ctx then return nil end
    for _, provider in ipairs(self:getOrderedProviders()) do
        local owns = false
        if provider.ownsTooltip then
            owns = provider:ownsTooltip(ctx)
        elseif provider.handles and provider.renderMain then
            owns = provider:handles(ctx)
        end

        if owns then
            return provider
        end
    end
    return nil
end

function EuryTooltipController:getDefaultOwnerProvider()
    if not self.defaultOwnerProvider then
        self.defaultOwnerProvider = {
            id = "Vanilla",
            priority = 1000,
            renderMain = function(_, ctx)
                ctx.item:DoTooltip(ctx.tooltip)
            end,
        }
    end
    return self.defaultOwnerProvider
end

local function getTooltipFont(tt)
    if tt and tt.getFont then
        return tt:getFont()
    end
    return UIFont.Medium
end

local FIRST_PROVIDER_GROUP_GAP = 4
local PROVIDER_GROUP_GAP = 8

local function getProviderGroupKey(provider)
    local id = provider and provider.id or ""
    id = tostring(id)
    if string.sub(id, 1, 14) == "BetterItemInfo" then
        return "BetterItemInfo"
    end
    return id
end

local function getProviderGroupGap(previousProvider, provider)
    if not previousProvider then
        return FIRST_PROVIDER_GROUP_GAP
    end
    if getProviderGroupKey(previousProvider) ~= getProviderGroupKey(provider) then
        return PROVIDER_GROUP_GAP
    end
    return 0
end

local function normalizeTooltipLineBreaks(text)
    text = tostring(text or "")
    text = string.gsub(text, "<[Bb][Rr]%s*/?>", "\n")
    return text
end

local function countTooltipTextLines(text)
    text = normalizeTooltipLineBreaks(text)
    if text == "" then return 0 end

    local lines = 1
    for _ in string.gmatch(text, "\n") do
        lines = lines + 1
    end
    return lines
end

local function measureTooltipTextWidth(tm, font, text)
    text = normalizeTooltipLineBreaks(text)
    if text == "" then return 0 end

    local width = 0
    for line in string.gmatch(text .. "\n", "(.-)\n") do
        local lineW = tm:MeasureStringX(font, line)
        if lineW > width then width = lineW end
    end
    return width
end

local function drawLineTooltipText(tt, lines, textX, startY)
    if not lines then return startY end

    local font = getTooltipFont(tt)
    local lineH = tt:getLineSpacing() or 18
    local y = startY
    for _, line in ipairs(lines) do
        local label = line.label or ""
        local value = line.value or ""
        local text = line.text or ""
        if label ~= "" or value ~= "" then
            local labelR = line.labelR or line.r or 1.0
            local labelG = line.labelG or line.g or 1.0
            local labelB = line.labelB or line.b or 0.8
            local valueR = line.valueR or 1.0
            local valueG = line.valueG or 1.0
            local valueB = line.valueB or 1.0

            tt:DrawText(font, label, textX, y, labelR, labelG, labelB, 1.0)
            if value ~= "" then
                local valueX = textX + getTextManager():MeasureStringX(font, label) + 6
                if type(line.valueParts) == "table" then
                    for _, part in ipairs(line.valueParts) do
                        local partText = tostring(part.text or "")
                        tt:DrawText(font, partText, valueX, y, part.r or valueR, part.g or valueG, part.b or valueB, 1.0)
                        valueX = valueX + getTextManager():MeasureStringX(font, partText)
                    end
                else
                    tt:DrawText(font, value, valueX, y, valueR, valueG, valueB, 1.0)
                end
            end
            y = y + math.max(countTooltipTextLines(label), countTooltipTextLines(value), 1) * lineH
        elseif text ~= "" then
            local r = line.r or 1.0
            local g = line.g or 0.6
            local b = line.b or 0.0
            tt:DrawText(font, text, textX, y, r, g, b, 1.0)
            y = y + countTooltipTextLines(text) * lineH
        end
    end

    return y
end

local function measureLines(tt, lines, padLeft, padRight)
    if not lines then return 0, 0 end

    local extraW, extraH = 0, 0
    local font = getTooltipFont(tt)
    local tm = getTextManager()
    local lineH = tt:getLineSpacing() or 18

    for _, line in ipairs(lines) do
        local label = line.label or ""
        local value = line.value or ""
        local text = line.text or ""
        if label ~= "" or value ~= "" then
            text = label
            if value ~= "" then
                text = text .. " " .. value
            end
        end
        if text ~= "" then
            local w = measureTooltipTextWidth(tm, font, text) + padLeft + padRight
            if w > extraW then extraW = w end
            extraH = extraH + countTooltipTextLines(text) * lineH
        end
    end

    return extraW, extraH
end

function EuryTooltipController:getProviderRows(provider, ctx)
    if not provider then return nil end
    local id = provider.id or tostring(provider)

    if ctx and ctx.rowCache and ctx.rowCache[id] ~= nil then
        return ctx.rowCache[id] or nil
    end

    local rows = nil
    if provider.getRows then
        rows = provider:getRows(ctx)
    elseif provider.getLines then
        rows = provider:getLines(ctx)
    end

    if type(rows) == "table" and #rows > 0 then
        if ctx and ctx.rowCache then ctx.rowCache[id] = rows end
        return rows
    end
    if ctx and ctx.rowCache then ctx.rowCache[id] = false end
    return nil
end

function EuryTooltipController:collectRowGroups(ctx)
    local groups = {}
    for _, provider in ipairs(self:getOrderedProviders()) do
        local rows = self:getProviderRows(provider, ctx)
        if rows then
            table.insert(groups, {
                provider = provider,
                rows = rows,
            })
        end
    end
    return groups
end

function EuryTooltipController:renderControlled(panel, provider, ctx)
    -- vanilla visibility guard
    if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
        return
    end

    local item = ctx.item
    local tt = ctx.tooltip

    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not panel.followMouse then
        mx = panel:getX()
        my = panel:getY()
        if panel.anchorBottomLeft then
            mx = panel.anchorBottomLeft.x
            my = panel.anchorBottomLeft.y
        end
    end

    local PADX = (provider.getPadX and provider:getPadX(ctx)) or 0
    ctx.ownerProvider = provider

    local PADY = (provider.getPadY and provider:getPadY(ctx)) or 10
    local ATTACHED_GAP = provider.attachedGap or 8

    tt:setX(mx + PADX)
    tt:setY(my)

    -- B42.13 --
    if panel.contextMenu and panel.contextMenu.joyfocus then
        local playerNum = panel.contextMenu.player
        tt:setX(getPlayerScreenLeft(playerNum) + 60)
        tt:setY(getPlayerScreenTop(playerNum) + 60)
    elseif panel.contextMenu and panel.contextMenu.currentOptionRect then
        if panel.contextMenu.currentOptionRect.height > 32 then
            panel:setY(my + panel.contextMenu.currentOptionRect.height)
        end
        panel:adjustPositionToAvoidOverlap(panel.contextMenu.currentOptionRect)
    end
    -- END B42.13 --

    tt:setWidth(50)

    -------------------------------------------------
    -- MEASURE PASS: base content
    -------------------------------------------------
    tt:setMeasureOnly(true)
    provider:renderMain(ctx)
    tt:setMeasureOnly(false)

    local baseW = tt:getWidth()
    local baseH = tt:getHeight()

    -------------------------------------------------
    -- MEASURE PASS: provider rows (if any)
    -------------------------------------------------
    local rowGroups = self:collectRowGroups(ctx)
    local extraW, extraH = 0, 0
    if #rowGroups > 0 then
        for index, group in ipairs(rowGroups) do
            local rowProvider = group.provider
            local padLeft = (rowProvider.getLinePadLeft and rowProvider:getLinePadLeft(ctx)) or 10
            local padRight = (rowProvider.getLinePadRight and rowProvider:getLinePadRight(ctx)) or 10
            local groupW, groupH = measureLines(tt, group.rows, padLeft, padRight)
            if groupW > extraW then extraW = groupW end
            local previous = rowGroups[index - 1]
            extraH = extraH + getProviderGroupGap(previous and previous.provider or nil, rowProvider)
            extraH = extraH + groupH
        end
        extraH = extraH + math.max(PADY - FIRST_PROVIDER_GROUP_GAP, 0)
    end

    local mainW = math.max(baseW, extraW)
    local mainH = baseH + extraH

    -------------------------------------------------
    -- MEASURE PASS: attached side panel (if any)
    -------------------------------------------------
    local sidePanel = provider.getSidePanel and provider:getSidePanel(ctx) or nil
    local sideW, sideH = 0, 0
    if sidePanel and sidePanel.render then
        tt:setWidth(50)
        tt:setMeasureOnly(true)
        sidePanel.render(tt)
        tt:setMeasureOnly(false)
        sideW = tt:getWidth()
        sideH = tt:getHeight()
    end

    local tw = mainW
    local th = mainH
    if sideW > 0 then
        tw = mainW + ATTACHED_GAP + sideW + PADX
        th = math.max(mainH, sideH)
    end

    -------------------------------------------------
    -- Clamp like vanilla
    -------------------------------------------------
    local core = getCore()
    local maxX = core:getScreenWidth()
    local maxY = core:getScreenHeight()

    tt:setX(math.max(0, math.min(mx + PADX, maxX - tw - 1)))
    if not panel.followMouse and panel.anchorBottomLeft then
        tt:setY(math.max(0, math.min(my - th, maxY - th - 1)))
    else
        tt:setY(math.max(0, math.min(my, maxY - th - 1)))
    end

    panel:setX(tt:getX() - PADX)
    panel:setY(tt:getY())
    panel:setWidth(tw + PADX)
    panel:setHeight(th)

    if panel.followMouse and (panel.contextMenu == nil) then
        panel:adjustPositionToAvoidOverlap({
            x = mx - 24 * 2,
            y = my - 24 * 2,
            width = 24 * 2,
            height = 24 * 2
        })
    end

    -------------------------------------------------
    -- Background + border (vanilla look)
    -------------------------------------------------
    panel:drawRect(0, 0, mainW + PADX, mainH, self.backgroundAlpha,
        panel.backgroundColor.r, panel.backgroundColor.g, panel.backgroundColor.b)
    panel:drawRectBorder(0, 0, mainW + PADX, mainH,
        panel.borderColor.a, panel.borderColor.r, panel.borderColor.g, panel.borderColor.b)

    local sidePanelX = mainW + PADX + ATTACHED_GAP
    if sideW > 0 then
        panel:drawRect(sidePanelX, 0, sideW + PADX, sideH, self.backgroundAlpha,
            panel.backgroundColor.r, panel.backgroundColor.g, panel.backgroundColor.b)
        panel:drawRectBorder(sidePanelX, 0, sideW + PADX, sideH,
            panel.borderColor.a, panel.borderColor.r, panel.borderColor.g, panel.borderColor.b)
    end

    -------------------------------------------------
    -- DRAW PASS: base content
    -------------------------------------------------
    tt:setX(panel:getX() + PADX)
    tt:setY(panel:getY())
    tt:setWidth(50)
    provider:renderMain(ctx)

    -------------------------------------------------
    -- DRAW PASS: provider rows
    -------------------------------------------------
    if #rowGroups > 0 then
        local y = baseH
        for index, group in ipairs(rowGroups) do
            local rowProvider = group.provider
            local textX = (rowProvider.getTextX and rowProvider:getTextX(ctx)) or 12
            local previous = rowGroups[index - 1]
            y = y + getProviderGroupGap(previous and previous.provider or nil, rowProvider)
            y = drawLineTooltipText(tt, group.rows, textX, y)
        end
    end

    -------------------------------------------------
    -- DRAW PASS: attached side panel
    -------------------------------------------------
    if sideW > 0 and sidePanel and sidePanel.render then
        tt:setX(panel:getX() + sidePanelX + PADX)
        tt:setY(panel:getY())
        tt:setWidth(50)
        sidePanel.render(tt)
    end
end

function EuryTooltipController:render(panel)
    local ctx = self:getContext(panel)
    if not ctx then
        if self.originalRender then return self.originalRender(panel) end
        return
    end

    local provider = self:findOwnerProvider(ctx)
    if not provider then
        local rowGroups = self:collectRowGroups(ctx)
        if #rowGroups == 0 then
            if self.originalRender then return self.originalRender(panel) end
            return
        end
        provider = self:getDefaultOwnerProvider()
    end

    return self:renderControlled(panel, provider, ctx)
end

function EuryTooltipController:install()
    if self.installed then return end
    self.installed = true

    function ISToolTipInv:render()
        return EuryTooltipController:render(self)
    end

    local old_new = ISToolTipInv.new
    function ISToolTipInv:new(item)
        local o = old_new(self, item)
        o.backgroundColor.a = EuryTooltipController.backgroundAlpha
        return o
    end
end

return EuryTooltipController
