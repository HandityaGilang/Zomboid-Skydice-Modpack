local logger = require("dgmc_cleaning_wipes_logging")

local procedural = 
{
	ArmyBunkerLockers = 2,
	BathroomCabinet = 5,
	BathroomCounter = 5,
	BathroomShelf = 5,
	BedroomSidetableChild = 5,
	BreakRoomShelves = 1,
	CampingStoreGear = 1,
	ChangeroomCounters = 20,
	ClassroomShelves = 5,
	ClosetShelfGeneric = 1,
	CrateCamping = 1,
	CrateHumanitarian = 20,
	CrateRandomJunk = 1,
	CrateToiletPaper = 5,
	DaycareCounter = 40,
	DerelictHouseSquatter = 0.1,
	DresserGeneric = 1,
	DrugLabSupplies = 1,
	FactoryLockers = 0.5,
	FireDeptLockers = 0.5,
	FossoilCounterCleaning = 1,
	Gas2GoCounterCleaning = 1,
	GasStoreCounterCleaning = 1,
	GasStoreToiletries = 20,
	GigamartCosmetics = 5,
	GigamartPaper = 10,
	GigamartToiletries = 20,
	GolfLockers = 0.5,
	GymLockers = 0.5,
	Hiker = 1,
	HospitalLockers = 0.5,
	HospitalRoomCleaning = 1,
	HospitalRoomCounter = 1,
	HospitalRoomShelves = 2,
	HospitalRoomWardrobe = 0.5,
	JackiesDesk = 4,
	JanitorCleaning = 5,
	JanitorMisc = 1,
	JockeyLockers = 1,
	JudgeMattHassCounter = 1,
	LaboratoryLockers = 1,
	LiquorStoreBags = 1,
	LivingRoomWardrobe = 1,
	Locker = 0.5,
	LockerArmyBedroom = 2,
	MechanicOutfit = 0.5,
	MechanicShelfMisc = 5,
	MedicalOfficeCounter = 2,
	MedicalOfficeDesk = 2,
	MorgueTools = 4,
	NurseTools = 2,
	OfficeDeskHome = 2,
	OfficeDeskSecretary = 8,
	OtherGeneric = 1,
	PharmacyCosmetics = 8,
	PlankStashMagazine = 10,
	PoliceLockers = 1,
	PrisonCellRandom = 1,
	PrisonCellRandomClassy = 4,
	PrisonGuardLockers = 1,
	RangerLockers = 1,
	SafehouseMedical = 20,
	SafehouseMedical_Mid = 10,
	SafehouseMedical_Late = 5,
	SalonCounter = 20,
	SchoolLockers = 0.1,
	SeasonalWorkerLockers = 1,
	SecurityLockers = 1,
	StoreCounterCleaning = 2,
	StripClubCosmetic = 10,
	StripClubDressers = 5,
	UniversitySideTable = 5,
	WaitingRoomDesk = 4,
	WardrobeChild = 10,
}

local bags =
{
	BanditItems = 1,
	FirstAidKit_Camping = 10,
	FirstAidKit_Camping_New = 10,
	HandbagsAndPurses = 4,
	HikingBag = 4,
	MakeupCase_Professional = 20,
	SurvivorItems = 5,
	Tourist = 8,
}

local clutter =
{
	ClosetJunk = 0.1,
	DeskJunk = 1,
	GloveBoxItems = 4,
	GloveBoxWorkItems = 2,
}

---@param item string
---@param chance number
---@param distro table
local function injectItem(item, chance, distro)
	if distro ~= nil then
		table.insert(distro, item)
		table.insert(distro, chance)
	end
end

---@param targets { [string]: number }
---@param distro table
local function injectWipes(targets, distro)
	for k, v in pairs(targets) do
		local distroList = distro[k]

		if distroList ~= nil then
			injectItem("DGMC.CleaningWipes", v, distroList.items)
		else
			logger.error("initialization", "couldn't find distroList %s", k)
		end
	end
end

local function injectAll()
	injectWipes(procedural, ProceduralDistributions.list)
	injectWipes(bags, BagsAndContainers)
	injectWipes(clutter, ClutterTables)
	if ProceduralDistributions.list.DaycareCounter ~= nil then
		injectItem("DGMC.CleaningWipesBox", 5, ProceduralDistributions.list.DaycareCounter.items)
	end
	logger.info("initialization", "added wipes to loot tables")
end

Events.OnPreDistributionMerge.Add(injectAll)