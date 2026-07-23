--i'm using @Jabdoesthings (on discord) extension for visual studio code! it's pretty neat!
require 'Items/SuburbsDistributions'
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"



--[[ sapph: Hello! sapph here, so, there are alot of better ways to add distributions, using lists and stuff like that...
 but... that's a job for greater minds than me!
 i just did the old way, manually adding stuff, so if you're trying to learn, you should probably check some guides around there. 
 have fun! 


 also, this section with sandbox settings was made by poltergeist, he's around in the official pz discord doing helpful stuff
 so huge thanks to him! --]]
 
local function addSandboxLoot()

--Item drops.
--Set Sandbox Settings values.
local PerishableSpawnChance = SandboxVars.SapphCooking.PerishableChance; 
local NonPerishableSpawnChance = SandboxVars.SapphCooking.NonPerishableChance; 
local MagazineSpawnChance = SandboxVars.SapphCooking.MagazineChance; 
local MRESpawnChance = SandboxVars.SapphCooking.MREChance; 
local KitchenUtensilsSpawnChance = SandboxVars.SapphCooking.KitchenUtensilsChance;
local AlcoholSpawnChance = SandboxVars.SapphCooking.AlcoholChance;
local ZombieSpawnChance = SandboxVars.SapphCooking.ZombieLootSpawn;
local SpicesSpawnChance = SandboxVars.SapphCooking.SpicesSpawnChance;
local CannedSpawnChance = SandboxVars.SapphCooking.CannedSpawnChance;

--Default value is 3.

--Creates  the values.
--[[
local spawnChances = {
    PerishableSpawnChance = SandboxVars.SapphCooking.PerishableChance; 
    NonPerishableSpawnChance = SandboxVars.SapphCooking.NonPerishableChance; 
    MagazineSpawnChance = SandboxVars.SapphCooking.MagazineChance; 
    MRESpawnChance = SandboxVars.SapphCooking.MREChance; 
    KitchenUtensilsSpawnChance = SandboxVars.SapphCooking.KitchenUtensilsChance;
    AlcoholSpawnChance = SandboxVars.SapphCooking.AlcoholChance;
    ZombieSpawnChance = SandboxVars.SapphCooking.ZombieLootSpawn;
	--with this you can easily add items
}
--If value == 6, then it is equal to 0.
for key, value in pairs(spawnChances) do
    if (spawnChances[key] == 6) then
        spawnChances[key] = 0;
    end
end
--]]

--sapph: so, for some reason, the code above wasn't working, it never changed any value to 0,
--and since i'm really not in a good mental health to fix this, i just did the easiest fix on it!
--i will go back and fix it in future updates!


if (PerishableSpawnChance == 7) then
PerishableSpawnChance = 0;
end

if (NonPerishableSpawnChance == 7) then
NonPerishableSpawnChance = 0;
end

if (CannedSpawnChance == 7) then
    CannedSpawnChance = 0;
end

if (SpicesSpawnChance == 7) then
    SpicesSpawnChance = 0;
end
    

if (MagazineSpawnChance == 7) then
MagazineSpawnChance = 0;
end

if (MRESpawnChance == 7) then
MRESpawnChance = 0;
end

if (KitchenUtensilsSpawnChance == 7) then
KitchenUtensilsSpawnChance = 0;
end

if (AlcoholSpawnChance == 7) then
AlcoholSpawnChance = 0;
end

if (ZombieSpawnChance == 7) then
ZombieSpawnChance = 0;
end

--zombie spawn
table.insert(SuburbsDistributions["all"]["inventorymale"].items, "SapphCooking.FortuneCookie");
table.insert(SuburbsDistributions["all"]["inventorymale"].items, ZombieSpawnChance * 0.0000001);
table.insert(SuburbsDistributions["all"]["inventorymale"].items,  "SapphCooking.ProteinBar");
table.insert(SuburbsDistributions["all"]["inventorymale"].items, ZombieSpawnChance * 0.00009);

table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "SapphCooking.ProteinBar");
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, ZombieSpawnChance * 0.00009);
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "SapphCooking.FortuneCookie");
table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, ZombieSpawnChance * 0.0000001);

--Kitchen Pots

table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.WokPan");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.WoodenSpoon");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.CoffeeGrinder");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.PlasticFilterHolder");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.EmptyThermos");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.Empty_FrenchPress");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, "SapphCooking.SapphCooking.Blender");
table.insert(ProceduralDistributions["list"]["KitchenPots"].items, KitchenUtensilsSpawnChance * 0.8);


