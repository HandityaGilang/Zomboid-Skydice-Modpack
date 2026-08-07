--========================================================
-- Gore's SVU4 Core - Requirements + Player Naming
-- Adds clearer player-facing labels and selected-batch
-- requirement summaries for the multi-grade selector.
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

local function fmtNum(value)
    value = tonumber(value or 0) or 0

    if math.abs(value - math.floor(value + 0.0001)) < 0.001 then
        return tostring(math.floor(value + 0.0001))
    end

    return string.format("%.1f", value)
end

local function enoughColour(have, need)
    if (tonumber(have or 0) or 0) + 0.0001 >= (tonumber(need or 0) or 0) then
        return 0.30, 0.85, 0.30
    end

    return 0.90, 0.30, 0.25
end

local function setBtnTitle(btn, title)
    if btn and btn.setTitle then
        btn:setTitle(title)
    end
end

local function safeAdjustedRecipe(recipe)
    if recipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
        local ok, adjusted = pcall(VehicleArmorHelpers.getAdjustedRecipe, recipe)
        if ok and adjusted then
            return adjusted
        end
    end

    return recipe
end

local function getSkillForGrade(character, grade)
    if VehicleArmorHelpers and VehicleArmorHelpers.getSkillRequirementReport then
        local ok, report = pcall(VehicleArmorHelpers.getSkillRequirementReport, character, grade)
        if ok and report then
            return report
        end
    end

    local fallback = {
        metalRequired = 0,
        mechRequired = 0,
        metalLevel = 0,
        mechLevel = 0,
        hasSkills = true,
    }

    local req = VehicleArmorConfig
        and VehicleArmorConfig.LevelRequirements
        and VehicleArmorConfig.LevelRequirements[grade]

    if req then
        fallback.metalRequired = tonumber(req.MetalWelding or 0) or 0
        fallback.mechRequired = tonumber(req.Mechanics or 0) or 0
    end

    if VehicleArmorHelpers and VehicleArmorHelpers.getPerkLevel and character then
        if Perks and Perks.MetalWelding then
            fallback.metalLevel = VehicleArmorHelpers.getPerkLevel(character, Perks.MetalWelding)
        end
        if Perks and Perks.Mechanics then
            fallback.mechLevel = VehicleArmorHelpers.getPerkLevel(character, Perks.Mechanics)
        end
    end

    fallback.hasSkills =
        fallback.metalLevel >= fallback.metalRequired
        and fallback.mechLevel >= fallback.mechRequired

    return fallback
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

function VehicleArmorWindow:getGSVU4SelectedBatchTotals(report)
    local totals = {
        selected = 0,
        valid = 0,
        invalid = 0,
        affordable = 0,
        fuel = 0,
        mats = {},
        grades = {
            Scrap = 0,
            Standard = 0,
            Reinforced = 0,
            Apocalypse = 0,
        },
        maxMetalRequired = 0,
        maxMechanicsRequired = 0,
        metalLevel = 0,
        mechanicsLevel = 0,
    }

    if not self.installSelectedParts then
        return totals
    end

    report = report or self.cachedReport or self:getRecipeReport()

    for partId, grade in pairs(self.installSelectedParts) do
        if partId and grade then
            totals.selected = totals.selected + 1

            local valid = true
            if self.isInstallSelectionCandidate then
                valid = self:isInstallSelectionCandidate(partId, grade)
            end

            local recipe = nil
            if valid
            and VehicleArmorConfig
            and VehicleArmorConfig.getInstallRecipe
            then
                recipe = VehicleArmorConfig.getInstallRecipe(partId, grade)
                recipe = safeAdjustedRecipe(recipe)
            end

            if valid and recipe then
                totals.valid = totals.valid + 1

                if totals.grades[grade] ~= nil then
                    totals.grades[grade] = totals.grades[grade] + 1
                end

                for mat, req in pairs(recipe) do
                    totals.mats[mat] = (totals.mats[mat] or 0) + (tonumber(req) or 0)
                end

                local fuelPerPanel = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(partId, grade) or (VehicleArmorConfig.FuelUse.Install[grade] or 0)
                fuelPerPanel = tonumber(fuelPerPanel) or 0

                totals.fuel = totals.fuel + fuelPerPanel

                local sr = getSkillForGrade(self.character, grade)
                totals.maxMetalRequired = math.max(totals.maxMetalRequired, tonumber(sr.metalRequired or 0) or 0)
                totals.maxMechanicsRequired = math.max(totals.maxMechanicsRequired, tonumber(sr.mechRequired or 0) or 0)
                totals.metalLevel = math.max(totals.metalLevel, tonumber(sr.metalLevel or 0) or 0)
                totals.mechanicsLevel = math.max(totals.mechanicsLevel, tonumber(sr.mechLevel or 0) or 0)
            else
                totals.invalid = totals.invalid + 1
            end
        end
    end

    -- Work out how many selected panels are actually affordable together,
    -- using the same queue function as the install button when available.
    if self.getSelectedInstallQueue then
        local ok, queue = pcall(function()
            return self:getSelectedInstallQueue(report)
        end)
        if ok and queue then
            totals.affordable = #queue
        end
    end

    return totals
