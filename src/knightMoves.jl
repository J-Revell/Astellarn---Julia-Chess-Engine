function knightMove_NNE(knights::UInt64)
    ~FILE_A & (knights << 15)
end

function knightMove_ENE(knights::UInt64)
    ~FILE_AB & (knights << 6)
end

function knightMove_ESE(knights::UInt64)
    ~FILE_AB & (knights >> 10)
end

function knightMove_SSE(knights::UInt64)
    ~FILE_A & (knights >> 17)
end

function knightMove_SSW(knights::UInt64)
    ~FILE_H & (knights >> 15)
end

function knightMove_WSW(knights::UInt64)
    ~FILE_GH & (knights >> 6)
end

function knightMove_WNW(knights::UInt64)
    ~FILE_GH & (knights << 10)
end

function knightMove_NNW(knights::UInt64)
    ~FILE_H & (knights << 17)
end

function knightMoves(knights::UInt64)
    knightMove_NNE(knights) | knightMove_ENE(knights) | knightMove_ESE(knights) |
    knightMove_SSE(knights) | knightMove_SSW(knights) | knightMove_WSW(knights) |
    knightMove_WNW(knights) | knightMove_NNW(knights)
end
