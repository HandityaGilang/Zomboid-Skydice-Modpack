local CD = CompanionDogs

-- Integracao deterministica com o Project RV Interior. O mod do RV (modPROJECTRVInterior) controla entrada/saida totalmente
-- no client: faz vehicle:exit + um teleport distante pra uma cell de interior fixa (x>22500, y>12000) e, na saida,
-- RE-SENTA o motorista. O server do CompanionDogs antes INFERIA essa transicao a partir de um delta de posicao server-side,
-- que fica atrasado em relacao aos movimentos client do mod do RV (em MP a posicao/square do server ficam defasadas por segundos depois do
-- teleport), entao o cao "as vezes nao vinha junto". Detectamos a borda do MESMO predicado de "estar dentro" que o mod do RV
-- usa (RVFunction.CheckIfInRV em SP / CheckIfInRV em MP, ambos = getX>MINX e getY>MINY), aqui no client
-- onde a posicao e imediata e confiavel, e mandamos um sinal explicito; o server (CD.Server.rventer/rvexit em
-- CompanionDogs_Companion.lua) arma as janelas de bring existentes e ja comprovadas. A deteccao server-side de banda/salto continua
-- como fallback, entao isto e puramente aditivo e nunca o unico gatilho.

local MINX = CD.RV_INTERIOR_MIN_X or 22500
local MINY = CD.RV_INTERIOR_MIN_Y or 12000

-- Calculado localmente (nao via a funcao do mod do RV): em SP o CheckIfInRV fica numa tabela module-local que nao e
-- global, e replicar uma comparacao evita uma dependencia rigida dos internals/ordem de load do mod do RV.
local function isInRV(player)
    return player:getX() > MINX and player:getY() > MINY
end

local wasInRV = {}
local function onRVTransition(player)
    if not player then return end
    local pn = player:getPlayerNum()
    local now = isInRV(player) == true
    local prev = wasInRV[pn]
    if prev == nil then wasInRV[pn] = now; return end -- primeira vez: so baseline, sem borda
    if now == prev then return end
    wasInRV[pn] = now
    if now then
        CD.request("rventer", nil, {}) -- entrou no interior do RV: traz o cao pra dentro (o server valida pd.token)
    else
        CD.request("rvexit", nil, {}) -- saiu do interior do RV: traz o cao de volta pro dono no mundo
    end
end

-- Mesmo gate do CompanionDogs_Carry.lua: registra nos clients (coop/dedicated) e em SP, nunca num dedicated server.
if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onRVTransition)
end
