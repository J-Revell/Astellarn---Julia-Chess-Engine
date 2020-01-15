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
function engine!(board::Board; ab_depth::Int = 3)
    if isdrawbymaterial(board)
        return :DRAW
    end
    if is50moverule(board)
        return :DRAW
    end
    thread = Thread()
    copy!(thread.board, board)
    thread.ss.time_start = time()
    thread.ss.nodes = 0
    thread.ss.depth = 0
    thread.ss.seldepth = 0
    thread.ss.tbhits = 0
    ttable = TT_Table()
    eval = find_best_move(thread, ttable, ab_depth)
    move = thread.pv[1][1]
    nodes = thread.ss.nodes
    if move == Move()
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
engine!(board) = engine!(board; ab_depth = 3)


# play a match beween AI 1 and AI 2.
function match(N::Int, p1::Function, p2::Function)
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    wdb = [0,0,0]
    for i in 1:N
        playing = true
        b = importfen(fen)
        counter = 0
        while playing
            if isodd(counter)
                sym = p2(b)
            else
                sym = p1(b)
            end
            if sym == :WHITE_WINS
                wdb[1]+=1
                playing = false
            elseif sym == :DRAW
                wdb[2]+=1
                playing = false
            elseif sym == :BLACK_WINS
                wdb[3]+=1
                playing = false
            end
            counter += 1
        end
        show(b)
        println(wdb)
    end
    wdb
end


# play a match with a list of FEN strings. Plays a game from each side.
function match(openings::Vector{String}, p1::Function, p2::Function)
    p1_d_p2 = [0,0,0]
    for i in eachindex(openings)
        playing = true
        b = importfen(openings[i])
        while playing
            if b.turn == WHITE
                sym = p1(b)
            else
                sym = p2(b)
            end
            if sym == :WHITE_WINS
                p1_d_p2[1]+=1
                playing = false
            elseif sym == :DRAW
                p1_d_p2[2]+=1
                playing = false
            elseif sym == :BLACK_WINS
                p1_d_p2[3]+=1
                playing = false
            end
        end
        show(b)
        println(p1_d_p2)
        playing = true
        b = importfen(openings[i])
        while playing
            if b.turn == BLACK
                sym = p1(b)
            else
                sym = p2(b)
            end
            if sym == :WHITE_WINS
                p1_d_p2[3]+=1
                playing = false
            elseif sym == :DRAW
                p1_d_p2[2]+=1
                playing = false
            elseif sym == :BLACK_WINS
                p1_d_p2[1]+=1
                playing = false
            end
        end
        show(b)
        println(p1_d_p2)
    end
    p1_d_p2
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
    engine!(_globalboard)
end


"""
    @engine n

Play the best engine move on the global board, evaluated at a depth 'n::Int'.
"""
macro engine(depth::Int)
    engine!(_globalboard, ab_depth = depth)
end


macro perft(depth::Int)
    perft(_globalboard, depth)
end
