--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

require "Hooks/DAMN_EnterAnimations";

DAMN = DAMN or {};
CAM79 = CAM79 or {};

DAMN.EnterAnimations:registerVehicleScript("Base.79camaro", "sport");
DAMN.EnterAnimations:registerVehicleScript("Base.79camaroRS", "sport");
DAMN.EnterAnimations:registerVehicleScript("Base.79camaroZ28", "sport");
DAMN.EnterAnimations:registerVehicleScript("Base.79camaroGhost", "sport");

require "Hooks/DAMN_VehicleMenu";

DAMN.VehicleMenu:registerConditionalSlice(function(radialMenu, playerObj, vehicle, vehicleScriptName)
    if vehicleScriptName and string.find(vehicleScriptName, "79camaro")
    then
        local part = vehicle:getPartById("DAMNBumperFront");

        if part and DAMN.Parts:partIsInstalled(part)
        then
            local door = part:getDoor();

            if door:isOpen()
            then
                radialMenu:addSlice(getText("IGUI_close_teh_plow"), getTexture("media/textures/Slice_CAM79_plow.png"), function()
                    vehicle:playPartAnim(part, "Close");
                    vehicle:playPartSound(part, playerObj, "Close");
                    door:setOpen(false);
                end);
            else
                radialMenu:addSlice(getText("IGUI_drop_teh_plow"), getTexture("media/textures/Slice_CAM79_plow.png"), function()
                    vehicle:playPartAnim(part, "Open");
                    vehicle:playPartSound(part, playerObj, "Open");
                    door:setOpen(true);
                end);
            end
        end
    end
end, "toggle_CAM79ghostPlow");