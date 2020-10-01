const HistoryMaximum = 400
const HistoryMultiply = 32
const HistoryDivide = 512


"""
    updatehistory!(thread::Thread, quiets::MoveStack, ply::Int, depthbonus::Int)

A function to update the history heuristics stored in `thread`, by passing a list of attempted quiet moves, the current `ply`, and a depth bonus.
"""
function updatehistory!(thread::Thread, quietstried::MoveStack, ply::Int, depthbonus::Int)::Nothing
    colour = thread.board.turn.val
    @inbounds best_move = quietstried[quietstried.idx]

    # Extract counter move information.
    # If we haven't made a ply, we can't extract this.
    if ply > 0
        @inbounds counter = thread.movestack[ply]
        @inbounds cm_piece = thread.piecestack[ply]
        cm_to = to(counter)
    else
        counter = MOVE_NONE
        cm_piece = VOID
        cm_to = zero(UInt16)
    end

    # Extract move from 2 moves ago.
    # Must have made more than 1 ply to be able to do this.
    if ply > 1
        @inbounds follow = thread.movestack[ply - 1]
        @inbounds fm_piece = thread.piecestack[ply - 1]
        fm_to = to(follow)
    else
        follow = MOVE_NONE
        fm_piece = VOID
        fm_to = zero(UInt16)
    end

    # Set the killer moves.
    killer1 = thread.killer1s[ply + 1]
    if killer1 !== best_move
        @inbounds thread.killer2s[ply + 1] = killer1
        @inbounds thread.killer1s[ply + 1] = best_move
    end

    # Set the counter move.
    if (counter !== MOVE_NONE) && (counter !== NULL_MOVE)
        thread.cmtable[(!thread.board.turn).val][cm_piece.val][cm_to] = best_move
    end

    if quietstried.idx == 1 && depthbonus <= 1
        return
    end

    bonus = min(depthbonus, HistoryMaximum)

    # Below, the decision to split the cases up into 4 functions is so that the compiler can allow for SIMD optimisations.
    if (counter !== MOVE_NONE) && (counter !== NULL_MOVE) && (follow !== MOVE_NONE) && (follow !== NULL_MOVE)
        updatehistory_internal_countfollow!(thread, quietstried, bonus, best_move, colour, counter, cm_piece, cm_to, follow, fm_piece, fm_to)
    elseif (counter !== MOVE_NONE) && (counter !== NULL_MOVE)
        updatehistory_internal_count!(thread, quietstried, bonus, best_move, colour, counter, cm_piece, cm_to)
    elseif (follow !== MOVE_NONE) && (follow !== NULL_MOVE)
        updatehistory_internal_follow!(thread, quietstried, bonus, best_move, colour, follow, fm_piece, fm_to)
    else
        updatehistory_internal!(thread, quietstried, bonus, best_move, colour)
    end

    return
end


# Update the history heuristics for the case where we a counter move.
function updatehistory_internal_count!(thread::Thread, quietstried::MoveStack, bonus::Int, best_move::Move, colour::UInt8,
    counter::Move, cm_piece::PieceType, cm_to::Integer)::Nothing
    abs_δ = abs(bonus)
    @inbounds for move in quietstried
        δ = (move == best_move) ? bonus : -bonus
        sqr_to = to(move)
        sqr_from = from(move)
        move_piece = type(thread.board[sqr_from])

        mul_common = HistoryMultiply * δ

        # Update the butterfly table. (History heuristics)
        entry = thread.history[colour][sqr_from]
        entry[sqr_to] += mul_common - fld(entry[sqr_to] * abs_δ, HistoryDivide)

        # Update the counter move history table.
        entry_c = thread.counterhistory[cm_piece.val][cm_to][move_piece.val]
        entry_c[sqr_to] += mul_common - fld(entry_c[sqr_to] * abs_δ, HistoryDivide)
    end
    return
end


