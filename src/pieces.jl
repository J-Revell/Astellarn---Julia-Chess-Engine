"""
    PieceType

`DataType` representing a type of piece.
"""
struct PieceType
    val::UInt8
end

# Define all piecetypes
const PIECETYPES = [:VOID, :PAWN, :KNIGHT, :BISHOP, :ROOK, :QUEEN, :KING]

for (num, pt) in enumerate(PIECETYPES)
    @eval const $pt = PieceType($num - 1)
end


"""
    Piece

`DataType` representing a specific piece with type and color.
"""
struct Piece
    val::UInt8
end

# Define all pieces
const WHITE_PIECES = [:WHITEPAWN, :WHITEKNIGHT, :WHITEBISHOP, :WHITEROOK, :WHITEQUEEN, :WHITEKING]
const BLACK_PIECES = [:BLACKPAWN, :BLACKKNIGHT, :BLACKBISHOP, :BLACKROOK, :BLACKQUEEN, :BLACKKING]
const BLANK = Piece(0)

for (num, p) in enumerate(WHITE_PIECES)
    @eval const $p = Piece($num + 8)
end

for (num, p) in enumerate(BLACK_PIECES)
    @eval const $p = Piece($num + 16)
end


"""
    type(piece::Piece)

Return the type of a given `piece`.
"""
type(piece::Piece) = PieceType(piece.val & 7)


"""
    PieceStack

`DataType` storing a vector of PieceTypes.
"""
mutable struct PieceStack <: AbstractArray{PieceType, 1}
    list::Vector{PieceType}
    idx::Int
end

# Allows a preallocation for PieceStack
PieceStack(size::Int) = PieceStack(repeat([VOID], size), 0)

# define useful array methods for PieceStack
Base.iterate(m::PieceStack, state = 1) = (state > m.idx) ? nothing : (m.list[state], state + 1)
Base.length(m::PieceStack) = m.idx
Base.eltype(::Type{PieceStack}) = PieceType
Base.size(m::PieceStack) = (m.idx, )
Base.IndexStyle(::Type{<:PieceStack}) = IndexLinear()
Base.getindex(m::PieceStack, idx::Int) = m.list[idx]

# add moves to the PieceStack
function push!(m::PieceStack, piece::PieceType)
    m.idx += 1
    @inbounds m.list[m.idx] = piece
end


"""
    Color

`DataType` representing a color.
"""
struct Color
    val::UInt8
end

const COLORS = [:NONE, :WHITE, :BLACK]
for (num, c) in enumerate(COLORS)
    @eval const $c = Color($num - 1)
end


"""
    !(color::Color)

Find the opposite color.
"""
(!)(color::Color) = Color(4 >> color.val)


"""
    color(piece::Piece)

Return the `Color` type of a given `piece`.
"""
color(piece::Piece) = Color(piece.val >> 3)


"""
    makepiece(piece::Piece, color::Color)

Return a `piece` of a given `color`.
"""
makepiece(type::PieceType, color::Color) = Piece((color.val << 3) | type.val)
