include("pawnMoves.jl")
include("kingMoves.jl")

# datatype for storing the information about a move
struct Move
    move_from::UInt8
    move_to::UInt8
    promote_to::UInt8
end

# datatype for storing all the possible moves
mutable struct MoveList <: AbstractArray{Move, 1}
    moves::Vector{Move}
    idx::Int
end

MoveList(size::Int) = MoveList(Vector{Move}(undef, size), 0)

# define useful array methods for MoveList
Base.iterate(moveList::MoveList, state = 1) = (state > moveList.idx) ? nothing : (moveList.moves[state], state + 1)
Base.length(moveList::MoveList) = moveList.idx
Base.eltype(::Type{MoveList}) = Move
Base.size(moveList::MoveList) = (moveList.idx, )
Base.IndexStyle(::Type{<:MoveList}) = IndexLinear()
Base.getindex(moveList::MoveList, idx::Int) = moveList.moves[idx]

# add a push function
function push!(moveList::MoveList, move::Move)
    moveList.idx += 1
    moveList.moves[moveList.idx] = move
end

# pseudo-clear the moveList
function clear!(moveList::MoveList)
    moveList.idx = 0
end

# useful bitboard manipulation
function pop_square(bb::UInt64)
    sqr = getSquare(bb)
    bb &= bb - 1
    return sqr, bb
end

# ability to iterate through squares
function Base.iterate(bb::UInt64, state::UInt64 = bb)
    (state == zero(UInt)) ? nothing : pop_square(state)
end

# build moves onto the movelist
function build_moves!(moveList::MoveList, move_BB::UInt64, move_from::Int)
    for move_to in move_BB
        push!(moveList, Move(move_from, move_to, 0))
    end
end

# build pawn moves onto the movelist
function build_pawn_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > zero(UInt)
        move_to, move_BB = pop_square(move_BB)
        push!(moveList, Move(move_to + jump, move_to, 0))
    end
end

# build pawn promotions onto the movelist
function build_promo_moves!(moveList::MoveList, move_BB::UInt64, jump::Int)
    while move_BB > zero(UInt)
        move_to, move_BB = pop_square(move_BB)
        push!(moveList, Move(move_to + jump, move_to, KNIGHT))
        push!(moveList, Move(move_to + jump, move_to, BISHOP))
        push!(moveList, Move(move_to + jump, move_to, ROOK))
        push!(moveList, Move(move_to + jump, move_to, QUEEN))
    end
end

# build king moves onto the movelist
function build_king_moves!(moveList::MoveList, board::Board, targets::UInt64)
    king = getSquare(getOurKing(board))
    build_moves!(moveList, targets & KING_MOVES[king], king)
end

# build knight moves onto the movelist
function build_knight_moves!(moveList::MoveList, board::Board, targets::UInt64)
    for knight in getOurKnights(board)
        build_moves!(moveList, targets & KNIGHT_MOVES[knight], knight)
    end
end

# generate all possible moves
function gen_moves!(moveList::MoveList, board::Board)
    # find all our pieces, may not be needed
    pawns = getOurPawns(board)
    knights = getOurKnights(board)
    bishops = getOurBishops(board)
    rooks = getOurRooks(board)
    queens = getOurQueens(board)
    king = getOurKing(board)

    # find target squares
    enemies = getTheirPieces(board)
    empty = getEmpty(board)

    # dictate direction of pawn movement, could in future add new pawn methods
    if board.turn == WHITE
        oneStep = -8
        twoStep = -16
        left = -9
        right = -7
    else
        oneStep = 8
        twoStep = 16
        left = 9
        right = 7
    end

    pawnOne = pawnAdvance(pawns, empty, board.turn) & ~RANK_18
    pawnTwo = pawnDoubleAdvance(pawns, empty, board.turn)
    pawnLeft = pawnLeftCaptures(pawns, enemies, board.turn)
    pawnRight = pawnRightCaptures(pawns, enemies, board.turn)
    pawnLeftEnpass = pawnLeftCaptures(pawns, board.enpass, board.turn)
    pawnRightEnpass = pawnRightCaptures(pawns, board.enpass, board.turn)
    pawnPromo = pawnAdvance(pawns, empty, board.turn) & RANK_18
    pawnPromoLeft = pawnLeft & RANK_18
    pawnLeft &= ~RANK_18
    pawnPromoRight = pawnRight & RANK_18
    pawnRight &= ~RANK_18
    build_pawn_moves!(moveList, pawnOne, oneStep)
    build_pawn_moves!(moveList, pawnTwo, twoStep)
    build_pawn_moves!(moveList, pawnLeft, left)
    build_pawn_moves!(moveList, pawnRight, right)
    build_pawn_moves!(moveList, pawnLeftEnpass, left)
    build_pawn_moves!(moveList, pawnRightEnpass, right)
    build_promo_moves!(moveList, pawnPromo, oneStep)
    build_promo_moves!(moveList, pawnPromoLeft, left)
    build_promo_moves!(moveList, pawnPromoRight, right)


    build_king_moves!(moveList, board, empty)
    build_king_moves!(moveList, board, enemies)

    build_knight_moves!(moveList, board, empty)
    build_knight_moves!(moveList, board, enemies)
end
