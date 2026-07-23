
require "XpSystem/XpUpdate"

Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}
Recipe.OnGiveXP  = Recipe.OnGiveXP or {}
Recipe.OnTest    = Recipe.OnTest or {}
Recipe.OnCanPerform = Recipe.OnCanPerform or {}

Recipe.OnCreate.DismantleMiscElectronics = Recipe.OnCreate.DismantleMiscElectronics or function(craftRecipeData, character)
end

Recipe.OnTest.DismantleElectronics = Recipe.OnTest.DismantleElectronics or function(sourceItem, result)
    return true
end

local AZB42_SYNC_MODULE = "AZB42InventorySync"

local function AZB42_GetInventory(character)
    return character and character.getInventory and character:getInventory() or nil
end

local function AZB42_MarkContainerDirty(container)
    if container and container.setDrawDirty then
        container:setDrawDirty(true)
    end
end

local function AZB42_RefreshPlayerInventory(character)
    if not character then
        return
    end

    if isServer and isServer() and sendServerCommand then
        sendServerCommand(character, AZB42_SYNC_MODULE, "refreshInventory", {
            playerNum = character.getPlayerNum and character:getPlayerNum() or 0,
        })
    elseif getPlayerInventory and character.getPlayerNum then
        local inventoryPage = getPlayerInventory(character:getPlayerNum())
        if inventoryPage and inventoryPage.refreshBackpacks then
            inventoryPage:refreshBackpacks()
        end
    end
end

local function AZB42_AddItemSynced(character, fullType)
    local inventory = AZB42_GetInventory(character)
    if not inventory or not fullType then
        return nil
    end

    local item = inventory:AddItem(fullType)
    if item and sendAddItemToContainer then
        sendAddItemToContainer(inventory, item)
    end
    AZB42_MarkContainerDirty(inventory)
    AZB42_RefreshPlayerInventory(character)
    return item
end

local function AZB42_RemoveItemSynced(character, container, item)
    if not container or not item then
        return
    end

    container:Remove(item)
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(container, item)
    end
    AZB42_MarkContainerDirty(container)
    AZB42_RefreshPlayerInventory(character)
end

local function AZB42_SyncResult(character, item)
    if item and item.syncItemFields then
        item:syncItemFields()
    end
    if item and item.synchWithVisual then
        item:synchWithVisual()
    end
    if character and syncVisuals then
        syncVisuals(character)
    end
    AZB42_RefreshPlayerInventory(character)
end

local function AZB42_MoveContainerContents(character, sourceItem, resultItem)
    if not sourceItem or not resultItem then
        return
    end
    if not sourceItem:IsInventoryContainer() or not resultItem:IsInventoryContainer() then
        return
    end

    local sourceContainer = sourceItem:getItemContainer()
    local resultContainer = resultItem:getItemContainer()
    if not sourceContainer or not resultContainer then
        return
    end

    local movedCount = 0
    local sourceItems = sourceContainer:getItems()
    while sourceItems and sourceItems:size() > 0 do
        local nestedItem = sourceItems:get(0)
        sourceContainer:DoRemoveItem(nestedItem)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(sourceContainer, nestedItem)
        end
        resultContainer:AddItem(nestedItem)
        if sendAddItemToContainer then
            sendAddItemToContainer(resultContainer, nestedItem)
        end
        movedCount = movedCount + 1
    end

    AZB42_MarkContainerDirty(sourceContainer)
    AZB42_MarkContainerDirty(resultContainer)
    AZB42_SyncResult(character, resultItem)
end

AZRecipe = AZRecipe or {}
AZRecipe.GetItemTypes = AZRecipe.GetItemTypes or {}
AZRecipe.OnCanPerform = AZRecipe.OnCanPerform or {}
AZRecipe.OnCreate = AZRecipe.OnCreate or {}
AZRecipe.OnGiveXP = AZRecipe.OnGiveXP or {}
AZRecipe.OnTest = AZRecipe.OnTest or {}
AZRecipe.Recipes = AZRecipe.Recipes or {}
AZRecipe.Recipes.OnCreate = AZRecipe.Recipes.OnCreate or {}

