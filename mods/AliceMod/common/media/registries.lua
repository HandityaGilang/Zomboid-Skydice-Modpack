local bodylocations = {
    "Sheath",
    "Tail"
}

AliceRegistries = {}
AliceRegistries.BodyLocations = {}

for i = 1, #bodylocations do
    AliceRegistries.BodyLocations[i] = ItemBodyLocation.register("ALICE:" .. bodylocations[i])
end
