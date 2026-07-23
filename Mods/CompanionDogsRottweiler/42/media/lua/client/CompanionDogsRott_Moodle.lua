-- Moodle "Linha de Frente" do Rottweiler: o ICONE fica SEMPRE visivel perto de um Rott cuidado e leal
-- (igual as outras racas), mas o EFEITO (devolver fracao da endurance dos golpes corpo-a-corpo) so vale
-- enquanto o Rott esta ENGAJADO em combate no raio (CD.data(dog).inCombat, sincronizado em borda pelo
-- base 0.6.3+). Registrado no registry aberto CD.DogMoodles do base (gabarito: moodle Warmed do husky).
local CD = CompanionDogs
if not (CD and CD.DogMoodles and (CD.API_VERSION or 0) >= 1) then return end

local function dogIsCaredFor(dog)
    local h, t = 0, 0
    pcall(function() h = dog:getHunger() or 0 end)
    pcall(function() t = dog:getThirst() or 0 end)
    return h < CD.MOODLE_NEGLECT_MAX and t < CD.MOODLE_NEGLECT_MAX
end

-- pn -> true enquanto o Rott esta LUTANDO (gate do refund; setado pelo apply, limpo na desativacao)
local fighting = {}
-- pn -> endurance capturada no inicio do swing (medicao de delta por golpe)
local swingStart = {}

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "frontline",
    breed = "rottweiler",
    nameKey = "IGUI_PD_Moodle_FrontLine",
    descKey = "IGUI_PD_Moodle_FrontLine_desc",
    icon = "CD_Moodle_FrontLine",
    fg = "CD_MoodFrontLineFG",
    tintR = 0.78, tintG = 0.24, tintB = 0.20, -- frame vermelho-escuro de combate (distinto dos verdes/ambar/laranja)
    -- Icone sempre visivel perto do Rott cuidado (como breedHappy/courage/warmed); o combate so liga o efeito.
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "rottweiler" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end
        if not dogIsCaredFor(dog) then return 0 end
        return 1
    end,
    apply = function(player, dog)
        if not player then return end
        fighting[player:getPlayerNum()] = (dog and CD.data(dog).inCombat == true) or nil
    end,
    onDeactivate = function(player)
        if player then
            local pn = player:getPlayerNum()
            fighting[pn] = nil
            swingStart[pn] = nil
        end
    end,
}

local function isMeleeSwing(weapon)
    -- refund so em corpo-a-corpo (punho = weapon nil tambem vale); arma de fogo fica de fora.
    if not weapon then return true end
    local ranged = false
    pcall(function() ranged = weapon:isRanged() end)
    return not ranged
end

Events.OnWeaponSwing.Add(function(character, weapon)
    -- IsoAnimal extends IsoPlayer, entao instanceof IsoPlayer NAO filtra bicho; exclui animal explicitamente.
    if not character or not instanceof(character, "IsoPlayer") or instanceof(character, "IsoAnimal") then return end
    if not character:isLocalPlayer() then return end
    local pn = character:getPlayerNum()
    if not fighting[pn] then return end
    if not isMeleeSwing(weapon) then return end
    pcall(function() swingStart[pn] = character:getStats():get(CharacterStat.ENDURANCE) end)
end)

Events.OnPlayerAttackFinished.Add(function(playerObj, weapon)
    if not playerObj or instanceof(playerObj, "IsoAnimal") or not playerObj:isLocalPlayer() then return end
    local pn = playerObj:getPlayerNum()
    local e0 = swingStart[pn]
    if e0 == nil then return end
    swingStart[pn] = nil
    if not fighting[pn] then return end
    if not isMeleeSwing(weapon) then return end
    pcall(function()
        local st = playerObj:getStats()
        local cost = e0 - st:get(CharacterStat.ENDURANCE)
        if cost > 0 then
            st:add(CharacterStat.ENDURANCE, cost * (CD.ROTT_FRONTLINE_REFUND_FRAC or 0.35))
        end
    end)
end)
