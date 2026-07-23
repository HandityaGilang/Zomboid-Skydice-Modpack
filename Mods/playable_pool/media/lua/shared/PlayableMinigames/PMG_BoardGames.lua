require "PlayableMinigames/PMG_Core"

PMG_BoardGames = PMG_BoardGames or {}

local CHESS_HOME = { "R", "N", "B", "Q", "K", "B", "N", "R" }
local PROMOTIONS = { Q = true, R = true, B = true, N = true }

local function other(color)
    return color == "white" and "black" or "white"
end

local function prefix(color)
    return color == "white" and "w" or "b"
end

local function colorOf(piece)
    if not piece then
        return nil
    end
    return string.sub(piece, 1, 1) == "w" and "white" or "black"
end

local function kindOf(piece)
    return piece and string.sub(piece, 2, 2) or nil
end

local function onBoard(row, col)
    return row >= 1 and row <= 8 and col >= 1 and col <= 8
end

local function cloneBoard(board)
    local copy = {}
    for row = 1, 8 do
        copy[row] = {}
        for col = 1, 8 do
            copy[row][col] = board and board[row] and board[row][col] or nil
        end
    end
    return copy
end

local function emptyBoard()
    local board = {}
    for row = 1, 8 do
        board[row] = {}
    end
    return board
end

local function squareName(row, col)
    local files = "abcdefgh"
    return string.sub(files, col, col) .. tostring(9 - row)
end

function PMG_BoardGames.otherColor(color)
    return other(color)
end

function PMG_BoardGames.chessInitial()
    local board = emptyBoard()
    for col = 1, 8 do
        board[1][col] = "b" .. CHESS_HOME[col]
        board[2][col] = "bP"
        board[7][col] = "wP"
        board[8][col] = "w" .. CHESS_HOME[col]
    end
    return {
        board = board,
        turn = "white",
        seats = {},
        castle = {
            white = { king = true, queen = true },
            black = { king = true, queen = true },
        },
        enPassant = nil,
        halfmove = 0,
        fullmove = 1,
        moveCount = 0,
        captured = { white = {}, black = {} },
        status = "waiting",
    }
end

function PMG_BoardGames.checkersInitial()
    local board = emptyBoard()
    for row = 1, 3 do
        for col = 1, 8 do
            if (row + col) % 2 == 1 then
                board[row][col] = "bm"
            end
        end
    end
    for row = 6, 8 do
        for col = 1, 8 do
            if (row + col) % 2 == 1 then
                board[row][col] = "wm"
            end
        end
    end
    return {
        board = board,
        turn = "black",
        seats = {},
        moveCount = 0,
        captured = { white = 0, black = 0 },
        forceFrom = nil,
        status = "waiting",
    }
end

local function findKing(board, color)
    local target = prefix(color) .. "K"
    for row = 1, 8 do
        for col = 1, 8 do
            if board[row][col] == target then
                return row, col
            end
        end
    end
    return nil, nil
end

local function rayAttacks(board, row, col, byColor, directions, kinds)
    for i = 1, #directions do
        local dr = directions[i][1]
        local dc = directions[i][2]
        local r = row + dr
        local c = col + dc
        while onBoard(r, c) do
            local piece = board[r][c]
            if piece then
                if colorOf(piece) == byColor and kinds[kindOf(piece)] then
                    return true
                end
                break
            end
            r = r + dr
            c = c + dc
        end
    end
    return false
end

function PMG_BoardGames.isChessSquareAttacked(board, row, col, byColor)
    local pawnDir = byColor == "white" and -1 or 1
    for _, dc in ipairs({ -1, 1 }) do
        local r = row - pawnDir
        local c = col - dc
        if onBoard(r, c) and board[r][c] == prefix(byColor) .. "P" then
            return true
        end
    end
    local knightSteps = {
        { -2, -1 }, { -2, 1 }, { -1, -2 }, { -1, 2 },
        { 1, -2 }, { 1, 2 }, { 2, -1 }, { 2, 1 },
    }
    for i = 1, #knightSteps do
        local r = row + knightSteps[i][1]
        local c = col + knightSteps[i][2]
        if onBoard(r, c) and board[r][c] == prefix(byColor) .. "N" then
            return true
        end
    end
    if rayAttacks(board, row, col, byColor, { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }, { B = true, Q = true }) then
        return true
    end
    if rayAttacks(board, row, col, byColor, { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }, { R = true, Q = true }) then
        return true
    end
    for dr = -1, 1 do
        for dc = -1, 1 do
            if dr ~= 0 or dc ~= 0 then
                local r = row + dr
                local c = col + dc
                if onBoard(r, c) and board[r][c] == prefix(byColor) .. "K" then
                    return true
                end
            end
        end
    end
    return false
