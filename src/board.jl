# store the state of the chess board
mutable struct Board
    white::UInt64
    black::UInt64
    kings::UInt64
    queens::UInt64
    rooks::UInt64
    bishops::UInt64
    knights::UInt64
    pawns::UInt64

    turn::UInt8
    enpass::UInt64
end

# empty board
Board() = Board(repeat([0x000000000], 8)..., WHITE, 0x000000000)

# define the start position
startBoard() = Board(
    0x000000000000ffff,
    0xffff000000000000,
    0x0800000000000008,
    0x1000000000000010,
    0x8100000000000081,
    0x2400000000000024,
    0x4200000000000042,
    0x00ff00000000ff00,
    WHITE,
    0x000000000)

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
