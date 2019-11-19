function randMove!(board::Board)
    if isCheckmate(board)
        println("CHECKMATE!")
        return true
    end
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    #ml = filter(move -> move.move_flag !== CASTLE, ml)
    for move in ml
        _board = deepcopy(board)
        move!(_board, move)
        if isLegal(_board)
            push!(pml, move)
        end
    end
    if length(pml) == 0
        println("HELP! ", board)
    end
    monkeymove = pml[rand(1:length(pml))]
    move!(board, monkeymove)
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
