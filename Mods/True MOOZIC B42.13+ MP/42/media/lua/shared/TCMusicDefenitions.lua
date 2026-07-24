require "TCKeyBinding"
if isServer() then
    pcall(function() require "TCStartWithDevice" end)
end

local DEBUG = false

if not TCMusic then TCMusic = {} end
if (TCMusic.ItemMusicPlayer == nil) then TCMusic.ItemMusicPlayer = {} end
if (TCMusic.VehicleMusicPlayer == nil) then TCMusic.VehicleMusicPlayer = {} end
if (TCMusic.WorldMusicPlayer == nil) then TCMusic.WorldMusicPlayer = {} end
if (TCMusic.WalkmanPlayer == nil) then TCMusic.WalkmanPlayer = {} end
if (GlobalMusic == nil) then GlobalMusic = {} end

if DEBUG then
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoombox"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxBlue"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxCamo"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxBlack"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxGreen"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxPink"] = "TrueMoozic_music_01_35"
    TCMusic.ItemMusicPlayer["TrueMoozic.TCBoomboxRed"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_34"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_35"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_62"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_36"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_37"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_63"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoombox"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxBlue"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxCamo"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxBlack"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxGreen"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxPink"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCBoomboxRed"] = "TrueMoozic_music_01_35"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCVinylplayer"] = "TrueMoozic_music_01_36"
    TCMusic.WorldMusicPlayer["TrueMoozic.TCVinylplayerBlack"] = "TrueMoozic_music_01_36"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "TrueMoozic_music_01_35"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "TrueMoozic_music_01_35"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkman"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanPurple"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanRed"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanBlack"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanPink"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanGreen"] = "TrueMoozic_music_01_62"
    TCMusic.WalkmanPlayer["TrueMoozic.TCWalkmanCamoGreen"] = "TrueMoozic_music_01_62"
else
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxBlue"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxCamo"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxBlack"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxGreen"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxPink"] = "tsarcraft_music_01_62"
    TCMusic.ItemMusicPlayer["Tsarcraft.TCBoomboxRed"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_34"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_35"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_62"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_36"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_37"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["TrueMoozic_music_01_63"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoombox"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxBlue"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxCamo"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxBlack"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxGreen"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxPink"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCBoomboxRed"] = "tsarcraft_music_01_62"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"] = "tsarcraft_music_01_63"
    TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayerBlack"] = "tsarcraft_music_01_63"
    TCMusic.VehicleMusicPlayer["Base.HamRadio1"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.HamRadio2"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioBlack"] = "tsarcraft_music_01_62"
    TCMusic.VehicleMusicPlayer["Base.RadioRed"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkman"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanPurple"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanRed"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanBlack"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanPink"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanGreen"] = "tsarcraft_music_01_62"
    TCMusic.WalkmanPlayer["Tsarcraft.TCWalkmanCamoGreen"] = "tsarcraft_music_01_62"
end

GlobalMusic["CassetteMainTheme"] = "tsarcraft_music_01_62"
GlobalMusic["VinylMainTheme"] = "tsarcraft_music_01_63"

-- Alias actual lowercase proxy sprite names used by world IsoRadio objects.
TCMusic.WorldMusicPlayer["tsarcraft_music_01_62"] = "tsarcraft_music_01_62"
TCMusic.WorldMusicPlayer["tsarcraft_music_01_63"] = "tsarcraft_music_01_63"

