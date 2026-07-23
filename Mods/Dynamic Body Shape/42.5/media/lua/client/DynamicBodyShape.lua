-- Check if CopySkinningData function exists
--local isCopySkinningDataAvailable = BodyPartType.CopySkinningData ~= nil

local debug = false

local function MakeObese( chr )

    --if not isCopySkinningDataAvailable then
    --    return
    --end

    local humanVisual = chr:getHumanVisual()

    if chr:isFemale() then
        local obese_female_model = loadSkinnedZomboidModel("Base.FemaleBody_Obese", "skinned/femalebody_obese", "SmartTexture")
        humanVisual:setForceModel(obese_female_model)
    else
        local obese_male_model = loadSkinnedZomboidModel("Base.MaleBody_Obese","skinned/malebody_obese","SmartTexture")
        humanVisual:setForceModel(obese_male_model)
    end
end

local function MakeFat( chr )

    --if not isCopySkinningDataAvailable then
    --    return
    --end

    local humanVisual = chr:getHumanVisual()

    if chr:isFemale() then
        local fat_female_model = loadSkinnedZomboidModel("Base.FemaleBody_Fat", "skinned/femalebody_fat", "SmartTexture")
        humanVisual:setForceModel(fat_female_model)
    else
        local fat_male_model = loadSkinnedZomboidModel("Base.MaleBody_Fat","skinned/malebody_fat","SmartTexture")
        humanVisual:setForceModel(fat_male_model)
    end
end

local function MakeDefault( chr )

    --if not isCopySkinningDataAvailable then
    --    return
    --end

    local humanVisual = chr:getHumanVisual();

    if chr:isFemale() then
        local female_model = loadSkinnedZomboidModel("Base.FemaleBody", "skinned/femalebody", "SmartTexture")
        humanVisual:setForceModel(nil)
    else
        local male_model = loadSkinnedZomboidModel("Base.MaleBody","skinned/malebody","SmartTexture")
        humanVisual:setForceModel(nil)
    end
end

local function doesItemTypeExist(itemFullType)
    local item = getScriptManager():FindItem(itemFullType)
    return item ~= nil
end

local function RemoveSufix(string)
    return string:gsub("_Obese", ""):gsub("_Fat", "")
end

local function HasSufix(string)
    return string:find("_Obese") or string:find("_Fat")
end

local function UpdateClotheVisuals( chr , suffix)

    -- --if not isCopySkinningDataAvailable then
    -- --    return
    -- --end


    ---@type WornItems|ArrayList
    local wornItems = chr:getWornItems()

    for i=0, wornItems:size()-1 do
        local wornItem = wornItems:get(i):getItem()
        local ItemVisual = wornItem:getVisual()
        local ItemType = RemoveSufix(ItemVisual:getItemType())
        if doesItemTypeExist(ItemType..suffix) then
            ItemVisual:setItemType(ItemType..suffix)
        else
            ItemVisual:setItemType(ItemType)
        end
    end
end

local function AddEmaciatedSkin(chr)
    if chr:isFemale() then
        chr:getHumanVisual():addBodyVisualFromItemType("Base.Emaciated_Skin_Female")
    else
        chr:getHumanVisual():addBodyVisualFromItemType("Base.Emaciated_Skin_Male")
    end
end

local function AddUnderweightSkin(chr)
    if chr:isFemale() then
        chr:getHumanVisual():addBodyVisualFromItemType("Base.Underweight_Skin_Female")
    else
        chr:getHumanVisual():addBodyVisualFromItemType("Base.Underweight_Skin_Male")
    end
end

local function AddMuscles(chr)
    --Assuming its a player
    local strengthLvl = chr:getPerkLevel(Perks.Strength)
    local fitnessLvl = chr:getPerkLevel(Perks.Fitness)
    if strengthLvl > 9 then
        if chr:isFemale() then
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Female_3")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Male_3")
        end
    elseif strengthLvl > 7 then
        if chr:isFemale() then
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Female_2")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Male_2")
        end
    elseif strengthLvl > 5 then
        if chr:isFemale() then
           chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Female_1")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Top_Male_1")
        end
    end

    if fitnessLvl > 9 then
        if chr:isFemale() then
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Female_3")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Male_3")
        end
    elseif fitnessLvl > 7 then
        if chr:isFemale() then
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Female_2")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Male_2")
        end
    elseif fitnessLvl > 5 then
        if chr:isFemale() then
           chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Female_1")
        else
            chr:getHumanVisual():addBodyVisualFromItemType("Base.Muscles_Bottom_Male_1")
        end
    end
end

local function removeAllSkins( chr )
    local hv = chr:getHumanVisual()

    hv:removeBodyVisualFromItemType("Base.Emaciated_Skin_Female")
    hv:removeBodyVisualFromItemType("Base.Emaciated_Skin_Male")
    hv:removeBodyVisualFromItemType("Base.Underweight_Skin_Female")
    hv:removeBodyVisualFromItemType("Base.Underweight_Skin_Male")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Male_1")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Male_2")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Male_3")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Male_1")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Male_2")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Male_3")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Female_1")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Female_2")
    hv:removeBodyVisualFromItemType("Base.Muscles_Top_Female_3")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Female_1")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Female_2")
    hv:removeBodyVisualFromItemType("Base.Muscles_Bottom_Female_3")
    
    chr:resetModel()
    sendVisual(chr)
