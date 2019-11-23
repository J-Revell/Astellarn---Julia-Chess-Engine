mutable struct Undo
    checkers::UInt64
    enpass::UInt8
    castling::UInt8
    piece_captured::UInt8
end
Undo() = Undo(zero(UInt64), zero(UInt8), zero(UInt8), zero(UInt8))

mutable struct UndoStack <: AbstractArray{Move, 1}
    undos::Vector{Undo}
    idx::Int
end

UndoStack(size::Int) = UndoStack(Vector{Undo}(undef, size), 0)

# add a push function. The MoveList object is preallocated for performance.
function push!(undostack::UndoStack, undo::Undo)
    undostack.idx += 1
    @inbounds undostack.undos[undostack.idx] = undo
end

function popfirst!(undostack::UndoStack)
    undostack.idx -= 1
    popfirst!(undostack.undos)
end

function splice!(undostack::UndoStack, idx::Int)
    res = splice!(undostack.undos, idx)
    undostack.idx -= 1
    res
end

# pseudo-clear the moveList.
function clear!(undostack::UndoStack)
    undostack.idx = 0
end

# define useful array methods for MoveList
Base.iterate(undostack::UndoStack, state = 1) = (state > undostack.idx) ? nothing : (undostack.undos[state], state + 1)
Base.length(undostack::UndoStack) = undostack.idx
Base.eltype(::Type{UndoStack}) = Undo
Base.size(undostack::UndoStack) = (undostack.idx, )
Base.IndexStyle(::Type{<:UndoStack}) = IndexLinear()
Base.getindex(undostack::UndoStack, idx::Int) = undostack.undos[idx]


function move!(board::Board, move::Move, undo::Undo)
    makemove!(board, move, undo)
    if !isLegal(board)
        undomove!(board, move, undo)
        return false
    end
    return true
end

function gen_legal_moves!(moveList::MoveList, board::Board)
    gen_moves!(moveList, board)
    for (idx, candidate) in enumerate(moveList)
        undo = Undo()
        legal = move!(board, candidate, undo)
        if legal
            undomove!(board, candidate, undo)
        else
            deleteat!(moveList, idx)
        end
    end
    return
end

# assert that a move is legal
function move_legal!(board::Board, move::Move, undo::Undo)
    makemove!(board, move, undo)
    return true
end

# implement a new undo format
function makemove!(board::Board, move::Move, undo::Undo)
    undo.checkers = board.checkers
    undo.enpass = board.enpass
    undo.castling = board.castling

    if move.move_flag == NONE
        makemove_normal!(board, move, undo)
    elseif move.move_flag == ENPASS
        makemove_enpass!(board, move, undo)
    elseif move.move_flag == CASTLE
        makemove_castle!(board, move, undo)
    else
        makemove_promo!(board, move, undo)
    end

    switchTurn!(board)
    board.checkers = checkers(board)
    board.movecount += one(UInt16)
    return
end

# generate non special moves
function makemove_normal!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    piece_from = getPiece(board, sqr_from)
    piece_to = getPiece(board, sqr_to)

    pieceType_from = getPieceType(piece_from)

    pieceType_to = getPieceType(piece_to)
    color_to = getPieceColor(piece_to)

    @inbounds board.pieces[pieceType_from] ⊻= sqr_from_bb ⊻ sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.squares[sqr_from] = NONE
    @inbounds board.squares[sqr_to] = piece_from
    undo.piece_captured = piece_to

    if piece_to !== NONE
        @inbounds board.pieces[pieceType_to] ⊻= sqr_to_bb
        @inbounds board.colors[color_to] ⊻= sqr_to_bb
    end

    # check for double pawn advance, and set enpass square
    if (pieceType_from == PAWN) && (abs(sqr_from-sqr_to) > 10)
        board.enpass = UInt8(getSquare(BLOCKERMASKS[sqr_from, sqr_to]))
    else
        board.enpass = zero(UInt8)
    end

    # rook moves, remove castle rights
    if pieceType_from == ROOK
        (sqr_from == 1) && (board.castling &= ~0x01)
        (sqr_from == 8) && (board.castling &= ~0x02)
        (sqr_from == 57) && (board.castling &= ~0x04)
        (sqr_from == 64) && (board.castling &= ~0x08)
    end

    # king moves, remove castle rights
    if pieceType_from == KING
        (sqr_from == 60) && (board.castling &= ~0x04 & ~0x08)
        (sqr_from == 4) && (board.castling &= ~0x01 & ~0x02)
    end

    # rook square moved to (captured)? remove rights
    if pieceType_to == ROOK
        (sqr_to == 1) && (board.castling &= ~0x01)
        (sqr_to == 8) && (board.castling &= ~0x02)
        (sqr_to == 57) && (board.castling &= ~0x04)
        (sqr_to == 64) && (board.castling &= ~0x08)
    end
    return