# Function to update history heuristics when there is a follow up move.
function updatehistory_internal_follow!(thread::Thread, quietstried::MoveStack, bonus::Int, best_move::Move, colour::UInt8,
    follow::Move, fm_piece::PieceType, fm_to::Integer)::Nothing
    abs_δ = abs(bonus)
    @inbounds for move in quietstried
        δ = (move == best_move) ? bonus : -bonus
        sqr_to = to(move)
        sqr_from = from(move)
        move_piece = type(thread.board[sqr_from])

        mul_common = HistoryMultiply * δ

        # Update the butterfly table. (History heuristics)
        entry = thread.history[colour][sqr_from]
        entry[sqr_to] += mul_common - fld(entry[sqr_to] * abs_δ, HistoryDivide)

        # Update the follow up move history table.
        entry_f = thread.followhistory[fm_piece.val][fm_to][move_piece.val]
        entry_f[sqr_to] += mul_common - fld(entry_f[sqr_to] * abs_δ, HistoryDivide)
    end
    return
end


# Internals to update the history heuristics when we have both a counter and follow up move.
function updatehistory_internal_countfollow!(thread::Thread, quietstried::MoveStack, bonus::Int, best_move::Move, colour::UInt8,
    counter::Move, cm_piece::PieceType, cm_to::Integer, follow::Move, fm_piece::PieceType, fm_to::Integer)::Nothing
    abs_δ = abs(bonus)
    @inbounds for move in quietstried
        δ = (move == best_move) ? bonus : -bonus
        sqr_to = to(move)
        sqr_from = from(move)
        move_piece = type(thread.board[sqr_from])

        mul_common = HistoryMultiply * δ

        # Update the butterfly table. (History heuristics)
        entry = thread.history[colour][sqr_from]
        entry[sqr_to] += mul_common - fld(entry[sqr_to] * abs_δ, HistoryDivide)

        # Update the counter move history table.
        entry_c = thread.counterhistory[cm_piece.val][cm_to][move_piece.val]
        entry_c[sqr_to] += mul_common - fld(entry_c[sqr_to] * abs_δ, HistoryDivide)

        # Update the follow up move history table.
        entry_f = thread.followhistory[fm_piece.val][fm_to][move_piece.val]
        entry_f[sqr_to] += mul_common - fld(entry_f[sqr_to] * abs_δ, HistoryDivide)
    end
    return
end


# Update the history heuristics for the case where we have a counter move, and no follow move.
function updatehistory_internal!(thread::Thread, quietstried::MoveStack, bonus::Int, best_move::Move, colour::UInt8)::Nothing
    abs_δ = abs(bonus)
    @inbounds for move in quietstried
        δ = (move == best_move) ? bonus : -bonus
        sqr_to = to(move)
        sqr_from = from(move)

        mul_common = HistoryMultiply * δ

        # Update the butterfly table. (History heuristics)
        entry = thread.history[colour][sqr_from]
        entry[sqr_to] += mul_common - fld(entry[sqr_to] * abs_δ, HistoryDivide)
    end
    return
end


"""
    gethistoryscores!(thread::Thread, moves::MoveStack, scores::Vector{Int}, idx_start::Int, idx_end::Int, ply::Int)

A function to extract the scores of quiet moves using the history heuristics. `idx_start` and `idx_end` determing the starting and ending indexes of the quiet moves in `moves`.
"""
function gethistoryscores!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int, ply::Int)::Nothing
    board = thread.board

    # extract one move ago
    if ply > 0
        @inbounds counter = thread.movestack[ply]
        @inbounds cm_piece = thread.piecestack[ply]
        cm_to = to(counter)
    else
        counter = MOVE_NONE
        cm_piece = VOID
        cm_to = zero(UInt16)
    end

    # extract move from two moves ago
    if ply > 1
        @inbounds follow = thread.movestack[ply - 1]
        @inbounds fm_piece = thread.piecestack[ply - 1]
        fm_to = to(follow)
    else
        follow = MOVE_NONE
        fm_piece = VOID
        fm_to = zero(UInt16)
    end

    # Below, the decision to split the cases up into 4 functions is so that the compiler can allow for SIMD optimisations.
    if (counter !== MOVE_NONE) && (counter !== NULL_MOVE) && (follow !== MOVE_NONE) && (follow !== NULL_MOVE)
        gethistoryscores_internal_histcountfollow!(thread, moves, scores, idx_start, idx_end, counter, cm_piece, cm_to, follow, fm_piece, fm_to)
        return
    elseif (counter !== MOVE_NONE) && (counter !== NULL_MOVE)
        gethistoryscores_internal_histcount!(thread, moves, scores, idx_start, idx_end, counter, cm_piece, cm_to)
        return
    elseif (follow !== MOVE_NONE) && (follow !== NULL_MOVE)
        gethistoryscores_internal_histfollow!(thread, moves, scores, idx_start, idx_end, follow, fm_piece, fm_to)
        return
    else
        gethistoryscores_internal_history!(thread, moves, scores, idx_start, idx_end)
        return
    end
