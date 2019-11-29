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
    owl!(board, depth)

The owl looks ahead a move using alpha-beta pruning plus quiescence, alongside a naive evaluation. The owl is wiser than the monkey!
Care should be taken in selecting the depth, as too high will take a long time.
"""
function owl!(board::Board, depth::Int)
    if isdrawbymaterial(board)
        return :DRAW
    end
    if is50moverule(board)
        return :DRAW
    end
    eval, move, nodes = absearch(board, -100000, 100000, depth)
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
