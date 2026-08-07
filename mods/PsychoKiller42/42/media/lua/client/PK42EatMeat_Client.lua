-- PK42EatMeat_Client.lua
-- intercepta ISEatFoodAction.perform, lado CLIENTE.
-- Responsabilidade: detectar carne do mod no item consumido,
-- neutralizar o poisonPower localmente (bloqueia consumeWildFoodGeneric do engine antes que ele aplique FoodSickness) e enviar o comando
-- ao servidor via sendClientCommand para que toda a lógica de efeitos seja processada de forma autoritativa.

local CFG = {
    -- Debug prints
    DEBUGMODE = SandboxVars.PK42 and SandboxVars.PK42.isDebugMode or false,

    -- Carnes de zumbi
    ZOMBIE_MEATS = {
        ["PK42.TaintedMeat"]        = true,
        ["PK42.ZombieBrain"]        = true,
        ["PK42.InfectedTendons"]    = true,
    },

    -- Carnes humanas
    HUMAN_MEATS = {
        ["PK42.HumanMeat"]          = true,
        ["PK42.HumanBrain"]         = true,
        ["PK42.HumanTendons"]       = true,
    },

    -- Cogumelos/berries SEMPRE venenosos, independente do sorteio do Core (todo save).
    ALWAYS_POISON_NEUTRALIZERS = {
        ["Base.BerryPoisonIvy"] = true,
        ["Base.HollyBerry"]     = true,
    },

    -- Cogumelos/berries GENÉRICOS: apenas UM fullType de cada lista é o "venenoso da partida",
    -- sorteado em Core.initPoisonousBerry()/initPoisonousMushroom().
    -- Os outros 6/4 fullTypes do mesmo grupo são sempre seguros nesse save.
    -- Por isso não dá pra usar lookup estático, precisa comparar contra getCore():getPoisonousBerry() / getPoisonousMushroom() em runtime.
    GENERIC_MUSHROOM_BERRY = {
        ["Base.MushroomGeneric1"] = true,
        ["Base.MushroomGeneric2"] = true,
        ["Base.MushroomGeneric3"] = true,
        ["Base.MushroomGeneric4"] = true,
        ["Base.MushroomGeneric5"] = true,
        ["Base.MushroomGeneric6"] = true,
        ["Base.MushroomGeneric7"] = true,
        ["Base.BerryGeneric1"]    = true,
        ["Base.BerryGeneric2"]    = true,
        ["Base.BerryGeneric3"]    = true,
        ["Base.BerryGeneric4"]    = true,
        ["Base.BerryGeneric5"]    = true,
    },

    -- Neutralizador de food sickness (poison)
    POISON_NEUTRALIZERS = {
        ["Base.LemonGrass"] = true,
    },
}

-- Retorna true se o fullType for o cogumelo/berry realmente venenoso NESTE save
-- (HollyBerry/BerryPoisonIvy sempre, ou o genérico sorteado).
local function isInfectionNeutralizerItem(ft)
    if CFG.ALWAYS_POISON_NEUTRALIZERS[ft] then return true end
    if CFG.GENERIC_MUSHROOM_BERRY[ft] then
        local core = getCore()
        if not core then return false end
        if ft == core:getPoisonousBerry()    then return true end
        if ft == core:getPoisonousMushroom() then return true end
    end
    return false
end

local function classifyDirect(item)
    local ft       = item:getFullType()
    local isZombie = CFG.ZOMBIE_MEATS[ft] ~= nil
    local isHuman  = CFG.HUMAN_MEATS[ft]  ~= nil
    return isZombie, isHuman
end

local function countExtraMeat(item)
    local human, zombie = 0, 0
    if not item:haveExtraItems() then return 0, 0 end
    local extras = item:getExtraItems()
    for i = 0, extras:size() - 1 do
        local ft = extras:get(i)
        if CFG.HUMAN_MEATS[ft]  then human  = human  + 1 end
        if CFG.ZOMBIE_MEATS[ft] then zombie = zombie + 1 end
    end
    return human, zombie
end

