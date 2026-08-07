--Only meats above a weight of 0.2
function TryMeat(sourceItem, result)
  if instanceof(sourceItem, "Food") then
      return sourceItem:getActualWeight() > 0.0
  end
  return true
end

function TryMeatLard(sourceItem, result)
  if instanceof(sourceItem, "Food") then
      return sourceItem:getActualWeight() > 0.349
  end
  return true
end

--Only meats inbetween a size (think too large to go into a jar)
function TryMeatCanned(sourceItem, result)
  if instanceof(sourceItem, "Food") then
      return 0.15 < sourceItem:getActualWeight() < 1
  end
  return true
end

--Borrowed from the Cut Fillet Code, simply adjusting weight based on item used
--Ensured consistency when cutting a piece of meat that isnt the standard 0.5 size
function AdjustStates(craftRecipeData, character)

end

function AdjustStatesPemmican(craftRecipeData, character)

  end

function OnCookedTest(meatToChange)
  print("changing da meat")
  meatToChange:setIsCookable(false)
  print("post cookable")
  --print("FRESH", meatToChange:getDaysFresh())
  meatToChange:setOffAge(1000000000); --Becomes Non perishable
  meatToChange:setOffAgeMax(1000000000);
  print("meat change days")
  meatToChange:setActualWeight(meatToChange:getActualWeight() * 0.7); --Water weight removed
  meatToChange:setWeight(meatToChange:getActualWeight());
  meatToChange:setCustomWeight(true)
  meatToChange:setCarbohydrates(meatToChange:getCarbohydrates() * 0.70);
  meatToChange:setLipids(meatToChange:getLipids() * 0.70); --Mild loss for balancing idk
  meatToChange:setProteins(meatToChange:getProteins() * 0.70);
  meatToChange:setCalories(meatToChange:getCalories() * 0.70);
  meatToChange:setHungChange(meatToChange:getHungChange() * 0.70)
  --local name = meatToChange:getDisplayName()
  --meatToChange:setDisplayName(name .. "(Stable)");
  print("meat done")
end

--Overriding vanilla OnCooked function for canned Food
function CannedFood_OnCooked(cannedFood)
  local aged = cannedFood:getAge() / cannedFood:getOffAgeMax();
  cannedFood:setOffAgeMax(180);
  cannedFood:setOffAge(150);
  cannedFood:setAge(cannedFood:getOffAgeMax() * aged);
end