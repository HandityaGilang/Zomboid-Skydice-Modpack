------------------------------------------------------------------------
--  Mod: Video Game Consoles Addon - More NES Games
--  B42.20 Compatible
--  Original Distribution function by Unconid
--  Original Replace Dummies function by albion
--  Adapted for this mod by Big Al
------------------------------------------------------------------------  

-- Configuration for distribution chances and dummy/item mapping
local distributionChances = {
    BedroomDresserChild = 2,	
	BedroomDresserRedneck = 0.5,
    BedroomSidetableChild = 3,
    BreakRoomShelves = 1,
    ClassroomDesk = 1,
	ClassroomMisc = 0.5,
    ClassroomShelves = 1,
    ClassroomSecondaryDesk = 1,
	ClassroomSecondaryShelves = 0.5,
    CrateCompactDiscs = 1,
    CrateElectronics = 2,
    CrateRandomJunk = 0.2,
	CrateToys = 4,
	CrateVHSTapes = 3,
	DaycareCounter = 1,
	DaycareShelves = 1,
	DaycareDesk = 0.5,
    ElectronicStoreMisc = 3,
    Gifts = 1,
	GiftStoreToys = 5,
    GigamartHouseElectronics = 2,
	GigamartToys = 4,
	Hobbies = 1,
    LivingRoomShelf = 1,
	LivingRoomShelfClassy = 1.5,
	LivingRoomShelfRedneck = 0.5,
	LivingRoomSideTable = 1,
	LivingRoomSideTableClassy = 1.5,
	LivingRoomSideTableRedneck = 0.5,
    LivingRoomWardrobe = 1,
	MovieRentalShelves = 4,
    SchoolLockers = 1,
    SchoolLockersBad = 0.5,
	ShelfGeneric = 0.5,
	StoreShelfElectronics = 2,
    UniversityWardrobe = 2,
    WardrobeChild = 2,
	WardrobeRedneck = 0.5,
}

-- List of dummy NES items
local nesDummies = {
	"VGC_Addon_NESGames.NES_Cartridge_Dummy1",
	"VGC_Addon_NESGames.NES_Cartridge_Dummy2",
	"VGC_Addon_NESGames.NES_Cartridge_Dummy3",
	"VGC_Addon_NESGames.NES_Cartridge_Dummy4",
	"VGC_Addon_NESGames.NES_Cartridge_Dummy5",

  }