end

function VehicleArmorWindow:getGSVU4SelectedBatchMissingLines(report, totals)
    local lines = {}

    report = report or self.cachedReport or self:getRecipeReport()
    totals = totals or self:getGSVU4SelectedBatchTotals(report)

    if not report then
        table.insert(lines, "Requirements are not available yet.")
        return lines
    end

    if (totals.valid or 0) <= 0 then
        table.insert(lines, "No valid panels selected.")
        return lines
    end

    if not report.hasHammer then
        table.insert(lines, "Need Hammer.")
    end

    if not report.hasMask then
        table.insert(lines, "Need Welding Mask.")
    end

    local fuelHave = tonumber(report.torchUnits or 0) or 0
    local fuelNeed = tonumber(totals.fuel or 0) or 0
    if fuelHave + 0.0001 < fuelNeed then
        table.insert(lines, "Need " .. fmtNum(fuelNeed - fuelHave) .. " more blowtorch units.")
    end

    if (totals.metalLevel or 0) < (totals.maxMetalRequired or 0) then
        table.insert(lines,
            "Need MetalWelding " .. tostring(totals.maxMetalRequired)
            .. " (you have " .. tostring(totals.metalLevel) .. ")."
        )
    end

    if (totals.mechanicsLevel or 0) < (totals.maxMechanicsRequired or 0) then
        table.insert(lines,
            "Need Mechanics " .. tostring(totals.maxMechanicsRequired)
            .. " (you have " .. tostring(totals.mechanicsLevel) .. ")."
        )
    end

    for _, mat in ipairs(MAT_ORDER) do
        local need = totals.mats and tonumber(totals.mats[mat] or 0) or 0
        local have = tonumber(report[mat] or 0) or 0

        if need > 0 and have + 0.0001 < need then
            table.insert(lines,
                "Need " .. fmtNum(need - have) .. " more " .. tostring(MAT_LABEL[mat] or mat) .. "."
            )
        end
    end

    if totals.invalid and totals.invalid > 0 then
        table.insert(lines, tostring(totals.invalid) .. " selected panel(s) are no longer valid.")
    end

    if #lines <= 0 and (totals.affordable or 0) < (totals.valid or 0) then
        table.insert(lines,
            "Only " .. tostring(totals.affordable) .. " / " .. tostring(totals.valid)
            .. " selected panels are affordable in this batch."
        )
    end

    return lines
end

