require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"
require "TCZombieLoot"

local function addToVehicleDist(distName, itemName, weight)
    if weight <= 0 then return end
    if not VehicleDistributions then return end
    local dist = VehicleDistributions[distName]
    if not dist or not dist.items then return end
    table.insert(dist.items, itemName)
    table.insert(dist.items, weight)
end

-- Walkman in glove boxes only
addToVehicleDist("GloveBox", "Tsarcraft.TCWalkman", 0.15)
addToVehicleDist("LuxuryGloveBox", "Tsarcraft.TCWalkman", 0.15)
addToVehicleDist("SportsGloveBox", "Tsarcraft.TCWalkman", 0.15)

-- =========================
-- Walkman (base)
-- =========================
table.insert(ProceduralDistributions["list"]["BreakRoomShelves"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["BreakRoomShelves"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, 0.5)

table.insert(ProceduralDistributions["list"]["MusicStoreOthers"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MusicStoreOthers"].items, 2)

table.insert(ProceduralDistributions["list"]["MusicStoreCDs"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MusicStoreCDs"].items, 2)

table.insert(ProceduralDistributions["list"]["MusicStoreSpeaker"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MusicStoreSpeaker"].items, 2)

table.insert(ProceduralDistributions["list"]["ClassroomDesk"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["ClassroomDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["CrateElectronics"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["CrateElectronics"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ElectronicStoreMisc"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["ElectronicStoreMisc"].items, 2)

table.insert(ProceduralDistributions["list"]["ElectronicStoreMusic"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["ElectronicStoreMusic"].items, 2)

table.insert(ProceduralDistributions["list"]["DaycareShelves"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["DaycareShelves"].junk.items, 0.5)

table.insert(ProceduralDistributions["list"]["DeskGeneric"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["DeskGeneric"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["DresserGeneric"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["DresserGeneric"].junk.items, 2)

table.insert(ProceduralDistributions["list"]["GigamartHouseElectronics"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["GigamartHouseElectronics"].items, 2)

table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, 0.1)

table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, 1)

table.insert(ProceduralDistributions["list"]["GarageTools"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["GarageTools"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageMechanics"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["GarageMechanics"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageMetalwork"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["GarageMetalwork"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LivingRoomShelfNoTapes"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["LivingRoomShelfNoTapes"].items, 0.5)

table.insert(ProceduralDistributions["list"]["Locker"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["Locker"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LockerClassy"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["LockerClassy"].items, 0.5)

table.insert(ProceduralDistributions["list"]["SchoolLockers"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["SchoolLockers"].items, 1)

table.insert(ProceduralDistributions["list"]["LibraryCounter"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["LibraryCounter"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["OfficeDesk"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["OfficeDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["OfficeDeskHome"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["OfficeDeskHome"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["PoliceDesk"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["PoliceDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["PrisonCellRandom"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["PrisonCellRandom"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["WardrobeChild"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["WardrobeChild"].junk.items, 2)

table.insert(ProceduralDistributions["list"]["WardrobeRedneck"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["WardrobeRedneck"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].items, 5)

table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].junk.items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].junk.items, 15)

table.insert(ProceduralDistributions["list"]["CrateCompactDiscs"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["CrateCompactDiscs"].items, 0.5)

table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, 0.5)

table.insert(ProceduralDistributions["list"]["MusicStoreCases"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["MusicStoreCases"].items, 2)

table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, "Tsarcraft.TCWalkman")
table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, 0.5)

-- =========================
-- Boombox (base)
-- =========================
table.insert(ProceduralDistributions["list"]["BedroomDresser"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["BedroomDresser"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["BreakRoomShelves"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["BreakRoomShelves"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, 0.5)

table.insert(ProceduralDistributions["list"]["MusicStoreOthers"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MusicStoreOthers"].items, 2)

table.insert(ProceduralDistributions["list"]["MusicStoreCDs"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MusicStoreCDs"].items, 2)

table.insert(ProceduralDistributions["list"]["MusicStoreSpeaker"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MusicStoreSpeaker"].items, 2)

table.insert(ProceduralDistributions["list"]["ClassroomDesk"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["ClassroomDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["CrateElectronics"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["CrateElectronics"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ElectronicStoreMisc"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["ElectronicStoreMisc"].items, 2)

table.insert(ProceduralDistributions["list"]["ElectronicStoreMusic"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["ElectronicStoreMusic"].items, 2)

table.insert(ProceduralDistributions["list"]["DaycareShelves"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["DaycareShelves"].junk.items, 0.5)

table.insert(ProceduralDistributions["list"]["DeskGeneric"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["DeskGeneric"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["DresserGeneric"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["DresserGeneric"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["GigamartHouseElectronics"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["GigamartHouseElectronics"].items, 2)

table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, 0.1)

table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["KitchenRandom"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, 1)

table.insert(ProceduralDistributions["list"]["GarageTools"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["GarageTools"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageMechanics"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["GarageMechanics"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["GarageCarpentry"].items, 0.5)

table.insert(ProceduralDistributions["list"]["GarageMetalwork"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["GarageMetalwork"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LivingRoomShelfNoTapes"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["LivingRoomShelfNoTapes"].items, 0.5)

table.insert(ProceduralDistributions["list"]["Locker"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["Locker"].items, 0.5)

table.insert(ProceduralDistributions["list"]["LockerClassy"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["LockerClassy"].items, 0.5)

table.insert(ProceduralDistributions["list"]["SchoolLockers"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["SchoolLockers"].items, 1)

table.insert(ProceduralDistributions["list"]["LibraryCounter"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["LibraryCounter"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["OfficeDesk"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["OfficeDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["OfficeDeskHome"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["OfficeDeskHome"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["PoliceDesk"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["PoliceDesk"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["PrisonCellRandom"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["PrisonCellRandom"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["WardrobeChild"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["WardrobeChild"].junk.items, 1)

table.insert(ProceduralDistributions["list"]["WardrobeRedneck"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["WardrobeRedneck"].junk.items, 0.5)

table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].items, 5)

table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].junk.items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MechanicShelfElectric"].junk.items, 15)

table.insert(ProceduralDistributions["list"]["CrateCompactDiscs"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["CrateCompactDiscs"].items, 0.5)

table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, 0.5)

table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["ShelfGeneric"].items, 0.5)

table.insert(ProceduralDistributions["list"]["MusicStoreCases"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["MusicStoreCases"].items, 2)

table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, "Tsarcraft.TCBoombox")
table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, 0.5)

-- =========================
-- Vinyl player (base)
-- =========================
local function addVinylPlayers(dist, weight, useJunk)
	if not dist then return end
	local ebonyWeight = weight * 0.75 -- Ebony is 25% rarer than default.
	if useJunk then
		if not dist.junk or not dist.junk.items then return end
		table.insert(dist.junk.items, "Tsarcraft.TCVinylplayer")
		table.insert(dist.junk.items, weight)
		table.insert(dist.junk.items, "Tsarcraft.TCVinylplayerBlack")
		table.insert(dist.junk.items, ebonyWeight)
	else
		if not dist.items then return end
		table.insert(dist.items, "Tsarcraft.TCVinylplayer")
		table.insert(dist.items, weight)
		table.insert(dist.items, "Tsarcraft.TCVinylplayerBlack")
		table.insert(dist.items, ebonyWeight)
	end
end

addVinylPlayers(ProceduralDistributions["list"]["StoreCounterCleaning"], 0.5, false)
addVinylPlayers(ProceduralDistributions["list"]["ElectronicStoreMusic"], 2, false)
addVinylPlayers(ProceduralDistributions["list"]["ElectronicStoreMisc"], 5, false)
addVinylPlayers(ProceduralDistributions["list"]["MusicStoreCases"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["ShelfGeneric"], 1, false)
addVinylPlayers(ProceduralDistributions["list"]["CrateCompactDiscs"], 2, false)
addVinylPlayers(ProceduralDistributions["list"]["DeskGeneric"], 0.5, false)
addVinylPlayers(ProceduralDistributions["list"]["MechanicShelfElectric"], 15, true)
addVinylPlayers(ProceduralDistributions["list"]["MechanicShelfElectric"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["GarageTools"], 0.5, false)
addVinylPlayers(ProceduralDistributions["list"]["GarageMechanics"], 1, false)
addVinylPlayers(ProceduralDistributions["list"]["GarageCarpentry"], 1, false)
addVinylPlayers(ProceduralDistributions["list"]["GarageMetalwork"], 1, false)
addVinylPlayers(ProceduralDistributions["list"]["MusicStoreOthers"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["MusicStoreCDs"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["MusicStoreSpeaker"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["CrateElectronics"], 3, false)
addVinylPlayers(ProceduralDistributions["list"]["GigamartHouseElectronics"], 2, false)
addVinylPlayers(ProceduralDistributions["list"]["LivingRoomShelf"], 0.75, false)
addVinylPlayers(ProceduralDistributions["list"]["LivingRoomShelfNoTapes"], 0.75, false)
addVinylPlayers(ProceduralDistributions["list"]["Locker"], 0.5, false)
addVinylPlayers(ProceduralDistributions["list"]["OfficeDesk"], 0.5, true)
addVinylPlayers(ProceduralDistributions["list"]["OfficeDeskHome"], 0.5, true)
addVinylPlayers(ProceduralDistributions["list"]["PoliceDesk"], 0.5, true)
addVinylPlayers(ProceduralDistributions["list"]["PrisonCellRandom"], 0.5, true)

-- Vinyl in kitchen shelves at half rate of walkman/boombox
addVinylPlayers(ProceduralDistributions["list"]["KitchenBook"], 0.05, false)
addVinylPlayers(ProceduralDistributions["list"]["KitchenRandom"], 0.25, false)


