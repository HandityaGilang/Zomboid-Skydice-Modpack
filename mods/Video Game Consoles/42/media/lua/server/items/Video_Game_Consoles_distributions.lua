------------------------------------------------------------------------
--  Made By Unconid - slightly vibe coded - I hate gen ai
--  MIT License - you are free to do anything you want with this
--  Version 3.3
--  Mod: Video Game Consoles - B42.13 Compatible
--  Allows players to play video games and modify stats
------------------------------------------------------------------------  

-- Configuration for distribution chances and dummy/item mapping
local distributionChances = {
    BedroomDresserChild = 2,
    BedroomDresserRedneck = 0.5,
    BedroomSidetableChild = 2,
    BreakRoomShelves = 1,
    ClassroomDesk = 1,
    ClassroomMisc = 0.5,
    ClassroomSecondaryDesk = 1,
    ClassroomShelves = 1,
    CrateCompactDiscs = 1,
    CrateElectronics = 2,
    CrateRandomJunk = 0.2,
    CrateToys = 4,
	CrateVHSTapes = 3,
    ElectronicStoreMisc = 3,
    ElectronicStoreMusic = 1,
    DaycareCounter = 1,
	DaycareShelves = 1,
	DaycareDesk = 0.5,
    Gifts = 1,
    GiftStoreToys = 5,
    GigamartHouseElectronics = 2,
    GigamartToys = 4,
    LivingRoomShelf = 1,
    LivingRoomWardrobe = 2,
    LivingRoomSideTable = 1,
	LivingRoomSideTableClassy = 1.5,
	LivingRoomSideTableRedneck = 0.5,
    OfficeDeskHome = 1,
    SchoolLockers = 1,
    SchoolLockersBad = 0.5,
    UniversityWardrobe = 4,
    WardrobeChild = 2,
    WardrobeRedneck = 0.5,
}

-- List of dummy console items (Dummies 1-3: consoles, 4-10: cartridges)
local consoleItems = {
	"Video_Game_Consoles.Cartridge_Dummy1",
	"Video_Game_Consoles.Cartridge_Dummy2",
	"Video_Game_Consoles.Cartridge_Dummy3",
	"Video_Game_Consoles.Cartridge_Dummy4",
	"Video_Game_Consoles.Cartridge_Dummy5",
	"Video_Game_Consoles.Cartridge_Dummy6",
	"Video_Game_Consoles.Cartridge_Dummy7",
	"Video_Game_Consoles.Cartridge_Dummy8",
	"Video_Game_Consoles.Cartridge_Dummy9",
	"Video_Game_Consoles.Cartridge_Dummy10",
  }
  
-- Dummy to item mapping configuration
local dummyGroups = {
    { types = {
        'Video_Game_Consoles.Cartridge_Dummy4',
        'Video_Game_Consoles.Cartridge_Dummy5',
        'Video_Game_Consoles.Cartridge_Dummy6',
        'Video_Game_Consoles.Cartridge_Dummy7',
        'Video_Game_Consoles.Cartridge_Dummy8',
        'Video_Game_Consoles.Cartridge_Dummy9',
        'Video_Game_Consoles.Cartridge_Dummy10',
    }, itemList = nil },
    { types = {
        'Video_Game_Consoles.Cartridge_Dummy1',
        'Video_Game_Consoles.Cartridge_Dummy2',
        'Video_Game_Consoles.Cartridge_Dummy3',
    }, itemList = nil },
}
  
-- List of items to replace the dummy cartridges with
local itemList ={
	"Video_Game_Consoles.SNES_Cartridge_Mario",
	"Video_Game_Consoles.SNES_Cartridge_Mana",
	"Video_Game_Consoles.SNES_Cartridge_Fox",
	"Video_Game_Consoles.SNES_Cartridge_MK2",
	"Video_Game_Consoles.SNES_Cartridge_NBA",
	"Video_Game_Consoles.GB_Cartridge_Zelda",
	"Video_Game_Consoles.GB_Cartridge_Kirby",
	"Video_Game_Consoles.GB_Cartridge_Fantasy",
	"Video_Game_Consoles.GB_Cartridge_Mario",
	"Video_Game_Consoles.GB_Cartridge_Tetris",
	"Video_Game_Consoles.Genesis_Cartridge_Aladdin",
	"Video_Game_Consoles.Genesis_Cartridge_gaxe",
	"Video_Game_Consoles.Genesis_Cartridge_ghouls",
	"Video_Game_Consoles.Genesis_Cartridge_sonic",
	"Video_Game_Consoles.Genesis_Cartridge_street",
	"Video_Game_Consoles.Atari_Cartridge_Combat",
	"Video_Game_Consoles.Atari_Cartridge_Asteroids",
	"Video_Game_Consoles.Atari_Cartridge_MSPacman",
	"Video_Game_Consoles.Atari_Cartridge_Pitfall",
	"Video_Game_Consoles.Atari_Cartridge_Spaceinvaders",
	"Video_Game_Consoles.NES_Cartridge_Contra",
	"Video_Game_Consoles.NES_Cartridge_Mario3",
	"Video_Game_Consoles.NES_Cartridge_Megaman",
	"Video_Game_Consoles.NES_Cartridge_Metroid",
	"Video_Game_Consoles.NES_Cartridge_Zelda",
	"Video_Game_Consoles.GG_Cartridge_sor2",
	"Video_Game_Consoles.GG_Cartridge_AxBattler",
	"Video_Game_Consoles.GG_Cartridge_Shinobi",
	"Video_Game_Consoles.GG_Cartridge_Sonic",
	"Video_Game_Consoles.GG_Cartridge_Vampire",
	"Video_Game_Consoles.Sega_CD_Sonic",
	"Video_Game_Consoles.Sega_CD_beholder",
	"Video_Game_Consoles.Sega_CD_dune",
	"Video_Game_Consoles.Sega_CD_jurasic",
	"Video_Game_Consoles.Sega_CD_nighttrap",
	"Video_Game_Consoles.CDi_Link",
	"Video_Game_Consoles.CDi_7guest",
	"Video_Game_Consoles.CDi_lemmings",
	"Video_Game_Consoles.CDi_pacattack",
	"Video_Game_Consoles.CDi_zelda",
	"Video_Game_Consoles.Lynx_cartridge_checkered",
	"Video_Game_Consoles.Lynx_cartridge_chips",
	"Video_Game_Consoles.Lynx_cartridge_klax",
	"Video_Game_Consoles.Lynx_cartridge_rampart",
	"Video_Game_Consoles.Lynx_cartridge_todds",
}

