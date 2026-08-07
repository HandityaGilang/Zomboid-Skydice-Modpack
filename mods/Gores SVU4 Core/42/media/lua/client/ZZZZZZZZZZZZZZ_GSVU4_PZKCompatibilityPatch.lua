--========================================================
-- Gore's SVU4 Core - PZK / ATA2 Compatibility UI Patch
--========================================================
-- Notes:
--   * This is intentionally NOT a broad PZK block.
--   * It only blocks SVU4 locations/upgrades that overlap actual ATA2/SVU3 parts.
--   * UI block panels are drawn only for the currently active tab and only for
--     the currently selected blocked item/upgrade.
--========================================================

require "GoresSVU4Core/GSVU4_PZKCompatibility"

local Compat = GSVU4_PZKCompat or {}

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function getMode(window)
    if not window then return "Armor" end
    return window.gsvu4Mode or window.gsvu4ActiveTab or "Armor"
end

local function isArmorMode(window)
    return getMode(window) == "Armor"
end

local function isUpgradesMode(window)
    return getMode(window) == "Upgrades"
end

local function getExistingArmor(window, partId)
    if not window or not window.vehicle or not partId then return nil end
    local vdata = window.vehicle:getModData()
    return vdata and vdata.gArmor and vdata.gArmor[partId] or nil
end

local function isArmorBlocked(window, partId)
    if not window or not window.vehicle or not partId or not Compat.isArmorBlocked then return false, nil end
    return Compat.isArmorBlocked(window.vehicle, partId)
end

local function armorBlockedReason(window, partId, action)
    if not window or not window.vehicle or not partId or not Compat.getArmorBlockedReason then return nil end
    return Compat.getArmorBlockedReason(window.vehicle, partId, action)
end

local function isUpgradeBlocked(window, upgradeId)
    if not window or not window.vehicle or not upgradeId or not Compat.isUpgradeBlocked then return false, nil end
    return Compat.isUpgradeBlocked(window.vehicle, upgradeId)
end

local function upgradeBlockedReason(window, upgradeId, action)
    if not window or not window.vehicle or not upgradeId or not Compat.getUpgradeBlockedReason then return nil end
    return Compat.getUpgradeBlockedReason(window.vehicle, upgradeId, action)
end

local function getSelectedUpgrade(window)
    if not window then return nil end
    if window.gsvu4SelectedUpgrade and window.gsvu4SelectedUpgrade.upgradeId then
        return window.gsvu4SelectedUpgrade
    end

    local list = window.gsvu4UpgradeList
    if list and list.selected and list.selected > 0 and list.items and list.items[list.selected] then
        local row = list.items[list.selected]
        if row and row.item and row.item.upgradeId then return row.item end
    end

    return nil
end

local function say(character, text)
    text = text or "SVU4 compatibility block."
    if character and character.Say then character:Say(text) end
    if HaloTextHelper and getPlayer then
        HaloTextHelper.addText(getPlayer(), text, HaloTextHelper.getColorRed())
    end
end

local function pruneSelections(window)
    if not window or not window.vehicle then return end
    local function pruneBooleanMap(map)
        if not map then return end
        for partId, selected in pairs(map) do
            if selected and isArmorBlocked(window, partId) then map[partId] = nil end
        end
    end
    local function pruneGradeMap(map)
        if not map then return end
        for partId, grade in pairs(map) do
            if grade and isArmorBlocked(window, partId) then map[partId] = nil end
        end
    end
    pruneGradeMap(window.installSelectedParts)
    pruneBooleanMap(window.repairSelectedParts)
    pruneBooleanMap(window.uninstallSelectedParts)
end

local function wrapMethod(classTable, name, wrapper)
    if not classTable or not classTable[name] or classTable["gsvu4PZKCompatWrapped_" .. name] then return end
    local old = classTable[name]
    classTable[name] = function(self, ...)
        return wrapper(old, self, ...)
    end
    classTable["gsvu4PZKCompatWrapped_" .. name] = true
end

local function measureText(font, text)
    if getTextManager and UIFont then
        local measured = safeCall(function()
            return getTextManager():MeasureStringX(font or UIFont.Small, tostring(text or ""))
        end, nil)
        if measured then return tonumber(measured) or 0 end
    end
    return string.len(tostring(text or "")) * 7
end

local function fontHeight(font)
    if getTextManager and UIFont then
        local measured = safeCall(function()
            return getTextManager():getFontHeight(font or UIFont.Small)
        end, nil)
        if measured then return tonumber(measured) or 14 end
    end
    return 14
