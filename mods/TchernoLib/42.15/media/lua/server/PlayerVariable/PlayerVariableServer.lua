if isClient() then return end
require 'PlayerVariable/PlayerVariableShared'

function PlaVar.OnClientCommand(mod, command, player, args)
    if PlaVar.Verbose then print("PlaVar.OnClientCommand("..mod..", "..command..", "..tostring(player or "nil")..', '..tab2str(args)) end
    if mod ~= PlaVar.ModId then return end

    if PlaVar.Verbose then print('PlaVar server GMD: set '..command..' '..p2str(player)..' '..tostring(args[command] and 'true' or 'false')..' '..tab2str(args)) end
    --add to ModData and share with everyone
    local md = ModData.getOrCreate(PlaVar.MDKey)
    
    local playerKey = PlaVar.getIsoPlayerKey(player)
    if playerKey then
        local pmd = md[playerKey]
        if not pmd or pmd ~= args[command] then
            if not pmd then md[playerKey] = {}; pmd = md[playerKey] end
            pmd[command] = args[command]--set
            ModData.transmit(PlaVar.MDKey);--share
            PlaVar.setPlayerFlag(player, command, args[command])--update serverside player flag (for server-sided controlled Zs)
            if PlaVar.Verbose then print('PlaVar server GMD: Transmitted '..p2str(player)..' '..tostring(args[command] and 'true' or 'false')..' '..tab2str(args)) end
        else
            print('PlaVar server GMD: WARNING '..command..' order repetition. waste of network ressources '..p2str(player)..' '..tostring(args[command] and 'true' or 'false')..' '..tab2str(args))
        end
    else
        print('PlaVar server GMD: ERROR '..command..' order with invalid player '..p2str(player)..' '..tostring(args[command] and 'true' or 'false')..' '..tab2str(args))
    end
end

Events.OnClientCommand.Add(PlaVar.OnClientCommand);

--we use Global Mod Data to save and load, let's log it at load time for debug
function PlaVar.OnInitGlobalModData()
    ModData.getOrCreate(PlaVar.MDKey)--create for valid register of clients
    if PlaVar.Verbose then print ("PlaVar.OnInitGlobalModData "..tab2str(ModData.getOrCreate(PlaVar.MDKey))) end
end

Events.OnInitGlobalModData.Add(PlaVar.OnInitGlobalModData)--this is used in solo
