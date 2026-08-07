--========================================================
-- Gore's SVU4 Core - Upgrade Batch Selection
--========================================================
-- Adds Armor-style batch buttons to the Upgrades tab:
--   Select Install -> Install Batch
--   Select Repair  -> Repair Batch
--   Select Remove  -> Remove Batch
--========================================================

require "VehicleArmor_UI"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"
pcall(require, "GoresSVU4Core/GSVU4_PZKCompatibility")
pcall(require, "GoresSVU4TyreChains/GSVU4_TyreChains_Config")
pcall(require, "GSVU4_TyreChains_TimedActions")
pcall(require, "GSVU4_TyreChains_ContextMenu")
require "TimedActions/ISInstallVehicleUpgrade"
require "TimedActions/ISUninstallVehicleUpgrade"
require "TimedActions/ISTimedActionQueue"
require "VehicleArmor_ConsumeHelpers"

if not VehicleArmorWindow then
    return
end

local PREFIX = "[Gore's SVU4 Core UpgradeBatch] "

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function say(character, text)
    if character and character.Say then character:Say(tostring(text or "")) end
end

local function getMode(window)
    return window and (window.gsvu4Mode or window.gsvu4ActiveTab) or "Armor"
end

local function isUpgradesMode(window)
    return getMode(window) == "Upgrades"
end

local function keyForUpgrade(upgradeId, grade)
    return tostring(upgradeId or "") .. "|" .. tostring(grade or "")
end

local function selectedCount(map)
    local count = 0
    if not map then return 0 end
    for _, value in pairs(map) do
        if value then count = count + 1 end
    end
    return count
end

local function setButtonTitle(button, title)
    if button and button.setTitle then button:setTitle(tostring(title or "")) end
end

local function setVisible(ctrl, visible)
    if ctrl and ctrl.setVisible then ctrl:setVisible(visible == true) end
end

local function getTextH(font)
    if getTextManager and UIFont then
        local ok, h = pcall(function() return getTextManager():getFontHeight(font or UIFont.Small) end)
        if ok and h then return tonumber(h) or 14 end
    end
    return 14
end

local function getInstalledUpgrade(vehicle, upgradeId)
    if not vehicle or not GSVU4UpgradesConfig or not GSVU4UpgradesConfig.getInstalledUpgrade then return nil end
    return GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, upgradeId)
end

local function getInstalledHealth(upgrade)
    if not upgrade then return 0 end
    return tonumber(upgrade.health or upgrade.condition) or 100
end

local function getCfg(upgradeId, grade)
    if not GSVU4UpgradesConfig or not GSVU4UpgradesConfig.getGradeConfig then return nil end
    return GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
end

local function getUpgDef(upgradeId)
    if not GSVU4UpgradesConfig or not GSVU4UpgradesConfig.getUpgrade then return nil end
    return GSVU4UpgradesConfig.getUpgrade(upgradeId)
end

local function getUpgradeLabel(upgradeId)
    local def = getUpgDef(upgradeId)
    return def and def.label or tostring(upgradeId or "Upgrade")
end

local function getRowLabel(data)
    if not data then return "Upgrade" end
    local cfg = getCfg(data.upgradeId, data.grade)
    return cfg and cfg.label or (getUpgradeLabel(data.upgradeId) .. " " .. tostring(data.grade or ""))
end

local function isUpgradeBlocked(window, upgradeId)
    if window and window.vehicle and upgradeId and GSVU4_PZKCompat and GSVU4_PZKCompat.isUpgradeBlocked then
        local ok, blocked = pcall(function() return GSVU4_PZKCompat.isUpgradeBlocked(window.vehicle, upgradeId) end)
        return ok and blocked == true
    end
    return false
end

local function getBlockReason(window, upgradeId, action)
    if window and window.vehicle and upgradeId and GSVU4_PZKCompat and GSVU4_PZKCompat.getUpgradeBlockedReason then
        local ok, reason = pcall(function() return GSVU4_PZKCompat.getUpgradeBlockedReason(window.vehicle, upgradeId, action or "install") end)
        if ok and reason then return tostring(reason) end
    end
    return "Blocked by PZK/SVU3 compatibility."
end

local function getItemFullType(item)
    if not item then return "" end
    if item.getFullType then
        local ok, ft = pcall(function() return item:getFullType() end)
        if ok and ft then return tostring(ft) end
    end
    if item.getModule and item.getType then
        local ok, module, typ = pcall(function() return item:getModule(), item:getType() end)
        if ok and module and typ then return tostring(module) .. "." .. tostring(typ) end
    end
    return ""
