#======================== PAWN ATTACK TABLES ==================================#
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
    pawnAdvance(pawns, targets, WHITE)
end


function pawnAdvancesBlack(pawns::Bitboard, targets::Bitboard)
    pawnAdvance(pawns, targets, BLACK)
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


#======================== KNIGHT ATTACK TABLES ================================#


# steps in all knight compass directions
knightMove_NNE(knight::Bitboard) = ~FILE_A & (knight << 15)
knightMove_ENE(knight::Bitboard) = ~FILE_AB & (knight << 6)
knightMove_ESE(knight::Bitboard) = ~FILE_AB & (knight >> 10)
knightMove_SSE(knight::Bitboard) = ~FILE_A & (knight >> 17)
knightMove_SSW(knight::Bitboard) = ~FILE_H & (knight >> 15)
knightMove_WSW(knight::Bitboard) = ~FILE_GH & (knight >> 6)
knightMove_WNW(knight::Bitboard) = ~FILE_GH & (knight << 10)
knightMove_NNW(knight::Bitboard) = ~FILE_H & (knight << 17)


# collate all moves
function knightMove_all(knight::Bitboard)
    knightMove_NNE(knight) | knightMove_ENE(knight) | knightMove_ESE(knight) |
    knightMove_SSE(knight) | knightMove_SSW(knight) | knightMove_WSW(knight) |
    knightMove_WNW(knight) | knightMove_NNW(knight)
end


# pre-compute
const KNIGHT_MOVES = @SVector [knightMove_all(Bitboard(one(UInt64) << i)) for i in 0:63]


"""
    knightMoves(sqr::Integer)

Generate the potential knight moves from a square given by `sqr`, returned as a `Bitboard`.
"""
knightMoves(sqr::Integer) = @inbounds KNIGHT_MOVES[sqr]


#======================== BISHOP ATTACK TABLES ================================#


bishopMove_NE(bishop::Bitboard) = ~FILE_A & (bishop << 7)
bishopMove_SE(bishop::Bitboard) = ~FILE_A & (bishop >> 9)
bishopMove_SW(bishop::Bitboard) = ~FILE_H & (bishop >> 7)
bishopMove_NW(bishop::Bitboard) = ~FILE_H & (bishop << 9)


const BISHOP_MOVE_FUNCTIONS = @SVector Function[bishopMove_NE, bishopMove_SE, bishopMove_SW, bishopMove_NW]


# initialise the tables on startup
"""
    BISHOP_TABLE

Constant containing precomputed bishop moves for all occupancy configurations.
"""
const BISHOP_TABLE = SVector{64}(initSlidingTable(Vector{Vector{Bitboard}}(undef, 64), BISHOP_MAGICS, BISHOP_MOVE_FUNCTIONS))


bishopMoves(sqr::Int, occupied::Bitboard) = @inbounds BISHOP_TABLE[sqr][subindex(occupied, BISHOP_MAGICS[sqr])]
bishopMoves(bb::Bitboard, occupied::Bitboard) = bishopMoves(square(bb), occupied)


const BISHOP_MOVES_EMPTY = @SVector [bishopMoves(i, EMPTY) for i in 1:64]


bishopMoves_empty(sqr::Int) = @inbounds BISHOP_MOVES_EMPTY[sqr]


#========================== ROOK ATTACK TABLES ================================#


rookMove_N(rook::Bitboard) = rook << 8
rookMove_S(rook::Bitboard) = rook >> 8
rookMove_E(rook::Bitboard) = ~FILE_A & (rook >> 1)
rookMove_W(rook::Bitboard) = ~FILE_H & (rook << 1)


const ROOK_MOVE_FUNCTIONS = @SVector Function[rookMove_N, rookMove_S, rookMove_E, rookMove_W]


# initialise the tables on startup
"""
    ROOK_TABLE

Constant containing precomputed rook moves for all occupancy configurations.
"""
const ROOK_TABLE = SVector{64}(initSlidingTable(Vector{Vector{Bitboard}}(undef, 64), ROOK_MAGICS, ROOK_MOVE_FUNCTIONS))


