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
const SEE_MARGIN = -50

const WINDOW_DEPTH = 4

const MATE = 32000


"""
    find_best_move()

Probe the tablebase if appropriate, or perform the absearch routine.
"""
function find_best_move(board::Board; ab_depth::Int = 3)
    # probe the tablebase
    if (count(occupied(board)) <= 5)
        res = tb_probe_root(board)
        if res !== TB_RESULT_FAILED
            _eval = TB_GET_WDL(res)
            if iszero(_eval)
                eval = -MATE
            elseif 1 <= _eval <= 3 # blessed / cursed loss and wins are draws
                eval = 0
            else
                eval = MATE
            end
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

    # else we do a search
    else
        ttable = TT_Table()
        return iterative_deepening(board, ttable, ab_depth)
    end
end


function iterative_deepening(board::Board, ttable::TT_Table, max_depth::Int)
    eval = 0
    move = Move()
    nodes = 0
    for depth in 1:max_depth
        eval, move, nodes = aspiration_window(board, ttable, depth, eval)
    end
    return eval, move, nodes
end


function aspiration_window(board::Board, ttable::TT_Table, depth::Int, eval::Int)
    α = -MATE
    β = MATE
    δ = 50

    if depth >= WINDOW_DEPTH
        α = max(-MATE, eval - δ)
        β = min(MATE, eval + δ)
    end

    while true
        eval, move, nodes = absearch(board, ttable, α, β, depth)

        # inside an aspiration window
        if α < eval < β
            return eval, move, nodes
        end
        println(eval)

        # fail low
        if eval <= α
            β = fld(α + β, 2)
            α = max(-MATE, α - δ)

        # fail high
        elseif eval >= β
            β = min(MATE, β + δ)
        end

        # expand window
        δ += fld(δ, 2)
    end
end


# https://www.chessprogramming.org/Quiescence_Search
"""
    qsearch()

Quiescence search function. Under development.
"""
function qsearch(board::Board, ttable::TT_Table, α::Int, β::Int, depth::Int, ply::Int)
    # default val
    tt_eval = -2MATE
    nodes = 1

    # draw checks
    if isdrawbymaterial(board) || is50moverule(board)
        return 0, nodes
    end

    # max depth cutoff
    if depth == 0
        return evaluate(board), nodes
    end

    # probe the transposition table
    if hasTTentry(ttable, board.hash)
        tt_entry = getTTentry(ttable, board.hash)
        tt_eval = tt_entry.eval
        if (tt_entry.bound == BOUND_EXACT) ||
            ((tt_entry.bound == BOUND_LOWER) && (ttvalue(tt_entry, ply) >= β)) ||
            ((tt_entry.bound == BOUND_UPPER) && (ttvalue(tt_entry, ply) <= α))
            return tt_entry.eval, 1
        end
    end

    if tt_eval !== -2MATE
        eval = tt_eval
    else
        eval = evaluate(board)
    end

    best = eval

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
        eval, new_nodes = qsearch(board, ttable, -β, -α, depth - 1, ply + 1)
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
function absearch(board::Board, ttable::TT_Table, α::Int, β::Int, depth::Int)
    movestack = [MoveStack(200) for i in 0:depth+10]
    run_absearch(board, ttable, α, β, depth, 0, movestack)
end


