#=
store the state, currently using the following square scheme

64 63 62 61 60 59 58 57
56 ....................
48 ....................
.......................
.......................
.......................
.......................
 8  7  6  5  4  3  2  1

 where 64 = A8 and 1 = H1
 =#
mutable struct Board
    white::UInt64
    black::UInt64
    kings::UInt64
    queens::UInt64
    rooks::UInt64
    bishops::UInt64
    knights::UInt64
    pawns::UInt64

    turn::UInt8 # colour to move
    enpass::UInt64
end

# empty board
Board() = Board(repeat([0x000000000], 12)..., WHITE, 0x000000000)

# define the start position
startBoard() = Board(0x000000000000ffff, 0xffff000000000000, 0x0800000000000008,
    0x1000000000000010, 0x8100000000000081, 0x2400000000000024, 0x4200000000000042,
    0x00ff00000000ff00, WHITE, 0x000000000)


# given a column (1->8), and a row (1->8),
# return the UInt64 representation of the square
function square(col::Int, row::Int)
    sqr = UInt64(1) << ((8-col) + 8*(row-1))
end


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

# convert between
getSquare(sqr::UInt64) = trailing_zeros(sqr) + 1
getSquare(sqr::Int) = UInt(1) << sqr

# query files & ranks
getFile(sqr::UInt64) = FILE_A >> (leading_zeros(sqr) % 8)
getRank(sqr::UInt64) = RANK_1 << (fld(trailing_zeros(sqr), 8) * 8)

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

# clear a square
function clearSquare!(board::Board, sqr::UInt64)
    board.white &= ~sqr
    board.black &= ~sqr
    board.rooks &= ~sqr
    board.bishops &= ~sqr
    board.knights &= ~sqr
    board.pawns &= ~sqr
    board.kings &= ~sqr
    board.queens &= ~sqr
end

# set the piece type on a square
function setSquare!(board::Board, piece::UInt8, color::UInt8, sqr::UInt64)
    clearSquare!(board, sqr)
    color == WHITE ? (board.white |= sqr) : (board.black |= sqr)
    piece == KING && (board.kings |= sqr; return)
    piece == QUEEN && (board.queens |= sqr; return)
    piece == ROOK && (board.rooks |= sqr; return)
    piece == BISHOP && (board.bishops |= sqr; return)
    piece == KNIGHT && (board.knights |= sqr; return)
    piece == PAWN && (board.pawns |= sqr; return)
end

# switch turns
function switchTurn!(board::Board)
    if board.turn == WHITE
        board.turn = BLACK
    else
        board.turn = WHITE
    end
end
