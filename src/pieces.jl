"""
    PieceType

`DataType` representing a type of piece.
"""
struct PieceType
    val::UInt8
end


"""
    Piece

`DataType` representing a specific piece with type and color.
"""
struct Piece
    val::UInt8
end


"""
    PAWN

Constant representing a pawn.
"""
const PAWN = PieceType(1)

const WHITEPAWN = Piece(9)
const BLACKPAWN = Piece(17)


"""
    KNIGHT

Constant representing a knight.
"""
const KNIGHT = PieceType(2)

const WHITEKNIGHT = Piece(10)
const BLACKKNIGHT = Piece(18)


"""
    BISHOP

Constant representing a bishop.
"""
const BISHOP = PieceType(3)

const WHITEBISHOP = Piece(11)
const BLACKBISHOP = Piece(19)


"""
    ROOK

Constant representing a rook.
"""
const ROOK = PieceType(4)

const WHITEROOK = Piece(12)
const BLACKROOK = Piece(20)


"""
    QUEEN

Constant representing a Queen.
"""
const QUEEN = PieceType(5)

const WHITEQUEEN = Piece(13)
const BLACKQUEEN = Piece(21)

"""
    KING

Constant representing a King.
"""
const KING = PieceType(6)

const WHITEKING = Piece(14)
const BLACKKING = Piece(22)

"""
    Blank

Constant representing no piece, or a blank square.
"""
const VOID = PieceType(0)
const BLANK = Piece(0)

"""
    Color

`DataType` representing a color.
"""
struct Color
    val::UInt8
end


"""
    WHITE

Constant representing white.
"""
const WHITE = Color(1)


"""
    BLACK

Constant representing black.
"""
const BLACK = Color(2)


"""
    None

Constant representing no color.
"""
const NONE = Color(0)


"""
    !(color::Color)

Find the opposite color.
"""
(!)(color::Color) = Color(4 >> color.val)


"""
    type(piece::Piece)

Return the type of a given `piece`.
"""
type(piece::Piece) = PieceType(piece.val & 7)


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
