const MAX_MOVES = 256

function runperft(board::Board, depth::Int, ply::Int, movestack::Vector{MoveList}, undostack::Vector{UndoStack})
    if depth == 0
        return 1
    else
        movelist = movestack[ply + 1]
        undolist = undostack[ply + 1]
        gen_moves!(movelist, board)
        num_moves = 0
        for i in eachindex(movelist)
            legal = move!(board, movelist[i], undolist[i])
            if legal
                num_moves += runperft(board, depth - 1, ply + 1, movestack, undostack)
                undomove!(board, movelist[i], undolist[i])
            end
        end
        clear!(movelist)
        return num_moves
    end
end

function perft(board::Board, depth::Int)
    movestack = [MoveList(MAX_MOVES) for d in 1:depth]
    undostack = [UndoStack(repeat([Undo()], MAX_MOVES), 0) for d in 1:depth]
    runperft(board, depth, 0, movestack, undostack)
end
