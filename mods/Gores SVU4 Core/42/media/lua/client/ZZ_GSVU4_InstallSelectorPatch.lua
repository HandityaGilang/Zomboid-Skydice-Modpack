--========================================================
-- Gore's SVU4 Core - Multi-Grade Install Selector Patch
-- Phase 1U
--
-- Separate patch file. VehicleArmor_UI.lua is not edited.
--
-- Allows one install selection per vehicle part, but selected
-- parts can be mixed across Scrap / Standard / Reinforced /
-- Apocalypse in the same queued batch.
--========================================================

if not VehicleArmorWindow then
    return
end


local function gradeShort(grade)
    grade = tostring(grade or "")
    if grade == "Scrap" then return "Sc" end
    if grade == "Standard" then return "St" end
    if grade == "Reinforced" then return "Re" end
    if grade == "Apocalypse" then return "Ap" end
    return "?"
end

local function validGrade(grade)
    return grade == "Scrap"
        or grade == "Standard"
        or grade == "Reinforced"
        or grade == "Apocalypse"
end

local function Selector_GetToolRequirementsForGrade(grade)
    if VehicleArmorHelpers
    and VehicleArmorHelpers.getInstallToolRequirements
    then
        local ok, req = pcall(function()
            return VehicleArmorHelpers.getInstallToolRequirements(grade)
        end)
        if ok and req then
            return req
        end
    end

    -- Safe fallback matching the current Core rules.
    if tostring(grade or "") == "Scrap" then
        return { hammer = true, screwdriver = true, weldingMask = false, blowTorch = false }
    end

    return { hammer = true, screwdriver = false, weldingMask = true, blowTorch = true }
end

----------------------------------------------------------
-- LOCAL BUDGET HELPERS
-- VehicleArmor_UI.lua's budget helpers are local to that file,
-- so this patch keeps its own copies.
----------------------------------------------------------
local function Selector_CopyInstallBudget(report)
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

local function Selector_CanAffordRecipeFromBudget(budget, recipe)
    if not budget or not recipe then return false end

    for mat, req in pairs(recipe) do
        if (budget[mat] or 0) + 0.0001 < (tonumber(req) or 0) then
            return false
        end
    end

    return true
end

local function Selector_ReserveRecipeFromBudget(budget, recipe)
    if not budget or not recipe then return end

    for mat, req in pairs(recipe) do
        budget[mat] = (budget[mat] or 0) - (tonumber(req) or 0)
    end
end

local function Selector_SafeGasTankPart(partId)
    if GAA_IsGasTankPart then
        local ok, result = pcall(GAA_IsGasTankPart, partId)
        if ok then return result == true end
    end

    return tostring(partId or "") == "GasTank"
end

local function Selector_ArmorHealthColor(health)
    if GAA_GetArmorHealthColor then
        local ok, c = pcall(GAA_GetArmorHealthColor, health)
        if ok and c then return c end
    end

    local h = tonumber(health or 0) or 0
    if h <= 25 then return { r = 0.95, g = 0.35, b = 0.25 } end
    if h <= 60 then return { r = 0.95, g = 0.75, b = 0.25 } end
    return { r = 0.25, g = 0.85, b = 0.25 }
end

local function Selector_GasLeakColor()
    if GAA_GetGasLeakColor then
        local ok, c = pcall(GAA_GetGasLeakColor)
        if ok and c then return c end
    end

    return { r = 0.35, g = 0.75, b = 1.0 }
end

local function Selector_RefreshButtons(window)
    if not window then return end
    window.reportDirty = true

    if window.updateBulkButtons then
        local ok = pcall(function()
            window:updateBulkButtons(window.cachedReport or window:getRecipeReport())
        end)

        if not ok and window.installAllButton then
            window.installAllButton:setTitle("Install Selected")
        end
    end
end

function VehicleArmorWindow:clearInstallSelection(markDirty)
    self.installSelectMode = false
    self.installSelectedParts = {}

    if markDirty ~= false then
        self.reportDirty = true
    end
end

function VehicleArmorWindow:isInstallSelectionCandidate(partId, grade)
    if not partId or not self.vehicle then return false end

    grade = grade or self.currentGrade or "Scrap"
    if not validGrade(grade) then return false end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor or {}

    if armor and armor[partId] then
        return false
    end

    if not VehicleArmorConfig or not VehicleArmorConfig.getInstallRecipe then
        return false
    end

    return VehicleArmorConfig.getInstallRecipe(partId, grade) ~= nil
end

function VehicleArmorWindow:getSelectedInstallCount()
    local count = 0

    if not self.installSelectedParts then return 0 end

    for partId, grade in pairs(self.installSelectedParts) do
        if grade and self:isInstallSelectionCandidate(partId, grade) then
            count = count + 1
        end
    end

    return count
end

function VehicleArmorWindow:toggleInstallSelection(rowItem)
    if not rowItem then return end

    local partId = rowItem.partId
    local grade = self.currentGrade or "Scrap"

    if not self:isInstallSelectionCandidate(partId, grade) then
        return
    end

    self.installSelectedParts = self.installSelectedParts or {}

    -- One selected grade per part:
    -- clicking the same part/grade unticks it;
    -- clicking the same part under a different grade replaces the old grade.
    if self.installSelectedParts[partId] == grade then
        self.installSelectedParts[partId] = nil
    else
        self.installSelectedParts[partId] = grade
    end

    Selector_RefreshButtons(self)
