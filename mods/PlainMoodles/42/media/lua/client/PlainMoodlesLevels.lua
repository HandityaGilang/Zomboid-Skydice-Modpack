-- PlainMoodles: moodle stack with level indicators for Build 42
-- Build 42 draws moodle backgrounds from a single texture per style, so the
-- original per-level plates (Moodle_Bkg_Bad_1..4 / Moodle_Bkg_Good_1..4) can no
-- longer be supplied as textures. Vanilla also keeps its slot state in a
-- HashMap<MoodleType, MoodleUIData> and MoodleType has no hashCode override, so
-- the vanilla slot order changes from session to session and a level mark drawn
-- on top of the vanilla stack could end up on the wrong moodle. This script
-- hides the local player's vanilla moodle panel and draws the whole stack
-- itself in a fixed order: plate, border, moodle icon, coloured level mark.

PlainMoodlesLevels = PlainMoodlesLevels or {}
local PML = PlainMoodlesLevels

PML.sizes = { 32, 48, 64, 80, 96, 128 }
PML.margin = 10          -- vertical gap between moodles used by MoodlesUI
PML.goodId = 1           -- value of getGoodBadNeutral() that means "good"
PML.alpha = 1.0
PML.cache = {}
PML.debug = false         -- дамп геометрии панели мудлов в лог, включать только для отладки
PML.debugDone = false
PML.errorLogged = false
PML.diagLogged = {}
PML.testMode = false      -- тестовая стопка всех типов, переключается F10 в отладочной игре
PML.testLogged = false
PML.sawPlayer = false
PML.geomLogged = false
PML.offscreenY = -20000   -- куда уводится ванильная панель (UIElement не рисует при y + height < 0)
PML.baseX = nil
PML.baseY = nil
PML.tooltip = true        -- своя подпись мудла под курсором (ванильные подсказки ушли вместе с панелью)
PML.tooltipPad = 6
PML.tooltipFont = nil
PML.tintPlate = true      -- красить подложку по уровню мудла, как это делает ваниль
PML.ctx = nil             -- невидимый UIElement: цветная отрисовка есть только у него
PML.ctxW = nil
PML.ctxH = nil
PML.grey = 0.5            -- Color.gray: база подложки в MoodlesUI.update()
-- Имена для ключей переводов: MoodleType:getTranslationName() отдаёт ровно эти строки
-- (Endurance, HasACold, HeavyLoad, CantSprint...), таблица нужна как страховка.
PML.transNames = {
    ENDURANCE = "Endurance", TIRED = "Tired", HUNGRY = "Hungry", THIRST = "Thirst",
    PANIC = "Panic", SICK = "Sick", BORED = "Bored", UNHAPPY = "Unhappy",
    BLEEDING = "Bleeding", WET = "Wet", HAS_A_COLD = "HasACold", ANGRY = "Angry",
    STRESS = "Stress", INJURED = "Injured", PAIN = "Pain", HEAVY_LOAD = "HeavyLoad",
    DRUNK = "Drunk", DEAD = "Dead", ZOMBIE = "Zombie", HYPERTHERMIA = "Hyperthermia",
    HYPOTHERMIA = "Hypothermia", WINDCHILL = "Windchill", CANT_SPRINT = "CantSprint",
    UNCOMFORTABLE = "Uncomfortable", NOXIOUS_SMELL = "NoxiousSmell", FOOD_EATEN = "FoodEaten",
}

-- Одноразовое сообщение о причине, по которой оверлей уровней не рисуется.
function PML.diag(key, msg)
    if PML.diagLogged[key] then return end
    PML.diagLogged[key] = true
    print("PlainMoodles DIAG: " .. tostring(msg))
end

-- Тестовый режим доступен только при запуске игры с -debug или при PML.debug.
function PML.debugEnabled()
    if PML.debug then return true end
    local ok, res = pcall(function() return getDebug() end)
    return ok and res == true
end

-- Build 42 turned MoodleType into a registry-backed script object, so the old
-- MoodleType.ToIndex / FromIndex / MAX helpers no longer exist. The moodle stack
-- is walked over an explicit ordered list instead, and missing entries are
-- skipped so added or removed types in future builds cannot break the overlay.
PML.typeNames = {
    "ENDURANCE", "TIRED", "HUNGRY", "THIRST", "PANIC", "SICK", "BORED",
    "UNHAPPY", "BLEEDING", "WET", "HAS_A_COLD", "ANGRY", "STRESS",
    "INJURED", "PAIN", "HEAVY_LOAD", "DRUNK", "DEAD", "ZOMBIE",
    "HYPERTHERMIA", "HYPOTHERMIA", "WINDCHILL", "CANT_SPRINT",
    "UNCOMFORTABLE", "NOXIOUS_SMELL", "FOOD_EATEN",
}

-- Соответствие MoodleType -> имя файла иконки, снято из константного пула
-- zombie.ui.MoodleTextureSet (B42.20): media/ui/Moodles/<size>/<файл>.png. Эти же
-- файлы мод перекрывает своей графикой. FOOD_EATEN в ваниле использует ту же
-- иконку, что и HUNGRY.
PML.icons = {
    ENDURANCE = "Status_DifficultyBreathing",
    TIRED = "Mood_Sleepy",
    HUNGRY = "Status_Hunger",
    THIRST = "Status_Thirst",
    PANIC = "Mood_Panicked",
    SICK = "Mood_Nauseous",
    BORED = "Mood_Bored",
    UNHAPPY = "Mood_Sad",
    BLEEDING = "Status_Bleeding",
    WET = "Status_Wet",
    HAS_A_COLD = "Mood_Ill",
    ANGRY = "Mood_Angry",
    STRESS = "Mood_Stressed",
    INJURED = "Status_InjuredMinor",
    PAIN = "Mood_Pained",
    HEAVY_LOAD = "Status_HeavyLoad",
    DRUNK = "Mood_Drunk",
    DEAD = "Mood_Dead",
    ZOMBIE = "Mood_Zombified",
    HYPERTHERMIA = "Status_TemperatureHot",
    HYPOTHERMIA = "Status_TemperatureLow",
    WINDCHILL = "Status_Windchill",
    CANT_SPRINT = "Status_MovementRestricted",
    UNCOMFORTABLE = "Mood_Discomfort",
    NOXIOUS_SMELL = "Mood_NoxiousSmell",
    FOOD_EATEN = "Status_Hunger",
}

