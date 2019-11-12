# store the state
mutable struct Board
    white_kings::UInt64
    white_queens::UInt64
    white_rooks::UInt64
    white_bishops::UInt64
    white_knights::UInt64
    white_pawns::UInt64
    black_kings::UInt64
    black_queens::UInt64
    black_rooks::UInt64
    black_bishops::UInt64
    black_knights::UInt64
    black_pawns::UInt64

    turn::UInt8 # colour to move
end

# empty board
Board() = Board(repeat([0x000000000], 12)..., WHITE)

#=
starting positions UInt
0x0000000000000008 wkings
0x0000000000000010 wqueens
0x0000000000000081 wrooks
0x0000000000000024 wbishops
0x0000000000000042 wknights
0x000000000000ff00 wpawns
0x0800000000000000 bkings
0x1000000000000000 bqueens
0x8100000000000000 brooks
0x2400000000000000 bbishops
0x4200000000000000 bknights
0x00ff000000000000 bpawns
=#
startBoard() = Board(0x0000000000000008, 0x0000000000000010,0x0000000000000081,
0x0000000000000024, 0x0000000000000042, 0x000000000000ff00, 0x0800000000000000,
0x1000000000000000, 0x8100000000000000, 0x2400000000000000, 0x4200000000000000,
0x00ff000000000000, WHITE)


# given a column (1->8), and a row (1->8),
# return the UInt64 representation of the square
function square(col::Int, row::Int)
    sqr = UInt64(1) << ((8-col) + 8*(row-1))
end

# functions for logically querying squares #
function isKing(board::Board, sqr::UInt64)
    (sqr & (board.white_kings | board.black_kings)) > 0
end
function isQueen(board::Board, sqr::UInt64)
    (sqr & (board.white_queens | board.black_queens)) > 0
end
function isRook(board::Board, sqr::UInt64)
    (sqr & (board.white_rooks | board.black_rooks)) > 0
end
function isBishop(b::Board, sqr::UInt64)
    (sqr & (board.white_bishops | board.black_bishops)) > 0
end
function isKnight(b::Board, sqr::UInt64)
    (sqr & (board.white_knights | board.black_knights)) > 0
end
function isPawn(b::Board, sqr::UInt64)
    (sqr & (board.white_pawns | board.black_pawns)) > 0
end
function isWhite(b::Board, sqr::UInt64)
    (sqr & (board.white_kings | board.white_queens | board.white_rooks |
    board.white_bishops | board.white_knights | board.white_pawns)) > 0
end
function isBlack(b::Board, sqr::UInt64)
    (sqr & (board.black_kings | board.black_queens | board.black_rooks |
    board.black_bishops | board.black_knights | board.black_pawns)) > 0
end

# useful classifying queries
function getPiece(board::Board, sqr::UInt64)
    isPawn(board, sqr) && (return PAWN)
    isKnight(board, sqr) && (return KNIGHT)
    isBishop(board, sqr) && (return BISHOP)
    isRook(board, sqr) && (return ROOK)
    isQueen(board, sqr) && (return QUEEN)
    isKing(board, sqr) && (return KING)
    return NONE
end

function getColor(board::Board, sqr::UInt64)
    isWhite(board, sqr) && (return WHITE)
    isBlack(board, sqr) && (return BLACK)
    return NONE
end

# useful groups #
function whiteSquares(b::Board)
    b.white_kings | b.white_queens | b.white_rooks | b.white_bishops |
        b.white_knights | b.white_pawns
end
function blackSquares(b::Board)
    b.black_kings | b.black_queens | b.black_rooks | b.black_bishops |
        b.black_knights | b.black_pawns
end
function emptySquares(b::Board)
    ~(whiteSquares(b) | blackSquares(b))
end

# clear a square
function clearSquare!(b::Board, sqr::UInt64)
    b.white_kings = b.white_kings & ~sqr
    b.white_queens = b.white_queens & ~sqr
    b.white_rooks = b.white_rooks & ~sqr
    b.white_bishops = b.white_bishops & ~sqr
    b.white_knights = b.white_knights & ~sqr
    b.white_pawns = b.white_pawns & ~sqr
    b.black_kings = b.black_kings & ~sqr
    b.black_queens = b.black_queens & ~sqr
    b.black_rooks = b.black_rooks & ~sqr
    b.black_bishops = b.black_bishops & ~sqr
    b.black_knights = b.black_knights & ~sqr
    b.black_pawns = b.black_pawns & ~sqr
end

# set the piece type on a square
function setSquare!(b::Board, piece::UInt8, color::UInt8, sqr::UInt64)
    clearSquare!(b, sqr)
    if color == WHITE
        piece == KING && (b.white_kings |= sqr; return)
        piece == QUEEN && (b.white_queens |= sqr; return)
        piece == ROOK && (b.white_rooks |= sqr; return)
        piece == BISHOP && (b.white_bishops |= sqr; return)
        piece == KNIGHT && (b.white_knights |= sqr; return)
        piece == PAWN && (b.white_pawns |= sqr; return)
    elseif color == BLACK
        piece == KING && (b.black_kings |= sqr; return)
        piece == QUEEN && (b.black_queens |= sqr; return)
        piece == ROOK && (b.black_rooks |= sqr; return)
        piece == BISHOP && (b.black_bishops |= sqr; return)
        piece == KNIGHT && (b.black_knights |= sqr; return)
        piece == PAWN && (b.black_pawns |= sqr; return)
    else
        @error("No colour!")
    end
end

function switchTurn!(b::Board)
    if b.turn == WHITE
        b.turn = BLACK
    else
        b.turn = WHITE
    end
end
