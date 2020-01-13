const MAX_PLY = 40

const Q_FUTILITY_MARGIN = 100

const RAZOR_DEPTH = 1
const RAZOR_MARGIN = 400

const BETA_PRUNE_DEPTH = 8
const BETA_PRUNE_MARGIN = 85

const SEE_PRUNE_DEPTH = 8
const SEE_QUIET_MARGIN = -190
const SEE_NOISY_MARGIN = -20

const FUTILITY_PRUNE_DEPTH = 8
const FUTILITY_MARGIN = 185
const FUTILITY_MARGIN_NOHIST = 300
const FUTILITY_LIMIT = @SVector [12000, 6000]

const COUNTER_PRUNE_DEPTH = @SVector [3, 2]
const COUNTER_PRUNE_LIMIT = @SVector [0, -1000]

const FOLLOW_PRUNE_DEPTH = @SVector [3, 2]
const FOLLOW_PRUNE_LIMIT = @SVector [-2000, -4000]

const WINDOW_DEPTH = 5

const MATE = 32000

# For late move count, we can add another vector for when eval is improving. At the moment it is static.
const LATE_MOVE_COUNT = @SVector [SVector{13}([0, 2, 4,  7, 11, 16, 22, 29, 37, 46,  56,  67,  79]), SVector{13}([0, 4, 7, 12, 20, 30, 42, 56, 73, 92, 113, 136, 161])]
const LATE_MOVE_PRUNE_DEPTH = 12


function init_reduction_table()
    lmrtable = zeros(Int, (64, 64))
    for depth in 1:64
        for played in 1:64
            lmrtable[depth, played] = floor(Int, 0.6 + log(depth) * log(played) / 2.0)
        end
    end
    lmrtable
end
const LMRTABLE = init_reduction_table()



"""
    find_best_move()

Probe the tablebase if appropriate, or perform the absearch routine.
"""
function find_best_move(thread::Thread, ttable::TT_Table, ab_depth::Int)::Int
    board = thread.board
    # probe the tablebase
    if (count(occupied(board)) <= 5)
        res = tb_probe_root(board)
        if res !== TB_RESULT_FAILED
            thread.ss.tbhits += 1
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
                if promotion == TB_PROMOTES_QUEEN
                    push!(thread.pv[1], Move(move_from, move_to, __QUEEN_PROMO))
                    return eval
                elseif promotion == TB_PROMOTES_ROOK
                    push!(thread.pv[1], Move(move_from, move_to, __ROOK_PROMO))
                    return eval
                elseif promotion == TB_PROMOTES_BISHOP
                    push!(thread.pv[1], Move(move_from, move_to, __BISHOP_PROMO))
                    return eval
                elseif promotion == TB_PROMOTES_KNIGHT
                    push!(thread.pv[1], Move(move_from, move_to, __KNIGHT_PROMO))
                    return eval
                end
            else
                clear!(thread.pv[1])
                push!(thread.pv[1], Move(move_from, move_to, __NORMAL_MOVE))
                return eval
            end
        end
    end

    # else we do a search
    return iterative_deepening(thread, ttable, ab_depth)
end


function iterative_deepening(thread::Thread, ttable::TT_Table, max_depth::Int)::Int
    eval = -MATE
    for depth in 1:max_depth
        eval = aspiration_window(thread, ttable, depth, eval)
    end
    return eval
end


function aspiration_window(thread::Thread, ttable::TT_Table, depth::Int, eval::Int)::Int
    δ = 25
    if depth >= WINDOW_DEPTH
        α = max(-MATE, eval - δ)
        β = min(MATE, eval + δ)
    end
    return aspiration_window_internal(thread, ttable, depth, eval, -MATE, MATE, δ)
end

function aspiration_window_internal(thread::Thread, ttable::TT_Table, depth::Int, eval::Int, α::Int, β::Int, δ::Int)::Int
    while true
        eval = absearch(thread, ttable, α, β, depth, 0)

        # reporting
        thread.ss.depth = depth

        # window cond met
        if α < eval < β
            uci_report(thread, α, β, eval)
            return eval
        end

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

