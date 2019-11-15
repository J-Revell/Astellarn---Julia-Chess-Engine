# steps in all knight compass directions
knightMove_NNE(knight::UInt64) = ~FILE_A & (knight << 15)
knightMove_ENE(knight::UInt64) = ~FILE_AB & (knight << 6)
knightMove_ESE(knight::UInt64) = ~FILE_AB & (knight >> 10)
knightMove_SSE(knight::UInt64) = ~FILE_A & (knight >> 17)
knightMove_SSW(knight::UInt64) = ~FILE_H & (knight >> 15)
knightMove_WSW(knight::UInt64) = ~FILE_GH & (knight >> 6)
knightMove_WNW(knight::UInt64) = ~FILE_GH & (knight << 10)
knightMove_NNW(knight::UInt64) = ~FILE_H & (knight << 17)

# collate all moves
function knightMove_all(knight::UInt64)
    knightMove_NNE(knight) | knightMove_ENE(knight) | knightMove_ESE(knight) |
    knightMove_SSE(knight) | knightMove_SSW(knight) | knightMove_WSW(knight) |
    knightMove_WNW(knight) | knightMove_NNW(knight)
end

# pre-compute
const KNIGHT_MOVES = @SVector [knightMove_all(UInt(1) << i) for i in 0:63]
