local AE_FriendlinessSystem = {}
local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
local AE_DataConfig = require("AnimalsEssentials/Config/AE_DataConfig")
local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
local SandboxSettings = nil
local function getSandboxSettings()
    if not SandboxSettings then
        local success, result = pcall(function()
            return require("AnimalsEssentials/Config/AE_SandboxSettings")
        end)
        if success then
            SandboxSettings = result
        else
            SandboxSettings = {
                GetFriendlinessGainMultiplier = function() return 1.0 end
            }
        end
    end
    return SandboxSettings
end
local TamingSystem = nil
local tamingSuccess, tamingResult = pcall(function()
    return require("AnimalsEssentials/Taming/AE_TamingSystem")
end)
if tamingSuccess and tamingResult then
    TamingSystem = tamingResult
end
AE_FriendlinessSystem.KEY_FRIENDLINESS = AE_DataConfig.ModDataKeys.Friendliness
AE_FriendlinessSystem.ANIMAL_CARE_SKILL = Perks.Farming
function AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    if not animal then return nil end
    local animalCategory = AnimalRegistry.GetAnimalType(animal)
    if not animalCategory then return nil end
    return Config.GetFriendlinessConfig(animalCategory)
end
function AE_FriendlinessSystem.Initialize(animal)
    if not Config.IsSystemEnabled("FriendlinessSystem") then return false end
    if not animal then return false end
    if not TamingSystem then return false end
    local modData = TamingSystem.getAnimalModData(animal)
    if not modData then return false end
    if modData[AE_FriendlinessSystem.KEY_FRIENDLINESS] == nil then
        modData[AE_FriendlinessSystem.KEY_FRIENDLINESS] = 0.0
        animal:transmitModData()
    end
    return true
end
function AE_FriendlinessSystem.GetFriendliness(animal)
    if not animal then return 0.0 end
    if not TamingSystem then return 0.0 end
    local modData = TamingSystem.getAnimalModData(animal)
    if not modData then return 0.0 end
    local friendliness = modData[AE_FriendlinessSystem.KEY_FRIENDLINESS]
    return type(friendliness) == "number" and friendliness or 0.0
end
function AE_FriendlinessSystem.SetFriendliness(animal, value)
    if not animal then return nil end
    if not TamingSystem then return nil end
    local modData = TamingSystem.getAnimalModData(animal)
    if not modData then return nil end
    local friendlinessConfig = AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    local maxFriendliness = friendlinessConfig and friendlinessConfig.Max_Friendliness or 100.0
    local minFriendliness = friendlinessConfig and friendlinessConfig.Min_Friendliness or 0.0
    local clamped = math.min(maxFriendliness, math.max(minFriendliness, value))
    modData[AE_FriendlinessSystem.KEY_FRIENDLINESS] = clamped
    animal:transmitModData()
    return clamped
end
function AE_FriendlinessSystem.IncreaseFriendliness(animal, amount, player)
    if not animal then return nil end
    local sandboxSettings = getSandboxSettings()
    local multiplier = sandboxSettings.GetFriendlinessGainMultiplier()
    local adjustedAmount = amount * multiplier
    if player then
        local success, CrazyCatPersonProf = pcall(function()
            return require("Professions/CrazyCatPersonProf")
        end)
        if success and CrazyCatPersonProf then
            local professionMultiplier = CrazyCatPersonProf.GetBonus(player, "FRIENDLINESS_GAIN_MULTIPLIER")
            adjustedAmount = adjustedAmount * professionMultiplier
        end
    end
    local current = AE_FriendlinessSystem.GetFriendliness(animal)
    return AE_FriendlinessSystem.SetFriendliness(animal, current + adjustedAmount)
end
function AE_FriendlinessSystem.AwardAnimalCareXP(player, amount)
    if not player then return end
    if not amount or amount <= 0 then return end
    local success = pcall(function()
        player:getXp():AddXP(AE_FriendlinessSystem.ANIMAL_CARE_SKILL, amount)
    end)