end

function makemove_enpass!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    cap_sqr = getBitboard(sqr_to - 24 + (board.turn << 4))

    piece_from = makePiece(PAWN, board.turn)

    if board.turn == WHITE
        undo.piece_captured = makePiece(PAWN, BLACK)
        color_to = BLACK
    else
        undo.piece_captured = makePiece(PAWN, WHITE)
        color_to = WHITE
    end

    @inbounds board.pieces[PAWN] ⊻= sqr_from_bb ⊻ sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.pieces[PAWN] ⊻= cap_sqr
    @inbounds board.colors[color_to] ⊻= cap_sqr

    @inbounds board.squares[sqr_from] = NONE
    @inbounds board.squares[sqr_to] = piece_from
    @inbounds board.squares[sqr_to - 24 + (board.turn << 4)] = NONE

    board.enpass = zero(UInt8)
    return
end

function makemove_castle!(board::Board, move::Move, undo::Undo)
    king_from = Int(move.move_from)
    king_to = Int(move.move_to)

    king_from_bb = getBitboard(king_from)
    king_to_bb = getBitboard(king_to)

    if king_to == 2
        rook_from = 1
        rook_to = 3
        board.castling &= ~0x01 & ~0x02
    elseif king_to == 6
        rook_from = 8
        rook_to = 5
        board.castling &= ~0x01 & ~0x02
    elseif king_to == 58
        rook_from = 57
        rook_to = 59
        board.castling &= ~0x04 & ~0x08
    elseif king_to == 62
        rook_from = 64
        rook_to = 61
        board.castling &= ~0x04 & ~0x08
    end
    rook_from_bb = getBitboard(rook_from)
    rook_to_bb = getBitboard(rook_to)

    @inbounds board.pieces[KING] ⊻= king_from_bb ⊻ king_to_bb
    @inbounds board.pieces[ROOK] ⊻= rook_from_bb ⊻ rook_to_bb

    @inbounds board.colors[board.turn] ⊻= king_from_bb ⊻ king_to_bb
    @inbounds board.colors[board.turn] ⊻= rook_from_bb ⊻ rook_to_bb

    @inbounds board.squares[king_from] = NONE
    @inbounds board.squares[rook_from] = NONE
    @inbounds board.squares[king_to] = makePiece(KING, board.turn)
    @inbounds board.squares[rook_to] = makePiece(ROOK, board.turn)

    board.enpass = zero(UInt8)
    return
end

function makemove_promo!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    #piece_from = getPiece(board, sqr_from)
    piece_to = getPiece(board, sqr_to)

    pieceType_from = PAWN
    pieceType_to = getPieceType(piece_to)
    color_to = getPieceColor(piece_to)

    pieceType_promo = move.move_flag

    @inbounds board.pieces[pieceType_from] ⊻= sqr_from_bb
    @inbounds board.pieces[pieceType_promo] ⊻= sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.squares[sqr_from] = NONE
    @inbounds board.squares[sqr_to] = makePiece(pieceType_promo, board.turn)

    if piece_to !== NONE
        @inbounds board.pieces[pieceType_to] ⊻= sqr_to_bb
        @inbounds board.colors[color_to] ⊻= sqr_to_bb
    end

    undo.piece_captured = piece_to
    board.enpass = zero(UInt8)

    # rook square moved to (captured)? remove rights
    (sqr_to == 1) && (board.castling &= ~0x01)
    (sqr_to == 8) && (board.castling &= ~0x02)
    (sqr_to == 57) && (board.castling &= ~0x04)
    (sqr_to == 64) && (board.castling &= ~0x08)
    return
