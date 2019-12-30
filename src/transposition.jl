const BOUND_LOWER = 1
const BOUND_UPPER = 2
const BOUND_EXACT = 3


mutable struct TT_Entry
    eval::Int
    move::Move
    depth::Int
    bound::Int
end


mutable struct TT_Table
    table::Dict{UInt64, TT_Entry}
end
TT_Table() = TT_Table(Dict{UInt64, TT_Entry}())


function getTTentry(tt::TT_Table, hash::UInt64)
    tt.table[hash]
end


function hasTTentry(tt::TT_Table, hash::UInt64)
    haskey(tt.table, hash)
end


function setTTentry!(tt::TT_Table, hash::UInt64, entry::TT_Entry)
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