function AZRecipe.Recipes.OnCreate.InstantCraft(craftRecipeData, character)
    if not ISTimedActionQueue or not ISCraftAction or not character then
        return
    end

    local actionQueue = ISTimedActionQueue.getActionQueue(character)
    local craftAction = actionQueue and actionQueue.queue and actionQueue.queue[#actionQueue.queue]
    if craftAction and craftAction.__index == ISCraftAction then
        craftAction.is_ignore_additional_time = true
    end
end

local AZB42_TORCH_TYPES = {
    Torch2 = true,
    HandTorch2 = true,
    Authentic_MinerLightbulb = true,
    Authentic_MilitaryFlashlightGrey = true,
    Authentic_MilitaryFlashlightGreen = true,
}

function AuthenticTorchBatteryRemoval_OnCreate(items, result, character)
    if not items or not result then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and AZB42_TORCH_TYPES[item:getType()] then
            result:setUsedDelta(item:getUsedDelta())
            item:setUsedDelta(0)
        end
    end
end

function AuthenticTorchBatteryInsert_TestIsValid(sourceItem, result)
    if sourceItem and AZB42_TORCH_TYPES[sourceItem:getType()] then
        return sourceItem:getUsedDelta() == 0
    end
    return true
end

function GetGroguBack(items, result, character)
    AZB42_AddItemSynced(character, "AuthenticZClothing.GroguAZ");
end
local GlowStickList = {
    "AuthenticZClothing.AuthenticGlowstick_Red",
    "AuthenticZClothing.AuthenticGlowstick_Blue",
    "AuthenticZClothing.AuthenticGlowstick_Green",
    "AuthenticZClothing.AuthenticGlowstick_Orange",
    "AuthenticZClothing.AuthenticGlowstick_Pink",
    "AuthenticZClothing.AuthenticGlowstick_Purple",
    "AuthenticZClothing.AuthenticGlowstick_Yellow",
    "AuthenticZClothing.AuthenticGlowstick_White",
}

function Recipe.OnCreate.OpenGlowStickPackage(craftRecipeData, character)
    for i = 1, 3 do
        AZB42_AddItemSynced(character, GlowStickList[ZombRand(#GlowStickList) + 1])
    end
end

local SealedMedkit = {
            "AlcoholWipes",
            "AlcoholWipes",
            "Bandage",
            "Bandage",
            "Bandage",
            "Bandaid",
            "Bandaid",
            "Bandaid",
            "CottonBalls",
            "CottonBalls",
            "CottonBalls",
            "Disinfectant",
            "Gloves_Surgical",
            "Scalpel",
            "Scissors",
            "SutureNeedle",
            "SutureNeedle",
            "SutureNeedleHolder",
            "Tweezers",
}

function OpenSealedMedkit(first, second, third)
    local character = third or second
    for i = 1, 8 do
        AZB42_AddItemSynced(character, SealedMedkit[ZombRand(#SealedMedkit) + 1])
    end
end

function AZRecipe.OnGiveXP.Tailoring20(AZRecipe, ingredients, result, character)
    character:getXp():AddXP(Perks.Tailoring, 15);
end

function KoniTestAZ_OnTest_ConvertClothing(sourceItem, result)
    if instanceof(sourceItem, "Clothing") then
        sourceItem:getModData().onTestDataIsEquipped = sourceItem:isEquipped()
    end
    return true
end

function KoniTestAZ_OnCreate_ConvertClothing(craftRecipeData, character)
    if not craftRecipeData or not craftRecipeData.getAllConsumedItems or not craftRecipeData.getAllCreatedItems then
        return
    end

    local items = craftRecipeData:getAllConsumedItems()
    local createdItems = craftRecipeData:getAllCreatedItems()
    local result = createdItems and createdItems:get(0)

    if not items or items:isEmpty() or not result then
        return
    end

    for i = 0, items:size()-1 do
        local item = items:get(i)
        if instanceof(item, "Clothing") and instanceof(result, "Clothing") then
            local baseVisual = item:getVisual()
            local resultVisual = result:getVisual()

            if baseVisual and resultVisual then
                resultVisual:setTint(baseVisual:getTint(item:getClothingItem()))
                resultVisual:setBaseTexture(baseVisual:getBaseTexture())
                resultVisual:setTextureChoice(baseVisual:getTextureChoice())
                resultVisual:setDecal(baseVisual:getDecal(item:getClothingItem()))
                result:setColor(item:getColor())
                resultVisual:copyDirt(baseVisual)
                resultVisual:copyBlood(baseVisual)
                resultVisual:copyHoles(baseVisual)
                resultVisual:copyPatches(baseVisual)
            end
            if result:IsClothing() then
                item:copyPatchesTo(result)
                result:setWetness(item:getWetness())
            end

            result:setCondition(item:getCondition())
            result:setFavorite(item:isFavorite())
            if item:hasModData() then
                result:copyModData(item:getModData())
            end

            if result:IsInventoryContainer() and item:IsInventoryContainer() then
                AZB42_MoveContainerContents(character, item, result)

                local scriptItem = item.getScriptItem and item:getScriptItem()
                if scriptItem and item:getName() ~= scriptItem:getDisplayName() then
                    result:setName(item:getName())
                end
            end

            AZB42_SyncResult(character, result)

            if result:getModData().onTestDataIsEquipped then
                result:getModData().onTestDataIsEquipped = nil

                if instanceof(result, "InventoryContainer") and (result:canBeEquipped() ~= "") then
                    character:removeFromHands(result)
                    character:setWornItem(result:canBeEquipped(), result)
                    if sendClothing then
                        sendClothing(character, result:canBeEquipped(), result)
                    end

                elseif result:getCategory() == "Clothing" then
                    if result:getBodyLocation() ~= "" then
                        character:setWornItem(result:getBodyLocation(), result)
                        if sendClothing then
                            sendClothing(character, result:getBodyLocation(), result)
                        end

                        local humanVisual = character.getHumanVisual and character:getHumanVisual()
                        local hairModel = humanVisual and humanVisual.getHairModel and humanVisual:getHairModel()
                        if humanVisual and hairModel and hairModel.contains and hairModel:contains("Mohawk")
                            and (result:getBodyLocation() == "Hat" or result:getBodyLocation() == "FullHat") then
                            humanVisual:setHairModel("MohawkFlat")
                            character:resetModel()
                            character:resetHairGrowingTime()
                        end
                    end
                end
                AZB42_SyncResult(character, result)
                triggerEvent("OnClothingUpdated", character)
            end

            break
        end
    end
end

function PleaseKeepColor(craftRecipeData, character)
    KoniTestAZ_OnCreate_ConvertClothing(craftRecipeData, character)
end

function AZKeepDrainableContent_OnCreate(items, result, character)
    if items and items.getAllConsumedItems then
        local craftRecipeData = items
        character = result
        items = craftRecipeData:getAllConsumedItems()
        local createdItems = craftRecipeData:getAllCreatedItems()
        result = createdItems and createdItems:get(0)
    end

    if not items or not result or not instanceof(result, "Drainable") then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and instanceof(item, "Drainable") then
            result:setUsedDelta(item:getUsedDelta())
            break
        end
    end
end

local balloonColorFromSingle = {
    ["AuthenticZClothing.AuthenticBalloon_Red"]    = "Red",
    ["AuthenticZClothing.AuthenticBalloon_Blue"]   = "Blue",
    ["AuthenticZClothing.AuthenticBalloon_Green"]  = "Green",
    ["AuthenticZClothing.AuthenticBalloon_Yellow"] = "Yellow",
    ["AuthenticZClothing.AuthenticBalloon_Pink"]   = "Pink",
    ["AuthenticZClothing.AuthenticBalloon_Purple"] = "Purple",
    ["AuthenticZClothing.AuthenticBalloon_White"]  = "White",
    ["AuthenticZClothing.AuthenticBalloon_Teal"] = "Teal",
}

local balloonColorFromGroup = {
    ["AuthenticZClothing.AuthenticBalloonGroup_Red"]    = "Red",
    ["AuthenticZClothing.AuthenticBalloonGroup_Blue"]   = "Blue",
    ["AuthenticZClothing.AuthenticBalloonGroup_Green"]  = "Green",
    ["AuthenticZClothing.AuthenticBalloon_Group_Yellow"] = "Yellow",
    ["AuthenticZClothing.AuthenticBalloonGroup_Pink"]   = "Pink",
    ["AuthenticZClothing.AuthenticBalloonGroup_Purple"] = "Purple",
    ["AuthenticZClothing.AuthenticBalloonGroup_White"]  = "White",
    ["AuthenticZClothing.AuthenticBalloonGroup_Teal"] = "Teal",
}

local balloonGroupForColor = {
    ["Red"]    = "AuthenticZClothing.AuthenticBalloonGroup_Red",
    ["Blue"]   = "AuthenticZClothing.AuthenticBalloonGroup_Blue",
    ["Green"]  = "AuthenticZClothing.AuthenticBalloonGroup_Green",
    ["Yellow"] = "AuthenticZClothing.AuthenticBalloon_Group_Yellow",
    ["Pink"]   = "AuthenticZClothing.AuthenticBalloonGroup_Pink",
    ["Purple"] = "AuthenticZClothing.AuthenticBalloonGroup_Purple",
    ["White"]  = "AuthenticZClothing.AuthenticBalloonGroup_White",
    ["Teal"] = "AuthenticZClothing.AuthenticBalloonGroup_Teal",
}

local balloonSingleForColor = {
    ["Red"]    = "AuthenticZClothing.AuthenticBalloon_Red",
    ["Blue"]   = "AuthenticZClothing.AuthenticBalloon_Blue",
    ["Green"]  = "AuthenticZClothing.AuthenticBalloon_Green",
    ["Yellow"] = "AuthenticZClothing.AuthenticBalloon_Yellow",
    ["Pink"]   = "AuthenticZClothing.AuthenticBalloon_Pink",
    ["Purple"] = "AuthenticZClothing.AuthenticBalloon_Purple",
    ["White"]  = "AuthenticZClothing.AuthenticBalloon_White",
    ["Teal"] = "AuthenticZClothing.AuthenticBalloon_Teal",
}

function AZRecipe.OnCreate.UntieBalloons(craftRecipeData, character)
    if not craftRecipeData or not craftRecipeData.getAllConsumedItems then
        return
    end

    local items = craftRecipeData:getAllConsumedItems()
    if not items or items:isEmpty() then return end

    local groupItem = items:get(0)
    if not groupItem then return end

    local groupFullType = groupItem:getFullType()
    local color = balloonColorFromGroup[groupFullType]
    if color then
        local singleBalloonType = balloonSingleForColor[color]
        if singleBalloonType then

            for i=1,3 do
                AZB42_AddItemSynced(character, singleBalloonType)
            end
        end
    end
end

function AZKeepFoodContent_OnCreate(items, result, character)
    if items and items.getAllConsumedItems then
        local craftRecipeData = items
        character = result
        items = craftRecipeData:getAllConsumedItems()
        local createdItems = craftRecipeData:getAllCreatedItems()
        result = createdItems and createdItems:get(0)
    end

    if not items or not result then
        return
    end

    if instanceof(result, "Food") then
        for i=0, items:size()-1 do
            local item = items:get(i);
            if instanceof(item, "Food") then

                result:setBaseHunger(item:getBaseHunger());
                result:setHungChange(item:getHungChange());
                result:setThirstChange(item:getThirstChange());
                result:setBoredomChange(item:getBoredomChange());
                result:setUnhappyChange(item:getUnhappyChange());
                result:setCarbohydrates(item:getCarbohydrates());
                result:setLipids(item:getLipids());
                result:setProteins(item:getProteins());
                result:setCalories(item:getCalories());
                result:setTaintedWater(item:isTaintedWater());

                result:setCooked(item:isCooked());
                result:setBurnt(item:isBurnt());
                result:setPoisonDetectionLevel(item:getPoisonDetectionLevel());
                result:setPoisonPower(item:getPoisonPower());

                if item:getSpices() then
                    result:setSpices(item:getSpices());
                    result:setSpices(item:getSpices());
                end

                if item:haveExtraItems() then
                    local extras = item:getExtraItems();
                    for i = 0, extras:size() - 1 do
                        local extra = extras:get(i);
                        result:addExtraItem(extra);
                    end
                end

                break;
            end
        end
    end
end

local function AZB42_GetSmokePercent(food, percent)
    if not food or not food.getScriptItem then
        return percent or 1
    end

    local script = food:getScriptItem()
    local scriptStress = script and script.getStressChange and script:getStressChange() or 0
    if scriptStress == 0 then
        return percent or 1
    end

    return (percent or 1) * (food:getStressChange() * 100) / scriptStress
end

function OnEat_CigarAZ(food, character, percent)
    if not character then
        return
    end
    percent = AZB42_GetSmokePercent(food, percent)
    local bodyDamage = character:getBodyDamage()
    local stats = character:getStats()

    if character:HasTrait("Smoker") then
        bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 10 * percent);
        if bodyDamage:getUnhappynessLevel() < 0 then
            bodyDamage:setUnhappynessLevel(0);
        end
        stats:setStress(stats:getStress() - 10 * percent);
        if stats:getStress() < 0 then
            stats:setStress(0);
        end
        local reduceSFC = stats:getMaxStressFromCigarettes()
        stats:setStressFromCigarettes(stats:getStressFromCigarettes() - reduceSFC * percent);
        character:setTimeSinceLastSmoke(stats:getStressFromCigarettes() / stats:getMaxStressFromCigarettes());
    else

        bodyDamage:setFoodSicknessLevel(bodyDamage:getFoodSicknessLevel() + 14 * percent);
        if bodyDamage:getFoodSicknessLevel() > 100 then
            bodyDamage:setFoodSicknessLevel(100);
        end
    end
end
function OnEat_CigaretteHolder(food, character, percent)
    if not character then
        return
    end
    percent = AZB42_GetSmokePercent(food, percent)
    local bodyDamage = character:getBodyDamage()
    local stats = character:getStats()

    if character:HasTrait("Smoker") then
        bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 10 * percent);
        if bodyDamage:getUnhappynessLevel() < 0 then
            bodyDamage:setUnhappynessLevel(0);
        end
        stats:setStress(stats:getStress() - 10 * percent);
        if stats:getStress() < 0 then
            stats:setStress(0);
        end
        local reduceSFC = stats:getMaxStressFromCigarettes()
        stats:setStressFromCigarettes(stats:getStressFromCigarettes() - reduceSFC * percent);
        character:setTimeSinceLastSmoke(stats:getStressFromCigarettes() / stats:getMaxStressFromCigarettes());
    else

        bodyDamage:setFoodSicknessLevel(bodyDamage:getFoodSicknessLevel() + 14 * percent);
        if bodyDamage:getFoodSicknessLevel() > 100 then
            bodyDamage:setFoodSicknessLevel(100);
        end
    end
end

function AZ_OnTest_ConvertChainsaw(sourceItem, result)
    if sourceItem and instanceof(sourceItem, "InventoryItem") then
        local modData = sourceItem:getModData()
        modData.onTestDataIsEquipped = sourceItem:isEquipped()
        modData.onTestCurrentFuel = modData.CurrentFuel or 0
    end
    return true
end

function KoniTestAZ_OnCreate_ConvertChainsaw(craftRecipeData, character)
    if not craftRecipeData then
        return
    end

    local items = craftRecipeData.getAllConsumedItems and craftRecipeData:getAllConsumedItems()
    local createdItems = craftRecipeData.getAllCreatedItems and craftRecipeData:getAllCreatedItems()
    local result = createdItems and createdItems:get(0)

    if not items or items:isEmpty() or not result then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and instanceof(item, "InventoryItem") then
            local modData = item:getModData()
            result:setCondition(item:getCondition())
            result:setFavorite(item:isFavorite())
            result:getModData().CurrentFuel = modData.CurrentFuel or modData.onTestCurrentFuel or 0

            if character and modData.onTestDataIsEquipped then
                character:setPrimaryHandItem(result)
                character:setSecondaryHandItem(result)
                if sendEquip then
                    sendEquip(character)
                end
            end
            AZB42_SyncResult(character, result)
            break
        end
    end
end

Give20TailoringXP = AZRecipe.OnGiveXP.Tailoring20
GiveMeRadio = AZRecipe.OnCreate.GiveMeRadio
RefillBlowTorch_OnCreateAZ = AZRecipe.OnCreate.RefillBlowTorchAZ
RefillBlowTorch_OnTestAZ = AZRecipe.OnTest.RefillBlowTorchAZ
