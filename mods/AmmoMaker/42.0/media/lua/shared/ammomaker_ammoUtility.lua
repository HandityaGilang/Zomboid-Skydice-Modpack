--Ammo Maker by STIMP_TM

function ammoMakerGetAmmoTypeActive(ammoItemType)

    local typeActive = false;

    for i=1, #ammoMakerAmmoTypes[ammoItemType].modIds do

        if ammoMakerCompatibleMods[ammoMakerAmmoTypes[ammoItemType].modIds[i]] == true then

            typeActive = true;

        end

    end

    return typeActive

end

function ammoMakerGetAmmoTypeIndexActive(ammoItemType)

    local activeIndex = 1;

    if #ammoMakerAmmoTypes[ammoItemType].ammoTypes > 1 then

        for i=1, #ammoMakerAmmoTypes[ammoItemType].modIds do

            if ammoMakerCompatibleMods[ammoMakerAmmoTypes[ammoItemType].modIds[i]] == true and ammoMakerAmmoTypes[ammoItemType].modIds[i] ~= "Base" then

                activeIndex = i;

            end

        end

    end

    return activeIndex

end

function ammoMakerGetMakePartRecipesInactive()

    local inactiveMakePartRecipes = ammoMakerGetMakePartRecipesAll();

	for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

		if ammoMakerGetAmmoTypeActive(ammoItemType) == true then

			inactiveMakePartRecipes[ammoMakerGetMakeCasingRecipe(ammoItemType)] = nil;
			inactiveMakePartRecipes[ammoMakerGetMakeBulletRecipe(ammoItemType)] = nil;

		end

	end

    return inactiveMakePartRecipes

end

function ammoMakerGetRecyclePartRecipesInactive()

    local inactiveRecyclePartRecipes = ammoMakerGetRecyclePartRecipesAll();

	for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

		if ammoMakerGetAmmoTypeActive(ammoItemType) == true then

			inactiveRecyclePartRecipes[ammoMakerGetRecycleCasingRecipe(ammoItemType)] = nil;
			inactiveRecyclePartRecipes[ammoMakerGetRecycleBulletRecipe(ammoItemType)] = nil;

		end

	end

    return inactiveRecyclePartRecipes

end

function ammoMakerGetRepairPartRecipesInactive()

    local inactiveRepairPartRecipes = ammoMakerGetRepairPartRecipesAll();

	for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

		if ammoMakerGetAmmoTypeActive(ammoItemType) == true then

			inactiveRepairPartRecipes[ammoMakerGetRepairCasingRecipe(ammoItemType)] = nil;

		end

	end

    return inactiveRepairPartRecipes

end

function ammoMakerGetMakePartRecipesAll()

    local allMakePartRecipes = {};

    for ammoPartType, ammoPartData in pairs(ammoMakerAmmoParts) do

        if ammoPartData.makeRecipe and not allMakePartRecipes[ammoPartData.makeRecipe] then

            allMakePartRecipes[ammoPartData.makeRecipe] = true;

        end

    end

    return allMakePartRecipes

end

function ammoMakerGetRecyclePartRecipesAll()

    local allRecyclePartRecipes = {};

    for ammoPartType, ammoPartData in pairs(ammoMakerAmmoParts) do

        if ammoPartData.recycleRecipe and not allRecyclePartRecipes[ammoPartData.recycleRecipe] then

            allRecyclePartRecipes[ammoPartData.recycleRecipe] = true;

        end

    end

    return allRecyclePartRecipes

end

function ammoMakerGetRepairPartRecipesAll()

    local allRepairPartRecipes = {};

    for ammoPartType, ammoPartData in pairs(ammoMakerAmmoParts) do

        if ammoPartData.repairRecipe and not allRepairPartRecipes[ammoPartData.repairRecipe] then

            allRepairPartRecipes[ammoPartData.repairRecipe] = true;

        end

    end

    return allRepairPartRecipes

end

function ammoMakerGetCasingTypesActive()

    local activeCasingTypes = {};

	for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

		if ammoMakerGetAmmoTypeActive(ammoItemType) == true then

            local casingType = ammoMakerGetCasingType(ammoItemType);

			if not activeCasingTypes[casingType] then

				activeCasingTypes[casingType] = true;

			end

		end

	end

    return activeCasingTypes

end

function ammoMakerGetAmmoPartTypesActive()

    local activeAmmoPartTypes = {};

	for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

		if ammoMakerGetAmmoTypeActive(ammoItemType) == true then
            
            local bulletType = ammoMakerGetBulletType(ammoItemType);
            local casingType = ammoMakerGetCasingType(ammoItemType);

			if not activeAmmoPartTypes[bulletType] then

				activeAmmoPartTypes[bulletType] = true;

			end

            if not activeAmmoPartTypes[casingType] then

				activeAmmoPartTypes[casingType] = true;

			end

		end

	end

    return activeAmmoPartTypes

end

function ammoMakerGetAmmoData(ammoItemType)

    return ammoMakerAmmoData[ammoMakerAmmoTypes[ammoItemType].ammoTypes[ammoMakerGetAmmoTypeIndexActive(ammoItemType)]]

end

function ammoMakerGetGrainsAmount(ammoItemType)

    return ammoMakerGetAmmoData(ammoItemType).grainsAmount / 100

end

function ammoMakerGetBulletCount(ammoItemType)

    return ammoMakerGetAmmoData(ammoItemType).bulletCount

end

function ammoMakerGetBulletType(ammoItemType)

    return ammoMakerGetAmmoData(ammoItemType).bulletType

end

function ammoMakerGetMakeBulletRecipe(ammoItemType)

    return ammoMakerAmmoParts[ammoMakerGetBulletType(ammoItemType)].makeRecipe

end

function ammoMakerGetRecycleBulletRecipe(ammoItemType)

    return ammoMakerAmmoParts[ammoMakerGetBulletType(ammoItemType)].recycleRecipe

end

function ammoMakerGetCasingType(ammoItemType)

    return ammoMakerGetAmmoData(ammoItemType).casingType

end

function ammoMakerGetMakeCasingRecipe(ammoItemType)

    return ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].makeRecipe

end

function ammoMakerGetRecycleCasingRecipe(ammoItemType)

    return ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].recycleRecipe

end

function ammoMakerGetRepairCasingRecipe(ammoItemType)

    return ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].repairRecipe

end

function ammoMakerGetDropExtraDataItemType(ammoItemType, weaponType)

    local dropExtraData = ammoMakerGetAmmoData(ammoItemType).dropExtraData;

    if dropExtraData[weaponType] then

        for i=1, #dropExtraData[weaponType].itemMod do

            if ammoMakerCompatibleMods[dropExtraData[weaponType].itemMod[i]] == true then

                return dropExtraData[weaponType].itemType[i]

            end

        end

    end

    return nil

end

function ammoMakerGetDropExtraDataItemTypes()

    local dropExtraDataItemTypes = {};

    for _, ammoData in pairs(ammoMakerAmmoData) do

        local extraData = ammoData.dropExtraData;

        if extraData then

            for _, dropData in pairs(extraData) do

                if dropData.itemType then

                    for _, typeData in ipairs(dropData.itemType) do

                        dropExtraDataItemTypes[typeData] = true;

                    end
                
                end

            end

        end

    end

    return dropExtraDataItemTypes

end