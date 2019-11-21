# find the squares attacking a given square
function squareAttackers(board::Board, sqr::Int)
    enemies = getTheirPieces(board)
    occupied = getOccupied(board)
    sqr_bb = getBitboard(sqr)
    pawns = getPawns(board)
    queens = getQueens(board)
    return  enemies & pawns & ((board.turn == WHITE) ? PAWN_CAPTURES_WHITE[sqr] : PAWN_CAPTURES_BLACK[sqr]) |
    (KNIGHT_MOVES[sqr] & enemies & getKnights(board)) |
    (bishopMoves(sqr, occupied) & enemies & (getBishops(board) | queens)) |
    (rookMoves(sqr, occupied) & enemies & (getRooks(board) | queens)) |
    (KING_MOVES[sqr] & enemies & getKings(board))
end
squareAttackers(board::Board, sqr_bb::UInt) = squareAttackers(board, getSquare(sqr_bb))

# is a given square attacked? Bool.
isSquareAttacked(board::Board, sqr::Int) = squareAttackers(board, sqr) > zero(UInt)

# find the squares attacking the king!
function checkers(board::Board)
    squareAttackers(board, getOurKing(board))
end

# is the king attacked? Bool.
isCheck(board::Board) = board.checkers > zero(UInt)

# generate a mask for the bits between two squares of a sliding attack
function initBlockerMasks(blockermasks::Array{UInt, 2})
    for sqr1 in 1:64
        for sqr2 in 1:64
            if (rookMoves(sqr1, zero(UInt)) & getBitboard(sqr2)) > zero(UInt)
                blockermasks[sqr1, sqr2] = rookMoves(sqr1, getBitboard(sqr2)) & rookMoves(sqr2, getBitboard(sqr1))
            end
            if (bishopMoves(sqr1, zero(UInt)) & getBitboard(sqr2)) > zero(UInt)
                blockermasks[sqr1, sqr2] = bishopMoves(sqr1, getBitboard(sqr2)) & bishopMoves(sqr2, getBitboard(sqr1))
            end
        end
    end
    return blockermasks
end

# pre compute blocker masks.
const BLOCKERMASKS = initBlockerMasks(zeros(UInt, (64,64)))
