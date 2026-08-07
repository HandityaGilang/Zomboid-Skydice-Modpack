--[[
    TMJukeboxServerCommands.lua  (server)

    Server-authoritative conversion of a vanilla map jukebox tile into an
    IsoThumpable container jukebox.

    WHY: in B42 MP, container thumpables only PERSIST when created on the
    server (all vanilla BuildingObjects run in server lua and use
    AddSpecialObject + transmitCompleteItemToClients). A client-created
    thumpable is never saved server-side: the server's copy has no
    container (every media transfer into it silently rolls back) and the
    object disappears on server restart.
]]

if isClient() then return end

require "TMJukeboxDefs"

local TMJukeboxCommands = {}

function TMJukeboxCommands.convert(player, args)
    if not args or not args.x or not args.y or not args.z then return end
    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if not square then return end

    -- Find the jukebox object on the square.
    local target, index = nil, nil
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if TMJukebox.isConverted(o) then
            -- Already converted (another player raced us) - just re-apply
            -- settings and re-sync.
            TMJukebox.applyContainerSettings(o)
            o:transmitCompleteItemToClients()
            return
        end
        if TMJukebox.isVanillaJukebox(o) then
            target = o
            index = i
        end
    end
    if not target then return end

    local sprite = target:getSprite() and target:getSprite():getName() or nil
    if not sprite then return end

    -- Remove the static vanilla tile (server-side removal broadcasts).
    square:transmitRemoveItemFromSquare(target)

    -- Rebuild as a thumpable container, vanilla ISWoodenContainer pattern
    -- (server lua, so ISWoodenContainer is in scope).
    local luaItem = (ISWoodenContainer and ISWoodenContainer:new(sprite, sprite)) or {}
    local box = IsoThumpable.new(getCell(), square, sprite, false, luaItem)
    box:setIsContainer(true)
    box:setName("Jukebox")
    box:setIsDismantable(false)
    box:setCanBarricade(false)
    TMJukebox.applyContainerSettings(box)
    box:setCanBeLockByPadlock(false)
    box:setBlockAllTheSquare(true)
    box:setMaxHealth(500)
    box:setHealth(box:getMaxHealth())

    if index then
        square:AddSpecialObject(box, index)
    else
        square:AddSpecialObject(box)
    end
    box:transmitCompleteItemToClients()

    TMJukebox.getData(box)
    TMJukebox.transmit(box)

    square:RecalcProperties()
    square:RecalcAllWithNeighbours(true)
end

-- Re-apply container settings on an already-converted jukebox (accept
-- function name + capacity are re-stamped server-side after load).
function TMJukeboxCommands.touch(player, args)
    if not args or not args.x or not args.y or not args.z then return end
    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if not square then return end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if TMJukebox.isConverted(o) then
            TMJukebox.applyContainerSettings(o)
            return
        end
    end
end

local function onClientCommand(module, command, player, args)
    if module == "tmjukebox" and TMJukeboxCommands[command] then
        TMJukeboxCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
