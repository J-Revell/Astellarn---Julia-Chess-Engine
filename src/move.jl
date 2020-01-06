# https://www.chessprogramming.org/Encoding_Moves
# Idea is to use a 16-bit Int to encode the move.
# 6 bits for "from", 6 bits for "to", 4 bits for "flags"
const FLAGS = [:__NORMAL_MOVE, :__DOUBLE_PAWN, :__KING_CASTLE, :__QUEEN_CASTLE, :__ENPASS,
    :__KNIGHT_PROMO, :__BISHOP_PROMO, :__ROOK_PROMO, :__QUEEN_PROMO]

for (num, flag) in enumerate(FLAGS)
    @eval const $flag = UInt16($num - 1)
end


"""
    updatecastling!(board::Board, sqr_from::Integer, sqr_to::Integer)

Update the castling rights of the `board`, given a move is played from `sqr_from` to `sqr_to`.
"""
function updatecastling!(board::Board, sqr_from::Integer, sqr_to::Integer)
    board.hash ⊻= board.castling
    @inbounds board.castling &= CASTLING_RIGHT[sqr_from]
    @inbounds board.castling &= CASTLING_RIGHT[sqr_to]
    board.hash ⊻= board.castling
end


# Used for internally changing the castling rights when a move is played.
const CASTLING_RIGHT = @SVector [~0x01, ~0x00, ~0x00, ~0x05, ~0x00, ~0x00, ~0x00, ~0x04,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00, ~0x00,
                                ~0x02, ~0x00, ~0x00, ~0x0a, ~0x00, ~0x00, ~0x00, ~0x08]



# FLAG | mov to | m from
# 0000 | 000000 | 000000
"""
    Move

`DataType` used to store the information encoding a move.
"""
struct Move
    val::UInt16
end
Move() = Move(zero(UInt16))

const MOVE_NONE = Move()
const NULL_MOVE = Move(0xffff)


"""
    Move(move_from::Integer, move_to::Integer, move_flag::Integer)

Encode a move, giving the from & to squares, alongside the promotion flag.
"""
function Move(move_from::Integer, move_to::Integer, move_flag::Integer)
    Move((move_from - one(move_from)) | ((move_to - one(move_from)) << 6) | ((move_flag) << 12))
end


"""
    Move(move_from::Integer, move_to::Integer)

Encode a move, giving the from & to squares, assuming no special move flags.
"""
Move(move_from::Integer, move_to::Integer) = Move(move_from, move_to, __NORMAL_MOVE)


"""
    from(move::Move)

Given a move, retrieve the "move from" square, as an `Integer`.
"""
from(move::Move) = (move.val & 0x003f) + 0x0001


"""
    to(move::Move)

Given a move, retrieve the "move to" square, as an `Integer`.
"""
to(move::Move) = ((move.val >> 6) & 0x003f) + 0x0001


"""
    flag(move::Move)

Given a move, return any special flags, as an `Integer`.
"""
flag(move::Move) = move.val >> 12


function istactical(board::Board, move::Move)
    if flag(move) == __ENPASS
        return true
    elseif flag(move) == __KING_CASTLE
        return true
    elseif flag(move) == __QUEEN_CASTLE
        return true
    elseif flag(move) > __ENPASS
        return true
    elseif board[to(move)] !== BLANK
        return true
    else
        return false
    end
end


