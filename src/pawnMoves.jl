# generate pawn advances
function pawnSingleAdvance(pawns::UInt64, targets::UInt64, color::UInt8)
    targets & (color == WHITE ? (pawns << 8) : (pawns >> 8))
end

# generate double pawn advances
function pawnDoubleAdvance(pawns::UInt64, targets::UInt64, color::UInt8)
    if color == WHITE
        pawnSingleAdvance(pawnSingleAdvance(pawns & RANK_2, targets, color), targets, color)
    else
        pawnSingleAdvance(pawnSingleAdvance(pawns & RANK_7, targets, color), targets, color)
    end
end

# generate left captures
function pawnLeftCaptures(pawns::UInt64, targets::UInt64, color::UInt8)
    targets & (color == WHITE ? ((pawns & ~FILE_A) << 9) : ((pawns & ~FILE_H) >> 9))
end

# generate right captures
function pawnRightCaptures(pawns::UInt64, targets::UInt64, color::UInt8)
    targets & (color == WHITE ? ((pawns & ~FILE_H) << 7) : ((pawns & ~FILE_A) >> 7))
end


# functions used to pregenerate possible pawn moves
function pawnAdvancesWhite(pawns, targets)
    pawnSingleAdvance(pawns, targets, WHITE) | pawnDoubleAdvance(pawns, targets, WHITE)
end
function pawnAdvancesBlack(pawns, targets)
    pawnSingleAdvance(pawns, targets, BLACK) | pawnDoubleAdvance(pawns, targets, BLACK)
end
function pawnCapturesWhite(pawns, targets)
    pawnLeftCaptures(pawns, targets, WHITE) | pawnRightCaptures(pawns, targets, WHITE)
end
function pawnCapturesBlack(pawns, targets)
    pawnLeftCaptures(pawns, targets, BLACK) | pawnRightCaptures(pawns, targets, BLACK)
end

const PAWN_ADVANCES_WHITE = @SVector [pawnAdvancesWhite(getBitboard(sqr), 0xffffffffffffffff) for sqr in 1:64]
const PAWN_ADVANCES_BLACK = @SVector [pawnAdvancesBlack(getBitboard(sqr), 0xffffffffffffffff) for sqr in 1:64]
const PAWN_CAPTURES_WHITE = @SVector [pawnCapturesWhite(getBitboard(sqr), 0xffffffffffffffff) for sqr in 1:64]
const PAWN_CAPTURES_BLACK = @SVector [pawnCapturesBlack(getBitboard(sqr), 0xffffffffffffffff) for sqr in 1:64]
