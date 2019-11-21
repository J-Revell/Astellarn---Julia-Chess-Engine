function randMove!(board::Board)
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    undo = Undo()
    for move in ml
        #push!(ul, Undo())
        legal = move!(board, move, undo)
        if legal
            push!(pml, move)
            undomove!(board, move, undo)
        end
    end
    if length(pml) == 0
        if isCheck(board)
            #println("checkmate!")
            return true
        else
            #println("statemate!")
            return true
        end
    end
    monkeymove = pml[rand(1:length(pml))]
    move!(board, monkeymove, Undo())
    if isDrawByMaterial(board)
        #println("draw!")
        return true
    end
    return false
end