end
function AE_FriendlinessSystem.OnPetting(player, animal)
    if not Config.IsSystemEnabled("FriendlinessSystem") then return end
    if not player or not animal then return end
    AE_FriendlinessSystem.Initialize(animal)
    local friendlinessGain = ZombRand(1, 11)
    local newFriendliness = AE_FriendlinessSystem.IncreaseFriendliness(animal, friendlinessGain, player)
    local friendlinessConfig = AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    local xpMultiplier = friendlinessConfig and friendlinessConfig.XP_Multiplier_Petting or 0.5
    local xpGain = friendlinessGain * xpMultiplier
    AE_FriendlinessSystem.AwardAnimalCareXP(player, xpGain)
end
function AE_FriendlinessSystem.OnFeeding(player, animal, hungerRestored)
    if not Config.IsSystemEnabled("FriendlinessSystem") then return end
    if not player or not animal then return end
    if not hungerRestored or hungerRestored <= 0 then return end
    AE_FriendlinessSystem.Initialize(animal)
    local friendlinessGain = 0
    local hungerPercent = math.min(100, math.max(0, hungerRestored))
    if hungerPercent >= 76 then
        friendlinessGain = ZombRand(1, 16)
    elseif hungerPercent >= 51 then
        friendlinessGain = ZombRand(1, 11)
    elseif hungerPercent >= 26 then
        friendlinessGain = ZombRand(1, 9)
    else
        friendlinessGain = ZombRand(1, 6)
    end
    local newFriendliness = AE_FriendlinessSystem.IncreaseFriendliness(animal, friendlinessGain, player)
    local friendlinessConfig = AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    local xpMultiplier = friendlinessConfig and friendlinessConfig.XP_Multiplier_Feeding or 1.0
    local xpGain = friendlinessGain * xpMultiplier
    AE_FriendlinessSystem.AwardAnimalCareXP(player, xpGain)
end
function AE_FriendlinessSystem.OnGivingWater(player, animal, thirstRestored)
    if not Config.IsSystemEnabled("FriendlinessSystem") then return end
    if not player or not animal then return end
    if not thirstRestored or thirstRestored <= 0 then return end
    AE_FriendlinessSystem.Initialize(animal)
    local friendlinessGain = 0
    local thirstPercent = math.min(100, math.max(0, thirstRestored))
    if thirstPercent >= 76 then
        friendlinessGain = ZombRand(1, 16)
    elseif thirstPercent >= 51 then
        friendlinessGain = ZombRand(1, 11)
    elseif thirstPercent >= 26 then
        friendlinessGain = ZombRand(1, 9)
    else
        friendlinessGain = ZombRand(1, 6)
    end
    local newFriendliness = AE_FriendlinessSystem.IncreaseFriendliness(animal, friendlinessGain, player)
    local friendlinessConfig = AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    local xpMultiplier = friendlinessConfig and friendlinessConfig.XP_Multiplier_Watering or 1.0
    local xpGain = friendlinessGain * xpMultiplier
    AE_FriendlinessSystem.AwardAnimalCareXP(player, xpGain)
end
function AE_FriendlinessSystem.OnSuccessfulCommand(player, animal)
    if not Config.IsSystemEnabled("FriendlinessSystem") then return end
    if not player or not animal then return end
    AE_FriendlinessSystem.Initialize(animal)
    local friendlinessGain = ZombRand(1, 4)
    local newFriendliness = AE_FriendlinessSystem.IncreaseFriendliness(animal, friendlinessGain, player)
    local friendlinessConfig = AE_FriendlinessSystem.GetFriendlinessConfig(animal)
    local xpMultiplier = friendlinessConfig and friendlinessConfig.XP_Multiplier_Command or 0.3
    local xpGain = friendlinessGain * xpMultiplier
    AE_FriendlinessSystem.AwardAnimalCareXP(player, xpGain)
end
function AE_FriendlinessSystem.OnGameStart()
    if not Config.IsSystemEnabled("FriendlinessSystem") then
        return
    end
end
Events.OnGameStart.Add(AE_FriendlinessSystem.OnGameStart)
return AE_FriendlinessSystem