end

local function DynamicBodyShape ( chr )

    local PlayerWeight = chr:getNutrition():getWeight()
    removeAllSkins( chr )

    if PlayerWeight <= 65 then
        if debug then
            print("Make Emaciated")
        end
        AddEmaciatedSkin(chr)
        MakeDefault(chr);
        UpdateClotheVisuals( chr , "")
    elseif  PlayerWeight > 65 and PlayerWeight <= 75 then
        if debug then
            print("Make underweight")
        end
        AddUnderweightSkin(chr)
        MakeDefault(chr);
        UpdateClotheVisuals( chr , "")
    elseif  PlayerWeight > 75 and PlayerWeight <= 85 then
        if debug then
            print("Make normal")
        end
        AddMuscles(chr)
        MakeDefault(chr);
        UpdateClotheVisuals( chr , "")
    elseif PlayerWeight > 85 and PlayerWeight <= 100 then
        if debug then
            print("Make Fat")
        end
        MakeFat(chr);
        UpdateClotheVisuals( chr , "_Fat")
    else
        if debug then
            print("Make Obese")
        end
        MakeObese(chr)
        UpdateClotheVisuals( chr , "_Obese")
    end

    chr:resetModel()
    sendVisual(chr)
end

local function OnClothingUpdated( chr )
	if instanceof(chr,"IsoPlayer") then
        if debug then
            print("Player changed clothes")
        end
        DynamicBodyShape( chr )
    else
        if debug then
            print("Non Player changed clothes")
        end
    end
end



Events.OnClothingUpdated.Add(OnClothingUpdated)



local function UpdateZombieClotheVisuals( chr , suffix)

    ---@type ItemVisual|ArrayList
    local ItemVisuals = chr:getItemVisuals()
    for i=0, ItemVisuals:size()-1 do
        local ItemVisual = ItemVisuals:get(i)
        local ItemType = RemoveSufix(ItemVisual:getItemType())
        
        if doesItemTypeExist(ItemType..suffix) then
            ItemVisual:setItemType(ItemType..suffix)
        else
            ItemVisual:setItemType(ItemType)
        end
    end
end

local rand = newrandom()
local femaleRNG_MAX = SandboxVars.DynBodyShape.EmaciatedChanceFemale + SandboxVars.DynBodyShape.UnderweightChanceFemale + SandboxVars.DynBodyShape.DefaultChanceFemale + SandboxVars.DynBodyShape.FatChanceFemale + SandboxVars.DynBodyShape.ObeseChanceFemale
local maleRNG_MAX = SandboxVars.DynBodyShape.EmaciatedChanceMale + SandboxVars.DynBodyShape.UnderweightChanceMale + SandboxVars.DynBodyShape.DefaultChanceMale + SandboxVars.DynBodyShape.FatChanceMale + SandboxVars.DynBodyShape.ObeseChanceMale

local function DynamicZombieShape( zombie, TrueZombieID )
    rand:seed(TrueZombieID)
    local rng = rand:random()

    
    local zv = zombie:getHumanVisual()
    zv:removeBodyVisualFromItemType("Base.Emaciated_Skin_Female")
    zv:removeBodyVisualFromItemType("Base.Emaciated_Skin_Male")
    zv:removeBodyVisualFromItemType("Base.Underweight_Skin_Female")
    zv:removeBodyVisualFromItemType("Base.Underweight_Skin_Male")
    if zombie:isFemale() then
        rng = rng * femaleRNG_MAX
        if rng < SandboxVars.DynBodyShape.EmaciatedChanceFemale then
            zv:addBodyVisualFromItemType("Base.Emaciated_Skin_Female")
        elseif rng < SandboxVars.DynBodyShape.EmaciatedChanceFemale + SandboxVars.DynBodyShape.UnderweightChanceFemale then
            zv:addBodyVisualFromItemType("Base.Underweight_Skin_Female")
        elseif rng < SandboxVars.DynBodyShape.EmaciatedChanceFemale + SandboxVars.DynBodyShape.UnderweightChanceFemale + SandboxVars.DynBodyShape.DefaultChanceFemale then
        elseif rng <= SandboxVars.DynBodyShape.EmaciatedChanceFemale + SandboxVars.DynBodyShape.UnderweightChanceFemale + SandboxVars.DynBodyShape.DefaultChanceFemale + SandboxVars.DynBodyShape.FatChanceFemale then 
            MakeFat(zombie)
            UpdateZombieClotheVisuals(zombie, "_Fat")   
        else
            MakeObese(zombie)
            UpdateZombieClotheVisuals(zombie, "_Obese")
        end
    else
        rng = rng * maleRNG_MAX
        if rng < SandboxVars.DynBodyShape.EmaciatedChanceMale then
            zv:addBodyVisualFromItemType("Base.Emaciated_Skin_Male")
        elseif rng < SandboxVars.DynBodyShape.EmaciatedChanceMale + SandboxVars.DynBodyShape.UnderweightChanceMale then
            zv:addBodyVisualFromItemType("Base.Underweight_Skin_Male")
        elseif rng < SandboxVars.DynBodyShape.EmaciatedChanceMale + SandboxVars.DynBodyShape.UnderweightChanceMale + SandboxVars.DynBodyShape.DefaultChanceMale then
        elseif rng <= SandboxVars.DynBodyShape.EmaciatedChanceMale + SandboxVars.DynBodyShape.UnderweightChanceMale + SandboxVars.DynBodyShape.DefaultChanceMale + SandboxVars.DynBodyShape.FatChanceMale then 
            MakeFat(zombie)
            UpdateZombieClotheVisuals(zombie, "_Fat")   
        else
            MakeObese(zombie)
            UpdateZombieClotheVisuals(zombie, "_Obese")
        end
    end

    zombie:resetModel()
