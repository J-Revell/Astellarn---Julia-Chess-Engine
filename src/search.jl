"""
    isearlytermination(thread::Thread)

Check if we have met a termination condition for the thread.
"""
function isearlytermination(thread::Thread)
    # Ensure, minimum depth 1 searched.
    # Ensure, minumum 1023+ nodes searched.
    # And that time management is up.
    (thread.ss.depth > 1) && ((thread.ss.nodes & 1023) == 1023) && (elapsedtime(thread.timeman) > thread.timeman.max_time) &&
    (!thread.timeman.isinfinite) && (thread.timeman.depth == 0)
end


"""
    find_best_move()

Probe the tablebase if appropriate, or perform the absearch routine.
"""
function find_best_move(thread::Thread, ttable::TT_Table, depth::Int)::Int
    board = thread.board

    # Probe the syzygy tablebase.
    # At present, it is assumed 5 men tablebases are available.
    # Also assumes we want to always probe.
    if (count(occupied(board)) <= 5)
        res = tb_probe_root(board)
        if res !== TB_RESULT_FAILED
            # Extract the move to the PV and return an evaluation.
            return interpret_syzygy(thread, res)
        end
    end

    ABORT_SIGNAL[] = false
    initTimeManagement!(thread.timeman)

    # If no tablebase result found, we proceed with iterative deepening and absearch.
    eval = iterative_deepening(thread, ttable, depth)
    ABORT_SIGNAL[] = true
    return eval
end


"""
    iterative_deepening(thread::Thread, ttable::TT_Table, max_depth::Int)

Performs the iterative deepening approach to absearch, and forms the main core of the engine routine.
"""
function iterative_deepening(thread::Thread, ttable::TT_Table, max_depth::Int)::Int
    eval = -MATE

    # We iterate through depths until we either:
    # a) reach the maximum depth, or
    # b) hit a time management constraint.
    best_move = MOVE_NONE
    for depth in 1:max_depth
        eval = aspiration_window(thread, ttable, depth, eval)
        if thread.stop
            thread.pv[1].list[1] = best_move
            break
        else
            best_move = thread.pv[1][1]
        end
        if (!thread.timeman.isinfinite && elapsedtime(thread.timeman) > thread.timeman.max_time) ||
            (thread.timeman.depth !== 0 && depth >= thread.timeman.depth) || istermination(thread.timeman)
            break
        end
    end
    return eval
end


"""
    aspiration_window(thread::Thread, ttable::TT_Table, depth::Int, eval::Int)

When operating within the iterative deepening framework, aspiration windows are used via calls to this function.
"""
function aspiration_window(thread::Thread, ttable::TT_Table, depth::Int, eval::Int)::Int
    δ = 25
    if depth >= WINDOW_DEPTH
        α = max(-MATE, eval - δ)
        β = min(MATE, eval + δ)
    end
    return aspiration_window_internal(thread, ttable, depth, eval, -MATE, MATE, δ)
end