Quiescence search function.
"""
function qsearch(thread::Thread, ttable::TT_Table, α::Int, β::Int, ply::Int)::Int
    board = thread.board
    pv = thread.pv

    # ensure pv is clear
    clear!(thread.pv[ply + 1])

    # default val
    tt_eval = -MATE
    tt_move = MOVE_NONE

    thread.ss.seldepth = max(thread.ss.seldepth, ply)
    thread.ss.nodes += 1

    # draw checks
    if isdrawbymaterial(board) || is50moverule(board)
        return 0
    end

    # max depth cutoff
    if ply >= MAX_PLY
        return evaluate(board)
    end

    # probe the transposition table
    tt_entry = get(ttable.table, board.hash, NO_ENTRY)
    if tt_entry !== NO_ENTRY
        tt_eval = tt_entry.eval
        tt_move = tt_entry.move
        tt_value = ttvalue(tt_entry, ply)
        if (tt_entry.bound == BOUND_EXACT) ||
            ((tt_entry.bound == BOUND_LOWER) && (tt_value >= β)) ||
            ((tt_entry.bound == BOUND_UPPER) && (tt_value <= α))
            return tt_value
        end
    end

    if tt_eval !== -MATE
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
        return eval
    end

    # delta pruning
    margin = α - eval - Q_FUTILITY_MARGIN
    if optimistic_move_estimator(board) < margin
        return eval
    end

    moveorder = thread.moveorders[ply + 1]

    if ischeck(board)
        # we need evasions
        moveorder.type = NORMAL_TYPE
    else
        moveorder.type = NOISY_TYPE
        setmargin!(moveorder, max(1, margin))
    end

    best = qsearch_internal(thread, ttable, α, β, ply, tt_move, best)
    clear!(moveorder)
    return best
end


function qsearch_internal(thread::Thread, ttable::TT_Table, α::Int, β::Int, ply::Int, tt_move::Move, best::Int)::Int
    while true
        move = selectmove!(thread, tt_move, ply, thread.moveorders[ply + 1].type == NOISY_TYPE ? true : false)
        if move == MOVE_NONE
            break
        end

        u = apply_move!(thread, move)

        eval = -qsearch(thread, ttable, -β, -α, ply + 1)
        undo_move!(thread, move, u)

        # check for improvements
        if eval > best
            best = eval
            if eval > α
                α = best
                clear!(thread.pv[ply + 1])
                push!(thread.pv[ply + 1], move)
                updatepv!(thread.pv[ply + 1], thread.pv[ply + 2])
            end
        end

        # fail high?
        if α >= β
            clear!(thread.moveorders[ply + 1])
            return best
        end
    end
    return best
end


"""
    absearch()

