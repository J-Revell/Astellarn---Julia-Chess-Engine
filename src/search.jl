# mutable struct MoveGenerator
#     moves::MoveStack
# end

const Q_FUTILE_THRESH = 200


# https://www.chessprogramming.org/Quiescence_Search
"""
    qsearch()

Quiescence search function. Under development.
"""
function qsearch(board::Board, α::Int, β::Int, depth::Int)
    eval = evaluate(board)

    nodes = 1

    # eval pruning
    if eval >= β
        return β, nodes
    elseif eval > α
        α = eval
    end
    if depth == 0
        return eval, nodes # used to be α
    end

    # delta pruning
    margin = α - eval - Q_FUTILE_THRESH
    if optimistic_move_estimator(board) < margin
        return eval, nodes
    end

    moves = MoveStack(50)
    gen_noisy_moves!(moves, board)
    for move in moves
        u = apply_move!(board, move)
        eval, new_nodes = qsearch(board, -β, -α, depth - 1)
        eval = -eval
        undo_move!(board, move, u)
        nodes += new_nodes
        if eval >= β
            return β, nodes
        end
        if eval > α
            α = eval
        end
    end
    return α, nodes
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
        q_eval, nodes = qsearch(board, α, β, 4) # temporary max depth of 4 on quiescence search
        return q_eval, Move(), nodes
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
        eval = -eval
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
            # subtract depth to give an indication of the "fastest" mate
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
    # if it's your turn, you lost the SEE loop
    if board.turn == color
        return false
    else
        return true
    end
end


# delta pruning
function optimistic_move_estimator(board::Board)
    # assume pawn at minimum
    value = PVALS[1]

    # find highest val targets
    for i in 5:-1:2
        piecetype = PieceType(i)
        if !isempty(board[board.turn] & board[piecetype])
            value = PVALS[i]
            break
        end
    end

    # promo checks
    if !isempty(board[PAWN] & board[board.turn] & (board.turn == WHITE ? RANK_7 : RANK_2))
        value += PVALS[5] - PVALS[1]
    end

    return value
end