# The internals of aspiration_window
function aspiration_window_internal(thread::Thread, ttable::TT_Table, depth::Int, eval::Int, α::Int, β::Int, δ::Int)::Int
    eval = eval
    while !thread.stop
        eval = absearch(thread, ttable, α, β, depth, 0, false)

        # reporting
        thread.ss.depth = depth

        # window cond met
        if ((α < eval < β) || (elapsedtime(thread.timeman) > 2.5)) && !thread.stop
            uci_report(thread, ttable, α, β, eval)
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
    return eval
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

    # Check for abort signal, or TimeManagement criteria.
    if isearlytermination(thread) || (ABORT_SIGNAL[] == true)
        thread.stop = true
        return 0
    end

    # Check if the current position is drawn. (Ignoring stalemate)
    if isdrawbymaterial(board) || is50moverule(board)
        return 0
    end

    # If we have reached the maximum search ply depth, we stop here.
    if ply >= MAX_PLY
        return evaluate(board, thread.pktable)
    end

    # probe the transposition table
    tt_entry = getTTentry(ttable, board.hash)
    if tt_entry !== NO_ENTRY
        tt_eval = Int(tt_entry.eval)
        tt_move = tt_entry.move
        tt_value = Int(ttvalue(tt_entry, ply))
        if (tt_entry.bound == BOUND_EXACT) ||
            ((tt_entry.bound == BOUND_LOWER) && (tt_value >= β)) ||
            ((tt_entry.bound == BOUND_UPPER) && (tt_value <= α))
            return tt_value
        end
    end

    # We may treat checks in qsearch specially.
    if ischeck(board)
        best = -MATE
        margin = 0
    else
        if tt_eval !== -MATE
            eval = thread.evalstack[ply + 1] = tt_eval
        elseif (ply > 0) && (thread.movestack[ply] == NULL_MOVE)
            eval = thread.evalstack[ply + 1] = -thread.evalstack[ply] + 2*TEMPO_BONUS
        else
            eval = thread.evalstack[ply + 1] = evaluate(board, thread.pktable)
        end

        best = eval

        # Evaluation pruning step.
        if eval > α
            α = eval
        end
        if α >= β
            return eval
        end

        # Delta pruning step.
        # If a "best case" (but perhaps non-existent) move, plus a small margin, is not enough to raise alpha, we stop.
        # Rather not perform this when in check.
        margin = α - eval - Q_FUTILITY_MARGIN
        if !ischeck(board) && (optimistic_move_estimator(board) < margin)
            return eval
        end
    end

    moveorder = thread.moveorders[ply + 1]

    if ischeck(board)
        # We need evasions, so generate quiet moves.
        init_normal_moveorder!(thread, tt_move, ply)
        @inbounds thread.killers[ply + 2][1] = MOVE_NONE
        @inbounds thread.killers[ply + 2][2] = MOVE_NONE
    else
        # We just look at noisy moves.
        # We make sure that the moves satisfy a SEE margin.
        init_noisy_moveorder!(thread, ply, max(1, margin))
    end

    best = qsearch_internal(thread, ttable, α, β, ply, tt_move, best)
    clear!(moveorder)
    return best
end


# The internals of qsearch.
function qsearch_internal(thread::Thread, ttable::TT_Table, α::Int, β::Int, ply::Int, tt_move::Move, best::Int)::Int
    # We can select skipquiets = false during qsearch, as if it's a NOISY type moveorder, quiets are skipped anyway.
    # Otherwise, quiets are needed to generate king check evasions.
    while ((move = selectmove!(thread, ply, false)) !== MOVE_NONE) && !thread.stop

        u = apply_move!(thread, move)

        eval = -qsearch(thread, ttable, -β, -α, ply + 1)
        undo_move!(thread, move, u)

        # Check for improvements, and update PV.
        # Ensure we met no stop signals.
        if (eval > best) && (!thread.stop)
            best = eval
            if eval > α
                α = best
                clear!(thread.pv[ply + 1])
                push!(thread.pv[ply + 1], move)
                updatepv!(thread.pv[ply + 1], thread.pv[ply + 2])
            end
        end

        # fail high?
        if (α >= β) && !thread.stop
            return best
        end
    end
    return best
end


