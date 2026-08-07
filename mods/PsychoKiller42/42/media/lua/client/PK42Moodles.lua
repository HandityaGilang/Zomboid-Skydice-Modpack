-- PK42FrenzyMoodle.lua
-- Moodle visual do Adrenaline Frenzy

if isServer() then return end

local SU = require "Utils/PK42SharedUtils"

local function getSandboxCFG()
    local opts = SandboxVars.PK42
    return {
        FRENZY_MAX_DMG_BONUS       = (opts and opts.FrenzyMaxDamageBonus or 80) / 100, -- bônus máximo de dano em frenzy
    }
end

-- Eventos customizados
if not Events.OnFrenzyStart then
    LuaEventManager.AddEvent("OnFrenzyStart")
end
if not Events.OnFrenzyEnd then
    LuaEventManager.AddEvent("OnFrenzyEnd")
end

-- Constantes
local TEXTURE_SIZES = {32, 48, 64, 80, 96, 128}
local FALLBACK_SIZE  = 32   -- pasta usada se a resolução escolhida não tiver o asset

-- Topo fixo da coluna de moodles vanilla (MoodlesUI, construtor: this.y = 120.0F)
local VANILLA_MOODLES_TOP_Y = 120

-- Ordinal de Moodle.MoodleLevel.HighMoodleLevel (Min=0, Low=1, Moderate=2, High=3, Max=4)
local HIGH_MOODLE_LEVEL = 3

-- Todos os MoodleType nativos que o MoodlesUI pode exibir, na mesma ordem
-- de MoodleType.java. Usado só para CONTAR quantos estão ativos agora e saber onde termina a coluna vanilla
local VANILLA_MOODLE_TYPES = {
    MoodleType.ENDURANCE, MoodleType.TIRED, MoodleType.HUNGRY, MoodleType.PANIC,
    MoodleType.SICK, MoodleType.BORED, MoodleType.UNHAPPY, MoodleType.BLEEDING,
    MoodleType.WET, MoodleType.HAS_A_COLD, MoodleType.ANGRY, MoodleType.STRESS,
    MoodleType.THIRST, MoodleType.INJURED, MoodleType.PAIN, MoodleType.HEAVY_LOAD,
    MoodleType.DRUNK, MoodleType.DEAD, MoodleType.ZOMBIE, MoodleType.HYPERTHERMIA,
    MoodleType.HYPOTHERMIA, MoodleType.WINDCHILL, MoodleType.CANT_SPRINT,
    MoodleType.UNCOMFORTABLE, MoodleType.NOXIOUS_SMELL, MoodleType.FOOD_EATEN,
}

-- ICONS[size][level] = caminho da textura
local ICONS = {}
for _, size in ipairs(TEXTURE_SIZES) do
    ICONS[size] = {
        [1] = "media/ui/Moodles/" .. size .. "/Moodle_PK42_AdrenalineFrenzy_lvl1.png",
        [2] = "media/ui/Moodles/" .. size .. "/Moodle_PK42_AdrenalineFrenzy_lvl2.png",
        [3] = "media/ui/Moodles/" .. size .. "/Moodle_PK42_AdrenalineFrenzy_lvl3.png",
        [4] = "media/ui/Moodles/" .. size .. "/Moodle_PK42_AdrenalineFrenzy_lvl4.png",
    }
end

local TOOLTIP_KEYS = {
    [1] = { title = "Moodles_pk42_adrenalinefrenzy_lvl1", desc = "Moodles_pk42_adrenalinefrenzy_lvl1_desc" },
    [2] = { title = "Moodles_pk42_adrenalinefrenzy_lvl2", desc = "Moodles_pk42_adrenalinefrenzy_lvl2_desc" },
    [3] = { title = "Moodles_pk42_adrenalinefrenzy_lvl3", desc = "Moodles_pk42_adrenalinefrenzy_lvl3_desc" },
    [4] = { title = "Moodles_pk42_adrenalinefrenzy_lvl4", desc = "Moodles_pk42_adrenalinefrenzy_lvl4_desc" },
}

-- Helpers
local function streakToLevel(streak)
    streak = tonumber(streak) or 0
    if streak >= 70 then return 4 end
    if streak >= 40 then return 3 end
    if streak >= 10 then return 2 end
    if streak >= 1  then return 1 end
    return 0
end

local function getStreakBonus(streak)
    local cfg = getSandboxCFG()
    local FRENZY_DMG_BONUS = cfg.FRENZY_MAX_DMG_BONUS / 8
    
    streak = tonumber(streak) or 0
    if streak >= 80 then return FRENZY_DMG_BONUS * 8
    elseif streak >= 70 then return FRENZY_DMG_BONUS * 7
    elseif streak >= 60 then return FRENZY_DMG_BONUS * 6
    elseif streak >= 50 then return FRENZY_DMG_BONUS * 5
    elseif streak >= 40 then return FRENZY_DMG_BONUS * 4
    elseif streak >= 30 then return FRENZY_DMG_BONUS * 3
    elseif streak >= 20 then return FRENZY_DMG_BONUS * 2
    elseif streak >= 10 then return FRENZY_DMG_BONUS
    else return 0.0
    end
