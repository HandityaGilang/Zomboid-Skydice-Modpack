local KittyMod_ModData = {}

local CatModDataKeys = {
    CatBreed = "KITTY_Breed",
    CatPersonality = "KITTY_Personality", 
    CatFurPattern = "KITTY_FurPattern",
    CatFurColor = "KITTY_FurColor",
    CatTameness = "KITTY_Tameness",
    CatIsTamed = "KITTY_IsTamed",
    CatOwner = "KITTY_Owner",
    CatNickname = "KITTY_Nickname",
    CatPlayfulness = "KITTY_Playfulness",
    CatHuntingSkill = "KITTY_HuntingSkill",
    CatLoyalty = "KITTY_Loyalty",
    CatAffection = "KITTY_Affection",
    CatEnergy = "KITTY_Energy",
    CatMood = "KITTY_Mood",
    CatAge = "KITTY_Age",
    CatLastFed = "KITTY_LastFed",
    CatFavoriteFood = "KITTY_FavoriteFood",
    CatSleepLocation = "KITTY_SleepLocation"
}

function KittyMod_ModData.setCatData(cat, key, value)
    if not cat then return false end
    local catKey = CatModDataKeys[key]
    if catKey then
        cat:getModData()[catKey] = value
        KittyMod_ModData.syncWithFramework(cat, key, value)
        return true
    end
    return false
end

function KittyMod_ModData.getCatData(cat, key)
    if not cat then return nil end
    local catKey = CatModDataKeys[key]
    if catKey then
        return cat:getModData()[catKey]
    end
    return nil
end

function KittyMod_ModData.initializeCatData(cat, catBreed)
    if not cat then return false end
    local modData = cat:getModData()
    if not modData[CatModDataKeys.CatBreed] then
        modData[CatModDataKeys.CatBreed] = catBreed or "Domestic Shorthair"
        modData[CatModDataKeys.CatPersonality] = KittyMod_ModData.generateRandomPersonality()
        modData[CatModDataKeys.CatFurPattern] = KittyMod_ModData.generateRandomPattern()
        modData[CatModDataKeys.CatFurColor] = KittyMod_ModData.generateRandomColor()
        modData[CatModDataKeys.CatTameness] = 0
        modData[CatModDataKeys.CatIsTamed] = false
        modData[CatModDataKeys.CatOwner] = ""
        modData[CatModDataKeys.CatNickname] = ""
        modData[CatModDataKeys.CatPlayfulness] = ZombRand(50, 100)
        modData[CatModDataKeys.CatHuntingSkill] = ZombRand(30, 80)
        modData[CatModDataKeys.CatLoyalty] = 0
        modData[CatModDataKeys.CatAffection] = 0
        modData[CatModDataKeys.CatEnergy] = 100
        modData[CatModDataKeys.CatMood] = "content"
        modData[CatModDataKeys.CatAge] = "adult"
        modData[CatModDataKeys.CatLastFed] = 0
        modData[CatModDataKeys.CatFavoriteFood] = KittyMod_ModData.generateFavoriteFood()
        modData[CatModDataKeys.CatSleepLocation] = ""
        return true
    end
    return false
end

function KittyMod_ModData.generateRandomPersonality()
    local personalities = {"playful", "lazy", "curious", "shy", "aggressive", "friendly", "independent", "clingy"}
    return personalities[ZombRand(1, #personalities + 1)]
end

function KittyMod_ModData.generateRandomPattern()
    local patterns = {"solid", "tabby", "calico", "tortoiseshell", "bicolor", "pointed"}
    return patterns[ZombRand(1, #patterns + 1)]
end

function KittyMod_ModData.generateRandomColor()
    local colors = {"black", "white", "gray", "orange", "brown", "cream", "silver"}
    return colors[ZombRand(1, #colors + 1)]
end

function KittyMod_ModData.generateFavoriteFood()
    local foods = {"fish", "chicken", "beef", "tuna", "salmon", "turkey", "treats"}
    return foods[ZombRand(1, #foods + 1)]
end

function KittyMod_ModData.isCat(animal)
    if not animal then return false end
    return KittyMod_ModData.getCatData(animal, "CatBreed") ~= nil
end

function KittyMod_ModData.syncWithFramework(cat, key, value)
    local success, bridge = pcall(function()
        return require("KittyMod/Integration/KittyMod_FrameworkBridge")
    end)
    if success and bridge and bridge.isFrameworkAvailable() then
        if bridge.isFeatureEnabled("dataSync") then
            local frameworkKeyMap = {
                CatTameness = "Tameness",
                CatIsTamed = "IsTamed", 
                CatOwner = "Owner",
                CatAffection = "Affection",
                CatMood = "Mood",
                CatEnergy = "Energy"
            }
            local frameworkKey = frameworkKeyMap[key]
            if frameworkKey then
                sendServerCommand("AE_UIFramework", "dataSync", {
                    syncType = "animalData",
                    animalID = cat:getOnlineID(),
                    animalType = "cat",
                    dataKey = frameworkKey,
                    value = value,
                    source = "KittyMod"
                })
            end
        end
    end
end

function KittyMod_ModData.getAllCatData(cat)
    if not cat then return nil end
    local catData = {}
    for key, _ in pairs(CatModDataKeys) do
        catData[key] = KittyMod_ModData.getCatData(cat, key)
    end
    return catData
end

function KittyMod_ModData.hasValidCatData(cat)
    if not cat then return false end
    local essentialKeys = {"CatBreed", "CatTameness"}
    for _, key in ipairs(essentialKeys) do
        if KittyMod_ModData.getCatData(cat, key) == nil then
            return false
        end
    end
    return true
end

return KittyMod_ModData