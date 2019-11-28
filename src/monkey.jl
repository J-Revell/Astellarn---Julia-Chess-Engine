function monkey!(board::Board)
    if isdrawbymaterial(board)
        #println("draw!")
        return :DRAW
    end
    ml = MoveStack(150)
    gen_moves!(ml, board)
    if length(ml) == 0
        if ischeck(board)
            #println("checkmate!")
            if board.turn == WHITE
                return :WHITE_WINS
            else
                return :BLACK_WINS
            end
        else
            #println("statemate!")
            return :DRAW
        end
    end
    apply_move!(board, rand(ml))
    board
end
