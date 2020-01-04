"""
    squareAttackers(board::Board, sqr::Integer)

Find all the enemy units that attack a given square, `sqr`.
"""
function squareAttackers(board::Board, sqr::Integer)
    occ = occupied(board)

    ((pawns(board) & pawnAttacks(board.turn, sqr)) |
    (knightMoves(sqr) & knights(board)) |
    (bishopMoves(sqr, occ) & bishoplike(board)) |
    (rookMoves(sqr, occ) & rooklike(board)) |
    (kingMoves(sqr) & kings(board))) & enemy(board)
end
squareAttackers(board::Board, bb::Bitboard) = squareAttackers(board, square(bb))


function squaresquareAttackers_through_king(board::Board, sqr::Integer)
    occ = occupied(board)
    occ &= ~(kings(board) & friendly(board))

    ((pawns(board) & pawnAttacks(board.turn, sqr)) |
    (knightMoves(sqr) & knights(board)) |
    (bishopMoves(sqr, occ) & bishoplike(board)) |
    (rookMoves(sqr, occ) & rooklike(board)) |
    (kingMoves(sqr) & kings(board))) & enemy(board)
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

    ((pawns(board) & pawnAttacks(board.turn, sqr)) |
    (knightMoves(sqr) & knights(board)) |
    (bishopMoves(sqr, occ) & bishoplike(board)) |
    (rookMoves(sqr, occ) & rooklike(board))) & enemies
end
kingAttackers(board::Board, bb::Bitboard) = kingAttackers(board, square(bb))
kingAttackers(board::Board) = kingAttackers(board, square(kings(board) & friendly(board)))


# function to precompte the masks for blocking squares of a sliding attack
function initBlockerMasks(blockermasks::Array{Bitboard, 2})
    for sqr1 in 1:64
        for sqr2 in 1:64
            if isempty(rookMoves(sqr1, EMPTY) & sqr2) == false
                blockermasks[sqr1, sqr2] = rookMoves(sqr1, Bitboard(sqr2)) & rookMoves(sqr2, Bitboard(sqr1))
            end
            if isempty(bishopMoves(sqr1, EMPTY) & sqr2) == false
                blockermasks[sqr1, sqr2] = bishopMoves(sqr1, Bitboard(sqr2)) & bishopMoves(sqr2, Bitboard(sqr1))
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
    sliders = (bishopMoves_empty(king) & bishoplike(board)) | (rookMoves_empty(king) & rooklike(board))
    sliders &= enemy(board)
    pinned = EMPTY
    for sqr in sliders
        blocking = blockers(sqr, king) & occ
        if isone(blocking) && (isempty(blocking & friendly(board)) == false)
            pinned |= blocking
        end
    end
    return pinned
end
