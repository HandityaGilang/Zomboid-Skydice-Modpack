--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Little Yoschi's Skillbooks.
-- 16 skill lines x 5 volumes, all sorted to Literature - Skill. The mod ships
-- as five standalone add-ons (agility / firearms / lockpicking / melee /
-- passive) that share the single LY_Skillbooks module, so all five IDs guard
-- one item list — the engine skips the volumes whose add-on is not installed.
--
-- Covers (one guard per mod in the original):
--   Little Yoschi's Skillbooks (LY_Skillbooks_agility, LY_Skillbooks_firearms,
--   LY_Skillbooks_lockpicking, LY_Skillbooks_melee, LY_Skillbooks_passive)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2737726733
--
-- Mappings migrated from Better Sorting (LittleYoschisSkillbooks_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "LittleYoschisSkillbooks",
    mods = { "LY_Skillbooks_agility", "LY_Skillbooks_firearms", "LY_Skillbooks_lockpicking", "LY_Skillbooks_melee", "LY_Skillbooks_passive" },
    data = {
        LitS = {
            items = {
                "LY_Skillbooks.BookAiming1",
                "LY_Skillbooks.BookAiming2",
                "LY_Skillbooks.BookAiming3",
                "LY_Skillbooks.BookAiming4",
                "LY_Skillbooks.BookAiming5",
                "LY_Skillbooks.BookAxe1",
                "LY_Skillbooks.BookAxe2",
                "LY_Skillbooks.BookAxe3",
                "LY_Skillbooks.BookAxe4",
                "LY_Skillbooks.BookAxe5",
                "LY_Skillbooks.BookBlunt1",
                "LY_Skillbooks.BookBlunt2",
                "LY_Skillbooks.BookBlunt3",
                "LY_Skillbooks.BookBlunt4",
                "LY_Skillbooks.BookBlunt5",
                "LY_Skillbooks.BookFitness1",
                "LY_Skillbooks.BookFitness2",
                "LY_Skillbooks.BookFitness3",
                "LY_Skillbooks.BookFitness4",
                "LY_Skillbooks.BookFitness5",
                "LY_Skillbooks.BookLightfooted1",
                "LY_Skillbooks.BookLightfooted2",
                "LY_Skillbooks.BookLightfooted3",
                "LY_Skillbooks.BookLightfooted4",
                "LY_Skillbooks.BookLightfooted5",
                "LY_Skillbooks.BookLockpicking1",
                "LY_Skillbooks.BookLockpicking2",
                "LY_Skillbooks.BookLockpicking3",
                "LY_Skillbooks.BookLockpicking4",
                "LY_Skillbooks.BookLockpicking5",
                "LY_Skillbooks.BookLongBlade1",
                "LY_Skillbooks.BookLongBlade2",
                "LY_Skillbooks.BookLongBlade3",
                "LY_Skillbooks.BookLongBlade4",
                "LY_Skillbooks.BookLongBlade5",
                "LY_Skillbooks.BookMaintenance1",
                "LY_Skillbooks.BookMaintenance2",
                "LY_Skillbooks.BookMaintenance3",
                "LY_Skillbooks.BookMaintenance4",
                "LY_Skillbooks.BookMaintenance5",
                "LY_Skillbooks.BookNimble1",
                "LY_Skillbooks.BookNimble2",
                "LY_Skillbooks.BookNimble3",
                "LY_Skillbooks.BookNimble4",
                "LY_Skillbooks.BookNimble5",
                "LY_Skillbooks.BookReloading1",
                "LY_Skillbooks.BookReloading2",
                "LY_Skillbooks.BookReloading3",
                "LY_Skillbooks.BookReloading4",
                "LY_Skillbooks.BookReloading5",
                "LY_Skillbooks.BookSmallBlade1",
                "LY_Skillbooks.BookSmallBlade2",
                "LY_Skillbooks.BookSmallBlade3",
                "LY_Skillbooks.BookSmallBlade4",
                "LY_Skillbooks.BookSmallBlade5",
                "LY_Skillbooks.BookSmallBlunt1",
                "LY_Skillbooks.BookSmallBlunt2",
                "LY_Skillbooks.BookSmallBlunt3",
                "LY_Skillbooks.BookSmallBlunt4",
                "LY_Skillbooks.BookSmallBlunt5",
                "LY_Skillbooks.BookSneaking1",
                "LY_Skillbooks.BookSneaking2",
                "LY_Skillbooks.BookSneaking3",
                "LY_Skillbooks.BookSneaking4",
                "LY_Skillbooks.BookSneaking5",
                "LY_Skillbooks.BookSpear1",
                "LY_Skillbooks.BookSpear2",
                "LY_Skillbooks.BookSpear3",
                "LY_Skillbooks.BookSpear4",
                "LY_Skillbooks.BookSpear5",
                "LY_Skillbooks.BookSprinting1",
                "LY_Skillbooks.BookSprinting2",
                "LY_Skillbooks.BookSprinting3",
                "LY_Skillbooks.BookSprinting4",
                "LY_Skillbooks.BookSprinting5",
                "LY_Skillbooks.BookStrength1",
                "LY_Skillbooks.BookStrength2",
                "LY_Skillbooks.BookStrength3",
                "LY_Skillbooks.BookStrength4",
                "LY_Skillbooks.BookStrength5",
            },
        },
    },
})