# """
#     move_is_psuedo_legal(board::Board, move::Move)
#
# Sanity checks to see if a move makes sense. Returns `true` if so.
# """
# # function is not complete
# function move_is_pseudo_legal(board::Board, move::Move)
#     if move == Move()
#         return false
#     end
#
#     # load square details
#     sqr_from = from(move)
#     sqr_to = to(move)
#
#     # are we moving the right colour?
#     if color(board[sqr_from]) !== board.turn
#         return false
#     end
#
#     # are we moving to a square of our own colour?
#     if color(board[sqr_to]) == board.turn
#         return false
#     end
#
#     ptype_from = type(board[sqr_from])
#     move_flag = flag(move)
#
#     if ptype_from == VOID
#         return false
#     end
#
#     # before we check piece cases, handle checks
#     if isdoublecheck(board) && (ptype_from !== KING)
#         return false
#     end
#
#     if ischeck(board)
#         if !((ptype_from == KING) || isone(Bitboard(sqr_to) & board.checkers) || isone(Bitboard(sqr_to) & blockers(sqr_to, square(kings(board) & friendly(board)))))
#             return false
#         end
#     end
#
#     if ptype_from == KNIGHT
#         return (move_flag == __NORMAL_MOVE) && !isempty(knightMoves(sqr_from) & Bitboard(sqr_to))
#     end
#
#     occ = occupied(board)
#
#     if ptype_from == BISHOP
#         return (move_flag == __NORMAL_MOVE) && isone(bishopMoves(Int(sqr_from), occ) & Bitboard(sqr_to))
#     elseif ptype_from == ROOK
#         return (move_flag == __NORMAL_MOVE) && isone(rookMoves(Int(sqr_from), occ) & Bitboard(sqr_to))
#     elseif ptype_from == QUEEN
#         return (move_flag == __NORMAL_MOVE) && isone(queenMoves(Int(sqr_from), occ) & Bitboard(sqr_to))
#     end
#
#     if ptype_from == PAWN
#         # pawns can't castle
#         if (move_flag == __KING_CASTLE) || (move_flag == __QUEEN_CASTLE)
#             return false
#         end
#
#         pawn_attacks = pawnAttacks(board.turn, sqr_from)
#
#         # check enpass
#         if (move_flag == __ENPASS)
#             return (board.enpass == sqr_to) && isone(Bitboard(sqr_to) & pawn_attacks)
#         end
#
#         advance = pawnAdvance(Bitboard(sqr_from), empty(board), board.turn)
#
#         if (move_flag > __ENPASS)
#             return isone(RANK_27 & Bitboard(sqr_from)) && isone(Bitboard(sqr_to) & RANK_18 & ((pawn_attacks & enemy(board)) | advance))
#         end
#
#         advance |= pawnDoubleAdvance(Bitboard(sqr_from), empty(board), board.turn)
#
#         return isone(Bitboard(sqr_to) & ~RANK_18 & ((pawn_attacks & enemy(board)) | advance))
#     end
#
#     if ptype_from == KING
#         if move_flag == __NORMAL_MOVE
#             return isone(kingMoves(sqr_from) & sqr_to & ~friendly(board))
#         elseif ischeck(board)
#             return false
#         elseif move_flag == __KING_CASTLE
#             return cancastlekingside(board)
#         elseif move_flag == __QUEEN_CASTLE
#             return cancastlequeenside(board)
#         end
#     end
#
#     return false
# end


"""
    MoveStack

`DataType` for storing lists of moves.
"""
mutable struct MoveStack <: AbstractArray{Move, 1}
    list::Vector{Move}
    idx::Int
end


# Allows a preallocation for MoveStack
MoveStack(size::Int) = MoveStack(Vector{Move}(undef, size), 0)


# define useful array methods for MoveStack
Base.iterate(m::MoveStack, state = 1) = (state > m.idx) ? nothing : (m.list[state], state + 1)
Base.length(m::MoveStack) = m.idx
Base.eltype(::Type{MoveStack}) = Move
Base.size(m::MoveStack) = (m.idx, )
Base.IndexStyle(::Type{<:MoveStack}) = IndexLinear()
Base.getindex(m::MoveStack, idx::Int) = m.list[idx]


# add moves to the MoveStack
function push!(m::MoveStack, move::Move)
    m.idx += 1
    @inbounds m.list[m.idx] = move
end


# pseudo-clear the MoveStack
clear!(m::MoveStack) = m.idx = 0


# Potential to make Undo into an immutable struct in future?
"""
    Undo

`DataType` for storing the minimal amount of information to restore a `Board` object to its previous position.
"""
struct Undo
    checkers::Bitboard
    pinned::Bitboard
    castling::UInt8
    enpass::UInt8
    captured::Piece
    halfmovecount::UInt16
    hash::UInt64
end


"""
    UndoStack

`DataType` for storing lists of `Undos`.
"""
mutable struct UndoStack <: AbstractArray{Undo, 1}
    list::Vector{Undo}
    idx::Int
end


# Allows a preallocation for MoveStack
UndoStack(size::Int) = UndoStack(Vector{Undo}(undef, size), 0)


