--========================================================
-- Gore's SVU4 Core - Admin Sandbox Controls Patch
-- Phase 2AB
--
-- Adds runtime behaviour for:
-- - Multi-install mode sandbox option
-- - Max queued actions sandbox option
-- - Enabled/disabled armor grades
--========================================================

require "VehicleArmor_Config"

if not VehicleArmorWindow then
    return
end

local PREFIX = "[Gore's SVU4 Core SandboxControls] "

local function getInstallMode()
    if VehicleArmorConfig and VehicleArmorConfig.getMultiInstallMode then
        return VehicleArmorConfig.getMultiInstallMode()
    end
    return "multi"
end

local function getMaxQueued()
    if VehicleArmorConfig and VehicleArmorConfig.getMaxQueuedActions then
        return VehicleArmorConfig.getMaxQueuedActions()
    end
    return 10
end

local function limitQueue(queue)
    local maxQueued = getMaxQueued()
    if not maxQueued or not queue or #queue <= maxQueued then
        return queue or {}
    end

    local limited = {}
    for i = 1, math.min(maxQueued, #queue) do
        table.insert(limited, queue[i])
    end
    return limited
end

local function isGradeEnabled(grade)
    if not grade then return false end
    if VehicleArmorConfig and VehicleArmorConfig.isArmorGradeEnabled then
        return VehicleArmorConfig.isArmorGradeEnabled(grade)
    end
    return true
end

local function firstEnabledGrade()
    if VehicleArmorConfig and VehicleArmorConfig.getFirstEnabledArmorGrade then
        return VehicleArmorConfig.getFirstEnabledArmorGrade()
    end
    return "Scrap"
end

local function refreshGradeButtons(window)
    if not window or not window.gradeButtons then return end

    for grade, btn in pairs(window.gradeButtons) do
        local enabled = isGradeEnabled(grade)

        if btn.setEnable then
            btn:setEnable(enabled)
        end

        if btn.setTitle then
            btn:setTitle(enabled and tostring(grade) or (tostring(grade) .. " OFF"))
        end

        if not enabled then
            btn.backgroundColor = {r=0.10, g=0.10, b=0.10, a=1}
        elseif grade == window.currentGrade then
            btn.backgroundColor = {r=0.25, g=0.35, b=0.50, a=1}
        else
            btn.backgroundColor = {r=0.15, g=0.15, b=0.15, a=1}
        end
    end
end

local function ensureCurrentGradeAllowed(window, say)
    if not window then return false end

    if window.currentGrade and isGradeEnabled(window.currentGrade) then
        return true
    end

    local fallback = firstEnabledGrade()
    if fallback then
        window.currentGrade = fallback
        if GSVU4Core and GSVU4Core.UIState then
            GSVU4Core.UIState.LastArmorGrade = fallback
        end
        if window.character and window.character.getModData then
            window.character:getModData().GSVU4_LastArmorGrade = fallback
        end
        return true
    end

    if say and window.character and window.character.Say then
        window.character:Say("All SVU4 armor grades are disabled by server settings.")
    end

    return false
end

local function clearInstallBatch(window)
    if not window then return end
    window.installSelectedParts = {}
    if window.gsvu4BatchMode == "install" then
        window.gsvu4BatchMode = nil
        window.installSelectMode = false
    end
    window.reportDirty = true
end

local oldCreateChildren = VehicleArmorWindow.createChildren
function VehicleArmorWindow:createChildren()
    oldCreateChildren(self)
    ensureCurrentGradeAllowed(self, false)
    refreshGradeButtons(self)
end

local oldSelectGrade = VehicleArmorWindow.selectGrade
function VehicleArmorWindow:selectGrade(grade)
    if grade and not isGradeEnabled(grade) then
        if self.character and self.character.Say then
            self.character:Say(tostring(grade) .. " armor is disabled by server settings.")
        end
        ensureCurrentGradeAllowed(self, false)
        refreshGradeButtons(self)
        return
    end

    local oldGrade = self.currentGrade
    local mode = getInstallMode()

    oldSelectGrade(self, grade)

    if mode == "grade"
    and self.gsvu4BatchMode == "install"
    and oldGrade
    and grade
    and oldGrade ~= grade
    then
        self.installSelectedParts = {}
        self.gsvu4BatchMode = nil
        self.installSelectMode = false
        if self.character and self.character.Say then
            self.character:Say("Install selection cleared: server allows one armor grade per batch.")
        end
    end

    refreshGradeButtons(self)
    self.gsvu4SandboxGradeButtonsRefreshed = true
end

local oldBeginInstallSelection = VehicleArmorWindow.beginInstallSelection
function VehicleArmorWindow:beginInstallSelection(report)
    local mode = getInstallMode()

    if mode == "single" then
        return false
    end

    if not ensureCurrentGradeAllowed(self, true) then
        return false
    end

    local result = oldBeginInstallSelection and oldBeginInstallSelection(self, report) or false

    if result and mode == "grade" then
        local grade = self.currentGrade or firstEnabledGrade()
        if self.installSelectedParts then
            for partId, selectedGrade in pairs(self.installSelectedParts) do
                if selectedGrade ~= grade then
                    self.installSelectedParts[partId] = nil
                end
            end
        end
    end

    return result
end

local oldOnInstallAllButtonClick = VehicleArmorWindow.onInstallAllButtonClick
function VehicleArmorWindow:onInstallAllButtonClick()
    local mode = getInstallMode()

    if mode == "single" then
        if self.character and self.character.Say then
            self.character:Say("Batch installing is disabled by server settings. Use Install Selected on one panel.")
        end
        return
    end

    if not ensureCurrentGradeAllowed(self, true) then
        return
    end

    return oldOnInstallAllButtonClick(self)
end

local oldToggleInstallSelection = VehicleArmorWindow.toggleInstallSelection
function VehicleArmorWindow:toggleInstallSelection(rowItem)
    if self.gsvu4BatchMode == "install" then
        if getInstallMode() == "single" then
            return
        end

        if not ensureCurrentGradeAllowed(self, true) then
            return
        end
    end

    return oldToggleInstallSelection(self, rowItem)
end

local oldIsInstallSelectionCandidate = VehicleArmorWindow.isInstallSelectionCandidate
function VehicleArmorWindow:isInstallSelectionCandidate(partId, grade)
    if getInstallMode() == "single" then
        return false
    end

    if not isGradeEnabled(grade or self.currentGrade) then
        return false
    end

    return oldIsInstallSelectionCandidate and oldIsInstallSelectionCandidate(self, partId, grade) or false
end

local oldGetInstallAllQueue = VehicleArmorWindow.getInstallAllQueue
function VehicleArmorWindow:getInstallAllQueue(report)
    if getInstallMode() == "single" then
        return {}
    end
    return limitQueue(oldGetInstallAllQueue and oldGetInstallAllQueue(self, report) or {})
end

local oldGetSelectedInstallQueue = VehicleArmorWindow.getSelectedInstallQueue
function VehicleArmorWindow:getSelectedInstallQueue(report)
    if getInstallMode() == "single" then
        return {}
    end
    return limitQueue(oldGetSelectedInstallQueue and oldGetSelectedInstallQueue(self, report) or {})
end

local oldGetRepairAllQueue = VehicleArmorWindow.getRepairAllQueue
function VehicleArmorWindow:getRepairAllQueue(report)
    return limitQueue(oldGetRepairAllQueue and oldGetRepairAllQueue(self, report) or {})
end

local oldGetUninstallAllQueue = VehicleArmorWindow.getUninstallAllQueue
function VehicleArmorWindow:getUninstallAllQueue(report)
    return limitQueue(oldGetUninstallAllQueue and oldGetUninstallAllQueue(self, report) or {})
end

local oldGetSelectedRepairQueue = VehicleArmorWindow.getSelectedRepairQueue
if oldGetSelectedRepairQueue then
    function VehicleArmorWindow:getSelectedRepairQueue(report)
        return limitQueue(oldGetSelectedRepairQueue(self, report) or {})
    end
end

local oldGetSelectedUninstallQueue = VehicleArmorWindow.getSelectedUninstallQueue
if oldGetSelectedUninstallQueue then
    function VehicleArmorWindow:getSelectedUninstallQueue(report)
        return limitQueue(oldGetSelectedUninstallQueue(self, report) or {})
    end
end

local oldUpdateBulkButtons = VehicleArmorWindow.updateBulkButtons
function VehicleArmorWindow:updateBulkButtons(report)
    oldUpdateBulkButtons(self, report)

    ensureCurrentGradeAllowed(self, false)
    refreshGradeButtons(self)

    local mode = getInstallMode()
    local maxQueued = getMaxQueued()
    local maxLabel = maxQueued and tostring(maxQueued) or "Unlimited"

    if self.installAllButton then
        if mode == "single" then
            self.installAllButton:setTitle("Batch Off")
            self.installAllButton:setEnable(false)
        elseif mode == "grade" then
            -- Previous patches set the count. Keep it short and make the server rule visible.
            if self.gsvu4BatchMode == "install" then
                local queue = self.getSelectedInstallQueue and self:getSelectedInstallQueue(report) or {}
                self.installAllButton:setTitle("Install Batch (" .. tostring(#queue) .. ")")
                self.installAllButton:setEnable(#queue > 0)
            else
                local queue = self.getInstallAllQueue and self:getInstallAllQueue(report) or {}
                self.installAllButton:setTitle(#queue > 0 and ("Select Grade (" .. tostring(#queue) .. ")") or "Select Grade")
                self.installAllButton:setEnable(#queue > 0)
            end
        end
    end

    if self.actionButton and self.selectedPart then
        local vdata = self.vehicle and self.vehicle:getModData()
        local existing = vdata and vdata.gArmor and vdata.gArmor[self.selectedPart.partId]
        if not existing and not ensureCurrentGradeAllowed(self, false) then
            self.actionButton:setTitle("Grades Off")
            self.actionButton:setEnable(false)
        end
    end
end

local oldPrerender = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender()
    oldPrerender(self)

    -- Sandbox grade toggles are static while the window is open. Avoid
    -- refreshing button enabled/title/color state every frame.
    if not self.gsvu4SandboxGradeButtonsRefreshed then
        refreshGradeButtons(self)
        self.gsvu4SandboxGradeButtonsRefreshed = true
    end

    if not self.detailBox then return end

    local mode = getInstallMode()
    local maxQueued = getMaxQueued()
    local maxLabel = maxQueued and tostring(maxQueued) or "Unlimited"
    local anyGrade = firstEnabledGrade() ~= nil

    local x = self.detailBox:getX() + 12
    local y = self.detailBox:getY() + self.detailBox:getHeight() - 72
    local w = self.detailBox:getWidth() - 24

    if not anyGrade then
        self:drawRect(x, y, w, 48, 0.88, 0.12, 0.02, 0.02)
        self:drawRectBorder(x, y, w, 48, 0.90, 0.95, 0.45, 0.25)
        self:drawText("SANDBOX: ALL ARMOR GRADES DISABLED", x + 8, y + 6, 1.0, 0.65, 0.30, 1, UIFont.Small)
        self:drawText("Install actions are disabled. Existing valid armor can still be repaired/removed.", x + 8, y + 24, 0.92, 0.92, 0.92, 1, UIFont.Small)
        return
    end

    if mode == "single" then
        self:drawText("Sandbox: batch install disabled. Queue limit: " .. maxLabel .. ".",
            x, y + 48, 0.70, 0.70, 0.70, 1, UIFont.Small)
    elseif mode == "grade" then
        self:drawText("Sandbox: one-grade install batches only. Queue limit: " .. maxLabel .. ".",
            x, y + 48, 0.70, 0.70, 0.70, 1, UIFont.Small)
    end
end
