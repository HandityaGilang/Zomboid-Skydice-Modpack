
-- PK42EatMeat_Server.lua
-- Orquestrador SERVER-SIDE do EatMeat.
-- Recebe o comando "MeatConsumed" do cliente via OnClientCommand.

local SU = require "Utils/PK42SharedUtils"
-- Carnes de zumbi
local ZOMBIE_MEATS = {
    ["PK42.TaintedMeat"]        = true,
    ["PK42.ZombieBrain"]        = true,
    ["PK42.InfectedTendons"]    = true,
}

-- Carnes humanas
local HUMAN_MEATS = {
    ["PK42.HumanMeat"]          = true,
    ["PK42.HumanBrain"]         = true,
    ["PK42.HumanTendons"]       = true,
}

local function getSandboxCFG()
    local opts = SandboxVars.PK42

    local xpZombieRaw    = opts and opts.XPOnEatRawZombieMeat    or 30
    local xpZombieCooked = opts and opts.XPOnEatCookedZombieMeat or 20
    local xpZombieRecipe = opts and opts.XPOnEatRecipeZombieMeat or 10
    local cookedChance   = opts and opts.OnEatCookedPlayerInfectionChance or 50

    return {
        -- Debug prints
        DEBUGMODE = opts and opts.isDebugMode or false,

        -- XP por consumo (humano = dobro do zumbi)
        XP_ZOMBIE_RAW    = xpZombieRaw,
        XP_ZOMBIE_COOKED = xpZombieCooked,
        XP_ZOMBIE_RECIPE = xpZombieRecipe,
        XP_HUMAN_RAW     = xpZombieRaw    * 2,
        XP_HUMAN_COOKED  = xpZombieCooked * 2,
        XP_HUMAN_RECIPE  = xpZombieRecipe * 2,

        -- Cap diário de XP
        ENABLE_XP_DAILY_CAP = opts and opts.EnableXPDailyCap ~= false,
        DAILY_XP_CAP        = opts and opts.XPDailyCap or 200,

        -- Infecção Knox
        INFECTION_DELAY_MIN            = 12,
        INFECTION_DELAY_MAX            = 24,
        -- Chances de infecção
        INFECTION_CHANCE_COOKED        = cookedChance,
        INFECTION_CHANCE_COOKED_PSYCHO = opts and opts.OnEatCookedPsychopathInfectionChance or 5,
        -- Chance na receita e acúmulo por consumo 
        INFECTION_CHANCE_RECIPE        = cookedChance / 2,
        INFECTION_EXTRA_PER_CONSUME    = 10,

        -- Food sickness
        POISON_DELAY_MIN         = 6,
        POISON_DELAY_MAX         = 12,
        POISON_CHANCE_COOKED     = 40,
        POISON_CHANCE_RECIPE     = 15,
        POISON_EXTRA_PER_CONSUME = 10,

        -- Carne humana cozida (player comum)
        HUMAN_COOKED_SICKNESS_CHANCE = 30,
        HUMAN_COOKED_POISON_POWER    = 10,

        -- Carne humana em receita (player comum)
        HUMAN_RECIPE_POISON_CHANCE   = 15,

        -- Redução de chance de poison quando LemonGrass está presente na receita
        -- Aplica para player comum
        LEMONGRASS_POISON_REDUCTION  = 0.8, --opts and opts.LemonGrassPoisonReduction or 0.8,
    }
end

-- Chaves de ModData — referenciadas via SU.MD para consistência global
local MD_XP_TODAY       = SU.MD.XP_EAT_TODAY
local MD_LAST_RESET     = SU.MD.LAST_EAT_RESET
local MD_TOTAL_MEAT     = SU.MD.TOTAL_MEAT
local MD_PENDING_INF    = SU.MD.PENDING_INFECTION
local MD_PENDING_POISON = SU.MD.PENDING_POISON
local MD_INF_WINDOW     = SU.MD.INF_WINDOW
local MD_POISON_WINDOW  = SU.MD.POISON_WINDOW

