require "GoresSVU4Core/GSVU4_KI5Compatibility"

if not VehicleArmorWindow then return end

local Compat = GSVU4_KI5Compat or {}

local function getBlockInfo(window, partId)
    if not window or not window.vehicle or not partId or not Compat.getBlockInfo then return nil end
    return Compat.getBlockInfo(window.vehicle, partId)
end

local function isBlocked(window, partId)
    if not window or not window.vehicle or not partId or not Compat.isBlocked then return false, nil end
    return Compat.isBlocked(window.vehicle, partId)
end

local function blockedReason(window, partId, action)
    if not window or not window.vehicle or not partId or not Compat.getBlockedReason then return nil end
    return Compat.getBlockedReason(window.vehicle, partId, action)
end

local function getExistingArmor(window, partId)
    if not window or not window.vehicle or not partId then return nil end
    local vdata = window.vehicle:getModData()
    return vdata and vdata.gArmor and vdata.gArmor[partId] or nil
end

local function pruneSelections(window)
    if not window or not window.vehicle then return end

    local function pruneBooleanMap(map)
        if not map then return end
        for partId, selected in pairs(map) do
            if selected and isBlocked(window, partId) then
                map[partId] = nil
            end
        end
    end

    local function pruneGradeMap(map)
        if not map then return end
        for partId, grade in pairs(map) do
            if grade and isBlocked(window, partId) then
                map[partId] = nil
            end
        end
    end

    pruneGradeMap(window.installSelectedParts)
    pruneBooleanMap(window.repairSelectedParts)
    pruneBooleanMap(window.uninstallSelectedParts)
end

local oldGetPrettyLabel = VehicleArmorWindow.getPrettyLabel
function VehicleArmorWindow:getPrettyLabel(id, part)
    local label = oldGetPrettyLabel and oldGetPrettyLabel(self, id, part) or tostring(id or "")
    local blocked = isBlocked(self, id)
    if blocked and tostring(label):find("KI5", 1, true) == nil then
        return tostring(label) .. " [KI5 Protected]"
    end
    return label
end

local oldGetRecipeReport = VehicleArmorWindow.getRecipeReport
function VehicleArmorWindow:getRecipeReport(...)
    local report = oldGetRecipeReport and oldGetRecipeReport(self, ...) or {}

    if self and self.selectedPart and self.selectedPart.partId then
        local partId = self.selectedPart.partId
        local existing = getExistingArmor(self, partId)
        local action = existing and "repair" or "install"
        local blocked, info = isBlocked(self, partId)
        if blocked then
            report.ki5Blocked = true
            report.ki5BlockInfo = info
            report.ki5BlockReason = blockedReason(self, partId, action)
            report.canCraft = false
            report.canRepair = false
            report.repairReq = report.repairReq or {}
        else
            report.ki5Blocked = false
            report.ki5BlockInfo = nil
            report.ki5BlockReason = nil
        end
    end

    return report
end

local oldIsInstallSelectionCandidate = VehicleArmorWindow.isInstallSelectionCandidate
function VehicleArmorWindow:isInstallSelectionCandidate(partId, grade)
    if isBlocked(self, partId) then return false end
    if oldIsInstallSelectionCandidate then
        return oldIsInstallSelectionCandidate(self, partId, grade)
    end
    return false
end

local oldIsRepairSelectionCandidate = VehicleArmorWindow.isRepairSelectionCandidate
function VehicleArmorWindow:isRepairSelectionCandidate(partId)
    if isBlocked(self, partId) then return false end
    if oldIsRepairSelectionCandidate then
        return oldIsRepairSelectionCandidate(self, partId)
    end
    return false
end

local oldIsRemoveSelectionCandidate = VehicleArmorWindow.isRemoveSelectionCandidate
function VehicleArmorWindow:isRemoveSelectionCandidate(partId)
    if isBlocked(self, partId) then return false end
    if oldIsRemoveSelectionCandidate then
        return oldIsRemoveSelectionCandidate(self, partId)
    end
    return false
end

local oldCanRepairArmorPart = VehicleArmorWindow.canRepairArmorPart
function VehicleArmorWindow:canRepairArmorPart(partId, armor, report)
    if isBlocked(self, partId) then return false end
    if oldCanRepairArmorPart then
        return oldCanRepairArmorPart(self, partId, armor, report)
    end
    return false
end

local oldGetInstallAllQueue = VehicleArmorWindow.getInstallAllQueue
function VehicleArmorWindow:getInstallAllQueue(report)
    pruneSelections(self)
    local queue = oldGetInstallAllQueue and oldGetInstallAllQueue(self, report) or {}
    local filtered = {}
    for _, partId in ipairs(queue) do
        if not isBlocked(self, partId) then
            table.insert(filtered, partId)
        end
    end
    return filtered
end

