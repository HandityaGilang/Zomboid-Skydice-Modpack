
AutoTailoring = AutoTailoring or {}
AutoTailoring.nbHolesForMoodle = 0;
AutoTailoring.displayDelayForMoodle = 15000;--show for 15 seconds
AutoTailoring.hideTimeForMoodle = {};--internal time memo for local players

function AutoTailoring.isModEnabled(modname)
    local actmods = getActivatedMods();
    for i=0, actmods:size()-1, 1 do
        if actmods:get(i) == modname then
            return true;
        end
    end
    return false;
end
local modInfoMF = getModInfoByID("\\MoodleFramework")
AutoTailoring.isMoodleFrameworkEnabled = modInfoMF and isModActive(modInfoMF)
--print ("Load AutoTailoring.updateClothingHoleMoodle "..tostring(AutoTailoring.isMoodleFrameworkEnabled).." "..tostring(modInfoMF));
if AutoTailoring.isMoodleFrameworkEnabled then
    require "MF_ISMoodle"

    --Moodle creation, replace Proteins by your own moodle name.
    MF.createMoodle("ClothingHole");

    function AutoTailoring.updateClothingHoleMoodle(player)
        if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring.updateClothingHoleMoodle "..tostring(player)); end
        if player then--some clothing change occured on local player
            local nbHoles = 0
            for j = 0, player:getWornItems():size()-1 do
                local clothingItem = player:getWornItems():get(j):getItem();
                if instanceof(clothingItem, "Clothing") then
                    --if AutoTailoring.OPTIONS.Verbose then print ("updateClothingHoleMoodle cloth = "..clothingItem:getFullType()); end
                    nbHoles = nbHoles + clothingItem:getHolesNumber();
                end
            end
            
            if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring.updateClothingHoleMoodle "..tostring(nbHoles)); end
            if AutoTailoring.nbHolesForMoodle ~= nbHoles then--on change
                local playerNum = player:getPlayerNum()
                local moodle = MF.getMoodle("ClothingHole",playerNum);--get access to the moodle
                if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring.updateClothingHoleMoodle "..tostring(playerNum).." "..tostring(moodle)); end
                if moodle then
                    if nbHoles > 0 then
                        moodle:setValue(0.3);--update has holes
                        moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), getText("Moodles_ClothingHole_Custom",tostring(nbHoles)));--update description
                    else
                        moodle:setValue(0.7);--update has no more holes
                        moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), "");--remove description
                    end
                    moodle:doWiggle();--force wiggling
                    AutoTailoring.nbHolesForMoodle = nbHoles;--memo for on change detection
                    AutoTailoring.manageTransientMoodle(moodle,playerNum);
                end
            end
        end
    end

    function AutoTailoring.manageTransientMoodle(moodle,playerNum)
        local reconnectEvent = #AutoTailoring.hideTimeForMoodle == 0;
        
        AutoTailoring.hideTimeForMoodle[playerNum] = getTimestampMs()+AutoTailoring.displayDelayForMoodle;--set end time
        
        if reconnectEvent then
            Events.OnPlayerUpdate.Add(AutoTailoring.updatePlayerMoodle)
        end
    end
    
    Events.OnClothingUpdated.Add(AutoTailoring.updateClothingHoleMoodle)


    function AutoTailoring.updatePlayerMoodle(player)--manage the time to display only temporarily
        local playerNum = player:getPlayerNum()
        local htfm = AutoTailoring.hideTimeForMoodle[playerNum]
        if htfm and getTimestampMs() > htfm then
            local moodle = MF.getMoodle("ClothingHole",playerNum);--get access to the moodle
            if moodle then
                moodle:setValue(0.5)--hide
            end
            AutoTailoring.hideTimeForMoodle[playerNum] = nil;
            
            if #AutoTailoring.hideTimeForMoodle == 0 then
                Events.OnPlayerUpdate.Remove(AutoTailoring.updatePlayerMoodle)--disconnect
            end
        end
    end
end
