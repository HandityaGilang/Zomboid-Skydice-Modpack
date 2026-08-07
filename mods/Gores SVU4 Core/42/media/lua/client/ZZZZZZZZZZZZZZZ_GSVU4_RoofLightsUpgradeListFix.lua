-- Gore's SVU4 Core - Roof Lighting UI late registration fix
-- Keeps all roof-light option rows visible even if the base list is built early.

local function gsvu4EnsureRoofLightOptionsConfig()
    if not GSVU4UpgradesConfig then return end
    if not GSVU4UpgradesConfig.RoofLightOptionIds then
        GSVU4UpgradesConfig.RoofLightOptionIds = { "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }
    end
end

local function gsvu4FindListItem(list, upgradeId, grade)
    if not list or not list.items then return false end
    for _, row in ipairs(list.items) do
        local data = row and row.item
        if data and data.upgradeId == upgradeId and data.grade == grade then
            return true
        end
    end
    return false
end

local function gsvu4EnsureRoofLightRows(window)
    if not window or not window.gsvu4UpgradeList or not GSVU4UpgradesConfig then return end
    gsvu4EnsureRoofLightOptionsConfig()
    for _, upgradeId in ipairs(GSVU4UpgradesConfig.RoofLightOptionIds or { "RoofLights" }) do
        for _, grade in ipairs(GSVU4UpgradesConfig.RoofLightsGrades or { "Basic" }) do
            local cfg = GSVU4UpgradesConfig.getGradeConfig and GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade) or nil
            if cfg and not gsvu4FindListItem(window.gsvu4UpgradeList, upgradeId, grade) then
                window.gsvu4UpgradeList:addItem(cfg.label or upgradeId, { upgradeId = upgradeId, grade = grade })
            end
        end
    end
end

local function gsvu4PatchVehicleArmorWindow()
    if not VehicleArmorWindow or VehicleArmorWindow.GSVU4_RoofLightsUILateFix then return end
    VehicleArmorWindow.GSVU4_RoofLightsUILateFix = true

    local oldCreateChildren = VehicleArmorWindow.createChildren
    function VehicleArmorWindow:createChildren()
        if oldCreateChildren then oldCreateChildren(self) end
        gsvu4EnsureRoofLightRows(self)
    end

    local oldSetMode = VehicleArmorWindow.setGSVU4Mode
    function VehicleArmorWindow:setGSVU4Mode(mode)
        if oldSetMode then oldSetMode(self, mode) end
        if (mode or self.gsvu4Mode) == "Upgrades" then
            gsvu4EnsureRoofLightRows(self)
        end
    end

    local oldPrerender = VehicleArmorWindow.prerender
    function VehicleArmorWindow:prerender()
        if oldPrerender then oldPrerender(self) end
        if (self.gsvu4Mode or "Armor") == "Upgrades" then
            gsvu4EnsureRoofLightRows(self)
        end
    end
end

local function gsvu4ApplyRoofLightsUILateFix()
    gsvu4EnsureRoofLightOptionsConfig()
    gsvu4PatchVehicleArmorWindow()
end

Events.OnGameStart.Add(gsvu4ApplyRoofLightsUILateFix)
Events.OnCreatePlayer.Add(gsvu4ApplyRoofLightsUILateFix)
Events.OnInitWorld.Add(gsvu4ApplyRoofLightsUILateFix)
gsvu4ApplyRoofLightsUILateFix()
