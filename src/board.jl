# store the state of the chess board
mutable struct Board
    squares::MVector{64,UInt8}
    pieces::MVector{6,UInt64}
    colors::MVector{2,UInt64}

    turn::UInt8
    castling::UInt8
    enpass::UInt64
end

# empty board
Board() = Board(
    MVector{64,UInt8}(repeat([0x00], 64)),
    MVector{6,UInt64}(repeat([0x000000000], 6)),
    MVector{2,UInt64}(repeat([0x000000000], 2)),
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
    [0x00ff00000000ff00,
    0x4200000000000042,
    0x2400000000000024,
    0x8100000000000081,
    0x1000000000000010,
    0x0800000000000008],
    [0x000000000000ffff,
    0xffff000000000000],
    WHITE,
    0x0f,
    0x000000000)

# clear a square
function clearSquare!(board::Board, sqr_bb::UInt64)
    board.squares[getSquare(sqr_bb)] = NONE
    board.colors .&= ~sqr_bb
    board.pieces .&= ~sqr_bb
    return
end
clearSquare!(board::Board, sqr::Int) = clearSquare!(board, getBitboard(sqr))

# set the piece type on a square
function setSquare!(board::Board, pieceType::UInt8, pieceColor::UInt8, sqr_bb::UInt64)
    clearSquare!(board, sqr_bb)
    board.squares[getSquare(sqr_bb)] = pieceType * UInt8(4) + pieceColor
    board.colors[pieceColor] |= sqr_bb
    board.pieces[pieceType] |= sqr_bb
    return
end
function setSquare!(board::Board, pieceType::UInt8, pieceColor::UInt8, sqr::Int)
    sqr_bb = getBitboard(sqr)
    clearSquare!(board, sqr_bb)
    board.squares[sqr] = pieceType * UInt8(4) + pieceColor
    board.colors[pieceColor] |= sqr_bb
    board.pieces[pieceType] |= sqr_bb
end

# switch turns
function switchTurn!(board::Board)
    if board.turn == WHITE
        board.turn = BLACK
    else
        board.turn = WHITE
    end
end
