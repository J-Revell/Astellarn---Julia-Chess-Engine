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

MoveOrder() = MoveOrder(NORMAL_TYPE, STAGE_TABLE, MoveStack(150),  MoveStack(150), zeros(Int32, 150), 0, 0, 0)

function setmargin!(moveorder::MoveOrder, margin::Int)
    moveorder.margin = margin
end


function clear!(moveorder::MoveOrder)
    moveorder.type = NORMAL_TYPE
    moveorder.stage = STAGE_TABLE
    clear!(moveorder.movestack)
    clear!(moveorder.quietstack)
    #moveorder.values .= zeros(Int, 150) # not needed if idxs are reset
    moveorder.noisy_size = 0
    moveorder.quiet_size = 0
end


# find the index of the best scored move in the movestack
function idx_bestmove(moveorder::MoveOrder, idx_start::Int, idx_end::Int)
    best = idx_start
    for i in (idx_start + 1):idx_end
        if moveorder.values[i] > moveorder.values[best]
            best = i
        end
    end
    return best
end


function popmove!(moveorder::MoveOrder, idx::Int)
    move = moveorder.movestack[idx]
    for i in idx:moveorder.movestack.idx
        @inbounds moveorder.movestack.list[i] = moveorder.movestack.list[i + 1]
        @inbounds moveorder.values[i] = moveorder.values[i + 1]
    end
    moveorder.movestack.idx -= 1
    if idx <= moveorder.noisy_size
        moveorder.noisy_size -= 1
    elseif moveorder.noisy_size < idx
        moveorder.quiet_size -= 1
    end
    return move
end


function MVVLVA!(moveorder::MoveOrder, board::Board)
    @inbounds for i in 1:moveorder.noisy_size
        sqr_from = from(moveorder.movestack[i])
        ptype_from = type(board[sqr_from])
        ptype_to = type(board[sqr_from])

        if ptype_to !== VOID
            moveorder.values[i] = MVVLVA_VALS[ptype_to.val] - ptype_to.val
        end

        if flag(moveorder.movestack[i]) === __ENPASS
            moveorder.values[i] += MVVLVA_VALS[1] - one(Int32)
        end

        if flag(moveorder.movestack[i]) === __QUEEN_PROMO
            moveorder.values[i] += MVVLVA_VALS[5]
        end
    end
end


function selectmove!(thread::Thread, tt_move::Move, ply::Int, skipquiets::Bool)::Move
    moveorder = thread.moveorders[ply + 1]
    board = thread.board

    # Get the counter move, if existing.
    if moveorder.type !== NOISY_TYPE
        if ply > 0
            previous_move = thread.movestack[ply]
            previous_piece = thread.piecestack[ply]
        else
            previous_move = MOVE_NONE
            previous_piece = VOID
        end
        previous_to = to(previous_move)
        if (previous_move === MOVE_NONE || previous_move === NULL_MOVE)
            counter = MOVE_NONE
        else
            counter = thread.cmtable[(!board.turn).val][previous_piece.val][previous_to]
        end
        killer1 = thread.killers[ply + 1][1]
        killer2 = thread.killers[ply + 1][2]
    else
        counter = MOVE_NONE
        killer1 = MOVE_NONE
        killer2 = MOVE_NONE
    end


    # First pick the transposition table move.
    # However, due to collisions and current TT implementation it may not always be legal.
    # Therefore verify legality, by *first* generating possible moves, and checking it exists.
    if moveorder.stage === STAGE_TABLE
        gen_noisy_moves!(moveorder.movestack, board)
        moveorder.noisy_size = moveorder.movestack.idx
        gen_quiet_moves!(moveorder.movestack, board)
        moveorder.quiet_size = moveorder.movestack.idx - moveorder.noisy_size
        moveorder.stage = STAGE_INIT_NOISY
        if (moveorder.type !== NOISY_TYPE) && (tt_move !== MOVE_NONE) && (tt_move ∈ moveorder.movestack)
            return tt_move
        end
    end

    # Score the noisy moves
    # Score the moves using MVV-LVA heuristics.
    if moveorder.stage === STAGE_INIT_NOISY
        MVVLVA!(moveorder, board)
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
                    return selectmove!(thread, tt_move, ply, skipquiets)
                end
                move = popmove!(moveorder, idx)
                if (moveorder.type !== NOISY_TYPE) && (move == tt_move)
                    return selectmove!(thread, tt_move, ply, skipquiets)
                else
                    # Avoid playing killer or counter moves twice.
                    (move == killer1) && (killer1 = MOVE_NONE)
                    (move == killer2) && (killer2 = MOVE_NONE)
                    (move == counter) && (counter = MOVE_NONE)
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
        if (killer1 !== tt_move) && (killer1 ∈ moveorder.movestack)
            moveorder.stage = STAGE_KILLER_2
            return killer1
        else
            moveorder.stage = STAGE_KILLER_2
        end
    end

    # Second killer move stage.
    if moveorder.stage === STAGE_KILLER_2
        if (killer2 !== tt_move) && (killer2 ∈ moveorder.movestack)
            moveorder.stage = STAGE_COUNTER
            return killer2
        else
            moveorder.stage = STAGE_COUNTER
        end
    end

    # Counter moves stage.
    if moveorder.stage === STAGE_COUNTER
        if (counter !== tt_move) && (counter !== killer1) && (counter !== killer2) && (counter ∈ moveorder.movestack)
            moveorder.stage = STAGE_INIT_QUIET
            return counter
        else
            moveorder.stage = STAGE_INIT_QUIET
        end
    end

    # Score all quiet moves.
    # Score using the history heuristics.
    if moveorder.stage === STAGE_INIT_QUIET
        gethistoryscores!(thread, moveorder.movestack, moveorder.values, moveorder.noisy_size + 1, moveorder.movestack.idx, ply)
        moveorder.stage = STAGE_QUIET
    end

    # Pick the best quiet moves.
    # Do not play TT move twice.
    if moveorder.stage === STAGE_QUIET
        if moveorder.quiet_size > 0
            idx = idx_bestmove(moveorder, moveorder.noisy_size + 1, moveorder.movestack.idx)
            move = popmove!(moveorder, idx)
            if (move == tt_move) || ((move == killer1) ||  (move == killer1) || (move == counter))
                return selectmove!(thread, tt_move, ply, skipquiets)
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
            if (move == tt_move) || (!skipquiets && ((move == killer1) ||  (move == killer2) || (move == counter)))
                return selectmove!(thread, tt_move, ply, skipquiets)
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