--Kitchen Canned Foods
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CanofProteinPowder");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofWontonWrappers");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CoffeeBeansBag");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.PackofCoffeeFilters");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CanofRefriedBeans");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CannedBread");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CanofKernelCorn");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CannedSausages");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
--[[table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack1");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack2");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack3");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack4");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack5");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack6");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack7");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack8");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack9");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack10");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.MRE_Pack12");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, MRESpawnChance * 0.0004);
I have no idea why it keeps spawning, so i'll just disable for now!--]]
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Lemon");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Orange");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Pineapple");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Strawberry");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Watermelon");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Drinkmix_Peach");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BeefBroth");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.ChickenBroth");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.ArborioRice");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BrownRice");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofSeaweed");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofFlourTortillas");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.GranulatedSugar");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "Base.BakingSoda");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofMarshmallows");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CanofBeets");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Jello_Lime");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Jello_Orange");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Jello_Strawberry");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Jello_Pineapple");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Jello_Grape");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BoxofTeaBags");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.CannedBacon");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, CannedSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.PowderedEggs");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Box_Bonbon");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.0005);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Box_LiqueurBonbons");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.0005);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofWoodenSkewers");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.BagofToothpicks");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.PipingBags");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, KitchenUtensilsSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.ClothFilter");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, KitchenUtensilsSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Syrup_Chocolate");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Syrup_Strawberry");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Syrup_Caramel");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.InstantNoodles_Beef");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.InstantNoodles_Chicken");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, "SapphCooking.Spice_OysterSauce");
table.insert(ProceduralDistributions["list"]["KitchenCannedFood"].items, SpicesSpawnChance * 0.4);







--Fridges Generic
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BrownEggCarton");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.ParmesanCheese");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.MozzarelaCheese");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofMashedPotatoes");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofFriedRice");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BrownRiceBowl");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.ArborioRiceBowl");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofRavioli");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofQueso");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofTortellini");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofBeefStew");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.CreamCheese");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.LasagnaPiece");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.Meatballs");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.SapphCutCheeseSandwich");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlofInstantNoodles");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlJello_Lime");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlJello_Strawberry");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlJello_Orange");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlJello_Pineapple");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.BowlJello_Grape");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.ChurrosPlain");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.Plate_BaconandEggs");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, PerishableSpawnChance * 0.016);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.WhippedCream_Can");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "SapphCooking.CheeseSpray_Can");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, NonPerishableSpawnChance * 0.05);




--FridgeRich
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.ParmesanCheese");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.MozzarelaCheese");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.CreamCheese");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.LasagnaPiece");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.Meatballs");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.SapphCutCheeseSandwich");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.BowlofYakisoba");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.BowlofKungPaoChicken");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.BowlofShuiZhuYu");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.BowlofJapaneseCurry");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.TinofCaviar");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, NonPerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.TiramisuPiece");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.Seitan");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.2)
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.Spice_PestoBowl");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.08)
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.BlueCheese");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, PerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "SapphCooking.StrawberryMilk");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, NonPerishableSpawnChance * 0.5);

--BinGeneric
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, "SapphCooking.WoodenSkewers");
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, KitchenUtensilsSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, "SapphCooking.BagofToothpicks");
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, NonPerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, "SapphCooking.BagofWoodenSkewers");
table.insert(ProceduralDistributions["list"]["BinGeneric"].items, NonPerishableSpawnChance * 0.05);

--KitchenBreakfast
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, "SapphCooking.CoffeeBeansBag");
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, "SapphCooking.PackofCoffeeFilters");
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, "SapphCooking.BoxofTeaBags");
table.insert(ProceduralDistributions["list"]["KitchenBreakfast"].items, NonPerishableSpawnChance * 0.5);

