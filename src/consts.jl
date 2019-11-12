# symbolic notation
const SYMBOLS = ['♙' + 6,'♘' + 6,'♗' + 6,'♖' + 6,'♕' + 6,'♔' + 6]

# defining a8 -> h1 square labels
const LETTER_PREFIXES = ["a", "b", "c", "d", "e", "f", "g", "h"]
const NUMBER_SUFFIXES = ["1", "2", "3", "4", "5", "6", "7", "8"]
_SQUARES = String[]
for number in reverse(NUMBER_SUFFIXES)
    for letter in LETTER_PREFIXES
        push!(_SQUARES, letter*number)
    end
end
const SQUARES = _SQUARES

# colours
const NONE = UInt8(0)
const WHITE = UInt8(1)
const BLACK = UInt8(2)

# pieces
const PAWN = UInt8(1)
const KNIGHT = UInt8(2)
const BISHOP = UInt8(3)
const ROOK = UInt8(4)
const QUEEN = UInt8(5)
const KING = UInt8(6)

# useful shorthand
const K = KNIGHT
const B = BISHOP
const R = ROOK
const Q = QUEEN

# useful for testing
const LABELLED_BOARD = reshape(SQUARES, (8,8))

# convert labels to row/column coords.
const LABEL_2_COORD = Dict(SQUARES .=> collect(Base.product(1:8,8:-1:1))[:])
const COORD_2_LABEL = Dict(collect(Base.product(1:8,8:-1:1))[:] .=> SQUARES)

# convert coordinates to UInt... slower than square() method
const COORD_2_UINT = Dict(collect(Base.product(1:8,8:-1:1))[:] .=>
    reverse([UInt64(1) << i for i in 0:63]))
const UINT_2_COORD = Dict(reverse([UInt64(1) << i for i in 0:63]) .=>
    collect(Base.product(1:8,8:-1:1))[:])

# convert labels to UInt representation
const LABEL_2_UINT = Dict(SQUARES .=> reverse([UInt64(1) << i for i in 0:63]))
const UINT_2_LABEL = Dict(reverse([UInt64(1) << i for i in 0:63]) .=> SQUARES)

const FILE_A = 0x8080808080808080
const FILE_B = FILE_A >> 1
const FILE_C = FILE_A >> 2
const FILE_D = FILE_A >> 3
const FILE_E = FILE_A >> 4
const FILE_F = FILE_A >> 5
const FILE_G = FILE_A >> 6
const FILE_H = FILE_A >> 7

const RANK_1 = 0x00000000000000ff
const RANK_2 = RANK_1 << 8
const RANK_3 = RANK_1 << 16
const RANK_4 = RANK_1 << 24
const RANK_5 = RANK_1 << 32
const RANK_6 = RANK_1 << 40
const RANK_7 = RANK_1 << 48
const RANK_8 = RANK_1 << 56

# knight bounds
const FILE_AB = FILE_A | FILE_B
const FILE_GH = FILE_G | FILE_H

# knight bounds
const RANK_12 = RANK_1 | RANK_2
const RANK_78 = RANK_7 | RANK_8

# promotion ranks
const RANK_18 = RANK_1 | RANK_8