end

local processedZombies = {}

local function FreeProcessedZombies()
    if debug then
        local count = 0
        for zombieID, _ in pairs(processedZombies) do
            count = count + 1
        end
        print("Processed Zombies Size: "..count)
    end
    processedZombies = {}
end

Events.EveryTenMinutes.Add(FreeProcessedZombies)

local function OnZombieUpdate(zombie)
    local ZombieID = zombie:getPersistentOutfitID()

    if not processedZombies[ZombieID] then
        if instanceof(zombie, "IsoZombie") then
            if zombie:isReanimatedPlayer() then
            else
                --Use TrueID as seed for random number. This should give persistent results across multiplayer and playthroughs
                --This gets true zombie ID, thanks to SirDoggyJvla https://pzwiki.net/wiki/PersistentOutfitID
                -- if zombie is not yet initialized by the game, force it to be initialized so no issues can arise from unset zombies
                if ZombieID == 0 then
                    zombie:dressInRandomOutfit()
                    ZombieID = zombie:getPersistentOutfitID()
                end
                -- transform the pID into bits
                local bits = string.split(string.reverse(Long.toUnsignedString(ZombieID, 2)), "")
                while #bits < 16 do bits[#bits+1] = "0" end

                -- trueID
                bits[16] = "0"
                local TrueID = Long.parseUnsignedLong(string.reverse(table.concat(bits, "")), 2)

                DynamicZombieShape( zombie, TrueID )
            end
            -- Mark the zombie as processed
            processedZombies[ZombieID] = true
        end
    end
end

Events.OnZombieUpdate.Add(OnZombieUpdate)

local function OnZombieDead(zombie)
    ---@type WornItems|ArrayList
    local wornItems = zombie:getWornItems()
    for i=0, wornItems:size()-1 do
        local wornItem = wornItems:get(i):getItem()
        local ItemVisual = wornItem:getVisual()

        if HasSufix(wornItem:getFullType()) then --Is one of the fat or Obese Version. Remove from inventory, add a default one, and copy visuals and conditions
            local newWornItem = instanceItem(RemoveSufix(wornItem:getFullType())) --Instance new Item
            local newItemVisual = newWornItem:getVisual() --get new Visual
            newItemVisual:copyFrom(ItemVisual) --copy visuals
            newWornItem:copyConditionModData(wornItem) --copy conditions
            newWornItem:setCondition(wornItem:getCondition())
            local zombInv =zombie:getInventory() --get inventory
            zombInv:Remove(wornItem) --Remove old Item
            zombInv:AddItem(newWornItem) --Add new Item
            zombie:setWornItem(newWornItem:getBodyLocation(),newWornItem) --Force Wear New Item
        end
    end
end

Events.OnZombieDead.Add(OnZombieDead)

local function OnGameStart()
    --if not isCopySkinningDataAvailable then
    --    if firstError == true then
    --        firstError = false
    --        error("If you see this, You probably haven't installed Dynamic Body Shape mod properly")
            --This error is caused by Dynamic Body Shape Mod
            --If you see this, You probably haven't followed the install instructions.
            --Check the mod description, you need to modify java classes.

            --You can continue forward to the game by pressing f11
            --You can leave the mod enabled, and it won't bother again until restarting the game
            --But the fat and obese models won't work
    --    end
    --end
    processedZombies = {}
    OnClothingUpdated(getPlayer())
end

Events.OnGameStart.Add(OnGameStart)

local firstError = true

local function OnGameBoot()
	--if not isCopySkinningDataAvailable then
    --    return
    --end
    -- Load The skinned Models
    processedZombies = {}

    local male_model = loadSkinnedZomboidModel("MaleBody","skinned/malebody","SmartTexture") --Base Models
    local female_model = loadSkinnedZomboidModel("FemaleBody", "skinned/femalebody", "SmartTexture") --Base Models
end

Events.OnGameBoot.Add(OnGameBoot)