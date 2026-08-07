--[[
    Weight Reduction — Project Zomboid Build 42

    Lowers the weight of building materials, tools and paint by a configurable
    percentage (default 95%).

    Implementation notes:

    * We mutate the *script* item definitions (zombie.scripting.objects.Item)
      rather than shipping copies of the vanilla item scripts. Overriding item
      blocks in a .txt would replace the whole definition, wiping weapon stats
      and breaking on every game patch, and would conflict with any other mod
      touching the same items. Editing the definition at runtime only writes the
      one field we care about.

    * The script Item class exposes setActualWeight()/getActualWeight() but has
      no getWeight(), so ActualWeight is the single value the game reads when it
      builds an InventoryItem. We deliberately do not touch setCustomWeight() —
      that lives on InventoryItem (the per-instance object), and flagging
      instances as custom-weight would bake the reduced value into the save file
      permanently, even after this mod is removed.

    * Original weights are captured once, before anything is modified, and every
      recalculation is done from those originals. That makes apply() idempotent,
      so re-running it (boot, then again on world load once the sandbox settings
      are known) can never compound the reduction.
]]

WeightReduction = WeightReduction or {}

-- DisplayCategory -> group the option toggles control.
-- These are the raw category keys from the item scripts, not display strings.
local CATEGORIES = {
    Material       = "materials", -- logs, twigs, planks, sheet metal, nails, screws, rope, ore...
    MaterialWeapon = "materials", -- plank, metal pipe, iron bar — materials that double as weapons
    Paint          = "materials", -- paint cans and spray paint
    Tool           = "tools",     -- saw, drill, pliers, anvil, whetstone...
    ToolWeapon     = "tools",     -- hammer, axe, crowbar, sledgehammer, screwdriver...
}

local DEFAULT_PERCENT = 95

-- Array of { item = <script Item>, original = <number>, group = <string> }.
-- nil until the first capture pass runs.
local tracked = nil

local function capture()
    if tracked then return end
    tracked = {}

    local items = getScriptManager():getAllItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local category = item:getDisplayCategory() -- nil for items with no category set
        local group = category and CATEGORIES[category]
        if group then
            local weight = item:getActualWeight()
            -- Skip weightless items; scaling 0 is a no-op and would only pad the log.
            if weight and weight > 0 then
                tracked[#tracked + 1] = { item = item, original = weight, group = group }
            end
        end
    end
end

-- Reads the sandbox options, falling back to defaults when they are not
-- available yet (OnGameBoot runs before a world — and its settings — exist).
local function readSettings()
    local vars = SandboxVars and SandboxVars.WeightReduction

    local percent = vars and vars.ReductionPercent
    if type(percent) ~= "number" then
        percent = DEFAULT_PERCENT
    elseif percent < 0 then
        percent = 0
    elseif percent > 99 then
        -- Capped below 100 so nothing ever lands on exactly zero weight.
        percent = 99
    end

    local affectTools = true
    if vars and vars.AffectTools ~= nil then
        affectTools = vars.AffectTools
    end

    return percent, affectTools
end

function WeightReduction.apply()
    capture()

    local percent, affectTools = readSettings()
    local multiplier = 1 - (percent / 100)
    local reduced = 0

    for i = 1, #tracked do
        local record = tracked[i]
        -- Always recompute from the captured original, never from the current
        -- value, so repeated calls converge instead of stacking.
        local target = record.original
        if record.group == "materials" or affectTools then
            target = record.original * multiplier
        end
        record.item:setActualWeight(target)
        if target < record.original then
            reduced = reduced + 1
        end
    end

    print(string.format(
        "[WeightReduction] %d of %d item definitions reduced by %d%% (tools included: %s).",
        reduced, #tracked, percent, tostring(affectTools)))
end

-- Runs once after the item scripts are parsed, so freshly generated items and
-- the item list in the main menu already reflect the reduction. Sandbox
-- settings do not exist this early, so this pass uses the defaults.
Events.OnGameBoot.Add(WeightReduction.apply)

-- Runs again once a world is loaded and SandboxVars is populated (received from
-- the server in multiplayer). This is the pass that honours the player's
-- configured percentage, and it re-runs when switching between saves.
Events.OnGameStart.Add(WeightReduction.apply)

-- The dedicated-server equivalent of OnGameStart: OnGameStart is a client-side
-- event, so without this a server would keep serving the boot-time defaults and
-- ignore the percentage set in its .ini. capture() runs lazily on first use, so
-- it does not matter which of these events fires first on a given host.
Events.OnServerStarted.Add(WeightReduction.apply)
