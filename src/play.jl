# clear both squares (in case of captures), and set the second square
function user_move!(board::Board, movefrom::String, moveto::String)
    sqr1 = LABEL_TO_SQUARE[movefrom]
    sqr2 = LABEL_TO_SQUARE[moveto]
    if type(board[sqr1]) == PAWN
        if abs(sqr2 - sqr1) > 10
            f = __DOUBLE_PAWN
        elseif abs(sqr2 - sqr1) !== 8
            if board[sqr2] == BLANK
                f = __ENPASS
            else
                f = __NORMAL_MOVE
            end
        else
            f = __NORMAL_MOVE
        end
    else
        f = __NORMAL_MOVE
    end
    ctype = color(board[sqr1])
    if ctype !== board.turn
        @warn "Illegal move, try another"
        return
    end
    move = Move(sqr1, sqr2, f)
    if verify_move(board, move)
        apply_move!(board, Move(sqr1, sqr2, f))
    else
        @warn "Not a legal move"
    end
    return
end
user_move!(board::Board, move::String) = play!(board, move[1:2], move[3:4])


function user_move!(board::Board, movefrom::String, moveto::String, promo::PieceType)
    sqr1 = LABEL_TO_SQUARE[movefrom]
    sqr2 = LABEL_TO_SQUARE[moveto]
    if promo == KNIGHT
        f = __KNIGHT_PROMO
    elseif promo == BISHOP
        f = __BISHOP_PROMO
    elseif promo == ROOK
        f = __ROOK_PROMO
    elseif promo == QUEEN
        f = __QUEEN_PROMO
    end
    ctype = color(board[sqr1])
    if ctype !== board.turn
        @warn "Illegal move, try another"
        return
    end
    move = Move(sqr1, sqr2, f)
    if verify_move(board, move)
        apply_move!(board, Move(sqr1, sqr2, f))
    else
        @warn "Not a legal move"
    end
    return
end

function user_move!(board::Board, castling::Expr)
    if castling.args == [:-,0,0]
        f = __KING_CASTLE
    elseif castling.args == [:-,:(0-0),0]
        f = __QUEEN_CASTLE
    else
        @warn "Input not understood"
    end
    sqr1 = square(kings(board) & friendly(board))
    if f == __KING_CASTLE
        sqr2 = sqr1 - 2
    else
        sqr2 = sqr1 + 2
    end
    ctype = color(board[sqr1])
    if ctype !== board.turn
        @warn "Illegal move, try another"
        return
    end
    move = Move(sqr1, sqr2, f)
    if verify_move(board, move)
        apply_move!(board, Move(sqr1, sqr2, f))
    else
        @warn "Not a legal move"
    end
    return
end

function verify_move(board::Board, move::Move)
    ml = MoveStack(200)
    gen_moves!(ml, board)
    in(move, ml)
end

# edit the global board
macro move(sqr1::Symbol, sqr2::Symbol)
    user_move!(_globalboard, String(sqr1), String(sqr2))
    _globalboard
end

macro move(sqr1::Symbol, sqr2::Symbol, promo::Symbol)
    user_move!(_globalboard, String(sqr1), String(sqr2), eval(promo))
    _globalboard
end

macro move(sqr12::Symbol)
    user_move!(_globalboard, String(sqr12))
    _globalboard
end

macro move(castling::Expr)
    user_move!(_globalboard, castling)
    _globalboard
end

macro board()
    global _globalboard = Board()
end

macro newgame()
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    global _globalboard = importfen(fen)
end

macro random()
    monkey!(_globalboard)
end
