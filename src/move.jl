mutable struct Move
    move_from::UInt64
    move_to::UInt64
    promote_to::UInt8
end

const MoveList = Vector{Move}

# clear both squares (in case of captures), and set the second square
function move!(b::Board, movefrom::String, moveto::String)
    sqr1 = LABEL_2_UINT[movefrom]
    sqr2 = LABEL_2_UINT[moveto]
    piece = getPiece(b, sqr1)
    color = getColor(b, sqr1)
    if color !== b.turn
        @warn "Illegal move, try another"
        return
    end
    clearSquare!(b, sqr1)
    setSquare!(b, piece, color, sqr2)
    switchTurn!(b)
    return
end
move!(b::Board, move::String) = move!(b, move[1:2], move[3:4])


function move!(b::Board, movefrom::String, moveto::String, promo::UInt8)
    sqr1 = LABEL_2_UINT[movefrom]
    sqr2 = LABEL_2_UINT[moveto]
    color = getColor(b, sqr1)
    if color !== b.turn
        @warn "Illegal move, try another"
        return
    end
    clearSquare!(b, sqr1)
    setSquare!(b, promo, color, sqr2)
    switchTurn!(b)
    return
end

# edit the global board
macro move(sqr1::Symbol, sqr2::Symbol)
    move!(__gboard, String(sqr1), String(sqr2))
    displayLabelledColorBoard(__gboard)
end

macro
    move(sqr1::Symbol, sqr2::Symbol, promo::Symbol)
    move!(__gboard, String(sqr1), String(sqr2), eval(promo))
    displayLabelledColorBoard(__gboard)
end

macro move(sqr12::Symbol)
    move!(__gboard, String(sqr12))
    displayLabelledColorBoard(__gboard)
end