--DishCabinetGeneric
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CanofRefriedBeans");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BagofWontonWrappers");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CoffeeBeansBag");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.PackofCoffeeFilters");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CanofKernelCorn");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BeefBroth");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.ChickenBroth");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Lemon");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Orange");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Pineapple");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Strawberry");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Watermelon");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Peach");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Drinkmix_Apple");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.ArborioRice");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BrownRice");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BagofMarshmallows");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CurryPowder");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CanofBeets");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Jello_Lime");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Jello_Orange");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Jello_Strawberry");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Jello_Pineapple");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Jello_Grape");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.CannedBacon");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, CannedSpawnChance * 0.052);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.PipingBags");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BagofWoodenSkewers");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.PowderedEggs");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, CannedSpawnChance * 0.06);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.MessTray");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.ClothFilter");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.02);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Syrup_Chocolate");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Syrup_Strawberry");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Syrup_Caramel");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.BagofToothpicks");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Gloves_OvenMitten_White");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Gloves_OvenMitten_Udderly");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.InstantNoodles_Beef");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.InstantNoodles_Chicken");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, NonPerishableSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Empty_FrenchPress");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.SapphCooking.Blender");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, KitchenUtensilsSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Spice_Furikake");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.03);
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, "SapphCooking.Spice_OysterSauce");
table.insert(ProceduralDistributions["list"]["DishCabinetGeneric"].items, SpicesSpawnChance * 0.03);





--FreezerGeneric
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, "SapphCooking.Meatballs");
table.insert(ProceduralDistributions["list"]["FreezerGeneric"].items, PerishableSpawnChance * 0.6);


--GigamartDryGoods
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.BrownRice");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.ArborioRice");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.BagofFlourTortillas");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.20);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.BagofSeaweed");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Lemon");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Orange");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Pineapple");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Strawberry");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Watermelon");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Peach");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Drinkmix_Apple");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.BagofMarshmallows");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.CurryPowder");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Jello_Lime");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Jello_Orange");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Jello_Strawberry");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Jello_Pineapple");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Jello_Grape");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.BoxofTeaBags");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Syrup_Chocolate");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Syrup_Strawberry");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Syrup_Caramel");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Spice_OysterSauce");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, "SapphCooking.Spice_Furikake");
table.insert(ProceduralDistributions["list"]["GigamartDryGoods"].items, SpicesSpawnChance * 0.4);


--GigamartCannedFood
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CoffeeBeansBag");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.PackofCoffeeFilters");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CannedSausages");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CanofRefriedBeans");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CannedBread");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CanofKernelCorn");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.BagofFlourTortillas");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, NonPerishableSpawnChance * 0.20);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "Base.BakingSoda");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, NonPerishableSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.TinofCaviar");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, SpicesSpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, "SapphCooking.CanofBeets");
table.insert(ProceduralDistributions["list"]["GigamartCannedFood"].items, CannedSpawnChance * 1.2);


--GigamartCandy
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.PackofCandyCigarretes");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.BagofMarshmallows");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Box_Bonbon");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Box_LiqueurBonbons");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Heart_Chocolate");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Bonbon");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Bonbon_Liqueur");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.ChocolateEgg_Small");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.22);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.ChocolateEgg_Medium");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.22);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.ChocolateEgg_Large");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.22);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Gingerbread_Man");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Syrup_Chocolate");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, SpicesSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Syrup_Strawberry");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, SpicesSpawnChance * 0.08);
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, "SapphCooking.Syrup_Caramel");
table.insert(ProceduralDistributions["list"]["GigamartCandy"].items, SpicesSpawnChance * 0.08);


--GigamartHousewares
table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, KitchenUtensilsSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, "SapphCooking.EmptyThermos");
table.insert(ProceduralDistributions["list"]["GigamartHousewares"].items, KitchenUtensilsSpawnChance * 1);

--GigamartPots
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, "SapphCooking.WokPan");
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, KitchenUtensilsSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, KitchenUtensilsSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, "SapphCooking.MessTray");
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, KitchenUtensilsSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, "SapphCooking.PizzaPeel");
table.insert(ProceduralDistributions["list"]["GigamartPots"].items, KitchenUtensilsSpawnChance * 0.08);

--GigamartSauce
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "Base.Soysauce");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.6);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.CurryPowder");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 1);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.SoySauce_Sachet");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.Mustard_Sachet");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.Tomato_Sachet");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.MonosodiumGlutamate_MSG");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, "SapphCooking.PeanutButter_Sachet");
table.insert(ProceduralDistributions["list"]["GigamartSauce"].items, SpicesSpawnChance * 0.5);




--BakeryBread
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "SapphCooking.Banana_Bread");
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, "SapphCooking.Sausage_PigBlanket");
table.insert(ProceduralDistributions["list"]["BakeryBread"].items, PerishableSpawnChance * 0.9)


--CafeteriaSandwiches
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, "SapphCooking.Empty_FrenchPress");
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, KitchenUtensilsSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, "SapphCooking.Sausage_PigBlanket");
table.insert(ProceduralDistributions["list"]["CafeteriaSandwiches"].items, PerishableSpawnChance * 0.9)



