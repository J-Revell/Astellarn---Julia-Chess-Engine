const STAGE_INIT = 0
const STAGE_TABLE = 1
const STAGE_SCORE = 2
const STAGE_GOOD_NOISY = 3
const STAGE_QUIET = 4
const STAGE_BAD_NOISY = 5
const STAGE_DONE = 6


const NORMAL_TYPE = 1
const NOISY_TYPE = 2

const MVVLVA_VALS = @SVector [100, 400, 425, 650, 1200, 0]


mutable struct MoveOrder
    type::Int
    stage::Int
    movestack::MoveStack
    values::Vector{Int}
    margin::Int
    noisy_size::Int
    quiet_size::Int
end
MoveOrder() = MoveOrder(NORMAL_TYPE, STAGE_INIT, MoveStack(150), zeros(Int, 150), 0, 0, 0)


function setmargin!(moveorder::MoveOrder, margin::Int)
    moveorder.margin = margin
end


function clear!(moveorder::MoveOrder)
    moveorder.type = NORMAL_TYPE
    moveorder.stage = STAGE_INIT
    clear!(moveorder.movestack)
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
    for i in 1:moveorder.noisy_size
        ptype_from = type(board[from(moveorder.movestack[i])])
        ptype_to = type(board[from(moveorder.movestack[i])])

        if ptype_to !== VOID
            @inbounds moveorder.values[i] = MVVLVA_VALS[ptype_to.val] - ptype_to.val
        end

        if flag(moveorder.movestack[i]) == __ENPASS
            @inbounds moveorder.values[i] += MVVLVA_VALS[1] - 1
        end

        if flag(moveorder.movestack[i]) == __QUEEN_PROMO
            @inbounds moveorder.values[i] += MVVLVA_VALS[5]
        end
    end
end


function selectmove!(moveorder::MoveOrder, board::Board, tt_move::Move)
    if moveorder.stage == STAGE_INIT
        gen_noisy_moves!(moveorder.movestack, board)
        moveorder.noisy_size = moveorder.movestack.idx

        if moveorder.type !== NOISY_TYPE
            gen_quiet_moves!(moveorder.movestack, board)
            moveorder.quiet_size = moveorder.movestack.idx - moveorder.noisy_size
            moveorder.stage = STAGE_TABLE
        else
            moveorder.stage = STAGE_SCORE
        end
    end

    # first pick ttable move
    if moveorder.stage == STAGE_TABLE
        if tt_move !== Move()
            moveorder.stage = STAGE_SCORE
            # robust check for hash nonsense (collisions)
            if tt_move ∈ moveorder.movestack
                return tt_move
            end
        else
            moveorder.stage = STAGE_SCORE
        end
    end

    if moveorder.stage == STAGE_SCORE
        MVVLVA!(moveorder, board)
        # to-do, insert score quiets
        moveorder.stage = STAGE_GOOD_NOISY
    end

    # pick noisy moves
    if moveorder.stage == STAGE_GOOD_NOISY
        if moveorder.noisy_size > 0
            idx = idx_bestmove(moveorder, 1, moveorder.movestack.idx)
            if moveorder.values[idx] >= 0
                move = popmove!(moveorder, idx)
                if static_exchange_evaluator(board, move, moveorder.margin) == false
                    moveorder.values[idx] = -1
                    return selectmove!(moveorder, board, tt_move)
                end
                return move
            else
                moveorder.stage = STAGE_QUIET
            end
        else
            moveorder.stage = STAGE_QUIET
        end
    end

    # pick quiet moves
    if moveorder.stage == STAGE_QUIET
        if moveorder.quiet_size > 0
            idx = idx_bestmove(moveorder, moveorder.noisy_size + 1, moveorder.movestack.idx)
            move = popmove!(moveorder, idx)
            return move
        else
            moveorder.stage = STAGE_BAD_NOISY
        end
    end

    # pick bad noisy moves
    if moveorder.stage == STAGE_BAD_NOISY
        if (moveorder.noisy_size > 0) && (moveorder.type !== NOISY_TYPE)
            move = popmove!(moveorder, 1)
            return move
        else
            moveorder.stage = STAGE_DONE
        end
    end

    # we are done
    if moveorder.stage == STAGE_DONE
        return MOVE_NONE
    end
end
