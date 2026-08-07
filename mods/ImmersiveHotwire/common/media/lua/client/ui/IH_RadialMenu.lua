ISVehicleMenu._IH_originalShowRadialMenu = ISVehicleMenu._IH_originalShowRadialMenu or ISVehicleMenu.showRadialMenu
local originalShowRadialMenu = ISVehicleMenu._IH_originalShowRadialMenu
local HotwireWindow = require "ui/IH_HotwireWindow"

if ISVehicleMenu._IH_isWrapped then
    return
end
ISVehicleMenu._IH_isWrapped = true

local function containsHotwireText(txt)
    local t = tostring(txt):lower()
    return t:find("hotwire", 1, true) ~= nil
end

local function isVanillaOrLockedHotwireSlice(slice, playerObj)
    if slice.IH == true then return false end

    local txt = slice.text
    local cmd = slice.command

    local cmd1 = nil
    local cmd2 = nil
    if type(cmd) == "table" then
        cmd1 = cmd[1]
        cmd2 = cmd[2]
    end

    if cmd1 == ISVehicleMenu.onHotwire then
        return true
    end

    if cmd1 == nil and cmd2 == playerObj then
        local hotwireSkillText = getText("ContextMenu_VehicleHotwireSkill")
        if txt == hotwireSkillText then
            return true
        end
        if containsHotwireText(txt) then
            return true
        end
    end

    if containsHotwireText(txt) then
        return true
    end

    return false
end

local function addSlicePreservingCommand(menu, snap)
    menu:addSlice(snap.text, snap.texture)
    menu.slices[#menu.slices].command = snap.command
end

local function addIHHotwire(menu, playerObj)
    if not playerObj then return end

    local vehicle = playerObj:getVehicle()
    if not vehicle then

        return
    end

    local seat = vehicle:getSeat(playerObj)
    if seat ~= 0 then
        return
    end

    if vehicle.isHotwired and vehicle:isHotwired() then
        return
    end

    if vehicle.isKeysInIgnition and vehicle:isKeysInIgnition() then
        return
    end

    local inv = playerObj.getInventory and playerObj:getInventory() or nil
    if inv and inv.haveThisKeyId and vehicle.getKeyId then
        local keyId = vehicle:getKeyId()
        if keyId and inv:haveThisKeyId(keyId) then
            return
        end
    end

    local myText = getText("ContextMenu_VehicleHotwire")
    local myTex  = getTexture("media/ui/vehicles/vehicle_hotwire.png")

    menu:addSlice(myText, myTex)
    local s = menu.slices[#menu.slices]
    s.IH = true
    s.command = { HotwireWindow.showHotwireWindow, playerObj }
end

ISVehicleMenu.showRadialMenu = function(playerObj)
    originalShowRadialMenu(playerObj)

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    if not menu or not menu.slices then return end

    local snapshot = {}
    for _, s in ipairs(menu.slices) do
        snapshot[#snapshot + 1] = {
            text    = s.text,
            texture = s.texture,
            command = s.command,
            IH    = s.IH == true,
        }
    end

    menu:clear()

    local hotwireAdded = false
    for _, snap in ipairs(snapshot) do
        if not snap.IH then
            local pseudo = { text = snap.text, command = snap.command, IH = false }
            local isHotwire = isVanillaOrLockedHotwireSlice(pseudo, playerObj)
            if isHotwire then
                if not hotwireAdded then
                    addIHHotwire(menu, playerObj)
                    hotwireAdded = true
                end
            else
                addSlicePreservingCommand(menu, snap)
            end
        end
    end

    if not hotwireAdded then
        addIHHotwire(menu, playerObj)
    end

    menu:center()
end
