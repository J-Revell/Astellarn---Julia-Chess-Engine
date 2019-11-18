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

    (pieceType_from == PAWN) && (board.pawns ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (pieceType_from == KNIGHT) && (board.knights ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (pieceType_from == BISHOP) && (board.bishops ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (pieceType_from == ROOK) && (board.rooks ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (pieceType_from == QUEEN) && (board.queens ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (pieceType_from == KING) && (board.kings ⊻= sqr_from_bb ⊻ sqr_to_bb)

    (board.turn == WHITE) && (board.white ⊻= sqr_from_bb ⊻ sqr_to_bb)
    (board.turn == BLACK) && (board.black ⊻= sqr_from_bb ⊻ sqr_to_bb)

    (pieceType_to == PAWN) && (board.pawns ⊻=  sqr_to_bb)
    (pieceType_to == KNIGHT) && (board.knights ⊻= sqr_to_bb)
    (pieceType_to == BISHOP) && (board.bishops ⊻= sqr_to_bb)
    (pieceType_to == ROOK) && (board.rooks ⊻= sqr_to_bb)
    (pieceType_to == QUEEN) && (board.queens ⊻= sqr_to_bb)
    (pieceType_to == KING) && (board.kings ⊻= sqr_to_bb)

    (to_color == WHITE) && (board.white ⊻= sqr_to_bb)
    (to_color == BLACK) && (board.black ⊻= sqr_to_bb)

    board.squares[sqr_from] = NONE
    board.squares[sqr_to] = piece_from

    switchTurn!(board)
end

function move_enpass!(board::Board, move::Move)

end

function move_castle!(board::Board, move::Move)

end

function move_promo!(board::Board, move::Board)

end

function randMove!(board::Board)
    pml = MoveList(150)
    ml = MoveList(150)
    gen_moves!(ml, board)
    ml = filter(move -> move.move_flag == 0, ml)
    for move in ml
        _board = deepcopy(board)
        move_normal!(_board, move)
        if isLegal(_board)
            push!(pml, move)
        end
    end
    move_normal!(board, pml[rand(1:length(pml))])
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