end

-- Replica MoodlesUI.getTextureSizeForOption() (zombie/ui/MoodlesUI.java):
-- índices 0-5 = tamanhos fixos (32..128); índice 6 = "Scale with font",
-- que usa o índice da opção de tamanho de fonte no mesmo array.
local function getMoodleIconSize()
    local core = getCore()
    local moodleSizeIndex = core:getOptionMoodleSize() - 1
    if moodleSizeIndex >= 0 and moodleSizeIndex < #TEXTURE_SIZES then
        return TEXTURE_SIZES[moodleSizeIndex + 1]
    elseif moodleSizeIndex == 6 then
        local fontSizeIndex = core:getOptionFontSizeReal() - 1
        if fontSizeIndex >= 0 and fontSizeIndex < #TEXTURE_SIZES then
            return TEXTURE_SIZES[fontSizeIndex + 1]
        end
    end
    return 32
end

-- Busca a textura na resolução alvo; se faltar o asset, cai pra FALLBACK_SIZE
local function getFrenzyIcon(size, level)
    local iconSet = ICONS[size]
    local icon = iconSet and getTexture(iconSet[level])
    if not icon and size ~= FALLBACK_SIZE then
        local fallbackSet = ICONS[FALLBACK_SIZE]
        icon = fallbackSet and getTexture(fallbackSet[level])
    end
    return icon
end

-- Conta quantos moodles vanilla estão visíveis agora, replicando o filtro
-- de MoodlesUI.update(): qualquer tipo com level > 0 conta, EXCETO
-- FOOD_EATEN, que só conta a partir de HighMoodleLevel (ordinal 3).
local function countActiveVanillaMoodles(player)
    local moodles = player:getMoodles()
    if not moodles then return 0 end

    local count = 0
    for _, moodleType in ipairs(VANILLA_MOODLE_TYPES) do
        local level = moodles:getMoodleLevel(moodleType)
        if moodleType == MoodleType.FOOD_EATEN then
            if level >= HIGH_MOODLE_LEVEL then
                count = count + 1
            end
        elseif level > 0 then
            count = count + 1
        end
    end
    return count
end

-- Y onde a coluna vanilla termina (= onde nosso moodle deve começar).
-- MoodlesUI.java linha 324: moodleDistY = 10 + this.width (this.width = tamanho do ícone)
-- MoodlesUI.java linha 362: slotsDesiredPos = moodleDistY * currentSlotPlace
-- Slot 0 = primeiro moodle em y=120, slot N = y = 120 + N*(10+size)
local function getVanillaMoodlesBottomY(player, iconSize)
    local moodleDistY = 10 + iconSize
    local activeCount = countActiveVanillaMoodles(player)
    return VANILLA_MOODLES_TOP_Y + (activeCount * moodleDistY)
end

