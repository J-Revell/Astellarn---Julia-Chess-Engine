const BOUND_LOWER = UInt8(1)
const BOUND_UPPER = UInt8(2)
const BOUND_EXACT = UInt8(3)


mutable struct TT_Entry
    eval::Int16
    move::Move
    depth::UInt8
    bound::UInt8
end
const NO_ENTRY = TT_Entry(0, Move(), 0, 0)


mutable struct TT_Table
    table::Dict{ZobristHash, TT_Entry}
end
TT_Table() = TT_Table(Dict{ZobristHash, TT_Entry}())



function getTTentry(tt::TT_Table, hash::ZobristHash)
    tt.table[hash]
end


function hasTTentry(tt::TT_Table, hash::ZobristHash)
    haskey(tt.table, hash)
end


function setTTentry!(tt::TT_Table, hash::ZobristHash, entry::TT_Entry)
    tt.table[hash] = entry
end


function ttvalue(tt_entry::TT_Entry, ply::Int)
    if tt_entry.eval >= (MATE - MAX_PLY)
        return tt_entry.eval + ply
    elseif tt_entry.eval <= (MAX_PLY - MATE)
        return tt_entry.eval - ply
    else
        return tt_entry.eval
    end
end
