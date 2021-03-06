# wrappers of the fathom c library
# currently only Linux support for Astellarn

const TB_RESULT_FAILED = 0xFFFFFFFF


# constants defined in fathom
const TB_LOSS = 0
const TB_BLESSED_LOSS = 1
const TB_DRAW = 2
const TB_CURSED_WIN = 3
const TB_WIN = 4

const TB_PROMOTES_NONE = 0
const TB_PROMOTES_QUEEN = 1
const TB_PROMOTES_ROOK = 2
const TB_PROMOTES_BISHOP = 3
const TB_PROMOTES_KNIGHT = 4

const TB_RESULT_WDL_MASK = 0x0000000F
const TB_RESULT_TO_MASK = 0x000003F0
const TB_RESULT_FROM_MASK = 0x0000FC00
const TB_RESULT_PROMOTES_MASK = 0x00070000
const TB_RESULT_EP_MASK = 0x00080000
const TB_RESULT_DTZ_MASK = 0xFFF00000
const TB_RESULT_WDL_SHIFT = 0
const TB_RESULT_TO_SHIFT = 4
const TB_RESULT_FROM_SHIFT = 10
const TB_RESULT_PROMOTES_SHIFT = 16
const TB_RESULT_EP_SHIFT = 19
const TB_RESULT_DTZ_SHIFT = 20


function TB_GET_WDL(res::UInt32)
    Int((res & TB_RESULT_WDL_MASK) >> TB_RESULT_WDL_SHIFT)
end


function TB_GET_TO(res::UInt32)
    Int(((res & TB_RESULT_TO_MASK) >> TB_RESULT_TO_SHIFT) + 1)
end


function TB_GET_FROM(res::UInt32)
    Int(((res & TB_RESULT_FROM_MASK) >> TB_RESULT_FROM_SHIFT) + 1)
end


function TB_GET_PROMOTES(res::UInt32)
    Int((res & TB_RESULT_PROMOTES_MASK) >> TB_RESULT_PROMOTES_SHIFT)
end


# check output of this function
function TB_GET_EP(res::UInt32)
    Int(((res & TB_RESULT_EP_MASK) >> TB_RESULT_EP_SHIFT) + 1)
end


function TB_GET_DTZ(res::UInt32)
    Int((res & TB_RESULT_DTZ_MASK) >> TB_RESULT_DTZ_SHIFT)
end


function tb_init(syzygypath::S)::Bool where S <: Union{String, SubString}
    return ccall((:tb_init, FATHOM_PATH), UInt8, (Ptr{UInt8},), syzygypath)
end


function tb_free()
    return ccall((:tb_free, FATHOM_PATH), Cvoid, ())
end


# We can't call static inline function :tb_probe_wdl, so we use :tb_probe_wdl_impl as a workaround.
# Because of the above, care is taken to ensure we conform to syzygy rules.
function tb_probe_wdl(board::Board)::UInt32
    if iszero(board.enpass) === false
        return TB_RESULT_FAILED
    elseif iszero(board.castling) === false
        return TB_RESULT_FAILED
    elseif iszero(board.halfmovecount) === false
        return TB_RESULT_FAILED
    else
        return ccall((:tb_probe_wdl_impl, FATHOM_PATH), Cuint, (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt32, UInt8,),
            board[WHITE].val, board[BLACK].val, board[KING].val, board[QUEEN].val, board[ROOK].val, board[BISHOP].val, board[KNIGHT].val, board[PAWN].val,
            0, board.turn == WHITE ? 1 : 0)
    end
end


# We can't call static inline function :tb_probe_root, so we use :tb_probe_root_impl as a workaround.
# Because of the above, care is taken to ensure we conform to syzygy rules.
function tb_probe_root(board::Board)::UInt32
    if iszero(board.castling) === false
        return TB_RESULT_FAILED
    else
        return ccall((:tb_probe_root_impl, FATHOM_PATH), Cuint, (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt32, UInt32, UInt8, UInt32, ),
            board[WHITE].val, board[BLACK].val, board[KING].val, board[QUEEN].val, board[ROOK].val, board[BISHOP].val, board[KNIGHT].val, board[PAWN].val,
            board.halfmovecount, board.enpass, board.turn == WHITE ? 1 : 0, 0)
    end
end


# Called at the root node if a TB result is returned
function interpret_syzygy(thread::Thread, res::UInt32)
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
