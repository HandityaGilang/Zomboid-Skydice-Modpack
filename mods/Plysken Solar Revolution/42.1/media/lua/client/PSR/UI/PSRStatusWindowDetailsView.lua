require "ISUI/ISPanelJoypad"
require "PSR/UI/PSRUI"
local PSR = require "PSR/Utilities"

local rgbGood, rgbBad = PSR.UI.rgbGood, PSR.UI.rgbBad

local PSRWindowDetails = ISPanelJoypad:derive("PSRWindowDetails")

function PSRWindowDetails:new(x, y, width, height)
    local o = ISPanelJoypad.new(self, x, y, self.measureWidth(), height)
    o:noBackground()
    o.currentFrame = 0
    o.fps = getCore():getOptionUIRenderFPS()
    return o
end

function PSRWindowDetails:createChildren()
    -- no child buttons needed
end

function PSRWindowDetails:setVisible(visible)
    ISPanelJoypad.setVisible(self, visible)
    if visible then
        self:setWidthAndParentWidth(self.width)
    end
end

function PSRWindowDetails:render()
    local win = self.parent.parent
    local pb  = win.luaPB
    if not (pb and pb:getIsoObject()) then return win:close() end

    local textX  = 10
    local textXr = self.width - 10
    local textY  = 10
    local borderX, borderY, borderW, borderH = 5, 0, self.width - 10, 0
    local fontHeightSm  = getTextManager():getFontHeight(UIFont.Small)
    local fontHeightMed = getTextManager():getFontHeight(UIFont.Medium)

    -- Cache ~1/sec le rafraîchissement + le BFS réseau (coûteux), comme le SummaryView frère :
    -- évite un BFS O(taille réseau) à CHAQUE frame tant que l'onglet Details reste ouvert.
    -- `refreshTick` : ce cache-ci s'installe AVANT que `area` soit connu (ligne ~54), donc le scan
    -- de generateurs ne peut pas etre calcule ici. On memorise juste « c'est la frame de
    -- rafraichissement » pour le recalculer plus bas au meme rythme. Voir le bloc `showBackupDetails`.
    self.refreshTick = (self.currentFrame == 0)
    if self.currentFrame == 0 then
        pb:updateFromIsoObject()
        self.cachedNetworkTotalPanels, self.cachedLinkedPanelInfo = PSR.WorldUtil.getLinkedBanksPanelInfo(pb)
        self.currentFrame = self.fps - 1
    else
        self.currentFrame = self.currentFrame - 1
    end
    local networkTotalPanels = self.cachedNetworkTotalPanels or 0
    local linkedPanelInfo = self.cachedLinkedPanelInfo or {}
    local hasLinkedBanks = #linkedPanelInfo > 0
    local player    = win.playerObj
    local canSee    = win.square:getCanSee(win.player)
    local area      = PSR.WorldUtil.getValidBackupArea(player:getPerkLevel(Perks.Electricity))
    local validArea = IsoUtils.DistanceToSquared(player:getX(), player:getY(), player:getZ(), pb.x+0.5, pb.y+0.5, pb.z) <= area.distance
                   and math.abs(player:getZ() - pb.z) <= area.levels

    if canSee and validArea or self.showDetails then
        local isoObj = pb:getIsoObject()
        if not isoObj then return end

        -- ── Battery bank stats ────────────────────────────────────────────
        self:drawText(getText("ContextMenu_PSR_BatteryBank"), textX, textY, 1, 1, 1, 1, UIFont.Medium)
        textY = textY + fontHeightMed + 5
        borderY, borderH = textY - 3, fontHeightSm * (hasLinkedBanks and 4 or 3) + 6
        self:drawRect(borderX, borderY, borderW, borderH, 0.7, 0.2, 0.2, 0.2)
        self:drawRectBorder(borderX, borderY, borderW, borderH, 1, 0.3, 0.3, 0.3)
        self:drawText(getText("IGUI_PSRWindow_Details_MaxCapacity"), textX, textY, 1, 1, 1, 1, UIFont.Small)
        self:drawTextRight(tostring(math.floor(pb.maxcapacity or 0) .. " Ah"), textXr, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + fontHeightSm
        self:drawText(getText("IGUI_PSRWindow_Details_ConnectedPanels"), textX, textY, 1, 1, 1, 1, UIFont.Small)
        self:drawTextRight(tostring(pb.npanels or 0), textXr, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + fontHeightSm
        if hasLinkedBanks then
            self:drawText(getText("IGUI_PSRWindow_Details_NetworkPanels"), textX, textY, 1, 1, 1, 1, UIFont.Small)
            self:drawTextRight(tostring(networkTotalPanels), textXr, textY, 1, 1, 1, 1, UIFont.Small)
            textY = textY + fontHeightSm
        end
        self:drawText(getText("IGUI_PSRWindow_Details_MaxPanelOutput"), textX, textY, 1, 1, 1, 1, UIFont.Small)
        self:drawTextRight(string.format("%.1f", pb.luaSystem:getMaxSolarOutput(hasLinkedBanks and networkTotalPanels or pb.npanels)) .. " Ah", textXr, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + fontHeightSm

        -- ── Electrical Devices — active drain ─────────────────────────────
        textY = textY + fontHeightSm
        self:drawText(getText("IGUI_PSRWindow_Details_ElectricalDevices"), textX, textY, 1, 1, 1, 1, UIFont.Medium)
        textY = textY + fontHeightMed + 5
        -- While the live city grid covers the load, the batteries don't actually discharge. Show the
        -- player WHY (kept under the drain figure, which we deliberately keep as a sizing aid: it tells
        -- them what the solar must cover once the grid shuts down). The line vanishes on shutdown.
        local coveredByMains = pb:coveredByMains()
        borderY, borderH = textY - 3, fontHeightSm * (coveredByMains and 2 or 1) + 6
        self:drawRect(borderX, borderY, borderW, borderH, 0.7, 0.2, 0.2, 0.2)
        self:drawRectBorder(borderX, borderY, borderW, borderH, 1, 0.3, 0.3, 0.3)
        self:drawText(getText("IGUI_PSRWindow_Details_BatteryDrain") .. ": ", textX, textY, 1, 1, 1, 1, UIFont.Small)
        local drain        = pb.drain or 0
        local drainRounded = math.floor(drain * 10 + 0.5) / 10
        self:drawTextRight(string.format("%g", drainRounded) .. " Ah", textXr, textY, 1, 1, 1, 1, UIFont.Small)
        textY = textY + fontHeightSm
        if coveredByMains then
            self:drawText(getText("IGUI_PSRWindow_Details_CoveredByMains"), textX, textY, rgbGood.r, rgbGood.g, rgbGood.b, 1, UIFont.Small)
            textY = textY + fontHeightSm
        end

        -- ── External sources ──────────────────────────────────────────────
        textY = textY + fontHeightSm
        self:drawText(getText("IGUI_PSRWindow_Details_ElectricityExternal"), textX, textY, 1, 1, 1, 1, UIFont.Medium)
        textY = textY + fontHeightMed + 5

        local rechargeText
        if hasLinkedBanks and networkTotalPanels > 0 then
            local networkSolar = pb.luaSystem:getModifiedSolarOutput(networkTotalPanels)
            local netRate = networkSolar - drain
            local mc, ch = pb.maxcapacity or 0, pb.charge or 0
            if netRate > 0 and mc > 0 and ch < mc then
                local h = math.floor((mc - ch) / netRate)
                local m = math.floor(((mc - ch) / netRate - h) * 60)
                rechargeText = string.format("%dh %02dm", h, m)
            end
        end

        local extLines = 2 + (hasLinkedBanks and 1 or 0) + (rechargeText and 1 or 0)
        borderY, borderH = textY - 3, fontHeightSm * extLines + 6
        self:drawRect(borderX, borderY, borderW, borderH, 0.7, 0.2, 0.2, 0.2)
        self:drawRectBorder(borderX, borderY, borderW, borderH, 1, 0.3, 0.3, 0.3)

        self:drawLineB(pb.conGenerator, "IGUI_PSRWindow_Details_conGenerator", textY)
        textY = textY + fontHeightSm
        self:drawLineB(pb.conGenerator and PSR.WorldUtil.findOnSquare(getSquare(pb.conGenerator.x, pb.conGenerator.y, pb.conGenerator.z), "solarmod_tileset_01_15"), "IGUI_PSRWindow_Details_Failsafe", textY)
        textY = textY + fontHeightSm
        if hasLinkedBanks then
            self:drawLineB(true, "IGUI_PSRWindow_Details_LinkedNetwork", textY)
            textY = textY + fontHeightSm
            if rechargeText then
                self:drawText(getText("IGUI_PSRWindow_Details_NetworkRecharge"), textX, textY, 1, 1, 1, 1, UIFont.Small)
                self:drawTextRight(rechargeText, textXr, textY, 1, 1, 1, 1, UIFont.Small)
                textY = textY + fontHeightSm
            end
        end

        if self.showBackupDetails then
            textY = textY + 5
            borderY, borderH = textY - 3, fontHeightSm * 3 + 6
            self:drawRect(borderX, borderY, borderW, borderH, 0.7, 0.2, 0.2, 0.2)
            self:drawRectBorder(borderX, borderY, borderW, borderH, 1, 0.3, 0.3, 0.3)
            self:drawLineB(validArea, "IGUI_PSRWindow_Details_ValidAreaPlayer", textY)
            textY = textY + fontHeightSm
            self:drawText(getText("IGUI_PSRWindow_Details_GenInRange"), textX, textY, 1, 1, 1, 1, UIFont.Small)
            -- 🔴 SCAN PAR FRAME (audit 2026-08-04). Cette ligne appelait `getGeneratorsInAreaInfo`
            -- a CHAQUE frame de rendu : elle etait EN DEHORS du cache 1/sec installe plus haut
            -- pour le BFS reseau — une ligne oubliee hors du cache, pas un oubli de cache.
            -- Cout = (2r+1)² × 3 cases PAR FRAME, avec `r` = niveau d'Electricite du joueur, ou
            -- l'option sandbox `BackupConnectRange` qui l'ecrase : 3 cases a Electricite 0, mais
            -- **1 323 a Electricite 10**, et 30 603 si un serveur regle la portee a 50. Et chaque
            -- case fait un `getGenerator()` + un parcours des objets speciaux, pas un simple test.
            -- Le declencheur est le bouton « Show Backup Area Details », que les joueurs laissent
            -- activé. => meme cadence que le BFS voisin : ~1/seconde.
            if self.refreshTick or self.cachedGenInRange == nil then
                self.cachedGenInRange = pb.luaSystem.getGeneratorsInAreaInfo(pb, area)
            end
            self:drawTextRight(tostring(self.cachedGenInRange), textXr, textY, 1, 1, 1, 1, UIFont.Small)
            textY = textY + fontHeightSm
            self:drawText(self:getDebugLineForPlayerSquareBackup(), textX, textY, 1, 1, 1, 1, UIFont.Small)
            textY = textY + fontHeightSm
        end
    else
        self:drawText(getText("IGUI_PSRWindow_Details_CantSee"), textX, textY, rgbBad.r, rgbBad.g, rgbBad.b, 1, UIFont.Medium)
        textY = textY + fontHeightMed
    end

    if hasLinkedBanks then
        textY = textY + fontHeightSm
        self:drawText(getText("IGUI_PSRWindow_Details_LinkedBanks"), textX, textY, 1, 1, 1, 1, UIFont.Medium)
        textY = textY + fontHeightMed + 5
        borderY = textY - 3
        borderH = fontHeightSm * #linkedPanelInfo + 6
        self:drawRect(borderX, borderY, borderW, borderH, 0.7, 0.2, 0.2, 0.2)
        self:drawRectBorder(borderX, borderY, borderW, borderH, 1, 0.3, 0.3, 0.3)
        for _, info in ipairs(linkedPanelInfo) do
            self:drawText(string.format("(%d, %d, %d) [%s]", info.x, info.y, info.z, info.dir), textX, textY, rgbGood.r, rgbGood.g, rgbGood.b, 1, UIFont.Small)
            self:drawTextRight(tostring(info.npanels) .. " " .. getText("IGUI_PSRWindow_SolarPanelUnit"), textXr, textY, rgbGood.r, rgbGood.g, rgbGood.b, 1, UIFont.Small)
            textY = textY + fontHeightSm
        end
    end

    self:setHeightAndParentHeight(textY + 10)
end

function PSRWindowDetails:drawLineB(isTrue, igui, y)
    if isTrue then
        self:drawText(getText(igui), 10, y, rgbGood.r, rgbGood.g, rgbGood.b, 1, UIFont.Small)
        self:drawTextRight(getText("UI_Yes"), self.width - 10, y, rgbGood.r, rgbGood.g, rgbGood.b, 1, UIFont.Small)
    else
        self:drawText(getText(igui), 10, y, rgbBad.r, rgbBad.g, rgbBad.b, 1, UIFont.Small)
        self:drawTextRight(getText("UI_No"), self.width - 10, y, rgbBad.r, rgbBad.g, rgbBad.b, 1, UIFont.Small)
    end
end

function PSRWindowDetails:getDebugLineForPlayerSquareBackup()
    local text
    local sq = self.parent.parent.playerObj:getSquare()
    if not sq then text = "IGUI_PSRWindow_Details_BackupDebugNoSquare"
    else
        local pb = self.parent.parent.luaPB
        local generator = sq:getGenerator()
        if not generator then text = "IGUI_PSRWindow_Details_BackupDebugNoGenerator"
        elseif not generator:isConnected() then text = "IGUI_PSRWindow_Details_BackupDebugNotConnected"
        elseif PSR.WorldUtil.findTypeOnSquare(sq, "PowerBank") then text = "IGUI_PSRWindow_Details_BackupDebugPowerbank"
        elseif not pb.conGenerator or pb.conGenerator.x ~= sq:getX() or pb.conGenerator.y ~= sq:getY() or pb.conGenerator.z ~= sq:getZ() then text = "IGUI_PSRWindow_Details_BackupDebugNotBackup"
        elseif not PSR.WorldUtil.findTypeOnSquare(sq, "Failsafe") then text = "IGUI_PSRWindow_Details_BackupDebugNoFailsafe"
        elseif generator:getFuel() <= 0 then text = "IGUI_PSRWindow_Details_BackupDebugNoFuel"
        elseif generator:getCondition() <= 20 then text = "IGUI_PSRWindow_Details_BackupDebugLowCondition"
        else
            return getText("IGUI_PSRWindow_Details_BackupDebugOK"), true
        end
    end
    return getText(text), false
end

local function maxWidthOfTexts(texts)
    local max = 0
    for _, text in ipairs(texts) do
        local width = getTextManager():MeasureStringX(UIFont.Small, getText(text))
        max = math.max(max, width)
    end
    return max
end

local function maxWidthOfVarTexts(varTexts)
    local max = 0
    for _, textVars in ipairs(varTexts) do
        local len = getTextManager():MeasureStringX(UIFont.Small, string.format(textVars[1], getText(textVars[2]), textVars[3] and getText(textVars[3])))
        max = math.max(max, len)
    end
    return max
end

function PSRWindowDetails.measureWidth()
    local varTexts = {
        {"%s 100.000 Ah",      "IGUI_PSRWindow_Details_MaxCapacity"},
        {"%s 999",             "IGUI_PSRWindow_Details_ConnectedPanels"},
        {"%s 999",             "IGUI_PSRWindow_Details_NetworkPanels"},
        {"%s 10.000.0 Ah",     "IGUI_PSRWindow_Details_MaxPanelOutput"},
        {"%s %s: 10.000.0 Ah", "IGUI_Total", "IGUI_PowerConsumption"},
    }
    local bTexts = {
        "IGUI_PSRWindow_Details_conGenerator",
        "IGUI_PSRWindow_Details_Failsafe",
        "IGUI_PSRWindow_Details_LinkedNetwork",
        "IGUI_PSRWindow_Details_GenInRange",
        "IGUI_PSRWindow_Details_ValidAreaPlayer",
    }
    local max = maxWidthOfVarTexts(varTexts)
    max = math.max(max, maxWidthOfVarTexts({{"%s 999h 00m", "IGUI_PSRWindow_Details_NetworkRecharge"}}))
    max = math.max(max, maxWidthOfVarTexts({{"999 %s", "IGUI_PSRWindow_SolarPanelUnit"}}))
    max = math.max(max, maxWidthOfTexts(bTexts) + maxWidthOfTexts({"UI_Yes", "UI_No"}))
    max = math.max(max + 20, getTextManager():MeasureStringX(UIFont.Medium, getText("IGUI_PSRWindow_Details_ElectricalDevices")) + 40)
    max = math.max(max, getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_PSRWindow_Details_CoveredByMains")) + 20)
    return max
end

PSR.StatusWindowDetailsView = PSRWindowDetails