# define useful array methods for UndoStack
Base.iterate(u::UndoStack, state = 1) = (state > u.idx) ? nothing : (u.list[state], state + 1)
Base.length(u::UndoStack) = u.idx
Base.eltype(::Type{UndoStack}) = Undo
Base.size(u::UndoStack) = (u.idx, )
Base.IndexStyle(::Type{<:UndoStack}) = IndexLinear()
Base.getindex(u::UndoStack, idx::Int) = u.list[idx]


# add Undos to the UndoStack
function push!(u::UndoStack, undo::Undo)
    u.idx += 1
    @inbounds u.list[u.idx] = undo
end


# pseudo-clear the UndoStack
clear!(u::UndoStack) = u.idx = 0


"""
    apply_move!(board::Board, move::Move, undo::Undo)

Apply the given `move` to the `board`, adding changes to 'undo'.
"""
function apply_move!(board::Board, move::Move)
    undo_checkers = board.checkers
    undo_pinned = board.pinned
    undo_castling = board.castling
    undo_enpass = board.enpass
    undo_halfmovecount = board.halfmovecount
    undo_hash = board.hash

    # before we update the enpass
    if board.enpass !== zero(UInt8)
        board.hash ⊻= zobepkey(board.enpass)
    end

    # Apply the moves according to the appropriate flag
    if (flag(move) == __NORMAL_MOVE) || (flag(move) == __DOUBLE_PAWN)
        undo_captured = apply_normal!(board, move)
    elseif flag(move) == __ENPASS
        undo_captured = apply_enpass!(board, move)
    elseif (flag(move) == __KING_CASTLE) || (flag(move) == __QUEEN_CASTLE)
        undo_captured = apply_castle!(board, move)
    else
        undo_captured = apply_promo!(board, move)
    end

    # Finishing calculations, for the next turn
    board.hash ⊻= zobturnkey()
    switchturn!(board)

    board.checkers = kingAttackers(board)
    board.pinned = findpins(board)
    board.movecount += one(board.movecount)
    board.history[board.movecount] = board.hash
    return Undo(undo_checkers, undo_pinned, undo_castling, undo_enpass, undo_captured, undo_halfmovecount, undo_hash)
end


"""
    apply_normal!(board::Board, move::Move)

Apply the given `move` to the `board`. Assumes the move has either the `__NORMAL_MOVE` or `__DOUBLE_PAWN` flags.
"""
function apply_normal!(board::Board, move::Move)
    sqr_from = from(move)
    sqr_to = to(move)

    # Check for double pawn advance and set enpass square

    if flag(move) == __DOUBLE_PAWN
        board.enpass = UInt8(square(blockers(sqr_from, sqr_to)))
        board.hash ⊻= zobepkey(sqr_from)
    else
        board.enpass = zero(board.enpass)
    end

    updatecastling!(board, sqr_from, sqr_to)

    p_from = piece(board, sqr_from)
    p_to = piece(board, sqr_to)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    @inbounds board[type(p_from)] ⊻= bb_from ⊻ bb_to
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to
    @inbounds board[sqr_from] = BLANK
    @inbounds board[sqr_to] = p_from

    if p_to !== BLANK
        @inbounds board[type(p_to)] ⊻= bb_to
        @inbounds board[!board.turn] ⊻= bb_to
        board.hash ⊻= zobkey(p_to, sqr_to)
    end

    if (type(p_from) == PAWN) || (p_to !== BLANK)
        board.halfmovecount = 0
    else
        board.halfmovecount += 1
    end

    board.hash ⊻= zobkey(p_from, sqr_from)
    board.hash ⊻= zobkey(p_from, sqr_to)

    return p_to
end


"""
    apply_enpass!(board::Board, move::Move)

Apply the given `move` to the `board`. Assumes the move has the `__ENPASS` flag.
"""
function apply_enpass!(board::Board, move::Move)
    board.enpass = zero(UInt8)

    sqr_from = from(move)
    sqr_to = to(move)

    cap_sqr = sqr_to - 24 + (board.turn.val << 4)
    cap_bb = Bitboard(cap_sqr)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    @inbounds board[PAWN] ⊻= bb_from ⊻ bb_to ⊻ cap_bb
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to
    @inbounds board[!board.turn] ⊻= cap_bb

    # First set the square to
    @inbounds board[sqr_to] = piece(board, sqr_from)
    # Then clear the square from
    @inbounds board[sqr_from] = BLANK
    # Then clear the captured square
    @inbounds board[cap_sqr] = BLANK

    p_from = makepiece(PAWN, board.turn)
    p_capt = makepiece(PAWN, !board.turn)
    board.hash ⊻= zobkey(p_from, sqr_from)
    board.hash ⊻= zobkey(p_from, sqr_to)
    board.hash ⊻= zobkey(p_capt, cap_sqr)

    board.halfmovecount = 0

    return p_capt
