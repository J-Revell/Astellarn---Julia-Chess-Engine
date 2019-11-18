# store the state of the chess board
mutable struct Board
    pieces::MVector{64,UInt8}

    white::UInt64
    black::UInt64
    kings::UInt64
    queens::UInt64
    rooks::UInt64
    bishops::UInt64
    knights::UInt64
    pawns::UInt64

    turn::UInt8
    castling::UInt8
    enpass::UInt64
end

# empty board
Board() = Board(
    MVector{64,UInt8}(repeat([0x00], 64)),
    repeat([0x000000000], 8)...,
    WHITE,
    0x00,
    0x000000000)

# define the start position
startBoard() = Board(
    [WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_KING, WHITE_QUEEN, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK,
    WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN,
    NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
    NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
    NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
    NONE, NONE, NONE, NONE, NONE, NONE, NONE, NONE,
    BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN,
    BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_KING, BLACK_QUEEN, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK],
    0x000000000000ffff,
    0xffff000000000000,
    0x0800000000000008,
    0x1000000000000010,
    0x8100000000000081,
    0x2400000000000024,
    0x4200000000000042,
    0x00ff00000000ff00,
    WHITE,
    0x0f,
    0x000000000)

# clear a square
function clearSquare!(board::Board, sqr_bb::UInt64)
    board.pieces[getSquare(sqr_bb)] = NONE
    board.white &= ~sqr_bb
    board.black &= ~sqr_bb
    board.rooks &= ~sqr_bb
    board.bishops &= ~sqr_bb
    board.knights &= ~sqr_bb
    board.pawns &= ~sqr_bb
    board.kings &= ~sqr_bb
    board.queens &= ~sqr_bb
end
clearSquare!(board::Board, sqr::Int) = clearSquare!(board, getBitboard(sqr))

# set the piece type on a square
function setSquare!(board::Board, pieceType::UInt8, pieceColor::UInt8, sqr_bb::UInt64)
    clearSquare!(board, sqr_bb)
    board.pieces[sqr] = pieceType * UInt8(4) + pieceColor
    pieceColor == WHITE ? (board.white |= sqr_bb) : (board.black |= sqr_bb)
    pieceType == KING && (board.kings |= sqr_bb; return)
    pieceType == QUEEN && (board.queens |= sqr_bb; return)
    pieceType == ROOK && (board.rooks |= sqr_bb; return)
    pieceType == BISHOP && (board.bishops |= sqr_bb; return)
    pieceType == KNIGHT && (board.knights |= sqr_bb; return)
    pieceType == PAWN && (board.pawns |= sqr_bb; return)
end
function setSquare!(board::Board, pieceType::UInt8, pieceColor::UInt8, sqr::Int)
    sqr_bb = getBitboard(sqr)
    clearSquare!(board, sqr_bb)
    board.pieces[sqr] = pieceType * UInt8(4) + pieceColor
    pieceColor == WHITE ? (board.white |= sqr_bb) : (board.black |= sqr_bb)
    pieceType == KING && (board.kings |= sqr_bb; return)
    pieceType == QUEEN && (board.queens |= sqr_bb; return)
    pieceType == ROOK && (board.rooks |= sqr_bb; return)
    pieceType == BISHOP && (board.bishops |= sqr_bb; return)
    pieceType == KNIGHT && (board.knights |= sqr_bb; return)
    pieceType == PAWN && (board.pawns |= sqr_bb; return)
end

# switch turns
function switchTurn!(board::Board)
    if board.turn == WHITE
        board.turn = BLACK
    else
        board.turn = WHITE
    end
end
