require "VehicleArmor_UI"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
pcall(require, "GoresSVU4Core/GSVU4_FilteredAirIntake")
pcall(require, "GoresSVU4Core/GSVU4_PZKCompatibility")
pcall(require, "GoresSVU4Core/GSVU4_KI5FullBlock")
pcall(require, "GoresSVU4TyreChains/GSVU4_TyreChains_Config")
pcall(require, "GSVU4_TyreChains_TimedActions")

if not VehicleArmorWindow then return end

local function setVisible(control, visible)
    if control and control.setVisible then control:setVisible(visible == true) end
end

local function setEnabled(control, enabled)
    if control and control.setEnable then control:setEnable(enabled == true) end
end

local function setTitle(control, title)
    if control and control.setTitle then control:setTitle(tostring(title or "")) end
end

local function selectedCount(values)
    local count = 0
    for _, selected in pairs(values or {}) do
        if selected then count = count + 1 end
    end
    return count
end

local function modeIsUpgrades(window)
    return window and (window.gsvu4Mode or window.gsvu4ActiveTab) == "Upgrades"
end

local function listArmorParts(window, predicate)
    if not window or not window.partList or not window.partList.items then return 0 end
    local count = 0
    for _, row in ipairs(window.partList.items) do
        local data = row and row.item
        local partId = data and not data.header and data.partId or nil
        if partId and predicate(partId, data) then count = count + 1 end
    end
    return count
end

local function listUpgradeRows(window, predicate)
    if not window or not window.gsvu4UpgradeList or not window.gsvu4UpgradeList.items then return 0 end
    local count = 0
    for _, row in ipairs(window.gsvu4UpgradeList.items) do
        local data = row and row.item
        if data and predicate(data) then count = count + 1 end
    end
    return count
end

local function upgradeBlocked(window, upgradeId)
    if window and window.vehicle and GSVU4_PZKCompat and GSVU4_PZKCompat.isUpgradeBlocked then
        local ok, blocked = pcall(function() return GSVU4_PZKCompat.isUpgradeBlocked(window.vehicle, upgradeId) end)
        return ok and blocked == true
    end
    return false
end

local function getInstalledUpgrade(window, upgradeId)
    if not window or not window.vehicle or not GSVU4UpgradesConfig or not GSVU4UpgradesConfig.getInstalledUpgrade then return nil end
    return GSVU4UpgradesConfig.getInstalledUpgrade(window.vehicle, upgradeId)
end

local function getUpgradeMaximum(upgradeId, current)
    if not current then return 100 end
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig
        and GSVU4UpgradesConfig.getGradeConfig(upgradeId, current.grade) or nil
    return tonumber((cfg and cfg.health) or current.maxHealth or 100) or 100
end

local function vehicleArgs(vehicle, extra)
    local args = extra or {}
    if not vehicle then return args end
    if vehicle.getId then args.vehicleId = vehicle:getId() end
    if vehicle.getOnlineID then args.vehicleOnlineId = vehicle:getOnlineID() end
    if vehicle.getX then args.vehicleX = vehicle:getX() end
    if vehicle.getY then args.vehicleY = vehicle:getY() end
    if vehicle.getZ then args.vehicleZ = vehicle:getZ() end
    return args
end

local function queueTyreChainAction(character, vehicle, command)
    local totalTime = 240
    local label = "Installing tyre chains"
    if GSVU4_TyreChains and GSVU4_TyreChains.Config then
        if command == "Remove" then
            totalTime = GSVU4_TyreChains.Config.RemoveTime or 180
            label = "Removing tyre chains"
        elseif command == "RepairHeavy" then
            totalTime = GSVU4_TyreChains.Config.HeavyRepairTime or 180
            label = "Repairing tyre chains"
        elseif command == "RepairLight" then
            totalTime = GSVU4_TyreChains.Config.LightRepairTime or 120
            label = "Repairing tyre chains"
        else
            totalTime = GSVU4_TyreChains.Config.InstallTime or 240
        end
    end
    if GSVU4_TyreChains and GSVU4_TyreChains.queueTimedVehicleAction then
        GSVU4_TyreChains.queueTimedVehicleAction(character, vehicle, command, totalTime, label)
    elseif GSVU4_TyreChains and GSVU4_TyreChains.sendVehicleCommand then
        GSVU4_TyreChains.sendVehicleCommand(command, character, vehicle)
    end