end

function VehicleArmorWindow:beginInstallSelection(report)
    report = report or self.cachedReport or self:getRecipeReport()

    local queue = self:getInstallAllQueue(report)
    if #queue <= 0 then
        return false
    end

    self.installSelectMode = true
    self.installSelectedParts = self.installSelectedParts or {}

    local grade = self.currentGrade or "Scrap"

    -- Select all currently affordable missing parts for the current grade.
    -- This preserves old "Install Missing" convenience while still allowing
    -- the player to change individual rows and switch grade tabs.
    for _, partId in ipairs(queue) do
        self.installSelectedParts[partId] = grade
    end

    Selector_RefreshButtons(self)
    return true
end

function VehicleArmorWindow:getSelectedInstallToolRequirements()
    local combined = {
        hammer = false,
        screwdriver = false,
        weldingMask = false,
        blowTorch = false,
    }

    for partId, grade in pairs(self.installSelectedParts or {}) do
        if grade and self:isInstallSelectionCandidate(partId, grade) then
            local req = Selector_GetToolRequirementsForGrade(grade)
            combined.hammer = combined.hammer or req.hammer == true
            combined.screwdriver = combined.screwdriver or req.screwdriver == true
            combined.weldingMask = combined.weldingMask or req.weldingMask == true
            combined.blowTorch = combined.blowTorch or req.blowTorch == true
        end
    end

    return combined
end

function VehicleArmorWindow:getSelectedInstallQueue(report)
    local queue = {}

    if not self.vehicle or not self.partList or not self.partList.items then
        return queue
    end

    if not self.installSelectedParts then
        return queue
    end

    report = report or self.cachedReport or self:getRecipeReport()
    if not report then
        return queue
    end

    local toolReq = self:getSelectedInstallToolRequirements()
    if (toolReq.hammer and not report.hasHammer)
    or (toolReq.screwdriver and not report.hasScrewdriver)
    or (toolReq.weldingMask and not report.hasMask)
    then
        return queue
    end

    if report.skillReport and not report.skillReport.hasSkills then
        return queue
    end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor or {}
    local budget = Selector_CopyInstallBudget(report)
    local orderedPartIds = {}

    -- Preserve visible list order first.
    for _, row in ipairs(self.partList.items) do
        local item = row and row.item
        local partId = item and item.partId
        if partId and self.installSelectedParts[partId] then
            table.insert(orderedPartIds, partId)
        end
    end

    -- Then include selected parts hidden by the current filter/sort,
    -- so changing filters does not silently drop a cross-grade selection.
    for partId, _ in pairs(self.installSelectedParts) do
        local already = false
        for _, listedPartId in ipairs(orderedPartIds) do
            if listedPartId == partId then
                already = true
                break
            end
        end
        if not already then
            table.insert(orderedPartIds, partId)
        end
    end

    for _, partId in ipairs(orderedPartIds) do
        local grade = self.installSelectedParts[partId]

        if partId
        and grade
        and not armor[partId]
        and self:isInstallSelectionCandidate(partId, grade)
        then
            local recipe = VehicleArmorConfig.getInstallRecipe(partId, grade)

            if recipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
                recipe = VehicleArmorHelpers.getAdjustedRecipe(recipe)
            end

            local fuelPerPanel = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(partId, grade) or (VehicleArmorConfig.FuelUse.Install[grade] or 0)

            if recipe
            and (budget.torchUnits or 0) + 0.0001 >= fuelPerPanel
            and Selector_CanAffordRecipeFromBudget(budget, recipe)
            then
                table.insert(queue, { partId = partId, grade = grade })
                budget.torchUnits = (budget.torchUnits or 0) - fuelPerPanel
                Selector_ReserveRecipeFromBudget(budget, recipe)
            end
        end
    end

    return queue
end

function VehicleArmorWindow:getSelectedInstallGradeBreakdown()
    local counts = {
        Scrap = 0,
        Standard = 0,
        Reinforced = 0,
        Apocalypse = 0,
    }

    if not self.installSelectedParts then return counts end

    for partId, grade in pairs(self.installSelectedParts) do
        if grade and counts[grade] ~= nil and self:isInstallSelectionCandidate(partId, grade) then
            counts[grade] = counts[grade] + 1
        end
    end

    return counts
end

local oldCreateChildren = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    oldCreateChildren(self)

    self.installSelectMode = false
    self.installSelectedParts = {}

    if self.installAllButton then
        self.installAllButton:setTitle("Select Missing")
    end

    if self.partList then
        local armorWindow = self

        self.partList.doDrawItem = function(list, y, item, alt)
            if not item then
                return y + list.itemheight
            end

            local rowData = item.item
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
                    and Selector_SafeGasTankPart(partId)
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

            local r, g, b = 0.75, 0.75, 0.75

            if leaking then
                local c = Selector_GasLeakColor()
                r, g, b = c.r, c.g, c.b
                label = label .. "  [LEAKING]"
            elseif armor then
                local c = Selector_ArmorHealthColor(armor.health or 0)
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
                armorWindow:onSelectPart(rowItem)

                if armorWindow.installSelectMode then
                    armorWindow:toggleInstallSelection(rowItem)
                end
            end
        end
    end
