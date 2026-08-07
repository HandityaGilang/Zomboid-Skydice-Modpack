--========================================================
-- Gore's SVU4 Core - Batch Repair / Remove UI Patch
-- Phase 1Z
--
-- Adds:
-- - normal time estimates instead of "action units"
-- - multi-select repair batch
-- - multi-select remove/uninstall batch
-- - shorter balanced bottom button labels
--
-- Separate patch file. VehicleArmor_UI.lua is not edited.
--========================================================

if not VehicleArmorWindow then
    return
end


local GRADE_LABEL = {
    Scrap = "Scrap Armor",
    Standard = "Standard Armor",
    Reinforced = "Reinforced Armor",
    Apocalypse = "Apocalypse Armor",
}

local GRADE_SHORT = {
    Scrap = "Sc",
    Standard = "St",
    Reinforced = "Re",
    Apocalypse = "Ap",
}

local MAT_LABEL = {
    scrap    = "Scrap Pieces",
    sheets   = "Steel Sheets",
    bars     = "Metal Bars",
    screws   = "Screws",
    wire     = "Wire",
    carScrap = "Car Scrap",
    rods     = "Welding Rods",
}

local MAT_ORDER = {
    "scrap",
    "sheets",
    "bars",
    "screws",
    "wire",
    "carScrap",
    "rods",
}

local function gradeLabel(grade)
    return GRADE_LABEL[tostring(grade or "")] or tostring(grade or "Armor")
end

local function gradeShort(grade)
    return GRADE_SHORT[tostring(grade or "")] or "?"
end

local function getArmorGrade(armor)
    if not armor then return nil end
    return armor.grade or armor.Grade or armor.armorGrade or armor.type or armor[1]
end

local function fmtNum(value)
    value = tonumber(value or 0) or 0
    if math.abs(value - math.floor(value + 0.0001)) < 0.001 then
        return tostring(math.floor(value + 0.0001))
    end
    return string.format("%.1f", value)
end

local function formatActionTime(units)
    units = tonumber(units or 0) or 0
    if units <= 0 then return "about 0 sec" end

    -- Project Zomboid timed actions use arbitrary action ticks.
    -- For player display, this presents an easy approximate real-time value.
    local seconds = math.max(1, math.floor((units / 60) + 0.5))

    if seconds < 60 then
        return "about " .. tostring(seconds) .. " sec"
    end

    local minutes = math.floor(seconds / 60)
    local rem = seconds - (minutes * 60)

    if rem <= 0 then
        return "about " .. tostring(minutes) .. " min"
    end

    return "about " .. tostring(minutes) .. " min " .. tostring(rem) .. " sec"
end

local function enoughColour(have, need)
    if (tonumber(have or 0) or 0) + 0.0001 >= (tonumber(need or 0) or 0) then
        return 0.30, 0.85, 0.30
    end
    return 0.90, 0.30, 0.25
end

local function safeGasTankPart(partId)
    if GAA_IsGasTankPart then
        local ok, result = pcall(GAA_IsGasTankPart, partId)
        if ok then return result == true end
    end
    return tostring(partId or "") == "GasTank"
end

local function armorHealthColor(health)
    if GAA_GetArmorHealthColor then
        local ok, c = pcall(GAA_GetArmorHealthColor, health)
        if ok and c then return c end
    end

    local h = tonumber(health or 0) or 0
    if h <= 25 then return { r = 0.95, g = 0.25, b = 0.20 } end
    if h <= 60 then return { r = 0.95, g = 0.75, b = 0.25 } end
    return { r = 0.45, g = 0.95, b = 0.45 }
end

local function gasLeakColor()
    if GAA_GetGasLeakColor then
        local ok, c = pcall(GAA_GetGasLeakColor)
        if ok and c then return c end
    end
    return { r = 0.35, g = 0.75, b = 1.0 }
end

local function copyBudget(report)
    report = report or {}
    return {
        scrap      = tonumber(report.scrap or 0) or 0,
        sheets     = tonumber(report.sheets or 0) or 0,
        bars       = tonumber(report.bars or 0) or 0,
        screws     = tonumber(report.screws or 0) or 0,
        wire       = tonumber(report.wire or 0) or 0,
        carScrap   = tonumber(report.carScrap or 0) or 0,
        rods       = tonumber(report.rods or 0) or 0,
        torchUnits = tonumber(report.torchUnits or 0) or 0,
    }
end

