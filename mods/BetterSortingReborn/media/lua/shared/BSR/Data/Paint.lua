--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Paint.
--
-- B41 only (whole-table only = "41"). Paint reuses the vanilla "Paint" key and
-- B42 already files all 15 paint cans as "Paint" (same key, same label), so the
-- override would be redundant there. The one non-can entry, Base.Paintbrush, is
-- a vanilla "Tool" on B42 and is left as such (a paintbrush is defensibly a
-- tool). On B41, which has no such categorization, this table applies.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- PAINT section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Paint = {
    only = "41",
    items = {
        "Base.PaintBlack",
        "Base.PaintBlue",
        "Base.PaintBrown",
        "Base.PaintCyan",
        "Base.PaintGreen",
        "Base.PaintGrey",
        "Base.PaintLightBlue",
        "Base.PaintLightBrown",
        "Base.PaintOrange",
        "Base.PaintPink",
        "Base.PaintPurple",
        "Base.PaintRed",
        "Base.PaintTurquoise",
        "Base.PaintWhite",
        "Base.PaintYellow",
        "Base.Paintbrush",
    },
}