end

local function wrapTextByWidth(text, font, maxWidth)
    local out = {}
    local line = ""
    maxWidth = math.max(40, tonumber(maxWidth) or 260)

    for word in tostring(text or ""):gmatch("%S+") do
        local candidate = (line == "" and word) or (line .. " " .. word)
        if measureText(font, candidate) > maxWidth and line ~= "" then
            table.insert(out, line)
            line = word
        else
            line = candidate
        end
    end

    if line ~= "" then table.insert(out, line) end
    return out
end

local function drawBlockBox(window, box, title, reason)
    if not window or not box or not window.drawRect or not reason then return end

    local font = UIFont.Small
    local lineH = math.max(14, fontHeight(font) + 2)
    local x = box:getX() + 10
    local w = box:getWidth() - 20
    local maxTextW = math.max(80, w - 20)
    local lines = wrapTextByWidth(reason, font, maxTextW)

    -- Keep the panel inside the existing box and avoid huge overlays on smaller UI scales.
    local maxLines = math.max(2, math.floor((box:getHeight() - 48) / lineH))
    if #lines > maxLines then
        local trimmed = {}
        for i = 1, maxLines do trimmed[i] = lines[i] end
        trimmed[maxLines] = tostring(trimmed[maxLines] or ""):gsub("%.?$", "") .. "..."
        lines = trimmed
    end

    local h = 34 + (#lines * lineH)
    local y = box:getY() + box:getHeight() - h - 12
    if y < box:getY() + 8 then y = box:getY() + 8 end

    window:drawRect(x, y, w, h, 0.88, 0.12, 0.12, 0.12)
    window:drawRectBorder(x, y, w, h, 0.95, 0.82, 0.52, 0.18)
    window:drawText(title or "PZK / SVU3 COMPATIBILITY BLOCK", x + 10, y + 8, 0.95, 0.82, 0.52, 1, font)

    local lineY = y + 24
    for _, line in ipairs(lines) do
        window:drawText(line, x + 10, lineY, 0.92, 0.92, 0.92, 1, font)
        lineY = lineY + lineH
    end
end

local function setUpgradeButtonsBlocked(window, reason)
    if not window then return end
    if window.gsvu4InstallUpgradeButton then
        window.gsvu4InstallUpgradeButton:setEnable(false)
        window.gsvu4InstallUpgradeButton:setTitle("PZK/SVU3 Protected")
        window.gsvu4InstallUpgradeButton.tooltip = reason
    end
    if window.gsvu4RepairUpgradeButton then
        window.gsvu4RepairUpgradeButton:setEnable(false)
        window.gsvu4RepairUpgradeButton.tooltip = reason
    end
    if window.gsvu4RemoveUpgradeButton then
        window.gsvu4RemoveUpgradeButton:setEnable(false)
        window.gsvu4RemoveUpgradeButton.tooltip = reason
    end
end

local function installArmorPatch()
    if not VehicleArmorWindow then return end

    wrapMethod(VehicleArmorWindow, "getPrettyLabel", function(old, self, id, part)
        local label = old and old(self, id, part) or tostring(id or "")
        local blocked = isArmorBlocked(self, id)
        if blocked and tostring(label):find("PZK", 1, true) == nil then
            return tostring(label) .. " [PZK/SVU3 Protected]"
        end
        return label
    end)

    wrapMethod(VehicleArmorWindow, "getRecipeReport", function(old, self, ...)
        local report = old and old(self, ...) or {}
        local partId = self and self.selectedPart and self.selectedPart.partId
        if partId then
            local existing = getExistingArmor(self, partId)
            local action = existing and "repair" or "install"
            local blocked, info = isArmorBlocked(self, partId)
            if blocked then
                report.pzkBlocked = true
                report.pzkBlockInfo = info
                report.pzkBlockReason = armorBlockedReason(self, partId, action)
                report.canCraft = false
                report.canRepair = false
            end
        end
        return report
    end)

    wrapMethod(VehicleArmorWindow, "isInstallSelectionCandidate", function(old, self, partId, grade)
        if isArmorBlocked(self, partId) then return false end
        return old and old(self, partId, grade) or false
    end)

    wrapMethod(VehicleArmorWindow, "isRepairSelectionCandidate", function(old, self, partId)
        if isArmorBlocked(self, partId) then return false end
        return old and old(self, partId) or false
    end)

    wrapMethod(VehicleArmorWindow, "isRemoveSelectionCandidate", function(old, self, partId)
        if isArmorBlocked(self, partId) then return false end
        return old and old(self, partId) or false
    end)

    wrapMethod(VehicleArmorWindow, "canRepairArmorPart", function(old, self, partId, armor, report)
        if isArmorBlocked(self, partId) then return false end
        return old and old(self, partId, armor, report) or false
    end)

    local function filterQueue(self, queue)
        local filtered = {}
        for _, entry in ipairs(queue or {}) do
            local partId = type(entry) == "table" and entry.partId or entry
            if partId and not isArmorBlocked(self, partId) then
                table.insert(filtered, entry)
            end
        end
        return filtered
    end

    wrapMethod(VehicleArmorWindow, "getInstallAllQueue", function(old, self, report)
        pruneSelections(self)
        return filterQueue(self, old and old(self, report) or {})
    end)

    wrapMethod(VehicleArmorWindow, "getSelectedInstallQueue", function(old, self, report)
        pruneSelections(self)
        return filterQueue(self, old and old(self, report) or {})
    end)

    wrapMethod(VehicleArmorWindow, "getRepairAllQueue", function(old, self, report)
        pruneSelections(self)
        return filterQueue(self, old and old(self, report) or {})
    end)

    wrapMethod(VehicleArmorWindow, "getUninstallAllQueue", function(old, self, report)
        pruneSelections(self)
        return filterQueue(self, old and old(self, report) or {})
    end)

    wrapMethod(VehicleArmorWindow, "toggleInstallSelection", function(old, self, rowItem)
        local partId = rowItem and rowItem.partId
        if partId and isArmorBlocked(self, partId) then
            local mode = self.gsvu4BatchMode == "repair" and "repair" or (self.gsvu4BatchMode == "uninstall" and "uninstall" or "install")
            say(self.character, armorBlockedReason(self, partId, mode) or "Blocked by PZK/SVU3 compatibility.")
            return
        end
        return old and old(self, rowItem)
    end)

    wrapMethod(VehicleArmorWindow, "onActionButtonClick", function(old, self, ...)
        local partId = self and self.selectedPart and self.selectedPart.partId
        if partId and isArmorBlocked(self, partId) then
            local existing = getExistingArmor(self, partId)
            say(self.character, armorBlockedReason(self, partId, existing and "uninstall" or "install") or "Blocked by PZK/SVU3 compatibility.")
            return nil
        end
        return old(self, ...)
    end)

    wrapMethod(VehicleArmorWindow, "onRepairButtonClick", function(old, self, ...)
        local partId = self and self.selectedPart and self.selectedPart.partId
        if partId and isArmorBlocked(self, partId) then
            say(self.character, armorBlockedReason(self, partId, "repair") or "Blocked by PZK/SVU3 compatibility.")
            return nil
        end
        return old(self, ...)
    end)

    wrapMethod(VehicleArmorWindow, "prerender", function(old, self, ...)
        if old then old(self, ...) end

        -- Do not let the old selected armour row draw a PZK block box while the
        -- Upgrades tab is active.
        if not isArmorMode(self) then return end

        local partId = self and self.selectedPart and self.selectedPart.partId
        if not partId then return end
        local blocked, info = isArmorBlocked(self, partId)
        if not blocked then return end

        if self.actionButton then
            self.actionButton:setEnable(false)
            self.actionButton:setTitle("PZK/SVU3 Protected")
        end
        if self.repairButton then
            self.repairButton:setEnable(false)
            self.repairButton:setTitle("PZK/SVU3 Protected")
        end

        local box = self.detailBox
        local reason = armorBlockedReason(self, partId, "install") or (info and info.reason) or "Blocked by PZK/SVU3 compatibility."
        drawBlockBox(self, box, "PZK / SVU3 COMPATIBILITY BLOCK", reason)
    end)
end

local function installTimedActionPatch()
    if ISWeldVehicleArmor and not ISWeldVehicleArmor.GSVU4_PZKCompatWrapped then
        local oldValid = ISWeldVehicleArmor.isValid
        function ISWeldVehicleArmor:isValid()
            if self.vehicle and self.partId and Compat.isArmorBlocked then
                local blocked = Compat.isArmorBlocked(self.vehicle, self.partId)
                if blocked then return false end
            end
            return oldValid and oldValid(self) or false
        end
        ISWeldVehicleArmor.GSVU4_PZKCompatWrapped = true
    end

    if ISRepairVehicleArmor and not ISRepairVehicleArmor.GSVU4_PZKCompatWrapped then
        local oldValid = ISRepairVehicleArmor.isValid
        function ISRepairVehicleArmor:isValid()
            if self.vehicle and self.partId and Compat.isArmorBlocked then
                local blocked = Compat.isArmorBlocked(self.vehicle, self.partId)
                if blocked then return false end
            end
            return oldValid and oldValid(self) or false
        end
        ISRepairVehicleArmor.GSVU4_PZKCompatWrapped = true
    end

    if ISUninstallVehicleArmor and not ISUninstallVehicleArmor.GSVU4_PZKCompatWrapped then
        local oldValid = ISUninstallVehicleArmor.isValid
        function ISUninstallVehicleArmor:isValid()
            if self.vehicle and self.partId and Compat.isArmorBlocked then
                local blocked = Compat.isArmorBlocked(self.vehicle, self.partId)
                if blocked then return false end
            end
            return oldValid and oldValid(self) or false
        end
        ISUninstallVehicleArmor.GSVU4_PZKCompatWrapped = true
    end

    if ISInstallVehicleUpgrade and not ISInstallVehicleUpgrade.GSVU4_PZKCompatWrapped then
        local oldValid = ISInstallVehicleUpgrade.isValid
        function ISInstallVehicleUpgrade:isValid()
            if self.vehicle and self.upgradeId and Compat.isUpgradeBlocked then
                local blocked = Compat.isUpgradeBlocked(self.vehicle, self.upgradeId)
                if blocked then return false end
            end
            return oldValid and oldValid(self) or false
        end
        ISInstallVehicleUpgrade.GSVU4_PZKCompatWrapped = true
    end
end

local function installUpgradePatch()
    if not VehicleArmorWindow then return end

    if VehicleArmorWindow.prerender and not VehicleArmorWindow.gsvu4PZKCompatUpgradePrerenderWrapped then
        local oldPrerender = VehicleArmorWindow.prerender
        function VehicleArmorWindow:prerender(...)
            if oldPrerender then oldPrerender(self, ...) end
            if not isUpgradesMode(self) then return end

            local selected = getSelectedUpgrade(self)
            local upgradeId = selected and selected.upgradeId
            if not upgradeId then return end

            local blocked, info = isUpgradeBlocked(self, upgradeId)
            if not blocked then return end

            local reason = upgradeBlockedReason(self, upgradeId, "install") or (info and info.reason) or "Blocked by PZK/SVU3 compatibility."
            setUpgradeButtonsBlocked(self, reason)

            -- Draw this only on the Upgrades tab, and only for the selected blocked upgrade.
            -- Reuse the upgrades help panel area because armour detailBox is hidden in this mode.
            local listY = 154
            local listH = self.height - listY - 88
            local detailX, detailW = 300, 330
            local helpX = detailX + detailW + 18
            local helpW = self.width - helpX - 10
            local pseudoBox = {
                getX = function() return helpX end,
                getY = function() return listY end,
                getWidth = function() return helpW end,
                getHeight = function() return listH end,
            }
            drawBlockBox(self, pseudoBox, "PZK / SVU3 UPGRADE BLOCK", reason)
        end
        VehicleArmorWindow.gsvu4PZKCompatUpgradePrerenderWrapped = true
    end

    for _, name in ipairs({"onGSVU4InstallUpgradeClick", "onGSVU4RepairUpgradeClick", "onGSVU4RemoveUpgradeClick", "onInstallUpgradeClick", "onRepairUpgradeClick", "onRemoveUpgradeClick", "gsvu4OnInstallUpgrade", "gsvu4OnRepairUpgrade", "gsvu4OnRemoveUpgrade"}) do
        wrapMethod(VehicleArmorWindow, name, function(old, self, ...)
            local selected = getSelectedUpgrade(self)
            local upgradeId = selected and selected.upgradeId
            if upgradeId and isUpgradeBlocked(self, upgradeId) then
                say(self.character, upgradeBlockedReason(self, upgradeId, "install") or "Blocked by PZK/SVU3 compatibility.")
                return nil
            end
            return old(self, ...)
        end)
    end
end

local function installPatch()
    installArmorPatch()
    installTimedActionPatch()
    installUpgradePatch()
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(installPatch) end
if Events and Events.OnLoad then Events.OnLoad.Add(installPatch) end
if Events and Events.OnCreatePlayer then Events.OnCreatePlayer.Add(function() installPatch() end) end