--BakeryKitchenBaking
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.GranulatedSugar");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PastaDough");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.BagelShapedDough");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PastaSheets");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.Banana_Bread");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PipingBag_PastryDough");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PipingBag_Icing");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PastryDough");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PipingBags");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.Gloves_OvenMitten_White");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.Gloves_OvenMitten_Udderly");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, "SapphCooking.PizzaPeel");
table.insert(ProceduralDistributions["list"]["BakeryKitchenBaking"].items, KitchenUtensilsSpawnChance * 1.2);


--KitchenBaking
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, "SapphCooking.Gloves_OvenMitten_White");
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, "SapphCooking.Gloves_OvenMitten_Udderly");
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, "SapphCooking.PizzaPeel");
table.insert(ProceduralDistributions["list"]["KitchenBaking"].items, KitchenUtensilsSpawnChance * 0.03);


--BakeryMisc
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "SapphCooking.Box_Bonbon");
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "SapphCooking.Box_LiqueurBonbons");
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, NonPerishableSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "SapphCooking.Heart_Chocolate");
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "SapphCooking.Bonbon");
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, "SapphCooking.PizzaPeel");
table.insert(ProceduralDistributions["list"]["BakeryMisc"].items, KitchenUtensilsSpawnChance * 0.05);





--StoreKitchenBaking
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.GranulatedSugar");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PastaDough");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.BagelShapedDough");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PastaSheets");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PipingBag_PastryDough");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PipingBag_Icing");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, PerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PastryDough");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, PerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PipingBags");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.FortuneCookie");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.SapphCooking.Blender");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, KitchenUtensilsSpawnChance * 0.8);
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, "SapphCooking.PizzaPeel");
table.insert(ProceduralDistributions["list"]["StoreKitchenBaking"].items, KitchenUtensilsSpawnChance * 0.05);




--StoreKitchenGlasses
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, "SapphCooking.CocktailGlass");
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, KitchenUtensilsSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, "SapphCooking.CocktailMixer");
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, "SapphCooking.LowballGlass");
table.insert(ProceduralDistributions["list"]["StoreKitchenGlasses"].items, KitchenUtensilsSpawnChance * 0.11);


--GigamartBakingMisc
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.PipingBags");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 1.8);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.CoffeeGrinder");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.PlasticFilterHolder");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.MessTray");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.Gloves_OvenMitten_White");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.Gloves_OvenMitten_Udderly");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["GigamartBakingMisc"].items, KitchenUtensilsSpawnChance * 0.5);


--BurgerKitchenSauce
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.SaltPacket");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.SugarPacket");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.HotsaucePacket");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.CurryPowder");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.SoySauce_Sachet");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.Mustard_Sachet");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.Tomato_Sachet");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, "SapphCooking.MonosodiumGlutamate_MSG");
table.insert(ProceduralDistributions["list"]["BurgerKitchenSauce"].items, SpicesSpawnChance * 0.5);

--BarShelfLiquor
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.CocktailGlass");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, KitchenUtensilsSpawnChance * 6.65);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.CocktailMixer");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.LowballGlass");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, KitchenUtensilsSpawnChance * 6.65);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.CachacaFull");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.SakeFull");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, AlcoholSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "SapphCooking.EnergyDrink");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, NonPerishableSpawnChance * 0.05);

--BarCounterGlasses
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, "SapphCooking.CocktailGlass");
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, KitchenUtensilsSpawnChance * 6.65);
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, "SapphCooking.CocktailMixer");
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, "SapphCooking.LowballGlass");
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, KitchenUtensilsSpawnChance * 6.65);


--StoreKitchenPots
table.insert(ProceduralDistributions["list"]["StoreKitchenPots"].items, "SapphCooking.WokPan");
table.insert(ProceduralDistributions["list"]["StoreKitchenPots"].items, KitchenUtensilsSpawnChance * 0.4);
table.insert(ProceduralDistributions["list"]["StoreKitchenPots"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["StoreKitchenPots"].items, KitchenUtensilsSpawnChance * 1.2);


--StoreKitchenCutlery
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.WokPan");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.CoffeeGrinder");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.PlasticFilterHolder");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.MessTray");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.3);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.ChefKnife1");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.05);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.Gloves_OvenMitten_White");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.7);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.Gloves_OvenMitten_Udderly");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.7);
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["StoreKitchenCutlery"].items, KitchenUtensilsSpawnChance * 0.05);

