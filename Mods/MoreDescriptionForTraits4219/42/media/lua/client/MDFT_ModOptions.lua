MDFT = MDFT or {}
MDFT.OPTIONS = {
    ShowMoreDescription = nil,
    ShowFreeRecipes = nil,
    ShowForagingStats = nil
}
PZAPI = PZAPI or {}

-- Callback function when any option changes
local function onOptionChanged()
    if MDFT.refreshTraitLists then
        MDFT.refreshTraitLists()
    end
end

local function ModOptions() 
    local id = "MoreDescriptionForTraits"
    local options = PZAPI.ModOptions:create(id, getText("UI_moredesc_options_MoreDescriptionForTraits"))

    MDFT.OPTIONS.ShowMoreDescription = options:addTickBox(
        "ShowMoreDescription", 
        getText("UI_moredesc_options_ShowMoreDescription"),
        true, 
        getText("UI_moredesc_options_Tooltip_ShowMoreDescription")
    )
    MDFT.OPTIONS.ShowMoreDescription.onUpdate = onOptionChanged

    MDFT.OPTIONS.ShowFreeRecipes = options:addTickBox(
        "ShowFreeRecipes", 
        getText("UI_moredesc_options_ShowFreeRecipes"),
        true, 
        getText("UI_moredesc_options_Tooltip_ShowFreeRecipes")
    )
    MDFT.OPTIONS.ShowFreeRecipes.onUpdate = onOptionChanged

    MDFT.OPTIONS.ShowForagingStats = options:addTickBox(
        "ShowForagingStats", 
        getText("UI_moredesc_options_ShowForagingStats"),
        true, 
        getText("UI_moredesc_options_Tooltip_ShowForagingStats")
    )
    MDFT.OPTIONS.ShowForagingStats.onUpdate = onOptionChanged
end

ModOptions()
