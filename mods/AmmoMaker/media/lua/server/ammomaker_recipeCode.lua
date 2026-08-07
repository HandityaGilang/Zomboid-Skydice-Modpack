--Ammo Maker by STIMP_TM

require 'recipecode'

--recipe on test general

function Recipe.OnTest.disabled(recipe, playerObj, item)

    return false;

end

function Recipe.OnTest.isActivated_Charcoal(recipe, playerObj, item)

    return not SandboxVars.ammomakerOptions.DeactivateCharcoalRecipes;

end

function Recipe.OnTest.isActivated_Archery(recipe, playerObj, item)

    return SandboxVars.ammomakerOptions.ActivateArchery or getActivatedMods():contains("HayesFirearmsExtension");

end

--recipe on test mods active

function Recipe.OnTest.isActivated_AGF(recipe, playerObj, item)

    return getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]");

end

function Recipe.OnTest.isActivated_AGF2(recipe, playerObj, item)

    return getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]");

end

function Recipe.OnTest.isActivated_CJ(recipe, playerObj, item)

    return getActivatedMods():contains("CaptainJuezo1") or getActivatedMods():contains("CaptainJuezo1_WIP");

end

function Recipe.OnTest.isActivated_CJWIP(recipe, playerObj, item)

    return getActivatedMods():contains("CaptainJuezo1_WIP");

end

function Recipe.OnTest.isActivated_EK2(recipe, playerObj, item)

    return getActivatedMods():contains("EscapeFromKentucky2");

end

function Recipe.OnTest.isNotActivated_EK2(recipe, playerObj, item)

    return not getActivatedMods():contains("EscapeFromKentucky2");

end

function Recipe.OnTest.isActivated_FA(recipe, playerObj, item)

    return getActivatedMods():contains("firearmmod");

end

function Recipe.OnTest.isActivated_FAR(recipe, playerObj, item)

    return getActivatedMods():contains("firearmmodRevamp");

end

function Recipe.OnTest.isActivated_PSA(recipe, playerObj, item)

    return getActivatedMods():contains("PRitemtest");

end

function Recipe.OnTest.isActivated_RF(recipe, playerObj, item)

    return getActivatedMods():contains("Real Firearms");

end

function Recipe.OnTest.isActivated_RFG(recipe, playerObj, item)

    return getActivatedMods():contains("RainsFirearmsandGunParts") or getActivatedMods():contains("RainsFirearmsandGunPartsApocalyPZe");

end

function Recipe.OnTest.isActivated_SP(recipe, playerObj, item)

    return getActivatedMods():contains("Swatpack");

end

function Recipe.OnTest.isActivated_SG(recipe, playerObj, item)

    return getActivatedMods():contains("ScrapGuns(new version)");

end

function Recipe.OnTest.isActivated_THC(recipe, playerObj, item)

    return getActivatedMods():contains("TIHFP");

end

function Recipe.OnTest.isActivated_THWW2(recipe, playerObj, item)

    return getActivatedMods():contains("TIHFPWW2AF");

end

function Recipe.OnTest.isActivated_TEB(recipe, playerObj, item)

    return getActivatedMods():contains("TEBFP");

end

function Recipe.OnTest.isActivated_TFR(recipe, playerObj, item)

    return getActivatedMods():contains("TIHFPA3R");

end

function Recipe.OnTest.isActivated_TAC(recipe, playerObj, item)

    return getActivatedMods():contains("TFACP");

end

function Recipe.OnTest.isActivated_TPF(recipe, playerObj, item)

    return getActivatedMods():contains("PFF");

end

function Recipe.OnTest.isActivated_VFE(recipe, playerObj, item)

    return getActivatedMods():contains("VFExpansion1");

end

function Recipe.OnTest.isActivated_GWP(recipe, playerObj, item)

    return getActivatedMods():contains("GunrunnersWeaponPack");

end

function Recipe.OnTest.isActivated_VFE2(recipe, playerObj, item)

    return getActivatedMods():contains("VFExpansion2");

end

function Recipe.OnTest.isActivated_VFEID(recipe, playerObj, item)

    return getActivatedMods():contains("VFExpansion1ID");

end

function Recipe.OnTest.isActivated_VFESID(recipe, playerObj, item)

    return getActivatedMods():contains("VFExpansion2ID");

end

