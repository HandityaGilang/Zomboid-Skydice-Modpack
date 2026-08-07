-- Moodle "Mira Firme" do Doberman (addon). Ajuda o player com ARMAS DE FOGO por tres vias, todas
-- auto-corretivas (a engine reescreve os valores sozinha), entao o onDeactivate so limpa bookkeeping:
--   1) dreno de CharacterStat.STRESS -- STRESS entra em CombatManager.getMoodlesPenalty com peso IGUAL
--      ao do panico (STRESS_TO_HIT_BASE_PENALTY 4.0 + 0.5 por tile de distancia) e nenhuma outra raca
--      usa. ATENCAO: STRESS e escala 0-1 (o PANIC do GS e 0-100) -> constante ~100x menor.
--   2) recoilDelay por TIRO -- IsoGameCharacter.updateAimingDelay so volta a assentar a mira quando
--      getRecoilDelay() <= 0 + mod, entao cortar o recoil pos-tiro faz a mira reassentar mais cedo.
--   3) ReloadSpeed -- envelopa ISReloadWeaponAction.setReloadSpeed, que RECALCULA do zero a cada
--      recarga; por construcao reverte sozinho quando o buff sai.
-- NAO usar weapon:setHitChance/setAimingTime/setRecoilDelay/setReloadTime: HandWeapon.save() serializa
-- esses campos (e SyncHandWeaponFieldsPacket replica em MP), entao ficariam GRAVADOS no item pra sempre
-- se o player deslogasse com o buff ativo. E getCombatConfig() e singleton de processo (buffaria todo
-- player do cliente em MP).
local CD = CompanionDogs
if not (CD and CD.DogMoodles and (CD.API_VERSION or 0) >= 1) then return end

local function dogIsCaredFor(dog)
    local h, t = 0, 0
    pcall(function() h = dog:getHunger() or 0 end)
    pcall(function() t = dog:getThirst() or 0 end)
    return h < CD.MOODLE_NEGLECT_MAX and t < CD.MOODLE_NEGLECT_MAX
end

local steady = {}   -- pn -> true enquanto o moodle esta ativo (gate do recoil e da recarga)

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "steadyaim",
    breed = "doberman",
    nameKey = "IGUI_PD_Moodle_SteadyAim",
    descKey = "IGUI_PD_Moodle_SteadyAim_desc",
    icon = "CD_Moodle_SteadyAim",
    fg = "CD_MoodSteadyAimFG",
    tintR = 0.35, tintG = 0.55, tintB = 0.78,
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "doberman" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end
        if not dogIsCaredFor(dog) then return 0 end
        return 1
    end,
    apply = function(player, dog, elapsedMin)
        if not player then return end
        steady[player:getPlayerNum()] = true
        local n = (CD.DOB_STRESS_RELIEF_PER_MIN or 0) * (elapsedMin or 0)
        if n <= 0 then return end
        pcall(function()
            player:getStats():remove(CharacterStat.STRESS, n)
        end)
    end,
    onDeactivate = function(player)
        if player then steady[player:getPlayerNum()] = nil end
    end,
}

-- ---- 2) recoil por tiro ----------------------------------------------------------------------
local function isRangedShot(weapon)
    if not weapon then return false end
    local ranged = false
    pcall(function() ranged = weapon:isRanged() end)
    return ranged
end

-- IsoAnimal herda de IsoPlayer, entao instanceof "IsoPlayer" NAO filtra bicho.
local function isRealLocalPlayer(c)
    if not c or not instanceof(c, "IsoPlayer") or instanceof(c, "IsoAnimal") then return false end
    return c:isLocalPlayer()
end

Events.OnPlayerAttackFinished.Add(function(playerObj, weapon)
    if not isRealLocalPlayer(playerObj) then return end
    if not steady[playerObj:getPlayerNum()] then return end
    if not isRangedShot(weapon) then return end
    local frac = CD.DOB_RECOIL_FRAC or 0
    if frac <= 0 then return end
    -- SwipeStatePlayer acabou de setar o recoilDelay do tiro; cortamos uma fracao dele. Transiente,
    -- nao serializa, e a engine reescreve no proximo tiro -> sem teardown.
    pcall(function()
        local rd = playerObj:getRecoilDelay()
        if rd and rd > 0 then playerObj:setRecoilDelay(rd * (1 - frac)) end
    end)
end)

-- ---- 3) recarga ------------------------------------------------------------------------------
-- setReloadSpeed recalcula o ReloadSpeed do zero a cada recarga (pericia + panico + bandoleira +
-- veiculo) e grava na variavel do personagem; so multiplicamos o resultado. Sem buff -> nada muda.
if ISReloadWeaponAction and ISReloadWeaponAction.setReloadSpeed and not CD.DOB_reloadWrapped then
    CD.DOB_reloadWrapped = true
    local vanillaSetReloadSpeed = ISReloadWeaponAction.setReloadSpeed
    ISReloadWeaponAction.setReloadSpeed = function(character, rack)
        vanillaSetReloadSpeed(character, rack)
        if not isRealLocalPlayer(character) then return end
        if not steady[character:getPlayerNum()] then return end
        local mult = CD.DOB_RELOAD_MULT or 1
        if mult == 1 then return end
        pcall(function()
            local cur = character:getVariableFloat("ReloadSpeed", 1.0)
            character:setVariable("ReloadSpeed", cur * mult)
        end)
    end
end
