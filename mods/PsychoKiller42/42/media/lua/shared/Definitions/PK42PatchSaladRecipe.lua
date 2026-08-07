-- PK42PatchSaladRecipe.lua
-- Adiciona LemonGrass como ingrediente válido para a evolved recipe "Salad"
-- Funciona também criar um script.txt para sobrescrever a definição vanilla, porém com o patch via lua
-- garantimos não só a compatibilidade com outros mods, mas também a persistência da definição mesmo que outro mod sobrescreva a definição vanilla.
-- além disso serve de referência para outros modders entenderem como funcionam os métodos

local function patchLemonGrass()
    local item = getScriptManager():getItem("Base.LemonGrass")
    if not item then
        print("[PK42] ERRO: Base.LemonGrass não encontrado")
        return
    end

    -- Verifica se Salad já existe na definição atual (vanilla ou override de outro mod)
    local evolvedList = item:getEvolvedRecipe()
    for i = 0, evolvedList:size() - 1 do
        local entry = evolvedList:get(i)
        -- entry pode ser "Salad:1" ou só "Salad". Checa pelo nome antes do ":"
        local recipeName = entry:split(":")[1] or entry
        if recipeName:trim():lower() == "salad" then
            print("[PK42] LemonGrass já tem Salad definido ('" .. entry .. "'), pulando patch")
            return
        end
    end

    -- Não existe -> Adiciona via DoParam
    item:DoParam("EvolvedRecipe", "Salad:1")
    print("[PK42] DoParam EvolvedRecipe Salad:1 aplicado ao LemonGrass")

    local ok, err = pcall(function()
        item:OnScriptsLoaded(nil)
    end)
    
    if ok then
        print("[PK42] LemonGrass registrado em Salad com sucesso")
    else
        print("[PK42] ERRO: evolved recipe 'Salad' não encontrada")
    end
end

Events.OnInitWorld.Add(patchLemonGrass)