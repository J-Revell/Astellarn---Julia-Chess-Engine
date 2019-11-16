# clear both squares (in case of captures), and set the second square
function move!(board::Board, movefrom::String, moveto::String)
    sqr1 = LABEL_TO_BITBOARD[movefrom]
    sqr2 = LABEL_TO_BITBOARD[moveto]
    piece = getPiece(board, sqr1)
    color = getColor(board, sqr1)
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
    sqr1 = LABEL_TO_BITBOARD[movefrom]
    sqr2 = LABEL_TO_BITBOARD[moveto]
    color = getColor(board, sqr1)
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
