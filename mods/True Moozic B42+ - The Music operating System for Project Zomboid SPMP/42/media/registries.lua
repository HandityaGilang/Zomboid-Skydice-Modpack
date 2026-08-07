--[[
    registries.lua  (engine-loaded, runs BEFORE script parsing)

    B42 parses character_trait_definition scripts before any mod Lua runs,
    and those scripts RESOLVE the CharacterTrait object out of
    Registries.CHARACTER_TRAIT at parse time - they never create it.
    A trait that isn't registered here NPEs the definition script
    ("characterTraitType is null") and the trait silently vanishes.

    The engine runs <mod>/<version>/media/registries.lua for every active
    mod at boot (zombie.scripting.objects.ModRegistries)
    Same pattern as More Traits (ToadTraitsRegistries).
]]

TrueMoozicRegistries = TrueMoozicRegistries or {}

-- Registry.register THROWS on a duplicate id, so never blind-register.
local function reg(id)
    local obj
    pcall(function() obj = CharacterTrait.get(ResourceLocation.of(id)) end)
    if obj then return obj end
    local ok, res = pcall(function() return CharacterTrait.register(id) end)
    if ok and res then return res end
    print("[TrueMOOZIC] FAILED to register trait '" .. tostring(id) .. "'")
    return nil
end

TrueMoozicRegistries.truemoozicfan = reg("TrueMoozic:truemoozicfan")

