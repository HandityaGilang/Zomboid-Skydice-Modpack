-- PK42ServerLogic.lua

local SU = require "Utils/PK42SharedUtils"

PK42ServerLogic = PK42ServerLogic or {}

local HOOK_MD_KEYS = {
    "PK42HookStatus", "PK42IsZombie", "PK42IsPlayerCorpse",
    "PK42IsSkeleton", "PK42IsSkinned", "PK42DeathTime",
    "PK42BloodQty",   "PK42MeatRatio", "PK42DeathAge",
    "PK42RotStage",   "PK42CorpseId",
}

local function getSandboxCFG()
    local opts        = SandboxVars.PK42
    local butcherXp   = opts and opts.ButcheringXP or 10
    local insanityXp  = opts and opts.InsanityXP   or 10
    return {
        -- XP no chão
        BUTCHERING_XP      = butcherXp,
        INSANITY_XP        = insanityXp,
        -- XP no gancho (dobro do chão)
        BUTCHERING_XP_HOOK = butcherXp  * 2,
        INSANITY_XP_HOOK   = insanityXp * 2,
        -- Nível de desbloqueio de canibal
        CANNIBAL_UNLOCK_LEVEL = opts and opts.CannibalUnlockThreshold or 7,
        -- Cap diário (mesmo valor e flag do EatMeat, contador independente via SU.MD.XP_BUTCHER_TODAY)
        ENABLE_XP_DAILY_CAP = opts and opts.EnableXPDailyCap ~= false,
        DAILY_XP_CAP        = opts and opts.XPDailyCap or 200,
    }
end

--- Atalho local: concede XP de Insanity com cap usando o bucket de butchering.
local function gainInsanityXP(player, amount)
    local cfg = getSandboxCFG()
    SU.gainInsanityXP(
        player, amount,
        SU.MD.XP_BUTCHER_TODAY, SU.MD.LAST_BUTCHER_RESET,
        cfg.DAILY_XP_CAP, cfg.ENABLE_XP_DAILY_CAP
    )
end

--- Limpa todas as chaves PK42 do ModData de um gancho e transmite.
local function hook_ClearModData(hook)
    if not hook then return end
    local md = hook:getModData()
    for _, k in ipairs(HOOK_MD_KEYS) do md[k] = nil end
    hook:transmitModData()
end

-- Helpers locais
local function getCorpseFromSquare(sq, objectIDAsLong, floatX, floatY, floatZ)
    if not sq then return nil end
    local bodies = sq:getDeadBodys()
    if not bodies or bodies:size() == 0 then return nil end

    if objectIDAsLong then
        for i = 0, bodies:size() - 1 do
            local body = bodies:get(i)
            if body.getObjectIDAsLong then
                local ok, id = pcall(function() return body:getObjectIDAsLong() end)
                if ok and id == objectIDAsLong then
                    return body
                end
            end
        end
    end

    if floatX and floatY then
        local best, bestDist = nil, math.huge
        for i = 0, bodies:size() - 1 do
            local body = bodies:get(i)
            local dx = body:getX() - floatX
            local dy = body:getY() - floatY
            local dz = floatZ and (body:getZ() - floatZ) or 0
            local dist = dx*dx + dy*dy + dz*dz
            if dist < bestDist then bestDist = dist; best = body end
        end
        if best then return best end
    end

    return bodies:get(0)
end

local function removeCorpseFromWorld(sq, corpse)
    if not sq or not corpse then return end
    if isServer() then
        sq:removeCorpse(corpse, false)
        sq:transmitRemoveItemFromSquare(corpse)
    else
        corpse:removeFromWorld()
        corpse:removeFromSquare()
    end
    sq:RecalcAllWithNeighbours(true)
end