-- Fábrica de ISUIElement por nível
local function newFrenzyMoodle(source, level)
    local WIGGLE_MAX_CYCLES = 2   -- ciclos completos antes de parar

    local wiggle, wiggleX, wiggleBidirectional, wiggleDegradation = 0, 0, false, 0
    local enableWiggle  = false
    local hasWiggled    = false
    local wiggleFrame   = 0   -- contador de frames para controlar a velocidade

    local ISMoodle = ISUIElement:derive("PK42FrenzyMoodle_lvl" .. level)

    ISMoodle.initialise = function(self)
        ISUIElement.initialise(self)
    end

    ISMoodle.renderImpl = function(self)
        -- Recalcula tamanho/posição todo frame: tanto a opção de Moodle Size quanto o número de moodles vanilla ativos mudam em runtime
        local size = getMoodleIconSize()
        local scaleRatio = size / 48   -- 48 = referência original do wiggle em px

        self:setWidth(size)
        self:setHeight(size + 18)  -- folga extra pra área de hit-test do tooltip

        -- ========================
        -- TUNING DO WIGGLE
        -- ========================
        local wiggleMax       = 14 * scaleRatio  -- amplitude lateral em px (maior = balanço mais largo)
        local wiggleStep      = 3  * scaleRatio  -- passo por frame ATIVO (menor = movimento mais suave)
        local wiggleFrameSkip = 3                -- avança o wiggle 1x a cada N frames (maior = mais lento)
        ---------------------------

        local frenzyActive = SU.IsFrenzyActive(source)
        local streak        = SU.GetStreak(source) or 0
        local activeLevel   = frenzyActive and streakToLevel(streak) or 0

        -- X: ancora em screenWidth-10 e cresce para a esquerda, igual MoodlesUI.java linha 55:
        -- this.x = Core.getInstance().getScreenWidth() - 10
        -- dx = this.x - textureWidth → logo: x = screenWidth - 10 - size
        local x = getCore():getScreenWidth() - 10 - size
        local y = getVanillaMoodlesBottomY(source, size)
        self:setX(x)
        self:setY(y)

        -- Nível inativo: garante wiggleX=0 e reseta estado
        if activeLevel ~= level then
            enableWiggle      = false
            hasWiggled        = false
            wiggle            = 0
            wiggleX           = 0
            wiggleDegradation = 0
            wiggleFrame       = 0
            return
        end

        -- Dispara wiggle uma única vez ao ativar
        if not hasWiggled then
            hasWiggled          = true
            enableWiggle        = true
            wiggle              = 0
            wiggleX             = 0
            wiggleDegradation   = 0
            wiggleFrame         = 0
            wiggleBidirectional = ZombRand(2) == 0
        end

        -- Animação de wiggle com frame skip para controlar a velocidade
        if enableWiggle then
            wiggleFrame = wiggleFrame + 1
            if wiggleFrame >= wiggleFrameSkip then  -- só move a cada wiggleFrameSkip frames
                wiggleFrame = 0
                if wiggleBidirectional then
                    wiggle = wiggle - wiggleStep
                    if wiggle <= -wiggleMax then
                        wiggleBidirectional = false
                        wiggleDegradation   = wiggleDegradation + 1
                    end
                else
                    wiggle = wiggle + wiggleStep
                    if wiggle >= wiggleMax then
                        wiggleBidirectional = true
                        wiggleDegradation   = wiggleDegradation + 1
                    end
                end
            end

            wiggleX = wiggle * math.sin(0.5)

            -- Para após WIGGLE_MAX_CYCLES ciclos e garante retorno ao centro
            if wiggleDegradation > WIGGLE_MAX_CYCLES then
                enableWiggle = false
                wiggle       = 0
                wiggleX      = 0
                wiggleFrame  = 0
            end
        end

        -- Desenha ícone (na resolução nativa da pasta correspondente, sem escalar)
        local icon = getFrenzyIcon(size, level)
        if icon then
            self:drawTexture(icon, wiggleX, 0, 1, 1, 1, 1)
        end

        -- Tooltip
        if self:isMouseOver() then
            local bonus = getStreakBonus(streak)
            local title = getText(TOOLTIP_KEYS[level].title)
            local desc1 = getText(TOOLTIP_KEYS[level].desc)
            local desc2 = string.format("Streak: %d kills | Bonus: +%d%%", streak, math.floor(bonus * 100 + 0.5))

            local titleLen = getTextManager():MeasureStringX(UIFont.Small, title) + 7
            local desc1Len = getTextManager():MeasureStringX(UIFont.Small, desc1) + 7
            local desc2Len = getTextManager():MeasureStringX(UIFont.Small, desc2) + 7
            local boxW     = math.max(titleLen, desc1Len, desc2Len) + 5
            local boxH     = 44

            self:drawRect(-4 - boxW, 0, boxW, boxH, 0.6, 0, 0, 0)
            self:drawTextRight(title, -10, 2,  1, 1, 1, 1.0)
            self:drawTextRight(desc1, -10, 15, 1, 1, 1, 0.7)
            self:drawTextRight(desc2, -10, 28, 1, 1, 1, 0.7)
        end

        self:bringToTop()
    end

    ISMoodle.render = function(self)
        local ok, err = pcall(ISMoodle.renderImpl, self)
        if not ok then
            print("[PK42FrenzyMoodle lvl" .. level .. "] " .. tostring(err))
        end
    end

    ISMoodle.new = function(self, x, y, w, h)
        local o = ISUIElement:new(x, y, w, h)
        setmetatable(o, self)
        self.__index = self
        o.borderColor     = { r=0, g=0, b=0, a=0 }
        o.backgroundColor = { r=0, g=0, b=0, a=0 }
        return o
    end

    local initSize = getMoodleIconSize()
    local x = getCore():getScreenWidth() - 10 - initSize
    local y = getVanillaMoodlesBottomY(source, initSize)
    return ISMoodle:new(x, y, initSize, initSize + 18)
end

-- Gestão de instâncias
local instances = {}

local function removeInstances(playerNum)
    if instances[playerNum] then
        for lvl = 1, 4 do
            if instances[playerNum][lvl] then
                instances[playerNum][lvl]:removeFromUIManager()
            end
        end
        instances[playerNum] = nil
    end
end

local function createInstances(source)
    local num = source:getPlayerNum() or 0
    removeInstances(num)
    instances[num] = {}
    for lvl = 1, 4 do
        local moodle = newFrenzyMoodle(source, lvl)
        moodle:addToUIManager()
        instances[num][lvl] = moodle
    end
end

-- Eventos
local function onGameStart()
    local player = getPlayer()
    if player then createInstances(player) end
end

local function onCreatePlayer(index, player)
    createInstances(player)
end

local function onPlayerDeath(player)
    local num = player:getPlayerNum() or 0
    removeInstances(num)
end

Events.OnGameStart.Add(onGameStart)
Events.OnLoad.Add(onGameStart)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)