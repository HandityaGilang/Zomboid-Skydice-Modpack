-- Parts de abate do Rottweiler: sem entrada em AnimalPartsDefinitions o abate vanilla crasha
-- (ButcheringUtil indexa type..breed e estoura em def.feather nil). Ver contrato de addon.
if CompanionDogs and CompanionDogs.defineDogParts then
    CompanionDogs.defineDogParts("rott", "rottweiler")
end
