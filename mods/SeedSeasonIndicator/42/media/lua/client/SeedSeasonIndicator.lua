
local SeedSeasonIndicator = {}

SeedSeasonIndicator.texBest = getTexture("media/ui/SeedSeason_Best.png")
SeedSeasonIndicator.texInSeason = getTexture("media/ui/SeedSeason_InSeason.png")
SeedSeasonIndicator.texRisk = getTexture("media/ui/SeedSeason_Risk.png")
SeedSeasonIndicator.texOutOfSeason = getTexture("media/ui/SeedSeason_OutOfSeason.png")

SeedSeasonIndicator.seedLookup = nil
SeedSeasonIndicator.recipeLookup = nil

local options = PZAPI.ModOptions:create("SeedSeasonIndicator", "Seed Season Indicator")
SeedSeasonIndicator.optEnabled = options:addTickBox("enabled", getText("UI_SSI_OptEnabled"), true, getText("UI_SSI_OptEnabled_TT"))
SeedSeasonIndicator.optTooltip = options:addTickBox("tooltip", getText("UI_SSI_OptTooltip"), true, getText("UI_SSI_OptTooltip_TT"))

SeedSeasonIndicator.sssistActive = false

function SeedSeasonIndicator.buildSeedLookup()
    SeedSeasonIndicator.seedLookup = {}
    SeedSeasonIndicator.recipeLookup = {}
    if not farming_vegetableconf or not farming_vegetableconf.props then return end

    for typeOfSeed, props in pairs(farming_vegetableconf.props) do
        local seedTypes = props.seedTypes or { props.seedName }
        if seedTypes then
            for _, seedFullType in ipairs(seedTypes) do
                if seedFullType then
                    SeedSeasonIndicator.seedLookup[seedFullType] = typeOfSeed
                end
            end
        end
        if props.seasonRecipe then
            SeedSeasonIndicator.recipeLookup[props.seasonRecipe] = typeOfSeed
        end
    end
end

function SeedSeasonIndicator.getSeasonStatus(typeOfSeed)
    local props = farming_vegetableconf.props[typeOfSeed]
    if not props or not props.sowMonth then return nil end

    if not getSandboxOptions():getOptionByName("PlantGrowingSeasons"):getValue() then
        return nil
    end

    local currentMonth = getGameTime():getMonth() + 1

    local inSeason = false
    for _, m in ipairs(props.sowMonth) do
        if currentMonth == m then
            inSeason = true
            break
        end
    end

    if not inSeason then
        return "outofseason"
    end

    if props.bestMonth then
        for _, m in ipairs(props.bestMonth) do
            if currentMonth == m then
                return "best"
            end
        end
    end

    if props.riskMonth then
        for _, m in ipairs(props.riskMonth) do
            if currentMonth == m then
                return "risk"
            end
        end
    end

    return "inseason"
end

function SeedSeasonIndicator.playerHasLearnedRecipe(player, seasonRecipe)
    return player:isRecipeActuallyKnown(seasonRecipe)
end

function SeedSeasonIndicator.playerKnowsSeason(player, typeOfSeed)
    local props = farming_vegetableconf.props[typeOfSeed]
    if not props or not props.seasonRecipe then return false end

    return SeedSeasonIndicator.playerHasLearnedRecipe(player, props.seasonRecipe)
end

function SeedSeasonIndicator.resolveTypeOfSeed(item)
    if not SeedSeasonIndicator.seedLookup then return nil end

    local fullType = item:getFullType()
    local typeOfSeed = SeedSeasonIndicator.seedLookup[fullType]

    if not typeOfSeed and SeedSeasonIndicator.recipeLookup
        and instanceof(item, "Literature") and item:getType():contains("BagSeed") then
        local learnedRecipes = item:getLearnedRecipes()
        if learnedRecipes then
            for i = 0, learnedRecipes:size() - 1 do
                local recipe = learnedRecipes:get(i)
                typeOfSeed = SeedSeasonIndicator.recipeLookup[recipe]
                if typeOfSeed then
                    SeedSeasonIndicator.seedLookup[fullType] = typeOfSeed
                    break
                end
            end
        end
    end

    return typeOfSeed
end

