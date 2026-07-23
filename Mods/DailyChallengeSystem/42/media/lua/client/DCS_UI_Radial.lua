if isServer() and not isClient() then return end

require 'ISUI/Maps/ISWorldMap'

local DCS_RADIAL_TEX = getTexture("media/textures/dcs_radial.png")
local old_center = ISRadialMenu.center

function ISRadialMenu:center()
    old_center(self)

    local playerNum = 0
    local radialMenu = getPlayerRadialMenu(playerNum)
    if self == radialMenu and not radialMenu:isEmpty() then
        local hasDCS = false
        for i = 1, #self.slices do
            if self.slices[i].icon == DCS_RADIAL_TEX then
                hasDCS = true
                break
            end
        end
        if not hasDCS then
            radialMenu:addSlice(getText("IGUI_DCS_Radial_MenuEntry"), DCS_RADIAL_TEX, DCS_UI_Panel.toggle)
        end
    end
end
