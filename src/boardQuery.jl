# query a square's piece
getPiece(board::Board, sqr::Int) = board.pieces[sqr]
getPieceType(board::Board, sqr::Int) = fld(board.pieces[sqr], UInt8(4))
getPieceColor(board::Board, sqr::Int) = board.pieces[sqr] % UInt8(4)

# functions for logically querying piece types on squares
isKing(board::Board, sqr_bb::UInt64) = (sqr_bb & board.kings) > zero(UInt)
isQueen(board::Board, sqr_bb::UInt64) = (sqr_bb & board.queens) > zero(UInt)
isRook(board::Board, sqr_bb::UInt64) = (sqr_bb & board.rooks) > zero(UInt)
isBishop(board::Board, sqr_bb::UInt64) = (sqr_bb & board.bishops) > zero(UInt)
isKnight(board::Board, sqr_bb::UInt64) = (sqr_bb & board.knights) > zero(UInt)
isPawn(board::Board, sqr_bb::UInt64)  = (sqr_bb & board.pawns) > zero(UInt)

isKing(board::Board, sqr::Int) = getPieceType(board, sqr) == KING
isQueen(board::Board, sqr::Int) = getPieceType(board, sqr) == QUEEN
isRook(board::Board, sqr::Int) = getPieceType(board, sqr) == ROOK
isBishop(board::Board, sqr::Int) = getPieceType(board, sqr) == BISHOP
isKnight(board::Board, sqr::Int) = getPieceType(board, sqr) == KNIGHT
isPawn(board::Board, sqr::Int)  = getPieceType(board, sqr) == PAWN

# functions for logically querying colour of piece on squares
isWhite(board::Board, sqr_bb::UInt64) = (sqr_bb & board.white) > zero(UInt)
isBlack(board::Board, sqr_bb::UInt64) = (sqr_bb & board.black) > zero(UInt)

isWhite(board::Board, sqr::Int) = getPieceColor(board, sqr) == WHITE
isBlack(board::Board, sqr::Int) = getPieceColor(board, sqr) == BLACK

# convert between bitboard <-> int representation
getSquare(sqr_bb::UInt64) = trailing_zeros(sqr_bb) + 1
getBitboard(sqr::Int) = UInt64(1) << (sqr - 1)

# given a column (1->8), and a row (1->8),
# return the BB or Int representation of the square
getBitboard(col::Int, row::Int) = UInt64(1) << (-col + 8 * row)
getSquare(col::Int, row::Int) = -col + 8 * row + 1

# query files & ranks
getFile(sqr_bb::UInt64) = FILE_A >> (leading_zeros(sqr_bb) % 8)
getRank(sqr_bb::UInt64) = RANK_1 << (fld(trailing_zeros(sqr_bb), 8) * 8)
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
isOccupied(board::Board, sqr_bb::UInt64) = (getOccupied(board, sqr_bb) & sqr_bb) > zero(UInt)
isempty(board::Board, sqr_bb::UInt64) = ~isOccupied(board, sqr_bb)

# query if we have castling rights still
canCastleKingside(board::Board, color::UInt8) = (board.castling & (color == WHITE ? 0x01 : 0x04)) > zero(UInt8)
canCastleQueenside(board::Board, color::UInt8) = (board.castling & (color == WHITE ? 0x02 : 0x08)) > zero(UInt8)
canCastle(board::Board, color::UInt8) = canCastleKingside(board, color) | canCastleQueenside(board, color)
