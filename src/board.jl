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
 =#
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
    enpass::UInt64
end

# empty board
Board() = Board(repeat([0x000000000], 12)..., WHITE, 0x000000000)

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
0x00ff000000000000, WHITE, 0x000000000)


# given a column (1->8), and a row (1->8),
# return the UInt64 representation of the square
function square(col::Int, row::Int)
    sqr = UInt64(1) << ((8-col) + 8*(row-1))
end

# functions for logically querying squares #
function isKing(board::Board, sqr::UInt64)
    (sqr & (board.white_kings | board.black_kings)) > zero(UInt)
end
function isQueen(board::Board, sqr::UInt64)
    (sqr & (board.white_queens | board.black_queens)) > zero(UInt)
end
function isRook(board::Board, sqr::UInt64)
    (sqr & (board.white_rooks | board.black_rooks)) > zero(UInt)
end
function isBishop(board::Board, sqr::UInt64)
    (sqr & (board.white_bishops | board.black_bishops)) > zero(UInt)
end
function isKnight(board::Board, sqr::UInt64)
    (sqr & (board.white_knights | board.black_knights)) > zero(UInt)
end
function isPawn(board::Board, sqr::UInt64)
    (sqr & (board.white_pawns | board.black_pawns)) > zero(UInt)
end
function isWhite(board::Board, sqr::UInt64)
    (sqr & (board.white_kings | board.white_queens | board.white_rooks |
    board.white_bishops | board.white_knights | board.white_pawns)) > zero(UInt)
end
function isBlack(board::Board, sqr::UInt64)
    (sqr & (board.black_kings | board.black_queens | board.black_rooks |
    board.black_bishops | board.black_knights | board.black_pawns)) > zero(UInt)
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

# function getFile(sqr::UInt64)
#     ((sqr & FILE_A) > zero(UInt)) && return FILE_A
#     ((sqr & FILE_B) > zero(UInt)) && return FILE_B
#     ((sqr & FILE_C) > zero(UInt)) && return FILE_C
#     ((sqr & FILE_D) > zero(UInt)) && return FILE_D
#     ((sqr & FILE_E) > zero(UInt)) && return FILE_E
#     ((sqr & FILE_F) > zero(UInt)) && return FILE_F
#     ((sqr & FILE_G) > zero(UInt)) && return FILE_G
#     ((sqr & FILE_H) > zero(UInt)) && return FILE_H
# end
function getFile(sqr::UInt64)
    (FILE_A >> (leading_zeros(sqr) % 8))
end

# function getRank(sqr::UInt64)
#     ((sqr & RANK_1) > zero(UInt)) && return RANK_1
#     ((sqr & RANK_2) > zero(UInt)) && return RANK_2
#     ((sqr & RANK_3) > zero(UInt)) && return RANK_3
#     ((sqr & RANK_4) > zero(UInt)) && return RANK_4
#     ((sqr & RANK_5) > zero(UInt)) && return RANK_5
#     ((sqr & RANK_6) > zero(UInt)) && return RANK_6
#     ((sqr & RANK_7) > zero(UInt)) && return RANK_7
#     ((sqr & RANK_8) > zero(UInt)) && return RANK_8
# end
function getRank(sqr::UInt64)
    RANK_1 << (fld(trailing_zeros(sqr), 8) * 8)
end

# useful groups #
function whiteSquares(board::Board)
    board.white_kings | board.white_queens | board.white_rooks | board.white_bishops |
        board.white_knights | board.white_pawns
end
function blackSquares(board::Board)
    board.black_kings | board.black_queens | board.black_rooks | board.black_bishops |
        board.black_knights | board.black_pawns
end
function emptySquares(board::Board)
    ~(whiteSquares(board) | blackSquares(board))
end

# clear a square
function clearSquare!(board::Board, sqr::UInt64)
    board.white_kings = board.white_kings & ~sqr
    board.white_queens = board.white_queens & ~sqr
    board.white_rooks = board.white_rooks & ~sqr
    board.white_bishops = board.white_bishops & ~sqr
    board.white_knights = board.white_knights & ~sqr
    board.white_pawns = board.white_pawns & ~sqr
    board.black_kings = board.black_kings & ~sqr
    board.black_queens = board.black_queens & ~sqr
    board.black_rooks = board.black_rooks & ~sqr
    board.black_bishops = board.black_bishops & ~sqr
    board.black_knights = board.black_knights & ~sqr
    board.black_pawns = board.black_pawns & ~sqr
end

# set the piece type on a square
function setSquare!(board::Board, piece::UInt8, color::UInt8, sqr::UInt64)
    clearSquare!(board, sqr)
    if color == WHITE
        piece == KING && (board.white_kings |= sqr; return)
        piece == QUEEN && (board.white_queens |= sqr; return)
        piece == ROOK && (board.white_rooks |= sqr; return)
        piece == BISHOP && (board.white_bishops |= sqr; return)
        piece == KNIGHT && (board.white_knights |= sqr; return)
        piece == PAWN && (board.white_pawns |= sqr; return)
    elseif color == BLACK
        piece == KING && (board.black_kings |= sqr; return)
        piece == QUEEN && (board.black_queens |= sqr; return)
        piece == ROOK && (board.black_rooks |= sqr; return)
        piece == BISHOP && (board.black_bishops |= sqr; return)
        piece == KNIGHT && (board.black_knights |= sqr; return)
        piece == PAWN && (board.black_pawns |= sqr; return)
    else
        @error("No colour!")
    end
end

function switchTurn!(board::Board)
    if board.turn == WHITE
        board.turn = BLACK
    else
        board.turn = WHITE
    end
end