-- List of NES items to replace the dummy with
local itemList =
	{
		"VGC_Addon_NESGames.NES_Cartridge_AdventureIsland",
		"VGC_Addon_NESGames.NES_Cartridge_AdventureIsland2",
		"VGC_Addon_NESGames.NES_Cartridge_BaseballStars",
		"VGC_Addon_NESGames.NES_Cartridge_Batman",
		"VGC_Addon_NESGames.NES_Cartridge_Battletoads",
		"VGC_Addon_NESGames.NES_Cartridge_BionicCommando",
		"VGC_Addon_NESGames.NES_Cartridge_BladesOfSteel",
		"VGC_Addon_NESGames.NES_Cartridge_BlasterMaster",
		"VGC_Addon_NESGames.NES_Cartridge_Bomberman",
		"VGC_Addon_NESGames.NES_Cartridge_BubbleBobble",
		"VGC_Addon_NESGames.NES_Cartridge_Castlevania",
		"VGC_Addon_NESGames.NES_Cartridge_Castlevania2",
		"VGC_Addon_NESGames.NES_Cartridge_Castlevania3",
		"VGC_Addon_NESGames.NES_Cartridge_Crystalis",
		"VGC_Addon_NESGames.NES_Cartridge_ChipNDale",
		"VGC_Addon_NESGames.NES_Cartridge_DoubleDragon",
		"VGC_Addon_NESGames.NES_Cartridge_DoubleDragon2",
		"VGC_Addon_NESGames.NES_Cartridge_DrMario",
		"VGC_Addon_NESGames.NES_Cartridge_DragonWarrior",
		"VGC_Addon_NESGames.NES_Cartridge_DragonWarrior2",
		"VGC_Addon_NESGames.NES_Cartridge_DragonWarrior3",
		"VGC_Addon_NESGames.NES_Cartridge_DragonWarrior4",
		"VGC_Addon_NESGames.NES_Cartridge_DuckHunt",
		"VGC_Addon_NESGames.NES_Cartridge_DuckTales",
		"VGC_Addon_NESGames.NES_Cartridge_Excitebike",
		"VGC_Addon_NESGames.NES_Cartridge_Faxanadu",
		"VGC_Addon_NESGames.NES_Cartridge_FinalFantasy",
		"VGC_Addon_NESGames.NES_Cartridge_GhostsNGoblins",
		"VGC_Addon_NESGames.NES_Cartridge_Gradius",
		"VGC_Addon_NESGames.NES_Cartridge_IceClimber",
		"VGC_Addon_NESGames.NES_Cartridge_Jackal",
		"VGC_Addon_NESGames.NES_Cartridge_KidIcarus",
		"VGC_Addon_NESGames.NES_Cartridge_Kirby",
		"VGC_Addon_NESGames.NES_Cartridge_KungFu",
		"VGC_Addon_NESGames.NES_Cartridge_LifeForce",
		"VGC_Addon_NESGames.NES_Cartridge_LodeRunner",
		"VGC_Addon_NESGames.NES_Cartridge_ManiacMansion",
		"VGC_Addon_NESGames.NES_Cartridge_MegaMan2",
		"VGC_Addon_NESGames.NES_Cartridge_MegaMan3",
		"VGC_Addon_NESGames.NES_Cartridge_MetalGear",
		"VGC_Addon_NESGames.NES_Cartridge_PunchOut",
		"VGC_Addon_NESGames.NES_Cartridge_NinjaGaiden",
		"VGC_Addon_NESGames.NES_Cartridge_NinjaGaiden2",
		"VGC_Addon_NESGames.NES_Cartridge_RCProAm",
		"VGC_Addon_NESGames.NES_Cartridge_RiverCityRansom",
		"VGC_Addon_NESGames.NES_Cartridge_StarTropics",
		"VGC_Addon_NESGames.NES_Cartridge_SuperMarioBros",
		"VGC_Addon_NESGames.NES_Cartridge_SuperMarioBros2",
		"VGC_Addon_NESGames.NES_Cartridge_TecmoBowl",
		"VGC_Addon_NESGames.NES_Cartridge_TecmoSuperBowl",
		"VGC_Addon_NESGames.NES_Cartridge_TMNT",
		"VGC_Addon_NESGames.NES_Cartridge_TMNT2",
		"VGC_Addon_NESGames.NES_Cartridge_TMNT3",
		"VGC_Addon_NESGames.NES_Cartridge_Tetris",
		"VGC_Addon_NESGames.NES_Cartridge_ZeldaG",
		"VGC_Addon_NESGames.NES_Cartridge_Zelda2",
	}

-- Function to add NES loot to procedural distributions  
  local function addNESLoot(proc_name, chance)
	local data = ProceduralDistributions.list
	if not data then
	  return print('VGC NES Addon ERROR: procedure distributions not found!')
	end
	
	local c = data[proc_name]
	if not c then
	  return print('VGC NES Addon ERROR: cant add items to procedure '..proc_name)
	end
	
	for _, console in ipairs(nesDummies) do
	  table.insert(c.items, console)
	  table.insert(c.items, chance)
	end
  end
  
-- Track distribution success for logging
local distribsAdded_forNesAddon = 0
local distribsFailed_forNesAddon = 0
local failedDistribs_forNesAddon = {}

-- Original addNESLoot wrapped to track results
local addNESLootOriginal = addNESLoot
function addNESLoot(proc_name, chance)
    local data = ProceduralDistributions.list
    if not data or not data[proc_name] then
        distribsFailed_forNesAddon = distribsFailed_forNesAddon + 1
        table.insert(failedDistribs_forNesAddon, proc_name)
        return
    end
    addNESLootOriginal(proc_name, chance)
    distribsAdded_forNesAddon = distribsAdded_forNesAddon + 1