function Recipe.OnTest.isActivated_VFE2_VFESID(recipe, playerObj, item)

    return getActivatedMods():contains("VFExpansion2") or getActivatedMods():contains("VFExpansion2ID");

end

function Recipe.OnTest.isActivated_G93(recipe, playerObj, item)

    return getActivatedMods():contains("Guns93");

end

function Recipe.OnTest.isActivated_AFR(recipe, playerObj, item)

    return getActivatedMods():contains("AdditonalFirearmsR") or getActivatedMods():contains("AdditonalFirearmsR rebalance");

end

function Recipe.OnTest.isActivated_HFE(recipe, playerObj, item)

    return getActivatedMods():contains("HayesFirearmsExtension");

end

function Recipe.OnTest.isActivated_SC(recipe, playerObj, item)

    return getActivatedMods():contains("spentcasingsvfe") or getActivatedMods():contains("spentcasingsguns93");

end

function Recipe.OnTest.isActivated_SCV_VFE(recipe, playerObj, item)

    return getActivatedMods():contains("spentcasingsvfe") and getActivatedMods():contains("VFExpansion1");

end

function Recipe.OnTest.isActivated_SCV_AFR(recipe, playerObj, item)

    return getActivatedMods():contains("spentcasingsvfe") and (getActivatedMods():contains("AdditonalFirearmsR") or getActivatedMods():contains("AdditonalFirearmsR rebalance"));

end

function Recipe.OnTest.isActivated_SCV_GWP(recipe, playerObj, item)

    return getActivatedMods():contains("spentcasingsvfe") and getActivatedMods():contains("GunrunnersWeaponPack");

end

function Recipe.OnTest.isActivated_SCG_G93(recipe, playerObj, item)

    return getActivatedMods():contains("spentcasingsguns93") and getActivatedMods():contains("Guns93");

end

function Recipe.OnTest.isActivated_Archery_AGF(recipe, playerObj, item)

    return SandboxVars.ammomakerOptions.ActivateArchery and (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]"));

end

--recipe on test parts active

function Recipe.OnTest.isActivated_Slug12(recipe, playerObj, item)

    return getActivatedMods():contains("Guns93") or getActivatedMods():contains("HayesFirearmsExtension");

end

function Recipe.OnTest.isActivated_BottleneckL(recipe, playerObj, item)

    return (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) or getActivatedMods():contains("CaptainJuezo1_WIP") or getActivatedMods():contains("HayesFirearmsExtension") or getActivatedMods():contains("VFExpansion1ID");

end

function Recipe.OnTest.isActivated_BottleneckMRim(recipe, playerObj, item)

    return (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) or getActivatedMods():contains("CaptainJuezo1") or getActivatedMods():contains("Real Firearms") or getActivatedMods():contains("TIHFP") or getActivatedMods():contains("TIHFPA3R") or getActivatedMods():contains("TFACP") or getActivatedMods():contains("PFF") or getActivatedMods():contains("HayesFirearmsExtension") or getActivatedMods():contains("VFExpansion2ID");

end

function Recipe.OnTest.isActivated_StraightL(recipe, playerObj, item)

    return getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]") or getActivatedMods():contains("VFExpansion2ID");

end

function Recipe.OnTest.isActivated_StraightSRim(recipe, playerObj, item)

    return (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) or getActivatedMods():contains("CaptainJuezo1") or getActivatedMods():contains("firearmmod") or getActivatedMods():contains("firearmmodRevamp") or getActivatedMods():contains("Guns93") or getActivatedMods():contains("PRitemtest") or getActivatedMods():contains("VFExpansion1") or getActivatedMods():contains("HayesFirearmsExtension");

end

function Recipe.OnTest.isActivated_StraightLRim(recipe, playerObj, item)

    return getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]");

end

function Recipe.OnTest.isActivated_HullShotgunL(recipe, playerObj, item)

    return (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) or getActivatedMods():contains("PRitemtest") or getActivatedMods():contains("VFExpansion2ID");

end

function Recipe.OnTest.isActivated_Grenade(recipe, playerObj, item)

    return (getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) or getActivatedMods():contains("PRitemtest");

end

--recipe on create recycle ammo

function Recipe.OnCreate.Recycle177BB(items, result, player)

	player:getInventory():AddItems("Base.ScrapMetal", 1);

end

