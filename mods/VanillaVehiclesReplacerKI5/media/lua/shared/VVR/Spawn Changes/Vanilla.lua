require "VVR/Utils"

if not VehicleZoneDistribution then return end

VVR.Utils.NilSpawnZones("Base.SmallCar")
VVR.Utils.NilSpawnZones("Base.SmallCar02")
VVR.Utils.NilSpawnZones("Base.CarTaxi2")
VVR.Utils.NilSpawnZones("Base.CarStationWagon2")
VVR.Utils.NilSpawnZones("Base.ModernCar02")
VVR.Utils.NilSpawnZones("Base.StepVan")
VVR.Utils.NilSpawnZones("Base.PickUpTruck_Camo")
VVR.Utils.NilSpawnZones("Base.PickUpVan_Camo")

VehicleZoneDistribution.parkingstall.vehicles["Base.CarNormal"] = {index = -1, spawnChance = 38}
VehicleZoneDistribution.parkingstall.vehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 12}
VehicleZoneDistribution.parkingstall.vehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 12}
VehicleZoneDistribution.parkingstall.vehicles["Base.CarTaxi"] = {index = -1, spawnChance = 10}
VehicleZoneDistribution.parkingstall.vehicles["Base.PickUpVan"] = {index = -1, spawnChance = 6}
VehicleZoneDistribution.parkingstall.vehicles["Base.ModernCar"] = {index = -1, spawnChance = 6}
VehicleZoneDistribution.parkingstall.vehicles["Base.CarLuxury"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.parkingstall.vehicles["Base.Van"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.parkingstall.vehicles["Base.VanSeats"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.parkingstall.vehicles["Base.SportsCar"] = {index = -1, spawnChance = 3}

VehicleZoneDistribution.trailerpark.vehicles["Base.CarNormal"] = {index = -1, spawnChance = 50}
VehicleZoneDistribution.trailerpark.vehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 25}
VehicleZoneDistribution.trailerpark.vehicles["Base.Van"] = {index = -1, spawnChance = 13}
VehicleZoneDistribution.trailerpark.vehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 7}
VehicleZoneDistribution.trailerpark.vehicles["Base.PickUpVan"] = {index = -1, spawnChance = 5}

VehicleZoneDistribution.bad.vehicles["Base.CarNormal"] = {index = -1, spawnChance = 48}
VehicleZoneDistribution.bad.vehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 24}
VehicleZoneDistribution.bad.vehicles["Base.Van"] = {index = -1, spawnChance = 13}
VehicleZoneDistribution.bad.vehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 7}
VehicleZoneDistribution.bad.vehicles["Base.PickUpVan"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.bad.vehicles["Base.VanSeats"] = {index = -1, spawnChance = 3}

VehicleZoneDistribution.medium.vehicles["Base.CarNormal"] = {index = -1, spawnChance = 36}
VehicleZoneDistribution.medium.vehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 14}
VehicleZoneDistribution.medium.vehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 11}
VehicleZoneDistribution.medium.vehicles["Base.ModernCar"] = {index = -1, spawnChance = 11}
VehicleZoneDistribution.medium.vehicles["Base.PickUpVan"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.medium.vehicles["Base.SUV"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.medium.vehicles["Base.OffRoad"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.medium.vehicles["Base.VanSeats"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.medium.vehicles["Base.CarLuxury"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.medium.vehicles["Base.Van"] = {index = -1, spawnChance = 3}
VehicleZoneDistribution.medium.vehicles["Base.SportsCar"] = {index = -1, spawnChance = 2}

VehicleZoneDistribution.good.vehicles["Base.ModernCar"] = {index = -1, spawnChance = 30}
VehicleZoneDistribution.good.vehicles["Base.SUV"] = {index = -1, spawnChance = 23}
VehicleZoneDistribution.good.vehicles["Base.OffRoad"] = {index = -1, spawnChance = 22}
VehicleZoneDistribution.good.vehicles["Base.CarLuxury"] = {index = -1, spawnChance = 13}
VehicleZoneDistribution.good.vehicles["Base.SportsCar"] = {index = -1, spawnChance = 12}

VehicleZoneDistribution.sport.vehicles["Base.SportsCar"] = {index = -1, spawnChance = 65}
VehicleZoneDistribution.sport.vehicles["Base.CarLuxury"] = {index = -1, spawnChance = 35}

VehicleZoneDistribution.junkyard.vehicles["Base.CarNormal"] = {index = -1, spawnChance = 38}
VehicleZoneDistribution.junkyard.vehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 12}
VehicleZoneDistribution.junkyard.vehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 12}
VehicleZoneDistribution.junkyard.vehicles["Base.CarTaxi"] = {index = -1, spawnChance = 10}
VehicleZoneDistribution.junkyard.vehicles["Base.PickUpVan"] = {index = -1, spawnChance = 6}
VehicleZoneDistribution.junkyard.vehicles["Base.ModernCar"] = {index = -1, spawnChance = 6}
VehicleZoneDistribution.junkyard.vehicles["Base.CarLuxury"] = {index = -1, spawnChance = 5}
VehicleZoneDistribution.junkyard.vehicles["Base.Van"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.junkyard.vehicles["Base.VanSeats"] = {index = -1, spawnChance = 4}
VehicleZoneDistribution.junkyard.vehicles["Base.SportsCar"] = {index = -1, spawnChance = 3}

local trafficjamVehicles = {}

trafficjamVehicles["Base.CarNormal"] = {index = -1, spawnChance = 30}
trafficjamVehicles["Base.PickUpTruck"] = {index = -1, spawnChance = 11}
trafficjamVehicles["Base.CarStationWagon"] = {index = -1, spawnChance = 11}
trafficjamVehicles["Base.CarTaxi"] = {index = -1, spawnChance = 10}
trafficjamVehicles["Base.PickUpVan"] = {index = -1, spawnChance = 6}
trafficjamVehicles["Base.ModernCar"] = {index = -1, spawnChance = 6}
trafficjamVehicles["Base.SUV"] = {index = -1, spawnChance = 5}
trafficjamVehicles["Base.OffRoad"] = {index = -1, spawnChance = 5}
trafficjamVehicles["Base.CarLuxury"] = {index = -1, spawnChance = 5}
trafficjamVehicles["Base.Van"] = {index = -1, spawnChance = 4}
trafficjamVehicles["Base.VanSeats"] = {index = -1, spawnChance = 4}
trafficjamVehicles["Base.SportsCar"] = {index = -1, spawnChance = 3}

VehicleZoneDistribution.trafficjamw.vehicles = trafficjamVehicles
VehicleZoneDistribution.trafficjame.vehicles = trafficjamVehicles
VehicleZoneDistribution.trafficjamn.vehicles = trafficjamVehicles
VehicleZoneDistribution.trafficjams.vehicles = trafficjamVehicles