--[[
    TMJukeboxContext.lua  (client)

    Right-click a world jukebox tile -> "Jukebox" option.

    On first use, the static vanilla map jukebox (sprite CustomName ==
    "Jukebox") is upgraded in place into an IsoThumpable with a real
    container (type "tm_jukebox"), keeping the same sprite.  From then on
    the loot window shows the jukebox container and media can be dropped
    straight in; the option opens the TM Jukebox control window.
]]

require "TMJukeboxDefs"
require "RadioCom/TMJukeboxWindow"

TMJukeboxContext = TMJukeboxContext or {}

------------------------------------------------------------------------
--  Conversion: vanilla tile -> container jukebox
------------------------------------------------------------------------

--- SP-ONLY direct conversion. In MP the server must create the thumpable
--- (client-created thumpables are never saved server-side: the server copy
--- has no container, media transfers roll back, and the object disappears
--- on restart). MP goes through the "tmjukebox"/"convert" server command.
function TMJukeboxContext.convert(obj)
    if TMJukebox.isConverted(obj) then return obj end
    if not TMJukebox.isVanillaJukebox(obj) then return nil end

    local square = obj:getSquare()
    local sprite = obj:getSprite() and obj:getSprite():getName() or nil
    if not square or not sprite then return nil end
    local index = obj:getObjectIndex()

    square:transmitRemoveItemFromSquare(obj)

    -- Rebuild it as a thumpable with a working container, same sprite.
    local luaItem = (ISWoodenContainer and ISWoodenContainer:new(sprite, sprite)) or {}
    local box = IsoThumpable.new(getCell(), square, sprite, false, luaItem)
    box:setIsContainer(true)
    box:setName("Jukebox")
    box:setIsDismantable(false)
    box:setCanBarricade(false)
    TMJukebox.applyContainerSettings(box)
    box:setCanBeLockByPadlock(false)
    box:setBlockAllTheSquare(true)

    if index then
        square:AddSpecialObject(box, index)
    else
        square:AddSpecialObject(box)
    end

    TMJukebox.getData(box)
    TMJukebox.transmit(box)

    square:RecalcProperties()

    return box
end

--- MP: poll for the server-created jukebox to arrive, then open the window.
local function waitForConverted(player, square, tries)
    local jb = TMJukebox.findOnSquare(square)
    if jb and TMJukebox.isConverted(jb) then
        if luautils and luautils.walkAdj then
            luautils.walkAdj(player, square, true)
        end
        TMJukeboxWindow.activate(player, jb)
        return
    end
    if tries <= 0 then return end
    local fn
    local ticks = 0
    fn = function()
        ticks = ticks + 1
        if ticks < 15 then return end   -- ~250ms between checks
        Events.OnTick.Remove(fn)
        waitForConverted(player, square, tries - 1)
    end
    Events.OnTick.Add(fn)
end

------------------------------------------------------------------------
--  Context menu
------------------------------------------------------------------------

function TMJukeboxContext.onOpen(worldobjects, player, jukeboxObj)
    if not jukeboxObj or not jukeboxObj:getSquare() then return end
    local square = jukeboxObj:getSquare()

    if TMJukebox.isConverted(jukeboxObj) then
        -- Ask the server to re-stamp accept function + capacity on its copy.
        if isClient() then
            sendClientCommand(player, "tmjukebox", "touch",
                { x = square:getX(), y = square:getY(), z = square:getZ() })
        end
        if luautils and luautils.walkAdj then
            luautils.walkAdj(player, square, true)
        end
        TMJukeboxWindow.activate(player, jukeboxObj)
        return
    end

    if isClient() then
        -- MP: server-authoritative conversion, then wait for the broadcast
        -- object to arrive before opening the window.
        sendClientCommand(player, "tmjukebox", "convert",
            { x = square:getX(), y = square:getY(), z = square:getZ() })
        waitForConverted(player, square, 12)   -- up to ~3s
        return
    end

    -- SP: direct conversion.
    local converted = TMJukeboxContext.convert(jukeboxObj)
    if not converted then return end
    if luautils and luautils.walkAdj then
        luautils.walkAdj(player, converted:getSquare(), true)
    end
    TMJukeboxWindow.activate(player, converted)
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() or player:getVehicle() then return end

    local seen = {}
    for _, o in ipairs(worldobjects) do
        local sq = o:getSquare()
        if sq and not seen[sq] then
            seen[sq] = true
            local jb = TMJukebox.findOnSquare(sq)
            if jb then
                local option = context:addOption(getText("IGUI_TM_Jukebox_Open"),
                    worldobjects, TMJukeboxContext.onOpen, player, jb)
                if option then
                    option.iconTexture = getTexture("media/ui/Container_Jukebox.png")
                end
                return
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
