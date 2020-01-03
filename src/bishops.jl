bishopMove_NE(bishop::Bitboard) = ~FILE_A & (bishop << 7)
bishopMove_SE(bishop::Bitboard) = ~FILE_A & (bishop >> 9)
bishopMove_SW(bishop::Bitboard) = ~FILE_H & (bishop >> 7)
bishopMove_NW(bishop::Bitboard) = ~FILE_H & (bishop << 9)

const BISHOP_MOVE_FUNCTIONS = @SVector Function[bishopMove_NE, bishopMove_SE, bishopMove_SW, bishopMove_NW]


# initialise the tables on startup
"""
    BISHOP_TABLE

Constant containing precomputed bishop moves for all occupancy configurations.
"""
const BISHOP_TABLE = SVector{64}(initSlidingTable(Vector{Vector{Bitboard}}(undef, 64), BISHOP_MAGICS, BISHOP_MOVE_FUNCTIONS))

bishopMoves(sqr::Integer, occupied::Bitboard) = @inbounds BISHOP_TABLE[sqr][subindex(occupied, BISHOP_MAGICS[sqr])]
bishopMoves(bb::Bitboard, occupied::Bitboard) = bishopMoves(square(bb), occupied)

const BISHOP_MOVES_EMPTY = @SVector [bishopMoves(i, EMPTY) for i in 1:64]

bishopMoves_empty(sqr::Integer) = @inbounds BISHOP_MOVES_EMPTY[sqr]
