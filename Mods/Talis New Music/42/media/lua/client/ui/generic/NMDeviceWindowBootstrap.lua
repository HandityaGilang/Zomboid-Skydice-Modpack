require "ISUI/ISCollapsableWindow"

_G.NMDeviceWindow = _G.NMDeviceWindow or {}
_G.NMDeviceWindowEnv = _G.NMDeviceWindowEnv or {}
local env = _G.NMDeviceWindowEnv
if getmetatable(env) == nil then
    setmetatable(env, { __index = _G })
end

env.NMDeviceWindow = _G.NMDeviceWindow
env.DeviceWindow = env.DeviceWindow or ISCollapsableWindow:derive("NMDeviceWindow")
env.windowsByPlayer = env.windowsByPlayer or {}
env.EDGE_PAD = env.EDGE_PAD or 20
env.MODULE_GAP = env.MODULE_GAP or 16
env.POWER_SIZE = env.POWER_SIZE or 56
env.BATTERY_SLOT_SIZE = env.BATTERY_SLOT_SIZE or 40
env.MEDIA_SLOT_SIZE = env.MEDIA_SLOT_SIZE or 40
env.HEADPHONE_SLOT_SIZE = env.HEADPHONE_SLOT_SIZE or 40
env.FADER_W = env.FADER_W or 54
env.FADER_H = env.FADER_H or 242
env.READOUT_W = env.READOUT_W or 200
env.READOUT_H = env.READOUT_H or 40
env.COVER_W = env.COVER_W or 200
env.COVER_H = env.COVER_H or 200
env.ROW_TO_READOUT_GAP = env.ROW_TO_READOUT_GAP or 14
env.READOUT_TO_COVER_GAP = env.READOUT_TO_COVER_GAP or 12
env.COVER_TO_TRANSPORT_GAP = env.COVER_TO_TRANSPORT_GAP or 20
env.UI_ASSETS_PREWARMED = env.UI_ASSETS_PREWARMED or false
env.UI_PREWARM_TEXTURE_PATHS = env.UI_PREWARM_TEXTURE_PATHS or {
    "media/textures/UI/NewMusicLogo.png",
    "media/textures/UI/NewMusic40.png",
    "media/textures/UI/UI_NM_SlotEmpty_Battery.png",
    "media/textures/UI/UI_NM_SlotEmpty_Cassette.png",
    "media/textures/UI/UI_NM_SlotEmpty_CD.png",
    "media/textures/UI/UI_NM_SlotEmpty_Vinyl.png",
    "media/textures/UI/UI_NM_SlotEmpty_Headphones.png",
    "media/textures/UI/UI_NM_SlotEmpty_Headphone.png",
    "media/textures/UI/UI_NM_ButtonBaseIn.png",
    "media/textures/UI/UI_NM_ButtonBaseOut.png",
    "media/textures/UI/UI_NM_Play.png",
    "media/textures/UI/UI_NM_Stop.png",
    "media/textures/UI/UI_NM_Prev.png",
    "media/textures/UI/UI_NM_Next.png",
    "media/textures/UI/UI_NM_RepeatNone.png",
    "media/textures/UI/UI_NM_RepeatSong.png",
    "media/textures/UI/UI_NM_RepeatAlbum.png",
    "media/textures/UI/UI_NM_SoundOn.png",
    "media/textures/UI/UI_NM_SoundOff.png",
    "media/textures/UI/UI_NM_NumberFader.png",
    "media/textures/UI/UI_NM_VolumeFaderTicks.png",
    "media/textures/Item_Battery.png",
    "media/textures/Item_Headphones.png",
    "media/textures/Item_Earbuds.png",
    "media/textures/WorldItems/Vinyl/World_NM_NoCover.png"
}

return env