end


function undomove!(board::Board, move::Move, undo::Undo)
    board.checkers = undo.checkers
    board.enpass = undo.enpass
    board.castling = undo.castling
    board.movecount -= one(UInt16)
    switchTurn!(board)
    if move.move_flag == NONE
        undomove_normal!(board, move, undo)
    elseif move.move_flag == ENPASS
        undomove_enpass!(board, move, undo)
    elseif move.move_flag == CASTLE
        undomove_castle!(board, move, undo)
    else
        undomove_promo!(board, move, undo)
    end
    return
end

function undomove_normal!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)
    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    piece_from = getPiece(board, sqr_to)
    piece_to = undo.piece_captured
    pieceType_from = getPieceType(piece_from)
    pieceType_to = getPieceType(piece_to)

    color_to = getPieceColor(piece_to)

    @inbounds board.pieces[pieceType_from] ⊻= sqr_from_bb ⊻ sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.squares[sqr_from] = piece_from
    @inbounds board.squares[sqr_to] = piece_to

    if piece_to !== NONE
        @inbounds board.pieces[pieceType_to] ⊻= sqr_to_bb
        @inbounds board.colors[color_to] ⊻= sqr_to_bb
    end
end

function undomove_enpass!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)
    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    cap_sqr = getBitboard(sqr_to - 24 + (board.turn << 4))

    piece_from = getPiece(board, sqr_to)
    piece_captured = undo.piece_captured

    color_to = getPieceColor(piece_captured)

    @inbounds board.pieces[PAWN] ⊻= sqr_from_bb ⊻ sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.squares[sqr_from] = piece_from
    @inbounds board.squares[sqr_to] = NONE
    @inbounds board.squares[sqr_to - 24 + (board.turn << 4)] = piece_captured

    @inbounds board.pieces[PAWN] ⊻= cap_sqr
    @inbounds board.colors[color_to] ⊻= cap_sqr
end

function undomove_castle!(board::Board, move::Move, undo::Undo)
    king_from = Int(move.move_from)
    king_to = Int(move.move_to)

    king_from_bb = getBitboard(king_from)
    king_to_bb = getBitboard(king_to)

    if king_to == 2
        rook_from = 1
        rook_to = 3
    elseif king_to == 6
        rook_from = 8
        rook_to = 5
    elseif king_to == 58
        rook_from = 57
        rook_to = 59
    elseif king_to == 62
        rook_from = 64
        rook_to = 61
    end
    rook_from_bb = getBitboard(rook_from)
    rook_to_bb = getBitboard(rook_to)

    @inbounds board.pieces[KING] ⊻= king_from_bb ⊻ king_to_bb
    @inbounds board.pieces[ROOK] ⊻= rook_from_bb ⊻ rook_to_bb

    @inbounds board.colors[board.turn] ⊻= king_from_bb ⊻ king_to_bb
    @inbounds board.colors[board.turn] ⊻= rook_from_bb ⊻ rook_to_bb

    @inbounds board.squares[king_from] = makePiece(KING, board.turn)
    @inbounds board.squares[rook_from] = makePiece(ROOK, board.turn)
    @inbounds board.squares[king_to] = NONE
    @inbounds board.squares[rook_to] = NONE
end

function undomove_promo!(board::Board, move::Move, undo::Undo)
    sqr_from = Int(move.move_from)
    sqr_to = Int(move.move_to)

    sqr_from_bb = getBitboard(sqr_from)
    sqr_to_bb = getBitboard(sqr_to)

    piece_to = undo.piece_captured

    pieceType_to = getPieceType(piece_to)
    color_to = getPieceColor(piece_to)

    @inbounds board.pieces[PAWN] ⊻= sqr_from_bb
    @inbounds board.pieces[move.move_flag] ⊻= sqr_to_bb
    @inbounds board.colors[board.turn] ⊻= sqr_from_bb ⊻ sqr_to_bb

    @inbounds board.squares[sqr_from] = makePiece(PAWN, board.turn)
    @inbounds board.squares[sqr_to] = piece_to

    if piece_to !== NONE
        @inbounds board.pieces[pieceType_to] ⊻= sqr_to_bb
        @inbounds board.colors[color_to] ⊻= sqr_to_bb
    end
end
