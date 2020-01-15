# The Move struct stores information in bits as follows...
# FLAG | mov to | m from
# 0000 | 000000 | 000000
"""
    Move

`DataType` used to store the information encoding a move.
"""
struct Move
    val::UInt16
end


"""
    MoveStack

`DataType` for storing lists of moves.
"""
mutable struct MoveStack <: AbstractArray{Move, 1}
    list::Vector{Move}
    idx::Int
end


"""
    Undo

`DataType` for storing the minimal amount of information to restore a `Board` object to its previous position.
"""
struct Undo
    checkers::Bitboard
    pinned::Bitboard
    castling::UInt8
    enpass::UInt8
    captured::Piece
    halfmovecount::UInt16
    hash::ZobristHash
    psqteval::Int32
    phash::ZobristHash
end


"""
    UndoStack

`DataType` for storing lists of `Undos`.
"""
mutable struct UndoStack <: AbstractArray{Undo, 1}
    list::Vector{Undo}
    idx::Int
end


"""
    ThreadStats

`DataType` for storing the stats of the thread during a search.
"""
mutable struct ThreadStats
    depth::Int
    seldepth::Int
    nodes::Int
    tbhits::Int
    time_start::Float64
end


# ButterflyTable for storing move histories.
# The datatype is ugly, so this alias makes it more tidy.
# BTABLE[i][j][k]
# [i] => colour
# [j] => from
# [k] => to
# https://www.chessprogramming.org/index.php?title=Butterfly_Boards
const ButterflyHistTable = MArray{Tuple{2},MArray{Tuple{64},MArray{Tuple{64},Int,1,64},1,64},1,2}
const CounterHistTable = MArray{Tuple{6},MArray{Tuple{64},MArray{Tuple{6},MArray{Tuple{64},Int,1,64},1,6},1,64},1,6}
const CounterTable = MArray{Tuple{2},MArray{Tuple{6},MArray{Tuple{64},Move,1,64},1,6},1,2}


"""
    MoveOrder

`DataType` for storing information used in ordering moves.
"""
mutable struct MoveOrder
    type::UInt8
    stage::UInt8
    movestack::MoveStack
    values::Vector{Int}
    margin::Int
    noisy_size::Int
    quiet_size::Int
    tt_move::Move
    killer1::Move
    killer2::Move
    counter::Move
end


mutable struct PT_Entry
    score::Int
end

const PawnTable = Dict{ZobristHash, PT_Entry}


"""
    Thread

`DataType` used to store information used by the thread during its search.
"""
mutable struct Thread
    board::Board
    pv::Vector{MoveStack} # 1st element is the PV, rest are preallocated tmp PVs
    ss::ThreadStats
    moveorders::Vector{MoveOrder}
    movestack::MoveStack
    piecestack::PieceStack
    evalstack::Vector{Int}
    quietstack::Vector{MoveStack}
    history::ButterflyHistTable
    counterhistory::CounterHistTable
    followhistory::CounterHistTable
    killers::Vector{MoveStack}
    cmtable::CounterTable
    ptable::PawnTable
end
