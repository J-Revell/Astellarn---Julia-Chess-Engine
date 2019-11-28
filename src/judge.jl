# is the position legal
function islegal(board::Board)
    switchturn!(board)
    bool = isempty(kingAttackers(board))
    switchturn!(board)
    return bool
end

function ischeckmate(board::Board)
    if ischeck(board)
        ml = MoveStack(50)
        gen_moves!(ml, board)
        if length(ml) == 0
            return true
        else
            return false
        end
    else
        return false
    end
end

function isstalemate(board::Board)
    if ischeck(board)
        return false
    else
        ml = MoveStack(50)
        gen_moves!(ml, board)
        if length(ml) == 0
            return true
        else
            return false
        end
    end
end

function isdrawbymaterial(board::Board)
    piece_count = count(board[WHITE]) + count(board[BLACK])
    if piece_count == 2
        return true
    elseif piece_count == 3
        if count(board[BISHOP]) > 0
            return true
        elseif count(board[KNIGHT]) > 0
            return true
        end
    end
    return false
end

function is50moverule(board::Board)
    if board.halfmovecount > 99
        return true
    else
        return false
    end
end
