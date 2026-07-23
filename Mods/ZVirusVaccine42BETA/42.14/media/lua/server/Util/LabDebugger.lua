-- FILE USED FOR DEBUG PURPOSES. CODES HERE AREN'T RELEASED FOR PUBLIC.

-- PK42AudioDebugger.lua (Client)
-- Menu de contexto no LabItems.LabDebugger para testar métodos de áudio.
-- Testa: playSoundLocal, getEmitter:playSound, addSound, playSound (global)
-- e combinações usadas no PK42Hallucinations.lua
--
-- Legenda esperada nos testes:
--   playSoundLocal     → só o dono ouve, NÃO atrai zumbis
--   getEmitter:playSound → outros jogadores próximos PODEM ouvir, NÃO atrai zumbis por si só
--   addSound           → atrai zumbis (radius), outros jogadores NÃO ouvem o som em si
--   getEmitter + addSound → outros ouvem + zumbis atraídos (usado em LAUGH/SCREAM)

-- ── Sons de teste ─────────────────────────────────────────────
-- Usa sons que já existem no jogo base para garantir que toca

local TEST_SOUND        = "z_male_C_Attack_01"          -- som de zumbi curto e claro
local TEST_SOUND_LAUGH  = "male_laugh_03"               -- risada (usada no mod)
local TEST_SOUND_SCREAM = "MalePlayer_DeathScreams_03"  -- grito (usado no mod)
local TEST_SOUND_HELI   = "m_heli_hover_loop_close"     -- som ambiente

local RADIUS_SMALL  = 20
local RADIUS_MEDIUM = 30
local RADIUS_LARGE  = 40

-- ── Logger ────────────────────────────────────────────────────

local function LOG(msg)
    print("[PK42|AudioDebug] " .. tostring(msg))
end

-- ── Helpers ───────────────────────────────────────────────────

local function getLocalPlayer()
    return getSpecificPlayer(0)
end

local function getTestSound()
    return TEST_SOUND
end

-- ── Métodos de teste ──────────────────────────────────────────

-- 1. playSoundLocal
-- Esperado: só o dono ouve | NÃO atrai zumbis | outros jogadores NÃO ouvem
local function testPlaySoundLocal()
    local player = getLocalPlayer()
    if not player then return end
    local sound = getTestSound()
    player:playSoundLocal(sound)
    LOG("playSoundLocal(\"" .. sound .. "\")")
    LOG("  → Só VOCÊ ouve | NÃO atrai zumbis | outros jogadores NÃO ouvem")
end

-- 2. getEmitter():playSound
-- Esperado: outros jogadores próximos PODEM ouvir | NÃO atrai zumbis por si só
local function testEmitterPlaySound()
    local player = getLocalPlayer()
    if not player then return end
    local sound = getTestSound()
    player:getEmitter():playSound(sound)
    LOG("getEmitter():playSound(\"" .. sound .. "\")")
    LOG("  → Você e outros próximos OUVEM | NÃO atrai zumbis sozinho")
end

-- 3. addSound apenas (sem tocar som)
-- Esperado: NÃO toca som audível | ATRAI zumbis no raio
local function testAddSoundOnly()
    local player = getLocalPlayer()
    if not player then return end
    addSound(player, player:getX(), player:getY(), player:getZ(), RADIUS_MEDIUM, RADIUS_MEDIUM)
    LOG("addSound(radius=" .. RADIUS_MEDIUM .. ") — SEM som audível")
    LOG("  → Silencioso para jogadores | ATRAI zumbis no raio=" .. RADIUS_MEDIUM)
end

-- 4. getEmitter + addSound (padrão LAUGH do mod)
-- Esperado: outros ouvem + zumbis atraídos
local function testEmitterPlusAddSound()
    local player = getLocalPlayer()
    if not player then return end
    local sound  = TEST_SOUND_LAUGH
    local radius = RADIUS_MEDIUM
    player:getEmitter():playSound(sound)
    addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
    LOG("getEmitter():playSound(\"" .. sound .. "\") + addSound(radius=" .. radius .. ")")
    LOG("  → [LAUGH pattern] Você e outros OUVEM | ATRAI zumbis raio=" .. radius)
end

-- 5. getEmitter + addSound large (padrão SCREAM do mod)
local function testEmitterPlusAddSoundLarge()
    local player = getLocalPlayer()
    if not player then return end
    local sound  = TEST_SOUND_SCREAM
    local radius = RADIUS_LARGE
    player:getEmitter():playSound(sound)
    addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
    LOG("getEmitter():playSound(\"" .. sound .. "\") + addSound(radius=" .. radius .. ")")
    LOG("  → [SCREAM pattern] Você e outros OUVEM | ATRAI zumbis raio=" .. radius)