function SeedSeasonIndicator.getIconForItem(player, item)
    local typeOfSeed = SeedSeasonIndicator.resolveTypeOfSeed(item)
    if not typeOfSeed then return nil end

    if item:getType():contains("_Empty") then return nil end

    if not SeedSeasonIndicator.playerKnowsSeason(player, typeOfSeed) then
        return nil
    end

    local status = SeedSeasonIndicator.getSeasonStatus(typeOfSeed)
    if status == "best" then
        return SeedSeasonIndicator.texBest
    elseif status == "inseason" then
        return SeedSeasonIndicator.texInSeason
    elseif status == "risk" then
        return SeedSeasonIndicator.texRisk
    elseif status == "outofseason" then
        return SeedSeasonIndicator.texOutOfSeason
    end

    return nil
end

local STATUS_SORT_SUFFIX = {
    best        = "_01_Best",
    inseason    = "_02_InSeason",
    risk        = "_03_Risk",
    outofseason = "_04_OutOfSeason",
}

local STATUS_LABEL_KEY = {
    best        = "IGUI_SSI_SeasonSuffix_Best",
    inseason    = "IGUI_SSI_SeasonSuffix_InSeason",
    risk        = "IGUI_SSI_SeasonSuffix_Risk",
    outofseason = "IGUI_SSI_SeasonSuffix_OutOfSeason",
}

function SeedSeasonIndicator.computeCategoryKey(player, item)
    local dc = item:getDisplayCategory()
    if not dc then return nil end
    local isGardening = (dc == "Gardening" or dc == "FarmSeed")

    local typeOfSeed = SeedSeasonIndicator.resolveTypeOfSeed(item)
    if not typeOfSeed then
        if isGardening then
            return "Gardening_06_Other", getText("IGUI_ItemCat_Gardening_06_Other")
        end
        return nil
    end

    local known = SeedSeasonIndicator.playerKnowsSeason(player, typeOfSeed)
    local status = known and SeedSeasonIndicator.getSeasonStatus(typeOfSeed) or nil

    if isGardening then
        local key
        if status then
            key = "Gardening" .. STATUS_SORT_SUFFIX[status]
        elseif known then
            key = "Gardening_06_Other"
        else
            key = "Gardening_05_Unknown"
        end
        return key, getText("IGUI_ItemCat_" .. key)
    end

    if not status then return nil end
    local label = getText("IGUI_ItemCat_" .. dc) .. " " .. getText(STATUS_LABEL_KEY[status])
    return dc .. STATUS_SORT_SUFFIX[status], label
end

local TOOLTIP_LABEL_COLOR = { 1.0, 1.0, 0.8, 1.0 }
local TOOLTIP_STATUS_COLOR = {
    best        = { 0.2, 0.9, 0.2, 1.0 },
    inseason    = { 0.6, 1.0, 0.6, 1.0 },
    risk        = { 1.0, 1.0, 0.2, 1.0 },
    outofseason = { 1.0, 0.3, 0.2, 1.0 },
}
local TOOLTIP_STATUS_KEY = {
    best        = "IGUI_SSI_TooltipStatus_Best",
    inseason    = "IGUI_SSI_TooltipStatus_InSeason",
    risk        = "IGUI_SSI_TooltipStatus_Risk",
    outofseason = "IGUI_SSI_TooltipStatus_OutOfSeason",
}

local function formatMonthList(months)
    local parts = {}
    for _, m in ipairs(months) do
        table.insert(parts, getText("Farming_Month_" .. m))
    end
    return table.concat(parts, ", ")
end

