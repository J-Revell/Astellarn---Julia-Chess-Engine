function count_pawn_advances(board::Board, targets::Bitboard)
    n = 0
    if board.turn == WHITE
        n += count_wpawn_advances(board, targets)
    else
        n += count_bpawn_advances(board, targets)
    end
    return n
end


function count_wpawn_advances(board::Board, targets::Bitboard)
    n = 0
    pwns = (pawns(board) & friendly(board)) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Single pawn advances
    dests = (pwns << 8) & empty(board) & ~RANK_8
    n += count(dests & targets)

    # Double pawn advances
    doubledests = (dests << 8) & targets & RANK_4
    n += count(doubledests)
    return n
end


function count_bpawn_advances(board::Board, targets::Bitboard)
    n = 0
    pwns = (pawns(board) & friendly(board)) & (~pinned(board) | file(kings(board) & friendly(board)))

    # Single pawn advances
    dests = (pwns >> 8) & empty(board) & ~RANK_1
    n += count(dests & targets)

    # Double pawn advances
    doubledests = (dests >> 8) & targets & RANK_5
    n += count(doubledests)
    return n
end


function count_free_pawn_captures(board::Board, targets::Bitboard)
    n = 0
    if board.turn == WHITE
        n += count_free_wpawn_captures(board, targets)
    else
        n += count_free_bpawn_captures(board, targets)
    end
    return n
end


function count_free_wpawn_captures(board::Board, targets::Bitboard)
    n = 0
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures
    dests = (pwns << 9) & targets & ~FILE_H
    n += count(dests & ~RANK_8)

    n += count(dests & RANK_8) * 4


    # "Right" pawn captures
    dests = (pwns << 7) & targets & ~FILE_A
    n += count(dests & ~RANK_8)

    n += count(dests & RANK_8) * 4
    return n
end


function count_free_bpawn_captures(board::Board, targets::Bitboard)
    n = 0
    pwns = pawns(board) & friendly(board) & ~pinned(board)

    # "Left" pawn captures
    dests = (pwns >> 7) & targets & ~FILE_H
    n += count(dests & ~RANK_1)

    n += count(dests & RANK_1) * 4

    # "Right" pawn captures

    dests = (pwns >> 9) & targets & ~FILE_A
    n += count(dests & ~RANK_1)

    n += count(dests & RANK_1) * 4
    return n
end


function count_enpass_moves(board::Board)
    n = 0
    ep_sqr = board.enpass
    if ep_sqr !== zero(UInt8)
        king = square(kings(board) & friendly(board))
        for pwn in (pawnAttacks(!board.turn, ep_sqr) & pawns(board) & friendly(board))
            occ = occupied(board)
            occ &= ~Bitboard(pwn) & ~Bitboard(ep_sqr - 24 + (board.turn.val << 4))
            occ |= Bitboard(ep_sqr)
            if isempty(bishopMoves(king, occ) & bishoplike(board) & enemy(board)) && isempty(rookMoves(king, occ) & rooklike(board) & enemy(board))
                n += 1
            end
        end
    end
    return n
end


function count_pawn_advance_promos(board::Board, targets::Bitboard)
    n = 0
    if board.turn == WHITE
        n += count_wpawn_advance_promos(board, targets)
    else
        n += count_bpawn_advance_promos(board, targets)
    end
    return n
end


function count_wpawn_advance_promos(board::Board, targets::Bitboard)
    n = 0
    pwns = pawns(board) & friendly(board) & (~pinned(board) | file(kings(board) & friendly(board)))
    dests = (pwns << 8) & targets & RANK_8
    n += count(dests) * 4
    return n
end


function count_bpawn_advance_promos(board::Board, targets::Bitboard)
    n = 0
    pwns = pawns(board) & friendly(board) & (~pinned(board) | file(kings(board) & friendly(board)))
    dests = (pwns >> 8) & targets & RANK_1
    n += count(dests) * 4
    return n
end


function count_pinned_pawn_captures_and_promos(board::Board, targets::Bitboard)
    n = 0
    pwns = pawns(board) & friendly(board) & pinned(board)
    king = square(kings(board) & friendly(board))
    for pwn in pwns
        for move_to in (pawnAttacks(board.turn, pwn) & enemy(board) & targets)
            if !isempty(Bitboard(pwn) & blockers(king, move_to))
                if !isempty(Bitboard(move_to) & RANK_18)
                    n += 4
                else
                    n += 1
                end
            end
        end
    end
    return n
end


function count_knight_moves(board::Board, targets::Bitboard)
    n = 0
    for knight in (knights(board) & friendly(board) & ~pinned(board))
        n += count(knightMoves(knight) & targets)
    end
    return n
