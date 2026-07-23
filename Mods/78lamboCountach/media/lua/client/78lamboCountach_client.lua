--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

require "Hooks/DAMN_EnterAnimations";

DAMN = DAMN or {};
LP400 = LP400 or {};

DAMN.EnterAnimations:registerVehicleScript("Base.78lamboCountachLP400", function(seatIndex, player)
    if seatIndex == 0
    then
        return {
            ["damnPosition"] = "driver_lambo",
            ["damnRole"] = "",
        };
    else
        return {
            ["damnPosition"] = "passenger_lambo",
            ["damnRole"] = "",
        };
    end
end);

DAMN.EnterAnimations:registerVehicleScript("Base.78lamboCountachLP400S", function(seatIndex, player)
    if seatIndex == 0
    then
        return {
            ["damnPosition"] = "driver_lambo",
            ["damnRole"] = "",
        };
    else
        return {
            ["damnPosition"] = "passenger_lambo",
            ["damnRole"] = "",
        };
    end
end);

DAMN.EnterAnimations:registerVehicleScript("Base.78lamboCountachLP400Scb", function(seatIndex, player)
    if seatIndex == 0
    then
        return {
            ["damnPosition"] = "driver_lambo",
            ["damnRole"] = "",
        };
    else
        return {
            ["damnPosition"] = "passenger_lambo",
            ["damnRole"] = "",
        };
    end
end);