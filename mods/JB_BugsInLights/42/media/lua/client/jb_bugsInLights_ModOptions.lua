-- jb_bugsInLights_ModOptions.lua

local function JB_BugsOptions()
    local modOptions = PZAPI.ModOptions:getOptions("JB_BugOptions")
    local superHiddenEasterEggText_DONT_LOOK

    local smolBug = "UI_ModOptions_JB_BugsInLights_Description"
    local thiccBug = "UI_ModOptions_JB_BugsInLights_Description_BIG"
    
    local options = PZAPI.ModOptions:create("JB_BugOptions", "")

    options:addDescription("UI_ModOptions_JB_BugsInLights_DescTitle")
    options:addDescription("UI_ModOptions_JB_BugsInLights_Image")

    if modOptions and modOptions:getOption("JB_BugOptions_SizeOfBugs") then
        local value = modOptions:getOption("JB_BugOptions_SizeOfBugs"):getValue()
        local targetText = (tonumber(value) > 1) and getText(thiccBug) or getText(smolBug)
        superHiddenEasterEggText_DONT_LOOK = options:addDescription(targetText)
    else
        superHiddenEasterEggText_DONT_LOOK = options:addDescription(smolBug)
    end

    options:addDescription("UI_ModOptions_JB_BugsInLights_Description2")
    options:addDescription("")

    options:addTickBox("JB_BugOptions_ActiveAllYear", "UI_ModOptions_JB_BugsInLights_ActiveAllYear", false)
    options:addTickBox("JB_BugOptions_EnvironAffectsSpawn", "UI_ModOptions_JB_BugsInLights_EnvironAffectsSpawn", true)
    options:addTickBox("JB_BugOptions_AcitveDayAndNight", "UI_ModOptions_JB_BugsInLights_AcitveDayAndNight", false)
    options:addSlider("JB_BugOptions_BugsPerLight", "UI_ModOptions_JB_BugsInLights_BugsPerLight", 5, 50, 5, 20)

    local sizeSlider = options:addSlider("JB_BugOptions_SizeOfBugs", "UI_ModOptions_JB_BugsInLights_SizeOfBugs", 1, 10, 0.5, 1)
    options:addDescription("")
    options:addDescription("")

    sizeSlider.onChange = function(self, value)
        local targetText = value > 2 and getText(thiccBug) or getText(smolBug)
        local subPanel = self.element and self.element.parent 
        
        if subPanel then
            local mainPanel = subPanel.javaObject:getParent()
            local controls = mainPanel:getControls()
            for i = 0, controls:size() - 1 do
                local child = controls:get(i)
                local tbl = child:getTable()
                if tbl.text then
                    if tbl.text == getText(thiccBug) or tbl.text == getText(smolBug) then
                        tbl.text = targetText
                        tbl:paginate()
                        break
                    end
                end
            end
        end
    end

    options.onApply = function(self)
        -- leave this shit here in case I need it again later
        -- 
        --local currentMaxBugs = self:getOption("JB_BugOptions_BugsPerLight"):getValue()
        --local isAllYear = self:getOption("JB_BugOptions_ActiveAllYear"):getValue()
        --local activeDayAndNight = self:getOption("JB_BugOptions_ActiveDayAndNight"):getValue()
        
        --print("JB Bugs In Lights: Mod Options Applied!")
        --print(" -> Max Bugs: " .. tostring(currentMaxBugs))
        --print(" -> Active All Year: " .. tostring(isAllYear))
    end

    return options
end

return JB_BugsOptions()
