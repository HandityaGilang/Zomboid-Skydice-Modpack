local AliceVest = {
  "Sheath",
  "Tail",
  "AliceVest"
}

local group = BodyLocations.getGroup("Human")
for _, location in ipairs(AliceVest) do
    local bodyLocation = BodyLocation.new(group, location)
    group:getAllLocations():add(bodyLocation)
end
