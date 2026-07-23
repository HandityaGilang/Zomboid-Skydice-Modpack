-- Better Sorting Build 42.13+ compatibility patch.
-- This script replaces the original categorizer and OnGameBoot handler so
-- the legacy code never runs on Build 42.13+ (prevents early errors).
if not BetterSorting then
  print("[BetterSorting 42.13 patch] Base mod missing, skipping patch.")
  return
end

if BetterSorting._build4213Patch then
  -- Already active (avoid double registration when reloading Lua).
  return
end

local originalOnGameBoot = BetterSorting.OnGameBoot

local function removeOriginalBootHook()
  if originalOnGameBoot and Events and Events.OnGameBoot and Events.OnGameBoot.Remove then
    Events.OnGameBoot.Remove(originalOnGameBoot)
  end
end

local function isPerishable(item)
  if item.getDaysTotallyRotten then
    local days = item:getDaysTotallyRotten()
    if days and days > 0 and days < 1000000000 then
      return true
    end
  end

  if item.getRottenTime then
    local time = item:getRottenTime()
    if time and time > 0 and time < 1000000000 then
      return true
    end
  end

  return false
end

local function categorizeItemBuild42(item)
  local category = ""

  if item.fluidContainer then
    local fluidContainerWrapper = item.fluidContainer:getFluidContainer()
    local fluid = fluidContainerWrapper and fluidContainerWrapper:getPrimaryFluid() or nil
    local fluidContainer = item.getFluidContainer and item:getFluidContainer() or nil

    if fluid and fluidContainer and fluidContainer:getAmount() > 0 then
      if fluid:isCategory(FluidCategory.Alcoholic) then
        category = "FoodA"
      elseif fluid:isCategory(FluidCategory.Beverage) then
        category = "FoodB"
      elseif fluid:isCategory(FluidCategory.Fuel) then
        category = "Fuel"
      end
    else
      category = "Container"
    end

  elseif item:getDisplayCategory() == "Water" then
    category = "FoodB"

  elseif item:getItemType() == ItemType.FOOD then
    category = isPerishable(item) and "FoodP" or "FoodN"

  elseif item:getItemType() == ItemType.LITERATURE then
    local skillTrained = item.skillTrained or ""
    local teachedRecipes = item.teachedRecipes
    local stressChange = item.stressChange or 0
    local boredomChange = item.boredomChange or 0
    local unhappyChange = item.unhappyChange or 0

    if teachedRecipes and not teachedRecipes:isEmpty() then
      category = "LitR"
    elseif skillTrained and string.len(tostring(skillTrained)) > 0 then
      category = "LitS"
    elseif stressChange ~= 0 or boredomChange ~= 0 or unhappyChange ~= 0 then
      category = "LitE"
    else
      category = "LitW"
    end

  elseif item:getItemType() == ItemType.WEAPON then
    if item:getDisplayCategory() == "Explosives" or item:getDisplayCategory() == "Devices" then
      category = "WepBomb"
    end

  elseif string.find(item:getFullName(), "Tsarcraft.Cassette") or string.find(item:getFullName(), "Tsarcraft.Vinyl") then
    category = "MediaA"

  elseif item:getItemType() == ItemType.NORMAL and item:getModuleName() == "TAD" then
    category = "Misc"
  end

  if #category > 0 then
    TweakItem(item:getFullName(), "DisplayCategory", category)
  end
end

local function patchedOnGameBoot()
  print("--- BetterSorting Start (42.13 patch) ---")
  BetterSorting.CategorizeAllItems()
  if ItemTweaker and ItemTweaker.tweakItems then
    ItemTweaker.tweakItems()
  end
  print("--- BetterSorting End (42.13 patch) ---")
end

removeOriginalBootHook()
BetterSorting.CategorizeItem = categorizeItemBuild42
BetterSorting.OnGameBoot = patchedOnGameBoot
Events.OnGameBoot.Add(BetterSorting.OnGameBoot)
BetterSorting._build4213Patch = true

print("[BetterSorting 42.13 patch] Replaced categorizer and OnGameBoot handler.")
