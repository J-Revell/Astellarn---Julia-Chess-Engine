"""
    Bitboard

The type used to encode the information about the 64 squares into a 64 bit number.
Construct an object of type `Bitboard` by providing a value of type `UInt64`.

# Example
```julia-repl
julia> Bitboard(0x00ff00000000ff00)
Bitboard:
8
7 x x x x x x x x
6
5
4
3
2 x x x x x x x x
1
  A B C D E F G H
```
"""
struct Bitboard
    val::UInt64
end


"""
    square(bb::Bitboard)

Returns an `Int` representing the first square contained within a `Bitboard`.
"""
function square(bb::Bitboard)
    trailing_zeros(bb.val) + 1
end


"""
    Bitboard(sqr::Integer)

Returns the `Bitboard` representing the square given by an integer `sqr`.
"""
# function Bitboard(sqr::Integer)
#     #@assert one(eltype(sqr)) <= sqr <= eltype(sqr)(64)
#     Bitboard(one(UInt) << (sqr - one(eltype(sqr))))
# end
function Bitboard(sqr::Integer)
    #@assert one(eltype(sqr)) <= sqr <= eltype(sqr)(64)
    Bitboard(one(UInt) << (sqr - one(sqr)))
end


"""
    &(bb_1::Bitboard, bb_2::Bitboard)
    &(bb::Bitboard, sqr::Integer)
The bitwise "and" (intersection) between two `Bitboard` objects.
Also supports the case where one argument is a square of `Integer` type.
"""
(&)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val & bb_2.val)
(&)(bb::Bitboard, sqr::Integer) = bb & Bitboard(sqr)


"""
    |(bb_1::Bitboard, bb_2::Bitboard)
    |(bb::Bitboard, sqr::Integer)
The bitwise "or" (union) between two `Bitboard` objects.
Also supports the case where one argument is a square of `Integer` type.
"""
(|)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val | bb_2.val)
(|)(bb::Bitboard, sqr::Integer) = bb | Bitboard(sqr)


"""
    ~(bb::Bitboard)

The bitwise "not" of a `Bitboard` object. That is, return a `Bitboard` representing all the squares not in `bb`.
"""
(~)(bb::Bitboard) = Bitboard(~bb.val)


"""
    <<(bb::Bitboard, n::Int)

Shift the bits in the `Bitboard` object left by an integer `n`.
"""
(<<)(bb::Bitboard, n::Integer) = Bitboard(bb.val << n)


"""
    >>(bb::Bitboard, n::Int)

Shift the bits in the `Bitboard` object right by an integer `n`.
"""
(>>)(bb::Bitboard, n::Integer) = Bitboard(bb.val >> n)


"""
    ⊻(bb_1::Bitboard, bb_2::Bitboard)

The bitwise "exclusive or" between two `Bitboard` objects.
"""
(⊻)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val ⊻ bb_2.val)
(⊻)(bb::Bitboard, sqr::Integer) = bb ⊻ Bitboard(sqr)


"""
    isempty(bb:Bitboard)

Determines if a given `Bitboard` contains any active squares
"""
isempty(bb::Bitboard) = bb.val === zero(UInt)


"""
    count(bb::Bitboard)

Count the number of filled squares in a `Bitboard` object.
"""
count(bb::Bitboard) = count_ones(bb.val)


"""
    isone(bb::Bitboard)

Returns `true` if the `Bitboard` contains only one square.
"""
isone(bb::Bitboard) = count(bb) === 1


"""
    ismany(bb::Bitboard)

Returns `true` if the `Bitboard` contains more than one square.
"""
ismany(bb::Bitboard) = count(bb) > 1


# Used internally for iterating over bitboard squares
function poplsb(bb::Bitboard)
    return square(bb), Bitboard(bb.val & (bb.val - one(bb.val)))
end


# Used internally for iterating over bitboard squares
function iterate(bb::Bitboard, state::Bitboard = bb)
    isempty(state) ? nothing : poplsb(state)
end


"""
    FILE_A

A `Bitboard` constant representing the A file of a chess board.
"""
const FILE_A = Bitboard(0x8080808080808080)


"""
    FILE_B

A `Bitboard` constant representing the B file of a chess board.
"""
const FILE_B = FILE_A >> 1


"""
    FILE_C

A `Bitboard` constant representing the C file of a chess board.
"""
const FILE_C = FILE_A >> 2


"""
    FILE_D

A `Bitboard` constant representing the D file of a chess board.
"""
const FILE_D = FILE_A >> 3


