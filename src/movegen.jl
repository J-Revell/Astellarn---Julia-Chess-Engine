struct MoveGenCommon
    friends::Bitboard
    enemies::Bitboard
    empty::Bitboard
    occ::Bitboard
    ourking::Bitboard
    unpinned::Bitboard
end


function MoveGenCommon(board::Board)
    MoveGenCommon(friendly(board), enemy(board), empty(board), occupied(board), friendly(board) & kings(board), ~pinned(board))
end


function build_pawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    if board.turn == WHITE
        build_wpawn_advances!(movestack, board, targets, common)
    else
        build_bpawn_advances!(movestack, board, targets, common)
    end
    return
end


function build_wpawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = (pawns(board) & common.friends) & (common.unpinned | file(common.ourking))

    # Single pawn advances
    dests = (pwns << 8) & common.empty & ~RANK_8
    for dest in dests & targets
        # add a normal move
        push!(movestack, Move(dest - 8, dest))
    end

    # Double pawn advances
    doubledests = (dests << 8) & targets & RANK_4
    for dest in doubledests
        # add a double pawn move
        push!(movestack, Move(dest - 16, dest, __DOUBLE_PAWN))
    end
    return
end


function build_bpawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = (pawns(board) & common.friends) & (common.unpinned | file(common.ourking))

    # Single pawn advances
    dests = (pwns >> 8) & common.empty & ~RANK_1
    for dest in dests & targets
        # add a normal move
        push!(movestack, Move(dest + 8, dest))
    end

    # Double pawn advances
    doubledests = (dests >> 8) & targets & RANK_5
    for dest in doubledests
        # add a double pawn move
        push!(movestack, Move(dest + 16, dest, __DOUBLE_PAWN))
    end
    return
end


function build_free_pawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    if board.turn == WHITE
        build_free_wpawn_captures!(movestack, board, targets, common)
    else
        build_free_bpawn_captures!(movestack, board, targets, common)
    end
    return
end


function build_free_wpawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = pawns(board) & common.friends & common.unpinned

    # "Left" pawn captures

    dests = (pwns << 9) & targets & ~FILE_H
    for dest in (dests & ~RANK_8)
        push!(movestack, Move(dest - 9, dest))
    end
    build_promo_internal!(movestack, dests & RANK_8, 9)


    # "Right" pawn captures

    dests = (pwns << 7) & targets & ~FILE_A
    for dest in (dests & ~RANK_8)
        push!(movestack, Move(dest - 7, dest))
    end
    build_promo_internal!(movestack, dests & RANK_8, 7)
    return
end


function build_free_bpawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = pawns(board) & common.friends & common.unpinned

    # "Left" pawn captures

    dests = (pwns >> 7) & targets & ~FILE_H
    for dest in (dests & ~RANK_1)
        push!(movestack, Move(dest + 7, dest))
    end
    build_promo_internal!(movestack, dests & RANK_1, -7)

    # "Right" pawn captures

    dests = (pwns >> 9) & targets & ~FILE_A
    for dest in (dests & ~RANK_1)
        push!(movestack, Move(dest + 9, dest))
    end
    build_promo_internal!(movestack, dests & RANK_1, -9)
    return
end


function build_enpass_moves!(movestack::MoveStack, board::Board, common::MoveGenCommon)
    ep_sqr = board.enpass
    if ep_sqr !== zero(UInt8)
        king = square(common.ourking)
        for pwn in (pawnAttacks(!board.turn, ep_sqr) & pawns(board) & common.friends)
            occ = common.occ
            occ &= ~Bitboard(pwn) & ~Bitboard(ep_sqr - 24 + (board.turn.val << 4))
            occ |= Bitboard(ep_sqr)
            if isempty(bishopMoves(king, occ) & bishoplike(board) & common.enemies) && isempty(rookMoves(king, occ) & rooklike(board) & common.enemies)
                push!(movestack, Move(pwn, ep_sqr, __ENPASS))
            end
        end
    end
    return
