# query a square's piece
getPiece(board::Board, sqr::Int) = board.squares[sqr]
getPieceType(board::Board, sqr::Int) = fld(board.squares[sqr], UInt8(4))
getPieceColor(board::Board, sqr::Int) = board.squares[sqr] % UInt8(4)

# functions for logically querying piece types on squares
isKing(board::Board, sqr_bb::UInt64) = (sqr_bb & board.pieces[KING]) > zero(UInt)
isQueen(board::Board, sqr_bb::UInt64) = (sqr_bb & board.pieces[QUEEN]) > zero(UInt)
isRook(board::Board, sqr_bb::UInt64) = (sqr_bb & board.pieces[ROOK]) > zero(UInt)
isBishop(board::Board, sqr_bb::UInt64) = (sqr_bb & board.pieces[BISHOP]) > zero(UInt)
isKnight(board::Board, sqr_bb::UInt64) = (sqr_bb & board.pieces[KNIGHT]) > zero(UInt)
isPawn(board::Board, sqr_bb::UInt64)  = (sqr_bb & board.pieces[PAWN]) > zero(UInt)

isKing(board::Board, sqr::Int) = getPieceType(board, sqr) == KING
isQueen(board::Board, sqr::Int) = getPieceType(board, sqr) == QUEEN
isRook(board::Board, sqr::Int) = getPieceType(board, sqr) == ROOK
isBishop(board::Board, sqr::Int) = getPieceType(board, sqr) == BISHOP
isKnight(board::Board, sqr::Int) = getPieceType(board, sqr) == KNIGHT
isPawn(board::Board, sqr::Int)  = getPieceType(board, sqr) == PAWN

# functions for logically querying colour of piece on squares
isWhite(board::Board, sqr_bb::UInt64) = (sqr_bb & board.colors[WHITE]) > zero(UInt)
isBlack(board::Board, sqr_bb::UInt64) = (sqr_bb & board.colors[BLACK]) > zero(UInt)

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
getWhite(board::Board) = board.colors[WHITE]
getBlack(board::Board) = board.colors[BLACK]

getKings(board::Board) = board.pieces[KING]
getQueens(board::Board) = board.pieces[QUEEN]
getRooks(board::Board) = board.pieces[ROOK]
getBishops(board::Board) = board.pieces[BISHOP]
getKnights(board::Board) = board.pieces[KNIGHT]
getPawns(board::Board) = board.pieces[PAWN]

# It's our turn, find our kings/queens/rooks/bishops/knights/pawns
# Or it's our turn, find their kings/queens/rooks/bishops/knights/pawns
getOurKing(board::Board) = getKings(board) & board.colors[board.turn]
getTheirKing(board::Board) = getKings(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurQueens(board::Board) = getQueens(board) & board.colors[board.turn]
getTheirQueens(board::Board) = getQueens(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurRooks(board::Board) = getRooks(board) & board.colors[board.turn]
getTheirRooks(board::Board) = getRooks(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurBishops(board::Board) = getBishops(board) & board.colors[board.turn]
getTheirBishops(board::Board) = getBishops(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurKnights(board::Board) = getKnights(board) & board.colors[board.turn]
getTheirKnights(board::Board) = getKnights(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurPawns(board::Board) = getPawns(board) & board.colors[board.turn]
getTheirPawns(board::Board) = getPawns(board) & (board.turn == WHITE ? getBlack(board) : getWhite(board))

getOurPieces(board::Board) = board.colors[board.turn]
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

makePiece(pieceType::UInt8, color::UInt8) = pieceType*UInt8(4) + color
