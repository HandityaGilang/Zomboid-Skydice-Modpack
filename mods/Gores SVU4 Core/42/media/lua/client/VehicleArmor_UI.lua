--========================================================
-- VEHICLE ARMOR UI  (B42.19)
-- Client only.  Radial menu hooks live in
-- VehicleArmor_RadialMenu.lua — do NOT add hooks here.
--
-- Changes from previous version:
--   • getRecipeReport: WeldingRods counted by mod-owned fractional amount
--   • getRecipeReport: FuelUse is now read per-grade from
--     Config (FuelUse.Install[grade] etc.) instead of the
--     old flat FuelUse.Install value.
--   • prerender: torchNeeded reads per-grade fuel cost.
--   • prerender: rods displayed in material requirements.
--   • onActionButtonClick: uninstall time scales with grade.
--   • onRepairButtonClick: time derived by timed action.
--   • Torch scan nil-guards getFluidContainer / getAmount
--     for B42 fluid API compatibility.
--========================================================

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
pcall(require, "ISUI/ISVehicleMenu")
require "VehicleArmor_Config"
require "VehicleArmor_ConsumeHelpers"

VehicleArmorWindow = ISPanel:derive("VehicleArmorWindow")
_G.VehicleArmorWindow = VehicleArmorWindow

-- UI preference fallback. Player modData is still used where available,
-- but this keeps the last grade stable during the same game session even
-- when the UI is reopened from different radial contexts.
GSVU4Core = GSVU4Core or {}
GSVU4Core.UIState = GSVU4Core.UIState or {}

----------------------------------------------------------
-- UI COLOUR / STATUS HELPERS
----------------------------------------------------------
local function GAA_GetArmorHealthColor(hp)
    hp = tonumber(hp) or 0

    if hp <= 0 then
        return {r=0.95, g=0.35, b=0.25}
    elseif hp < 35 then
        return {r=0.95, g=0.35, b=0.25}
    elseif hp < 70 then
        return {r=0.95, g=0.75, b=0.25}
    end

    return {r=0.25, g=0.85, b=0.25}
end

local function GAA_GetGasLeakColor()
    return {r=1.00, g=0.50, b=0.10}
end

local function GAA_IsGasTankPart(partId)
    return VehicleArmorConfig
       and VehicleArmorConfig.isGasTankPart
       and VehicleArmorConfig.isGasTankPart(partId)
end

local function GAA_GetProtectionAbsorbPercent(grade)
    if VehicleArmorConfig
    and VehicleArmorConfig.getProtectionPercent
    then
        return math.max(0, math.min(100, math.floor(VehicleArmorConfig.getProtectionPercent(grade) + 0.5)))
    end

    local passThrough = VehicleArmorConfig
        and VehicleArmorConfig.Protection
        and VehicleArmorConfig.Protection[grade]

    passThrough = tonumber(passThrough) or 1.0
    return math.max(0, math.min(100, math.floor(((1.0 - passThrough) * 100) + 0.5)))
end

local function GAA_GetArmorDurabilityText(grade)
    local value = VehicleArmorConfig
        and VehicleArmorConfig.ArmorDurability
        and VehicleArmorConfig.ArmorDurability[grade]

    value = tonumber(value) or 1.0

    if value > 1.05 then
        return string.format("Armor Wear: %.2fx faster", value)
    elseif value < 0.95 then
        return string.format("Armor Wear: %.2fx slower", value)
    end

    return "Armor Wear: normal"
end

----------------------------------------------------------
-- INITIALISE
----------------------------------------------------------
function VehicleArmorWindow:initialise()
    ISPanel.initialise(self)
end

----------------------------------------------------------
-- CREATE CHILDREN
----------------------------------------------------------
function VehicleArmorWindow:createChildren()
    ISPanel.createChildren(self)

    -- Grade selector centred across the header.
    local tabY, tabW, tabH, tabGap = 56, 145, 28, 8
    local gradeCount = #VehicleArmorConfig.Grades
    local totalTabW = (gradeCount * tabW) + ((gradeCount - 1) * tabGap)
    local tabX = math.floor((self.width - totalTabW) / 2)
    self.gradeButtons = {}

    for _, grade in ipairs(VehicleArmorConfig.Grades) do
        local g   = grade
        local btn = ISButton:new(tabX, tabY, tabW, tabH, g, self, function()
            self:selectGrade(g)
        end)
        btn:initialise()
        self:addChild(btn)
        self.gradeButtons[g] = btn
        tabX = tabX + tabW + tabGap
    end

    -- Part list filter/sort buttons and left column
    local filterY = 96
    local sortY = 124
    local listY = 154
    local listW = 272
    local listH = self.height - listY - 88

    self.partFilter = self.partFilter or "All"
    self.partFilterButtons = {}

    local filters = {
        {key="All",       label="All",       x=58,  w=42},
        {key="Installed", label="Armored",   x=104, w=58},
        {key="Damaged",   label="Damaged",   x=166, w=60},
        {key="Unarmored", label="Empty",     x=230, w=52},
    }

    for _, filter in ipairs(filters) do
        local f = filter.key
        local btn = ISButton:new(filter.x, filterY, filter.w, 22, filter.label, self, function()
            self:setPartFilter(f)
        end)
        btn:initialise()
        self:addChild(btn)
        self.partFilterButtons[f] = btn
    end

    self.partSort = self.partSort or "Alpha"
    self.partSortButtons = {}

    local sorts = {
        {key="Alpha",        label="A-Z",      x=58,  w=42},
        {key="DamagedFirst", label="Damage",   x=104, w=58},
        {key="InstalledFirst", label="Armor",  x=166, w=60},
        {key="UnarmoredFirst", label="Empty",  x=230, w=52},
    }

    for _, sort in ipairs(sorts) do
        local s = sort.key
        local btn = ISButton:new(sort.x, sortY, sort.w, 22, sort.label, self, function()
            self:setPartSort(s)
        end)
        btn:initialise()
        self:addChild(btn)
        self.partSortButtons[s] = btn
    end

    self.partListBox = ISPanel:new(10, listY, listW, listH)
    self.partListBox:initialise()
    self.partListBox.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self:addChild(self.partListBox)

    self.partList = ISScrollingListBox:new(14, listY + 4, listW - 8, listH - 8)
    self.partList:initialise()
    self.partList:instantiate()
    self.partList.itemheight = 22
    self.partList.font = UIFont.Small

    local armorWindow = self
    self.partList.doDrawItem = function(list, y, item, alt)
        if not item then
            return y + list.itemheight
        end

        local rowData = item.item
        local partId  = rowData and rowData.partId
        local label   = item.text or (rowData and rowData.name) or ""

        local armor = nil
        local leaking = false

        if armorWindow.vehicle and partId then
            local vdata = armorWindow.vehicle:getModData()
            armor = vdata
                and vdata.gArmor
                and vdata.gArmor[partId]

            leaking = vdata
                and vdata.gArmorGasLeak == true
                and GAA_IsGasTankPart(partId)
        end

        if item.index and list.selected == item.index then
            list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55)
        elseif alt then
            list:drawRect(0, y, list.width, list.itemheight, 0.12, 0.08, 0.08, 0.08)
        end

        local r, g, b = 0.75, 0.75, 0.75

        if leaking then
            local c = GAA_GetGasLeakColor()
            r, g, b = c.r, c.g, c.b
            label = label .. "  [LEAKING]"
        elseif armor then
            local c = GAA_GetArmorHealthColor(armor.health or 0)
            r, g, b = c.r, c.g, c.b
        end

        list:drawText(label, 8, y + 3, r, g, b, 1, list.font or UIFont.Small)

        return y + list.itemheight
    end

    self.partList.onmousedown = function()
        local list = self.partList
        local row  = list.selected
        if row and row > 0 and list.items[row] then
            self:onSelectPart(list.items[row].item)
        end
    end

    self:addChild(self.partList)

    -- Detail panel (centre column)
    local detailX = 300
    self.detailBox = ISPanel:new(detailX, listY, 330, listH)
    self.detailBox:initialise()
    self.detailBox.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self:addChild(self.detailBox)

    -- Overview panel (right column)
    local overviewX = detailX + self.detailBox.width + 18
    self.overviewBox = ISPanel:new(overviewX, listY, self.width - overviewX - 10, listH)
    self.overviewBox:initialise()
    self.overviewBox.backgroundColor = {r=0, g=0, b=0, a=0.5}
    self:addChild(self.overviewBox)

    -- Bottom buttons, left to right:
    -- Repair All | Repair | Uninstall All | Install Missing | Install/Uninstall selected
    local bottomY = self.height - 45
    local bottomW = 150
    local gap = 10
    local groupW = (bottomW * 5) + (gap * 4)
    local groupX = self.width - groupW - 10

    self.repairAllButton = ISButton:new(
        groupX, bottomY, bottomW, 32,
        "Repair All", self, self.onRepairAllButtonClick)
    self.repairAllButton:initialise()
    self:addChild(self.repairAllButton)

    self.repairButton = ISButton:new(
        groupX + bottomW + gap, bottomY, bottomW, 32,
        "Repair Armor", self, self.onRepairButtonClick)
    self.repairButton:initialise()
    self:addChild(self.repairButton)

    self.uninstallAllButton = ISButton:new(
        groupX + ((bottomW + gap) * 2), bottomY, bottomW, 32,
        "Uninstall All", self, self.onUninstallAllButtonClick)
    self.uninstallAllButton:initialise()
    self:addChild(self.uninstallAllButton)

    self.installAllButton = ISButton:new(
        groupX + ((bottomW + gap) * 3), bottomY, bottomW, 32,
        "Install Missing", self, self.onInstallAllButtonClick)
    self.installAllButton:initialise()
    self:addChild(self.installAllButton)

    self.actionButton = ISButton:new(
        groupX + ((bottomW + gap) * 4), bottomY, bottomW, 32,
        "Weld Armor", self, self.onActionButtonClick)
    self.actionButton:initialise()
    self:addChild(self.actionButton)

    self.showMaterialHelp = false
    self.materialHelpButton = ISButton:new(
        self.width - 172, 118, 150, 24,
        "Material Help", self, self.onMaterialHelpButtonClick)
    self.materialHelpButton:initialise()
    self:addChild(self.materialHelpButton)

    self.closeButton = ISButton:new(
        10, self.height - 45, 90, 32,
        "Close", self, self.close)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    local rememberedGrade = nil

    -- Prefer player modData, then same-session global fallback.
    if self.character and self.character.getModData then
        local md = self.character:getModData()
        rememberedGrade = md and md.GSVU4_LastArmorGrade
    end
    if not rememberedGrade and GSVU4Core and GSVU4Core.UIState then
        rememberedGrade = GSVU4Core.UIState.LastArmorGrade
    end

    local validRemembered = false
    if rememberedGrade and VehicleArmorConfig and VehicleArmorConfig.Grades then
        for _, g in ipairs(VehicleArmorConfig.Grades) do
            if g == rememberedGrade then
                validRemembered = true
                break
            end
        end
    end
    self.currentGrade = validRemembered and rememberedGrade or VehicleArmorConfig.Grades[1]
    self:updatePartFilterButtons()
    self:updatePartSortButtons()
