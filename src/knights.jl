# steps in all knight compass directions
knightMove_NNE(knight::Bitboard) = ~FILE_A & (knight << 15)
knightMove_ENE(knight::Bitboard) = ~FILE_AB & (knight << 6)
knightMove_ESE(knight::Bitboard) = ~FILE_AB & (knight >> 10)
knightMove_SSE(knight::Bitboard) = ~FILE_A & (knight >> 17)
knightMove_SSW(knight::Bitboard) = ~FILE_H & (knight >> 15)
knightMove_WSW(knight::Bitboard) = ~FILE_GH & (knight >> 6)
knightMove_WNW(knight::Bitboard) = ~FILE_GH & (knight << 10)
knightMove_NNW(knight::Bitboard) = ~FILE_H & (knight << 17)

# collate all moves
function knightMove_all(knight::Bitboard)
    knightMove_NNE(knight) | knightMove_ENE(knight) | knightMove_ESE(knight) |
    knightMove_SSE(knight) | knightMove_SSW(knight) | knightMove_WSW(knight) |
    knightMove_WNW(knight) | knightMove_NNW(knight)
end

# pre-compute
const KNIGHT_MOVES = @SVector [knightMove_all(Bitboard(one(UInt64) << i)) for i in 0:63]


"""
    knightMoves(sqr::Integer)

Generate the potential knight moves from a square given by `sqr`, returned as a `Bitboard`.
"""
knightMoves(sqr::Integer) = @inbounds KNIGHT_MOVES[sqr]