local function canAffordRecipe(budget, recipe)
    if not budget or not recipe then return false end

    for mat, req in pairs(recipe) do
        if (budget[mat] or 0) + 0.0001 < (tonumber(req) or 0) then
            return false
        end
    end

    return true
end

local function reserveRecipe(budget, recipe)
    if not budget or not recipe then return end

    for mat, req in pairs(recipe) do
        budget[mat] = (budget[mat] or 0) - (tonumber(req) or 0)
    end
end

local function setButtonTitle(button, title)
    if button and button.setTitle then
        button:setTitle(title)
    end
end

local function selectedCount(map)
    local count = 0
    if not map then return 0 end

    for _, selected in pairs(map) do
        if selected then count = count + 1 end
    end

    return count
end

function VehicleArmorWindow:gsvu4ClearBatchSelections(exitMode)
    self.installSelectedParts = {}
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}

    if exitMode ~= false then
        self.gsvu4BatchMode = nil
        self.installSelectMode = false
    end

    self.reportDirty = true
end

local oldClearInstallSelectionForBatch = VehicleArmorWindow.clearInstallSelection
function VehicleArmorWindow:clearInstallSelection(markDirty)
    if oldClearInstallSelectionForBatch then
        oldClearInstallSelectionForBatch(self, false)
    end

    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}
    self.gsvu4BatchMode = nil

    if markDirty ~= false then
        self.reportDirty = true
    end
end

local oldBeginInstallSelectionForBatch = VehicleArmorWindow.beginInstallSelection
function VehicleArmorWindow:beginInstallSelection(report)
    self.repairSelectedParts = {}
    self.uninstallSelectedParts = {}

    local result = false
    if oldBeginInstallSelectionForBatch then
        result = oldBeginInstallSelectionForBatch(self, report)
    end

    if result then
        self.gsvu4BatchMode = "install"
        self.installSelectMode = true
    end

    return result
end

function VehicleArmorWindow:isRepairSelectionCandidate(partId)
    if not partId or not self.vehicle then return false end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor and vdata.gArmor[partId]

    return armor ~= nil and (tonumber(armor.health) or 100) < 100
end

function VehicleArmorWindow:isRemoveSelectionCandidate(partId)
    if not partId or not self.vehicle then return false end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor and vdata.gArmor[partId]

    return armor ~= nil
end

local oldToggleInstallSelectionForBatch = VehicleArmorWindow.toggleInstallSelection
function VehicleArmorWindow:toggleInstallSelection(rowItem)
    if not rowItem then return end
    local partId = rowItem.partId
    if not partId then return end

    if self.gsvu4BatchMode == "repair" then
        if not self:isRepairSelectionCandidate(partId) then return end

        self.repairSelectedParts = self.repairSelectedParts or {}
        self.repairSelectedParts[partId] = not self.repairSelectedParts[partId]
        self.reportDirty = true
        return
    end

    if self.gsvu4BatchMode == "uninstall" then
        if not self:isRemoveSelectionCandidate(partId) then return end

        self.uninstallSelectedParts = self.uninstallSelectedParts or {}
        self.uninstallSelectedParts[partId] = not self.uninstallSelectedParts[partId]
        self.reportDirty = true

        if self.updateBulkButtons then
            self:updateBulkButtons(self.cachedReport or self:getRecipeReport())
        end
        return
    end

    if oldToggleInstallSelectionForBatch then
        oldToggleInstallSelectionForBatch(self, rowItem)
    end
end

local function orderSelectedPartsByList(window, selectedMap)
    local ordered = {}
    local seen = {}

    if window and window.partList and window.partList.items then
        for _, row in ipairs(window.partList.items) do
            local item = row and row.item
            local partId = item and item.partId
            if partId and selectedMap and selectedMap[partId] then
                table.insert(ordered, partId)
                seen[partId] = true
            end
        end
    end

    if selectedMap then
        for partId, selected in pairs(selectedMap) do
            if selected and not seen[partId] then
                table.insert(ordered, partId)
            end
        end
    end

    return ordered
end

function VehicleArmorWindow:beginRepairSelection(report)
    report = report or self.cachedReport or self:getRecipeReport()

    local queue = self:getRepairAllQueue(report)
    if #queue <= 0 then
        return false
    end

    self:gsvu4ClearBatchSelections(false)
    self.gsvu4BatchMode = "repair"
    self.installSelectMode = true
    self.repairSelectedParts = {}

    for _, partId in ipairs(queue) do
        self.repairSelectedParts[partId] = true
    end

    self.reportDirty = true
    return true
end

