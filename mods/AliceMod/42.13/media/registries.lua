local bodylocations = {
    "Sheath",
    "Tail",
    "GasMaskPouch",
    "GasMaskDoff",
}

AliceRegistries = {}
AliceRegistries.BodyLocations = {}

for i = 1, #bodylocations do
    AliceRegistries.BodyLocations[i] = ItemBodyLocation.register("ALICE:" .. bodylocations[i])
end
