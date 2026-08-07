-- True Music Mod Detector System
-- Detects active music mods and their cassette items

if isClient() then return end

require "TCDynamicSandbox"

TCMusicModDetector = TCMusicModDetector or {}

local DEBUG = false
local function log(msg)
    if DEBUG then
        print(msg)
    end
end

-- Table to store detected music mods
TCMusicModDetector.DetectedMods = {}
TCMusicModDetector.CassetteItems = {}

-- Known music mod patterns to search for
TCMusicModDetector.MusicModPatterns = {
    -- Add patterns for known music mods
    "music",
    "cassette",
    "tape",
    "vinyl",
    "cd",
    "radio",
}

-- Item type patterns that indicate cassettes/music media
-- NOTE: These must match the actual TYPE name, not display name
TCMusicModDetector.ItemPatterns = {
    "Cassette",  -- Most music mods use this
    "Vinyl",     -- Vinyl records
    "CD",        -- Compact discs
    "Tape",      -- Some packs use tape naming instead of cassette
    "TMCassette",-- Simple Moozic Builder convention
    "TMVinyl",   -- Simple Moozic Builder convention
}

-- Function to check if a mod is a music mod
function TCMusicModDetector.IsMusicMod(modInfo)
    if not modInfo then return false end
    
    local modID = modInfo:getId()
    local modName = modInfo:getName()
    
    if not modID or not modName then return false end
    
    -- Skip self
    if modID == "TrueMoozic" then return false end
    
    -- Check if mod ID or name contains music-related keywords
    local searchText = (modID .. " " .. modName):lower()
    
    for _, pattern in ipairs(TCMusicModDetector.MusicModPatterns) do
        if string.find(searchText, pattern:lower()) then
            return true
        end
    end
    
    return false
end

-- Function to scan all items and find music-related items from a mod
function TCMusicModDetector.FindCassettesFromMod(modID)
    local cassettes = {}
    local allItems = getAllItems()
    
    if not allItems then 
        log("TCMusicModDetector: WARNING - getAllItems() returned nil")
        return cassettes 
    end
    
    local totalItems = allItems:size()
    local checkedItems = 0
    local matchedItems = 0
    
    log("TCMusicModDetector: Scanning " .. totalItems .. " total items for mod: " .. modID)
    
    for i = 0, totalItems - 1 do
        local item = allItems:get(i)
        if item then
            local fullType = item:getFullName()
            local itemName = item:getName()
            
            if fullType and itemName then
                local itemModID = item:getModID()
                
                -- Check if item belongs to this mod
                if itemModID == modID then
                    checkedItems = checkedItems + 1
                    
                    -- Check if item matches cassette/music media patterns
                    local searchText = (fullType .. " " .. itemName):lower()
                    
                    for _, pattern in ipairs(TCMusicModDetector.ItemPatterns) do
                        if string.find(searchText, pattern:lower()) then
                            matchedItems = matchedItems + 1
                            table.insert(cassettes, {
                                fullType = fullType,
                                displayName = item:getDisplayName(),
                                modID = modID
                            })
                            log("TCMusicModDetector: Found cassette: " .. fullType)
                            break
                        end
                    end
                end
            end
        end
    end
    
    log("TCMusicModDetector: Mod " .. modID .. " - Checked " .. checkedItems .. " items, found " .. matchedItems .. " cassettes")
    
    return cassettes
end

