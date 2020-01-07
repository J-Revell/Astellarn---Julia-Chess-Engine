const HistoryMaximum = 400
const HistoryMultiply = 32
const HistoryDivide = 512

function updatehistory!(thread::Thread, quietstried::MoveStack, ply::Int, depthbonus::Int)
    colour = thread.board.turn.val
    best_move = quietstried[end]

    # extract counter move info
    # counter = thread.movestack[ply - 1]
    # cm_piece = thread.piecestack[ply - 1]
    # cm_to = to(counter)

    # extract move from two moves ago
    # follow = thread.movestack[ply - 2]
    # fm_piece = thread.piecestack[ply - 2]
    # fm_to = to(follow)

    bonus = max(depthbonus, HistoryMaximum)

    @inbounds for move in quietstried
        δ = (move == best_move) ? bonus : -bonus
        sqr_to = to(move)
        sqr_from = from(move)
        move_piece = type(thread.board[sqr_from])

        # Update the butterfly table
        entry = thread.history[colour][sqr_from][sqr_to]
        entry += HistoryMultiply * δ - entry * fld(abs(δ), HistoryDivide)
        thread.history[colour][sqr_from][sqr_to] = entry
    end
    return
end

function gethistoryscores!(thread::Thread, moves::MoveStack, scores::Vector{Int32}, idx_start::Int, idx_end::Int, ply::Int)
    board = thread.board
    @inbounds @simd for i in idx_start:idx_end
        sqr_to = to(moves[i])
        sqr_from = from(moves[i])
        move_piece = type(thread.board[sqr_from])
        scores[i] = thread.history[board.turn.val][sqr_from][sqr_to]
    end
end