function SeedSeasonIndicator.appendSeasonTooltip(tooltip, item, player)
    if not player or not instanceof(item, "InventoryItem") then return end

    local typeOfSeed = SeedSeasonIndicator.resolveTypeOfSeed(item)
    if not typeOfSeed then return end
    if item:getType():contains("_Empty") then return end
    if not SeedSeasonIndicator.playerKnowsSeason(player, typeOfSeed) then return end
    local status = SeedSeasonIndicator.getSeasonStatus(typeOfSeed)
    if not status then return end

    local props = farming_vegetableconf.props[typeOfSeed]
    if not props or not props.sowMonth then return end

    local font = tooltip:getFont()
    local textManager = getTextManager()
    local layout = tooltip:beginLayout()
    local maxLabelW, maxValueW = 0, 0

    local function addRow(labelText, valueText, valueColor)
        local layoutItem = layout:addItem()
        local lc = TOOLTIP_LABEL_COLOR
        local vc = valueColor or TOOLTIP_LABEL_COLOR
        layoutItem:setLabel(labelText, lc[1], lc[2], lc[3], lc[4])
        layoutItem:setValue(valueText, vc[1], vc[2], vc[3], vc[4])
        maxLabelW = math.max(maxLabelW, textManager:MeasureStringX(font, labelText))
        maxValueW = math.max(maxValueW, textManager:MeasureStringX(font, valueText))
    end

    local currentMonth = getGameTime():getMonth() + 1
    addRow(getText("IGUI_SSI_TooltipThisMonth") .. " (" .. getText("Farming_Month_" .. currentMonth) .. "):",
        getText(TOOLTIP_STATUS_KEY[status]), TOOLTIP_STATUS_COLOR[status])
    addRow(getText("Farming_Tooltip_InSeason") .. ":",
        formatMonthList(props.sowMonth), TOOLTIP_STATUS_COLOR.inseason)
    addRow(getText("Farming_Tooltip_BestMonth2") .. ":",
        props.bestMonth and formatMonthList(props.bestMonth) or getText("Farming_Tooltip_None"),
        props.bestMonth and TOOLTIP_STATUS_COLOR.best or nil)
    addRow(getText("Farming_Tooltip_RiskMonth2") .. ":",
        props.riskMonth and formatMonthList(props.riskMonth) or getText("Farming_Tooltip_None"),
        props.riskMonth and TOOLTIP_STATUS_COLOR.risk or nil)

    local VALUE_GAP = 20
    local padLeft, padRight = 14, 12
    local padBottom = tooltip.padBottom or 5
    layout:setMinLabelWidth(maxLabelW + VALUE_GAP)

    local startY = tooltip:getHeight() - padBottom
    local endY = layout:render(padLeft, startY, tooltip)
    tooltip:endLayout(layout)
    tooltip:setHeight(endY + padBottom)

    local iconTex = (props.texture and getTexture(props.texture))
        or (props.icon and getTexture(props.icon)) or nil

    local drawW, drawH = 0, 0
    if iconTex then
        local texW, texH = iconTex:getWidth(), iconTex:getHeight()
        if texW > 0 and texH > 0 then
            drawH = endY - startY
            drawW = texW * drawH / texH
        else
            iconTex = nil
        end
    end

    local neededWidth = padLeft + maxLabelW + VALUE_GAP + maxValueW + padRight
    if iconTex then
        neededWidth = neededWidth + VALUE_GAP + math.ceil(drawW)
    end
    if tooltip:getWidth() < neededWidth then
        tooltip:setWidth(neededWidth)
    end

    if iconTex then
        local iconX = tooltip:getWidth() - padRight - drawW
        tooltip:DrawTextureScaled(iconTex, iconX, startY, drawW, drawH, 1)
    end
end

SeedSeasonIndicator.origToolTipRender = ISToolTipInv.render

function ISToolTipInv:render()
    local item = self.item
    local enabled = item
        and SeedSeasonIndicator.optTooltip:getValue()
        and not SeedSeasonIndicator.sssistActive
        and SeedSeasonIndicator.seedLookup

    if not enabled then
        return SeedSeasonIndicator.origToolTipRender(self)
    end

    local itemMetatable = getmetatable(item)
    local itemIndex = itemMetatable and itemMetatable.__index
    local origDoTooltip = itemIndex and itemIndex.DoTooltip
    if not origDoTooltip then
        return SeedSeasonIndicator.origToolTipRender(self)
    end

    local player = self.chr or getPlayer()
    itemIndex.DoTooltip = function(tooltipItem, tooltip)
        origDoTooltip(tooltipItem, tooltip)
        SeedSeasonIndicator.appendSeasonTooltip(tooltip, tooltipItem, player)
    end

    local ok, err = pcall(SeedSeasonIndicator.origToolTipRender, self)
    itemIndex.DoTooltip = origDoTooltip
    if not ok then error(err) end
end

SeedSeasonIndicator.origRenderDetails = ISInventoryPane.renderdetails