function Recipe.OnCreate.Recycle545x39(items, result, player)

	local grains56 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.56);
	player:getInventory():AddItem(grains56);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle223Rem(items, result, player)

    local grains48 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.48);
	player:getInventory():AddItem(grains48);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle556x45NATO(items, result, player)

    local grains50 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.50);
	player:getInventory():AddItem(grains50);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle57x28(items, result, player)

    local grains12 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.12);
	player:getInventory():AddItem(grains12);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle22LR(items, result, player)

    local grains4 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.04);
	player:getInventory():AddItem(grains4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightSRim", 1);

end

function Recipe.OnCreate.Recycle58x42mm(items, result, player)

    local grains4 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.56);
	player:getInventory():AddItem(grains4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle25ACP(items, result, player)

    local grains4 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.04);
	player:getInventory():AddItem(grains4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle65x50SRAris(items, result, player)

    local grains66 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.66);
	player:getInventory():AddItem(grains66);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle65x52Carc(items, result, player)

    local grains64 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.64);
	player:getInventory():AddItem(grains64);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.RecycleSalvagedBullets(items, result, player)

    local grains50 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.50);
	player:getInventory():AddItem(grains50);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle3030Win(items, result, player)

    local grains60 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.60);
	player:getInventory():AddItem(grains60);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckMRim", 1);

end

function Recipe.OnCreate.Recycle30Carbine(items, result, player)

    local grains26 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.26);
	player:getInventory():AddItem(grains26);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightM", 1);

end

function Recipe.OnCreate.Recycle762x25Tok(items, result, player)

    local grains12 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.12);
	player:getInventory():AddItem(grains12);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle762x38RNag(items, result, player)

    local grains8 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.08);
	player:getInventory():AddItem(grains8);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle762x51NATO(items, result, player)

    local grains86 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.86);
	player:getInventory():AddItem(grains86);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle75x54(items, result, player)

    local grains92 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.92);
	player:getInventory():AddItem(grains92);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle3006Spring(items, result, player)

    local grains4 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.04);
	player:getInventory():AddItem(grains4);
    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 1);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle308Win(items, result, player)

    local grains90 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.90);
	player:getInventory():AddItem(grains90);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle762x39(items, result, player)

    local grains50 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.50);
	player:getInventory():AddItem(grains50);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle303British(items, result, player)

    local grains74 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.74);
	player:getInventory():AddItem(grains74);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckMRim", 1);

end

function Recipe.OnCreate.Recycle762x54R(items, result, player)

    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 1);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckMRim", 1);

end

function Recipe.OnCreate.Recycle32ACP(items, result, player)

    local grains6 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.06);
	player:getInventory():AddItem(grains6);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle792x33Kurz(items, result, player)

    local grains42 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.42);
	player:getInventory():AddItem(grains42);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle792x57Maus(items, result, player)

    local grains92 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.92);
	player:getInventory():AddItem(grains92);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle8x50RLeb(items, result, player)

    local grains70 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.70);
	player:getInventory():AddItem(grains70);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckMRim", 1);

end

function Recipe.OnCreate.Recycle8x27RLeb(items, result, player)

    local grains18 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.18);
	player:getInventory():AddItem(grains18);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle86mmBLK(items, result, player)

    local grains90 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.90);
	player:getInventory():AddItem(grains90);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckM", 1);

end

function Recipe.OnCreate.Recycle338Lapua(items, result, player)

    local grains80 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.80);
	player:getInventory():AddItem(grains80);
	player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 1);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckL", 1);

end

function Recipe.OnCreate.Recycle380ACP(items, result, player)

    local grains6 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.06);
	player:getInventory():AddItem(grains6);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle9x25Maus(items, result, player)

    local grains12 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.12);
	player:getInventory():AddItem(grains12);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle9mmLuger(items, result, player)

    local grains10 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.10);
	player:getInventory():AddItem(grains10);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle38SP(items, result, player)

    local grains12 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.12);
	player:getInventory():AddItem(grains12);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle357Mag(items, result, player)

    local grains18 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.18);
	player:getInventory():AddItem(grains18);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle9x39(items, result, player)

    local grains20 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.20);
	player:getInventory():AddItem(grains20);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckS", 1);

end

function Recipe.OnCreate.Recycle9x18Mak(items, result, player)

    local grains6 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.06);
	player:getInventory():AddItem(grains6);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.RecycleScrapBullets(items, result, player)

    local grains14 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.14);
	player:getInventory():AddItem(grains14);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightS", 1);

end

