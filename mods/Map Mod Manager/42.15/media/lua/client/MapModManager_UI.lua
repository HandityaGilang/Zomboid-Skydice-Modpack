--      ██╗██╗██╗███████╗███████╗██╗███████╗ █  ███████╗    ███╗   ███╗ ██████╗ ██████╗ ███████╗ --
--      ██║██║██║╚══███╔╝╚══███╔╝██║██╔════╝    ██╔════╝    ████╗ ████║██╔═══██╗██╔══██╗██╔════╝ --
--      ██║██║██║  ███╔╝   ███╔╝ ██║█████╗      ███████╗    ██╔████╔██║██║   ██║██║  ██║███████╗ --
-- ██   ██║██║██║ ███╔╝   ███╔╝  ██║██╔══╝      ╚════██║    ██║╚██╔╝██║██║   ██║██║  ██║╚════██║ --
-- ╚█████╔╝██║██║███████╗███████╗██║███████╗    ███████║    ██║ ╚═╝ ██║╚██████╔╝██████╔╝███████║ --
--  ╚════╝ ╚═╝╚═╝╚══════╝╚══════╝╚═╝╚══════╝    ╚══════╝    ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝ --

-- Permissions                                                                                   --
-- Redistribution of this mod without explicit permission from the creator, jiizzjacuzzii is     --
-- prohibited under any circumstances. This includes, but is not limited to, uploading this mod  --
-- to the Steam Workshop or any other site, distrubtion as part of another mod or modpack,       --
-- distribution of modified versions.                                       © 2025 jiizzjacuzzii --

-- Main Menu --
    local MapModManagerLabel = {}

