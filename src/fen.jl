const LABELLED_SQUARES = [*(args...) for args in Base.product("hgfedcba","12345678")]
const LABEL_TO_SQUARE = Dict(reshape(LABELLED_SQUARES, 64) .=> 1:64)


"""
    importfen(fen::String)

Create a `Board` object from an input FEN, given as a `String`.
"""
function importfen(fen::String)
    board = Board()

    # break down components of the string
    parts = split(fen, r"\s+")

    # start from square 64 and go backwards
    sqr = 64
    for char in parts[1]
        piece = chartopiece(char)
        if piece !== BLANK
            add!(board, piece, sqr)
            sqr -= 1
        elseif '1' <= char <= '8'
            sqr -= parse(Int, char)
        elseif char == '/'
            nothing
        else
            return nothing
        end
    end

    # update who's turn it is
    turn = get(parts, 2, "w")
    if isequal(turn, "w")
        board.turn = WHITE
    else
        board.turn = BLACK
        board.hash ⊻= zobturnkey()
    end

    # fix castling rights
    castling = get(parts, 3, "-")
    for char in castling
        i = findfirst(isequal(char), "KkQq")
        if i !== nothing
            board.castling |= UInt8(1) << (i - 1)
            board.hash ⊻= zobookey(UInt8(1) << (i - 1))
        end
    end

    # annotate the enpassant square
    enpass = get(parts, 4, "-")
    if !isequal(enpass, "-")
        sqr = LABEL_TO_SQUARE[enpass]
        board.enpass = sqr
        board.hash ⊻= zobepkey(sqr)
    end

    board.halfmovecount = parse(Int, get(parts, 5, "0"))
    board.movecount = parse(Int, get(parts, 6, "1"))


    board.pinned = findpins(board)
    board.checkers = kingAttackers(board)

    board.history = [board.hash]

    board
end


"""
    chartopiece(c::Char)

Converts a `Char` from the FEN to its respective `Piece` type.
"""
function chartopiece(c::Char)
    if c == 'r'
        return BLACKROOK
    elseif c == 'n'
        return BLACKKNIGHT
    elseif c == 'b'
        return BLACKBISHOP
    elseif c == 'q'
        return BLACKQUEEN
    elseif c == 'k'
        return BLACKKING
    elseif c == 'p'
        return BLACKPAWN
    elseif c == 'R'
        return WHITEROOK
    elseif c == 'N'
        return WHITEKNIGHT
    elseif c == 'B'
        return WHITEBISHOP
    elseif c == 'Q'
        return WHITEQUEEN
    elseif c == 'K'
        return WHITEKING
    elseif c == 'P'
        return WHITEPAWN
    else
        return BLANK
    end
end
