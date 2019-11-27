const MAX_MOVES = 200


# Internal function to run perft
function runperft(board::Board, depth::Int, ply::Int, movestack::Vector{MoveStack})
    if depth == 1
        gen_moves!(movestack[ply + 1], board)
        n = movestack[ply + 1].idx
        clear!(movestack[ply + 1])
        return n
    else
        movelist = movestack[ply + 1]
        gen_moves!(movelist, board)
        num_moves = 0
        for i in eachindex(movelist)
            u = apply_move!(board, movelist[i])
            num_moves += runperft(board, depth - 1, ply + 1, movestack)
            undo_move!(board, movelist[i], u)
        end
        clear!(movelist)
        return num_moves
    end
end


"""
    perft(board::Board, depth::Int)

Run the perft routine to a given `depth`.
"""
function perft(board::Board, depth::Int)
    movestack = [MoveStack(MAX_MOVES) for d in 1:depth]
    runperft(board, depth, 0, movestack)
end