end

local oldSetPartFilter = VehicleArmorWindow.setPartFilter
function VehicleArmorWindow:setPartFilter(filter)
    -- Do not clear selections. Multi-grade selection may intentionally span
    -- rows hidden by the current filter.
    oldSetPartFilter(self, filter)
    Selector_RefreshButtons(self)
end

local oldSetPartSort = VehicleArmorWindow.setPartSort
function VehicleArmorWindow:setPartSort(sort)
    oldSetPartSort(self, sort)
    Selector_RefreshButtons(self)
end

local oldSelectGrade = VehicleArmorWindow.selectGrade
function VehicleArmorWindow:selectGrade(grade)
    -- Keep selection when switching grades so players can build mixed-grade batches.
    oldSelectGrade(self, grade)
    Selector_RefreshButtons(self)
end

local oldUpdateBulkButtons = VehicleArmorWindow.updateBulkButtons
function VehicleArmorWindow:updateBulkButtons(report)
    oldUpdateBulkButtons(self, report)

    if not self.installAllButton then
        return
    end

    report = report or self.cachedReport or self:getRecipeReport()

    if self.installSelectMode then
        local selectedCount = self:getSelectedInstallCount()
        local selectedQueue = self:getSelectedInstallQueue(report)

        if selectedCount > 0 then
            self.installAllButton:setTitle(
                "Install Selected (" .. tostring(#selectedQueue) .. "/" .. tostring(selectedCount) .. ")")
            self.installAllButton:setEnable(#selectedQueue > 0)
        else
            self.installAllButton:setTitle("Install Selected")
            self.installAllButton:setEnable(false)
        end
    else
        local installQueue = self:getInstallAllQueue(report)
        if #installQueue > 0 then
            self.installAllButton:setTitle("Select Missing (" .. tostring(#installQueue) .. ")")
            self.installAllButton:setEnable(true)
        else
            self.installAllButton:setTitle("Select Missing")
            self.installAllButton:setEnable(false)
        end
    end
end

local oldDrawOverview = VehicleArmorWindow.drawOverview
function VehicleArmorWindow:drawOverview(x, y, w, h)
    oldDrawOverview(self, x, y, w, h)

    if not self.installSelectMode then return end
    if not self.installSelectedParts then return end

    local counts = self:getSelectedInstallGradeBreakdown()
    local total = self:getSelectedInstallCount()

    if total <= 0 then return end

    local line = "Selected: "
        .. "Sc " .. tostring(counts.Scrap or 0)
        .. " | St " .. tostring(counts.Standard or 0)
        .. " | Re " .. tostring(counts.Reinforced or 0)
        .. " | Ap " .. tostring(counts.Apocalypse or 0)

    self:drawText(line, x + 10, y + h - 18, 0.97, 0.97, 0.97, 1, UIFont.Small)
end

function VehicleArmorWindow:onInstallAllButtonClick()
    if not self.vehicle then return end

    local report = self.refreshBulkActionState and self:refreshBulkActionState() or self:getRecipeReport()

    if not self.installSelectMode then
        if not self:beginInstallSelection(report) then
            self.character:Say("No installable missing armor for this grade.")
            return
        end

        self.character:Say("Select panels and grades, then click Install Selected.")
        self:updateBulkButtons(report)
        return
    end

    local selectedCount = self:getSelectedInstallCount()
    local queue = self:getSelectedInstallQueue(report)

    if selectedCount <= 0 then
        self.character:Say("No armor panels selected.")
        return
    end

    if #queue <= 0 then
        self.character:Say("Selected armor cannot be installed with current tools/materials.")
        return
    end

    if GSVU4Core and GSVU4Core.UIState then
        GSVU4Core.UIState.LastArmorGrade = self.currentGrade
    end

    if self.character and self.character.getModData then
        self.character:getModData().GSVU4_LastArmorGrade = self.currentGrade
    end

    local queued = 0
    for _, entry in ipairs(queue) do
        local partId = entry.partId
        local grade = entry.grade

        local action = ISWeldVehicleArmor:new(
            self.character,
            self.vehicle,
            partId,
            grade,
            VehicleArmorConfig.Time[grade] or 200
        )

        local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
        if action and (inVehicle or not action.isValid or action:isValid()) then
            VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
            queued = queued + 1
        end
    end

    if queued > 0 then
        local suffix = ""
        if selectedCount > queued then
            suffix = " (" .. tostring(queued) .. "/" .. tostring(selectedCount) .. " affordable)"
        end

        self.character:Say("Queued " .. tostring(queued) .. " mixed-grade armor installs." .. suffix)
        self:clearInstallSelection(false)
        self:close()
    else
        self.character:Say("No installable selected armor for this grade.")
    end
end