end


"""
    apply_castle!(board::Board, move::Move)

Apply the given `move` to the `board`. Assumes the move has the `__KING_CASTLE` or `__QUEEN_CASTLE` flag.
"""
function apply_castle!(board::Board, move::Move)
    board.enpass = zero(UInt8)

    k_from = from(move)
    k_to = to(move)

    updatecastling!(board, k_from, k_to)

    if flag(move) == __KING_CASTLE
        r_from = k_from - 3
        r_to = k_from - 1
    else
        r_from = k_from + 4
        r_to = k_from + 1
    end

    r_from_bb = Bitboard(r_from)
    r_to_bb = Bitboard(r_to)
    k_from_bb = Bitboard(k_from)
    k_to_bb = Bitboard(k_to)

    @inbounds board[KING] ⊻= k_from_bb ⊻ k_to_bb
    @inbounds board[ROOK] ⊻= r_from_bb ⊻ r_to_bb

    @inbounds board[board.turn] ⊻= k_from_bb ⊻ k_to_bb ⊻ r_from_bb ⊻ r_to_bb

    @inbounds board[k_from] = BLANK
    @inbounds board[r_from] = BLANK

    _king = makepiece(KING, board.turn)
    _rook = makepiece(ROOK, board.turn)
    @inbounds board[k_to] = _king
    @inbounds board[r_to] = _rook

    board.hash ⊻= zobkey(_king, k_from)
    board.hash ⊻= zobkey(_king, k_to)
    board.hash ⊻= zobkey(_rook, r_from)
    board.hash ⊻= zobkey(_rook, r_to)

    board.halfmovecount += 1

    return BLANK
end


"""
    apply_promo!(board::Board, move::Move)

Apply the given `move` to the `board`. Assumes the move has the `__<PIECE>_PROMO` flag, where `<PIECE>` is either a `KNIGHT`, `BISHOP`, `ROOK`, or `QUEEN`.
"""
function apply_promo!(board::Board, move::Move)
    board.enpass = zero(UInt8)

    sqr_from = from(move)
    sqr_to = to(move)

    updatecastling!(board, sqr_from, sqr_to)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    p_to = piece(board, sqr_to)
    ptype_promo = PieceType(flag(move) - 3)

    @inbounds board[PAWN] ⊻= bb_from
    @inbounds board[ptype_promo] ⊻= bb_to
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to

    @inbounds board[sqr_from] = BLANK

    p_promo = makepiece(ptype_promo, board.turn)
    @inbounds board[sqr_to] = p_promo

    if p_to !== BLANK
        @inbounds board[type(p_to)] ⊻= bb_to
        @inbounds board[!board.turn] ⊻= bb_to
        board.hash ⊻= zobkey(p_to, sqr_to)
    end

    p_from = makepiece(PAWN, board.turn)
    board.hash ⊻= zobkey(p_from, sqr_from)
    board.hash ⊻= zobkey(p_promo, sqr_to)

    board.halfmovecount = 0

    return p_to
end


function undo_move!(board::Board, move::Move, undo::Undo)
    board.checkers = undo.checkers
    board.pinned = undo.pinned
    board.enpass = undo.enpass
    board.castling = undo.castling
    board.halfmovecount = undo.halfmovecount
    board.movecount -= one(UInt16)
    board.hash = undo.hash
    switchturn!(board)
    if (flag(move) == __NORMAL_MOVE) || (flag(move) == __DOUBLE_PAWN)
        undo_normal!(board, move, undo)
    elseif flag(move) == __ENPASS
        undo_enpass!(board, move, undo)
    elseif (flag(move) == __KING_CASTLE) || (flag(move) == __QUEEN_CASTLE)
        undo_castle!(board, move, undo)
    else
        undo_promo!(board, move, undo)
    end
    return
