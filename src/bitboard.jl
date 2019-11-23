import Base.&, Base.|, Base.~, Base.<<, Base.>>, Base.⊻, Base.isempty
import Base.show


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


# Custom show for bitboard types
function Base.show(io::IO, bb::Bitboard)
    println(io, "Bitboard:")
    displayBitboard(bb.val)
end


"""
    &(bb_1::Bitboard, bb_2::Bitboard)

The bitwise "and" (intersection) between two `Bitboard` objects.
"""
(&)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val & bb_2.val)


"""
    |(bb_1::Bitboard, bb_2::Bitboard)

The bitwise "or" (union) between two `Bitboard` objects.
"""
(|)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val | bb_2.val)


"""
    ~(bb::Bitboard)

The bitwise "not" of a `Bitboard` object. That is, return a `Bitboard` representing all the squares not in `bb`.
"""
(~)(bb::Bitboard) = Bitboard(~bb.val)


"""
    <<(bb::Bitboard, n::Int)

Shift the bits in the `Bitboard` object left by an integer `n`.
"""
(<<)(bb::Bitboard, n::Int) = Bitboard(bb.val << n)


"""
    >>(bb::Bitboard, n::Int)

Shift the bits in the `Bitboard` object right by an integer `n`.
"""
(>>)(bb::Bitboard, n::Int) = Bitboard(bb.val >> n)


"""
    ⊻(bb_1::Bitboard, bb_2::Bitboard)

The bitwise "exclusive or" between two `Bitboard` objects.
"""
(⊻)(bb_1::Bitboard, bb_2::Bitboard) = Bitboard(bb_1.val ⊻ bb_2.val)


"""
    isempty(bb:Bitboard)

Determines if a given `Bitboard` contains any active squares
"""
isempty(bb::Bitboard) = bb.val == zero(UInt)


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


# constants for all the squares in bitboard representation
const H1_BB = Bitboard(UInt(1))
const G1_BB = H1_BB << 1
const F1_BB = H1_BB << 2
const E1_BB = H1_BB << 3
const D1_BB = H1_BB << 4
const C1_BB = H1_BB << 5
const B1_BB = H1_BB << 6
const A1_BB = H1_BB << 7

const H2_BB = H1_BB << 8
const G2_BB = H1_BB << 9
const F2_BB = H1_BB << 10
const E2_BB = H1_BB << 11
const D2_BB = H1_BB << 12
const C2_BB = H1_BB << 13
const B2_BB = H1_BB << 14
const A2_BB = H1_BB << 15

const H3_BB = H1_BB << 16
const G3_BB = H1_BB << 17
const F3_BB = H1_BB << 18
const E3_BB = H1_BB << 19
const D3_BB = H1_BB << 20
const C3_BB = H1_BB << 21
const B3_BB = H1_BB << 22
const A3_BB = H1_BB << 23

const H4_BB = H1_BB << 24
const G4_BB = H1_BB << 25
const F4_BB = H1_BB << 26
const E4_BB = H1_BB << 27
const D4_BB = H1_BB << 28
const C4_BB = H1_BB << 29
const B4_BB = H1_BB << 30
const A4_BB = H1_BB << 31

const H5_BB = H1_BB << 32
const G5_BB = H1_BB << 33
const F5_BB = H1_BB << 34
const E5_BB = H1_BB << 35
const D5_BB = H1_BB << 36
const C5_BB = H1_BB << 37
const B5_BB = H1_BB << 38
const A5_BB = H1_BB << 39

const H6_BB = H1_BB << 40
const G6_BB = H1_BB << 41
const F6_BB = H1_BB << 42
const E6_BB = H1_BB << 43
const D6_BB = H1_BB << 44
const C6_BB = H1_BB << 45
const B6_BB = H1_BB << 46
const A6_BB = H1_BB << 47

const H7_BB = H1_BB << 48
const G7_BB = H1_BB << 49
const F7_BB = H1_BB << 50
const E7_BB = H1_BB << 51
const D7_BB = H1_BB << 52
const C7_BB = H1_BB << 53
const B7_BB = H1_BB << 54
const A7_BB = H1_BB << 55

const H8_BB = H1_BB << 56
const G8_BB = H1_BB << 57
const F8_BB = H1_BB << 58
const E8_BB = H1_BB << 59
const D8_BB = H1_BB << 60
const C8_BB = H1_BB << 61
const B8_BB = H1_BB << 62
const A8_BB = H1_BB << 63
