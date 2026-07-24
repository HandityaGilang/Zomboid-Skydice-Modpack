-- TM_HIFI: HiFi Stereo definitions
-- Registers the HiFi as a recognized music device in TrueMusic systems

require "TCMusicDefenitions"

if not HiFiStereo then HiFiStereo = {} end

-- World music player mapping: the HiFi supports both cassette and vinyl sprites
-- These will be set when the device is placed in the world and linked to an IsoRadio
-- The HiFi uses mediaType internally to decide which slot is active for TrueMusic tapes:
--   mediaType 0 = cassette   (uses GlobalMusic["CassetteMainTheme"] mapping)
--   mediaType 1 = vinyl      (uses GlobalMusic["VinylMainTheme"] mapping)

-- Register the HiFi item as a world music player for both cassette and vinyl tile sprites
-- (The actual sprite name is resolved at runtime in TCRWMMedia via WorldMusicPlayer lookup)
-- We register the fullType so that TCMusicClientFunctions and TCTickCheckMusic can find it
TCMusic.WorldMusicPlayer["Tsarcraft.TM_HiFiStereo"] = "tsarcraft_music_01_62"

-- Also register as an item player in case it's ever held (shouldn't be, but safety)
TCMusic.ItemMusicPlayer["Tsarcraft.TM_HiFiStereo"] = "tsarcraft_music_01_62"

-- GlobalMusic entries for cassette / vinyl items are already defined by True MOOZIC:
--   GlobalMusic["CassetteMainTheme"] = "tsarcraft_music_01_62"
--   GlobalMusic["VinylMainTheme"]    = "tsarcraft_music_01_63"
-- We don't redefine them here.

-- The HiFi's CD slot does NOT use GlobalMusic. It uses SWTCCDAlbums (custom CD system).
