-- common custom parts

ISCarMechanicsOverlay.PartList["PRS82FrontBumper"] = {img="bullbar", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82RearBumper"] = {img="bullbarr", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82WindshieldArmor"] = {img="windshield_armor", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82FrontLeftArmor"] = {img="window_front_left_armor", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82FrontRightArmor"] = {img="window_front_right_armor", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82WindshieldRearArmor"] = {img="windshield_rear_armor", vehicles = {}};
ISCarMechanicsOverlay.PartList["PRS82Trunk"] = {img="trunkc", vehicles = {}};
--
--##########82porsche911##########
--
ISCarMechanicsOverlay.CarList["Base.82porsche911turbo"] = {imgPrefix = "82porsche911_", x=10,y=0};
ISCarMechanicsOverlay.CarList["Base.82porsche911rwb"] = ISCarMechanicsOverlay.CarList["Base.82porsche911turbo"]
ISCarMechanicsOverlay.CarList["Base.82porsche911sc"] = ISCarMechanicsOverlay.CarList["Base.82porsche911turbo"]
--
ISCarMechanicsOverlay.PartList["Battery"].vehicles["82porsche911_"] = {img="battery", x=228,y=317,x2=270,y2=348};
--
ISCarMechanicsOverlay.PartList["HeadlightLeft"].vehicles["82porsche911_"] = {img="headlight_left", x=79,y=143,x2=99,y2=156};
ISCarMechanicsOverlay.PartList["HeadlightRight"].vehicles["82porsche911_"] = {img="headlight_right", x=182,y=143,x2=202,y2=156};
--
ISCarMechanicsOverlay.PartList["SuspensionFrontLeft"].vehicles["82porsche911_"] = {img="suspension_front_left", x=13,y=143,x2=55,y2=181};
ISCarMechanicsOverlay.PartList["SuspensionFrontRight"].vehicles["82porsche911_"] = {img="suspension_front_right", x=228,y=143,x2=270,y2=181};
ISCarMechanicsOverlay.PartList["SuspensionRearLeft"].vehicles["82porsche911_"] = {x=13,y=357,x2=55,y2=396};
ISCarMechanicsOverlay.PartList["SuspensionRearRight"].vehicles["82porsche911_"] = {x=228,y=357,x2=270,y2=396};
--
ISCarMechanicsOverlay.PartList["BrakeFrontLeft"].vehicles["82porsche911_"] = {img="brake_front_left", x=14,y=181,x2=55,y2=218};
ISCarMechanicsOverlay.PartList["BrakeFrontRight"].vehicles["82porsche911_"] = {img="brake_front_right", x=228,y=181,x2=270,y2=218};
ISCarMechanicsOverlay.PartList["BrakeRearLeft"].vehicles["82porsche911_"] = {x=13,y=396,x2=55,y2=431};
ISCarMechanicsOverlay.PartList["BrakeRearRight"].vehicles["82porsche911_"] = {x=228,y=396,x2=270,y2=431};
--
ISCarMechanicsOverlay.PartList["TireFrontLeft"].vehicles["82porsche911_"] = {x=13,y=218,x2=55,y2=258};
ISCarMechanicsOverlay.PartList["TireFrontRight"].vehicles["82porsche911_"] = {x=228,y=218,x2=270,y2=258};
ISCarMechanicsOverlay.PartList["TireRearLeft"].vehicles["82porsche911_"] = {x=13,y=431,x2=55,y2=471};
ISCarMechanicsOverlay.PartList["TireRearRight"].vehicles["82porsche911_"] = {x=228,y=431,x2=270,y2=471};
--
ISCarMechanicsOverlay.PartList["DoorFrontLeft"].vehicles["82porsche911_"] = {x=72,y=264,x2=82,y2=350};
ISCarMechanicsOverlay.PartList["DoorFrontRight"].vehicles["82porsche911_"] = {x=200,y=264,x2=210,y2=350};
--
ISCarMechanicsOverlay.PartList["Engine"].vehicles["82porsche911_"] = {x=204,y=528,x2=269,y2=568};
--
ISCarMechanicsOverlay.PartList["EngineDoor"].vehicles["82porsche911_"] = {x=102,y=429,x2=179,y2=480};
--
ISCarMechanicsOverlay.PartList["PRS82Trunk"].vehicles["82porsche911_"] = {x=100,y=135,x2=182,y2=245};
--
ISCarMechanicsOverlay.PartList["WindowFrontLeft"].vehicles["82porsche911_"] = {x=82,y=295,x2=93,y2=355};
ISCarMechanicsOverlay.PartList["WindowFrontRight"].vehicles["82porsche911_"] = {x=190,y=295,x2=200,y2=355};
--
ISCarMechanicsOverlay.PartList["Windshield"].vehicles["82porsche911_"] = {x=93,y=248,x2=190,y2=295};
ISCarMechanicsOverlay.PartList["WindshieldRear"].vehicles["82porsche911_"] = {x=99,y=375,x2=183,y2=428};
--
ISCarMechanicsOverlay.PartList["GasTank"].vehicles["82porsche911_"] = {img="gastank", x=13,y=48,x2=70,y2=87};
--
ISCarMechanicsOverlay.PartList["Muffler"].vehicles["82porsche911_"] = {x=13,y=527,x2=83,y2=564};

ISCarMechanicsOverlay.PartList["PRS82FrontBumper"].vehicles["82porsche911_"] = {x=98,y=48,x2=141,y2=86};
ISCarMechanicsOverlay.PartList["PRS82RearBumper"].vehicles["82porsche911_"] = {x=146,y=526,x2=187,y2=564};
ISCarMechanicsOverlay.PartList["PRS82WindshieldArmor"].vehicles["82porsche911_"] = {x=144,y=48,x2=187,y2=86};
ISCarMechanicsOverlay.PartList["PRS82FrontLeftArmor"].vehicles["82porsche911_"] = {x=13,y=268,x2=55,y2=306};
ISCarMechanicsOverlay.PartList["PRS82FrontRightArmor"].vehicles["82porsche911_"] = {x=228,y=268,x2=270,y2=306};
ISCarMechanicsOverlay.PartList["PRS82WindshieldRearArmor"].vehicles["82porsche911_"] = {x=99,y=526,x2=140,y2=564};
--
--##########82porsche911targa##########
--
ISCarMechanicsOverlay.CarList["Base.82porsche911targa"] = {imgPrefix = "82porsche911targa_", x=10,y=0};
--
ISCarMechanicsOverlay.PartList["Battery"].vehicles["82porsche911targa_"] = {img="battery", x=228,y=317,x2=270,y2=348};
--
ISCarMechanicsOverlay.PartList["HeadlightLeft"].vehicles["82porsche911targa_"] = {img="headlight_left", x=79,y=143,x2=99,y2=156};
ISCarMechanicsOverlay.PartList["HeadlightRight"].vehicles["82porsche911targa_"] = {img="headlight_right", x=182,y=143,x2=202,y2=156};
--
ISCarMechanicsOverlay.PartList["SuspensionFrontLeft"].vehicles["82porsche911targa_"] = {img="suspension_front_left", x=13,y=143,x2=55,y2=181};
ISCarMechanicsOverlay.PartList["SuspensionFrontRight"].vehicles["82porsche911targa_"] = {img="suspension_front_right", x=228,y=143,x2=270,y2=181};
ISCarMechanicsOverlay.PartList["SuspensionRearLeft"].vehicles["82porsche911targa_"] = {x=13,y=357,x2=55,y2=396};
ISCarMechanicsOverlay.PartList["SuspensionRearRight"].vehicles["82porsche911targa_"] = {x=228,y=357,x2=270,y2=396};
--
ISCarMechanicsOverlay.PartList["BrakeFrontLeft"].vehicles["82porsche911targa_"] = {img="brake_front_left", x=14,y=181,x2=55,y2=218};
ISCarMechanicsOverlay.PartList["BrakeFrontRight"].vehicles["82porsche911targa_"] = {img="brake_front_right", x=228,y=181,x2=270,y2=218};
ISCarMechanicsOverlay.PartList["BrakeRearLeft"].vehicles["82porsche911targa_"] = {x=13,y=396,x2=55,y2=431};
ISCarMechanicsOverlay.PartList["BrakeRearRight"].vehicles["82porsche911targa_"] = {x=228,y=396,x2=270,y2=431};
--
ISCarMechanicsOverlay.PartList["TireFrontLeft"].vehicles["82porsche911targa_"] = {x=13,y=218,x2=55,y2=258};
ISCarMechanicsOverlay.PartList["TireFrontRight"].vehicles["82porsche911targa_"] = {x=228,y=218,x2=270,y2=258};
ISCarMechanicsOverlay.PartList["TireRearLeft"].vehicles["82porsche911targa_"] = {x=13,y=431,x2=55,y2=471};
ISCarMechanicsOverlay.PartList["TireRearRight"].vehicles["82porsche911targa_"] = {x=228,y=431,x2=270,y2=471};
--
ISCarMechanicsOverlay.PartList["DoorFrontLeft"].vehicles["82porsche911targa_"] = {x=72,y=264,x2=82,y2=350};
ISCarMechanicsOverlay.PartList["DoorFrontRight"].vehicles["82porsche911targa_"] = {x=200,y=264,x2=210,y2=350};
--
ISCarMechanicsOverlay.PartList["Engine"].vehicles["82porsche911targa_"] = {x=204,y=528,x2=269,y2=568};
--
ISCarMechanicsOverlay.PartList["EngineDoor"].vehicles["82porsche911targa_"] = {x=102,y=429,x2=179,y2=480};
--
ISCarMechanicsOverlay.PartList["PRS82Trunk"].vehicles["82porsche911targa_"] = {x=100,y=135,x2=182,y2=245};
--
ISCarMechanicsOverlay.PartList["WindowFrontLeft"].vehicles["82porsche911targa_"] = {x=82,y=295,x2=93,y2=355};
ISCarMechanicsOverlay.PartList["WindowFrontRight"].vehicles["82porsche911targa_"] = {x=190,y=295,x2=200,y2=355};
--
ISCarMechanicsOverlay.PartList["Windshield"].vehicles["82porsche911targa_"] = {x=93,y=248,x2=190,y2=295};
ISCarMechanicsOverlay.PartList["WindshieldRear"].vehicles["82porsche911targa_"] = {x=99,y=375,x2=183,y2=428};
--
ISCarMechanicsOverlay.PartList["GasTank"].vehicles["82porsche911targa_"] = {img="gastank", x=13,y=48,x2=70,y2=87};
--
ISCarMechanicsOverlay.PartList["Muffler"].vehicles["82porsche911targa_"] = {x=13,y=527,x2=83,y2=564};

ISCarMechanicsOverlay.PartList["PRS82FrontBumper"].vehicles["82porsche911targa_"] = {x=98,y=48,x2=141,y2=86};
ISCarMechanicsOverlay.PartList["PRS82RearBumper"].vehicles["82porsche911targa_"] = {x=146,y=526,x2=187,y2=564};
ISCarMechanicsOverlay.PartList["PRS82WindshieldArmor"].vehicles["82porsche911targa_"] = {x=144,y=48,x2=187,y2=86};
ISCarMechanicsOverlay.PartList["PRS82FrontLeftArmor"].vehicles["82porsche911targa_"] = {x=13,y=268,x2=55,y2=306};
ISCarMechanicsOverlay.PartList["PRS82FrontRightArmor"].vehicles["82porsche911targa_"] = {x=228,y=268,x2=270,y2=306};
ISCarMechanicsOverlay.PartList["PRS82WindshieldRearArmor"].vehicles["82porsche911targa_"] = {x=99,y=526,x2=140,y2=564};
--