--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Madax's weapon mods.
-- Melee Weapons Pack  https://steamcommunity.com/sharedfiles/filedetails/?id=2492565135
-- Akier Machete       https://steamcommunity.com/sharedfiles/filedetails/?id=2798493195
-- Elgor Camp Axe      https://steamcommunity.com/sharedfiles/filedetails/?id=2748133073
-- Rager Baseball Bat  https://steamcommunity.com/sharedfiles/filedetails/?id=2693183552
--
-- Four separate Workshop mods, one guard each in the original; their
-- items are disjoint and none of them is a vanilla item name, so they
-- ship as a single pack (an inactive sub-mod's items are simply skipped
-- at boot).
--
-- The Akier Machete family is carried by one scoped rule instead of an
-- explicit list: two of its seven variants are named
-- "akiermacheteergonomic&shortmod" / "...&bleedmod", and "&" is rejected
-- by BSR's strict item format. The rule covers the whole family (present
-- and future variants) with the same WepMelee mapping the original used.
--
-- Mappings migrated from Better Sorting v2.0.4 (Madax_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Madax",
    mods = { "Max", "MDXakiermachete", "MDXelgorcampaxe", "MDXragerbaseballbat" },
    rules = {
        { contains = { "Base.akiermachete" }, category = "WepMelee" },
    },
    data = {
        WepMelee = {
            items = {
                "Base.elgorcampaxe",
                "Base.elgorcampaxehammermod",
                "Base.elgorcampaxepiercemod",
                "Base.ragerbaseballbat",
                "Base.ragerbaseballbataxemod",
                "Base.ragerbaseballbatbarbedmod",
                "Base.ragerbaseballbatheavymod",
                "Base.ragerbaseballbatnailmod",
                "MWPWeapons.aitormonterobowieknife",
                "MWPWeapons.albtacticalkatana",
                "MWPWeapons.aluminiumbaseballbat",
                "MWPWeapons.arliabutterflyknife",
                "MWPWeapons.assaultvknife",
                "MWPWeapons.avengebaseballbat",
                "MWPWeapons.blitalianstiletto",
                "MWPWeapons.britishp1856pioneers",
                "MWPWeapons.brooklynsmasher",
                "MWPWeapons.cgcombattanto",
                "MWPWeapons.coldsteelspear",
                "MWPWeapons.crtkfreyraxe",
                "MWPWeapons.crtkkukrimachete",
                "MWPWeapons.cwcombathatchet",
                "MWPWeapons.defender18machete",
                "MWPWeapons.dmmiceaxe",
                "MWPWeapons.doomsdaysurvivalaxe",
                "MWPWeapons.eastonb5baseballbat",
                "MWPWeapons.fatmaxbrickhammer",
                "MWPWeapons.fiskarcurvedmachete",
                "MWPWeapons.fiskarsplittingmaul",
                "MWPWeapons.gemtord42crashaxe",
                "MWPWeapons.gerberdownrangetomahawk",
                "MWPWeapons.gerberpackhatchet",
                "MWPWeapons.gothsamuraisword",
                "MWPWeapons.kabar1245tanto",
                "MWPWeapons.khkcombatknife",
                "MWPWeapons.korekmachete",
                "MWPWeapons.louisvillevaporbaseballbat",
                "MWPWeapons.m48tacticalwarhammer",
                "MWPWeapons.muelahuntingknife",
                "MWPWeapons.ontariookc10bayonet",
                "MWPWeapons.oxnailhammer",
                "MWPWeapons.pythoncampaxe",
                "MWPWeapons.reapertacsickle",
                "MWPWeapons.reavercleaver",
                "MWPWeapons.rexlerkunai",
                "MWPWeapons.roughneckaxe",
                "MWPWeapons.roughneckgorillasledgehammer",
                "MWPWeapons.russianakmbayonet",
                "MWPWeapons.sogbeardedcampaxe",
                "MWPWeapons.sogf19nelite",
                "MWPWeapons.sogfaritantomachete",
                "MWPWeapons.sptesnaztacticalshovel",
                "MWPWeapons.spydercohatchethawk",
                "MWPWeapons.syntheticsword",
                "MWPWeapons.taigamachete",
                "MWPWeapons.winklersurvivalhatchet",
                "MWPWeapons.yangjangcolumbiabayonet",
                "MWPWeapons.zhunterhookmachete",
            },
        },
    },
})