"""
    run_absearch()

Internals of `absearch()` routine.
"""
function run_absearch(board::Board, ttable::TT_Table, α::Int, β::Int, depth::Int, ply::Int, movestack::Vector{MoveStack})
    # init vales
    init_α = α

    # is this the root node?
    isroot = ply == 0

    # is this a pvnode
    pvnode = β !== α + 1

    # default best val
    best = -MATE #+ ply

    # default tt_eval
    tt_eval = -2MATE

    # ensure +ve depth
    if depth < 0
        depth = 0
    end

    # enter quiescence search
    if iszero(depth) && !ischeck(board)
        q_eval, nodes = qsearch(board, ttable, α, β, QSEARCH_DEPTH, 0)
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

    # probe the transposition table
    if hasTTentry(ttable, board.hash)
        tt_entry = getTTentry(ttable, board.hash)
        tt_eval = tt_entry.eval
        if (tt_entry.depth >= depth) && (depth == 0 || !pvnode)
            if (tt_entry.bound == BOUND_EXACT) ||
                ((tt_entry.bound == BOUND_LOWER) && (ttvalue(tt_entry, ply) >= β)) ||
                ((tt_entry.bound == BOUND_UPPER) && (ttvalue(tt_entry, ply) <= α))
                return tt_eval, tt_entry.move, 1
            end
        end
    end

    # probe the syzygy tablebase
    # to-do, add entries to the transposition table
    if (count(occupied(board)) <= 5)
        _eval = tb_probe_wdl(board)
        if _eval !== TB_RESULT_FAILED

            # is the tablebase losing
            if iszero(_eval)
                eval = -MATE + MAX_PLY + ply + 1
                tt_bound = BOUND_UPPER

            # is the tablebase a draw, blessed / cursed loss and wins are draws
            elseif 1 <= _eval <= 3
                eval = 0
                tt_bound = BOUND_EXACT

            # the tablebase is a win
            else
                eval = MATE - MAX_PLY - ply - 1
                tt_bound = BOUND_LOWER
            end

            # add to transposition table
            tt_entry = TT_Entry(eval, Move(), MAX_PLY - 1, tt_bound)
            if (tt_entry.bound == BOUND_EXACT) ||
                ((tt_entry.bound == BOUND_LOWER) && (eval >= β)) ||
                ((tt_entry.bound == BOUND_UPPER) && (eval <= α))
                setTTentry!(ttable, board.hash, tt_entry)
                return eval, Move(), 1
            end
        end
    end

    # set the eval
    if tt_eval !== -2MATE
        eval = tt_eval
    else
        eval = evaluate(board)
    end

    #razoring
    if !pvnode && !ischeck(board) && (depth <= RAZOR_DEPTH) && (eval + RAZOR_MARGIN < α)
        q_eval, nodes = qsearch(board, ttable, α, β, QSEARCH_DEPTH, 0)
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

        # discard bad SEE moves
        if (static_exchange_evaluator(board, move, SEE_MARGIN * depth) == false) && (best_move !== Move()) && (depth <= SEE_PRUNE_DEPTH)
            continue
        end

        u = apply_move!(board, move)

        # do we need an extension?
        if ischeck(board) 
            newdepth = depth + 1
        else
            newdepth = depth
        end

        # perform search
        cand_eval, cand_pv, cand_nodes = run_absearch(board, ttable, -β, -α, newdepth - 1, ply + 1, movestack)
        cand_eval = -cand_eval

        # revert move and count nodes
        undo_move!(board, move, u)
        nodes += cand_nodes

        # improvement?
        if cand_eval > best
            best = cand_eval
            if cand_eval > α
                α = cand_eval
                best_move = move

                # fail high?
                if α >= β
                    break
                end
            end
        end

    end

    if length(moves) == 0
        if ischeck(board)
            # add depth to give an indication of the "fastest" mate
            best = -MATE + ply
        else
            best = 0
        end
    end
    clear!(moves)

    if isroot == false
        tt_bound = best >= β ? BOUND_LOWER : (best > init_α ? BOUND_EXACT : BOUND_UPPER)
        tt_entry = TT_Entry(eval, best_move, depth, tt_bound)
        setTTentry!(ttable, board.hash, tt_entry)
    end

    return best, best_move, nodes
end


"""
    static_exchange_evaluator(board::Board, move::Move)

Returns true if a move passes a static exchange criteria, false otherwise.
"""
function static_exchange_evaluator(board::Board, move::Move, threshold::Int)
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

    attackers = (pawns(board) & pawnAttacks(!board.turn, to_sqr) & friendly(board)) |
    (pawns(board) & pawnAttacks(board.turn, to_sqr) & enemy(board)) |
    (knightMoves(to_sqr) & knights(board)) |
    (bishopMoves(to_sqr, occ) & bishoplike(board)) |
    (rookMoves(to_sqr, occ) & rooklike(board)) |
    (kingMoves(to_sqr) & kings(board))

    attackers &= occ

    if isempty(attackers & enemy(board))
        return true
    end

    color = !board.turn

    balance = -threshold

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