-- Delay randomizado para infecção e food poisoning
local function randInfectionDelay()
    local cfg = getSandboxCFG()
    return cfg.INFECTION_DELAY_MIN
        + ZombRand(cfg.INFECTION_DELAY_MAX - cfg.INFECTION_DELAY_MIN + 1)
end

local function randPoisonDelay()
    local cfg = getSandboxCFG()
    return cfg.POISON_DELAY_MIN
        + ZombRand(cfg.POISON_DELAY_MAX - cfg.POISON_DELAY_MIN + 1)
end

-- Helpers
local function worldHour()
    return SU.worldHour()
end

-- concede XP de Insanity com cap usando o bucket de EatMeat.
local function gainInsanityXP(player, amount)
    local cfg = getSandboxCFG()
    SU.gainInsanityXP(
        player, amount,
        MD_XP_TODAY, MD_LAST_RESET,
        cfg.DAILY_XP_CAP, cfg.ENABLE_XP_DAILY_CAP
    )
end

local function incrementTotalMeat(player, units)
    local md  = player:getModData()
    local old = md[MD_TOTAL_MEAT] or 0
    md[MD_TOTAL_MEAT] = old + (units or 1)
    player:transmitModData()
end

-- Janela de consumo
-- Consumir várias porções em um curto período aumenta a chance de infecção/poisoning.
local function windowCount(player, key, windowHours)
    local md  = player:getModData()
    local win = md[key]
    if not win then return 0 end
    local elapsed = worldHour() - (win.windowStart or 0)
    if elapsed >= windowHours then
        md[key] = nil
        return 0
    end
    return win.count or 0
end

local function windowRecord(player, key, windowHours)
    local md  = player:getModData()
    local now = worldHour()
    local win = md[key]
    if not win or (now - (win.windowStart or 0)) >= windowHours then
        md[key] = { count = 1, windowStart = now }
    else
        win.count = (win.count or 0) + 1
    end
end

-- Infecção imediata para carne de zumbi crua, sem chance, sem delay, sem janela de consumo.
-- Comeu é vala e já era.
local function infectPlayer(player)
    local bd = player:getBodyDamage()
    if not bd then return end

    bd:setInfected(true)
    bd:setInfectionMortalityDuration(bd:pickMortalityDuration())
    bd:setInfectionTime(player:getHoursSurvived())

    local bodyParts  = bd:getBodyParts()
    local torsoUpper = bodyParts:get(BodyPartType.ToIndex(BodyPartType.Torso_Upper))

    if torsoUpper then
        torsoUpper:SetInfected(true)
    else
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part then
                part:SetInfected(true)
                break
            end
        end
    end
end

