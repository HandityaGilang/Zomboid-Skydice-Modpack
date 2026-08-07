--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Occupations Expertises.
-- 15 skill lines x 5 volumes, all sorted to Literature - Skill.
--
-- Covers (one guard per mod in the original):
--   OccupationsExpertises (OccupationsExpertises) — https://steamcommunity.com/sharedfiles/filedetails/?id=2729436580
--
-- Mappings migrated from Better Sorting (OccupationsExpertises_Items.lua).
-- The original listed BookNimble1/2/4/5 but skipped BookNimble3; the gap is
-- treated as an oversight and the volume is included here (an item the mod
-- does not define is simply skipped at boot).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "OccupationsExpertises",
    mods = { "OccupationsExpertises" },
    data = {
        LitS = {
            items = {
                "OccupationsExpertises.BookAiming1",
                "OccupationsExpertises.BookAiming2",
                "OccupationsExpertises.BookAiming3",
                "OccupationsExpertises.BookAiming4",
                "OccupationsExpertises.BookAiming5",
                "OccupationsExpertises.BookAxe1",
                "OccupationsExpertises.BookAxe2",
                "OccupationsExpertises.BookAxe3",
                "OccupationsExpertises.BookAxe4",
                "OccupationsExpertises.BookAxe5",
                "OccupationsExpertises.BookBlunt1",
                "OccupationsExpertises.BookBlunt2",
                "OccupationsExpertises.BookBlunt3",
                "OccupationsExpertises.BookBlunt4",
                "OccupationsExpertises.BookBlunt5",
                "OccupationsExpertises.BookFitness1",
                "OccupationsExpertises.BookFitness2",
                "OccupationsExpertises.BookFitness3",
                "OccupationsExpertises.BookFitness4",
                "OccupationsExpertises.BookFitness5",
                "OccupationsExpertises.BookLightfooted1",
                "OccupationsExpertises.BookLightfooted2",
                "OccupationsExpertises.BookLightfooted3",
                "OccupationsExpertises.BookLightfooted4",
                "OccupationsExpertises.BookLightfooted5",
                "OccupationsExpertises.BookLongBlade1",
                "OccupationsExpertises.BookLongBlade2",
                "OccupationsExpertises.BookLongBlade3",
                "OccupationsExpertises.BookLongBlade4",
                "OccupationsExpertises.BookLongBlade5",
                "OccupationsExpertises.BookMaintenance1",
                "OccupationsExpertises.BookMaintenance2",
                "OccupationsExpertises.BookMaintenance3",
                "OccupationsExpertises.BookMaintenance4",
                "OccupationsExpertises.BookMaintenance5",
                "OccupationsExpertises.BookNimble1",
                "OccupationsExpertises.BookNimble2",
                "OccupationsExpertises.BookNimble3",
                "OccupationsExpertises.BookNimble4",
                "OccupationsExpertises.BookNimble5",
                "OccupationsExpertises.BookReloading1",
                "OccupationsExpertises.BookReloading2",
                "OccupationsExpertises.BookReloading3",
                "OccupationsExpertises.BookReloading4",
                "OccupationsExpertises.BookReloading5",
                "OccupationsExpertises.BookSmallBlade1",
                "OccupationsExpertises.BookSmallBlade2",
                "OccupationsExpertises.BookSmallBlade3",
                "OccupationsExpertises.BookSmallBlade4",
                "OccupationsExpertises.BookSmallBlade5",
                "OccupationsExpertises.BookSmallBlunt1",
                "OccupationsExpertises.BookSmallBlunt2",
                "OccupationsExpertises.BookSmallBlunt3",
                "OccupationsExpertises.BookSmallBlunt4",
                "OccupationsExpertises.BookSmallBlunt5",
                "OccupationsExpertises.BookSneaking1",
                "OccupationsExpertises.BookSneaking2",
                "OccupationsExpertises.BookSneaking3",
                "OccupationsExpertises.BookSneaking4",
                "OccupationsExpertises.BookSneaking5",
                "OccupationsExpertises.BookSpear1",
                "OccupationsExpertises.BookSpear2",
                "OccupationsExpertises.BookSpear3",
                "OccupationsExpertises.BookSpear4",
                "OccupationsExpertises.BookSpear5",
                "OccupationsExpertises.BookSprinting1",
                "OccupationsExpertises.BookSprinting2",
                "OccupationsExpertises.BookSprinting3",
                "OccupationsExpertises.BookSprinting4",
                "OccupationsExpertises.BookSprinting5",
                "OccupationsExpertises.BookStrength1",
                "OccupationsExpertises.BookStrength2",
                "OccupationsExpertises.BookStrength3",
                "OccupationsExpertises.BookStrength4",
                "OccupationsExpertises.BookStrength5",
            },
        },
    },
})
