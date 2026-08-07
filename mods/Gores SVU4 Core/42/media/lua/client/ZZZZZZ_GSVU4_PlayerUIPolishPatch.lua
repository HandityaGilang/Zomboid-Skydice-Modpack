--========================================================
-- Gore's SVU4 Core - Player UI Polish Patch
-- Phase 1X
--
-- Adds:
-- - multi-select total install time
-- - Clear Selection button
-- - installed grade tags in the left part list
-- - armour condition warning on installed panels
-- - grouped part list ordering: Front / Doors / Rear
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

local GROUP_ORDER = {
    Front = 10,
    Doors = 20,
    Rear = 30,
}

local GROUP_LABEL = {
    Front = "FRONT",
    Doors = "DOORS",
    Rear = "REAR",
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

local function fmtTimeUnits(value)
    value = tonumber(value or 0) or 0
    if value <= 0 then return "0" end
    return fmtNum(value)
end

local function enoughColour(have, need)
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

local function getSkillForGrade(character, grade)
    if VehicleArmorHelpers and VehicleArmorHelpers.getSkillRequirementReport then
        local ok, report = pcall(VehicleArmorHelpers.getSkillRequirementReport, character, grade)
        if ok and report then
            return report
        end
    end

    return {
        metalRequired = 0,
        mechRequired = 0,
        metalLevel = 0,
        mechLevel = 0,
        hasSkills = true,
    }
end

local function classifyPartGroup(partId)
    local id = tostring(partId or "")
    local l = string.lower(id)

    -- Front: hood, front windscreen, headlights/front fittings.
    if l == "enginedoor"
    or l == "hood"
    or l == "windshield"
    or l == "windshieldfront"
    or string.find(l, "headlight", 1, true)
    or string.find(l, "frontgrill", 1, true)
    or string.find(l, "grill", 1, true)
    then
        return "Front"
    end

    -- Rear: trunk, bed, fuel tank, rear windscreen/rear window, trailers.
    if l == "trunkdoor"
    or string.find(l, "trunk", 1, true)
    or string.find(l, "truckbed", 1, true)
    or l == "gastank"
    or l == "windshieldrear"
    or l == "rearwindshield"
    or l == "windowrear"
    or string.find(l, "trailer", 1, true)
    or string.find(l, "animal", 1, true)
    then
        return "Rear"
    end

    -- Doors group includes all side doors and side windows, including rear-left/right side windows.
    if string.find(l, "door", 1, true)
    or string.find(l, "windowfront", 1, true)
    or string.find(l, "windowmiddle", 1, true)
    or string.find(l, "windowrearleft", 1, true)
    or string.find(l, "windowrearright", 1, true)
    or string.find(l, "windowleft", 1, true)
    or string.find(l, "windowright", 1, true)
    then
        return "Doors"
    end

    return "Rear"
end

local function partWithinGroupScore(partId)
    local id = string.lower(tostring(partId or ""))

    if id == "enginedoor" or id == "hood" then return 10 end
    if id == "windshield" or id == "windshieldfront" then return 20 end
    if string.find(id, "headlight", 1, true) then return 30 end

    if string.find(id, "doorfront", 1, true) then return 110 end
    if string.find(id, "doormiddle", 1, true) then return 120 end
    if string.find(id, "doorrear", 1, true) then return 130 end
    if string.find(id, "windowfront", 1, true) then return 140 end
    if string.find(id, "windowmiddle", 1, true) then return 150 end
    if string.find(id, "windowrearleft", 1, true) or string.find(id, "windowrearright", 1, true) then return 160 end
    if string.find(id, "windowleft", 1, true) or string.find(id, "windowright", 1, true) then return 170 end

    if id == "windshieldrear" or id == "rearwindshield" or id == "windowrear" then return 210 end
    if string.find(id, "trunk", 1, true) then return 220 end
    if string.find(id, "truckbed", 1, true) then return 230 end
    if id == "gastank" then return 240 end
    if string.find(id, "trailer", 1, true) or string.find(id, "animal", 1, true) then return 250 end

    return 999
end

local oldGetPartSortScoreForPolish = VehicleArmorWindow.getPartSortScore
function VehicleArmorWindow:getPartSortScore(partId)
    local sort = self.partSort or "Alpha"

    -- The old A-Z button is now the grouped player-friendly view.
    if sort == "Alpha" or sort == "Group" then
        local group = classifyPartGroup(partId)
        return (GROUP_ORDER[group] or 90) + (partWithinGroupScore(partId) / 1000)
    end

    return oldGetPartSortScoreForPolish(self, partId)
end

function VehicleArmorWindow:getGSVU4SelectedBatchTotals(report)
    local totals = {
        selected = 0,
        valid = 0,
        invalid = 0,
        affordable = 0,
        fuel = 0,
        time = 0,
        mats = {},
        tools = {
            hammer = false,
            screwdriver = false,
            weldingMask = false,
            blowTorch = false,
        },
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

                if VehicleArmorConfig and VehicleArmorConfig.Time then
                    totals.time = totals.time + (tonumber(VehicleArmorConfig.Time[grade] or 0) or 0)
                end

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

    if self.getSelectedInstallToolRequirements then
        local ok, toolReq = pcall(function()
            return self:getSelectedInstallToolRequirements()
        end)
        if ok and toolReq then
            totals.tools.hammer = toolReq.hammer == true
            totals.tools.screwdriver = toolReq.screwdriver == true
            totals.tools.weldingMask = toolReq.weldingMask == true
            totals.tools.blowTorch = toolReq.blowTorch == true
        end
    end

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

    local toolReq = totals.tools or {}

    if toolReq.hammer and not report.hasHammer then
        table.insert(lines, "Need Hammer.")
    end

    if toolReq.screwdriver and not report.hasScrewdriver then
        table.insert(lines, "Need Screwdriver.")
    end

    if toolReq.weldingMask and not report.hasMask then
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
    dy = dy + 16

    self:drawText(
        "Estimated Install Time: " .. fmtTimeUnits(totals.time or 0) .. " action units",
        dx, dy, 0.78, 0.88, 1.00, 1, UIFont.Small
    )
    dy = dy + 20

    self:drawText("TOOLS:", dx, dy, 1, 1, 1, 1, UIFont.Small)
    dy = dy + 16

    local function toolLine(label, ok)
        local mark = ok and "[OK]" or "[NEED]"
        local r, g, b = ok and 0.30 or 0.90, ok and 0.85 or 0.30, ok and 0.30 or 0.25
        self:drawText(mark .. " " .. label, dx + 8, dy, r, g, b, 1, UIFont.Small)
        dy = dy + 15
    end

    local toolReq = totals.tools or {}
    if toolReq.hammer then toolLine("Hammer", report and report.hasHammer) end
    if toolReq.screwdriver then toolLine("Screwdriver", report and report.hasScrewdriver) end
    if toolReq.weldingMask then toolLine("Welding Mask", report and report.hasMask) end

    local torchHave = report and tonumber(report.torchUnits or 0) or 0
    local torchNeed = tonumber(totals.fuel or 0) or 0
    if torchNeed > 0 then
        local tr, tg, tb = enoughColour(torchHave, torchNeed)
        self:drawText(
            "Blowtorch Fuel: " .. fmtNum(torchHave) .. " / " .. fmtNum(torchNeed) .. " units",
            dx + 8, dy, tr, tg, tb, 1, UIFont.Small
        )
        dy = dy + 15
    end
    dy = dy + 5

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

        local maxLines = 5
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

function VehicleArmorWindow:populateParts(vehicle)
    self.partList:clear()
    local v = vehicle or self.vehicle
    if not v then return end

    local added = {}
    local groups = {
        Front = {},
        Doors = {},
        Rear = {},
    }
    local rows = {}

    pcall(function()
        local script = v:getScript()
        if script and script.getPartCount then
            for i = 0, script:getPartCount() - 1 do
                local sp = script:getPart(i)
                if sp then
                    local id = (sp.getPartId and sp:getPartId()) or sp:getId()
                    if id
                    and VehicleArmorConfig.isAllowedPart(id)
                    and self:partPassesFilter(id)
                    and not added[id]
                    then
                        local label = self:getPrettyLabel(id, v:getPartById(id))
                        local group = classifyPartGroup(id)

                        table.insert(groups[group] or groups.Rear, {
                            label = label,
                            partId = id,
                            group = group,
                        })

                        added[id] = true
                    end
                end
            end
        end
    end)

    local sort = self.partSort or "Alpha"

    if sort == "Alpha" or sort == "Group" then
        for groupName, groupRows in pairs(groups) do
            table.sort(groupRows, function(a, b)
                local scoreA = partWithinGroupScore(a.partId)
                local scoreB = partWithinGroupScore(b.partId)
                if scoreA ~= scoreB then
                    return scoreA < scoreB
                end
                return tostring(a.label):lower() < tostring(b.label):lower()
            end)
        end

        for _, groupName in ipairs({"Front", "Doors", "Rear"}) do
            local groupRows = groups[groupName] or {}
            if #groupRows > 0 then
                self.partList:addItem("— " .. tostring(GROUP_LABEL[groupName] or groupName) .. " —", {
                    name = tostring(GROUP_LABEL[groupName] or groupName),
                    header = true,
                    group = groupName,
                })

                for _, row in ipairs(groupRows) do
                    self.partList:addItem(row.label, {
                        name = row.label,
                        partId = row.partId,
                        group = groupName,
                    })
                end
            end
        end
    else
        for _, groupRows in pairs(groups) do
            for _, row in ipairs(groupRows) do
                table.insert(rows, row)
            end
        end

        table.sort(rows, function(a, b)
            local scoreA = self:getPartSortScore(a.partId)
            local scoreB = self:getPartSortScore(b.partId)

            if scoreA ~= scoreB then
                return scoreA < scoreB
            end

            return tostring(a.label):lower() < tostring(b.label):lower()
        end)

        for _, row in ipairs(rows) do
            self.partList:addItem(row.label, {
                name = row.label,
                partId = row.partId,
                group = row.group,
            })
        end
    end

    local firstPartItem = nil
    if self.partList.items and #self.partList.items > 0 then
        for i = 1, #self.partList.items do
            local item = self.partList.items[i] and self.partList.items[i].item
            if item and item.partId then
                firstPartItem = item
                self.partList.selected = i
                break
            end
        end
    end

    if firstPartItem then
        self.unsupportedVehicle = false
        self.emptyFilter        = false
        self.selectedPart       = firstPartItem
        self.reportDirty        = true
    else
        self.selectedPart       = nil
        self.reportDirty        = true
        self.unsupportedVehicle = (self.partFilter or "All") == "All"
        self.emptyFilter        = not self.unsupportedVehicle
    end

    self:updatePartFilterButtons()
    if self.updatePartSortButtons then
        self:updatePartSortButtons()
    end
end

local oldUpdatePartSortButtonsForPolish = VehicleArmorWindow.updatePartSortButtons
function VehicleArmorWindow:updatePartSortButtons()
    oldUpdatePartSortButtonsForPolish(self)

    if self.partSortButtons and self.partSortButtons.Alpha then
        if self.partSortButtons.Alpha.setTitle then
            self.partSortButtons.Alpha:setTitle("Group")
        end
    end
end

local oldUpdateBulkButtonsForPolish = VehicleArmorWindow.updateBulkButtons
function VehicleArmorWindow:updateBulkButtons(report)
    oldUpdateBulkButtonsForPolish(self, report)

    if self.clearSelectionButton then
        local count = 0
        if self.getSelectedInstallCount then
            local ok, selectedCount = pcall(function() return self:getSelectedInstallCount() end)
            if ok then count = selectedCount or 0 end
        end

        self.clearSelectionButton:setTitle("Clear Selection" .. (count > 0 and (" (" .. tostring(count) .. ")") or ""))

        if self.installSelectMode then
            self.clearSelectionButton:setEnable(count > 0)
            if self.clearSelectionButton.setVisible then
                self.clearSelectionButton:setVisible(true)
            end
        else
            self.clearSelectionButton:setEnable(false)
            if self.clearSelectionButton.setVisible then
                self.clearSelectionButton:setVisible(true)
            end
        end
    end
end

function VehicleArmorWindow:onClearInstallSelectionButton()
    self.installSelectMode = true
    self.installSelectedParts = {}
    self.reportDirty = true
end

local oldCreateChildrenForPolish = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    oldCreateChildrenForPolish(self)

    if self.partSortButtons and self.partSortButtons.Alpha and self.partSortButtons.Alpha.setTitle then
        self.partSortButtons.Alpha:setTitle("Group")
    end

    local bottomY = self.height - 45
    self.clearSelectionButton = ISButton:new(
        10, bottomY, 150, 32,
        "Clear Selection", self, self.onClearInstallSelectionButton)
    self.clearSelectionButton:initialise()
    self:addChild(self.clearSelectionButton)
    self.clearSelectionButton:setEnable(false)

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

        self.partList.onmousedown = function()
            local list = armorWindow.partList
            local row = list and list.selected

            if row and row > 0 and list.items[row] then
                local rowItem = list.items[row].item

                if rowItem and rowItem.header then
                    return
                end

                armorWindow:onSelectPart(rowItem)

                if armorWindow.installSelectMode then
                    armorWindow:toggleInstallSelection(rowItem)
                end
            end
        end
    end

    self:populateParts(self.vehicle)
end

function VehicleArmorWindow:drawArmorConditionWarning()
    if self.installSelectMode then return end
    if not self.detailBox or not self.vehicle or not self.selectedPart then return end

    local partId = self.selectedPart.partId
    if not partId then return end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor and vdata.gArmor[partId]
    if not armor then return end

    local health = tonumber(armor.health or 0) or 0
    if health > 60 then return end

    local x = self.detailBox:getX()
    local y = self.detailBox:getY() + self.detailBox:getHeight() - 42
    local w = self.detailBox:getWidth()
    local h = 36

    local critical = health <= 25
    local title = critical and "CRITICAL ARMOR CONDITION" or "ARMOR CONDITION WARNING"
    local msg = tostring(gradeLabel(getArmorGrade(armor))) .. " condition: " .. fmtNum(health) .. "%. Repair recommended."

    self:drawRect(x + 8, y, w - 16, h, 0.88, 0.10, 0.05, 0.03)
    self:drawRectBorder(x + 8, y, w - 16, h, 0.90, 0.95, 0.55, 0.25)
    self:drawText(title, x + 18, y + 4, 1.00, 0.72, 0.30, 1, UIFont.Small)
    self:drawText(msg, x + 18, y + 19, 0.95, 0.95, 0.95, 1, UIFont.Small)
end

local oldPrerenderForPolish = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender()
    oldPrerenderForPolish(self)

    self:drawArmorConditionWarning()
end