-- Main detection function - scans all items and groups by mod
function TCMusicModDetector.DetectMusicMods()
    log("=== TCMusicModDetector: Starting mod detection ===")
    
    -- Clear previous detection results
    TCMusicModDetector.DetectedMods = {}
    TCMusicModDetector.CassetteItems = {}
    
    -- Get all items in the game
    local allItems = getAllItems()
    if not allItems then
        log("TCMusicModDetector: ERROR - getAllItems() returned nil")
        return
    end
    
    local totalItems = allItems:size()
    log("TCMusicModDetector: Scanning " .. totalItems .. " total items")
    log("TCMusicModDetector: ===== DETAILED DEBUG INFO =====")
    
    -- Track items by mod ID
    local itemsByMod = {}
    
    for i = 0, totalItems - 1 do
        local item = allItems:get(i)
        if item then
            local fullType = item:getFullName()
            local itemName = item:getName()
            local itemModID = item:getModID()
            
            -- Skip items without mod ID (base game items)
            if itemModID and itemModID ~= "" then
                -- Check if this looks like a cassette/music item
                local lowerName = (fullType .. " " .. itemName):lower()
                local isMusicItem = false
                
                for _, pattern in ipairs(TCMusicModDetector.ItemPatterns) do
                    if string.find(lowerName, pattern:lower()) then
                        isMusicItem = true
                        break
                    end
                end
                
                if isMusicItem then
                    -- Initialize mod entry if not exists
                    if not itemsByMod[itemModID] then
                        itemsByMod[itemModID] = {
                            cassettes = {},
                            count = 0
                        }
                    end
                    
                    -- Add cassette to this mod's list
                    table.insert(itemsByMod[itemModID].cassettes, {
                        fullType = fullType,
                        name = itemName
                    })
                    itemsByMod[itemModID].count = itemsByMod[itemModID].count + 1
                end
            end
        end
    end
    
    -- Now process each mod that has cassettes
    log("TCMusicModDetector: ===== PROCESSING DETECTED MODS =====")
    local modCount = 0
    
    for modID, modData in pairs(itemsByMod) do
        -- Skip TrueMoozic itself and base game items
        if modID ~= "TrueMoozic" and modID ~= "pz-vanilla" and modID ~= "Base" then
            modCount = modCount + 1
            log("TCMusicModDetector: [" .. modCount .. "] Found music mod: " .. modID)
            log("TCMusicModDetector: [" .. modCount .. "] Cassette count: " .. modData.count)
            
            -- Store detected mod
            TCMusicModDetector.DetectedMods[modID] = {
                name = modID, -- Use modID as name since we don't have mod metadata
                id = modID,
                cassetteCount = modData.count
            }
            
            TCMusicModDetector.CassetteItems[modID] = modData.cassettes
            
            -- Print first few cassettes as examples
            local printCount = math.min(5, modData.count)
            for j = 1, printCount do
                local cassette = modData.cassettes[j]
                log("TCMusicModDetector: [" .. modCount .. "] - Example cassette " .. j .. ": " .. cassette.fullType)
            end
            if modData.count > 5 then
                log("TCMusicModDetector: [" .. modCount .. "] - ... and " .. (modData.count - 5) .. " more")
            end
            
            -- Add translations for this mod's sandbox options
            TCDynamicSandbox.AddModTranslations(modID, modID)
        end
    end
    
    log("TCMusicModDetector: ===== DETECTION SUMMARY =====")
    log("TCMusicModDetector: Total music mods detected: " .. 
          TCMusicModDetector.GetDetectedModCount())
    
    if TCMusicModDetector.GetDetectedModCount() > 0 then
        log("TCMusicModDetector: Detected mods list:")
        for modID, modInfo in pairs(TCMusicModDetector.DetectedMods) do
            log("TCMusicModDetector: - " .. modInfo.name .. " (" .. modInfo.cassetteCount .. " cassettes)")
        end
    else
        log("TCMusicModDetector: No music mods detected")
    end
    
    log("TCMusicModDetector: ===========================")
    
    return TCMusicModDetector.DetectedMods
end

-- Get count of detected mods
function TCMusicModDetector.GetDetectedModCount()
    local count = 0
    for _ in pairs(TCMusicModDetector.DetectedMods) do
        count = count + 1
    end
    return count
end

-- Get all cassettes from all detected mods
function TCMusicModDetector.GetAllCassettes()
    local allCassettes = {}
    for modID, cassettes in pairs(TCMusicModDetector.CassetteItems) do
        for _, cassette in ipairs(cassettes) do
            table.insert(allCassettes, cassette)
        end
    end
    return allCassettes
end

-- Get cassettes from a specific mod
function TCMusicModDetector.GetCassettesFromMod(modID)
    return TCMusicModDetector.CassetteItems[modID] or {}
end

-- Detection is called directly by TCSpawnController during OnPostDistributionMerge
-- This ensures detection runs before spawn rate adjustments

-- Backup: Also run on server start for dedicated servers
if isServer() then
    local function OnServerStarted()
        log("TCMusicModDetector: OnServerStarted event fired!")
        if TCMusicModDetector.GetDetectedModCount() == 0 then
            TCMusicModDetector.DetectMusicMods()
        end
    end
    Events.OnServerStarted.Add(OnServerStarted)
end
