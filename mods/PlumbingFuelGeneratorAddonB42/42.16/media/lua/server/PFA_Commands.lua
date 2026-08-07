require "WPUtils"
require "PFA_GMD"

PFAServer = {}
PFAServer.Commands = {}

local FUEL_BARREL_MAX = 100.0
local FILL_CHUNK = 25.0

-- Barrels are tracked entirely in our own mod data (never WPModData.Barrels),
-- so this never touches the base mod's real fluid-container sync.
PFAServer.Commands.BarrelFuelFill = function(player, args)
    local pgmd = GetPFAModData()
    local coordId = WPUtils.Coords2Id(args.x, args.y, args.z)

    local flowing = pgmd.FuelPipes[coordId]
    if not flowing or flowing <= 0 then return end

    local barrel = pgmd.FuelBarrels[coordId]
    if not barrel then
        barrel = {x = args.x, y = args.y, z = args.z, amount = 0, max = FUEL_BARREL_MAX}
        pgmd.FuelBarrels[coordId] = barrel
    end

    local room = barrel.max - barrel.amount
    if room <= 0 then return end

    barrel.amount = barrel.amount + math.min(FILL_CHUNK, room)
end

local function isFuelCanNotFull(item)
    return (item:hasTag("Petrol") or item:getType() == "PetrolCan") and item:getUsedDelta() < 1
end

PFAServer.Commands.BarrelFuelSiphon = function(player, args)
    local pgmd = GetPFAModData()
    local coordId = WPUtils.Coords2Id(args.x, args.y, args.z)

    local barrel = pgmd.FuelBarrels[coordId]
    if not barrel or barrel.amount <= 0 then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    -- re-find the can server-side rather than trusting a client-passed item
    -- reference, mirroring vanilla's own predicatePetrolNotFull lookup pattern
    local item = playerObj:getInventory():getFirstEvalRecurse(isFuelCanNotFull)
    if not item then return end

    local roomFraction = 1.0 - item:getUsedDelta()
    if roomFraction <= 0 then return end

    local transfer = math.min(barrel.amount, roomFraction * 100)
    item:setUsedDelta(item:getUsedDelta() + transfer / 100)
    item:transmitModData()

    barrel.amount = barrel.amount - transfer
end

local function onClientCommand(mod, command, player, args)
    if mod == "PFACommands" and PFAServer.Commands[command] then
        PFAServer.Commands[command](player, args)
        TransmitPFAModData()
    end
end

Events.OnClientCommand.Add(onClientCommand)
