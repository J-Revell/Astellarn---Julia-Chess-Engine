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

        #discard bad SEE moves
        if !static_exchange_evaluator(board, move) && (best_move !== Move())
            continue
        end

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
            α = -10000-depth
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


# returns true if move passes SEE criteria
function static_exchange_evaluator(board::Board, move::Move)
    from_sqr = Int(from(move))
    to_sqr = Int(to(move))

    move_flag = flag(move)

    from_piece = piece(board, from_sqr)
    to_piece = piece(board, to_sqr)
    victim = (move_flag < 5) ? from_piece : makepiece(PieceType(flag(move) - 3), board.turn)

    occ = occupied(board)
    occ ⊻= (Bitboard(from_sqr) | Bitboard(to_sqr))

    if move_flag == __ENPASS
        occ ⊻= Bitboard(board.enpass)
    end

    attackers = (pawns(board) & pawnAttacks(board.turn, to_sqr)) |
    (pawns(board) & pawnAttacks(!board.turn, to_sqr)) |
    (knightMoves(to_sqr) & knights(board)) |
    (bishopMoves(to_sqr, occ) & bishoplike(board)) |
    (rookMoves(to_sqr, occ) & rooklike(board)) |
    (kingMoves(to_sqr) & kings(board))

    attackers &= occ

    if isempty(attackers & enemy(board))
        return true
    end

    color = !board.turn

    balance = 20

    if to_piece !== BLANK
        balance += PVALS[type(to_piece).val]
    end

    if move_flag >= 5
        balance += PVALS[type(victim).val] - PVALS[1]
    end

    if move_flag == __ENPASS
        balance += PVALS[1]
    end

    #if (move_flag == __KING_CASTLE) || (move_flag == __QUEEN_CASTLE)
    #end

    if balance < 0
        return false
    end

    balance -= PVALS[type(victim).val]

    if balance >= 0
        return true
    end

    while true
        our_attackers = attackers & board[color]

        # if we can't attack, we lose
        if isempty(our_attackers)
            break
        end

        # find weakest piece to recapture
        for i in 1:6
            piecetype = PieceType(i)
            if !isempty(our_attackers & board[piecetype])
                victim = piecetype
                break
            end
        end

        # remove our attacker
        occ ⊻= Bitboard(poplsb(our_attackers & board[victim])[1])

        # check for diag moves
        if (victim == PAWN || victim == BISHOP || victim == QUEEN)
            attackers |= bishopMoves(to_sqr, occ) & bishoplike(board)
        end

        # check for rank/file moves
        if (victim == ROOK || victim == QUEEN)
            attackers |= rookMoves(to_sqr, occ) & rooklike(board)
        end

        attackers &= occ

        balance = -balance - 1 - PVALS[victim.val]
        color = !color

        if balance >= 0
            if (victim == KING) && !isempty(attackers & board[!color])
                color = !color
            end

            break
        end

    end
    if board.turn == color
        return false
    else
        return true
    end
end
