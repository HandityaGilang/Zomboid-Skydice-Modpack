-- From "Open All Containers [B41]" mod -- Author = carlesturo

-- ------------------------------------------------------------------------------------------------

-- **************** OAC - ON LOADED TILE DEFINITIONS - COMPATIBILITY WITH - MDO ****************

Events.OnLoadedTileDefinitions.Add(function(manager)
    if not getActivatedMods():contains("MoreDamagedObjects") then
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
        props:Set("HitByCar", "")
        props:Set("MinimumCarSpeedDmg", "10")
        props:Set("DamagedSprite", damagedSprite)
        props:CreateKeySet()
    end
end)