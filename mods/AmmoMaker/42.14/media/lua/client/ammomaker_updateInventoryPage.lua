--Ammo Maker by STIMP_TM

local function ammoMakerUpdateInventoryPage(module, command)

    if command == "updateInventoryPage" then

        triggerEvent("OnContainerUpdate");

    end

end

Events.OnServerCommand.Add(ammoMakerUpdateInventoryPage)