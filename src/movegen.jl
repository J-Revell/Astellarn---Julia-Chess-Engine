function build_pawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard)
    if board.turn == WHITE
        build_wpawn_advances!(movestack, board, targets)
    else
        build_bpawn_advances!(movestack, board, targets)
    end
    return
end

function build_wpawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = (pawns(board) & friendly(board)) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Single pawn advances
    dests = (pwns << 8) & empty(board) & ~RANK_8
    for dest in (dests & targets)
        push!(movestack, Move(dest - 8, dest, __NORMAL_MOVE))
    end

    # Double pawn advances
    doubledests = (dests << 8) & targets & RANK_4
    for dest in doubledests
        push!(movestack, Move(dest - 16, dest, __DOUBLE_PAWN))
    end
    return
end

function build_bpawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = (pawns(board) & friendly(board)) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Single pawn advances
    dests = (pwns >> 8) & empty(board) & ~RANK_1
    for dest in (dests & targets)
        push!(movestack, Move(dest + 8, dest, __NORMAL_MOVE))
    end

    # Double pawn advances
    doubledests = (dests >> 8) & targets & RANK_5
    for dest in doubledests
        push!(movestack, Move(dest + 16, dest, __DOUBLE_PAWN))
    end
    return
end


function build_free_pawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard)
    if board.turn == WHITE
        build_free_wpawn_captures!(movestack, board, targets)
    else
        build_free_bpawn_captures!(movestack, board, targets)
    end
    return
end

function build_free_wpawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures

    dests = (pwns << 9) & targets & ~FILE_H
    for dest in (dests & ~RANK_8)
        push!(movestack, Move(dest - 9, dest, __NORMAL_MOVE))
    end
    build_promo_internal!(movestack, dests & RANK_8, 9)


    # "Right" pawn captures

    dests = (pwns << 7) & targets & ~FILE_A
    for dest in (dests & ~RANK_8)
        push!(movestack, Move(dest - 7, dest, __NORMAL_MOVE))
    end
    build_promo_internal!(movestack, dests & RANK_8, 7)
    return
end

function build_free_bpawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures

    dests = (pwns >> 7) & targets & ~FILE_H
    for dest in (dests & ~RANK_1)
        push!(movestack, Move(dest + 7, dest, __NORMAL_MOVE))
    end
    build_promo_internal!(movestack, dests & RANK_1, -7)

    # "Right" pawn captures

    dests = (pwns >> 9) & targets & ~FILE_A
    for dest in (dests & ~RANK_1)
        push!(movestack, Move(dest + 9, dest, __NORMAL_MOVE))
    end
    build_promo_internal!(movestack, dests & RANK_1, -9)
    return
end


function build_enpass_moves!(movestack::MoveStack, board::Board)
    ep_sqr = board.enpass
    if ep_sqr !== zero(UInt8)
        king = square(kings(board) & friendly(board))
        for pwn in (pawnAttacks(!board.turn, ep_sqr) & pawns(board) & friendly(board))
            occ = occupied(board)
            occ &= ~Bitboard(pwn) & ~Bitboard(ep_sqr - 24 + (board.turn.val << 4))
            occ |= Bitboard(ep_sqr)
            if isempty(bishopMoves(king, occ) & bishoplike(board) & enemy(board)) && isempty(rookMoves(king, occ) & rooklike(board) & enemy(board))
                push!(movestack, Move(pwn, ep_sqr, __ENPASS))
            end
        end
    end
    return
end


function build_pawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    if board.turn == WHITE
        build_wpawn_advance_promos!(movestack, board, targets)
    else
        build_bpawn_advance_promos!(movestack, board, targets)
    end
    return
end

function build_wpawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & (~pinned(board) | file(kings(board) & friendly(board)))
    dests = (pwns << 8) & targets & RANK_8
    build_promo_internal!(movestack, dests, 8)
    return
end

function build_bpawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & (~pinned(board) | file(kings(board) & friendly(board)))
    dests = (pwns >> 8) & targets & RANK_1
    build_promo_internal!(movestack, dests, -8)
    return
end

function build_promo_internal!(movestack::MoveStack, dests::Bitboard, shift::Integer)
    for dest in dests
        push!(movestack, Move(dest - shift, dest, __KNIGHT_PROMO))
        push!(movestack, Move(dest - shift, dest, __BISHOP_PROMO))
        push!(movestack, Move(dest - shift, dest, __ROOK_PROMO))
        push!(movestack, Move(dest - shift, dest, __QUEEN_PROMO))
    end
    return
end


function build_pinned_pawn_captures_and_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & pinned(board)
    king = square(kings(board) & friendly(board))
    for pwn in pwns
        for move_to in (pawnAttacks(board.turn, pwn) & enemy(board) & targets)
            if !isempty(Bitboard(pwn) & blockers(king, move_to))
                if !isempty(Bitboard(move_to) & RANK_18)
                    push!(movestack, Move(pwn, move_to, __KNIGHT_PROMO))
                    push!(movestack, Move(pwn, move_to, __BISHOP_PROMO))
                    push!(movestack, Move(pwn, move_to, __ROOK_PROMO))
                    push!(movestack, Move(pwn, move_to, __QUEEN_PROMO))
                else
                    push!(movestack, Move(pwn, move_to, __NORMAL_MOVE))
                end
            end
        end
    end
    return
