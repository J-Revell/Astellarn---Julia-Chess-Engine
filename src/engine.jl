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
    eval, move, nodes = find_best_move(thread; ab_depth = ab_depth)
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