function Recipe.OnCreate.Recycle410GBuck00(items, result, player)

    local grains24 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.24);
	player:getInventory():AddItem(grains24);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Ball00", 6);

end

function Recipe.OnCreate.Recycle10mmAuto(items, result, player)

    local grains18 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.18);
	player:getInventory():AddItem(grains18);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightM", 1);

end

function Recipe.OnCreate.Recycle40SW(items, result, player)

    local grains14 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.14);
	player:getInventory():AddItem(grains14);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightM", 1);

end

function Recipe.OnCreate.Recycle4440WCF(items, result, player)

    local grains20 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.20);
	player:getInventory():AddItem(grains20);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle44Mag(items, result, player)

    local grains30 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.30);
	player:getInventory():AddItem(grains30);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle45ACP(items, result, player)

    local grains16 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.16);
	player:getInventory():AddItem(grains16);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightM", 1);

end

function Recipe.OnCreate.Recycle45LC(items, result, player)

    local grains16 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.16);
	player:getInventory():AddItem(grains16);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightMRim", 1);

end

function Recipe.OnCreate.Recycle4570Gov(items, result, player)

    local grains90 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.90);
	player:getInventory():AddItem(grains90);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightLRim", 1);

end

function Recipe.OnCreate.Recycle50AE(items, result, player)

    local grains60 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.60);
	player:getInventory():AddItem(grains60);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightL", 1);

end

function Recipe.OnCreate.Recycle50BMG(items, result, player)

    local grains40 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.40);
	player:getInventory():AddItem(grains40);
    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsBottleneckL", 1);

end

function Recipe.OnCreate.Recycle127x55(items, result, player)

    local grains90 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.90);
	player:getInventory():AddItem(grains90);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsStraightL", 1);

end

function Recipe.OnCreate.Recycle58Minie(items, result, player)

    local grains80 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.80);
	player:getInventory():AddItem(grains80);
    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 1);

	player:getInventory():AddItems("Base.ScrapMetal", 1);

end

function Recipe.OnCreate.Recycle20GBuck00(items, result, player)

    local grains32 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.32);
	player:getInventory():AddItem(grains32);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Ball00", 8);

end

function Recipe.OnCreate.Recycle12GBuck00(items, result, player)

    local grains40 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.40);
	player:getInventory():AddItem(grains40);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Ball00", 10);

end

function Recipe.OnCreate.Recycle12GRubber(items, result, player)

    local grains40 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.40);
	player:getInventory():AddItem(grains40);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_RecRubber", 1);

end

function Recipe.OnCreate.Recycle12GSlug(items, result, player)

    local grains40 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.40);
	player:getInventory():AddItem(grains40);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Slug12", 1);

end

function Recipe.OnCreate.Recycle12GFlare(items, result, player)

    local grains80 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.80);
	player:getInventory():AddItem(grains80);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunS", 1);

end

function Recipe.OnCreate.Recycle10GBuck00(items, result, player)

    local grains90 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.90);
	player:getInventory():AddItem(grains90);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunL", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Ball00", 12);

end

