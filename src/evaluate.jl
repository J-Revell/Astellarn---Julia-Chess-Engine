#====================== Auxilliary precomputation =============================#
"""
    EvalInfo

EvalAux is an auxilliary data structure for storing useful computations for the evaluation of the board.
"""
struct EvalInfo
    wrammedpawns::Bitboard
    brammedpawns::Bitboard
    wmobility::Bitboard
    bmobility::Bitboard
    stage::Int
end


"""
    EvalAttackInfo

EvalAux is an auxilliary data structure for storing useful computations for the evaluation of the board.
"""
mutable struct EvalAttackInfo
    wpawnattacks::Bitboard
    wknightattacks::Bitboard
    wbishopattacks::Bitboard
    wrookattacks::Bitboard
    wqueenattacks::Bitboard
    wkingattacks::Bitboard
    bpawnattacks::Bitboard
    bknightattacks::Bitboard
    bbishopattacks::Bitboard
    brookattacks::Bitboard
    bqueenattacks::Bitboard
    bkingattacks::Bitboard
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

    wkingattacks = EMPTY
    bkingattacks = EMPTY

    # mobility regions
    wmobility = ~(board[WHITEKING] | bpawnattacks)
    bmobility = ~(board[BLACKKING] | wpawnattacks)

    gamestage = stage(board)

    # wattacks = [wpawnattacks, wknightattacks, wbishopattacks, wrookattacks, wqueenattacks, wkingattacks]
    # battacks = [bpawnattacks, bknightattacks, bbishopattacks, brookattacks, bqueenattacks, bkingattacks]
    # allattacks = [EMPTY, EMPTY]

    ei = EvalInfo(wrammedpawns, brammedpawns, wmobility, bmobility, gamestage)
    ea = EvalAttackInfo(wpawnattacks, wknightattacks, wbishopattacks, wrookattacks, wqueenattacks, wkingattacks, bpawnattacks, bknightattacks, bbishopattacks, brookattacks, bqueenattacks, bkingattacks)
    ei, ea
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
    ei, ea = initEvalInfo(board::Board)

    score = 0
    score += board.psqteval

    if (pt_entry = get(ptable, board.phash, false)) !== false
        score += pt_entry.score
    end

    v = fld(scoreEG(score) + scoreMG(score), 2)
    if abs(v) > LAZY_THRESH
        if board.turn == WHITE
            return v
        else
            return -v
        end
    end

    if pt_entry == false
        score += evaluate_pawns(board, ei, ea, ptable)
    end
    score += evaluate_knights(board, ei, ea)
    score += evaluate_bishops(board, ei, ea)
    score += evaluate_rooks(board, ei, ea)
    score += evaluate_queens(board, ei, ea)
    score += evaluate_kings(board, ei, ea)


    score += evaluate_pins(board)
    score += evaluate_space(board, ei, ea)
    score += evaluate_threats(board, ei, ea)

    scale_f = scale_factor(board, scoreEG(score))

    eval = (256 - ei.stage) * scoreMG(score) + ei.stage * scoreEG(score) * fld(scale_f, SCALE_NORMAL)
    eval = fld(eval, 256)

    if board.turn == WHITE
        eval += TEMPO_BONUS
        return eval
    else
        eval -= TEMPO_BONUS
        return -eval
    end
end


function evaluate_pawns(board::Board, ei::EvalInfo, ea::EvalAttackInfo, ptable::PawnTable)

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

    position_eval += count(ea.wpawnattacks & w_pawns) * PAWN_DEFEND_PAWN_BONUS
    position_eval -= count(ea.bpawnattacks & b_pawns) * PAWN_DEFEND_PAWN_BONUS

    result = makescore(position_eval, position_eval) + score
    ptable[board.phash] = PT_Entry(result)
    return result
end


