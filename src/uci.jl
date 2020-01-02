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
    board = importfen(START_FEN)

    # main UCI loop
    while true
        line = readline()
        io = stdout

        if line == "uci"
            uci_engine(io)
            continue

        elseif line == "isready"
            uci_isready(io)
            continue

        elseif line == "quit"
            break
        end

        splitlines = split(line)

        if splitlines[1] == "go"
            uci_go(board, splitlines)
            continue

        elseif splitlines[1] == "position"
            uci_position!(board, splitlines)
        end
        # additional options currently unsupported
    end
    return
end


function uci_engine(io::IOStream)
    print(io, "id name Astellarn\n")
    print(io, "id author Jeremy Revell\n")
    print(io, "uciok\n")
end

function uci_isready(io::IOStream)
    print(io, "readyok\n")
end


function uci_go(board::board, splitlines::Vector{SubString{String}})
    ab_depth = 3 #temporary default value

    # extract depth
    for i in eachindex(splitlines)
        if splitlines[i] == "depth"
            ab_depth = splitlines[i + 1]
            break
        end
    end
    eval, move, nodes = find_best_move(board, ab_depth = ab_depth)
    ucistring = movetostring(move)
    print(io, "info nodes ", nodes, " score cp ", eval, " depth ", ab_depth, "\n")
    print(io, "bestmove ", ucistring, "\n")
end


function uci_position!(board::Board, splitlines::Vector{SubString{String}})
    # import a given FEN string
    if splitlines[2] == "startpos"
        copy!(board, importfen(START_FEN))
    elseif splitlines[2] == "fen"
        fen = join(splitlines[3:8], " ")
        copy!(board, importfen(fen))
    end

    # make the given moves, if any
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
