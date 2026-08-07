--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Undead Survivor (Fluffy).
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2713921292
--
-- The guard ID is the mod's own misspelling, "UndeadSuvivor" (one "r"), kept
-- verbatim — it is what getActivatedMods() reports. The mod's three weapon
-- items live in the Base module, everything else in "UndeadSurvivor".
--
-- The Druid Bow is carried by a scoped rule instead of an explicit entry: it
-- is named "UndeadSurvivor.DruidBow(WIP)" and parentheses are rejected by
-- BSR's strict item format. The rule keeps the original's WepBow mapping and
-- also covers the eventual non-WIP rename.
--
-- Mappings migrated from Better Sorting v2.0.4 (Fluffy_Items.lua), with the
-- original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Fluffy",
    mods = { "UndeadSuvivor" },
    rules = {
        { contains = { "UndeadSurvivor.DruidBow" }, category = "WepBow" },
    },
    data = {
        Appear = {
            items = {
                "UndeadSurvivor.MakeUp_Amazona01",
            },
        },
        ClothAcc = {
            items = {
                "UndeadSurvivor.AmazonaFeather01",
                "UndeadSurvivor.AmazonaFeather02",
                "UndeadSurvivor.AmazonaFeather03",
                "UndeadSurvivor.AmazonaFeather04",
                "UndeadSurvivor.AmazonaFeather05",
                "UndeadSurvivor.AmazonaFeather06",
                "UndeadSurvivor.AmazonaFeather07",
                "UndeadSurvivor.AmazonaFeather08",
                "UndeadSurvivor.AmazonaFeather09",
                "UndeadSurvivor.AmazonaFeather10",
                "UndeadSurvivor.AmazonaFeather11",
                "UndeadSurvivor.AmazonaFeather12",
            },
        },
        ClothArm = {
            items = {
                "UndeadSurvivor.StalkerGloves",
            },
        },
        ClothBack = {
            items = {
                "UndeadSurvivor.DeadlyHeadhunterBackpack",
                "UndeadSurvivor.HeadhunterBackpack",
                "UndeadSurvivor.NomadBackpack",
                "UndeadSurvivor.PrepperVestPacked",
            },
        },
        ClothBag = {
            items = {
                "UndeadSurvivor.AmazonaHipBag",
            },
        },
        ClothBody = {
            items = {
                "UndeadSurvivor.AmazonaCloakDOWN",
                "UndeadSurvivor.AmazonaCloakUP",
                "UndeadSurvivor.AmazonaDress",
                "UndeadSurvivor.AmazonaDressTrimmed01",
                "UndeadSurvivor.AmazonaDressTrimmed02",
                "UndeadSurvivor.AmazonaDressTrimmed03",
                "UndeadSurvivor.AmazonaDressTrimmed04",
                "UndeadSurvivor.AmazonaDressTrimmed05",
                "UndeadSurvivor.AmazonaDressTrimmed06",
                "UndeadSurvivor.DeadlyHeadhunterMantle",
                "UndeadSurvivor.DeadlyHeadhunterMantleDOWN",
                "UndeadSurvivor.HeadhunterMantle",
                "UndeadSurvivor.HeadhunterMantleDOWN",
                "UndeadSurvivor.NomadParka",
                "UndeadSurvivor.NomadParkaDOWN",
                "UndeadSurvivor.OminousNomadParka",
                "UndeadSurvivor.OminousNomadParkaDOWN",
                "UndeadSurvivor.PrepperJacket",
                "UndeadSurvivor.PrepperVest",
                "UndeadSurvivor.StalkerJacket",
            },
        },
        ClothFeet = {
            items = {
                "UndeadSurvivor.AmazonaBoots",
                "UndeadSurvivor.NomadBoots",
                "UndeadSurvivor.StalkerBoots",
            },
        },
        ClothHead = {
            items = {
                "UndeadSurvivor.DeadlyHeadhunterGasmask",
                "UndeadSurvivor.HeadhunterGasmask",
                "UndeadSurvivor.NomadMask",
                "UndeadSurvivor.OminousNomadMask",
                "UndeadSurvivor.PrepperHelmet",
                "UndeadSurvivor.PrepperMask",
                "UndeadSurvivor.StalkerCloak",
                "UndeadSurvivor.StalkerCloakDOWN",
                "UndeadSurvivor.StalkerMask",
            },
        },
        ClothLeg = {
            items = {
                "UndeadSurvivor.NomadTrousers",
                "UndeadSurvivor.NomadTrousersTucked",
                "UndeadSurvivor.PrepperTrousers",
                "UndeadSurvivor.PrepperTrousersTucked",
                "UndeadSurvivor.StalkerTrousers",
                "UndeadSurvivor.StalkerTrousersTucked",
            },
        },
        Container = {
            items = {
                "UndeadSurvivor.PrepperBags",
            },
        },
        Elec = {
            items = {
                "UndeadSurvivor.PrepperFlashlight",
            },
        },
        Junk = {
            items = {
                "UndeadSurvivor.BountyPhoto01",
                "UndeadSurvivor.BountyPhoto02",
                "UndeadSurvivor.BountyPhoto03",
                "UndeadSurvivor.BountyPhoto04",
                "UndeadSurvivor.BountyPhoto05",
                "UndeadSurvivor.BountyPhoto06",
                "UndeadSurvivor.BountyPhoto07",
                "UndeadSurvivor.BountyPhoto08",
                "UndeadSurvivor.BountyPhoto09",
                "UndeadSurvivor.BountyPhoto10",
            },
        },
        WepFire = {
            items = {
                "Base.DeadlyHeadhunterRifle",
                "Base.HeadhunterRifle",
            },
        },
        WepMelee = {
            items = {
                "UndeadSurvivor.AmazonaSpear",
                "UndeadSurvivor.PrepperKnifeKnock",
                "UndeadSurvivor.PrepperKnifeStab",
                "UndeadSurvivor.PrepperKnifeSwing",
                "UndeadSurvivor.StalkerKnife",
            },
        },
        WepPart = {
            items = {
                "Base.HeadhunterScope",
            },
        },
    },
})
