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
    io = stdout
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
            uci_engine(io)
            continue

        elseif line == "isready"
            uci_isready(io)
            continue

        elseif line == "ucinewgame"
            uci_newgame!(threads, ttable)
        elseif line == "quit"
            break
        end

        splitlines = split(line)

        if splitlines[1] == "go"
            uci_go(io, threads, ttable, splitlines)
            continue

        elseif splitlines[1] == "position"
            uci_position!(threads, splitlines)

        elseif splitlines[1] == "perft"
            uci_perft(io, threads, splitlines)

        elseif splitlines[1] == "setoption"
            uci_setoptions(io, threads, splitlines)
        end
        # additional options currently unsupported
    end
    return
end


function uci_engine(io::IO)
    print(io, "id name Astellarn ", ASTELLARN_VERSION, "\n")
    print(io, "id author Jeremy Revell\n")
    print(io, "uciok\n")
end


function uci_isready(io::IO)
    print(io, "readyok\n")
end


function uci_newgame!(threads::ThreadPool, ttable::TT_Table)
    board = importfen(START_FEN)
    setthreadpoolboard!(threads, board)
    ttable.table = Dict{UInt64, TT_Entry}()
    threads[1].history = ButterflyHistTable([[zeros(Int32, 64) for i in 1:64] for j in 1:2])
    threads[1].counterhistory = CounterHistTable([[[zeros(Int32, 64) for j in 1:6] for k in 1:64] for l in 1:6])
    threads[1].followhistory = CounterHistTable([[[zeros(Int32, 64) for j in 1:6] for k in 1:64] for l in 1:6])
    return
end


function uci_perft(io::IO, threads::ThreadPool, splitlines::Vector{SubString{String}})
    depth = parse(Int, splitlines[2])
    time_start = time()
    nodes = perft(threads[1].board, depth)
    time_stop = time()
    elapsed = time_stop - time_start
    @printf(io, "Total time (ms) : %d\n", elapsed*1000)
    @printf(io, "Nodes searched : %d\n", nodes)
    nps = nodes/elapsed
    @printf(io, "Nodes/second :  %d\n", nps)
    return
end


function uci_go(io::IO, threads::ThreadPool, ttable::TT_Table, splitlines::Vector{SubString{String}})
    ab_depth = 6 #temporary default value

    # extract depth
    for i in eachindex(splitlines)
        if splitlines[i] == "depth"
            ab_depth = parse(Int, splitlines[i + 1])
            break
        end
    end

    # following section is a hack, while multithreadding is not supported.
    threads[1].ss.time_start = time()
    threads[1].ss.nodes = 0
    threads[1].ss.depth = 0
    threads[1].ss.seldepth = 0
    threads[1].ss.tbhits = 0

    eval = find_best_move(threads[1], ttable, ab_depth)
    move = threads[1].pv[1][1]
    nodes = threads[1].ss.nodes
    time_stop = time()
    elapsed = time_stop - threads[1].ss.time_start
    nps = nodes/elapsed

    ucistring = movetostring(move)
    @printf(io, "info depth %d seldepth %d nodes %d nps %d tbhits %d score cp %d pv ", ab_depth, threads[1].ss.seldepth, nodes, nps, threads[1].ss.tbhits, eval)
    print(io, join(movetostring.(threads[1].pv[1]), " "))
    print(io, "\n")
    print(io, "bestmove ", ucistring, "\n")
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


function uci_setoptions(io::IO, threads::ThreadPool, splitlines::Vector{SubString{String}})
    if splitlines[3] == "Threads"
        num_threads = parse(Int, splitlines[5])
        createthreadpool(threads[1].board, num_threads)
        println(io, "info string set Threads to ", num_threads)
    end

    if splitlines[3] == "SyzygyPath"
        tb_init(splitlines[5])
        println(io, "info string set SyzygyPath to ", splitlines[5])
    end
    return
end


# This function is called when the thread (or search) wishes to output stats mid-execution.
function uci_report(thread::Thread, α::Int, β::Int, value::Int)
    score = max(α, min(β, value))
    elapsed = time() - thread.ss.time_start
    nps = thread.ss.nodes / elapsed
    @printf("info depth %d seldepth %d nodes %d nps %d tbhits %d score cp %d pv ", thread.ss.depth, thread.ss.seldepth, thread.ss.nodes, nps, thread.ss.tbhits, score)
    print(join(movetostring.(thread.pv[1]), " "))
    print("\n")
    return
end
