bishopMove_NE(bishop::UInt64) = ~FILE_A & (bishop << 7)
bishopMove_SE(bishop::UInt64) = ~FILE_A & (bishop >> 9)
bishopMove_SW(bishop::UInt64) = ~FILE_H & (bishop >> 7)
bishopMove_NW(bishop::UInt64) = ~FILE_H & (bishop << 9)

const BISHOP_MOVE_FUNCTIONS = @SVector Function[bishopMove_NE, bishopMove_SE, bishopMove_SW, bishopMove_NW]

# initialise the tables on startup
#const BISHOP_TABLE = initSlidingTable(Vector{UInt}(undef, 5248), BISHOP_MAGICS, BISHOP_MOVE_FUNCTIONS)
const BISHOP_TABLE = initSlidingTable(Vector{Vector{UInt}}(undef, 64), BISHOP_MAGICS, BISHOP_MOVE_FUNCTIONS)

#bishopMoves(sqr::Int, occupied::UInt64) = @inbounds BISHOP_TABLE[tableIndex(occupied, BISHOP_MAGICS[sqr])]
bishopMoves(sqr::Int, occupied::UInt64) = @inbounds BISHOP_TABLE[sqr][subIndex(occupied, BISHOP_MAGICS[sqr])]
bishopMoves(sqr::UInt, occupied::UInt64) = getBishopMoves(getSquare(sqr), occupied)
