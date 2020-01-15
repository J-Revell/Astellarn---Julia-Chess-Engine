#====================== Auxilliary precomputation =============================#
"""
    EvalInfoImmutable

EvalAux is an auxilliary data structure for storing useful computations for the evaluation of the board.
"""
struct EvalInfoImmutable
    wrammedpawns::Bitboard
    brammedpawns::Bitboard
    wpawnattacks::Bitboard
    bpawnattacks::Bitboard
    wmobility::Bitboard
    bmobility::Bitboard
    stage::Int
end


"""
    EvalInfoMutable

EvalAux is an auxilliary data structure for storing useful computations for the evaluation of the board.
"""
mutable struct EvalInfoMutable
    wknightattacks::Bitboard
    bknightattacks::Bitboard
    wbishopattacks::Bitboard
    bbishopattacks::Bitboard
    wrookattacks::Bitboard
    brookattacks::Bitboard
    wqueenattacks::Bitboard
    bqueenattacks::Bitboard
end


function initEvalInfo(board::Board)
    # extract pawn positions
    wpawns = board[WHITE] & board[PAWN]
    bpawns = board[BLACK] & board[PAWN]
    pawns = [wpawns, bpawns]

    # check for rammed pawns
    wrammedpawns = pawnAdvance(bpawns, wpawns, BLACK)
    brammedpawns = pawnAdvance(wpawns, bpawns, WHITE)

    # generate list of all positions attacked by a pawn
    wpawnattacks = pawnCapturesWhite(wpawns, FULL)
    bpawnattacks = pawnCapturesBlack(bpawns, FULL)

    # generate list of all positions attacked by a knight
    wknightattacks = EMPTY #knightMove_all(wknights)
    bknightattacks = EMPTY #knightMove_all(bknights)

    wbishopattacks = EMPTY
    bbishopattacks = EMPTY

    wrookattacks = EMPTY
    brookattacks = EMPTY

    wqueenattacks = EMPTY
    bqueenattacks = EMPTY

    # mobility regions
    wmobility = ~(board[WHITEKING] | bpawnattacks)
    bmobility = ~(board[BLACKKING] | wpawnattacks)

    gamestage = stage(board)

    eii = EvalInfoImmutable(wrammedpawns, brammedpawns, wpawnattacks, bpawnattacks, wmobility, bmobility, gamestage)
    eim = EvalInfoMutable(wknightattacks, bknightattacks, wbishopattacks, bbishopattacks, wrookattacks, brookattacks, wqueenattacks, bqueenattacks)
    eii, eim
end


#============================== Game stage functions ==========================#


function stage(board::Board)
    stage = 24 - 4count(queens(board)) - 2count(rooks(board)) - count(knights(board) | bishops(board))
    stage = fld(stage * 256 + 12, 24)
end


#=============================== Endgame scoring scaling ======================#


function scale_factor(board::Board, eval::Int)
    if isone(board[WHITEBISHOP]) && isone(board[BLACKBISHOP]) && isone(bishops(board) & LIGHT)
        if isempty(knights(board) | rooklike(board))
            return SCALE_OCB_BISHOPS
        end
        if isempty(rooklike(board)) && isone(board[WHITEKNIGHT]) && isone(board[BLACKKNIGHT])
            return SCALE_OCB_ONE_KNIGHT
        end
        if isempty(knights(board) | queens(board)) && isone(board[WHITEROOK]) && isone(board[BLACKROOK])
            return SCALE_OCB_ONE_ROOK
        end
    end
    if (eval > 0) && (count(board[WHITE]) == 2) && ismany(board[WHITEKNIGHT] | board[WHITEBISHOP])
        return SCALE_DRAW
    elseif (eval < 0) && (count(board[BLACK]) == 2) && ismany(board[BLACKKNIGHT] | board[BLACKBISHOP])
        return SCALE_DRAW
    end
    return SCALE_NORMAL
end


#=============================== Main evaluation ==============================#


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board, ptable::PawnTable)
    eii, eim = initEvalInfo(board::Board)

    score = 0
    score += board.psqteval

    score += evaluate_pawns(board, eii, eim, ptable)
    score += evaluate_knights(board, eii, eim)
    score += evaluate_bishops(board, eii, eim)
    score += evaluate_rooks(board, eii, eim)
    score += evaluate_queens(board, eii, eim)
    score += evaluate_kings(board, eii, eim)

    score += evaluate_pins(board)
    score += evaluate_space(board, eii, eim)
    score += evaluate_threats(board, eii, eim)

    scale_f = scale_factor(board, scoreEG(score))

    eval = (256 - eii.stage) * scoreMG(score) + eii.stage * scoreEG(score) * fld(scale_f, SCALE_NORMAL)
    eval = fld(eval, 256)

    if board.turn == WHITE
        eval += TEMPO_BONUS
        return eval
    else
        eval -= TEMPO_BONUS
        return -eval
    end