function VehicleArmorWindow:getSelectedRepairQueue(report)
    local queue = {}

    if not self.vehicle or not report then return queue end
    if not report.hasHammer or not report.hasMask then return queue end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if not armorData then return queue end

    local budget = copyBudget(report)

    for _, partId in ipairs(orderSelectedPartsByList(self, self.repairSelectedParts)) do
        local armor = armorData[partId]

        if armor and (tonumber(armor.health) or 100) < 100 then
            local grade = getArmorGrade(armor) or "Scrap"
            local fuelUse = 1
            if VehicleArmorConfig
            and VehicleArmorConfig.FuelUse
            and VehicleArmorConfig.FuelUse.Repair
            and VehicleArmorConfig.FuelUse.Repair[grade]
            then
                fuelUse = tonumber(VehicleArmorConfig.FuelUse.Repair[grade]) or 1
            end

            local recipe = self:getRepairRecipeForPart(partId, armor)
            local canQueue = recipe ~= nil and (budget.torchUnits or 0) + 0.0001 >= fuelUse

            if canQueue and canAffordRecipe(budget, recipe) then
                table.insert(queue, partId)
                budget.torchUnits = (budget.torchUnits or 0) - fuelUse
                reserveRecipe(budget, recipe)
            end
        end
    end

    return queue
end

function VehicleArmorWindow:beginRemoveSelection(report)
    report = report or self.cachedReport or self:getRecipeReport()

    local queue = self:getUninstallAllQueue(report)
    if #queue <= 0 then
        return false
    end

    self:gsvu4ClearBatchSelections(false)
    self.gsvu4BatchMode = "uninstall"
    self.installSelectMode = true
    self.uninstallSelectedParts = {}

    for _, partId in ipairs(queue) do
        self.uninstallSelectedParts[partId] = true
    end

    self.pendingUninstallAll = false
    self.reportDirty = true
    return true
end

function VehicleArmorWindow:getSelectedUninstallQueue(report)
    local queue = {}

    if not self.vehicle or not report then return queue end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if not armorData then return queue end

    local availableFuel = tonumber(report.torchUnits or 0) or 0

    for _, partId in ipairs(orderSelectedPartsByList(self, self.uninstallSelectedParts)) do
        local armor = armorData[partId]

        if armor then
            local grade = getArmorGrade(armor) or "Scrap"
            local fuelUse = 1

            if VehicleArmorConfig
            and VehicleArmorConfig.FuelUse
            and VehicleArmorConfig.FuelUse.Uninstall
            and VehicleArmorConfig.FuelUse.Uninstall[grade]
            then
                fuelUse = tonumber(VehicleArmorConfig.FuelUse.Uninstall[grade]) or 1
            end

            if availableFuel + 0.0001 >= fuelUse then
                table.insert(queue, partId)
                availableFuel = availableFuel - fuelUse
            end
        end
    end

    return queue
end

function VehicleArmorWindow:getSelectedRepairTotals(report)
    local totals = {
        selected = selectedCount(self.repairSelectedParts),
        repairable = 0,
        time = 0,
        fuel = 0,
        mats = {},
    }

    if not self.vehicle then return totals end
    report = report or self.cachedReport or self:getRecipeReport()

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if not armorData then return totals end

    local queue = self:getSelectedRepairQueue(report)
    totals.repairable = #queue

    for _, partId in ipairs(orderSelectedPartsByList(self, self.repairSelectedParts)) do
        local armor = armorData[partId]

        if armor and (tonumber(armor.health) or 100) < 100 then
            local grade = getArmorGrade(armor) or "Scrap"
            local recipe = self:getRepairRecipeForPart(partId, armor)

            if recipe then
                for mat, req in pairs(recipe) do
                    totals.mats[mat] = (totals.mats[mat] or 0) + (tonumber(req) or 0)
                end
            end

            local fuelUse = 1
            if VehicleArmorConfig
            and VehicleArmorConfig.FuelUse
            and VehicleArmorConfig.FuelUse.Repair
            and VehicleArmorConfig.FuelUse.Repair[grade]
            then
                fuelUse = tonumber(VehicleArmorConfig.FuelUse.Repair[grade]) or 1
            end
            totals.fuel = totals.fuel + fuelUse

            local baseTime = VehicleArmorConfig and VehicleArmorConfig.Time and VehicleArmorConfig.Time[grade] or 250
            local missingHP = math.max(0, 100 - (tonumber(armor.health) or 0))
            totals.time = totals.time + math.max(50, math.floor((tonumber(baseTime) or 250) * (missingHP / 100)))
        end
    end

    return totals
