require "PlayableMinigames/PMG_Core"

PMG_Anchors = PMG_Anchors or {}

PMG_Anchors.CARD_SURFACE_WORDS = {
    "table",
    "desk",
    "counter",
    "bar",
}

PMG_Anchors.CARD_DECK_ITEM = "Base.CardDeck"
PMG_Anchors.DART_ITEM = "Base.Dart"
PMG_Anchors.CHECKERBOARD_ITEM = "Base.CheckerBoard"
PMG_Anchors.CHESS_WHITE_ITEM = "Base.ChessWhite"
PMG_Anchors.CHESS_BLACK_ITEM = "Base.ChessBlack"

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function objectText(isoObject)
    local spriteName = PMG.getSpriteName(isoObject)
    local customName = PMG.getObjectProperty(isoObject, "CustomName")
    local groupName = PMG.getObjectProperty(isoObject, "GroupName")
    return lower(spriteName) .. " " .. lower(customName) .. " " .. lower(groupName)
end

function PMG_Anchors.isDartboardObject(isoObject)
    local text = objectText(isoObject)
    return string.find(text, "dartboard", 1, true) ~= nil or string.find(text, "dart board", 1, true) ~= nil
end

function PMG_Anchors.isCardSurfaceObject(isoObject)
    local text = objectText(isoObject)
    if text == "  " then
        return false
    end
    if string.find(text, "pool", 1, true) then
        return false
    end
    for i = 1, #PMG_Anchors.CARD_SURFACE_WORDS do
        if string.find(text, PMG_Anchors.CARD_SURFACE_WORDS[i], 1, true) then
            return true
        end
    end
    return false
end

function PMG_Anchors.isCardDeckWorldObject(isoObject)
    return PMG.isWorldInventoryItemType(isoObject, PMG_Anchors.CARD_DECK_ITEM)
end

function PMG_Anchors.isDartWorldObject(isoObject)
    return PMG.isWorldInventoryItemType(isoObject, PMG_Anchors.DART_ITEM)
end

function PMG_Anchors.isCheckerBoardWorldObject(isoObject)
    return PMG.isWorldInventoryItemType(isoObject, PMG_Anchors.CHECKERBOARD_ITEM)
end

function PMG_Anchors.isChessPiecesWorldObject(isoObject)
    return PMG.isWorldInventoryItemType(isoObject, PMG_Anchors.CHESS_WHITE_ITEM) or
        PMG.isWorldInventoryItemType(isoObject, PMG_Anchors.CHESS_BLACK_ITEM)
end

function PMG_Anchors.anchorFromObject(gameId, isoObject)
    if not isoObject or not isoObject.getSquare then
        return nil
    end
    local square = isoObject:getSquare()
    if not square then
        return nil
    end
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    return {
        gameId = gameId,
        x = x,
        y = y,
        z = z,
        key = PMG.keyForAnchor(gameId, x, y, z),
        sprite = PMG.getSpriteName(isoObject),
        customName = PMG.getObjectProperty(isoObject, "CustomName"),
    }
end

local function findFromWorldObjects(worldobjects, predicate)
    if not worldobjects then
        return nil
    end
    local function findInList(objects)
        if not objects then
            return nil
        end
        for j = 0, objects:size() - 1 do
            local candidate = objects:get(j)
            if predicate(candidate) then
                return candidate
            end
        end
        return nil
    end
    for i = 1, #worldobjects do
        local object = worldobjects[i]
        if predicate(object) then
            return object
        end
        if object and object.getSquare then
            local square = object:getSquare()
            if square and square.getObjects then
                local found = findInList(square:getObjects())
                if found then
                    return found
                end
            end
            if square and square.getWorldObjects then
                local found = findInList(square:getWorldObjects())
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

function PMG_Anchors.findDartboardFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isDartboardObject)
end

function PMG_Anchors.findCardSurfaceFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isCardSurfaceObject)
end

function PMG_Anchors.findCardDeckFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isCardDeckWorldObject)
end

function PMG_Anchors.findDartFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isDartWorldObject)
end

function PMG_Anchors.findCheckerBoardFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isCheckerBoardWorldObject)
end

function PMG_Anchors.findChessPiecesFromWorldObjects(worldobjects)
    return findFromWorldObjects(worldobjects, PMG_Anchors.isChessPiecesWorldObject)
end

function PMG_Anchors.anchorFromArgs(args)
    if not args then
        return nil
    end
    local gameId = tostring(args.gameId or "")
    local x = tonumber(args.x)
    local y = tonumber(args.y)
    local z = tonumber(args.z)
    if gameId == "" or not x or not y or not z then
        return nil
    end
    x = math.floor(x)
    y = math.floor(y)
    z = math.floor(z)
    return {
        gameId = gameId,
        x = x,
        y = y,
        z = z,
        key = tostring(args.key or PMG.keyForAnchor(gameId, x, y, z)),
        source = tostring(args.source or ""),
    }
end

local function coordinateKey(kind, source, x, y, z)
    return tostring(kind) .. ":" ..
        tostring(source or "anchor") .. ":" ..
        tostring(math.floor(tonumber(x) or 0)) .. ":" ..
        tostring(math.floor(tonumber(y) or 0)) .. ":" ..
        tostring(math.floor(tonumber(z) or 0))
end

