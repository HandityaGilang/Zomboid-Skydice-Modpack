require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}

local function boot()
    if LifestyleSecure.Features.HasUpstreamConflict() then
        LifestyleSecure.Disabled = true
        print("[LifestyleSecure] BLOCKED: official LifestyleHobbies is active. Disable one of the two mods.")
        return
    end

    LifestyleSecure.Disabled = false
    LifestyleSecure.Version = LifestyleSecure.Features.VERSION
    print("[LifestyleSecure] shared core ready version=" .. tostring(LifestyleSecure.Version)
        .. " (standalone; Kardinal optional)")
    -- Soft tip only: this mod does not require Kardinal. If Kardinal is present,
    -- loading Lifestyle last avoids inventory/timed-action wrap order fights.
    if LifestyleSecure.Features.HasKardinalPack and LifestyleSecure.Features.HasKardinalPack() then
        print("[LifestyleSecure] Kardinal pack also active: prefer Mods= ...;LifestyleHobbies_KardinalTest last.")
    end
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Remove(boot)
    Events.OnGameBoot.Add(boot)
else
    boot()
end