rookMoves(sqr::Integer, occupied::Bitboard) = @inbounds ROOK_TABLE[sqr][subindex(occupied, ROOK_MAGICS[sqr])]
rookMoves(bb::Bitboard, occupied::Bitboard) = rookMoves(square(bb), occupied)


const ROOK_MOVES_EMPTY = @SVector [rookMoves(i, EMPTY) for i in 1:64]


rookMoves_empty(sqr::Integer) = @inbounds ROOK_MOVES_EMPTY[sqr]


#========================== QUEEN ATTACK TABLES ===============================#


# Queen moves are just the union of all bishop moves, plus all rook moves.
queenMoves(sqr::T, occupied::Bitboard) where T <: Union{Integer, Bitboard} = rookMoves(sqr, occupied) | bishopMoves(sqr, occupied)


#=========================== KING ATTACK TABLES ===============================#


# steps in all compass directions
kingMove_N(king::Bitboard) = king << 8
kingMove_NE(king::Bitboard) = ~FILE_A & (king << 7)
kingMove_E(king::Bitboard) = ~FILE_A & (king >> 1)
kingMove_SE(king::Bitboard) = ~FILE_A & (king >> 9)
kingMove_S(king::Bitboard) = king >> 8
kingMove_SW(king::Bitboard) = ~FILE_H & (king >> 7)
kingMove_W(king::Bitboard) = ~FILE_H & (king << 1)
kingMove_NW(king::Bitboard) = ~FILE_H & (king << 9)


# collate all moves
function kingMove_all(king::Bitboard)
    kingMove_N(king) | kingMove_NE(king) | kingMove_E(king) | kingMove_SE(king) |
    kingMove_S(king) | kingMove_SW(king) | kingMove_W(king) | kingMove_NW(king)
end


# pre-compute table
const KING_MOVES = @SVector [kingMove_all(Bitboard(one(UInt64) << i)) for i in 0:63]


"""
    kingMoves(sqr::Integer)

Generate the potential king moves from a square given by `sqr`, returned as a `Bitboard`.
"""
kingMoves(sqr::Integer) = @inbounds KING_MOVES[sqr]


#=========================== Additional Utilities =============================#


"""
    squareAttackers(board::Board, sqr::Integer)

Find all the enemy units that attack a given square, `sqr`.
"""
function squareAttackers(board::Board, sqr::Integer)
    occ = occupied(board)
    attackers = (pawns(board) & pawnAttacks(board.turn, sqr)) |
        (knightMoves(sqr) & knights(board)) |
        (kingMoves(sqr) & kings(board))
    if !isempty(bishoplike(board))
        attackers |= (bishopMoves(sqr, occ) & bishoplike(board))
    end
    if !isempty(rooklike(board))
        attackers |= (rookMoves(sqr, occ) & rooklike(board))
    end
    attackers &= enemy(board)
end
squareAttackers(board::Board, bb::Bitboard) = squareAttackers(board, square(bb))


function squaresquareAttackers_through_king(board::Board, sqr::Integer)
    occ = occupied(board)
    occ &= ~(kings(board) & friendly(board))
    attackers = (pawns(board) & pawnAttacks(board.turn, sqr)) |
        (knightMoves(sqr) & knights(board))
    if !isempty(bishoplike(board))
        attackers |= (bishopMoves(sqr, occ) & bishoplike(board))
    end
    if !isempty(rooklike(board))
        attackers |= (rookMoves(sqr, occ) & rooklike(board))
    end
    attackers &= enemy(board)
end


