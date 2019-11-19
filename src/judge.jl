# is the position legal
function isLegal(board::Board)
    !isTheirKingAttacked(board::Board)
end

function isCheckmate(board::Board)
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    ml = filter(move -> move.move_flag !== CASTLE, ml)
    for move in ml
        _board = deepcopy(board)
        (move.move_flag == NONE) && move_normal!(_board, move)
        (move.move_flag == ENPASS) && move_enpass!(_board, move)
        (UInt8(1) < move.move_flag < UInt8(6)) && move_promo!(_board, move)
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
    ml = filter(move -> move.move_flag !== CASTLE, ml)
    for move in ml
        _board = deepcopy(board)
        (move.move_flag == NONE) && move_normal!(_board, move)
        (move.move_flag == ENPASS) && move_enpass!(_board, move)
        (UInt8(1) < move.move_flag < UInt8(6)) && move_promo!(_board, move)
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
