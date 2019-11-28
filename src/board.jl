"""
    Board

A `DataType` representing the state of a chess board.
"""
mutable struct Board
    squares::MVector{64,Piece}
    pieces::MVector{6,Bitboard}
    colors::MVector{2,Bitboard}
    checkers::Bitboard
    pinned::Bitboard
    turn::Color
    castling::UInt8
    enpass::UInt8
    halfmovecount::UInt16
    movecount::UInt16
    hash::UInt64
end

function Board(squares::AbstractArray{Piece}, pieces::AbstractArray{Bitboard}, colors::AbstractArray{Bitboard},
    checkers::Bitboard, pinned::Bitboard, turn::Color, castling::UInt8, enpass::UInt8, halfmovecount::UInt16, movecount::UInt16, hash::UInt64)

    return Board(MVector(squares...), MVector(pieces...), MVector(colors...), checkers, pinned, turn, castling, enpass, halfmovecount, movecount, hash)
end
Board() = Board(repeat([BLANK], 64), repeat([EMPTY], 6), repeat([EMPTY], 2), EMPTY, EMPTY, WHITE, zero(UInt8), zero(UInt8), zero(UInt16), zero(UInt16), zero(UInt64))


getindex(board::Board, color::Color) = @inbounds board.colors[color.val]
getindex(board::Board, type::PieceType) = @inbounds board.pieces[type.val]
getindex(board::Board, piece::Piece) = @inbounds board[type(piece)] & board[color(piece)]
getindex(board::Board, idx::Integer) = @inbounds board.squares[idx]

setindex!(board::Board, bb::Bitboard, type::PieceType) = setindex!(board.pieces, bb, type.val)
setindex!(board::Board, bb::Bitboard, color::Color) = setindex!(board.colors, bb, color.val)
setindex!(board::Board, piece::Piece, idx::Integer) = setindex!(board.squares, piece, idx)


"""
    add!(board::Board, piece::Piece, bb::Bitboard)
    add!(board::Board, piece::Piece, sqr::Integer)

Add a `piece` to the `board` square given by an `Integer` `sqr`, or a `Bitboard` `bb`.
"""
function add!(board::Board, piece::Piece, bb::Bitboard, sqr::Integer)
    @inbounds board[type(piece)] |= bb
    @inbounds board[color(piece)] |= bb
    @inbounds board[sqr] = piece
    board.hash ⊻= zobkey(piece, sqr)
end
add!(board::Board, piece::Piece, bb::Bitboard) = add!(board, piece, bb, square(bb))
add!(board::Board, piece::Piece, sqr::Integer) = add!(board, piece, Bitboard(sqr), sqr)


"""
    remove!(board::Board, bb::Bitboard)
    remove!(board::Board, sqr::Integer)

Remove a `piece` from the `board` at the square given by an `Integer` `sqr`, or a `Bitboard` `bb`.
"""
function remove!(board::Board, bb::Bitboard, sqr::Integer)
    piece = board.squares[sqr]
    board[type(piece)] &= ~bb
    board[color(piece)] &= ~bb
    board.squares[sqr] = BLANK
    board.hash ⊻= zobkey(piece, sqr)
end
remove!(board::Board, bb::Bitboard) = remove!(board, bb, square(bb))
remove!(board::Board, sqr::Integer) = remove!(board, Bitboard(sqr), sqr)


"""
    addremove!(board::Board, piece::Piece, bb::Bitboard)
    addremove!(board::Board, piece::Piece, sqr::Integer)

Remove a `piece` from the `board` at the square given by an `Integer` `sqr`, or a `Bitboard` `bb`, and then add the given `piece` in its place.
"""
function addremove!(board::Board, piece::Piece, bb::Bitboard, sqr::Integer)
    captured = board.squares[sqr]
    board[type(captured)] &= ~bb
    board[color(captured)] &= ~bb
    board[type(piece)] |= bb
    board[color(piece)] |= bb
    board[sqr] = piece
    board.hash ⊻= zobkey(captured, sqr)
    board.hash ⊻= zobkey(piece, sqr)
end
addremove!(board::Board, piece::Piece, bb::Bitboard) = addremove!(board, piece, bb, square(bb))
addremove!(board::Board, piece::Piece, sqr::Integer) = addremove!(board, piece, Bitboard(sqr), sqr)


"""
    ischeck(board::Board)

Returns `true` if the king is in check, `false` otherwise.
"""
ischeck(board::Board) = !isempty(board.checkers)


"""
    isdoublecheck(board::Board)

Returns `true` if the king is in check, `false` otherwise.
"""
isdoublecheck(board::Board) = ismany(board.checkers)


"""
    switchturn(board::Board)

Switches the `Color` of the side to move on a given `Board` object.
"""
switchturn!(board::Board) = board.turn = !board.turn


