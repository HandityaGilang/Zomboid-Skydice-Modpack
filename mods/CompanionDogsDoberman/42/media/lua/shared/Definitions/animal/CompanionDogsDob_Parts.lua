-- Parts de abate do Doberman: sem entrada em AnimalPartsDefinitions o abate vanilla crasha
-- (ButcheringUtil indexa type..breed e estoura em def.feather nil). Ver contrato de addon.
if CompanionDogs and CompanionDogs.defineDogParts then
    CompanionDogs.defineDogParts("dob", "doberman")
end