end

local function scanInventory(inv, callback, seen)
    if not inv or not callback then return end
    seen = seen or {}
    local key = tostring(inv)
    if seen[key] then return end
    seen[key] = true

    local items = inv.getItems and inv:getItems() or nil
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            callback(item)
            if item.getInventory then
                local ok, child = pcall(function() return item:getInventory() end)
                if ok and child then scanInventory(child, callback, seen) end
            end
        end
    end
end

local function forEachAccessibleItem(character, callback)
    if not character or not callback then return end
    if character.getInventory then
        local ok, inv = pcall(function() return character:getInventory() end)
        if ok and inv then scanInventory(inv, callback) end
    end
end

local function countFullType(character, fullType)
    local count = 0
    fullType = tostring(fullType or "")
    forEachAccessibleItem(character, function(item)
        if getItemFullType(item) == fullType then count = count + 1 end
    end)
    return count
end

local function hasFullType(character, fullTypes)
    for _, fullType in ipairs(fullTypes or {}) do
        if countFullType(character, fullType) > 0 then return true end
    end
    return false
end

local function isScrewdriverItem(item)
    if VehicleArmorHelpers and VehicleArmorHelpers.isScrewdriverItem and VehicleArmorHelpers.isScrewdriverItem(item) then return true end
    local ft = string.lower(getItemFullType(item))
    local t = item and item.getType and string.lower(tostring(item:getType())) or ""
    return ft == "base.screwdriver" or t == "screwdriver" or string.find(ft, "screwdriver", 1, true) ~= nil or string.find(t, "screwdriver", 1, true) ~= nil
end

local function isHammerItem(item)
    if VehicleArmorHelpers and VehicleArmorHelpers.isHammerItem and VehicleArmorHelpers.isHammerItem(item) then return true end
    local ft = getItemFullType(item)
    local t = item and item.getType and tostring(item:getType()) or ""
    return ft == "Base.Hammer" or ft == "Base.BallPeenHammer" or string.find(t, "Hammer") ~= nil or string.find(ft, "Hammer") ~= nil
end

local function getToolReport(character)
    local report = {
        hammer = false,
        screwdriver = false,
        mask = false,
        blowTorch = false,
        lugWrench = false,
        wrenchOrRatchet = false,
    }
    if not character then return report end
    if VehicleArmorHelpers and VehicleArmorHelpers.getTotalTorchFuel then
        report.blowTorch = (tonumber(VehicleArmorHelpers.getTotalTorchFuel(character)) or 0) > 0
    else
        report.blowTorch = hasFullType(character, {"Base.BlowTorch"})
    end
    forEachAccessibleItem(character, function(item)
        local ft = getItemFullType(item)
        if ft == "Base.WeldingMask" then report.mask = true end
        if isHammerItem(item) then report.hammer = true end
        if isScrewdriverItem(item) then report.screwdriver = true end
        if ft == "Base.LugWrench" then report.lugWrench = true end
        if ft == "Base.Wrench" or ft == "Base.RatchetWrench" then report.wrenchOrRatchet = true end
    end)
    return report
end

local function toolOkFor(character, upgradeId, grade)
    local tools = getToolReport(character)
    if upgradeId == "TyreChains" then
        return tools.lugWrench and tools.wrenchOrRatchet, tools
    end
    local cfg = getCfg(upgradeId, grade)
    local upg = getUpgDef(upgradeId)
    local req = (cfg and cfg.tools) or (upg and upg.tools) or {}
    if req.hammer and not tools.hammer then return false, tools end
    if req.screwdriver and not tools.screwdriver then return false, tools end
    if req.weldingMask and not tools.mask then return false, tools end
    if req.blowTorch and not tools.blowTorch then return false, tools end
    return true, tools
end

local function getPerkLevel(character, perk)
    if not character or not perk or not character.getPerkLevel then return 0 end
    local ok, v = pcall(function() return character:getPerkLevel(perk) end)
    if ok and v then return tonumber(v) or 0 end
    return 0
end

