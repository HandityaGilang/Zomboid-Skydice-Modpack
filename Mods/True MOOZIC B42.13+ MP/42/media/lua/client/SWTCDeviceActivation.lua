require "RadioCom/SWTCPlayerWindow"

if not SWTCCDAlbums then
    SWTCCDAlbums = {}
end

local function loadSWTCAlbums()
    pcall(function()
        require "SWTCAlbumsLoader"
    end)
end

loadSWTCAlbums()

if not CustomCDMusic then CustomCDMusic = {} end
if not CustomCDMusic.CustomDevices then CustomCDMusic.CustomDevices = {} end

CustomCDMusic.CustomDevices["Base.CDplayer"] = true
CustomCDMusic.CustomDevices["Base.StarWalkman"] = true
CustomCDMusic.CustomDevices["TM_CDTEST.TM_CDPlayer"] = true
CustomCDMusic.CustomDevices["Tsarcraft.CDplayer"] = true
CustomCDMusic.CustomDevices["TrueMoozic.CDplayer"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Blue"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Purple"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Red"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Black"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Green"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_Orange"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_White"] = true
CustomCDMusic.CustomDevices["Tsarcraft.TM_CDPlayer_TrueMoozic"] = true

local originalISRadioWindowActivate = ISRadioWindow.activate

function ISRadioWindow.activate(_player, _item, bol)
    if _player == getPlayer() then
        if instanceof(_item, "Radio") then
            if CustomCDMusic.CustomDevices[_item:getFullType()] then
                SWTCPlayerWindow.activate(_player, _item)
            else
                originalISRadioWindowActivate(_player, _item, bol)
            end
        else
            originalISRadioWindowActivate(_player, _item, bol)
        end
    end
end
 