local oldGetSelectedInstallQueue = VehicleArmorWindow.getSelectedInstallQueue
function VehicleArmorWindow:getSelectedInstallQueue(report)
    pruneSelections(self)
    local queue = oldGetSelectedInstallQueue and oldGetSelectedInstallQueue(self, report) or {}
    local filtered = {}
    for _, entry in ipairs(queue) do
        if type(entry) == "table" then
            if entry.partId and not isBlocked(self, entry.partId) then
                table.insert(filtered, entry)
            end
        elseif entry and not isBlocked(self, entry) then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

local oldGetRepairAllQueue = VehicleArmorWindow.getRepairAllQueue
function VehicleArmorWindow:getRepairAllQueue(report)
    pruneSelections(self)
    local queue = oldGetRepairAllQueue and oldGetRepairAllQueue(self, report) or {}
    local filtered = {}
    for _, partId in ipairs(queue) do
        if not isBlocked(self, partId) then
            table.insert(filtered, partId)
        end
    end
    return filtered
end

local oldGetUninstallAllQueue = VehicleArmorWindow.getUninstallAllQueue
function VehicleArmorWindow:getUninstallAllQueue(report)
    pruneSelections(self)
    local queue = oldGetUninstallAllQueue and oldGetUninstallAllQueue(self, report) or {}
    local filtered = {}
    for _, partId in ipairs(queue) do
        if not isBlocked(self, partId) then
            table.insert(filtered, partId)
        end
    end
    return filtered
end

local oldToggleInstallSelection = VehicleArmorWindow.toggleInstallSelection
function VehicleArmorWindow:toggleInstallSelection(rowItem)
    local partId = rowItem and rowItem.partId
    if partId and isBlocked(self, partId) then
        if self.character and self.character.Say then
            self.character:Say(blockedReason(self, partId, self.gsvu4BatchMode == "repair" and "repair" or (self.gsvu4BatchMode == "uninstall" and "uninstall" or "install")) or "Blocked by KI5 native armour.")
        end
        return
    end
    if oldToggleInstallSelection then
        return oldToggleInstallSelection(self, rowItem)
    end
end

local oldActionClick = VehicleArmorWindow.onActionButtonClick
function VehicleArmorWindow:onActionButtonClick()
    local partId = self and self.selectedPart and self.selectedPart.partId
    if partId then
        local existing = getExistingArmor(self, partId)
        if isBlocked(self, partId) then
            if self.character and self.character.Say then
                self.character:Say(blockedReason(self, partId, existing and "uninstall" or "install") or "Blocked by KI5 native armour.")
            end
            return
        end
    end
    if oldActionClick then
        return oldActionClick(self)
    end
end

local oldRepairClick = VehicleArmorWindow.onRepairButtonClick
function VehicleArmorWindow:onRepairButtonClick()
    local partId = self and self.selectedPart and self.selectedPart.partId
    if partId and isBlocked(self, partId) then
        if self.character and self.character.Say then
            self.character:Say(blockedReason(self, partId, "repair") or "Blocked by KI5 native armour.")
        end
        return
    end
    if oldRepairClick then
        return oldRepairClick(self)
    end
end

local oldGetBulkActionStatus = VehicleArmorWindow.getBulkActionStatus
function VehicleArmorWindow:getBulkActionStatus(report)
    local repairLine, uninstallLine = oldGetBulkActionStatus and oldGetBulkActionStatus(self, report) or nil, nil
    if type(repairLine) == "table" then
        -- defensive: should not happen, but avoid breaking the UI
        repairLine, uninstallLine = nil, nil
    end

    local blockedInstalled = 0
    local vdata = self.vehicle and self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor or nil
    if armorData then
        for partId, armor in pairs(armorData) do
            if armor and isBlocked(self, partId) then
                blockedInstalled = blockedInstalled + 1
            end
        end
    end

    if blockedInstalled > 0 then
        local extra = tostring(blockedInstalled) .. " KI5-protected SVU4 part(s) are blocked from repair/remove."
        if repairLine then
            repairLine = repairLine .. " " .. extra
        else
            repairLine = extra
        end
    end

    return repairLine, uninstallLine
end

local oldPrerender = VehicleArmorWindow.prerender
local function wrapText(text, maxChars)
    local out = {}
    local line = ""
    for word in tostring(text or ""):gmatch("%S+") do
        local candidate = (line == "" and word) or (line .. " " .. word)
        if #candidate > maxChars and line ~= "" then
            table.insert(out, line)
            line = word
        else
            line = candidate
        end
    end
    if line ~= "" then table.insert(out, line) end
    return out
end

