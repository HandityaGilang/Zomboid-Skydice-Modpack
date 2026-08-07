--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: LitS (Literature - Skill).
--
-- Both builds. On B42 the auto-literature rule already re-homes Literature-
-- type items as a fallback, but these manual entries are still migrated (per
-- the original): they also catch any listed item whose type is not Literature
-- and the cases where the rule's replaces42 guard would abstain. Every skill
-- book here exists in 42.19, so none is 41-only.
--
-- These lines are commented out in the original (superseded there by its own
-- auto rule); migrated anyway to preserve the explicit mapping.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- LITERATURE section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.LitS = {
    items = {
        "Base.BookBlacksmith1",
        "Base.BookBlacksmith2",
        "Base.BookBlacksmith3",
        "Base.BookBlacksmith4",
        "Base.BookBlacksmith5",
        "Base.BookCarpentry1",
        "Base.BookCarpentry2",
        "Base.BookCarpentry3",
        "Base.BookCarpentry4",
        "Base.BookCarpentry5",
        "Base.BookCooking1",
        "Base.BookCooking2",
        "Base.BookCooking3",
        "Base.BookCooking4",
        "Base.BookCooking5",
        "Base.BookElectrician1",
        "Base.BookElectrician2",
        "Base.BookElectrician3",
        "Base.BookElectrician4",
        "Base.BookElectrician5",
        "Base.BookFarming1",
        "Base.BookFarming2",
        "Base.BookFarming3",
        "Base.BookFarming4",
        "Base.BookFarming5",
        "Base.BookFirstAid1",
        "Base.BookFirstAid2",
        "Base.BookFirstAid3",
        "Base.BookFirstAid4",
        "Base.BookFirstAid5",
        "Base.BookFishing1",
        "Base.BookFishing2",
        "Base.BookFishing3",
        "Base.BookFishing4",
        "Base.BookFishing5",
        "Base.BookForaging1",
        "Base.BookForaging2",
        "Base.BookForaging3",
        "Base.BookForaging4",
        "Base.BookForaging5",
        "Base.BookMechanic1",
        "Base.BookMechanic2",
        "Base.BookMechanic3",
        "Base.BookMechanic4",
        "Base.BookMechanic5",
        "Base.BookMetalWelding1",
        "Base.BookMetalWelding2",
        "Base.BookMetalWelding3",
        "Base.BookMetalWelding4",
        "Base.BookMetalWelding5",
        "Base.BookTailoring1",
        "Base.BookTailoring2",
        "Base.BookTailoring3",
        "Base.BookTailoring4",
        "Base.BookTailoring5",
        "Base.BookTrapping1",
        "Base.BookTrapping2",
        "Base.BookTrapping3",
        "Base.BookTrapping4",
        "Base.BookTrapping5",
        "Base.SmithingMag1",
        "Base.SmithingMag2",
        "Base.SmithingMag3",
        "Base.SmithingMag4",
    },
}
