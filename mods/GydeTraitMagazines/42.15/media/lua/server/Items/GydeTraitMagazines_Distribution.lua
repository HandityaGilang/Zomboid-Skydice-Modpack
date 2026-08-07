require 'Items/ProceduralDistributions'
require "Items/ItemPicker"

GydeTraitMags = GydeTraitMags or {};

local sBvars = SandboxVars.GydeTraitMags;

-- Assign SandboxVars SpawnRate to a specific multiplier
local spawnRateMultipliers = {
    [1] = 0.1,
    [2] = 0.5,
    [3] = 1,
    [4] = 2,
    [5] = 3,
}

-- Gets the spawn rate multiplier set in SandboxVars
local function getSpawnRateMultiplier()
    return spawnRateMultipliers[sBvars.SpawnRate] or 1
end

-- Function to insert item into distribution tables with adjusted multiplier
local function insertItem(distributionTable, item, baseChance)
	local spawnMultiplier = getSpawnRateMultiplier()
	local newSpawnRate = baseChance * spawnMultiplier -- Calculates new spawn rate based on multiplier

	-- Insert into loot table
	table.insert(distributionTable.items, item)
	table.insert(distributionTable.items, newSpawnRate)
end

Events.OnInitGlobalModData.Add(function()

	-- Speed Demon
	if sBvars.SpawnSpeedDemon then
		local magazineType = "Base.SpeedDemonMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["MechanicShelfBooks"], magazineType, 2)
	end

	-- Nutritionist
	if sBvars.SpawnNutritionist then
		local magazineType = "Base.NutritionistMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["ClassroomDesk"], magazineType, 0.01)
		insertItem(ProceduralDistributions["list"]["GigamartSchool"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["CafeShelfBooks"], magazineType, 3)
	end

	-- Organzied
	if sBvars.SpawnOrganized then
		local magazineType = "Base.OrganizedMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)
	end

	-- Dextrous
	if sBvars.SpawnDextrous then
		local magazineType = "Base.DextrousMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["BedroomSidetable"], magazineType, 1.5) -- ( ͡° ͜ʖ ͡°)
	end

	-- Graceful
	if sBvars.SpawnGraceful then
		local magazineType = "Base.GracefulMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["GymLockers"], magazineType, 1)
	end

	-- Outdoorsman
	if sBvars.SpawnOutdoorsman then
		local magazineType = "Base.OutdoorsmanMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["CampingStoreBooks"], magazineType, 2)
		insertItem(ProceduralDistributions["list"]["CrateCamping"], magazineType, 1)
	end

	-- Handy
	if sBvars.SpawnHandy then
		local magazineType = "Base.HandyMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["ToolStoreBooks"], magazineType, 2)
	end

	-- Fast Reader
	if sBvars.SpawnFastReader then
		local magazineType = "Base.FastReaderMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["GigamartSchool"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["SchoolLockers"], magazineType, 0.01)
		insertItem(ProceduralDistributions["list"]["ClassroomDesk"], magazineType, 0.01)
	end

	-- Fast Learner
	if sBvars.SpawnFastLearner then
		local magazineType = "Base.FastLearnerMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["GigamartSchool"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["SchoolLockers"], magazineType, 0.01)
		insertItem(ProceduralDistributions["list"]["ClassroomDesk"], magazineType, 0.01)
	end

	-- Axe Man (Occupation Trait)
	if sBvars.SpawnAxeMan then
		local magazineType = "Base.AxeManMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.025)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 0.5)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 0.5)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["GarageCarpentry"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["ToolStoreBooks"], magazineType, 1)
	end

	-- Burglar (Occupation Trait)
	if sBvars.SpawnBurglar then
		local magazineType = "Base.BurglarMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.025)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.025)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 0.5)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 0.5)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["PoliceEvidence"], magazineType, 4)
	end

	-- Inconspicuous
	if sBvars.SpawnInconspicuous then
		local magazineType = "Base.InconspicuousMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["HuntingLockers"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["PoliceEvidence"], magazineType, 4)
		insertItem(ProceduralDistributions["list"]["PoliceLockers"], magazineType, 1)
	end

	-- Keen Hearing
	if sBvars.SpawnKeenHearing then
		local magazineType = "Base.KeenHearingMag"

		-- Generic Spawn Locations --
		insertItem(ProceduralDistributions["list"]["ShelfGeneric"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomShelf"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTable"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableClassy"], magazineType, 0.1)
		insertItem(ProceduralDistributions["list"]["LivingRoomSideTableRedneck"], magazineType, 0.1)
    	insertItem(ProceduralDistributions["list"]["MagazineRackMixed"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["CrateMagazines"], magazineType, 1)
    	insertItem(ProceduralDistributions["list"]["PostOfficeMagazines"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["LibraryMagazines"], magazineType, 1)
		insertItem(ProceduralDistributions["list"]["UniversityLibraryMagazines"], magazineType, 1)

		-- Unique Locations --
		insertItem(ProceduralDistributions["list"]["HuntingLockers"], magazineType, 0.5)
		insertItem(ProceduralDistributions["list"]["MedicalOfficeBooks"], magazineType, 4)
		insertItem(ProceduralDistributions["list"]["CampingStoreBooks"], magazineType, 2)
	end

	ItemPickerJava.Parse()
end)