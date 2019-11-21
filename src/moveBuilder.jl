# datatype for storing the information about a move
struct Move
    move_from::UInt8
    move_to::UInt8
    move_flag::UInt8
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

# add a push function. The MoveList object is preallocated for performance.
function push!(moveList::MoveList, move::Move)
    moveList.idx += 1
    @inbounds moveList.moves[moveList.idx] = move
end

function popfirst!(moveList::MoveList)
    moveList.idx -= 1
    popfirst!(moveList.moves)
end

function splice!(moveList::MoveList, idx::Int)
    moveList.idx -= 1
    splice!(moveList.moves, idx)
end

# pseudo-clear the moveList.
function clear!(moveList::MoveList)
    moveList.idx = 0
end

# useful bitboard manipulation
function pop_square(sqr_bb::UInt64)
    sqr = getSquare(sqr_bb)
    sqr_bb &= sqr_bb - 1
    return sqr, sqr_bb
end

# ability to iterate through squares
function Base.iterate(sqr_bb::UInt64, state::UInt64 = sqr_bb)
    (state == zero(UInt)) ? nothing : pop_square(state)
end

# build moves onto the movelist
function build_moves!(moveList::MoveList, move_bb::UInt64, move_from::Int)
    for move_to in move_bb
        push!(moveList, Move(move_from, move_to, NONE))
    end
end

# build pawn moves onto the movelist
function build_pawn_moves!(moveList::MoveList, move_bb::UInt64, jump::Int)
    for move_to in move_bb
        push!(moveList, Move(move_to + jump, move_to, NONE))
    end
end

function build_enpass_moves!(moveList::MoveList, move_bb::UInt64, jump::Int)
    for move_to in move_bb
        push!(moveList, Move(move_to + jump, move_to, ENPASS))
    end
end

# build pawn promotions onto the movelist
function build_promo_moves!(moveList::MoveList, move_bb::UInt64, jump::Int)
    for move_to in move_bb
        push!(moveList, Move(move_to + jump, move_to, KNIGHT))
        push!(moveList, Move(move_to + jump, move_to, BISHOP))
        push!(moveList, Move(move_to + jump, move_to, ROOK))
        push!(moveList, Move(move_to + jump, move_to, QUEEN))
    end
end

# build king moves onto the movelist
function build_king_moves!(moveList::MoveList, board::Board, targets::UInt64)
    king = getSquare(getOurKing(board))
    @inbounds build_moves!(moveList, targets & KING_MOVES[king], king)
end

# build castling moves onto the movelist
function build_castling!(moveList::MoveList, board::Board, occupied::UInt64)
    king = getSquare(getOurKing(board))

    # kingside castling
    if canCastleKingside(board, board.turn)
        if (occupied & ((board.turn == WHITE) ? (CASTLE_OO_MASK_W) : (CASTLE_OO_MASK_B))) == zero(UInt)
            if !isSquareAttacked(board, king - 1) && !isSquareAttacked(board, king - 2)
                push!(moveList, Move(king, king - 2, CASTLE))
            end
        end
    end

    # queenside castling
    if canCastleQueenside(board::Board, board.turn)
        if (occupied & ((board.turn == WHITE) ? (CASTLE_OOO_MASK_W) : (CASTLE_OOO_MASK_B))) == zero(UInt)
            if !isSquareAttacked(board, king + 1) && !isSquareAttacked(board, king + 2)
                push!(moveList, Move(king, king + 2, CASTLE))
            end
        end
    end
    return
end

# build knight moves onto the movelist
function build_knight_moves!(moveList::MoveList, board::Board, targets::UInt64)
    for knight in getOurKnights(board)
        @inbounds build_moves!(moveList, targets & KNIGHT_MOVES[knight], knight)
    end
end

# function to build bishop moves onto the movelist
function build_bishop_moves!(moveList::MoveList, board::Board, targets::UInt64, occupied::UInt64)
    for bishop in (getOurBishops(board) | getOurQueens(board))
        @inbounds build_moves!(moveList, targets & bishopMoves(bishop, occupied), bishop)
    end
