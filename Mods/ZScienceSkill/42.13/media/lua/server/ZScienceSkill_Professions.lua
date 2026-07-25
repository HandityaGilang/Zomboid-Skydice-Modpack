-- Applies profPreResearchedSpecimens[profId] for the player's profession on new game / game start.
-- Data is registered by integration data files (e.g. ZScienceSkill/data/ResearchLabInternProfession.lua).
local function getProfessionId(player)
    if not player or not player.getDescriptor then return nil end
    local prof = player:getDescriptor():getCharacterProfession()
    return tostring(prof)
end

local function applyPreResearchedSpecimens(player)
    local profId = getProfessionId(player)
    if not profId then return end

    local pzsData = ZScienceSkill.getPlayerZSData(player)
    pzsData.profPreResearched = pzsData.profPreResearched or {}

    if not pzsData.profPreResearched[profId] then
        local keys = ZScienceSkill.Data.profPreResearchedSpecimens and ZScienceSkill.Data.profPreResearchedSpecimens[profId]
        if not keys or #keys == 0 then return end

        for _, key in ipairs(keys) do
            ZScienceSkill.setResearched(player, key)
        end
        pzsData.profPreResearched[profId] = true
        player:transmitModData()
    end
end

local function onCreatePlayer(playerNum, playerObj)
    if not playerObj then return end

    applyPreResearchedSpecimens(playerObj)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