end

-- Add an event handler for when game starts
Events.OnGameStart.Add(function()
    print("VGC MOD Addon NES: Game started")
    print(string.format("VGC MOD Addon NES: Successfully added to %d distributions", distribsAdded_forNesAddon))
    -- if distribsFailed_forNesAddon > 0 then
    --     print(string.format("VGC MOD Addon NES WARNING: Failed to add to %d distributions:", distribsFailed_forNesAddon))
    --     for _, distrib in ipairs(failedDistribs_forNesAddon) do
    --         print("  - " .. distrib)
    --     end
    -- end
    print("VGC MOD Addon NES: Using 5 dummy items per location")
end)

-- Optional: Add a debug command to check settings in-game
if isDebugEnabled() then
    local function checkVGC_AddonNES_Settings()
        print("VGC MOD Addon NES DEBUG: Distributions added: " .. distribsAdded_forNesAddon)
        if distribsFailed_forNesAddon > 0 then
            print("VGC MOD Addon NES: Distributions failed: " .. distribsFailed_forNesAddon)
        end
    end
end

-- Adding NES loot to various procedural distributions
-- Distribution chances configured at top in distributionChances table
for proc_name, chance in pairs(distributionChances) do
    addNESLoot(proc_name, chance)
end

-- Function to replace dummy items in a container with real items
local function replaceNESDummies(container)
    if not container then
        return
    end
	
    local dummies = container:getAllType('VGC_Addon_NESGames.NES_Cartridge_Dummy1') -- dummy item type
    if dummies then
		for i = 0, dummies:size()-1 do
			container:Remove(dummies:get(i))
			local itemChoice = ZombRand(#itemList)+1
			local item = container:AddItem(itemList[itemChoice])
			if not item then
                -- Item failed to add, likely doesn't exist
            end
		end
    end
	
	local dummies = container:getAllType('VGC_Addon_NESGames.NES_Cartridge_Dummy2') -- dummy item type
    if dummies then
		for i = 0, dummies:size()-1 do
			container:Remove(dummies:get(i))
			local itemChoice = ZombRand(#itemList)+1
			local item = container:AddItem(itemList[itemChoice])
			if not item then
                -- Item failed to add, likely doesn't exist
            end
		end
    end
	
	local dummies = container:getAllType('VGC_Addon_NESGames.NES_Cartridge_Dummy3') -- dummy item type
    if dummies then
		for i = 0, dummies:size()-1 do
			container:Remove(dummies:get(i))
			local itemChoice = ZombRand(#itemList)+1
			local item = container:AddItem(itemList[itemChoice])
			if not item then
                -- Item failed to add, likely doesn't exist
            end
		end
    end
	
	local dummies = container:getAllType('VGC_Addon_NESGames.NES_Cartridge_Dummy4') -- dummy item type
    if dummies then
		for i = 0, dummies:size()-1 do
			container:Remove(dummies:get(i))
			local itemChoice = ZombRand(#itemList)+1
			local item = container:AddItem(itemList[itemChoice])
			if not item then
                -- Item failed to add, likely doesn't exist
            end
		end
    end
	
	local dummies = container:getAllType('VGC_Addon_NESGames.NES_Cartridge_Dummy5') -- dummy item type
    if dummies then
		for i = 0, dummies:size()-1 do
			container:Remove(dummies:get(i))
			local itemChoice = ZombRand(#itemList)+1
			local item = container:AddItem(itemList[itemChoice])
			if not item then
                -- Item failed to add, likely doesn't exist
            end
		end
    end
end

-- Function to handle filling containers with items
local function onFillContainer(_roomName, _containerType, container)
    -- Only run on server
    if isClient() then
        return
    end
    
    -- Check if the container is an instance of ItemContainer
    if not instanceof(container, "ItemContainer") then
        print("Container is not an instance of ItemContainer")
        return
    end

    replaceNESDummies(container)
end

Events.OnFillContainer.Add(onFillContainer)