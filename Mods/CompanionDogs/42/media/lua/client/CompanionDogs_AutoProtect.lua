local CD = CompanionDogs

-- A deteccao do auto-protect roda no client do DONO porque os sinais de acao vulneravel (a ISTimedActionQueue
-- de ler/comer/pescar) so existem no client, o server nunca os ve. Quando o dono esta no meio de uma dessas
-- acoes E o companion carregado esta com o toggle por-cao ligado, batemos heartbeat pro server (~uma vez por game-minute, e
-- imediatamente na entrada) pra (re)armar a janela de protect; o companion loop autoritativo no host entao
-- guarda o cao ancorado no dono. No fim da acao mandamos um OFF explicito pra o cao ser liberado prontamente.

local active = {}    -- playerNum -> batendo heartbeat no momento
local lastSendMin = {}

local function hasBlockingAction(player)
    local ok, result = pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(player)
        if not q or not q.queue then return false end
        for i = 1, #q.queue do
            local a = q.queue[i]
            local t = a and a.Type
            if t then
                if CD.AUTO_PROTECT_ACTIONS[t] then return true end
                if string.find(t, "Fish", 1, true) then return true end
            end
        end
        return false
    end)
    return ok and result == true
end

local function isOwnerVulnerable(player)
    local v = false
    pcall(function()
        if player:isAsleep() then v = true; return end
        if player.isReading and player:isReading() then v = true; return end
        if player.isSitOnGround and player:isSitOnGround() then v = true; return end
    end)
    if v then return true end
    return hasBlockingAction(player)
end

local function onPlayerUpdate(player)
    if not player then return end
    if not CD.autoProtectEnabled() then return end
    local pn = player:getPlayerNum()

    -- isOwnerVulnerable e barato (getters de estado do player + um scan minusculo de timed-action). Resolve o companion (um
    -- scan de animais por toda a cell) so quando o dono esta de fato vulneravel, ou quando precisamos mandar o release.
    if isOwnerVulnerable(player) then
        local dog = CD.getCompanionAnimal(player)
        if dog and CD.getAutoProtect(dog) then
            -- Arredonda pra game-minutes pra o heartbeat disparar ~uma vez/min, nao a cada frame (a janela do server e de 5 min).
            local now = math.floor(CD.worldMinutes())
            if lastSendMin[pn] == nil or now ~= lastSendMin[pn] then
                CD.request("setprotectactive", dog, {})
                lastSendMin[pn] = now
            end
            active[pn] = true
            return
        end
    end

    if active[pn] then
        -- Acao terminou (ou o toggle/cao sumiu): libera o cao prontamente. dog pode ser nil agora (saiu/guardado),
        -- caso em que a janela do server simplesmente expira sozinha.
        local dog = CD.getCompanionAnimal(player)
        if dog then CD.request("setprotectactive", dog, { off = true }) end
        active[pn] = nil
        lastSendMin[pn] = nil
    end
end

if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
end
