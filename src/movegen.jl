function build_pawn_advances!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = (pawns(board) & friendly(board)) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Single pawn advances

    shift = 24 - board.turn.val << 4
    dests = (pwns << shift) & empty(board) & ~RANK_18
    for dest in (dests & targets)
        push!(movestack, Move(dest - shift, dest, __NORMAL_MOVE))
    end

    # Double pawn advances

    doubledests = (dests << shift) & targets & (RANK_3 << (8 * board.turn.val))
    for dest in doubledests
        push!(movestack, Move(dest - 2shift, dest, __DOUBLE_PAWN))
    end
    return
end

function build_free_pawn_captures!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures

    shift_l = 25 - board.turn.val << 4
    dests = (pwns << shift_l) & targets & ~RANK_18 & ~FILE_H
    for dest in dests
        push!(movestack, Move(dest - shift_l, dest, __NORMAL_MOVE))
    end

    # "Right" pawn captures

    shift_r = 23 - board.turn.val << 4
    dests = (pwns << shift_r) & targets & ~RANK_18 & ~FILE_A
    for dest in dests
        push!(movestack, Move(dest - shift_r, dest, __NORMAL_MOVE))
    end
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
end

function build_promo_internal!(movestack::MoveStack, dests::Bitboard, shift::Integer)
    for dest in dests
        push!(movestack, Move(dest - shift, dest, __KNIGHT_PROMO))
        push!(movestack, Move(dest - shift, dest, __BISHOP_PROMO))
        push!(movestack, Move(dest - shift, dest, __ROOK_PROMO))
        push!(movestack, Move(dest - shift, dest, __QUEEN_PROMO))
    end
end

function build_pawn_advance_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Pawn advance promos
    shift = 24 - board.turn.val << 4
    dests = (pwns << shift) & targets & RANK_18
    build_promo_internal!(movestack, dests, shift)
end

function build_free_pawn_capture_promos!(movestack::MoveStack, board::Board, targets::Bitboard)
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures + promotions
    shift = 25 - board.turn.val << 4
    dests = (pwns << shift) & targets & RANK_18 & ~FILE_H
    build_promo_internal!(movestack, dests, shift)

    # "Right" pawn captures + promotions
    shift = 23 - board.turn.val << 4
    dests = (pwns << shift) & targets & RANK_18 & ~FILE_A
    build_promo_internal!(movestack, dests, shift)
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
end

function push_normal!(movestack::MoveStack, sqr_from::Integer, dests::Bitboard)
    for dest in dests
        push!(movestack, Move(sqr_from, dest, __NORMAL_MOVE))
    end
end

# internal function to build knight moves
function build_knight_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    for knight in (knights(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, knight, knightMoves(knight) & targets)
    end
end


# internal functions to build bishop moves
function build_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    build_free_bishop_moves!(movestack, board, targets)
    build_pinned_bishop_moves!(movestack, board, targets)
end

function build_free_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    for bishop in (bishoplike(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, bishop, bishopMoves(bishop, occupied(board)) & targets)
    end
end

function build_pinned_bishop_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    for bishop in (bishoplike(board) & friendly(board) & pinned(board))
        for move_to in (bishopMoves(bishop, occupied(board)) & targets)
            if !isempty(Bitboard(move_to) & blockers(king, bishop)) || !isempty(Bitboard(bishop) & blockers(king, move_to))
                push!(movestack, Move(bishop, move_to, __NORMAL_MOVE))
            end
        end
    end
end


# internal functions to build rook moves
function build_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    build_free_rook_moves!(movestack, board, targets)
    build_pinned_rook_moves!(movestack, board, targets)
end

function build_free_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    for rook in (rooklike(board) & friendly(board) & ~pinned(board))
        push_normal!(movestack, rook, rookMoves(rook, occupied(board)) & targets)
    end
end

function build_pinned_rook_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    for rook in (rooklike(board) & friendly(board) & pinned(board))
        for move_to in (rookMoves(rook, occupied(board)) & targets)
            if !isempty(Bitboard(move_to) & blockers(king, rook)) || !isempty(Bitboard(rook) & blockers(king, move_to))
                push!(movestack, Move(rook, move_to, __NORMAL_MOVE))
            end
        end
    end
end


# internal function to build king moves
function build_king_moves!(movestack::MoveStack, board::Board, targets::Bitboard)
    king = square(kings(board) & friendly(board))
    for move_to in (kingMoves(king) & targets)
        if !isattacked_through_king(board, move_to)
            push!(movestack, Move(king, move_to, __NORMAL_MOVE))
        end
    end
end

function build_castling!(movestack::MoveStack, board::Board)
    if cancastlekingside(board)
        build_kingside_castling!(movestack, board)
    end
    if cancastlequeenside(board)
        build_queenside_castling!(movestack, board)
    end
end

function build_kingside_castling!(movestack::MoveStack, board::Board)
    king = square(kings(board) & friendly(board))
    rook = king - 3
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king - 1) && !isattacked(board, king - 2)
        push!(movestack, Move(king, king - 2, __KING_CASTLE))
    end
end

function build_queenside_castling!(movestack, board)
    king = square(kings(board) & friendly(board))
    rook = king + 4
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king + 1) && !isattacked(board, king + 2)
        push!(movestack, Move(king, king + 2, __QUEEN_CASTLE))
    end
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
        targets = blockers(square(kings(board) & friendly(board)), square(checkers(board)))
    else
        build_castling!(movestack, board)
        targets = empty_bb
    end
    build_pawn_advances!(movestack, board, targets)
    build_king_moves!(movestack, board, empty_bb)
    build_knight_moves!(movestack, board, targets)
    build_bishop_moves!(movestack, board, targets)
    build_rook_moves!(movestack, board, targets)
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
    build_free_pawn_capture_promos!(movestack, board, targets)
    build_pinned_pawn_captures_and_promos!(movestack, board, targets)
    build_enpass_moves!(movestack, board)
    build_king_moves!(movestack, board, enemies)
    build_knight_moves!(movestack, board, targets)
    build_bishop_moves!(movestack, board, targets)
    build_rook_moves!(movestack, board, targets)
end


"""
    gen_moves!(movestack::Movestack, board::Board)

Generate all the possible moves in the position.
"""
function gen_moves!(movestack::MoveStack, board::Board)
    gen_quiet_moves!(movestack, board)
    gen_noisy_moves!(movestack, board)
end