end

function VehicleArmorWindow:beginInstallSelection(report)
    local grade = self.currentGrade or "Scrap"
    local candidates = listArmorParts(self, function(partId)
        return self.isInstallSelectionCandidate and self:isInstallSelectionCandidate(partId, grade)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearBatchSelections then self:gsvu4ClearBatchSelections(false) end
    self.gsvu4BatchMode = "install"
    self.installSelectMode = true
    self.installSelectedParts = {}
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}
    self.reportDirty = true
    return true
end

function VehicleArmorWindow:beginRepairSelection(report)
    local candidates = listArmorParts(self, function(partId)
        return self.isRepairSelectionCandidate and self:isRepairSelectionCandidate(partId)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearBatchSelections then self:gsvu4ClearBatchSelections(false) end
    self.gsvu4BatchMode = "repair"
    self.installSelectMode = true
    self.installSelectedParts = {}
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}
    self.reportDirty = true
    return true
end

function VehicleArmorWindow:beginRemoveSelection(report)
    local candidates = listArmorParts(self, function(partId)
        return self.isRemoveSelectionCandidate and self:isRemoveSelectionCandidate(partId)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearBatchSelections then self:gsvu4ClearBatchSelections(false) end
    self.gsvu4BatchMode = "uninstall"
    self.installSelectMode = true
    self.installSelectedParts = {}
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}
    self.pendingUninstallAll = false
    self.reportDirty = true
    return true
end

