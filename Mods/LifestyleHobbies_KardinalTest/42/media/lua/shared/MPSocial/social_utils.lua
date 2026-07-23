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

LSMPS = LSMPS or {}

LSMPS.getOrCreatePersonalInfo = function(character)
    local charData = character:getModData()
    if charData.LSSocial then return charData.LSSocial; end
    charData.LSSocial = {}
    -- id
    local id = character:getSteamID() or character:getUsername()
    charData.LSSocial.id = id
    -- hidden skills
    if not charData.LSHiddenSkills then -- initialise hs table
        HiddenSkills.getSkill(character, "Yoga")
    end
    charData.LSSocial.hs = charData.LSHiddenSkills
    LSSync.updateClientData(character, charData)
    return charData.LSSocial
end

LSMPS.getPlayersNearby = function(area, x, y, exclude)
    local players = getOnlinePlayers()
    if players then
        local nearbyPlayers = {}
        for i=1,players:size() do
            local player = players:get(i-1)
            if player and (not player.isAnimal or not player:isAnimal()) then
                local id = player.getOnlineID and player:getOnlineID()
                if id and id ~= exclude then
                    local pX, pY = player:getX(), player:getY()
                    if pX >= x-area and pX < x+area and pY >= y-area and pY < y+area then
                        table.insert(nearbyPlayers, player)
                    end
                end
            end
        end
        return nearbyPlayers
    end
    return false
end

--[[
function ScanForPlayers(command, args)
    if not command or not args then return; end
    if type(args) ~= "table" then return; end
    local playerObj = getPlayer()
    local players = getOnlinePlayers();
    if players then
        for i=1,players:size() do
            local player = players:get(i-1)
            if player and player ~= playerObj and (not player.isAnimal or not player:isAnimal()) then
                if player:getX() >= playerObj:getX() - 30 and player:getX() < playerObj:getX() + 30 and
                   player:getY() >= playerObj:getY() - 30 and player:getY() < playerObj:getY() + 30 then
                    sendClientCommand(playerObj, "LSK", command, {player:getOnlineID(), playerObj:getDisplayName(), args})
                end
            end
        end
    end
end
]]--