function ISInventoryPane:renderdetails(doDragged)
    local enabled = SeedSeasonIndicator.optEnabled:getValue() and SeedSeasonIndicator.seedLookup
    local origDrawText = nil

    if enabled then
        local expectedX = self.column3 + 8
        local pane = self
        local player = getSpecificPlayer(pane.player)
        origDrawText = self.drawText
        self.drawText = function(this, text, x, y, r, g, b, a, font)
            if player and x and this.column3 and x >= expectedX and x <= expectedX + 4 then
                local rowIdx = math.floor((y - this.headerHgt) / this.itemHgt) + 1
                local entry = this.items and this.items[rowIdx]
                local item = entry
                if entry and entry.items and type(entry.items) == "table" then
                    item = entry.items[1]
                end
                if item then
                    local _, newLabel = SeedSeasonIndicator.computeCategoryKey(player, item)
                    if newLabel and newLabel ~= "" then
                        text = newLabel
                    end
                end
            end
            return origDrawText(this, text, x, y, r, g, b, a, font)
        end
    end

    local ok, err = pcall(SeedSeasonIndicator.origRenderDetails, self, doDragged)
    if origDrawText then self.drawText = origDrawText end
    if not ok then error(err) end

    if not enabled then return end
    if not self.itemslist then return end

    local player = getSpecificPlayer(self.player)
    if not player then return end

    local MOUSEX = self:getMouseX()
    local MOUSEY = self:getMouseY()
    local YSCROLL = self:getYScroll()
    local HEIGHT = self:getHeight()

    local y = 0
    for _, v in ipairs(self.itemslist) do
        local count = 1
        for _, v2 in ipairs(v.items) do
            local item = v2
            local icon = SeedSeasonIndicator.getIconForItem(player, item)

            if icon then
                local doIt = true
                local xoff = 0
                local yoff = 0
                local isDragging = false

                if self.dragging ~= nil and self.selected[y + 1] ~= nil and self.dragStarted then
                    xoff = MOUSEX - self.draggingX
                    yoff = MOUSEY - self.draggingY
                    if not doDragged then
                        doIt = false
                    else
                        isDragging = true
                    end
                else
                    if doDragged then
                        doIt = false
                    end
                end

                local topOfItem = y * self.itemHgt + YSCROLL
                if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
                    doIt = false
                end

                if doIt then
                    local texWH = math.min(self.itemHgt - 2, 32)
                    local auxDXY = self.itemHgt - (self.itemHgt - texWH) / 2 - 13
                    local texOffsetX = self.column2 - texWH - (self.itemHgt - texWH) / 2 + xoff
                    local texOffsetY = (y * self.itemHgt) + (self.itemHgt - texWH) / 2 + self.headerHgt + yoff
                    if count == 1 then
                        self:drawTexture(icon, texOffsetX + auxDXY, texOffsetY - 1, 1, 1, 1, 1)
                    elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y + 1) - (count - 1)] == nil) then
                        self:drawTexture(icon, texOffsetX + auxDXY + 16, texOffsetY - 1, 0.3, 1, 1, 1)
                    end
                end
            end

            y = y + 1
            if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
                break
            end
            if count == 51 then
                break
            end
            count = count + 1
        end
    end
end

SeedSeasonIndicator.origRefreshContainer = ISInventoryPane.refreshContainer

function ISInventoryPane:refreshContainer()
    SeedSeasonIndicator.origRefreshContainer(self)

    if not SeedSeasonIndicator.optEnabled:getValue() then return end
    if not SeedSeasonIndicator.seedLookup then return end
    if not self.itemslist then return end

    local player = getSpecificPlayer(self.player)
    if not player then return end

    local changed = false
    for _, v in ipairs(self.itemslist) do
        local item = v.items[1]
        if item then
            local newCat = SeedSeasonIndicator.computeCategoryKey(player, item)
            if newCat and v.cat ~= newCat then
                v.cat = newCat
                changed = true
            end
        end
    end

    if changed and self.itemSortFunc then
        table.sort(self.itemslist, self.itemSortFunc)
    end
end

local function onGameStart()
    SeedSeasonIndicator.buildSeedLookup()

    local activatedMods = getActivatedMods()
    SeedSeasonIndicator.sssistActive =
        (activatedMods ~= nil and activatedMods:contains("ShowSowingSeasonInTooltip")) or false
end

Events.OnGameStart.Add(onGameStart)

return SeedSeasonIndicator