end

function VehicleArmorWindow:getSelectedUninstallTotals(report)
    local totals = {
        selected = selectedCount(self.uninstallSelectedParts),
        removable = 0,
        time = 0,
        fuel = 0,
    }

    if not self.vehicle then return totals end
    report = report or self.cachedReport or self:getRecipeReport()

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if not armorData then return totals end

    local queue = self:getSelectedUninstallQueue(report)
    totals.removable = #queue

    for _, partId in ipairs(orderSelectedPartsByList(self, self.uninstallSelectedParts)) do
        local armor = armorData[partId]

        if armor then
            local grade = getArmorGrade(armor) or "Scrap"

            local fuelUse = 1
            if VehicleArmorConfig
            and VehicleArmorConfig.FuelUse
            and VehicleArmorConfig.FuelUse.Uninstall
            and VehicleArmorConfig.FuelUse.Uninstall[grade]
            then
                fuelUse = tonumber(VehicleArmorConfig.FuelUse.Uninstall[grade]) or 1
            end
            totals.fuel = totals.fuel + fuelUse

            local baseTime = VehicleArmorConfig and VehicleArmorConfig.Time and VehicleArmorConfig.Time[grade] or 200
            totals.time = totals.time + (tonumber(baseTime) or 200)
        end
    end

    return totals
end

function VehicleArmorWindow:onRepairAllButtonClick()
    if not self.vehicle then return end

    local report = self.refreshBulkActionState and self:refreshBulkActionState() or self:getRecipeReport()

    if self.gsvu4BatchMode ~= "repair" then
        if not self:beginRepairSelection(report) then
            self.character:Say("No repairable damaged armor selected.")
            return
        end

        self.character:Say("Select damaged panels to repair, then click Repair Selected.")
        self:updateBulkButtons(report)
        return
    end

    local selected = selectedCount(self.repairSelectedParts)
    local queue = self:getSelectedRepairQueue(report)

    if selected <= 0 then
        self.character:Say("No repair panels selected.")
        return
    end

    if #queue <= 0 then
        self.character:Say("Selected repairs are missing tools or materials.")
        return
    end

    local queued = 0
    for _, partId in ipairs(queue) do
        local action = ISRepairVehicleArmor:new(self.character, self.vehicle, partId)
        local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)

        if action and (inVehicle or not action.isValid or action:isValid()) then
            VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
            queued = queued + 1
        end
    end

    if queued > 0 then
        self.character:Say("Queued " .. tostring(queued) .. " armor repairs.")
        self:gsvu4ClearBatchSelections(true)
        self:close()
    else
        self.character:Say("No selected armor repairs could be queued.")
    end
end

function VehicleArmorWindow:onUninstallAllButtonClick()
    if not self.vehicle then return end

    local report = self.refreshBulkActionState and self:refreshBulkActionState() or self:getRecipeReport()

    if self.gsvu4BatchMode ~= "uninstall" then
        if not self:beginRemoveSelection(report) then
            self.character:Say("No removable armor panels selected.")
            return
        end

        self.character:Say("Select panels to remove, then click Remove Selected.")
        self:updateBulkButtons(report)
        return
    end

    local selected = selectedCount(self.uninstallSelectedParts)
    local queue = self:getSelectedUninstallQueue(report)

    if selected <= 0 then
        self.character:Say("No armor panels selected for removal.")
        return
    end

    if #queue <= 0 then
        self.character:Say("Selected panels cannot be removed with current blowtorch fuel.")
        return
    end

    local queued = 0
    for _, partId in ipairs(queue) do
        local vdata = self.vehicle:getModData()
        local armor = vdata and vdata.gArmor and vdata.gArmor[partId]
        local grade = armor and (getArmorGrade(armor) or "Scrap") or "Scrap"
        local time = VehicleArmorConfig and VehicleArmorConfig.Time and VehicleArmorConfig.Time[grade] or 200

        local action = ISUninstallVehicleArmor:new(self.character, self.vehicle, partId, time)
        local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)

        if action and (inVehicle or not action.isValid or action:isValid()) then
            VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
            queued = queued + 1
        end
    end

    if queued > 0 then
        self.character:Say("Queued " .. tostring(queued) .. " armor removals.")
        self:gsvu4ClearBatchSelections(true)
        self:close()
    else
        self.character:Say("No selected armor removals could be queued.")
    end
end

