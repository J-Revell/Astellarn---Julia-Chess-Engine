# is the position legal
function isLegal(board::Board)
    switchTurn!(board)
    bool = !isOurKingAttacked(board::Board)
    switchTurn!(board)
    return bool
end

function isCheckmate(board::Board)
    pml = MoveList(8)
    ml = MoveList(8)
    build_king_moves!(ml, board, ~getWhite(board))
    for move in ml
        _board = deepcopy(board)
        move!(_board, move)
        if isLegal(_board)
            push!(pml, move)
        end
    end
    (length(pml) == 0) && isOurKingAttacked(board)
end

function isStalemate(board::Board)
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    for move in ml
        _board = deepcopy(board)
        move!(_board, move)
        if isLegal(_board)
            push!(pml, move)
        end
    end
    (length(pml) == 0) && !isOurKingAttacked(board)
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
