
TaillightsHaibane = TaillightsHaibane or {};
TaillightsHaibane.OPTIONS = TaillightsHaibane.OPTIONS or {};

TaillightsHaibane.SETTINGS = {
  options = { 
    reverseLight = false,
  },
  names = {
    reverseLight = "Enable reverse lights",
  },
  mod_id = "TaillightsAndStoplights",
  mod_shortname = "Taillights and Stoplights",
}

-- Connecting the settings to the menu, so user can change them.
if ModOptions and ModOptions.getInstance then
  ModOptions:getInstance(TaillightsHaibane.SETTINGS)
end
