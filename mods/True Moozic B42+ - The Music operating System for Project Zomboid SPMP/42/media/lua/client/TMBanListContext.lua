-- TMBanListContext.lua (client)
-- Adds the "Ban Music List" option to the world (ground) right-click context
-- menu for admins / debug users only. Clicking the ground -- not a device --
-- is the entry point by design.
require "TMBanListDefs"

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    if not TMBanList.isAuthorized(player) then return end

    context:addOption(getText("IGUI_TMBan_MenuOption"), player, function(pl)
        TMBanListWindow.toggle(pl)
    end)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
