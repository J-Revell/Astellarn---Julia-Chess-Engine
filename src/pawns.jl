# Used internally to generate possible pawn advances
function pawnAdvance(pawns::Bitboard, targets::Bitboard, color::Color)
    targets & (color == WHITE ? (pawns << 8) : (pawns >> 8))
end

# Used internally to generate possible double pawn advances
function pawnDoubleAdvance(pawns::Bitboard, targets::Bitboard, color::Color)
    if color == WHITE
        pawnAdvance(pawnAdvance(pawns & RANK_2, targets, color), targets, color)
    else
        pawnAdvance(pawnAdvance(pawns & RANK_7, targets, color), targets, color)
    end
end


# Used internally to generate left captures
function pawnLeftCaptures(pawns::Bitboard, targets::Bitboard, color::Color)
    targets & (color == WHITE ? ((pawns & ~FILE_A) << 9) : ((pawns & ~FILE_H) >> 9))
end

# Used internally to generate right captures
function pawnRightCaptures(pawns::Bitboard, targets::Bitboard, color::Color)
    targets & (color == WHITE ? ((pawns & ~FILE_H) << 7) : ((pawns & ~FILE_A) >> 7))
end


# functions used to pregenerate possible pawn moves
function pawnAdvancesWhite(pawns::Bitboard, targets::Bitboard)
    pawnAdvance(pawns, targets, WHITE) #| pawnDoubleAdvance(pawns, targets, WHITE)
end

function pawnAdvancesBlack(pawns::Bitboard, targets::Bitboard)
    pawnAdvance(pawns, targets, BLACK) #| pawnDoubleAdvance(pawns, targets, BLACK)
end

function pawnCapturesWhite(pawns::Bitboard, targets::Bitboard)
    pawnLeftCaptures(pawns, targets, WHITE) | pawnRightCaptures(pawns, targets, WHITE)
end

function pawnCapturesBlack(pawns::Bitboard, targets::Bitboard)
    pawnLeftCaptures(pawns, targets, BLACK) | pawnRightCaptures(pawns, targets, BLACK)
end


# Precomputed pawn advance tables
const PAWN_ADVANCES_WHITE = @SVector [pawnAdvancesWhite(Bitboard(sqr), FULL) for sqr in 1:64]
const PAWN_ADVANCES_BLACK = @SVector [pawnAdvancesBlack(Bitboard(sqr), FULL) for sqr in 1:64]
const PAWN_CAPTURES_WHITE = @SVector [pawnCapturesWhite(Bitboard(sqr), FULL) for sqr in 1:64]
const PAWN_CAPTURES_BLACK = @SVector [pawnCapturesBlack(Bitboard(sqr), FULL) for sqr in 1:64]


"""
    pawnAttacks(c::Color, sqr::Integer)

Generate the potential pawn attacks from a square given by `sqr`, from the point of view of the color `c`. Returned as a `Bitboard`.
"""
function pawnAttacks(c::Color, sqr::Integer)
    if c == WHITE
        return @inbounds PAWN_CAPTURES_WHITE[sqr]
    else
        return @inbounds PAWN_CAPTURES_BLACK[sqr]
    end
end


"""
    pawnAdvances(c::Color, sqr::Integer)

Generate the potential pawn pushes from a square given by `sqr`, from the point of view of the color `c`. Returned as a `Bitboard`.
"""
function pawnAdvances(c::Color, sqr::Integer)
    if c == WHITE
        return @inbounds PAWN_ADVANCES_WHITE[sqr]
    else
        return @inbounds PAWN_ADVANCES_BLACK[sqr]
    end
end