end

-- 6. playSoundLocal com som de ambiente (padrão HALLUCINATION do mod)
local function testHallucinationPattern()
    local player = getLocalPlayer()
    if not player then return end
    local sound = TEST_SOUND
    player:playSoundLocal(sound)
    LOG("playSoundLocal(\"" .. sound .. "\") — padrão alucinação")
    LOG("  → [HALLUCINATION pattern] Só VOCÊ ouve | NÃO atrai zumbis | outros NÃO ouvem")
end

-- 7. playSoundLocal com heli
local function testHeliSoundLocal()
    local player = getLocalPlayer()
    if not player then return end
    player:playSoundLocal(TEST_SOUND_HELI)
    LOG("playSoundLocal(\"" .. TEST_SOUND_HELI .. "\")")
    LOG("  → Só VOCÊ ouve | NÃO atrai zumbis")
end

-- 8. addSound com raio pequeno
local function testAddSoundSmall()
    local player = getLocalPlayer()
    if not player then return end
    addSound(player, player:getX(), player:getY(), player:getZ(), RADIUS_SMALL, RADIUS_SMALL)
    LOG("addSound(radius=" .. RADIUS_SMALL .. ") indoor")
    LOG("  → Silencioso | ATRAI zumbis raio=" .. RADIUS_SMALL)
end

-- 9. addSound com raio grande
local function testAddSoundLarge()
    local player = getLocalPlayer()
    if not player then return end
    addSound(player, player:getX(), player:getY(), player:getZ(), RADIUS_LARGE, RADIUS_LARGE)
    LOG("addSound(radius=" .. RADIUS_LARGE .. ") outdoor")
    LOG("  → Silencioso | ATRAI zumbis raio=" .. RADIUS_LARGE)
end

-- ── Menu de contexto ──────────────────────────────────────────

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    if playerNum ~= 0 then return end

    -- Procura o LabDebugger nos itens selecionados
    local debuggerFound = false
    for _, item in ipairs(items) do
        local realItem = item
        if type(item) == "table" and item.items then
            realItem = item.items[1]
        end
        if realItem and realItem.getFullType and realItem:getFullType() == "LabItems.LabDebugger" then
            debuggerFound = true
            break
        end
    end

    if not debuggerFound then return end

    -- Separador
    context:addOptionOnTop("── PK42 Audio Debug ──", nil, nil)

    -- Submenu principal
    local subMenu = context:getNew(context)
    context:addSubMenu(
        context:addOptionOnTop(getText("PK42 Audio Tester"), nil, nil),
        subMenu
    )

    -- ── Grupo 1: Métodos isolados ──
    subMenu:addOption("1. playSoundLocal  [só você | sem zumbis]",
        nil, testPlaySoundLocal)

    subMenu:addOption("2. getEmitter:playSound  [outros ouvem | sem zumbis]",
        nil, testEmitterPlaySound)

    subMenu:addOption("3. addSound only  [silencioso | atrai zumbis r=" .. RADIUS_MEDIUM .. "]",
        nil, testAddSoundOnly)

    subMenu:addOption("4. addSound small  [silencioso | atrai zumbis r=" .. RADIUS_SMALL .. "]",
        nil, testAddSoundSmall)

    subMenu:addOption("5. addSound large  [silencioso | atrai zumbis r=" .. RADIUS_LARGE .. "]",
        nil, testAddSoundLarge)

    -- ── Grupo 2: Padrões do mod ──
    local subMenu2 = context:getNew(context)
    context:addSubMenu(
        context:addOptionOnTop("PK42 Patterns", nil, nil),
        subMenu2
    )

    subMenu2:addOption("HALLUCINATION pattern  [playSoundLocal | só você | sem zumbis]",
        nil, testHallucinationPattern)

    subMenu2:addOption("HELI pattern  [playSoundLocal | só você | sem zumbis]",
        nil, testHeliSoundLocal)

    subMenu2:addOption("LAUGH pattern  [emitter+addSound | outros ouvem | r=" .. RADIUS_MEDIUM .. "]",
        nil, testEmitterPlusAddSound)

    subMenu2:addOption("SCREAM pattern  [emitter+addSound | outros ouvem | r=" .. RADIUS_LARGE .. "]",
        nil, testEmitterPlusAddSoundLarge)
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)