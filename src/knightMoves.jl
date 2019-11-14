function knightMove_NNE(knight::UInt64)
    ~FILE_A & (knight << 15)
end

function knightMove_ENE(knight::UInt64)
    ~FILE_AB & (knight << 6)
end

function knightMove_ESE(knight::UInt64)
    ~FILE_AB & (knight >> 10)
end

function knightMove_SSE(knight::UInt64)
    ~FILE_A & (knight >> 17)
end

function knightMove_SSW(knight::UInt64)
    ~FILE_H & (knight >> 15)
end

function knightMove_WSW(knight::UInt64)
    ~FILE_GH & (knight >> 6)
end

function knightMove_WNW(knight::UInt64)
    ~FILE_GH & (knight << 10)
end

function knightMove_NNW(knight::UInt64)
    ~FILE_H & (knight << 17)
end

function knightMove_all(knight::UInt64)
    knightMove_NNE(knight) | knightMove_ENE(knight) | knightMove_ESE(knight) |
    knightMove_SSE(knight) | knightMove_SSW(knight) | knightMove_WSW(knight) |
    knightMove_WNW(knight) | knightMove_NNW(knight)
end

const KNIGHT_MOVES = @SVector [knightMove_all(UInt(1) << i) for i in 0:63]

#knightMoves(knight::UInt64) = KNIGHT_MOVES[trailing_zeros(knight) + 1]
