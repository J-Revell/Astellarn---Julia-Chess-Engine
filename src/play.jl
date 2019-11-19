# clear both squares (in case of captures), and set the second square
function play!(board::Board, movefrom::String, moveto::String)
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
play!(board::Board, move::String) = play!(board, move[1:2], move[3:4])

function play!(board::Board, movefrom::String, moveto::String, promo::UInt8)
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
macro play(sqr1::Symbol, sqr2::Symbol)
    play!(__gboard, String(sqr1), String(sqr2))
    displayColorBoard(__gboard)
end

macro play(sqr1::Symbol, sqr2::Symbol, promo::Symbol)
    play!(__gboard, String(sqr1), String(sqr2), eval(promo))
    displayColorBoard(__gboard)
end

macro play(sqr12::Symbol)
    play!(__gboard, String(sqr12))
    displayColorBoard(__gboard)
end
