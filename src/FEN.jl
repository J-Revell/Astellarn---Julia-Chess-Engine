# function to import a game position from the FEN format
function importFEN(fen::String)
    board = Board()

    # break down components of the string
    parts = split(fen, r"\s+")

    # start from square 64 and go backwards
    sqr = 64
    for char in parts[1]
        piece = piecefromchar(char)
        if piece !== NONE
            println(sqr)
            pieceType = getPieceType(piece)
            pieceColor = getPieceColor(piece)
            setSquare!(board, pieceType, pieceColor, sqr)
            sqr -= 1
        elseif char ≥ '1' && char ≤ '8'
            println(sqr)
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
    end

    # fix castling rights
    castling = get(parts, 3, "-")
    for char in castling
        i = findfirst(isequal(char), "KQkq")
        if i !== nothing
            board.castling |= UInt8(1) << (i - 1)
        end
    end

    # annotate the enpassant square
    enpass = get(parts, 4, "-")
    if !isequal(enpass, "-")
        sqr = LABEL_TO_BITBOARD[enpass]
        board.enpass = getSquare(sqr)
    end

    board
end

# given a character, return the piece
function piecefromchar(c::Char)
    if c == 'r'
        return makePiece(ROOK, BLACK)
    elseif c == 'n'
        return makePiece(KNIGHT, BLACK)
    elseif c == 'b'
        return makePiece(BISHOP, BLACK)
    elseif c == 'q'
        return makePiece(QUEEN, BLACK)
    elseif c == 'k'
        return makePiece(KING, BLACK)
    elseif c == 'p'
        return makePiece(PAWN, BLACK)
    elseif c == 'R'
        return makePiece(ROOK, WHITE)
    elseif c == 'N'
        return makePiece(KNIGHT, WHITE)
    elseif c == 'B'
        return makePiece(BISHOP, WHITE)
    elseif c == 'Q'
        return makePiece(QUEEN, WHITE)
    elseif c == 'K'
        return makePiece(KING, WHITE)
    elseif c == 'P'
        return makePiece(PAWN, WHITE)
    else
        return NONE
    end
end
