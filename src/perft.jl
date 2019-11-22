function runperft(board::Board, depth::Int, ply::Int, movestack::Vector{MoveList})
    if depth == 1
        movelist = MoveList(200)
        undostack = UndoStack(200)
        gen_legal_moves!(movelist, undostack, board)
        num_moves = length(movelist)
    else
        movelist = movestack[ply + 1]
        undostack = UndoStack(200)
        gen_legal_moves!(movelist, undostack, board)
        num_moves = 0
        for move in movelist
            undo = Undo()
            move_legal!(board, move, undo)
            num_moves += runperft(board, depth - 1, ply + 1, movestack)
            undomove!(board, move, undo)
        end
        clear!(movelist)
    end
    return num_moves
end

function perft(board::Board, depth::Int)
    if depth == 0
        return 1
    else
        movestack = [MoveList(200) for d in 1:depth]
        runperft(board, depth, 0, movestack)
    end
end
