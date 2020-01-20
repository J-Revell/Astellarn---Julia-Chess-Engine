const STAGE_TABLE = UInt8(0)
const STAGE_INIT_NOISY = UInt8(1)
const STAGE_GOOD_NOISY = UInt8(2)
const STAGE_KILLER_1 = UInt8(3)
const STAGE_KILLER_2 = UInt8(4)
const STAGE_COUNTER = UInt8(5)
const STAGE_INIT_QUIET = UInt8(6)
const STAGE_QUIET = UInt8(7)
const STAGE_BAD_NOISY = UInt8(8)
const STAGE_DONE = UInt8(9)


const NORMAL_TYPE = UInt8(1)
const NOISY_TYPE = UInt8(2)


const MVVLVA_VALS = @SVector Int32[100, 450, 450, 675, 1300, 5000]


MoveOrder() = MoveOrder(NORMAL_TYPE, STAGE_TABLE, MoveStack(MAX_MOVES), zeros(Int32, MAX_MOVES),
    0, 0, 0, MOVE_NONE, MOVE_NONE, MOVE_NONE, MOVE_NONE)


function setmargin!(moveorder::MoveOrder, margin::Int)
    moveorder.margin = margin
end


function clear!(moveorder::MoveOrder)
    moveorder.type = NORMAL_TYPE
    moveorder.stage = STAGE_TABLE
    clear!(moveorder.movestack)
    moveorder.noisy_size = 0
    moveorder.quiet_size = 0
end


# find the index of the best scored move in the movestack
function idx_bestmove(moveorder::MoveOrder, idx_start::Int, idx_end::Int)
    best_idx = idx_start
    best_val = moveorder.values[best_idx]
    @inbounds for i in (idx_start + 1):idx_end
        if (cv = moveorder.values[i]) >= best_val
            best_idx = i
            best_val = cv
        end
    end
    return best_idx
end


function popmove!(moveorder::MoveOrder, idx::Int)
    move = moveorder.movestack[idx]
    @inbounds for i in idx:moveorder.movestack.idx
        moveorder.movestack.list[i] = moveorder.movestack.list[i + 1]
        moveorder.values[i] = moveorder.values[i + 1]
    end
    moveorder.movestack.idx -= 1
    if idx <= moveorder.noisy_size
        moveorder.noisy_size -= 1
    elseif moveorder.noisy_size < idx
        moveorder.quiet_size -= 1
    end
    return move
end

# function sortmoves!(moveorder::MoveOrder, idx_start::Int, idx_end::Int)
#     idx = Vector{Int}(undef, max(0, idx_end-idx_start+1))
#     m = view(moveorder.movestack, idx_start:idx_end)
#     v = view(moveorder.values, idx_start:idx_end)
#     sortperm!(idx, v, rev = true)
#     permute!(m, idx)
#     permute!(v, idx)
# end

function MVVLVA!(moveorder::MoveOrder, board::Board)
    @inbounds for i in 1:moveorder.noisy_size
        sqr_from = from(moveorder.movestack[i])
        sqr_to = to(moveorder.movestack[i])
        ptype_from = type(board[sqr_from])
        ptype_to = type(board[sqr_to])

        if ptype_to !== VOID
            moveorder.values[i] = MVVLVA_VALS[ptype_to.val] - ptype_from.val
        end

        if flag(moveorder.movestack[i]) === __ENPASS
            moveorder.values[i] = MVVLVA_VALS[1] - one(Int32)
        end

        if flag(moveorder.movestack[i]) === __QUEEN_PROMO
            moveorder.values[i] += MVVLVA_VALS[5]
        end
    end
end


function init_noisy_moveorder!(thread::Thread, ply::Int, margin::Int)
    board = thread.board
    moveorder = thread.moveorders[ply + 1]
    moveorder.type = NOISY_TYPE
    moveorder.margin = margin
    # Set move heuristics
    moveorder.tt_move = MOVE_NONE
    moveorder.counter = MOVE_NONE
    moveorder.killer1 = MOVE_NONE
    moveorder.killer2 = MOVE_NONE
    # Generate moves
    gen_noisy_moves!(moveorder.movestack, board)
    moveorder.noisy_size = moveorder.movestack.idx
    moveorder.stage = STAGE_INIT_NOISY
    return
end


function init_normal_moveorder!(thread::Thread, tt_move::Move, ply::Int)
    board = thread.board
    moveorder = thread.moveorders[ply + 1]
    moveorder.type = NORMAL_TYPE
    moveorder.margin = 0
    # Set move heuristics
    moveorder.tt_move = tt_move
    if ply > 0
        @inbounds previous_move = thread.movestack[ply]
        @inbounds previous_piece = thread.piecestack[ply]
    else
        previous_move = MOVE_NONE
        previous_piece = VOID
    end
    previous_to = to(previous_move)
    if (previous_move === MOVE_NONE || previous_move === NULL_MOVE)
         moveorder.counter = MOVE_NONE
    else
        @inbounds moveorder.counter = thread.cmtable[(!board.turn).val][previous_piece.val][previous_to]
    end
    @inbounds moveorder.killer1 = thread.killers[ply + 1][1]
    @inbounds moveorder.killer2 = thread.killers[ply + 1][2]
    # generate moves
    gen_noisy_moves!(moveorder.movestack, board)
    moveorder.noisy_size = moveorder.movestack.idx
    gen_quiet_moves!(moveorder.movestack, board)
    moveorder.quiet_size = moveorder.movestack.idx - moveorder.noisy_size
    moveorder.stage = STAGE_TABLE
    return