local function replaceCorpseWithSkeleton(sq, corpse, isZombie)
    if not sq or not corpse then return end

    local x     = corpse:getX()
    local y     = corpse:getY()
    local z     = corpse:getZ()
    local angle = corpse:getAngle()

    -- Mesma sequência do removeCorpseFromWorld que funciona
    sq:removeCorpse(corpse, false)
    sq:transmitRemoveItemFromSquare(corpse)

    -- Cria esqueleto, mesma assinatura do RemoveCorpseFromHook que funciona
    local newBody = sq:addCorpse(true)
    if not newBody then return end
    
    -- Configura posição e direção do esqueleto igual ao cadáver original
    newBody:setX(x)
    newBody:setY(y)
    newBody:setZ(z)
    newBody:setForwardDirectionAngle(angle)

    -- Persiste origem do esqueleto para CollectBones diferenciar o crânio
    local bodyMd = newBody:getModData()
    bodyMd["PK42IsZombie"] = isZombie == true
    newBody:transmitModData()

    if isServer() then sendCorpse(newBody) end

    sq:RecalcAllWithNeighbours(true)
end

local function giveButcheringLoot(player, corpse, defKey)
    local def = ButcheringUtil.getAnimalDef(defKey)
    if not def then return 0 end

    local skill     = player:getPerkLevel(Perks.Butchering)
    local md        = corpse:getModData()
    local meatRatio = md["meatRatio"] or 1.0
    local deathAge  = md["deathAge"]  or 0
    local rotStage  = md["animalRotStage"] or 0
    local rotten    = rotStage > 0

    md["PK42DefKey"] = defKey

    if def.parts then
        for _, part in pairs(def.parts) do
            local minNb = (part.minNb or 1) * 1.2
            local maxNb = (part.maxNb or 1) * 1.2
            local skillIndex = (math.floor(skill / 2) / 10) + 1
            maxNb = maxNb * skillIndex

            if deathAge > 12 then
                local delta = deathAge / 13
                minNb = minNb / delta
                maxNb = maxNb / delta
                meatRatio = meatRatio / delta
            end

            local nb = math.max(1, ZombRand(
                math.max(1, math.floor(minNb)),
                math.max(2, math.floor(maxNb))
            ))

            local meatDef = AnimalPartsDefinitions.meat[part.item]
            if meatDef then
                local effectiveMeatRatio = (skill == 0) and math.max(meatRatio, 1.2) or meatRatio
                ButcheringUtil.giveMeatModified(meatDef, nb, player, effectiveMeatRatio, corpse, false, rotten, deathAge)
            else
                for _ = 1, nb do
                    local item = instanceItem(part.item)
                    if item then
                        player:getInventory():AddItem(item)
                        sendAddItemToContainer(player:getInventory(), item)
                    end
                end
            end
        end
    end

    md["PK42DefKey"] = nil
end

local function giveSkin(player)
    local item = instanceItem("PK42.Human_Leather_Full_Medium")
    if item then
        player:getInventory():AddItem(item)
        sendAddItemToContainer(player:getInventory(), item)
    end
end

-- Limite máximo de cada osso por coleta (índice 1 da lista = crânio, 2 = dentes, 3 = grande, 4 = médio, 5 = pequeno)
-- A ordem corresponde a BONES_PK42 / BONES_ZVV definidas em HumanPartsDefinitions.
local BONE_CAPS_BY_INDEX = { 1, 1, 2, 2, 2 }  -- [1]=crânio [2]=dentes [3]=grande [4]=médio [5]=pequeno