--CrateOilVegetable
table.insert(ProceduralDistributions["list"]["CrateOilVegetable"].items, "SapphCooking.PeanutOil");
table.insert(ProceduralDistributions["list"]["CrateOilVegetable"].items, NonPerishableSpawnChance * 0.11);

--GrillAcessories
table.insert(ProceduralDistributions["list"]["GrillAcessories"].items, "SapphCooking.MeatTenderizer");
table.insert(ProceduralDistributions["list"]["GrillAcessories"].items, KitchenUtensilsSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["GrillAcessories"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["GrillAcessories"].items, KitchenUtensilsSpawnChance * 0.5);

--CrateChocolate
table.insert(ProceduralDistributions["list"]["CrateChocolate"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["CrateChocolate"].items, NonPerishableSpawnChance * 0.11);

--CrateRice
table.insert(ProceduralDistributions["list"]["CrateRice"].items, "SapphCooking.BrownRice");
table.insert(ProceduralDistributions["list"]["CrateRice"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CrateRice"].items, "SapphCooking.ArborioRice");
table.insert(ProceduralDistributions["list"]["CrateRice"].items, NonPerishableSpawnChance * 0.11);

--FridgeSnacks
table.insert(ProceduralDistributions["list"]["FridgeSnacks"].items, "SapphCooking.Spice_PestoBowl");
table.insert(ProceduralDistributions["list"]["FridgeSnacks"].items, PerishableSpawnChance * 0.5);



--SpiffosDiningCounter 
table.insert(ProceduralDistributions["list"]["SpiffosDiningCounter"].items, "SapphCooking.FortuneCookie");
table.insert(ProceduralDistributions["list"]["SpiffosDiningCounter"].items, NonPerishableSpawnChance * 0.4);



--ChineseKitchenBaking
table.insert(ProceduralDistributions["list"]["ChineseKitchenBaking"].items, "SapphCooking.FortuneCookie");
table.insert(ProceduralDistributions["list"]["ChineseKitchenBaking"].items, NonPerishableSpawnChance * 1.2);


--ServingTrayNoodleSoup 
table.insert(ProceduralDistributions["list"]["ServingTrayNoodleSoup"].items, "SapphCooking.FortuneCookie");
table.insert(ProceduralDistributions["list"]["ServingTrayNoodleSoup"].items, NonPerishableSpawnChance * 1.8);

--ServingTrayChickenNuggets 
table.insert(ProceduralDistributions["list"]["ServingTrayChickenNuggets"].items, "SapphCooking.FortuneCookie");
table.insert(ProceduralDistributions["list"]["ServingTrayChickenNuggets"].items, NonPerishableSpawnChance * 1.8);

--FridgeSoda
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofLemonJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofOrangeJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofPineappleJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofOrangeJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofAppleJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofStrawberryJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofPeachJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofWatermelonJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.BottleofGrapeJuice");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 1.2);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "SapphCooking.EnergyDrink");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, NonPerishableSpawnChance * 0.2);

--StoreShelfSnacks
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.ChocolateEgg_Small");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.ChocolateEgg_Medium");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.ChocolateEgg_Large");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.66); 
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.Box_Bonbon");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.Box_LiqueurBonbons");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.Heart_Chocolate");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, "SapphCooking.Bonbon");
table.insert(ProceduralDistributions["list"]["StoreShelfSnacks"].items, NonPerishableSpawnChance * 0.56);


--CafeteriaSnacks
table.insert(ProceduralDistributions["list"]["CafeteriaSnacks"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["CafeteriaSnacks"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CafeteriaSnacks"].items, "SapphCooking.ChocolateEgg_Small");
table.insert(ProceduralDistributions["list"]["CafeteriaSnacks"].items, NonPerishableSpawnChance * 0.11);


--CrateCandyPackage
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, "SapphCooking.PackofCandyCigarretes");
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, "SapphCooking.ChocolateEgg_Small");
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, NonPerishableSpawnChance * 0.22);
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, "SapphCooking.ChocolateEgg_Medium");
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, NonPerishableSpawnChance * 0.22);
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, "SapphCooking.ChocolateEgg_Large");
table.insert(ProceduralDistributions["list"]["CrateCandyPackage"].items, NonPerishableSpawnChance * 0.22);