end


function selectmove!(thread::Thread, ply::Int, skipquiets::Bool)::Move
    moveorder = thread.moveorders[ply + 1]
    board = thread.board

    # First pick the transposition table move.
    # However, due to collisions and current TT implementation it may not always be legal.
    # Therefore verify legality, by *first* generating possible moves, and checking it exists.
    if moveorder.stage === STAGE_TABLE
        moveorder.stage = STAGE_INIT_NOISY
        if (moveorder.tt_move !== MOVE_NONE) && (moveorder.tt_move ∈ moveorder.movestack)
            return moveorder.tt_move
        end
    end

    # Score the noisy moves
    # Score the moves using MVV-LVA heuristics.
    if moveorder.stage === STAGE_INIT_NOISY
        MVVLVA!(moveorder, board)
        # sortmoves!(moveorder, 1, moveorder.noisy_size)
        moveorder.stage = STAGE_GOOD_NOISY
    end

    # Pick the noisy moves which pass MVV-LVA, and a static_exchange_evaluator runby.
    # Do not play TT moves twice.
    if moveorder.stage === STAGE_GOOD_NOISY
        if moveorder.noisy_size > 0
            idx = idx_bestmove(moveorder, 1, moveorder.noisy_size)
            if moveorder.values[idx] >= 0
                if !ischeck(board) && (static_exchange_evaluator(board, moveorder.movestack[idx], moveorder.margin) == false)
                    moveorder.values[idx] = -1
                    return selectmove!(thread, ply, skipquiets)
                end
                move = popmove!(moveorder, idx)
                if move === moveorder.tt_move
                    return selectmove!(thread, ply, skipquiets)
                else
                    # Avoid playing killer or counter moves twice.
                    (move == moveorder.killer1) && (moveorder.killer1 = MOVE_NONE)
                    (move == moveorder.killer2) && (moveorder.killer2 = MOVE_NONE)
                    (move == moveorder.counter) && (moveorder.counter = MOVE_NONE)
                    return move
                end
            else
                moveorder.stage = STAGE_KILLER_1
            end
        else
            moveorder.stage = STAGE_KILLER_1
        end
    end

    # If skipquiets flag is set, now is the time to skip a few stages.
    if skipquiets || (moveorder.type === NOISY_TYPE)
        moveorder.stage = STAGE_BAD_NOISY
    end

    # First killer move stage.
    if moveorder.stage === STAGE_KILLER_1
        if (moveorder.killer1 !== moveorder.tt_move) && (moveorder.killer1 ∈ moveorder.movestack)
            moveorder.stage = STAGE_KILLER_2
            return moveorder.killer1
        else
            moveorder.stage = STAGE_KILLER_2
        end
    end

    # Second killer move stage.
    if moveorder.stage === STAGE_KILLER_2
        if (moveorder.killer2 !== moveorder.tt_move) && (moveorder.killer2 ∈ moveorder.movestack)
            moveorder.stage = STAGE_COUNTER
            return moveorder.killer2
        else
            moveorder.stage = STAGE_COUNTER
        end
    end

    # Counter moves stage.
    if moveorder.stage === STAGE_COUNTER
        if (moveorder.counter !== moveorder.tt_move) && (moveorder.counter !== moveorder.killer1) &&
            (moveorder.counter !== moveorder.killer2) && (moveorder.counter ∈ moveorder.movestack)
            moveorder.stage = STAGE_INIT_QUIET
            return moveorder.counter
        else
            moveorder.stage = STAGE_INIT_QUIET
        end
    end

    # Score all quiet moves.
    # Score using the history heuristics.
    if moveorder.stage === STAGE_INIT_QUIET
        gethistoryscores!(thread, moveorder.movestack, moveorder.values, moveorder.noisy_size + 1, moveorder.movestack.idx, ply)
        # sortmoves!(moveorder, moveorder.noisy_size + 1, moveorder.movestack.idx)
        moveorder.stage = STAGE_QUIET
    end

    # Pick the best quiet moves.
    # Do not play TT move twice.
    if moveorder.stage === STAGE_QUIET
        if moveorder.quiet_size > 0
            idx = idx_bestmove(moveorder, moveorder.noisy_size + 1, moveorder.movestack.idx)
            move = popmove!(moveorder, idx)
            if (move == moveorder.tt_move) || ((move == moveorder.killer1) ||
                (move == moveorder.killer1) || (move == moveorder.counter))
                return selectmove!(thread, ply, skipquiets)
            else
                return move
            end
        else
            moveorder.stage = STAGE_BAD_NOISY
        end
    end

    # Lastly, if we are left with noisy moves that failed STAGE_GOOD_NOISY, we can pick them now.
    if moveorder.stage === STAGE_BAD_NOISY
        if (moveorder.noisy_size > 0) && (moveorder.type !== NOISY_TYPE)
            move = popmove!(moveorder, 1)
            if (move == moveorder.tt_move) || (!skipquiets && ((move == moveorder.killer1) ||
                (move == moveorder.killer2) || (move == moveorder.counter)))
                return selectmove!(thread, ply, skipquiets)
            else
                return move
            end
        else
            moveorder.stage = STAGE_DONE
        end
    end

    # We are done
    if moveorder.stage === STAGE_DONE
        return MOVE_NONE
    end

    # If return type == Nothing, something went wrong.
end