local function giveBones(player, boneList, minNb, maxNb)
    if not boneList or #boneList == 0 then return end

    -- Monta tabela de contadores respeitando os caps
    local caps    = {}
    local given   = {}
    for i = 1, #boneList do
        caps[i]  = BONE_CAPS_BY_INDEX[i] or 1
        given[i] = 0
    end

    local nb = ZombRand(minNb, maxNb + 1)

    for _ = 1, nb do

        -- Monta lista de candidatos que ainda têm cap disponível
        local available = {}
        for i = 1, #boneList do
            if given[i] < caps[i] then
                table.insert(available, i)
            end
        end
        if #available == 0 then break end  -- todos os caps esgotados

        local pick  = available[ZombRand(1, #available + 1)]
        given[pick] = given[pick] + 1

        local item = instanceItem(boneList[pick])
        if item then
            player:getInventory():AddItem(item)
            sendAddItemToContainer(player:getInventory(), item)
        end
    end
end

-- Tendões
local function tryGiveHumanTendons(player, isZombie)
    local insanity = player:getPerkLevel(Perks.Insanity)
    local chance   = math.min(10 + math.max(0, insanity - 3) * 10, 70)
    if ZombRand(100) < chance then
        local itemType = isZombie and "PK42.InfectedTendons" or "PK42.HumanTendons"
        local item = instanceItem(itemType)
        if item then
            player:getInventory():AddItem(item)
            sendAddItemToContainer(player:getInventory(), item)
        end
    end
end

local function doBloodAndPanic(player, sq, corpse)
    -- Sangue no chão (no player e no square do cadáver)
    local playerSq = player:getCurrentSquare()
    if playerSq then addBloodSplat(playerSq, ZombRand(20)) end
    if sq then addBloodSplat(sq, ZombRand(15)) end

    -- Sangue no player (padrão vanilla de ISRemoveMeatFromAnimal/ISButcherAnimal)
    local perkLevel = player:getPerkLevel(Perks.Butchering)
    local bloodNb   = ZombRand(22 - (perkLevel * 2))
    local bloodGround = 0

    if corpse then
        local md       = corpse:getModData()
        local bloodQty = md and (md["BloodQty"] or md["PK42BloodQty"]) or 0
        if bloodQty > 0 then
            bloodNb     = bloodNb + bloodQty * 2
            bloodGround = bloodQty * 2
        end
    end

    for i = 0, bloodNb do
        player:addBlood(nil, true, false, false)
    end
    syncVisuals(player)
    syncClothingFields(player)
    sendHumanVisual(player)

    if sq then
        for i = 0, bloodGround do
            addBloodSplat(sq, 2, ZombRandFloat(-0.3, 0.3), ZombRandFloat(-0.3, 0.3))
        end
    end

    if player:hasTrait(CharacterTrait.HEMOPHOBIC) then
        player:getStats():add(CharacterStat.PANIC, 30)
        syncPlayerStats(player, 0x00000100)
    end
end

local function getHookFromSquare(sq)
    if not sq then return nil end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if instanceof(obj, "IsoButcherHook") and obj:getSprite() then
            if SU.HookTable[obj:getSprite():getName()] then
                return obj
            end
        end
    end
    return nil
end

-- Handlers: corpos no chão
function PK42ServerLogic.ButcherCorpse(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local sq = cell:getGridSquare(args.corpseX, args.corpseY, args.corpseZ)
    if not sq then return end

    local corpse = getCorpseFromSquare(sq, args.corpseId)
    if not corpse then return end

    local ok, isSkel = pcall(function() return corpse:isSkeleton() end)
    if ok and isSkel then return end

    local defKey   = args.isPlayerCorpse and "PKhuman" or "PKzombie"

    local realSq  = corpse:getSquare() or sq
    giveButcheringLoot(player, corpse, defKey)
    tryGiveHumanTendons(player, args.isZombie)

    replaceCorpseWithSkeleton(realSq, corpse, args.isZombie)
    doBloodAndPanic(player, realSq, corpse)

    sendServerCommand(player, "PK42", "ButcherCorpseFeedback", { success = true })
end

function PK42ServerLogic.SkinCorpse(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local sq = cell:getGridSquare(args.corpseX, args.corpseY, args.corpseZ)
    if not sq then return end

    local corpse = getCorpseFromSquare(sq, args.corpseId)
    if not corpse then return end
    if corpse:getModData()["PK42Skinned"] then return end

    local ok, isSkel = pcall(function() return corpse:isSkeleton() end)
    if ok and isSkel then return end

    giveSkin(player)

    -- Remove itens do cadáver
    corpse:getWornItems():clear()
    corpse:getAttachedItems():clear()
    if corpse:getContainer() then corpse:getContainer():clear() end

    -- Visual skinned
    local hv = corpse.getHumanVisual and corpse:getHumanVisual()
    if hv then
        hv:setBeardModel("")
        hv:setHairModel("")
        local skinned = args.isPlayerCorpse
            and "M_HumanBody04_Skinned"
            or  "M_ZedBody04_Skinned"
        hv:setSkinTextureName(skinned)
        corpse:invalidateCorpse()
        corpse:setInvalidateNextRender(true)
    end

    -- ModData primeiro, depois transmite visual
    corpse:getModData()["PK42Skinned"] = true
    corpse:transmitModData()
    if isServer() then sendCorpse(corpse) end

    local cfg = getSandboxCFG()
    addXp(player, Perks.Butchering, cfg.BUTCHERING_XP)
    gainInsanityXP(player, cfg.INSANITY_XP)
    doBloodAndPanic(player, sq, corpse)

    sendServerCommand(player, "PK42", "SkinCorpseFeedback", { success = true })
end

function PK42ServerLogic.CollectBones(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local sq = cell:getGridSquare(args.corpseX, args.corpseY, args.corpseZ)
    if not sq then return end

    local corpse = getCorpseFromSquare(sq, args.corpseId)
    if not corpse then return end

    local ok, isSkel = pcall(function() return corpse:isSkeleton() end)
    if not (ok and isSkel) then return end

    local skelMd   = corpse:getModData()
    local isZombie
    if skelMd["PK42IsZombie"] ~= nil then
        -- Esqueleto criado pelo mod (ButcherCorpse -> replaceCorpseWithSkeleton): a flag foi gravada.
        isZombie = skelMd["PK42IsZombie"] == true
    else
        -- Esqueleto de decomposição natural: nunca passou pelo ButcherCorpse do mod,
        -- então usa a flag nativa do engine (wasZombie)
        local ok, nativeIsZombie = pcall(function() return corpse:isZombie() end)
        isZombie = ok and nativeIsZombie or false
    end
    local boneList = isZombie and PK42.ZombieBones or PK42.HumanBones

    giveBones(player, boneList, 1, 3)

    local maxInsanityXp = getSandboxCFG().INSANITY_XP / 3
    gainInsanityXP(player, maxInsanityXp)
    removeCorpseFromWorld(sq, corpse)

    sendServerCommand(player, "PK42", "CollectBonesFeedback", { success = true })
end

-- Handlers: corpo no gancho
function PK42ServerLogic.PutCorpseOnHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    local currentStatus = SU.hook_GetStatus(hook)
    if currentStatus ~= "Empty" then return end

    local corpseSq = cell:getGridSquare(args.corpseX, args.corpseY, args.corpseZ)
    if not corpseSq then return end

    local corpse = getCorpseFromSquare(corpseSq, args.objectIDAsLong, args.corpseFloatX, args.corpseFloatY, args.corpseFloatZ)
    if corpse then
        removeCorpseFromWorld(corpseSq, corpse)
    end

    local md = hook:getModData()
    md.PK42HookStatus     = args.initialStatus
    md.PK42IsZombie       = args.isZombie
    md.PK42IsPlayerCorpse = args.isPlayerCorpse or false
    md.PK42IsSkeleton     = args.isSkeleton
    md.PK42IsSkinned      = args.isSkinned
    md.PK42DeathTime      = args.deathTime
    md.PK42BloodQty       = args.bloodQty or 2.5
    md.PK42MeatRatio      = args.meatRatio or 1.0
    md.PK42DeathAge       = args.deathAge or 0
    md.PK42RotStage       = args.rotStage or 0
    md.PK42CorpseId       = args.corpseId
    hook:transmitModData()

    SU.hook_SwapSprite(hook, args.initialStatus)
    hook:sync()

    sendServerCommand(player, "PK42", "HookUpdated", { status = args.initialStatus })
end

function PK42ServerLogic.RemoveCorpseFromHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    local status = SU.hook_GetStatus(hook)
    if status == "Empty" then return end

    local md = hook:getModData()

    if not isClient() then
        local isSkel = md.PK42HookStatus == "Skeleton" or md.PK42IsSkeleton
        local newBody = hookSq:addCorpse(isSkel)

        if newBody then
            newBody:setX(hookSq:getX())
            newBody:setY(hookSq:getY())
            newBody:setZ(hookSq:getZ())

            if newBody.getWornItems   and newBody:getWornItems()   then newBody:getWornItems():clear()   end
            if newBody.getAttachedItems and newBody:getAttachedItems() then newBody:getAttachedItems():clear() end
            if newBody.getContainer   and newBody:getContainer()   then newBody:getContainer():clear()   end

            local bodyMd = newBody:getModData()
            bodyMd["PK42Skinned"]    = md.PK42IsSkinned
            bodyMd["deathTime"]      = md.PK42DeathTime
            bodyMd["BloodQty"]       = md.PK42BloodQty
            bodyMd["meatRatio"]      = md.PK42MeatRatio
            bodyMd["deathAge"]       = md.PK42DeathAge
            bodyMd["animalRotStage"] = md.PK42RotStage

            -- Aplica texture correta: considera skinned e se o sangue foi drenado (Bleeded).
            -- Corpo no gancho sem pele usa M_*Body04_Skinned; se também sangrado, usa _Bleeded.
            if md.PK42IsSkinned and not isSkel then
                local hv = newBody.getHumanVisual and newBody:getHumanVisual()
                if hv then
                    local bleeded = (md.PK42BloodQty or 0) <= 0
                    local tex
                    if md.PK42IsPlayerCorpse then
                        tex = bleeded and "M_HumanBody04_Skinned_Bleeded" or "M_HumanBody04_Skinned"
                    else
                        tex = bleeded and "M_ZedBody04_Skinned_Bleeded"   or "M_ZedBody04_Skinned"
                    end
                    hv:setSkinTextureName(tex)
                    newBody:invalidateCorpse()
                    newBody:setInvalidateNextRender(true)
                end
            end

            newBody:transmitModData()
            if isServer() then sendCorpse(newBody) end
        end
    end

    -- Limpa ModData via helper compartilhado
    hook_ClearModData(hook)

    SU.hook_SwapSprite(hook, "Empty")
    hook:sync()

    hookSq:RecalcAllWithNeighbours(true)
    sendServerCommand(player, "PK42", "HookUpdated", { status = "Empty" })
end

function PK42ServerLogic.SkinCorpseOnHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    local status = SU.hook_GetStatus(hook)
    if status ~= "Corpse" and status ~= "CorpseBleeded" then return end

    local md = hook:getModData()
    if md.PK42IsSkinned then return end

    giveSkin(player)

    -- Se o cadáver já foi sangrado, vai para SkinnedBleeded; senão Skinned.
    local newStatus = (status == "CorpseBleeded") and "SkinnedBleeded" or "Skinned"
    md.PK42IsSkinned  = true
    md.PK42HookStatus = newStatus
    hook:transmitModData()

    local cfg = getSandboxCFG()
    addXp(player, Perks.Butchering, cfg.BUTCHERING_XP_HOOK)
    gainInsanityXP(player, cfg.INSANITY_XP_HOOK)
    doBloodAndPanic(player, hookSq)

    SU.hook_SwapSprite(hook, newStatus)
    hook:sync()

    --triggerEvent("OnRefreshInventoryWindowContainers", player)
    sendServerCommand(player, "PK42", "HookUpdated", { status = newStatus })
end

function PK42ServerLogic.ButcherCorpseOnHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    local status = SU.hook_GetStatus(hook)
    if status ~= "Corpse" and status ~= "Skinned"
    and status ~= "CorpseBleeded" and status ~= "SkinnedBleeded" then return end

    local md     = hook:getModData()
    local defKey = md.PK42IsPlayerCorpse and "PKhuman" or "PKzombie"

    local def    = ButcheringUtil.getAnimalDef(defKey)

    local carcassProxy = {
        _md = {
            meatRatio      = md.PK42MeatRatio or 1.0,
            deathAge       = md.PK42DeathAge  or 0,
            animalRotStage = md.PK42RotStage  or 0,
            roadKill       = false,
        },
        getAnimalSize  = function(self) return 1.0 end,
        getModData     = function(self) return self._md end,
        getCarcassName = function(self) return defKey end,
    }

    totalHunger   = 0
    totalLipids   = 0
    totalProteins = 0
    totalCarbo    = 0
    totalCalories = 0

    if def and def.parts then
        for _, part in pairs(def.parts) do
            ButcheringUtil.addAnimalPart(part, player, carcassProxy, false)
        end
    end

    md.PK42HookStatus = "Skeleton"
    hook:transmitModData()

    SU.hook_SwapSprite(hook, "Skeleton")
    hook:sync()

    --triggerEvent("OnRefreshInventoryWindowContainers", player)
    sendServerCommand(player, "PK42", "HookUpdated", { status = "Skeleton" })
end

function PK42ServerLogic.CollectBonesOnHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    if SU.hook_GetStatus(hook) ~= "Skeleton" then return end

    local md       = hook:getModData()
    local isZombie = md.PK42IsZombie == true
    local boneList = isZombie and PK42.ZombieBones or PK42.HumanBones

    --if isZombie then tryGiveZombieLeather(player) end
    giveBones(player, boneList, 2, 6) -- coleta no gancho é mais "produtiva" que no chão, então aumenta a quantidade

    local maxInsanityXp = getSandboxCFG().INSANITY_XP_HOOK / 3
    gainInsanityXP(player, maxInsanityXp)
    doBloodAndPanic(player, hookSq)

    -- Limpa ModData via helper compartilhado
    hook_ClearModData(hook)

    SU.hook_SwapSprite(hook, "Empty")
    hook:sync()

    --triggerEvent("OnRefreshInventoryWindowContainers", player)
    sendServerCommand(player, "PK42", "CollectBonesFeedback", { success = true })
end

function PK42ServerLogic.AcquireTrait(player, args)
    if not player or not args or not args.trait then return end
    if not SU.hasPsychopathTrait(player)  then return end
    if SU.hasCannibalistTrait(player)     then return end

    if args.trait == "pk42:cannibalist" then
        if player:getPerkLevel(Perks.Insanity) < getSandboxCFG().CANNIBAL_UNLOCK_LEVEL then return end
    end

    player:getCharacterTraits():add(PK42.CharacterTrait.CANNIBALIST)
    syncPlayerStats(player, 0x00000100)
    sendServerCommand(player, "PK42", "TraitAcquired", { trait = args.trait })
end

function PK42ServerLogic.BleedCorpseOnHook(player, args)
    if not player or not args then return end
    local cell = getCell(); if not cell then return end

    local hookSq = cell:getGridSquare(args.hookX, args.hookY, args.hookZ)
    if not hookSq then return end

    local hook = getHookFromSquare(hookSq)
    if not hook then return end

    local status = SU.hook_GetStatus(hook)
    if status ~= "Corpse" and status ~= "Skinned" then return end

    local md = hook:getModData()
    local newStatus = (status == "Corpse") and "CorpseBleeded" or "SkinnedBleeded"
    md.PK42BloodQty   = 0
    md.PK42HookStatus = newStatus
    hook:transmitModData()
    SU.hook_SwapSprite(hook, newStatus)
    hook:sync()

    for i = 1, ZombRand(10, 20) do
        addBloodSplat(hookSq, ZombRand(2, 5),
            0.5 + ZombRandFloat(-0.08, 0.08),
            1.0 + ZombRandFloat(-0.08, 0.08))
    end

    gainInsanityXP(player, getSandboxCFG().INSANITY_XP_HOOK)
    doBloodAndPanic(player, hookSq)
    sendServerCommand(player, "PK42", "HookUpdated", { status = newStatus })
end

-- Dispatcher
local function onClientCommand(module, command, player, args)
    if module ~= "PK42" then return end

    if     command == "ButcherCorpse"        then PK42ServerLogic.ButcherCorpse(player, args)
    elseif command == "SkinCorpse"           then PK42ServerLogic.SkinCorpse(player, args)
    elseif command == "CollectBones"         then PK42ServerLogic.CollectBones(player, args)
    elseif command == "PutCorpseOnHook"      then PK42ServerLogic.PutCorpseOnHook(player, args)
    elseif command == "RemoveCorpseFromHook" then PK42ServerLogic.RemoveCorpseFromHook(player, args)
    elseif command == "SkinCorpseOnHook"     then PK42ServerLogic.SkinCorpseOnHook(player, args)
    elseif command == "ButcherCorpseOnHook"  then PK42ServerLogic.ButcherCorpseOnHook(player, args)
    elseif command == "CollectBonesOnHook"   then PK42ServerLogic.CollectBonesOnHook(player, args)
    elseif command == "BleedCorpseOnHook"    then PK42ServerLogic.BleedCorpseOnHook(player, args)
    elseif command == "AcquireTrait"         then PK42ServerLogic.AcquireTrait(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)