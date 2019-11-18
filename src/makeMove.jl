function move_normal!(board::Board, move::Move)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    #sqr_from_bb = getBitboard(sqr_from)
    #sqr_to_BB = getBitboard(sqr_to))

    piece_from = getPiece(board, sqr_from)
    piece_to = getPiece(board, sqr_to)

    pieceType_from = getPieceType(board, sqr_from)
    pieceType_to = getPieceType(board, sqr_to)
    to_color = getPieceColor(board, sqr_to)

    (pieceType_from == PAWN) && (board.pawns ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (pieceType_from == KNIGHT) && (board.knights ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (pieceType_from == BISHOP) && (board.bishops ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (pieceType_from == ROOK) && (board.rooks ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (pieceType_from == QUEEN) && (board.queens ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (pieceType_from == KING) && (board.kings ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))

    (board.turn == WHITE) && (board.white ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))
    (board.turn == BLACK) && (board.black ⊻= getBitboard(sqr_from) ⊻ getBitboard(sqr_to))

    (pieceType_to == PAWN) && (board.pawns ⊻=  getBitboard(sqr_to))
    (pieceType_to == KNIGHT) && (board.knights ⊻= getBitboard(sqr_to))
    (pieceType_to == BISHOP) && (board.bishops ⊻= getBitboard(sqr_to))
    (pieceType_to == ROOK) && (board.rooks ⊻= getBitboard(sqr_to))
    (pieceType_to == QUEEN) && (board.queens ⊻= getBitboard(sqr_to))
    (pieceType_to == KING) && (board.kings ⊻= getBitboard(sqr_to))

    (to_color == WHITE) && (board.white ⊻= getBitboard(sqr_to))
    (to_color == BLACK) && (board.black ⊻= getBitboard(sqr_to))

    board.pieces[sqr_from] = NONE
    board.pieces[sqr_to] = piece_from

    switchTurn!(board)
end

function move_enpass!(board::Board, move::Move)

end

function move_castle!(board::Board, move::Move)

end

function move_promo!(board::Board, move::Board)

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
