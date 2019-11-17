# symbolic notation
const SYMBOLS = ['♙','♘','♗','♖','♕','♔'] .+ 6

const COLUMNS = ["A", "B", "C", "D", "E", "F", "G", "H"]

# colours
const NONE = UInt8(0)
const WHITE = UInt8(1)
const BLACK = UInt8(2)

# pieces, also used as PROMOTION flags
const PAWN = UInt8(1)
const KNIGHT = UInt8(2)
const BISHOP = UInt8(3)
const ROOK = UInt8(4)
const QUEEN = UInt8(5)
const KING = UInt8(6)

# Enpassant flag
const ENPASS = UInt8(10)

# Castling flag
const CASTLE = UInt8(20)

# convert labels to bitboard representation
const LABELLED_SQUARES = [*(args...) for args in Base.product("hgfedcba","12345678")]
const LABEL_TO_BITBOARD = Dict(reshape(LABELLED_SQUARES, 64) .=> [UInt64(1) << i for i in 0:63])

# Bitboard representation of the board FILES
const FILE_A = 0x8080808080808080
const FILE_B = FILE_A >> 1
const FILE_C = FILE_A >> 2
const FILE_D = FILE_A >> 3
const FILE_E = FILE_A >> 4
const FILE_F = FILE_A >> 5
const FILE_G = FILE_A >> 6
const FILE_H = FILE_A >> 7

# Bitboard representation of the board RANKS
const RANK_1 = 0x00000000000000ff
const RANK_2 = RANK_1 << 8
const RANK_3 = RANK_1 << 16
const RANK_4 = RANK_1 << 24
const RANK_5 = RANK_1 << 32
const RANK_6 = RANK_1 << 40
const RANK_7 = RANK_1 << 48
const RANK_8 = RANK_1 << 56

# Useful Bitboard representation of side files, for determining Knight bounds.
const FILE_AB = FILE_A | FILE_B
const FILE_GH = FILE_G | FILE_H

# Useful Bitboard representation of side ranks, for determining Knight bounds.
const RANK_12 = RANK_1 | RANK_2
const RANK_78 = RANK_7 | RANK_8

# Bitboard representation of the panw promotion ranks.
const RANK_18 = RANK_1 | RANK_8

# castling masks
const CASTLE_OO_MASK_W = (UInt(1) << 1) | (UInt(1) << 2)
const CASTLE_OOO_MASK_W = (UInt(1) << 4) | (UInt(1) << 5)
const CASTLE_OO_MASK_B = (UInt(1) << 57) | (UInt(1) << 58)
const CASTLE_OOO_MASK_B = (UInt(1) << 60) | (UInt(1) << 61)