function PMG_Anchors.findObjectNearAnchor(anchor, predicate, radius)
    local cell = getCell and getCell() or nil
    if not cell or not anchor then
        return nil
    end
    radius = tonumber(radius) or 2
    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(anchor.x + dx, anchor.y + dy, anchor.z)
            if square and square.getObjects then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    if predicate(objects:get(i)) then
                        return objects:get(i), square
                    end
                end
            end
            if square and square.getWorldObjects then
                local objects = square:getWorldObjects()
                for i = 0, objects:size() - 1 do
                    if predicate(objects:get(i)) then
                        return objects:get(i), square
                    end
                end
            end
        end
    end
    return nil
end

function PMG_Anchors.equipmentKeyForAnchor(kind, anchor)
    if not kind or not anchor then
        return nil
    end
    if kind == "card_deck" then
        local deck, square = PMG_Anchors.findObjectNearAnchor(anchor, PMG_Anchors.isCardDeckWorldObject, 1)
        if deck and deck.getSquare then
            square = deck:getSquare() or square
        end
        if square then
            return coordinateKey(kind, "world", square:getX(), square:getY(), square:getZ())
        end
    end
    if kind == "checkerboard" then
        local board, square = PMG_Anchors.findObjectNearAnchor(anchor, PMG_Anchors.isCheckerBoardWorldObject, 1)
        if board and board.getSquare then
            square = board:getSquare() or square
        end
        if square then
            return coordinateKey(kind, "world", square:getX(), square:getY(), square:getZ())
        end
        return nil
    end
    return coordinateKey(kind, "anchor", anchor.x, anchor.y, anchor.z)
end

function PMG_Anchors.objectExistsNearAnchor(anchor, predicate, radius)
    if PMG_Anchors.findObjectNearAnchor(anchor, predicate, radius) then
        return true
    end
    return false
end

local function countWorldItemsNearAnchor(anchor, fullType, radius)
    local cell = getCell and getCell() or nil
    if not cell or not anchor or not fullType then
        return 0
    end
    radius = tonumber(radius) or 1
    local count = 0
    local seen = {}
    local function countObject(isoObject)
        if isoObject and not seen[isoObject] and PMG.isWorldInventoryItemType(isoObject, fullType) then
            seen[isoObject] = true
            count = count + 1
        end
    end
    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(anchor.x + dx, anchor.y + dy, anchor.z)
            if square and square.getWorldObjects then
                local objects = square:getWorldObjects()
                for i = 0, objects:size() - 1 do
                    countObject(objects:get(i))
                end
            end
            if square and square.getObjects then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    countObject(objects:get(i))
                end
            end
        end
    end
    return count
end

function PMG_Anchors.hasCardDeckForAnchor(_, anchor)
    if PMG_Anchors.objectExistsNearAnchor(anchor, PMG_Anchors.isCardDeckWorldObject, 1) then
        return true, 1, "world"
    end
    return false, 0, nil
end

function PMG_Anchors.hasDartsForAnchor(_, anchor)
    local count = countWorldItemsNearAnchor(anchor, PMG_Anchors.DART_ITEM, 1)
    if count >= 3 then
        return true, count, "world"
    end
    return false, count, nil
end

local function hasWorldItemNearAnchor(anchor, fullType, radius)
    return PMG_Anchors.objectExistsNearAnchor(anchor, function(isoObject)
        return PMG.isWorldInventoryItemType(isoObject, fullType)
    end, radius or 1)
end

function PMG_Anchors.hasCheckerBoardForAnchor(_, anchor)
    if hasWorldItemNearAnchor(anchor, PMG_Anchors.CHECKERBOARD_ITEM, 1) then
        return true, 1, "world"
    end
    return false, 0, nil
end

function PMG_Anchors.hasChessSetForAnchor(_, anchor)
    local hasBoard = PMG_Anchors.hasCheckerBoardForAnchor(nil, anchor)
    local hasWhite = hasWorldItemNearAnchor(anchor, PMG_Anchors.CHESS_WHITE_ITEM, 1)
    local hasBlack = hasWorldItemNearAnchor(anchor, PMG_Anchors.CHESS_BLACK_ITEM, 1)
    if hasBoard and hasWhite and hasBlack then
        return true, 1, "world"
    end
    local missing = {}
    if not hasBoard then
        table.insert(missing, "checkerboard")
    end
    if not hasWhite then
        table.insert(missing, "white chess pieces")
    end
    if not hasBlack then
        table.insert(missing, "black chess pieces")
    end
    return false, {
        board = hasBoard,
        white = hasWhite,
        black = hasBlack,
        whiteCount = hasWhite and 1 or 0,
        blackCount = hasBlack and 1 or 0,
    }, "You need " .. table.concat(missing, ", ") .. " to play chess."
end

function PMG_Anchors.validateAnchorForGame(gameId, anchor)
    if gameId == "darts_501" then
        return PMG_Anchors.objectExistsNearAnchor(anchor, PMG_Anchors.isDartboardObject, 2) and
            PMG_Anchors.hasDartsForAnchor(nil, anchor)
    end
    if gameId == "blackjack" or gameId == "holdem" or gameId == "solitaire" then
        return (PMG_Anchors.objectExistsNearAnchor(anchor, PMG_Anchors.isCardSurfaceObject, 2) or
            PMG_Anchors.objectExistsNearAnchor(anchor, PMG_Anchors.isCardDeckWorldObject, 2)) and
            PMG_Anchors.hasCardDeckForAnchor(nil, anchor)
    end
    if gameId == "checkers" then
        return PMG_Anchors.hasCheckerBoardForAnchor(nil, anchor)
    end
    if gameId == "chess" then
        return PMG_Anchors.hasChessSetForAnchor(nil, anchor)
    end
    return false
end
