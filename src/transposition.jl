const BOUND_LOWER = UInt8(1)
const BOUND_UPPER = UInt8(2)
const BOUND_EXACT = UInt8(3)


mutable struct TT_Entry
    eval::Int16
    move::Move
    depth::UInt8
    bound::UInt8
    hash16::UInt16
end
const NO_ENTRY = TT_Entry(0, Move(), 0, 0, 0)


mutable struct TT_Table
    table::Dict{UInt32, TT_Entry}
    hashmask::UInt64
end
TT_Table() = TT_Table(16)


# Chess engines usually face memory restrictions, as we can't possibly hash and store all positions.
# The below function aims to cap the hash memory size, by restricting the keys in the dict.
function TT_Table(size_MB::Int)
    bytes = size_MB << 20

    # work out size of slots in TT
    #slotsize = Base.summarysize(TT_Entry())
    slotsize = 14 # At present...
    maxslots = bytes / slotsize

    size = 1
    while size <= maxslots
        size <<= 1
    end
    # We shift right again as we "overshifted" by one in the while loop.
    size >>= 1
    #
    size -= 1

    TT_Table(Dict{UInt32, TT_Entry}(), UInt64(size))
end


function getTTentry(tt::TT_Table, hash::ZobristHash)
    res = get(tt.table, UInt32(hash.hash & tt.hashmask), NO_ENTRY)
    if (res !== NO_ENTRY) && (res.hash16 === UInt16(hash.hash >> 48))
        return res
    else
        return NO_ENTRY
    end
end


# function hasTTentry(tt::TT_Table, hash::ZobristHash)
#     haskey(tt.table, UInt32(hash.hash & tt.hashmask))
# end


function setTTentry!(tt::TT_Table, hash::ZobristHash, eval::Integer, move::Move, depth::Integer, bound::UInt8)
    hash16 = UInt16(hash.hash >> 48)
    entry = TT_Entry(eval, move, depth, bound, hash16)
    tt.table[UInt32(hash.hash & tt.hashmask)] = entry
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


function hashfull(tt::TT_Table)
    full = 0
    for i in 1:3000
        if haskey(tt.table, UInt32(i))
            full += 1
        end
    end
    fld(full,3)
end