end

# function to add the rook moves onto the movelist
function build_rook_moves!(moveList::MoveList, board::Board, targets::UInt64, occupied::UInt64)
    for rook in (getOurRooks(board) | getOurQueens(board))
        @inbounds build_moves!(moveList, targets & rookMoves(rook, occupied), rook)
    end
end

# function to add the queen moves
function build_queen_moves!(moveList::MoveList, board::Board, targets::UInt64, occupied::UInt64)
    for queen in getOurQueens(board)
        @inbounds build_moves!(moveList, targets & queenMoves(queen, occupied), queen)
    end
end

# generate all possible moves in one go
function gen_all_moves!(moveList::MoveList, board::Board)
    # find all our pieces, may not be needed
    pawns = getOurPawns(board)
    king = getOurKing(board)

    # find target squares
    enemies = getTheirPieces(board)
    empty = getEmpty(board)
    enpass = getBitboard(Int(board.enpass))

    # find the occupied squares
    occupied = getOccupied(board)

    # squares attacking the king, if any
    kingAttacks = board.checkers#kingAttackers(board)

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

    # are we in double check?
    # if so we can only ever move the king: either to an empty square, or capture.
    if count_ones(kingAttacks) > 1
        build_king_moves!(moveList, board, empty)
        build_king_moves!(moveList, board, enemies)
        return
    end

    if count_ones(kingAttacks) == 1
        # if we are in check from a single attacker, we can only target the attacker,
        # move the king, or block the attack
        targets = kingAttacks | BLOCKERMASKS[getSquare(king), getSquare(kingAttacks)]
    else
        # not in check, so we can build castling moves
        build_castling!(moveList, board, occupied)
        # and we can move to any enemy or empty square
        targets = enemies | empty
    end

    # first, we generate all the pawn target squares
    pawnOne = pawnSingleAdvance(pawns, empty, board.turn)
    pawnTwo = pawnDoubleAdvance(pawns, empty, board.turn)
    pawnLeft = pawnLeftCaptures(pawns, enemies, board.turn)
    pawnRight = pawnRightCaptures(pawns, enemies, board.turn)
    pawnLeftEnpass = pawnLeftCaptures(pawns, enpass, board.turn)
    pawnRightEnpass = pawnRightCaptures(pawns, enpass, board.turn)
    pawnPromo = pawnOne & RANK_18
    pawnOne &= ~RANK_18
    pawnPromoLeft = pawnLeft & RANK_18
    pawnLeft &= ~RANK_18
    pawnPromoRight = pawnRight & RANK_18
    pawnRight &= ~RANK_18

    # next, we add all the possible pawn moves onto the movelist
    build_pawn_moves!(moveList, pawnOne & targets, oneStep)
    build_pawn_moves!(moveList, pawnTwo & targets, twoStep)
    build_pawn_moves!(moveList, pawnLeft & targets, left)
    build_pawn_moves!(moveList, pawnRight & targets, right)
    build_enpass_moves!(moveList, pawnLeftEnpass & targets, left)
    build_enpass_moves!(moveList, pawnRightEnpass & targets, right)
    build_promo_moves!(moveList, pawnPromo & targets, oneStep)
    build_promo_moves!(moveList, pawnPromoLeft & targets, left)
    build_promo_moves!(moveList, pawnPromoRight & targets, right)

    # king moves, no check-threats built yet, no castling implemented yet,
    build_king_moves!(moveList, board, empty)
    build_king_moves!(moveList, board, enemies)

    # build the knights moves
    build_knight_moves!(moveList, board, targets)

    # generate the bishop moves using magic bitboards
    build_bishop_moves!(moveList, board, targets, occupied)

    # generate the rook moves using magic bitboards
    build_rook_moves!(moveList, board, targets, occupied)

    # build the queen moves
    #build_queen_moves!(moveList, board, targets, occupied)
    return