end


function evaluate_pawns(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable, ptable::PawnTable)

    if (pt_entry = get(ptable, board.phash, false)) !== false
        return pt_entry.score
    end

    w_pawns = board[WHITE] & board[PAWN]
    b_pawns = board[BLACK] & board[PAWN]
    position_eval = 0
    score = 0

    @inbounds for pawn in w_pawns
        file = fileof(pawn)
        # Passed pawns
        if isempty(b_pawns & PASSED_PAWN_MASKS[1][pawn])
            score += PASS_PAWN_THREAT[rankof(pawn)]
        end
        # Isolated pawns
        if isempty(NEIGHBOUR_FILE_MASKS[file] & w_pawns & ~FILE[file])
            score -= ISOLATED_PAWN_PENALTY
        end
        # Double pawns
        if ismany(w_pawns & FILE[file])
            score -= DOUBLE_PAWN_PENALTY
        end
    end

    @inbounds for pawn in b_pawns
        file = fileof(pawn)
        # Passed pawns
        if isempty(w_pawns & PASSED_PAWN_MASKS[2][pawn])
            score -= PASS_PAWN_THREAT[8 - rankof(pawn)]
        end
        # Isolated pawns
        if isempty(NEIGHBOUR_FILE_MASKS[file] & b_pawns & ~FILE[file])
            score += ISOLATED_PAWN_PENALTY
        end
        # Double pawns
        if ismany(b_pawns & FILE[file])
            score += DOUBLE_PAWN_PENALTY
        end
    end

    position_eval += count(eii.wpawnattacks & w_pawns) * PAWN_DEFEND_PAWN_BONUS
    position_eval -= count(eii.bpawnattacks & b_pawns) * PAWN_DEFEND_PAWN_BONUS

    result = makescore(position_eval, position_eval) + score
    ptable[board.phash] = PT_Entry(result)
    return result
end


