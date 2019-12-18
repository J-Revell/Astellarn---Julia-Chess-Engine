# wrappers of the fathom c library
# currently only Linux support for Astellarn

const FATHOM_PATH = "./Fathom/src/apps/fathom.linux"

function tb_init(syzygypath::String)::Bool
    return ccall((:tb_init, FATHOM_PATH), UInt8, (Ptr{UInt8},), syzygypath)
end

function tb_free()
    ccall((:tb_free, FATHOM_PATH), Cvoid, ())
end

function tb_probe_wdl(board::Board)
    return ccall((:tb_probe_wdl_impl, FATHOM_PATH), Cuint, (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt32, UInt8,),
        board[WHITE].val, board[BLACK].val, board[KING].val, board[QUEEN].val, board[ROOK].val, board[BISHOP].val, board[KNIGHT].val, board[PAWN].val,
        0, board.turn == WHITE ? 1 : 0)
end
