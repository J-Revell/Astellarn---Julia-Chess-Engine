mutable struct TT_Entry
    eval::Int
    move::Move
    depth::Int
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


function setTTentry(tt::TT_Table, hash::UInt64, entry::TT_Entry)
    tt.table[hash] = entry
end
