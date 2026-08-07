local AE_SummoningSystemHandler = {}

-- Load the shared spawning system
local AE_SummoningSystem = require("AnimalsEssentials/AE_SummoningSystem")

local function validateAndCoerceCoordinate(value, defaultValue)
    if type(value) == "number" then
        return value
    elseif type(value) == "string" then
        local numValue = tonumber(value)
        return numValue or defaultValue
    else
        return defaultValue
    end
end

local function validatePlayerAuthority(player)
    if not player then return false end
    if not player:getUsername() then return false end
    return true
end

function AE_SummoningSystemHandler.onServerCommand(module, command, player, args)
    print("[AE_SummoningSystemHandler] SERVER: Command received - module: " .. tostring(module) .. ", command: " .. tostring(command))
    print("[AE_SummoningSystemHandler] SERVER: Player object: " .. tostring(player))
    print("[AE_SummoningSystemHandler] SERVER: Args object: " .. tostring(args))
    
    if module ~= "AE_SummoningSystem" then
        print("[AE_SummoningSystemHandler] SERVER: Wrong module '" .. tostring(module) .. "', expected 'AE_SummoningSystem', exiting")
        return
    end
    print("[AE_SummoningSystemHandler] SERVER: Module validation passed")
    
    if command == "requestAnimalSummon" then
        print("[AE_SummoningSystemHandler] SERVER: Processing requestAnimalSummon command")
        
        if not player then
            print("[AE_SummoningSystemHandler] SERVER: Player object is nil")
            return
        end
        
        if not args then
            print("[AE_SummoningSystemHandler] SERVER: Args object is nil")
            return
        end
        
        print("[AE_SummoningSystemHandler] SERVER: Raw args - x:" .. tostring(args.x) .. " y:" .. tostring(args.y) .. " z:" .. tostring(args.z))
        
        local playerValid = validatePlayerAuthority(player)
        print("[AE_SummoningSystemHandler] SERVER: Player validation result: " .. tostring(playerValid))
        
        if not playerValid then
            print("[AE_SummoningSystemHandler] SERVER: Player validation failed")
            return
        end
        
        local x = validateAndCoerceCoordinate(args.x, 0)
        local y = validateAndCoerceCoordinate(args.y, 0)
        local z = validateAndCoerceCoordinate(args.z, 0)
        local radius = validateAndCoerceCoordinate(args.radius, 3)
        
        print("[AE_SummoningSystemHandler] SERVER: Processed coordinates - x: " .. tostring(x) .. ", y: " .. tostring(y) .. ", z: " .. tostring(z) .. ", radius: " .. tostring(radius))
        
        if not x or not y or not z then
            print("[AE_SummoningSystemHandler] SERVER: Invalid coordinates after processing, exiting")
            return
        end
        
        print("[AE_SummoningSystemHandler] SERVER: All validation passed, calling AE_SummoningSystem.summonRandomCat")
        local result = AE_SummoningSystem.summonRandomCat(player, x, y, z, radius)
        print("[AE_SummoningSystemHandler] SERVER: Summoning result: " .. tostring(result))
        
        if result then
            print("[AE_SummoningSystemHandler] SERVER: Spawning completed successfully")
        else
            print("[AE_SummoningSystemHandler] SERVER: Spawning failed")
        end
    else
        print("[AE_SummoningSystemHandler] SERVER: Unknown command '" .. tostring(command) .. "'")
    end
end

function AE_SummoningSystemHandler.Initialize()
    print("[AE_SummoningSystemHandler] Initialize called - registering OnClientCommand handler")
    Events.OnClientCommand.Add(AE_SummoningSystemHandler.onServerCommand)
end

Events.OnGameStart.Add(AE_SummoningSystemHandler.Initialize)

return AE_SummoningSystemHandler