-- Infecção zumbi com delay e chance, dependendo do tipo de carne e do player.
-- isPsycho: usa chance reduzida (INFECTION_CHANCE_COOKED_PSYCHO)
-- skipInfection: neutralizador ativo = só registra janela, sem agendar infecção
local function scheduleInfection(player, isRecipe, isCooked, skipInfection, isPsycho)
    local cfg   = getSandboxCFG()
    local extra = windowCount(player, MD_INF_WINDOW, cfg.INFECTION_DELAY_MAX)
    windowRecord(player, MD_INF_WINDOW, cfg.INFECTION_DELAY_MAX)

    if cfg.DEBUGMODE then
        print("[PK42][EatMeat][Server] scheduleInfection -> isRecipe=" .. tostring(isRecipe)
            .. " isCooked=" .. tostring(isCooked)
            .. " skipInfection(neutralized)=" .. tostring(skipInfection)
            .. " isPsycho=" .. tostring(isPsycho)
            .. " windowExtra=" .. tostring(extra))
    end

    if skipInfection then
        if cfg.DEBUGMODE then
            print("[PK42][EatMeat][Server] scheduleInfection -> SKIPPED (neutralizer active, window registered only)")
        end
        return
    end

    local base
    if isRecipe then
        base = cfg.INFECTION_CHANCE_RECIPE
    elseif isPsycho then
        base = cfg.INFECTION_CHANCE_COOKED_PSYCHO
    else
        base = cfg.INFECTION_CHANCE_COOKED
    end

    local chance = math.min(base + extra * cfg.INFECTION_EXTRA_PER_CONSUME, 100)
    local roll   = ZombRand(100)

    if cfg.DEBUGMODE then
        print("[PK42][EatMeat][Server] scheduleInfection -> base=" .. tostring(base)
            .. " finalChance=" .. tostring(chance)
            .. " roll=" .. tostring(roll)
            .. " result=" .. ((roll < chance) and "INFECT" or "SAFE"))
    end

    if roll >= chance then return end

    local md = player:getModData()

    if md[MD_PENDING_INF] then
        md[MD_PENDING_INF].consumed = (md[MD_PENDING_INF].consumed or 1) + 1
        player:transmitModData()
        return
    end

    local delay  = randInfectionDelay()
    local eta    = worldHour() + delay
    local parts  = { "Torso_Upper", "Torso_Lower", "UpperArm_L", "UpperArm_R", "Hand_L", "Hand_R" }
    local part   = parts[ZombRand(#parts) + 1]

    md[MD_PENDING_INF] = {
        scheduledHour = eta,
        bodyPart      = part,
        consumed      = 1,
    }
    player:transmitModData()
end

local function CheckPendingInfection(player)
    local md      = player:getModData()
    local pending = md[MD_PENDING_INF]
    if not pending then return end

    local remaining = pending.scheduledHour - worldHour()
    if remaining > 0 then return end

    if not SU.hasCannibalistTrait(player) then -- previne que canibais sejam infectados, caso tenham adquirido a trait APÓS já terem infecção agendada.
        infectPlayer(player)
    end

    md[MD_PENDING_INF] = nil
    player:transmitModData()
end

-- Food poisoning com delay e chance, dependendo do tipo de carne e do player.
-- neutralizedPoison: LemonGrass presente.
-- isPsycho=true  -> elimina poison completamente (retorna sem fazer nada)
-- isPsycho=false -> reduz chance em LEMONGRASS_POISON_REDUCTION
local function schedulePoison(player, isRecipe, isCooked, neutralizedPoison, isPsycho)
    -- Psicopata com LemonGrass: cancela poison completamente
    local cfg = getSandboxCFG()

    if neutralizedPoison and isPsycho then
        if cfg.DEBUGMODE then
            print("[PK42][EatMeat][Server] schedulePoison -> SKIPPED (psycho + neutralized LemonGrass)")
        end
        return
    end

    local delay = randPoisonDelay()
    local extra = windowCount(player, MD_POISON_WINDOW, cfg.POISON_DELAY_MAX)
    windowRecord(player, MD_POISON_WINDOW, cfg.POISON_DELAY_MAX)

    local base
    if isRecipe     then base = cfg.POISON_CHANCE_RECIPE
    elseif isCooked then base = cfg.POISON_CHANCE_COOKED
    else                 base = cfg.POISON_CHANCE_COOKED  -- raw: mesma chance que cozido (native já aplica)
    end

    local chance = math.min(base + extra * cfg.POISON_EXTRA_PER_CONSUME, 100)

    -- Player comum com LemonGrass: reduz chance em LEMONGRASS_POISON_REDUCTION
    if neutralizedPoison then
        chance = chance * (1.0 - cfg.LEMONGRASS_POISON_REDUCTION)
    end

    local roll   = ZombRand(100)

    if cfg.DEBUGMODE then
        print("[PK42][EatMeat][Server] schedulePoison -> isRecipe=" .. tostring(isRecipe)
            .. " isCooked=" .. tostring(isCooked)
            .. " neutralizedPoison=" .. tostring(neutralizedPoison)
            .. " isPsycho=" .. tostring(isPsycho)
            .. " base=" .. tostring(base)
            .. " windowExtra=" .. tostring(extra)
            .. " finalChance=" .. tostring(chance)
            .. " roll=" .. tostring(roll)
            .. " result=" .. ((roll < chance) and "POISON" or "SAFE"))
    end

    if roll >= chance then return end

    local md = player:getModData()
    if md[MD_PENDING_POISON] then
        if md[MD_PENDING_POISON].scheduledHour > worldHour() then
            md[MD_PENDING_POISON].consumed = (md[MD_PENDING_POISON].consumed or 1) + 1
            player:transmitModData()
            return
        else
            md[MD_PENDING_POISON] = nil
        end
    end

    local eta = worldHour() + delay
    md[MD_PENDING_POISON] = { scheduledHour = eta, consumed = 1 }
    player:transmitModData()
end

local function CheckPendingPoison(player)
    local md      = player:getModData()
    local pending = md[MD_PENDING_POISON]
    if not pending then return end

    local remaining = pending.scheduledHour - worldHour()
    if remaining > 0 then return end

    local severity = math.min(pending.consumed, 3)

    -- POISON > 0 impede que FOOD_SICKNESS decaia (ver UpdateIllness em BodyDamage.java)
    -- É o mesmo mecanismo que DangerousUncooked usa
    player:getStats():add(CharacterStat.POISON, severity * 15.0)

    md[MD_PENDING_POISON] = nil
    player:transmitModData()
end

-- Lógica central por consumo
-- Chamada pelo OnClientCommand
local function onMeatConsumed(player, args)
    local isHuman            = args.isHuman            or false
    local isZombie           = args.isZombie           or false
    local isCooked           = args.isCooked           or false
    local isRecipe           = args.isRecipe           or false
    local units              = args.units              or 1
    local neutralizedInfection = args.neutralizedInfection or false
    local neutralizedPoison    = args.neutralizedPoison    or false

    local cfg = getSandboxCFG()

    if cfg.DEBUGMODE then
        print("[PK42][EatMeat][Server] onMeatConsumed RECEIVED -> isHuman=" .. tostring(isHuman)
            .. " isZombie=" .. tostring(isZombie)
            .. " isCooked=" .. tostring(isCooked)
            .. " isRecipe=" .. tostring(isRecipe)
            .. " units=" .. tostring(units)
            .. " neutralizedInfection=" .. tostring(neutralizedInfection)
            .. " neutralizedPoison=" .. tostring(neutralizedPoison))
    end

    -- XP
    local xp = 0
    if isHuman then
        xp = isRecipe and (cfg.XP_HUMAN_RECIPE * units)
                      or  (isCooked and cfg.XP_HUMAN_COOKED or cfg.XP_HUMAN_RAW)
    elseif isZombie then
        xp = isRecipe and (cfg.XP_ZOMBIE_RECIPE * units)
                      or  (isCooked and cfg.XP_ZOMBIE_COOKED or cfg.XP_ZOMBIE_RAW)
    end
    gainInsanityXP(player, xp)
    incrementTotalMeat(player, units)

    -- Canibal: imune a qualquer efeito negativo de carne, com ou sem tempero
    if SU.hasCannibalistTrait(player) then return end

    local isPsycho = SU.hasPsychopathTrait(player)

    -- Carne humana
    if isHuman then
        if isPsycho then
            -- Psicopata: cru = FoodSickness nativo. Cozida = sem efeito.
            -- Receita: LemonGrass elimina poison completamente (neutralizedPoison cancela tudo).
            if isRecipe then
                if not neutralizedPoison then
                    local chance = cfg.HUMAN_RECIPE_POISON_CHANCE
                    local roll   = ZombRand(100)
                    if roll < chance then
                        player:getStats():add(CharacterStat.POISON, cfg.HUMAN_COOKED_POISON_POWER)
                    end
                end
                -- neutralizedPoison=true = sem efeito nenhum
            end
            return
        end

        -- Player comum:
        -- Crua: FoodSickness já resolvido nativamente pelo engine.
        -- Cozida: chance de food sickness leve via mod.
        if isCooked then
            local roll = ZombRand(100)
            if roll < cfg.HUMAN_COOKED_SICKNESS_CHANCE then
                player:getStats():add(CharacterStat.POISON, cfg.HUMAN_COOKED_POISON_POWER)
            end
        end

        -- Receita: LemonGrass reduz chance em LEMONGRASS_POISON_REDUCTION (não elimina)
        if isRecipe then
            local chance = cfg.HUMAN_RECIPE_POISON_CHANCE
            if neutralizedPoison then
                chance = chance * (1.0 - cfg.LEMONGRASS_POISON_REDUCTION)
            end
            local roll = ZombRand(100)
            if roll < chance then
                player:getStats():add(CharacterStat.POISON, cfg.HUMAN_COOKED_POISON_POWER)
            end
        end
        return
    end

    -- Carne de zumbi
    if not isZombie then return end

    -- Crua direta (qualquer player): infecção imediata. FoodSickness nativo.
    if not isCooked and not isRecipe then
        infectPlayer(player)
        return
    end

    -- Cozida ou receita... psicopata e player comum têm mesma estrutura:
    -- neutralizedInfection (cogumelo/berry): cancela infecção completamente para ambos
    -- neutralizedPoison (LemonGrass):
    --   Psicopata    -> elimina chance de poison completamente (passa true como "cancelar tudo")
    --   Player comum -> reduz chance de poison em LEMONGRASS_POISON_REDUCTION
    scheduleInfection(player, isRecipe, isCooked, neutralizedInfection, isPsycho)
    schedulePoison(player, isRecipe, isCooked, neutralizedPoison, isPsycho)
end

-- Flag de neutralização
local NEUTRALIZER_FLAG = SU.MD.NEUTRALIZER_FLAG

-- Seta a flag ANTES de o engine processar os OnEat dos extraItems.
-- Chamado dentro do OnClientCommand ao receber neutralized=true,
-- com antecedência suficiente pois o comando chega antes do Eat ser processado.
local function setNeutralizerFlag(player, count)
    local pMod = player:getModData()
    -- Acumula caso haja múltiplos cogumelos neutralizadores na receita
    pMod[NEUTRALIZER_FLAG] = (pMod[NEUTRALIZER_FLAG] or 0) + count
    player:transmitModData()
end

-- OnClientCommand
local function OnClientCommand(module, command, player, args)
    if module ~= "PK42EatMeat" then return end

    if command == "MeatConsumed" then
        if not player or not args then return end

        -- Se o cliente confirmou neutralização de infecção, seta a flag ANTES de onMeatConsumed
        if args.neutralizedInfection and args.isZombie then
            setNeutralizerFlag(player, args.units or 1)
        end

        onMeatConsumed(player, args)
    end
end

-- Checks periódicos
local function onEveryTenMinutes()
    if isClient() then return end

    local online = getOnlinePlayers and getOnlinePlayers()
    local onlineSize = online and online:size() or 0

    if onlineSize > 0 then
        -- Multiplayer: itera jogadores online
        for i = 0, onlineSize - 1 do
            local p = online:get(i)
            if p and p:isAlive() then
                CheckPendingInfection(p)
                CheckPendingPoison(p)
            end
        end
    else
        -- Singleplayer: getOnlinePlayers retorna lista vazia, usa getPlayer()
        local p = getPlayer and getPlayer()
        if p and p:isAlive() then
            CheckPendingInfection(p)
            CheckPendingPoison(p)
        end
    end
end

-- Hook no ISEatFoodAction:complete
-- O UsedItemProperties.java transfere o maior poisonPower dos
-- ingredientes para o item resultado ANTES do Eat ser chamado.
-- Isso faz o PanFriedVegetables (ou qualquer evolved recipe)
-- herdar o poisonPower do cogumelo venenoso, e o OnEat do item
-- aplica +50 FoodSickness com base nisso.
--
-- A solução: interceptar o complete no servidor, detectar se há
-- um neutralizador nos extraItems, e zerar o poisonPower do item
-- resultado ANTES de chamar character:Eat.
-- Isso roda antes do OnClientCommand chegar,
-- portanto não depende do cliente, é totalmente autoritativo do servidor.

-- Cogumelos/berries SEMPRE venenosos, independente do sorteio do Core (todo save).
local ALWAYS_POISON_NEUTRALIZERS = {
    ["Base.BerryPoisonIvy"] = true,
    ["Base.HollyBerry"]     = true,
}

-- Cogumelos/berries GENÉRICOS: apenas UM fullType de cada lista é o "venenoso da partida",
-- sorteado uma vez por save em Core.initPoisonousBerry()/initPoisonousMushroom().
-- Os outros 6/4 fullTypes do mesmo grupo são sempre seguros nesse save.
-- Não dá pra usar lookup estático, precisa comparar contra getCore():getPoisonousBerry() / getPoisonousMushroom() em runtime.
local GENERIC_MUSHROOM_BERRY = {
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
}

-- Retorna true se o fullType for o cogumelo/berry realmente venenoso NESTE save.
local function isInfectionNeutralizerItem(ft)
    if ALWAYS_POISON_NEUTRALIZERS[ft] then return true end
    if GENERIC_MUSHROOM_BERRY[ft] then
        local core = getCore()
        if not core then return false end
        if ft == core:getPoisonousBerry()    then return true end
        if ft == core:getPoisonousMushroom() then return true end
    end
    return false
end

local POISON_NEUTRALIZERS_ZDK = {
    ["Base.LemonGrass"] = true,
}  -- neutralizadores de food sickness (poison)

zdk.hook({
    ISEatFoodAction = {
        complete = function(orig, self)
            local item = self.item
            if not item then return orig(self) end

            local cfg = getSandboxCFG()

            local hasMeat    = false
            local hasNeutral = false

            -- extraItems: ingredientes normais (carnes, cogumelos, berries)
            if item:haveExtraItems() then
                local extras = item:getExtraItems()
                for i = 0, extras:size() - 1 do
                    local ft = extras:get(i)
                    if ZOMBIE_MEATS[ft] or HUMAN_MEATS[ft] then
                        hasMeat = true
                    end
                    local isInf = isInfectionNeutralizerItem(ft)
                    if isInf or POISON_NEUTRALIZERS_ZDK[ft] then
                        hasNeutral = true
                    end
                    if cfg.DEBUGMODE then
                        print("[PK42][EatMeat][Server][zdk] extraItem: " .. tostring(ft)
                            .. " | isMeat=" .. tostring(ZOMBIE_MEATS[ft] ~= nil or HUMAN_MEATS[ft] ~= nil)
                            .. " | isNeutralizer(real)=" .. tostring(isInf or POISON_NEUTRALIZERS_ZDK[ft] ~= nil))
                    end
                end
            end

            -- spices: temperos (ex: LemonGrass) — vão para baseItem.spices, não extraItems
            local spices = item:getSpices()
            if spices then
                for i = 0, spices:size() - 1 do
                    local ft = spices:get(i)
                    local isInf = isInfectionNeutralizerItem(ft)
                    if isInf or POISON_NEUTRALIZERS_ZDK[ft] then
                        hasNeutral = true
                    end
                    if cfg.DEBUGMODE then
                        print("[PK42][EatMeat][Server][zdk] spice: " .. tostring(ft)
                            .. " | isNeutralizer(real)=" .. tostring(isInf or POISON_NEUTRALIZERS_ZDK[ft] ~= nil))
                    end
                end
            end

            if cfg.DEBUGMODE then
                print("[PK42][EatMeat][Server][zdk] hasMeat=" .. tostring(hasMeat)
                    .. " hasNeutral=" .. tostring(hasNeutral)
                    .. " poisonPower=" .. tostring(item:getPoisonPower()))
            end

            if hasMeat and hasNeutral and item:getPoisonPower() > 0 then
                if cfg.DEBUGMODE then
                    print("[PK42][EatMeat][Server][zdk] zeroing poisonPower (was " .. tostring(item:getPoisonPower()) .. ")")
                end
                item:setPoisonPower(0)
            end

            return orig(self)
        end
    }
}) -- zdk

-- Eventos
Events.OnClientCommand.Add(OnClientCommand)
Events.EveryTenMinutes.Add(onEveryTenMinutes)