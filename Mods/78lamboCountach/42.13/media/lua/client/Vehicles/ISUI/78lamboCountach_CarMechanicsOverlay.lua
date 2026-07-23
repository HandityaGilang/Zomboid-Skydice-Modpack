require "DAMN_MechOverlay";
--
--##########78lamboCountach##########
--
DAMN.MechOverlay:addParts({
    ["Base.78lamboCountachLP400"] = "78lamboCountach_",
    ["Base.78lamboCountachLP400S"] = "78lamboCountach_",
    ["Base.78lamboCountachLP400Scb"] = "78lamboCountach_",
}, {
    Battery = {img="battery", x=228,y=56,x2=270,y2=86},
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
    DoorFrontLeft = {img="door_front_left", x=66,y=223,x2=71,y2=332},
    DoorFrontRight = {img="door_front_right", x=210,y=223,x2=216,y2=332},
    --
    Engine = {img="engine", x=142,y=347,x2=181,y2=427},
    --
    EngineDoor = {img="hood", x=101,y=347,x2=142,y2=427},
    --
    TrunkDoor = {img="trunk", x=101,y=427,x2=181,y2=473},
    LP400TrunkDoorFront = {img="trunkf", x=110,y=139,x2=172,y2=197},
    --
    WindowFrontLeft = {img="window_front_left", x=71,y=251,x2=96,y2=328},
    WindowFrontRight = {img="window_front_right", x=185,y=251,x2=210,y2=328},
    WindowRearLeft = {img="window_rear_left", x=71,y=336,x2=96,y2=349},
    WindowRearRight = {img="window_rear_right", x=185,y=336,x2=210,y2=349},
    --
    Windshield = {img="window_windshield", x=101,y=205,x2=181,y2=279},
    --
    GasTank = {img="gastank", x=14,y=527,x2=70,y2=564},
    --
    Muffler = {img="muffler", x=198,y=527,x2=268,y2=564},
    --
    DAMNBumperFront = {img="bullbar", x=98,y=48,x2=141,y2=86},
    DAMNWindshieldArmor = {img="windshield_armor", x=144,y=48,x2=187,y2=86},
    DAMNFrontLeftArmor = {img="window_front_left_armor", x=13,y=268,x2=55,y2=306},
    DAMNFrontRightArmor = {img="window_front_right_armor", x=228,y=268,x2=270,y2=306},
    DAMNRearLeftArmor = {img="window_rear_left_armor", x=13,y=310,x2=55,y2=346},
    DAMNRearRightArmor = {img="window_rear_right_armor", x=228,y=310,x2=270,y2=346},
    DAMNWindshieldRearArmor = {img="windshield_rear_armor", x=120,y=526,x2=163,y2=564},
}, 10, 0);
--