end


function build_pawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    if board.turn == WHITE
        build_wpawn_advance_promos!(movestack, board, targets, common)
    else
        build_bpawn_advance_promos!(movestack, board, targets, common)
    end
    return
end


function build_wpawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = pawns(board) & common.friends & (common.unpinned | file(common.ourking))
    dests = (pwns << 8) & targets & RANK_8
    build_promo_internal!(movestack, dests, 8)
    return
end


function build_bpawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = pawns(board) & common.friends & (common.unpinned | file(common.ourking))
    dests = (pwns >> 8) & targets & RANK_1
    build_promo_internal!(movestack, dests, -8)
    return
end


function build_promo_internal!(movestack::MoveStack, dests::Bitboard, shift::Integer)
    for dest in dests
        _move_uint16 = Move(dest - shift, dest).val
        push!(movestack, Move(_move_uint16 | __KNIGHT_PROMO))
        push!(movestack, Move(_move_uint16 | __BISHOP_PROMO))
        push!(movestack, Move(_move_uint16 | __ROOK_PROMO))
        push!(movestack, Move(_move_uint16 | __QUEEN_PROMO))
    end
    return
end


function build_pinned_pawn_captures_and_promos!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    pwns = pawns(board) & common.friends & pinned(board)
    king = square(common.ourking)
    for pwn in pwns
        for move_to in (pawnAttacks(board.turn, pwn) & common.enemies & targets)
            if !isempty(Bitboard(pwn) & blockers(king, move_to))
                _move_uint16 = Move(pwn, move_to).val
                if !isempty(Bitboard(move_to) & RANK_18)
                    push!(movestack, Move(_move_uint16 | __KNIGHT_PROMO))
                    push!(movestack, Move(_move_uint16 | __BISHOP_PROMO))
                    push!(movestack, Move(_move_uint16 | __ROOK_PROMO))
                    push!(movestack, Move(_move_uint16 | __QUEEN_PROMO))
                else
                    push!(movestack, Move(_move_uint16))
                end
            end
        end
    end
    return
end


function push_normal!(movestack::MoveStack, sqr_from::Integer, dests::Bitboard)
    for dest in dests
        push!(movestack, Move(sqr_from, dest))
    end
    return
end


# internal function to build knight moves
function build_knight_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    for knight in (knights(board) & common.friends & common.unpinned)
        push_normal!(movestack, knight, knightMoves(knight) & targets)
    end
    return
end


# internal functions to build bishop moves
function build_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    build_free_bishop_moves!(movestack, board, targets, common)
    if !isempty(pinned(board))
        build_pinned_bishop_moves!(movestack, board, targets, common)
    end
    return
end


function build_free_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    occ = common.occ
    for bishop in (bishoplike(board) & common.friends & common.unpinned)
        push_normal!(movestack, bishop, bishopMoves(bishop, occ) & targets)
    end
    return
end