end

# generate captures + promos
function gen_noisy_moves!(moveList::MoveList, board::Board)
    pawns = getOurPawns(board)
    king = getOurKing(board)
    enemies = getTheirPieces(board)
    empty = getEmpty(board)
    enpass = getBitboard(Int(board.enpass))
    occupied = getOccupied(board)
    kingAttacks = board.checkers
    if board.turn == WHITE
        oneStep = -8
        left = -9
        right = -7
    else
        oneStep = 8
        left = 9
        right = 7
    end
    if count_ones(kingAttacks) > 1
        build_king_moves!(moveList, board, enemies)
        return
    end
    if count_ones(kingAttacks) == 1
        targets = kingAttacks
    else
        targets = enemies
    end
    pawnOne = pawnSingleAdvance(pawns, empty, board.turn)
    pawnLeft = pawnLeftCaptures(pawns, enemies, board.turn)
    pawnRight = pawnRightCaptures(pawns, enemies, board.turn)
    pawnLeftEnpass = pawnLeftCaptures(pawns, enpass, board.turn)
    pawnRightEnpass = pawnRightCaptures(pawns, enpass, board.turn)
    pawnPromo = pawnOne & RANK_18
    pawnPromoLeft = pawnLeft & RANK_18
    pawnLeft &= ~RANK_18
    pawnPromoRight = pawnRight & RANK_18
    pawnRight &= ~RANK_18
    build_pawn_moves!(moveList, pawnLeft & targets, left)
    build_pawn_moves!(moveList, pawnRight & targets, right)
    build_enpass_moves!(moveList, pawnLeftEnpass & targets, left)
    build_enpass_moves!(moveList, pawnRightEnpass & targets, right)
    build_promo_moves!(moveList, pawnPromo & empty, oneStep)
    build_promo_moves!(moveList, pawnPromoLeft & targets, left)
    build_promo_moves!(moveList, pawnPromoRight & targets, right)
    build_king_moves!(moveList, board, enemies)
    build_knight_moves!(moveList, board, targets)
    build_bishop_moves!(moveList, board, targets, occupied)
    build_rook_moves!(moveList, board, targets, occupied)
    return
end

# generate non captures
function gen_quiet_moves!(moveList::MoveList, board::Board)
    pawns = getOurPawns(board)
    king = getOurKing(board)
    enemies = getTheirPieces(board)
    empty = getEmpty(board)
    enpass = getBitboard(Int(board.enpass))
    occupied = getOccupied(board)
    kingAttacks = board.checkers
    if board.turn == WHITE
        oneStep = -8
        twoStep = -16
    else
        oneStep = 8
        twoStep = 16
    end
    if count_ones(kingAttacks) > 1
        build_king_moves!(moveList, board, empty)
        return
    end
    if count_ones(kingAttacks) == 1
        targets = BLOCKERMASKS[getSquare(king), getSquare(kingAttacks)]
    else
        build_castling!(moveList, board, occupied)
        targets = empty
    end
    pawnOne = pawnSingleAdvance(pawns, empty, board.turn)
    pawnTwo = pawnDoubleAdvance(pawns, empty, board.turn)
    pawnOne &= ~RANK_18
    build_pawn_moves!(moveList, pawnOne & targets, oneStep)
    build_pawn_moves!(moveList, pawnTwo & targets, twoStep)
    build_king_moves!(moveList, board, empty)
    build_knight_moves!(moveList, board, targets)
    build_bishop_moves!(moveList, board, targets, occupied)
    build_rook_moves!(moveList, board, targets, occupied)
    return
end

function gen_moves!(moveList::MoveList, board::Board)
    gen_noisy_moves!(moveList, board)
    gen_quiet_moves!(moveList, board)
    return
end

function gen_moves(board::Board)
    moveList = MoveList(150)
    gen_moves!(moveList, board)
    return moveList
end