-- Verifica se há neutralizador de infecção (cogumelo/berry) e/ou de poison (LemonGrass).
-- Retorna dois booleans: neutralizedInfection, neutralizedPoison.
local function neutralizeAndCheck(item)
    local foundInfNeutral    = false
    local foundPoisonNeutral = false

    -- extraItems: ingredientes normais (carnes, cogumelos, berries)
    if item:haveExtraItems() then
        local extras = item:getExtraItems()
        for i = 0, extras:size() - 1 do
            local ft = extras:get(i)
            local isInf = isInfectionNeutralizerItem(ft)
            if CFG.DEBUGMODE then
                print("[PK42][EatMeat][Client] extraItem: " .. tostring(ft)
                    .. " | isInfNeutralizer(real)=" .. tostring(isInf)
                    .. " | isPoisonNeutralizer=" .. tostring(CFG.POISON_NEUTRALIZERS[ft] ~= nil))
            end
            if isInf then foundInfNeutral    = true end
            if CFG.POISON_NEUTRALIZERS[ft]    then foundPoisonNeutral = true end
        end
    end

    -- spices: temperos adicionados via useSpice (ex: LemonGrass, Garlic, etc)
    local spices = item:getSpices()
    if spices then
        for i = 0, spices:size() - 1 do
            local ft = spices:get(i)
            local isInf = isInfectionNeutralizerItem(ft)
            if CFG.DEBUGMODE then
                print("[PK42][EatMeat][Client] spice: " .. tostring(ft)
                    .. " | isInfNeutralizer(real)=" .. tostring(isInf)
                    .. " | isPoisonNeutralizer=" .. tostring(CFG.POISON_NEUTRALIZERS[ft] ~= nil))
            end
            if isInf then foundInfNeutral    = true end
            if CFG.POISON_NEUTRALIZERS[ft]    then foundPoisonNeutral = true end
        end
    end

    if CFG.DEBUGMODE then
        print("[PK42][EatMeat][Client] neutralizeAndCheck result -> foundInfNeutral="
            .. tostring(foundInfNeutral) .. " foundPoisonNeutral=" .. tostring(foundPoisonNeutral))
    end

    if not foundInfNeutral and not foundPoisonNeutral then
        return false, false
    end

    -- Zera o poisonPower se qualquer neutralizador estiver presente,
    -- impedindo que o engine aplique FoodSickness nativo
    local pp = item:getPoisonPower() or 0
    if CFG.DEBUGMODE then
        print("[PK42][EatMeat][Client] poisonPower before zero-out: " .. tostring(pp))
    end
    if pp > 0 then
        item:setPoisonPower(0)
    end

    return foundInfNeutral, foundPoisonNeutral
end

local _ISEatFoodAction_perform = ISEatFoodAction.perform
function ISEatFoodAction:perform()
    local character = self.character
    local item      = self.item

    if not character or not item then
        _ISEatFoodAction_perform(self)
        return
    end

    local isZombieDirect, isHumanDirect = classifyDirect(item)
    local humanCount, zombieCount       = 0, 0
    local neutralizedInfection          = false
    local neutralizedPoison             = false
    local isRecipe                      = false

    if not (isZombieDirect or isHumanDirect) then
        humanCount, zombieCount = countExtraMeat(item)
        if humanCount > 0 or zombieCount > 0 then
            isRecipe = true
            -- Pré-neutralização: deve acontecer ANTES do perform original
            neutralizedInfection, neutralizedPoison = neutralizeAndCheck(item)
        end
    end

    if CFG.DEBUGMODE then
        print("[PK42][EatMeat][Client] perform() classify -> isZombieDirect=" .. tostring(isZombieDirect)
            .. " isHumanDirect=" .. tostring(isHumanDirect)
            .. " humanCount=" .. tostring(humanCount)
            .. " zombieCount=" .. tostring(zombieCount)
            .. " isRecipe=" .. tostring(isRecipe)
            .. " neutralizedInfection=" .. tostring(neutralizedInfection)
            .. " neutralizedPoison=" .. tostring(neutralizedPoison))
    end

    -- Perform original
    _ISEatFoodAction_perform(self)

    if not isZombieDirect and not isHumanDirect
        and humanCount == 0 and zombieCount == 0 then
        return
    end

    -- Envia ao servidor para processar efeitos.
    local isCooked = item:isCooked()

    if isZombieDirect or isHumanDirect then
        sendClientCommand(
            character,
            "PK42EatMeat",
            "MeatConsumed",
            {
                isHuman              = isHumanDirect,
                isZombie             = isZombieDirect,
                isCooked             = isCooked,
                isRecipe             = false,
                units                = 1,
                neutralizedInfection = false,
                neutralizedPoison    = false,
            }
        )
        return
    end

    if humanCount > 0 then
        sendClientCommand(
            character,
            "PK42EatMeat",
            "MeatConsumed",
            {
                isHuman            = true,
                isZombie           = false,
                isCooked           = false,
                isRecipe           = true,
                units              = humanCount,
                neutralizedPoison  = neutralizedPoison,
            }
        )
    end

    if zombieCount > 0 then
        if CFG.DEBUGMODE then
            print("[PK42][EatMeat][Client] sending MeatConsumed (zombie recipe) -> units="
                .. tostring(zombieCount) .. " neutralizedInfection=" .. tostring(neutralizedInfection)
                .. " neutralizedPoison=" .. tostring(neutralizedPoison))
        end
        sendClientCommand(
            character,
            "PK42EatMeat",
            "MeatConsumed",
            {
                isHuman              = false,
                isZombie             = true,
                isCooked             = false,
                isRecipe             = true,
                units                = zombieCount,
                neutralizedInfection = neutralizedInfection,
                neutralizedPoison    = neutralizedPoison,
            }
        )
    end
end