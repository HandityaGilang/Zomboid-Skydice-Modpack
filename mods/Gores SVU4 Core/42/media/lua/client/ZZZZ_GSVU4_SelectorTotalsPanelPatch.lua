--========================================================
-- Gore's SVU4 Core - Selector Totals Centre Panel
-- Displays running tool and material totals while the
-- install selector is active.
--========================================================

if not VehicleArmorWindow then
    return
end


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

local function gradeShort(grade)
    grade = tostring(grade or "")
    if grade == "Scrap" then return "Sc" end
    if grade == "Standard" then return "St" end
    if grade == "Reinforced" then return "Re" end
    if grade == "Apocalypse" then return "Ap" end
    return "?"
end

local function fmtNum(value)
    value = tonumber(value or 0) or 0

    if math.abs(value - math.floor(value + 0.0001)) < 0.001 then
        return tostring(math.floor(value + 0.0001))
    end

    return string.format("%.1f", value)
end

local function colourForEnough(have, need)
    if (tonumber(have or 0) or 0) + 0.0001 >= (tonumber(need or 0) or 0) then
        return 0.30, 0.85, 0.30
    end

    return 0.90, 0.30, 0.25
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

function VehicleArmorWindow:getSelectedInstallTotals(report)
    local totals = {
        selected = 0,
        valid = 0,
        invalid = 0,
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
    }

    if not self.installSelectedParts then
        return totals
    end

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

                if VehicleArmorConfig and VehicleArmorConfig.SkillRequirements then
                    local req = VehicleArmorConfig.SkillRequirements[grade]
                    if req then
                        totals.maxMetalRequired = math.max(totals.maxMetalRequired, tonumber(req.MetalWelding or req.metal or 0) or 0)
                        totals.maxMechanicsRequired = math.max(totals.maxMechanicsRequired, tonumber(req.Mechanics or req.mechanics or 0) or 0)
                    end
                end
            else
                totals.invalid = totals.invalid + 1
            end
        end
    end

    return totals
end


local function GSVU4_BuildSelectedInstallSignature(window)
    if not window or not window.installSelectedParts then return "none" end
    local keys = {}
    for partId, grade in pairs(window.installSelectedParts) do
        if partId and grade then
            keys[#keys + 1] = tostring(partId) .. ":" .. tostring(grade)
        end
    end
    table.sort(keys)
    return table.concat(keys, "|")
end

function VehicleArmorWindow:drawSelectedInstallTotalsPanel()
    if not self.installSelectMode then return end
    if not self.detailBox then return end

    local report = self.cachedReport
    if not report then return end

    local signature = GSVU4_BuildSelectedInstallSignature(self)
    if self.gsvu4SelectedTotalsDirty
    or not self.gsvu4SelectedTotals
    or self.gsvu4SelectedTotalsSignature ~= signature
    then
        self.gsvu4SelectedTotals = self:getSelectedInstallTotals(report)
        self.gsvu4SelectedTotalsSignature = signature
        self.gsvu4SelectedTotalsDirty = false
    end

    local totals = self.gsvu4SelectedTotals or self:getSelectedInstallTotals(report)

    local x = self.detailBox:getX()
    local y = self.detailBox:getY()
    local w = self.detailBox:getWidth()
    local h = self.detailBox:getHeight()

    -- Cover the normal highlighted-part detail view with selector totals.
    self:drawRect(x, y, w, h, 0.94, 0.02, 0.02, 0.02)
    self:drawRectBorder(x, y, w, h, 0.95, 0.55, 0.55, 0.55)

    local dx = x + 14
    local dy = y + 12

    self:drawText("SELECTED INSTALL TOTALS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 18

    if (totals.selected or 0) <= 0 then
        self:drawText("No panels selected.", dx, dy, 0.75, 0.75, 0.75, 1, UIFont.Small)
        dy = dy + 18
        self:drawText("Click rows in the selector list to build a batch.",
            dx, dy, 0.62, 0.72, 0.90, 1, UIFont.Small)
        return
    end

    local queueCount = 0
    if self.getSelectedInstallQueue then
        local ok, queue = pcall(function() return self:getSelectedInstallQueue(report) end)
        if ok and queue then
            queueCount = #queue
        end
    end

    self:drawText(
        "Panels: " .. tostring(queueCount) .. " affordable / " .. tostring(totals.valid) .. " selected",
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
        local mark = ok and "[OK]" or "[--]"
        local r, g, b = ok and 0.30 or 0.90, ok and 0.85 or 0.30, ok and 0.30 or 0.25
        self:drawText(mark .. " " .. label, dx + 8, dy, r, g, b, 1, UIFont.Small)
        dy = dy + 15
    end

    toolLine("Hammer", report and report.hasHammer)
    toolLine("Welding Mask", report and report.hasMask)

    local torchHave = report and tonumber(report.torchUnits or 0) or 0
    local torchNeed = tonumber(totals.fuel or 0) or 0
    local tr, tg, tb = colourForEnough(torchHave, torchNeed)
    self:drawText(
        "Blowtorch: " .. fmtNum(torchHave) .. " / " .. fmtNum(torchNeed) .. " units",
        dx + 8, dy, tr, tg, tb, 1, UIFont.Small
    )
    dy = dy + 20

    self:drawText("MATERIAL TOTALS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local anyMat = false
    for _, mat in ipairs(MAT_ORDER) do
        local need = totals.mats and totals.mats[mat] or 0
        if need and need > 0 then
            anyMat = true
            local have = report and tonumber(report[mat] or 0) or 0
            local r, g, b = colourForEnough(have, need)
            local label = (MAT_LABEL[mat] or mat) .. ": " .. fmtNum(have) .. " / " .. fmtNum(need)
            self:drawText(label, dx + 8, dy, r, g, b, 1, UIFont.Small)
            dy = dy + 15
        end
    end

    if not anyMat then
        self:drawText("No valid material requirements found.", dx + 8, dy, 0.85, 0.45, 0.30, 1, UIFont.Small)
        dy = dy + 16
    end

    if totals.invalid and totals.invalid > 0 then
        dy = dy + 2
        self:drawText(
            "Skipped invalid/already-installed selections: " .. tostring(totals.invalid),
            dx + 8, dy, 0.95, 0.55, 0.25, 1, UIFont.Small
        )
    end
end

local oldPrerenderForSelectorTotals = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender()
    oldPrerenderForSelectorTotals(self)
    self:drawSelectedInstallTotalsPanel()
end
