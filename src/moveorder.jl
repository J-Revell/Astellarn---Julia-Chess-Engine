const STAGE_TABLE = 1
const STAGE_GEN_NOISY = 2
const STAGE_NOISY = 3
const STAGE_GEN_QUIET = 4
const STAGE_QUIET = 5
const STAGE_DONE = 6


mutable struct MoveOrder
    stage::Int
    movestack::MoveStack
    values::Vector{Int}
    noisy_size::Int
    quiet_size::Int
end
MoveOrder() = MoveOrder(STAGE_TABLE, MoveStack(150), zeros(Int, 150), 0, 0)


function clear!(moveorder::MoveOrder)
    moveorder.stage = STAGE_TABLE
    clear!(moveorder.movestack)
    moveorder.values .= zeros(Int, 150)
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


function selectmove!(moveorder::MoveOrder, board::Board, tt_move::Move)
    # first pick ttable move
    if moveorder.stage == STAGE_TABLE
        if tt_move !== Move()
            moveorder.stage = STAGE_GEN_NOISY
            # robust check for hash nonsense (collisions)
            if move_is_pseudo_legal(board, tt_move)
                return tt_move
            end
        else
            moveorder.stage = STAGE_GEN_NOISY
        end
    end

    # generate noisy moves
    if moveorder.stage == STAGE_GEN_NOISY
        gen_noisy_moves!(moveorder.movestack, board)
        # TO-DO insert move score here
        moveorder.noisy_size = moveorder.movestack.idx
        moveorder.stage = STAGE_NOISY
    end

    # pick noisy moves
    if moveorder.stage == STAGE_NOISY
        if moveorder.noisy_size > 0
            idx = idx_bestmove(moveorder, 1, moveorder.movestack.idx)
            move = popmove!(moveorder, idx)
            return move
        else
            moveorder.stage = STAGE_GEN_QUIET
        end
    end

    # generate quiet moves
    if moveorder.stage == STAGE_GEN_QUIET
        gen_quiet_moves!(moveorder.movestack, board)
        # TO-DO insert move score here
        moveorder.quiet_size = moveorder.movestack.idx - moveorder.noisy_size
        moveorder.stage = STAGE_QUIET
    end

    # pick quiet moves
    if moveorder.stage == STAGE_QUIET
        if moveorder.quiet_size > 0
            idx = idx_bestmove(moveorder, moveorder.noisy_size + 1, moveorder.movestack.idx)
            move = popmove!(moveorder, idx)
            return move
        else
            moveorder.stage = STAGE_DONE
        end
    end

    # we are done
    if moveorder.stage == STAGE_DONE
        return Move()
    end
end
