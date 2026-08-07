-- CrazyCatPersonTraitSwapper = {}

--[[
local function swapCrazyCatPersonTraits(playerObj)
    if not playerObj then 
        print("[CATTOWO] TraitSwapper: Player object is nil")
        return 
    end
    
    local profession = playerObj:getDescriptor():getProfession()
    print("[CATTOWO] TraitSwapper: Player profession is: " .. tostring(profession))
    
    if not profession or profession ~= "crazycatperson" then 
        return 
    end
    
    local traits = playerObj:getTraits()
    if not traits then 
        print("[CATTOWO] TraitSwapper: Traits collection is nil")
        return 
    end
    
    print("[CATTOWO] TraitSwapper: Checking for CrazyCatPersonCatEyes trait...")
    
    if traits:contains("CrazyCatPersonCatEyes") then
        print("[CATTOWO] Swapping CrazyCatPersonCatEyes for vanilla NightVision for player: " .. playerObj:getDescriptor():getForename())
        
        traits:remove("CrazyCatPersonCatEyes")
        traits:add("NightVision")
        
        playerObj:setNightVision(true)
        
        print("[CATTOWO] Trait swap completed successfully - NightVision should now be active")
    else
        print("[CATTOWO] TraitSwapper: CrazyCatPersonCatEyes trait not found in player traits")
    end
end

local function onCreatePlayer(playerNum, playerObj)
    if playerObj then
        swapCrazyCatPersonTraits(playerObj)
    end
end

local function onNewGame()
    local players = getNumActivePlayers()
    for i = 0, players - 1 do
        local playerObj = getSpecificPlayer(i)
        if playerObj then
            swapCrazyCatPersonTraits(playerObj)
        end
    end
end

local function onGameStart()
    local players = getNumActivePlayers()
    for i = 0, players - 1 do
        local playerObj = getSpecificPlayer(i)
        if playerObj then
            swapCrazyCatPersonTraits(playerObj)
        end
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnNewGame.Add(onNewGame)
Events.OnGameStart.Add(onGameStart)
--]]