function build_pinned_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    king = square(common.ourking)
    occ = common.occ
    for bishop in (bishoplike(board) & common.friends & pinned(board))
        block_1 = blockers(king, bishop)
        for move_to in (bishopMoves(bishop, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(bishop) & blockers(king, move_to))
                push!(movestack, Move(bishop, move_to))
            end
        end
    end
    return
end


# internal functions to build rook moves
function build_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    build_free_rook_moves!(movestack, board, targets, common)
    if !isempty(pinned(board))
        build_pinned_rook_moves!(movestack, board, targets, common)
    end
    return
end


function build_free_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    occ = common.occ
    for rook in (rooklike(board) & common.friends & common.unpinned)
        push_normal!(movestack, rook, rookMoves(rook, occ) & targets)
    end
    return
end


function build_pinned_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    king = square(common.ourking)
    occ = common.occ
    for rook in (rooklike(board) & common.friends & pinned(board))
        block_1 = blockers(king, rook)
        for move_to in (rookMoves(rook, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(rook) & blockers(king, move_to))
                push!(movestack, Move(rook, move_to))
            end
        end
    end
    return
end


# internal function to build king moves
function build_king_moves!(movestack::MoveStack, board::Board, targets::Bitboard, common::MoveGenCommon)
    king = square(common.ourking)
    for move_to in (kingMoves(king) & targets)
        if !isattacked_through_king(board, move_to)
            push!(movestack, Move(king, move_to))
        end
    end
    return
end


function build_castling!(movestack::MoveStack, board::Board, common::MoveGenCommon)
    if cancastlekingside(board)
        build_kingside_castling!(movestack, board, common)
    end
    if cancastlequeenside(board)
        build_queenside_castling!(movestack, board, common)
    end
    return
end


function build_kingside_castling!(movestack::MoveStack, board::Board, common::MoveGenCommon)
    king = square(common.ourking)
    rook = king - 3
    if isempty(common.occ & blockers(king, rook)) && !isattacked(board, king - 1) && !isattacked(board, king - 2)
        push!(movestack, Move(king, king - 2, __KING_CASTLE))
    end
    return
end


function build_queenside_castling!(movestack::MoveStack, board::Board, common::MoveGenCommon)
    king = square(common.ourking)
    rook = king + 4
    if isempty(common.occ & blockers(king, rook)) && !isattacked(board, king + 1) && !isattacked(board, king + 2)
        push!(movestack, Move(king, king + 2, __QUEEN_CASTLE))
    end
    return
end


"""
    gen_quiet_moves!(movestack::MoveStack, board::Board)

Generate all the quiet moves on a `board`, pushing each `Move` to the `MoveStack`.
"""
function gen_quiet_moves!(movestack::MoveStack, board::Board)
    common = MoveGenCommon(board)
    if isdoublecheck(board)
        build_king_moves!(movestack, board, common.empty, common)
        return
    end
    if ischeck(board)
        if isempty(checkers(board) & knights(board))
            targets = blockers(square(common.ourking), square(checkers(board)))
        else
            # if a knight gives check, only *quiet* move is for king to step away
            build_king_moves!(movestack, board, common.empty, common)
            return
        end
    else
        build_castling!(movestack, board, common)
        targets = common.empty
    end
    build_pawn_advances!(movestack, board, targets, common)
    build_king_moves!(movestack, board, common.empty, common)
    build_knight_moves!(movestack, board, targets, common)
    build_bishop_moves!(movestack, board, targets, common)
    build_rook_moves!(movestack, board, targets, common)
    return
end


"""
    gen_noisy_moves!(movestack::MoveStack, board::Board)

Generate all the noisy moves on a `board`, pushing each `Move` to the `MoveStack`.
"""
function gen_noisy_moves!(movestack::MoveStack, board::Board)
    common = MoveGenCommon(board)
    enemies = common.enemies
    if isdoublecheck(board)
        build_king_moves!(movestack, board, enemies, common)
        return
    end
    if ischeck(board)
        targets = checkers(board)
        build_pawn_advance_promos!(movestack, board, blockers(square(common.ourking), square(targets)), common)
    else
        targets = enemies
        build_pawn_advance_promos!(movestack, board, common.empty, common)
    end
    build_free_pawn_captures!(movestack, board, targets, common)
    build_pinned_pawn_captures_and_promos!(movestack, board, targets, common)
    build_enpass_moves!(movestack, board, common)
    build_king_moves!(movestack, board, enemies, common)
    build_knight_moves!(movestack, board, targets, common)
    build_bishop_moves!(movestack, board, targets, common)
    build_rook_moves!(movestack, board, targets, common)
    return
end


"""
    gen_moves!(movestack::Movestack, board::Board)

Generate all the possible moves in the position.
"""
function gen_moves!(movestack::MoveStack, board::Board)
    gen_quiet_moves!(movestack, board)
    gen_noisy_moves!(movestack, board)
    return
end
