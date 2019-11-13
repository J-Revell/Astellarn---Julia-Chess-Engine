include("pawnMoves.jl")
include("kingMoves.jl")

mutable struct Move
    move_from::UInt64
    move_to::UInt64
    promote_to::UInt8
end
const MoveList = Vector{Move}


# useful bitboard manipulation
function popSquare(bb::UInt64)
    sqr = trailing_zeros(bb)
    bb &= bb - 1
    return sqr, bb
end

# build moves onto the movelist
function build_moves!(moveList::MoveList, move_BB::UInt64, move_from::UInt64)
    while move_BB > zero(UInt)
        move_to, move_BB = popSquare(move_BB)
        push!(moveList, Move(move_from, UInt64(1) << move_to, 0))
    end
end

# build pawn moves onto the movelist
function build_pawn_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > zero(UInt)
        move_to, move_BB = popSquare(move_BB)
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, 0))
    end
end

# build promotions onto the movelist
function build_promo_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > zero(UInt)
        move_to, move_BB = popSquare(move_BB)
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, KNIGHT))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, BISHOP))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, ROOK))
        push!(moveList, Move(UInt64(1) << (move_to + jump), UInt64(1) << move_to, QUEEN))
    end
end

function build_king_moves!(moveList::MoveList, targets::UInt64, king::UInt64)
    build_moves!(moveList, targets & kingMoves(king), king)
end

function build_knight_moves!(moveList::MoveList, targets::UInt64, knights::UInt64)
    while knights > zero(UInt)
        knight, knights = popSquare(knights)
        build_moves!(moveList, targets & knightMoves(UInt64(1) << knight), UInt64(1) << knight)
    end
end

function gen_moves!(moveList::MoveList, board::Board)
    if board.turn == WHITE
        pawns = board.white_pawns
        knights = board.white_knights
        kings = board.white_kings
        enemies = blackSquares(board)
        oneStep = -8
        twoStep = -16
        left = -9
        right = -7
    else
        pawns = board.black_pawns
        knights = board.black_knights
        kings = board.black_kings
        enemies = whiteSquares(board)
        oneStep = 8
        twoStep = 16
        left = 9
        right = 7
    end
    empty = emptySquares(board)

    pawnOne = pawnAdvance(pawns, empty, board.turn) & ~RANK_18
    pawnTwo = pawnDoubleAdvance(pawns, empty, board.turn)
    pawnLeft = pawnLeftCaptures(pawns, enemies, board.turn)
    pawnRight = pawnRightCaptures(pawns, enemies, board.turn)
    pawnLeftEnpass = pawnLeftCaptures(pawns, board.enpass, board.turn)
    pawnRightEnpass = pawnRightCaptures(pawns, board.enpass, board.turn)
    pawnPromo = pawnAdvance(pawns, empty, board.turn) & RANK_18
    pawnPromoLeft = pawnLeft & RANK_18
    pawnLeft &= ~RANK_18
    pawnPromoRight = pawnRight & RANK_18
    pawnRight &= ~RANK_18
    build_pawn_moves!(moveList, pawnOne, oneStep)
    build_pawn_moves!(moveList, pawnTwo, twoStep)
    build_pawn_moves!(moveList, pawnLeft, left)
    build_pawn_moves!(moveList, pawnRight, right)
    build_pawn_moves!(moveList, pawnLeftEnpass, left)
    build_pawn_moves!(moveList, pawnRightEnpass, right)
    build_promo_moves!(moveList, pawnPromo, oneStep)
    build_promo_moves!(moveList, pawnPromoLeft, left)
    build_promo_moves!(moveList, pawnPromoRight, right)


    build_king_moves!(moveList, empty, kings)
    build_king_moves!(moveList, enemies, kings)

    build_knight_moves!(moveList, empty, knights)
    build_knight_moves!(moveList, enemies, knights)
end
