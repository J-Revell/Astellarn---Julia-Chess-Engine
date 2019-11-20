rookMove_N(rook::UInt64) = rook << 8
rookMove_S(rook::UInt64) = rook >> 8
rookMove_E(rook::UInt64) = ~FILE_A & (rook >> 1)
rookMove_W(rook::UInt64) = ~FILE_H & (rook << 1)

const ROOK_MOVE_FUNCTIONS = @SVector Function[rookMove_N, rookMove_S, rookMove_E, rookMove_W]

# initialise the tables on startup
const ROOK_TABLE = initSlidingTable(Vector{Vector{UInt}}(undef, 64), ROOK_MAGICS, ROOK_MOVE_FUNCTIONS)

rookMoves(sqr::Int, occupied::UInt64) = @inbounds ROOK_TABLE[sqr][subIndex(occupied, ROOK_MAGICS[sqr])]
rookMoves(sqr::UInt, occupied::UInt64) = getRookMoves(getSquare(sqr), occupied)