function Recipe.OnCreate.Recycle4GBuck00(items, result, player)

    local grains20 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.20);
	player:getInventory():AddItem(grains20);
    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 1);

	player:getInventory():AddItems("ammomaker.ammomaker_HullShotgunL", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_Ball00", 30);

end

function Recipe.OnCreate.RecycleBlunderbussPellets(items, result, player)

    local grains50 = InventoryItemFactory.CreateItem("ammomaker.ammomaker_GunPowderGrains", 0.5);
	player:getInventory():AddItem(grains50);
    player:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", 7);

	player:getInventory():AddItems("Base.ScrapMetal", 4);

end

function Recipe.OnCreate.Recycle40mmHE(items, result, player)

    local gunpowderU4 = InventoryItemFactory.CreateItem("Base.GunPowder", 0.4);
	player:getInventory():AddItem(gunpowderU4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsGrenade", 1);

end

function Recipe.OnCreate.Recycle40mmINC(items, result, player)

    local gunpowderU4 = InventoryItemFactory.CreateItem("Base.GunPowder", 0.4);
	player:getInventory():AddItem(gunpowderU4);

	player:getInventory():AddItems("ammomaker.ammomaker_PartsGrenade", 1);

end

function Recipe.OnCreate.RecycleHERocket(items, result, player)

    player:getInventory():AddItems("Base.GunPowder", 4);

	player:getInventory():AddItems("Base.ElectronicsScrap", 5);
	player:getInventory():AddItems("Base.ScrapMetal", 4);
	player:getInventory():AddItems("Base.SheetMetal", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 2);

end

function Recipe.OnCreate.RecycleNailBomb(items, result, player)

    local gunpowderU7 = InventoryItemFactory.CreateItem("Base.GunPowder", 0.7);
	player:getInventory():AddItem(gunpowderU7);

	player:getInventory():AddItems("Base.Nails", 25);
	local twineU1 = InventoryItemFactory.CreateItem("Base.Twine", 0.2);
	player:getInventory():AddItem(twineU1);
	player:getInventory():AddItems("Base.TinCanEmpty", 1);

end

function Recipe.OnCreate.RecycleGlassBomb(items, result, player)

    player:getInventory():AddItems("Base.GunPowder", 1);

	local twineU1 = InventoryItemFactory.CreateItem("Base.Twine", 0.2);
	player:getInventory():AddItem(twineU1);
	player:getInventory():AddItems("Base.EmptyJar", 1);

end

function Recipe.OnCreate.RecyclePipeBomb(items, result, player)

    player:getInventory():AddItems("Base.GunPowder", 2);

	local twineU1 = InventoryItemFactory.CreateItem("Base.Twine", 0.2);
	player:getInventory():AddItem(twineU1);
	player:getInventory():AddItems("Base.MetalPipe", 1);

end

function Recipe.OnCreate.RecycleDecoy(items, result, player)

    local gunpowderU4 = InventoryItemFactory.CreateItem("Base.GunPowder", 0.4);
	player:getInventory():AddItem(gunpowderU4);

	local twineU1 = InventoryItemFactory.CreateItem("Base.Twine", 0.2);
	player:getInventory():AddItem(twineU1);
	player:getInventory():AddItems("Base.TinCanEmpty", 1);

end

function Recipe.OnCreate.RecycleArrowWoodenAM(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_ArrowFletching", 3);
	player:getInventory():AddItems("ammomaker.ammomaker_ArrowHead", 1);
	player:getInventory():AddItems("Base.Twigs", 1);

end

function Recipe.OnCreate.RecycleBoltWoodenAM(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_ArrowFletching", 6);
	player:getInventory():AddItems("ammomaker.ammomaker_ArrowHead", 2);
	player:getInventory():AddItems("Base.Twigs", 1);

end

function Recipe.OnCreate.RecycleBoltHFE(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_ArrowFletching", 6);
	player:getInventory():AddItems("ammomaker.ammomaker_ArrowHead", 2);
	player:getInventory():AddItems("Base.ScrapMetal", 2);

end

function Recipe.OnCreate.RecycleBoltWoodenHFE(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_ArrowFletching", 6);
	player:getInventory():AddItems("ammomaker.ammomaker_ArrowHead", 2);
	player:getInventory():AddItems("Base.Twigs", 1);

end

function Recipe.OnCreate.RecycleBlowgunDartsHFE(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_ArrowFletching", 16);
	player:getInventory():AddItems("ammomaker.ammomaker_ArrowHead", 4);
	player:getInventory():AddItems("Base.ScrapMetal", 2);

end

--recipe on create recycle ammo parts

function Recipe.OnCreate.RecycleHullShotgunS(items, result, player)

	player:getInventory():AddItems("Base.ScrapMetal", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 1);

end

function Recipe.OnCreate.RecycleHullShotgunL(items, result, player)

	player:getInventory():AddItems("Base.ScrapMetal", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 1);

end

function Recipe.OnCreate.RecyclePartsGrenade(items, result, player)

	player:getInventory():AddItems("Base.ScrapMetal", 1);
	player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 1);

end

--recipe on create items

function Recipe.OnCreate.WeighGunpowderUnit(items, result, player)

	local gunpowderU1 = InventoryItemFactory.CreateItem("Base.GunPowder", 0.1);
	player:getInventory():AddItem(gunpowderU1);

end

function Recipe.OnCreate.ExtractSulfur(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_Sulfur", 10);
	player:getInventory():AddItems("Base.Gravelbag", 1);

end

function Recipe.OnCreate.ExtractNitre(items, result, player)

	player:getInventory():AddItems("ammomaker.ammomaker_Nitre", SandboxVars.ammomakerOptions.NitreYield);
	player:getInventory():AddItems("Base.Pot", 1);

end

function Recipe.OnCreate.RecyclePlastic(items, result, player)

	local item = items:get(0);
		
	if item:getType() == "BleachEmpty"
	or item:getType() == "Cube"
	or item:getType() == "Comb"
	or item:getType() == "Razor" then

		player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 2);

	elseif item:getType() == "CuttingBoardPlastic" then

		player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 3);

	elseif item:getType() == "Lunchbox"
	or item:getType() == "Lunchbox2"
	or item:getType() == "BucketEmpty" then

		player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 10);
		
	elseif item:getType() == "Cooler" then

		player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 15);

	else
		
		player:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", 1);

	end

end

function Recipe.OnCreate.RecycleRubber(items, result, player)

	local item = items:get(0);
		
	if item:getType() == "OldTire1"
	or item:getType() == "OldTire2"
	or item:getType() == "OldTire3"
	or item:getType() == "NormalTire1"
	or item:getType() == "NormalTire2"
	or item:getType() == "NormalTire3"
	or item:getType() == "ModernTire1"
	or item:getType() == "ModernTire2"
	or item:getType() == "ModernTire3" then

		player:getInventory():AddItems("ammomaker.ammomaker_RecRubber", 49);
		player:getInventory():AddItems("Base.ScrapMetal", 50);

	end

end

function Recipe.OnCreate.MakeFilterPaper(items, result, player)

	local item = items:get(0);

	if item:getType() == "SheetPaper2" then

		player:getInventory():AddItems("ammomaker.ammomaker_FilterPaper", 1);

	elseif item:getType() == "Doodle" then

		player:getInventory():AddItems("ammomaker.ammomaker_FilterPaper", 3);

	elseif item:getType() == "Notebook" then

		player:getInventory():AddItems("ammomaker.ammomaker_FilterPaper", 10);
		
	elseif item:getType() == "Journal" then

		player:getInventory():AddItems("ammomaker.ammomaker_FilterPaper", 20);

	end

end

function Recipe.OnCreate.RecycleMetal(items, result, player)

	local item = items:get(0);
	
	if item:getType() == "TinCanEmpty" then

		player:getInventory():AddItems("Base.ScrapMetal", 2);

	elseif item:getType() == "UnusableMetal" then

		player:getInventory():AddItems("Base.ScrapMetal", 10);
	
	end

end

function Recipe.OnCreate.RecycleJewelryChain(items, result, player)

	local item = items:get(0);
		
	if item:getType() == "Bracelet_ChainRightGold"
	or item:getType() == "Bracelet_ChainLeftGold"
	or item:getType() == "Bracelet_ChainRightSilver"
	or item:getType() == "Bracelet_ChainLeftSilver" then

		player:getInventory():AddItems("ammomaker.ammomaker_JewelryChain", 1);

	elseif item:getType() == "Necklace_Gold"
	or item:getType() == "Necklace_Silver"
	or item:getType() == "Necklace_DogTag"
	or item:getType() == "Necklace_GoldRuby"
	or item:getType() == "Necklace_GoldDiamond"
	or item:getType() == "Necklace_SilverSapphire"
	or item:getType() == "Necklace_SilverCrucifix"
	or item:getType() == "Necklace_SilverDiamond" then

		player:getInventory():AddItems("ammomaker.ammomaker_JewelryChain", 2);

	elseif item:getType() == "NecklaceLong_Gold"
	or item:getType() == "NecklaceLong_Silver"
	or item:getType() == "NecklaceLong_GoldDiamond"
	or item:getType() == "NecklaceLong_SilverEmerald"
	or item:getType() == "NecklaceLong_SilverSapphire"
	or item:getType() == "NecklaceLong_SilverDiamond" then

		player:getInventory():AddItems("ammomaker.ammomaker_JewelryChain", 3);

	end

end

--recipe on give xp

function Recipe.OnGiveXP.MetalWelding5(recipe, ingredients, result, player)

    player:getXp():AddXP(Perks.MetalWelding, 5);

end

function Recipe.OnGiveXP.Reloading3(recipe, ingredients, result, player)

    player:getXp():AddXP(Perks.Reloading, 3);

end

function Recipe.OnGiveXP.Chemistry3(recipe, ingredients, result, player)

	player:getXp():AddXP(Perks.MetalWelding, 3);
	player:getXp():AddXP(Perks.Cooking, 3);

end