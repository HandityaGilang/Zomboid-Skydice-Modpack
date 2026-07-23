--This code is for compatibility with AuthenticZ Attatchments



--Thanks Authentic Peach for the mod!
--Huge thanks to Glytch3r for the help optimizing the code!!

--Sapph: Hi, it's sapph from... 29/06/23 here, just wanna explain this really quick.
--it basically checks to see if  the ID authenticZ is activated, and if it is, it adds on the local items,  the attatchment for Canteen.
--that allows it to be compatible with that mod!

if getActivatedMods():contains("Authentic Z - Current") or getActivatedMods():contains("AuthenticZLite") or getActivatedMods():contains("AuthenticZBackpacks+") then

local items = {
  "SapphCooking.FullWaterThermos",
  "SapphCooking.EmptyThermos",
  "SapphCooking.ThermosBeverage",
  "SapphCooking.ThermosCoffee",
  "SapphCooking.ColaBottlewithMilk",
  "SapphCooking.WaterColaBottle",
  "SapphCooking.ColaBottleEmpty",
  "SapphCooking.ColaBottle",
  "SapphCooking.ColaBottlewithProteinShake",
  "SapphCooking.GinFull",
  "SapphCooking.GinEmpty",
  "SapphCooking.GinWaterFull",
  "SapphCooking.VodkaFull",
  "SapphCooking.VodkaEmpty",
  "SapphCooking.VodkaWaterFull",
  "SapphCooking.TequilaFull",
  "SapphCooking.TequilaEmpty",
  "SapphCooking.TequilaWaterFull",
  "SapphCooking.SakeFull",
  "SapphCooking.SakeEmpty",
  "SapphCooking.SakeWaterFull",
  "SapphCooking.EnergyDrink",
  "SapphCooking.ThermosCoffeeEvolved",
  "SapphCooking.ThermosSoup",
  "SapphCooking.Syrup_Chocolate",
  "SapphCooking.Syrup_Strawberry",
  "SapphCooking.Syrup_Caramel",
  "SapphCooking.Blender",
}

local manager = ScriptManager.instance

for _, item_name in pairs(items) do
  local item = manager:getItem(item_name)
  if item then
    item:DoParam("AttachmentType = Canteen")
  end
end

end
