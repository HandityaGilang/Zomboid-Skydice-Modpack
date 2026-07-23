-- From "Open All Containers [B42]" mod -- Author = carlesturo

local OAC_Utils = require("OAC_Utils")

-- ------------------------------------------------------------------------------------------------

-- **************** OAC - ON LOADED TILE DEFINITIONS - COMPATIBILITY WITH - MDO ****************

Events.OnLoadedTileDefinitions.Add(function(manager)
    if not OAC_Utils.isModActivated("MoreDamagedObjects") then
        return
    end

    local damagedMap = {
        ["ct_oac_trashcontainers_01_24"] = "ct_more_damaged_objects_01_16",
        ["ct_oac_trashcontainers_01_25"] = "ct_more_damaged_objects_01_17",
        ["ct_oac_trashcontainers_01_26"] = "ct_more_damaged_objects_01_18",
        ["ct_oac_trashcontainers_01_27"] = "ct_more_damaged_objects_01_19",
    }

    for sprite, damagedSprite in pairs(damagedMap) do
        local props = manager:getSprite(sprite):getProperties()
        props:set("HitByCar", "")
        props:set("MinimumCarSpeedDmg", "10")
        props:set("DamagedSprite", damagedSprite)
        props:CreateKeySet()
    end
end)