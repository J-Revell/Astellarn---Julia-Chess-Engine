# Queen moves are just the union of all bishop moves, plus all rook moves.
queenMoves(sqr::T, occupied::Bitboard) where T <: Union{Integer, Bitboard} = rookMoves(sqr, occupied) | bishopMoves(sqr, occupied)