"""
    absearch()

The main alpha-beta search function, containing all the pruning heuristics.
"""
function absearch(thread::Thread, ttable::TT_Table, α::Int, β::Int, depth::Int, ply::Int, cutnode::Bool)::Int
    board = thread.board
    @inbounds pv_current = thread.pv[ply + 1]
    @inbounds pv_future = thread.pv[ply + 2]

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

    # If depth reaches 0, we enter quiescence search.
    # If we are in check, we prefer to hold off one more ply.
    if iszero(depth) && !ischeck(board)
        q_eval = qsearch(thread, ttable, α, β, ply)
        return q_eval
    end

    # update thread details
    thread.ss.seldepth = max(thread.ss.seldepth, ply)
    thread.ss.nodes += 1

    # Check for abort signal, or TimeManagement criteria.
    if isearlytermination(thread) || (ABORT_SIGNAL[] == true)
        thread.stop = true
        return evaluate(board, thread.pktable)
    end

    # If this is not the root node, we can check for early exit conditions.
    if isroot == false

        # If we detect a draw, we can return an evaluation of zero.
        if isdrawbymaterial(board) || is50moverule(board) || isrepetition(board)
            return 0
        end

        # If we reach the max ply, we evaluate the board here and return.
        if ply >= MAX_PLY
            eval = evaluate(board, thread.pktable)
            return eval
        end

        # Check for mating evaluations, and prune for the best mate.
        # This avoids the need to look for sub-optimal continuations.
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
    tt_entry = getTTentry(ttable, board.hash)
    if tt_entry !== NO_ENTRY
        tt_eval = Int(tt_entry.eval)
        tt_value = Int(ttvalue(tt_entry, ply))
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
            if (tt_bound == BOUND_EXACT) ||
                ((tt_bound == BOUND_LOWER) && (eval >= β)) ||
                ((tt_bound == BOUND_UPPER) && (eval <= α))
                #tt_entry = TT_Entry(eval, MOVE_NONE, MAX_PLY - 1, tt_bound)
                setTTentry!(ttable, board.hash, eval, MOVE_NONE, MAX_PLY - 1, tt_bound)
                return eval
            end
        end
    end

    # Set a static evaluation.
    # If the last move was a NULL move, the evaluation is simply a change in 2*TEMPO_BONUS (flip a sign).
    if tt_eval !== -MATE
        eval = thread.evalstack[ply + 1] = tt_eval
    elseif (ply > 0) && (thread.movestack[ply] == NULL_MOVE)
        eval = thread.evalstack[ply + 1] = -thread.evalstack[ply] + 2*TEMPO_BONUS
    else
        eval = thread.evalstack[ply + 1] = evaluate(board, thread.pktable)
    end

    # Reset killer moves for the upcoming ply.
    @inbounds thread.killers[ply + 2][1] = MOVE_NONE
    @inbounds thread.killers[ply + 2][2] = MOVE_NONE

    # Razoring.
    # If the evaluation plus a small margin is still below alpha, we drop into the quiescence search.
    if (pvnode === false) && (ischeck(board) === false) && (depth <= RAZOR_DEPTH) && (eval + RAZOR_MARGIN <= α)
        q_eval = qsearch(thread, ttable, α, β, ply)
        return q_eval
    end

    # Check to see if the evaluation history has improved over the last few plies.
    # We can use this to modify some pruning heuristics later on.
    improving = ((ply >= 2) && (thread.evalstack[ply + 1] > thread.evalstack[ply - 1])) ? 2 : 1


    # Beta pruning.
    # If the evaluation minus a margin is still better than beta, we can prune here.
    if (pvnode === false) && (ischeck(board) === false) && (depth <= BETA_PRUNE_DEPTH) && (eval - BETA_PRUNE_MARGIN * (depth - improving + 1) >= β)
        return eval
    end

    # Null move pruning.
    # Check we are greater than depth 2, eval > β.
    # Not done in a pvnode.
    # Not done when in check.
    # Check we have non-pawn material left on the board.
    # Do not do more than 2 b2b null moves.
    if (depth >= 2) && (eval >= β) && !pvnode && !ischeck(board) &&
        (ply > 0 ? (thread.movestack[ply] !== NULL_MOVE) : true)  &&
        (ply > 1 ? (thread.movestack[ply - 1] !== NULL_MOVE) : true) &&
        ((tt_entry === NO_ENTRY) || (tt_eval >= β)) &&
        has_non_pawn_material(board)

        reduction = fld(depth, 5) + 3 + min(fld(eval - β, 150), 3)

        u = apply_null!(thread)

        cand_eval = -absearch(thread, ttable, -β, -β + 1, depth - reduction, ply + 1, !cutnode)
        undo_null!(thread, u)
        if (cand_eval >= β)
            return β
        end
    end

    best_move = MOVE_NONE

    # Set pruning variables used during the main loop.
    futility_margin = FUTILITY_MARGIN * (depth - improving + 1)
    see_quiet_margin = SEE_QUIET_MARGIN * depth
    see_noisy_margin = SEE_NOISY_MARGIN * depth^2
    skipquiets = false
    played = 0
    num_quiets = 0

    # Probcut pruning.
    # We are not in a PV-node.
    # A potential exists on the board such that it can beat β plus a margin.
    if !pvnode &&  (depth >= PROBCUT_DEPTH) && (abs(β) < (MATE - MAX_PLY)) &&
        (eval + optimistic_move_estimator(board) >= β + PROBCUT_MARGIN)
        probcut_count = 0
        raised_β = min(β + PROBCUT_MARGIN, MATE - MAX_PLY - 1)
        init_noisy_moveorder!(thread, ply, raised_β - eval)
        while ((move = selectmove!(thread, ply, false)) !== MOVE_NONE) && !thread.stop && (probcut_count < 2 + (cutnode ? 2 : 0))

            u = apply_move!(thread, move)
            # We check that the move holds in a qsearch.
            eval = -qsearch(thread, ttable, -β, -β + 1, ply + 1)
            # If it holds, and is above raised β, we do a fuller search.
            if eval >= raised_β
                eval = -absearch(thread, ttable, -β, -β + 1, depth - 4, ply + 1, !cutnode)
            end
            undo_move!(thread, move, u)

            if (eval >= raised_β)
                clear!(thread.moveorders[ply + 1])
                return eval
            end
        end
        clear!(thread.moveorders[ply + 1])
    end

    # Internal iterative deepening step.
    # Aim is to perform a quick search to fill the transposition table with potential moves.
    if (depth > 6) && (tt_move === MOVE_NONE)
        absearch(thread, ttable, α, β, depth - 7, ply + 1, cutnode)
        tt_entry = getTTentry(ttable, board.hash)
        if tt_entry !== NO_ENTRY
            tt_move = tt_entry.move
        end
    end

    # Init the move ordering
    init_normal_moveorder!(thread, tt_move, ply)
    @inbounds quiets_tried = thread.quietstack[ply + 1]
    @inbounds moveorder = thread.moveorders[ply + 1]
    while ((move = selectmove!(thread, ply, skipquiets)) !== MOVE_NONE) && !thread.stop

        isquiet = !istactical(board, move)

        # If we pick a quiet move, extract the history statistics.
        if isquiet
            hist, cmhist, fmhist = gethistory(thread, move, ply)
            num_quiets += 1
        end

        # Quiet move pruning steps.
        # We require that a non-mating line exists before pruning.
        # Opt not to prune if there is only king + pawn material remaining.
        if isquiet && (best > -MATE + MAX_PLY) && has_non_pawn_material(board)
            # Quiet move futility pruning step, using history.
            if (depth <= FUTILITY_PRUNE_DEPTH) && (eval + futility_margin <= α) &&
                (hist + cmhist + fmhist < FUTILITY_LIMIT[improving])
                skipquiets = true
            end

            # Quiet move futility pruning, using an additional margin.
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
        if (moveorder.stage > STAGE_GOOD_NOISY) && (depth <= SEE_PRUNE_DEPTH) && (best > -MATE + MAX_PLY) &&
            (static_exchange_evaluator(board, move, isquiet ? see_quiet_margin : see_noisy_margin) == false)
            continue
        end

        u = apply_move!(thread, move)
        played += 1
        if isquiet && (quiets_tried.idx < MAX_QUIET_TRACK)
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
            # Add reductions for cutnodes
            if cutnode
                reduction += 2
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
        if (ischeck(board))# || (isquiet && num_quiets <= 4 && cmhist >= 10000 && fmhist >= 10000)) && (isroot === false)
            newdepth = depth + 1
        else
            newdepth = depth
        end

        # perform search, taking into account LMR
        if reduction !== 1
            cand_eval = -absearch(thread, ttable, -α - 1, -α, newdepth - reduction, ply + 1, true)
        end
        if ((reduction !== 1) && (cand_eval > α)) || (reduction == 1 && !(pvnode && played == 1))
            cand_eval = -absearch(thread, ttable, -α - 1, -α, newdepth - 1, ply + 1, !cutnode)
        end
        if (pvnode && (played == 1 || ((cand_eval > α) && (isroot || cand_eval < β))))
            cand_eval = -absearch(thread, ttable, -β, -α, newdepth - 1, ply + 1, false)
        end

        # Revert move.
        undo_move!(thread, move, u)

        # Have we found a better move?
        # Ensure we encountered no stops, and update the PV.
        if (cand_eval > best) && (!thread.stop)
            best = cand_eval
            best_move = move
            if cand_eval > α
                α = cand_eval
                # Update the PV
                clear!(pv_current)
                push!(pv_current, best_move)
                updatepv!(pv_current, pv_future)

                # Did we fail high? Then we can break.
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
    # This is done when a quiet move fails high.
    if (best >= β) && (best_move !== MOVE_NONE) && !istactical(board, best_move)
        updatehistory!(thread, quiets_tried, ply, depth^2)
    end

    clear!(moveorder)
    clear!(quiets_tried)

    # Update the transposition table.
    # We don't do this at the root node.
    if isroot == false
        tt_bound = best >= β ? BOUND_LOWER : (best > init_α ? BOUND_EXACT : BOUND_UPPER)
        setTTentry!(ttable, board.hash, eval, best_move, depth, tt_bound)
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
    if isempty(pawns(board) & board[board.turn] & (board.turn == WHITE ? RANK_7 : RANK_2)) == false
        @inbounds value += PVALS_MG[5] - PVALS_MG[1]
    end

    return value
end


function updatepv!(pv_current::MoveStack, pv_future::MoveStack)
    for tmp_pv_move in pv_future
        push!(pv_current, tmp_pv_move)
    end
end
