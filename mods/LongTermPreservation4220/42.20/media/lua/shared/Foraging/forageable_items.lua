require 'Foraging/forageSystem'

local function onAddForageDefs(forageSystem)
  local saltRock = 
  {
    type = "Skittles.SaltRock",
    snowChance = -50,
    minCount = 1,
		maxCount = 2,
		xp = 2,
		categories = { "Stones" },
    zones = {
      Forest      = 5,
      DeepForest  = 5,
      Vegitation  = 5,
      FarmLand    = 5,
      Farm        = 5,
      TrailerPark = 1,
      TownZone    = 1,
      ForagingNav = 5,
    },

  }

  forageSystem.addItemDef(saltRock)
end

Events.onAddForageDefs.Add(onAddForageDefs)