end

----------------------------------------------------------
-- SELECT PART
----------------------------------------------------------
function VehicleArmorWindow:onSelectPart(item)
    if not item then return end
    self.selectedPart = item
    -- Do not rescan inventories just because the selected part changed.
    -- Inventory/material state only refreshes on UI open and grade change.
    self.pendingUninstallPartId = nil
    self.pendingUninstallAll = false
end

----------------------------------------------------------
-- PART FILTERS
----------------------------------------------------------
function VehicleArmorWindow:setPartFilter(filter)
    self.partFilter = filter or "All"
    self.pendingUninstallPartId = nil
    self.pendingUninstallAll = false
    self:updatePartFilterButtons()
    self:populateParts(self.vehicle)
end

function VehicleArmorWindow:updatePartFilterButtons()
    if not self.partFilterButtons then return end

    local colOff = {r=0.15, g=0.15, b=0.15, a=1}
    local colOn  = {r=0.25, g=0.35, b=0.50, a=1}

    for key, btn in pairs(self.partFilterButtons) do
        btn.backgroundColor = (key == self.partFilter) and colOn or colOff
    end
end

function VehicleArmorWindow:setPartSort(sort)
    self.partSort = sort or "Alpha"
    self.pendingUninstallPartId = nil
    self.pendingUninstallAll = false
    self:updatePartSortButtons()
    self:populateParts(self.vehicle)
end

function VehicleArmorWindow:updatePartSortButtons()
    if not self.partSortButtons then return end

    local colOff = {r=0.15, g=0.15, b=0.15, a=1}
    local colOn  = {r=0.25, g=0.35, b=0.50, a=1}

    for key, btn in pairs(self.partSortButtons) do
        btn.backgroundColor = (key == self.partSort) and colOn or colOff
    end
end

function VehicleArmorWindow:getPartSortScore(partId)
    local vdata = self.vehicle and self.vehicle:getModData()
    local armor = vdata and vdata.gArmor and vdata.gArmor[partId]
    local hp = armor and (tonumber(armor.health) or 0) or nil
    local sort = self.partSort or "Alpha"

    if sort == "DamagedFirst" then
        if armor and hp and hp < 100 then return 0 end
        if armor then return 1 end
        return 2
    elseif sort == "InstalledFirst" then
        return armor and 0 or 1
    elseif sort == "UnarmoredFirst" then
        return armor and 1 or 0
    end

    return 0
end

function VehicleArmorWindow:drawHeaderLabels()
    self:drawText("Filter", 12, 100, 0.95, 0.95, 0.95, 1, UIFont.Small)
    self:drawText("Sort",   12, 128, 0.95, 0.95, 0.95, 1, UIFont.Small)
end

function VehicleArmorWindow:drawColorLegend()
    local entries = {
        {label="Empty",    r=0.60, g=0.60, b=0.60, w=58},
        {label="Good",     r=0.30, g=0.80, b=0.30, w=52},
        {label="Damaged",  r=0.80, g=0.70, b=0.20, w=78},
        {label="Critical", r=0.80, g=0.30, b=0.30, w=66},
        {label="Leak",     r=1.00, g=0.50, b=0.10, w=48},
    }

    local totalW = 58
    for _, entry in ipairs(entries) do
        totalW = totalW + entry.w
    end

    local x = self.width - totalW - 28
    local y = 100

    self:drawText("Legend:", x, y, 1.00, 0.88, 0.50, 1, UIFont.Small)

    local lx = x + 58
    for _, entry in ipairs(entries) do
        self:drawRect(lx, y + 4, 8, 8, 1, entry.r, entry.g, entry.b)
        self:drawRectBorder(lx, y + 4, 8, 8, 0.7, 0.75, 0.75, 0.75)
        self:drawText(entry.label, lx + 12, y, 0.97, 0.97, 0.97, 1, UIFont.Small)
        lx = lx + entry.w
    end
end

function VehicleArmorWindow:partPassesFilter(partId)
    local filter = self.partFilter or "All"
    if filter == "All" then return true end

    local vdata = self.vehicle and self.vehicle:getModData()
    local armor = vdata and vdata.gArmor and vdata.gArmor[partId]

    if filter == "Installed" then
        return armor ~= nil
    elseif filter == "Unarmored" then
        return armor == nil
    elseif filter == "Damaged" then
        return armor ~= nil and (tonumber(armor.health) or 0) < 100
    end

    return true
end

----------------------------------------------------------
-- REPAIR ALL HELPERS
----------------------------------------------------------
function VehicleArmorWindow:getDamagedArmorPartIds()
    local result = {}

    if not self.vehicle then return result end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    if not armorData then return result end

    for partId, armor in pairs(armorData) do
        if armor and (tonumber(armor.health) or 0) < 100 then
            table.insert(result, {
                partId = partId,
                label  = self:getPrettyLabel(partId, self.vehicle and self.vehicle:getPartById(partId) or nil),
            })
        end
    end

    table.sort(result, function(a, b)
        return tostring(a.label):lower() < tostring(b.label):lower()
    end)

    return result
end


function VehicleArmorWindow:getRepairRecipeForPart(partId, armor)
    if not partId or not armor then return nil end

    local baseRecipe = VehicleArmorConfig.getRepairRecipe(partId, armor.grade)
    if not baseRecipe then return nil end

    if VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
        baseRecipe = VehicleArmorHelpers.getAdjustedRecipe(baseRecipe)
    end

    local missing = math.max(0, 100 - (tonumber(armor.health) or 0)) / 100
    local scaled = {}

    for mat, req in pairs(baseRecipe) do
        scaled[mat] = math.max(1, math.ceil(math.floor(req) * missing))
    end

    return scaled
end

function VehicleArmorWindow:canRepairArmorPart(partId, armor, report)
    if not partId or not armor or not report then return false end
    if (tonumber(armor.health) or 100) >= 100 then return false end

    if not report.hasHammer or not report.hasMask then
        return false
    end

    local grade = armor.grade or "Scrap"
    local fuelUse = VehicleArmorConfig.FuelUse.Repair[grade] or 1

    if (report.torchUnits or 0) < fuelUse then
        return false
    end

    local recipe = self:getRepairRecipeForPart(partId, armor)
    if not recipe then return false end

    for mat, req in pairs(recipe) do
        if (report[mat] or 0) + 0.0001 < (req or 0) then
            return false
        end
    end

    return true
end

function VehicleArmorWindow:getRepairAllStatus(report)
    local status = {
        damaged = 0,
        repairable = 0,
    }

    if not self.vehicle then return status end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    if not armorData then return status end

    for partId, armor in pairs(armorData) do
        if armor and (tonumber(armor.health) or 100) < 100 then
            status.damaged = status.damaged + 1

            if self:canRepairArmorPart(partId, armor, report) then
                status.repairable = status.repairable + 1
            end
        end
    end

    return status
end