--BarCounterLiquor
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "SapphCooking.CocktailGlass");
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, KitchenUtensilsSpawnChance * 6.65);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "SapphCooking.LowballGlass");
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, KitchenUtensilsSpawnChance * 6.65);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "SapphCooking.CachacaFull");
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "SapphCooking.SakeFull");
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, AlcoholSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, "SapphCooking.CocktailMixer");
table.insert(ProceduralDistributions["list"]["BarCounterLiquor"].items, KitchenUtensilsSpawnChance * 0.5);

--CandyStoreSnacks
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.PackofCandyCigarretes");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.WhiteChocolate");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.BagofFlourTortillas");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.5);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.ChocolateEgg_Small");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.ChocolateEgg_Medium");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.ChocolateEgg_Large");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.66); 
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.Box_Bonbon");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.Box_LiqueurBonbons");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.2);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.Heart_Chocolate");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.Bonbon");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.56);
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, "SapphCooking.Bonbon_Liqueur");
table.insert(ProceduralDistributions["list"]["CandyStoreSnacks"].items, NonPerishableSpawnChance * 0.56);



--ButcherTools 
table.insert(ProceduralDistributions["list"]["ButcherTools"].items, "SapphCooking.Meatgrinder");
table.insert(ProceduralDistributions["list"]["ButcherTools"].items, KitchenUtensilsSpawnChance * 1.2);


--MRE
--TruckBed
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack1");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack2");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack3");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack4");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack5");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack6");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack7");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack8");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack9");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack10");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack11");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);
table.insert(VehicleDistributions.Police["TruckBed"].items, "SapphCooking.MRE_Pack12");
table.insert(VehicleDistributions.Police["TruckBed"].items, MRESpawnChance * 0.055);



--SurvivorCache1
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack1");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack2");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack3");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack4");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack5");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack6");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack7");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack8");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack9");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack10");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack11");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack12");
table.insert(SuburbsDistributions["SurvivorCache1"]["SurvivorCrate"].items, MRESpawnChance * 0.055);

--SurvivorCache2
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack1");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack2");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack3");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack4");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack5");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack6");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack7");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack8");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack9");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack10");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack11");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, "SapphCooking.MRE_Pack12");
table.insert(SuburbsDistributions["SurvivorCache2"]["SurvivorCrate"].items, MRESpawnChance * 0.055);

--HuntingLockers
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack1");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack2");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack3");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack4");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack5");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack6");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack7");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack8");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack9");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack10");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack11");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, "SapphCooking.MRE_Pack12");
table.insert(ProceduralDistributions["list"]["HuntingLockers"].items, MRESpawnChance * 0.07);

--LockerArmyBedroom
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack1");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack2");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack3");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack4");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack5");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack6");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack7");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack8");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack9");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack10");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack11");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, "SapphCooking.MRE_Pack12");
table.insert(ProceduralDistributions["list"]["LockerArmyBedroom"].items, MRESpawnChance * 0.07);

--ArmySurplusMisc
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack1");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack2");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack3");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack4");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack5");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack6");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack7");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack8");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack9");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack10");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack11");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, "SapphCooking.MRE_Pack12");
table.insert(ProceduralDistributions["list"]["ArmySurplusMisc"].items, MRESpawnChance * 0.055);


--Books

table.insert(ProceduralDistributions["list"]["CrateBooks"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, MagazineSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["CrateBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, MagazineSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["CampingStoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, MagazineSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["LivingRoomShelf"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, MagazineSpawnChance * 0.66);
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["PrisonGuardLockers"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["LibraryCounter"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreStationery"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["ClassroomShelves"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreMisc"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["KitchenBook"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, "SapphCooking.AsianFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, "SapphCooking.EuropeFoodMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, "SapphCooking.PastaDoughMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, MagazineSpawnChance * 0.11);
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, "SapphCooking.SausageMakingMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, MagazineSpawnChance * 0.11);
    ItemPickerJava.Parse();
end

--Readds and reloads the spawns, that way, it should account for the sandbox settings
local function parseTables()
    if ItemPickerJava.doParse then
        ItemPickerJava.Parse()
        ItemPickerJava.doParse = nil
    end
end

Events.OnInitGlobalModData.Add(addSandboxLoot);
Events.OnLoadedMapZones.Add(parseTables);





