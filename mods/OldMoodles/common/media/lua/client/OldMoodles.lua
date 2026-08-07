if ISMoodlesInLuaHandle == nil then return end -- do not remove this

-- Register texture set
local name = "Old Moodles" -- Name of your texture set
local path = "media/ui/MIL/OldMoodles" -- Path to your textures

ISMoodlesInLuaHandle:registerIconTextureSet(name, path)
