--------------------------------------------------------------------------------------------------
--        ----      |              |            |         |                |    --    |      ----            --
--        ----      |              |            |         |                |    --       |      ----            --
--        ----      |        -------       -----|     ---------        -----          -      ----       -------
--        ----      |            ---            |         -----        ------        --      ----            --
--        ----      |            ---            |         -----        -------          ---      ----            --
--        ----      |        -------       ----------     -----        -------         ---      ----       -------
--            |      |        -------            |         -----        -------         ---          |            --
--            |      |        -------            |          -----        -------         ---          |            --
--------------------------------------------------------------------------------------------------

require('NPCs/MainCreationMethods');
require "LifestyleCore/LSK_NetSchema"
require "LifestyleCore/LSK_PersistenceClient"
require "LifestyleCore/LSK_Scheduler"

--
local musicStyles = {"disco","beach","classical","country","holiday","jazz","metal","muzak","pop","rap","rbsoul","reggae","rock","salsa","world"}
local musicStylesDislike = {"discono","beachno","classicalno","countryno","holidayno","jazzno","metalno","muzakno","popno","rapno","rbsoulno","reggaeno","rockno","salsano","worldno"}
-- new game
local function initPlayerTracker(_player)
    local player = _player
    --PlayTracker
    player:getModData().PlayTracker = {}
    --HaloCooldownCounter
    if not (player:getModData().HaloCooldownCounter) or (not (tonumber(player:getModData().HaloCooldownCounter))) then player:getModData().HaloCooldownCounter = 0; end
    --PlayerVoice
    if not (not player:getModData().PlayerVoice) or (not (tonumber(player:getModData().PlayerVoice))) then player:getModData().PlayerVoice = ZombRand(5); end
end

local function checkInventingRecipes(ogPlayer)
    local skillLevel = HiddenSkills.getLevel(ogPlayer, "Inventing")
    if not skillLevel or skillLevel < 9 then return; end
    local recipes = {"ConvertPartsMech","ConvertPartsElec","ConvertPartsPlumb","ConvertPartsWood"}
    for n=1,#recipes do
        local recipe = recipes[n]
        if not ogPlayer:isRecipeActuallyKnown(recipe) then
            LSUtil.learnRecipes(ogPlayer, recipes)
            break
        end
    end
end

local function resolveMusicTrait(styleName)
    if type(styleName) ~= "string" or styleName == "" or not CharacterTrait then
        return nil, nil
    end
    if LSK_NetSchema and LSK_NetSchema.resolveChangeTrait then
        return LSK_NetSchema.resolveChangeTrait(styleName)
    end
    if CharacterTrait[styleName] then
        return CharacterTrait[styleName], styleName
    end
    local upper = string.upper(styleName)
    if CharacterTrait[upper] then
        return CharacterTrait[upper], upper
    end
    local lower = string.lower(styleName)
    if CharacterTrait[lower] then
        return CharacterTrait[lower], lower
    end
    return nil, nil
end

local function playerHasMusicTrait(player, styleName)
    local traitObj = resolveMusicTrait(styleName)
    return traitObj ~= nil and player:hasTrait(traitObj)
end

local function addMusicTrait(player, styleName, haloGreen)
    local traitObj, traitKey = resolveMusicTrait(styleName)
    if not traitObj or not traitKey then
        return false
    end
    if player:hasTrait(traitObj) then
        return true
    end
    if isClient() then
        sendClientCommand(player, "LSK", "ChangeTrait", {traitKey, "add"})
    else
        player:getCharacterTraits():add(traitObj)
        player:modifyTraitXPBoost(traitObj, false)
        SyncXp(player)
    end
    local color = haloGreen and HaloTextHelper.getColorGreen() or HaloTextHelper.getColorRed()
    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_" .. styleName), true, color)
    return true
end

local function findOwnedMusicStyle(player, styleList)
    for i = 1, #styleList do
        if playerHasMusicTrait(player, styleList[i]) then
            return styleList[i]
        end
    end
    return nil
end