"""
    FILE_E

A `Bitboard` constant representing the E file of a chess board.
"""
const FILE_E = FILE_A >> 4


"""
    FILE_F

A `Bitboard` constant representing the F file of a chess board.
"""
const FILE_F = FILE_A >> 5


"""
    FILE_G

A `Bitboard` constant representing the G file of a chess board.
"""
const FILE_G = FILE_A >> 6


"""
    FILE_H

A `Bitboard` constant representing the H file of a chess board.
"""
const FILE_H = FILE_A >> 7


"""
    FILE_AB

A `Bitboard` constant representing the files A and B together.
"""
const FILE_AB = FILE_A | FILE_B


"""
    FILE_GH

A `Bitboard` constant representing the files G and H together.
"""
const FILE_GH = FILE_G | FILE_H


"""
    RANK_1

A `Bitboard` constant representing the 1st rank (A1 -> H1) of a chess board.
"""
const RANK_1 = Bitboard(0x00000000000000ff)


"""
    RANK_2

A `Bitboard` constant representing the 2nd rank of a chess board.
"""
const RANK_2 = RANK_1 << 8


"""
    RANK_3

A `Bitboard` constant representing the 3rd rank of a chess board.
"""
const RANK_3 = RANK_1 << 16


"""
    RANK_4

A `Bitboard` constant representing the 4th rank of a chess board.
"""
const RANK_4 = RANK_1 << 24


"""
    RANK_5

A `Bitboard` constant representing the 5th rank of a chess board.
"""
const RANK_5 = RANK_1 << 32


"""
    RANK_6

A `Bitboard` constant representing the 6th rank of a chess board.
"""
const RANK_6 = RANK_1 << 40


"""
    RANK_7

A `Bitboard` constant representing the 7th rank of a chess board.
"""
const RANK_7 = RANK_1 << 48


"""
    RANK_8

A `Bitboard` constant representing the 8th rank of a chess board.
"""
const RANK_8 = RANK_1 << 56


"""
    RANK_12

A `Bitboard` constant representing the 1st and 2nd ranks of the chess board.
"""
const RANK_12 = RANK_1 | RANK_2


"""
    RANK_12

A `Bitboard` constant representing the 7th and 8th ranks of the chess board.
"""
const RANK_78 = RANK_7 | RANK_8


"""
    RANK_18

A `Bitboard` constant representing the promotion ranks of a chess board.
"""
const RANK_18 = RANK_1 | RANK_8


"""
    RANK_27

A `Bitboard` constant representing the starting pawn ranks of a chess board.
"""
const RANK_27 = RANK_2 | RANK_7


"""
    FILE

A static vector containing all the `Bitboard` representations of the files of the board.
"""
const FILE = @SVector [FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H]


"""
    RANK

A static vector containing all the `Bitboard` representations of the ranks of the board.
"""
const RANK = @SVector [RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8]


"""
    file(bb::Bitboard)
    file(sqr::Int)

Get the `Bitboard` representing the file of the given square.
Input is given as either an `Integer` type, or a `Bitboard` - assuming it contains only one square.
"""
function file(sqr::Integer)
    @inbounds FILE[mod1(65 - sqr, 8)]
end
file(bb::Bitboard) = file(square(bb))


"""
    rank(bb::Bitboard)
    rank(sqr::Int)

Get the `Bitboard` representing the rank of the given square.
Input is given as either an `Integer` type, or a `Bitboard` - assuming it contains only one square.
"""
function rank(sqr::Integer)
    @inbounds RANK[fld1(sqr, 8)]
end
rank(bb::Bitboard) = rank(square(bb))


"""
    EMPTY

A `Bitboard` constant representing an empty board.
"""
const EMPTY = Bitboard(UInt(0))


"""
    FULL

A `Bitboard` constant representing a full board.
"""
const FULL = ~EMPTY


const LIGHT = Bitboard(0xAA55AA55AA55AA55)
const DARK = ~LIGHT

# Custom show for bitboard types
function Base.show(io::IO, bb::Bitboard)
    println(io, "Bitboard:")
    for row in 1:8
        for col in 1:8
            if col == 1
                print(9 - row, " ")
            end
            sqr = FILE[col] & RANK[9 - row]
            sym = !isempty(sqr & bb) ? 'x' : ' '
            foreground = :red
            background = isodd(row + col) ? :blue : :light_blue
            print(Crayon(foreground = foreground, background = background), sym, " ")
        end
        print(Crayon(reset = true), "\n")
    end
    println("  A B C D E F G H")
end
