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


function uci_main()
    if iszero(length(ARGS))
        # by default, load starting position
        board = importfen(START_FEN)
        threads = ThreadPool(1)
    else
        # else, a FEN was supplied in command line (assume)
        board = importfen(ARGS[1])
        println(io, ARGS[2])
        threads = ThreadPool(Threads.nthreads())
    end
    # init thread boards
    setthreadpoolboard!(threads, board)
    ttable = TT_Table()


    # main UCI loop
    while true
        line = readline()

        if line == "uci"
            uci_engine()
            continue

        elseif line == "isready"
            uci_isready()
            continue

        elseif line == "ucinewgame"
            uci_newgame!(threads, ttable)
        elseif line == "quit"
            break
        end

        splitlines = split(line)

        if splitlines[1] == "go"
            uci_go(threads, ttable, splitlines)
            continue

        elseif splitlines[1] == "position"
            uci_position!(threads, splitlines)

        elseif splitlines[1] == "perft"
            uci_perft(threads, splitlines)

        elseif splitlines[1] == "setoption"
            uci_setoptions(threads, splitlines, ttable)
        end
        # additional options currently unsupported
    end
    return
end


function uci_engine()
    print("id name Astellarn ", ASTELLARN_VERSION, "\nid author Jeremy Revell\nuciok\n")
end


function uci_isready()
    print("readyok\n")
end


function uci_newgame!(threads::ThreadPool, ttable::TT_Table)
    board = importfen(START_FEN)
    threads[1] = Thread()
    setthreadpoolboard!(threads, board)
    ttable.table = Dict{UInt64, TT_Entry}()
    return
end


function uci_perft(threads::ThreadPool, splitlines::Vector{SubString{String}})
    depth = parse(Int, splitlines[2])
    start_time = time()
    nodes = perft(threads[1].board, depth)
    stop_time = time()
    elapsed = stop_time - start_time
    nps = nodes/elapsed
    @printf("Total time (ms) : %d\n", elapsed*1000)
    @printf("Nodes searched : %d\n", nodes)
    @printf("Nodes/second :  %d\n", nps)
    return
end


function uci_go(threads::ThreadPool, ttable::TT_Table, splitlines::Vector{SubString{String}})
    # First, take note of the starting time.
    start_time = time()

    # Initialise the default search + time management values.
    infinite = false
    depth = wtime = btime = movetime = winc = binc = 0
    movestogo = -1

    # Extract search and time management parameters from the UCI command.
    for i in eachindex(splitlines)
        if splitlines[i] == "infinite"
            infinite = true
            break # We can break as we expect no more inputs
        end
        # The explicit depth.
        if splitlines[i] == "depth"
            depth = parse(Int, splitlines[i + 1])
            infinite = true # So that we know we are not time limited
            break # We can assume no more inputs?
        end
        # White's clock time.
        if splitlines[i] == "wtime"
            wtime = parse(Int, splitlines[i + 1])
            continue
        end
        # Black's clock time.
        if splitlines[i] == "btime"
            btime = parse(Int, splitlines[i + 1])
            continue
        end
        # White increment amount.
        if splitlines[i] == "winc"
            winc = parse(Int, splitlines[i + 1])
            continue
        end
        # Black increment amount.
        if splitlines[i] == "binc"
            binc = parse(Int, splitlines[i + 1])
            continue
        end
        # The movetime we have available.
        if splitlines[i] == "movetime"
            movetime = parse(Int, splitlines[i + 1])
            continue
        end
        # Find out the movestogo.
        if splitlines[i] == "movestogo"
            movestogo = parse(Int, splitlines[i + 1])
            continue
        end
    end

    # Which colour's turn is it?
    if threads[1].board.turn == WHITE
        clock_time = wtime
        inc_time = winc
    else
        clock_time = btime
        inc_time = binc
    end

    # Init the time manager and set to the thread
    timeman = TimeManagement(MOVE_OVERHEAD, infinite, movetime, depth, start_time, clock_time, inc_time, movestogo, 0, 0)
    threads[1].timeman = timeman
    threads[1].stop = false

    # following section is a hack, while multithreadding is not supported.
    threads[1].ss.nodes = 0
    threads[1].ss.depth = 0
    threads[1].ss.seldepth = 0
    threads[1].ss.tbhits = 0

    # Calling the main search function.
    if depth == 0
        depth = 50
    end
    eval = find_best_move(threads[1], ttable, depth)

    # Extract the search info and stats.
    move = threads[1].pv[1][1]
    nodes = threads[1].ss.nodes
    elapsed = elapsedtime(timeman)
    nps = nodes*1000/elapsed
    hf = hashfull(ttable)

    # Report back to the UCI
    ucistring = movetostring(move)
    if !threads[1].stop
        @printf("info depth %d seldepth %d nodes %d nps %d tbhits %d score cp %d hashfull %d pv ", threads[1].ss.depth, threads[1].ss.seldepth, nodes, nps, threads[1].ss.tbhits, eval, hf)
        print(join(movetostring.(threads[1].pv[1]), " "))
        print("\n")
    end
    print("bestmove ", ucistring, "\n")
    return
end


function uci_position!(threads::ThreadPool, splitlines::Vector{SubString{String}})
    # import a given FEN string
    if splitlines[2] == "startpos"
        board = importfen(START_FEN)
    elseif splitlines[2] == "fen"
        fen = join(splitlines[3:8], " ")
        board = importfen(fen)
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
    setthreadpoolboard!(threads, board)
    return
end


function uci_setoptions(threads::ThreadPool, splitlines::Vector{SubString{String}}, ttable::TT_Table)
    if splitlines[3] == "Hash"
        newtable = TT_Table(parse(Int, splitlines[5]))
        ttable.table = newtable.table
        ttable.hashmask = newtable.hashmask
        println("info string set Hash to ", splitlines[5])
    end

    if splitlines[3] == "Threads"
        num_threads = parse(Int, splitlines[5])
        createthreadpool(threads[1].board, num_threads)
        println("info string set Threads to ", num_threads)
    end

    if splitlines[3] == "SyzygyPath"
        tb_init(splitlines[5])
        println("info string set SyzygyPath to ", splitlines[5])
    end

    if splitlines[3] == "MoveOverhead"
        global MOVE_OVERHEAD = parse(Int, splitlines[5])
        println("info string set MoveOverhead to ", splitlines[5])
    end
    return
end


# This function is called when the thread (or search) wishes to output stats mid-execution.
function uci_report(thread::Thread, ttable::TT_Table, α::Int, β::Int, value::Int)
    score = max(α, min(β, value))
    elapsed = elapsedtime(thread.timeman)
    nps = thread.ss.nodes*1000 / elapsed
    hf = hashfull(ttable)
    @printf("info depth %d seldepth %d nodes %d nps %d tbhits %d score cp %d hashfull %d pv ", thread.ss.depth, thread.ss.seldepth, thread.ss.nodes, nps, thread.ss.tbhits, score, hf)
    print(join(movetostring.(thread.pv[1]), " "))
    print("\n")
    return
end
