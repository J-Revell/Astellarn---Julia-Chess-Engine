rookMove_N(rook::Bitboard) = rook << 8
rookMove_S(rook::Bitboard) = rook >> 8
rookMove_E(rook::Bitboard) = ~FILE_A & (rook >> 1)
rookMove_W(rook::Bitboard) = ~FILE_H & (rook << 1)

const ROOK_MOVE_FUNCTIONS = @SVector Function[rookMove_N, rookMove_S, rookMove_E, rookMove_W]


# initialise the tables on startup
"""
    ROOK_TABLE

Constant containing precomputed rook moves for all occupancy configurations.
"""
const ROOK_TABLE = SVector{64}(initSlidingTable(Vector{Vector{Bitboard}}(undef, 64), ROOK_MAGICS, ROOK_MOVE_FUNCTIONS))

rookMoves(sqr::Integer, occupied::Bitboard) = @inbounds ROOK_TABLE[sqr][subindex(occupied, ROOK_MAGICS[sqr])]
rookMoves(bb::Bitboard, occupied::Bitboard) = rookMoves(square(bb), occupied)

const ROOK_MOVES_EMPTY = @SVector [rookMoves(i, EMPTY) for i in 1:64]

rookMoves_empty(sqr::Integer) = @inbounds ROOK_MOVES_EMPTY[sqr]