end

function PMG_BoardGames.isChessInCheck(state, color, board)
    board = board or state.board
    local row, col = findKing(board, color)
    if not row then
        return true
    end
    return PMG_BoardGames.isChessSquareAttacked(board, row, col, other(color))
end

local function addChessMove(moves, fromRow, fromCol, toRow, toCol, extra)
    if not onBoard(toRow, toCol) then
        return
    end
    local move = extra and PMG.copyTable(extra) or {}
    move.fromRow = fromRow
    move.fromCol = fromCol
    move.toRow = toRow
    move.toCol = toCol
    table.insert(moves, move)
end

local function chessPseudoMovesFor(state, row, col)
    local board = state.board
    local piece = board[row] and board[row][col]
    local color = colorOf(piece)
    local kind = kindOf(piece)
    local moves = {}
    if not color then
        return moves
    end
    if kind == "P" then
        local dir = color == "white" and -1 or 1
        local startRow = color == "white" and 7 or 2
        local promotionRow = color == "white" and 1 or 8
        if onBoard(row + dir, col) and not board[row + dir][col] then
            addChessMove(moves, row, col, row + dir, col, row + dir == promotionRow and { promotion = "Q" } or nil)
            if row == startRow and not board[row + dir * 2][col] then
                addChessMove(moves, row, col, row + dir * 2, col, { doublePawn = true })
            end
        end
        for _, dc in ipairs({ -1, 1 }) do
            local tr = row + dir
            local tc = col + dc
            if onBoard(tr, tc) then
                local target = board[tr][tc]
                if target and colorOf(target) == other(color) then
                    addChessMove(moves, row, col, tr, tc, tr == promotionRow and { promotion = "Q" } or nil)
                elseif state.enPassant and state.enPassant.row == tr and state.enPassant.col == tc then
                    addChessMove(moves, row, col, tr, tc, { enPassant = true, captureRow = row, captureCol = tc })
                end
            end
        end
    elseif kind == "N" then
        local steps = {
            { -2, -1 }, { -2, 1 }, { -1, -2 }, { -1, 2 },
            { 1, -2 }, { 1, 2 }, { 2, -1 }, { 2, 1 },
        }
        for i = 1, #steps do
            local tr = row + steps[i][1]
            local tc = col + steps[i][2]
            local target = onBoard(tr, tc) and board[tr][tc] or nil
            if onBoard(tr, tc) and colorOf(target) ~= color then
                addChessMove(moves, row, col, tr, tc)
            end
        end
    elseif kind == "B" or kind == "R" or kind == "Q" then
        local dirs = {}
        if kind == "B" or kind == "Q" then
            dirs[#dirs + 1] = { -1, -1 }; dirs[#dirs + 1] = { -1, 1 }; dirs[#dirs + 1] = { 1, -1 }; dirs[#dirs + 1] = { 1, 1 }
        end
        if kind == "R" or kind == "Q" then
            dirs[#dirs + 1] = { -1, 0 }; dirs[#dirs + 1] = { 1, 0 }; dirs[#dirs + 1] = { 0, -1 }; dirs[#dirs + 1] = { 0, 1 }
        end
        for i = 1, #dirs do
            local tr = row + dirs[i][1]
            local tc = col + dirs[i][2]
            while onBoard(tr, tc) do
                local target = board[tr][tc]
                if not target then
                    addChessMove(moves, row, col, tr, tc)
                else
                    if colorOf(target) ~= color then
                        addChessMove(moves, row, col, tr, tc)
                    end
                    break
                end
                tr = tr + dirs[i][1]
                tc = tc + dirs[i][2]
            end
        end
    elseif kind == "K" then
        for dr = -1, 1 do
            for dc = -1, 1 do
                if dr ~= 0 or dc ~= 0 then
                    local tr = row + dr
                    local tc = col + dc
                    local target = onBoard(tr, tc) and board[tr][tc] or nil
                    if onBoard(tr, tc) and colorOf(target) ~= color then
                        addChessMove(moves, row, col, tr, tc)
                    end
                end
            end
        end
        local rights = state.castle and state.castle[color] or {}
        local home = color == "white" and 8 or 1
        if row == home and col == 5 and not PMG_BoardGames.isChessInCheck(state, color) then
            if rights.king and board[home][8] == prefix(color) .. "R" and not board[home][6] and not board[home][7]
                and not PMG_BoardGames.isChessSquareAttacked(board, home, 6, other(color))
                and not PMG_BoardGames.isChessSquareAttacked(board, home, 7, other(color)) then
                addChessMove(moves, row, col, home, 7, { castle = "king" })
            end
            if rights.queen and board[home][1] == prefix(color) .. "R" and not board[home][2] and not board[home][3] and not board[home][4]
                and not PMG_BoardGames.isChessSquareAttacked(board, home, 4, other(color))
                and not PMG_BoardGames.isChessSquareAttacked(board, home, 3, other(color)) then
                addChessMove(moves, row, col, home, 3, { castle = "queen" })
            end
        end
    end
    return moves
end

local function applyChessMoveToBoard(board, move, promotion)
    local nextBoard = cloneBoard(board)
    local piece = nextBoard[move.fromRow][move.fromCol]
    nextBoard[move.fromRow][move.fromCol] = nil
    if move.enPassant then
        nextBoard[move.captureRow][move.captureCol] = nil
    end
    if move.castle == "king" then
        nextBoard[move.toRow][6] = nextBoard[move.toRow][8]
        nextBoard[move.toRow][8] = nil
    elseif move.castle == "queen" then
        nextBoard[move.toRow][4] = nextBoard[move.toRow][1]
        nextBoard[move.toRow][1] = nil
    end
    if kindOf(piece) == "P" and (move.toRow == 1 or move.toRow == 8) then
        promotion = PROMOTIONS[promotion or move.promotion] and (promotion or move.promotion) or "Q"
        piece = prefix(colorOf(piece)) .. promotion
    end
    nextBoard[move.toRow][move.toCol] = piece
    return nextBoard
end

function PMG_BoardGames.chessLegalMoves(state, color)
    color = color or state.turn
    local legal = {}
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = state.board[row][col]
            if piece and colorOf(piece) == color then
                local pseudo = chessPseudoMovesFor(state, row, col)
                for i = 1, #pseudo do
                    local move = pseudo[i]
                    local nextBoard = applyChessMoveToBoard(state.board, move, move.promotion)
                    if not PMG_BoardGames.isChessInCheck({ board = nextBoard }, color, nextBoard) then
                        table.insert(legal, move)
                    end
                end
            end
        end
    end
    return legal
end

function PMG_BoardGames.findChessMove(state, args)
    local fr = PMG.clamp(args and args.fromRow, 1, 8)
    local fc = PMG.clamp(args and args.fromCol, 1, 8)
    local tr = PMG.clamp(args and args.toRow, 1, 8)
    local tc = PMG.clamp(args and args.toCol, 1, 8)
    local moves = PMG_BoardGames.chessLegalMoves(state, state.turn)
    for i = 1, #moves do
        local move = moves[i]
        if move.fromRow == fr and move.fromCol == fc and move.toRow == tr and move.toCol == tc then
            return move, moves
        end
    end
    return nil, moves
end

local function revokeCastleRights(state, piece, fromRow, fromCol, captured, toRow, toCol)
    local color = colorOf(piece)
    if kindOf(piece) == "K" and state.castle[color] then
        state.castle[color].king = false
        state.castle[color].queen = false
    elseif kindOf(piece) == "R" and state.castle[color] then
        if fromRow == (color == "white" and 8 or 1) and fromCol == 1 then
            state.castle[color].queen = false
        elseif fromRow == (color == "white" and 8 or 1) and fromCol == 8 then
            state.castle[color].king = false
        end
    end
    local capturedColor = colorOf(captured)
    if kindOf(captured) == "R" and state.castle[capturedColor] then
        if toRow == (capturedColor == "white" and 8 or 1) and toCol == 1 then
            state.castle[capturedColor].queen = false
        elseif toRow == (capturedColor == "white" and 8 or 1) and toCol == 8 then
            state.castle[capturedColor].king = false
        end
    end
end

function PMG_BoardGames.applyChessMove(state, args)
    local move = PMG_BoardGames.findChessMove(state, args or {})
    if not move then
        return false, "That chess move is not legal."
    end
    local piece = state.board[move.fromRow][move.fromCol]
    local captured = move.enPassant and state.board[move.captureRow][move.captureCol] or state.board[move.toRow][move.toCol]
    local resultPiece = piece
    local promotion = args and args.promotion or move.promotion
    if kindOf(piece) == "P" and (move.toRow == 1 or move.toRow == 8) then
        promotion = PROMOTIONS[promotion] and promotion or "Q"
        resultPiece = prefix(colorOf(piece)) .. promotion
    end
    local rookMove = nil
    if move.castle == "king" then
        rookMove = {
            piece = prefix(colorOf(piece)) .. "R",
            fromRow = move.toRow,
            fromCol = 8,
            toRow = move.toRow,
            toCol = 6,
        }
    elseif move.castle == "queen" then
        rookMove = {
            piece = prefix(colorOf(piece)) .. "R",
            fromRow = move.toRow,
            fromCol = 1,
            toRow = move.toRow,
            toCol = 4,
        }
    end
    revokeCastleRights(state, piece, move.fromRow, move.fromCol, captured, move.toRow, move.toCol)
    state.board = applyChessMoveToBoard(state.board, move, promotion)
    if captured then
        local mover = colorOf(piece)
        table.insert(state.captured[mover], captured)
    end
    state.enPassant = move.doublePawn and { row = (move.fromRow + move.toRow) / 2, col = move.fromCol } or nil
    state.halfmove = (kindOf(piece) == "P" or captured) and 0 or ((state.halfmove or 0) + 1)
    if state.turn == "black" then
        state.fullmove = (state.fullmove or 1) + 1
    end
    state.turn = other(state.turn)
    state.moveCount = (state.moveCount or 0) + 1
    state.lastMove = {
        fromRow = move.fromRow,
        fromCol = move.fromCol,
        toRow = move.toRow,
        toCol = move.toCol,
        piece = piece,
        resultPiece = resultPiece,
        captured = captured,
        promotion = promotion,
        enPassant = move.enPassant == true,
        captureRow = move.captureRow,
        captureCol = move.captureCol,
        castle = move.castle,
        rookMove = rookMove,
    }
    local replies = PMG_BoardGames.chessLegalMoves(state, state.turn)
    state.check = PMG_BoardGames.isChessInCheck(state, state.turn)
    state.checkmate = state.check and #replies == 0
    state.stalemate = (not state.check) and #replies == 0
    if state.checkmate then
        state.status = "checkmate"
        state.winnerColor = other(state.turn)
    elseif state.stalemate then
        state.status = "stalemate"
        state.winnerColor = nil
    else
        state.status = state.check and "check" or "playing"
    end
    return true
end

local function checkersDirections(piece)
    local color = colorOf(piece)
    if kindOf(piece) == "M" then
        return { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }
    end
    local dir = color == "white" and -1 or 1
    return { { dir, -1 }, { dir, 1 } }
end

local function checkersMovesFor(state, row, col, capturesOnly)
    local board = state.board
    local piece = board[row] and board[row][col]
    local color = colorOf(piece)
    local moves = {}
    if not color then
        return moves
    end
    local dirs = checkersDirections(piece)
    for i = 1, #dirs do
        local mr = row + dirs[i][1]
        local mc = col + dirs[i][2]
        local tr = row + dirs[i][1] * 2
        local tc = col + dirs[i][2] * 2
        if onBoard(tr, tc) and board[mr][mc] and colorOf(board[mr][mc]) == other(color) and not board[tr][tc] then
            table.insert(moves, { fromRow = row, fromCol = col, toRow = tr, toCol = tc, captureRow = mr, captureCol = mc })
        elseif not capturesOnly and onBoard(mr, mc) and not board[mr][mc] then
            table.insert(moves, { fromRow = row, fromCol = col, toRow = mr, toCol = mc })
        end
    end
    return moves
end

function PMG_BoardGames.checkersLegalMoves(state, color)
    color = color or state.turn
    local captures = {}
    local quiet = {}
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = state.board[row][col]
            if piece and colorOf(piece) == color then
                if state.forceFrom and (state.forceFrom.row ~= row or state.forceFrom.col ~= col) then
                    -- A multi-jump must continue with the same piece.
                else
                    local pieceCaptures = checkersMovesFor(state, row, col, true)
                    for i = 1, #pieceCaptures do
                        table.insert(captures, pieceCaptures[i])
                    end
                    if not state.forceFrom then
                        local pieceQuiet = checkersMovesFor(state, row, col, false)
                        for i = 1, #pieceQuiet do
                            if not pieceQuiet[i].captureRow then
                                table.insert(quiet, pieceQuiet[i])
                            end
                        end
                    end
                end
            end
        end
    end
    return #captures > 0 and captures or quiet
end

function PMG_BoardGames.findCheckersMove(state, args)
    local fr = PMG.clamp(args and args.fromRow, 1, 8)
    local fc = PMG.clamp(args and args.fromCol, 1, 8)
    local tr = PMG.clamp(args and args.toRow, 1, 8)
    local tc = PMG.clamp(args and args.toCol, 1, 8)
    local moves = PMG_BoardGames.checkersLegalMoves(state, state.turn)
    for i = 1, #moves do
        local move = moves[i]
        if move.fromRow == fr and move.fromCol == fc and move.toRow == tr and move.toCol == tc then
            return move, moves
        end
    end
    return nil, moves
end

local function countCheckersPieces(board, color)
    local count = 0
    for row = 1, 8 do
        for col = 1, 8 do
            if colorOf(board[row][col]) == color then
                count = count + 1
            end
        end
    end
    return count
end

function PMG_BoardGames.applyCheckersMove(state, args)
    local move = PMG_BoardGames.findCheckersMove(state, args or {})
    if not move then
        return false, "That checkers move is not legal."
    end
    local piece = state.board[move.fromRow][move.fromCol]
    local originalPiece = piece
    local mover = colorOf(piece)
    state.board[move.fromRow][move.fromCol] = nil
    local captured = nil
    if move.captureRow then
        captured = state.board[move.captureRow][move.captureCol]
        state.board[move.captureRow][move.captureCol] = nil
        state.captured[mover] = (state.captured[mover] or 0) + 1
    end
    local crowned = false
    if piece == "wm" and move.toRow == 1 then
        piece = "wM"
        crowned = true
    elseif piece == "bm" and move.toRow == 8 then
        piece = "bM"
        crowned = true
    end
    state.board[move.toRow][move.toCol] = piece
    state.lastMove = {
        fromRow = move.fromRow,
        fromCol = move.fromCol,
        toRow = move.toRow,
        toCol = move.toCol,
        piece = originalPiece,
        resultPiece = piece,
        captured = captured,
        captureRow = move.captureRow,
        captureCol = move.captureCol,
        crowned = crowned,
    }
    state.moveCount = (state.moveCount or 0) + 1
    state.forceFrom = nil
    if captured and not crowned then
        local more = checkersMovesFor(state, move.toRow, move.toCol, true)
        if #more > 0 then
            state.forceFrom = { row = move.toRow, col = move.toCol }
            state.status = "must_continue"
            return true
        end
    end
    state.turn = other(state.turn)
    local opponentCount = countCheckersPieces(state.board, state.turn)
    local replies = PMG_BoardGames.checkersLegalMoves(state, state.turn)
    if opponentCount == 0 or #replies == 0 then
        state.status = "won"
        state.winnerColor = other(state.turn)
    else
        state.status = "playing"
    end
    return true
end

function PMG_BoardGames.movesFrom(moves, row, col)
    local result = {}
    for i = 1, #(moves or {}) do
        local move = moves[i]
        if move.fromRow == row and move.fromCol == col then
            table.insert(result, PMG.copyTable(move))
        end
    end
    return result
end

function PMG_BoardGames.squareName(row, col)
    return squareName(row, col)
end
