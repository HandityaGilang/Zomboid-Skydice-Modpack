-- True Music Sandbox Options System
-- Creates dynamic sandbox options for detected music mods

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end

-- Safely require detector module
local detectorLoaded = pcall(require, "TCMusicModDetector")
if not detectorLoaded then
    dlog("TCMusicSandbox: Warning - TCMusicModDetector not loaded")
end

TCMusicSandbox = TCMusicSandbox or {}

-- Default spawn rate values
TCMusicSandbox.SpawnRateValues = {
    {value = 0.1, name = "VeryLow"},
    {value = 0.5, name = "Low"},
    {value = 1.0, name = "Normal"},
    {value = 2.0, name = "High"},
    {value = 5.0, name = "VeryHigh"},
    {value = 0.0, name = "Disabled"}
}

-- Get spawn rate multiplier for a specific mod
function TCMusicSandbox.GetSpawnRateForMod(modID)
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end
    
    -- Create safe sandbox variable name from modID
    local sandboxKey = "SpawnRate_" .. modID:gsub("[^%w]", "_")
    
    local spawnRate = SandboxVars.PZTrueMusicSandbox[sandboxKey]
    
    if spawnRate == nil then
        return 1.0 -- Default normal spawn rate
    end
    
    -- Convert percentage (0-500) to multiplier (0.0-5.0)
    return spawnRate / 100.0
end

-- Get spawn rate for vinyl media items (records/albums).
function TCMusicSandbox.GetVinylSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end
    
    local spawnRate = SandboxVars.PZTrueMusicSandbox.VinylSpawn
    
    if spawnRate == nil then
        -- Backwards compatibility with older saves
        local legacyRate = SandboxVars.PZTrueMusicSandbox.TrueMusicSpawnRate
        if legacyRate == nil then
            return 1.0
        end
        spawnRate = legacyRate
    end
    
    -- Intentional compression for better low-end control:
    -- 100% behaves like effective 50%.
    return (spawnRate / 100.0) * 0.5
end

-- Get spawn rate for Vinyl player device items.
function TCMusicSandbox.GetVinylPlayerSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.VinylPlayerSpawn
    if spawnRate == nil then
        -- Backwards compatibility: prior versions used VinylSpawn for the player.
        spawnRate = SandboxVars.PZTrueMusicSandbox.VinylSpawn
    end
    if spawnRate == nil then
        return 1.0
    end
    return spawnRate / 100.0
end

-- Legacy alias for older code paths
function TCMusicSandbox.GetTrueMusicSpawnRate()
    return TCMusicSandbox.GetVinylSpawnRate()
end

-- Legacy helpers (kept for compatibility; now map to unified rate)
function TCMusicSandbox.GetWalkmanSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.WalkmanSpawn

    if spawnRate == nil then
        return 1.0
    end

    return spawnRate / 100.0
end

function TCMusicSandbox.GetBoomboxSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.BoomboxSpawn

    if spawnRate == nil then
        return 1.0
    end

    return spawnRate / 100.0
end

function TCMusicSandbox.GetZombieWalkmanSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.ZombieWalkmanSpawnRate

    if spawnRate == nil then
        return 1.0
    end

    return spawnRate / 100.0
end

-- Check if a mod's spawning is enabled
function TCMusicSandbox.IsModSpawnEnabled(modID)
    local rate = TCMusicSandbox.GetSpawnRateForMod(modID)
    return rate > 0
end

-- Get spawn rate for cassette media items.
function TCMusicSandbox.GetCassetteSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local cassetteRate = SandboxVars.PZTrueMusicSandbox.CassetteSpawnRate
    if cassetteRate == nil then
        -- Backwards compatibility with older saves/configs.
        cassetteRate = SandboxVars.PZTrueMusicSandbox.MasterCassetteSpawnRate
    end

    if cassetteRate == nil then
        return 1.0
    end

    -- Intentional compression for better low-end control:
    -- 100% behaves like effective 50%.
    return (cassetteRate / 100.0) * 0.5
end

-- Legacy alias for older code paths.
function TCMusicSandbox.GetMasterSpawnRate()
    return TCMusicSandbox.GetCassetteSpawnRate()
