--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: More Books!.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2815857931
--
-- The mod adds ~100 classic novels, all in the "Books" module, every one
-- sorted to Literature - Entertainment. Several titles contain apostrophes
-- and accents (Charlotte's_Web, A_Doll's_House, Pere_Goriot) that BSR's
-- strict item-name format rejects, so the whole set is handled by a single
-- scoped module rule: while MoreBooks is active, any Books.* item sorts to
-- LitE. Covers present and future titles.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "MoreBooks",
    mods = { "MoreBooks" },
    rules = {
        { module = "Books", category = "LitE" },
    },
})
