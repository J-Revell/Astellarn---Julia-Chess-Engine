# steps in all compass directions
kingMove_N(king::Bitboard) = king << 8
kingMove_NE(king::Bitboard) = ~FILE_A & (king << 7)
kingMove_E(king::Bitboard) = ~FILE_A & (king >> 1)
kingMove_SE(king::Bitboard) = ~FILE_A & (king >> 9)
kingMove_S(king::Bitboard) = king >> 8
kingMove_SW(king::Bitboard) = ~FILE_H & (king >> 7)
kingMove_W(king::Bitboard) = ~FILE_H & (king << 1)
kingMove_NW(king::Bitboard) = ~FILE_H & (king << 9)

# collate all moves
function kingMove_all(king::Bitboard)
    kingMove_N(king) | kingMove_NE(king) | kingMove_E(king) | kingMove_SE(king) |
    kingMove_S(king) | kingMove_SW(king) | kingMove_W(king) | kingMove_NW(king)
end

# pre-compute table
const KING_MOVES = @SVector [kingMove_all(Bitboard(one(UInt64) << i)) for i in 0:63]


"""
    kingMoves(sqr::Integer)

Generate the potential king moves from a square given by `sqr`, returned as a `Bitboard`.
"""
kingMoves(sqr::Integer) = @inbounds KING_MOVES[sqr]
