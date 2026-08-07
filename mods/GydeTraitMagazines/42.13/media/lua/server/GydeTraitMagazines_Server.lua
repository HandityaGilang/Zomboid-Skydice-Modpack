require "GydeTraitMagazines_Shared"

local function onClientCommand(module, command, player, args)
    if module ~= "GydeTraitMags" then return end
    if command ~= "ApplyMagazine" then return end

    print("[GTM] ApplyMagazine received on server.")

    GydeTraitMags.applyMagazineTraits(player, args.magazineType)
end

Events.OnClientCommand.Add(onClientCommand)