function VehicleArmorWindow:gsvu4BeginUpgradeInstallSelection()
    local candidates = listUpgradeRows(self, function(data)
        return self.gsvu4IsUpgradeInstallCandidate and self:gsvu4IsUpgradeInstallCandidate(data)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
    self.gsvu4UpgradeBatchMode = "install"
    self.gsvu4UpgradeInstallSelected = {}
    self.gsvu4UpgradeRepairSelected = {}
    self.gsvu4UpgradeRemoveSelected = {}
    return true
end

function VehicleArmorWindow:gsvu4BeginUpgradeRepairSelection()
    local candidates = listUpgradeRows(self, function(data)
        return self.gsvu4IsUpgradeRepairCandidate and self:gsvu4IsUpgradeRepairCandidate(data)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
    self.gsvu4UpgradeBatchMode = "repair"
    self.gsvu4UpgradeInstallSelected = {}
    self.gsvu4UpgradeRepairSelected = {}
    self.gsvu4UpgradeRemoveSelected = {}
    return true
end

function VehicleArmorWindow:gsvu4BeginUpgradeRemoveSelection()
    local candidates = listUpgradeRows(self, function(data)
        return self.gsvu4IsUpgradeRemoveCandidate and self:gsvu4IsUpgradeRemoveCandidate(data)
    end)
    if candidates <= 0 then return false end

    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
    self.gsvu4UpgradeBatchMode = "remove"
    self.gsvu4UpgradeInstallSelected = {}
    self.gsvu4UpgradeRepairSelected = {}
    self.gsvu4UpgradeRemoveSelected = {}
    return true
end

local previousUpgradeRepairCandidate = VehicleArmorWindow.gsvu4IsUpgradeRepairCandidate
function VehicleArmorWindow:gsvu4IsUpgradeRepairCandidate(data)
    if not data or not data.upgradeId or upgradeBlocked(self, data.upgradeId) then return false end
    if data.upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        local current = getInstalledUpgrade(self, data.upgradeId)
        if not current then return false end
        if data.grade and current.grade and tostring(data.grade) ~= tostring(current.grade) then return false end
        local status = GSVU4FilteredAirIntake.getStatus(self.vehicle)
        return (tonumber(status and status.capacity) or 0) < (tonumber(status and status.maximum) or 0)
    end

    local current = getInstalledUpgrade(self, data.upgradeId)
    if current and (not data.grade or not current.grade or tostring(data.grade) == tostring(current.grade)) then
        return (tonumber(current.health or current.condition) or 100) < getUpgradeMaximum(data.upgradeId, current)
    end

    if previousUpgradeRepairCandidate then return previousUpgradeRepairCandidate(self, data) end
    return false
end

function VehicleArmorWindow:onGSVU4RepairUpgradeClick()
    if self.gsvu4UpgradeBatchMode ~= "repair" then
        if not self:gsvu4BeginUpgradeRepairSelection() then
            if self.character then self.character:Say("No damaged or depleted upgrades available.") end
            return
        end
        if self.character then self.character:Say("Select upgrades to repair, then click Repair Selected.") end
        return
    end

    local queue = self.gsvu4BuildSelectedRepairUpgradeQueue and self:gsvu4BuildSelectedRepairUpgradeQueue() or {}
    if #queue <= 0 then
        if self.character then self.character:Say("No selected upgrades can be repaired.") end
        return
    end

    local queued = 0
    for _, data in ipairs(queue) do
        local current = getInstalledUpgrade(self, data.upgradeId)
        if data.upgradeId == "TyreChains" then
            local condition = tonumber(current and (current.health or current.condition)) or 100
            queueTyreChainAction(self.character, self.vehicle, condition <= 50 and "RepairHeavy" or "RepairLight")
            queued = queued + 1
        elseif data.upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
            if isClient and isClient() and sendClientCommand then
                sendClientCommand("GoresSVU4Core", "ReplaceFilteredAirIntakeFilters", vehicleArgs(self.vehicle))
                queued = queued + 1
            else
                local ok, _, _, reason = GSVU4FilteredAirIntake.replaceFilterSetFromCharacter(self.character, self.vehicle)
                if ok then
                    if self.vehicle and self.vehicle.transmitModData then pcall(function() self.vehicle:transmitModData() end) end
                    if GSVU4FilteredAirIntake.refreshProtectionRuntime then
                        pcall(function() GSVU4FilteredAirIntake.refreshProtectionRuntime(self.character, self.vehicle) end)
                    end
                    queued = queued + 1
                elseif self.character then
                    self.character:Say(reason or "Unable to replace filters.")
                end
            end
        elseif isClient and isClient() and sendClientCommand then
            sendClientCommand("GoresSVU4Core", "RepairUpgrade", vehicleArgs(self.vehicle, {upgradeId = data.upgradeId}))
            queued = queued + 1
        elseif current then
            local maximum = getUpgradeMaximum(data.upgradeId, current)
            current.health = maximum
            current.maxHealth = maximum
            current.wearRemainder = 0
            queued = queued + 1
        end
    end

    if queued > 0 and self.vehicle and self.vehicle.transmitModData and not (isClient and isClient()) then
        pcall(function() self.vehicle:transmitModData() end)
    end
    if self.character then self.character:Say("Queued " .. tostring(queued) .. " upgrade repairs.") end
    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
    if queued > 0 then self:close() end
end

local previousArmorAction = VehicleArmorWindow.onActionButtonClick
function VehicleArmorWindow:onActionButtonClick()
    if not self.selectedPart or not self.vehicle then return end
    local partId = self.selectedPart.partId
    local md = self.vehicle:getModData()
    if md and md.gArmor and md.gArmor[partId] then
        if self.character then self.character:Say("This panel is already installed. Use Select Remove to remove it.") end
        return
    end
    return previousArmorAction(self)
end

function VehicleArmorWindow:onGSVU4SingleInstallClick()
    local selected = self.gsvu4SelectedUpgrade
    if not selected or not self.gsvu4IsUpgradeInstallCandidate or not self:gsvu4IsUpgradeInstallCandidate(selected) then
        if self.character then self.character:Say("Select an installable upgrade.") end
        return
    end

    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
    self.gsvu4UpgradeBatchMode = "install"
    self.gsvu4UpgradeInstallSelected = {[selected.upgradeId] = selected.grade}
    self.gsvu4UpgradeRepairSelected = {}
    self.gsvu4UpgradeRemoveSelected = {}

    local queue = self.gsvu4BuildSelectedInstallUpgradeQueue and self:gsvu4BuildSelectedInstallUpgradeQueue() or {}
    if #queue <= 0 then
        if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end
        if self.character then self.character:Say("The selected upgrade is missing requirements.") end
        return
    end

    self:onGSVU4InstallUpgradeClick()
end

local function placeFooterButtons(window, buttons)
    local margin = 10
    local gap = 6
    local height = 32
    local width = math.floor(((window.width or 1040) - (margin * 2) - (gap * 5)) / 6)
    local y = (window.height or 650) - height - 8

    for index, button in ipairs(buttons) do
        if button then
            button:setX(margin + ((index - 1) * (width + gap)))
            button:setY(y)
            if button.setWidth then button:setWidth(width) end
            if button.setHeight then button:setHeight(height) end
        end
    end
end

local function armorCandidateCounts(window)
    local grade = window.currentGrade or "Scrap"
    local install = listArmorParts(window, function(partId)
        return window.isInstallSelectionCandidate and window:isInstallSelectionCandidate(partId, grade)
    end)
    local repair = listArmorParts(window, function(partId)
        return window.isRepairSelectionCandidate and window:isRepairSelectionCandidate(partId)
    end)
    local remove = listArmorParts(window, function(partId)
        return window.isRemoveSelectionCandidate and window:isRemoveSelectionCandidate(partId)
    end)
    return install, repair, remove
end

local function updateArmorFooter(window)
    local installCandidates, repairCandidates, removeCandidates = armorCandidateCounts(window)
    local mode = window.gsvu4BatchMode
    local installSelected = window.getSelectedInstallCount and window:getSelectedInstallCount() or selectedCount(window.installSelectedParts)
    local repairSelected = selectedCount(window.repairSelectedParts)
    local removeSelected = selectedCount(window.uninstallSelectedParts)

    setTitle(window.closeButton, "Close")
    setTitle(window.clearSelectionButton, "Clear")
    setTitle(window.repairAllButton, mode == "repair" and ("Repair Selected" .. (repairSelected > 0 and " (" .. repairSelected .. ")" or "")) or "Select Repair")
    setTitle(window.uninstallAllButton, mode == "uninstall" and ("Remove Selected" .. (removeSelected > 0 and " (" .. removeSelected .. ")" or "")) or "Select Remove")
    setTitle(window.installAllButton, mode == "install" and ("Install Selected" .. (installSelected > 0 and " (" .. installSelected .. ")" or "")) or "Select Install")
    setTitle(window.actionButton, "Install")

    setEnabled(window.clearSelectionButton, mode ~= nil)
    setEnabled(window.repairAllButton, mode == "repair" and repairSelected > 0 or repairCandidates > 0)
    setEnabled(window.uninstallAllButton, mode == "uninstall" and removeSelected > 0 or removeCandidates > 0)
    setEnabled(window.installAllButton, mode == "install" and installSelected > 0 or installCandidates > 0)

    local canSingleInstall = false
    if window.selectedPart and window.vehicle then
        local partId = window.selectedPart.partId
        local md = window.vehicle:getModData()
        local installed = md and md.gArmor and md.gArmor[partId]
        local report = window.cachedReport
        canSingleInstall = not installed and report and report.canCraft == true
        if GSVU4_KI5FullBlock and GSVU4_KI5FullBlock.IsBlocked and GSVU4_KI5FullBlock.IsBlocked(window.vehicle) then
            canSingleInstall = false
        end
    end
    setEnabled(window.actionButton, canSingleInstall)
end

local function updateUpgradeFooter(window)
    local mode = window.gsvu4UpgradeBatchMode
    local installSelected = selectedCount(window.gsvu4UpgradeInstallSelected)
    local repairSelected = selectedCount(window.gsvu4UpgradeRepairSelected)
    local removeSelected = selectedCount(window.gsvu4UpgradeRemoveSelected)

    local installCandidates = listUpgradeRows(window, function(data)
        return window.gsvu4IsUpgradeInstallCandidate and window:gsvu4IsUpgradeInstallCandidate(data)
    end)
    local repairCandidates = listUpgradeRows(window, function(data)
        return window.gsvu4IsUpgradeRepairCandidate and window:gsvu4IsUpgradeRepairCandidate(data)
    end)
    local removeCandidates = listUpgradeRows(window, function(data)
        return window.gsvu4IsUpgradeRemoveCandidate and window:gsvu4IsUpgradeRemoveCandidate(data)
    end)

    setTitle(window.closeButton, "Close")
    setTitle(window.gsvu4ClearUpgradeSelectionButton, "Clear")
    setTitle(window.gsvu4RepairUpgradeButton, mode == "repair" and ("Repair Selected" .. (repairSelected > 0 and " (" .. repairSelected .. ")" or "")) or "Select Repair")
    setTitle(window.gsvu4RemoveUpgradeButton, mode == "remove" and ("Remove Selected" .. (removeSelected > 0 and " (" .. removeSelected .. ")" or "")) or "Select Remove")
    setTitle(window.gsvu4InstallUpgradeButton, mode == "install" and ("Install Selected" .. (installSelected > 0 and " (" .. installSelected .. ")" or "")) or "Select Install")
    setTitle(window.gsvu4SingleInstallButton, "Install")

    setEnabled(window.gsvu4ClearUpgradeSelectionButton, mode ~= nil)
    setEnabled(window.gsvu4RepairUpgradeButton, mode == "repair" and repairSelected > 0 or repairCandidates > 0)
    setEnabled(window.gsvu4RemoveUpgradeButton, mode == "remove" and removeSelected > 0 or removeCandidates > 0)
    setEnabled(window.gsvu4InstallUpgradeButton, mode == "install" and installSelected > 0 or installCandidates > 0)

    local selected = window.gsvu4SelectedUpgrade
    local canSingleInstall = selected and window.gsvu4IsUpgradeInstallCandidate and window:gsvu4IsUpgradeInstallCandidate(selected) or false
    setEnabled(window.gsvu4SingleInstallButton, canSingleInstall == true)
end

local previousCreateChildren = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    previousCreateChildren(self)

    self.gsvu4BatchMode = nil
    self.installSelectMode = false
    self.installSelectedParts = {}
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}
    if self.gsvu4ClearUpgradeBatchSelections then self:gsvu4ClearUpgradeBatchSelections() end

    self.gsvu4SingleInstallButton = ISButton:new(0, 0, 150, 32, "Install", self, function(target)
        target:onGSVU4SingleInstallClick()
    end)
    self.gsvu4SingleInstallButton:initialise()
    self:addChild(self.gsvu4SingleInstallButton)

    setVisible(self.repairButton, false)
end

local previousPrerender = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender(...)
    if previousPrerender then previousPrerender(self, ...) end

    local upgrades = modeIsUpgrades(self)
    setVisible(self.repairButton, false)

    if upgrades then
        setVisible(self.closeButton, true)
        setVisible(self.clearSelectionButton, false)
        setVisible(self.repairAllButton, false)
        setVisible(self.uninstallAllButton, false)
        setVisible(self.installAllButton, false)
        setVisible(self.actionButton, false)

        setVisible(self.gsvu4ClearUpgradeSelectionButton, true)
        setVisible(self.gsvu4RepairUpgradeButton, true)
        setVisible(self.gsvu4RemoveUpgradeButton, true)
        setVisible(self.gsvu4InstallUpgradeButton, true)
        setVisible(self.gsvu4SingleInstallButton, true)

        placeFooterButtons(self, {
            self.closeButton,
            self.gsvu4ClearUpgradeSelectionButton,
            self.gsvu4RepairUpgradeButton,
            self.gsvu4RemoveUpgradeButton,
            self.gsvu4InstallUpgradeButton,
            self.gsvu4SingleInstallButton,
        })
        updateUpgradeFooter(self)
    else
        setVisible(self.closeButton, true)
        setVisible(self.clearSelectionButton, true)
        setVisible(self.repairAllButton, true)
        setVisible(self.uninstallAllButton, true)
        setVisible(self.installAllButton, true)
        setVisible(self.actionButton, true)

        setVisible(self.gsvu4ClearUpgradeSelectionButton, false)
        setVisible(self.gsvu4RepairUpgradeButton, false)
        setVisible(self.gsvu4RemoveUpgradeButton, false)
        setVisible(self.gsvu4InstallUpgradeButton, false)
        setVisible(self.gsvu4SingleInstallButton, false)

        placeFooterButtons(self, {
            self.closeButton,
            self.clearSelectionButton,
            self.repairAllButton,
            self.uninstallAllButton,
            self.installAllButton,
            self.actionButton,
        })
        updateArmorFooter(self)
    end
end