"""
    enemies(board::Board)

Return the positions, as a `Bitboard`, of all the enemies on the board.
"""
enemy(board::Board) = @inbounds board[!board.turn]


"""
    friendly(board::Board)

Return the positions, as a `Bitboard`, of all the friendly units on the board.
"""
friendly(board::Board) = @inbounds board[board.turn]


"""
    occupied(board::Board)

Return the positions, as a `Bitboard`, of all the occupied squares on the board.
"""
occupied(board::Board) = @inbounds board[WHITE] | board[BLACK]


"""
    empty(board::Board)

Return the positions, as a `Bitboard`, of all the empty squares on the board.
"""
empty(board::Board) = ~occupied(board)


"""
    SYMBOLS

A constant holding the glyphs for each chess piece.
"""
const SYMBOLS = ['♙','♘','♗','♖','♕','♔'] .+ 6


# custom show for board type
function Base.show(io::IO, board::Board)
    for row in 1:8
        for col in 1:8
            if col == 1
                print(9 - row, " ")
            end
            sqr = square(FILE[col] & RANK[9 - row])
            pcolor = color(board[sqr])
            ptype = type(board[sqr])
            sym = (ptype.val > zero(UInt8)) ? SYMBOLS[ptype.val] : ' '
            foreground = (pcolor == WHITE) ? :white : :black
            background = isodd(row + col) ? :blue : :light_blue
            print(Crayon(foreground = foreground, background = background), sym, " ")
            if (row == 1) && (col == 8) && (board.turn == WHITE)
                print(Crayon(reset = true), " White to move...")
            elseif (row == 1) && (col == 8) && (board.turn == BLACK)
                print(Crayon(reset = true), " Black to move...")
            end
        end
        print(Crayon(reset = true), "\n")
    end
    println("  A B C D E F G H")
end


"""
    pawns(board::Board)

Get the location of all the pawns on the `board`, as a `Bitboard`.
"""
pawns(board::Board) = @inbounds board[PAWN]


"""
    knights(board::Board)

Get the location of all the knights on the `board`, as a `Bitboard`.
"""
knights(board::Board) = @inbounds board[KNIGHT]


"""
    bishops(board::Board)

Get the location of all the bishops on the `board`, as a `Bitboard`.
"""
bishops(board::Board) = @inbounds board[BISHOP]


"""
    rooks(board::Board)

Get the location of all the rooks on the `board`, as a `Bitboard`.
"""
rooks(board::Board) = @inbounds board[ROOK]


"""
    queens(board::Board)

Get the location of all the queens on the `board`, as a `Bitboard`.
"""
queens(board::Board) = @inbounds board[QUEEN]


"""
    kings(board::Board)

Get the location of all the kings on the `board`, as a `Bitboard`.
"""
kings(board::Board) = @inbounds board[KING]


"""
    rooklike(board::Board)

Get the location of all the rooks and queens on the `board`, as a `Bitboard`.
"""
rooklike(board::Board) = rooks(board) | queens(board)


"""
    bishoplike(board::Board)

Get the location of all the bishops and queens on the `board`, as a `Bitboard`.
"""
bishoplike(board::Board) = bishops(board) | queens(board)


"""
    piece(board::Board, sqr::Integer)

Get the `Piece` located at a square, `sqr`.
"""
piece(board::Board, sqr::Integer) = @inbounds board[sqr]


"""
    checkers(board::Board)

Return the `Bitboard` of all the pieces giving check.
"""
checkers(board::Board) = board.checkers


"""
    pinned(board::Board)

Return the `Bitboard` of all the pieces that are pinned.
"""
pinned(board::Board) = board.pinned


# Castling as follows
# white kingside UInt8(1) << 0 (color val - 1)
# black kingside UInt8(1) << 1 (color val - 1)
# white queenside UInt8(1) << 2 (color val + 1)
# black queenside UInt8(1) << 3(color val + 1)
"""
    cancastlekingside(board::Board, color::Color)
    cancastlekingside(board::Board)

Return a `Bool` which denotes if the player of `color` can castle kingside.
"""
cancastlekingside(board::Board, color::Color) = isone((board.castling >> (color.val - 1)) & 1)
cancastlekingside(board::Board) = cancastlekingside(board, board.turn)


"""
    cancastlequeenside(board::Board, color::Color)
    cancastlequeenside(board::Board)

Return a `Bool` which denotes if the player of `color` can castle queenside. If no color is given, it assumes the `color` of the current turn.
"""
cancastlequeenside(board::Board, color::Color) = isone((board.castling >> (color.val + 1)) & 1)
cancastlequeenside(board::Board) = cancastlequeenside(board, board.turn)