Internals of `absearch()` routine.
"""
function absearch(thread::Thread, ttable::TT_Table, α::Int, β::Int, depth::Int, ply::Int)::Int
    board = thread.board
    pv_current = thread.pv[ply + 1]
    pv_future = thread.pv[ply + 2]

    # Set initial history stats to zero.
    hist = cmhist = fmhist = 0

    # Initial α value for later computation.
    init_α = α
    clear!(pv_current)

    # Is this the root node?
    isroot = iszero(ply)

    # Is this a pvnode?
    pvnode = β !== α + 1

    # Best evaluation defaults to -MATE.
    best = -MATE

    # default tt_eval, tt_move
    tt_eval = -MATE
    tt_move = MOVE_NONE

    # ensure +ve depth
    if depth < 0
        depth = 0
    end

    # enter quiescence search
    if iszero(depth) #&& !ischeck(board)
        q_eval = qsearch(thread, ttable, α, β, ply)
        return q_eval
    end

    # update thread details
    thread.ss.seldepth = max(thread.ss.seldepth, ply)
    thread.ss.nodes += 1

    # If this is not the root node, we can check for early exit conditions.
    if isroot == false

        # Draw checking.
        if isdrawbymaterial(board) || is50moverule(board) || isrepetition(board)
            return 0
        end

        # Max search depth check.
        if ply >= MAX_PLY
            eval = evaluate(board)
            return eval
        end

        # Check for mating evaluations, and prune for the best mate.
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
            return mate_α
        end
    end

    # Probe the transposition table.
    tt_entry = get(ttable.table, board.hash, NO_ENTRY)
    if tt_entry !== NO_ENTRY
        tt_eval = tt_entry.eval
        tt_value = ttvalue(tt_entry, ply)
        tt_move = tt_entry.move
        if (tt_entry.depth >= depth) && (depth == 0 || (pvnode == false))
            if (tt_entry.bound == BOUND_EXACT) ||
                ((tt_entry.bound == BOUND_LOWER) && (tt_value >= β)) ||
                ((tt_entry.bound == BOUND_UPPER) && (tt_value <= α))
                return tt_value
            end
        end
    end

    # If we have less than 5 pieces, we are in the realms of the Syzygy tablebase.
    # Attempt to probe.
    if (count(occupied(board)) <= 5) && !isroot
        _eval = tb_probe_wdl(board)
        if _eval !== TB_RESULT_FAILED
            thread.ss.tbhits += 1

            # Is the tablebase score losing?
            if iszero(_eval)
                eval = -MATE + MAX_PLY + ply + 1
                tt_bound = BOUND_UPPER

            # Is the tablebase a draw? Blessed / cursed loss and wins are draws
            elseif 1 <= _eval <= 3
                eval = 0
                tt_bound = BOUND_EXACT

            # Else, the tablebase is a win.
            else
                eval = MATE - MAX_PLY - ply - 1
                tt_bound = BOUND_LOWER
            end

            # add to transposition table
            tt_entry = TT_Entry(eval, MOVE_NONE, MAX_PLY - 1, tt_bound)
            if (tt_entry.bound == BOUND_EXACT) ||
                ((tt_entry.bound == BOUND_LOWER) && (eval >= β)) ||
                ((tt_entry.bound == BOUND_UPPER) && (eval <= α))
                setTTentry!(ttable, board.hash, tt_entry)
                return eval
            end
        end
    end

    # Set a static evaluation.
    if tt_eval !== -MATE
        eval = thread.evalstack[ply + 1] = tt_eval
    else
        eval = thread.evalstack[ply + 1] = evaluate(board)
    end

    # Reset killer moves for the upcoming ply.
    thread.killers[ply + 2][1] = MOVE_NONE
    thread.killers[ply + 2][0] = MOVE_NONE

    # Razoring.
    if (pvnode === false) && (ischeck(board) === false) && (depth <= RAZOR_DEPTH) && (eval + RAZOR_MARGIN < α)
        q_eval = qsearch(thread, ttable, α, β, ply)
        return q_eval
    end

    # Beta pruning.
    if (pvnode === false) && (ischeck(board) === false) && (depth <= BETA_PRUNE_DEPTH) && (eval - BETA_PRUNE_MARGIN * depth > β)
        return eval
    end

    # Null move pruning.
    # Check we are greater than depth 2, eval > β.
    # Not done in a pvnode.
    # Not done when in check.
    # Check we have non-pawn material left on the board.
    # Do not do more than 2 b2b null moves.
    if (depth >= 2) && (eval >= β) && !pvnode && !ischeck(board) &&
        !isempty(queens(board) | bishops(board) | knights(board) | rooks(board)) &&
        (ply > 0 ? (thread.movestack[ply] !== NULL_MOVE) : true)  &&
        (ply > 1 ? (thread.movestack[ply - 1] !== NULL_MOVE) : true) &&
        ((tt_entry === NO_ENTRY) || (tt_eval >= β))

        reduction = fld(depth, 5) + 3 + min(fld(eval - β, 150), 3)

        u = apply_null!(thread)

        cand_eval = -absearch(thread, ttable, -β, -β + 1, depth - reduction, ply + 1)
        undo_null!(thread, u)
        if (cand_eval >= β)
            return β
        end
    end

    best_move = MOVE_NONE

    # Check to see if the evaluation history has improved over the last few plies.
    # We can use this to modify some pruning heuristics later on.
    improving = ((ply >= 2) && (thread.evalstack[ply + 1] > thread.evalstack[ply - 1])) ? 2 : 1


    futility_margin = FUTILITY_MARGIN * depth
    see_quiet_margin = SEE_QUIET_MARGIN * depth
    see_noisy_margin = SEE_NOISY_MARGIN * depth^2
    skipquiets = false

    played = 0
    num_quiets = 0
    quiets_tried = thread.moveorders[ply + 1].quietstack
    moveorder = thread.moveorders[ply + 1]
    setmargin!(moveorder, 0)
    while true
        move = selectmove!(thread, tt_move, ply, skipquiets)

        if move == MOVE_NONE
            break
        end

        isquiet = !istactical(board, move)

        if isquiet
            hist, cmhist, fmhist = gethistory(thread, move, ply)
            num_quiets += 1
        end

        if isquiet && (best > -MATE + MAX_PLY)
            # Futility pruning
            if (depth <= FUTILITY_PRUNE_DEPTH) && (eval + futility_margin <= α) &&
                (hist + cmhist + fmhist < FUTILITY_LIMIT[improving])
                skipquiets = true
            end

            # quiet move futility pruning
            if (depth <= FUTILITY_PRUNE_DEPTH) && (eval + futility_margin + FUTILITY_MARGIN_NOHIST <= α)
                skipquiets = true
            end

            # Late move pruning.
            if (depth <= LATE_MOVE_PRUNE_DEPTH) && (num_quiets >= LATE_MOVE_COUNT[improving][depth + 1])
                skipquiets = true
            end

            # Counter move pruning
            if (depth <= COUNTER_PRUNE_DEPTH[improving]) && (cmhist < COUNTER_PRUNE_LIMIT[improving])
                continue
            end

            # Follow up move pruning
            if (depth <= FOLLOW_PRUNE_DEPTH[improving]) && (fmhist < FOLLOW_PRUNE_LIMIT[improving])
                continue
            end
        end

        # Prune moves which fail the static exchange evaluator.
        # Only ran if our best evaluation is not a mating line.
        if (static_exchange_evaluator(board, move, isquiet ? see_quiet_margin : see_noisy_margin) == false) &&
            (depth <= SEE_PRUNE_DEPTH) && (best > -MATE + MAX_PLY) && (moveorder.stage > STAGE_GOOD_NOISY)
            continue
        end

        u = apply_move!(thread, move)
        played += 1
        if isquiet
            push!(quiets_tried, move)
        end

        # Late move reduction calculations.
        # This allows later searches to probe to a lower depth under given scenarios.
        if isquiet && (depth > 2) && (played > 1)
            reduction = @inbounds LMRTABLE[min(depth, 64)][min(played, 64)]
            if !pvnode
                reduction += 1
            end
            # If we are not improving, increase the reduction depth.
            if isone(improving)
                reduction += 1
            end
            # Killer moves, and counter moves, are worth looking at more.
            if moveorder.stage < STAGE_INIT_QUIET
                reduction -= 1
            end
            # Alter if we are moving our king when in check.
            if ischeck(board) && (type(board[from(move)]) === KING)
                reduction += 1
            end
            # Adjust on the history
            reduction -= max(-2, min(2, fld(hist + cmhist + fmhist, 5000)))
            reduction = min(depth - 1, max(reduction, 1))
        else
            reduction = 1
        end

        # do we need an extension?
        if ischeck(board) && (isroot === false)
            newdepth = depth + 1
        else
            newdepth = depth
        end

        # perform search, taking into account LMR
        if reduction !== 1
            cand_eval = -absearch(thread, ttable, -α - 1, -α, newdepth - reduction, ply + 1)
        end
        if ((reduction !== 1) && (cand_eval > α)) || (reduction == 1 && !(pvnode && played == 1))
            cand_eval = -absearch(thread, ttable, -α - 1, -α, newdepth - 1, ply + 1)
        end
        if (pvnode && (played == 1 || cand_eval > α))
            cand_eval = -absearch(thread, ttable, -β, -α, newdepth - 1, ply + 1)
        end

        # Revert move.
        undo_move!(thread, move, u)

        # Have we found a better move?
        if cand_eval > best
            best = cand_eval
            best_move = move
            if cand_eval > α
                α = cand_eval
                clear!(pv_current)
                push!(pv_current, best_move)
                updatepv!(pv_current, pv_future)

                # fail high?
                if α >= β
                    break
                end
            end
        end

    end

    if iszero(played)
        if ischeck(board)
            # add ply to give an indication of the "fastest" mate
            best = -MATE + ply
        else
            # Stalemate is a draw.
            best = 0
        end
    end

    # Update the history heuristics.
    if (best >= β) && !istactical(board, best_move) && (best_move !== MOVE_NONE)
        updatehistory!(thread, quiets_tried, ply, depth^2)
    end

    clear!(moveorder)

    # Update the transposition table.
    if isroot == false
        tt_bound = best >= β ? BOUND_LOWER : (best > init_α ? BOUND_EXACT : BOUND_UPPER)
        tt_entry = TT_Entry(eval, best_move, depth, tt_bound)
        setTTentry!(ttable, board.hash, tt_entry)
    end

    return best
end


"""
    static_exchange_evaluator(board::Board, move::Move)

