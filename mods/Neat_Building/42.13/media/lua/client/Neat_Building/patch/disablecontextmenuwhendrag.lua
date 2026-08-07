require "neat_building/nb_modoptions"

ISWorldObjectContextMenu._NB_old_createMenu = ISWorldObjectContextMenu._NB_old_createMenu or ISWorldObjectContextMenu.createMenu

local function NB_createMenu_wrapper(player, worldobjects, x, y, test)
    local playerNum = getSpecificPlayer(player):getPlayerNum()
    local windowKey = "BuildWindow"
    
    if ISEntityUI and ISEntityUI.players[playerNum] and 
       ISEntityUI.players[playerNum].windows[windowKey] and 
       ISEntityUI.players[playerNum].windows[windowKey].instance and
       getCell():getDrag(player) ~= nil then
        return
    end
    return ISWorldObjectContextMenu._NB_old_createMenu(player, worldobjects, x, y, test)
end

-- -------------------------------------------------------------------------------------- --
-- Toggle hook: enable/disable Neat Building context-menu guard at runtime
-- -------------------------------------------------------------------------------------- --
local function NB_applyContextMenuToggle(enabled)
    if not ISWorldObjectContextMenu then return end
    if enabled then
        ISWorldObjectContextMenu.createMenu = NB_createMenu_wrapper
    else
        if ISWorldObjectContextMenu._NB_old_createMenu then
            ISWorldObjectContextMenu.createMenu = ISWorldObjectContextMenu._NB_old_createMenu
        end
    end
end

if NB_RegisterUiToggleCallback then
    NB_RegisterUiToggleCallback(NB_applyContextMenuToggle)
else
    NB_applyContextMenuToggle(true)
end
