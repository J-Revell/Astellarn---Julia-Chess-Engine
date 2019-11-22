# is the position legal
function isLegal(board::Board)
    switchTurn!(board)
    bool = !(checkers(board) > zero(UInt))
    switchTurn!(board)
    return bool
end

function isCheckmate(board::Board)
    if isCheck(board)
        ml = MoveList(50)
        gen_moves!(ml, board)
        for move in ml
            undo = Undo()
            legal = move!(board, move, undo)
            if legal
                undomove!(board, move, undo)
                return false
            end
        end
        return true
    else
        return false
    end
end

function isStalemate(board::Board)
    if !isCheck(board)
        ml = MoveList(100)
        gen_moves!(ml, board)
        for move in ml
            undo = Undo()
            legal = move!(board, move, undo)
            if legal
                undomove!(board, move, undo)
                return false
            end
        end
        return true
    else
        return false
    end
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
