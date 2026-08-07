--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Misc (Misc).
--
-- Both builds. Custom key.
--
-- The original re-listed 55 Base.Mov_* items here that it had already filed as
-- Furniture; per the project decision (moveables are furniture, the double
-- assignment is a bug) those stay in Furn.lua and are EXCLUDED here. The nine
-- Base.Mov_* appliances the original placed ONLY in MISC (lamps, microwaves,
-- toaster) plus Base.Moveable are kept here, faithful to the original.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- MISC section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Misc = {
    items = {
        "Base.BareHands",
        { "Base.Barricade", only = "41" },
        "Base.CardDeck",
        "Base.CombinationPadlock",
        "Base.CorpseFemale",
        "Base.CorpseMale",
        "Base.Dice",
        { "Base.Door", only = "41" },
        { "Base.DoorFrame", only = "41" },
        "Base.KeyPadlock",
        "Base.Mov_Lamp1",
        "Base.Mov_Lamp2",
        "Base.Mov_Lamp3",
        "Base.Mov_Lamp4",
        "Base.Mov_Lamp5",
        "Base.Mov_Lamp6",
        "Base.Mov_Microwave",
        "Base.Mov_Microwave2",
        "Base.Mov_Toaster",
        "Base.Moveable",
        "Base.Padlock",
        "Base.Stairs",
        { "Base.Underwear1", only = "41" },
        { "Base.Underwear2", only = "41" },
        "Base.WaterDrop",
    },
}
