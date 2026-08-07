
local group = BodyLocations.getGroup("Human")
for i = 1, #AliceRegistries.BodyLocations do
    group:getOrCreateLocation(AliceRegistries.BodyLocations[i])
end