function evaluate_knights(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_knights = (board[WHITE] & board[KNIGHT])
    b_knights = (board[BLACK] & board[KNIGHT])

    score = 0
    position_eval = 0

    @inbounds for knight in w_knights
        attacks = knightMoves(knight)
        eim.wknightattacks |= attacks
        score += KNIGHT_MOBILITY[count(attacks & eii.wmobility) + 1]
    end
    score += count((w_knights << 8) & board[WHITE] & board[PAWN]) * PAWN_SHIELD_BONUS
    position_eval += count(eii.wpawnattacks & w_knights) * PAWN_DEFEND_MINOR_BONUS
    score -= count(eii.bpawnattacks & w_knights) * PAWN_ATTACK_MINOR_BONUS

    @inbounds for knight in b_knights
        attacks = knightMoves(knight)
        eim.bknightattacks |= attacks
        score -= KNIGHT_MOBILITY[count(attacks & eii.bmobility) + 1]
    end
    score -= count((b_knights >> 8) & board[BLACK] & board[PAWN]) * PAWN_SHIELD_BONUS
    position_eval -= count(eii.bpawnattacks & b_knights) * PAWN_DEFEND_MINOR_BONUS
    score += count(eii.wpawnattacks & b_knights) * PAWN_ATTACK_MINOR_BONUS

    # bonus for knights in rammed positions
    num_rammed = count(eii.wrammedpawns)
    position_eval += div(count(w_knights) * KNIGHT_RAMMED_BONUS * num_rammed^2, 4)
    position_eval -= div(count(b_knights) * KNIGHT_RAMMED_BONUS * num_rammed^2, 4)

    # Evaluate trapped knights.
    for trap in KNIGHT_TRAP_PATTERNS[1]
        if ((board[BLACK] & board[PAWN] & trap.pawnmask) == trap.pawnmask) && isone(w_knights & trap.minormask)
            position_eval -= KNIGHT_TRAP_PENALTY
        end
    end
    for trap in KNIGHT_TRAP_PATTERNS[2]
        if ((board[WHITE] & board[PAWN] & trap.pawnmask) == trap.pawnmask) && isone(b_knights & trap.minormask)
            position_eval += KNIGHT_TRAP_PENALTY
        end
    end

    position_eval += count(eim.wknightattacks & (board[WHITE] & board[BISHOP])) * 10
    position_eval -= count(eim.bknightattacks & (board[BLACK] & board[BISHOP])) * 10
    position_eval += count(eim.wknightattacks & (board[WHITE] & board[ROOK])) * 7
    position_eval -= count(eim.bknightattacks & (board[BLACK] & board[ROOK])) * 7
    position_eval += count(eim.wknightattacks & board[WHITEQUEEN]) * 5
    position_eval -= count(eim.bknightattacks & board[BLACKQUEEN]) * 5

    threat_eval = 0
    threat_eval += count(eim.wknightattacks & (board[BLACK] & board[BISHOP])) * 15
    threat_eval -= count(eim.bknightattacks & (board[WHITE] & board[BISHOP])) * 15
    threat_eval += count(eim.wknightattacks & (board[BLACK] & board[ROOK])) * 28
    threat_eval -= count(eim.bknightattacks & (board[WHITE] & board[ROOK])) * 28
    threat_eval += count(eim.wknightattacks & board[BLACKQUEEN]) * 42
    threat_eval -= count(eim.bknightattacks & board[WHITEQUEEN]) * 42

    eval = position_eval + threat_eval
    makescore(eval, eval) + score
end


function evaluate_bishops(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_bishops = (board[WHITE] & board[BISHOP])
    b_bishops = (board[BLACK] & board[BISHOP])

    position_eval = 0
    score = 0

    attacks = EMPTY
    occ = occupied(board)

    @inbounds for bishop in w_bishops
        attacks = bishopMoves(bishop, occ)
        eim.wbishopattacks |= attacks
        score += BISHOP_MOBILITY[count(attacks & eii.wmobility) + 1]
    end
    # Add a bonus for being behind a pawn.
    score += count((w_bishops << 8) & board[WHITE] & board[PAWN]) * PAWN_SHIELD_BONUS
    position_eval += count(eii.wpawnattacks & w_bishops) * PAWN_DEFEND_MINOR_BONUS
    score -= count(eii.bpawnattacks & w_bishops) * PAWN_ATTACK_MINOR_BONUS

    @inbounds for bishop in b_bishops
        attacks = bishopMoves(bishop, occ)
        eim.bbishopattacks |= attacks
        score -= BISHOP_MOBILITY[count(attacks & eii.bmobility) + 1]
    end
    # Add a bonus for being behind a pawn
    score -= count((b_bishops >> 8) & board[BLACK] & board[PAWN]) * PAWN_SHIELD_BONUS
    position_eval -= count(eii.bpawnattacks & b_bishops) * PAWN_DEFEND_MINOR_BONUS
    score += count(eii.wpawnattacks & b_bishops) * PAWN_ATTACK_MINOR_BONUS

    for trap in BISHOP_TRAP_PATTERNS[1]
        if ((board[BLACK] & board[PAWN] & trap.pawnmask) == trap.pawnmask) && !isempty(w_bishops & trap.minormask)
            position_eval -= BISHOP_TRAP_PENALTY
        end
    end
    for trap in BISHOP_TRAP_PATTERNS[2]
        if ((board[WHITE] & board[PAWN] & trap.pawnmask) == trap.pawnmask) && !isempty(b_bishops & trap.minormask)
            position_eval += BISHOP_TRAP_PENALTY
        end
    end

    # bishop pair
    if count(w_bishops) >= 2
        position_eval += BISHOP_PAIR_BONUS
    end
    if count(b_bishops) >= 2
        position_eval -= BISHOP_PAIR_BONUS
    end

    # penalty for bishops on colour of own pawns
    if !isempty(w_bishops & LIGHT)
        score -= BISHOP_COLOR_PENALTY * count(board[WHITE] & board[PAWN] & LIGHT)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(eii.wrammedpawns & LIGHT)
    end
    if !isempty(w_bishops & DARK)
        score -= BISHOP_COLOR_PENALTY * count(board[WHITE] & board[PAWN] & DARK)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(eii.wrammedpawns & DARK)
    end
    if !isempty(b_bishops & LIGHT)
        score += BISHOP_COLOR_PENALTY * count(board[BLACK] & board[PAWN] & LIGHT)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(eii.brammedpawns & LIGHT)
    end
    if !isempty(b_bishops & DARK)
        score += BISHOP_COLOR_PENALTY * count(board[BLACK] & board[PAWN] & DARK)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(eii.brammedpawns & DARK)
    end

    eval = position_eval
    makescore(eval, eval) + score
end


function evaluate_rooks(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_rooks = (board[WHITE] & board[ROOK])
    b_rooks = (board[BLACK] & board[ROOK])

    position_eval = 0
    score = 0

    occ = occupied(board)
    for rook in w_rooks
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            score += ROOK_OPEN_FILE_BONUS
        elseif isempty(rfile & board[WHITE] & board[PAWN])
            score += ROOK_SEMIOPEN_FILE_BONUS
        end
        if isone(rfile & board[BLACKKING])
            position_eval += ROOK_KING_FILE_BONUS
        end
        attacks = rookMoves(rook, occ)
        eim.wrookattacks |= attacks
        score += ROOK_MOBILITY[count(attacks & eii.wmobility) + 1]
    end

    for rook in b_rooks
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            score -= ROOK_OPEN_FILE_BONUS
        elseif isempty(rfile & board[BLACK] & board[PAWN])
            score -= ROOK_SEMIOPEN_FILE_BONUS
        end
        if isone(rfile & board[WHITEKING])
            position_eval -= ROOK_KING_FILE_BONUS
        end
        attacks = rookMoves(rook, occ)
        eim.brookattacks |= attacks
        score -= ROOK_MOBILITY[count(attacks & eii.bmobility) + 1]
    end

    position_eval += count(eii.wpawnattacks & w_rooks) * PAWN_DEFEND_MAJOR_BONUS
    score -= count(eii.bpawnattacks & w_rooks) * PAWN_ATTACK_MAJOR_BONUS
    position_eval -= count(eii.bpawnattacks & b_rooks) * PAWN_DEFEND_MAJOR_BONUS
    score += count(eii.wpawnattacks & b_rooks) * PAWN_ATTACK_MAJOR_BONUS

    eval = position_eval
    score + makescore(eval, eval)
end


function evaluate_queens(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_queens = board[WHITEQUEEN]
    b_queens = board[BLACKQUEEN]

    position_eval = 0
    score = 0

    occ = occupied(board)

    @inbounds for queen in w_queens
        attacks = queenMoves(queen, occ)
        eim.wqueenattacks |= attacks
        score += QUEEN_MOBILITY[count(attacks & eii.wmobility) + 1]
    end

    @inbounds for queen in b_queens
        attacks = queenMoves(queen, occ)
        eim.bqueenattacks |= attacks
        score -= QUEEN_MOBILITY[count(attacks & eii.bmobility) + 1]
    end

    # attacked by a pawn?
    score -= count(eii.bpawnattacks & w_queens) * PAWN_ATTACK_MAJOR_BONUS
    score += count(eii.wpawnattacks & b_queens) * PAWN_ATTACK_MAJOR_BONUS

    eval = position_eval
    score + makescore(eval, eval)
end


function evaluate_kings(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_king = board[WHITEKING]
    b_king = board[BLACKKING]
    w_king_sqr = square(w_king)
    b_king_sqr = square(b_king)

    position_eval = 0
    king_safety = 0
    score = 0

    if cancastlekingside(board, WHITE)
        position_eval += CASTLE_OPTION_BONUS
    end
    if cancastlequeenside(board, WHITE)
        position_eval += CASTLE_OPTION_BONUS
    end
    if cancastlekingside(board, BLACK)
        position_eval -= CASTLE_OPTION_BONUS
    end
    if cancastlequeenside(board, BLACK)
        position_eval -= CASTLE_OPTION_BONUS
    end

    # Increase king safety if attacking pieces are non existent
    if isempty(board[BLACKQUEEN])
        king_safety += 15
    end
    if isempty(board[WHITEQUEEN])
        king_safety -= 15
    end
    if isempty((board[BLACK] & board[ROOK]))
        king_safety += 9
    end
    if isempty((board[WHITE] & board[ROOK]))
        king_safety -= 9
    end
    if isempty((board[BLACK] & board[BISHOP]))
        king_safety += 6
    end
    if isempty((board[WHITE] & board[BISHOP]))
        king_safety -= 6
    end
    if isempty((board[BLACK] & board[KNIGHT]))
        king_safety += 5
    end
    if isempty((board[WHITE] & board[KNIGHT]))
        king_safety -= 5
    end

    wkingattacks = kingMoves(w_king_sqr)
    bkingattacks = kingMoves(b_king_sqr)

    # Increase king safety for each pawn surrounding him
    king_safety += count(wkingattacks & board[WHITE] & board[PAWN]) * KING_PAWN_SHIELD_BONUS
    king_safety -= count(bkingattacks & board[BLACK] & board[PAWN]) * KING_PAWN_SHIELD_BONUS


    # decrease king safety if on an open file, with enemy rooks or queens on the board.
    if !isempty((board[BLACK] & board[ROOK]) | board[BLACKQUEEN]) && isempty(file(w_king_sqr) & pawns(board))
        king_safety -= 15
    end
    if !isempty((board[WHITE] & board[ROOK]) | board[WHITEQUEEN]) && isempty(file(b_king_sqr) & pawns(board))
        king_safety += 15
    end

    # decrease king safety if a neighbouring knight can deliver a check
    if !isempty(knightMoves(square(w_king)) & eim.bknightattacks)
        king_safety -= 10
    end
    if !isempty(knightMoves(square(b_king)) & eim.wknightattacks)
        king_safety += 10
    end

    # decrease safety if neighbouring squares are attacked
    b_attacks = eii.bpawnattacks | eim.bknightattacks | eim.bbishopattacks | eim.brookattacks | eim.bqueenattacks
    w_attacks = eii.wpawnattacks | eim.wknightattacks | eim.wbishopattacks | eim.wrookattacks | eim.wqueenattacks
    king_safety -= 9 * count(b_attacks & wkingattacks) * div(15, (count(wkingattacks) + 1))
    king_safety += 9 * count(w_attacks & bkingattacks) * div(15, (count(bkingattacks) + 1))

    # Score the number of attacks on our king's flank
    score -= count(b_attacks & KINGFLANK[fileof(w_king_sqr)]) * KING_FLANK_ATTACK
    score += count(w_attacks & KINGFLANK[fileof(b_king_sqr)]) * KING_FLANK_ATTACK

    eval = position_eval + king_safety
    score + makescore(eval, eval)
end


function evaluate_pins(board::Board)
    eval = 0

    # switch turn and find all pins
    board.turn = !board.turn
    opp_pinned = findpins(board)
    board.turn = !board.turn

    if board.turn == WHITE
        eval -= count(board.pinned) * PIN_BONUS
        eval += count(opp_pinned) * PIN_BONUS
    else
        eval += count(board.pinned) * PIN_BONUS
        eval -= count(opp_pinned) * PIN_BONUS
    end

    # specific additional pin bonus
    eval -= count(pinned(board) & queens(board)) * 30
    eval += count(opp_pinned & queens(board)) * 30
    eval -= count(pinned(board) & rooks(board)) * 10
    eval += count(opp_pinned & rooks(board)) * 10

    makescore(eval, eval)
end


function evaluate_space(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    eval = 0

    w_filter = (RANK_2 | RANK_3 | RANK_4) & CENTERFILES
    b_filter = (RANK_5 | RANK_6 | RANK_7) & CENTERFILES
    w_attacks = eii.wpawnattacks | eim.wknightattacks | eim.wbishopattacks | eim.wrookattacks
    b_attacks = eii.bpawnattacks | eim.bknightattacks | eim.bbishopattacks | eim.brookattacks
    eval += count(w_filter & ~b_attacks) * SPACE_BONUS
    eval -= count(b_filter & ~w_attacks) * SPACE_BONUS

    makescore(eval, eval)
end


function evaluate_threats(board::Board, eii::EvalInfoImmutable, eim::EvalInfoMutable)
    w_attacks = eii.wpawnattacks | eim.wknightattacks | eim.wbishopattacks | eim.wrookattacks
    b_attacks = eii.bpawnattacks | eim.bknightattacks | eim.bbishopattacks | eim.brookattacks

    weak_bonus = 0

    weak_wpawns = board[WHITEPAWN] & ~w_attacks & b_attacks
    weak_bonus -= count(weak_wpawns) * WEAK_PAWN_PENALTY

    weak_bpawns = board[BLACKPAWN] & ~b_attacks & w_attacks
    weak_bonus += count(weak_bpawns) * WEAK_PAWN_PENALTY

    makescore(weak_bonus, weak_bonus)
end
