local Core = PhunCure

local activeMods = getActivatedMods()
if (activeMods:contains("phunzones2") or activeMods:contains("phunzones2test")) then

    require "PhunZones/core"
    local PZ = PhunZones
    if PZ and PZ.fields then

        PZ.fields.cureDropRate = {
            label = "IGUI_PhunCure_CureDropRate",
            type = "string",
            tooltip = "IGUI_PhunCure_CureDropRate_Tooltip",
            group = "mods",
            order = 200
        }

        if activeMods:contains("phunsprinters2") or activeMods:contains("phunsprinters2test") then

            PZ.fields.dropRateSprinters = {
                label = "IGUI_PhunCure_DropRateSprinters",
                type = "string",
                tooltip = "IGUI_PhunCure_DropRateSprinters_Tooltip",
                group = "mods",
                order = 201
            }
        end

    end
end