end


function undo_normal!(board::Board, move::Move, undo::Undo)
    sqr_from = to(move)
    sqr_to = from(move)

    p_from = piece(board, sqr_from)
    p_to = undo.captured #piece(board, sqr_to)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    @inbounds board[type(p_from)] ⊻= bb_from ⊻ bb_to
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to
    @inbounds board[sqr_from] = p_to
    @inbounds board[sqr_to] = p_from

    if p_to !== BLANK
        @inbounds board[type(p_to)] ⊻= bb_from
        @inbounds board[!board.turn] ⊻= bb_from
    end
    return
end


function undo_enpass!(board::Board, move::Move, undo::Undo)
    sqr_from = from(move)
    sqr_to = to(move)

    cap_sqr = sqr_to - 24 + (board.turn.val << 4)
    cap_bb = Bitboard(cap_sqr)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    @inbounds board[PAWN] ⊻= bb_from ⊻ bb_to ⊻ cap_bb
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to
    @inbounds board[!board.turn] ⊻= cap_bb

    @inbounds board[sqr_from] = piece(board, sqr_to)
    @inbounds board[sqr_to] = BLANK
    @inbounds board[cap_sqr] = undo.captured
    return
end


function undo_castle!(board::Board, move::Move, undo::Undo)
    k_from = from(move)
    k_to = to(move)

    if flag(move) == __KING_CASTLE
        r_from = k_from - 3
        r_to = k_from - 1
    else
        r_from = k_from + 4
        r_to = k_from + 1
    end

    r_from_bb = Bitboard(r_from)
    r_to_bb = Bitboard(r_to)
    k_from_bb = Bitboard(k_from)
    k_to_bb = Bitboard(k_to)

    @inbounds board[KING] ⊻= k_from_bb ⊻ k_to_bb
    @inbounds board[ROOK] ⊻= r_from_bb ⊻ r_to_bb

    @inbounds board[board.turn] ⊻= k_from_bb ⊻ k_to_bb ⊻ r_from_bb ⊻ r_to_bb

    @inbounds board[k_from] = makepiece(KING, board.turn)
    @inbounds board[r_from] = makepiece(ROOK, board.turn)
    @inbounds board[k_to] = BLANK
    @inbounds board[r_to] = BLANK
    return
end


function undo_promo!(board::Board, move::Move, undo::Undo)
    sqr_from = from(move)
    sqr_to = to(move)

    bb_from = Bitboard(sqr_from)
    bb_to = Bitboard(sqr_to)

    p_to = undo.captured
    ptype_promo = PieceType(flag(move) - 3)

    @inbounds board[PAWN] ⊻= bb_from
    @inbounds board[ptype_promo] ⊻= bb_to
    @inbounds board[board.turn] ⊻= bb_from ⊻ bb_to

    @inbounds board[sqr_from] = makepiece(PAWN, board.turn)
    @inbounds board[sqr_to] = p_to

    if p_to !== BLANK
        @inbounds board[type(p_to)] ⊻= bb_to
        @inbounds board[!board.turn] ⊻= bb_to
    end
    return
end


# "pass" the go, and let out opponent have another move.
function apply_null!(board::Board)
    undo_checkers = board.checkers
    undo_pinned = board.pinned
    undo_castling = board.castling
    undo_enpass = board.enpass
    undo_halfmovecount = board.halfmovecount
    undo_hash = board.hash

    if board.enpass !== zero(UInt8)
        board.hash ⊻= zobepkey(board.enpass)
    end

    # Finishing calculations, for the next turn
    board.hash ⊻= zobturnkey()
    switchturn!(board)

    board.checkers = kingAttackers(board)
    board.pinned = findpins(board)
    board.movecount += one(board.movecount)
    board.history[board.movecount] = board.hash
    return Undo(undo_checkers, undo_pinned, undo_castling, undo_enpass, BLANK, undo_halfmovecount, undo_hash)
end


function undo_null!(board::Board, undo::Undo)
    board.checkers = undo.checkers
    board.pinned = undo.pinned
    board.enpass = undo.enpass
    board.castling = undo.castling
    board.halfmovecount = undo.halfmovecount
    board.movecount -= one(UInt16)
    board.hash = undo.hash
    switchturn!(board)
end
