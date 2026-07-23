
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

if not isServer() then return end

local function OnClientCommand_LMN_Player(module, command, player, args)
    if module ~= "LMN_Player" then return end
    
    if command == "SaveDontShow" then
        local pData = player:getModData()
        pData.LMN_dontShowNotes = pData.LMN_dontShowNotes or {}
        pData.LMN_dontShowNotes[args.noteId] = true
    end
end

Events.OnClientCommand.Add(OnClientCommand_LMN_Player)