end


function count_bishop_moves(board::Board, targets::Bitboard)
    n = 0
    n += count_free_bishop_moves(board, targets)
    n += count_pinned_bishop_moves(board, targets)
    return n
end


function count_free_bishop_moves(board::Board, targets::Bitboard)
    n = 0
    occ = occupied(board)
    for bishop in (bishoplike(board) & friendly(board) & ~pinned(board))
        n += count(bishopMoves(bishop, occ) & targets)
    end
    return n
end


function count_pinned_bishop_moves(board::Board, targets::Bitboard)
    n = 0
    king = square(kings(board) & friendly(board))
    occ = occupied(board)
    for bishop in (bishoplike(board) & friendly(board) & pinned(board))
        block_1 = blockers(king, bishop)
        for move_to in (bishopMoves(bishop, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(bishop) & blockers(king, move_to))
                n += 1
            end
        end
    end
    return n
end


function count_rook_moves(board::Board, targets::Bitboard)
    n = 0
    n += count_free_rook_moves(board, targets)
    n += count_pinned_rook_moves(board, targets)
    return n
end


function count_free_rook_moves(board::Board, targets::Bitboard)
    n = 0
    occ = occupied(board)
    for rook in (rooklike(board) & friendly(board) & ~pinned(board))
        n += count(rookMoves(rook, occ) & targets)
    end
    return n
end


function count_pinned_rook_moves(board::Board, targets::Bitboard)
    n = 0
    king = square(kings(board) & friendly(board))
    occ = occupied(board)
    for rook in (rooklike(board) & friendly(board) & pinned(board))
        block_1 = blockers(king, rook)
        for move_to in (rookMoves(rook, occ) & targets)
            if !isempty(Bitboard(move_to) & block_1) || !isempty(Bitboard(rook) & blockers(king, move_to))
                n += 1
            end
        end
    end
    return n
end


function count_king_moves(board::Board, targets::Bitboard)
    n = 0
    king = square(kings(board) & friendly(board))
    for move_to in (kingMoves(king) & targets)
        if !isattacked_through_king(board, move_to)
            n += 1
        end
    end
    return n
end


function count_castling(board::Board)
    n = 0
    if cancastlekingside(board)
        n += count_kingside_castling(board)
    end
    if cancastlequeenside(board)
        n += count_queenside_castling(board)
    end
    return n
end


function count_kingside_castling(board::Board)
    n = 0
    king = square(kings(board) & friendly(board))
    rook = king - 3
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king - 1) && !isattacked(board, king - 2)
        n += 1
    end
    return n
end


function count_queenside_castling(board)
    n = 0
    king = square(kings(board) & friendly(board))
    rook = king + 4
    if isempty(occupied(board) & blockers(king, rook)) && !isattacked(board, king + 1) && !isattacked(board, king + 2)
        n += 1
    end
    return n
end


function count_quiet_moves(board::Board)
    n = 0
    empty_bb = empty(board)
    if isdoublecheck(board)
        n += count_king_moves(board, empty_bb)
        return n
    end
    if ischeck(board)
        if isempty(checkers(board) & knights(board))
            targets = blockers(square(kings(board) & friendly(board)), square(checkers(board)))
        else
            # if a knight gives check, only *quiet* move is for king to step away
            n += count_king_moves(board, empty_bb)
            return n
        end
    else
        n += count_castling(board)
        targets = empty_bb
    end
    n += count_pawn_advances(board, targets)
    n += count_king_moves(board, empty_bb)
    n += count_knight_moves(board, targets)
    n += count_bishop_moves(board, targets)
    n += count_rook_moves(board, targets)
    return n
end


function count_noisy_moves(board::Board)
    n = 0
    enemies = enemy(board)
    if isdoublecheck(board)
        n += count_king_moves(board, enemies)
        return n
    end
    if ischeck(board)
        targets = checkers(board)
        n += count_pawn_advance_promos(board, blockers(square(kings(board) & friendly(board)), square(targets)))
    else
        targets = enemies
        n += count_pawn_advance_promos(board, empty(board))
    end
    n += count_free_pawn_captures(board, targets)
    n += count_pinned_pawn_captures_and_promos(board, targets)
    n += count_enpass_moves(board)
    n += count_king_moves(board, enemies)
    n += count_knight_moves(board, targets)
    n += count_bishop_moves(board, targets)
    n += count_rook_moves(board, targets)
    return n
end


function count_moves(board::Board)
    n = 0
    n += count_quiet_moves(board)
    n += count_noisy_moves(board)
    return n
end
