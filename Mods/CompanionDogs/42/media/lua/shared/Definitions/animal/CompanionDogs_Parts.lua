-- O abate vanilla (ButcheringUtil.setAnimalBodyData) indexa AnimalPartsDefinitions.animals[type..breed]
-- e estoura em `def.feather` quando ele e nil. Nossos caes (dog{male,female,pup}+"brown", gs{male,female,pup}+
-- "germanshepherd", e retriever{male,female,pup}+"golden") nao tem entrada de parts no vanilla, entao qualquer cao morto/abatido estourava. Registra parts baseadas no guaxinim.
if AnimalPartsDefinitions and AnimalPartsDefinitions.animals then
    local dogparts = { { item = "Base.Smallanimalmeat", minNb = 5, maxNb = 8 } }
    local puppyparts = { { item = "Base.Smallanimalmeat", minNb = 3, maxNb = 5 } }

    local function defineDog(key, parts, boneMin, boneMax)
        local d = AnimalPartsDefinitions.animals[key] or {}
        d.parts = d.parts or parts
        d.bones = d.bones or {}
        table.insert(d.bones, { item = "Base.SmallAnimalBone", minNb = boneMin, maxNb = boneMax })
        d.noSkeleton = true
        d.xpPerItem = 10
        AnimalPartsDefinitions.animals[key] = d
    end

    -- Registra parts dos 3 stages de uma raca; exposto pro contrato de addon (CD.registerBreed).
    CompanionDogs = CompanionDogs or {}
    function CompanionDogs.defineDogParts(typePrefix, engineBreed)
        defineDog(typePrefix .. "male" .. engineBreed, dogparts, 3, 6)
        defineDog(typePrefix .. "female" .. engineBreed, dogparts, 3, 6)
        defineDog(typePrefix .. "pup" .. engineBreed, puppyparts, 2, 3)
    end

    CompanionDogs.defineDogParts("dog", "brown")
    CompanionDogs.defineDogParts("gs", "germanshepherd")
    CompanionDogs.defineDogParts("retriever", "golden")
    CompanionDogs.defineDogParts("husky", "husky")
end
