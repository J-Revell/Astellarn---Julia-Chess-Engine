# mutable struct MoveGenerator
#     moves::MoveStack
# end

const MAX_PLY = 100

const Q_FUTILE_THRESH = 200

const QSEARCH_DEPTH = 4

const RAZOR_DEPTH = 1
const RAZOR_MARGIN = 330

const BETA_PRUNE_DEPTH = 8
const BETA_PRUNE_MARGIN = 85

const SEE_PRUNE_DEPTH = 8

const MATE = 50000


"""
    find_best_move()

Probe the tablebase if appropriate, or perform the absearch routine.
"""
function find_best_move(board::Board; ab_depth::Int = 3)
    if (count(occupied(board)) <= 5)
        res = tb_probe_root(board)
        if res !== TB_RESULT_FAILED
            eval = TB_GET_WDL(res)
            move_from = TB_GET_FROM(res)
            move_to = TB_GET_TO(res)
            promotion = TB_GET_PROMOTES(res)
            if promotion !== TB_PROMOTES_NONE
                (promotion == TB_PROMOTES_QUEEN) && (return eval, Move(move_from, move_to, __QUEEN_PROMO), 1)
                (promotion == TB_PROMOTES_ROOK) && (return eval, Move(move_from, move_to, __ROOK_PROMO), 1)
                (promotion == TB_PROMOTES_BISHOP) && (return eval, Move(move_from, move_to, __BISHOP_PROMO), 1)
                (promotion == TB_PROMOTES_KNIGHT) && (return eval, Move(move_from, move_to, __KNIGHT_PROMO), 1)
            else
                return eval, Move(move_from, move_to, __NORMAL_MOVE), 1
            end
        end
    else
        return absearch(board, -100000, 100000, ab_depth)
    end
end


# https://www.chessprogramming.org/Quiescence_Search
"""
    qsearch()

Quiescence search function. Under development.
"""
function qsearch(board::Board, α::Int, β::Int, depth::Int)
    # draw checks
    if isdrawbymaterial(board) || is50moverule(board)
        return 0, 1
    end

    eval = evaluate(board)
    best = eval

    nodes = 1

    # max depth cutoff
    if depth == 0
        return eval, nodes
    end

    # eval pruning
    if eval > α
        α = eval
    end
    if α >= β
        return eval, nodes
    end

    # delta pruning
    margin = α - eval - Q_FUTILE_THRESH
    if optimistic_move_estimator(board) < margin
        return eval, nodes
    end

    moves = MoveStack(50)
    gen_noisy_moves!(moves, board)

    # iterate through moves
    for move in moves
        u = apply_move!(board, move)
        eval, new_nodes = qsearch(board, -β, -α, depth - 1)
        eval = -eval
        undo_move!(board, move, u)
        nodes += new_nodes

        # check for improvements
        if eval > best
            best = eval
            if eval > α
                α = best
            end
        end

        # fail high?
        if α >= β
            return best, nodes
        end

    end
    return best, nodes
end


"""
    absearch()

Naive αβ search. Implements qsearch, SEE eval pruning.
"""
function absearch(board::Board, α::Int, β::Int, depth::Int)
    movestack = [MoveStack(200) for i in 1:depth]
    run_absearch(board, α, β, depth, 0, movestack)
end


"""
    run_absearch()

Internals of `absearch()` routine.
"""
function run_absearch(board::Board, α::Int, β::Int, depth::Int, ply::Int, movestack::Vector{MoveStack})
    # is this the root node?
    isroot = ply == 0

    # is this a pvnode
    pvnode = β > α + 1

    # default best val
    best = -MATE

    # enter quiescence search
    if (depth <= 0) #&& !ischeck(board)
        q_eval, nodes = qsearch(board, α, β, QSEARCH_DEPTH) # temporary max depth of 4 on quiescence search
        return q_eval, Move(), nodes
    end

    # early exit conditions
    if isroot == false
        if isdrawbymaterial(board) || is50moverule(board) || isrepetition(board)
            return 0, Move(), 1
        end
        if ply >= MAX_PLY
            eval = evaluate(board)
            return eval, Move(), 1
        end

        # mate pruning
        if α > -MATE + ply
            mate_α = α
        else
            mate_α = -MATE + ply
        end
        if β < MATE - ply - 1
            mate_β = β
        else
            mate_β = MATE - ply - 1
        end
        if mate_α >= mate_β
            return mate_α, Move(), 1
        end
    end

    # set eval
    eval = evaluate(board)

    #razoring
    if !pvnode && !ischeck(board) && (depth <= RAZOR_DEPTH) && (eval + RAZOR_MARGIN < α)
        q_eval, nodes = qsearch(board, α, β, QSEARCH_DEPTH)
        return q_eval, Move(), nodes
    end

    # beta pruning
    if !pvnode && !ischeck(board) && (depth <= BETA_PRUNE_DEPTH) && (eval - BETA_PRUNE_MARGIN * depth > β)
        return eval, Move(), 1
    end

    moves = movestack[ply + 1]
    gen_moves!(moves, board)
    nodes = 0
    best_move = Move()

    for move in moves

        #discard bad SEE moves
        if (static_exchange_evaluator(board, move) == false) && (best_move !== Move()) && (depth <= SEE_PRUNE_DEPTH)
            continue
        end

        u = apply_move!(board, move)
        eval, cand, n = run_absearch(board, -β, -α, depth - 1, ply + 1, movestack)
        eval = -eval
        undo_move!(board, move, u)
        nodes += n

        # improvement?
        if eval > best
            best = eval
            if eval > α
                α = eval
                best_move = move

                # fail high?
                if α > β
                    break
                end
            end
        end

    end

    if length(moves) == 0
        if ischeck(board)
            # add depth to give an indication of the "fastest" mate
            α = -MATE + ply
        else
            α = 0
        end
    end
    clear!(moves)
    return best, best_move, nodes
end


"""
    static_exchange_evaluator(board::Board, move::Move)

Returns true if a move passes a static exchange criteria, false otherwise.
"""
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
        if isempty(board[board.turn] & board[piecetype]) == false
            value = PVALS[i]
            break
        end
    end

    # promo checks
    if isempty(board[PAWN] & board[board.turn] & (board.turn == WHITE ? RANK_7 : RANK_2)) == false
        value += PVALS[5] - PVALS[1]
    end

    return value
end
