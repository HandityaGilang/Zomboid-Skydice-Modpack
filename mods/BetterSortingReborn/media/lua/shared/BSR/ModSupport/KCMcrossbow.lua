--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Kitsune's Crossbow Mod.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2205190407
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2572385719
--
-- Two Workshop items (the original and the remaster) behind one guard; both
-- ship the same KCMweapons module, so they stay one pack. The second mod ID is
-- a display-style string with spaces and an apostrophe -- kept verbatim, as the
-- game matches it literally (Compat adds the B42 backslash prefix itself).
--
-- Mappings migrated from Better Sorting (KCMcrossbow_Items.lua): 34 lines, no
-- repeats -> 34 items. The Base.KCM_* scopes and sling are mod items, not
-- vanilla weapon parts, so they sit in `data` like the rest.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "KCMcrossbow",
    mods = { "TKCM", "Remastered Kitsune's Crossbow Mod" },
    data = {
        Ammo = {
            items = {
                "KCMweapons.CrossbowBolt",
                "KCMweapons.CrossbowBoltBox",
                "KCMweapons.CrossbowBoltLarge",
                "KCMweapons.CrossbowBoltLargeBox",
                "KCMweapons.WoodenBolt",
                "KCMweapons.WoodenBoltBox",
            },
        },
        Craft = {
            items = {
                "KCMweapons.CrossbowBoltFletching",
                "KCMweapons.CrossbowBoltHead",
                "KCMweapons.CrossbowBoltParts",
                "KCMweapons.CrossbowBoltShaft",
                "KCMweapons.KCM_Flax",
                "KCMweapons.LongBrokenBolt",
                "KCMweapons.LongShaft",
                "KCMweapons.ShortBrokenBolt",
                "KCMweapons.ShortShaft",
                "KCMweapons.WoodenBrokenBolt",
            },
        },
        LitR = {
            items = {
                "KCMweapons.DoomsdayPreppers1",
                "KCMweapons.DoomsdayPreppers2",
                "KCMweapons.DoomsdayPreppers3",
                "KCMweapons.TheUltimateHuntingGuide",
                "KCMweapons.WeaponHandlersReloaded",
            },
        },
        WepBow = {
            items = {
                "KCMweapons.HandCrossbow",
                "KCMweapons.KCM_Compound",
                "KCMweapons.KCM_Compound02",
                "KCMweapons.KCM_Handmade",
                "KCMweapons.KCM_Handmade02",
                "KCMweapons.LargeCrossbow",
            },
        },
        WepPart = {
            items = {
                "Base.KCM_FiberglassStock",
                "Base.KCM_IronSight",
                "Base.KCM_RedDot",
                "Base.KCM_Sling",
                "Base.KCM_x2Scope",
                "Base.KCM_x4Scope",
                "Base.KCM_x8Scope",
            },
        },
    },
})
