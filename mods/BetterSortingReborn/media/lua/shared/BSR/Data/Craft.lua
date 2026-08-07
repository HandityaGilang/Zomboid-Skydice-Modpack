--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Craft (Crafting).
--
-- Applies on both builds. B42 vanilla files most of these under "Material" (a
-- different key and label), so grouping them as Crafting is a refinement on
-- both builds. Items absent from B42 scripts are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CRAFTING section — general).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Craft = {
    items = {
        "Base.BucketConcreteFull",
        "Base.BucketPlasterFull",
        "Base.ConcretePowder",
        "Base.Doorknob",
        "Base.DuctTape",
        "Base.Garbagebag",
        "Base.Glue",
        "Base.Gravelbag",
        "Base.GunPowder",
        { "Base.Hairspray", only = "41" },
        "Base.Handle",
        "Base.Hinge",
        "Base.IronIngot",
        "Base.Mattress",
        "Base.Nails",
        "Base.NailsBox",
        "Base.Paperclip",
        "Base.PaperclipBox",
        "Base.Pillow",
        "Base.PlasterPowder",
        "Base.PropaneTank",
        "Base.Rope",
        "Base.Sandbag",
        "Base.Scotchtape",
        "Base.Screws",
        "Base.ScrewsBox",
        "Base.SharpedStone",
        "Base.Sheet",
        "Base.Sparklers",
        { "Base.Stone", only = "41" },
        { "Base.TreeBranch", only = "41" },
        "Base.Twine",
        "Base.Wire",
        "Base.Woodglue",
    },
}
