function movetostring(move::Move)
    # extract move details
    from_sqr = from(move)
    to_sqr = to(move)
    flags = flag(move)

    # convert to string
    ucistring = ""
    ucistring *= LABELLED_SQUARES[from_sqr]
    ucistring *= LABELLED_SQUARES[to_sqr]
    if flags == __KNIGHT_PROMO
        ucistring *= "n"
    elseif flags == __BISHOP_PROMO
        ucistring *= "b"
    elseif flags == __ROOK_PROMO
        ucistring *= "r"
    elseif flags == __QUEEN_PROMO
        ucistring *= "q"
    end

    return ucistring
end


function main()
    # by default, load starting position
    startfen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    board = importfen(startfen)

    # main UCI loop
    while true
        line = readline()
        io = stdout

        if line == "uci"
            print(io, "id name Astellarn\n")
            print(io, "id author Jeremy Revell\n")
            print(io, "uciok\n")
            flush(io)
            continue

        elseif line == "isready"
            print(io, "readyok\n")
            flush(io)
            continue

        elseif line == "quit"
            break
        end

        splitlines = split(line)
        # additional options currently unsupported
        if splitlines[1] == "go"
            eval, move, nodes = find_best_move(board, ab_depth = 4)
            ucistring = movetostring(move)
            print(io, "info nodes ", nodes, " score cp ", eval, "\n")
            print(io, "bestmove ", ucistring, "\n")
            flush(io)
            continue

        elseif splitlines[1] == "position"

            if splitlines[2] == "startpos"
                board = importfen(startfen)

            elseif splitlines[2] == "fen"
                fen = join(splitlines[3:8], " ")
                board = importfen(fen)
            end

            makemoves = false
            for i in eachindex(splitlines)
                if splitlines[i] == "moves"
                    makemoves = true
                    continue
                end
                if makemoves == true
                    movestack = MoveStack(200)
                    gen_moves!(movestack, board)
                    for move in movestack
                        if movetostring(move) == splitlines[i]
                            apply_move!(board, move)
                            break
                        end
                    end
                end
            end
        end
    end
end