function VehicleArmorWindow:getRepairAllQueue(report)
    local queue = {}

    if not self.vehicle or not report then return queue end
    if not report.hasHammer or not report.hasMask then return queue end

    local available = {
        scrap      = report.scrap or 0,
        sheets     = report.sheets or 0,
        bars       = report.bars or 0,
        screws     = report.screws or 0,
        wire       = report.wire or 0,
        rods       = report.rods or 0,
        torchUnits = report.torchUnits or 0,
    }

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if not armorData then return queue end

    local damaged = self:getDamagedArmorPartIds()

    for _, entry in ipairs(damaged) do
        local partId = entry.partId
        local armor = partId and armorData[partId]

        if armor and (tonumber(armor.health) or 100) < 100 then
            local grade = armor.grade or "Scrap"
            local fuelUse = VehicleArmorConfig.FuelUse.Repair[grade] or 1
            local recipe = self:getRepairRecipeForPart(partId, armor)
            local canQueue = recipe ~= nil and available.torchUnits >= fuelUse

            if canQueue and recipe then
                for mat, req in pairs(recipe) do
                    if (available[mat] or 0) + 0.0001 < (req or 0) then
                        canQueue = false
                        break
                    end
                end
            end

            if canQueue then
                table.insert(queue, partId)
                available.torchUnits = available.torchUnits - fuelUse

                for mat, req in pairs(recipe) do
                    available[mat] = (available[mat] or 0) - (req or 0)
                end
            end
        end
    end

    return queue
end

----------------------------------------------------------
-- UNINSTALL ALL HELPERS
----------------------------------------------------------
function VehicleArmorWindow:getInstalledArmorPartIds()
    local result = {}

    if not self.vehicle then return result end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    if not armorData then return result end

    for partId, armor in pairs(armorData) do
        if armor then
            table.insert(result, {
                partId = partId,
                label  = self:getPrettyLabel(partId, self.vehicle and self.vehicle:getPartById(partId) or nil),
            })
        end
    end

    table.sort(result, function(a, b)
        return tostring(a.label):lower() < tostring(b.label):lower()
    end)

    return result
end


----------------------------------------------------------
-- INSTALL MISSING QUEUE
-- Queues every affordable unarmored part in the current
-- visible part list using the active grade tab.
----------------------------------------------------------
local function GSVU4_CopyInstallBudget(report)
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

local function GSVU4_CanAffordRecipeFromBudget(budget, recipe)
    if not budget or not recipe then return false end
    for mat, req in pairs(recipe) do
        if (budget[mat] or 0) + 0.0001 < (tonumber(req) or 0) then
            return false
        end
    end
    return true
end

local function GSVU4_ReserveRecipeFromBudget(budget, recipe)
    if not budget or not recipe then return end
    for mat, req in pairs(recipe) do
        budget[mat] = (budget[mat] or 0) - (tonumber(req) or 0)
    end
end

function VehicleArmorWindow:getInstallAllQueue(report)
    local queue = {}
    if not self.vehicle or not self.partList or not self.partList.items then return queue end

    report = report or self.cachedReport or self:getRecipeReport()
    if not report then return queue end
    local grade = self.currentGrade or "Scrap"
    local toolReq = VehicleArmorHelpers and VehicleArmorHelpers.getInstallToolRequirements and VehicleArmorHelpers.getInstallToolRequirements(grade) or { hammer = true, weldingMask = true }
    if (toolReq.hammer and not report.hasHammer) or (toolReq.screwdriver and not report.hasScrewdriver) or (toolReq.weldingMask and not report.hasMask) then return queue end
    if report.skillReport and not report.skillReport.hasSkills then return queue end

    local vdata = self.vehicle:getModData()
    local armor = vdata and vdata.gArmor or {}

    local budget = GSVU4_CopyInstallBudget(report)

    for _, row in ipairs(self.partList.items) do
        local item = row and row.item
        local partId = item and item.partId
        if partId and not armor[partId] then
            local recipe = VehicleArmorConfig.getInstallRecipe(partId, grade)
            if recipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
                recipe = VehicleArmorHelpers.getAdjustedRecipe(recipe)
            end
            local fuelPerPanel = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(partId, grade) or (VehicleArmorConfig.FuelUse.Install[grade] or 0)
            if recipe
            and (budget.torchUnits or 0) + 0.0001 >= fuelPerPanel
            and GSVU4_CanAffordRecipeFromBudget(budget, recipe)
            then
                table.insert(queue, partId)
                budget.torchUnits = (budget.torchUnits or 0) - fuelPerPanel
                GSVU4_ReserveRecipeFromBudget(budget, recipe)
            end
        end
    end

    return queue
end

function VehicleArmorWindow:getUninstallAllStatus(report)
    local status = {
        installed = 0,
        removable = 0,
    }

    local queue = self:getUninstallAllQueue(report)
    status.removable = #queue
    status.installed = #self:getInstalledArmorPartIds()

    return status
end

function VehicleArmorWindow:getUninstallAllQueue(report)
    local queue = {}

    if not self.vehicle or not report then return queue end

    local availableFuel = report.torchUnits or 0
    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    if not armorData then return queue end

    for _, entry in ipairs(self:getInstalledArmorPartIds()) do
        local partId = entry.partId
        local armor = partId and armorData[partId]

        if armor then
            local grade = armor.grade or "Scrap"
            local fuelUse = VehicleArmorConfig.FuelUse.Uninstall[grade] or 1

            if availableFuel + 0.0001 >= fuelUse then
                local action = ISUninstallVehicleArmor:new(
                    self.character,
                    self.vehicle,
                    partId,
                    VehicleArmorConfig.Time[grade] or 200
                )

                local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
                if action and (inVehicle or not action.isValid or action:isValid()) then
                    table.insert(queue, partId)
                    availableFuel = availableFuel - fuelUse
                end
            end
        end
    end

    return queue
end

local function GAA_GetMaterialLabelSafe(mat)
    local labels = {
        scrap  = "Scrap Metal",
        sheets = "Sheet Metal",
        bars   = "Metal Bars",
        screws = "Screws",
        wire   = "Wire",
        rods   = "Welding Rods",
    }

    return labels[mat] or tostring(mat or "material")
end

function VehicleArmorWindow:getRepairAllBlockedReason(report)
    report = report or self.cachedReport or self:getRecipeReport()
    if not report then return "Requirements are not available yet." end

    local status = self:getRepairAllStatus(report)
    if status.damaged <= 0 then
        return "No damaged armor panels."
    end

    if not report.hasHammer then
        return "Missing Hammer."
    end

    if not report.hasMask then
        return "Missing Welding Mask."
    end

    local neededFuel = nil
    local neededMaterial = nil
    local vdata = self.vehicle and self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    for _, entry in ipairs(self:getDamagedArmorPartIds()) do
        local partId = entry.partId
        local armor = partId and armorData and armorData[partId]

        if armor and (tonumber(armor.health) or 100) < 100 then
            local grade = armor.grade or "Scrap"
            local fuelUse = VehicleArmorConfig.FuelUse.Repair[grade] or 1

            if (report.torchUnits or 0) + 0.0001 < fuelUse then
                neededFuel = fuelUse
            end

            local recipe = self:getRepairRecipeForPart(partId, armor)
            if recipe then
                for mat, req in pairs(recipe) do
                    if (report[mat] or 0) + 0.0001 < (req or 0) then
                        neededMaterial = GAA_GetMaterialLabelSafe(mat)
                        break
                    end
                end
            end
        end

        if neededFuel or neededMaterial then break end
    end

    if neededFuel then
        return string.format("Missing blowtorch fuel. Need %.1f units.", neededFuel)
    end

    if neededMaterial then
        return "Missing " .. tostring(neededMaterial) .. "."
    end

    return "No currently valid repair action."
end

function VehicleArmorWindow:getUninstallAllBlockedReason(report)
    report = report or self.cachedReport or self:getRecipeReport()
    if not report then return "Requirements are not available yet." end

    local status = self:getUninstallAllStatus(report)
    if status.installed <= 0 then
        return "No installed armor panels."
    end

    local minFuel = nil
    local vdata = self.vehicle and self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    for _, entry in ipairs(self:getInstalledArmorPartIds()) do
        local armor = entry.partId and armorData and armorData[entry.partId]
        if armor then
            local grade = armor.grade or "Scrap"
            local fuelUse = VehicleArmorConfig.FuelUse.Uninstall[grade] or 1
            if not minFuel or fuelUse < minFuel then
                minFuel = fuelUse
            end
        end
    end

    if minFuel and (report.torchUnits or 0) + 0.0001 < minFuel then
        return string.format("Missing blowtorch fuel. Need %.1f units.", minFuel)
    end

    return "No currently valid uninstall action."
end

