require "TimedActions/Animals/ISPickupAnimal"

local CD = CompanionDogs

-- Local no mesmo arquivo (nao CD.deepCopy): um arquivo shared/ em cache antigo pode ler um helper CD.* como nil; um local nao.
local function cdDeepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = cdDeepCopy(v) end
    return r
end

-- Dono pega o companheiro no colo -> a engine reconstroi um cao novo via copyFrom ao soltar (perde nosso ModData). O ModData ainda esta
-- intacto em complete(), entao registramos o vinculo por onlineID aqui; o server reanexa ao soltar (CD.Server.carry / recoverCarriedDogs).
if ISPickupAnimal and not ISPickupAnimal.cd_carryWrapped then
    local vanillaComplete = ISPickupAnimal.complete
    function ISPickupAnimal:complete()
        local ok = vanillaComplete(self)
        pcall(function()
            local a, chr = self.animal, self.character
            if a and chr and CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, chr) then
                CD.request("carry", nil, {
                    onlineID = a:getOnlineID(),
                    data = cdDeepCopy(CD.data(a)),
                })
            end
        end)
        return ok
    end
    ISPickupAnimal.cd_carryWrapped = true
end

-- Fechando a morte do cao-carregado-embaixo-do-carro: no instante em que o dono entra no veiculo ainda segurando o
-- item do cao, pedimos ao server para guardar como o stash dentro do veiculo, ANTES que ele possa equipar uma arma (o que
-- desequiparia->soltaria o cao no tile do veiculo em movimento e o atropelaria). O server (convertCarriedToStash)
-- revalida posse/companheiro e e idempotente; dispara uma vez por entrada em veiculo.
local stashRequested = {}
local function onCarryVehicleEnter(player)
    if not player then return end
    local pn = player:getPlayerNum()
    if not CD.isMounted(player) then stashRequested[pn] = nil; return end
    if stashRequested[pn] then return end
    local inv = player:getInventory()
    if not inv then return end
    local items = inv:getItems()
    local holding = false
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and instanceof(it, "AnimalInventoryItem") then holding = true; break end
    end
    if not holding then return end
    stashRequested[pn] = true
    CD.request("stashcarried", nil, {})
end

if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onCarryVehicleEnter)
end
