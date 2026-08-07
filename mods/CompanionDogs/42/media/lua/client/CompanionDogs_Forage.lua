local CD = CompanionDogs

-- Ajuda leve no forrageio: enquanto um companion proximo, alimentado, leal e capaz de cacar esta por perto, o Search
-- Mode (forrageio) vanilla do DONO revela caca de um pouco mais longe (o faro do cao). Dois wraps minimos no forageSystem vanilla:
-- um bonus fixo de raio de visao (getProfessionVisionBonus, lido uma vez em maxRadius + viewDistance, e a engine limita
-- o total em visionRadiusCap = 15) e um multiplicador de categoria pras categorias relevantes pra caca (Animals / Insects
-- / Tracks / DeadAnimals). Totalmente CLIENT-side / por-player (forrageio e por-player), lendo o ModData replicado
-- do cao. Gated exatamente como o mood do companion (proximo + alimentado + leal, ver CompanionDogs_Moodles.lua); disponivel desde L0.

if forageSystem then
    local HUNT_FORAGE_CATEGORIES = { Animals = true, Insects = true, Tracks = true, DeadAnimals = true }
    local cache = {}  -- por playerNum: { ms, bonus }; doVisionCheck roda POR ICONE, entao guarda em cache a varredura de raio por um instante

    local function neglected(dog)
        local h, t = 0, 0
        pcall(function()
            h = dog:getHunger()
            t = dog:getThirst()
        end)
        local max = CD.MOODLE_NEGLECT_MAX or 0.75
        return h >= max or t >= max
    end

    -- Bonus de raio de forrageio de um companion; o base precisa de huntEnabled, o extra de faro apurado do Golden vale mesmo com a caca desligada. Memoizado ~0.5s.
    function CD.huntForageBonus(character)
        if not character then return 0 end
        local pn = (character.getPlayerNum and character:getPlayerNum()) or 0
        local nowMs = getTimestampMs()
        local c = cache[pn]
        if c and (nowMs - c.ms) < 500 then return c.bonus end
        local bonus = 0
        local dog = CD.findNearbyCompanion(character, CD.moodleHappyRadius())
        if dog and not CD.isDisloyal(dog) and not neglected(dog) then
            if CD.huntEnabled() and CD.huntForageBonusEnabled() then
                bonus = CD.effectiveForageBonus(dog) or 0
            end
            if CD.getBreed(dog) == "retriever" then bonus = bonus + CD.goldenForageVisionExtra() end -- faro apurado do golden
        end
        cache[pn] = { ms = nowMs, bonus = bonus }
        return bonus
    end

    local origProf = forageSystem.getProfessionVisionBonus
    function forageSystem.getProfessionVisionBonus(character)
        local base = origProf(character)
        local b = 0
        pcall(function() b = CD.huntForageBonus(character) end)
        return base + b
    end

    local origCat = forageSystem.getCategoryBonus
    function forageSystem.getCategoryBonus(character, catDef)
        local base = origCat(character, catDef)
        if catDef and catDef.name and HUNT_FORAGE_CATEGORIES[catDef.name] then
            local extra = 0
            pcall(function()
                if CD.huntEnabled() and (CD.huntForageBonus(character) or 0) > 0 then extra = CD.huntForageCategoryBonus() end
            end)
            if extra > 0 then return base * (1 + extra) end
        end
        return base
    end
end
