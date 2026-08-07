-- Tags VANILLA que indicam recipes que aceitam couro curtido
local VANILLA_LEATHER_TAGS = {
    ["base:leathercrudetannedsmall"]  = true,
    ["base:leathercrudetannedmedium"] = true,
    ["base:leathercrudetannedlarge"]  = true,
    --["base:leatherfurtannedsmall"]    = true,
    --["base:leatherfurtannedmedium"]   = true,
    --["base:leatherfurtannedlarge"]    = true,
}

-- FullType dos itens de couro humano curtido
local HUMAN_LEATHER_TYPES = {
    ["PK42.Human_Leather_Crude_Small_Tan"]  = true,
    ["PK42.Human_Leather_Crude_Medium_Tan"] = true,
    ["PK42.Human_Leather_Crude_Large_Tan"] = true,
}

local function getHumanMadeText()
    local translated = getText("IGUI_PK42_HumanMade")
    -- Se retornou a chave crua, a tradução não foi carregada no servidor
    if translated == "IGUI_PK42_HumanMade" then
        return "Made of Human Skin"  -- fallback hardcoded
    end
    return translated
end

function leatherOnCreate(data, character)
    --print("[PK42] OnCreate chamado!")
    local humanLeatherUsed = false

    local consumed = data:getAllConsumedItems()
    for i = 0, consumed:size() - 1 do
        local ft = consumed:get(i):getFullType()
        --print("[PK42] Consumido: " .. tostring(ft))
        if HUMAN_LEATHER_TYPES[ft] then
            humanLeatherUsed = true
        end
    end

    if not humanLeatherUsed then return end

    local created = data:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local item = created:get(i)
        --print("[PK42] Criado: " .. tostring(item:getName()))
        item:setName(item:getDisplayName() .. " (" .. getHumanMadeText() .. ")")
        item:setCustomName(true)
        item:syncItemFields()  -- sincroniza name + customName com o cliente
    end
    
    addXp(character, Perks.Insanity, 30)
end

local function hookAllLeatherRecipes()
    local allRecipes = getScriptManager():getAllCraftRecipes()
    local count = 0

    for i = 0, allRecipes:size() - 1 do
        local recipe = allRecipes:get(i)
        local hasVanillaLeatherInput = false

        for j = 0, recipe:getInputCount() - 1 do
            if hasVanillaLeatherInput then break end
            local input = recipe:getInputs():get(j)
            local tags = input:getItemTags()
            if tags then
                local iter = tags:iterator()
                while iter:hasNext() do
                    local tag = tostring(iter:next())
                    if VANILLA_LEATHER_TAGS[tag] then
                        hasVanillaLeatherInput = true
                        break
                    end
                end
            end
        end

        if hasVanillaLeatherInput then
            local recipeName = recipe:getName()
            print("[PK42] Hookando recipe: " .. recipeName)
            local wrapperName = "PK42_LW_" .. recipeName:gsub("[^%w]", "_")
            _G[wrapperName] = leatherOnCreate

            local ok, err = pcall(function()
                recipe:Load(recipeName, "{ OnCreate = " .. wrapperName .. ", }")
            end)

            if ok then
                count = count + 1
            else
                print("[PK42] Failed to hook: " .. recipeName .. " | " .. tostring(err))
            end
        end
    end

    print("[PK42] Hooked " .. count .. " leather recipes.")
end

Events.OnInitWorld.Add(hookAllLeatherRecipes)