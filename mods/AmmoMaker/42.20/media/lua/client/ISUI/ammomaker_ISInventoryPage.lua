--Ammo Maker by STIMP_TM

local function refreshInventoryContainers(inventoryPage, reason)

    local function addContainerButton()

        local character = getSpecificPlayer(inventoryPage.player);

        local characterInventoryItems = character:getInventory():getItems();

        for i = 0, characterInventoryItems:size()-1 do

            local item = characterInventoryItems:get(i);
            local ammomakerRegistries = require("ammomaker_Registries");

            if item:hasTag(ammomakerRegistries.tags.BRASSCATCHER) then

                inventoryPage:addContainerButton(item:getInventory(), item:getTex(), item:getName(), item:getName());

            end

        end
    
    end

    --do not add container buttons if other mods are active that are doing it
    if not getActivatedMods():contains('AccessibleContainers') then

        --add container buttons OnRefreshInventoryWindowContainers 'beforeFloor' if UI enhancing mods are active
        if reason == "beforeFloor" and inventoryPage.onCharacter and (getActivatedMods():contains('REORDER_CONTAINERS') or getActivatedMods():contains('CleanUI')) then

            addContainerButton();

        --add container buttons OnRefreshInventoryWindowContainers 'buttonsAdded' for pure vanilla UI
        elseif reason == "buttonsAdded" and inventoryPage.onCharacter then

            addContainerButton();

        end

    end

end

Events.OnRefreshInventoryWindowContainers.Add(refreshInventoryContainers);