"""
    isattacked(board::Board, sqr::Integer)

Is the given square attacked?
"""
function isattacked(board::Board, sqr::Integer)
    occ = occupied(board)
    enemies = enemy(board)
    isempty(pawns(board) & enemies & pawnAttacks(board.turn, sqr)) == false && return true
    isempty(knightMoves(sqr) & knights(board) & enemies) == false && return true
    isempty(bishopMoves(sqr, occ) & bishoplike(board) & enemies) == false && return true
    isempty(rookMoves(sqr, occ) & rooklike(board) & enemies) == false && return true
    isempty(kingMoves(sqr) & kings(board) & enemies) == false && return true
    return false
end


function isattacked_through_king(board::Board, sqr::Integer)
    occ = occupied(board)
    occ &= ~(kings(board) & friendly(board))
    enemies = enemy(board)
    isempty(pawns(board) & enemies & pawnAttacks(board.turn, sqr)) == false && return true
    isempty(knightMoves(sqr) & knights(board) & enemies) == false && return true
    isempty(bishopMoves(sqr, occ) & bishoplike(board) & enemies) == false && return true
    isempty(rookMoves(sqr, occ) & rooklike(board) & enemies) == false && return true
    isempty(kingMoves(sqr) & kings(board) & enemies) == false && return true
    return false
end


"""
    kingAttackers(board::Board, sqr::Integer)

Find all the attackers of a given square, `sqr`.
"""
function kingAttackers(board::Board, sqr::Integer)
    enemies = enemy(board)
    occ = occupied(board)
    attackers = (pawns(board) & pawnAttacks(board.turn, sqr)) |
        (knightMoves(sqr) & knights(board))
    if !isempty(bishoplike(board))
        attackers |= (bishopMoves(sqr, occ) & bishoplike(board))
    end
    if !isempty(rooklike(board))
        attackers |= (rookMoves(sqr, occ) & rooklike(board))
    end
    attackers &= enemy(board)
end
kingAttackers(board::Board, bb::Bitboard) = kingAttackers(board, square(bb))
kingAttackers(board::Board) = kingAttackers(board, square(kings(board) & friendly(board)))


# function to precompte the masks for blocking squares of a sliding attack
function initBlockerMasks(blockermasks::Array{Bitboard, 2})
    for sqr1 in 1:64
        for sqr2 in 1:64
            if isempty(rookMoves(sqr1, EMPTY) & sqr2) == false
                @inbounds blockermasks[sqr1, sqr2] = rookMoves(sqr1, Bitboard(sqr2)) & rookMoves(sqr2, Bitboard(sqr1))
            end
            if isempty(bishopMoves(sqr1, EMPTY) & sqr2) == false
                @inbounds blockermasks[sqr1, sqr2] = bishopMoves(sqr1, Bitboard(sqr2)) & bishopMoves(sqr2, Bitboard(sqr1))
            end
        end
    end
    return blockermasks
end


# precomputed blocker masks.
const BLOCKERMASKS = initBlockerMasks(fill(EMPTY, (64,64)))


"""
    blockers(sqr_1::Integer, sqr_2::Integer)

Retrieve all the blocking squares between `sqr_1` and `sqr_2`, as a `Bitboard`.
"""
blockers(sqr_1::Integer, sqr_2::Integer) = @inbounds BLOCKERMASKS[sqr_1, sqr_2]


"""
    pins(board::Board)

Retrieves all the pinned pieces on the board, as a `Bitboard`.
"""
function findpins(board::Board)
    king = square(kings(board) & friendly(board))
    occ = occupied(board)
    # Find all sliding pieces that xray through to the king.
    sliders = EMPTY
    if !isempty(bishoplike(board))
        sliders |= (bishopMoves_empty(king) & bishoplike(board))
    end
    if !isempty(rooklike(board))
        sliders |= (rookMoves_empty(king) & rooklike(board))
    end
    sliders &= enemy(board)
    # Find all times where there is only one blocker on the xray path.
    pinned = EMPTY
    for sqr in sliders
        blocking = blockers(sqr, king) & occ
        if isone(blocking) && (isempty(blocking & friendly(board)) === false)
            pinned |= blocking
        end
    end
    return pinned
end
