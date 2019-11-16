# To generate queen moves, simply take the union of all possible rook moves + all possible bishop moves from that square.
queenMoves(sqr::T, occupied::UInt) where T <: Union{Int, UInt} = rookMoves(sqr, occupied) | bishopMoves(sqr, occupied)
