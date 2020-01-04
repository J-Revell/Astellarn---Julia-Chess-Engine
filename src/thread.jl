mutable struct ThreadStats
    depth::Int
    seldepth::Int
    nodes::Int
    tbhits::Int
    time_start::Float64
end
ThreadStats() = ThreadStats(0, 0, 0, 0, time())


function updatestats!(ss::ThreadStats, depth::Int, nodes::Int, tbhits::Int)
    ss.depth = depth
    ss.nodes = nodes
    ss.tbhits = tbhits
end


mutable struct Thread
    board::Board
    pv::Vector{MoveStack} # 1st element is the PV, rest are preallocated tmp PVs
    ss::ThreadStats
    moveorders::Vector{MoveOrder}
end
Thread() = Thread(Board(), [MoveStack(MAX_PLY + 1) for i in 1:MAX_PLY+1], ThreadStats(), [MoveOrder() for i in 0:MAX_PLY+1])


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