local itemList2 = {
	"Video_Game_Consoles.GameBoy",
	"Video_Game_Consoles.Genesis",
	"Video_Game_Consoles.SegaCD_empty",
	"Video_Game_Consoles.Atari",
	"Video_Game_Consoles.NES",
	"Video_Game_Consoles.SNES",
	"Video_Game_Consoles.Philips_CD_I",
	"Video_Game_Consoles.Game_Gear",
	"Video_Game_Consoles.Atari_Lynx",
}

-- Link dummyGroups to the item lists
dummyGroups[1].itemList = itemList
dummyGroups[2].itemList = itemList2
  -- Function to add console loot to procedural distributions
  local function addConsoleLoot(proc_name, chance)
    local data = ProceduralDistributions.list
    if not data then
        return print('VGC Addon ERROR: procedure distributions not found!')
    end
    
    local c = data[proc_name]
    if not c then
        return print('VGC Addon ERROR: cant add items to procedure '..proc_name)
    end
    
    for _, console in ipairs(consoleItems) do
        table.insert(c.items, console)
        table.insert(c.items, chance)
    end
end

-- Track distribution success for logging
local distribsAdded = 0
local distribsFailed = 0
local failedDistribs = {}

-- Original addConsoleLoot wrapped to track results
local addConsoleLootOriginal = addConsoleLoot
function addConsoleLoot(proc_name, chance)
    local data = ProceduralDistributions.list
    if not data or not data[proc_name] then
        distribsFailed = distribsFailed + 1
        table.insert(failedDistribs, proc_name)
        return
    end
    addConsoleLootOriginal(proc_name, chance)
    distribsAdded = distribsAdded + 1
end

-- Add an event handler for when game starts
Events.OnGameStart.Add(function()
    print("VGC MOD: Game started")
    print(string.format("VGC MOD: Successfully added to %d distributions", distribsAdded))
    -- if distribsFailed > 0 then
    --     print(string.format("VGC MOD WARNING: Failed to add to %d distributions:", distribsFailed))
    --     for _, distrib in ipairs(failedDistribs) do
    --         print("  - " .. distrib)
    --     end
    -- end
    print("VGC MOD: Using 10 dummy items per location (340 total items)")
end)

-- Optional: Add a debug command to check settings in-game
if isDebugEnabled() then
    local function checkVGCSettings()
        print("VGC MOD DEBUG: Distributions added: " .. distribsAdded)
        if distribsFailed > 0 then
            print("VGC MOD DEBUG: Distributions failed: " .. distribsFailed)
        end
    end
end

-- Adding console loot to various procedural distributions
-- Distribution chances configured at top in distributionChances table
for proc_name, chance in pairs(distributionChances) do
    addConsoleLoot(proc_name, chance)
end

-- Function to replace dummy items in a container with real items
local function replaceDummies(container)
    if not container then
        return
    end

    for _, group in ipairs(dummyGroups) do
        if group.itemList and #group.itemList > 0 then
            for _, dummyType in ipairs(group.types) do
                local dummies = container:getAllType(dummyType)
                if dummies then
                    for i = 0, dummies:size() - 1 do
                        container:Remove(dummies:get(i))
                        local itemChoice = ZombRand(#group.itemList) + 1
                        local item = container:AddItem(group.itemList[itemChoice])
                        if not item then
                            -- Item failed to add, likely doesn't exist
                        end
                    end
                end
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

    replaceDummies(container)
end

Events.OnFillContainer.Add(onFillContainer)