end

function push_normal!(movestack::MoveStack, sqr_from::Integer, dests::Bitboard)
    for dest in dests
        push!(movestack, Move(sqr_from, dest, __NORMAL_MOVE))
    end
    return
end

# internal function to build knight moves
function build_knight_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    for knight in (knights(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, knight, knightMoves(knight) & targets)
    end
    return
end


# internal functions to build bishop moves
function build_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    build_free_bishop_moves!(movestack, board, targets)
    build_pinned_bishop_moves!(movestack, board, targets)
    return
end

function build_free_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    occ = occupied(board)
    for bishop in (bishoplike(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, bishop, bishopMoves(bishop, occ) & targets)
    end
    return
end

function build_pinned_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    occ = occupied(board)
    for bishop in (bishoplike(board) & friendly(board) & pinned(board))
        block_1 = blockers(king, bishop)
        for move_to in (bishopMoves(bishop, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(bishop) & blockers(king, move_to))
                push!(movestack, Move(bishop, move_to, __NORMAL_MOVE))
            end
        end
    end
    return
end


# internal functions to build rook moves
function build_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    build_free_rook_moves!(movestack, board, targets)
    build_pinned_rook_moves!(movestack, board, targets)
    return
end

function build_free_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    occ = occupied(board)
    for rook in (rooklike(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, rook, rookMoves(rook, occ) & targets)
    end
    return
end

function build_pinned_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    occ = occupied(board)
    for rook in (rooklike(board) & friendly(board) & pinned(board))
        block_1 = blockers(king, rook)
        for move_to in (rookMoves(rook, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(rook) & blockers(king, move_to))
                push!(movestack, Move(rook, move_to, __NORMAL_MOVE))
            end
        end
    end
    return
end


# internal function to build king moves
function build_king_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    for move_to in (kingMoves(king) & targets)
        if !isattacked_through_king(board, move_to)
            push!(movestack, Move(king, move_to, __NORMAL_MOVE))
        end
    end
    return
end

function build_castling!(movestack::MoveStack, board::Board)
    if cancastlekingside(board)
        build_kingside_castling!(movestack, board)
    end
    if cancastlequeenside(board)
        build_queenside_castling!(movestack, board)
    end
    return
end

function build_kingside_castling!(movestack::MoveStack, board::Board)
    king = square(kings(board) & friendly(board))
    rook = king - 3
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king - 1) && !isattacked(board, king - 2)
        push!(movestack, Move(king, king - 2, __KING_CASTLE))
    end
    return
end

function build_queenside_castling!(movestack, board)
    king = square(kings(board) & friendly(board))
    rook = king + 4
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king + 1) && !isattacked(board, king + 2)
        push!(movestack, Move(king, king + 2, __QUEEN_CASTLE))
    end
    return
end


"""
    gen_quiet_moves!(movestack::MoveStack, board::Board)

Generate all the quiet moves on a `board`, pushing each `Move` to the `MoveStack`.
"""
function gen_quiet_moves!(movestack::MoveStack, board::Board)
    empty_bb = empty(board)
    if isdoublecheck(board)
        build_king_moves!(movestack, board, empty_bb)
        return
    end
    if ischeck(board)
        if isempty(checkers(board) & knights(board))
            targets = blockers(square(kings(board) & friendly(board)), square(checkers(board)))
        else
            # if a knight gives check, only *quiet* move is for king to step away
            build_king_moves!(movestack, board, empty_bb)
            return
        end
    else
        build_castling!(movestack, board)
        targets = empty_bb
    end
    build_pawn_advances!(movestack, board, targets)
    build_king_moves!(movestack, board, empty_bb)
    build_knight_moves!(movestack, board, targets)
    build_bishop_moves!(movestack, board, targets)
    build_rook_moves!(movestack, board, targets)
    return
end


"""
    gen_noisy_moves!(movestack::MoveStack, board::Board)

Generate all the noisy moves on a `board`, pushing each `Move` to the `MoveStack`.
"""
function gen_noisy_moves!(movestack::MoveStack, board::Board)
    enemies = enemy(board)
    if isdoublecheck(board)
        build_king_moves!(movestack, board, enemies)
        return
    end
    if ischeck(board)
        targets = checkers(board)
        build_pawn_advance_promos!(movestack, board, blockers(square(kings(board) & friendly(board)), square(targets)))
    else
        targets = enemies
        build_pawn_advance_promos!(movestack, board, empty(board))
    end
    build_free_pawn_captures!(movestack, board, targets)
    build_pinned_pawn_captures_and_promos!(movestack, board, targets)
    build_enpass_moves!(movestack, board)
    build_king_moves!(movestack, board, enemies)
    build_knight_moves!(movestack, board, targets)
    build_bishop_moves!(movestack, board, targets)
    build_rook_moves!(movestack, board, targets)
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
