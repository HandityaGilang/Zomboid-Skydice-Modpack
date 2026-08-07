PFAVirtual = PFAVirtual or {}

PFAVirtual.BarrelFuelFill = function(x, y, z)
    sendClientCommand(getSpecificPlayer(0), "PFACommands", "BarrelFuelFill", {x = x, y = y, z = z})
end

PFAVirtual.BarrelFuelSiphon = function(x, y, z)
    sendClientCommand(getSpecificPlayer(0), "PFACommands", "BarrelFuelSiphon", {x = x, y = y, z = z})
end