Returns true if a move passes a static exchange criteria, false otherwise.
"""
# should we think about pins?
function static_exchange_evaluator(board::Board, move::Move, threshold::Int)
    from_sqr = Int(from(move))
    to_sqr = Int(to(move))

    move_flag = flag(move)

    from_piece = piece(board, from_sqr)
    to_piece = piece(board, to_sqr)
    victim = (move_flag < 5) ? from_piece : makepiece(PieceType(flag(move) - 3), board.turn)

    occ = occupied(board)
    occ ⊻= (Bitboard(from_sqr) | Bitboard(to_sqr))

    if move_flag === __ENPASS
        occ ⊻= Bitboard(board.enpass)
    end

    attackers = (pawns(board) & pawnAttacks(!board.turn, to_sqr) & friendly(board)) |
    (pawns(board) & pawnAttacks(board.turn, to_sqr) & enemy(board)) |
    (knightMoves(to_sqr) & knights(board)) |
    (kingMoves(to_sqr) & kings(board))
    if !isempty(bishoplike(board))
        attackers |= (bishopMoves(to_sqr, occ) & bishoplike(board))
    end
    if !isempty(rooklike(board))
        attackers |= (rookMoves(to_sqr, occ) & rooklike(board))
    end

    attackers &= occ

    if isempty(attackers & enemy(board))
        return true
    end

    color = !board.turn

    balance = -threshold

    if to_piece !== BLANK
        @inbounds balance += PVALS_MG[type(to_piece).val]
    end

    if move_flag >= 5
        @inbounds balance += PVALS_MG[type(victim).val] - PVALS_MG[1]
    end

    if move_flag === __ENPASS
        @inbounds balance += PVALS_MG[1]
    end

    if balance < 0
        return false
    end

    @inbounds balance -= PVALS_MG[type(victim).val]

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
            if isempty(our_attackers & board[piecetype]) == false
                victim = piecetype
                break
            end
        end

        # remove our attacker
        occ ⊻= Bitboard(poplsb(our_attackers & board[victim])[1])

        # check for diag moves
        if (victim === PAWN || victim === BISHOP || victim === QUEEN)
            attackers |= bishopMoves(to_sqr, occ) & bishoplike(board)
        end

        # check for rank/file moves
        if (victim === ROOK || victim === QUEEN)
            attackers |= rookMoves(to_sqr, occ) & rooklike(board)
        end

        attackers &= occ

        balance = -balance - 1 - PVALS_MG[victim.val]
        color = !color

        if balance >= 0
            if (victim === KING) && (isempty(attackers & board[!color]) === false)
                color = !color
            end

            break
        end

    end
    # if it's your turn, you lost the SEE loop
    if board.turn === color
        return false
    else
        return true
    end
end


# delta pruning
function optimistic_move_estimator(board::Board)
    # assume pawn at minimum
    value = PVALS_MG[1]

    # find highest val targets
    for i in 5:-1:2
        piecetype = PieceType(i)
        if isempty(board[board.turn] & board[piecetype]) == false
            @inbounds value = PVALS_MG[i]
            break
        end
    end

    # promo checks
    if isempty(board[PAWN] & board[board.turn] & (board.turn == WHITE ? RANK_7 : RANK_2)) == false
        @inbounds value += PVALS_MG[5] - PVALS_MG[1]
    end

    return value
end


function updatepv!(pv_current::MoveStack, pv_future::MoveStack)
    for tmp_pv_move in pv_future
        push!(pv_current, tmp_pv_move)
    end
end
