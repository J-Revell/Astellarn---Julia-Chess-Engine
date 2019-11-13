# generate pawn advances
function pawnAdvance(pawns::UInt64, targets::UInt64, color::UInt8)
    targets & (color == WHITE ? (pawns << 8) : (pawns >> 8))
end

# generate double pawn advances
function pawnDoubleAdvance(pawns::UInt64, targets::UInt64, color::UInt8)
    if color == WHITE
        pawnAdvance(pawnAdvance(pawns & RANK_2, targets, color), targets, color)
    else
        pawnAdvance(pawnAdvance(pawns & RANK_7, targets, color), targets, color)
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