function VehicleArmorWindow:prerender()
    if oldPrerender then
        oldPrerender(self)
    end

    local partId = self and self.selectedPart and self.selectedPart.partId
    if not partId then return end

    local vehicleKey = tostring(self.vehicle or "no-vehicle")
    local cacheKey = vehicleKey .. "|" .. tostring(partId)
    if self.gsvu4KI5CompatCacheKey ~= cacheKey then
        pruneSelections(self)

        local blocked, info = isBlocked(self, partId)
        local existing = getExistingArmor(self, partId)
        local action = existing and "repair" or "install"
        local reason = nil
        if blocked then
            reason = blockedReason(self, partId, action) or (info and info.reason) or "Blocked by KI5 native armour."
        end

        self.gsvu4KI5CompatCacheKey = cacheKey
        self.gsvu4KI5CompatBlocked = blocked == true
        self.gsvu4KI5CompatExisting = existing
        self.gsvu4KI5CompatReason = reason
    end

    if not self.gsvu4KI5CompatBlocked then return end

    local existing = self.gsvu4KI5CompatExisting
    local reason = self.gsvu4KI5CompatReason or "Blocked by KI5 native armour."

    if self.actionButton then
        self.actionButton:setEnable(false)
        self.actionButton:setTitle("KI5 Protected")
    end
    if self.repairButton then
        self.repairButton:setEnable(false)
        self.repairButton:setTitle("KI5 Protected")
    end

    local box = self.detailBox
    if not box then return end

    local x = box:getX() + 10
    local w = box:getWidth() - 20
    local lines = wrapText(reason, 62)
    local header = existing and "KI5 COMPATIBILITY BLOCK" or "KI5 NATIVE ARMOUR"
    local h = 40 + (#lines * 15)
    local y = box:getY() + box:getHeight() - h - 12

    self:drawRect(x, y, w, h, 0.88, 0.12, 0.12, 0.12)
    self:drawRectBorder(x, y, w, h, 0.95, 0.82, 0.52, 0.18)
    self:drawText(header, x + 10, y + 8, 0.95, 0.82, 0.52, 1, UIFont.Small)

    local lineY = y + 26
    for _, line in ipairs(lines) do
        self:drawText(line, x + 10, lineY, 0.92, 0.92, 0.92, 1, UIFont.Small)
        lineY = lineY + 15
    end
end

-- Timed action safety checks (SP / normal clients)
if ISWeldVehicleArmor and not ISWeldVehicleArmor.GSVU4_KI5CompatWrapped then
    local oldValid = ISWeldVehicleArmor.isValid
    function ISWeldVehicleArmor:isValid()
        if self.vehicle and self.partId and Compat.isBlocked then
            local blocked = Compat.isBlocked(self.vehicle, self.partId)
            if blocked then return false end
        end
        return oldValid and oldValid(self) or false
    end
    ISWeldVehicleArmor.GSVU4_KI5CompatWrapped = true
end

if ISRepairVehicleArmor and not ISRepairVehicleArmor.GSVU4_KI5CompatWrapped then
    local oldValid = ISRepairVehicleArmor.isValid
    function ISRepairVehicleArmor:isValid()
        if self.vehicle and self.partId and Compat.isBlocked then
            local blocked = Compat.isBlocked(self.vehicle, self.partId)
            if blocked then return false end
        end
        return oldValid and oldValid(self) or false
    end
    ISRepairVehicleArmor.GSVU4_KI5CompatWrapped = true
end

if ISUninstallVehicleArmor and not ISUninstallVehicleArmor.GSVU4_KI5CompatWrapped then
    local oldValid = ISUninstallVehicleArmor.isValid
    function ISUninstallVehicleArmor:isValid()
        if self.vehicle and self.partId and Compat.isBlocked then
            local blocked = Compat.isBlocked(self.vehicle, self.partId)
            if blocked then return false end
        end
        return oldValid and oldValid(self) or false
    end
    ISUninstallVehicleArmor.GSVU4_KI5CompatWrapped = true
end

-- Disable armour protection on blocked overlapping parts, even if legacy installs still exist.
if VehicleArmorDamage and VehicleArmorDamage.Check and not VehicleArmorDamage.GSVU4_KI5CompatWrapped then
    local oldDamageCheck = VehicleArmorDamage.Check
    local function wrappedDamageCheck(player)
        local vehicle = nil
        if player and player.getVehicle then
            vehicle = player:getVehicle()
        end

        if vehicle and Compat.isBlocked then
            local vdata = vehicle:getModData()
            local armorData = vdata and vdata.gArmor
            if armorData then
                local removed = {}
                for partId, armor in pairs(armorData) do
                    local blocked = Compat.isBlocked(vehicle, partId)
                    if blocked then
                        removed[partId] = armor
                        armorData[partId] = nil
                    end
                end
                oldDamageCheck(player)
                for partId, armor in pairs(removed) do
                    armorData[partId] = armor
                end
                return
            end
        end

        oldDamageCheck(player)
    end

    Events.OnPlayerUpdate.Remove(oldDamageCheck)
    VehicleArmorDamage.Check = wrappedDamageCheck
    Events.OnPlayerUpdate.Add(VehicleArmorDamage.Check)
    VehicleArmorDamage.GSVU4_KI5CompatWrapped = true
end
