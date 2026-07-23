--[[
    Lifestyle secure test rebuild - feature registry.

    Keeps all upstream systems available while providing one authoritative
    place for sandbox gating, compatibility guards and subsystem metadata.
]]

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.Features = LifestyleSecure.Features or {}

local Features = LifestyleSecure.Features

Features.VERSION = "0.4.0-test.1"
Features.MOD_ID = "LifestyleHobbies_KardinalTest"
Features.UPSTREAM_MOD_ID = "LifestyleHobbies"

Features.Definitions = {
    Music = {
        sandboxPath = { "Text", "DividerMusicNew" },
        networkGroup = "music",
        persistenceGroup = "music",
    },
    Dancing = {
        sandboxPath = { "Text", "DividerDancingNew" },
        networkGroup = "dance",
        persistenceGroup = "dance",
    },
    Meditation = {
        sandboxPath = { "Text", "DividerMeditationNew" },
        networkGroup = "wellness",
        persistenceGroup = "wellness",
    },
    Hygiene = {
        sandboxPath = { "Text", "DividerHygiene" },
        networkGroup = "hygiene",
        persistenceGroup = "hygiene",
    },
    Art = {
        sandboxPath = { "Text", "DividerArt" },
        networkGroup = "art",
        persistenceGroup = "art",
    },
    Ambitions = {
        sandboxPath = { "LSAmbt", "Toggle" },
        networkGroup = "ambitions",
        persistenceGroup = "ambitions",
    },
    Inventions = {
        sandboxPath = nil,
        networkGroup = "inventions",
        persistenceGroup = "inventions",
    },
    Comfort = {
        sandboxPath = nil,
        networkGroup = "comfort",
        persistenceGroup = "comfort",
    },
    Social = {
        sandboxPath = nil,
        networkGroup = "social",
        persistenceGroup = "social",
    },
}

local function activeMods()
    if not getActivatedMods then
        return nil
    end
    return getActivatedMods()
end

function Features.HasActiveMod(id)
    local mods = activeMods()
    return mods and mods.contains and mods:contains(id) or false
end

function LSKHasActiveMod(id)
    return Features.HasActiveMod(id)
end

function LSKOptionalRequire(moduleName)
    if type(moduleName) ~= "string" then
        return nil
    end
    local ok, result = pcall(require, moduleName)
    if not ok then
        return nil
    end
    -- Prefer real module table/function. Keep boolean true only for side-effect requires.
    if result ~= nil then
        return result
    end
    return true
end

function Features.HasUpstreamConflict()
    return Features.HasActiveMod(Features.UPSTREAM_MOD_ID)
end

local function sandboxValue(path)
    if not path or not SandboxVars then
        return true
    end
    local value = SandboxVars
    for i = 1, #path do
        value = value and value[path[i]] or nil
    end
    if value == nil then
        return true
    end
    return value ~= false
end

-- Master sandbox kill-switch: false = Lifestyle actions/network/moddata flush off.
-- Skills/perks stay on the character; they are not wiped.
function Features.IsModActive()
    if LifestyleSecure and LifestyleSecure.Disabled then
        return false
    end
    if not SandboxVars then
        return true
    end
    local lsk = SandboxVars.LSK
    if type(lsk) == "table" and lsk.MasterEnable == false then
        return false
    end
    return true
end

-- Soft detect only. Lifestyle never requires Kardinal to run.
function Features.HasKardinalPack()
    return Features.HasActiveMod("kardinal_lib_RuRustV3")
        or Features.HasActiveMod("kardinal_RuRustV3")
end

function LSKIsLifestyleActive()
    return Features.IsModActive()
end

function Features.IsEnabled(name)
    if not Features.IsModActive() then
        return false
    end
    local definition = Features.Definitions[name]
    if not definition then
        return false
    end
    return sandboxValue(definition.sandboxPath)
end

function Features.GetEnabled()
    local enabled = {}
    for name in pairs(Features.Definitions) do
        if Features.IsEnabled(name) then
            enabled[#enabled + 1] = name
        end
    end
    table.sort(enabled)
    return enabled
end

function Features.GetDefinition(name)
    return Features.Definitions[name]
end

-- When MasterEnable is false, force classic divider toggles off so context menus
-- and legacy checks behave as if Lifestyle systems are gone. Restores on re-enable.
-- Does not wipe skills/perks.
function Features.SyncSandboxMirror()
    if not SandboxVars then
        return
    end
    SandboxVars.Text = SandboxVars.Text or {}
    SandboxVars.LSAmbt = SandboxVars.LSAmbt or {}
    if not Features.IsModActive() then
        if not Features._savedSandbox then
            Features._savedSandbox = {
                DividerMusicNew = SandboxVars.Text.DividerMusicNew,
                DividerDancingNew = SandboxVars.Text.DividerDancingNew,
                DividerMeditationNew = SandboxVars.Text.DividerMeditationNew,
                DividerHygiene = SandboxVars.Text.DividerHygiene,
                DividerArt = SandboxVars.Text.DividerArt,
                AmbtToggle = SandboxVars.LSAmbt.Toggle,
            }
        end
        SandboxVars.Text.DividerMusicNew = false
        SandboxVars.Text.DividerDancingNew = false
        SandboxVars.Text.DividerMeditationNew = false
        SandboxVars.Text.DividerHygiene = false
        SandboxVars.Text.DividerArt = false
        SandboxVars.LSAmbt.Toggle = false
        return
    end
    local saved = Features._savedSandbox
    if not saved then
        return
    end
    SandboxVars.Text.DividerMusicNew = saved.DividerMusicNew
    SandboxVars.Text.DividerDancingNew = saved.DividerDancingNew
    SandboxVars.Text.DividerMeditationNew = saved.DividerMeditationNew
    SandboxVars.Text.DividerHygiene = saved.DividerHygiene
    SandboxVars.Text.DividerArt = saved.DividerArt
    SandboxVars.LSAmbt.Toggle = saved.AmbtToggle
    Features._savedSandbox = nil
end

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Remove(Features.SyncSandboxMirror)
        Events.OnGameStart.Add(Features.SyncSandboxMirror)
    end
    if Events.EveryOneMinute then
        Events.EveryOneMinute.Remove(Features.SyncSandboxMirror)
        Events.EveryOneMinute.Add(Features.SyncSandboxMirror)
    end
end
