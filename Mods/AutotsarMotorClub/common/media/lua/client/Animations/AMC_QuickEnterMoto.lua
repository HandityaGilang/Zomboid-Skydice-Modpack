local function onKeyStartPressed(key)
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end
    if playerObj:isDead() or playerObj:getVehicle() then return end
    if key == getCore():getKey("Interact") then
        local vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
        if vehicle then 
            local conf = vehicle:getPartById("AMCConfig") 
            --print('onKeyStartPressed ',key,' ',getCore():getKey("Interact"),' ',conf)
            if conf then
                local conftable = conf:getTable("AMCConfig")
                --print('OnAMCConfig ',tab2str(conftable))
                if conftable and conftable.quickEnter == "1" and vehicle:isEnterBlocked(playerObj, 0) and vehicle:isEnterBlocked(playerObj, 1) then --and vehicle:isEnterBlocked(playerObj, 0) and vehicle:isEnterBlocked(playerObj, 1)
                    vehicle:enter(0, playerObj)
                    vehicle:setCharacterPosition(playerObj, 0, "inside")
                    vehicle:transmitCharacterPosition(0, "inside")
                    vehicle:playPassengerAnim(0, "idle")
                    triggerEvent("OnEnterVehicle", playerObj)
                end
            end
        end
    end
end

Events.OnKeyStartPressed.Add(onKeyStartPressed);