function VehicleArmorWindow:drawSelectedInstallTotalsPanel()
    if not self.installSelectMode then return end
    if not self.detailBox then return end

    local report = self.cachedReport or self:getRecipeReport()
    local totals = self:getGSVU4SelectedBatchTotals(report)
    local missingLines = self:getGSVU4SelectedBatchMissingLines(report, totals)

    local x = self.detailBox:getX()
    local y = self.detailBox:getY()
    local w = self.detailBox:getWidth()
    local h = self.detailBox:getHeight()

    -- Cover the normal highlighted-part details while selector mode is active.
    self:drawRect(x, y, w, h, 0.96, 0.02, 0.02, 0.02)
    self:drawRectBorder(x, y, w, h, 0.95, 0.55, 0.55, 0.55)

    local dx = x + 14
    local dy = y + 12

    self:drawText("SELECTED BATCH REQUIREMENTS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 18

    if (totals.selected or 0) <= 0 then
        self:drawText("No panels selected.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        dy = dy + 18
        self:drawText("Click rows in the selector list to build a batch.",
            dx, dy, 0.62, 0.72, 0.90, 1, UIFont.Small)
        return
    end

    self:drawText(
        "Panels: " .. tostring(totals.affordable or 0) .. " installable / "
        .. tostring(totals.valid or 0) .. " selected",
        dx, dy, 0.70, 0.82, 1.00, 1, UIFont.Small
    )
    dy = dy + 16

    local gradeLine = "Grades: "
        .. "Sc " .. tostring(totals.grades.Scrap or 0)
        .. " | St " .. tostring(totals.grades.Standard or 0)
        .. " | Re " .. tostring(totals.grades.Reinforced or 0)
        .. " | Ap " .. tostring(totals.grades.Apocalypse or 0)

    self:drawText(gradeLine, dx, dy, 0.82, 0.82, 0.82, 1, UIFont.Small)
    dy = dy + 20

    self:drawText("TOOLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local function toolLine(label, ok)
        local mark = ok and "[OK]" or "[NEED]"
        local r, g, b = ok and 0.30 or 0.90, ok and 0.85 or 0.30, ok and 0.30 or 0.25
        self:drawText(mark .. " " .. label, dx + 8, dy, r, g, b, 1, UIFont.Small)
        dy = dy + 15
    end

    toolLine("Hammer", report and report.hasHammer)
    toolLine("Welding Mask", report and report.hasMask)

    local torchHave = report and tonumber(report.torchUnits or 0) or 0
    local torchNeed = tonumber(totals.fuel or 0) or 0
    local tr, tg, tb = enoughColour(torchHave, torchNeed)
    self:drawText(
        "Blowtorch Fuel: " .. fmtNum(torchHave) .. " / " .. fmtNum(torchNeed) .. " units",
        dx + 8, dy, tr, tg, tb, 1, UIFont.Small
    )
    dy = dy + 20

    if (totals.maxMetalRequired or 0) > 0 or (totals.maxMechanicsRequired or 0) > 0 then
        self:drawText("SKILLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
        dy = dy + 16

        if (totals.maxMetalRequired or 0) > 0 then
            local mr, mg, mb = enoughColour(totals.metalLevel, totals.maxMetalRequired)
            self:drawText(
                "MetalWelding: " .. tostring(totals.metalLevel or 0) .. " / " .. tostring(totals.maxMetalRequired or 0),
                dx + 8, dy, mr, mg, mb, 1, UIFont.Small
            )
            dy = dy + 15
        end

        if (totals.maxMechanicsRequired or 0) > 0 then
            local cr, cg, cb = enoughColour(totals.mechanicsLevel, totals.maxMechanicsRequired)
            self:drawText(
                "Mechanics: " .. tostring(totals.mechanicsLevel or 0) .. " / " .. tostring(totals.maxMechanicsRequired or 0),
                dx + 8, dy, cr, cg, cb, 1, UIFont.Small
            )
            dy = dy + 15
        end

        dy = dy + 5
    end

    self:drawText("MATERIAL TOTALS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local anyMat = false
    for _, mat in ipairs(MAT_ORDER) do
        local need = totals.mats and totals.mats[mat] or 0
        if need and need > 0 then
            anyMat = true
            local have = report and tonumber(report[mat] or 0) or 0
            local r, g, b = enoughColour(have, need)
            local label = (MAT_LABEL[mat] or mat) .. ": " .. fmtNum(have) .. " / " .. fmtNum(need)
            self:drawText(label, dx + 8, dy, r, g, b, 1, UIFont.Small)
            dy = dy + 15
        end
    end

    if not anyMat then
        self:drawText("No valid material requirements found.", dx + 8, dy, 0.85, 0.45, 0.30, 1, UIFont.Small)
        dy = dy + 16
    end

    dy = dy + 4
    if #missingLines <= 0 then
        self:drawText("READY: All selected batch requirements are met.",
            dx, dy, 0.30, 0.85, 0.30, 1, UIFont.Small)
    else
        self:drawText("MISSING / BLOCKED:", dx, dy, 1, 0.72, 0.35, 1, UIFont.Small)
        dy = dy + 16

        local maxLines = 6
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

local function applyCleanButtonNames(window, report)
    if not window then return end

    report = report or window.cachedReport
    if not report and window.getRecipeReport then
        local ok, r = pcall(function() return window:getRecipeReport() end)
        if ok then report = r end
    end

    if window.gradeButtons then
        for grade, btn in pairs(window.gradeButtons) do
            setBtnTitle(btn, gradeLabel(grade))
        end
    end

    if window.installAllButton then
        if window.installSelectMode then
            local selectedCount = 0
            local queueCount = 0

            if window.getSelectedInstallCount then
                local ok, count = pcall(function() return window:getSelectedInstallCount() end)
                if ok then selectedCount = count or 0 end
            end

            if window.getSelectedInstallQueue then
                local ok, queue = pcall(function() return window:getSelectedInstallQueue(report) end)
                if ok and queue then queueCount = #queue end
            end

            if selectedCount > 0 then
                setBtnTitle(window.installAllButton,
                    "Install Selected Panels (" .. tostring(queueCount) .. "/" .. tostring(selectedCount) .. ")")
                window.installAllButton:setEnable(queueCount > 0)
            else
                setBtnTitle(window.installAllButton, "Install Selected Panels")
                window.installAllButton:setEnable(false)
            end
        else
            local installQueue = {}
            if window.getInstallAllQueue then
                local ok, queue = pcall(function() return window:getInstallAllQueue(report) end)
                if ok and queue then installQueue = queue end
            end

            if #installQueue > 0 then
                setBtnTitle(window.installAllButton, "Select Missing Panels (" .. tostring(#installQueue) .. ")")
                window.installAllButton:setEnable(true)
            else
                setBtnTitle(window.installAllButton, "Select Missing Panels")
                window.installAllButton:setEnable(false)
            end
        end
    end

    if window.repairAllButton and window.getRepairAllStatus and window.getRepairAllQueue then
        local okS, status = pcall(function() return window:getRepairAllStatus(report) end)
        local okQ, queue = pcall(function() return window:getRepairAllQueue(report) end)

        if okS and status and status.damaged and status.damaged > 0 then
            if okQ and queue and #queue > 0 then
                setBtnTitle(window.repairAllButton,
                    "Repair Damaged Panels (" .. tostring(#queue) .. "/" .. tostring(status.damaged) .. ")")
            else
                setBtnTitle(window.repairAllButton, "Repair Blocked")
            end
        else
            setBtnTitle(window.repairAllButton, "Repair Damaged Panels")
        end
    end

    if window.uninstallAllButton and window.getUninstallAllStatus and window.getUninstallAllQueue then
        local okS, status = pcall(function() return window:getUninstallAllStatus(report) end)
        local okQ, queue = pcall(function() return window:getUninstallAllQueue(report) end)

        if window.pendingUninstallAll then
            setBtnTitle(window.uninstallAllButton, "Confirm Remove All")
        elseif okS and status and status.installed and status.installed > 0 then
            if okQ and queue and #queue > 0 then
                setBtnTitle(window.uninstallAllButton,
                    "Remove All Panels (" .. tostring(#queue) .. "/" .. tostring(status.installed) .. ")")
            else
                setBtnTitle(window.uninstallAllButton, "Remove Blocked")
            end
        else
            setBtnTitle(window.uninstallAllButton, "Remove All Panels")
        end
    end

    if window.repairButton then
        setBtnTitle(window.repairButton, "Repair Panel")
    end

    if window.actionButton and window.selectedPart and window.vehicle then
        local vdata = window.vehicle:getModData()
        local armor = vdata and vdata.gArmor and vdata.gArmor[window.selectedPart.partId]

        if armor then
            if window.pendingUninstallPartId == window.selectedPart.partId then
                setBtnTitle(window.actionButton, "Confirm Remove Panel")
            else
                setBtnTitle(window.actionButton, "Remove Armor Panel")
            end
        elseif report and report.canCraft then
            setBtnTitle(window.actionButton,
                "Install " .. gradeLabel(window.currentGrade) .. " - " .. tostring(window.selectedPart.name or "Panel"))
        elseif window.selectedPart then
            setBtnTitle(window.actionButton, "Missing Requirements")
        end
    end
end

local oldCreateChildrenForClarity = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    oldCreateChildrenForClarity(self)
    applyCleanButtonNames(self, self.cachedReport)
end

local oldSelectGradeForClarity = VehicleArmorWindow.selectGrade
function VehicleArmorWindow:selectGrade(grade)
    oldSelectGradeForClarity(self, grade)
    applyCleanButtonNames(self, self.cachedReport)
end

local oldUpdateBulkButtonsForClarity = VehicleArmorWindow.updateBulkButtons
function VehicleArmorWindow:updateBulkButtons(report)
    oldUpdateBulkButtonsForClarity(self, report)
    applyCleanButtonNames(self, report)
end

-- Per-frame button renaming removed. Clean names are applied on createChildren,
-- selectGrade and updateBulkButtons instead.
