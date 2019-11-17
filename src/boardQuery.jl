# functions for logically querying piece types on squares
isKing(board::Board, sqr::UInt64) = (sqr & board.kings) > zero(UInt)
isQueen(board::Board, sqr::UInt64) = (sqr & board.queens) > zero(UInt)
isRook(board::Board, sqr::UInt64) = (sqr & board.rooks) > zero(UInt)
isBishop(board::Board, sqr::UInt64) = (sqr & board.bishops) > zero(UInt)
isKnight(board::Board, sqr::UInt64) = (sqr & board.knights) > zero(UInt)
isPawn(board::Board, sqr::UInt64)  = (sqr & board.pawns) > zero(UInt)

# functions for logically querying colour of piece on squares
isWhite(board::Board, sqr::UInt64) = (sqr & board.white) > zero(UInt)
isBlack(board::Board, sqr::UInt64) = (sqr & board.black) > zero(UInt)

# convert between bitboard <-> int representation
getSquare(sqr::UInt64) = trailing_zeros(sqr) + 1
getBitboard(sqr::Int) = UInt(1) << (sqr - 1)

# given a column (1->8), and a row (1->8),
# return the BB or Int representation of the square
getBitboard(col::Int, row::Int) = UInt64(1) << (-col + 8 * row)
getSquare(col::Int, row::Int) = -col + 8 * row + 1

# query files & ranks
getFile(sqr::UInt64) = FILE_A >> (leading_zeros(sqr) % 8)
getRank(sqr::UInt64) = RANK_1 << (fld(trailing_zeros(sqr), 8) * 8)
getFile(sqr::Int) = getFile(getBitboard(sqr))
getRank(sqr::Int) = getRank(getBitboard(sqr))

# get all the black pieces, or all the white pieces
getWhite(board::Board) = board.white
getBlack(board::Board) = board.black

# It's our turn, find our kings/queens/rooks/bishops/knights/pawns
# Or it's our turn, find their kings/queens/rooks/bishops/knights/pawns
getOurKing(board::Board) = board.kings & (board.turn == WHITE ? board.white : board.black)
getTheirKing(board::Board) = board.kings & (board.turn == WHITE ? board.black : board.white)

getOurQueens(board::Board) = board.queens & (board.turn == WHITE ? board.white : board.black)
getTheirQueens(board::Board) = board.queens & (board.turn == WHITE ? board.black : board.white)

getOurRooks(board::Board) = board.rooks & (board.turn == WHITE ? board.white : board.black)
getTheirRooks(board::Board) = board.rooks & (board.turn == WHITE ? board.black : board.white)

getOurBishops(board::Board) = board.bishops & (board.turn == WHITE ? board.white : board.black)
getTheirBishops(board::Board) = board.bishops & (board.turn == WHITE ? board.black : board.white)

getOurKnights(board::Board) = board.knights & (board.turn == WHITE ? board.white : board.black)
getTheirKnights(board::Board) = board.knights & (board.turn == WHITE ? board.black : board.white)

getOurPawns(board::Board) = board.pawns & (board.turn == WHITE ? board.white : board.black)
getTheirPawns(board::Board) = board.pawns & (board.turn == WHITE ? board.black : board.white)

getOurPieces(board::Board) = (board.turn == WHITE) ? getWhite(board) : getBlack(board)
getTheirPieces(board::Board) = (board.turn == WHITE) ? getBlack(board) : getWhite(board)

# find all the empty, or occupied squares
getOccupied(board::Board) = getWhite(board) | getBlack(board)
getEmpty(board::Board) = ~getOccupied(board)

# is a given square empty or occupied?
isOccupied(board::Board, sqr::UInt64) = (getOccupied(board, sqr) & sqr) > zero(UInt)
isempty(board::Board, sqr::UInt64) = ~isOccupied(board, sqr)

# query if we have castling rights still
canCastleKingside(board::Board, color::UInt8) = (board.castling & (color == WHITE ? 0x01 : 0x04)) > zero(UInt8)
canCastleQueenside(board::Board, color::UInt8) = (board.castling & (color == WHITE ? 0x02 : 0x08)) > zero(UInt8)
canCastle(board::Board, color::UInt8) = canCastleKingside(board, color) | canCastleQueenside(board, color)

# retrieve the piece type on a given square
function getPiece(board::Board, sqr::UInt64)
    isPawn(board, sqr) && (return PAWN)
    isKnight(board, sqr) && (return KNIGHT)
    isBishop(board, sqr) && (return BISHOP)
    isRook(board, sqr) && (return ROOK)
    isQueen(board, sqr) && (return QUEEN)
    isKing(board, sqr) && (return KING)
    return NONE
end

# retrieve the colour of the piece on a given square
function getColor(board::Board, sqr::UInt64)
    isWhite(board, sqr) && (return WHITE)
    isBlack(board, sqr) && (return BLACK)
    return NONE
end
