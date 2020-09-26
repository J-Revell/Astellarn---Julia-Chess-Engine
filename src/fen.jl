const LABELLED_SQUARES = [*(args...) for args in Base.product("hgfedcba","12345678")]
const LABEL_TO_SQUARE = Dict(reshape(LABELLED_SQUARES, 64) .=> 1:64)

const START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"


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
            error("Could not process input")
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
    board.movecount = parse(Int, get(parts, 6, "1")) * 2
    if board.turn == WHITE
        board.movecount -= 1
    end

    board.pinned = findpins(board)
    board.checkers = kingAttackers(board)

    board.history = ZobristHash.(zeros(UInt64, 512))
    board.history[board.movecount] = board.hash

    board
end


"""
    exportfen(board::Board)

Create a FEN 'String' object from a given 'Board'.
"""
function exportfen(board::Board)
    fen = Vector{SubString{String}}()

    # core string
    skip = '0'
    core = ""
    for sqr in 64:-1:1

        # handle line break
        if iszero(sqr%8) && (sqr < 64)
            if skip !== '0'
                core *= skip
                skip = '0'
            end
            core *= '/'
        end

        # extract char
        char = piecetochar(board.squares[sqr])

        # blank square
        if char == '1'
            skip += 1

        # new line or piece char
        else
            if skip !== '0'
                core *= skip
                skip = '0'
            end
            core *= char
        end
    end
    push!(fen, core)

    # add color
    if board.turn == WHITE
        push!(fen, "w")
    else
        push!(fen, "b")
    end

    # add castling
    castle = ""
    cancastlekingside(board, WHITE) && (castle *= 'K')
    cancastlequeenside(board, WHITE) && (castle *= 'Q')
    cancastlekingside(board, BLACK) && (castle *= 'k')
    cancastlequeenside(board, BLACK) && (castle *= 'q')
    (castle == "") && (castle *= '-')
    push!(fen, castle)

    # add enpassant
    enpass = ""
    iszero(board.enpass) ? (enpass *= '-') : (enpass *= LABELLED_SQUARES[board.enpass])
    push!(fen, enpass)

    # add halfmovecount
    push!(fen, "$(board.halfmovecount)")

    # add fullmovecount
    push!(fen, "$(board.movecount)")

    return join(fen, " ")
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


"""
    piecetochar(p::Piece)

Converts a `Piece` to its respective FEN `Char`.
"""
function piecetochar(p::Piece)
    if p == BLACKROOK
        return 'r'
    elseif p == BLACKKNIGHT
        return 'n'
    elseif p == BLACKBISHOP
        return 'b'
    elseif p == BLACKQUEEN
        return 'q'
    elseif p == BLACKKING
        return 'k'
    elseif p == BLACKPAWN
        return 'p'
    elseif p == WHITEROOK
        return 'R'
    elseif p == WHITEKNIGHT
        return 'N'
    elseif p == WHITEBISHOP
        return 'B'
    elseif p == WHITEQUEEN
        return 'Q'
    elseif p == WHITEKING
        return 'K'
    elseif p == WHITEPAWN
        return 'P'
    else
        # will be a blank, which needs special consideration
        return '1'
    end
end
