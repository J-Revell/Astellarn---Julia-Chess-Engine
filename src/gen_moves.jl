# useful bitboard manipulation
function popSquare(bb::UInt64)
    sqr = trailing_zeros(bb)
    bb &= bb - 1
    return sqr, bb
end

# build moves onto the movelist
function build_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > 0
        move_to, move_BB = popSquare(move_BB)
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, 0))
    end
end

# build promotions onto the movelist
function build_promo_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > 0
        move_to, move_BB = popSquare(move_BB)
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, KNIGHT))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, BISHOP))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, ROOK))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, QUEEN))
    end
end

# generate possible pawn advances
function pawnAdvance(pawns::UInt64, esqrs::UInt64, color::UInt8)
    esqrs & (color == WHITE ? (pawns << 8) : (pawns >> 8))
end

# generate double pawn advances
function pawnDoubleAdvance(pawns::UInt64, esqrs::UInt64, color::UInt8)
    if color == WHITE
        pawnAdvance(pawnAdvance(pawns & RANK_2, esqrs, color), esqrs, color)
    else
        pawnAdvance(pawnAdvance(pawns & RANK_7, esqrs, color), esqrs, color)
    end
end

# generate left captures
function pawnLeftCaptures(pawns::UInt64, enemies::UInt64, color::UInt8)
    enemies & (color == WHITE ? ((pawns & ~FILE_A) << 9) : ((pawns & ~FILE_H) >> 9))
end

# generate right captures
function pawnRightCaptures(pawns::UInt64, enemies::UInt64, color::UInt8)
    enemies & (color == WHITE ? ((pawns & ~FILE_H) << 7) : ((pawns & ~FILE_A) >> 7))
end

# build all pawn moves
function build_pawn_moves!(moveList::MoveList, board::Board)
    # quiet moves
    esqrs = emptySquares(board)
    if board.turn == WHITE
        pawns = board.white_pawns
        enemies = blackSquares(board)
        oneStep = -8
        twoStep = -16
        left = -9
        right = -7
    else
        pawns = board.black_pawns
        enemies = whiteSquares(board)
        oneStep = 8
        twoStep = 16
        left = 9
        right = 7
    end
    esqrs = emptySquares(board)
    pawnOne = pawnAdvance(pawns, esqrs, board.turn) & ~RANK_18
    pawnTwo = pawnDoubleAdvance(pawns, esqrs, board.turn)
    pawnLeft = pawnLeftCaptures(pawns, enemies, board.turn)
    pawnRight = pawnRightCaptures(pawns, enemies, board.turn)
    pawnPromo = pawnAdvance(pawns, esqrs, board.turn) & RANK_18
    pawnPromoLeft = pawnLeft & RANK_18
    pawnLeft &= ~RANK_18
    pawnPromoRight = pawnRight & RANK_18
    pawnRight &= ~RANK_18
    build_moves!(moveList, pawnOne, oneStep)
    build_moves!(moveList, pawnTwo, twoStep)
    build_moves!(moveList, pawnLeft, left)
    build_moves!(moveList, pawnRight, right)
    build_promo_moves!(moveList, pawnPromo, oneStep)
    build_promo_moves!(moveList, pawnPromoLeft, left)
    build_promo_moves!(moveList, pawnPromoRight, right)
end


# no legality checks yet, modify needed
# function build_king_moves!(moveList::Vector{Vector{UInt64}}, board::Board)
#     esqrs = emptySquares(board)
#     if board.turn == WHITE
#         sqr = board.white_kings
#         enemy = blackSquares(board)
#     else
#         sqr = board.black_kings
#         enemy = whiteSquares(board)
#     end
#     #step left, no capture
#     if ((sqr & ~FILE_A) > 0) && (((sqr << 1) & esqrs) > 0)
#         push!(moveList, [sqr, sqr << 1])
#     end
#     # step right, no capture
#     if ((sqr &  ~FILE_H) > 0) && (((sqr >> 1) & esqrs) > 0)
#         push!(moveList, [sqr, sqr >> 1])
#     end
#     # step NE
#     if ((sqr & ~FILE_H & ~RANK_8) > 0) && (((sqr << 7) & esqrs) > 0)
#         push!(moveList, [sqr, sqr << 7])
#     end
#     # step NW
#     if ((sqr & ~FILE_A & ~RANK_8) > 0) && (((sqr << 9) & esqrs) > 0)
#         push!(moveList, [sqr, sqr << 9])
#     end
#     # step N
#     if ((sqr & ~RANK_8) > 0) && (((sqr << 8) & esqrs) > 0)
#         push!(moveList, [sqr, sqr << 8])
#     end
#     # step S
#     if ((sqr & ~RANK_1) > 0) && (((sqr >> 8) & esqrs) > 0)
#         push!(moveList, [sqr, sqr >> 8])
#     end
#     # step SW
#     if ((sqr & ~RANK_1 & ~FILE_A) > 0) && (((sqr >> 7) & esqrs) > 0)
#         push!(moveList, [sqr, sqr >> 7])
#     end
#     # step SE
#     if ((sqr & ~RANK_1 & ~FILE_H) > 0) && (((sqr >> 9) & esqrs) > 0)
#         push!(moveList, [sqr, sqr >> 9])
#     end
# end
