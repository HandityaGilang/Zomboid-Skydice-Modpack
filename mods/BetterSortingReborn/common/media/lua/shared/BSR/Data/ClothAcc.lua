--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: ClothAcc (Clothing - Accessory).
--
-- Applies on both builds: ClothAcc ("Clothing - Accessory") stays more specific than
-- B42's generic vanilla clothing buckets (Clothing / Accessory / Bag /
-- ProtectiveGear), so it stays valuable on both. Items renamed or removed
-- in B42 42.19 are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CLOTHING section — Accessory).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.ClothAcc = {
    items = {
        "Base.AmmoStrap_Bullets",
        "Base.AmmoStrap_Shells",
        { "Base.Belt", only = "41" },
        "Base.Belt2",
        "Base.Bracelet_LeftFriendshipTINT",
        "Base.Bracelet_RightFriendshipTINT",
        "Base.BunnyTail",
        "Base.HolsterDouble",
        "Base.HolsterSimple",
        "Base.Necklace_Choker",
        "Base.Necklace_DogTag",
        "Base.Scarf_StripeBlackWhite",
        "Base.Scarf_StripeBlueWhite",
        "Base.Scarf_StripeRedWhite",
        "Base.Scarf_White",
        "Base.SpiffoTail",
        "Base.Tie_BowTieFull",
        "Base.Tie_BowTieWorn",
        "Base.Tie_Full",
        "Base.Tie_Full_Spiffo",
        "Base.Tie_Worn",
        "Base.Tie_Worn_Spiffo",
        "Base.WristWatch_Left_ClassicBlack",
        "Base.WristWatch_Left_ClassicBrown",
        "Base.WristWatch_Left_ClassicGold",
        "Base.WristWatch_Left_ClassicMilitary",
        "Base.WristWatch_Right_ClassicBlack",
        "Base.WristWatch_Right_ClassicBrown",
        "Base.WristWatch_Right_ClassicGold",
        "Base.WristWatch_Right_ClassicMilitary",
    },
}