-- Get Subscribed Maps Not In Database --
    local dynamicMerged = false

    local function buildDynamicMapEntries()
        local result = {}
        local modDirs = getModDirectoryTable()
        local separator = "/"
        local dependencyLookup = {}

        for _, directory in ipairs(modDirs) do
            local info = getModInfo(directory)
            if info then
                local id   = tostring(info:getId())
                local wsID = directory:match("108600[\\/](%d+)")
                dependencyLookup[id] = {
                    name       = tostring(info:getName()),
                    workshopID = wsID or "",
                }
            end
        end

        for _, directory in ipairs(modDirs) do
            local info       = getModInfo(directory)
            if info then
                local id         = tostring(info:getId())
                local wsID       = directory:match("108600[\\/](%d+)")
                local url        = wsID
                                  and ("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. wsID)
                                  or ""
                local mapFolders = getMapFoldersForMod(id)

                local deps = {}
                do
                    local reqs = info:getRequire()
                    if reqs and reqs:size() > 0 then
                        for i = 0, reqs:size()-1 do
                            local depID = tostring(reqs:get(i))
                            local dep   = dependencyLookup[depID]
                            if dep then
                                if dep.workshopID ~= "" then
                                    table.insert(deps,
                                      string.format("%s (https://steamcommunity.com/workshop/filedetails/?id=%s)",
                                                    dep.name, dep.workshopID))
                                else
                                    table.insert(deps, dep.name)
                                end
                            else
                                table.insert(deps, depID)
                            end
                        end
                    end
                end

                if mapFolders then
                    for j = 0, mapFolders:size()-1 do
                        local mapName = mapFolders:get(j)
                        local testDir = "media/maps" .. separator .. mapName
                        local files   = listFilesInModDirectory(id, testDir)

                        if files and files:size() > 0 then
                            local cells = {}
                            local seen  = {}

                            for k = 0, files:size()-1 do
                                local fname = tostring(files:get(k))
                                local r, c  = fname:match("^world_(%d+)_(%d+)%.lotpack$")
                                if r and c then
                                    local key = r .. ":" .. c
                                    if not seen[key] then
                                        seen[key] = true
                                        table.insert(cells, {
                                            row = tonumber(r),
                                            col = tonumber(c),
                                        })
                                    end
                                end
                            end

                            if #cells > 0 then
                                local uniqueKey = mapName
                                if result[mapName] then
                                    uniqueKey = id .. "_" .. mapName
                                end
                                result[uniqueKey] = {
                                    cells        = cells,
                                    tooltip      = mapName,
                                    workshopID   = wsID or "",
                                    modID        = id,
                                    mapFolder    = mapName,
                                    url          = url,
                                    dependencies = deps,
                                }
                            end
                        end
                    end
                end
            end
        end

        return result
    end

    -- Merge subscribed maps not in the database
        local function mergeDynamicMapEntries()
            if dynamicMerged then return end

            local existingModIDs = {}
            for _, entry in pairs(MapModManager_DB) do
                if entry.modID and entry.modID ~= "" then
                    existingModIDs[entry.modID] = true
                end
            end

            local dyn = buildDynamicMapEntries()
            for name, data in pairs(dyn) do
                if not existingModIDs[data.modID] then
                    MapModManagerLabel.MergedMapList[name] = data
                end
            end

            dynamicMerged = true
        end

-- Get Subscribed Dependencies Not In Database --
    local dependencyMerged = false

    local function buildDynamicDependencyEntries()
        local result       = {}
        local modDirs      = getModDirectoryTable()
        local lookup       = {}
        local outputted    = {}

        for _, dir in ipairs(modDirs) do
            local info = getModInfo(dir)
            if info then
                local id   = tostring(info:getId())
                local wsID = dir:match("108600[\\/](%d+)")
                lookup[id] = {
                    name       = tostring(info:getName()),
                    workshopID = wsID or "",
                    modID      = id,
                }
            end
        end

        for _, dir in ipairs(modDirs) do
            local info = getModInfo(dir)
            if info then
                local reqs = info:getRequire()
                if reqs and reqs:size() > 0 then
                    for i = 0, reqs:size()-1 do
                        local depID = tostring(reqs:get(i))
                        local dep   = lookup[depID]
                        if dep and not outputted[dep.modID] then
                            -- only one block per mod
                            result[dep.name] = {
                                workshopID = dep.workshopID,
                                modID      = dep.modID,
                                MapFolder  = "",
                            }
                            outputted[dep.modID] = true
                        end
                    end
                end
            end
        end

        return result
    end

    --- Merge subscribed dependencies not in the database
        local function mergeDynamicDependencyEntries()
            if dependencyMerged then return end

            local existingModIDs = {}
            for _, entry in pairs(Dependency_DB) do
                if entry.modID and entry.modID ~= "" then
                    existingModIDs[entry.modID] = true
                end
            end

            local dyn = buildDynamicDependencyEntries()
            for name, data in pairs(dyn) do
                if not existingModIDs[data.modID] then
                    MapModManagerLabel.MergedDependencyList[name] = data
                end
            end

            dependencyMerged = true
        end

-- Build Merged Map List --
    function buildMergedMapList()
        local merged = {}
        local dynamicModIDs = {}
        local addedDynamic = {}

        -- First pass: Add all dynamic (live) map entries and track their modIDs
        local dynamic = buildDynamicMapEntries()
        for name, data in pairs(dynamic) do
            merged[name] = data
            if data.modID and data.modID ~= "" then
                dynamicModIDs[data.modID] = true
            end
            table.insert(addedDynamic, name)
        end

        -- Second pass: Add database entries only if their modID wasn't found in dynamic scan
        for name, data in pairs(MapModManager_DB) do
            local shouldAdd = true
            if data.modID and data.modID ~= "" and dynamicModIDs[data.modID] then
                shouldAdd = false
            end
            if shouldAdd and not merged[name] then
                merged[name] = data
            end
        end

        if #addedDynamic > 0 then
            print("Map mods found locally (not in the database): " .. table.concat(addedDynamic, ", "))
        end

        return merged
    end

-- Conflict Check --
    function buildConflicts(mapList)
        local cellMap = {}
        for name, data in pairs(mapList) do
            if data.cells then
                for _, cell in ipairs(data.cells) do
                    local key = cell.row .. ":" .. cell.col
                    cellMap[key] = cellMap[key] or {}
                    table.insert(cellMap[key], name)
                end
            end
        end

        for name, data in pairs(mapList) do
            local conflicts = {}
            local conflictSet = {}
            if data.cells then
                for _, cell in ipairs(data.cells) do
                    local key = cell.row .. ":" .. cell.col
                    for _, other in ipairs(cellMap[key] or {}) do
                        if other ~= name and not conflictSet[other] then
                            table.insert(conflicts, other)
                            conflictSet[other] = true
                        end
                    end
                end
            end
            data.conflicts = conflicts
        end
    end

-- Temp Mod List --
    local tempModList = {}

-- Get Active Mods --
    function MapModManagerLabel.getActiveMods()
        tempModList = {}
        MapModManagerLabel.originalTempModList = {}
        local activeMods = getActivatedMods()
        for i = 0, activeMods:size() - 1 do
            local modID = tostring(activeMods:get(i))
            tempModList[modID] = true
            MapModManagerLabel.originalTempModList[modID] = true
        end
    end

-- Get Subscribed Mods --
    MapModManagerLabel.subscribedModsCache = {}
    do
        local steamIDs = getSteamWorkshopItemIDs()
        for i = 0, steamIDs:size() - 1 do
            MapModManagerLabel.subscribedModsCache[tostring(steamIDs:get(i))] = true
        end
    end

-- Initialize Pages --
    MapModManagerLabel.currentPage = 1
    MapModManagerLabel.mapsPerPage = 1
    MapModManagerLabel.totalMaps = 0
    MapModManagerLabel.totalPages = 1

-- Populate S Scroll List --
    function MapModManagerLabel.populateScrollListS()
        local mainScreen = MainScreen.instance
        local SScrollList = mainScreen.MapModManager_SScrollList
        if not SScrollList then return end
        SScrollList:clear()

        -- Active mods list
            local activeMapNames = {}
            local orderedMods = {}

            if MainScreen.instance.MLPanel and MainScreen.instance.MLPanel.loadOrderList then
                orderedMods = MainScreen.instance.MLPanel.loadOrderList
            else

                for modID, isActive in pairs(tempModList) do
                    if isActive then
                        table.insert(orderedMods, modID)
                    end
                end
            end

            for _, modID in ipairs(orderedMods) do
                for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
                    if mapData.modID == modID then
                        table.insert(activeMapNames, mapName)
                    end
                end
            end

        -- Subscribed mods list
            local subscribedMods = getSteamWorkshopItemIDs()
            local subscribedMapNames = {}
            for i = 0, subscribedMods:size() - 1 do
                local workshopID = tostring(subscribedMods:get(i))
                for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
                    if mapData.workshopID == workshopID then
                        table.insert(subscribedMapNames, mapName)
                    end
                end
            end

            local activeSet = {}
            for _, name in ipairs(activeMapNames) do
                activeSet[name] = true
            end
            local filteredSubscribed = {}
            for _, name in ipairs(subscribedMapNames) do
                if not activeSet[name] then
                    table.insert(filteredSubscribed, name)
                end
            end

        -- Sort subscribed mods A-Z
            table.sort(filteredSubscribed, function(a, b) return a:lower() < b:lower() end)

        -- Combine lists
            local finalMapNames = {}
            for _, name in ipairs(activeMapNames) do
                table.insert(finalMapNames, name)
            end
            for _, name in ipairs(filteredSubscribed) do
                table.insert(finalMapNames, name)
            end

            for _, mapName in ipairs(finalMapNames) do
                SScrollList:addItem(mapName, nil)
            end
    end

    function setupSScrollListCallbacks()
        local mainScreen = MainScreen.instance
        local SScrollList = mainScreen.MapModManager_SScrollList
        if not SScrollList then return end

        SScrollList.doDrawItem = function(self, y, item, alt)
            local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
            if gridPanel and gridPanel.selectedMaps[item.text] then
                self:drawRect(0, y, self:getWidth(), self.itemheight, 0.2, 0.8, 0.8, 0.8)
            else
                self:drawRect(0, y, self:getWidth(), self.itemheight, 1, 0, 0, 0)
            end

            local mapData = MapModManagerLabel.MergedMapList[item.text]
            local modID = mapData and mapData.modID

            local textColor = { r = 1, g = 1, b = 1, a = 1 }
            if modID and tempModList[modID] then
                textColor = { r = 102/255, g = 204/255, b = 76/255, a = 1 }
            end

            self:drawText(
                item.text,
                10,
                y + (self.itemheight - getTextManager():MeasureStringY(UIFont.Medium, item.text)) / 2,
                textColor.r, textColor.g, textColor.b, textColor.a,
                UIFont.Medium
            )

            -- On/Off Button
                local buttonLabel = "Off"
                if modID and tempModList[modID] then
                    buttonLabel = "On"
                end

                local buttonWidth = 50
                local buttonHeight = 20
                local buttonX = self:getWidth() - buttonWidth - 20
                local buttonY = y + ((self.itemheight - buttonHeight) / 2)

                self:drawRect(buttonX, buttonY, buttonWidth, buttonHeight, 1, 0, 0, 0)
                self:drawRectBorder(buttonX, buttonY, buttonWidth, buttonHeight, 1, 1, 1, 1)
                self:drawTextCentre(buttonLabel, buttonX + buttonWidth / 2, buttonY + 3, 1, 1, 1, 1, UIFont.Small)

                item.buttonX = buttonX
                item.buttonY = buttonY
                item.buttonWidth = buttonWidth
                item.buttonHeight = buttonHeight

            return y + self.itemheight
        end

        SScrollList.onMouseDown = function(self, x, y)
            local idx = self:rowAt(x, y)
            if idx and idx >= 1 and idx <= #self.items then
                local item = self.items[idx]
                if item then
                    local mapName = item.text
                    local mapData = MapModManagerLabel.MergedMapList[mapName]
                    local modID = mapData and mapData.modID
                    local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
        
                    if item.buttonX and item.buttonY and item.buttonWidth and item.buttonHeight then
                        if x >= item.buttonX and x <= (item.buttonX + item.buttonWidth)
                        and y >= item.buttonY and y <= (item.buttonY + item.buttonHeight) then
                            if modID then
                                local wasActive = tempModList[modID]
                                tempModList[modID] = not wasActive
                                if gridPanel and gridPanel.updateDependencies then
                                    gridPanel:updateDependencies()
                                end
                                MapModManagerLabel.populateScrollListD()
        
                                local mainScreen = MainScreen.instance
                                local MLPanel = mainScreen.MLPanel
                                if MLPanel and MLPanel.loadOrderList then
                                    if tempModList[modID] then
                                        local found = false
                                        for _, id in ipairs(MLPanel.loadOrderList) do
                                            if id == modID then
                                                found = true
                                                break
                                            end
                                        end
                                        if not found then
                                            table.insert(MLPanel.loadOrderList, modID)
                                        end
                                    else
                                        for i, id in ipairs(MLPanel.loadOrderList) do
                                            if id == modID then
                                                table.remove(MLPanel.loadOrderList, i)
                                                break
                                            end
                                        end
                                    end
                                    MapModManagerLabel.refreshMLScrollList()
                                end
                            end
                            return
                        end
                    end
        
                    if gridPanel then
                        if gridPanel.selectedMaps[mapName] then
                            gridPanel.selectedMaps[mapName] = nil
                        else
                            gridPanel.selectedMaps[mapName] = true
                        end
                        if gridPanel.updateDependencies then
                            gridPanel:updateDependencies()
                        end
                    end
                    self.selected = idx
                    MapModManagerLabel.populateScrollListD()
                end
            end
        end        
    end

-- Populate D Scroll List --
    function MapModManagerLabel.populateScrollListD()
        local mainScreen = MainScreen.instance
        local ScrollListD = mainScreen.MapModManager_DependencyScrollList
        if not ScrollListD then return end

        ScrollListD:clear()
        
        local gridPanel = mainScreen.gridPanel
        if not gridPanel then return end

        local Dependency = {}

        for mapName, _ in pairs(gridPanel.selectedMaps) do
            local mapData = MapModManagerLabel.MergedMapList[mapName]
            if mapData and mapData.dependencies then
                for _, dependency in ipairs(mapData.dependencies) do
                    local workshopID = dependency:match("id=(%d+)")
                    if workshopID then
                        for DName, DData in pairs(MapModManagerLabel.MergedDependencyList) do
                            if DData.workshopID == workshopID then
                                Dependency[DName] = Dependency[DName] or {}
                                table.insert(Dependency[DName], mapName)
                                break
                            end
                        end
                    end
                end
            end
        end

        for modID, isActive in pairs(tempModList) do
            if isActive then
                for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
                    if mapData.modID == modID and mapData.dependencies then
                        for _, dependency in ipairs(mapData.dependencies) do
                            local workshopID = dependency:match("id=(%d+)")
                            if workshopID then
                                for DName, DData in pairs(Dependency_DB) do
                                    if DData.workshopID == workshopID then
                                        Dependency[DName] = Dependency[DName] or {}
                                        table.insert(Dependency[DName], mapName)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local sortedD = {}
        for DName, _ in pairs(Dependency) do
            table.insert(sortedD, DName)
        end
        table.sort(sortedD)

        for _, DName in ipairs(sortedD) do
            ScrollListD:addItem(DName, nil)
        end
    end

-- Export Function --
    function MapModManagerLabel.exportSelected()
        local file = getFileWriter("path/mapmodmanager.txt", true, false)
        file:write("This was generated using the Map Mod Manager. Be mindful of load orders, you may need to rearrange maps that overlap each other.\n\n")
        file:write("Maps selected:\n")
        
        local workshopIDsSet = {}
        local modIDsSet = {}
        local mapFoldersSet = {}
        
        local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
        if gridPanel then
            for mapName, _ in pairs(gridPanel.selectedMaps) do
                if not string.find(mapName, "Vanilla:") then
                    local mapData = MapModManagerLabel.MergedMapList[mapName]
                    if mapData then
                        file:write(string.format("%s (%s)\n", mapName, mapData.url or "N/A"))
                        if mapData.workshopID and mapData.workshopID ~= "N/A" then
                            workshopIDsSet[mapData.workshopID] = true
                        end
                        if mapData.modID and mapData.modID ~= "N/A" then
                            modIDsSet[mapData.modID] = true
                        end
                        if mapData.mapFolder and mapData.mapFolder ~= "N/A" then
                            mapFoldersSet[mapData.mapFolder] = true
                        end
                    end
                end
            end
        end

        file:write("\nDependencies required:\n")
        local dependenciesSet = {}
        if gridPanel then
            for mapName, _ in pairs(gridPanel.selectedMaps) do
                local mapData = MapModManagerLabel.MergedMapList[mapName]
                if mapData and mapData.dependencies then
                    for _, dependency in ipairs(mapData.dependencies) do
                        local workshopID = dependency:match("id=(%d+)")
                        if workshopID then
                            for depName, depData in pairs(MapModManagerLabel.MergedDependencyList) do
                                if depData.workshopID == workshopID then
                                    dependenciesSet[depName] = depData.url or "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. workshopID
                                    if depData.workshopID and depData.workshopID ~= "N/A" then
                                        workshopIDsSet[depData.workshopID] = true
                                    end
                                    if depData.modID and depData.modID ~= "N/A" then
                                        modIDsSet[depData.modID] = true
                                    end
                                    if depData.MapFolder and depData.MapFolder ~= "N/A" then
                                        mapFoldersSet[depData.MapFolder] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        for depName, url in pairs(dependenciesSet) do
            file:write(string.format("%s (%s)\n", depName, url))
        end

        local workshopIDs = {}
        for id, _ in pairs(workshopIDsSet) do
            table.insert(workshopIDs, id)
        end

        local modIDs = {}
        for id, _ in pairs(modIDsSet) do
            table.insert(modIDs, id)
        end

        local mapFolders = {}
        for folder, _ in pairs(mapFoldersSet) do
            table.insert(mapFolders, folder)
        end

        file:write("\nWorkshop ID: " .. table.concat(workshopIDs, ";") .. "\n")
        file:write("ModID: " .. table.concat(modIDs, ";") .. "\n")
        local mapFolderStr = table.concat(mapFolders, ";")
        if mapFolderStr ~= "" then
            file:write("MapFolder: " .. mapFolderStr .. "Muldraugh, KY\n")
        else
            file:write("MapFolder: Muldraugh, KY\n")
        end
        file:close()
    end

-- Grid --
    MapModManager_UI = ISPanel:derive("MapModManager_UI")

    function MapModManager_UI:new(x, y, width, height)
        local o = ISPanel.new(self, x, y, width, height)
        o.isGridExpanded = false
        o.selectedMaps = {}
        o.tooltip = nil
        o:initialise()
        o:instantiate()
        return o
    end

    -- Mouse position for tooltips
        function MapModManager_UI:isMouseOverCell(cellX, cellY, cellSize)
            local mouseX = getMouseX()
            local mouseY = getMouseY()
            local absX   = self:getAbsoluteX()
            local absY   = self:getAbsoluteY()
            
            local globalCellX1 = absX + cellX
            local globalCellY1 = absY + cellY
            local globalCellX2 = globalCellX1 + cellSize
            local globalCellY2 = globalCellY1 + cellSize
            
            return (mouseX >= globalCellX1 and mouseX <= globalCellX2
                and mouseY >= globalCellY1 and mouseY <= globalCellY2)
        end

    -- Render
        function MapModManager_UI:render()
            ISPanel.render(self)
            self:renderOverlay()
            self:renderTooltip()
        end

        function MapModManager_UI:renderOverlay()
            local gridRows      = 64
            local gridCols      = 64
            local paddingTop    = 10
            local paddingBottom = 10
            local availableHeight = self.height - paddingTop - paddingBottom
            local availableWidth

            if self.isGridExpanded then
                local aspectRatio = gridCols / gridRows
                availableWidth = availableHeight * aspectRatio
            else
                availableWidth = self.width - 50
            end

            local cellSize   = math.min(availableWidth / gridCols, availableHeight / gridRows)
            local gridWidth  = cellSize * gridCols
            local gridHeight = cellSize * gridRows

            local gridStartX = (self.width - gridWidth) / 2
            local gridStartY = paddingTop

            self.tooltip = nil

            -- Grid background
                self:drawRect(gridStartX, gridStartY, gridWidth, gridHeight, 0.6, 0, 0, 0)

            -- Prepare cellTooltips table
                local cellTooltips = {}

                for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
                    if self.selectedMaps[mapName] and mapData.cells then
                        for _, cellData in ipairs(mapData.cells) do
                            local row = cellData.row
                            local col = cellData.col
                            local cellKey = row .. "_" .. col
                            if not cellTooltips[cellKey] then
                                cellTooltips[cellKey] = { color = {0.5, 0, 0.5}, tooltips = {} }
                            end
                            table.insert(cellTooltips[cellKey].tooltips, mapName)
                            
                            if mapName:find("Ohio River") then
                                cellTooltips[cellKey].color = {0, 0, 1}  -- blue
                            elseif mapName:find("Vanilla:") then
                                cellTooltips[cellKey].color = {0, 1, 0}  -- green
                            else
                                if #cellTooltips[cellKey].tooltips > 1 then
                                    local hasVanillaConflict = false
                                    local nonVanillaCount = 0
                                    for _, conflictName in ipairs(cellTooltips[cellKey].tooltips) do
                                        if conflictName:find("Vanilla:") then
                                            hasVanillaConflict = true
                                        else
                                            nonVanillaCount = nonVanillaCount + 1
                                        end
                                    end
                                    if hasVanillaConflict and nonVanillaCount > 1 then
                                        cellTooltips[cellKey].color = {1, 0, 0}  -- red
                                    elseif hasVanillaConflict then
                                        cellTooltips[cellKey].color = {1, 1, 0}  -- yellow
                                    elseif nonVanillaCount > 1 then
                                        cellTooltips[cellKey].color = {1, 0, 0}  -- red
                                    end
                                end
                            end
                        end
                    end
                end

        -- Draw grid cell borders
            for r = 0, gridRows - 1 do
                for c = 0, gridCols - 1 do
                    local cellX = gridStartX + (r * cellSize)
                    local cellY = gridStartY + (c * cellSize)
                    self:drawRectBorder(cellX, cellY, cellSize, cellSize, 0.5, 0.75, 0.75, 0.75)
                end
            end

        -- Header row / column
            for row = 0, gridRows - 1 do
                for col = 0, gridCols - 1 do
                    if row == 0 or col == 0 then
                        local cellX = gridStartX + (row * cellSize)
                        local cellY = gridStartY + (col * cellSize)
                        self:drawRect(cellX, cellY, cellSize, cellSize, 1, 0.8, 0.8, 0.8)

                        local labelText = ""
                        if row == 0 and col == 0 then
                        elseif row == 0 then
                            labelText = tostring(col - 1)
                        elseif col == 0 then
                            labelText = tostring(row - 1)
                        end

                        if labelText ~= "" then
                            local textW = getTextManager():MeasureStringX(UIFont.VerySmall, labelText)
                            local textH = getTextManager():MeasureStringY(UIFont.VerySmall, labelText)
                            local textX = cellX + (cellSize - textW) / 2
                            local textY = cellY + (cellSize - textH) / 2 - 8
                            self:drawText(labelText, textX, textY, 0, 0, 0, 1, UIFont.VerySmall)
                        end
                    end
                end
            end

        -- Draw highlights
            for cellKey, cellInfo in pairs(cellTooltips) do
                local r, c = cellKey:match("(%d+)_(%d+)")
                r = tonumber(r)
                c = tonumber(c)
                if r and c then
                    local cellX = gridStartX + ((r + 1) * cellSize)
                    local cellY = gridStartY + ((c + 1) * cellSize)
                    self:drawRect(cellX, cellY, cellSize, cellSize, 0.5,
                                cellInfo.color[1], cellInfo.color[2], cellInfo.color[3])
                    
                    if self:isMouseOverCell(cellX, cellY, cellSize) then
                        local modList = table.concat(cellInfo.tooltips, "\n")
                        local tooltipText = "Cell " .. r .. "x" .. c .. "\n" .. modList
                        tooltipText = tooltipText:gsub("%s+$", "")
                        local lineCount = 0
                        for _ in tooltipText:gmatch("[^\n]+") do lineCount = lineCount + 1 end
                        local lineHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
                        local tooltipWidth = getTextManager():MeasureStringX(UIFont.Small, tooltipText) + 10
                        local tooltipHeight = (lineCount * lineHeight) + 10

                        local cursorX = getMouseX()
                        local cursorY = getMouseY()
                        local tooltipOffsetX = -480
                        local tooltipOffsetY = 20
                        self.tooltip = {
                            x = cursorX + tooltipOffsetX,
                            y = cursorY + tooltipOffsetY,
                            width = tooltipWidth,
                            height = tooltipHeight,
                            text = tooltipText
                        }
                    end
                end
            end

    -- Tooltip
        function MapModManager_UI:renderTooltip()
            if self.tooltip then
                self:drawRect(self.tooltip.x, self.tooltip.y, self.tooltip.width, self.tooltip.height, 1, 0, 0, 0)
                self:drawRectBorder(self.tooltip.x, self.tooltip.y, self.tooltip.width, self.tooltip.height, 1, 1, 1, 1)
                local lineHeight = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
                local offsetY = 5
                for line in self.tooltip.text:gmatch("[^\n]+") do
                    self:drawText(line, self.tooltip.x + 5, self.tooltip.y + offsetY, 1, 1, 1, 1, UIFont.Small)
                    offsetY = offsetY + lineHeight
                    end
                end
            end
        end

-- Main Menu --
    function MapModManagerLabel.addLabel()
        local mainScreen = MainScreen.instance
        local bottomPanel = mainScreen.bottomPanel
        local quitLabel = mainScreen.exitOption

        local MMMLabelY = quitLabel:getY() + quitLabel:getHeight() + 16
        local MMMLabelX = quitLabel:getX()

        local displayText = getText("UI_MapModManager")

        local mapModManagerLabel = ISLabel:new(
            MMMLabelX,
            MMMLabelY,
            quitLabel:getHeight(),
            displayText,
            1, 1, 1, 1,
            UIFont.Large,
            true
        )
        mapModManagerLabel.internal = "MAPMODMANAGER"
        mapModManagerLabel:initialise()

        mapModManagerLabel.onMouseDown = function(self, x, y)
            if self.internal == "MAPMODMANAGER" then
                MapModManagerLabel.openMainUI()
            else
                MainScreen.onMenuItemMouseDownMainMenu(self, x, y)
            end
        end

        bottomPanel:addChild(mapModManagerLabel)
        bottomPanel:setHeight(MMMLabelY + mapModManagerLabel:getHeight())

        mapModManagerLabel.fade = UITransition.new()
        mapModManagerLabel.fade:setFadeIn(false)

        mapModManagerLabel.prerender = function(self)
            if self.fade then self.fade:update() end
            local alpha = self.fade and self.fade:fraction() * 0.5 or 0
            local r, g, b = 0.3, 0.3, 0.3
            if alpha > 0 then
                self:drawRect(-5, 0, self:getWidth() + 12, self:getHeight(), alpha, r, g, b)
            end
            ISLabel.prerender(self)
        end

        mainScreen.mapModManagerOption = mapModManagerLabel
    end

-- Main UI --
    function MapModManagerLabel.openMainUI()
        local mainScreen = MainScreen.instance
        MapModManagerLabel.getActiveMods()

        for modID, _ in pairs(MapModManagerLabel.originalTempModList) do
        end

        local bottomPanel = mainScreen.bottomPanel
        if bottomPanel then bottomPanel:setVisible(false) end

        local screenWidth  = mainScreen:getWidth()
        local screenHeight = mainScreen:getHeight()

        local sdPanelWidth = screenWidth * 0.2
        local gPanelWidth  = screenWidth * 0.6
        local aPanelWidth  = screenWidth * 0.2
        local panelHeight  = screenHeight

    -- SD Panel (Subscribed / Dependencies)
        local SD_Panel = ISPanel:new(0, 0, sdPanelWidth, panelHeight)
        SD_Panel:initialise()
        SD_Panel:setVisible(true)
        SD_Panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
        mainScreen:addChild(SD_Panel)
        mainScreen.SD_Panel = SD_Panel

    -- G Panel (Grid)
        local G_Panel = ISPanel:new(sdPanelWidth, 0, gPanelWidth, panelHeight)
        G_Panel:initialise()
        G_Panel:setVisible(true)
        G_Panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
        mainScreen:addChild(G_Panel)
        mainScreen.G_Panel = G_Panel

        local gridPanelWidth  = G_Panel:getWidth()
        local gridPanelHeight = G_Panel:getHeight()
        local gridPanel = MapModManager_UI:new(0, 0, gridPanelWidth, gridPanelHeight)
        G_Panel:addChild(gridPanel)
        mainScreen.gridPanel = gridPanel

    -- A Panel (All Map Mods)
        local A_Panel = ISPanel:new(sdPanelWidth + gPanelWidth, 0, aPanelWidth, panelHeight)
        A_Panel:initialise()
        A_Panel:setVisible(true)
        A_Panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
        mainScreen:addChild(A_Panel)
        mainScreen.A_Panel = A_Panel

    -- Preset Button Width / Height
        local Button_Width  = 95
        local Button_Height = 23

    -- Default select all vanilla maps
        for mapName, _ in pairs(MapModManagerLabel.MergedMapList) do
            if mapName:find("^Vanilla:") then
                mainScreen.gridPanel.selectedMaps[mapName] = true
            end
        end

    -- A Panel --
        -- Accept Button
            local acceptButtonX = A_Panel:getWidth() - Button_Width - 10
            local acceptButtonY = 10

            local acceptButton = ISButton:new(
                acceptButtonX,
                acceptButtonY,
                Button_Width,
                Button_Height,
                getText("UI_acceptButton"),
                self,
                MapModManagerLabel.applyChanges
            )
            acceptButton:initialise()
            acceptButton:instantiate()
            acceptButton.backgroundColor = { r = 0, g = 63/255, b = 0, a = 1 }
            acceptButton.borderColor     = { r = 0, g = 1, b = 0, a = 1 }
            acceptButton.tooltip = getText("UI_acceptButtonTooltip")
            A_Panel:addChild(acceptButton)
            mainScreen.MapModManager_acceptButton = acceptButton

        -- Help Button
            local helpButtonX = acceptButtonX - Button_Width - 10
            local helpButtonY = acceptButtonY

            local helpButton = ISButton:new(
                helpButtonX,
                helpButtonY,
                Button_Width,
                Button_Height,
                getText("UI_helpButton"),
                self,
                MapModManagerLabel.openHelpPanel
            )
            helpButton:initialise()
            helpButton:instantiate()
            A_Panel:addChild(helpButton)
            mainScreen.MapModManager_helpButton = helpButton

        -- Text Label: All Map Mods
            local allMapModsLabel = ISLabel:new(
                0,
                acceptButtonY + Button_Height + 10,
                40,
                getText("UI_allMapModsLabel"),
                1, 1, 1, 1,
                UIFont.Medium,
                false
            )
            allMapModsLabel:initialise()
            allMapModsLabel:instantiate()
            allMapModsLabel:setWidth(A_Panel:getWidth() - 20)
            allMapModsLabel:setX((A_Panel:getWidth() - allMapModsLabel:getWidth()) / 2)
            allMapModsLabel.prerender = function(self)
                self:drawRect(0, 0, self:getWidth(), self:getHeight(), 0.6, 0, 0, 0)
                local text = getText("UI_allMapModsLabel")
                local textWidth  = getTextManager():MeasureStringX(UIFont.Medium, text)
                local textHeight = getTextManager():MeasureStringY(UIFont.Medium, text)
                local textX = (self:getWidth() - textWidth) / 2
                local textY = (self:getHeight() - textHeight) / 2
                self:drawText(text, textX, textY, 1, 1, 1, 1, UIFont.Medium)
            end
            A_Panel:addChild(allMapModsLabel)
            mainScreen.MapModManager_allMapModsLabel = allMapModsLabel

        -- Search Bar
            local scrollListWidth = A_Panel:getWidth() - 20
            local searchBarWidth  = scrollListWidth - Button_Width - 15
            local searchBarHeight = 25
            local searchBarX      = 10
            local searchBarY      = allMapModsLabel:getY() + allMapModsLabel:getHeight() + 10

            local searchBar = ISTextEntryBox:new("", searchBarX, searchBarY, searchBarWidth, searchBarHeight)
            searchBar:initialise()
            searchBar:instantiate()
            searchBar:setClearButton(true)
            A_Panel:addChild(searchBar)
            mainScreen.MapModManager_searchBar = searchBar

            searchBar.onTextChange = function(self)
                MapModManagerLabel.currentPage = 1
                MapModManagerLabel.populateScrollListA(MapModManagerLabel.currentPage)
            end

        -- Clear Button
            local clearButtonX = searchBarX + searchBarWidth + 15
            local clearButtonY = searchBarY

            local clearButton = ISButton:new(
                clearButtonX,
                clearButtonY,
                Button_Width,
                Button_Height,
                getText("UI_ClearButton"),
                self,
                function()
                    if mainScreen.MapModManager_searchBar then
                        mainScreen.MapModManager_searchBar:setText("")
                    end
                    MapModManagerLabel.currentPage = 1
                    MapModManagerLabel.populateScrollListA(1)
                end
            )
            clearButton:initialise()
            clearButton:instantiate()
            A_Panel:addChild(clearButton)
            mainScreen.MapModManager_clearButton = clearButton

            local buttonPadding = 15
            local numButtons = 3
            local totalSpacing = (numButtons - 1) * buttonPadding
            local buttonWidth = (scrollListWidth - totalSpacing) / numButtons
            local buttonHeight = Button_Height
            local buttonRowY = clearButtonY + Button_Height + 10

        -- Select Vanilla Maps
            function MapModManagerLabel.selectVanillaMaps()
                local mainScreen = MainScreen.instance
                local gridPanel = mainScreen and mainScreen.gridPanel
                if not gridPanel then return end
                for mapName, _ in pairs(MapModManagerLabel.MergedMapList) do
                    if mapName:find("^Vanilla:") then
                        gridPanel.selectedMaps[mapName] = true
                    else
                        gridPanel.selectedMaps[mapName] = nil
                    end
                end
                if gridPanel.updateDependencies then
                    gridPanel:updateDependencies()
                end
                MapModManagerLabel.populateScrollListD()
            end
    
            local vanillaButtonX = searchBarX
            local selectVanillaButton = ISButton:new(
                vanillaButtonX,
                buttonRowY,
                buttonWidth,
                buttonHeight,
                getText("UI_SelectVanillaMaps"),
                self,
                MapModManagerLabel.selectVanillaMaps
            )
            selectVanillaButton:initialise()
            selectVanillaButton:instantiate()
            selectVanillaButton.tooltip = getText("UI_SelectVanillaMapsTooltip")
            A_Panel:addChild(selectVanillaButton)
            mainScreen.MapModManager_selectVanillaMapsButton = selectVanillaButton

        -- Unselect Maps
            function MapModManagerLabel.unselectAllMaps()
                local mainScreen = MainScreen.instance
                local gridPanel = mainScreen and mainScreen.gridPanel
                if not gridPanel then return end
                for mapName, _ in pairs(MapModManagerLabel.MergedMapList) do
                    gridPanel.selectedMaps[mapName] = nil
                end
                if gridPanel.updateDependencies then
                    gridPanel:updateDependencies()
                end
                MapModManagerLabel.populateScrollListD()
            end
    
            local unselectButtonX = vanillaButtonX + buttonWidth + buttonPadding
            local unselectButton = ISButton:new(
                unselectButtonX,
                buttonRowY,
                buttonWidth,
                buttonHeight,
                getText("UI_UnselectAllMaps"),
                self,
                MapModManagerLabel.unselectAllMaps
            )
            unselectButton:initialise()
            unselectButton:instantiate()
            unselectButton.tooltip = getText("UI_UnselectAllMapsTooltip")
            A_Panel:addChild(unselectButton)
            mainScreen.MapModManager_unselectAllMapsButton = unselectButton

        -- Find Maps
            function MapModManagerLabel.findNonConflictingMaps()
                local mainScreen = MainScreen.instance
                local gridPanel = mainScreen and mainScreen.gridPanel
                if not gridPanel then return end

                local merged = MapModManagerLabel.MergedMapList
                if not merged then return end

                -- Start with only vanilla maps selected
                local selected = {}
                for name, _ in pairs(gridPanel.selectedMaps) do
                    selected[name] = true
                end

                local candidateMaps = {}
                for mapName, mapData in pairs(merged) do
                    if not mapName:find("^Vanilla:") and not selected[mapName] then
                        table.insert(candidateMaps, mapName)
                    end
                end

                for _, mapName in ipairs(candidateMaps) do
                    local mapData = merged[mapName]
                    local conflicts = mapData.conflicts or {}
                    local conflictFound = false
                    for _, conflictName in ipairs(conflicts) do
                        if selected[conflictName] then
                            conflictFound = true
                            break
                        end
                    end
                    if not conflictFound then
                        selected[mapName] = true
                    end
                end

                gridPanel.selectedMaps = selected

                if gridPanel.updateDependencies then
                    gridPanel:updateDependencies()
                end
                MapModManagerLabel.populateScrollListD()
            end
    
            local findButtonX = unselectButtonX + buttonWidth + buttonPadding
            local findButton = ISButton:new(
                findButtonX,
                buttonRowY,
                buttonWidth,
                buttonHeight,
                getText("UI_QuickSelect"),
                self,
                MapModManagerLabel.findNonConflictingMaps
            )
            findButton:initialise()
            findButton:instantiate()
            findButton.tooltip = getText("UI_QuickSelectTooltip")
            A_Panel:addChild(findButton)
            mainScreen.MapModManager_findNonConflictingMapsButton = findButton

        -- Filter Maps
            local numCols = 4
            local itemSpacing = 10
            local totalSpacing = itemSpacing * (numCols - 1)
            local itemWidth = (scrollListWidth - totalSpacing) / numCols
            local itemHeight = Button_Height

            local filterControlsY = buttonRowY + buttonHeight + 10

            -- Filter Row Dropdown
                local filterRowDropdown = ISComboBox:new(
                    searchBarX,
                    filterControlsY,
                    itemWidth,
                    itemHeight
                )
                filterRowDropdown:initialise()
                filterRowDropdown:instantiate()
                for i = 0, 62 do
                    filterRowDropdown:addOption(tostring(i))
                end
                filterRowDropdown.selected = 1
                A_Panel:addChild(filterRowDropdown)
                mainScreen.MapModManager_filterRowDropdown = filterRowDropdown

            -- Filter Col Dropdown
                local filterColDropdownX = searchBarX + itemWidth + itemSpacing
                local filterColDropdown = ISComboBox:new(
                    filterColDropdownX,
                    filterControlsY,
                    itemWidth,
                    itemHeight
                )
                filterColDropdown:initialise()
                filterColDropdown:instantiate()
                for i = 0, 62 do
                    filterColDropdown:addOption(tostring(i))
                end
                filterColDropdown.selected = 1
                A_Panel:addChild(filterColDropdown)
                mainScreen.MapModManager_filterColDropdown = filterColDropdown

            -- Filter Maps Button
                local filterMapsButtonX = filterColDropdownX + itemWidth + itemSpacing
                local filterMapsButton = ISButton:new(
                    filterMapsButtonX,
                    filterControlsY,
                    itemWidth,
                    itemHeight,
                    getText("UI_FilterMaps"),
                    self,
                    MapModManagerLabel.filterMaps
                )
                filterMapsButton:initialise()
                filterMapsButton:instantiate()
                filterMapsButton.tooltip = getText("UI_FilterMapsTooltip")
                A_Panel:addChild(filterMapsButton)
                mainScreen.MapModManager_filterMapsButton = filterMapsButton

            -- Clear Filter Button
                local clearFilterButtonX = filterMapsButtonX + itemWidth + itemSpacing
                local clearFilterButton = ISButton:new(
                    clearFilterButtonX,
                    filterControlsY,
                    itemWidth,
                    itemHeight,
                    getText("UI_ClearFilter"),
                    self,
                    MapModManagerLabel.clearFilter
                )
                clearFilterButton:initialise()
                clearFilterButton:instantiate()
                A_Panel:addChild(clearFilterButton)
                mainScreen.MapModManager_clearFilterButton = clearFilterButton

        -- Page Navigation Buttons
            local navPadding = 10
            local navButtonHeight = Button_Height
            local navButtonY = A_Panel:getHeight() - navPadding - navButtonHeight

            local prevButton = ISButton:new(
                10,
                navButtonY,
                Button_Width,
                navButtonHeight,
                getText("UI_prevButton"),
                self,
                function() MapModManagerLabel.goToPreviousPage() end
            )
            prevButton:initialise()
            prevButton:instantiate()
            A_Panel:addChild(prevButton)
            mainScreen.MapModManager_prevButton = prevButton

            local nextButtonX = scrollListWidth - Button_Width + 10
            local nextButton = ISButton:new(
                nextButtonX,
                navButtonY,
                Button_Width,
                navButtonHeight,
                getText("UI_nextButton"),
                self,
                function() MapModManagerLabel.goToNextPage() end
            )
            nextButton:initialise()
            nextButton:instantiate()
            A_Panel:addChild(nextButton)
            mainScreen.MapModManager_nextButton = nextButton

        -- Scroll List A
            function MapModManagerLabel.populateScrollListA(page)
                local mainScreen = MainScreen.instance
                local ScrollListA = mainScreen.MapModManager_ScrollList
                local prevButton = mainScreen.MapModManager_prevButton
                local nextButton = mainScreen.MapModManager_nextButton
                local searchBar  = mainScreen.MapModManager_searchBar

                local font = UIFont.Medium
                local itemHeight = getTextManager():MeasureStringY(font, "Test") + 18
                ScrollListA.itemheight = itemHeight
                local currentHeight = ScrollListA:getHeight()
                local mapsPerPage = math.floor(currentHeight / itemHeight)
                if mapsPerPage < 1 then mapsPerPage = 1 end
                local newHeight = mapsPerPage * itemHeight
                ScrollListA:setHeight(newHeight)
                MapModManagerLabel.mapsPerPage = mapsPerPage

                ScrollListA:clear()

                local searchQuery = searchBar and searchBar:getText() or ""
                searchQuery = searchQuery:lower()

                MapModManagerLabel.totalMaps = 0
                local filteredMaps = {}

                for mapName, _ in pairs(MapModManagerLabel.MergedMapList) do
                    if mapName:lower():find(searchQuery) then
                        MapModManagerLabel.totalMaps = MapModManagerLabel.totalMaps + 1
                        table.insert(filteredMaps, mapName)
                    end
                end

                local vanillaMaps = {}
                local otherMaps   = {}

                for _, mapName in ipairs(filteredMaps) do
                    if mapName:find("^Vanilla:") then
                        table.insert(vanillaMaps, mapName)
                    else
                        table.insert(otherMaps, mapName)
                    end
                end

                table.sort(otherMaps, function(a, b) return a:lower() < b:lower() end)

                local allMaps = {}
                for _, mapName in ipairs(vanillaMaps) do table.insert(allMaps, mapName) end
                for _, mapName in ipairs(otherMaps) do table.insert(allMaps, mapName) end

                MapModManagerLabel.totalPages = math.ceil(MapModManagerLabel.totalMaps / MapModManagerLabel.mapsPerPage)

                if page < 1 then page = 1
                elseif page > MapModManagerLabel.totalPages then page = MapModManagerLabel.totalPages end

                MapModManagerLabel.currentPage = page

                local startIndex = (MapModManagerLabel.currentPage - 1) * MapModManagerLabel.mapsPerPage + 1
                local endIndex   = startIndex + MapModManagerLabel.mapsPerPage - 1

                for i = startIndex, math.min(endIndex, #allMaps) do
                    ScrollListA:addItem(allMaps[i], nil)
                end

                if prevButton then prevButton:setEnable(MapModManagerLabel.currentPage > 1) end
                if nextButton then nextButton:setEnable(MapModManagerLabel.currentPage < MapModManagerLabel.totalPages) end

                -- Steam logo
                    ScrollListA.doDrawItem = function(self, y, item, alt)
                        local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
                    
                        if not item or not item.text then return y + self.itemheight end
                    
                        local mapData = MapModManagerLabel.MergedMapList[item.text]
                        if not mapData then
                            return y + self.itemheight
                        end
                    
                        if gridPanel and gridPanel.selectedMaps[item.text] then
                            self:drawRect(0, y, self:getWidth(), self.itemheight, 0.2, 0.8, 0.8, 0.8)
                        end
                    
                        self:drawText(
                            item.text,
                            10,
                            y + (self.itemheight - getTextManager():MeasureStringY(UIFont.Medium, item.text)) / 2,
                            1, 1, 1, 1,
                            UIFont.Medium
                        )
                    
                        if not item.text:match("^Vanilla:") then
                            local logoX = self:getWidth() - 25
                            local logoY = y + (self.itemheight - 20) / 2
                            self:drawTexture(getTexture("media/textures/steamlogo20x20.png"), logoX, logoY, 1, 1, 1, 1)
                            item.logoX = logoX
                            item.logoY = logoY
                            item.logoWidth = 20
                            item.logoHeight = 20
                        else
                            item.logoX, item.logoY, item.logoWidth, item.logoHeight = nil, nil, nil, nil
                        end
                    
                        return y + self.itemheight
                    end

                -- Navigate to workshop
                    ScrollListA.onMouseDown = function(self, x, y)
                        local idx = self:rowAt(x, y)
                        if idx and idx >= 1 and idx <= #self.items then
                            local item = self.items[idx]
                            if item then
                                if item.logoX and item.logoY and item.logoWidth and item.logoHeight then
                                    if x >= item.logoX and x <= item.logoX + item.logoWidth
                                    and y >= item.logoY and y <= item.logoY + item.logoHeight then
                                        local mapData = MapModManagerLabel.MergedMapList[item.text]
                                        if mapData and mapData.workshopID then
                                            local steamURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. mapData.workshopID
                                            openUrl(steamURL)
                                        end
                                        return
                                    end
                                end
                                local mapName = item.text
                                local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
                                if gridPanel then
                                    if gridPanel.selectedMaps[mapName] then
                                        gridPanel.selectedMaps[mapName] = nil
                                    else
                                        gridPanel.selectedMaps[mapName] = true
                                    end
                                    self.selected = idx
                                    if gridPanel.updateDependencies then
                                        gridPanel:updateDependencies()
                                    end

                                    MapModManagerLabel.populateScrollListD()
                                end
                            end
                        end
                    end

                local function calculateMapsPerPage()
                    local font = UIFont.Medium
                    local sampleText = "Test"
                    local textHeight = getTextManager():MeasureStringY(font, sampleText)
                    local extraPadding = 10
                    local itemHeight = textHeight + extraPadding
                    MapModManagerLabel.mapsPerPage = math.floor(ScrollListA:getHeight() / itemHeight)
                    if MapModManagerLabel.mapsPerPage < 1 then
                        MapModManagerLabel.mapsPerPage = 1
                    end
                end
                calculateMapsPerPage()
            end

            function MapModManagerLabel.goToPreviousPage()
                if MapModManagerLabel.currentPage > 1 then
                    MapModManagerLabel.populateScrollListA(MapModManagerLabel.currentPage - 1)
                end
            end

            function MapModManagerLabel.goToNextPage()
                if MapModManagerLabel.currentPage < MapModManagerLabel.totalPages then
                    MapModManagerLabel.populateScrollListA(MapModManagerLabel.currentPage + 1)
                end
            end

            local scrollListX = 10
            local scrollListY = filterControlsY + Button_Height + 10
            local navButtonY_A = A_Panel:getHeight() - navPadding - navButtonHeight
            local scrollListHeight = navButtonY_A - scrollListY

            local ScrollListA = ISScrollingListBox:new(scrollListX, scrollListY, scrollListWidth, scrollListHeight)
            ScrollListA:initialise()
            ScrollListA:instantiate()
            A_Panel:addChild(ScrollListA)
            mainScreen.MapModManager_ScrollList = ScrollListA

            ScrollListA.doDrawItem = function(self, y, item, alt)
                local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
                if gridPanel and gridPanel.selectedMaps[item.text] then
                    self:drawRect(0, y, self:getWidth(), self.itemheight, 0.2, 0.8, 0.8, 0.8)
                end
                self:drawText(item.text, 10, y + (self.itemheight - getTextManager():MeasureStringY(UIFont.Medium, item.text)) / 2,
                            1, 1, 1, 1, UIFont.Medium)
                return y + self.itemheight
            end

                ScrollListA.onMouseDown = function(self, x, y)
                    local idx = self:rowAt(x, y)
                    if idx and idx >= 1 and idx <= #self.items then
                        local item = self.items[idx]
                        local mapName = item.text
                        local gridPanel = MainScreen.instance and MainScreen.instance.gridPanel
                        if gridPanel then
                            if gridPanel.selectedMaps[mapName] then
                                gridPanel.selectedMaps[mapName] = nil
                            else
                                gridPanel.selectedMaps[mapName] = true
                            end
                            self.selected = idx
                            if gridPanel.updateDependencies then
                                gridPanel:updateDependencies()
                            end
                            MapModManagerLabel.populateScrollListD()
                        end
                    end
                end

                local function calculateMapsPerPage_A()
                    local font = UIFont.Medium
                    local sampleText = "Test"
                    local textHeight = getTextManager():MeasureStringY(font, sampleText)
                    local extraPadding = 10
                    local itemHeight = textHeight + extraPadding
                    MapModManagerLabel.mapsPerPage = math.floor(ScrollListA:getHeight() / itemHeight)
                    if MapModManagerLabel.mapsPerPage < 1 then
                        MapModManagerLabel.mapsPerPage = 1
                    end
                end
                calculateMapsPerPage_A()
                MapModManagerLabel.populateScrollListA(MapModManagerLabel.currentPage)

    -- SD Panel --
        -- Back Button
            local SD_backX = 10
            local SD_backY = 10

            local backButtonSD = ISButton:new(
                SD_backX,
                SD_backY,
                Button_Width,
                Button_Height,
                getText("UI_BackButton"),
                self,
                MapModManagerLabel.Back
            )
            backButtonSD:initialise()
            backButtonSD:instantiate()
            backButtonSD.backgroundColor = { r = 63/255, g = 0, b = 0, a = 1 }
            backButtonSD.borderColor     = { r = 1, g = 0, b = 0, a = 1 }
            backButtonSD.tooltip = getText("UI_backButtonTooltip")
            SD_Panel:addChild(backButtonSD)
            mainScreen.MapModManager_BackButton_SD = backButtonSD

        -- Text Label: Subscribed Map Mods
            local subscribedMapModsLabel = ISLabel:new(
                0,
                SD_backY + Button_Height + 10,
                40,
                getText("UI_subscribedMapModsLabel"),
                1, 1, 1, 1,
                UIFont.Medium,
                false
            )
            subscribedMapModsLabel:initialise()
            subscribedMapModsLabel:instantiate()
            subscribedMapModsLabel:setWidth(SD_Panel:getWidth() - 20)
            subscribedMapModsLabel:setX((SD_Panel:getWidth() - subscribedMapModsLabel:getWidth()) / 2)
            subscribedMapModsLabel.prerender = function(self)
                self:drawRect(0, 0, self:getWidth(), self:getHeight(), 0.6, 0, 0, 0)
                local text = getText("UI_subscribedMapModsLabel")
                local textWidth  = getTextManager():MeasureStringX(UIFont.Medium, text)
                local textHeight = getTextManager():MeasureStringY(UIFont.Medium, text)
                local textX = (self:getWidth() - textWidth) / 2
                local textY = (self:getHeight() - textHeight) / 2
                self:drawText(text, textX, textY, 1, 1, 1, 1, UIFont.Medium)
            end
            SD_Panel:addChild(subscribedMapModsLabel)
            mainScreen.MapModManager_subscribedMapModsLabel = subscribedMapModsLabel

        -- Select Buttons
            local numButtons = 3
            local sdMargin = 10
            local gap = 10
            local availableSDWidth = SD_Panel:getWidth() - 2 * sdMargin
            local newButtonWidth = (availableSDWidth - (numButtons - 1) * gap) / numButtons
            local sdButtonsY = subscribedMapModsLabel:getY() + subscribedMapModsLabel:getHeight() + 10

        -- Select All Subscribed Button
            local selectAllSubscribedButton
            selectAllSubscribedButton = ISButton:new(
                sdMargin,
                sdButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_SelectAllSubscribed"),
                nil,

            function()
                local currentTitle     = selectAllSubscribedButton.title
                local selectAllText    = getText("UI_SelectAllSubscribed")
                local unselectAllText  = getText("UI_UnselectAllSubscribed")

                local mainScreen  = MainScreen.instance
                local sScrollList = mainScreen.MapModManager_SScrollList
                if not sScrollList then return end

                local gridPanel = mainScreen.gridPanel
                if not gridPanel then return end

                -- Select all
                    if currentTitle == selectAllText then

                        for i = 1, #sScrollList.items do
                            local item = sScrollList.items[i]
                            gridPanel.selectedMaps[item.text] = true
                        end
                        selectAllSubscribedButton:setTitle(unselectAllText)

                else

                -- Unselect all
                        for i = 1, #sScrollList.items do
                            local item = sScrollList.items[i]
                            gridPanel.selectedMaps[item.text] = nil
                        end
                        selectAllSubscribedButton:setTitle(selectAllText)
                    end

                if gridPanel.updateDependencies then
                    gridPanel:updateDependencies()
                end

                MapModManagerLabel.populateScrollListD()
                end)
            
            selectAllSubscribedButton:initialise()
            selectAllSubscribedButton:instantiate()
            selectAllSubscribedButton.tooltip = getText("UI_SelectAllSubscribedTooltip")
            SD_Panel:addChild(selectAllSubscribedButton)

        -- Select All Active Button
            local selectAllActiveButton
            selectAllActiveButton = ISButton:new(
                sdMargin + newButtonWidth + gap,
                sdButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_SelectAllActive"),
                nil,
                function()

                    local function checkActiveMods()
                        for modID, isActive in pairs(tempModList) do
                            if isActive then
                                return true
                            end
                        end
                        return false
                    end

                    local mainScreen  = MainScreen.instance
                    local sScrollList = mainScreen.MapModManager_SScrollList
                    if not sScrollList then return end

                    local gridPanel = mainScreen.gridPanel
                    if not gridPanel then return end

                        if not checkActiveMods() then
                            return
                        end

                    local currentTitle    = selectAllActiveButton.title
                    local selectAllText   = getText("UI_SelectAllActive")
                    local unselectAllText = getText("UI_UnselectAllActive")

                    -- Select all
                        if currentTitle == selectAllText then
                            for i = 1, #sScrollList.items do
                                local item    = sScrollList.items[i]
                                local mapName = item.text
                                local mapData = MapModManagerLabel.MergedMapList[mapName]
                                if mapData and tempModList[mapData.modID] then
                                    gridPanel.selectedMaps[mapName] = true
                                end
                            end
                            selectAllActiveButton:setTitle(unselectAllText)

                    else

                        -- Unselect all
                            for i = 1, #sScrollList.items do
                                local item    = sScrollList.items[i]
                                local mapName = item.text
                                local mapData = MapModManagerLabel.MergedMapList[mapName]
                                if mapData and tempModList[mapData.modID] then
                                    gridPanel.selectedMaps[mapName] = nil
                                end
                            end
                            selectAllActiveButton:setTitle(selectAllText)
                    end

                    if gridPanel.updateDependencies then
                        gridPanel:updateDependencies()
                    end
                    MapModManagerLabel.populateScrollListD()
                end)

            selectAllActiveButton:initialise()
            selectAllActiveButton:instantiate()
            selectAllActiveButton.tooltip = getText("UI_SelectAllActiveTooltip")
            SD_Panel:addChild(selectAllActiveButton)

        -- Export Selected Button
            local exportSelectedButton = ISButton:new(
                sdMargin + 2*(newButtonWidth + gap),
                sdButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_ExportSelected"),
                self,
                function()
                    MapModManagerLabel.exportSelected()
                end
            )
            exportSelectedButton:initialise()
            exportSelectedButton:instantiate()
            exportSelectedButton.tooltip = getText("UI_ExportSelectedTooltip")
            SD_Panel:addChild(exportSelectedButton)


        -- Scroll List S
            local ScrollListSY = sdButtonsY + Button_Height + 10
            local ScrollListSWidth = SD_Panel:getWidth() - 20
            local ScrollListSHeight = SD_Panel:getHeight() * 0.5
            local ScrollListS = ISScrollingListBox:new(10, ScrollListSY, ScrollListSWidth, ScrollListSHeight)
            ScrollListS:initialise()
            ScrollListS:instantiate()
            SD_Panel:addChild(ScrollListS)
            mainScreen.MapModManager_SScrollList = ScrollListS

            setupSScrollListCallbacks()

            MapModManagerLabel.populateScrollListS()
            MapModManagerLabel.populateScrollListD()

        -- Toggle Buttons
            local numButtonsGroup2 = 3
            local sdGroup2Y = ScrollListSY + ScrollListSHeight + 10
            local newButtonWidthGroup2 = (availableSDWidth - (numButtonsGroup2 - 1) * gap) / numButtonsGroup2

        -- Toggle All Subscribed Button
            local toggleAllSubscribedButton
            toggleAllSubscribedButton = ISButton:new(
                sdMargin,
                sdGroup2Y,
                newButtonWidthGroup2,
                Button_Height,
                getText("UI_ToggleAllSubscribed"),
                nil,

                function()
                    local mainScreen  = MainScreen.instance
                    local sScrollList = mainScreen.MapModManager_SScrollList
                    local gridPanel   = mainScreen and mainScreen.gridPanel
                    if not sScrollList or not gridPanel then
                        return
                    end

                    local allOn = true
                    for i = 1, #sScrollList.items do
                        local item    = sScrollList.items[i]
                        local mapName = item.text
                        local mapData = MapModManagerLabel.MergedMapList[mapName]
                        local modID   = mapData and mapData.modID
                        if modID and not tempModList[modID] then
                            allOn = false
                            break
                        end
                    end

                    if allOn then
                        for i = 1, #sScrollList.items do
                            local item    = sScrollList.items[i]
                            local mapName = item.text
                            local mapData = MapModManagerLabel.MergedMapList[mapName]
                            local modID   = mapData and mapData.modID
                            if modID then
                                tempModList[modID] = false
                            end
                        end
                        toggleAllSubscribedButton:setTitle(getText("UI_ToggleAllSubscribed"))
                    else

                        for i = 1, #sScrollList.items do
                            local item    = sScrollList.items[i]
                            local mapName = item.text
                            local mapData = MapModManagerLabel.MergedMapList[mapName]
                            local modID   = mapData and mapData.modID
                            if modID then
                                tempModList[modID] = true
                            end
                        end
                        toggleAllSubscribedButton:setTitle(getText("UI_UnToggleAllSubscribed"))
                    end

                    if gridPanel.updateDependencies then
                        gridPanel:updateDependencies()
                    end
                    MapModManagerLabel.populateScrollListD()
                end)

            toggleAllSubscribedButton:initialise()
            toggleAllSubscribedButton:instantiate()
            toggleAllSubscribedButton.tooltip = getText("UI_ToggleAllSubscribedTooltip")
            SD_Panel:addChild(toggleAllSubscribedButton)

        -- Toggle All Selected Button
            local toggleAllSelectedButton = ISButton:new(
                sdMargin + newButtonWidthGroup2 + gap,
                sdGroup2Y,
                newButtonWidthGroup2,
                Button_Height,
                getText("UI_ToggleAllSelected"),
                nil,
                nil
            )

            toggleAllSelectedButton.onMouseDown = function(_, x, y)
                local mainScreen = MainScreen.instance
                local gridPanel = mainScreen and mainScreen.gridPanel
                if not gridPanel then return end

                local selectedMaps = {}
                for mapName, _ in pairs(gridPanel.selectedMaps) do
                    table.insert(selectedMaps, mapName)
                end

                if #selectedMaps == 0 then
                    return
                end

                local allOn = true
                for _, mapName in ipairs(selectedMaps) do
                    local mapData = MapModManagerLabel.MergedMapList[mapName]
                    local modID = mapData and mapData.modID
                    if modID and not tempModList[modID] then
                        allOn = false
                        break
                    end
                end

                if allOn then
                    for _, mapName in ipairs(selectedMaps) do
                        local mapData = MapModManagerLabel.MergedMapList[mapName]
                        local modID = mapData and mapData.modID
                        if modID then
                            tempModList[modID] = false
                        end
                    end
                    toggleAllSelectedButton:setTitle(getText("UI_ToggleAllSelected"))
                else
                    for _, mapName in ipairs(selectedMaps) do
                        local mapData = MapModManagerLabel.MergedMapList[mapName]
                        local modID = mapData and mapData.modID
                        if modID then
                            tempModList[modID] = true
                        end
                    end
                    toggleAllSelectedButton:setTitle(getText("UI_UnToggleAllSelected"))
                end

                if gridPanel.updateDependencies then
                    gridPanel:updateDependencies()
                end
                MapModManagerLabel.populateScrollListD()
            end

            toggleAllSelectedButton:initialise()
            toggleAllSelectedButton:instantiate()
            toggleAllSelectedButton.tooltip = getText("UI_ToggleAllSelectedTooltip")
            SD_Panel:addChild(toggleAllSelectedButton)

        -- Mod Load Order Button
            local modLoadOrderButton = ISButton:new(
                sdMargin + 2*(newButtonWidthGroup2 + gap),
                sdGroup2Y,
                newButtonWidthGroup2,
                Button_Height,
                getText("UI_ModLoadOrder"),
                self,
                function()
                    MapModManagerLabel.openMLPanel()
                end)
            modLoadOrderButton:initialise()
            modLoadOrderButton:instantiate()
            modLoadOrderButton.tooltip = getText("UI_ModLoadOrderTooltip")
            SD_Panel:addChild(modLoadOrderButton)

        -- Text Label: Dependencies
            local dependenciesLabelY = sdGroup2Y + Button_Height + 10
            local dependenciesLabel = ISLabel:new(
                0,
                dependenciesLabelY,
                40,
                getText("UI_Dependencies"),
                1, 1, 1, 1,
                UIFont.Medium,
                false
            )
            dependenciesLabel:initialise()
            dependenciesLabel:instantiate()
            dependenciesLabel:setWidth(SD_Panel:getWidth() - 20)
            dependenciesLabel:setX((SD_Panel:getWidth() - dependenciesLabel:getWidth()) / 2)
            dependenciesLabel.prerender = function(self)
                self:drawRect(0, 0, self:getWidth(), self:getHeight(), 0.6, 0, 0, 0)
                local text = getText("UI_Dependencies")
                local textWidth = getTextManager():MeasureStringX(UIFont.Medium, text)
                local textHeight = getTextManager():MeasureStringY(UIFont.Medium, text)
                local textX = (self:getWidth() - textWidth) / 2
                local textY = (self:getHeight() - textHeight) / 2
                self:drawText(text, textX, textY, 1, 1, 1, 1, UIFont.Medium)
            end
            SD_Panel:addChild(dependenciesLabel)

        -- Scroll List D
            local ScrollListDY     = dependenciesLabel:getY() + dependenciesLabel:getHeight() + 10
            local ScrollListDHeight = SD_Panel:getHeight() - ScrollListDY - 10
            local ScrollListDWidth  = SD_Panel:getWidth() - 20

            local ScrollListD = ISScrollingListBox:new(10, ScrollListDY, ScrollListDWidth, ScrollListDHeight)
            ScrollListD:initialise()
            ScrollListD:instantiate()

            ScrollListD.prerender = function(self)
                self.currentTooltip = nil
                ISScrollingListBox.prerender(self)
            end

            ScrollListD.doDrawItem = function(self, y, item, alt)
                local dependencyName = item.text
                local dependencyData = MapModManagerLabel.MergedDependencyList[dependencyName]
                local workshopID     = dependencyData and dependencyData.workshopID
                local modID          = dependencyData and dependencyData.modID

                local mainScreen = MainScreen.instance
                local gridPanel  = mainScreen and mainScreen.gridPanel

                local cache = MapModManagerLabel.subscribedModsCache or {}
                local isSubscribed = (workshopID and cache[tostring(workshopID)]) or false
                local isActive     = (modID and tempModList[modID] == true)

                -- Not active dependency: white
                    local textColor = { r = 1, g = 1, b = 1, a = 1 }
                
                -- Not subscribed depedency: red
                    if not isSubscribed then
                        textColor = { r = 1, g = 0, b = 0, a = 1 }
                
                -- Active depedency: green
                    elseif isActive then
                        textColor = { r = 102/255, g = 204/255, b = 76/255, a = 1 }
                    end

                -- Draw background
                    self:drawRect(0, y, self:getWidth(), self.itemheight, 1, 0, 0, 0)

                    local textX = 10
                    local textY = y + (self.itemheight - getTextManager():MeasureStringY(UIFont.Medium, dependencyName)) / 2
                    self:drawText(dependencyName, textX, textY, textColor.r, textColor.g, textColor.b, textColor.a, UIFont.Medium)

                -- Steam logo
                    local iconWidth  = 20
                    local iconHeight = 20
                    local iconX = self:getWidth() - (iconWidth + 70)
                    local iconY = y + (self.itemheight - iconHeight) / 2

                    if workshopID then
                        self:drawTexture(getTexture("media/textures/steamlogo20x20.png"), iconX, iconY, 1, 1, 1, 1)
                        item.logoX, item.logoY       = iconX, iconY
                        item.logoWidth, item.logoHeight = iconWidth, iconHeight
                    else
                        item.logoX, item.logoY, item.logoWidth, item.logoHeight = nil, nil, nil, nil
                    end
                
                -- On/Off button
                    local buttonLabel = isActive and getText("UI_On") or getText("UI_Off")
                    local buttonWidth, buttonHeight = 50, 20
                    local buttonX = self:getWidth() - (buttonWidth + 10)
                    local buttonY = y + (self.itemheight - buttonHeight) / 2

                    self:drawRect(buttonX, buttonY, buttonWidth, buttonHeight, 1, 0, 0, 0)
                    self:drawRectBorder(buttonX, buttonY, buttonWidth, buttonHeight, 1, 1, 1, 1)
                    self:drawTextCentre(buttonLabel, buttonX + buttonWidth / 2, buttonY + 3, 1, 1, 1, 1, UIFont.Small)

                    item.buttonX, item.buttonY = buttonX, buttonY
                    item.buttonWidth, item.buttonHeight = buttonWidth, buttonHeight

                -- Tooltip
                    local tooltipLines = {}

                    if workshopID then
                        local activeMaps = {}
                        for mapName, mData in pairs(MapModManager_DB) do
                            if mData and mData.modID and tempModList[mData.modID] then
                                if mData.dependencies then
                                    for _, depEntry in ipairs(mData.dependencies) do
                                        local depWSID = depEntry:match("id=(%d+)")
                                        if depWSID == workshopID then
                                            table.insert(activeMaps, mapName)
                                            break
                                        end
                                    end
                                end
                            end
                        end

                    local sScrollList = mainScreen.MapModManager_SScrollList
                    local selectedSubsSet = {}
                    if sScrollList then
                        for i = 1, #sScrollList.items do
                            local subItem = sScrollList.items[i]
                            selectedSubsSet[subItem.text] = true
                        end
                    end

                    local subscribedMaps = {}
                    local notSubscribedMaps = {}
                    local categorizedMaps = {}

                    if gridPanel then
                        for selectedMapName, _ in pairs(gridPanel.selectedMaps) do
                            local mData = MapModManagerLabel.MergedMapList[selectedMapName]
                            if mData and mData.dependencies then
                                for _, depEntry in ipairs(mData.dependencies) do
                                    local depWSID = depEntry:match("id=(%d+)")
                                    if depWSID == workshopID then
                                        if tempModList[mData.modID] then
                                            break -- Skip if already active
                                        end
                                        if not categorizedMaps[selectedMapName] then
                                            if selectedSubsSet[selectedMapName] then
                                                table.insert(subscribedMaps, selectedMapName)
                                            else
                                                table.insert(notSubscribedMaps, selectedMapName)
                                            end
                                            categorizedMaps[selectedMapName] = true
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end

                    -- Required by active maps
                        table.insert(tooltipLines, getText("UI_RequiredByActive"))
                        if #activeMaps > 0 then
                            for _, mapName in ipairs(activeMaps) do
                                table.insert(tooltipLines, mapName)
                            end
                        else
                            table.insert(tooltipLines,  getText("UI_None"))
                        end

                        table.insert(tooltipLines, "")

                    -- Required by subscribed maps
                        table.insert(tooltipLines, getText("UI_RequiredBySubscribed"))
                        if #subscribedMaps > 0 then
                            for _, mapName in ipairs(subscribedMaps) do
                                table.insert(tooltipLines, mapName)
                            end
                        else
                            table.insert(tooltipLines, getText("UI_None"))
                        end

                        table.insert(tooltipLines, "")

                    -- Required by not subscribed maps
                        table.insert(tooltipLines, getText("UI_RequiredByNotSubscribed"))
                        if #notSubscribedMaps > 0 then
                            for _, mapName in ipairs(notSubscribedMaps) do
                                table.insert(tooltipLines, mapName)
                            end
                        else
                            table.insert(tooltipLines,  getText("UI_None"))
                        end

                        item.tooltip = table.concat(tooltipLines, "\n")
                    end

                local mouseX, mouseY = self:getMouseX(), self:getMouseY()
                if mouseX >= 0 and mouseX <= self:getWidth() and mouseY >= y and mouseY <= y + self.itemheight then
                    self.parent.tooltip = {
                        x = mouseX + 15,
                        y = mouseY + 15,
                        width = getTextManager():MeasureStringX(UIFont.Small, item.tooltip) + 10,
                        height = (#tooltipLines * 20) + 10,
                        text = item.tooltip
                    }
                end

                    return y + self.itemheight
                    end

            ScrollListD.onMouseDown = function(self, x, y)
                local idx = self:rowAt(x, y)
                if not idx or idx < 1 or idx > #self.items then
                    return
                end

                local item           = self.items[idx]
                local dependencyName = item.text
                local dependencyData = MapModManagerLabel.MergedDependencyList[dependencyName]
                local workshopID     = dependencyData and dependencyData.workshopID
                local modID          = dependencyData and dependencyData.modID

                if workshopID and item.logoX and item.logoY and item.logoWidth and item.logoHeight then
                    local withinLogo =
                        x >= item.logoX and x <= (item.logoX + item.logoWidth) and
                        y >= item.logoY and y <= (item.logoY + item.logoHeight)
                    if withinLogo then
                        local steamURL = "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. workshopID
                        openUrl(steamURL)
                        return
                    end
                end

                if modID and item.buttonX and item.buttonY and item.buttonWidth and item.buttonHeight then
                    local withinButton =
                        x >= item.buttonX and x <= (item.buttonX + item.buttonWidth) and
                        y >= item.buttonY and y <= (item.buttonY + item.buttonHeight)

                    if withinButton then
                            local cache = MapModManagerLabel.subscribedModsCache or {}
                            local isSubscribed = (workshopID and cache[tostring(workshopID)]) or false

                            if not isSubscribed then
                                return
                            end

                            tempModList[modID] = not tempModList[modID]

                        local mainScreen = MainScreen.instance
                        local gridPanel  = mainScreen and mainScreen.gridPanel
                        if gridPanel and gridPanel.updateDependencies then
                            gridPanel:updateDependencies()
                        end
                        MapModManagerLabel.populateScrollListD()
                        return
                    end
                end
            end

            SD_Panel:addChild(ScrollListD)
            mainScreen.MapModManager_DependencyScrollList = ScrollListD

            MapModManagerLabel.populateScrollListD()
    end

-- Close Main UI --
    -- Close UI Panels
        function MapModManagerLabel.closeMainUI(button)
            local mainScreen = MainScreen.instance
            local bottomPanel = mainScreen.bottomPanel
            if bottomPanel then bottomPanel:setVisible(true) end
            local sdPanel = mainScreen.SD_Panel
            if sdPanel then
                mainScreen:removeChild(sdPanel)
                sdPanel:removeFromUIManager()
                mainScreen.SD_Panel = nil
            end

            local gPanel = mainScreen.G_Panel
            if gPanel then
                mainScreen:removeChild(gPanel)
                gPanel:removeFromUIManager()
                mainScreen.G_Panel = nil
            end

            local aPanel = mainScreen.A_Panel
            if aPanel then
                mainScreen:removeChild(aPanel)
                aPanel:removeFromUIManager()
                mainScreen.A_Panel = nil
            end

            local helpPanel = mainScreen.Help_Panel
            if helpPanel then
                mainScreen:removeChild(helpPanel)
                helpPanel:removeFromUIManager()
                mainScreen.Help_Panel = nil
            end

            local mlPanel = mainScreen.MLPanel
            if mlPanel then
                mainScreen:removeChild(mlPanel)
                mlPanel:removeFromUIManager()
                mainScreen.MLPanel = nil
            end
        end

    -- Discard Changes
        function MapModManagerLabel.discardChanges()
            tempModList = {}
            local activeMods = getActivatedMods()
            for i = 0, activeMods:size() - 1 do
                local modID = tostring(activeMods:get(i)):gsub("%s+", "")
                tempModList[modID] = true
            end
        end
    
    -- Helper Function: Close UI Panels and Discard Changes
        function MapModManagerLabel.Back()
            MapModManagerLabel.discardChanges()
            MapModManagerLabel.closeMainUI()
        end

    -- Check Mod List Changes
        function MapModManagerLabel.checkTempModListChanges()
            for modID, originalValue in pairs(MapModManagerLabel.originalTempModList) do
                local currentValue = tempModList[modID] or false
                if currentValue ~= originalValue then
                    return true
                end
            end

            for modID, currentValue in pairs(tempModList) do
                local originalValue = MapModManagerLabel.originalTempModList[modID] or false
                if currentValue ~= originalValue then
                    return true
                end
            end
            return false
        end

    -- Apply Changes
        function MapModManagerLabel.applyChanges()
            if MapModManagerLabel.checkTempModListChanges() then

                for modID, _ in pairs(tempModList) do
                    local mod = getModInfoByID(modID)
                    if mod then
                        toggleModActive(mod, false)
                    else
                        print("Mod with ID " .. modID .. " not found while disabling.")
                    end
                end

                for modID, shouldBeActive in pairs(tempModList) do
                    local mod = getModInfoByID(modID)
                    if mod then
                        toggleModActive(mod, shouldBeActive)
                    else
                        print("Mod with ID " .. modID .. " not found.")
                    end
                end

                saveModsFile()
                getCore():ResetLua("default", "modsChanged")
            end
            MapModManagerLabel.closeMainUI()
        end

-- Handle Resolution Changes --
    function MapModManagerLabel.onResolutionChange(oldw, oldh, neww, newh)
        if not MainScreen or not MainScreen.instance then return end
        local mainScreen = MainScreen.instance
        local bottomPanel = mainScreen.bottomPanel
        if bottomPanel then
            local mapModManagerLabel = mainScreen.mapModManagerOption
            if mapModManagerLabel then
                local quitLabel = mainScreen.exitOption
                if quitLabel then
                    local MMMLabelY = quitLabel:getY() + quitLabel:getHeight() + 16
                    mapModManagerLabel:setX(quitLabel:getX())
                    mapModManagerLabel:setY(MMMLabelY)
                    local labelWidth = quitLabel:getWidth()
                    mapModManagerLabel:setWidth(labelWidth)
                    bottomPanel:setHeight(MMMLabelY + mapModManagerLabel:getHeight())
                end
            end
        end
        local SD_Panel = MainScreen.instance.SD_Panel
        local G_Panel  = MainScreen.instance.G_Panel
        local A_Panel  = MainScreen.instance.A_Panel
        if SD_Panel and G_Panel and A_Panel then
            local screenWidth  = neww
            local screenHeight = newh
            local sdPanelWidth = screenWidth * 0.2
            local gPanelWidth  = screenWidth * 0.6
            local aPanelWidth  = screenWidth * 0.2
            SD_Panel:setX(0); SD_Panel:setY(0); SD_Panel:setWidth(sdPanelWidth); SD_Panel:setHeight(screenHeight)
            G_Panel:setX(sdPanelWidth); G_Panel:setY(0); G_Panel:setWidth(gPanelWidth); G_Panel:setHeight(screenHeight)
            A_Panel:setX(sdPanelWidth + gPanelWidth); A_Panel:setY(0); A_Panel:setWidth(aPanelWidth); A_Panel:setHeight(screenHeight)
            local ScrollListA = MainScreen.instance.MapModManager_ScrollList
            if ScrollListA then
                local font = UIFont.Medium
                local extraPadding = 10
                local itemHeight = getTextManager():MeasureStringY(font, "Test") + extraPadding
                MapModManagerLabel.mapsPerPage = math.floor(ScrollListA:getHeight() / itemHeight)
                if MapModManagerLabel.mapsPerPage < 1 then MapModManagerLabel.mapsPerPage = 1 end
                if MapModManagerLabel.mapsPerPage > 29 then MapModManagerLabel.mapsPerPage = 29 end
                MapModManagerLabel.populateScrollListA(MapModManagerLabel.currentPage)
            end
        end
    end

-- Add Label to Main Menu --
    function MapModManagerLabel.onMainMenuEnter()
        MapModManagerLabel.addLabel()
    end

    Events.OnMainMenuEnter.Add(MapModManagerLabel.onMainMenuEnter)
    Events.OnResolutionChange.Add(MapModManagerLabel.onResolutionChange)

-- Help Panel --
    function MapModManagerLabel.openHelpPanel()
        local mainScreen = MainScreen.instance
        if mainScreen.Help_Panel then return end
        local A_Panel = mainScreen.A_Panel

        local scrollListWidth = A_Panel:getWidth() - 20
        local panelX = A_Panel:getX() + (A_Panel:getWidth() - scrollListWidth) / 2

        local helpText = getText("UI_helpPanelText")
        helpText = helpText:gsub("\\\\n", "\n")

        local richTextWidth = scrollListWidth - 20
        local tempRichText = ISRichTextPanel:new(0, 0, richTextWidth, 1)
        tempRichText:initialise()
        tempRichText.background = false
        tempRichText.marginRight = tempRichText.marginLeft
        tempRichText:setText(helpText)
        tempRichText:paginate()
        local contentHeight = tempRichText:getHeight() + 20

        local minHelpPanelHeight = 200
        local panelHeight = math.max(minHelpPanelHeight, contentHeight)

        local acceptButton = mainScreen.MapModManager_acceptButton

        local padding = 20
        local panelY = acceptButton:getY() + acceptButton:getHeight() + padding - 10

        local Help_Panel = ISPanel:new(panelX, panelY, scrollListWidth, panelHeight)
        Help_Panel:initialise()
        Help_Panel:setVisible(true)
        Help_Panel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.95 }
        Help_Panel.borderColor = { r = 0.8, g = 0.8, b = 0.8, a = 0.6 }
        mainScreen:addChild(Help_Panel)
        mainScreen.Help_Panel = Help_Panel
        
        local richTextY = 10
        local helpRichText = ISRichTextPanel:new(10, richTextY, richTextWidth, contentHeight)
        helpRichText:initialise()
        helpRichText.background = false
        helpRichText.marginRight = helpRichText.marginLeft
        helpRichText:setText(helpText)
        helpRichText:paginate()
        Help_Panel:addChild(helpRichText)
        
        local closeButtonWidth  = 25
        local closeButtonHeight = 25
        local closeButtonX = scrollListWidth - closeButtonWidth - 5
        local closeButtonY = 5
        local closeButton = ISButton:new(
            closeButtonX,
            closeButtonY,
            closeButtonWidth,
            closeButtonHeight,
            "X",
            self,
            function() MapModManagerLabel.closeHelpPanel() end
        )
        closeButton:initialise()
        closeButton:instantiate()
        closeButton.backgroundColor = { r = 0.8, g = 0, b = 0, a = 1 }
        closeButton.borderColor = { r = 1, g = 1, b = 1, a = 1 }
        Help_Panel:addChild(closeButton)
    end

    function MapModManagerLabel.closeHelpPanel()
        local mainScreen = MainScreen.instance
        local Help_Panel = mainScreen.Help_Panel
        if Help_Panel then
            mainScreen:removeChild(Help_Panel)
            Help_Panel:removeFromUIManager()
            mainScreen.Help_Panel = nil
        end
    end

-- Mod Load Order Panel --
    -- Helper Function: Check ModID in Database
        function MapModManagerLabel.isModInDatabase(modID)
            for name, data in pairs(MapModManagerLabel.MergedMapList) do
                if tostring(data.modID) == modID then
                    return true
                end
            end
            for name, data in pairs(MapModManagerLabel.MergedDependencyList) do
                if tostring(data.modID) == modID then
                    return true
                end
            end
            return false
        end

    -- Helper Function: Hide A Panel Accept Button
        function MapModManagerLabel.hideAcceptButton()
            local mainScreen = MainScreen.instance
            if mainScreen and mainScreen.A_Panel and mainScreen.MapModManager_acceptButton then
                mainScreen.A_Panel:removeChild(mainScreen.MapModManager_acceptButton)
                mainScreen.MapModManager_acceptButton = nil
            end
        end

    -- Helper Function: Hide A Panel Help Button
        function MapModManagerLabel.hideHelpButton()
            local mainScreen = MainScreen.instance
            if mainScreen and mainScreen.A_Panel and mainScreen.MapModManager_helpButton then
                mainScreen.A_Panel:removeChild(mainScreen.MapModManager_helpButton)
                mainScreen.MapModManager_helpButton = nil
            end
        end

    -- Open ML Panel
        function MapModManagerLabel.openMLPanel()
            local mainScreen = MainScreen.instance
            if mainScreen.MLPanel then return end

            if mainScreen.SD_Panel then
                MapModManagerLabel.hiddenSDPanel = mainScreen.SD_Panel
                mainScreen:removeChild(mainScreen.SD_Panel)
            end

            local screenWidth = mainScreen:getWidth()
            local screenHeight = mainScreen:getHeight()
            local panelWidth = screenWidth * 0.2
            local panelHeight = screenHeight
            local panelX = 0
            local panelY = 0

            local MLPanel = ISPanel:new(panelX, panelY, panelWidth, panelHeight)
            MLPanel:initialise()
            MLPanel:setVisible(true)
            MLPanel.backgroundColor = { r = 0, g = 0, b = 0, a = 0.95 }
            MLPanel.borderColor = { r = 0.8, g = 0.8, b = 0.8, a = 0.6 }

        -- Adjusted Load Order List
            local adjustedLoadOrder = {}
            for modID, isActive in pairs(tempModList) do
                if isActive and MapModManagerLabel.isModInDatabase(modID) then
                    table.insert(adjustedLoadOrder, modID)
                end
            end
            MLPanel.loadOrderList = adjustedLoadOrder            

            mainScreen:addChild(MLPanel)
            mainScreen.MLPanel = MLPanel
            MapModManagerLabel.hideAcceptButton()
            MapModManagerLabel.closeHelpPanel()
            MapModManagerLabel.hideHelpButton()

            -- Button Preset
            local Button_Width  = 95
            local Button_Height = 23

        -- Back Button
            local backButton = ISButton:new(
                10,
                10,
                Button_Width,
                Button_Height,
                getText("UI_BackButton"),
                self,
                function() MapModManagerLabel.closeMLPanel() end)
            backButton:initialise()
            backButton:instantiate()
            backButton.backgroundColor = { r = 63/255, g = 0, b = 0, a = 1 }
            backButton.borderColor     = { r = 1, g = 0, b = 0, a = 1 }
            backButton.tooltip = getText("UI_MLbackButtonTooltip")
            MLPanel:addChild(backButton)

        -- Accept Button
            local acceptButton = ISButton:new(
                panelWidth - Button_Width - 10,
                10,
                Button_Width,
                Button_Height,
                getText("UI_acceptButton"),
                self,
                function() MapModManagerLabel.acceptMLPanelChanges() end)
            acceptButton:initialise()
            acceptButton:instantiate()
            acceptButton.backgroundColor = { r = 0, g = 63/255, b = 0, a = 1 }
            acceptButton.borderColor     = { r = 0, g = 1, b = 0, a = 1 }
            acceptButton.tooltip = getText("UI_MLacceptButtonTooltip")
            MLPanel:addChild(acceptButton)

        -- Text Label: Map Load Order
            local labelY = 10 + Button_Height + 10
            local mlLabel = ISLabel:new(
                0,
                labelY,
                40,
                getText("UI_modLoadOrder"),
                1, 1, 1, 1,
                UIFont.Medium,
                false)
            mlLabel:initialise()
            mlLabel:instantiate()
            mlLabel:setWidth(MLPanel:getWidth() - 20)
            mlLabel:setX((MLPanel:getWidth() - mlLabel:getWidth()) / 2)
            mlLabel.prerender = function(self)
                self:drawRect(0, 0, self:getWidth(), self:getHeight(), 0.6, 0, 0, 0)
                local text = getText("UI_modLoadOrder")
                local textWidth = getTextManager():MeasureStringX(UIFont.Medium, text)
                local textHeight = getTextManager():MeasureStringY(UIFont.Medium, text)
                local textX = (self:getWidth() - textWidth) / 2
                local textY = (self:getHeight() - textHeight) / 2
                self:drawText(text, textX, textY, 1, 1, 1, 1, UIFont.Medium)
            end
            MLPanel:addChild(mlLabel)
            mainScreen.MapModManager_modLoadOrderLabel = mlLabel

            -- Move Buttons
            local mlMargin = 10
            local mlGap = 10
            local newButtonWidth = (panelWidth - 2 * mlMargin - 2 * mlGap) / 3
            local mlButtonsY = mlLabel:getY() + mlLabel:getHeight() + 10

        -- Move to Top Button
            local moveToTopButton = ISButton:new(
                mlMargin,
                mlButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_MoveToTop"),
                self,
                function() MapModManagerLabel.moveToTop() end)
            moveToTopButton:initialise()
            moveToTopButton:instantiate()
            moveToTopButton.tooltip = getText("UI_MoveToTopTooltip")
            MLPanel:addChild(moveToTopButton)

            -- Move Up Button
            local moveUpButton = ISButton:new(
                mlMargin + newButtonWidth + mlGap,
                mlButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_MoveUp"),
                self,
                function() MapModManagerLabel.moveUp() end)
            moveUpButton:initialise()
            moveUpButton:instantiate()
            moveUpButton.tooltip = getText("UI_MoveUpTooltip")
            MLPanel:addChild(moveUpButton)

            -- Move Down Button
            local moveDownButton = ISButton:new(
                mlMargin + 2 * (newButtonWidth + mlGap),
                mlButtonsY,
                newButtonWidth,
                Button_Height,
                getText("UI_MoveDown"),
                self,
                function() MapModManagerLabel.moveDown() end)
            moveDownButton:initialise()
            moveDownButton:instantiate()
            moveDownButton.tooltip = getText("UI_MoveDownTooltip")
            MLPanel:addChild(moveDownButton)

            -- ML Scroll List
            local MLScrollListY = moveDownButton:getY() + moveDownButton:getHeight() + 10
            local MLScrollListHeight = MLPanel:getHeight() - MLScrollListY - 10
            local MLScrollList = ISScrollingListBox:new(10, MLScrollListY, MLPanel:getWidth() - 20, MLScrollListHeight)
            MLScrollList:initialise()
            MLScrollList:instantiate()
            MLScrollList.itemheight = getTextManager():MeasureStringY(UIFont.Medium, "Test") + 18
            MLPanel.MLScrollList = MLScrollList

            -- Populate ML Scroll List
            for _, modID in ipairs(MLPanel.loadOrderList) do
                local modName = nil
                for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
                    if tostring(mapData.modID) == modID then
                        modName = mapName
                        break
                    end
                end
                if not modName then
                    for depName, depData in pairs(MapModManagerLabel.MergedDependencyList) do
                        if tostring(depData.modID) == modID then
                            modName = depName
                            break
                        end
                    end
                end
                if modName then
                    MLScrollList:addItem(modName, nil)
                end
            end

            MLScrollList.onMouseDown = function(self, x, y)
                local idx = self:rowAt(x, y)
                if idx and idx >= 1 and idx <= #self.items then
                    self.selected = idx
                end
            end

            MLScrollList.doDrawItem = function(self, y, item, alt)
                if self.selected and self.items[self.selected] == item then
                    self:drawRect(0, y, self:getWidth(), self.itemheight, 0.2, 0.8, 0.8, 0.8)
                end
                self:drawText(item.text, 10, y + (self.itemheight - getTextManager():MeasureStringY(UIFont.Medium, item.text)) / 2,
                    1, 1, 1, 1, UIFont.Medium)
                return y + self.itemheight
            end

            MLPanel:addChild(MLScrollList)
        end

    -- Accept ML Panel Changes
        function MapModManagerLabel.acceptMLPanelChanges()
            local MLPanel = MainScreen.instance.MLPanel
            if not MLPanel or not MLPanel.loadOrderList then return end

            local newTempModList = {}
            for _, modID in ipairs(MLPanel.loadOrderList) do
                newTempModList[modID] = true
            end
            tempModList = newTempModList
            MapModManagerLabel.populateScrollListS()
            MapModManagerLabel.closeMLPanel()
        end

    -- Move to Top Button Logic
        function MapModManagerLabel.moveToTop()
            local MLPanel = MainScreen.instance.MLPanel
            local MLScrollList = MLPanel.MLScrollList
            local selectedIndex = MLScrollList.selected
            if selectedIndex and selectedIndex >= 1 and selectedIndex <= #MLPanel.loadOrderList then
                local modID = table.remove(MLPanel.loadOrderList, selectedIndex)
                table.insert(MLPanel.loadOrderList, 1, modID)
                MapModManagerLabel.refreshMLScrollList()
            end
        end

    -- Move Up Button Logic
        function MapModManagerLabel.moveUp()
            local mainScreen = MainScreen.instance
            local MLPanel = mainScreen.MLPanel
            if not MLPanel or not MLPanel.loadOrderList then return end
            local MLScrollList = MLPanel.MLScrollList
            if not MLScrollList then return end
            local selectedIndex = MLScrollList.selected
            if not selectedIndex or selectedIndex <= 1 or selectedIndex > #MLPanel.loadOrderList then return end
            MLPanel.loadOrderList[selectedIndex], MLPanel.loadOrderList[selectedIndex - 1] =
                MLPanel.loadOrderList[selectedIndex - 1], MLPanel.loadOrderList[selectedIndex]
            MapModManagerLabel.refreshMLScrollList()
            MLScrollList.selected = selectedIndex - 1
        end

    -- Move Down Button Logic
        function MapModManagerLabel.moveDown()
            local mainScreen = MainScreen.instance
            local MLPanel = mainScreen.MLPanel
            if not MLPanel or not MLPanel.loadOrderList then return end
            local MLScrollList = MLPanel.MLScrollList
            if not MLScrollList then return end
            local selectedIndex = MLScrollList.selected
            if not selectedIndex or selectedIndex >= #MLPanel.loadOrderList then return end
            MLPanel.loadOrderList[selectedIndex], MLPanel.loadOrderList[selectedIndex + 1] =
                MLPanel.loadOrderList[selectedIndex + 1], MLPanel.loadOrderList[selectedIndex]
            MapModManagerLabel.refreshMLScrollList()
            MLScrollList.selected = selectedIndex + 1
        end

    -- Helper Function: Refresh ML Scroll List
        function MapModManagerLabel.refreshMLScrollList()
            local mainScreen = MainScreen.instance
            local MLPanel = mainScreen.MLPanel
            if not MLPanel or not MLPanel.MLScrollList then return end

            local MLScrollList = MLPanel.MLScrollList
            MLScrollList:clear()
            for _, modID in ipairs(MLPanel.loadOrderList) do
                local modName = nil
                for name, data in pairs(MapModManagerLabel.MergedMapList) do
                    if tostring(data.modID) == modID then
                        modName = name
                        break
                    end
                end
                if not modName then
                    for depName, depData in pairs(MapModManagerLabel.MergedDependencyList) do
                        if tostring(depData.modID) == modID then
                            modName = depName
                            break
                        end
                    end
                end
                if modName then
                    MLScrollList:addItem(modName, nil)
                end
            end

            if #MLScrollList.items > 0 then
                MLScrollList.selected = 1
            end
        end

    -- Helper Function: Unhide A Panel Accept Button
        function MapModManagerLabel.unhideAcceptButton()
            local mainScreen = MainScreen.instance
            local A_Panel = mainScreen.A_Panel
            if not A_Panel then return end

            local Button_Width  = 95
            local Button_Height = 23
            local acceptButtonX = A_Panel:getWidth() - Button_Width - 10
            local acceptButtonY = 10

            local acceptButton = ISButton:new(
                acceptButtonX,
                acceptButtonY,
                Button_Width,
                Button_Height,
                getText("UI_acceptButton"),
                self,
                MapModManagerLabel.applyChanges
            )
            acceptButton:initialise()
            acceptButton:instantiate()
            acceptButton.backgroundColor = { r = 0, g = 63/255, b = 0, a = 1 }
            acceptButton.borderColor     = { r = 0, g = 1, b = 0, a = 1 }
            acceptButton.tooltip = getText("UI_acceptButtonTooltip")
            A_Panel:addChild(acceptButton)
            mainScreen.MapModManager_acceptButton = acceptButton
        end

    -- Helper Function: Unhide A Panel Help Button
        function MapModManagerLabel.unhideHelpButton()
            local mainScreen = MainScreen.instance
            local A_Panel = mainScreen.A_Panel
            if not A_Panel then return end

            local Button_Width  = 95
            local Button_Height = 23
            local acceptButtonX = A_Panel:getWidth() - Button_Width - 10
            local acceptButtonY = 10

            local helpButtonX = acceptButtonX - Button_Width - 10
            local helpButtonY = acceptButtonY

            local helpButton = ISButton:new(
                helpButtonX,
                helpButtonY,
                Button_Width,
                Button_Height,
                getText("UI_helpButton"),
                self,
                MapModManagerLabel.openHelpPanel
            )
            helpButton:initialise()
            helpButton:instantiate()
            A_Panel:addChild(helpButton)
            mainScreen.MapModManager_helpButton = helpButton
        end

    -- Close ML Panel
        function MapModManagerLabel.closeMLPanel()
            local mainScreen = MainScreen.instance
            if mainScreen.MLPanel then
                mainScreen:removeChild(mainScreen.MLPanel)
                mainScreen.MLPanel:removeFromUIManager()
                mainScreen.MLPanel = nil
            end

            if MapModManagerLabel.hiddenSDPanel then
                mainScreen:addChild(MapModManagerLabel.hiddenSDPanel)
                MapModManagerLabel.hiddenSDPanel:setVisible(true)
                MapModManagerLabel.hiddenSDPanel = nil
            end
            MapModManagerLabel.unhideAcceptButton()
            MapModManagerLabel.unhideHelpButton()
        end

-- Filter Functions --
    function MapModManagerLabel.filterMaps()
        local mainScreen = MainScreen.instance
        local ScrollListA = mainScreen.MapModManager_ScrollList
        if not ScrollListA then return end
        ScrollListA:clear()

        local rowValue = tonumber(mainScreen.MapModManager_filterRowDropdown:getSelectedText()) or 0
        local colValue = tonumber(mainScreen.MapModManager_filterColDropdown:getSelectedText()) or 0

        local filteredMaps = {}
        for mapName, mapData in pairs(MapModManagerLabel.MergedMapList) do
            if mapData.cells then
                for _, cell in ipairs(mapData.cells) do
                    if cell.row == rowValue and cell.col == colValue then
                        table.insert(filteredMaps, mapName)
                        break
                    end
                end
            end
        end

        MapModManagerLabel.totalMaps = #filteredMaps
        MapModManagerLabel.totalPages = math.ceil(MapModManagerLabel.totalMaps / MapModManagerLabel.mapsPerPage)
        MapModManagerLabel.currentPage = 1

        local vanillaMaps = {}
        local otherMaps = {}
        for _, mapName in ipairs(filteredMaps) do
            if mapName:find("^Vanilla:") then
                table.insert(vanillaMaps, mapName)
            else
                table.insert(otherMaps, mapName)
            end
        end
        table.sort(otherMaps, function(a, b) return a:lower() < b:lower() end)

        local allMaps = {}
        for _, mapName in ipairs(vanillaMaps) do table.insert(allMaps, mapName) end
        for _, mapName in ipairs(otherMaps) do table.insert(allMaps, mapName) end

        local startIndex = (MapModManagerLabel.currentPage - 1) * MapModManagerLabel.mapsPerPage + 1
        local endIndex   = startIndex + MapModManagerLabel.mapsPerPage - 1

        for i = startIndex, math.min(endIndex, #allMaps) do
            ScrollListA:addItem(allMaps[i], nil)
        end

        local prevButton = mainScreen.MapModManager_prevButton
        local nextButton = mainScreen.MapModManager_nextButton
        if prevButton then prevButton:setEnable(MapModManagerLabel.currentPage > 1) end
        if nextButton then nextButton:setEnable(MapModManagerLabel.currentPage < MapModManagerLabel.totalPages) end
    end

    function MapModManagerLabel.clearFilter()
        local mainScreen = MainScreen.instance
        if mainScreen.MapModManager_filterRowDropdown then
            mainScreen.MapModManager_filterRowDropdown.selected = 1
        end
        if mainScreen.MapModManager_filterColDropdown then
            mainScreen.MapModManager_filterColDropdown.selected = 1
        end
        MapModManagerLabel.populateScrollListA(1)
    end


-- Initialize Data on Game Boot --
    function mergeTables(static, dynamic)
        local merged = {}
        for k, v in pairs(static) do merged[k] = v end
        for k, v in pairs(dynamic) do merged[k] = v end
        return merged
    end

    function MapModManagerLabel.initializeMergedData()
        if MapModManagerLabel.getActiveMods then
            MapModManagerLabel.getActiveMods()
        end

        MapModManagerLabel.MergedMapList = buildMergedMapList()
        buildConflicts(MapModManagerLabel.MergedMapList)

        local staticDeps   = Dependency_DB
        local dynamicDeps  = buildDynamicDependencyEntries()
        MapModManagerLabel.MergedDependencyList = mergeTables(staticDeps, dynamicDeps)
    end

    function tablelength(tbl)
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        return count
    end

    Events.OnGameBoot.Add(MapModManagerLabel.initializeMergedData)