local function pickMusicStyle(styleList, conflictStyle)
    local idx = ZombRand(#styleList) + 1
    local picked = styleList[idx]
    if conflictStyle and string.find(picked, conflictStyle) then
        for _ = 1, 20 do
            local newIdx = ZombRand(#styleList) + 1
            picked = styleList[newIdx]
            if not string.find(picked, conflictStyle) then
                break
            end
        end
    end
    return picked
end

local function checkMusicTraits(ogPlayer)
    local player = ogPlayer or LSUtil.getValidCharacter(getPlayer())
    if not player then return; end
    local playerData = player:getModData()

    if player:hasTrait(CharacterTrait.DEAF) or player:hasTrait(CharacterTrait.TONEDEAF) then
        return
    end

    local likeStyle = playerData.PlayerMusicLike
    local dislikeStyle = playerData.PlayerMusicDislike

    if likeStyle and dislikeStyle
        and playerHasMusicTrait(player, likeStyle)
        and playerHasMusicTrait(player, dislikeStyle) then
        return
    end

    -- Keep saved tastes if present; only roll when missing. Re-request ChangeTrait if halo showed but server rejected.
    if not likeStyle then
        likeStyle = findOwnedMusicStyle(player, musicStyles)
    end
    if not dislikeStyle then
        dislikeStyle = findOwnedMusicStyle(player, musicStylesDislike)
    end

    if not likeStyle then
        likeStyle = pickMusicStyle(musicStyles, dislikeStyle)
    end
    if not dislikeStyle then
        dislikeStyle = pickMusicStyle(musicStylesDislike, likeStyle)
    end

    if not playerHasMusicTrait(player, likeStyle) then
        addMusicTrait(player, likeStyle, true)
    end
    playerData.PlayerMusicLike = likeStyle

    if not playerHasMusicTrait(player, dislikeStyle) then
        addMusicTrait(player, dislikeStyle, false)
    end
    playerData.PlayerMusicDislike = dislikeStyle
end

local waitForCommands
local count, countTotal = 0, 5
waitForCommands = function()
    count = count+1
    if count > countTotal then
        countTotal = 1000
        LSKScheduler.remove("player-tracker-init")
        local player = LSUtil.getValidCharacter(getPlayer())
        if player then
            checkMusicTraits(player)
            LifestyleSecure.PersistenceClient.flush(player)
        end
    end
end

-- we use this to enable any data that might not exist
local function LScheckPlayerTracker()
    if isServer() and not isClient() then return; end
    local entries = {
    ['REMOVE'] = {'LSZenActive','IsMeditating','cleaningETime','hygieneNeedETime','ActiveDiscoBallNearby','IsListeningToJukebox','PlayingDJBooth','IsDancingInit','IsDancingFull','IsDancingFullPartner',
    'WantsToDance','IsSittingOnSeat','IsSittingOnPianoStool','IsSittingOnSeatSouth','IsDoingToilet','TDcomplained','GaveApplause','PlayingInstrument','IsMeditationDisturbed','IsDoingShower','DJNotFailstate',
    'DJBoothOverlayPanel','DJBoothCustomLoopPlaying','DJBoothCustomLoop','IsListeningToDJ','DJKEYLEFTRIGHT','DJKEYUP','DJKEYDOWN','DJBoothSwitchAPressed','DJBoothSwitchBPressed','DJBoothSwitchCPressed',
    'DJBoothSwitchDPressed','DJBoothSwitchBAPressed','VynilAScratched','VynilBScratched','DJBoothSmallButtonAPressed','DJBoothSmallButtonBPressed','DJBoothSmallButtonCPressed','DJBoothSmallButtonDPressed',
    'DJBoothSmallButtonEPressed','DJBoothSmallButtonFPressed','DJBoothSmallButtonGPressed','DJBoothSmallButtonHPressed','DJBoothSmallButtonIPressed','DJBoothSmallButtonJPressed','DJBoothSmallButtonKPressed',
    'DJBoothSmallButtonLPressed','DJBoothSmallButtonMPressed','DJBoothSmallButtonNPressed','DJBoothSmallButtonOPressed','DJBoothSmallButtonPPressed','DJBoothBigButtonAPressed','DJBoothBigButtonBPressed',
    'DJBoothBigButtonCPressed','DJBoothBigButtonDPressed','DJBoothBigButtonEPressed','DJBoothBigButtonFPressed','DJBoothBigButtonGPressed','DJBoothBigButtonHPressed','DJBoothBigButton1Pressed',
    'DJBoothBigButton2Pressed','DJBoothBigButton3Pressed','DJBoothBigButton4Pressed','DJBoothBigButton5Pressed','DJBoothBigButton6Pressed','DJBoothBigButton7Pressed','DJBoothBigButton8Pressed'},
    ['FLOAT'] = {'VanillaMusicResume','OtherPlayersAroundDancing','DJBoothCustomLoopKeyPressed','DJBoothCustomLoopActive','DJKEY','VynilAScratchedTimes','VynilBScratchedTimes','DJBoothBigButtonRGB',
    'DJBoothBigButtonAPressedCount','DJBoothBigButtonBPressedCount','DJBoothBigButtonCPressedCount','DJBoothBigButtonDPressedCount','DJBoothBigButtonEPressedCount','DJBoothBigButtonFPressedCount',
    'DJBoothBigButtonGPressedCount','DJBoothBigButtonHPressedCount','DJBoothBigButton1PressedCount','DJBoothBigButton2PressedCount','DJBoothBigButton3PressedCount','DJBoothBigButton4PressedCount',
    'DJBoothBigButton5PressedCount','DJBoothBigButton6PressedCount','DJBoothBigButton7PressedCount','DJBoothBigButton8PressedCount'},
    ['TABLE'] = {'PlayTracker'},
    ['CUSTOM'] = {{'ListenedToMusic',-1,true},{'hygieneNeedLimit',100,true}},
    ['CUSTOMTONUM'] = {{'HaloCooldownCounter',0,false},{'PlayerVoice',ZombRand(5),false}},
    }
    if isClient() then ModData.request("LSDATA"); end

    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player and player:hasModData() and not player:isDead() then
            local data = player:getModData()
            if SandboxVars.Text.DividerMusicNew then InstrumentsUtilOnCreatePlayer(player); end
            for k, v in pairs(entries) do
                for n=1, #v do
                    local entry = v[n]
                    if k == "REMOVE" then
                        if data[entry] then data[entry] = nil; end
                    elseif k == "FLOAT" then
                        data[entry] = 0
                    elseif k == "TABLE" then
                        if not data[entry] then data[entry] = {}; end
                    elseif k == "CUSTOM" then
                        if entry[3] or not data[entry[1]] then data[entry[1]] = entry[2]; end
                    elseif k == "CUSTOMTONUM" then
                        if not data[entry[1]] or not tonumber(data[entry[1]]) then data[entry[1]] = entry[2]; end
                    end
                end
            end
        end
    end
    if isClient() then
        LSKScheduler.register("player-tracker-init", LSKScheduler.LANES.FAST, waitForCommands)
    else
        checkMusicTraits(nil)
    end
end

--By hour
local function updatePlayerTrackerByHour()
    local player = getPlayer()
    local playerData = player:getModData()

    --PlayTracker
    -- we add this loop and update at each hour to reset the contents stored in PlayTracker if it's more than 12 hours old, adding 1 hour if not
    if player:hasModData()
        and player:getModData().PlayTracker ~= nil then
    local n = #playerData.PlayTracker

    for i = n,1,-1 do
        if playerData.PlayTracker[i].hoursSince > 12 then
            table.remove(playerData.PlayTracker,i)
        else
            playerData.PlayTracker[i].hoursSince = playerData.PlayTracker[i].hoursSince + 1
        end
    end
    else
        player:getModData().PlayTracker = {}
    end
end


--By minute
local function updatePlayerTrackerByMinute()
    local player = getPlayer()
    local playerData = player:getModData()

    --HaloCooldownCounter
    -- we add this loop and update at each minute to reset the contents stored in HaloCooldownCounter if it's more than 5 minutes, adding 1 if not
    if player:hasModData()
        and player:getModData().HaloCooldownCounter ~= nil
        and tonumber(player:getModData().HaloCooldownCounter) ~= nil
    then
        if playerData.HaloCooldownCounter > 5 then
            playerData.HaloCooldownCounter = 0
        else
            playerData.HaloCooldownCounter = playerData.HaloCooldownCounter + 1
        end
    else
        player:getModData().HaloCooldownCounter = 0
    end
    --check if player has voice, needed in case something breaks midgame
    if (not player:getModData().PlayerVoice) or (not (tonumber(player:getModData().PlayerVoice))) then player:getModData().PlayerVoice = ZombRand(5); end
        
end

Events.OnNewGame.Add(initPlayerTracker)
Events.OnCreatePlayer.Add(LScheckPlayerTracker)
Events.EveryHours.Add(updatePlayerTrackerByHour)
Events.EveryOneMinute.Add(updatePlayerTrackerByMinute)