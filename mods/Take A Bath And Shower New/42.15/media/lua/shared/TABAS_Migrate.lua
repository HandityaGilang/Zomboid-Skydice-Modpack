-- if isClient() or isServer() then return end

-- local function moveKey(md, oldKey, newKey)
--     if md[oldKey] ~= nil and md[newKey] == nil then
--         md[newKey] = md[oldKey]
--         md[oldKey] = nil
--         return true
--     end
--     return false
-- end

-- local function removeKey(md, key)
--     if md[key] ~= nil then
--         md[key] = nil
--         return true
--     end
--     return false
-- end

-- local function migratePlayerData(playerObj)
--     if not playerObj then return false end
--     local md = playerObj:getModData()
--     if not md then return false end

--     local changed = false
--     changed = moveKey(md, "BodyGrime", "tabas_BodyGrime") or changed
--     changed = moveKey(md, "isBathing", "tabas_IsBathing") or changed
--     changed = removeKey(md, "tabasEquippedItems") or changed
--     changed = removeKey(md, "tabas_EquippedItems") or changed
--     changed = removeKey(md, "bathBenefitedLimit") or changed
--     changed = removeKey(md, "tabas_BenefitedLimit") or changed
--     return changed
-- end

-- local function TABAS_MigrateOnGameStart()
--     for i=0, getNumActivePlayers()-1 do
--         local playerObj = getSpecificPlayer(i)
--         if playerObj and migratePlayerData(playerObj) then
--             playerObj:transmitModData()
--         end
--     end
-- end

-- Events.OnGameStart.Add(TABAS_MigrateOnGameStart)
