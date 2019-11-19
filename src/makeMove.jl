function move(board::Board, move::Move)

# generate non special moves
function move_normal!(board::Board, move::Move)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    piece_from = getPiece(board, sqr_from)
    piece_to = getPiece(board, sqr_to)

    pieceType_from = getPieceType(board, sqr_from)
    pieceType_to = getPieceType(board, sqr_to)
    to_color = getPieceColor(board, sqr_to)

    board.pieces[pieceType_from] ⊻= sqr_from_bb ⊻ sqr_to_bb
    board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    board.squares[sqr_from] = NONE
    board.squares[sqr_to] = piece_from

    if piece_to !== NONE
        board.pieces[pieceType_to] ⊻= sqr_to_bb
        board.colors[to_color] ⊻= sqr_to_bb
    end

    switchTurn!(board)

    # check for double pawn advance, and set enpass square
    if (pieceType_from == PAWN) && (sqr_from-sqr_to > 10)
        board.enpass = UInt8(getSquare(BLOCKERMASKS[sqr_from, sqr_to]))
    else
        board.enpass = zero(UInt8)
    end

    # rook moves, remove castle rights
    (sqr_from == 1) && (board.castling &= ~0x01)
    (sqr_from == 8) && (board.castling &= ~0x02)
    (sqr_from == 57) && (board.castling &= ~0x04)
    (sqr_from == 64) && (board.castling &= ~0x08)

    # king moves, remove castle rights
    (sqr_from == 60) && (board.castling &= ~0x04 | ~0x08)
    (sqr_from == 4) && (board.castling &= ~0x01 | ~0x02)

    # rook square moved to (captured)? remove rights
    (sqr_to == 1) && (board.castling &= ~0x01)
    (sqr_to == 8) && (board.castling &= ~0x02)
    (sqr_to == 57) && (board.castling &= ~0x04)
    (sqr_to == 64) && (board.castling &= ~0x08)
end

function move_enpass!(board::Board, move::Move)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    cap_sqr = getBitboard(sqr_to - 24 + (board.turn << 4))

    piece_from = makePiece(PAWN, board.turn)

    if board.turn == WHITE
        piece_captured = makePiece(PAWN, BLACK)
        to_color = BLACK
    else
        piece_captured = makePiece(PAWN, WHITE)
        to_color = WHITE
    end

    board.pieces[PAWN] ⊻= sqr_from_bb ⊻ sqr_to_bb
    board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    board.pieces[PAWN] ⊻= cap_sqr
    board.colors[to_color] ⊻= cap_sqr

    board.squares[sqr_from] = NONE
    board.squares[sqr_to] = piece_from
    board.squares[sqr_to - 24 + (board.turn << 4)] = NONE

    board.enpass = zero(UInt8)
    switchTurn!(board)
end

function move_castle!(board::Board, move::Move)

end

function move_promo!(board::Board, move::Move)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    #piece_from = getPiece(board, sqr_from)
    piece_to = getPiece(board, sqr_to)

    pieceType_from = PAWN
    pieceType_to = getPieceType(board, sqr_to)
    to_color = getPieceColor(board, sqr_to)

    pieceType_promo = move.move_flag

    board.pieces[pieceType_from] ⊻= sqr_from_bb
    board.pieces[pieceType_promo] ⊻= sqr_to_bb
    board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    board.squares[sqr_from] = NONE
    board.squares[sqr_to] = makePiece(pieceType_promo, board.turn)

    if piece_to !== NONE
        board.pieces[pieceType_to] ⊻= sqr_to_bb
        board.colors[to_color] ⊻= sqr_to_bb
    end

    board.enpass = zero(UInt8)
    switchTurn!(board)

    # rook square moved to (captured)? remove rights
    (sqr_to == 1) && (board.castling ⊻= 0x01)
    (sqr_to == 8) && (board.castling ⊻= 0x02)
    (sqr_to == 57) && (board.castling ⊻= 0x04)
    (sqr_to == 64) && (board.castling ⊻= 0x08)
end

# clear both squares (in case of captures), and set the second square
function move!(board::Board, movefrom::String, moveto::String)
    sqr1 = LABEL_TO_SQUARE[movefrom]
    sqr2 = LABEL_TO_SQUARE[moveto]
    piece = getPieceType(board, sqr1)
    color = getPieceColor(board, sqr1)
    if color !== board.turn
        @warn "Illegal move, try another"
        return
    end
    clearSquare!(board, sqr1)
    setSquare!(board, piece, color, sqr2)
    switchTurn!(board)
    return
end
move!(board::Board, move::String) = move!(board, move[1:2], move[3:4])

function move!(board::Board, movefrom::String, moveto::String, promo::UInt8)
    sqr1 = LABEL_TO_SQUARE[movefrom]
    sqr2 = LABEL_TO_SQUARE[moveto]
    color = getPieceColor(board, sqr1)
    if color !== board.turn
        @warn "Illegal move, try another"
        return
    end
    clearSquare!(board, sqr1)
    setSquare!(board, promo, color, sqr2)
    switchTurn!(board)
    return
end

# edit the global board
macro move(sqr1::Symbol, sqr2::Symbol)
    move!(__gboard, String(sqr1), String(sqr2))
    displayColorBoard(__gboard)
end

macro move(sqr1::Symbol, sqr2::Symbol, promo::Symbol)
    move!(__gboard, String(sqr1), String(sqr2), eval(promo))
    displayColorBoard(__gboard)
end

macro move(sqr12::Symbol)
    move!(__gboard, String(sqr12))
    displayColorBoard(__gboard)
end