end


# Internals for the case where we have no counter or follow up move.
function gethistoryscores_internal_history!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int)::Nothing
    @inbounds thist = thread.history[thread.board.turn.val]
    @inbounds for i in idx_start:idx_end
        # Extract useful move information.
        sqr_to = to(moves[i])
        sqr_from = from(moves[i])
        # Add the scores
        scores[i] = thist[sqr_from][sqr_to]
    end
    return
end


# Internals for the case where we have a counter move.
function gethistoryscores_internal_histcount!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int,
    counter::Move, cm_piece::PieceType, cm_to::Integer)::Nothing
    @inbounds thist = thread.history[thread.board.turn.val]
    @inbounds tchist = thread.counterhistory[cm_piece.val][cm_to]
    @inbounds for i in idx_start:idx_end
        # Extract useful move information.
        sqr_to = to(moves[i])
        sqr_from = from(moves[i])
        move_piece = type(thread.board[sqr_from])
        # Add the scores
        scores[i] = thist[sqr_from][sqr_to]
        scores[i] += tchist[move_piece.val][sqr_to]
    end
    return
end


# Internals for the case where we have a counter and a follow up move.
function gethistoryscores_internal_histcountfollow!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int,
    counter::Move, cm_piece::PieceType, cm_to::Integer, follow::Move, fm_piece::PieceType, fm_to::Integer)::Nothing
    @inbounds thist = thread.history[thread.board.turn.val]
    @inbounds tchist = thread.counterhistory[cm_piece.val][cm_to]
    @inbounds tfhist = thread.followhistory[fm_piece.val][fm_to]
    @inbounds for i in idx_start:idx_end
        # Extract useful move information.
        sqr_to = to(moves[i])
        sqr_from = from(moves[i])
        move_piece = type(thread.board[sqr_from])
        # Add the scores
        scores[i] = thist[sqr_from][sqr_to]
        scores[i] += tchist[move_piece.val][sqr_to]
        scores[i] += tfhist[move_piece.val][sqr_to]
    end
    return
end


# Internals for the case where we have a follow up move.
function gethistoryscores_internal_histfollow!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int,
    follow::Move, fm_piece::PieceType, fm_to::Integer)::Nothing
    @inbounds thist = thread.history[thread.board.turn.val]
    @inbounds tfhist = thread.followhistory[fm_piece.val][fm_to]
    @inbounds for i in idx_start:idx_end
        # Extract useful move information.
        sqr_to = to(moves[i])
        sqr_from = from(moves[i])
        move_piece = type(thread.board[sqr_from])
        # Add the scores
        scores[i] = thist[sqr_from][sqr_to]
        scores[i] += tfhist[move_piece.val][sqr_to]
    end
    return
end


function gethistory(thread::Thread, move::Move, ply::Int)
    board = thread.board

    sqr_to = to(move)
    sqr_from = from(move)
    move_piece = type(thread.board[sqr_from])

    # extract one move ago
    if ply > 0
        @inbounds counter = thread.movestack[ply]
        @inbounds cm_piece = thread.piecestack[ply]
        cm_to = to(counter)
    else
        counter = MOVE_NONE
        cm_piece = VOID
        cm_to = zero(UInt16)
    end

    # extract move from two moves ago
    if ply > 1
        @inbounds follow = thread.movestack[ply - 1]
        @inbounds fm_piece = thread.piecestack[ply - 1]
        fm_to = to(follow)
    else
        follow = MOVE_NONE
        fm_piece = VOID
        fm_to = zero(UInt16)
    end

    @inbounds hist = thread.history[thread.board.turn.val][sqr_from][sqr_to]

    if (counter == MOVE_NONE || counter == NULL_MOVE)
        cmhist = 0
    else
        @inbounds cmhist = thread.counterhistory[cm_piece.val][cm_to][move_piece.val][sqr_to]
    end

    if (follow == MOVE_NONE || follow == NULL_MOVE)
        fmhist = 0
    else
        @inbounds fmhist = thread.followhistory[fm_piece.val][fm_to][move_piece.val][sqr_to]
    end

    hist, cmhist, fmhist
end
