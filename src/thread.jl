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


# ButterflyTable for storing move histories.
# BTABLE[i][j][k]
# [i] => colour
# [j] => from
# [k] => to
# https://www.chessprogramming.org/index.php?title=Butterfly_Boards
const ButterflyTable = MArray{Tuple{2},Array{Array{Int32,1},1},1,2}

mutable struct MoveOrder
    type::UInt8
    stage::UInt8
    movestack::MoveStack
    quietstack::MoveStack
    values::Vector{Int32}
    margin::Int
    noisy_size::Int
    quiet_size::Int
end
MoveOrder() = MoveOrder(NORMAL_TYPE, STAGE_TABLE, MoveStack(150),  MoveStack(150), zeros(Int32, 150), 0, 0, 0)

mutable struct Thread
    board::Board
    pv::Vector{MoveStack} # 1st element is the PV, rest are preallocated tmp PVs
    ss::ThreadStats
    moveorders::Vector{MoveOrder}
    movestack::MoveStack
    history::ButterflyTable
end
Thread() = Thread(Board(), [MoveStack(MAX_PLY + 1) for i in 1:MAX_PLY+1], ThreadStats(), [MoveOrder() for i in 0:MAX_PLY+1], MoveStack(256),
    ButterflyTable([[zeros(Int32, 64) for i in 1:64] for j in 1:2]))


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
