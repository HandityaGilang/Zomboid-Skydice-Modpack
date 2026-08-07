-- True Music Dynamic Sandbox Options Registration
-- This file registers sandbox options for detected music mods
-- Runs in shared context (both client and server)

TCDynamicSandbox = TCDynamicSandbox or {}
TCDynamicSandbox.RegisteredMods = {}

local DEBUG = false
local function log(msg)
    if DEBUG then
        print(msg)
    end
end

-- Function to safely create a sandbox variable name from mod ID
function TCDynamicSandbox.CreateSandboxKey(modID)
    -- Replace non-alphanumeric characters with underscores
    local cleanKey = modID:gsub("[^%w]", "_")
    return "SpawnRate_" .. cleanKey
end

-- Function to register sandbox options for detected mods
-- This should be called during game initialization
function TCDynamicSandbox.RegisterModOptions()
    -- This function will be called after mods are loaded
    -- The actual registration happens through the sandbox-options.txt file
    -- But we can prepare translations here
    
    log("TCDynamicSandbox: Preparing dynamic sandbox options")
    
    -- We'll add translations dynamically through the translation system
    -- This is a placeholder for future dynamic option registration
end

-- Add translation entries for detected mods
function TCDynamicSandbox.AddModTranslations(modID, modName)
    local sandboxKey = TCDynamicSandbox.CreateSandboxKey(modID)
    
    -- Try to add to translation table if it exists
    if Sandbox_EN then
        local translationKey = "Sandbox_PZTrueMusicSandbox_" .. sandboxKey
        local tooltipKey = translationKey .. "_tooltip"
        
        Sandbox_EN[translationKey] = modName .. " Cassette Spawn Rate"
        Sandbox_EN[tooltipKey] = "Control spawn rate for cassettes from " .. modName .. ". Multiplied by Master rate."
        
        -- Add option values
        for i = 1, 6 do
            local optionKey = translationKey .. "_option" .. i
            local optionValues = {
                "Very Low (0.1x)",
                "Low (0.5x)", 
                "Normal (1.0x)",
                "High (2.0x)",
                "Very High (5.0x)",
                "Disabled"
            }
            Sandbox_EN[optionKey] = optionValues[i]
        end
        
        log("TCDynamicSandbox: Added translations for " .. modName)
        TCDynamicSandbox.RegisteredMods[modID] = true
    end
end

-- Initialize translations on startup
local function OnGameBoot()
    -- This runs very early, but we may not have mod info yet
    log("TCDynamicSandbox: Game boot - preparing for dynamic options")
end

Events.OnGameBoot.Add(OnGameBoot)
