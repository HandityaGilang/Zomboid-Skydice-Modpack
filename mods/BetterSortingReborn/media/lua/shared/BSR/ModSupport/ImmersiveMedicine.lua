--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Immersive Medicine.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2709866494
--
-- Mod-support packs are pure data. They register themselves into
-- BSR.ModPacks at load time; the engine merges a pack's tables into the
-- override map at boot ONLY when one of the mod IDs in "mods" is active
-- (checked through BSR.Compat.isModActive, which handles the B41/B42
-- getActivatedMods() differences).
--
-- Mappings migrated from Better Sorting (ImmersiveMedicine_Items.lua): 55
-- lines, no repeats -> 55 items. Every item is in the mod's own iMeds module,
-- so nothing collides with the vanilla tables in Data/. The mod's medical
-- consumables (the ...Pack drugs) keep the original's Drugs/Med split.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "ImmersiveMedicine",
    mods = { "iMeds" },
    data = {
        Drugs = {
            items = {
                "iMeds.Alkagin",
                "iMeds.AlkaginPack",
                "iMeds.BismuthSubsalicylate",
                "iMeds.BismuthSubsalicylatePack",
                "iMeds.Butamirate",
                "iMeds.ButamiratePack",
                "iMeds.Erythropoietin",
                "iMeds.ErythropoietinPack",
                "iMeds.HemoStop",
                "iMeds.HemoStopPack",
                "iMeds.Morphine",
                "iMeds.MorphinePack",
                "iMeds.Naloxon",
                "iMeds.NaloxonPack",
                "iMeds.Nasivion",
                "iMeds.NasivionPack",
                "iMeds.Umifenovir",
                "iMeds.UmifenovirPack",
                "iMeds.UnknownPack",
            },
        },
        Med = {
            items = {
                "iMeds.BloodPressureMonitorLeft",
                "iMeds.BloodPressureMonitorRight",
                "iMeds.BloodTester",
                "iMeds.BloodTestingKit",
                "iMeds.BloodVolumeIncreaser",
                "iMeds.BloodVolumeReducer",
                "iMeds.DrugApplier",
                "iMeds.EmptyBloodBag",
                "iMeds.ErythrocyteSuspensionBagABN",
                "iMeds.ErythrocyteSuspensionBagABP",
                "iMeds.ErythrocyteSuspensionBagAN",
                "iMeds.ErythrocyteSuspensionBagAP",
                "iMeds.ErythrocyteSuspensionBagBN",
                "iMeds.ErythrocyteSuspensionBagBP",
                "iMeds.ErythrocyteSuspensionBagON",
                "iMeds.ErythrocyteSuspensionBagOP",
                "iMeds.FullBloodBag",
                "iMeds.FullSyringeWithNeedle",
                "iMeds.HeartRateMonitorLeft",
                "iMeds.HeartRateMonitorRight",
                "iMeds.Needle",
                "iMeds.NeedlePack",
                "iMeds.PeripheralVenousCatheter",
                "iMeds.PlasmaBagABN",
                "iMeds.PlasmaBagABP",
                "iMeds.PlasmaBagAN",
                "iMeds.PlasmaBagAP",
                "iMeds.PlasmaBagBN",
                "iMeds.PlasmaBagBP",
                "iMeds.PlasmaBagON",
                "iMeds.PlasmaBagOP",
                "iMeds.PulseChecker",
                "iMeds.Stethoscope",
                "iMeds.Syringe",
                "iMeds.SyringePack",
                "iMeds.SyringeWithNeedle",
            },
        },
    },
})
