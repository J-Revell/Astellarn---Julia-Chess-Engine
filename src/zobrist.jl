struct ZobristHash
    hash::UInt64
end

(⊻)(z1::ZobristHash, z2::ZobristHash) = ZobristHash(z1.hash ⊻ z2.hash)
(⊻)(z1::ZobristHash, z2::Unsigned) = ZobristHash(z1.hash ⊻ z2)
Base.isequal(z1::ZobristHash, z2::ZobristHash) = isequal(z1.hash, z2.hash)


mutable struct XORShiftState
    val::UInt64
end

const __XORSHIFT_SEED = XORShiftState(UInt64(1070372))

# inspired from Ethereal
function xorshift_generator()
    let seed = __XORSHIFT_SEED
        seed.val ⊻= seed.val >> 12
        seed.val ⊻= seed.val << 25
        seed.val ⊻= seed.val >> 27
        return ZobristHash(seed.val * UInt64(2685821657736338717))
    end
end

# Pieces
const ZOB_SQKEYS = SVector{64}([SVector{12}([xorshift_generator() for i in 1:12]) for j in 1:64])

# enpassant
const ZOB_EPKEYS = SVector{8}([xorshift_generator() for i in 1:8])

# castling
const ZOB_OOKEYS = SVector{16}([xorshift_generator() for i in 1:16])

# side to move
const ZOB_TURNKEY = xorshift_generator()


function zobkey(piece::Piece, sqr::Integer)
    @inbounds ZOB_SQKEYS[sqr][type(piece).val << (color(piece).val - 1)]
end

function zobepkey(sqr::Integer)
    @inbounds ZOB_EPKEYS[mod1(65 - sqr, 8)]
end


# + 1 for no castling case
function zobookey(castling::UInt8)
    @inbounds ZOB_OOKEYS[castling + 1]
end

function zobturnkey()
    @inbounds ZOB_TURNKEY
end
