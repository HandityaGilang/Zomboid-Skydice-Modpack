if ISMoodlesInLuaHandle == nil then return end -- do not remove this

-- Register texture set
local name = "Devcatt's Pixel Moodles" -- Name of your texture set
local path = "media/ui/MIL/devcattpixelmoodles" -- Path to your textures

ISMoodlesInLuaHandle:registerIconTextureSet(name, path)
