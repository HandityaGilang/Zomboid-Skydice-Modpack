require "DAMN_MechOverlay";
--
--##########79camaro##########
--
DAMN.MechOverlay:addParts({
    ["Base.79camaro"] = "79camaro_",
    ["Base.79camaroRS"] = "79camaro_",
    ["Base.79camaroZ28"] = "79camaro_",
    ["Base.79camaroGhost"] = "79camaro_",
}, {
    Battery = {img="battery", x=228,y=103,x2=270,y2=134},
    --
    SuspensionFrontLeft = {img="suspension_front_left", x=13,y=143,x2=55,y2=181},
    SuspensionFrontRight = {img="suspension_front_right", x=228,y=143,x2=270,y2=181},
    SuspensionRearLeft = {img="suspension_rear_left", x=13,y=357,x2=55,y2=396},
    SuspensionRearRight = {img="suspension_rear_right", x=228,y=357,x2=270,y2=396},
    --
    BrakeFrontLeft = {img="brake_front_left", x=14,y=181,x2=55,y2=218},
    BrakeFrontRight = {img="brake_front_right", x=228,y=181,x2=270,y2=218},
    BrakeRearLeft = {img="brake_rear_left", x=13,y=396,x2=55,y2=431},
    BrakeRearRight = {img="brake_rear_right", x=228,y=396,x2=270,y2=431},
    --
    TireFrontLeft = {img="wheel_front_left", x=13,y=218,x2=55,y2=258},
    TireFrontRight = {img="wheel_front_right", x=228,y=218,x2=270,y2=258},
    TireRearLeft = {img="wheel_rear_left", x=13,y=431,x2=55,y2=471},
    TireRearRight = {img="wheel_rear_right", x=228,y=431,x2=270,y2=471},
    --
    DoorFrontLeft = {img="door_front_left", x=75,y=256,x2=83,y2=365},
    DoorFrontRight = {img="door_front_right", x=201,y=256,x2=208,y2=365},
    --
    Engine = {img="engine", x=142,y=143,x2=193,y2=248},
    --
    EngineDoor = {img="hood", x=90,y=143,x2=142,y2=248},
    --
    TrunkDoor = {img="trunk", x=103,y=431,x2=181,y2=472},
    --
    WindowFrontLeft = {img="window_front_left", x=83,y=277,x2=99,y2=365},
    WindowFrontRight = {img="window_front_right", x=185,y=277,x2=201,y2=365},
    --
    Windshield = {img="window_windshield", x=97,y=248,x2=186,y2=284},
    WindshieldRear = {img="window_rear_windshield", x=88,y=378,x2=196,y2=423},
    --
    GasTank = {img="gastank", x=14,y=527,x2=70,y2=565},
    --
    Muffler = {img="muffler", x=200,y=527,x2=269,y2=564},
    --
    DAMNBumperFront = {img="armor_bull", x=98,y=48,x2=141,y2=86},
    DAMNWindshieldArmor = {img="armor_wind", x=144,y=48,x2=187,y2=86},
    DAMNFrontLeftArmor = {img="armor_doorfl", x=13,y=268,x2=55,y2=306},
    DAMNFrontRightArmor = {img="armor_doorfr", x=228,y=268,x2=270,y2=306},
    DAMNWindshieldRearArmor = {img="armor_windr", x=120,y=526,x2=163,y2=564},
}, 10, 0);
--