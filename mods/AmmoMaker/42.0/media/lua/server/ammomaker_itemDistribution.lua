--Ammo Maker by STIMP_TM

require "Items/ProceduralDistributions"

local ProceduralDistributions_list = ProceduralDistributions.list;
local table_insert = table.insert;

local function addItemToProceduralDistributions(location, item, chance)

    table_insert(ProceduralDistributions_list[location].items, item);
    table_insert(ProceduralDistributions_list[location].items, chance);

end

ammoMakerUpdateCompatibleMods();

local distributionParts = ammoMakerGetAmmoPartTypesActive();

for partType, partData in pairs(distributionParts) do

    local partCat = ammoMakerAmmoParts[partType].partCat;
    local partClass = ammoMakerAmmoParts[partType].partClass;
    local partOld = ammoMakerAmmoParts[partType].partOld;

    local partBox;
    local partBag;

    if ammoMakerAmmoParts[partType].boxType then
        partBox = ammoMakerAmmoParts[partType].boxType;
    else
        partBox = partType;
    end

    if ammoMakerAmmoParts[partType].bagType then
        partBag = ammoMakerAmmoParts[partType].bagType;
    else
        partBag = partOld;
    end

    --all ammo parts
    addItemToProceduralDistributions("ArmyStorageAmmunition", partBox, SandboxVars.ammomakerOptions.ChanceArmyStorageAmmunition);
    addItemToProceduralDistributions("ArmySurplusMisc", partBox, SandboxVars.ammomakerOptions.ChanceArmySurplusMisc);

    --all ammo parts except grenade category
    if partCat ~= "Grenade" then

        addItemToProceduralDistributions("DrugLabGuns", partType, SandboxVars.ammomakerOptions.ChanceDrugLabGuns);
        addItemToProceduralDistributions("FirearmWeapons", partType, SandboxVars.ammomakerOptions.ChanceFirearmWeapons);
        addItemToProceduralDistributions("FirearmWeapons_Mid", partType, SandboxVars.ammomakerOptions.ChanceFirearmWeapons_Mid);
        addItemToProceduralDistributions("FirearmWeapons_Late", partType, SandboxVars.ammomakerOptions.ChanceFirearmWeapons_Late);
        addItemToProceduralDistributions("GunStoreAmmunition", partBox, SandboxVars.ammomakerOptions.ChanceGunStoreAmmunition);
        addItemToProceduralDistributions("GunStoreMagsAmmo", partBox, SandboxVars.ammomakerOptions.ChanceGunStoreMagsAmmo);
        addItemToProceduralDistributions("GunStoreGuns", partBox, SandboxVars.ammomakerOptions.ChanceGunStoreGuns);
        addItemToProceduralDistributions("PoliceStorageAmmunition", partBox, SandboxVars.ammomakerOptions.ChancePoliceStorageAmmunition);
        addItemToProceduralDistributions("PoliceStorageGuns", partBox, SandboxVars.ammomakerOptions.ChancePoliceStorageGuns);
        addItemToProceduralDistributions("WardrobeRedneck", partBox, SandboxVars.ammomakerOptions.ChanceWardrobeRedneck);

    end

    --pistol and revolver ammo parts
    if partCat == "Pistol" then

        addItemToProceduralDistributions("GunStorePistols", partBox, SandboxVars.ammomakerOptions.ChanceGunStorePistols);

    end

    --rifle ammo parts
    if partCat == "Rifle" then

        addItemToProceduralDistributions("GunStoreRifles", partBox, SandboxVars.ammomakerOptions.ChanceGunStoreRifles);
        addItemToProceduralDistributions("HuntingLockers", partBox, SandboxVars.ammomakerOptions.ChanceHuntingLockers);

    end

    --shotgun ammo parts
    if partCat == "Shotgun" then

        addItemToProceduralDistributions("GunStoreShotguns", partBox, SandboxVars.ammomakerOptions.ChanceGunStoreShotguns);
        addItemToProceduralDistributions("HuntingLockers", partBox, SandboxVars.ammomakerOptions.ChanceHuntingLockers);

    end

    --all old casings and shotgun hulls
    if partClass == "Casing" or partClass == "Hull" then

        addItemToProceduralDistributions("ArmyBunkerStorage", partBag, SandboxVars.ammomakerOptions.ChanceArmyBunkerStorage);
        addItemToProceduralDistributions("LockerArmyBedroomHome", partOld, SandboxVars.ammomakerOptions.ChanceLockerArmyBedroomHome);
        addItemToProceduralDistributions("PoliceEvidence", partBag, SandboxVars.ammomakerOptions.ChancePoliceEvidence);

        --all old casings and shotgun hulls except grenade category
        if partCat ~= "Grenade" then

            addItemToProceduralDistributions("BedroomDresserRedneck", partOld, SandboxVars.ammomakerOptions.ChanceBedroomDresserRedneck);
            addItemToProceduralDistributions("DrugShackWeapons", partOld, SandboxVars.ammomakerOptions.ChanceDrugShackWeapons);
            addItemToProceduralDistributions("GarageFirearms", partBag, SandboxVars.ammomakerOptions.ChanceGarageFirearms);

        end

        --old pistol and revolver casings
        if partCat == "Pistol" then

            addItemToProceduralDistributions("BedroomSidetable", partOld, SandboxVars.ammomakerOptions.ChanceBedroomSidetable);
            addItemToProceduralDistributions("BedroomSidetableClassy", partOld, SandboxVars.ammomakerOptions.ChanceBedroomSidetableClassy);
            addItemToProceduralDistributions("BedroomSidetableRedneck", partOld, SandboxVars.ammomakerOptions.ChanceBedroomSidetableRedneck);
            addItemToProceduralDistributions("DresserGeneric", partOld, SandboxVars.ammomakerOptions.ChanceDresserGeneric);
            addItemToProceduralDistributions("PlankStashGun", partOld, SandboxVars.ammomakerOptions.ChancePlankStashGun);
            addItemToProceduralDistributions("SecurityDesk", partOld, SandboxVars.ammomakerOptions.ChanceSecurityDesk);
            addItemToProceduralDistributions("SecurityLockers", partBag, SandboxVars.ammomakerOptions.ChanceSecurityLockers);

        end

        --old rifle casings
        if partCat == "Rifle" then

            addItemToProceduralDistributions("Hunter", partOld, SandboxVars.ammomakerOptions.ChanceHunter);
            addItemToProceduralDistributions("HuntingLockers", partBag, SandboxVars.ammomakerOptions.ChanceHuntingLockers);

        end

        --old shotgun hulls
        if partCat == "Shotgun" then

            addItemToProceduralDistributions("Hunter", partOld, SandboxVars.ammomakerOptions.ChanceHunter);
            addItemToProceduralDistributions("HuntingLockers", partBag, SandboxVars.ammomakerOptions.ChanceHuntingLockers);
            addItemToProceduralDistributions("PrisonArmoryShotguns", partBag, SandboxVars.ammomakerOptions.ChancePrisonArmoryShotguns);

        end

    end

end