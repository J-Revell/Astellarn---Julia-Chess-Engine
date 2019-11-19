function randMove!(board::Board)
    if isCheckmate(board)
        println("CHECKMATE!")
        return true
    end
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
    monkeymove = pml[rand(1:length(pml))]
    (monkeymove.move_flag == NONE) && move_normal!(board, monkeymove)
    (monkeymove.move_flag == ENPASS) && move_enpass!(board, monkeymove)
    (UInt8(1) < monkeymove.move_flag < UInt8(6)) && move_promo!(board, monkeymove)
    if isStalemate(board)
        println("STALEMATE!")
        return true
    end
    if isDrawByMaterial(board)
        println("DRAW DETECTED!")
        return true
    end
    return false
end