function VehicleArmorWindow:onClearInstallSelectionButton()
    self:gsvu4ClearBatchSelections(true)

    if self.updateBulkButtons then
        self:updateBulkButtons(self.cachedReport or self:getRecipeReport())
    end
end

local oldUpdateBulkButtonsForBatch = VehicleArmorWindow.updateBulkButtons
function VehicleArmorWindow:updateBulkButtons(report)
    oldUpdateBulkButtonsForBatch(self, report)

    report = report or self.cachedReport or self:getRecipeReport()

    local repairQueue = {}
    if self.getRepairAllQueue then
        local ok, q = pcall(function() return self:getRepairAllQueue(report) end)
        if ok and q then repairQueue = q end
    end

    local removeQueue = {}
    if self.getUninstallAllQueue then
        local ok, q = pcall(function() return self:getUninstallAllQueue(report) end)
        if ok and q then removeQueue = q end
    end

    local installQueue = {}
    if self.getInstallAllQueue then
        local ok, q = pcall(function() return self:getInstallAllQueue(report) end)
        if ok and q then installQueue = q end
    end

    if self.gsvu4BatchMode == "repair" then
        local selected = selectedCount(self.repairSelectedParts)
        local queue = self:getSelectedRepairQueue(report)
        setButtonTitle(self.repairAllButton, "Repair Batch (" .. tostring(#queue) .. "/" .. tostring(selected) .. ")")
        self.repairAllButton:setEnable(#queue > 0)
    else
        setButtonTitle(self.repairAllButton,
            #repairQueue > 0 and ("Select Repair (" .. tostring(#repairQueue) .. ")") or "Select Repair")
        self.repairAllButton:setEnable(#repairQueue > 0)
    end

    if self.gsvu4BatchMode == "uninstall" then
        local selected = selectedCount(self.uninstallSelectedParts)
        local queue = self:getSelectedUninstallQueue(report)
        setButtonTitle(self.uninstallAllButton, "Remove Batch (" .. tostring(#queue) .. "/" .. tostring(selected) .. ")")
        self.uninstallAllButton:setEnable(#queue > 0)
    else
        setButtonTitle(self.uninstallAllButton,
            #removeQueue > 0 and ("Select Remove (" .. tostring(#removeQueue) .. ")") or "Select Remove")
        self.uninstallAllButton:setEnable(#removeQueue > 0)
    end

    if self.gsvu4BatchMode == "install" then
        local selected = 0
        local queue = {}
        if self.getSelectedInstallCount then
            local ok, count = pcall(function() return self:getSelectedInstallCount() end)
            if ok then selected = count or 0 end
        end
        if self.getSelectedInstallQueue then
            local ok, q = pcall(function() return self:getSelectedInstallQueue(report) end)
            if ok and q then queue = q end
        end
        setButtonTitle(self.installAllButton, "Install Batch (" .. tostring(#queue) .. "/" .. tostring(selected) .. ")")
        self.installAllButton:setEnable(#queue > 0)
    else
        setButtonTitle(self.installAllButton,
            #installQueue > 0 and ("Select Install (" .. tostring(#installQueue) .. ")") or "Select Install")
        self.installAllButton:setEnable(#installQueue > 0)
    end

    setButtonTitle(self.repairButton, "Repair Selected")

    if self.actionButton then
        if self.selectedPart and self.vehicle then
            local vdata = self.vehicle:getModData()
            local armor = vdata and vdata.gArmor and vdata.gArmor[self.selectedPart.partId]
            if armor then
                if self.pendingUninstallPartId == self.selectedPart.partId then
                    setButtonTitle(self.actionButton, "Confirm Remove")
                else
                    setButtonTitle(self.actionButton, "Remove Selected")
                end
            elseif report and report.canCraft then
                setButtonTitle(self.actionButton, "Install Selected")
            else
                setButtonTitle(self.actionButton, "Blocked")
            end
        else
            setButtonTitle(self.actionButton, "Select Panel")
        end
    end

    if self.clearSelectionButton then
        local count = 0
        if self.gsvu4BatchMode == "repair" then
            count = selectedCount(self.repairSelectedParts)
        elseif self.gsvu4BatchMode == "uninstall" then
            count = selectedCount(self.uninstallSelectedParts)
        elseif self.gsvu4BatchMode == "install" and self.getSelectedInstallCount then
            local ok, c = pcall(function() return self:getSelectedInstallCount() end)
            if ok then count = c or 0 end
        end

        setButtonTitle(self.clearSelectionButton, count > 0 and ("Clear (" .. tostring(count) .. ")") or "Clear")
        self.clearSelectionButton:setEnable(self.gsvu4BatchMode ~= nil and count > 0)
    end
end

local function drawPanelBase(window)
    if not window.detailBox then return nil end

    local x = window.detailBox:getX()
    local y = window.detailBox:getY()
    local w = window.detailBox:getWidth()
    local h = window.detailBox:getHeight()

    window:drawRect(x, y, w, h, 0.96, 0.02, 0.02, 0.02)
    window:drawRectBorder(x, y, w, h, 0.95, 0.55, 0.55, 0.55)

    return x + 14, y + 12, w - 28, h - 24
end

local function drawMaterialTotals(window, report, totals, dx, dy)
    window:drawText("MATERIAL TOTALS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local anyMat = false
    for _, mat in ipairs(MAT_ORDER) do
        local need = totals.mats and totals.mats[mat] or 0
        if need and need > 0 then
            anyMat = true
            local have = report and tonumber(report[mat] or 0) or 0
            local r, g, b = enoughColour(have, need)
            window:drawText((MAT_LABEL[mat] or mat) .. ": " .. fmtNum(have) .. " / " .. fmtNum(need),
                dx + 8, dy, r, g, b, 1, UIFont.Small)
            dy = dy + 15
        end
    end

    if not anyMat then
        window:drawText("No material requirements.", dx + 8, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        dy = dy + 15
    end

    return dy
end

function VehicleArmorWindow:drawRepairBatchPanel()
    local report = self.cachedReport or self:getRecipeReport()
    local totals = self:getSelectedRepairTotals(report)
    local dx, dy = drawPanelBase(self)
    if not dx then return end

    self:drawText("SELECTED REPAIR REQUIREMENTS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 18

    if totals.selected <= 0 then
        self:drawText("No damaged panels selected.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        return
    end

    self:drawText("Panels: " .. tostring(totals.repairable) .. " repairable / " .. tostring(totals.selected) .. " selected",
        dx, dy, 0.70, 0.82, 1.00, 1, UIFont.Small)
    dy = dy + 16

    self:drawText("Estimated Repair Time: " .. formatActionTime(totals.time),
        dx, dy, 0.78, 0.88, 1.00, 1, UIFont.Small)
    dy = dy + 20

    self:drawText("TOOLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local hammerOk = report and report.hasHammer
    local maskOk = report and report.hasMask
    self:drawText((hammerOk and "[OK] " or "[NEED] ") .. "Hammer",
        dx + 8, dy, hammerOk and 0.30 or 0.90, hammerOk and 0.85 or 0.30, hammerOk and 0.30 or 0.25, 1, UIFont.Small)
    dy = dy + 15
    self:drawText((maskOk and "[OK] " or "[NEED] ") .. "Welding Mask",
        dx + 8, dy, maskOk and 0.30 or 0.90, maskOk and 0.85 or 0.30, maskOk and 0.30 or 0.25, 1, UIFont.Small)
    dy = dy + 15

    local fuelHave = report and tonumber(report.torchUnits or 0) or 0
    local fr, fg, fb = enoughColour(fuelHave, totals.fuel)
    self:drawText("Blowtorch Fuel: " .. fmtNum(fuelHave) .. " / " .. fmtNum(totals.fuel) .. " units",
        dx + 8, dy, fr, fg, fb, 1, UIFont.Small)
    dy = dy + 20

    dy = drawMaterialTotals(self, report, totals, dx, dy)

    if totals.repairable >= totals.selected and hammerOk and maskOk then
        self:drawText("READY: Selected repairs can be queued.", dx, dy + 4, 0.30, 0.85, 0.30, 1, UIFont.Small)
    else
        self:drawText("MISSING / BLOCKED: Some selected repairs cannot be queued.", dx, dy + 4, 0.95, 0.45, 0.35, 1, UIFont.Small)
    end
end

function VehicleArmorWindow:drawRemoveBatchPanel()
    local report = self.cachedReport or self:getRecipeReport()
    local totals = self:getSelectedUninstallTotals(report)
    local dx, dy = drawPanelBase(self)
    if not dx then return end

    self:drawText("SELECTED REMOVE REQUIREMENTS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 18

    if totals.selected <= 0 then
        self:drawText("No armour panels selected for removal.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        return
    end

    self:drawText("Panels: " .. tostring(totals.removable) .. " removable / " .. tostring(totals.selected) .. " selected",
        dx, dy, 0.70, 0.82, 1.00, 1, UIFont.Small)
    dy = dy + 16

    self:drawText("Estimated Remove Time: " .. formatActionTime(totals.time),
        dx, dy, 0.78, 0.88, 1.00, 1, UIFont.Small)
    dy = dy + 20

    local fuelHave = report and tonumber(report.torchUnits or 0) or 0
    local fr, fg, fb = enoughColour(fuelHave, totals.fuel)

    self:drawText("TOOLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16
    self:drawText("Blowtorch Fuel: " .. fmtNum(fuelHave) .. " / " .. fmtNum(totals.fuel) .. " units",
        dx + 8, dy, fr, fg, fb, 1, UIFont.Small)
    dy = dy + 20

    self:drawText("No material items are required to remove panels.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
    dy = dy + 20

    if totals.removable >= totals.selected then
        self:drawText("READY: Selected panels can be removed.", dx, dy, 0.30, 0.85, 0.30, 1, UIFont.Small)
    else
        self:drawText("MISSING / BLOCKED: Need more blowtorch fuel.", dx, dy, 0.95, 0.45, 0.35, 1, UIFont.Small)
    end
end

local oldDrawSelectedInstallTotalsPanelForBatch = VehicleArmorWindow.drawSelectedInstallTotalsPanel
function VehicleArmorWindow:drawSelectedInstallTotalsPanel()
    if not self.installSelectMode then return end

    if self.gsvu4BatchMode == "repair" then
        self:drawRepairBatchPanel()
        return
    end

    if self.gsvu4BatchMode == "uninstall" then
        self:drawRemoveBatchPanel()
        return
    end

    if self.gsvu4BatchMode ~= "install" then
        if oldDrawSelectedInstallTotalsPanelForBatch then
            oldDrawSelectedInstallTotalsPanelForBatch(self)
        end
        return
    end

    local report = self.cachedReport or self:getRecipeReport()
    local totals = self:getGSVU4SelectedBatchTotals(report)
    local missingLines = self:getGSVU4SelectedBatchMissingLines(report, totals)
    local dx, dy = drawPanelBase(self)
    if not dx then return end

    self:drawText("SELECTED INSTALL REQUIREMENTS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 18

    if (totals.selected or 0) <= 0 then
        self:drawText("No panels selected.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        self:drawText("Click rows in the selector list to build a batch.",
            dx, dy + 18, 0.62, 0.72, 0.90, 1, UIFont.Small)
        return
    end

    self:drawText("Panels: " .. tostring(totals.affordable or 0) .. " installable / "
        .. tostring(totals.valid or 0) .. " selected",
        dx, dy, 0.70, 0.82, 1.00, 1, UIFont.Small)
    dy = dy + 16

    local gradeLine = "Grades: "
        .. "Sc " .. tostring(totals.grades.Scrap or 0)
        .. " | St " .. tostring(totals.grades.Standard or 0)
        .. " | Re " .. tostring(totals.grades.Reinforced or 0)
        .. " | Ap " .. tostring(totals.grades.Apocalypse or 0)
    self:drawText(gradeLine, dx, dy, 0.82, 0.82, 0.82, 1, UIFont.Small)
    dy = dy + 16

    self:drawText("Estimated Install Time: " .. formatActionTime(totals.time or 0),
        dx, dy, 0.78, 0.88, 1.00, 1, UIFont.Small)
    dy = dy + 20

    self:drawText("TOOLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local function installToolLine(label, ok)
        self:drawText((ok and "[OK] " or "[NEED] ") .. label,
            dx + 8, dy, ok and 0.30 or 0.90, ok and 0.85 or 0.30, ok and 0.30 or 0.25, 1, UIFont.Small)
        dy = dy + 15
    end

    local toolReq = totals.tools or {}
    if toolReq.hammer then installToolLine("Hammer", report and report.hasHammer) end
    if toolReq.screwdriver then installToolLine("Screwdriver", report and report.hasScrewdriver) end
    if toolReq.weldingMask then installToolLine("Welding Mask", report and report.hasMask) end

    local torchHave = report and tonumber(report.torchUnits or 0) or 0
    local torchNeed = tonumber(totals.fuel or 0) or 0
    if torchNeed > 0 then
        local tr, tg, tb = enoughColour(torchHave, torchNeed)
        self:drawText("Blowtorch Fuel: " .. fmtNum(torchHave) .. " / " .. fmtNum(torchNeed) .. " units",
            dx + 8, dy, tr, tg, tb, 1, UIFont.Small)
        dy = dy + 15
    end
    dy = dy + 5

    dy = drawMaterialTotals(self, report, totals, dx, dy)

    if #missingLines <= 0 then
        self:drawText("READY: Selected panels can be installed.", dx, dy + 4, 0.30, 0.85, 0.30, 1, UIFont.Small)
    else
        self:drawText("MISSING / BLOCKED:", dx, dy + 4, 1, 0.72, 0.35, 1, UIFont.Small)
        dy = dy + 20

        local maxLines = 4
        for i, line in ipairs(missingLines) do
            if i > maxLines then
                self:drawText("...and " .. tostring(#missingLines - maxLines) .. " more.",
                    dx + 8, dy, 0.95, 0.55, 0.25, 1, UIFont.Small)
                break
            end
            self:drawText("- " .. tostring(line), dx + 8, dy, 0.95, 0.45, 0.35, 1, UIFont.Small)
            dy = dy + 15
        end
    end
end

local oldCreateChildrenForBatch = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    oldCreateChildrenForBatch(self)

    if self.clearSelectionButton then
        setButtonTitle(self.clearSelectionButton, "Clear")
    end

    if self.partList then
        local armorWindow = self

        self.partList.doDrawItem = function(list, y, item, alt)
            if not item then
                return y + list.itemheight
            end

            local rowData = item.item

            if rowData and rowData.header then
                if item.index and list.selected == item.index then
                    list:drawRect(0, y, list.width, list.itemheight, 0.18, 0.20, 0.25, 0.45)
                else
                    list:drawRect(0, y, list.width, list.itemheight, 0.20, 0.08, 0.08, 0.08)
                end

                list:drawText(item.text or rowData.name or "", 8, y + 3, 0.85, 0.85, 0.85, 1, list.font or UIFont.Small)
                return y + list.itemheight
            end

            local partId = rowData and rowData.partId
            local label = item.text or (rowData and rowData.name) or ""

            local armor = nil
            local leaking = false

            if armorWindow.vehicle and partId then
                local vdata = armorWindow.vehicle:getModData()
                armor = vdata
                    and vdata.gArmor
                    and vdata.gArmor[partId]

                leaking = vdata
                    and vdata.gArmorGasLeak == true
                    and safeGasTankPart(partId)
            end

            if armor then
                local installedGrade = getArmorGrade(armor)
                if installedGrade then
                    label = label .. " (" .. gradeLabel(installedGrade) .. ")"
                else
                    label = label .. " (Armored)"
                end
            end

            if armorWindow.installSelectMode and partId then
                if armorWindow.gsvu4BatchMode == "repair" then
                    if armorWindow:isRepairSelectionCandidate(partId) then
                        label = (armorWindow.repairSelectedParts and armorWindow.repairSelectedParts[partId] and "[x] " or "[ ] ") .. label
                    else
                        label = "    " .. label
                    end
                elseif armorWindow.gsvu4BatchMode == "uninstall" then
                    if armorWindow:isRemoveSelectionCandidate(partId) then
                        label = (armorWindow.uninstallSelectedParts and armorWindow.uninstallSelectedParts[partId] and "[x] " or "[ ] ") .. label
                    else
                        label = "    " .. label
                    end
                else
                    local selectedGrade = armorWindow.installSelectedParts and armorWindow.installSelectedParts[partId] or nil
                    local currentGrade = armorWindow.currentGrade or "Scrap"

                    if armor then
                        label = "    " .. label
                    elseif selectedGrade and selectedGrade == currentGrade then
                        label = "[x " .. gradeShort(selectedGrade) .. "] " .. label
                    elseif selectedGrade then
                        label = "[" .. gradeShort(selectedGrade) .. "] " .. label
                    else
                        label = "[ ] " .. label
                    end
                end
            end

            if item.index and list.selected == item.index then
                list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55)
            elseif alt then
                list:drawRect(0, y, list.width, list.itemheight, 0.12, 0.08, 0.08, 0.08)
            end

            local r, g, b = 0.60, 0.60, 0.60

            if leaking then
                local c = gasLeakColor()
                r, g, b = c.r, c.g, c.b
                label = label .. "  [LEAKING]"
            elseif armor then
                local c = armorHealthColor(armor.health or 0)
                r, g, b = c.r, c.g, c.b
            end

            list:drawText(label, 8, y + 3, r, g, b, 1, list.font or UIFont.Small)
            return y + list.itemheight
        end
    end
end

local oldPrerenderForBatch = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender()
    oldPrerenderForBatch(self)
end
