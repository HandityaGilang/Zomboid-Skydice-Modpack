if isClient() then return end
require 'Spectate/ShSpectate'

function Spectate.OnClientCommand(mod, command, player, args)
    if Spectate.Verbose then print("Spectate.OnClientCommand("..mod..", "..command..", "..tostring(player or "nil")..', '..tab2str(args)) end
    if mod ~= Spectate.ModId then return end

    if command == Spectate.CmdSpectate then
        if Spectate.Verbose then print('Spectate server GMD: set spectate '..p2str(player)..' '..tostring(args.spectate and 'true' or 'false')..' '..tab2str(args)) end
        --add to ModData and share with everyone
        local md = ModData.getOrCreate(Spectate.MDKey)
        
        local playerKey = Spectate.getIsoPlayerKey(player)
        if playerKey then
            if not md[playerKey] or md[playerKey] ~= args.spectate then
                md[playerKey] = args.spectate--set
                ModData.transmit(Spectate.MDKey);--share
                if Spectate.Verbose then print('Spectate server GMD: Transmitted '..p2str(player)..' '..tostring(args.spectate and 'true' or 'false')..' '..tab2str(args)) end
            else
                print('Spectate server GMD: WARNING spectate order repetition. waste of network ressources '..p2str(player)..' '..tostring(args.spectate and 'true' or 'false')..' '..tab2str(args))
            end
        else
            print('Spectate server GMD: ERROR spectate order with invalid player '..p2str(player)..' '..tostring(args.spectate and 'true' or 'false')..' '..tab2str(args))
        end
    end
end

Events.OnClientCommand.Add(Spectate.OnClientCommand);


--we use Global Mod Data to save and load, let's log it at load time for debug
function Spectate.OnInitGlobalModData()
    ModData.getOrCreate(Spectate.MDKey)--create for valid register of clients
    if Spectate.Verbose then print ("Spectate.OnInitGlobalModData "..tab2str(ModData.getOrCreate(Spectate.MDKey))) end
end

Events.OnInitGlobalModData.Add(Spectate.OnInitGlobalModData)--this is used in solo
