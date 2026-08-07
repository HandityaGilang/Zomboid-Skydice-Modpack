--========================================================
-- Gore's SVU4 Vanilla Cars - SVU3 Hybrid Visual Lifecycle
-- Hidden lifecycle anchors handle creation and refresh while
-- fitted visual anchors support families that use EngineDoor.
--========================================================

GSVU4VanillaCars = GSVU4VanillaCars or {}
GSVU4VV = GSVU4VV or {}
GSVU4VV.VisualPart = GSVU4VV.VisualPart or {}

local PREFIX = "[Gore's SVU4 Vanilla Vehicles SVU3Hybrid] "


GSVU4VV.Families = {
    {
        id = "CarNormal",
        suffix = "CarNormal",
        template = "GSVU4_SVU3_BodyAnchor_CarNormal",
        lifecycleAnchor = "GSVU4_SVU3_CarNormal_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_CarNormal_BodyAnchor",
        vehicles = { "CarAmbulance", "CarFire", "CarLights", "CarLightsAmbulance", "CarLightsCityLouisvillePD", "CarLightsFire", "CarLightsKST", "CarLightsKYStateTrooper", "CarLightsKentuckyState", "CarLightsKentuckyStatePolice", "CarLightsLouisvilleCounty", "CarLightsLouisvillePolice", "CarLightsMeadeSheriff", "CarLightsPolice", "CarLightsRanger", "CarLightsSheriff", "CarLightsStatePolice", "CarLightsStateTrooper", "CarLightsWestPoint", "CarLights_Ambulance", "CarLights_CityLouisvillePD", "CarLights_Fire", "CarLights_KST", "CarLights_KYStateTrooper", "CarLights_KentuckyState", "CarLights_KentuckyStatePolice", "CarLights_LouisvilleCounty", "CarLights_LouisvillePolice", "CarLights_MeadeSheriff", "CarLights_Police", "CarLights_Ranger", "CarLights_Sheriff", "CarLights_StatePolice", "CarLights_StateTrooper", "CarLights_WestPoint", "CarNormal", "CarNormalTaxi", "CarNormal_Taxi", "CarPolice", "CarRanger", "CarSheriff", "CarStatePolice", "CarTaxi", "CarTaxi2", "Car_Lights", "Car_LightsAmbulance", "Car_LightsCityLouisvillePD", "Car_LightsFire", "Car_LightsKST", "Car_LightsKYStateTrooper", "Car_LightsKentuckyState", "Car_LightsKentuckyStatePolice", "Car_LightsLouisvilleCounty", "Car_LightsLouisvillePolice", "Car_LightsMeadeSheriff", "Car_LightsPolice", "Car_LightsRanger", "Car_LightsSheriff", "Car_LightsStatePolice", "Car_LightsStateTrooper", "Car_LightsWestPoint", "Taxi", "Taxi2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_CarNormal_Paper",
                    Standard = "SVU_Hood_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Hood_CarNormal_Reinforced",
                    Apocalypse = "SVU_Hood_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_CarNormal_Paper",
                    Standard = "SVU_Trunk_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Trunk_CarNormal_Reinforced",
                    Apocalypse = "SVU_Trunk_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_CarNormal_Paper",
                    Standard = "SVU_F_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_F_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_F_Window_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_CarNormal_Paper",
                    Standard = "SVU_R_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_R_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_R_Window_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_CarNormal_Paper",
                    Standard = "SVU_Door_FL_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Door_FL_CarNormal_Reinforced",
                    Apocalypse = "SVU_Door_FL_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_CarNormal_Paper",
                    Standard = "SVU_Door_FR_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Door_FR_CarNormal_Reinforced",
                    Apocalypse = "SVU_Door_FR_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_CarNormal_Paper",
                    Standard = "SVU_Door_RL_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Door_RL_CarNormal_Reinforced",
                    Apocalypse = "SVU_Door_RL_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_CarNormal_Paper",
                    Standard = "SVU_Door_RR_CarNormal_Light_Spiked",
                    Reinforced = "SVU_Door_RR_CarNormal_Reinforced",
                    Apocalypse = "SVU_Door_RR_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_CarNormal_Paper",
                    Standard = "SVU_FL_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_FL_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_FL_Window_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_CarNormal_Paper",
                    Standard = "SVU_FR_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_FR_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_FR_Window_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_CarNormal_Paper",
                    Standard = "SVU_RL_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_RL_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_RL_Window_CarNormal_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_CarNormal_Paper",
                    Standard = "SVU_RR_Window_CarNormal_Light_Spiked",
                    Reinforced = "SVU_RR_Window_CarNormal_Reinforced",
                    Apocalypse = "SVU_RR_Window_CarNormal_Heavy_Spiked"
                }
            }
        }
    },
    {
        id = "CarWagon",
        suffix = "CarWagon",
        template = "GSVU4_SVU3_BodyAnchor_CarWagon",
        lifecycleAnchor = "GSVU4_SVU3_CarWagon_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_CarWagon_BodyAnchor",
        vehicles = { "CarStationWagon", "CarStationWagon2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_CarWagon_Paper",
                    Standard = "SVU_Hood_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Hood_CarWagon_Reinforced",
                    Apocalypse = "SVU_Hood_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_CarWagon_Paper",
                    Standard = "SVU_Trunk_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Trunk_CarWagon_Reinforced",
                    Apocalypse = "SVU_Trunk_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_CarWagon_Paper",
                    Standard = "SVU_F_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_F_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_F_Window_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_CarWagon_Paper",
                    Standard = "SVU_R_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_R_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_R_Window_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_CarWagon_Paper",
                    Standard = "SVU_Door_FL_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Door_FL_CarWagon_Reinforced",
                    Apocalypse = "SVU_Door_FL_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_CarWagon_Paper",
                    Standard = "SVU_Door_FR_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Door_FR_CarWagon_Reinforced",
                    Apocalypse = "SVU_Door_FR_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_CarWagon_Paper",
                    Standard = "SVU_Door_RL_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Door_RL_CarWagon_Reinforced",
                    Apocalypse = "SVU_Door_RL_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_CarWagon_Paper",
                    Standard = "SVU_Door_RR_CarWagon_Light_Spiked",
                    Reinforced = "SVU_Door_RR_CarWagon_Reinforced",
                    Apocalypse = "SVU_Door_RR_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_CarWagon_Paper",
                    Standard = "SVU_FL_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_FL_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_FL_Window_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_CarWagon_Paper",
                    Standard = "SVU_FR_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_FR_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_FR_Window_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_CarWagon_Paper",
                    Standard = "SVU_RL_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_RL_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_RL_Window_CarWagon_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_CarWagon_Paper",
                    Standard = "SVU_RR_Window_CarWagon_Light_Spiked",
                    Reinforced = "SVU_RR_Window_CarWagon_Reinforced",
                    Apocalypse = "SVU_RR_Window_CarWagon_Heavy_Spiked"
                }
            }
        }
    },
    {
        id = "LuxuryCar",
        suffix = "LuxuryCar",
        template = "GSVU4_SVU3_BodyAnchor_LuxuryCar",
        lifecycleAnchor = "GSVU4_SVU3_LuxuryCar_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_LuxuryCar_BodyAnchor",
        vehicles = { "CarLuxury", "CarLuxury2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_LuxuryCar_Paper",
                    Standard = "SVU_Hood_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_Hood_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_Hood_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_LuxuryCar_Paper",
                    Standard = "SVU_Trunk_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_Trunk_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_Trunk_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_LuxuryCar_Paper",
                    Standard = "SVU_F_Window_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_F_Window_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_F_Window_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_LuxuryCar_Paper",
                    Standard = "SVU_R_Window_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_R_Window_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_R_Window_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_LuxuryCar_Paper",
                    Standard = "SVU_Door_FL_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_Door_FL_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_Door_FL_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_LuxuryCar_Paper",
                    Standard = "SVU_Door_FR_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_Door_FR_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_Door_FR_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_LuxuryCar_Paper",
                    Standard = "SVU_FL_Window_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_FL_Window_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_FL_Window_LuxuryCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_LuxuryCar_Paper",
                    Standard = "SVU_FR_Window_LuxuryCar_Light_Spiked",
                    Reinforced = "SVU_FR_Window_LuxuryCar_Reinforced",
                    Apocalypse = "SVU_FR_Window_LuxuryCar_Heavy_Spiked"
                }
            }
        }
    },
    {
        id = "SUV",
        suffix = "SUV",
        template = "GSVU4_SVU3_BodyAnchor_SUV",
        lifecycleAnchor = "GSVU4_SVU3_SUV_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_SUV_BodyAnchor",
        vehicles = { "SUV", "SUV2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_SUV_Paper",
                    Standard = "SVU_Hood_SUV_Light_Spiked",
                    Reinforced = "SVU_Hood_SUV_Reinforced",
                    Apocalypse = "SVU_Hood_SUV_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_SUV_Paper",
                    Standard = "SVU_Trunk_SUV_Light_Spiked",
                    Reinforced = "SVU_Trunk_SUV_Reinforced",
                    Apocalypse = "SVU_Trunk_SUV_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_SUV_Paper",
                    Standard = "SVU_F_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_F_Window_SUV_Reinforced",
                    Apocalypse = "SVU_F_Window_SUV_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_SUV_Paper",
                    Standard = "SVU_R_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_R_Window_SUV_Reinforced",
                    Apocalypse = "SVU_R_Window_SUV_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_SUV_Paper",
                    Standard = "SVU_Door_FL_SUV_Light_Spiked",
                    Reinforced = "SVU_Door_FL_SUV_Reinforced",
                    Apocalypse = "SVU_Door_FL_SUV_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_SUV_Paper",
                    Standard = "SVU_Door_FR_SUV_Light_Spiked",
                    Reinforced = "SVU_Door_FR_SUV_Reinforced",
                    Apocalypse = "SVU_Door_FR_SUV_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_SUV_Paper",
                    Standard = "SVU_Door_RL_SUV_Light_Spiked",
                    Reinforced = "SVU_Door_RL_SUV_Reinforced",
                    Apocalypse = "SVU_Door_RL_SUV_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_SUV_Paper",
                    Standard = "SVU_Door_RR_SUV_Light_Spiked",
                    Reinforced = "SVU_Door_RR_SUV_Reinforced",
                    Apocalypse = "SVU_Door_RR_SUV_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_SUV_Paper",
                    Standard = "SVU_FL_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_FL_Window_SUV_Reinforced",
                    Apocalypse = "SVU_FL_Window_SUV_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_SUV_Paper",
                    Standard = "SVU_FR_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_FR_Window_SUV_Reinforced",
                    Apocalypse = "SVU_FR_Window_SUV_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_SUV_Paper",
                    Standard = "SVU_RL_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_RL_Window_SUV_Reinforced",
                    Apocalypse = "SVU_RL_Window_SUV_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_SUV_Paper",
                    Standard = "SVU_RR_Window_SUV_Light_Spiked",
                    Reinforced = "SVU_RR_Window_SUV_Reinforced",
                    Apocalypse = "SVU_RR_Window_SUV_Heavy_Spiked"
                }
            }
        }
    },
    {
        id = "PickUp",
        suffix = "PickUp",
        template = "GSVU4_SVU3_BodyAnchor_PickUpVan",
        lifecycleAnchor = "GSVU4_SVU3_PickUpVan_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_PickUpVan_BodyAnchor",
        vehicles = { "PickUpTruck", "PickUpTruckBrickingIt", "PickUpTruckBuilder", "PickUpTruckCallowayLandscaping", "PickUpTruckHeltonMetalWorking", "PickUpTruckJOLandscaping", "PickUpTruckJPLandscaping", "PickUpTruckKimbleKonstruction", "PickUpTruckLights", "PickUpTruckLightsAirport", "PickUpTruckLightsAirportSecurity", "PickUpTruckLightsCarpenter", "PickUpTruckLightsFire", "PickUpTruckLightsFossoil", "PickUpTruckLightsKentuckyLumber", "PickUpTruckLightsPolice", "PickUpTruckLightsRanger", "PickUpTruckLightsStatePolice", "PickUpTruckMarchRidgeConstruction", "PickUpTruckMccoy", "PickUpTruckMetalworker", "PickUpTruckTransit", "PickUpTruckWeldingbyCamille", "PickUpTruckYingsWood", "PickUpTruck_Camo", "PickUpVan", "PickUpVanBrickingIt", "PickUpVanBuilder", "PickUpVanCallowayLandscaping", "PickUpVanHeltonMetalWorking", "PickUpVanKimbleKonstruction", "PickUpVanLights", "PickUpVanLightsCarpenter", "PickUpVanLightsFire", "PickUpVanLightsFossoil", "PickUpVanLightsKentuckyLumber", "PickUpVanLightsLouisvilleCounty", "PickUpVanLightsPolice", "PickUpVanLightsRanger", "PickUpVanLightsStatePolice", "PickUpVanLights_LouisvilleCounty", "PickUpVanLouisvilleCounty", "PickUpVanMarchRidgeConstruction", "PickUpVanMccoy", "PickUpVanMetalworker", "PickUpVanTransit", "PickUpVanWeldingbyCamille", "PickUpVanYingsWood", "PickUpVan_Camo", "PickUpVan_LightsLouisvilleCounty", "PickUpVan_LouisvilleCounty" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_PickUp_Paper",
                    Standard = "SVU_Hood_PickUp_Light_Spiked",
                    Reinforced = "SVU_Hood_PickUp_Reinforced",
                    Apocalypse = "SVU_Hood_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_PickUp_Paper",
                    Standard = "SVU_Trunk_PickUp_Light_Spiked",
                    Reinforced = "SVU_Trunk_PickUp_Reinforced",
                    Apocalypse = "SVU_Trunk_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_PickUp_Paper",
                    Standard = "SVU_F_Window_PickUp_Light_Spiked",
                    Reinforced = "SVU_F_Window_PickUp_Reinforced",
                    Apocalypse = "SVU_F_Window_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_PickUp_Paper",
                    Standard = "SVU_R_Window_PickUp_Light_Spiked",
                    Reinforced = "SVU_R_Window_PickUp_Reinforced",
                    Apocalypse = "SVU_R_Window_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_PickUp_Paper",
                    Standard = "SVU_Door_FL_PickUp_Light_Spiked",
                    Reinforced = "SVU_Door_FL_PickUp_Reinforced",
                    Apocalypse = "SVU_Door_FL_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_PickUp_Paper",
                    Standard = "SVU_Door_FR_PickUp_Light_Spiked",
                    Reinforced = "SVU_Door_FR_PickUp_Reinforced",
                    Apocalypse = "SVU_Door_FR_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_Pickup_Paper",
                    Standard = "SVU_Door_RL_Pickup_Light_Spiked",
                    Reinforced = "SVU_Door_RL_Pickup_Reinforced",
                    Apocalypse = "SVU_Door_RL_Pickup_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_Pickup_Paper",
                    Standard = "SVU_Door_RR_Pickup_Light_Spiked",
                    Reinforced = "SVU_Door_RR_Pickup_Reinforced",
                    Apocalypse = "SVU_Door_RR_Pickup_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_PickUp_Paper",
                    Standard = "SVU_FL_Window_PickUp_Light_Spiked",
                    Reinforced = "SVU_FL_Window_PickUp_Reinforced",
                    Apocalypse = "SVU_FL_Window_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_PickUp_Paper",
                    Standard = "SVU_FR_Window_PickUp_Light_Spiked",
                    Reinforced = "SVU_FR_Window_PickUp_Reinforced",
                    Apocalypse = "SVU_FR_Window_PickUp_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_Pickup_Paper",
                    Standard = "SVU_RL_Window_Pickup_Light_Spiked",
                    Reinforced = "SVU_RL_Window_Pickup_Reinforced",
                    Apocalypse = "SVU_RL_Window_Pickup_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_Pickup_Paper",
                    Standard = "SVU_RR_Window_Pickup_Light_Spiked",
                    Reinforced = "SVU_RR_Window_Pickup_Reinforced",
                    Apocalypse = "SVU_RR_Window_Pickup_Heavy_Spiked"
                }
            }
        }
    },
    {
        id = "SmallCar",
        suffix = "SmallCar",
        template = "GSVU4_SVU3_BodyAnchor_SmallCar",
        lifecycleAnchor = "GSVU4_SVU3_SmallCar_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "SmallCar" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_SmallCar_Paper",
                    Standard = "SVU_Hood_SmallCar_Light_Spiked",
                    Reinforced = "SVU_Hood_SmallCar_Reinforced",
                    Apocalypse = "SVU_Hood_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_SmallCar_Paper",
                    Standard = "SVU_Trunk_SmallCar_Light_Spiked",
                    Reinforced = "SVU_Trunk_SmallCar_Reinforced",
                    Apocalypse = "SVU_Trunk_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_SmallCar_Paper",
                    Standard = "SVU_F_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_F_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_F_Window_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_SmallCar_Paper",
                    Standard = "SVU_R_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_R_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_R_Window_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FR_SmallCar_Paper",
                    Standard = "SVU_Door_FR_SmallCar_Light_Spiked",
                    Reinforced = "SVU_Door_FR_SmallCar_Reinforced",
                    Apocalypse = "SVU_Door_FR_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FL_SmallCar_Paper",
                    Standard = "SVU_Door_FL_SmallCar_Light_Spiked",
                    Reinforced = "SVU_Door_FL_SmallCar_Reinforced",
                    Apocalypse = "SVU_Door_FL_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FR_Window_SmallCar_Paper",
                    Standard = "SVU_FR_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_FR_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_FR_Window_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FL_Window_SmallCar_Paper",
                    Standard = "SVU_FL_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_FL_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_FL_Window_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_SmallCar_Paper",
                    Standard = "SVU_RL_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_RL_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_RL_Window_SmallCar_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_SmallCar_Paper",
                    Standard = "SVU_RR_Window_SmallCar_Light_Spiked",
                    Reinforced = "SVU_RR_Window_SmallCar_Reinforced",
                    Apocalypse = "SVU_RR_Window_SmallCar_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_SmallCar_Paper
            {
                file = SVU_Hood_SmallCar_Paper,
            }
            model SVU_Hood_SmallCar_Light_Spiked
            {
                file = SVU_Hood_SmallCar_Light_Spiked,
            }
            model SVU_Hood_SmallCar_Reinforced
            {
                file = SVU_Hood_SmallCar_Reinforced,
            }
            model SVU_Hood_SmallCar_Heavy_Spiked
            {
                file = SVU_Hood_SmallCar_Heavy_Spiked,
            }
            model SVU_Trunk_SmallCar_Paper
            {
                file = SVU_Trunk_SmallCar_Paper,
            }
            model SVU_Trunk_SmallCar_Light_Spiked
            {
                file = SVU_Trunk_SmallCar_Light_Spiked,
            }
            model SVU_Trunk_SmallCar_Reinforced
            {
                file = SVU_Trunk_SmallCar_Reinforced,
            }
            model SVU_Trunk_SmallCar_Heavy_Spiked
            {
                file = SVU_Trunk_SmallCar_Heavy_Spiked,
            }
            model SVU_F_Window_SmallCar_Paper
            {
                file = SVU_F_Window_SmallCar_Paper,
            }
            model SVU_F_Window_SmallCar_Light_Spiked
            {
                file = SVU_F_Window_SmallCar_Light_Spiked,
            }
            model SVU_F_Window_SmallCar_Reinforced
            {
                file = SVU_F_Window_SmallCar_Reinforced,
            }
            model SVU_F_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_F_Window_SmallCar_Heavy_Spiked,
            }
            model SVU_R_Window_SmallCar_Paper
            {
                file = SVU_R_Window_SmallCar_Paper,
            }
            model SVU_R_Window_SmallCar_Light_Spiked
            {
                file = SVU_R_Window_SmallCar_Light_Spiked,
            }
            model SVU_R_Window_SmallCar_Reinforced
            {
                file = SVU_R_Window_SmallCar_Reinforced,
            }
            model SVU_R_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_R_Window_SmallCar_Heavy_Spiked,
            }
            model SVU_Door_FR_SmallCar_Paper
            {
                file = SVU_Door_FR_SmallCar_Paper,
            }
            model SVU_Door_FR_SmallCar_Light_Spiked
            {
                file = SVU_Door_FR_SmallCar_Light_Spiked,
            }
            model SVU_Door_FR_SmallCar_Reinforced
            {
                file = SVU_Door_FR_SmallCar_Reinforced,
            }
            model SVU_Door_FR_SmallCar_Heavy_Spiked
            {
                file = SVU_Door_FR_SmallCar_Heavy_Spiked,
            }
            model SVU_Door_FL_SmallCar_Paper
            {
                file = SVU_Door_FL_SmallCar_Paper,
            }
            model SVU_Door_FL_SmallCar_Light_Spiked
            {
                file = SVU_Door_FL_SmallCar_Light_Spiked,
            }
            model SVU_Door_FL_SmallCar_Reinforced
            {
                file = SVU_Door_FL_SmallCar_Reinforced,
            }
            model SVU_Door_FL_SmallCar_Heavy_Spiked
            {
                file = SVU_Door_FL_SmallCar_Heavy_Spiked,
            }
            model SVU_FR_Window_SmallCar_Paper
            {
                file = SVU_FR_Window_SmallCar_Paper,
            }
            model SVU_FR_Window_SmallCar_Light_Spiked
            {
                file = SVU_FR_Window_SmallCar_Light_Spiked,
            }
            model SVU_FR_Window_SmallCar_Reinforced
            {
                file = SVU_FR_Window_SmallCar_Reinforced,
            }
            model SVU_FR_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_FR_Window_SmallCar_Heavy_Spiked,
            }
            model SVU_FL_Window_SmallCar_Paper
            {
                file = SVU_FL_Window_SmallCar_Paper,
            }
            model SVU_FL_Window_SmallCar_Light_Spiked
            {
                file = SVU_FL_Window_SmallCar_Light_Spiked,
            }
            model SVU_FL_Window_SmallCar_Reinforced
            {
                file = SVU_FL_Window_SmallCar_Reinforced,
            }
            model SVU_FL_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_FL_Window_SmallCar_Heavy_Spiked,
            }
            model SVU_RL_Window_SmallCar_Paper
            {
                file = SVU_RL_Window_SmallCar_Paper,
            }
            model SVU_RL_Window_SmallCar_Light_Spiked
            {
                file = SVU_RL_Window_SmallCar_Light_Spiked,
            }
            model SVU_RL_Window_SmallCar_Reinforced
            {
                file = SVU_RL_Window_SmallCar_Reinforced,
            }
            model SVU_RL_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_RL_Window_SmallCar_Heavy_Spiked,
            }
            model SVU_RR_Window_SmallCar_Paper
            {
                file = SVU_RR_Window_SmallCar_Paper,
            }
            model SVU_RR_Window_SmallCar_Light_Spiked
            {
                file = SVU_RR_Window_SmallCar_Light_Spiked,
            }
            model SVU_RR_Window_SmallCar_Reinforced
            {
                file = SVU_RR_Window_SmallCar_Reinforced,
            }
            model SVU_RR_Window_SmallCar_Heavy_Spiked
            {
                file = SVU_RR_Window_SmallCar_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "SmallCar02",
        suffix = "SmallCar02",
        template = "GSVU4_SVU3_BodyAnchor_SmallCar02",
        lifecycleAnchor = "GSVU4_SVU3_SmallCar02_BodyAnchor",
        visualAnchor = "EngineDoor",
        engineDoorParam = [==[
        part EngineDoor
        {
            setAllModelsVisible = false,
            model GSVU4_SC02_NATIVE_Hood_Scrap
            {
                file = SVU_Hood_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_Hood_Standard
            {
                file = SVU_Hood_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_Hood_Reinforced
            {
                file = SVU_Hood_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_Hood_Apocalypse
            {
                file = SVU_Hood_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_Trunk_Scrap
            {
                file = SVU_Trunk_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_Trunk_Standard
            {
                file = SVU_Trunk_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_Trunk_Reinforced
            {
                file = SVU_Trunk_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_Trunk_Apocalypse
            {
                file = SVU_Trunk_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_FWindow_Scrap
            {
                file = SVU_F_Window_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_FWindow_Standard
            {
                file = SVU_F_Window_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_FWindow_Reinforced
            {
                file = SVU_F_Window_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_FWindow_Apocalypse
            {
                file = SVU_F_Window_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_RWindow_Scrap
            {
                file = SVU_R_Window_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_RWindow_Standard
            {
                file = SVU_R_Window_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_RWindow_Reinforced
            {
                file = SVU_R_Window_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_RWindow_Apocalypse
            {
                file = SVU_R_Window_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_DoorFL_Scrap
            {
                file = SVU_Door_FL_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_DoorFL_Standard
            {
                file = SVU_Door_FL_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_DoorFL_Reinforced
            {
                file = SVU_Door_FL_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_DoorFL_Apocalypse
            {
                file = SVU_Door_FL_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_DoorFR_Scrap
            {
                file = SVU_Door_FR_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_DoorFR_Standard
            {
                file = SVU_Door_FR_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_DoorFR_Reinforced
            {
                file = SVU_Door_FR_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_DoorFR_Apocalypse
            {
                file = SVU_Door_FR_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_WindowFL_Scrap
            {
                file = SVU_FL_Window_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_WindowFL_Standard
            {
                file = SVU_FL_Window_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_WindowFL_Reinforced
            {
                file = SVU_FL_Window_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_WindowFL_Apocalypse
            {
                file = SVU_FL_Window_SmallCar02_Heavy_Spiked,
            }
            model GSVU4_SC02_NATIVE_WindowFR_Scrap
            {
                file = SVU_FR_Window_SmallCar02_Paper,
            }
            model GSVU4_SC02_NATIVE_WindowFR_Standard
            {
                file = SVU_FR_Window_SmallCar02_Light_Spiked,
            }
            model GSVU4_SC02_NATIVE_WindowFR_Reinforced
            {
                file = SVU_FR_Window_SmallCar02_Reinforced,
            }
            model GSVU4_SC02_NATIVE_WindowFR_Apocalypse
            {
                file = SVU_FR_Window_SmallCar02_Heavy_Spiked,
            }

            model GSVU4_SC02_NATIVE_BullBar_Basic
            {
                file = GSVU4_BullbarFallbackModel_SmallCar02_Medium,
            }
            model GSVU4_SC02_NATIVE_BullBar_Standard
            {
                file = GSVU4_BullbarFallbackModel_SmallCar02_Large,
            }
            model GSVU4_SC02_NATIVE_BullBar_Military
            {
                file = GSVU4_BullbarFallbackModel_SmallCar02_LargeSpiked,
            }
        }    ]==],
        vehicles = { "SmallCar02", "SmallCar2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_Hood_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_Hood_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_Hood_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_Hood_Apocalypse"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_Trunk_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_Trunk_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_Trunk_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_Trunk_Apocalypse"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_FWindow_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_FWindow_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_FWindow_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_FWindow_Apocalypse"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_RWindow_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_RWindow_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_RWindow_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_RWindow_Apocalypse"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_DoorFL_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_DoorFL_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_DoorFL_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_DoorFL_Apocalypse"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_DoorFR_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_DoorFR_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_DoorFR_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_DoorFR_Apocalypse"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_WindowFL_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_WindowFL_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_WindowFL_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_WindowFL_Apocalypse"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "GSVU4_SC02_NATIVE_WindowFR_Scrap",
                    Standard = "GSVU4_SC02_NATIVE_WindowFR_Standard",
                    Reinforced = "GSVU4_SC02_NATIVE_WindowFR_Reinforced",
                    Apocalypse = "GSVU4_SC02_NATIVE_WindowFR_Apocalypse"
                }
            }
        }
    },
    {
        id = "SportsCar",
        suffix = "SportsCar",
        template = "GSVU4_SVU3_BodyAnchor_SportsCar",
        lifecycleAnchor = "GSVU4_SVU3_SportsCar_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_SportsCar_BodyAnchor",
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model GSVU4_SVU3_SportsCar_Hood_Scrap
            {
                file = GSVU4_SVU3_SportsCar_Hood_Scrap,
            }
            model GSVU4_SVU3_SportsCar_Hood_Scrap_Alt
            {
                file = GSVU4_SVU3_SportsCar_Hood_Scrap_Alt,
            }
            model GSVU4_SVU3_SportsCar_Hood_Standard
            {
                file = GSVU4_SVU3_SportsCar_Hood_Standard,
            }

            model GSVU4_SVU3_SportsCar_Hood_Light
            {
                file = GSVU4_SVU3_SportsCar_Hood_Light,
            }
            model GSVU4_SVU3_SportsCar_Hood_Reinforced
            {
                file = GSVU4_SVU3_SportsCar_Hood_Reinforced,
            }
            model GSVU4_SVU3_SportsCar_Hood_Apocalypse
            {
                file = GSVU4_SVU3_SportsCar_Hood_Apocalypse,
            }
            model GSVU4_SVU3_SportsCar_Hood_Apocalypse_Base
            {
                file = GSVU4_SVU3_SportsCar_Hood_Apocalypse_Base,
            }
            model GSVU4_SVU3_SportsCar_Hood_Apocalypse_Spiked
            {
                file = GSVU4_SVU3_SportsCar_Hood_Apocalypse_Spiked,
            }
            model GSVU4_SVU3_SportsCar_Hood_Apocalypse_Scoop
            {
                file = GSVU4_SVU3_SportsCar_Hood_Apocalypse_Scoop,
            }
        }
    ]==],
        vehicles = { "SportsCar" },
        groups = {
            {
                group = "Hood",
                visualAnchor = "EngineDoor",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = { "GSVU4_SVU3_SportsCar_Hood_Standard" },
                    Standard = { "GSVU4_SVU3_SportsCar_Hood_Light" },
                    Reinforced = { "GSVU4_SVU3_SportsCar_Hood_Reinforced" },
                    Apocalypse = {
                        "GSVU4_SVU3_SportsCar_Hood_Apocalypse",
                        "GSVU4_SVU3_SportsCar_Hood_Apocalypse_Base",
                        "GSVU4_SVU3_SportsCar_Hood_Apocalypse_Spiked"
                    }
                },
                hideModels = { "GSVU4_SVU3_SportsCar_Hood_Scrap", "GSVU4_SVU3_SportsCar_Hood_Scrap_Alt", "GSVU4_SVU3_SportsCar_Hood_Standard", "GSVU4_SVU3_SportsCar_Hood_Light", "GSVU4_SVU3_SportsCar_Hood_Reinforced", "GSVU4_SVU3_SportsCar_Hood_Apocalypse", "GSVU4_SVU3_SportsCar_Hood_Apocalypse_Base", "GSVU4_SVU3_SportsCar_Hood_Apocalypse_Spiked", "GSVU4_SVU3_SportsCar_Hood_Apocalypse_ScoopBase", "GSVU4_SVU3_SportsCar_Hood_Apocalypse_ScoopSpiked", "GSVU4_SVU3_SportsCar_Hood_Apocalypse_Scoop" }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_Trunk_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_Trunk_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_Trunk_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_Trunk_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_Trunk_Scrap", "GSVU4_SVU3_SportsCar_Trunk_Standard", "GSVU4_SVU3_SportsCar_Trunk_Light", "GSVU4_SVU3_SportsCar_Trunk_Reinforced", "GSVU4_SVU3_SportsCar_Trunk_Apocalypse" }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_Windshield_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_Windshield_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_Windshield_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_Windshield_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_Windshield_Scrap", "GSVU4_SVU3_SportsCar_Windshield_Standard", "GSVU4_SVU3_SportsCar_Windshield_Light", "GSVU4_SVU3_SportsCar_Windshield_Reinforced", "GSVU4_SVU3_SportsCar_Windshield_Apocalypse" }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_WindshieldRear_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_WindshieldRear_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_WindshieldRear_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_WindshieldRear_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_WindshieldRear_Scrap", "GSVU4_SVU3_SportsCar_WindshieldRear_Standard", "GSVU4_SVU3_SportsCar_WindshieldRear_Light", "GSVU4_SVU3_SportsCar_WindshieldRear_Reinforced", "GSVU4_SVU3_SportsCar_WindshieldRear_Apocalypse" }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_DoorFrontLeft_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_DoorFrontLeft_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_DoorFrontLeft_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_DoorFrontLeft_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_DoorFrontLeft_Scrap", "GSVU4_SVU3_SportsCar_DoorFrontLeft_Standard", "GSVU4_SVU3_SportsCar_DoorFrontLeft_Light", "GSVU4_SVU3_SportsCar_DoorFrontLeft_Reinforced", "GSVU4_SVU3_SportsCar_DoorFrontLeft_Apocalypse" }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_DoorFrontRight_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_DoorFrontRight_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_DoorFrontRight_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_DoorFrontRight_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_DoorFrontRight_Scrap", "GSVU4_SVU3_SportsCar_DoorFrontRight_Standard", "GSVU4_SVU3_SportsCar_DoorFrontRight_Light", "GSVU4_SVU3_SportsCar_DoorFrontRight_Reinforced", "GSVU4_SVU3_SportsCar_DoorFrontRight_Apocalypse" }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_WindowFrontLeft_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_WindowFrontLeft_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_WindowFrontLeft_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_WindowFrontLeft_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_WindowFrontLeft_Scrap", "GSVU4_SVU3_SportsCar_WindowFrontLeft_Standard", "GSVU4_SVU3_SportsCar_WindowFrontLeft_Light", "GSVU4_SVU3_SportsCar_WindowFrontLeft_Reinforced", "GSVU4_SVU3_SportsCar_WindowFrontLeft_Apocalypse" }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "GSVU4_SVU3_SportsCar_WindowFrontRight_Standard",
                    Standard = "GSVU4_SVU3_SportsCar_WindowFrontRight_Light",
                    Reinforced = "GSVU4_SVU3_SportsCar_WindowFrontRight_Reinforced",
                    Apocalypse = "GSVU4_SVU3_SportsCar_WindowFrontRight_Apocalypse"
                },
                hideModels = { "GSVU4_SVU3_SportsCar_WindowFrontRight_Scrap", "GSVU4_SVU3_SportsCar_WindowFrontRight_Standard", "GSVU4_SVU3_SportsCar_WindowFrontRight_Light", "GSVU4_SVU3_SportsCar_WindowFrontRight_Reinforced", "GSVU4_SVU3_SportsCar_WindowFrontRight_Apocalypse" }
            }
        }
    },
    {
        id = "ModernCar",
        suffix = "CarModern",
        template = "GSVU4_SVU3_BodyAnchor_CarModern",
        lifecycleAnchor = "GSVU4_SVU3_CarModern_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "CarModern", "CarModernLightsCityLouisvillePD", "CarModernLightsMeadeSheriff", "CarModernLightsWestPoint", "ModernCar", "ModernCarLightsCityLouisvillePD", "ModernCarLightsMeadeSheriff", "ModernCarLightsWestPoint" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_CarModern_Paper",
                    Standard = "SVU_Hood_CarModern_Light_Spiked",
                    Reinforced = "SVU_Hood_CarModern_Reinforced",
                    Apocalypse = "SVU_Hood_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_CarModern_Paper",
                    Standard = "SVU_Trunk_CarModern_Light_Spiked",
                    Reinforced = "SVU_Trunk_CarModern_Reinforced",
                    Apocalypse = "SVU_Trunk_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_CarModern_Paper",
                    Standard = "SVU_F_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_F_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_F_Window_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_CarModern_Paper",
                    Standard = "SVU_R_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_R_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_R_Window_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_CarModern_Paper",
                    Standard = "SVU_Door_FL_CarModern_Light_Spiked",
                    Reinforced = "SVU_Door_FL_CarModern_Reinforced",
                    Apocalypse = "SVU_Door_FL_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_CarModern_Paper",
                    Standard = "SVU_Door_FR_CarModern_Light_Spiked",
                    Reinforced = "SVU_Door_FR_CarModern_Reinforced",
                    Apocalypse = "SVU_Door_FR_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_CarModern_Paper",
                    Standard = "SVU_Door_RL_CarModern_Light_Spiked",
                    Reinforced = "SVU_Door_RL_CarModern_Reinforced",
                    Apocalypse = "SVU_Door_RL_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_CarModern_Paper",
                    Standard = "SVU_Door_RR_CarModern_Light_Spiked",
                    Reinforced = "SVU_Door_RR_CarModern_Reinforced",
                    Apocalypse = "SVU_Door_RR_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_CarModern_Paper",
                    Standard = "SVU_FL_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_FL_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_FL_Window_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_CarModern_Paper",
                    Standard = "SVU_FR_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_FR_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_FR_Window_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_CarModern_Paper",
                    Standard = "SVU_RL_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_RL_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_RL_Window_CarModern_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_CarModern_Paper",
                    Standard = "SVU_RR_Window_CarModern_Light_Spiked",
                    Reinforced = "SVU_RR_Window_CarModern_Reinforced",
                    Apocalypse = "SVU_RR_Window_CarModern_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_CarModern_Paper
            {
                file = SVU_Hood_CarModern_Paper,
            }
            model SVU_Hood_CarModern_Light_Spiked
            {
                file = SVU_Hood_CarModern_Light_Spiked,
            }
            model SVU_Hood_CarModern_Reinforced
            {
                file = SVU_Hood_CarModern_Reinforced,
            }
            model SVU_Hood_CarModern_Heavy_Spiked
            {
                file = SVU_Hood_CarModern_Heavy_Spiked,
            }
            model SVU_Trunk_CarModern_Paper
            {
                file = SVU_Trunk_CarModern_Paper,
            }
            model SVU_Trunk_CarModern_Light_Spiked
            {
                file = SVU_Trunk_CarModern_Light_Spiked,
            }
            model SVU_Trunk_CarModern_Reinforced
            {
                file = SVU_Trunk_CarModern_Reinforced,
            }
            model SVU_Trunk_CarModern_Heavy_Spiked
            {
                file = SVU_Trunk_CarModern_Heavy_Spiked,
            }
            model SVU_F_Window_CarModern_Paper
            {
                file = SVU_F_Window_CarModern_Paper,
            }
            model SVU_F_Window_CarModern_Light_Spiked
            {
                file = SVU_F_Window_CarModern_Light_Spiked,
            }
            model SVU_F_Window_CarModern_Reinforced
            {
                file = SVU_F_Window_CarModern_Reinforced,
            }
            model SVU_F_Window_CarModern_Heavy_Spiked
            {
                file = SVU_F_Window_CarModern_Heavy_Spiked,
            }
            model SVU_R_Window_CarModern_Paper
            {
                file = SVU_R_Window_CarModern_Paper,
            }
            model SVU_R_Window_CarModern_Light_Spiked
            {
                file = SVU_R_Window_CarModern_Light_Spiked,
            }
            model SVU_R_Window_CarModern_Reinforced
            {
                file = SVU_R_Window_CarModern_Reinforced,
            }
            model SVU_R_Window_CarModern_Heavy_Spiked
            {
                file = SVU_R_Window_CarModern_Heavy_Spiked,
            }
            model SVU_Door_FL_CarModern_Paper
            {
                file = SVU_Door_FL_CarModern_Paper,
            }
            model SVU_Door_FL_CarModern_Light_Spiked
            {
                file = SVU_Door_FL_CarModern_Light_Spiked,
            }
            model SVU_Door_FL_CarModern_Reinforced
            {
                file = SVU_Door_FL_CarModern_Reinforced,
            }
            model SVU_Door_FL_CarModern_Heavy_Spiked
            {
                file = SVU_Door_FL_CarModern_Heavy_Spiked,
            }
            model SVU_Door_FR_CarModern_Paper
            {
                file = SVU_Door_FR_CarModern_Paper,
            }
            model SVU_Door_FR_CarModern_Light_Spiked
            {
                file = SVU_Door_FR_CarModern_Light_Spiked,
            }
            model SVU_Door_FR_CarModern_Reinforced
            {
                file = SVU_Door_FR_CarModern_Reinforced,
            }
            model SVU_Door_FR_CarModern_Heavy_Spiked
            {
                file = SVU_Door_FR_CarModern_Heavy_Spiked,
            }
            model SVU_Door_RL_CarModern_Paper
            {
                file = SVU_Door_RL_CarModern_Paper,
            }
            model SVU_Door_RL_CarModern_Light_Spiked
            {
                file = SVU_Door_RL_CarModern_Light_Spiked,
            }
            model SVU_Door_RL_CarModern_Reinforced
            {
                file = SVU_Door_RL_CarModern_Reinforced,
            }
            model SVU_Door_RL_CarModern_Heavy_Spiked
            {
                file = SVU_Door_RL_CarModern_Heavy_Spiked,
            }
            model SVU_Door_RR_CarModern_Paper
            {
                file = SVU_Door_RR_CarModern_Paper,
            }
            model SVU_Door_RR_CarModern_Light_Spiked
            {
                file = SVU_Door_RR_CarModern_Light_Spiked,
            }
            model SVU_Door_RR_CarModern_Reinforced
            {
                file = SVU_Door_RR_CarModern_Reinforced,
            }
            model SVU_Door_RR_CarModern_Heavy_Spiked
            {
                file = SVU_Door_RR_CarModern_Heavy_Spiked,
            }
            model SVU_FL_Window_CarModern_Paper
            {
                file = SVU_FL_Window_CarModern_Paper,
            }
            model SVU_FL_Window_CarModern_Light_Spiked
            {
                file = SVU_FL_Window_CarModern_Light_Spiked,
            }
            model SVU_FL_Window_CarModern_Reinforced
            {
                file = SVU_FL_Window_CarModern_Reinforced,
            }
            model SVU_FL_Window_CarModern_Heavy_Spiked
            {
                file = SVU_FL_Window_CarModern_Heavy_Spiked,
            }
            model SVU_FR_Window_CarModern_Paper
            {
                file = SVU_FR_Window_CarModern_Paper,
            }
            model SVU_FR_Window_CarModern_Light_Spiked
            {
                file = SVU_FR_Window_CarModern_Light_Spiked,
            }
            model SVU_FR_Window_CarModern_Reinforced
            {
                file = SVU_FR_Window_CarModern_Reinforced,
            }
            model SVU_FR_Window_CarModern_Heavy_Spiked
            {
                file = SVU_FR_Window_CarModern_Heavy_Spiked,
            }
            model SVU_RL_Window_CarModern_Paper
            {
                file = SVU_RL_Window_CarModern_Paper,
            }
            model SVU_RL_Window_CarModern_Light_Spiked
            {
                file = SVU_RL_Window_CarModern_Light_Spiked,
            }
            model SVU_RL_Window_CarModern_Reinforced
            {
                file = SVU_RL_Window_CarModern_Reinforced,
            }
            model SVU_RL_Window_CarModern_Heavy_Spiked
            {
                file = SVU_RL_Window_CarModern_Heavy_Spiked,
            }
            model SVU_RR_Window_CarModern_Paper
            {
                file = SVU_RR_Window_CarModern_Paper,
            }
            model SVU_RR_Window_CarModern_Light_Spiked
            {
                file = SVU_RR_Window_CarModern_Light_Spiked,
            }
            model SVU_RR_Window_CarModern_Reinforced
            {
                file = SVU_RR_Window_CarModern_Reinforced,
            }
            model SVU_RR_Window_CarModern_Heavy_Spiked
            {
                file = SVU_RR_Window_CarModern_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "ModernCar2",
        suffix = "CarModern2",
        template = "GSVU4_SVU3_BodyAnchor_CarModern2",
        lifecycleAnchor = "GSVU4_SVU3_CarModern2_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "CarModern02", "CarModern2", "ModernCar02", "ModernCar2" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_CarModern2_Paper",
                    Standard = "SVU_Hood_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Hood_CarModern2_Reinforced",
                    Apocalypse = "SVU_Hood_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_CarModern2_Paper",
                    Standard = "SVU_Trunk_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Trunk_CarModern2_Reinforced",
                    Apocalypse = "SVU_Trunk_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_CarModern2_Paper",
                    Standard = "SVU_F_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_F_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_F_Window_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_CarModern2_Paper",
                    Standard = "SVU_R_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_R_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_R_Window_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_CarModern2_Paper",
                    Standard = "SVU_Door_FL_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Door_FL_CarModern2_Reinforced",
                    Apocalypse = "SVU_Door_FL_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_CarModern2_Paper",
                    Standard = "SVU_Door_FR_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Door_FR_CarModern2_Reinforced",
                    Apocalypse = "SVU_Door_FR_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_CarModern2_Paper",
                    Standard = "SVU_Door_RL_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Door_RL_CarModern2_Reinforced",
                    Apocalypse = "SVU_Door_RL_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_CarModern2_Paper",
                    Standard = "SVU_Door_RR_CarModern2_Light_Spiked",
                    Reinforced = "SVU_Door_RR_CarModern2_Reinforced",
                    Apocalypse = "SVU_Door_RR_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_CarModern2_Paper",
                    Standard = "SVU_FL_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_FL_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_FL_Window_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_CarModern2_Paper",
                    Standard = "SVU_FR_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_FR_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_FR_Window_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_CarModern2_Paper",
                    Standard = "SVU_RL_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_RL_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_RL_Window_CarModern2_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_CarModern2_Paper",
                    Standard = "SVU_RR_Window_CarModern2_Light_Spiked",
                    Reinforced = "SVU_RR_Window_CarModern2_Reinforced",
                    Apocalypse = "SVU_RR_Window_CarModern2_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_CarModern2_Paper
            {
                file = SVU_Hood_CarModern2_Paper,
            }
            model SVU_Hood_CarModern2_Light_Spiked
            {
                file = SVU_Hood_CarModern2_Light_Spiked,
            }
            model SVU_Hood_CarModern2_Reinforced
            {
                file = SVU_Hood_CarModern2_Reinforced,
            }
            model SVU_Hood_CarModern2_Heavy_Spiked
            {
                file = SVU_Hood_CarModern2_Heavy_Spiked,
            }
            model SVU_Trunk_CarModern2_Paper
            {
                file = SVU_Trunk_CarModern2_Paper,
            }
            model SVU_Trunk_CarModern2_Light_Spiked
            {
                file = SVU_Trunk_CarModern2_Light_Spiked,
            }
            model SVU_Trunk_CarModern2_Reinforced
            {
                file = SVU_Trunk_CarModern2_Reinforced,
            }
            model SVU_Trunk_CarModern2_Heavy_Spiked
            {
                file = SVU_Trunk_CarModern2_Heavy_Spiked,
            }
            model SVU_F_Window_CarModern2_Paper
            {
                file = SVU_F_Window_CarModern2_Paper,
            }
            model SVU_F_Window_CarModern2_Light_Spiked
            {
                file = SVU_F_Window_CarModern2_Light_Spiked,
            }
            model SVU_F_Window_CarModern2_Reinforced
            {
                file = SVU_F_Window_CarModern2_Reinforced,
            }
            model SVU_F_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_F_Window_CarModern2_Heavy_Spiked,
            }
            model SVU_R_Window_CarModern2_Paper
            {
                file = SVU_R_Window_CarModern2_Paper,
            }
            model SVU_R_Window_CarModern2_Light_Spiked
            {
                file = SVU_R_Window_CarModern2_Light_Spiked,
            }
            model SVU_R_Window_CarModern2_Reinforced
            {
                file = SVU_R_Window_CarModern2_Reinforced,
            }
            model SVU_R_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_R_Window_CarModern2_Heavy_Spiked,
            }
            model SVU_Door_FL_CarModern2_Paper
            {
                file = SVU_Door_FL_CarModern2_Paper,
            }
            model SVU_Door_FL_CarModern2_Light_Spiked
            {
                file = SVU_Door_FL_CarModern2_Light_Spiked,
            }
            model SVU_Door_FL_CarModern2_Reinforced
            {
                file = SVU_Door_FL_CarModern2_Reinforced,
            }
            model SVU_Door_FL_CarModern2_Heavy_Spiked
            {
                file = SVU_Door_FL_CarModern2_Heavy_Spiked,
            }
            model SVU_Door_FR_CarModern2_Paper
            {
                file = SVU_Door_FR_CarModern2_Paper,
            }
            model SVU_Door_FR_CarModern2_Light_Spiked
            {
                file = SVU_Door_FR_CarModern2_Light_Spiked,
            }
            model SVU_Door_FR_CarModern2_Reinforced
            {
                file = SVU_Door_FR_CarModern2_Reinforced,
            }
            model SVU_Door_FR_CarModern2_Heavy_Spiked
            {
                file = SVU_Door_FR_CarModern2_Heavy_Spiked,
            }
            model SVU_Door_RL_CarModern2_Paper
            {
                file = SVU_Door_RL_CarModern2_Paper,
            }
            model SVU_Door_RL_CarModern2_Light_Spiked
            {
                file = SVU_Door_RL_CarModern2_Light_Spiked,
            }
            model SVU_Door_RL_CarModern2_Reinforced
            {
                file = SVU_Door_RL_CarModern2_Reinforced,
            }
            model SVU_Door_RL_CarModern2_Heavy_Spiked
            {
                file = SVU_Door_RL_CarModern2_Heavy_Spiked,
            }
            model SVU_Door_RR_CarModern2_Paper
            {
                file = SVU_Door_RR_CarModern2_Paper,
            }
            model SVU_Door_RR_CarModern2_Light_Spiked
            {
                file = SVU_Door_RR_CarModern2_Light_Spiked,
            }
            model SVU_Door_RR_CarModern2_Reinforced
            {
                file = SVU_Door_RR_CarModern2_Reinforced,
            }
            model SVU_Door_RR_CarModern2_Heavy_Spiked
            {
                file = SVU_Door_RR_CarModern2_Heavy_Spiked,
            }
            model SVU_FL_Window_CarModern2_Paper
            {
                file = SVU_FL_Window_CarModern2_Paper,
            }
            model SVU_FL_Window_CarModern2_Light_Spiked
            {
                file = SVU_FL_Window_CarModern2_Light_Spiked,
            }
            model SVU_FL_Window_CarModern2_Reinforced
            {
                file = SVU_FL_Window_CarModern2_Reinforced,
            }
            model SVU_FL_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_FL_Window_CarModern2_Heavy_Spiked,
            }
            model SVU_FR_Window_CarModern2_Paper
            {
                file = SVU_FR_Window_CarModern2_Paper,
            }
            model SVU_FR_Window_CarModern2_Light_Spiked
            {
                file = SVU_FR_Window_CarModern2_Light_Spiked,
            }
            model SVU_FR_Window_CarModern2_Reinforced
            {
                file = SVU_FR_Window_CarModern2_Reinforced,
            }
            model SVU_FR_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_FR_Window_CarModern2_Heavy_Spiked,
            }
            model SVU_RL_Window_CarModern2_Paper
            {
                file = SVU_RL_Window_CarModern2_Paper,
            }
            model SVU_RL_Window_CarModern2_Light_Spiked
            {
                file = SVU_RL_Window_CarModern2_Light_Spiked,
            }
            model SVU_RL_Window_CarModern2_Reinforced
            {
                file = SVU_RL_Window_CarModern2_Reinforced,
            }
            model SVU_RL_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_RL_Window_CarModern2_Heavy_Spiked,
            }
            model SVU_RR_Window_CarModern2_Paper
            {
                file = SVU_RR_Window_CarModern2_Paper,
            }
            model SVU_RR_Window_CarModern2_Light_Spiked
            {
                file = SVU_RR_Window_CarModern2_Light_Spiked,
            }
            model SVU_RR_Window_CarModern2_Reinforced
            {
                file = SVU_RR_Window_CarModern2_Reinforced,
            }
            model SVU_RR_Window_CarModern2_Heavy_Spiked
            {
                file = SVU_RR_Window_CarModern2_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "Van",
        suffix = "Van",
        template = "GSVU4_SVU3_BodyAnchor_Van",
        lifecycleAnchor = "GSVU4_SVU3_Van_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "Van", "VanAmbulance", "VanBeckmans", "VanBlacksmith", "VanBrewsterHarbin", "VanBugWipers", "VanBuilder", "VanCarpenter", "VanCharlemangeBeer", "VanCoastToCoast", "VanCraftSupplies", "VanDeerValley", "VanFossoil", "VanGardenGods", "VanGardener", "VanGlass", "VanGreenes", "VanHeritageTailors", "VanJohnMcCoy", "VanJonesFabrication", "VanKerrHomes", "VanKnobCreekGas", "VanKnoxCom", "VanKnoxDisti", "VanKorshunovs", "VanLeather", "VanLectroMax", "VanLocksmith", "VanLouisvilleLandscaping", "VanMail", "VanMasonry", "VanMassGenFac", "VanMcCoy", "VanMccoy", "VanMechanic", "VanMeltingPointMetal", "VanMetalheads", "VanMetalworker", "VanMicheles", "VanMobileMechanics", "VanMooreMechanics", "VanOldMill", "VanOvoFarm", "VanPennSHam", "VanPerfickPotato", "VanPlattAuto", "VanPluggedInElectrics", "VanRadio", "VanRadio3N", "VanRadio_3N", "VanRiversideFabrication", "VanRosewoodworking", "VanSchwabSheetMetal", "VanSeats", "VanSeatsAirportShuttle", "VanSeatsCreature", "VanSeatsLadyDelighter", "VanSeatsMural", "VanSeatsPrison", "VanSeatsSpace", "VanSeatsTrippy", "VanSeatsValkyrie", "VanSeats_AirportShuttle", "VanSeats_Creature", "VanSeats_LadyDelighter", "VanSeats_Mural", "VanSeats_Prison", "VanSeats_Space", "VanSeats_Trippy", "VanSeats_Valkyrie", "VanSpiffo", "VanTransit", "VanTreyBaines", "VanUncloggers", "VanUtility", "VanVoltMojo", "VanWPCarpentry", "Van_Ambulance", "Van_Beckmans", "Van_Blacksmith", "Van_BrewsterHarbin", "Van_BugWipers", "Van_Builder", "Van_Carpenter", "Van_CharlemangeBeer", "Van_Charlemange_Beer", "Van_CoastToCoast", "Van_CraftSupplies", "Van_DeerValley", "Van_Fossoil", "Van_GardenGods", "Van_Gardener", "Van_Glass", "Van_Greenes", "Van_HeritageTailors", "Van_JohnMcCoy", "Van_JonesFabrication", "Van_KerrHomes", "Van_KnobCreekGas", "Van_KnoxCom", "Van_KnoxDisti", "Van_Korshunovs", "Van_Leather", "Van_LectroMax", "Van_Locksmith", "Van_LouisvilleLandscaping", "Van_Mail", "Van_Masonry", "Van_MassGenFac", "Van_McCoy", "Van_Mccoy", "Van_Mechanic", "Van_MeltingPointMetal", "Van_Metalheads", "Van_Metalworker", "Van_Micheles", "Van_MobileMechanics", "Van_MooreMechanics", "Van_OldMill", "Van_OvoFarm", "Van_PennSHam", "Van_PerfickPotato", "Van_Perfick_Potato", "Van_PlattAuto", "Van_PluggedInElectrics", "Van_RiversideFabrication", "Van_Rosewoodworking", "Van_SchwabSheetMetal", "Van_Spiffo", "Van_Transit", "Van_TreyBaines", "Van_Uncloggers", "Van_Utility", "Van_VoltMojo", "Van_WPCarpentry" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_Van_Paper",
                    Standard = "SVU_Hood_Van_Light_Spiked",
                    Reinforced = "SVU_Hood_Van_Reinforced",
                    Apocalypse = "SVU_Hood_Van_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_Van_Paper",
                    Standard = "SVU_Trunk_Van_Light_Spiked",
                    Reinforced = "SVU_Trunk_Van_Reinforced",
                    Apocalypse = "SVU_Trunk_Van_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_Van_Paper",
                    Standard = "SVU_F_Window_Van_Light_Spiked",
                    Reinforced = "SVU_F_Window_Van_Reinforced",
                    Apocalypse = "SVU_F_Window_Van_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_Van_Paper",
                    Standard = "SVU_R_Window_Van_Light_Spiked",
                    Reinforced = "SVU_R_Window_Van_Reinforced",
                    Apocalypse = "SVU_R_Window_Van_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_Van_Paper",
                    Standard = "SVU_Door_FL_Van_Light_Spiked",
                    Reinforced = "SVU_Door_FL_Van_Reinforced",
                    Apocalypse = "SVU_Door_FL_Van_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_Van_Paper",
                    Standard = "SVU_Door_FR_Van_Light_Spiked",
                    Reinforced = "SVU_Door_FR_Van_Reinforced",
                    Apocalypse = "SVU_Door_FR_Van_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_Van_Paper",
                    Standard = "SVU_Door_RL_Van_Light_Spiked",
                    Reinforced = "SVU_Door_RL_Van_Reinforced",
                    Apocalypse = "SVU_Door_RL_Van_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_Van_Paper",
                    Standard = "SVU_Door_RR_Van_Light_Spiked",
                    Reinforced = "SVU_Door_RR_Van_Reinforced",
                    Apocalypse = "SVU_Door_RR_Van_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_Van_Paper",
                    Standard = "SVU_FL_Window_Van_Light_Spiked",
                    Reinforced = "SVU_FL_Window_Van_Reinforced",
                    Apocalypse = "SVU_FL_Window_Van_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_Van_Paper",
                    Standard = "SVU_FR_Window_Van_Light_Spiked",
                    Reinforced = "SVU_FR_Window_Van_Reinforced",
                    Apocalypse = "SVU_FR_Window_Van_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_Van_Paper",
                    Standard = "SVU_RL_Window_Van_Light_Spiked",
                    Reinforced = "SVU_RL_Window_Van_Reinforced",
                    Apocalypse = "SVU_RL_Window_Van_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_Van_Paper",
                    Standard = "SVU_RR_Window_Van_Light_Spiked",
                    Reinforced = "SVU_RR_Window_Van_Reinforced",
                    Apocalypse = "SVU_RR_Window_Van_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_Van_Paper
            {
                file = SVU_Hood_Van_Paper,
            }
            model SVU_Hood_Van_Light_Spiked
            {
                file = SVU_Hood_Van_Light_Spiked,
            }
            model SVU_Hood_Van_Reinforced
            {
                file = SVU_Hood_Van_Reinforced,
            }
            model SVU_Hood_Van_Heavy_Spiked
            {
                file = SVU_Hood_Van_Heavy_Spiked,
            }
            model SVU_Trunk_Van_Paper
            {
                file = SVU_Trunk_Van_Paper,
            }
            model SVU_Trunk_Van_Light_Spiked
            {
                file = SVU_Trunk_Van_Light_Spiked,
            }
            model SVU_Trunk_Van_Reinforced
            {
                file = SVU_Trunk_Van_Reinforced,
            }
            model SVU_Trunk_Van_Heavy_Spiked
            {
                file = SVU_Trunk_Van_Heavy_Spiked,
            }
            model SVU_F_Window_Van_Paper
            {
                file = SVU_F_Window_Van_Paper,
            }
            model SVU_F_Window_Van_Light_Spiked
            {
                file = SVU_F_Window_Van_Light_Spiked,
            }
            model SVU_F_Window_Van_Reinforced
            {
                file = SVU_F_Window_Van_Reinforced,
            }
            model SVU_F_Window_Van_Heavy_Spiked
            {
                file = SVU_F_Window_Van_Heavy_Spiked,
            }
            model SVU_R_Window_Van_Paper
            {
                file = SVU_R_Window_Van_Paper,
            }
            model SVU_R_Window_Van_Light_Spiked
            {
                file = SVU_R_Window_Van_Light_Spiked,
            }
            model SVU_R_Window_Van_Reinforced
            {
                file = SVU_R_Window_Van_Reinforced,
            }
            model SVU_R_Window_Van_Heavy_Spiked
            {
                file = SVU_R_Window_Van_Heavy_Spiked,
            }
            model SVU_Door_FL_Van_Paper
            {
                file = SVU_Door_FL_Van_Paper,
            }
            model SVU_Door_FL_Van_Light_Spiked
            {
                file = SVU_Door_FL_Van_Light_Spiked,
            }
            model SVU_Door_FL_Van_Reinforced
            {
                file = SVU_Door_FL_Van_Reinforced,
            }
            model SVU_Door_FL_Van_Heavy_Spiked
            {
                file = SVU_Door_FL_Van_Heavy_Spiked,
            }
            model SVU_Door_FR_Van_Paper
            {
                file = SVU_Door_FR_Van_Paper,
            }
            model SVU_Door_FR_Van_Light_Spiked
            {
                file = SVU_Door_FR_Van_Light_Spiked,
            }
            model SVU_Door_FR_Van_Reinforced
            {
                file = SVU_Door_FR_Van_Reinforced,
            }
            model SVU_Door_FR_Van_Heavy_Spiked
            {
                file = SVU_Door_FR_Van_Heavy_Spiked,
            }
            model SVU_Door_RL_Van_Paper
            {
                file = SVU_Door_RL_Van_Paper,
            }
            model SVU_Door_RL_Van_Light_Spiked
            {
                file = SVU_Door_RL_Van_Light_Spiked,
            }
            model SVU_Door_RL_Van_Reinforced
            {
                file = SVU_Door_RL_Van_Reinforced,
            }
            model SVU_Door_RL_Van_Heavy_Spiked
            {
                file = SVU_Door_RL_Van_Heavy_Spiked,
            }
            model SVU_Door_RR_Van_Paper
            {
                file = SVU_Door_RR_Van_Paper,
            }
            model SVU_Door_RR_Van_Light_Spiked
            {
                file = SVU_Door_RR_Van_Light_Spiked,
            }
            model SVU_Door_RR_Van_Reinforced
            {
                file = SVU_Door_RR_Van_Reinforced,
            }
            model SVU_Door_RR_Van_Heavy_Spiked
            {
                file = SVU_Door_RR_Van_Heavy_Spiked,
            }
            model SVU_FL_Window_Van_Paper
            {
                file = SVU_FL_Window_Van_Paper,
            }
            model SVU_FL_Window_Van_Light_Spiked
            {
                file = SVU_FL_Window_Van_Light_Spiked,
            }
            model SVU_FL_Window_Van_Reinforced
            {
                file = SVU_FL_Window_Van_Reinforced,
            }
            model SVU_FL_Window_Van_Heavy_Spiked
            {
                file = SVU_FL_Window_Van_Heavy_Spiked,
            }
            model SVU_FR_Window_Van_Paper
            {
                file = SVU_FR_Window_Van_Paper,
            }
            model SVU_FR_Window_Van_Light_Spiked
            {
                file = SVU_FR_Window_Van_Light_Spiked,
            }
            model SVU_FR_Window_Van_Reinforced
            {
                file = SVU_FR_Window_Van_Reinforced,
            }
            model SVU_FR_Window_Van_Heavy_Spiked
            {
                file = SVU_FR_Window_Van_Heavy_Spiked,
            }
            model SVU_RL_Window_Van_Paper
            {
                file = SVU_RL_Window_Van_Paper,
            }
            model SVU_RL_Window_Van_Light_Spiked
            {
                file = SVU_RL_Window_Van_Light_Spiked,
            }
            model SVU_RL_Window_Van_Reinforced
            {
                file = SVU_RL_Window_Van_Reinforced,
            }
            model SVU_RL_Window_Van_Heavy_Spiked
            {
                file = SVU_RL_Window_Van_Heavy_Spiked,
            }
            model SVU_RR_Window_Van_Paper
            {
                file = SVU_RR_Window_Van_Paper,
            }
            model SVU_RR_Window_Van_Light_Spiked
            {
                file = SVU_RR_Window_Van_Light_Spiked,
            }
            model SVU_RR_Window_Van_Reinforced
            {
                file = SVU_RR_Window_Van_Reinforced,
            }
            model SVU_RR_Window_Van_Heavy_Spiked
            {
                file = SVU_RR_Window_Van_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "StepVan",
        suffix = "StepVan",
        template = "GSVU4_SVU3_BodyAnchor_StepVan",
        lifecycleAnchor = "GSVU4_SVU3_StepVan_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "StepVan", "StepVanCatering", "StepVanCityLouisvillePD", "StepVanCourier", "StepVanFire", "StepVanFossoil", "StepVanHeralds", "StepVanKentuckyLumber", "StepVanLaundry", "StepVanLouisvillePolice", "StepVanLouisvillePoliceSWAT", "StepVanLouisvilleSWAT", "StepVanMail", "StepVanMcCoy", "StepVanMeadeSheriff", "StepVanMechanic", "StepVanMobileMechanic", "StepVanPolice", "StepVanPostal", "StepVanPrison", "StepVanPropane", "StepVanRanger", "StepVanSWAT", "StepVanScarletOakDistillery", "StepVanValuInsurance", "StepVanWestPoint", "StepVan_Catering", "StepVan_CityLouisvillePD", "StepVan_Courier", "StepVan_Fire", "StepVan_Fossoil", "StepVan_Heralds", "StepVan_KentuckyLumber", "StepVan_Laundry", "StepVan_LouisvillePolice", "StepVan_LouisvillePoliceSWAT", "StepVan_LouisvilleSWAT", "StepVan_Mail", "StepVan_McCoy", "StepVan_MeadeSheriff", "StepVan_Mechanic", "StepVan_MobileMechanic", "StepVan_Police", "StepVan_PostOffice", "StepVan_Prison", "StepVan_Propane", "StepVan_Ranger", "StepVan_SWAT", "StepVan_ScarletOakDistillery", "StepVan_ValuInsurance", "StepVan_WestPoint", "StepVan_Citr8", "StepVan_MobileLibrary", "StepVan_SouthEasternHosp" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_StepVan_Paper",
                    Standard = "SVU_Hood_StepVan_Light_Spiked",
                    Reinforced = "SVU_Hood_StepVan_Reinforced",
                    Apocalypse = "SVU_Hood_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_StepVan_Paper",
                    Standard = "SVU_Trunk_StepVan_Light_Spiked",
                    Reinforced = "SVU_Trunk_StepVan_Reinforced",
                    Apocalypse = "SVU_Trunk_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_StepVan_Paper",
                    Standard = "SVU_F_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_F_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_F_Window_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_StepVan_Paper",
                    Standard = "SVU_R_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_R_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_R_Window_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_StepVan_Paper",
                    Standard = "SVU_Door_FL_StepVan_Light_Spiked",
                    Reinforced = "SVU_Door_FL_StepVan_Reinforced",
                    Apocalypse = "SVU_Door_FL_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_StepVan_Paper",
                    Standard = "SVU_Door_FR_StepVan_Light_Spiked",
                    Reinforced = "SVU_Door_FR_StepVan_Reinforced",
                    Apocalypse = "SVU_Door_FR_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_StepVan_Paper",
                    Standard = "SVU_Door_RL_StepVan_Light_Spiked",
                    Reinforced = "SVU_Door_RL_StepVan_Reinforced",
                    Apocalypse = "SVU_Door_RL_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_StepVan_Paper",
                    Standard = "SVU_Door_RR_StepVan_Light_Spiked",
                    Reinforced = "SVU_Door_RR_StepVan_Reinforced",
                    Apocalypse = "SVU_Door_RR_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_StepVan_Paper",
                    Standard = "SVU_FL_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_FL_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_FL_Window_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_StepVan_Paper",
                    Standard = "SVU_FR_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_FR_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_FR_Window_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_StepVan_Paper",
                    Standard = "SVU_RL_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_RL_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_RL_Window_StepVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_StepVan_Paper",
                    Standard = "SVU_RR_Window_StepVan_Light_Spiked",
                    Reinforced = "SVU_RR_Window_StepVan_Reinforced",
                    Apocalypse = "SVU_RR_Window_StepVan_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_StepVan_Paper
            {
                file = SVU_Hood_StepVan_Paper,
            }
            model SVU_Hood_StepVan_Light_Spiked
            {
                file = SVU_Hood_StepVan_Light_Spiked,
            }
            model SVU_Hood_StepVan_Reinforced
            {
                file = SVU_Hood_StepVan_Reinforced,
            }
            model SVU_Hood_StepVan_Heavy_Spiked
            {
                file = SVU_Hood_StepVan_Heavy_Spiked,
            }
            model SVU_Trunk_StepVan_Paper
            {
                file = SVU_Trunk_StepVan_Paper,
            }
            model SVU_Trunk_StepVan_Light_Spiked
            {
                file = SVU_Trunk_StepVan_Light_Spiked,
            }
            model SVU_Trunk_StepVan_Reinforced
            {
                file = SVU_Trunk_StepVan_Reinforced,
            }
            model SVU_Trunk_StepVan_Heavy_Spiked
            {
                file = SVU_Trunk_StepVan_Heavy_Spiked,
            }
            model SVU_F_Window_StepVan_Paper
            {
                file = SVU_F_Window_StepVan_Paper,
            }
            model SVU_F_Window_StepVan_Light_Spiked
            {
                file = SVU_F_Window_StepVan_Light_Spiked,
            }
            model SVU_F_Window_StepVan_Reinforced
            {
                file = SVU_F_Window_StepVan_Reinforced,
            }
            model SVU_F_Window_StepVan_Heavy_Spiked
            {
                file = SVU_F_Window_StepVan_Heavy_Spiked,
            }
            model SVU_R_Window_StepVan_Paper
            {
                file = SVU_R_Window_StepVan_Paper,
            }
            model SVU_R_Window_StepVan_Light_Spiked
            {
                file = SVU_R_Window_StepVan_Light_Spiked,
            }
            model SVU_R_Window_StepVan_Reinforced
            {
                file = SVU_R_Window_StepVan_Reinforced,
            }
            model SVU_R_Window_StepVan_Heavy_Spiked
            {
                file = SVU_R_Window_StepVan_Heavy_Spiked,
            }
            model SVU_Door_FL_StepVan_Paper
            {
                file = SVU_Door_FL_StepVan_Paper,
            }
            model SVU_Door_FL_StepVan_Light_Spiked
            {
                file = SVU_Door_FL_StepVan_Light_Spiked,
            }
            model SVU_Door_FL_StepVan_Reinforced
            {
                file = SVU_Door_FL_StepVan_Reinforced,
            }
            model SVU_Door_FL_StepVan_Heavy_Spiked
            {
                file = SVU_Door_FL_StepVan_Heavy_Spiked,
            }
            model SVU_Door_FR_StepVan_Paper
            {
                file = SVU_Door_FR_StepVan_Paper,
            }
            model SVU_Door_FR_StepVan_Light_Spiked
            {
                file = SVU_Door_FR_StepVan_Light_Spiked,
            }
            model SVU_Door_FR_StepVan_Reinforced
            {
                file = SVU_Door_FR_StepVan_Reinforced,
            }
            model SVU_Door_FR_StepVan_Heavy_Spiked
            {
                file = SVU_Door_FR_StepVan_Heavy_Spiked,
            }
            model SVU_Door_RL_StepVan_Paper
            {
                file = SVU_Door_RL_StepVan_Paper,
            }
            model SVU_Door_RL_StepVan_Light_Spiked
            {
                file = SVU_Door_RL_StepVan_Light_Spiked,
            }
            model SVU_Door_RL_StepVan_Reinforced
            {
                file = SVU_Door_RL_StepVan_Reinforced,
            }
            model SVU_Door_RL_StepVan_Heavy_Spiked
            {
                file = SVU_Door_RL_StepVan_Heavy_Spiked,
            }
            model SVU_Door_RR_StepVan_Paper
            {
                file = SVU_Door_RR_StepVan_Paper,
            }
            model SVU_Door_RR_StepVan_Light_Spiked
            {
                file = SVU_Door_RR_StepVan_Light_Spiked,
            }
            model SVU_Door_RR_StepVan_Reinforced
            {
                file = SVU_Door_RR_StepVan_Reinforced,
            }
            model SVU_Door_RR_StepVan_Heavy_Spiked
            {
                file = SVU_Door_RR_StepVan_Heavy_Spiked,
            }
            model SVU_FL_Window_StepVan_Paper
            {
                file = SVU_FL_Window_StepVan_Paper,
            }
            model SVU_FL_Window_StepVan_Light_Spiked
            {
                file = SVU_FL_Window_StepVan_Light_Spiked,
            }
            model SVU_FL_Window_StepVan_Reinforced
            {
                file = SVU_FL_Window_StepVan_Reinforced,
            }
            model SVU_FL_Window_StepVan_Heavy_Spiked
            {
                file = SVU_FL_Window_StepVan_Heavy_Spiked,
            }
            model SVU_FR_Window_StepVan_Paper
            {
                file = SVU_FR_Window_StepVan_Paper,
            }
            model SVU_FR_Window_StepVan_Light_Spiked
            {
                file = SVU_FR_Window_StepVan_Light_Spiked,
            }
            model SVU_FR_Window_StepVan_Reinforced
            {
                file = SVU_FR_Window_StepVan_Reinforced,
            }
            model SVU_FR_Window_StepVan_Heavy_Spiked
            {
                file = SVU_FR_Window_StepVan_Heavy_Spiked,
            }
            model SVU_RL_Window_StepVan_Paper
            {
                file = SVU_RL_Window_StepVan_Paper,
            }
            model SVU_RL_Window_StepVan_Light_Spiked
            {
                file = SVU_RL_Window_StepVan_Light_Spiked,
            }
            model SVU_RL_Window_StepVan_Reinforced
            {
                file = SVU_RL_Window_StepVan_Reinforced,
            }
            model SVU_RL_Window_StepVan_Heavy_Spiked
            {
                file = SVU_RL_Window_StepVan_Heavy_Spiked,
            }
            model SVU_RR_Window_StepVan_Paper
            {
                file = SVU_RR_Window_StepVan_Paper,
            }
            model SVU_RR_Window_StepVan_Light_Spiked
            {
                file = SVU_RR_Window_StepVan_Light_Spiked,
            }
            model SVU_RR_Window_StepVan_Reinforced
            {
                file = SVU_RR_Window_StepVan_Reinforced,
            }
            model SVU_RR_Window_StepVan_Heavy_Spiked
            {
                file = SVU_RR_Window_StepVan_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "OffRoad",
        suffix = "OffRoad",
        template = "GSVU4_SVU3_BodyAnchor_OffRoad",
        lifecycleAnchor = "GSVU4_SVU3_OffRoad_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "OffRoad", "OffRoadFire", "OffRoadFossoil", "OffRoadHunter", "OffRoadLightsFire", "OffRoadLightsPolice", "OffRoadLightsRanger", "OffRoadLightsSheriff", "OffRoadLightsStatePolice", "OffRoadLights_Fire", "OffRoadLights_Police", "OffRoadLights_Ranger", "OffRoadLights_Sheriff", "OffRoadLights_StatePolice", "OffRoadMcCoy", "OffRoadMccoy", "OffRoadPolice", "OffRoadRanger", "OffRoadSheriff", "OffRoadStatePolice", "OffRoad_Fire", "OffRoad_Fossoil", "OffRoad_Hunter", "OffRoad_LightsFire", "OffRoad_LightsPolice", "OffRoad_LightsRanger", "OffRoad_LightsSheriff", "OffRoad_LightsStatePolice", "OffRoad_McCoy", "OffRoad_Mccoy", "OffRoad_Police", "OffRoad_Ranger", "OffRoad_Sheriff", "OffRoad_StatePolice" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_OffRoad_Paper",
                    Standard = "SVU_Hood_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Hood_OffRoad_Reinforced",
                    Apocalypse = "SVU_Hood_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_OffRoad_Paper",
                    Standard = "SVU_Trunk_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Trunk_OffRoad_Reinforced",
                    Apocalypse = "SVU_Trunk_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_OffRoad_Paper",
                    Standard = "SVU_F_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_F_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_F_Window_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_OffRoad_Paper",
                    Standard = "SVU_R_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_R_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_R_Window_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_OffRoad_Paper",
                    Standard = "SVU_Door_FL_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Door_FL_OffRoad_Reinforced",
                    Apocalypse = "SVU_Door_FL_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_OffRoad_Paper",
                    Standard = "SVU_Door_FR_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Door_FR_OffRoad_Reinforced",
                    Apocalypse = "SVU_Door_FR_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearLeft",
                sourceParts = { "DoorRearLeft", "DoorRearL" },
                models = {
                    Scrap = "SVU_Door_RL_OffRoad_Paper",
                    Standard = "SVU_Door_RL_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Door_RL_OffRoad_Reinforced",
                    Apocalypse = "SVU_Door_RL_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_OffRoad_Paper",
                    Standard = "SVU_Door_RR_OffRoad_Light_Spiked",
                    Reinforced = "SVU_Door_RR_OffRoad_Reinforced",
                    Apocalypse = "SVU_Door_RR_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_OffRoad_Paper",
                    Standard = "SVU_FL_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_FL_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_FL_Window_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_OffRoad_Paper",
                    Standard = "SVU_FR_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_FR_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_FR_Window_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearLeft",
                sourceParts = { "WindowRearLeft", "WindowRearL" },
                models = {
                    Scrap = "SVU_RL_Window_OffRoad_Paper",
                    Standard = "SVU_RL_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_RL_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_RL_Window_OffRoad_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_OffRoad_Paper",
                    Standard = "SVU_RR_Window_OffRoad_Light_Spiked",
                    Reinforced = "SVU_RR_Window_OffRoad_Reinforced",
                    Apocalypse = "SVU_RR_Window_OffRoad_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_OffRoad_Paper
            {
                file = SVU_Hood_OffRoad_Paper,
            }
            model SVU_Hood_OffRoad_Light_Spiked
            {
                file = SVU_Hood_OffRoad_Light_Spiked,
            }
            model SVU_Hood_OffRoad_Reinforced
            {
                file = SVU_Hood_OffRoad_Reinforced,
            }
            model SVU_Hood_OffRoad_Heavy_Spiked
            {
                file = SVU_Hood_OffRoad_Heavy_Spiked,
            }
            model SVU_Trunk_OffRoad_Paper
            {
                file = SVU_Trunk_OffRoad_Paper,
            }
            model SVU_Trunk_OffRoad_Light_Spiked
            {
                file = SVU_Trunk_OffRoad_Light_Spiked,
            }
            model SVU_Trunk_OffRoad_Reinforced
            {
                file = SVU_Trunk_OffRoad_Reinforced,
            }
            model SVU_Trunk_OffRoad_Heavy_Spiked
            {
                file = SVU_Trunk_OffRoad_Heavy_Spiked,
            }
            model SVU_F_Window_OffRoad_Paper
            {
                file = SVU_F_Window_OffRoad_Paper,
            }
            model SVU_F_Window_OffRoad_Light_Spiked
            {
                file = SVU_F_Window_OffRoad_Light_Spiked,
            }
            model SVU_F_Window_OffRoad_Reinforced
            {
                file = SVU_F_Window_OffRoad_Reinforced,
            }
            model SVU_F_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_F_Window_OffRoad_Heavy_Spiked,
            }
            model SVU_R_Window_OffRoad_Paper
            {
                file = SVU_R_Window_OffRoad_Paper,
            }
            model SVU_R_Window_OffRoad_Light_Spiked
            {
                file = SVU_R_Window_OffRoad_Light_Spiked,
            }
            model SVU_R_Window_OffRoad_Reinforced
            {
                file = SVU_R_Window_OffRoad_Reinforced,
            }
            model SVU_R_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_R_Window_OffRoad_Heavy_Spiked,
            }
            model SVU_Door_FL_OffRoad_Paper
            {
                file = SVU_Door_FL_OffRoad_Paper,
            }
            model SVU_Door_FL_OffRoad_Light_Spiked
            {
                file = SVU_Door_FL_OffRoad_Light_Spiked,
            }
            model SVU_Door_FL_OffRoad_Reinforced
            {
                file = SVU_Door_FL_OffRoad_Reinforced,
            }
            model SVU_Door_FL_OffRoad_Heavy_Spiked
            {
                file = SVU_Door_FL_OffRoad_Heavy_Spiked,
            }
            model SVU_Door_FR_OffRoad_Paper
            {
                file = SVU_Door_FR_OffRoad_Paper,
            }
            model SVU_Door_FR_OffRoad_Light_Spiked
            {
                file = SVU_Door_FR_OffRoad_Light_Spiked,
            }
            model SVU_Door_FR_OffRoad_Reinforced
            {
                file = SVU_Door_FR_OffRoad_Reinforced,
            }
            model SVU_Door_FR_OffRoad_Heavy_Spiked
            {
                file = SVU_Door_FR_OffRoad_Heavy_Spiked,
            }
            model SVU_Door_RL_OffRoad_Paper
            {
                file = SVU_Door_RL_OffRoad_Paper,
            }
            model SVU_Door_RL_OffRoad_Light_Spiked
            {
                file = SVU_Door_RL_OffRoad_Light_Spiked,
            }
            model SVU_Door_RL_OffRoad_Reinforced
            {
                file = SVU_Door_RL_OffRoad_Reinforced,
            }
            model SVU_Door_RL_OffRoad_Heavy_Spiked
            {
                file = SVU_Door_RL_OffRoad_Heavy_Spiked,
            }
            model SVU_Door_RR_OffRoad_Paper
            {
                file = SVU_Door_RR_OffRoad_Paper,
            }
            model SVU_Door_RR_OffRoad_Light_Spiked
            {
                file = SVU_Door_RR_OffRoad_Light_Spiked,
            }
            model SVU_Door_RR_OffRoad_Reinforced
            {
                file = SVU_Door_RR_OffRoad_Reinforced,
            }
            model SVU_Door_RR_OffRoad_Heavy_Spiked
            {
                file = SVU_Door_RR_OffRoad_Heavy_Spiked,
            }
            model SVU_FL_Window_OffRoad_Paper
            {
                file = SVU_FL_Window_OffRoad_Paper,
            }
            model SVU_FL_Window_OffRoad_Light_Spiked
            {
                file = SVU_FL_Window_OffRoad_Light_Spiked,
            }
            model SVU_FL_Window_OffRoad_Reinforced
            {
                file = SVU_FL_Window_OffRoad_Reinforced,
            }
            model SVU_FL_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_FL_Window_OffRoad_Heavy_Spiked,
            }
            model SVU_FR_Window_OffRoad_Paper
            {
                file = SVU_FR_Window_OffRoad_Paper,
            }
            model SVU_FR_Window_OffRoad_Light_Spiked
            {
                file = SVU_FR_Window_OffRoad_Light_Spiked,
            }
            model SVU_FR_Window_OffRoad_Reinforced
            {
                file = SVU_FR_Window_OffRoad_Reinforced,
            }
            model SVU_FR_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_FR_Window_OffRoad_Heavy_Spiked,
            }
            model SVU_RL_Window_OffRoad_Paper
            {
                file = SVU_RL_Window_OffRoad_Paper,
            }
            model SVU_RL_Window_OffRoad_Light_Spiked
            {
                file = SVU_RL_Window_OffRoad_Light_Spiked,
            }
            model SVU_RL_Window_OffRoad_Reinforced
            {
                file = SVU_RL_Window_OffRoad_Reinforced,
            }
            model SVU_RL_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_RL_Window_OffRoad_Heavy_Spiked,
            }
            model SVU_RR_Window_OffRoad_Paper
            {
                file = SVU_RR_Window_OffRoad_Paper,
            }
            model SVU_RR_Window_OffRoad_Light_Spiked
            {
                file = SVU_RR_Window_OffRoad_Light_Spiked,
            }
            model SVU_RR_Window_OffRoad_Reinforced
            {
                file = SVU_RR_Window_OffRoad_Reinforced,
            }
            model SVU_RR_Window_OffRoad_Heavy_Spiked
            {
                file = SVU_RR_Window_OffRoad_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "DashRoamer",
        suffix = "DashRoamer",
        template = "GSVU4_SVU3_BodyAnchor_DashRoamer",
        lifecycleAnchor = "GSVU4_SVU3_DashRoamer_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "DashRoamer", "DashRoamer01", "DashRoamer02", "DashRoamer2", "DashRoamerFire", "DashRoamerFossoil", "DashRoamerHunter", "DashRoamerLights", "DashRoamerLightsFire", "DashRoamerLightsPolice", "DashRoamerLightsRanger", "DashRoamerLightsSheriff", "DashRoamerLightsStatePolice", "DashRoamerLights_Fire", "DashRoamerLights_Police", "DashRoamerLights_Ranger", "DashRoamerLights_Sheriff", "DashRoamerLights_StatePolice", "DashRoamerMcCoy", "DashRoamerMccoy", "DashRoamerPolice", "DashRoamerRanger", "DashRoamerSheriff", "DashRoamerStatePolice", "DashRoamer_Fire", "DashRoamer_Fossoil", "DashRoamer_Hunter", "DashRoamer_Lights", "DashRoamer_LightsFire", "DashRoamer_LightsPolice", "DashRoamer_LightsRanger", "DashRoamer_LightsSheriff", "DashRoamer_LightsStatePolice", "DashRoamer_McCoy", "DashRoamer_Mccoy", "DashRoamer_Police", "DashRoamer_Ranger", "DashRoamer_Sheriff", "DashRoamer_StatePolice" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_DashRoamer_Light",
                    Standard = "SVU_Hood_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_Hood_DashRoamer_Reinforced",
                    Apocalypse = "SVU_Hood_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_DashRoamer_Light",
                    Standard = "SVU_Trunk_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_Trunk_DashRoamer_Reinforced",
                    Apocalypse = "SVU_Trunk_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_DashRoamer_Light",
                    Standard = "SVU_F_Window_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_F_Window_DashRoamer_Reinforced",
                    Apocalypse = "SVU_F_Window_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_DashRoamer_Light",
                    Standard = "SVU_R_Window_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_R_Window_DashRoamer_Reinforced",
                    Apocalypse = "SVU_R_Window_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_DashRoamer_Light",
                    Standard = "SVU_Door_FL_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_Door_FL_DashRoamer_Reinforced",
                    Apocalypse = "SVU_Door_FL_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_DashRoamer_Light",
                    Standard = "SVU_Door_FR_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_Door_FR_DashRoamer_Reinforced",
                    Apocalypse = "SVU_Door_FR_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "DoorRearRight",
                sourceParts = { "DoorRearRight", "DoorRearR" },
                models = {
                    Scrap = "SVU_Door_RR_DashRoamer_Light",
                    Standard = "SVU_Door_RR_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_Door_RR_DashRoamer_Reinforced",
                    Apocalypse = "SVU_Door_RR_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_DashRoamer_Light",
                    Standard = "SVU_FL_Window_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_FL_Window_DashRoamer_Reinforced",
                    Apocalypse = "SVU_FL_Window_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_DashRoamer_Light",
                    Standard = "SVU_FR_Window_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_FR_Window_DashRoamer_Reinforced",
                    Apocalypse = "SVU_FR_Window_DashRoamer_Heavy_Spiked"
                }
            },
            {
                group = "WindowRearRight",
                sourceParts = { "WindowRearRight", "WindowRearR" },
                models = {
                    Scrap = "SVU_RR_Window_DashRoamer_Light",
                    Standard = "SVU_RR_Window_DashRoamer_Light_Spiked",
                    Reinforced = "SVU_RR_Window_DashRoamer_Reinforced",
                    Apocalypse = "SVU_RR_Window_DashRoamer_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_DashRoamer_Light
            {
                file = SVU_Hood_DashRoamer_Light,
            }
            model SVU_Hood_DashRoamer_Light_Spiked
            {
                file = SVU_Hood_DashRoamer_Light_Spiked,
            }
            model SVU_Hood_DashRoamer_Reinforced
            {
                file = SVU_Hood_DashRoamer_Reinforced,
            }
            model SVU_Hood_DashRoamer_Heavy_Spiked
            {
                file = SVU_Hood_DashRoamer_Heavy_Spiked,
            }
            model SVU_Trunk_DashRoamer_Light
            {
                file = SVU_Trunk_DashRoamer_Light,
            }
            model SVU_Trunk_DashRoamer_Light_Spiked
            {
                file = SVU_Trunk_DashRoamer_Light_Spiked,
            }
            model SVU_Trunk_DashRoamer_Reinforced
            {
                file = SVU_Trunk_DashRoamer_Reinforced,
            }
            model SVU_Trunk_DashRoamer_Heavy_Spiked
            {
                file = SVU_Trunk_DashRoamer_Heavy_Spiked,
            }
            model SVU_F_Window_DashRoamer_Light
            {
                file = SVU_F_Window_DashRoamer_Light,
            }
            model SVU_F_Window_DashRoamer_Light_Spiked
            {
                file = SVU_F_Window_DashRoamer_Light_Spiked,
            }
            model SVU_F_Window_DashRoamer_Reinforced
            {
                file = SVU_F_Window_DashRoamer_Reinforced,
            }
            model SVU_F_Window_DashRoamer_Heavy_Spiked
            {
                file = SVU_F_Window_DashRoamer_Heavy_Spiked,
            }
            model SVU_R_Window_DashRoamer_Light
            {
                file = SVU_R_Window_DashRoamer_Light,
            }
            model SVU_R_Window_DashRoamer_Light_Spiked
            {
                file = SVU_R_Window_DashRoamer_Light_Spiked,
            }
            model SVU_R_Window_DashRoamer_Reinforced
            {
                file = SVU_R_Window_DashRoamer_Reinforced,
            }
            model SVU_R_Window_DashRoamer_Heavy_Spiked
            {
                file = SVU_R_Window_DashRoamer_Heavy_Spiked,
            }
            model SVU_Door_FL_DashRoamer_Light
            {
                file = SVU_Door_FL_DashRoamer_Light,
            }
            model SVU_Door_FL_DashRoamer_Light_Spiked
            {
                file = SVU_Door_FL_DashRoamer_Light_Spiked,
            }
            model SVU_Door_FL_DashRoamer_Reinforced
            {
                file = SVU_Door_FL_DashRoamer_Reinforced,
            }
            model SVU_Door_FL_DashRoamer_Heavy_Spiked
            {
                file = SVU_Door_FL_DashRoamer_Heavy_Spiked,
            }
            model SVU_Door_FR_DashRoamer_Light
            {
                file = SVU_Door_FR_DashRoamer_Light,
            }
            model SVU_Door_FR_DashRoamer_Light_Spiked
            {
                file = SVU_Door_FR_DashRoamer_Light_Spiked,
            }
            model SVU_Door_FR_DashRoamer_Reinforced
            {
                file = SVU_Door_FR_DashRoamer_Reinforced,
            }
            model SVU_Door_FR_DashRoamer_Heavy_Spiked
            {
                file = SVU_Door_FR_DashRoamer_Heavy_Spiked,
            }
            model SVU_Door_RR_DashRoamer_Light
            {
                file = SVU_Door_RR_DashRoamer_Light,
            }
            model SVU_Door_RR_DashRoamer_Light_Spiked
            {
                file = SVU_Door_RR_DashRoamer_Light_Spiked,
            }
            model SVU_Door_RR_DashRoamer_Reinforced
            {
                file = SVU_Door_RR_DashRoamer_Reinforced,
            }
            model SVU_Door_RR_DashRoamer_Heavy_Spiked
            {
                file = SVU_Door_RR_DashRoamer_Heavy_Spiked,
            }
            model SVU_FL_Window_DashRoamer_Light
            {
                file = SVU_FL_Window_DashRoamer_Light,
            }
            model SVU_FL_Window_DashRoamer_Light_Spiked
            {
                file = SVU_FL_Window_DashRoamer_Light_Spiked,
            }
            model SVU_FL_Window_DashRoamer_Reinforced
            {
                file = SVU_FL_Window_DashRoamer_Reinforced,
            }
            model SVU_FL_Window_DashRoamer_Heavy_Spiked
            {
                file = SVU_FL_Window_DashRoamer_Heavy_Spiked,
            }
            model SVU_FR_Window_DashRoamer_Light
            {
                file = SVU_FR_Window_DashRoamer_Light,
            }
            model SVU_FR_Window_DashRoamer_Light_Spiked
            {
                file = SVU_FR_Window_DashRoamer_Light_Spiked,
            }
            model SVU_FR_Window_DashRoamer_Reinforced
            {
                file = SVU_FR_Window_DashRoamer_Reinforced,
            }
            model SVU_FR_Window_DashRoamer_Heavy_Spiked
            {
                file = SVU_FR_Window_DashRoamer_Heavy_Spiked,
            }
            model SVU_RR_Window_DashRoamer_Light
            {
                file = SVU_RR_Window_DashRoamer_Light,
            }
            model SVU_RR_Window_DashRoamer_Light_Spiked
            {
                file = SVU_RR_Window_DashRoamer_Light_Spiked,
            }
            model SVU_RR_Window_DashRoamer_Reinforced
            {
                file = SVU_RR_Window_DashRoamer_Reinforced,
            }
            model SVU_RR_Window_DashRoamer_Heavy_Spiked
            {
                file = SVU_RR_Window_DashRoamer_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "GMCVan",
        suffix = "GMCVan",
        template = "GSVU4_SVU3_BodyAnchor_GMCVan",
        lifecycleAnchor = "GSVU4_SVU3_GMCVan_BodyAnchor",
        visualAnchor = "EngineDoor",
        vehicles = { "GMCVan", "GMCVanAmbulance", "GMCVanBuilder", "GMCVanFire", "GMCVanFossoil", "GMCVanLights", "GMCVanLightsFire", "GMCVanLightsPolice", "GMCVanLightsRanger", "GMCVanLightsSheriff", "GMCVanLightsStatePolice", "GMCVanLights_Fire", "GMCVanLights_Police", "GMCVanLights_Ranger", "GMCVanLights_Sheriff", "GMCVanLights_StatePolice", "GMCVanMcCoy", "GMCVanMccoy", "GMCVanMechanic", "GMCVanMetalworker", "GMCVanPolice", "GMCVanRadio", "GMCVanRanger", "GMCVanSeats", "GMCVanSheriff", "GMCVanStatePolice", "GMCVan_Ambulance", "GMCVan_Builder", "GMCVan_Fire", "GMCVan_Fossoil", "GMCVan_Lights", "GMCVan_LightsFire", "GMCVan_LightsPolice", "GMCVan_LightsRanger", "GMCVan_LightsSheriff", "GMCVan_LightsStatePolice", "GMCVan_McCoy", "GMCVan_Mccoy", "GMCVan_Mechanic", "GMCVan_Metalworker", "GMCVan_Police", "GMCVan_Ranger", "GMCVan_Sheriff", "GMCVan_StatePolice" },
        groups = {
            {
                group = "Hood",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "SVU_Hood_GMCVan_Light",
                    Standard = "SVU_Hood_GMCVan_Light_Spiked",
                    Reinforced = "SVU_Hood_GMCVan_Reinforced",
                    Apocalypse = "SVU_Hood_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "SVU_Trunk_GMCVan_Light",
                    Standard = "SVU_Trunk_GMCVan_Light_Spiked",
                    Reinforced = "SVU_Trunk_GMCVan_Reinforced",
                    Apocalypse = "SVU_Trunk_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "SVU_F_Window_GMCVan_Light",
                    Standard = "SVU_F_Window_GMCVan_Light_Spiked",
                    Reinforced = "SVU_F_Window_GMCVan_Reinforced",
                    Apocalypse = "SVU_F_Window_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "SVU_R_Window_GMCVan_Light",
                    Standard = "SVU_R_Window_GMCVan_Light_Spiked",
                    Reinforced = "SVU_R_Window_GMCVan_Reinforced",
                    Apocalypse = "SVU_R_Window_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "SVU_Door_FL_GMCVan_Light",
                    Standard = "SVU_Door_FL_GMCVan_Light_Spiked",
                    Reinforced = "SVU_Door_FL_GMCVan_Reinforced",
                    Apocalypse = "SVU_Door_FL_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "SVU_Door_FR_GMCVan_Light",
                    Standard = "SVU_Door_FR_GMCVan_Light_Spiked",
                    Reinforced = "SVU_Door_FR_GMCVan_Reinforced",
                    Apocalypse = "SVU_Door_FR_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "SVU_FL_Window_GMCVan_Light",
                    Standard = "SVU_FL_Window_GMCVan_Light_Spiked",
                    Reinforced = "SVU_FL_Window_GMCVan_Reinforced",
                    Apocalypse = "SVU_FL_Window_GMCVan_Heavy_Spiked"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "SVU_FR_Window_GMCVan_Light",
                    Standard = "SVU_FR_Window_GMCVan_Light_Spiked",
                    Reinforced = "SVU_FR_Window_GMCVan_Reinforced",
                    Apocalypse = "SVU_FR_Window_GMCVan_Heavy_Spiked"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model SVU_Hood_GMCVan_Light
            {
                file = SVU_Hood_GMCVan_Light,
            }
            model SVU_Hood_GMCVan_Light_Spiked
            {
                file = SVU_Hood_GMCVan_Light_Spiked,
            }
            model SVU_Hood_GMCVan_Reinforced
            {
                file = SVU_Hood_GMCVan_Reinforced,
            }
            model SVU_Hood_GMCVan_Heavy_Spiked
            {
                file = SVU_Hood_GMCVan_Heavy_Spiked,
            }
            model SVU_Trunk_GMCVan_Light
            {
                file = SVU_Trunk_GMCVan_Light,
            }
            model SVU_Trunk_GMCVan_Light_Spiked
            {
                file = SVU_Trunk_GMCVan_Light_Spiked,
            }
            model SVU_Trunk_GMCVan_Reinforced
            {
                file = SVU_Trunk_GMCVan_Reinforced,
            }
            model SVU_Trunk_GMCVan_Heavy_Spiked
            {
                file = SVU_Trunk_GMCVan_Heavy_Spiked,
            }
            model SVU_F_Window_GMCVan_Light
            {
                file = SVU_F_Window_GMCVan_Light,
            }
            model SVU_F_Window_GMCVan_Light_Spiked
            {
                file = SVU_F_Window_GMCVan_Light_Spiked,
            }
            model SVU_F_Window_GMCVan_Reinforced
            {
                file = SVU_F_Window_GMCVan_Reinforced,
            }
            model SVU_F_Window_GMCVan_Heavy_Spiked
            {
                file = SVU_F_Window_GMCVan_Heavy_Spiked,
            }
            model SVU_R_Window_GMCVan_Light
            {
                file = SVU_R_Window_GMCVan_Light,
            }
            model SVU_R_Window_GMCVan_Light_Spiked
            {
                file = SVU_R_Window_GMCVan_Light_Spiked,
            }
            model SVU_R_Window_GMCVan_Reinforced
            {
                file = SVU_R_Window_GMCVan_Reinforced,
            }
            model SVU_R_Window_GMCVan_Heavy_Spiked
            {
                file = SVU_R_Window_GMCVan_Heavy_Spiked,
            }
            model SVU_Door_FL_GMCVan_Light
            {
                file = SVU_Door_FL_GMCVan_Light,
            }
            model SVU_Door_FL_GMCVan_Light_Spiked
            {
                file = SVU_Door_FL_GMCVan_Light_Spiked,
            }
            model SVU_Door_FL_GMCVan_Reinforced
            {
                file = SVU_Door_FL_GMCVan_Reinforced,
            }
            model SVU_Door_FL_GMCVan_Heavy_Spiked
            {
                file = SVU_Door_FL_GMCVan_Heavy_Spiked,
            }
            model SVU_Door_FR_GMCVan_Light
            {
                file = SVU_Door_FR_GMCVan_Light,
            }
            model SVU_Door_FR_GMCVan_Light_Spiked
            {
                file = SVU_Door_FR_GMCVan_Light_Spiked,
            }
            model SVU_Door_FR_GMCVan_Reinforced
            {
                file = SVU_Door_FR_GMCVan_Reinforced,
            }
            model SVU_Door_FR_GMCVan_Heavy_Spiked
            {
                file = SVU_Door_FR_GMCVan_Heavy_Spiked,
            }
            model SVU_FL_Window_GMCVan_Light
            {
                file = SVU_FL_Window_GMCVan_Light,
            }
            model SVU_FL_Window_GMCVan_Light_Spiked
            {
                file = SVU_FL_Window_GMCVan_Light_Spiked,
            }
            model SVU_FL_Window_GMCVan_Reinforced
            {
                file = SVU_FL_Window_GMCVan_Reinforced,
            }
            model SVU_FL_Window_GMCVan_Heavy_Spiked
            {
                file = SVU_FL_Window_GMCVan_Heavy_Spiked,
            }
            model SVU_FR_Window_GMCVan_Light
            {
                file = SVU_FR_Window_GMCVan_Light,
            }
            model SVU_FR_Window_GMCVan_Light_Spiked
            {
                file = SVU_FR_Window_GMCVan_Light_Spiked,
            }
            model SVU_FR_Window_GMCVan_Reinforced
            {
                file = SVU_FR_Window_GMCVan_Reinforced,
            }
            model SVU_FR_Window_GMCVan_Heavy_Spiked
            {
                file = SVU_FR_Window_GMCVan_Heavy_Spiked,
            }
        }]==]
    },
    {
        id = "RaceCar",
        suffix = "RaceCar",
        template = "GSVU4_SVU3_BodyAnchor_RaceCar",
        lifecycleAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
        visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
        vehicles = { "RaceCar", "RaceCar12", "RaceCar34", "RaceCar58" },
        groups = {
            {
                group = "Hood",
                visualAnchor = "GSVU4_SVU3_RaceCar_BodyAnchor",
                sourceParts = { "EngineDoor", "Hood" },
                models = {
                    Scrap = "GSVU4_RaceCar_Hood_Scrap",
                    Standard = "GSVU4_RaceCar_Hood_Standard",
                    Reinforced = "GSVU4_RaceCar_Hood_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_Hood_Apocalypse"
                },
                hideModels = {
                    "GSVU4_RaceCar_Hood_Scrap",
                    "GSVU4_RaceCar_Hood_Standard",
                    "GSVU4_RaceCar_Hood_Reinforced",
                    "GSVU4_RaceCar_Hood_Apocalypse",
                    "GSVU4_RaceCar_Hood_Scrap_Scoop",
                    "GSVU4_RaceCar_Hood_Standard_Scoop",
                    "GSVU4_RaceCar_Hood_Reinforced_Scoop",
                    "GSVU4_RaceCar_Hood_Apocalypse_Scoop"
                }
            },
            {
                group = "Trunk",
                sourceParts = { "TrunkDoor", "Trunk", "TruckBed", "TruckBedOpen" },
                models = {
                    Scrap = "GSVU4_RaceCar_Trunk_Scrap",
                    Standard = "GSVU4_RaceCar_Trunk_Standard",
                    Reinforced = "GSVU4_RaceCar_Trunk_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_Trunk_Apocalypse"
                }
            },
            {
                group = "Windshield",
                sourceParts = { "Windshield", "WindshieldFront" },
                models = {
                    Scrap = "GSVU4_RaceCar_Windshield_Scrap",
                    Standard = "GSVU4_RaceCar_Windshield_Standard",
                    Reinforced = "GSVU4_RaceCar_Windshield_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_Windshield_Apocalypse"
                }
            },
            {
                group = "RearWindshield",
                sourceParts = { "WindshieldRear", "RearWindshield", "WindowRear" },
                models = {
                    Scrap = "GSVU4_RaceCar_WindshieldRear_Scrap",
                    Standard = "GSVU4_RaceCar_WindshieldRear_Standard",
                    Reinforced = "GSVU4_RaceCar_WindshieldRear_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_WindshieldRear_Apocalypse"
                }
            },
            {
                group = "DoorFrontLeft",
                sourceParts = { "DoorFrontLeft", "DoorFrontL" },
                models = {
                    Scrap = "GSVU4_RaceCar_DoorFrontLeft_Scrap",
                    Standard = "GSVU4_RaceCar_DoorFrontLeft_Standard",
                    Reinforced = "GSVU4_RaceCar_DoorFrontLeft_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_DoorFrontLeft_Apocalypse"
                }
            },
            {
                group = "DoorFrontRight",
                sourceParts = { "DoorFrontRight", "DoorFrontR" },
                models = {
                    Scrap = "GSVU4_RaceCar_DoorFrontRight_Scrap",
                    Standard = "GSVU4_RaceCar_DoorFrontRight_Standard",
                    Reinforced = "GSVU4_RaceCar_DoorFrontRight_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_DoorFrontRight_Apocalypse"
                }
            },
            {
                group = "WindowFrontLeft",
                sourceParts = { "WindowFrontLeft", "WindowFrontL" },
                models = {
                    Scrap = "GSVU4_RaceCar_WindowFrontLeft_Scrap",
                    Standard = "GSVU4_RaceCar_WindowFrontLeft_Standard",
                    Reinforced = "GSVU4_RaceCar_WindowFrontLeft_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_WindowFrontLeft_Apocalypse"
                }
            },
            {
                group = "WindowFrontRight",
                sourceParts = { "WindowFrontRight", "WindowFrontR" },
                models = {
                    Scrap = "GSVU4_RaceCar_WindowFrontRight_Scrap",
                    Standard = "GSVU4_RaceCar_WindowFrontRight_Standard",
                    Reinforced = "GSVU4_RaceCar_WindowFrontRight_Reinforced",
                    Apocalypse = "GSVU4_RaceCar_WindowFrontRight_Apocalypse"
                }
            }
        },
        engineDoorParam = [==[        part EngineDoor
        {
            setAllModelsVisible = false,
            model GSVU4_RaceCar_Hood_Scrap { file = GSVU4_RaceCar_Hood_Scrap, }
            model GSVU4_RaceCar_Hood_Standard { file = GSVU4_RaceCar_Hood_Standard, }
            model GSVU4_RaceCar_Hood_Light { file = GSVU4_RaceCar_Hood_Light, }
            model GSVU4_RaceCar_Hood_Reinforced { file = GSVU4_RaceCar_Hood_Reinforced, }
            model GSVU4_RaceCar_Hood_Apocalypse { file = GSVU4_RaceCar_Hood_Apocalypse, }

            model GSVU4_RaceCar_Trunk_Scrap { file = GSVU4_RaceCar_Trunk_Scrap, }
            model GSVU4_RaceCar_Trunk_Standard { file = GSVU4_RaceCar_Trunk_Standard, }
            model GSVU4_RaceCar_Trunk_Light { file = GSVU4_RaceCar_Trunk_Light, }
            model GSVU4_RaceCar_Trunk_Reinforced { file = GSVU4_RaceCar_Trunk_Reinforced, }
            model GSVU4_RaceCar_Trunk_Apocalypse { file = GSVU4_RaceCar_Trunk_Apocalypse, }

            model GSVU4_RaceCar_DoorFrontLeft_Scrap { file = GSVU4_RaceCar_DoorFrontLeft_Scrap, }
            model GSVU4_RaceCar_DoorFrontLeft_Standard { file = GSVU4_RaceCar_DoorFrontLeft_Standard, }
            model GSVU4_RaceCar_DoorFrontLeft_Light { file = GSVU4_RaceCar_DoorFrontLeft_Light, }
            model GSVU4_RaceCar_DoorFrontLeft_Reinforced { file = GSVU4_RaceCar_DoorFrontLeft_Reinforced, }
            model GSVU4_RaceCar_DoorFrontLeft_Apocalypse { file = GSVU4_RaceCar_DoorFrontLeft_Apocalypse, }

            model GSVU4_RaceCar_DoorFrontRight_Scrap { file = GSVU4_RaceCar_DoorFrontRight_Scrap, }
            model GSVU4_RaceCar_DoorFrontRight_Standard { file = GSVU4_RaceCar_DoorFrontRight_Standard, }
            model GSVU4_RaceCar_DoorFrontRight_Light { file = GSVU4_RaceCar_DoorFrontRight_Light, }
            model GSVU4_RaceCar_DoorFrontRight_Reinforced { file = GSVU4_RaceCar_DoorFrontRight_Reinforced, }
            model GSVU4_RaceCar_DoorFrontRight_Apocalypse { file = GSVU4_RaceCar_DoorFrontRight_Apocalypse, }

            model GSVU4_RaceCar_Windshield_Scrap { file = GSVU4_RaceCar_Windshield_Scrap, }
            model GSVU4_RaceCar_Windshield_Standard { file = GSVU4_RaceCar_Windshield_Standard, }
            model GSVU4_RaceCar_Windshield_Light { file = GSVU4_RaceCar_Windshield_Light, }
            model GSVU4_RaceCar_Windshield_Reinforced { file = GSVU4_RaceCar_Windshield_Reinforced, }
            model GSVU4_RaceCar_Windshield_Apocalypse { file = GSVU4_RaceCar_Windshield_Apocalypse, }

            model GSVU4_RaceCar_WindshieldRear_Scrap { file = GSVU4_RaceCar_WindshieldRear_Scrap, }
            model GSVU4_RaceCar_WindshieldRear_Standard { file = GSVU4_RaceCar_WindshieldRear_Standard, }
            model GSVU4_RaceCar_WindshieldRear_Light { file = GSVU4_RaceCar_WindshieldRear_Light, }
            model GSVU4_RaceCar_WindshieldRear_Reinforced { file = GSVU4_RaceCar_WindshieldRear_Reinforced, }
            model GSVU4_RaceCar_WindshieldRear_Apocalypse { file = GSVU4_RaceCar_WindshieldRear_Apocalypse, }

            model GSVU4_RaceCar_WindowFrontLeft_Scrap { file = GSVU4_RaceCar_WindowFrontLeft_Scrap, }
            model GSVU4_RaceCar_WindowFrontLeft_Standard { file = GSVU4_RaceCar_WindowFrontLeft_Standard, }
            model GSVU4_RaceCar_WindowFrontLeft_Light { file = GSVU4_RaceCar_WindowFrontLeft_Light, }
            model GSVU4_RaceCar_WindowFrontLeft_Reinforced { file = GSVU4_RaceCar_WindowFrontLeft_Reinforced, }
            model GSVU4_RaceCar_WindowFrontLeft_Apocalypse { file = GSVU4_RaceCar_WindowFrontLeft_Apocalypse, }

            model GSVU4_RaceCar_WindowFrontRight_Scrap { file = GSVU4_RaceCar_WindowFrontRight_Scrap, }
            model GSVU4_RaceCar_WindowFrontRight_Standard { file = GSVU4_RaceCar_WindowFrontRight_Standard, }
            model GSVU4_RaceCar_WindowFrontRight_Light { file = GSVU4_RaceCar_WindowFrontRight_Light, }
            model GSVU4_RaceCar_WindowFrontRight_Reinforced { file = GSVU4_RaceCar_WindowFrontRight_Reinforced, }
            model GSVU4_RaceCar_WindowFrontRight_Apocalypse { file = GSVU4_RaceCar_WindowFrontRight_Apocalypse, }
        }]==]
    }
}

-- B42.19 PickUpVan alignment split
-- The original PickUp family covers both PickUpTruck and PickUpVan aliases. The
-- FBX contains alternate .001 pickup-van meshes for the front/rear armour and
-- windscreens, so split PickUpVan aliases into their own family and map only
-- those vehicles to the adjusted models.
local function cloneModelMap(map)
    local out = {}
    for k, v in pairs(map or {}) do out[k] = v end
    return out
end

local function cloneGroup(group)
    local out = {}
    for k, v in pairs(group or {}) do
        if k == "models" then
            out.models = cloneModelMap(v)
        elseif k == "sourceParts" then
            out.sourceParts = {}
            for i, value in ipairs(v) do out.sourceParts[i] = value end
        else
            out[k] = v
        end
    end
    return out
end

local function cloneFamily(family)
    local out = {}
    for k, v in pairs(family or {}) do
        if k ~= "groups" and k ~= "vehicles" then out[k] = v end
    end
    out.groups = {}
    for i, group in ipairs(family.groups or {}) do out.groups[i] = cloneGroup(group) end
    out.vehicles = {}
    return out
end

local function pickUpVanStripBaseLocal(name)
    if not name then return nil end
    return tostring(name):gsub("^Base%.", "")
end

local function isPickUpVanAlias(name)
    local short = pickUpVanStripBaseLocal(name or "")
    return tostring(short):find("^PickUpVan") ~= nil
end

local function applyPickUpVanModelOverrides(family)
    for _, group in ipairs(family.groups or {}) do
        if group.group == "Hood" then
            group.models = {
                Scrap = "GSVU4_PickUpVan_Hood_Scrap",
                Standard = "GSVU4_PickUpVan_Hood_Standard",
                Reinforced = "GSVU4_PickUpVan_Hood_Reinforced",
                Apocalypse = "GSVU4_PickUpVan_Hood_Apocalypse"
            }
        elseif group.group == "Trunk" then
            group.models = {
                Scrap = "GSVU4_PickUpVan_Trunk_Scrap",
                Standard = "GSVU4_PickUpVan_Trunk_Standard",
                Reinforced = "GSVU4_PickUpVan_Trunk_Reinforced",
                Apocalypse = "GSVU4_PickUpVan_Trunk_Apocalypse"
            }
        elseif group.group == "Windshield" then
            group.models = {
                Scrap = "GSVU4_PickUpVan_Windshield_Scrap",
                Standard = "GSVU4_PickUpVan_Windshield_Standard",
                Reinforced = "GSVU4_PickUpVan_Windshield_Reinforced",
                Apocalypse = "GSVU4_PickUpVan_Windshield_Apocalypse"
            }
        elseif group.group == "RearWindshield" then
            group.models = {
                Scrap = "GSVU4_PickUpVan_WindshieldRear_Scrap",
                Standard = "GSVU4_PickUpVan_WindshieldRear_Standard",
                Reinforced = "GSVU4_PickUpVan_WindshieldRear_Reinforced",
                Apocalypse = "GSVU4_PickUpVan_WindshieldRear_Apocalypse"
            }
        end
    end
end

local function splitPickUpVanFamily()
    if GSVU4VV._pickUpVanAlignmentSplitDone then return end
    GSVU4VV._pickUpVanAlignmentSplitDone = true

    for index, family in ipairs(GSVU4VV.Families or {}) do
        if family.id == "PickUp" then
            local truckAliases, vanAliases = {}, {}
            for _, vehicleName in ipairs(family.vehicles or {}) do
                if isPickUpVanAlias(vehicleName) then
                    vanAliases[#vanAliases + 1] = vehicleName
                else
                    truckAliases[#truckAliases + 1] = vehicleName
                end
            end

            if #vanAliases > 0 then
                family.vehicles = truckAliases
                local vanFamily = cloneFamily(family)
                vanFamily.id = "PickUpVan"
                vanFamily.suffix = "PickUpVan"
                vanFamily.vehicles = vanAliases
                applyPickUpVanModelOverrides(vanFamily)
                table.insert(GSVU4VV.Families, index + 1, vanFamily)

            end
            return
        end
    end
end

splitPickUpVanFamily()

GSVU4VV.FamilyByVehicle = {}
GSVU4VV.FamilyByLifecycleAnchor = {}
GSVU4VV.InjectedTemplates = GSVU4VV.InjectedTemplates or {}

local function stripBase(name)
    if not name then return nil end
    return tostring(name):gsub("^Base%.", "")
end

local function normaliseVehicleName(name)
    if not name then return nil end
    name = tostring(name)
    if string.find(name, ".", 1, true) then return name end
    return "Base." .. name
end

local function getVehicleScriptName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return tostring(value) end
    end
    if vehicle.getScript then
        local okScript, script = pcall(function() return vehicle:getScript() end)
        if okScript and script then
            if script.getFullName then
                local ok, value = pcall(function() return script:getFullName() end)
                if ok and value then return tostring(value) end
            end
            if script.getName then
                local ok, value = pcall(function() return script:getName() end)
                if ok and value then return tostring(value) end
            end
        end
    end
    return nil
end

local function buildIndexes()
    GSVU4VV.FamilyByVehicle = {}
    GSVU4VV.FamilyByLifecycleAnchor = {}
    for _, family in ipairs(GSVU4VV.Families or {}) do
        if family.lifecycleAnchor then GSVU4VV.FamilyByLifecycleAnchor[family.lifecycleAnchor] = family end
        family.PartToGroup = {}
        family.GroupByName = {}
        for _, group in ipairs(family.groups or {}) do
            if group.group then family.GroupByName[group.group] = group end
            for _, partId in ipairs(group.sourceParts or {}) do
                family.PartToGroup[partId] = group
            end
        end
        for _, vehicleName in ipairs(family.vehicles or {}) do
            GSVU4VV.FamilyByVehicle[vehicleName] = family
            GSVU4VV.FamilyByVehicle[normaliseVehicleName(vehicleName)] = family
            GSVU4VV.FamilyByVehicle[stripBase(vehicleName)] = family
        end
    end
end
buildIndexes()

local function addAliasToFamily(family, vehicleName)
    if not family or not vehicleName or vehicleName == "" then return false end
    local short = stripBase(vehicleName)
    if not short or short == "" then return false end
    local lower = string.lower(short)
    -- Do not let the vanilla visual pack claim PZK or obvious mod-prefixed scripts.
    if string.sub(lower, 1, 3) == "pzk" then return false end
    for _, existing in ipairs(family.vehicles or {}) do
        if stripBase(existing) == short then return false end
    end
    family.vehicles = family.vehicles or {}
    family.vehicles[#family.vehicles + 1] = short
    return true
end

local function getFamilyById(id)
    for _, family in ipairs(GSVU4VV.Families or {}) do
        if family.id == id or family.suffix == id then return family end
    end
    return nil
end

function GSVU4VV.AddLoadedVanillaVariantAliases()
    local added = 0
    local explicit = {
        StepVan_Citr8 = "StepVan",
        StepVan_MobileLibrary = "StepVan",
        StepVan_SouthEasternHosp = "StepVan",
    }
    for alias, familyId in pairs(explicit) do
        local family = getFamilyById(familyId)
        if addAliasToFamily(family, alias) then added = added + 1 end
    end

    local rules = {
        { pattern = "^StepVan", familyId = "StepVan" },
        { pattern = "^Van", familyId = "Van" },
        { pattern = "^PickUpVan", familyId = "PickUpVan" },
        { pattern = "^PickUpTruck", familyId = "PickUp" },
        { pattern = "^SUV", familyId = "SUV" },
        { pattern = "^OffRoad", familyId = "OffRoad" },
        { pattern = "^RaceCar", familyId = "RaceCar" },
        { pattern = "^SportsCar", familyId = "SportsCar" },
        { pattern = "^SmallCar2", familyId = "SmallCar02" },
        { pattern = "^SmallCar02", familyId = "SmallCar02" },
        { pattern = "^SmallCar", familyId = "SmallCar" },
        { pattern = "^CarModern2", familyId = "ModernCar2" },
        { pattern = "^CarModern", familyId = "ModernCar" },
        { pattern = "^ModernCar2", familyId = "ModernCar2" },
        { pattern = "^ModernCar", familyId = "ModernCar" },
        { pattern = "^Luxury", familyId = "LuxuryCar" },
        { pattern = "^CarLuxury", familyId = "LuxuryCar" },
        { pattern = "^StationWagon", familyId = "CarWagon" },
        { pattern = "^Wagon", familyId = "CarWagon" },
        { pattern = "^CarStationWagon", familyId = "CarWagon" },
        { pattern = "^Dash", familyId = "DashRoamer" },
        { pattern = "^GMC", familyId = "GMCVan" },
        { pattern = "^CarLightsKST", familyId = "DashRoamer" },
        { pattern = "^CarLights", familyId = "CarNormal" },
        { pattern = "^CarNormal", familyId = "CarNormal" },
        { pattern = "^Taxi", familyId = "CarNormal" },
        { pattern = "^CarTaxi", familyId = "CarNormal" },
    }

    local sm = nil
    if getScriptManager then
        local ok, value = pcall(getScriptManager)
        if ok then sm = value end
    end
    if not sm and ScriptManager and ScriptManager.instance then sm = ScriptManager.instance end

    local vehicles = nil
    if sm and sm.getAllVehicleScripts then
        local ok, value = pcall(function() return sm:getAllVehicleScripts() end)
        if ok then vehicles = value end
    end
    if not vehicles and sm and sm.getVehicles then
        local ok, value = pcall(function() return sm:getVehicles() end)
        if ok then vehicles = value end
    end

    local function consider(name)
        local short = stripBase(name)
        if not short or short == "" then return end
        if GSVU4VV.FamilyByVehicle and (GSVU4VV.FamilyByVehicle[short] or GSVU4VV.FamilyByVehicle["Base." .. short]) then return end
        for _, rule in ipairs(rules) do
            if string.find(short, rule.pattern) then
                local family = getFamilyById(rule.familyId)
                if addAliasToFamily(family, short) then added = added + 1 end
                return
            end
        end
    end

    if vehicles then
        if vehicles.size and vehicles.get then
            local okSize, count = pcall(function() return vehicles:size() end)
            if okSize and count then
                for i = 0, count - 1 do
                    local okGet, vs = pcall(function() return vehicles:get(i) end)
                    if okGet and vs then
                        local name = nil
                        if vs.getFullName then local ok, value = pcall(function() return vs:getFullName() end); if ok then name = value end end
                        if not name and vs.getName then local ok, value = pcall(function() return vs:getName() end); if ok then name = value end end
                        consider(name)
                    end
                end
            end
        else
            for _, vs in pairs(vehicles) do
                local name = nil
                if vs and vs.getFullName then local ok, value = pcall(function() return vs:getFullName() end); if ok then name = value end end
                if not name and vs and vs.getName then local ok, value = pcall(function() return vs:getName() end); if ok then name = value end end
                consider(name)
            end
        end
    end

    if added > 0 then
        buildIndexes()

    end
    return added
end

local function getFamilyForVehicle(vehicle)
    local scriptName = getVehicleScriptName(vehicle)
    if not scriptName then return nil end
    return GSVU4VV.FamilyByVehicle[scriptName]
        or GSVU4VV.FamilyByVehicle[normaliseVehicleName(scriptName)]
        or GSVU4VV.FamilyByVehicle[stripBase(scriptName)]
end

local function getFamilyForLifecyclePart(part)
    if not part or not part.getId then return nil end
    return GSVU4VV.FamilyByLifecycleAnchor[tostring(part:getId())]
end

local function getVisualPart(vehicle, family, group)
    local visualPartId = group and group.visualAnchor
        or family and (family.visualAnchor or family.lifecycleAnchor)
    if not vehicle or not visualPartId or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(visualPartId) end)
    if ok then return part end
    return nil
end

local function getLifecyclePart(vehicle, family)
    if not vehicle or not family or not family.lifecycleAnchor or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(family.lifecycleAnchor) end)
    if ok then return part end
    return nil
end

local function iterModels(value, callback)
    if not value or not callback then return end
    if type(value) == "table" then
        for _, modelName in ipairs(value) do
            if modelName then callback(modelName) end
        end
    else
        callback(value)
    end
end

local function getGroupGrade(vehicle, group)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local armor = md and md.gArmor
    if type(armor) ~= "table" then return nil, nil end
    for _, partId in ipairs(group.sourceParts or {}) do
        local entry = armor[partId]
        if type(entry) == "table" and entry.grade then return tostring(entry.grade), partId end
        if type(entry) == "string" then return tostring(entry), partId end
    end
    return nil, nil
end

local function safeSetModelVisible(part, modelName, visible)
    if not part or not modelName then return false end
    local ok, err = pcall(function() part:setModelVisible(tostring(modelName), visible == true) end)
    if not ok then

        return false
    end
    return true
end

local function hideGroupModels(visualPart, group)
    local seen = {}
    local candidates = group.hideModels or group.models or {}

    for _, spec in pairs(candidates) do
        iterModels(spec, function(modelName)
            if modelName and not seen[modelName] then
                seen[modelName] = true
                safeSetModelVisible(visualPart, modelName, false)
            end
        end)
    end
end

local function transmitVisualState(vehicle, visualPart, lifecyclePart)
    -- Visual-only state is reconstructed locally from authoritative modData.
    -- Sending model packets here can rebuild the model list and erase damage or armour.
    return
end

local function sameModelList(a, b)
    if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
    for i = 1, #a do
        if tostring(a[i]) ~= tostring(b[i]) then return false end
    end
    return true
end

function GSVU4VV.VisualPart.ApplyGroup(vehicle, family, group)
    if not vehicle or not family or not group then return false end
    local visualPart = getVisualPart(vehicle, family, group)
    if not visualPart then return false end
    local lifecyclePart = getLifecyclePart(vehicle, family)

    local grade, sourcePart = getGroupGrade(vehicle, group)
    local modelSpec = grade and group.models and (group.models[grade] or group.models[tostring(grade)]) or nil

    local statePart = lifecyclePart or visualPart
    local md = statePart:getModData()
    md.gsvu4Visual = md.gsvu4Visual or {}
    local stateKey = group.group or sourcePart or "unknown"
    local current = md.gsvu4Visual[stateKey]

    local desired = {}
    if modelSpec then
        iterModels(modelSpec, function(modelName)
            desired[#desired + 1] = tostring(modelName)
        end)
    end

    -- Routine refresh of an unchanged group only reasserts the desired model.
    -- It never hides first, eliminating the visible off/on pulse in MP.
    if grade and current and tostring(current.grade) == tostring(grade)
            and sameModelList(current.models, desired) then
        local shown = 0
        for _, modelName in ipairs(desired) do
            if safeSetModelVisible(visualPart, modelName, true) then shown = shown + 1 end
        end
        return shown > 0
    end

    if not grade or not modelSpec then
        -- Important: always hide this group on first authoritative apply even if
        -- we do not yet have cached visual state. Some vehicle parts can finish
        -- binding with default-visible models before any later interaction tick.
        hideGroupModels(visualPart, group)
        if current ~= nil then
            md.gsvu4Visual[stateKey] = nil
            transmitVisualState(vehicle, visualPart, lifecyclePart)
        else
            md.gsvu4Visual[stateKey] = nil
        end
        return true
    end

    -- Actual install, uninstall or grade change.
    hideGroupModels(visualPart, group)
    local shown = {}
    for _, modelName in ipairs(desired) do
        if safeSetModelVisible(visualPart, modelName, true) then
            shown[#shown + 1] = modelName
        end
    end

    md.gsvu4Visual[stateKey] = {
        sourcePart = sourcePart,
        grade = grade,
        models = shown,
        visualPart = group.visualAnchor or family.visualAnchor or family.lifecycleAnchor,
    }

    transmitVisualState(vehicle, visualPart, lifecyclePart)
    return #shown > 0
end

function GSVU4VV.VisualPart.ApplySourcePart(vehicle, sourcePartId)
    local family = getFamilyForVehicle(vehicle)
    local group = family and family.PartToGroup and family.PartToGroup[sourcePartId]
    if not group then return false end
    return GSVU4VV.VisualPart.ApplyGroup(vehicle, family, group)
end

function GSVU4VV.VisualPart.ApplyVehicle(vehicle)
    local family = getFamilyForVehicle(vehicle)
    if not family then return false end
    local okAny = false
    for _, group in ipairs(family.groups or {}) do
        if GSVU4VV.VisualPart.ApplyGroup(vehicle, family, group) then okAny = true end
    end
    return okAny
end

function GSVU4VV.VisualPart.Create(vehicle, part)
    if vehicle and part and getFamilyForLifecyclePart(part) then GSVU4VV.VisualPart.ApplyVehicle(vehicle) end
end

function GSVU4VV.VisualPart.Init(vehicle, part)
    if vehicle and part and getFamilyForLifecyclePart(part) then GSVU4VV.VisualPart.ApplyVehicle(vehicle) end
end

function GSVU4VV.CoreApplyVisual(vehicle, grade, modelName, visualPartId, entry)
    local family = getFamilyForVehicle(vehicle)
    if entry and entry.group and family and family.GroupByName then
        local group = family.GroupByName[entry.group]
        if group then return GSVU4VV.VisualPart.ApplyGroup(vehicle, family, group) end
    end
    return GSVU4VV.VisualPart.ApplyVehicle(vehicle)
end

local function makeProfileForFamily(family)
    local profile = {
        id = "GSVU4VV.SVU3Hybrid." .. tostring(family.id),
        vehicleFamily = family.id,
        svu3Hybrid = true,
        templates = { family.template },
        notes = "SVU3-style lifecycle anchor with fitted visual anchor. No proximity scanner.",
        parts = {},
    }
    for _, group in ipairs(family.groups or {}) do
        for _, partId in ipairs(group.sourceParts or {}) do
            profile.parts[partId] = {
                visualPart = group.visualAnchor or family.visualAnchor or family.lifecycleAnchor,
                applyVisual = GSVU4VV.CoreApplyVisual,
                models = group.models,
                group = group.group,
            }
        end
    end
    return profile
end

function GSVU4VV.RegisterProfiles()
    if not GSVU4Core or not GSVU4Core.RegisterVisualProfile then return false end
    local count = 0
    for _, family in ipairs(GSVU4VV.Families or {}) do
        local profile = makeProfileForFamily(family)
        for _, vehicleName in ipairs(family.vehicles or {}) do
            GSVU4Core.RegisterVisualProfile("Base." .. tostring(vehicleName), profile)
            count = count + 1
        end
    end


    return true
end

local function doVehicleParam(vehicleName, param)
    if not ScriptManager or not ScriptManager.instance then return false, "ScriptManager not ready" end
    local short = stripBase(vehicleName)
    local full = "Base." .. tostring(short)
    local vehicleScript = ScriptManager.instance:getVehicle(full)
    if not vehicleScript then return false, "missing " .. full end
    local ok, err = pcall(function() vehicleScript:Load(short, "{" .. param .. "}") end)
    if not ok then return false, tostring(err) end
    return true
end

function GSVU4VV.InjectTemplates()
    for _, family in ipairs(GSVU4VV.Families or {}) do
        for _, vehicleName in ipairs(family.vehicles or {}) do
            local params = { "template! = " .. tostring(family.template) .. "," }
            if family.engineDoorParam then params[#params + 1] = family.engineDoorParam end

            for idx, param in ipairs(params) do
                local key = tostring(vehicleName) .. ":" .. tostring(family.template) .. ":" .. tostring(idx)
                if not GSVU4VV.InjectedTemplates[key] then
                    local ok = doVehicleParam(vehicleName, param)
                    if ok then GSVU4VV.InjectedTemplates[key] = true end
                end
            end
        end
    end
end

local function iterVehicles(collection, callback)
    if not collection or not callback then return false end
    if type(collection) == "table" then
        for _, vehicle in pairs(collection) do if callback(vehicle) then return true end end
        return false
    end
    if collection.size and collection.get then
        local okSize, count = pcall(function() return collection:size() end)
        if okSize and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return collection:get(i) end)
                if okGet and callback(vehicle) then return true end
            end
        end
    end
    return false
end

local function vehicleMatchesArgs(vehicle, args)
    if not vehicle or not args then return false end
    if args.vehicleId ~= nil and vehicle.getId then
        local ok, id = pcall(function() return vehicle:getId() end)
        if ok and id ~= nil and tostring(id) == tostring(args.vehicleId) then return true end
    end
    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, id = pcall(function() return vehicle:getOnlineID() end)
        if ok and id ~= nil and tostring(id) == tostring(args.vehicleOnlineId) then return true end
    end
    if args.vehicleX ~= nil and args.vehicleY ~= nil and vehicle.getX and vehicle.getY then
        local okX, x = pcall(function() return vehicle:getX() end)
        local okY, y = pcall(function() return vehicle:getY() end)
        if okX and okY and x and y
        and math.abs((tonumber(x) or 0) - (tonumber(args.vehicleX) or 999999)) < 1.0
        and math.abs((tonumber(y) or 0) - (tonumber(args.vehicleY) or 999999)) < 1.0 then return true end
    end
    return false
end

local function getVehicleFromArgs(args)
    if not args or not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end
    local okVehicles, vehicles = pcall(function() return cell:getVehicles() end)
    if not okVehicles or not vehicles then return nil end
    local found = nil
    iterVehicles(vehicles, function(vehicle)
        if vehicleMatchesArgs(vehicle, args) then found = vehicle; return true end
        return false
    end)
    return found
end

GSVU4VV.PendingApply = GSVU4VV.PendingApply or {}
local GSVU4VVApplyTickRegistered = false

local function visualVehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, id = pcall(function() return vehicle:getOnlineID() end)
        if ok and id ~= nil then return "online:" .. tostring(id) end
    end
    if vehicle.getId then
        local ok, id = pcall(function() return vehicle:getId() end)
        if ok and id ~= nil then return "id:" .. tostring(id) end
    end
    if vehicle.getX and vehicle.getY and vehicle.getZ then
        local ok, x, y, z = pcall(function()
            return vehicle:getX(), vehicle:getY(), vehicle:getZ()
        end)
        if ok then
            return "pos:" .. tostring(math.floor(x or 0))
                .. ":" .. tostring(math.floor(y or 0))
                .. ":" .. tostring(math.floor(z or 0))
        end
    end
    return tostring(vehicle)
end

local function pendingApplyHasEntries()
    for _, _ in pairs(GSVU4VV.PendingApply or {}) do
        return true
    end
    return false
end

local function runVVApply(vehicle, partId)
    if not vehicle then return false end

    local ok = false
    if partId and GSVU4VV.VisualPart and GSVU4VV.VisualPart.ApplySourcePart then
        local okCall, result = pcall(function()
            return GSVU4VV.VisualPart.ApplySourcePart(vehicle, partId)
        end)
        ok = (okCall and result == true) or ok
    end

    if (not ok) and GSVU4VV.VisualPart and GSVU4VV.VisualPart.ApplyVehicle then
        local okCall, result = pcall(function()
            return GSVU4VV.VisualPart.ApplyVehicle(vehicle)
        end)
        ok = (okCall and result == true) or ok
    end

    return ok
end

local function unregisterVVApplyTick()
    if not GSVU4VVApplyTickRegistered then return end
    if Events and Events.OnTick and Events.OnTick.Remove then
        pcall(function() Events.OnTick.Remove(GSVU4VV_ProcessApplyQueue) end)
    end
    GSVU4VVApplyTickRegistered = false
end

local function registerVVApplyTick()
    if GSVU4VVApplyTickRegistered then return end
    if Events and Events.OnTick then
        Events.OnTick.Add(GSVU4VV_ProcessApplyQueue)
        GSVU4VVApplyTickRegistered = true
    end
end

function GSVU4VV.QueueApply(vehicle, partId)
    if not vehicle then return false end

    local key = visualVehicleKey(vehicle)
    if not key then return false end

    GSVU4VV.PendingApply[key] = {
        vehicle = vehicle,
        partId = partId,
        ticks = 0,
        attempts = 0,
    }

    -- Try immediately, then retry briefly over the next few ticks in case the
    -- visual anchor/model state is not ready on the exact timed-action frame.
    runVVApply(vehicle, partId)
    registerVVApplyTick()
    return true
end

function GSVU4VV_ProcessApplyQueue()
    if not pendingApplyHasEntries() then
        unregisterVVApplyTick()
        return
    end

    for key, entry in pairs(GSVU4VV.PendingApply or {}) do
        entry.ticks = (entry.ticks or 0) + 1

        if entry.ticks >= 5 then
            entry.ticks = 0
            entry.attempts = (entry.attempts or 0) + 1

            runVVApply(entry.vehicle, entry.partId)

            if entry.attempts >= 10 then
                GSVU4VV.PendingApply[key] = nil
            end
        end
    end

    if not pendingApplyHasEntries() then
        unregisterVVApplyTick()
    end
end

local function isMPClient()
    return isClient and isClient()
end

local function wrapTimedActionPerform(className)
    local cls = _G and _G[className] or nil
    if not cls or cls.GSVU4VV_PostInstallApplyWrapped then return false end
    if type(cls.perform) ~= "function" then return false end

    local oldPerform = cls.perform
    cls.perform = function(self, ...)
        local vehicle = self and self.vehicle or nil
        local partId = self and self.partId or nil

        local result = oldPerform(self, ...)

        -- In MP, wait for the authoritative ArmorActionApplied server command.
        -- In SP, the local timed action has already changed gArmor by this point,
        -- so queue the VV visual apply immediately.
        if vehicle and not isMPClient() then
            GSVU4VV.QueueApply(vehicle, partId)
        end

        return result
    end

    cls.GSVU4VV_PostInstallApplyWrapped = true
    return true
end

function GSVU4VV.InstallTimedActionApplyWrappers()
    wrapTimedActionPerform("ISWeldVehicleArmor")
    wrapTimedActionPerform("ISRepairVehicleArmor")
    wrapTimedActionPerform("ISUninstallVehicleArmor")
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" or command ~= "ArmorActionApplied" then return end
    local vehicle = getVehicleFromArgs(args)
    if vehicle then
        if args and args.partId then
            GSVU4VV.QueueApply(vehicle, args.partId)
        else
            GSVU4VV.QueueApply(vehicle, nil)
        end
    end
end

local function onEnterVehicle(character)
    if not character or not character.getVehicle then return end
    local vehicle = character:getVehicle()
    if vehicle then GSVU4VV.VisualPart.ApplyVehicle(vehicle) end
end

local function onGameStart()
    if GSVU4VV.AddLoadedVanillaVariantAliases then GSVU4VV.AddLoadedVanillaVariantAliases() end
    GSVU4VV.InjectTemplates()
    GSVU4VV.RegisterProfiles()
    GSVU4VV.InstallTimedActionApplyWrappers()
end

if GSVU4VV.AddLoadedVanillaVariantAliases then GSVU4VV.AddLoadedVanillaVariantAliases() end
GSVU4VV.InjectTemplates()
GSVU4VV.RegisterProfiles()
GSVU4VV.InstallTimedActionApplyWrappers()

if Events and Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
if Events and Events.OnLoad then Events.OnLoad.Add(onGameStart) end
if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
