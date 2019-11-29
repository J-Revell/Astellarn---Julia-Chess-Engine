# mutable struct MoveGenerator
#     moves::MoveStack
# end


# https://www.chessprogramming.org/Quiescence_Search
"""
    qsearch()

Quiescence search function. Under development.
"""
function qsearch(board::Board, α::Int, β::Int, depth::Int)
    eval = evaluate(board)
    if eval >= β
        return β
    elseif eval > α
        α = eval
    end
    if depth == 0
        return α
    end
    moves = MoveStack(50)
    gen_noisy_moves!(moves, board)
    for move in moves
        u = apply_move!(board, move)
        eval = -qsearch(board, -β, -α, depth - 1)
        undo_move!(board, move, u)
        if eval >= β
            return β
        end
        if eval > α
            α = eval
        end
    end
    return α
end


"""
    absearch()

Naive αβ search. Under development.
"""
function absearch(board::Board, α::Int, β::Int, depth::Int)
    movestack = [MoveStack(200) for i in 1:depth]
    run_absearch(board, α, β, depth, 0, movestack)
end

function run_absearch(board::Board, α::Int, β::Int, depth::Int, ply::Int, movestack::Vector{MoveStack})
    if depth == 0
        return qsearch(board, α, β, 4), Move(), 1 # temporary max depth of 4 on quiescence search
    end
    moves = movestack[ply + 1]
    gen_moves!(moves, board)
    nodes = 0
    best_move = Move()
    for move in moves
        u = apply_move!(board, move)
        eval, cand, n = run_absearch(board, -β, -α, depth - 1, ply + 1, movestack)
        eval *= -1
        undo_move!(board, move, u)
        nodes += n
        if eval >= β
            clear!(moves)
            return β, best_move, nodes
        elseif eval > α
            α = eval
            best_move = move
        end
    end
    if length(moves) == 0
        if ischeck(board)
            α = -10000
        else
            α = 0
        end
    end
    if is50moverule(board)
        α = 0
    end
    clear!(moves)
    return α, best_move, nodes
end