function PML.getTypes()
    if PML.types ~= nil then return PML.types end
    local list = {}
    local icons = {}
    if MoodleType ~= nil then
        for i = 1, #PML.typeNames do
            local t = MoodleType[PML.typeNames[i]]
            if t ~= nil then
                list[#list + 1] = t
                icons[#list] = PML.icons[PML.typeNames[i]]
            end
        end
    end
    PML.types = list
    PML.typeIcons = icons
    return list
end

-- Подложка, рамка и иконки мудлов лежат в media/ui/Moodles/<size>/ — мод
-- перекрывает эти файлы своей графикой, поэтому стопку можно рисовать самим.
function PML.getUiTexture(size, name)
    local key = "ui:" .. tostring(size) .. ":" .. tostring(name)
    local tex = PML.cache[key]
    if tex == nil then
        tex = getTexture(string.format("media/ui/Moodles/%d/%s.png", size, name))
        if tex == nil then tex = false end
        PML.cache[key] = tex
    end
    if tex == false then return nil end
    return tex
end

function PML.drawUiTexture(size, name, x, y, drawSize)
    local tex = PML.getUiTexture(size, name)
    if tex == nil then return false end
    UIManager.DrawTexture(tex, x, y, drawSize, drawSize, PML.alpha)
    return true
end

-- Ваниль красит подложку сама: MoodlesUI.update() берёт Color.gray и подмешивает
-- к нему getGoodHighlitedColor() / getBadHighlitedColor() в доле level/4, а рисует
-- подложку через DrawTextureCol. Статический UIManager.DrawTexture цвет не
-- принимает, цветные варианты есть только у UIElement, поэтому держим свой
-- невидимый элемент в координатах экрана (0,0) и рисуем подложку через него.
function PML.getDrawCtx()
    if not PML.tintPlate then return nil end
    local w, h = 1920, 1080
    pcall(function() w = getCore():getScreenWidth(); h = getCore():getScreenHeight() end)
    if PML.ctx ~= nil and (PML.ctxW ~= w or PML.ctxH ~= h) then
        pcall(function() PML.ctx:setWidth(w); PML.ctx:setHeight(h) end)
        PML.ctxW, PML.ctxH = w, h
    end
    if PML.ctx == nil then
        local ok = pcall(function()
            local ctx = ISUIElement:new(0, 0, w, h)
            ctx:initialise()
            ctx:instantiate()
            -- DrawTextureScaledCol ничего не рисует у невидимого элемента.
            ctx:setVisible(true)
            PML.ctx = ctx
        end)
        if not ok or PML.ctx == nil then
            PML.ctx = nil
            PML.tintPlate = false
            PML.diag("noctx", "cannot create the draw context, moodle plates stay grey")
            return nil
        end
        PML.ctxW, PML.ctxH = w, h
    end
    return PML.ctx
end

-- Палитра уровней для подложки. Ровно те же RGB, что в полосках уровней мода
-- (media/ui/PlainMoodles/<size>/bad_N.png и good_N.png): bad 1-4 жёлтый ->
-- оранжевый -> красный, good 1-4 оттенки зелёного, как в оригинальном Plain Moodles.
PML.plateBad = { {1.00, 0.80, 0.00}, {1.00, 0.53, 0.00}, {1.00, 0.33, 0.00}, {1.00, 0.00, 0.00} }
PML.plateGood = { {0.61, 1.00, 0.10}, {0.56, 1.00, 0.09}, {0.49, 1.00, 0.04}, {0.40, 1.00, 0.00} }

function PML.getPlateColour(gbn, level)
    local g = PML.grey
    if gbn == nil or gbn == 0 or level == nil then return g, g, g end
    -- Раньше цвет брался из getGoodHighlitedColor() / getBadHighlitedColor().
    -- Эти цвета игрок настраивает в опциях игры, поэтому подложка красилась в
    -- произвольный оттенок и связь с уровнем читалась плохо: жалобы "с каждым
    -- уровнем менял цвет, а сейчас будто рандом" и "i can barely see the color
    -- change". Теперь берём свою палитру уровней и заметный шаг по уровню.
    local lvl = level
    if lvl < 1 then return g, g, g end
    if lvl > 4 then lvl = 4 end
    local set = PML.plateBad
    if gbn == PML.goodId then set = PML.plateGood end
    local c = set[lvl]
    if c == nil then return g, g, g end
    local f = 0.4 + 0.2 * (lvl - 1)
    return g + (c[1] - g) * f, g + (c[2] - g) * f, g + (c[3] - g) * f
end

-- Подложка мудла: с цветом уровня, если контекст доступен, иначе как раньше.
function PML.drawPlate(size, x, y, drawSize, gbn, level)
    local tex = PML.getUiTexture(size, "_Moodles_BGsolid")
    if tex == nil then return false end
    local ctx = nil
    if PML.opt("tint", true) ~= false then ctx = PML.getDrawCtx() end
    if ctx ~= nil then
        local r, g, b = PML.getPlateColour(gbn, level)
        local ok = pcall(function() ctx:drawTextureScaledStatic(tex, x, y, drawSize, drawSize, PML.alpha, r, g, b) end)
        if ok then return true end
        PML.tintPlate = false
        PML.diag("nodrawcol", "coloured draw failed, moodle plates stay grey")
    end
    UIManager.DrawTexture(tex, x, y, drawSize, drawSize, PML.alpha)
    return true
end

-- Свою стопку рисуем только если графика мода на месте, иначе оставляем ваниль.
function PML.canOwnRender(setSize)
    if PML.getUiTexture(setSize, "_Moodles_BGsolid") == nil then return false end
    if PML.getTexture(setSize, false, 1) == nil then return false end
    return true
end

-- ВАЖНО: флаг видимости у ванильной панели мудлов трогать нельзя. Хотбар прячется
-- при езде за рулём (ISHotbar:update, ISHotbar.lua:232-234), а вернуться на экран
-- может только по проверке moodleUI:isVisible() (там же, :226-230). Пока мы снимали
-- видимость панели, после выхода из машины хотбар больше не появлялся до
-- перезагрузки мира - именно на это жаловались игроки. Поэтому панель прячем только
-- координатой, а видимость, наоборот, держим включённой: ванильный хотбар тогда
-- восстанавливается сам, в том числе в уже испорченной сессии.
local function moveOffscreen(panel)
    pcall(function() if not panel:isVisible() then panel:setVisible(true) end end)
    local ok = pcall(function() panel:setY(PML.offscreenY) end)
    if not ok then return false end
    -- Координату читаем обратно: если движок вернул панель на место, свою стопку
    -- рисовать нельзя, иначе полоски уровней лягут на ванильные подложки.
    local py = nil
    pcall(function() py = panel:getAbsoluteY() end)
    if type(py) == "number" and py > -1000 then return false end
    return true
end

-- В MP среди UIManager.MoodleUI[0..3] попадается вторая панель с теми же
-- координатами, что у панели локального игрока (в логе n=0 и n=1 обе 1846,120).
-- Если увести за экран только свою, вторая продолжает рисовать ванильную стопку
-- в том же месте, и наши полоски уровней ложатся на чужие подложки: игроки
-- видели это как "the bars on the moodles get swapped". Панели сплитскрина
-- стоят по другим координатам и не трогаются.
function PML.hideVanilla(ui, baseX, baseY)
    -- Ванильную стопку убираем только координатой: снятый флаг видимости её всё равно
    -- не прячет (в B42 панель рисуется независимо от флага), зато ломает возврат
    -- хотбара после езды. Панель уводится за верхний край экрана:
    -- UIElement.DrawTexture пропускает отрисовку при y + h < 0.
    local ok = moveOffscreen(ui)
    -- Уведённые панели запоминаем, чтобы PML.restoreVanilla вернула их на место.
    PML.hiddenPanels = { ui }
    PML.dupPanels = 0
    if UIManager ~= nil and type(baseX) == "number" and type(baseY) == "number" then
        for n = 0, 3 do
            local p = nil
            pcall(function() p = UIManager.getMoodleUI(n) end)
            if p ~= nil and p ~= ui then
                local px, py = nil, nil
                pcall(function() px = p:getAbsoluteX(); py = p:getAbsoluteY() end)
                if px == baseX and (py == baseY or (type(py) == "number" and py < -1000)) then
                    PML.dupPanels = PML.dupPanels + 1
                    PML.hiddenPanels[#PML.hiddenPanels + 1] = p
                    if not moveOffscreen(p) then ok = false end
                end
            end
        end
    end
    if PML.dupPanels > 0 then
        PML.diag("duppanel", "duplicate vanilla moodle panel at the same coordinates moved offscreen: " .. tostring(PML.dupPanels))
    end
    PML.hideOk = ok
    PML.hidden = true
    return ok
end

-- Возврат ванильной стопки на место. Пока мод рисует свою стопку, ванильная панель
-- стоит на y = PML.offscreenY, и раньше её никто не возвращал: стоило снять галочку
-- своей стопки или уйти в меню ESC - и мудлов не было видно совсем до перезагрузки
-- мира (жалоба "all moodle icons disappear completely"). Возвращаем только те панели,
-- которые уводили сами, и только пока помним исходный Y.
function PML.restoreVanilla()
    if not PML.hidden then return end
    local y = PML.baseY
    if type(y) ~= "number" then return end
    local panels = PML.hiddenPanels or {}
    for i = 1, #panels do
        local p = panels[i]
        pcall(function()
            if not p:isVisible() then p:setVisible(true) end
            p:setY(y)
        end)
    end
    PML.hiddenPanels = {}
    PML.hidden = false
    PML.hideOk = nil
end

-- Меню ESC (MainScreen) рисуется поверх игрового интерфейса, но наши статические
-- вызовы UIManager.DrawTexture идут из OnPostUIDraw, и меню их не перекрывало:
-- игрок видел полоски уровней поверх паузы. Признаки видимости меню взяты из
-- ванильных ISPostDeathUI.lua и SpeedControlsHandler.lua.
function PML.isMenuOpen()
    local open = false
    pcall(function()
        local ms = MainScreen ~= nil and MainScreen.instance or nil
        if ms == nil then return end
        if ms.isReallyVisible ~= nil then
            open = ms:isReallyVisible() == true
        elseif ms.getIsVisible ~= nil then
            open = ms:getIsVisible() == true
        end
    end)
    -- Карта (ISWorldMap) рисуется во весь экран поверх интерфейса, но наши
    -- статические UIManager.DrawTexture идут из OnPostUIDraw, поэтому мудлы
    -- оставались поверх карты (жалоба "moodle icons are still showing up with
    -- the map open"). Признак видимости карты взят из ванильных ISChat.lua:229
    -- и ISZoneDisplay.lua:604 - глобальный ISWorldMap_instance.
    if not open then
        pcall(function()
            local map = ISWorldMap_instance
            if map == nil and ISWorldMap ~= nil then map = ISWorldMap.instance end
            if map ~= nil and map.isVisible ~= nil and map:isVisible() == true then open = true end
        end)
    end
    return open
end

local function texturePath(size, isGood, level)
    return string.format("media/ui/PlainMoodles/%d/%s_%d.png", size, isGood and "good" or "bad", level)
end

function PML.getTexture(size, isGood, level)
    local key = tostring(size) .. (isGood and "g" or "b") .. tostring(level)
    local tex = PML.cache[key]
    if tex == nil then
        tex = getTexture(texturePath(size, isGood, level))
        if tex == nil then tex = false end
        PML.cache[key] = tex
    end
    if tex == false then return nil end
    return tex
end

function PML.pickSet(px)
    local best, bestDist = PML.sizes[1], 1000000
    for i = 1, #PML.sizes do
        local d = math.abs(PML.sizes[i] - px)
        if d < bestDist then bestDist = d; best = PML.sizes[i] end
    end
    return best
end

function PML.getDrawSize(ui)
    local w = ui:getWidth()
    if w ~= nil and w >= 16 then return w end
    local opt = getCore():getOptionMoodleSize()
    if opt ~= nil and opt >= 1 and opt <= 6 then return opt * 16 + 16 end
    return 48
end

-- В MP локального игрока надо брать через getPlayer(); getSpecificPlayer(0)
-- остаётся вторым вариантом для SP и сплитскрина.
function PML.getLocalPlayer()
    local p = nil
    if type(getPlayer) == "function" then p = getPlayer() end
    if p == nil and type(getSpecificPlayer) == "function" then p = getSpecificPlayer(0) end
    return p
end

-- Панелей мудлов в движке четыре: UIManager.MoodleUI[0..3], по одной на слот
-- сплитскрина. MoodlesUI.getInstance() отдаёт последнюю созданную, то есть
-- панель четвёртого игрока: X у неё такой же, как у игрока 0, а Y выставлен в
-- UIManager.resize() как screenHeight/2 + отступ часов (в логе это 520), из-за
-- чего шкалы уезжали к центру экрана. Панель локального игрока берём по его
-- playerNum через UIManager.getMoodleUI().
function PML.getMoodleUI(player)
    local num = 0
    if player ~= nil then
        local ok, n = pcall(function() return player:getPlayerNum() end)
        if ok and type(n) == "number" and n >= 0 and n <= 3 then num = n end
    end
    local ui = nil
    if UIManager ~= nil then
        local ok, res = pcall(function() return UIManager.getMoodleUI(num) end)
        if ok then ui = res end
    end
    if ui == nil then
        local ok, res = pcall(function() return MoodlesUI.getInstance() end)
        if ok then ui = res end
        PML.diag("fallbackui", "UIManager.getMoodleUI(" .. tostring(num) .. ") == nil, using MoodlesUI.getInstance()")
    end
    return ui, num
end

-- Страховка для ванильного хотбара. ISHotbar:update() (ISHotbar.lua:223-234) прячет
-- хотбар за рулём и возвращает его обратно ТОЛЬКО если moodleUI:isVisible() == true.
-- Флаг видимости панели мудлов мы не снимаем, но он может остаться выключенным после
-- старых версий мода, из-за другого мода или кадра, в котором мы не рисовали свою
-- стопку, - тогда после выхода из машины хотбар пропадает до перезагрузки мира.
-- Поэтому каждый кадр держим флаг панели включённым и один раз, на переходе
-- "за рулём -> не за рулём", сами возвращаем хотбар, если движок этого не сделал.
function PML.keepHotbarAlive()
    local player = PML.getLocalPlayer()
    if player == nil then return end

    local num = 0
    local okNum, n = pcall(function() return player:getPlayerNum() end)
    if okNum and type(n) == "number" and n >= 0 and n <= 3 then num = n end

    -- Флаг видимости панели мудлов - единственное условие возврата хотбара в ванили.
    if UIManager ~= nil then
        pcall(function()
            local ui = UIManager.getMoodleUI(num)
            if ui ~= nil and not ui:isVisible() then ui:setVisible(true) end
        end)
    end

    -- У геймпадов и у игроков сплитскрина хотбар скрыт штатно (ISPlayerDataObject.lua:113-116).
    if num ~= 0 then return end
    if JoypadState ~= nil and JoypadState.players ~= nil and JoypadState.players[num + 1] ~= nil then return end
    local okBind, bind = pcall(function() return player:getJoypadBind() end)
    if okBind and type(bind) == "number" and bind ~= -1 then return end

    local driver = false
    pcall(function()
        local veh = player:getVehicle()
        if veh ~= nil and veh:isDriver(player) then driver = true end
    end)

    if driver then
        PML.wasDriver = true
        return
    end

    -- Один раз после выхода из машины: если хотбар всё ещё скрыт, включаем его сами.
    if PML.wasDriver then
        PML.wasDriver = false
        if type(getPlayerHotbar) == "function" then
            pcall(function()
                local hotbar = getPlayerHotbar(num)
                if hotbar ~= nil and not hotbar:isVisible() then
                    hotbar:setVisible(true)
                    PML.diag("hotbarfix", "the vanilla hotbar stayed hidden after leaving a vehicle and has been restored")
                end
            end)
        end
    end
end

-- Название мудла берём из ванильных переводов (media/lua/shared/Translate/<LANG>/Moodles.json):
-- ключ Moodles_<TranslationName>_lvl<уровень>. В EN-файле имена в CamelCase, в RU-файле те же
-- ключи в нижнем регистре, поэтому пробуем оба написания. Строка есть не для всех уровней
-- (DEAD/ZOMBIE только lvl4, CANT_SPRINT только lvl1), поэтому при промахе спускаемся по уровням.
function PML.getTransName(i, moodleType)
    local ok, res = pcall(function() return moodleType:getTranslationName() end)
    if ok and type(res) == "string" and res ~= "" then return res end
    return PML.transNames[PML.typeNames[i]]
end

function PML.lookupText(key)
    local ok, res = pcall(function() return getTextOrNull(key) end)
    if ok and type(res) == "string" and res ~= "" then return res end
    local ok2, res2 = pcall(function() return getText(key) end)
    if ok2 and type(res2) == "string" and res2 ~= "" and res2 ~= key then return res2 end
    return nil
end

function PML.getMoodleName(base, level)
    if base == nil then return nil end
    local lower = string.lower(base)
    local order = { level, 4, 3, 2, 1 }
    for k = 1, #order do
        local n = order[k]
        if n ~= nil then
            local t = PML.lookupText(string.format("Moodles_%s_lvl%d", base, n))
            if t == nil then t = PML.lookupText(string.format("Moodles_%s_lvl%d", lower, n)) end
            if t ~= nil then return t end
        end
    end
    return nil
end

-- Кроме названия ванильные переводы содержат описание уровня:
-- Moodles_<TranslationName>_desc_lvl<N> (media/lua/shared/Translate/<LANG>/Moodles.json,
-- в EN 190 ключей: по 4 названия и по 4 описания на мудл). Мод Moodles Descriptions
-- Expanded перезаписывает именно эти ключи, поэтому показываем их в своей подсказке:
-- ванильная панель уведена за экран, и её собственная подсказка игроку не видна.
function PML.getMoodleDesc(base, level)
    if base == nil then return nil end
    local lower = string.lower(base)
    local order = { level, 4, 3, 2, 1 }
    for k = 1, #order do
        local n = order[k]
        if n ~= nil then
            local t = PML.lookupText(string.format("Moodles_%s_desc_lvl%d", base, n))
            if t == nil then t = PML.lookupText(string.format("Moodles_%s_desc_lvl%d", lower, n)) end
            if t ~= nil then return t end
        end
    end
    return nil
end

function PML.getFont()
    if PML.tooltipFont ~= nil then return PML.tooltipFont end
    local f = nil
    if UIFont ~= nil then f = UIFont.Small or UIFont.Medium end
    PML.tooltipFont = f
    return f
end

-- Подпись рисуем слева от подложки, по центру её высоты, на затемнённой плашке.
-- Подсказка стала многострочной (название + описание уровня), поэтому текст режем по
-- переводам строк, а длинные абзацы делим по словам примерно на 52 знака: ширину шрифта
-- здесь измерить нельзя, getTextManager() доступен только на отрисовке.
function PML.wrapTooltip(text)
    local out = {}
    if type(text) ~= "string" or text == "" then return out end
    local function clen(s)
        local _, n = string.gsub(s, "[^\128-\191]", "")
        return n
    end
    for chunk in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local line = nil
        for word in string.gmatch(chunk, "%S+") do
            if line == nil then
                line = word
            elseif clen(line) + clen(word) + 1 <= 52 then
                line = line .. " " .. word
            else
                out[#out + 1] = line
                line = word
            end
        end
        if line ~= nil then out[#out + 1] = line end
    end
    return out
end

function PML.drawTooltip(text, slotX, slotY, drawSize)
    local tm = nil
    pcall(function() tm = getTextManager() end)
    if tm == nil then return end
    local font = PML.getFont()
    if font == nil then return end
    local lines = PML.wrapTooltip(text)
    if #lines == 0 then return end
    local w, h = 0, 0
    local ok = pcall(function()
        h = tm:getFontHeight(font)
        for i = 1, #lines do
            local lw = tm:MeasureStringX(font, lines[i])
            if type(lw) == "number" and lw > w then w = lw end
        end
    end)
    if not ok or w <= 0 or h <= 0 then return end
    local pad = PML.tooltipPad
    local boxW = w + pad * 2
    local boxH = h * #lines + pad
    local boxX = slotX - boxW - 4
    local boxY = slotY + math.floor((drawSize - boxH) / 2)
    if boxX < 0 then boxX = 0 end
    if boxY < 0 then boxY = 0 end
    local black = nil
    pcall(function() black = UIManager.getBlack() end)
    if black ~= nil then UIManager.DrawTexture(black, boxX, boxY, boxW, boxH, 0.75) end
    pcall(function()
        for i = 1, #lines do
            tm:DrawString(font, boxX + pad, boxY + math.floor(pad / 2) + h * (i - 1), lines[i], 1, 1, 1, 1)
        end
    end)
end

-- Мудлы сторонних модов приходят через MoodleFramework: это отдельные
-- ISUIElement-панели из MF.MoodlesStorage[playerNum][name]. Подложку и иконку
-- они рисуют сами (наши текстуры media/ui/Moodles/<size>/ им достаются через
-- перекрытие файлов), но про шкалу уровня не знают. Поэтому поверх каждой такой
-- панели дорисовываем свою полоску по её собственным координатам и размеру.
function PML.getFrameworkMoodles(playerNum)
    if MF == nil or MF.MoodlesStorage == nil then return nil end
    local store = MF.MoodlesStorage[playerNum or 0]
    if store == nil then return nil end
    local list = {}
    for _, moodle in pairs(store) do
        if type(moodle) == "table" and moodle.getLevel ~= nil and moodle.getGoodBadNeutral ~= nil then
            list[#list + 1] = moodle
        end
    end
    return list
end

-- Мудлы MoodleFramework рисует сам фреймворк, поэтому два его поведения приходится
-- перехватывать на месте, один раз за сессию.
-- 1) Подсказка: MF рисует её внутри своего render() (вызов mouseOverMoodle), так что
--    наша галочка "название под курсором" на неё не действовала.
-- 2) Раскачка: MF повторяет ванильное покачивание (MoodleOscilationLevel), причём
--    сдвигает только рисунок, а панель стоит на месте. Гасить её после кадра мало —
--    MF успевает нарисовать кадр со смещением, и вместо плавной качки виден редкий
--    резкий рывок (заметнее всего при открытом инвентаре, когда значение мудла
--    обновляется часто). Поэтому подменяем сам счётчик: он вызывается из render()
--    до отрисовки, значит смещение всегда ноль и колонка стоит ровно.
-- При выключенной своей стопке (ownStack) обе подмены отдают управление оригиналу.
function PML.patchFramework()
    if PML.mfPatched then return end
    if MF == nil or MF.ISMoodle == nil then return end
    PML.mfPatched = true
    local overFn = MF.ISMoodle.mouseOverMoodle
    if type(overFn) ~= "function" then
        PML.diag("nomfhook", "MF.ISMoodle.mouseOverMoodle not found, the hover label of framework moodles is left as is")
    else
        PML.mfMouseOver = overFn
        MF.ISMoodle.mouseOverMoodle = function(self, gbn, level, size)
            if PML.opt("ownStack", true) ~= false and PML.opt("tooltip", true) == false then return end
            return PML.mfMouseOver(self, gbn, level, size)
        end
    end
    local oscFn = MF.ISMoodle.updateOscilatorXOffset
    if type(oscFn) ~= "function" then
        PML.diag("nomfosc", "MF.ISMoodle.updateOscilatorXOffset not found, framework moodles keep their shake")
    else
        PML.mfOscilator = oscFn
        MF.ISMoodle.updateOscilatorXOffset = function(self)
            if PML.opt("ownStack", true) == false then return PML.mfOscilator(self) end
            self.MoodleOscilationLevel = 0
            self.OscilatorStep = 0
            self.OscilatorXOffset = 0
        end
    end
    print("PlainMoodles: MoodleFramework moodles hooked - steady plate, hover label follows the mod option")
end

function PML.renderFrameworkMoodles(playerNum)
    PML.patchFramework()
    local list = PML.getFrameworkMoodles(playerNum)
    if list == nil or #list == 0 then return 0 end
    local drawn = 0
    for i = 1, #list do
        local m = list[i]
        local gbn, level, mx, my, mw = nil, nil, nil, nil, nil
        local wob = 0
        local ok = pcall(function()
            if m.disable then return end
            gbn = m:getGoodBadNeutral()
            level = m:getLevel()
            mx = m:getX()
            my = m:getY()
            mw = m:getWidth()
            -- MF повторяет ванильную раскачку мудла (MF.ISMoodle:updateOscilatorXOffset):
            -- подложку и иконку он сдвигает по горизонтали на OscilatorXOffset, а сама
            -- панель стоит на месте, поэтому иконка стороннего мудла "дёргалась", а наша
            -- шкала рядом с ней стояла ровно. Раскачку гасим: у собственной стопки её нет.
            -- Сбрасывать надо и уровень, и смещение: при нулевом уровне MF смещение уже
            -- не пересчитывает, и панель осталась бы застывшей в сдвинутом положении.
            if type(m.OscilatorXOffset) == "number" then wob = m.OscilatorXOffset end
            if type(m.MoodleOscilationLevel) == "number" and m.MoodleOscilationLevel > 0 then
                m.MoodleOscilationLevel = 0
                m.OscilatorStep = 0
                m.OscilatorXOffset = 0
            end
        end)
        if ok and type(level) == "number" and level > 0 and gbn ~= nil and gbn ~= 0
            and type(mx) == "number" and type(my) == "number" and type(mw) == "number" and mw >= 16 then
            if level > 4 then level = 4 end
            local setSize = PML.pickSet(mw)
            local tex = PML.getTexture(setSize, gbn == PML.goodId, level)
            if tex ~= nil then
                UIManager.DrawTexture(tex, mx + wob, my, mw, mw, PML.alpha)
                drawn = drawn + 1
            else
                PML.diag("nomftex" .. tostring(setSize), string.format("missing texture media/ui/PlainMoodles/%s/*.png for a framework moodle", tostring(setSize)))
            end
        end
    end
    return drawn
end

function PML.render()
    if MoodlesUI == nil then PML.diag("noclass", "MoodlesUI == nil") return end
    local player = PML.getLocalPlayer()
    if player == nil then
        -- До появления персонажа (загрузка мира, экран смерти/респауна) getPlayer()
        -- законно возвращает nil, поэтому сообщаем только если игрок уже был найден.
        if PML.sawPlayer then PML.diag("noplayer", "local player == nil") end
        return
    end
    PML.sawPlayer = true
    local ui, playerNum = PML.getMoodleUI(player)
    if ui == nil then PML.diag("noui", "moodle panel not found in UIManager or MoodlesUI.getInstance()") return end
    -- Ванильный порядок слотов недетерминирован: MoodlesUI держит состояние в
    -- HashMap<MoodleType, MoodleUIData>, а MoodleType не переопределяет hashCode,
    -- поэтому обход карты в MoodlesUI.update() (и вместе с ним нумерация слотов)
    -- меняется от запуска к запуску — шкала уровня попадала на чужую подложку.
    -- Поэтому панель мудлов локального игрока скрывается, а стопка рисуется здесь
    -- целиком в фиксированном порядке PML.typeNames.
    local moodles = player:getMoodles()
    if moodles == nil then PML.diag("nomoodles", "player:getMoodles() == nil") return end

    local drawSize = PML.getDrawSize(ui)
    local setSize = PML.pickSet(drawSize)
    local own = PML.canOwnRender(setSize)
    -- Геометрию панели снимаем до того, как она уедет за экран, и запоминаем:
    -- после увода getAbsoluteY() отдаёт уже offscreen-координату. Когда движок
    -- вернёт панель на место (UIManager.resize при смене разрешения), значение
    -- снова обновится.
    local px = ui:getAbsoluteX()
    local py = ui:getAbsoluteY()
    if type(px) == "number" and type(py) == "number" and py > -1000 then
        PML.baseX = px
        PML.baseY = py
    end
    -- Пока ванильная панель видна, рисовать поверх неё нельзя: её порядок слотов
    -- задаёт HashMap и он не совпадает с нашим, поэтому полоски уровней садились
    -- на чужие иконки (жалоба "the bars on the moodles get swapped"). Если своей
    -- графики под этот размер нет или панель не удалось увести за экран — не
    -- рисуем ничего и оставляем игроку чистую ваниль.
    -- В меню ESC свою стопку не рисуем: ванильные панели там прячет движок, а наши
    -- статические текстуры ложились поверх меню паузы.
    if PML.isMenuOpen() then
        PML.restoreVanilla()
        return
    end
    if not own then
        PML.restoreVanilla()
        PML.diag("noart", string.format("no mod art for size %s, vanilla panel left visible", tostring(setSize)))
        return
    end
    -- Настройки из меню Options -> Mods читаем каждый кадр: галочки применяются сразу.
    if PML.opt("ownStack", true) == false then
        -- Галочку сняли на ходу: ванильную панель обязательно возвращаем на экран.
        PML.restoreVanilla()
        return
    end
    PML.tooltip = PML.opt("tooltip", true) ~= false
    if not PML.hideVanilla(ui, PML.baseX, PML.baseY) then
        PML.restoreVanilla()
        PML.diag("nohide", "failed to move the vanilla panel offscreen, own stack not drawn")
        return
    end
    local x = PML.baseX
    local y = PML.baseY
    if x == nil or y == nil then
        PML.restoreVanilla()
        PML.diag("nogeom", "MoodlesUI getAbsoluteX/Y = " .. tostring(x) .. "," .. tostring(y))
        return
    end
    local test = PML.testMode and PML.debugEnabled()
    local screenH = 1080
    do
        local ok, h = pcall(function() return getCore():getScreenHeight() end)
        if ok and type(h) == "number" and h > 0 then screenH = h end
    end
    local perCol = math.max(1, math.floor((screenH - y) / (drawSize + PML.margin)))
    -- Диагностика геометрии панели: только при PML.debug = true.
    if PML.debug and not PML.geomLogged then
        PML.geomLogged = true
        print(string.format("PlainMoodles GEOM: playerNum=%s panel=%s,%s w=%s h=%s drawSize=%s setSize=%s step=%s perCol=%s screenH=%s own=%s test=%s hideOk=%s panelY=%s", tostring(playerNum), tostring(x), tostring(y), tostring(ui:getWidth()), tostring(ui:getHeight()), tostring(drawSize), tostring(setSize), tostring(drawSize + PML.margin), tostring(perCol), tostring(screenH), tostring(own), tostring(test), tostring(PML.hideOk), tostring(ui:getAbsoluteY())))
        for n = 0, 3 do
            local p2 = nil
            pcall(function() p2 = UIManager.getMoodleUI(n) end)
            if p2 ~= nil then
                local vis, px, py, pw, ph = nil, nil, nil, nil, nil
                pcall(function() vis = p2:isVisible(); px = p2:getAbsoluteX(); py = p2:getAbsoluteY(); pw = p2:getWidth(); ph = p2:getHeight() end)
                print(string.format("PlainMoodles PANEL: n=%d visible=%s x=%s y=%s w=%s h=%s isLocal=%s", n, tostring(vis), tostring(px), tostring(py), tostring(pw), tostring(ph), tostring(p2 == ui)))
            end
        end
    end
    -- Ванильные подсказки ушли вместе с панелью, поэтому наведение считаем сами.
    local mouseX, mouseY = nil, nil
    if PML.tooltip then
        local okm = pcall(function() mouseX = getMouseX(); mouseY = getMouseY() end)
        if not okm then mouseX, mouseY = nil, nil end
    end
    local hoverText, hoverX, hoverY = nil, nil, nil

    local slot = 0
    local types = PML.getTypes()
    if #types == 0 then PML.diag("notypes", "MoodleType registry is empty") end
    PML.logCount = PML.logCount or 0
    local logging = PML.debug and not PML.debugDone and PML.logCount < 20

    if logging then
        PML.logCount = PML.logCount + 1
        print(string.format("PlainMoodles: playerNum=%s drawSize=%s textureSet=%s panel=%s,%s w=%s h=%s moodleTypes=%s isClient=%s", tostring(playerNum), tostring(drawSize), tostring(setSize), tostring(x), tostring(y), tostring(ui:getWidth()), tostring(ui:getHeight()), tostring(#types), tostring(isClient())))
    end

    for i = 1, #types do
        local moodleType = types[i]
        local level = moodles:getMoodleLevel(moodleType)
        if test then level = ((i - 1) % 4) + 1 end
        if level ~= nil and level > 0 then
            local visible = true
            if not test and moodleType == MoodleType.FOOD_EATEN and level < 3 then visible = false end
            if visible then
                local gbn = moodles:getGoodBadNeutral(moodleType)
                local isGood = (gbn == PML.goodId)
                -- В тестовом показе good/bad чередуются блоками по 4 слота: у неактивных
                -- мудлов getGoodBadNeutral() возвращает neutral, поэтому иначе рисовался бы
                -- только набор bad_1..4 и шкалы выглядели бы иначе, чем в обычной игре.
                if test then isGood = (math.floor((i - 1) / 4) % 2 == 0) end
                if level > 4 then level = 4 end
                local slotX = x
                local slotY = y + (drawSize + PML.margin) * slot
                if test then
                    slotX = x - (drawSize + PML.margin) * math.floor(slot / perCol)
                    slotY = y + (drawSize + PML.margin) * (slot % perCol)
                end
                local iconName = PML.typeIcons and PML.typeIcons[i] or nil
                if own then
                    local plateGbn = gbn
                    if test then plateGbn = isGood and PML.goodId or 2 end
                    PML.drawPlate(setSize, slotX, slotY, drawSize, plateGbn, level)
                    PML.drawUiTexture(setSize, "_Moodles_BGoutline", slotX, slotY, drawSize)
                    if iconName ~= nil then PML.drawUiTexture(setSize, iconName, slotX, slotY, drawSize) end
                end
                local tex = PML.getTexture(setSize, isGood, level)
                if tex ~= nil then
                    UIManager.DrawTexture(tex, slotX, slotY, drawSize, drawSize, PML.alpha)
                else
                    PML.diag("notex" .. tostring(setSize), string.format("missing texture media/ui/PlainMoodles/%s/*.png", tostring(setSize)))
                end
                if logging then
                    print(string.format("PlainMoodles:   slot=%d type=%s level=%d goodBadNeutral=%s tex=%s", slot, tostring(moodleType), level, tostring(gbn), tostring(tex ~= nil)))
                end
                if test and not PML.testLogged then
                    print(string.format("PlainMoodles TEST: slot=%d type=%s icon=%s level=%d gbn=%s isGood=%s", slot, tostring(moodleType), tostring(iconName), level, tostring(gbn), tostring(isGood)))
                end
                if mouseX ~= nil and mouseY ~= nil and mouseX >= slotX and mouseX < slotX + drawSize and mouseY >= slotY and mouseY < slotY + drawSize then
                    local base = PML.getTransName(i, moodleType)
                    local name = PML.getMoodleName(base, level)
                    if name ~= nil then
                        hoverText = name
                        -- Второй строкой даём описание уровня: у игроков с Moodles
                        -- Descriptions Expanded здесь окажется их расширенный текст.
                        local desc = PML.getMoodleDesc(base, level)
                        if desc ~= nil and desc ~= name then hoverText = name .. "\n" .. desc end
                        hoverX = slotX
                        hoverY = slotY
                    end
                end
                slot = slot + 1
            end
        end
    end

    -- Мудлы MoodleFramework живут в своих панелях и рисуются движком отдельно,
    -- поэтому шкалу уровня накладываем на них вторым проходом.
    PML.renderFrameworkMoodles(playerNum)

    if hoverText ~= nil then
        PML.drawTooltip(hoverText, hoverX, hoverY, drawSize)
    end

    if test then PML.testLogged = true end
    if logging and slot > 0 then PML.debugDone = true end
end

local function onPostUIDraw()
    if isServer() then return end
    pcall(PML.keepHotbarAlive)
    local ok, err = pcall(PML.render)
    if not ok and not PML.errorLogged then
        PML.errorLogged = true
        print("PlainMoodles ERROR: " .. tostring(err))
    end
end

local function onGameStart()
    PML.cache = {}
    PML.debugDone = false
    PML.errorLogged = false
    PML.diagLogged = {}
    PML.logCount = 0
    PML.sawPlayer = false
    PML.testMode = false
    PML.testLogged = false
    PML.geomLogged = false
    PML.baseX = nil
    PML.baseY = nil
    PML.tooltipFont = nil
    PML.hidden = false
    PML.hiddenPanels = {}
    PML.wasDriver = nil
end

-- F10 (код LWJGL 68) в отладочной игре включает тестовую стопку: все типы сразу
-- с уровнями 1-2-3-4, колонками влево от края экрана, и один раз печатает в лог
-- пары slot/type/icon. В обычной игре (без -debug) хоткей ничего не делает.
local function onKeyPressed(key)
    if key ~= 68 then return end
    if not PML.debugEnabled() then return end
    PML.testMode = not PML.testMode
    PML.testLogged = false
    PML.geomLogged = false
    print("PlainMoodles: testMode = " .. tostring(PML.testMode))
end

-- Настройки мода живут в ванильном меню Options -> Mods: PZAPI.ModOptions из
-- media/lua/client/PZAPI/ModOptions.lua (значения сохраняются в ModOptions.ini,
-- MainOptions:apply() вызывает options:apply() и PZAPI.ModOptions:save()).
PML.optionsId = "PlainMoodles"
PML.options = nil

-- Значение галочки: читаем на лету, чтобы Apply срабатывал без перезапуска.
function PML.opt(id, default)
    local opts = PML.options
    if opts == nil then return default end
    local ok, v = pcall(function()
        local o = opts:getOption(id)
        if o == nil then return nil end
        return o:getValue()
    end)
    if not ok or v == nil then return default end
    return v
end

function PML.text(key, fallback)
    local t = PML.lookupText(key)
    if t ~= nil then return t end
    return fallback
end

function PML.setupOptions()
    if PML.options ~= nil then return end
    if PZAPI == nil or PZAPI.ModOptions == nil then
        print("PlainMoodles DIAG: nooptapi - PZAPI.ModOptions is not loaded, mod options page skipped")
        return
    end
    local ok, err = pcall(function()
        local opts = PZAPI.ModOptions:create(PML.optionsId, PML.text("UI_PlainMoodles_Title", "Plain Moodles Redone"))
        opts:addTickBox("ownStack", PML.text("UI_PlainMoodles_OwnStack", "Draw the moodle stack with this mod"), true,
            PML.text("UI_PlainMoodles_OwnStack_tip", "Off: the game draws the stack itself and only the textures come from the mod."))
        opts:addTickBox("tint", PML.text("UI_PlainMoodles_Tint", "Colour the plate by moodle level"), true,
            PML.text("UI_PlainMoodles_Tint_tip", "Off: plates stay grey at every level, like in version 1.4.0."))
        opts:addTickBox("tooltip", PML.text("UI_PlainMoodles_Tooltip", "Show the moodle name on mouse hover"), true,
            PML.text("UI_PlainMoodles_Tooltip_tip", "Off: no label next to the plate under the cursor."))
        PML.options = opts
    end)
    if not ok then
        PML.options = nil
        print("PlainMoodles DIAG: nooptreg - " .. tostring(err))
    else
        print("PlainMoodles: mod options registered, see Options -> Mods")
    end
end

-- PZAPI грузится из своей папки, поэтому пробуем сразу и, если рано, на OnGameBoot.
PML.setupOptions()
if PML.options == nil and Events ~= nil and Events.OnGameBoot ~= nil then
    Events.OnGameBoot.Add(PML.setupOptions)
end

Events.OnPostUIDraw.Add(onPostUIDraw)
Events.OnGameStart.Add(onGameStart)
Events.OnKeyPressed.Add(onKeyPressed)