function VehicleArmorWindow:getBulkActionStatus(report)
    report = report or self.cachedReport or self:getRecipeReport()
    if not report then return nil, nil end

    local repairStatus = self:getRepairAllStatus(report)
    local repairQueue = self:getRepairAllQueue(report)
    local uninstallStatus = self:getUninstallAllStatus(report)
    local uninstallQueue = self:getUninstallAllQueue(report)

    local repairLine = nil
    local uninstallLine = nil

    if repairStatus.damaged > 0 then
        if #repairQueue > 0 then
            repairLine = "Repair All: " .. tostring(#repairQueue) .. "/" .. tostring(repairStatus.damaged) .. " repairable."
        else
            repairLine = "Repair All blocked: " .. self:getRepairAllBlockedReason(report)
        end
    end

    if uninstallStatus.installed > 0 then
        if #uninstallQueue > 0 then
            uninstallLine = "Uninstall All: " .. tostring(#uninstallQueue) .. "/" .. tostring(uninstallStatus.installed) .. " removable."
        else
            uninstallLine = "Uninstall All blocked: " .. self:getUninstallAllBlockedReason(report)
        end
    end

    return repairLine, uninstallLine
end

function VehicleArmorWindow:drawBulkActionStatus(x, y, report)
    local repairLine, uninstallLine = self:getBulkActionStatus(report)
    if not repairLine and not uninstallLine then return y end

    self:drawText("BULK ACTION STATUS:", x, y, 1.00, 0.88, 0.50, 1, UIFont.Small)
    y = y + 16

    local function drawLine(line)
        if not line then return end

        local blocked = tostring(line):find("blocked", 1, true) ~= nil
        local c = blocked and {r=0.95, g=0.35, b=0.25} or {r=0.55, g=0.88, b=1.0}

        self:drawText(line, x + 8, y, c.r, c.g, c.b, 1, UIFont.Small)
        y = y + 15
    end

    drawLine(repairLine)
    drawLine(uninstallLine)

    return y + 4
end

function VehicleArmorWindow:updateBulkButtons(report)
    report = report or self.cachedReport or self:getRecipeReport()

    if self.repairAllButton then
        local repairStatus = self:getRepairAllStatus(report)
        local repairQueue = self:getRepairAllQueue(report)

        if repairStatus.damaged > 0 and #repairQueue <= 0 then
            self.repairAllButton:setTitle("Repair All Blocked")
        else
            self.repairAllButton:setTitle(
                #repairQueue > 0
                and ("Repair All (" .. tostring(#repairQueue) .. "/" .. tostring(repairStatus.damaged) .. ")")
                or "Repair All"
            )
        end

        self.repairAllButton:setEnable(#repairQueue > 0)
    end

    if self.uninstallAllButton then
        local uninstallStatus = self:getUninstallAllStatus(report)
        local uninstallQueue = self:getUninstallAllQueue(report)

        if uninstallStatus.installed > 0 and #uninstallQueue <= 0 then
            self.uninstallAllButton:setTitle("Uninstall All Blocked")
            self.pendingUninstallAll = false
        elseif self.pendingUninstallAll and #uninstallQueue > 0 then
            self.uninstallAllButton:setTitle("Confirm Uninstall All")
        else
            self.uninstallAllButton:setTitle(
                #uninstallQueue > 0
                and ("Uninstall All (" .. tostring(#uninstallQueue) .. "/" .. tostring(uninstallStatus.installed) .. ")")
                or "Uninstall All"
            )
        end

        self.uninstallAllButton:setEnable(#uninstallQueue > 0)
    end

    if self.installAllButton then
        local installQueue = self:getInstallAllQueue(report)
        if #installQueue > 0 then
            self.installAllButton:setTitle("Install Missing (" .. tostring(#installQueue) .. ")")
            self.installAllButton:setEnable(true)
        else
            self.installAllButton:setTitle("Install Missing")
            self.installAllButton:setEnable(false)
        end
    end
end


function VehicleArmorWindow:updateBulkButtonsCached(report)
    -- Event-driven bulk queue cache.
    -- Runs once when the UI opens, and again when marked dirty by grade
    -- changes or explicit bulk-button clicks.
    if self.bulkButtonsDirty or not self.bulkButtonsInitialized then
        VehicleArmorWindow.updateBulkButtons(self, report)
        self.bulkButtonsDirty = false
        self.bulkButtonsInitialized = true
    end
end

local function GSVU4_GetUITickStamp()
    if getTimestampMs then
        local ok, value = pcall(getTimestampMs)
        if ok and value then return tonumber(value) or 0 end
    end
    if getTimestamp then
        local ok, value = pcall(getTimestamp)
        if ok and value then return (tonumber(value) or 0) * 1000 end
    end
    return 0
end

function VehicleArmorWindow:maybeRefreshInventoryReport()
    -- Low-frequency UI-open refresh for external inventory changes such as
    -- This is intentionally conservative for busy MP servers and does not run every frame.
    local now = GSVU4_GetUITickStamp()
    local interval = 4000

    if not self.cachedReport then
        return self:forceInventoryReportRefresh()
    end

    if not self.gsvu4LastPassiveInventoryScan then
        self.gsvu4LastPassiveInventoryScan = now
        return self.cachedReport
    end

    if now > 0 and now - self.gsvu4LastPassiveInventoryScan >= interval then
        self.gsvu4LastPassiveInventoryScan = now
        return self:forceInventoryReportRefresh()
    end

    return self.cachedReport
end

function VehicleArmorWindow:forceInventoryReportRefresh()
    -- Explicit action-time rescan.
    -- The UI can cache while idle, but button clicks must use a live inventory
    -- snapshot so MP server validation does not disagree with a stale UI report.
    local report = self:getRecipeReport()
    self.cachedReport = report
    self.reportDirty = false
    self.bulkButtonsDirty = true
    self.gsvu4SelectedTotalsDirty = true
    return report
end

function VehicleArmorWindow:refreshBulkActionState()
    -- This is called from explicit bulk/action button paths. Always rescan here.
    local report = self:forceInventoryReportRefresh()

    VehicleArmorWindow.updateBulkButtons(self, report)
    self.bulkButtonsDirty = false
    self.bulkButtonsInitialized = true
    return report
end

----------------------------------------------------------
-- POPULATE PART LIST
----------------------------------------------------------
function VehicleArmorWindow:populateParts(vehicle)
    self.partList:clear()
    local v = vehicle or self.vehicle
    if not v then return end

    local added = {}
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

                        table.insert(rows, {
                            label = label,
                            partId = id,
                        })

                        added[id] = true
                    end
                end
            end
        end
    end)

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
        })
    end

    if self.partList.items and #self.partList.items > 0 then
        self.unsupportedVehicle = false
        self.emptyFilter        = false
        self.partList.selected  = 1
        self.selectedPart       = self.partList.items[1].item
        -- Inventory cache intentionally left unchanged here.
    else
        self.selectedPart       = nil
        -- Inventory cache intentionally left unchanged here.
        self.unsupportedVehicle = (self.partFilter or "All") == "All"
        self.emptyFilter        = not self.unsupportedVehicle
    end

    self:updatePartFilterButtons()
end

----------------------------------------------------------
-- PRETTY LABELS
----------------------------------------------------------
function VehicleArmorWindow:getPrettyLabel(id, part)
    if VehicleArmorConfig and VehicleArmorConfig.getSmartPartLabel then
        return VehicleArmorConfig.getSmartPartLabel(id, part, self.vehicle)
    end

    if VehicleArmorConfig and VehicleArmorConfig.getPartLabel then
        return VehicleArmorConfig.getPartLabel(id)
    end

    return tostring(id or "")
end

----------------------------------------------------------
-- SELECT GRADE
----------------------------------------------------------
function VehicleArmorWindow:selectGrade(grade)
    self.currentGrade = grade
    GSVU4Core = GSVU4Core or {}
    GSVU4Core.UIState = GSVU4Core.UIState or {}
    GSVU4Core.UIState.LastArmorGrade = grade
    if self.character and self.character.getModData then
        self.character:getModData().GSVU4_LastArmorGrade = grade
    end
    -- Grade changes alter install recipe requirements, so this is one of
    -- the only times the UI intentionally rescans accessible inventories.
    self.reportDirty  = true
    self.bulkButtonsDirty = true
    self.pendingUninstallPartId = nil
    self.pendingUninstallAll = false

    local colOff = {r=0.15, g=0.15, b=0.15, a=1}
    local colOn  = {r=0.25, g=0.35, b=0.50, a=1}

    for g, btn in pairs(self.gradeButtons) do
        btn.backgroundColor = (g == grade) and colOn or colOff
    end
end

----------------------------------------------------------
-- HEADLIGHT CHECK
----------------------------------------------------------
function VehicleArmorWindow:isHeadlight()
    if not self.selectedPart then return false end
    return VehicleArmorConfig.isHeadlightPart
       and VehicleArmorConfig.isHeadlightPart(self.selectedPart.partId)
end

function VehicleArmorWindow:isGasTank()
    if not self.selectedPart then return false end
    return VehicleArmorConfig.isGasTankPart
       and VehicleArmorConfig.isGasTankPart(self.selectedPart.partId)
end

----------------------------------------------------------
-- PRETTY MATERIAL LABELS
-- Maps internal config keys to readable display names.
----------------------------------------------------------
local MAT_LABEL = {
    scrap  = "Scrap Metal",
    sheets = "Sheet Metal",
    bars   = "Metal Bars",
    screws = "Screws",
    wire   = "Wire",
    rods   = "Welding Rods",
}

local function getSortedMaterialKeys(recipe)
    local keys = {}

    if not recipe then
        return keys
    end

    for mat, _ in pairs(recipe) do
        table.insert(keys, mat)
    end

    table.sort(keys, function(a, b)
        local labelA = tostring(MAT_LABEL[a] or a):lower()
        local labelB = tostring(MAT_LABEL[b] or b):lower()

        if labelA == labelB then
            return tostring(a) < tostring(b)
        end

        return labelA < labelB
    end)

    return keys
end

local function GAA_UIGetGasTankPunctureDamage()
    if VehicleArmorConfig and VehicleArmorConfig.getGasTankPunctureDamage then
        return VehicleArmorConfig.getGasTankPunctureDamage()
    end

    return 20
end

local function GAA_UIApplyGasTankPunctureDamage(vehicle, vdata)
    if not vehicle or not vdata then return false end
    if vdata.gArmorGasLeakPunctureApplied then return false end
    if not vehicle.getPartById then return false end

    local part = vehicle:getPartById("GasTank")
    if not part or not part.getCondition or not part.setCondition then return false end

    local current = part:getCondition() or 100
    local damage = GAA_UIGetGasTankPunctureDamage()

    if damage <= 0 then
        vdata.gArmorGasLeakPunctureApplied = true
        return false
    end

    local nextCondition = math.max(0, current - damage)
    part:setCondition(nextCondition)

    if vehicle.transmitPartCondition then
        vehicle:transmitPartCondition(part)
    end

    vdata.gArmorGasLeakPunctureApplied = true
    return true
end

----------------------------------------------------------
-- WELDING ROD AMOUNT
-- B42 WeldingRods behave as a drainable item. For UI
-- purposes we count the remaining usedDelta directly:
--   usedDelta 1.0 = one full WeldingRods item
--   usedDelta 0.5 = half a WeldingRods item
-- Example config: rods = 0.1 consumes 10% of one item.
----------------------------------------------------------
local function getRodFraction(item)
    if not item then return 0 end

    -- Preferred path: mod-owned fractional amount.
    -- WeldingRods may not support getUsedDelta/setUsedDelta,
    -- or may be consumed as a whole item by item:Use().
    if item.getModData then
        local md = item:getModData()
        if md then
            if md.GAA_RodAmount == nil then
                md.GAA_RodAmount = 1.0
            end

            local amount = tonumber(md.GAA_RodAmount) or 0
            if amount > 0 then
                return amount
            end
        end
    end

    -- Fallback only for unusual item variants that genuinely
    -- expose drainable state.
    if item.getUsedDelta then
        local okDelta, delta = pcall(function()
            return item:getUsedDelta()
        end)

        if okDelta and delta and delta > 0 then
            return delta
        end
    end

    -- Final fallback: count a plain WeldingRods item as full.
    return 1.0
end

----------------------------------------------------------
-- RECIPE REPORT
-- Scans the player inventory and checks it against the
-- current grade recipe. Cached every 30 frames or when
-- the dirty flag is set.
----------------------------------------------------------
function VehicleArmorWindow:getRecipeReport()
    local report = {
        hasMask    = false,
        hasHammer  = false,
        hasScrewdriver = false,
        torchUnits = 0,

        scrap      = 0,
        sheets     = 0,
        bars       = 0,
        screws     = 0,
        wire       = 0,
        rods       = 0,

        canCraft   = true,
        canRepair  = true,

        skillReport = nil,
    }

    if not self.character then return report end

    if VehicleArmorHelpers and VehicleArmorHelpers.countMaterialsForCharacter then
        local mats = VehicleArmorHelpers.countMaterialsForCharacter(self.character)

        report.scrap  = mats.scrap or 0
        report.sheets = mats.sheets or 0
        report.bars   = mats.bars or 0
        report.screws = mats.screws or 0
        report.wire   = mats.wire or 0
        report.rods   = mats.rods or 0
    end

    if VehicleArmorHelpers
    and VehicleArmorHelpers.getAccessibleInventories
    then
        local inventories = VehicleArmorHelpers.getAccessibleInventories(self.character)

        for _, inv in ipairs(inventories) do
            local items = inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item then
                        local t = item.getType and item:getType() or ""
                        local ft = item.getFullType and item:getFullType() or ""

                        if t == "WeldingMask" or ft == "Base.WeldingMask" then
                            report.hasMask = true
                        end

                        if VehicleArmorHelpers.isHammerItem
                        and VehicleArmorHelpers.isHammerItem(item)
                        then
                            report.hasHammer = true
                        end

                        if VehicleArmorHelpers.isScrewdriverItem
                        and VehicleArmorHelpers.isScrewdriverItem(item)
                        then
                            report.hasScrewdriver = true
                        end
                    end
                end
            end
        end
    end

    if VehicleArmorHelpers and VehicleArmorHelpers.getTotalTorchFuel then
        report.torchUnits = VehicleArmorHelpers.getTotalTorchFuel(self.character)
    elseif VehicleArmorHelpers and VehicleArmorHelpers.findTorch then
        local torch = VehicleArmorHelpers.findTorch(self.character)
        if torch and VehicleArmorHelpers.getTorchFuel then
            report.torchUnits = VehicleArmorHelpers.getTorchFuel(torch)
        end
    end

    ------------------------------------------------
    -- TOOL GATES
    ------------------------------------------------
    local armorToolReq = VehicleArmorHelpers and VehicleArmorHelpers.getInstallToolRequirements and VehicleArmorHelpers.getInstallToolRequirements(self.currentGrade) or { hammer = true, weldingMask = true }
    if (armorToolReq.hammer and not report.hasHammer)
    or (armorToolReq.screwdriver and not report.hasScrewdriver)
    or (armorToolReq.weldingMask and not report.hasMask)
    then
        report.canCraft = false
    end
    if not report.hasMask or not report.hasHammer then
        report.canRepair = false
    end

    ------------------------------------------------
    -- TORCH REQUIREMENTS
    ------------------------------------------------
    local selectedPartIdForFuel = self.selectedPart and self.selectedPart.partId or nil
    local installFuel = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(selectedPartIdForFuel, self.currentGrade) or (VehicleArmorConfig.FuelUse.Install[self.currentGrade] or 0)
    local repairFuel  = VehicleArmorConfig.FuelUse.Repair[self.currentGrade] or 0

    if installFuel > 0 and (report.torchUnits or 0) < installFuel then
        report.canCraft = false
    end

    if repairFuel > 0 and (report.torchUnits or 0) < repairFuel then
        report.canRepair = false
    end

    ------------------------------------------------
    -- PART VALIDATION
    ------------------------------------------------
    if not self.selectedPart then
        report.canCraft  = false
        report.canRepair = false
        return report
    end

    ------------------------------------------------
    -- SKILL REQUIREMENTS FOR INSTALLING CURRENT GRADE
    ------------------------------------------------
    if VehicleArmorHelpers and VehicleArmorHelpers.getSkillRequirementReport then
        report.skillReport = VehicleArmorHelpers.getSkillRequirementReport(
            self.character,
            self.currentGrade
        )

        if report.skillReport and not report.skillReport.hasSkills then
            report.canCraft = false
        end
    end

    ------------------------------------------------
    -- INSTALL REQUIREMENTS
    ------------------------------------------------
    local installRecipe = VehicleArmorConfig.getInstallRecipe(
        self.selectedPart.partId,
        self.currentGrade
    )

    if installRecipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
        installRecipe = VehicleArmorHelpers.getAdjustedRecipe(installRecipe)
    end

    if installRecipe then
        for mat, req in pairs(installRecipe) do
            if (report[mat] or 0) < req then
                report.canCraft = false
            end
        end
    else
        report.canCraft = false
    end

    ------------------------------------------------
    -- REPAIR REQUIREMENTS
    ------------------------------------------------
    local vdata = self.vehicle:getModData()
    local armor = vdata.gArmor and vdata.gArmor[self.selectedPart.partId]

    if armor and armor.health and armor.health < 100 then
        local missing = (100 - armor.health) / 100

        local repairRecipe = VehicleArmorConfig.getRepairRecipe(
            self.selectedPart.partId,
            armor.grade
        )

        report.repairReq = {}

        if repairRecipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
            repairRecipe = VehicleArmorHelpers.getAdjustedRecipe(repairRecipe)
        end

        if repairRecipe then
            for mat, req in pairs(repairRecipe) do
                local scaled = math.max(1, math.ceil(math.floor(req) * missing))

                report.repairReq[mat] = scaled

                if (report[mat] or 0) < scaled then
                    report.canRepair = false
                end
            end
        end
    else
        report.canRepair = false
    end

    return report
end


----------------------------------------------------------
-- INSTALL MISSING BUTTON
----------------------------------------------------------
function VehicleArmorWindow:onInstallAllButtonClick()
    if not self.vehicle then return end

    local report = self:refreshBulkActionState()
    local queue = self:getInstallAllQueue(report)

    if #queue <= 0 then
        self.character:Say("No installable missing armor for this grade.")
        return
    end

    if GSVU4Core and GSVU4Core.UIState then
        GSVU4Core.UIState.LastArmorGrade = self.currentGrade
    end
    if self.character and self.character.getModData then
        self.character:getModData().GSVU4_LastArmorGrade = self.currentGrade
    end

    local queued = 0
    for _, partId in ipairs(queue) do
        local action = ISWeldVehicleArmor:new(
            self.character,
            self.vehicle,
            partId,
            self.currentGrade,
            VehicleArmorConfig.Time[self.currentGrade] or 200
        )
        local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
        if action and (inVehicle or not action.isValid or action:isValid()) then
            VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
            queued = queued + 1
        end
    end

    if queued > 0 then
        self.character:Say("Queued " .. tostring(queued) .. " " .. tostring(self.currentGrade) .. " armor installs.")
        self:close()
    else
        self.character:Say("No installable missing armor for this grade.")
    end
end

----------------------------------------------------------
-- ACTION BUTTON  (Install or Uninstall)
----------------------------------------------------------
function VehicleArmorWindow:onActionButtonClick()
    if not self.selectedPart then return end

    local vdata    = self.vehicle:getModData()
    local existing = vdata.gArmor and vdata.gArmor[self.selectedPart.partId]
    local report   = self:refreshBulkActionState()

    if existing then
        if self.pendingUninstallPartId ~= self.selectedPart.partId then
            self.pendingUninstallPartId = self.selectedPart.partId
            self.actionButton:setTitle("Confirm Uninstall")
            self.character:Say("Click again to confirm uninstall.")
            return
        end

        -- Uninstall: scale time to installed grade
        local grade = existing.grade or "Scrap"
        local time  = VehicleArmorConfig.Time[grade] or 200
        local action = ISUninstallVehicleArmor:new(
            self.character, self.vehicle, self.selectedPart.partId, time)

        local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
        if (not inVehicle) and (not action or not action.isValid or not action:isValid()) then
            self.character:Say("Missing blowtorch fuel.")
            self.pendingUninstallPartId = nil
            self.pendingUninstallAll = false
            self.actionButton:setTitle("Uninstall Armor Panel")
            return
        end

        VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, self.selectedPart.partId, action)
        self:close()
        return
    end

    if not report.canCraft then
        if report.skillReport and not report.skillReport.hasSkills then
            self.character:Say("Missing skill requirements.")
        else
            self.character:Say("Missing required materials.")
        end
        return
    end

    -- Store the actual grade used for this install, so the next UI open
    -- returns to the last installed grade rather than the default tab.
    if GSVU4Core and GSVU4Core.UIState then
        GSVU4Core.UIState.LastArmorGrade = self.currentGrade
    end
    if self.character and self.character.getModData then
        self.character:getModData().GSVU4_LastArmorGrade = self.currentGrade
    end

    local time = VehicleArmorConfig.Time[self.currentGrade] or 200
    local action = ISWeldVehicleArmor:new(
        self.character, self.vehicle,
        self.selectedPart.partId, self.currentGrade, time)
    VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, self.selectedPart.partId, action)
    self:close()
end

----------------------------------------------------------
-- REPAIR BUTTON
----------------------------------------------------------
function VehicleArmorWindow:onRepairButtonClick()
    if not self.selectedPart then return end

    local report = self:refreshBulkActionState()
    if not report.canRepair then
        self.character:Say("Missing repair materials.")
        return
    end

    local vdata = self.vehicle:getModData()
    local armor = vdata.gArmor and vdata.gArmor[self.selectedPart.partId]
    if not armor then return end

    -- No time arg — ISRepairVehicleArmor derives it from missing HP
    local action = ISRepairVehicleArmor:new(
        self.character, self.vehicle, self.selectedPart.partId)
    VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, self.selectedPart.partId, action)
    self:close()
end

----------------------------------------------------------
-- REPAIR ALL BUTTON
----------------------------------------------------------
function VehicleArmorWindow:onRepairAllButtonClick()
    if not self.vehicle then return end

    local report = self:refreshBulkActionState()
    local status = self:getRepairAllStatus(report)

    if status.damaged <= 0 then
        self.character:Say("No damaged armor to repair.")
        return
    end

    if status.repairable <= 0 then
        self.character:Say("Missing requirements to repair armor.")
        return
    end

    local queue = self:getRepairAllQueue(report)
    local queued = 0

    for _, partId in ipairs(queue) do
        if partId then
            local action = ISRepairVehicleArmor:new(
                self.character, self.vehicle, partId)

            local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
            if action and (inVehicle or not action.isValid or action:isValid()) then
                VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
                queued = queued + 1
            end
        end
    end

    if queued > 0 then
        if queued < status.damaged then
            self.character:Say("Queued " .. tostring(queued) .. "/" .. tostring(status.damaged) .. " armor repairs.")
        else
            self.character:Say("Queued all " .. tostring(queued) .. " armor repairs.")
        end
        self:close()
    else
        self.character:Say("Missing requirements to repair armor.")
    end
end

----------------------------------------------------------
-- UNINSTALL ALL BUTTON
----------------------------------------------------------
function VehicleArmorWindow:onUninstallAllButtonClick()
    if not self.vehicle then return end

    local report = self:refreshBulkActionState()
    local status = self:getUninstallAllStatus(report)

    if status.installed <= 0 then
        self.character:Say("No armor installed to uninstall.")
        return
    end

    if status.removable <= 0 then
        self.character:Say("Missing blowtorch fuel to uninstall armor.")
        return
    end

    local queue = self:getUninstallAllQueue(report)

    if not self.pendingUninstallAll then
        self.pendingUninstallAll = true
        if self.uninstallAllButton then
            self.uninstallAllButton:setTitle("Confirm Uninstall All")
        end
        self.character:Say("Click again to uninstall all armor.")
        return
    end

    self.pendingUninstallAll = false
    local queued = 0

    for _, partId in ipairs(queue) do
        local vdata = self.vehicle:getModData()
        local armor = vdata and vdata.gArmor and vdata.gArmor[partId]

        if armor then
            local grade = armor.grade or "Scrap"
            local action = ISUninstallVehicleArmor:new(
                self.character,
                self.vehicle,
                partId,
                VehicleArmorConfig.Time[grade] or 200
            )

            local inVehicle = VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character)
            if action and (inVehicle or not action.isValid or action:isValid()) then
                VehicleArmor_QueueVehicleArmorAction(self.character, self.vehicle, partId, action)
                queued = queued + 1
            end
        end
    end

    if queued > 0 then
        if queued < status.installed then
            self.character:Say("Queued " .. tostring(queued) .. "/" .. tostring(status.installed) .. " armor removals.")
        else
            self.character:Say("Queued all " .. tostring(queued) .. " armor removals.")
        end
        self:close()
    else
        self.character:Say("Missing blowtorch fuel to uninstall armor.")
    end
end


----------------------------------------------------------
-- MATERIAL HELP TOOLTIP
----------------------------------------------------------
function VehicleArmorWindow:onMaterialHelpButtonClick()
    self.showMaterialHelp = not self.showMaterialHelp
end

function VehicleArmorWindow:isMaterialHelpButtonHovered()
    if not self.materialHelpButton then return false end

    if self.materialHelpButton.isMouseOver then
        local ok, hovered = pcall(function()
            return self.materialHelpButton:isMouseOver()
        end)
        if ok and hovered then return true end
    end

    return false
end

function VehicleArmorWindow:drawMaterialHelpTooltip()
    if not self.showMaterialHelp and not self:isMaterialHelpButtonHovered() then
        return
    end

    local x = self.width - 420
    local y = 132
    local w = 400
    local h = 118

    self:drawRect(x, y, w, h, 0.92, 0.04, 0.04, 0.04)
    self:drawRectBorder(x, y, w, h, 0.95, 0.75, 0.75, 0.75)

    y = y + 8
    self:drawText("Material conversion help", x + 10, y, 1.0, 1.0, 1.0, 1, UIFont.Small)
    y = y + 18
    self:drawText("Sheets: full sheet = 1.0, small sheet = 0.25", x + 10, y, 0.97, 0.97, 0.97, 1, UIFont.Small)
    y = y + 16
    self:drawText("Bars: full bar = 1.0, half bar = 0.5, quarter bar = 0.25", x + 10, y, 0.97, 0.97, 0.97, 1, UIFont.Small)
    y = y + 16
    self:drawText("Welding rods support partial use where recipes need fractions.", x + 10, y, 0.97, 0.97, 0.97, 1, UIFont.Small)
    y = y + 16
    self:drawText("Counts include accessible inventory, containers, and nearby items.", x + 10, y, 0.70, 0.82, 0.95, 1, UIFont.Small)
end

----------------------------------------------------------
-- ARMOR OVERVIEW
----------------------------------------------------------
local function GAA_BuildArmorOverviewSignature(vehicle)
    if not vehicle or not vehicle.getModData then return "no-vehicle" end

    local vdata = vehicle:getModData()
    local armorData = vdata and vdata.gArmor
    if type(armorData) ~= "table" then
        return tostring(vdata and vdata.gArmorGasLeak or false) .. "|none"
    end

    local keys = {}
    for partId, _ in pairs(armorData) do
        keys[#keys + 1] = tostring(partId)
    end
    table.sort(keys)

    local bits = { tostring(vdata and vdata.gArmorGasLeak or false) }
    for _, partId in ipairs(keys) do
        local armor = armorData[partId]
        if type(armor) == "table" then
            bits[#bits + 1] = partId
                .. ":" .. tostring(armor.grade or "")
                .. ":" .. tostring(math.floor(tonumber(armor.health) or 0))
        else
            bits[#bits + 1] = partId .. ":" .. tostring(armor)
        end
    end

    return table.concat(bits, "|")
end

function VehicleArmorWindow:getArmorOverview()
    local overview = {
        count       = 0,
        totalWeight = 0,
        totalHealth = 0,
        critical    = 0,
        leaking     = false,
        entries     = {},
    }

    if not self.vehicle then
        return overview
    end

    local vdata = self.vehicle:getModData()
    local armorData = vdata and vdata.gArmor

    if not armorData then
        return overview
    end

    for partId, armor in pairs(armorData) do
        if armor then
            local grade  = armor.grade or "Unknown"
            local health = armor.health or 0
            local weight = VehicleArmorConfig.getArmorWeight and VehicleArmorConfig.getArmorWeight(grade, partId) or 0
            local label  = self:getPrettyLabel(partId, self.vehicle and self.vehicle:getPartById(partId) or nil)

            local leaking = vdata
                and vdata.gArmorGasLeak == true
                and GAA_IsGasTankPart(partId)

            overview.count = overview.count + 1
            overview.totalWeight = overview.totalWeight + weight
            overview.totalHealth = overview.totalHealth + health

            if health < 35 then
                overview.critical = overview.critical + 1
            end

            if leaking then
                overview.leaking = true
            end

            table.insert(overview.entries, {
                partId  = partId,
                label   = label,
                grade   = grade,
                health  = health,
                weight  = weight,
                leaking = leaking,
            })
        end
    end

    table.sort(overview.entries, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)

    return overview
end

function VehicleArmorWindow:drawArmorOverview(x, y)
    local signature = GAA_BuildArmorOverviewSignature(self.vehicle)
    if self.overviewDirty
    or not self.cachedOverview
    or self.cachedOverviewSignature ~= signature
    then
        self.cachedOverview = self:getArmorOverview()
        self.cachedOverviewSignature = signature
        self.overviewDirty = false
    end

    local overview = self.cachedOverview or self:getArmorOverview()

    self:drawText("ARMOR OVERVIEW:", x, y, 1, 1, 1, 1, UIFont.Small)
    y = y + 18

    if overview.count <= 0 then
        self:drawText("No armor installed.", x + 8, y, 0.97, 0.97, 0.97, 1, UIFont.Small)
        return y + 20
    end

    local avgHealth = 0
    if overview.count > 0 then
        avgHealth = math.floor((overview.totalHealth / overview.count) + 0.5)
    end

    self:drawText(
        "Panels: " .. tostring(overview.count)
            .. "   Weight: +" .. tostring(overview.totalWeight) .. " kg",
        x + 8, y, 0.97, 0.97, 0.97, 1, UIFont.Small
    )
    y = y + 16

    local summaryColor = overview.leaking and GAA_GetGasLeakColor() or {r=0.97, g=0.97, b=0.97}

    self:drawText(
        "Avg Integrity: " .. tostring(avgHealth) .. "%"
            .. "   Critical: " .. tostring(overview.critical),
        x + 8, y, 0.97, 0.97, 0.97, 1, UIFont.Small
    )
    y = y + 16

    if overview.leaking then
        self:drawText("Gas Leak: ACTIVE", x + 8, y,
            summaryColor.r, summaryColor.g, summaryColor.b, 1, UIFont.Small)
        y = y + 18
    else
        y = y + 2
    end

    local maxRows = 12
    local shown = 0

    for _, entry in ipairs(overview.entries) do
        shown = shown + 1
        if shown > maxRows then
            local remaining = overview.count - maxRows
            self:drawText(
                "...and " .. tostring(remaining) .. " more",
                x + 8, y, 0.75, 0.75, 0.75, 1, UIFont.Small
            )
            y = y + 16
            break
        end

        local hp = entry.health or 0
        local col = entry.leaking and GAA_GetGasLeakColor() or GAA_GetArmorHealthColor(hp)

        local line = entry.label .. ": " .. entry.grade .. " (" .. tostring(hp) .. "%)"
        if entry.leaking then
            line = line .. " - LEAKING"
        end

        self:drawText(line, x + 8, y, col.r, col.g, col.b, 1, UIFont.Small)
        y = y + 16
    end

    return y + 8
end


----------------------------------------------------------
-- PRERENDER
----------------------------------------------------------
function VehicleArmorWindow:prerender()
    self:drawRect(0, 0, self.width, self.height,
        self.backgroundColor.a,
        self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height,
        self.borderColor.a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)

    self:drawTextCentre("VEHICLE REINFORCEMENT STATION",
        self.width / 2, 10, 1, 1, 1, 1, UIFont.Medium)

    -- Subtle frame around filter/sort controls.
    self:drawRect(10, 92, 272, 58, 0.22, 0, 0, 0)
    self:drawRectBorder(10, 92, 272, 58, 0.45, 0.45, 0.45, 0.45)

    -- Border overlay for the left part list panel.
    if self.partListBox then
        self:drawRectBorder(
            self.partListBox:getX(),
            self.partListBox:getY(),
            self.partListBox:getWidth(),
            self.partListBox:getHeight(),
            0.85, 0.55, 0.55, 0.55
        )
    end

    self:drawHeaderLabels()
    self:drawColorLegend()

    if self.materialHelpButton then
        self.materialHelpButton:setTitle(self.showMaterialHelp and "Hide Material Help" or "Material Help")
    end

    -- Event-driven material/tool cache.
    -- getRecipeReport scans player inventory, nearby containers and ground
    -- items. Do not run it repeatedly while the UI is open.
    -- It now runs on UI open, and when grade changes.
    local globalDirtyStamp = GSVU4Core and GSVU4Core.UIState and GSVU4Core.UIState.InventoryDirtyStamp or nil
    local globalInventoryDirty = globalDirtyStamp and self.gsvu4LastInventoryDirtyStamp ~= globalDirtyStamp

    if self.reportDirty or globalInventoryDirty or not self.cachedReport then
        self.cachedReport = self:getRecipeReport()
        self.reportDirty  = false
        self.bulkButtonsDirty = true
        self.gsvu4SelectedTotalsDirty = true
        self.gsvu4LastInventoryDirtyStamp = globalDirtyStamp
    else
        self:maybeRefreshInventoryReport()
    end

    if not self.selectedPart then
        local cx = self.detailBox:getX() + math.floor(self.detailBox.width  / 2)
        local cy = self.detailBox:getY() + math.floor(self.detailBox.height / 2)

        if self.unsupportedVehicle then
            self:drawTextCentre("No compatible armor locations found.",
                cx, cy - 10, 0.9, 0.35, 0.35, 1, UIFont.Small)
            self:drawTextCentre("This vehicle may use custom part IDs.",
                cx, cy + 10, 0.70, 0.82, 0.95, 1, UIFont.Small)
        elseif self.emptyFilter then
            self:drawTextCentre("No parts match the selected filter.",
                cx, cy - 10, 0.97, 0.97, 0.97, 1, UIFont.Small)
            self:drawTextCentre("Choose All to show every compatible part.",
                cx, cy + 10, 0.70, 0.82, 0.95, 1, UIFont.Small)
        else
            self:drawTextCentre("Select a part from the list.",
                cx, cy, 0.70, 0.82, 0.95, 1, UIFont.Small)
        end

        if not self.unsupportedVehicle and self.overviewBox then
            self:drawArmorOverview(self.overviewBox:getX() + 12, self.overviewBox:getY() + 12)
        end

        self.actionButton:setEnable(false)
        self.repairButton:setEnable(false)
        self.repairButton:setTitle("Repair Armor")
        self:updateBulkButtonsCached(self.cachedReport or self:getRecipeReport())
        return
    end

    local report = self.cachedReport
    local dx     = self.detailBox:getX() + 15
    local dy     = self.detailBox:getY() + 15

    ------------------------------------------------
    -- OVERVIEW PANEL
    ------------------------------------------------
    if self.overviewBox then
        self:drawArmorOverview(self.overviewBox:getX() + 12, self.overviewBox:getY() + 12)
    end

    -- Shared selected-state values used by the centre panel.
    local vdata       = self.vehicle:getModData()
    local armorExists = vdata.gArmor and vdata.gArmor[self.selectedPart.partId]
    local activeGrade = armorExists and armorExists.grade or self.currentGrade

    local torchNeeded
    if armorExists then
        torchNeeded = VehicleArmorConfig.FuelUse.Repair[activeGrade] or 1
    else
        torchNeeded = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(self.selectedPart.partId, activeGrade) or (VehicleArmorConfig.FuelUse.Install[activeGrade] or 0)
    end

    local function drawToolsSection()
        self:drawText("REQUIRED TOOLS:", dx, dy, 1.00, 0.88, 0.50, 1, UIFont.Small)
        dy = dy + 20

        local function toolLine(label, ok)
            local mark = ok and "[OK]" or "[--]"
            local c    = ok and {r=0.25, g=0.85, b=0.25} or {r=0.95, g=0.35, b=0.25}
            self:drawText(mark .. " " .. label, dx + 8, dy, c.r, c.g, c.b, 1, UIFont.Small)
            dy = dy + 16
        end

        local toolReq = VehicleArmorHelpers and VehicleArmorHelpers.getInstallToolRequirements and VehicleArmorHelpers.getInstallToolRequirements(activeGrade) or { hammer = true, weldingMask = true, blowTorch = true }
        if armorExists then toolReq = { hammer = true, weldingMask = true, blowTorch = true } end
        if toolReq.hammer then toolLine("Hammer", report.hasHammer) end
        if toolReq.screwdriver then toolLine("Screwdriver", report.hasScrewdriver) end
        if toolReq.weldingMask then toolLine("Welding Mask", report.hasMask) end

        if torchNeeded > 0 then
            local torchOk    = report.torchUnits >= torchNeeded
            local torchLabel = string.format(
                "Blowtorch  (%.1f / %.1f units)", report.torchUnits, torchNeeded)
            toolLine(torchLabel, torchOk)
        end

        dy = dy + 4
    end

    local armor = armorExists

    self:updateBulkButtonsCached(report)

    dy = self:drawBulkActionStatus(dx, dy, report)

    if armor then
        ------------------------------------------------
        -- INSTALLED: show grade, health, repair cost
        ------------------------------------------------
        self:drawText("INSTALLED ARMOR:", dx, dy, 1, 1, 1, 1, UIFont.Small)
        dy = dy + 18

        self:drawText("Grade: " .. armor.grade, dx, dy, 0.55, 0.88, 1.00, 1, UIFont.Medium)
        dy = dy + 22

        local installedWeight = VehicleArmorConfig.getArmorWeight and VehicleArmorConfig.getArmorWeight(armor.grade, self.selectedPart.partId) or 0
        self:drawText("Added Weight: +" .. tostring(installedWeight) .. " kg",
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 18

        self:drawText("Damage Absorbed: " .. tostring(GAA_GetProtectionAbsorbPercent(armor.grade)) .. "%",
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 16

        self:drawText(GAA_GetArmorDurabilityText(armor.grade),
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 20

        if GAA_IsGasTankPart(self.selectedPart.partId)
        and vdata.gArmorGasLeak
        then
            local leakCol = GAA_GetGasLeakColor()
            self:drawText("WARNING: Fuel leak active - repair armor or Gas Tank.",
                dx, dy, leakCol.r, leakCol.g, leakCol.b, 1, UIFont.Small)
            dy = dy + 18
        end

        local hp  = armor.health or 0
        local col = GAA_GetArmorHealthColor(hp)

        if GAA_IsGasTankPart(self.selectedPart.partId)
        and vdata.gArmorGasLeak
        then
            col = GAA_GetGasLeakColor()
        end

        self:drawText("Integrity: " .. hp .. "%", dx, dy, col.r, col.g, col.b, 1, UIFont.Small)
        dy = dy + 18

        self:drawRect(dx, dy, 200, 12, 0.4, 0.1, 0.1, 0.1)
        self:drawRect(dx, dy, math.floor(200 * (hp / 100)), 12, 1, col.r, col.g, col.b)
        dy = dy + 25

        drawToolsSection()

        if hp < 100 then
            self.repairButton:setEnable(report.canRepair)
            self.repairButton:setTitle(report.canRepair and "Repair Armor" or "Missing Requirements")
            self:drawText("REPAIR COST:", dx, dy, 1.00, 0.88, 0.50, 1, UIFont.Small)
            dy = dy + 16

            for _, mat in ipairs(getSortedMaterialKeys(report.repairReq or {})) do
                local req   = report.repairReq[mat]
                local have  = report[mat] or 0
                local ok    = have >= req
                local c     = ok and {r=0.25, g=0.85, b=0.25} or {r=0.95, g=0.35, b=0.25}
                local label = (MAT_LABEL[mat] or mat)
                    .. ": " .. string.format("%.1f", have) .. " / " .. req
                self:drawText(label, dx, dy, c.r, c.g, c.b, 1, UIFont.Small)
                dy = dy + 16
            end

        else
            self.repairButton:setEnable(false)
            self.repairButton:setTitle("Repair Armor")
            self:drawText("Armor is fully repaired.", dx, dy, 0.25, 0.85, 0.25, 1, UIFont.Small)
        end

        if self.pendingUninstallPartId == self.selectedPart.partId then
            self.actionButton:setTitle("Confirm Uninstall")
        else
            self.actionButton:setTitle("Uninstall Armor Panel")
        end
        self.actionButton:setEnable(true)

    else
        ------------------------------------------------
        -- NOT INSTALLED: show install cost
        ------------------------------------------------
        self.repairButton:setEnable(false)

        self:drawText("PLANNED ARMOR:", dx, dy, 1, 1, 1, 1, UIFont.Small)
        dy = dy + 18

        self:drawText("Grade: " .. tostring(self.currentGrade),
            dx, dy, 0.55, 0.88, 1.00, 1, UIFont.Medium)
        dy = dy + 22

        local plannedWeight = VehicleArmorConfig.getArmorWeight and VehicleArmorConfig.getArmorWeight(self.currentGrade, self.selectedPart.partId) or 0
        self:drawText("Added Weight: +" .. tostring(plannedWeight) .. " kg",
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 16

        self:drawText("Damage Absorbed: " .. tostring(GAA_GetProtectionAbsorbPercent(self.currentGrade)) .. "%",
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 16

        self:drawText(GAA_GetArmorDurabilityText(self.currentGrade),
            dx, dy, 0.97, 0.97, 0.97, 1, UIFont.Small)
        dy = dy + 20

        local skillReport = report.skillReport
        if skillReport then
            local showMetal = (tonumber(skillReport.metalRequired or 0) or 0) > 0
            local showMech = (tonumber(skillReport.mechRequired or 0) or 0) > 0
            if showMetal or showMech then
                self:drawText("SKILL REQUIREMENTS:", dx, dy, 1.00, 0.88, 0.50, 1, UIFont.Small)
                dy = dy + 18

                if showMetal then
                    local metalOk = skillReport.metalLevel >= skillReport.metalRequired
                    local metalC  = metalOk and {r=0.25, g=0.85, b=0.25} or {r=0.95, g=0.35, b=0.25}
                    self:drawText(
                        "MetalWelding: " .. tostring(skillReport.metalLevel)
                            .. " / " .. tostring(skillReport.metalRequired),
                        dx + 8, dy, metalC.r, metalC.g, metalC.b, 1, UIFont.Small
                    )
                    dy = dy + 16
                end

                if showMech then
                    local mechOk = skillReport.mechLevel >= skillReport.mechRequired
                    local mechC  = mechOk and {r=0.25, g=0.85, b=0.25} or {r=0.95, g=0.35, b=0.25}
                    self:drawText(
                        "Mechanics: " .. tostring(skillReport.mechLevel)
                            .. " / " .. tostring(skillReport.mechRequired),
                        dx + 8, dy, mechC.r, mechC.g, mechC.b, 1, UIFont.Small
                    )
                    dy = dy + 16
                end

                dy = dy + 6
            end
        end

        drawToolsSection()

        self:drawText("REQUIRED MATERIALS:", dx, dy, 1.00, 0.88, 0.50, 1, UIFont.Small)
        dy = dy + 18
        self:drawText("Tip: partial sheets/bars count.",
            dx + 8, dy, 0.70, 0.82, 0.95, 1, UIFont.Small)
        dy = dy + 18

        local recipe = VehicleArmorConfig.getInstallRecipe(
            self.selectedPart.partId,
            self.currentGrade
        )

        if recipe and VehicleArmorHelpers and VehicleArmorHelpers.getAdjustedRecipe then
            recipe = VehicleArmorHelpers.getAdjustedRecipe(recipe)
        end

        if recipe then
            for _, mat in ipairs(getSortedMaterialKeys(recipe)) do
                local req   = recipe[mat]
                local have  = report[mat] or 0
                local ok    = have >= req
                local c     = ok and {r=0.25, g=0.85, b=0.25} or {r=0.95, g=0.35, b=0.25}
                local label = (MAT_LABEL[mat] or mat)
                    .. ": " .. string.format("%.1f", have) .. " / " .. req
                self:drawText(label, dx, dy, c.r, c.g, c.b, 1, UIFont.Small)
                dy = dy + 16
            end
        else
            self:drawText(
                "This part supports Standard and Reinforced armor only.",
                dx, dy, 0.95, 0.35, 0.25, 1, UIFont.Small
            )
            report.canCraft = false
            dy = dy + 18
        end


        self.pendingUninstallPartId = nil

        local title = report.canCraft
            and ("Weld " .. self.currentGrade .. " " .. (self.selectedPart.name or "Panel"))
            or "Missing Requirements"
        self.actionButton:setTitle(title)
        self.actionButton:setEnable(report.canCraft)
    end

    self:drawMaterialHelpTooltip()
end

----------------------------------------------------------
-- CLOSE
----------------------------------------------------------
function VehicleArmorWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

----------------------------------------------------------
-- NEW
----------------------------------------------------------
function VehicleArmorWindow:new(x, y, w, h, character, vehicle)
    local o = ISPanel:new(x, y, 1040, 650)
    setmetatable(o, self)
    self.__index      = self
    o.character       = character
    o.vehicle         = vehicle
    o.selectedPart    = nil
    o.unsupportedVehicle = false
    o.emptyFilter     = false
    o.partFilter      = "All"
    o.partSort        = "Alpha"
    o.pendingUninstallPartId = nil
    o.pendingUninstallAll = false
    o.currentGrade    = nil
    o.cachedReport    = nil
    o.cachedOverview  = nil
    o.cachedOverviewSignature = nil
    -- reportDirty starts true so the first UI draw performs the one UI-open
    -- inventory/material scan.
    o.reportDirty     = true
    o.overviewDirty   = true
    -- bulkButtonsDirty starts true so bulk state is calculated once on open.
    o.bulkButtonsDirty = true
    o.borderColor     = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0,   g=0,   b=0,   a=0.9}
    o.moveWithMouse   = true
    return o
end