end

-- Get spawn rate for CD media items (from detected CD packs).
function TCMusicSandbox.GetCDSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.CDSpawnRate
    if spawnRate == nil then
        -- Fall back to the cassette master rate for older saves without the option.
        return TCMusicSandbox.GetCassetteSpawnRate()
    end

    -- Same low-end compression as cassettes: 100% behaves like effective 50%.
    return (spawnRate / 100.0) * 0.5
end

-- Max TrueMoozic media items (per category: cassette/vinyl/CD) allowed in one
-- freshly-filled container. 0 disables the cap.
function TCMusicSandbox.GetMaxMediaPerContainer()
    if not SandboxVars.PZTrueMusicSandbox then return 5 end
    local cap = SandboxVars.PZTrueMusicSandbox.MaxMediaPerContainer
    if cap == nil then return 5 end
    return tonumber(cap) or 5
end

-- Whether newly-added music packs should be sprinkled into already-generated
-- containers mid-save.
function TCMusicSandbox.IsMidSaveLootEnabled()
    if not SandboxVars.PZTrueMusicSandbox then return false end
    return SandboxVars.PZTrueMusicSandbox.GenerateNewLootMidSave == true
end

-- Percent of CDs looted OUTSIDE a CD case that spawn clean (unscratched).
-- The rest roll a scratch tier (25/50/100) evenly.
function TCMusicSandbox.GetCDScratchCleanChance()
    if not SandboxVars.PZTrueMusicSandbox then return 75 end
    local v = SandboxVars.PZTrueMusicSandbox.CDScratchCleanChance
    if v == nil then return 75 end
    v = tonumber(v) or 75
    if v < 0 then v = 0 end
    if v > 100 then v = 100 end
    return v
end

function TCMusicSandbox.GetCassetteCaseSpawnRate()
    if not SandboxVars.PZTrueMusicSandbox then return 1.0 end

    local spawnRate = SandboxVars.PZTrueMusicSandbox.CassetteCaseSpawnRate

    if spawnRate == nil then
        return 1.0
    end

    return spawnRate / 100.0
end

-- Calculate final spawn rate for an item
function TCMusicSandbox.GetFinalSpawnRate(modID)
    local masterRate = TCMusicSandbox.GetCassetteSpawnRate()
    local modRate = TCMusicSandbox.GetSpawnRateForMod(modID)
    
    return masterRate * modRate
end

-- Log current sandbox settings
function TCMusicSandbox.LogSettings()
    if not SandboxVars.PZTrueMusicSandbox then
        dlog("TCMusicSandbox: No sandbox vars found")
        return
    end
    
    dlog("=== TCMusicSandbox Settings ===")
    dlog("Cassette Spawn Rate: " .. TCMusicSandbox.GetCassetteSpawnRate())
    dlog("Cassette Case Spawn Rate: " .. TCMusicSandbox.GetCassetteCaseSpawnRate())
    dlog("Vinyl Spawn Rate: " .. TCMusicSandbox.GetVinylSpawnRate())
    dlog("Vinyl Player Spawn Rate: " .. TCMusicSandbox.GetVinylPlayerSpawnRate())
    dlog("Walkman Spawn Rate: " .. TCMusicSandbox.GetWalkmanSpawnRate())
    dlog("Boombox Spawn Rate: " .. TCMusicSandbox.GetBoomboxSpawnRate())
    dlog("Zombie Walkman Spawn Rate: " .. TCMusicSandbox.GetZombieWalkmanSpawnRate())
    
    if TCMusicModDetector and TCMusicModDetector.DetectedMods then
        for modID, modInfo in pairs(TCMusicModDetector.DetectedMods) do
            local rate = TCMusicSandbox.GetSpawnRateForMod(modID)
            local finalRate = TCMusicSandbox.GetFinalSpawnRate(modID)
            dlog(string.format("%s: Rate=%.2f, Final=%.2f", modInfo.name, rate, finalRate))
        end
    else
        dlog("No additional music mods detected")
    end
    
    dlog("================================")
end

-- Initialize on game start
local function OnGameStart()
    TCMusicSandbox.LogSettings()
end

Events.OnGameStart.Add(OnGameStart)
