# These are entirely functions relating to the REPL capability of Astellarn.

"""
    monkey!(board)

The monkey AI plays random moves. It is a monkey.
"""
function monkey!(board::Board)
    if isdrawbymaterial(board)
        return :DRAW
    end
    if is50moverule(board)
        return :DRAW
    end
    ml = MoveStack(150)
    gen_moves!(ml, board)
    if length(ml) == 0
        if ischeck(board)
            if board.turn == WHITE
                return :BLACK_WINS
            else
                return :WHITE_WINS
            end
        else
            return :DRAW
        end
    end
    apply_move!(board, rand(ml))
    board
end


"""
    engine!(board, depth)

Looks ahead using alpha-beta pruning plus quiescence, alongside a naive evaluation. Selects a move.
"""
function engine!(board::Board, depth::Int)
    if isdrawbymaterial(board)
        return :DRAW
    end
    if is50moverule(board)
        return :DRAW
    end
    thread = Thread()
    copy!(thread.board, board)

    timeman = TimeManagement(100, true, 0, depth, time(), 0, 0, -1, 0, 0)
    thread.timeman = timeman
    thread.stop = false
    thread.ss.nodes = 0
    thread.ss.depth = 0
    thread.ss.seldepth = 0
    thread.ss.tbhits = 0

    ttable = TT_Table()
    eval = find_best_move(thread, ttable, depth)
    move = thread.pv[1][1]
    if move == MOVE_NONE
        if ischeck(board)
            if board.turn == WHITE
                return :BLACK_WINS
            else
                return :WHITE_WINS
            end
        else
            return :DRAW
        end
    end
    apply_move!(board, move)
    board
end


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


"""
    @board

Create a new blank 'board' obect, accessible as the `global` object `_globalboard`.
"""
macro board()
    global _globalboard = Board()
end


"""
    @newgame

Create a new game from the starting position (accessible if needed as the `global` object `_globalboard`). Moves can be made using the @move macro.
"""
macro newgame()
    global _globalboard = importfen(START_FEN)
end


macro importfen(fen::String)
    global _globalboard = importfen(fen)
end


"""
    @random

Play a random legal move on the global board.
"""
macro random()
    monkey!(_globalboard)
end


"""
    @random

Play the best engine move on the global board.
"""
macro engine()
    engine!(_globalboard, 10)
end


"""
    @engine n

Play the best engine move on the global board, evaluated at a depth 'n::Int'.
"""
macro engine(depth::Int)
    engine!(_globalboard, depth)
end


macro perft(depth::Int)
    perft(_globalboard, depth)
end
