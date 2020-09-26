ThreadStats() = ThreadStats(0, 0, 0, 0)

Thread() = Thread(TimeManagement(),
    Board(),
    [MoveStack(MAX_PLY + 1) for i in 0:MAX_PLY+1],
    ThreadStats(),
    [MoveOrder() for i in 0:MAX_PLY+1],
    MoveStack(MAX_PLY + 1),
    PieceStack(MAX_PLY + 1),
    zeros(Int, MAX_PLY + 1),
    [MoveStack(MAX_QUIET_TRACK) for i in 0:MAX_PLY + 1],
    ButterflyHistTable(),
    CounterHistTable(),
    CounterHistTable(),
    MoveStack(MAX_PLY + 1),
    MoveStack(MAX_PLY + 1),
    CounterTable(),
    PawnKingTable(),
    false)


const ThreadPool = Vector{Thread}
ThreadPool(n::Int) = [Thread() for i in 1:n]


# we can't increase the number of threads in julia while the process is running...
# so we set an atexit condition to reload the engine & process from scratch
function createthreadpool(board::Board, num_threads::Int)
    if Threads.nthreads() !== num_threads
        fen = exportfen(board)
        atexit(() -> withenv(() -> run(`julia AstellarnEngine.jl $fen "info string set Threads to $num_threads"`), "JULIA_NUM_THREADS" => num_threads))
        exit()
    end
end


function setthreadpoolboard!(threads::ThreadPool, board::Board)
    for thread in threads
        copy!(thread.board, board)
    end
end
