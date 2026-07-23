require "ISUI/ISPanel"
require "ISUI/ISToolTip"

_G.NMWalkmanWindow = _G.NMWalkmanWindow or {}
_G.NMWalkmanWindowEnv = _G.NMWalkmanWindowEnv or {}

local env = _G.NMWalkmanWindowEnv
if getmetatable(env) == nil then
    setmetatable(env, { __index = _G })
end

env.NMWalkmanWindow = _G.NMWalkmanWindow
env.WalkmanWindow = env.WalkmanWindow or ISPanel:derive("NMWalkmanWindow")
env.windowsByPlayer = env.windowsByPlayer or {}
env.pendingRestoreByPlayer = env.pendingRestoreByPlayer or {}
env.WALKMAN_UI_TEXTURES_BY_VARIANT = env.WALKMAN_UI_TEXTURES_BY_VARIANT or {}
env.UI_TEXTURES = env.UI_TEXTURES or {}

return env