function evaluate_knights(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_knights = (board[WHITE] & board[KNIGHT])
    b_knights = (board[BLACK] & board[KNIGHT])

    score = 0
    position_eval = 0

    @inbounds for knight in w_knights
        attacks = knightMoves(knight)
        ea.wknightattacks |= attacks
        score += KNIGHT_MOBILITY[count(attacks & ei.wmobility) + 1]
    end
    score += count((w_knights << 8) & board[WHITE] & board[PAWN]) * PAWN_SHIELD_BONUS

    @inbounds for knight in b_knights
        attacks = knightMoves(knight)
        ea.bknightattacks |= attacks
        score -= KNIGHT_MOBILITY[count(attacks & ei.bmobility) + 1]
    end
    score -= count((b_knights >> 8) & board[BLACK] & board[PAWN]) * PAWN_SHIELD_BONUS

    # bonus for knights in rammed positions
    num_rammed = count(ei.wrammedpawns)
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

    eval = position_eval
    makescore(eval, eval) + score
end


function evaluate_bishops(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_bishops = (board[WHITE] & board[BISHOP])
    b_bishops = (board[BLACK] & board[BISHOP])

    position_eval = 0
    score = 0

    attacks = EMPTY
    occ = occupied(board)

    @inbounds for bishop in w_bishops
        attacks = bishopMoves(bishop, occ)
        ea.wbishopattacks |= attacks
        score += BISHOP_MOBILITY[count(attacks & ei.wmobility) + 1]
    end
    # Add a bonus for being behind a pawn.
    score += count((w_bishops << 8) & board[WHITE] & board[PAWN]) * PAWN_SHIELD_BONUS

    @inbounds for bishop in b_bishops
        attacks = bishopMoves(bishop, occ)
        ea.bbishopattacks |= attacks
        score -= BISHOP_MOBILITY[count(attacks & ei.bmobility) + 1]
    end
    # Add a bonus for being behind a pawn
    score -= count((b_bishops >> 8) & board[BLACK] & board[PAWN]) * PAWN_SHIELD_BONUS

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
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(ei.wrammedpawns & LIGHT)
    end
    if !isempty(w_bishops & DARK)
        score -= BISHOP_COLOR_PENALTY * count(board[WHITE] & board[PAWN] & DARK)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(ei.wrammedpawns & DARK)
    end
    if !isempty(b_bishops & LIGHT)
        score += BISHOP_COLOR_PENALTY * count(board[BLACK] & board[PAWN] & LIGHT)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(ei.brammedpawns & LIGHT)
    end
    if !isempty(b_bishops & DARK)
        score += BISHOP_COLOR_PENALTY * count(board[BLACK] & board[PAWN] & DARK)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(ei.brammedpawns & DARK)
    end

    eval = position_eval
    makescore(eval, eval) + score
end


function evaluate_rooks(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
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
        ea.wrookattacks |= attacks
        score += ROOK_MOBILITY[count(attacks & ei.wmobility) + 1]
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
        ea.brookattacks |= attacks
        score -= ROOK_MOBILITY[count(attacks & ei.bmobility) + 1]
    end

    eval = position_eval
    score + makescore(eval, eval)
end


function evaluate_queens(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_queens = board[WHITEQUEEN]
    b_queens = board[BLACKQUEEN]

    position_eval = 0
    score = 0

    occ = occupied(board)

    @inbounds for queen in w_queens
        attacks = queenMoves(queen, occ)
        ea.wqueenattacks |= attacks
        score += QUEEN_MOBILITY[count(attacks & ei.wmobility) + 1]
    end

    @inbounds for queen in b_queens
        attacks = queenMoves(queen, occ)
        ea.bqueenattacks |= attacks
        score -= QUEEN_MOBILITY[count(attacks & ei.bmobility) + 1]
    end

    eval = position_eval
    score + makescore(eval, eval)
end


function evaluate_kings(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_king = board[WHITEKING]
    b_king = board[BLACKKING]
    w_king_sqr = square(w_king)
    b_king_sqr = square(b_king)
    ea.wkingattacks |= kingMoves(w_king_sqr)
    ea.bkingattacks |= kingMoves(b_king_sqr)

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

    # Increase king safety for each pawn surrounding him
    king_safety += count(ea.wkingattacks & board[WHITE] & board[PAWN]) * KING_PAWN_SHIELD_BONUS
    king_safety -= count(ea.bkingattacks & board[BLACK] & board[PAWN]) * KING_PAWN_SHIELD_BONUS


    # decrease king safety if on an open file, with enemy rooks or queens on the board.
    if !isempty((board[BLACK] & board[ROOK]) | board[BLACKQUEEN]) && isempty(file(w_king_sqr) & pawns(board))
        king_safety -= 15
    end
    if !isempty((board[WHITE] & board[ROOK]) | board[WHITEQUEEN]) && isempty(file(b_king_sqr) & pawns(board))
        king_safety += 15
    end

    # decrease king safety if a neighbouring knight can deliver a check
    if !isempty(knightMoves(square(w_king)) & ea.bknightattacks)
        king_safety -= 10
    end
    if !isempty(knightMoves(square(b_king)) & ea.wknightattacks)
        king_safety += 10
    end

    # decrease safety if neighbouring squares are attacked
    b_attacks = ea.bpawnattacks | ea.bknightattacks | ea.bbishopattacks | ea.brookattacks | ea.bqueenattacks
    w_attacks = ea.wpawnattacks | ea.wknightattacks | ea.wbishopattacks | ea.wrookattacks | ea.wqueenattacks
    king_safety -= 9 * count(b_attacks & ea.wkingattacks) * div(15, (count(ea.wkingattacks) + 1))
    king_safety += 9 * count(w_attacks & ea.bkingattacks) * div(15, (count(ea.bkingattacks) + 1))

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


function evaluate_space(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    eval = 0

    w_filter = (RANK_2 | RANK_3 | RANK_4) & CENTERFILES
    b_filter = (RANK_5 | RANK_6 | RANK_7) & CENTERFILES
    w_attacks = ea.wpawnattacks | ea.wknightattacks | ea.wbishopattacks | ea.wrookattacks | ea.wqueenattacks | ea.wkingattacks
    b_attacks = ea.bpawnattacks | ea.bknightattacks | ea.bbishopattacks | ea.brookattacks | ea.bqueenattacks | ea.bkingattacks
    eval += count(w_filter & ~b_attacks) * SPACE_BONUS
    eval -= count(b_filter & ~w_attacks) * SPACE_BONUS

    makescore(eval, eval)
end


function evaluate_threats(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_attacks = ea.wpawnattacks
    w_double_attacks = w_attacks & ea.wknightattacks
    w_attacks |= ea.wknightattacks
    w_double_attacks |= w_attacks & ea.wbishopattacks
    w_attacks |= ea.wbishopattacks
    w_double_attacks |= w_attacks & ea.wrookattacks
    w_attacks |= ea.wrookattacks
    w_double_attacks |= w_attacks & ea.wqueenattacks
    w_attacks |= ea.wqueenattacks
    w_double_attacks |= w_attacks & ea.wkingattacks
    w_attacks |= ea.wkingattacks

    b_attacks = ea.bpawnattacks
    b_double_attacks = b_attacks & ea.bknightattacks
    b_attacks |= ea.bknightattacks
    b_double_attacks |= b_attacks & ea.bbishopattacks
    b_attacks |= ea.bbishopattacks
    b_double_attacks |= b_attacks & ea.brookattacks
    b_attacks |= ea.brookattacks
    b_double_attacks |= b_attacks & ea.bqueenattacks
    b_attacks |= ea.bqueenattacks
    b_double_attacks |= b_attacks & ea.bkingattacks
    b_attacks |= ea.bkingattacks

    score = 0

    #=================== below are newer evaluation terms ==================#
    # if board.turn == WHITE
    #     weak = b_attacks & (~w_attacks | ea.wqueenattacks | ea.wkingattacks) & ~w_double_attacks
    # else
    #     weak = w_attacks & (~b_attacks | ea.bqueenattacks | ea.bkingattacks)
    # end


    #========================= Evaluation w.r.t. white ========================#
    # strongly protected by the enemy.
    strongly_protected = ea.bpawnattacks | (b_double_attacks & ~w_double_attacks)
    # well defended by the enemy
    defended = (board[BLACK] & ~pawns(board)) & strongly_protected
    # not well defended by the enemy
    weak = board[BLACK] & ~strongly_protected & w_attacks

    # Case where our opponent is hanging pieces
    case = ~b_attacks | ((board[BLACK] & ~pawns(board)) & w_double_attacks)
    # Bonus if opponent is hanging pieces
    score += HANGING_BONUS * count(weak & case)

    if !isempty(weak & ea.wkingattacks)
        score += THREAT_BY_KING
    end

    # Case where our opponent is defended or weak, and attacked by a bishop or knight.
    case = (defended | weak) & (ea.wknightattacks | ea.wbishopattacks)
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    score += THREAT_BY_MINOR[1] * case_pawns
    score += THREAT_BY_MINOR[2] * case_knights
    score += THREAT_BY_MINOR[3] * case_bishops
    score += THREAT_BY_MINOR[4] * case_rooks
    score += THREAT_BY_MINOR[5] * case_queens

    # Case where our opponent is weak and attacked by our rook
    case = weak & ea.wrookattacks
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    score += THREAT_BY_ROOK[1] * case_pawns
    score += THREAT_BY_ROOK[2] * case_knights
    score += THREAT_BY_ROOK[3] * case_bishops
    score += THREAT_BY_ROOK[4] * case_rooks
    score += THREAT_BY_ROOK[5] * case_queens

    safe = ~b_attacks | w_attacks
    case = pawns(board) & board[WHITE] & safe
    case = pawnCapturesWhite(case, board[BLACK] & ~pawns(board))
    score += THREAT_BY_PAWN * count(case)


    #========================= Evaluation w.r.t. black ========================#

    # strongly protected by the enemy.
    strongly_protected = ea.wpawnattacks | (w_double_attacks & ~b_double_attacks)
    # well defended by the enemy
    defended = (board[WHITE] & ~pawns(board)) & strongly_protected
    # not well defended by the enemy
    weak = board[WHITE] & ~strongly_protected & b_attacks

    # Case where our opponent is hanging pieces
    case = ~w_attacks | ((board[WHITE] & ~pawns(board)) & b_double_attacks)
    # Bonus if opponent is hanging pieces
    score -= HANGING_BONUS * count(weak & case)

    if !isempty(weak & ea.bkingattacks)
        score -= THREAT_BY_KING
    end

    # Case where our opponent is defended or weak, and attacked by a bishop or knight.
    case = (defended | weak) & (ea.bknightattacks | ea.bbishopattacks)
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    score -= THREAT_BY_MINOR[1] * case_pawns
    score -= THREAT_BY_MINOR[2] * case_knights
    score -= THREAT_BY_MINOR[3] * case_bishops
    score -= THREAT_BY_MINOR[4] * case_rooks
    score -= THREAT_BY_MINOR[5] * case_queens

    # Case where our opponent is weak and attacked by our rook
    case = weak & ea.brookattacks
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    score -= THREAT_BY_ROOK[1] * case_pawns
    score -= THREAT_BY_ROOK[2] * case_knights
    score -= THREAT_BY_ROOK[3] * case_bishops
    score -= THREAT_BY_ROOK[4] * case_rooks
    score -= THREAT_BY_ROOK[5] * case_queens

    safe = ~w_attacks | b_attacks
    case = pawns(board) & board[BLACK] & safe
    case = pawnCapturesBlack(case, board[WHITE] & ~pawns(board))
    score -= THREAT_BY_PAWN * count(case)


    score
end
