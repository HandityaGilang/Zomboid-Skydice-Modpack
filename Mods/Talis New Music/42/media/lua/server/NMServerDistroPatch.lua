-- Optional loot distribution patch to suppress vanilla CD player spawns.
local suppressVanillaCDPlayer = true

local function removeItemFromLootList(list, itemName)
    if type(list) ~= "table" then
        return 0
    end
    local removed = 0
    for i = #list - 1, 1, -2 do
        if tostring(list[i]) == itemName then
            table.remove(list, i + 1)
            table.remove(list, i)
            removed = removed + 1
        end
    end
    return removed
end

local function walkAndStrip(node, itemName)
    local removed = 0
    if type(node) ~= "table" then
        return removed
    end
    if type(node.items) == "table" then
        removed = removed + removeItemFromLootList(node.items, itemName)
    end
    for _, value in pairs(node) do
        if type(value) == "table" then
            removed = removed + walkAndStrip(value, itemName)
        end
    end
    return removed
end

local function applyVanillaCDPlayerSuppression()
    if not suppressVanillaCDPlayer then
        return
    end
    local total = 0
    if ProceduralDistributions and ProceduralDistributions.list then
        total = total + walkAndStrip(ProceduralDistributions.list, "CDplayer")
        total = total + walkAndStrip(ProceduralDistributions.list, "Base.CDplayer")
    end
    if SuburbsDistributions then
        total = total + walkAndStrip(SuburbsDistributions, "CDplayer")
        total = total + walkAndStrip(SuburbsDistributions, "Base.CDplayer")
    end
    if NMCore and NMCore.logChannel then
        NMCore.logChannel("registry", "distro.patch removed CDplayer entries", tostring(total))
    end
end

if Events and Events.OnPreDistributionMerge and Events.OnPreDistributionMerge.Add then
    Events.OnPreDistributionMerge.Add(applyVanillaCDPlayerSuppression)
end

