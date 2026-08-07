local function ChangeBoilersuitToDress()
--
  local itemNames = {
    "Boilersuit",
    "Boilersuit_BlueRed",
    "Boilersuit_Flying",
    "Boilersuit_Prisoner",
    "Boilersuit_PrisonerKhaki",
    "Boilersuit_Yellow",
    "Boilersuit_SWAT",
    "BoilersuitOPEN",
    "Boilersuit_BlueRedOPEN",
    "Boilersuit_FlyingOPEN",
    "Boilersuit_PrisonerOPEN",
    "Boilersuit_PrisonerKhakiOPEN",
    "Boilersuit_YellowOPEN",
    "Boilersuit_SWATOPEN",
    "Boilersuit_BlueRedTIED",
    "Boilersuit_FlyingTIED",
    "Boilersuit_PrisonerKhakiTIED",
    "Boilersuit_PrisonerTIED",
    "Boilersuit_YellowTIED",
    "BoilersuitTIED"
  }
--
  for _, itemName in ipairs(itemNames) do
    local item = ScriptManager.instance:getItem(itemName)
    if item then
      item:DoParam("BodyLocation = base:dress")
    end
  end
end
--
Events.OnGameBoot.Add(ChangeBoilersuitToDress)