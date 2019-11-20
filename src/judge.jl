# is the position legal
function isLegal(board::Board)
    switchTurn!(board)
    bool = !(checkers(board) > zero(UInt))
    switchTurn!(board)
    return bool
end

function isCheckmate(board::Board)
    pml = MoveList(8)
    ml = MoveList(8)
    build_king_moves!(ml, board, ~getWhite(board))
    ul = UndoStack(150)
    for (num, move) in enumerate(ml)
        push!(ul, Undo())
        legal = move!(board, move, ul[num])
        if legal
            push!(pml, move)
            undomove!(board, move, ul[num])
        end
        #undomove!(board, move, undo)
    end
    (length(pml) == 0) && isCheck(board)
end

function isStalemate(board::Board)
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    ul = UndoStack(150)
    for (num, move) in enumerate(ml)
        push!(ul, Undo())
        legal = move!(board, move, ul[num])
        if legal
            push!(pml, move)
            undomove!(board, move, ul[num])
        end
        #undomove!(board, move, undo)
    end
    (length(pml) == 0) && !isCheck(board)
end

function isDrawByMaterial(board::Board)
    piece_count = count_ones(board.colors[WHITE]) + count_ones(board.colors[BLACK])
    if piece_count == 2
        return true
    elseif piece_count == 3
        if board.pieces[BISHOP] > zero(UInt)
            return true
        elseif board.pieces[KNIGHT] > zero(UInt)
            return true
        end
    elseif piece_count == 4
        if count_ones(board.pieces[KNIGHT]) == 2
            return true
        end
    end
    return false
end
