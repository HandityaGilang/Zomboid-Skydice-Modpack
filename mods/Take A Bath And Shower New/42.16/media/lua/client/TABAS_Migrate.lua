-- local function moveKey(md, oldKey, newKey)
--     if md[oldKey] ~= nil and md[newKey] == nil then
--         md[newKey] = md[oldKey]
--         md[oldKey] = nil
--         return true
--     end
--     return false
-- end

-- local function removeKeys(md, key)
--     if md[key] ~= nil then
--         md[key] = nil
--         return true
--     end
--     return false
-- end

-- local SHOULD_REMOVE_DATA = {
--     "isBathing",
--     "tabasEquippedItems",
--     "tabas_EquippedItems",
--     "tabas_FeelingGaze",
--     "tabas_Comforted",
--     "tabas_BathingStartH",
--     "tabas_WetEndH",
--     "tabas_WetGraceEndH",
-- }

-- local function migratePlayerData(playerObj)
--     if not playerObj then return false end
--     local md = playerObj:getModData()
--     if not md then return false end

--     local changed = false

--     changed = moveKey(md, "BodyGrime", "tabas_BodyGrime") or changed
--     for i=1, #SHOULD_REMOVE_DATA do
--         changed = removeKeys(md, SHOULD_REMOVE_DATA[i]) or changed
--     end
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