local function skillsOkFor(character, cfg)
    local skills = cfg and cfg.skills or {}
    local mwNeed = tonumber(skills.MetalWelding or 0) or 0
    local meNeed = tonumber(skills.Mechanics or 0) or 0
    local elNeed = tonumber(skills.Electricity or 0) or 0
    local mw = Perks and Perks.MetalWelding and getPerkLevel(character, Perks.MetalWelding) or 0
    local me = Perks and Perks.Mechanics and getPerkLevel(character, Perks.Mechanics) or 0
    local el = Perks and Perks.Electricity and getPerkLevel(character, Perks.Electricity) or 0
    return mw >= mwNeed and me >= meNeed and el >= elNeed
end

local function copyMaterialBudget(character)
    local budget = {}
    if VehicleArmorHelpers and VehicleArmorHelpers.countMaterialsForCharacter then
        local mats = VehicleArmorHelpers.countMaterialsForCharacter(character)
        for k, v in pairs(mats or {}) do budget[k] = tonumber(v) or 0 end
    end
    budget.heavyChain = countFullType(character, "Base.HeavyChain")
    budget.ductTape = countFullType(character, "Base.DuctTape")
    return budget
end

local function adjustedRecipe(recipe)
    if VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
        local ok, adjusted = pcall(function() return VehicleArmorHelpers.getAdjustedRecipe(recipe) end)
        if ok and adjusted then return adjusted end
    end
    local out = {}
    for k, v in pairs(recipe or {}) do
        local n = tonumber(v) or 0
        if k == "rods" then out[k] = math.max(0.01, n) else out[k] = math.ceil(n) end
    end
    return out
end

local function canAffordAndReserveRecipe(budget, recipe)
    local adjusted = adjustedRecipe(recipe)
    for k, need in pairs(adjusted or {}) do
        if (budget[k] or 0) + 0.0001 < (tonumber(need) or 0) then return false end
    end
    for k, need in pairs(adjusted or {}) do
        budget[k] = (budget[k] or 0) - (tonumber(need) or 0)
    end
    return true
end

local function addVehicleArgs(args, vehicle)
    args = args or {}
    if not vehicle then return args end
    if vehicle.getId then local ok, v = pcall(function() return vehicle:getId() end); if ok then args.vehicleId = v end end
    if vehicle.getOnlineID then local ok, v = pcall(function() return vehicle:getOnlineID() end); if ok then args.vehicleOnlineId = v end end
    if vehicle.getX then local ok, v = pcall(function() return vehicle:getX() end); if ok then args.vehicleX = v end end
    if vehicle.getY then local ok, v = pcall(function() return vehicle:getY() end); if ok then args.vehicleY = v end end
    if vehicle.getZ then local ok, v = pcall(function() return vehicle:getZ() end); if ok then args.vehicleZ = v end end
    return args
end

local function prerequisiteMetConsideringQueued(vehicle, upgradeId, queued)
    local upg = getUpgDef(upgradeId)
    local required = upg and upg.requiresUpgrade or nil
    if not required then return true end
    if getInstalledUpgrade(vehicle, required) then return true end
    return queued and queued[required] == true
end

local function canInstallRow(window, data, budget, queued)
    if not window or not data then return false, "Invalid upgrade." end
    local upgradeId, grade = data.upgradeId, data.grade
    local cfg = getCfg(upgradeId, grade)
    if not cfg then return false, "Invalid upgrade." end
    if isUpgradeBlocked(window, upgradeId) then return false, getBlockReason(window, upgradeId, "install") end
    if getInstalledUpgrade(window.vehicle, upgradeId) then return false, getUpgradeLabel(upgradeId) .. " already installed." end
    if not prerequisiteMetConsideringQueued(window.vehicle, upgradeId, queued) then return false, "Required upgrade not installed." end
    if not skillsOkFor(window.character, cfg) then return false, "Skill requirement not met." end
    local okTools = toolOkFor(window.character, upgradeId, grade)
    if not okTools then return false, "Missing tools." end

    if upgradeId == "ExtraFuelStorage" and GSVU4UpgradesConfig and GSVU4UpgradesConfig.canAffordTrunkPenalty then
        local okTrunk, reason = GSVU4UpgradesConfig.canAffordTrunkPenalty(window.vehicle, upgradeId, grade)
        if not okTrunk then return false, reason or "Cargo compartment is too small." end
    end

    local fuelUse = tonumber(cfg.fuelUse or 0) or 0
    if (budget.torchUnits or 0) + 0.0001 < fuelUse then return false, "Missing blowtorch fuel." end
    if not canAffordAndReserveRecipe(budget, cfg.recipe or {}) then return false, "Missing materials." end
    budget.torchUnits = (budget.torchUnits or 0) - fuelUse
    queued[upgradeId] = true
    return true, nil
