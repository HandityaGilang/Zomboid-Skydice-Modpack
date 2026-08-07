if ISMoodlesInLua == nil then return end -- uwu

local pmr_solid = "PMR - Background + Bar" 
local pmr_solid_path = "media/ui/MIL/PMR_BackgroundBar" 
local pmr_solid_options = { iconOffsetX = -5 }

ISMoodlesInLuaHandle:registerBorderTextureSet(pmr_solid, pmr_solid_path, pmr_solid_options)

local pmr_trans = "PMR - Minimal Bar"
local pmr_trans_path = "media/ui/MIL/PMR_Transparent"
local pmr_trans_options = { iconOffsetX = -11 }

ISMoodlesInLuaHandle:registerBorderTextureSet(pmr_trans, pmr_trans_path, pmr_trans_options)

local pmr_full = "PMR - Full Background"
local pmr_full_path = "media/ui/MIL/PMR_Full"
local pmr_full_options = { iconOffsetX = 1 }

ISMoodlesInLuaHandle:registerBorderTextureSet(pmr_full, pmr_full_path, pmr_full_options)