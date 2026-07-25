-- Spec helper functions for ZScienceSkill tests
-- Functions declared without 'local' so they're written to the request-scoped
-- shared environment (not _G). This allows spec files to access them without
-- polluting the global namespace.

---------------------------------------------

-- it's now set in ZBSpec_client_SP.lua and servertest.ini
-- set_sandbox_option("DayNightCycle", 2) -- Endless Day

if not isServer() then
    ZBSpec.wait_for_not(ISTimedActionQueue.isPlayerDoingAction, get_player())
    -- ZBSpec.wait_for_not(get_player().tooDarkToRead, get_player())
end

-- for skillbooks
function reset_pages(player, book)
    ZBSpec.all_exec("(getPlayer() or getOnlinePlayers():get(0)):setAlreadyReadPages(\"" .. book:getFullType() .. "\", 0)")
end

-- Place a microscope on the player's square (for testing research)
function place_microscope(player)
    local sq = player:getSquare()
    if not sq then return nil end
    
    -- Check if microscope already exists on square
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if obj and obj.getProperties and obj:getProperties():get("CustomName") == "Microscope" then
            return obj
        end
    end
    
    return place_tile(sq, "location_community_medical_01_139")
end

-- Perform research on a specimen
function research_specimen(player, item)
    if isServer() then
        local fullType = ZScienceSkill.getItemFullType(item)
        if fullType then
            ZScienceSkill.setResearched(player, fullType)
        else
            error("Item does not have a valid full type for research: " .. tostring(item))
        end
    else
        ISTimedActionQueue.add(ISResearchSpecimen:new(player, item, 100))
        ZBSpec.wait_for_not(ISTimedActionQueue.isPlayerDoingAction, player)
    end
end

-- Clear player's research data
function clear_research_data()
    ZBSpec.all_exec("table.wipe( ZScienceSkill.getPlayerZSData( getPlayer() or getOnlinePlayers():get(0) ))")
end
