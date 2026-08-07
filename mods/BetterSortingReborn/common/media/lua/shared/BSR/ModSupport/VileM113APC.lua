--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Vile's M113 APC.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=1983277711
--
-- Every vehicle part the APC adds (tires, brakes, suspensions, doors, windows,
-- glove boxes, in the mod's three quality tiers) sorts to Mech. The items are
-- declared in the Base module but none of them is a vanilla item, so they stay
-- in `data` — no `overrides` needed.
--
-- Mappings migrated from Better Sorting v2.0.4 (VileM113APC_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "VileM113APC",
    mods = { "VileM113APC" },
    data = {
        Mech = {
            items = {
                "Base.EngineM113Door1",
                "Base.EngineM113Door2",
                "Base.EngineM113Door3",
                "Base.FrontM113Door1",
                "Base.FrontM113Door2",
                "Base.FrontM113Door3",
                "Base.M113FrontWindow1",
                "Base.M113FrontWindow2",
                "Base.M113FrontWindow3",
                "Base.M113GloveBox1",
                "Base.M113GloveBox2",
                "Base.M113GloveBox3",
                "Base.M113Tire1",
                "Base.M113Tire2",
                "Base.M113Tire3",
                "Base.ModernM113Brake1",
                "Base.ModernM113Brake2",
                "Base.ModernM113Brake3",
                "Base.ModernM113Suspension1",
                "Base.ModernM113Suspension2",
                "Base.ModernM113Suspension3",
                "Base.NormalM113Brake1",
                "Base.NormalM113Brake2",
                "Base.NormalM113Brake3",
                "Base.NormalM113Suspension1",
                "Base.NormalM113Suspension2",
                "Base.NormalM113Suspension3",
                "Base.OldM113Brake1",
                "Base.OldM113Brake2",
                "Base.OldM113Brake3",
                "Base.RearM113Door1",
                "Base.RearM113Door2",
                "Base.RearM113Door3",
            },
        },
    },
})
