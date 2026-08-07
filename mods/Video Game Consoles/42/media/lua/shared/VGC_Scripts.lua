------------------------------------------------------------------------
--  Made By Unconid - slightly vibe coded - I hate gen ai
--  MIT License - you are free to do anything you want with this
--  Version 3.3
--  Mod: Video Game Consoles - B42.13 Compatible
--  Allows players to play video games and modify stats
------------------------------------------------------------------------  

Video_Game_Consoles = Video_Game_Consoles or {}

local ZombRand = ZombRand
local math_min = math.min
local math_max = math.max

local gameTime = GameTime:getInstance()
local allowExteriorGenerator = SandboxVars.AllowExteriorGenerator
local elecShutModifier = SandboxVars.ElecShutModifier

-- Magic number constants
local RAGE_QUIT_CHANCE = 10  -- 10% chance
local GRID_SCAN_RANGE = 2    -- -2 to +2 squares

--------------------------------------------------
-- 1. CONFIGURATION & LOOKUP TABLES
--------------------------------------------------

local BAD_ENDINGS = {
    "WHAT WERE THEY THINKING?!?",
    "WHY ARE THERE NO CONTINUES WHYYYYYYYY",
    "AAAASSSSSS",
    "THIS GAME SUCKS"
}

local tvSpriteMap = {}
for i = 0, 99 do
    tvSpriteMap["appliances_television_01_" .. i] = true
end

--------------------------------------------------
-- 2. MAIN LOGIC
--------------------------------------------------

-- Helper: Modify a stat with clamping
local function modifyStat(stats, statType, delta, minVal, maxVal)
    local current = stats:get(statType)
    stats:set(statType, math_max(minVal, math_min(maxVal, current + delta)))
end

function Video_Game_Consoles.VGC_PlayGame(recipeData, character)
    local stats = character:getStats()

    -- ROLL THE DICE: RAGE_QUIT_CHANCE
    if ZombRand(1, 101) <= RAGE_QUIT_CHANCE then
        -- BAD ENDING
        character:Say(BAD_ENDINGS[ZombRand(#BAD_ENDINGS) + 1])
        modifyStat(stats, CharacterStat.UNHAPPINESS, ZombRand(5, 21), 0.0, 100.0)
        modifyStat(stats, CharacterStat.BOREDOM, ZombRand(5, 21), 0.0, 100.0)
        modifyStat(stats, CharacterStat.STRESS, ZombRand(5, 21) / 100.0, 0.0, 1.0)
    else
        -- GOOD ENDING
        modifyStat(stats, CharacterStat.UNHAPPINESS, -ZombRand(10, 26), 0.0, 100.0)
        modifyStat(stats, CharacterStat.BOREDOM, -ZombRand(20, 41), 0.0, 100.0)
        modifyStat(stats, CharacterStat.STRESS, -ZombRand(10, 21) / 100.0, 0.0, 1.0)
    end
    
    return true
end

--------------------------------------------------
-- 3. HELPER FUNCTIONS
--------------------------------------------------

local function VGChasRequiredConditions(player, targetItemType, spriteMap)
    if not player then return false end

    local square = player:getSquare()
    if not square then return false end

    -- A. Power Check
    local hasPower = (allowExteriorGenerator and square:haveElectricity()) or 
                     (elecShutModifier > -1 and gameTime:getNightsSurvived() < elecShutModifier and not square:isOutside())

    if not hasPower then return false end

    local targetShortName = targetItemType
    if string.find(targetItemType, "%.") then
        targetShortName = string.match(targetItemType, "%.([^.]+)$")
    end

    -- B. Area Scan
    local cell = square:getCell()
    local startX, startY, startZ = square:getX(), square:getY(), square:getZ()

    local hasItemNearby = false
    local hasSpriteNearby = false

    for dx = -GRID_SCAN_RANGE, GRID_SCAN_RANGE do
        for dy = -GRID_SCAN_RANGE, GRID_SCAN_RANGE do
            local adjacentSquare = cell:getGridSquare(startX + dx, startY + dy, startZ)
            
            if adjacentSquare then
                
                if not hasItemNearby then
                    local worldObjects = adjacentSquare:getWorldObjects()
                    for i = 0, worldObjects:size() - 1 do
                        local obj = worldObjects:get(i)
                        if obj then 
                            local item = obj:getItem()
                            if item then
                                local foundType = item:getType()
                                if foundType == targetItemType or foundType == targetShortName then
                                    hasItemNearby = true
                                    break 
                                end
                            end
                        end
                    end
                end

                if not hasSpriteNearby then
                    local objects = adjacentSquare:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        local sprite = obj:getSprite()
                        if sprite then
                            local spriteName = sprite:getName()
                            if spriteName and spriteMap[spriteName] then
                                hasSpriteNearby = true
                                break 
                            end
                        end
                    end
                end

                if hasItemNearby and hasSpriteNearby then 
                    return true 
                end
            end
        end
    end

    return false
end

local function VGC_OnTest_CanPerform(recipe, player, item, targetItemType)
    local actualPlayer = player or getPlayer()
    if not actualPlayer then return false end
    return VGChasRequiredConditions(actualPlayer, targetItemType, tvSpriteMap)
end

--------------------------------------------------
-- 4. SPECIFIC CHECKS
--------------------------------------------------

function Video_Game_Consoles.VGC_OnTest_Atari(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "Atari") end
function Video_Game_Consoles.VGC_OnTest_SNES(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "SNES") end
function Video_Game_Consoles.VGC_OnTest_NES(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "NES") end
function Video_Game_Consoles.VGC_OnTest_Genesis(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "Genesis") or VGC_OnTest_CanPerform(recipe, player, item, "SegaCD") end
function Video_Game_Consoles.VGC_OnTest_SegaCD(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "SegaCD") end
function Video_Game_Consoles.VGC_OnTest_CD_I(recipe, player, item) return VGC_OnTest_CanPerform(recipe, player, item, "Philips_CD_I") end