end

local function orderUpgradeRows(window)
    local rows = {}
    if window and window.gsvu4UpgradeList and window.gsvu4UpgradeList.items then
        for _, row in ipairs(window.gsvu4UpgradeList.items) do
            local data = row and row.item
            if data and data.upgradeId and data.grade then rows[#rows + 1] = data end
        end
    end
    return rows
end

function VehicleArmorWindow:gsvu4ClearUpgradeBatchSelections()
    self.gsvu4UpgradeBatchMode = nil
    self.gsvu4UpgradeInstallSelected = {}
    self.gsvu4UpgradeRepairSelected = {}
    self.gsvu4UpgradeRemoveSelected = {}
    self.gsvu4UpgradeBatchDirty = true
end

local function ensureUpgradeSelectionTables(window)
    window.gsvu4UpgradeInstallSelected = window.gsvu4UpgradeInstallSelected or {}
    window.gsvu4UpgradeRepairSelected = window.gsvu4UpgradeRepairSelected or {}
    window.gsvu4UpgradeRemoveSelected = window.gsvu4UpgradeRemoveSelected or {}
end

function VehicleArmorWindow:gsvu4IsUpgradeInstallCandidate(data)
    if not data or not data.upgradeId or not data.grade then return false end
    if isUpgradeBlocked(self, data.upgradeId) then return false end
    if data.upgradeId == "FilteredAirIntake"
    and GSVU4FilteredAirIntake
    and GSVU4FilteredAirIntake.canInstallOnVehicle then
        local vehicleOk = GSVU4FilteredAirIntake.canInstallOnVehicle(self.vehicle)
        if not vehicleOk then return false end
    end
    if getInstalledUpgrade(self.vehicle, data.upgradeId) then return false end
    return getCfg(data.upgradeId, data.grade) ~= nil
end

function VehicleArmorWindow:gsvu4IsUpgradeRepairCandidate(data)
    if not data or not data.upgradeId then return false end
    if isUpgradeBlocked(self, data.upgradeId) then return false end
    local current = getInstalledUpgrade(self.vehicle, data.upgradeId)
    if not current then return false end
    if data.grade and current.grade and tostring(data.grade) ~= tostring(current.grade) then return false end
    return getInstalledHealth(current) < 100
end

function VehicleArmorWindow:gsvu4IsUpgradeRemoveCandidate(data)
    if not data or not data.upgradeId then return false end
    if isUpgradeBlocked(self, data.upgradeId) then return false end
    local current = getInstalledUpgrade(self.vehicle, data.upgradeId)
    if not current then return false end
    if data.grade and current.grade and tostring(data.grade) ~= tostring(current.grade) then return false end
    return true
end

function VehicleArmorWindow:gsvu4ToggleUpgradeBatchSelection(data)
    if not data or not data.upgradeId or not data.grade then return end
    ensureUpgradeSelectionTables(self)

    if self.gsvu4UpgradeBatchMode == "install" then
        if not self:gsvu4IsUpgradeInstallCandidate(data) then return end
        if self.gsvu4UpgradeInstallSelected[data.upgradeId] == data.grade then
            self.gsvu4UpgradeInstallSelected[data.upgradeId] = nil
        else
            self.gsvu4UpgradeInstallSelected[data.upgradeId] = data.grade
        end
    elseif self.gsvu4UpgradeBatchMode == "repair" then
        if not self:gsvu4IsUpgradeRepairCandidate(data) then return end
        local key = keyForUpgrade(data.upgradeId, data.grade)
        self.gsvu4UpgradeRepairSelected[key] = not self.gsvu4UpgradeRepairSelected[key]
    elseif self.gsvu4UpgradeBatchMode == "remove" then
        if not self:gsvu4IsUpgradeRemoveCandidate(data) then return end
        local key = keyForUpgrade(data.upgradeId, data.grade)
        self.gsvu4UpgradeRemoveSelected[key] = not self.gsvu4UpgradeRemoveSelected[key]
    end

    self.gsvu4UpgradeBatchDirty = true
end

function VehicleArmorWindow:gsvu4BuildSelectedInstallUpgradeQueue()
    local queue = {}
    local budget = copyMaterialBudget(self.character)
    budget.torchUnits = VehicleArmorHelpers and VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(self.character) or 0
    local queued = {}

    for _, data in ipairs(orderUpgradeRows(self)) do
        if self.gsvu4UpgradeInstallSelected and self.gsvu4UpgradeInstallSelected[data.upgradeId] == data.grade then
            local ok = canInstallRow(self, data, budget, queued)
            if ok then queue[#queue + 1] = {upgradeId=data.upgradeId, grade=data.grade} end
        end
    end
    return queue
end

function VehicleArmorWindow:gsvu4BuildSelectedRepairUpgradeQueue()
    local queue = {}
    for _, data in ipairs(orderUpgradeRows(self)) do
        local key = keyForUpgrade(data.upgradeId, data.grade)
        if self.gsvu4UpgradeRepairSelected and self.gsvu4UpgradeRepairSelected[key] and self:gsvu4IsUpgradeRepairCandidate(data) then
            queue[#queue + 1] = {upgradeId=data.upgradeId, grade=data.grade}
        end
    end
    return queue
end

function VehicleArmorWindow:gsvu4BuildSelectedRemoveUpgradeQueue()
    local queue = {}
    for _, data in ipairs(orderUpgradeRows(self)) do
        local key = keyForUpgrade(data.upgradeId, data.grade)
        if self.gsvu4UpgradeRemoveSelected and self.gsvu4UpgradeRemoveSelected[key] and self:gsvu4IsUpgradeRemoveCandidate(data) then
            queue[#queue + 1] = {upgradeId=data.upgradeId, grade=data.grade}
        end
    end
    return queue
end

function VehicleArmorWindow:gsvu4BeginUpgradeInstallSelection()
    ensureUpgradeSelectionTables(self)
    self:gsvu4ClearUpgradeBatchSelections()
    self.gsvu4UpgradeBatchMode = "install"
    self.gsvu4UpgradeInstallSelected = {}
    for _, data in ipairs(orderUpgradeRows(self)) do
        if self:gsvu4IsUpgradeInstallCandidate(data) and not self.gsvu4UpgradeInstallSelected[data.upgradeId] then
            self.gsvu4UpgradeInstallSelected[data.upgradeId] = data.grade
        end
    end
    return selectedCount(self.gsvu4UpgradeInstallSelected) > 0
end

function VehicleArmorWindow:gsvu4BeginUpgradeRepairSelection()
    ensureUpgradeSelectionTables(self)
    self:gsvu4ClearUpgradeBatchSelections()
    self.gsvu4UpgradeBatchMode = "repair"
    self.gsvu4UpgradeRepairSelected = {}
    for _, data in ipairs(orderUpgradeRows(self)) do
        if self:gsvu4IsUpgradeRepairCandidate(data) then
            self.gsvu4UpgradeRepairSelected[keyForUpgrade(data.upgradeId, data.grade)] = true
        end
    end
    return selectedCount(self.gsvu4UpgradeRepairSelected) > 0
end

function VehicleArmorWindow:gsvu4BeginUpgradeRemoveSelection()
    ensureUpgradeSelectionTables(self)
    self:gsvu4ClearUpgradeBatchSelections()
    self.gsvu4UpgradeBatchMode = "remove"
    self.gsvu4UpgradeRemoveSelected = {}
    for _, data in ipairs(orderUpgradeRows(self)) do
        if self:gsvu4IsUpgradeRemoveCandidate(data) then
            self.gsvu4UpgradeRemoveSelected[keyForUpgrade(data.upgradeId, data.grade)] = true
        end
    end
    return selectedCount(self.gsvu4UpgradeRemoveSelected) > 0
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

local function sendUpgradeCommand(window, command, upgradeId)
    if not sendClientCommand or not window then return end
    local args = addVehicleArgs({upgradeId = upgradeId}, window.vehicle)
    sendClientCommand("GoresSVU4Core", command, args)
end

function VehicleArmorWindow:onGSVU4InstallUpgradeClick()
    if self.gsvu4UpgradeBatchMode ~= "install" then
        if not self:gsvu4BeginUpgradeInstallSelection() then
            say(self.character, "No installable upgrades available.")
            return
        end
        say(self.character, "Select upgrades to install, then click Install Selected.")
        return
    end

    local queue = self:gsvu4BuildSelectedInstallUpgradeQueue()
    if #queue <= 0 then
        say(self.character, "Selected upgrades are missing requirements.")
        return
    end

    for _, data in ipairs(queue) do
        if data.upgradeId == "TyreChains" then
            queueTyreChainAction(self.character, self.vehicle, "Install")
        else
            local cfg = getCfg(data.upgradeId, data.grade)
            if GSVU4Core and GSVU4Core.QueueUpgradeInstallTimedAction then
                GSVU4Core.QueueUpgradeInstallTimedAction(
                    self.character,
                    self.vehicle,
                    data.upgradeId,
                    data.grade,
                    cfg and cfg.time or 200
                )
            else
                ISTimedActionQueue.add(ISInstallVehicleUpgrade:new(
                    self.character,
                    self.vehicle,
                    data.upgradeId,
                    data.grade,
                    cfg and cfg.time or 200
                ))
            end
        end
    end

    say(self.character, "Queued " .. tostring(#queue) .. " upgrade installs.")
    self:gsvu4ClearUpgradeBatchSelections()
    self:close()
end

function VehicleArmorWindow:onGSVU4RepairUpgradeClick()
    if self.gsvu4UpgradeBatchMode ~= "repair" then
        if not self:gsvu4BeginUpgradeRepairSelection() then
            say(self.character, "No damaged upgrades available.")
            return
        end
        say(self.character, "Select upgrades to repair, then click Repair Selected.")
        return
    end

    local queue = self:gsvu4BuildSelectedRepairUpgradeQueue()
    if #queue <= 0 then
        say(self.character, "No selected upgrades can be repaired.")
        return
    end

    for _, data in ipairs(queue) do
        if data.upgradeId == "TyreChains" then
            local current = getInstalledUpgrade(self.vehicle, "TyreChains")
            local condition = getInstalledHealth(current)
            queueTyreChainAction(self.character, self.vehicle, condition <= 50 and "RepairHeavy" or "RepairLight")
        else
            sendUpgradeCommand(self, "RepairUpgrade", data.upgradeId)
        end
    end

    say(self.character, "Queued " .. tostring(#queue) .. " upgrade repairs.")
    self:gsvu4ClearUpgradeBatchSelections()
    self:close()
end

function VehicleArmorWindow:onGSVU4RemoveUpgradeClick()
    if self.gsvu4UpgradeBatchMode ~= "remove" then
        if not self:gsvu4BeginUpgradeRemoveSelection() then
            say(self.character, "No removable upgrades available.")
            return
        end
        say(self.character, "Select upgrades to remove, then click Remove Selected.")
        return
    end

    local queue = self:gsvu4BuildSelectedRemoveUpgradeQueue()
    if #queue <= 0 then
        say(self.character, "No selected upgrades can be removed.")
        return
    end

    local queued = 0
    for _, data in ipairs(queue) do
        if data.upgradeId == "TyreChains" then
            queueTyreChainAction(self.character, self.vehicle, "Remove")
            queued = queued + 1
        elseif GSVU4Core
        and GSVU4Core.QueueUpgradeUninstallTimedAction
        and GSVU4Core.QueueUpgradeUninstallTimedAction(self.character, self.vehicle, data.upgradeId) then
            queued = queued + 1
        end
    end

    say(self.character, "Queued " .. tostring(queued) .. " upgrade removals.")
    self:gsvu4ClearUpgradeBatchSelections()
    self:close()
end

function VehicleArmorWindow:onGSVU4ClearUpgradeSelectionClick()
    self:gsvu4ClearUpgradeBatchSelections()
end

local function updateUpgradeButtons(window)
    if not window or not window.gsvu4InstallUpgradeButton then return end
    if not isUpgradesMode(window) then return end

    ensureUpgradeSelectionTables(window)

    local installQueue = window:gsvu4BuildSelectedInstallUpgradeQueue()
    local repairQueue = window:gsvu4BuildSelectedRepairUpgradeQueue()
    local removeQueue = window:gsvu4BuildSelectedRemoveUpgradeQueue()

    if window.gsvu4UpgradeBatchMode == "install" then
        local selected = selectedCount(window.gsvu4UpgradeInstallSelected)
        setButtonTitle(window.gsvu4InstallUpgradeButton, "Install Batch (" .. tostring(#installQueue) .. "/" .. tostring(selected) .. ")")
        window.gsvu4InstallUpgradeButton:setEnable(selected > 0)
        setButtonTitle(window.gsvu4RepairUpgradeButton, "Select Repair")
        setButtonTitle(window.gsvu4RemoveUpgradeButton, "Select Remove")
        if window.gsvu4RepairUpgradeButton then window.gsvu4RepairUpgradeButton:setEnable(false) end
        if window.gsvu4RemoveUpgradeButton then window.gsvu4RemoveUpgradeButton:setEnable(false) end
    elseif window.gsvu4UpgradeBatchMode == "repair" then
        local selected = selectedCount(window.gsvu4UpgradeRepairSelected)
        setButtonTitle(window.gsvu4RepairUpgradeButton, "Repair Batch (" .. tostring(#repairQueue) .. "/" .. tostring(selected) .. ")")
        window.gsvu4RepairUpgradeButton:setEnable(selected > 0)
        setButtonTitle(window.gsvu4InstallUpgradeButton, "Select Install")
        setButtonTitle(window.gsvu4RemoveUpgradeButton, "Select Remove")
        if window.gsvu4InstallUpgradeButton then window.gsvu4InstallUpgradeButton:setEnable(false) end
        if window.gsvu4RemoveUpgradeButton then window.gsvu4RemoveUpgradeButton:setEnable(false) end
    elseif window.gsvu4UpgradeBatchMode == "remove" then
        local selected = selectedCount(window.gsvu4UpgradeRemoveSelected)
        setButtonTitle(window.gsvu4RemoveUpgradeButton, "Remove Batch (" .. tostring(#removeQueue) .. "/" .. tostring(selected) .. ")")
        window.gsvu4RemoveUpgradeButton:setEnable(selected > 0)
        setButtonTitle(window.gsvu4InstallUpgradeButton, "Select Install")
        setButtonTitle(window.gsvu4RepairUpgradeButton, "Select Repair")
        if window.gsvu4InstallUpgradeButton then window.gsvu4InstallUpgradeButton:setEnable(false) end
        if window.gsvu4RepairUpgradeButton then window.gsvu4RepairUpgradeButton:setEnable(false) end
    else
        local installable, repairable, removable = 0, 0, 0
        for _, data in ipairs(orderUpgradeRows(window)) do
            if window:gsvu4IsUpgradeInstallCandidate(data) then installable = installable + 1 end
            if window:gsvu4IsUpgradeRepairCandidate(data) then repairable = repairable + 1 end
            if window:gsvu4IsUpgradeRemoveCandidate(data) then removable = removable + 1 end
        end
        -- Idle selector buttons should not show candidate counts. Counts only appear
        -- after the player enters selection mode and actively chooses rows.
        setButtonTitle(window.gsvu4InstallUpgradeButton, "Select Install")
        setButtonTitle(window.gsvu4RepairUpgradeButton, "Select Repair")
        setButtonTitle(window.gsvu4RemoveUpgradeButton, "Select Remove")
        window.gsvu4InstallUpgradeButton:setEnable(installable > 0)
        window.gsvu4RepairUpgradeButton:setEnable(repairable > 0)
        window.gsvu4RemoveUpgradeButton:setEnable(removable > 0)
    end

    if window.gsvu4ClearUpgradeSelectionButton then
        local count = 0
        if window.gsvu4UpgradeBatchMode == "install" then count = selectedCount(window.gsvu4UpgradeInstallSelected)
        elseif window.gsvu4UpgradeBatchMode == "repair" then count = selectedCount(window.gsvu4UpgradeRepairSelected)
        elseif window.gsvu4UpgradeBatchMode == "remove" then count = selectedCount(window.gsvu4UpgradeRemoveSelected) end
        setButtonTitle(window.gsvu4ClearUpgradeSelectionButton, count > 0 and ("Clear (" .. tostring(count) .. ")") or "Clear")
        window.gsvu4ClearUpgradeSelectionButton:setEnable(window.gsvu4UpgradeBatchMode ~= nil and count > 0)
    end
end

local function installCreateChildrenPatch()
    if VehicleArmorWindow.GSVU4_UpgradeBatchCreateWrapped then return end
    local oldCreateChildren = VehicleArmorWindow.createChildren
    function VehicleArmorWindow:createChildren()
        if oldCreateChildren then oldCreateChildren(self) end
        ensureUpgradeSelectionTables(self)

        local btnH = math.max(30, getTextH(UIFont.Small) + 14)
        local bottomY = self.height - btnH - 8
        local btnW = 150
        local gap = 10
        local actionX = self.width - ((btnW * 3) + (gap * 2)) - 10

        -- Retitle the existing upgrade buttons to match the armour batch workflow.
        setButtonTitle(self.gsvu4InstallUpgradeButton, "Select Install")
        setButtonTitle(self.gsvu4RepairUpgradeButton, "Select Repair")
        setButtonTitle(self.gsvu4RemoveUpgradeButton, "Select Remove")

        self.gsvu4ClearUpgradeSelectionButton = ISButton:new(actionX - btnW - gap, bottomY, btnW, btnH, "Clear", self, function()
            self:onGSVU4ClearUpgradeSelectionClick()
        end)
        self.gsvu4ClearUpgradeSelectionButton:initialise()
        self:addChild(self.gsvu4ClearUpgradeSelectionButton)


        if self.gsvu4UpgradeList then
            local window = self
            self.gsvu4UpgradeList.onmousedown = function()
                local list = window.gsvu4UpgradeList
                local row = list and list.selected or nil
                if row and row > 0 and list.items and list.items[row] then
                    local data = list.items[row].item
                    window.gsvu4SelectedUpgrade = data
                    if window.gsvu4UpgradeBatchMode then window:gsvu4ToggleUpgradeBatchSelection(data) end
                end
            end

            self.gsvu4UpgradeList.doDrawItem = function(list, y, item, alt)
                if not item then return y + list.itemheight end
                if item.index and list.selected == item.index then
                    list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55)
                elseif alt then
                    list:drawRect(0, y, list.width, list.itemheight, 0.12, 0.08, 0.08, 0.08)
                end
                local data = item.item
                local label = item.text or getRowLabel(data)
                local prefix = ""
                if data and window.gsvu4UpgradeBatchMode == "install" then
                    if window:gsvu4IsUpgradeInstallCandidate(data) then
                        prefix = (window.gsvu4UpgradeInstallSelected and window.gsvu4UpgradeInstallSelected[data.upgradeId] == data.grade) and "[x] " or "[ ] "
                    else prefix = "    " end
                elseif data and window.gsvu4UpgradeBatchMode == "repair" then
                    if window:gsvu4IsUpgradeRepairCandidate(data) then
                        prefix = (window.gsvu4UpgradeRepairSelected and window.gsvu4UpgradeRepairSelected[keyForUpgrade(data.upgradeId, data.grade)]) and "[x] " or "[ ] "
                    else prefix = "    " end
                elseif data and window.gsvu4UpgradeBatchMode == "remove" then
                    if window:gsvu4IsUpgradeRemoveCandidate(data) then
                        prefix = (window.gsvu4UpgradeRemoveSelected and window.gsvu4UpgradeRemoveSelected[keyForUpgrade(data.upgradeId, data.grade)]) and "[x] " or "[ ] "
                    else prefix = "    " end
                end

                local installedForType = data and data.upgradeId and getInstalledUpgrade(window.vehicle, data.upgradeId) or nil
                local isInstalled = installedForType and tostring(installedForType.grade or "") == tostring(data and data.grade or "")
                local r, g, b = 0.75, 0.75, 0.75
                if isUpgradeBlocked(window, data and data.upgradeId) then
                    r, g, b = 0.90, 0.68, 0.35
                    if string.find(label, "PZK", 1, true) == nil then label = label .. " [PZK/SVU3]" end
                elseif isInstalled then
                    r, g, b = 0.30, 0.85, 0.35
                end
                list:drawText(prefix .. tostring(label), 8, y + 4, r, g, b, 1, list.font or UIFont.Small)
                return y + list.itemheight
            end
        end
    end
    VehicleArmorWindow.GSVU4_UpgradeBatchCreateWrapped = true
end

local function installPrerenderPatch()
    if VehicleArmorWindow.GSVU4_UpgradeBatchPrerenderWrapped then return end
    local oldPrerender = VehicleArmorWindow.prerender
    function VehicleArmorWindow:prerender(...)
        if oldPrerender then oldPrerender(self, ...) end

        local upgrades = isUpgradesMode(self)
        setVisible(self.gsvu4ClearUpgradeSelectionButton, upgrades)

        if upgrades then
            updateUpgradeButtons(self)
        end
    end
    VehicleArmorWindow.GSVU4_UpgradeBatchPrerenderWrapped = true
end

installCreateChildrenPatch()
installPrerenderPatch()
