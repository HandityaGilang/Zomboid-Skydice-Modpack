--Ammo Maker by STIMP_TM

--[[

The API allows 42.13+ gun mods to assign custom ammo item types to Ammo Maker ammo types from their end.
Based on the added definitions, Ammo Maker adjusts craft recipes, foraging definitions, item distributions and other aspects dynamically.

Add `ammomaker_addAmmoTypes.lua` to `...\media\lua\shared\` of your 42.13+ gun mod and update `modId` and `ammoMap` inside of `ammoMakerAddAmmoTypes()` according to your needs.
Only if Ammo Maker is used in combination with your mod, `ammoMakerAddAmmoTypes()` will get called and add your definitions.

If you need to map custom ammo item types from multiple mods at the same time (e.g. a main mod plus one or more expansion mods), add a separate function to each mod.
The API supports up to 10 functions, using the following naming pattern:

    ammoMakerAddAmmoTypes();
    ammoMakerAddAmmoTypes1();
    ammoMakerAddAmmoTypes2();
    ammoMakerAddAmmoTypes3();
    ammoMakerAddAmmoTypes4();
    ammoMakerAddAmmoTypes5();
    ammoMakerAddAmmoTypes6();
    ammoMakerAddAmmoTypes7();
    ammoMakerAddAmmoTypes8();
    ammoMakerAddAmmoTypes9();

Each function should map the ammo item types for one specific mod.

If you would like to use the API and your mod was listed as compatible already, please let us know and we will remove the hard coded values for your mod.

    Ammo Maker Ammo Types:

        Modded Types:

            545x39            5.45x39mm - 1974
            223Rem            .223 Remington (aka. 5.7x45mm) - 1957
            57x28             5.7x28mm (aka. FN 5.7x28mm NATO) - 1990
            22LR              .22 long rifle (aka. 5.7x15mmR) - 1887
            58x42             5.8x42mm (aka. DBP87) - 1987
            25ACP             .25 ACP (aka. 6.35x16mmSR or .25 Auto) - 1905
            65x50SRAris       6.5x50mmSR Arisaka (aka. 6.5x51 R) - 1897
            65x52Carc         6.5x52mm Carcano round - 1891
            30Carbine         .30 Carbine (aka. 7.62x33mm) - 1942
            762x38RNag        7.62x38mmR (aka. 7.62mm Nagant) - 1895
            762x51NATO        7.62x51mm NATO (aka. 7.62 NATO) - 1954
            75x54             7.5x54mm (aka. 7.5 French or 7.5 MAS) - 1924
            3006Spring        .30-06 Springfield (aka. 7.62x63mm) - 1906
            762x25Tok         7.62x25mm Tokarev - 1930
            762x39            7.62x39mm (aka. 7.62 Soviet or .30 Russian Short) - 1945
            303British        .303 British (aka. 7.7x56mmR) - 1889
            762x54R           7.62x54mmR - 1891
            32ACP             .32 ACP (aka. 7.65x17mmSR or .32 Auto) - 1899
            792x33Kurz        7.92x33mm Kurz (aka. 7.9mm Kurz or 8x33 Polte) - 1942
            792x57Maus        7.92x57mm Mauser (aka. 8mm Mauser or 8x57mm) - 1905
            8x50RLeb          8x50mmR Lebel (aka. 8mm Lebel) - 1886
            8x27RLeb          8x27mmR Lebel (aka. 8mm French Ordnance) - 1892
            86x43BLK          8.6mm Blackout (aka. 8.6x43mm or 8.6 BLK) - 2022
            338Lapua          .338 Lapua Magnum (aka. 8.6x70mm or 8.58×70mm) - 1989
            380ACP            .380 ACP (aka. 9x17mm or .380 Auto) - 1908
            9x25Maus          9x25mm Mauser (aka. 9mm Mauser Export) - 1904
            9x39              9x39mm round - 1980
            9x18Mak           9x18mm Makarov (aka. 9x18mm PM) - 1946
            410Buck00         .410 bore 00 buckshot - 10.4mm - 1874
            10x25Auto         10mm Auto (aka. 10x25mm) - 1983
            40SW              .40 S&W (aka. 10.2x22mm) - 1990
            4440WCF           .44-40 Winchester (aka. 10.8x33mmR or .44 WCF) - 1873
            45LC              .45 Colt (aka. 11.43x33mmR or .45 Long Colt) - 1872
            4570Gov           .45-70 Government (aka. 11.6x53mmR) - 1872
            50AE              .50 Action Express (aka. 12.7x33mmRB or .50 AE) - 1988
            500SWMag          .500 S&W Magnum (aka. 12.7x41mmSR) - 2003
            50BMG             .50 BMG (aka. 12.7x99mm NATO or .50 Browning) - 1921
            127x55            12.7x55mm (aka. STs-130 or PS-12) - 2002
            20Buck00          20 bore 00 buckshot (aka. 20-gauge) - 15.6mm - 1870
            12Slug            12 bore slug (aka. 12-gauge) - 18.5mm - 1860
            10Buck00          10 bore 00 buckshot (aka. 10-gauge) - 19.7mm - 1830
            4Buck00           4 bore 00 buckshot (aka. 4-gauge) - 26.7mm - 1975
            40mmHE            40mm HE Grenade - 1961
            40mmINC           40mm INC Grenade - 1961

        Base Game Types:

            556x45NATO        5.56x45mm NATO (aka. 5.56 NATO) - 1980
            3030Win           .30-30 Winchester (aka. 7.8x51mmR or .30 WCF) - 1895
            308Win            .308 Winchester (aka. 7.82x51mm) - 1952
            9x19Para          9mm Luger (aka. 9x19mm Parabellum) - 1901
            38SP              .38 Special (aka. 9x29mmR or .38 Spl or .38 Spc) - 1898
            357Mag            .357 Magnum (aka. 9x33mmR) - 1934
            44Mag             .44 Magnum (aka. 10.9x33mmR) - 1950
            45ACP             .45 ACP (aka. 11.43x23mm or .45 Auto) - 1904
            12Buck00          12 bore 00 buckshot (aka. 12-gauge) - 18.5mm - 1860

--]]

--Map the ammo item types for one specific mod. Use a unique function name for each mod when mapping ammo item types for multiple mods.
function ammoMakerAddAmmoTypes()

    --Define the mod ID of your mod:
    local modId = "\\Real Firearms";

    --Assign the full item type of your ammo items to Ammo Maker ammo types.
    --Do not add base game item types, unless you are re-using them for different calibres than the base game
    local ammoMap = {
        { itemType = "Base.RF_762x51Bullets", ammoType = "762x51NATO" },
        { itemType = "Base.RF_3006Bullets", ammoType = "3006Spring" },
        { itemType = "Base.RF_762x25Bullets", ammoType = "762x25Tok" },
        { itemType = "Base.RF_762x39Bullets", ammoType = "762x39" },
        { itemType = "Base.RF_762x54Bullets", ammoType = "762x54R" },
        { itemType = "Base.RF_792x33Bullets", ammoType = "792x33Kurz" },
        { itemType = "Base.RF_792x57Bullets", ammoType = "792x57Maus" },
        { itemType = "Base.RF_357Bullets", ammoType = "357Mag" },
        { itemType = "Base.RF_9x18Bullets", ammoType = "9x18Mak" },
        { itemType = "Base.RF_500Bullets", ammoType = "500SWMag" },
    };

    ammoMakerCompatibleMods[modId] = true;

    for i, ammoDef in ipairs(ammoMap) do

        if not ammoMakerAmmoTypes[ammoDef.itemType] then

            ammoMakerAmmoTypes[ammoDef.itemType] = { 
                modIds                  = {modId},
                ammoTypes               = {ammoDef.ammoType},
            };

        else

            table.insert(ammoMakerAmmoTypes[ammoDef.itemType].modIds, modId);
            table.insert(ammoMakerAmmoTypes[ammoDef.itemType].ammoTypes, ammoDef.ammoType);

        end

    end

end