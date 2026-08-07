--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Spiffo's True Music.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2723341089
--
-- The original core sorted every Tsarcraft cassette/vinyl via a pattern
-- rule (their per-item lines were commented out for that reason, and their
-- names contain (), ! and ' which BSR's strict item format rejects). BSR
-- has no global rules, so the behaviour is reproduced as a scoped pack
-- rule: while SpiffoTrueMusic is active, any Tsarcraft.Cassette*/Vinyl*
-- item sorts to Media - Audio. Covers present and future tracks.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "TrueMusicAddonMod",
    mods = { "SpiffoTrueMusic" },
    rules = {
        { contains = { "Tsarcraft.Cassette", "Tsarcraft.Vinyl" }, category = "MediaA" },
    },
})
