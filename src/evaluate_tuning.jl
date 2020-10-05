#====================== Auxilliary precomputation =============================#
"""
    EvalInfo

EvalInfo is an auxilliary data structure for storing useful computations for the evaluation of the board.
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

EvalAttackInfo is an auxilliary data structure for storing useful computations for the evaluation of the board.
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
    passed::Bitboard
end


function initEvalInfo(board::Board)
    # extract pawn positions
    wpawns = white(board) & pawns(board)
    bpawns = black(board) & pawns(board)

    # check for rammed pawns
    wrammedpawns = pawnAdvance(bpawns, wpawns, BLACK)
    brammedpawns = pawnAdvance(wpawns, bpawns, WHITE)


    # generate list of all positions attacked by a pawn
    wpawnattacks = pawnCapturesWhite(wpawns, FULL)
    bpawnattacks = pawnCapturesBlack(bpawns, FULL)

    # generate list of all positions attacked by a knight
    wknightattacks = bknightattacks = EMPTY
    wbishopattacks = bbishopattacks = EMPTY
    wrookattacks = brookattacks = EMPTY
    wqueenattacks = bqueenattacks = EMPTY
    wkingattacks = bkingattacks = EMPTY

    # mobility regions
    wmobility = ~((white(board) & kings(board)) | bpawnattacks)
    bmobility = ~((black(board) & kings(board)) | wpawnattacks)

    passed = EMPTY

    gamestage = stage(board)

    ei = EvalInfo(wrammedpawns, brammedpawns, wmobility, bmobility, gamestage)
    ea = EvalAttackInfo(wpawnattacks, wknightattacks, wbishopattacks, wrookattacks, wqueenattacks, wkingattacks, bpawnattacks, bknightattacks, bbishopattacks, brookattacks, bqueenattacks, bkingattacks, passed)
    ei, ea
end


#============================== Game stage functions ==========================#


function stage(board::Board)
    stage = 6156 - 1024count(queens(board)) - 512count(rooks(board)) - 256count(knights(board) | bishops(board))
    stage = fld(stage, 24)
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
    if (eval > 0) && (count(white(board)) == 2) && ismany(board[WHITEKNIGHT] | board[WHITEBISHOP])
        return SCALE_DRAW
    elseif (eval < 0) && (count(black(board)) == 2) && ismany(board[BLACKKNIGHT] | board[BLACKBISHOP])
        return SCALE_DRAW
    end
    return SCALE_NORMAL
end


#=============================== Main evaluation ==============================#


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board, pktable::PawnKingTable)
    ei, ea = initEvalInfo(board)

    score = 0
    score += board.psqteval

    # if (pkt_entry = getPKentry(pktable, board.pkhash)) !== PKT_BLANK
        # score += pkt_entry.score
        # ea.passed = pkt_entry.passed
    # else
        kpscore = 0
        kpscore += evaluate_pawns(board, ea)
        kpscore += evaluate_kingpawns(board, ea)
        # storePKentry!(pktable, board.pkhash, ea.passed, kpscore)
        score += kpscore
    # end

    v = fld(scoreEG(score) + scoreMG(score), 2)
    v = round(Int, v * (100.0 - Float64(board.halfmovecount)) / 100.0)
    # if abs(v) > LAZY_THRESH
    #     if board.turn == WHITE
    #         return v
    #     else
    #         return -v
    #     end
    # end

    score += evaluate_knights(board, ei, ea)
    score += evaluate_bishops(board, ei, ea)
    score += evaluate_rooks(board, ei, ea)
    score += evaluate_queens(board, ei, ea)
    score += evaluate_kings(board, ea)
    score += evaluate_pins(board)
    score += evaluate_space(board, ea)
    score += evaluate_threats(board, ei, ea)

    score += evaluate_passed(board, ea)

    score += evaluate_initiative(board, ea.passed, score)

    scale_f = scale_factor(board, scoreEG(score))

    eval = (256 - ei.stage) * scoreMG(score) + ei.stage * scoreEG(score) * fld(scale_f, SCALE_NORMAL)
    eval = fld(eval, 256)

    if board.turn == WHITE
        eval += TEMPO_BONUS#
        eval = round(Int, eval * (100.0 - Float64(board.halfmovecount)) / 100.0)
        return eval
    else
        eval -= TEMPO_BONUS
        eval = round(Int, eval * (100.0 - Float64(board.halfmovecount)) / 100.0)
        return -eval
    end
end

function evaluate(board::Board, pktable::PawnKingTable, params::Dict{String, Int})
    ei, ea = initEvalInfo(board)

    score = 0
    #score += board.psqteval
    pvals = [makescore(params["VAL_PAWN_MG"], params["VAL_PAWN_EG"]), makescore(params["VAL_KNIGHT_MG"], params["VAL_KNIGHT_EG"]), makescore(params["VAL_BISHOP_MG"], params["VAL_BISHOP_EG"]),
        makescore(params["VAL_ROOK_MG"], params["VAL_ROOK_EG"]), makescore(params["VAL_QUEEN_MG"], params["VAL_QUEEN_EG"]), makescore(15000, 15000)]

    for (sqr, piece) in enumerate(board.squares)
        if piece !== BLANK
            pt = type(piece)
            col = color(piece)
            factor = 1
            if col == BLACK
                sqr = 65 - sqr
                factor = -1
            end
            @inbounds file = FILE_TO_QSIDE_MAP[fileof(sqr)]
            rank = rankof(sqr)
            @inbounds score += (PSQT[pt.val][rank][file] + pvals[pt.val]) * factor
        end
    end

    kpscore = 0
    kpscore += evaluate_pawns(board, ea, params)
    kpscore += evaluate_kingpawns(board, ea)

    score += kpscore

    v = fld(scoreEG(score) + scoreMG(score), 2)
    v = round(Int, v * (100.0 - Float64(board.halfmovecount)) / 100.0)

    score += evaluate_knights(board, ei, ea, params)
    score += evaluate_bishops(board, ei, ea, params)
    score += evaluate_rooks(board, ei, ea, params)
    score += evaluate_queens(board, ei, ea)
    score += evaluate_kings(board, ea)
    score += evaluate_pins(board, params)
    score += evaluate_space(board, ea, params)
    score += evaluate_threats(board, ei, ea, params)

    score += evaluate_passed(board, ea)

    score += evaluate_initiative(board, ea.passed, score)

    scale_f = scale_factor(board, scoreEG(score))

    eval = (256 - ei.stage) * scoreMG(score) + ei.stage * scoreEG(score) * fld(scale_f, SCALE_NORMAL)
    eval = fld(eval, 256)

    if board.turn == WHITE
        eval += TEMPO_BONUS#
        eval = round(Int, eval * (100.0 - Float64(board.halfmovecount)) / 100.0)
        return eval
    else
        eval -= TEMPO_BONUS
        eval = round(Int, eval * (100.0 - Float64(board.halfmovecount)) / 100.0)
        return -eval
    end
end


function evaluate_pawns(board::Board, ea::EvalAttackInfo, params::Dict{String, Int})

    w_pawns = white(board) & pawns(board)
    b_pawns = black(board) & pawns(board)

    w_king = square(white(board) & kings(board))
    b_king = square(black(board) & kings(board))

    score = 0

    @inbounds for pawn in w_pawns
        file = fileof(pawn)
        rank = rankof(pawn)
        blocked    = b_pawns & (Bitboard(pawn) << 8)
        stoppers   = b_pawns & PASSED_PAWN_MASKS[1][pawn]
        opposed    = stoppers & FILE[file]
        lever      = b_pawns & PAWN_CAPTURES_WHITE[pawn]
        leverpush  = b_pawns & PAWN_CAPTURES_WHITE[pawn + 8]
        doubled    = !isempty(w_pawns & (Bitboard(pawn) >> 8))
        neighbours = w_pawns & NEIGHBOUR_FILE_MASKS[file]
        phalanx    = neighbours & RANK[rank]
        support    = neighbours & RANK[rank - 1]

        # Passed pawns
        if isempty(stoppers)
            ea.passed |= Bitboard(pawn)
        end

        # Backward pawns
        backward = isempty(neighbours & PASSED_PAWN_MASKS[2][pawn - 8] & FILE[file]) && !isempty(leverpush | blocked)

        # file mapping
        file_psqt = FILE_TO_QSIDE_MAP[file]

        # Connected pawns
        if !isempty(support) || !isempty(phalanx)
            score += CONNECTED_PAWN_PSQT[rank][file_psqt]

        # Isolated pawns
        elseif isempty(neighbours)
            score -= makescore(params["ISOLATED_PAWN_PENALTY_MG"], params["ISOLATED_PAWN_PENALTY_EG"]) + makescore(params["WEAK_UNOPPOSED_MG"], params["WEAK_UNOPPOSED_EG"]) * isempty(opposed)

        # Backward pawns
        elseif backward
            score -= makescore(params["BACKWARD_PAWN_MG"], params["BACKWARD_PAWN_EG"]) + makescore(params["WEAK_UNOPPOSED_MG"], params["WEAK_UNOPPOSED_EG"]) * isempty(opposed)
        end

        # Doubled pawns
        if isempty(support)
            score -= makescore(params["DOUBLE_PAWN_PENALTY_MG"], params["DOUBLE_PAWN_PENALTY_EG"]) * doubled + makescore(params["WEAK_LEVER_MG"], params["WEAK_LEVER_EG"]) * ismany(lever)
        end
    end

    @inbounds for pawn in b_pawns
        file = fileof(pawn)
        rank = rankof(pawn)
        blocked    = w_pawns & (Bitboard(pawn) >> 8)
        stoppers   = w_pawns & PASSED_PAWN_MASKS[2][pawn]
        opposed    = stoppers & FILE[file]
        lever      = w_pawns & PAWN_CAPTURES_BLACK[pawn]
        leverpush  = w_pawns & PAWN_CAPTURES_BLACK[pawn - 8]
        doubled    = !isempty(b_pawns & (Bitboard(pawn) << 8))
        neighbours = b_pawns & NEIGHBOUR_FILE_MASKS[file]
        phalanx    = neighbours & RANK[rank]
        support    = neighbours & RANK[rank + 1]

        # Passed pawns
        if isempty(stoppers)
            ea.passed |= Bitboard(pawn)
        end

        # Backward pawns
        backward = isempty(neighbours & PASSED_PAWN_MASKS[1][pawn + 8] & FILE[file]) && !isempty(leverpush | blocked)

        # file mapping
        file_psqt = FILE_TO_QSIDE_MAP[file]

        # Connected pawns
        if !isempty(support) || !isempty(phalanx)
            score -= CONNECTED_PAWN_PSQT[9 - rank][file_psqt]

        # Isolated pawns
        elseif isempty(neighbours)
            score += makescore(params["ISOLATED_PAWN_PENALTY_MG"], params["ISOLATED_PAWN_PENALTY_EG"]) + makescore(params["WEAK_UNOPPOSED_MG"], params["WEAK_UNOPPOSED_EG"]) * isempty(opposed)

        # Backward pawns
        elseif backward
            score += makescore(params["BACKWARD_PAWN_MG"], params["BACKWARD_PAWN_EG"]) + makescore(params["WEAK_UNOPPOSED_MG"], params["WEAK_UNOPPOSED_EG"]) * isempty(opposed)
        end

        # Doubled pawns
        if isempty(support)
            score += makescore(params["DOUBLE_PAWN_PENALTY_MG"], params["DOUBLE_PAWN_PENALTY_EG"]) * doubled + makescore(params["WEAK_LEVER_MG"], params["WEAK_LEVER_EG"]) * ismany(lever)
        end
    end

    if isempty(pawns(board) & KINGFLANK[fileof(w_king)])
        score -= makescore(params["PAWNLESS_FLANK_MG"], params["PAWNLESS_FLANK_EG"])
    end
    if isempty(pawns(board) & KINGFLANK[fileof(b_king)])
        score += makescore(params["PAWNLESS_FLANK_MG"], params["PAWNLESS_FLANK_EG"])
    end

    return score
end


function evaluate_knights(board::Board, ei::EvalInfo, ea::EvalAttackInfo, params::Dict{String, Int})
    w_knights = white(board) & knights(board)
    b_knights = black(board) & knights(board)

    w_pawns = pawns(board) & white(board)
    b_pawns = pawns(board) & black(board)

    w_king_sqr = square(kings(board) & white(board))
    b_king_sqr = square(kings(board) & black(board))

    score = 0

    w_outposts = (RANK_4 | RANK_5 | RANK_6) & ea.wpawnattacks & ~ea.bpawnattacks
    @inbounds for knight in w_knights
        attacks = knightMoves(knight)
        ea.wknightattacks |= attacks
        score += KNIGHT_MOBILITY[count(attacks & ei.wmobility) + 1]
        score -= MINOR_KING_PROTECTION * DISTANCE_BETWEEN[w_king_sqr, knight]
    end

    # Score knight outposts
    score += count(w_outposts & w_knights) * makescore(params["KNIGHT_OUTPOST_BONUS_MG"], params["KNIGHT_OUTPOST_BONUS_EG"])

    # Score reachable knight outposts
    score += count(w_outposts & ea.wknightattacks & ~white(board)) * makescore(params["KNIGHT_POTENTIAL_OUTPOST_BONUS_MG"], params["KNIGHT_POTENTIAL_OUTPOST_BONUS_EG"])

    # Score knights behind pawns
    score += count((w_knights << 8) & w_pawns) * makescore(params["PAWN_SHIELD_BONUS_MG"], params["PAWN_SHIELD_BONUS_EG"])


    b_outposts = (RANK_3 | RANK_4 | RANK_5) & ~ea.wpawnattacks & ea.bpawnattacks
    @inbounds for knight in b_knights
        attacks = knightMoves(knight)
        ea.bknightattacks |= attacks
        score -= KNIGHT_MOBILITY[count(attacks & ei.bmobility) + 1]
        score += MINOR_KING_PROTECTION * DISTANCE_BETWEEN[b_king_sqr, knight]
    end

    # Score knight outposts
    score -= count(b_outposts & b_knights) * makescore(params["KNIGHT_OUTPOST_BONUS_MG"], params["KNIGHT_OUTPOST_BONUS_EG"])

    # Score reachable knight outposts
    score -= count(b_outposts & ea.bknightattacks & ~black(board)) * makescore(params["KNIGHT_POTENTIAL_OUTPOST_BONUS_MG"], params["KNIGHT_POTENTIAL_OUTPOST_BONUS_EG"])

    # Score knights behind pawns
    score -= count((b_knights >> 8) & b_pawns) * makescore(params["PAWN_SHIELD_BONUS_MG"], params["PAWN_SHIELD_BONUS_EG"])

    # bonus for knights in rammed positions
    num2_rammed = count(ei.wrammedpawns)^2
    score += div(count(w_knights) * num2_rammed, 4) * makescore(params["KNIGHT_RAMMED_BONUS_MG"], params["KNIGHT_RAMMED_BONUS_EG"])
    score -= div(count(b_knights) * num2_rammed, 4) * makescore(params["KNIGHT_RAMMED_BONUS_MG"], params["KNIGHT_RAMMED_BONUS_EG"])

    score
end


function evaluate_bishops(board::Board, ei::EvalInfo, ea::EvalAttackInfo, params::Dict{String, Int})
    w_bishops = white(board) & bishops(board)
    b_bishops = black(board) & bishops(board)

    w_pawns = pawns(board) & white(board)
    b_pawns = pawns(board) & black(board)

    w_king_sqr = square(kings(board) & white(board))
    b_king_sqr = square(kings(board) & black(board))

    score = 0

    attacks = EMPTY
    occ = occupied(board)

    w_outposts = (RANK_4 | RANK_5 | RANK_6) & ea.wpawnattacks & ~ea.bpawnattacks
    @inbounds for bishop in w_bishops
        attacks = bishopMoves(bishop, occ)
        ea.wbishopattacks |= attacks
        score += BISHOP_MOBILITY[count(attacks & ei.wmobility) + 1]
        if ismany(attacks & CENTRAL_SQUARES)
            score += makescore(params["BISHOP_CENTRAL_CONTROL_MG"], params["BISHOP_CENTRAL_CONTROL_EG"])
        end
        score -= MINOR_KING_PROTECTION * DISTANCE_BETWEEN[w_king_sqr, bishop]
    end

    # Outpost bonus
    score += count(w_outposts & w_bishops) * makescore(params["BISHOP_OUTPOST_BONUS_MG"], params["BISHOP_OUTPOST_BONUS_EG"])

    # Add a bonus for being behind a pawn.
    score += count((w_bishops << 8) & w_pawns) * makescore(params["PAWN_SHIELD_BONUS_MG"], params["PAWN_SHIELD_BONUS_EG"])


    b_outposts = (RANK_3 | RANK_4 | RANK_5) & ~ea.wpawnattacks & ea.bpawnattacks
    @inbounds for bishop in b_bishops
        attacks = bishopMoves(bishop, occ)
        ea.bbishopattacks |= attacks
        score -= BISHOP_MOBILITY[count(attacks & ei.bmobility) + 1]
        if ismany(attacks & CENTRAL_SQUARES)
            score -= makescore(params["BISHOP_CENTRAL_CONTROL_MG"], params["BISHOP_CENTRAL_CONTROL_EG"])
        end
        score += MINOR_KING_PROTECTION * DISTANCE_BETWEEN[b_king_sqr, bishop]
    end

    # Outpost bonus
    score -= count(b_outposts & b_bishops) * makescore(params["BISHOP_OUTPOST_BONUS_MG"], params["BISHOP_OUTPOST_BONUS_EG"])

    # Add a bonus for being behind a pawn
    score -= count((b_bishops >> 8) & b_pawns) * makescore(params["PAWN_SHIELD_BONUS_MG"], params["PAWN_SHIELD_BONUS_EG"])

    # bishop pair
    if count(w_bishops) >= 2
        score += makescore(params["BISHOP_CENTRAL_CONTROL_MG"], params["BISHOP_CENTRAL_CONTROL_EG"])
    end
    if count(b_bishops) >= 2
        score -= makescore(params["BISHOP_PAIR_BONUS_MG"], params["BISHOP_PAIR_BONUS_EG"])
    end

    # penalty for bishops on colour of own pawns
    if !isempty(w_bishops & LIGHT)
        score -= BISHOP_COLOR_PENALTY * count(w_pawns & LIGHT)
        score -= BISHOP_RAMMED_COLOR_PENALTY * count(ei.wrammedpawns & LIGHT)
    end
    if !isempty(w_bishops & DARK)
        score -= BISHOP_COLOR_PENALTY * count(w_pawns & DARK)
        score -= BISHOP_RAMMED_COLOR_PENALTY * count(ei.wrammedpawns & DARK)
    end
    if !isempty(b_bishops & LIGHT)
        score += BISHOP_COLOR_PENALTY * count(b_pawns & LIGHT)
        score += BISHOP_RAMMED_COLOR_PENALTY * count(ei.brammedpawns & LIGHT)
    end
    if !isempty(b_bishops & DARK)
        score += BISHOP_COLOR_PENALTY * count(b_pawns & DARK)
        score += BISHOP_RAMMED_COLOR_PENALTY * count(ei.brammedpawns & DARK)
    end

    score
end



function evaluate_rooks(board::Board, ei::EvalInfo, ea::EvalAttackInfo, params::Dict{String, Int})
    w_rooks = (white(board) & rooks(board))
    b_rooks = (black(board) & rooks(board))

    score = 0

    occ = occupied(board)
    @inbounds for rook in w_rooks
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            score += makescore(params["ROOK_OPEN_FILE_BONUS_MG"], params["ROOK_OPEN_FILE_BONUS_EG"])
        elseif isempty(rfile & white(board) & pawns(board))
            score += makescore(params["ROOK_SEMIOPEN_FILE_BONUS_MG"], params["ROOK_SEMIOPEN_FILE_BONUS_EG"])
        end
        if !isempty(rfile & queens(board))
            score += makescore(params["ROOK_ON_QUEEN_FILE_MG"], params["ROOK_ON_QUEEN_FILE_EG"])
        end
        attacks = rookMoves(rook, occ)
        ea.wrookattacks |= attacks
        mob_cnt = count(attacks & ei.wmobility) + 1
        score += ROOK_MOBILITY[mob_cnt]
    end

    @inbounds for rook in b_rooks
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            score -= makescore(params["ROOK_OPEN_FILE_BONUS_MG"], params["ROOK_OPEN_FILE_BONUS_EG"])
        elseif isempty(rfile & black(board) & pawns(board))
            score -= makescore(params["ROOK_SEMIOPEN_FILE_BONUS_MG"], params["ROOK_SEMIOPEN_FILE_BONUS_EG"])
        end
        if !isempty(rfile & queens(board))
            score -= makescore(params["ROOK_ON_QUEEN_FILE_MG"], params["ROOK_ON_QUEEN_FILE_EG"])
        end
        attacks = rookMoves(rook, occ)
        ea.brookattacks |= attacks
        mob_cnt = count(attacks & ei.bmobility) + 1
        score -= ROOK_MOBILITY[mob_cnt]
    end

    score
end


function evaluate_queens(board::Board, ei::EvalInfo, ea::EvalAttackInfo)
    w_queens = board[WHITEQUEEN]
    b_queens = board[BLACKQUEEN]

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

    score
end


function evaluate_kings(board::Board, ea::EvalAttackInfo)
    w_king = white(board) & kings(board)
    b_king = black(board) & kings(board)
    w_king_sqr = square(w_king)
    b_king_sqr = square(b_king)
    ea.wkingattacks |= kingMoves(w_king_sqr)
    ea.bkingattacks |= kingMoves(b_king_sqr)

    score = 0

    if cancastlekingside(board, WHITE)
        score += CASTLE_OPTION_BONUS
    end
    if cancastlequeenside(board, WHITE)
        score += CASTLE_OPTION_BONUS
    end
    if cancastlekingside(board, BLACK)
        score -= CASTLE_OPTION_BONUS
    end
    if cancastlequeenside(board, BLACK)
        score -= CASTLE_OPTION_BONUS
    end

    score
end


function evaluate_kingpawns(board::Board, ea::EvalAttackInfo)
    w_king = white(board) & kings(board)
    b_king = black(board) & kings(board)
    w_king_sqr = square(w_king)
    b_king_sqr = square(b_king)

    score = 0

    wkingfile = fileof(w_king_sqr)
    lower = max(1, wkingfile - 1)
    upper = min(8, wkingfile + 1)
    _wpawns = pawns(board) & white(board) & PASSED_PAWN_MASKS[1][w_king_sqr]
    _bpawns = pawns(board) & black(board) & PASSED_PAWN_MASKS[1][w_king_sqr]
    wksqr = rankof(w_king_sqr)
    @inbounds for file in lower:upper
        wpawns = _wpawns & FILE[file]
        if isempty(wpawns)
            w_dist = 8
        else
            w_dist = abs(wksqr - rankof(trailing_zeros(wpawns.val)+1))
        end

        bpawns = _bpawns & FILE[file]
        if isempty(bpawns)
            b_dist = 8
        else
            b_dist = abs(wksqr - rankof(trailing_zeros(bpawns.val)+1))
        end

        if file === wkingfile
            score += KING_SHELTER_ONFILE[file][w_dist]
        else
            score += KING_SHELTER_OFFFILE[file][w_dist]
        end

        blocked = (b_dist !== 8) && (w_dist === b_dist - 1)
        fmap = FILE_TO_QSIDE_MAP[file]
        if blocked
            score += KING_STORM_BLOCKED[fmap][b_dist]
        else
            score += KING_STORM_UNBLOCKED[fmap][b_dist]
        end
    end

    bkingfile = fileof(b_king_sqr)
    lower = max(1, bkingfile - 1)
    upper = min(8, bkingfile + 1)
    _bpawns = pawns(board) & black(board) & PASSED_PAWN_MASKS[2][b_king_sqr]
    _wpawns = pawns(board) & white(board) & PASSED_PAWN_MASKS[2][b_king_sqr]
    bksqr = rankof(b_king_sqr)
    @inbounds for file in lower:upper
        bpawns = _bpawns & FILE[file]
        if isempty(bpawns)
            b_dist = 8
        else
            b_dist = abs(bksqr - rankof(64-leading_zeros(bpawns.val)))
        end

        wpawns = _wpawns & FILE[file]
        if isempty(wpawns)
            w_dist = 8
        else
            w_dist = abs(bksqr - rankof(64-leading_zeros(wpawns.val)))
        end

        if file === bkingfile
            score -= KING_SHELTER_ONFILE[file][b_dist]
        else
            score -= KING_SHELTER_OFFFILE[file][b_dist]
        end

        blocked = (w_dist !== 8) && (b_dist === w_dist - 1)
        fmap = FILE_TO_QSIDE_MAP[file]
        if blocked
            score -= KING_STORM_BLOCKED[fmap][w_dist]
        else
            score -= KING_STORM_UNBLOCKED[fmap][w_dist]
        end
    end

    score
end


function evaluate_pins(board::Board, params::Dict{String, Int})
    eval = 0

    # switch turn and find all pins
    board.turn = !board.turn
    opp_pinned = findpins(board)
    board.turn = !board.turn

    if board.turn == WHITE
        eval -= count(board.pinned)
        eval += count(opp_pinned)
    else
        eval += count(board.pinned)
        eval -= count(opp_pinned)
    end

    eval *= params["PIN_BONUS"]

    # specific additional pin bonus
    eval -= count(pinned(board) & queens(board)) * 30
    eval += count(opp_pinned & queens(board)) * 30
    eval -= count(pinned(board) & rooks(board)) * 10
    eval += count(opp_pinned & rooks(board)) * 10

    makescore(eval, eval)
end


function evaluate_space(board::Board, ea::EvalAttackInfo, params::Dict{String, Int})
    eval = 0

    w_filter = (RANK_2 | RANK_3 | RANK_4) & CENTERFILES
    b_filter = (RANK_5 | RANK_6 | RANK_7) & CENTERFILES
    w_attacks = ea.wpawnattacks | ea.wknightattacks | ea.wbishopattacks | ea.wrookattacks | ea.wqueenattacks | ea.wkingattacks
    b_attacks = ea.bpawnattacks | ea.bknightattacks | ea.bbishopattacks | ea.brookattacks | ea.bqueenattacks | ea.bkingattacks
    eval += count(w_filter & ~b_attacks)
    eval -= count(b_filter & ~w_attacks)
    eval *= params["SPACE_BONUS"]

    makescore(eval, eval)
end


function evaluate_threats(board::Board, ei::EvalInfo, ea::EvalAttackInfo, params::Dict{String, Int})
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

    occ = occupied(board)

    score = 0

    #========================= Evaluation w.r.t. white ========================#
    # strongly protected by the enemy.
    strongly_protected = ea.bpawnattacks | (b_double_attacks & ~w_double_attacks)
    # well defended by the enemy
    defended = (black(board) & ~pawns(board)) & strongly_protected
    # not well defended by the enemy
    weak = black(board) & ~strongly_protected & w_attacks

    # Case where our opponent is hanging pieces
    case = ~b_attacks | ((black(board) & ~pawns(board)) & w_double_attacks)
    # Bonus if opponent is hanging pieces
    score += makescore(params["HANGING_BONUS_MG"], params["HANGING_BONUS_EG"]) * count(weak & case)

    if !isempty(weak & ea.wkingattacks)
        score += makescore(params["THREAT_BY_KING_MG"], params["THREAT_BY_KING_EG"])
    end

    # Case where our opponent is defended or weak, and attacked by a bishop or knight.
    case = (defended | weak) & (ea.wknightattacks | ea.wbishopattacks)
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    @inbounds score += makescore(params["THREAT_BY_MINOR_1_MG"], params["THREAT_BY_MINOR_1_EG"]) * case_pawns
    @inbounds score += makescore(params["THREAT_BY_MINOR_2_MG"], params["THREAT_BY_MINOR_2_EG"]) * case_knights
    @inbounds score += makescore(params["THREAT_BY_MINOR_3_MG"], params["THREAT_BY_MINOR_3_EG"]) * case_bishops
    @inbounds score += makescore(params["THREAT_BY_MINOR_4_MG"], params["THREAT_BY_MINOR_4_EG"]) * case_rooks
    @inbounds score += makescore(params["THREAT_BY_MINOR_5_MG"], params["THREAT_BY_MINOR_5_EG"]) * case_queens

    # Case where our opponent is weak and attacked by our rook
    case = weak & ea.wrookattacks
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    @inbounds score += makescore(params["THREAT_BY_ROOK_1_MG"], params["THREAT_BY_ROOK_1_EG"]) * case_pawns
    @inbounds score += makescore(params["THREAT_BY_ROOK_2_MG"], params["THREAT_BY_ROOK_2_EG"]) * case_knights
    @inbounds score += makescore(params["THREAT_BY_ROOK_3_MG"], params["THREAT_BY_ROOK_3_EG"]) * case_bishops
    @inbounds score += makescore(params["THREAT_BY_ROOK_4_MG"], params["THREAT_BY_ROOK_4_EG"]) * case_rooks
    @inbounds score += makescore(params["THREAT_BY_ROOK_5_MG"], params["THREAT_BY_ROOK_5_EG"]) * case_queens

    # Case where we get a bonus for restricting our opponent
    case = b_attacks & ~strongly_protected & w_attacks
    score += count(case) * makescore(params["RESTRICTION_BONUS_MG"], params["RESTRICTION_BONUS_EG"])

    # Find squares which are safe
    safe = ~b_attacks | w_attacks

    # Case where we have safe pawn attacks
    case = pawns(board) & white(board) & safe
    case = pawnCapturesWhite(case, black(board) & ~pawns(board))
    score += makescore(params["THREAT_BY_PAWN_MG"], params["THREAT_BY_PAWN_EG"]) * count(case)

    # Case threat by pawn push
    case = pawnAdvance(white(board) & pawns(board), empty(board), WHITE)
    case |= pawnDoubleAdvance(white(board) & pawns(board), empty(board), WHITE)
    case &= ~ea.bpawnattacks & safe
    case = pawnCapturesWhite(case, black(board) & ~pawns(board))
    score += makescore(params["THREAT_BY_PUSH_MG"], params["THREAT_BY_PUSH_EG"]) * count(case)

    # Evaluate if there are pieces that can reach a checking square, while being safe.
    # King Danger evaluations.
    # As WHITE, we are seeing how in danger the BLACK king is.
    b_king_sqr = square(black(board) & kings(board))
    b_king_box = ea.bkingattacks | Bitboard(b_king_sqr)
    safe = ~white(board) & (~b_attacks | (weak & w_double_attacks))
    king_bishop_moves = bishopMoves(b_king_sqr, occ)
    king_rook_moves = rookMoves(b_king_sqr, occ)
    king_knight_moves = knightMoves(b_king_sqr)
    knightcheck_sqrs = king_knight_moves & safe & ea.wknightattacks
    rookcheck_sqrs   = king_rook_moves & safe & ea.wrookattacks
    # Remove rook checks from queen checks, because they are more valuable.
    # Don't count if queens trade.
    queencheck_sqrs  = (king_rook_moves | king_bishop_moves) & safe & ea.wqueenattacks & ~rookcheck_sqrs & ~ea.bqueenattacks
    # Remove queen checks from bishop checks, because they are more valuable.
    bishopcheck_sqrs = king_bishop_moves & safe & ea.wbishopattacks & ~queencheck_sqrs

    king_danger = 0
    unsafechecks = EMPTY
    if !isempty(knightcheck_sqrs)
        king_danger += params["KNIGHT_SAFE_CHECK"]
    else
        unsafechecks |= king_knight_moves & ea.wknightattacks
    end
    if !isempty(bishopcheck_sqrs)
        king_danger += params["BISHOP_SAFE_CHECK"]
    else
        unsafechecks |= king_bishop_moves & ea.wbishopattacks
    end
    if !isempty(rookcheck_sqrs)
        king_danger += params["ROOK_SAFE_CHECK"]
    else
        unsafechecks |= king_rook_moves & ea.wrookattacks
    end
    if !isempty(queencheck_sqrs)
        king_danger += params["QUEEN_SAFE_CHECK"]
    end
    if isempty(board[WHITEQUEEN])
        king_danger -= params["KD_QUEEN"]
    end
    if isempty(board[WHITEROOK])
        king_danger -= params["KD_ROOK"]
    end
    if isempty(board[WHITEBISHOP])
        king_danger -= params["KD_BISHOP"]
    end
    if isempty(board[WHITEKNIGHT])
        king_danger -= params["KD_KNIGHT"]
    end
    king_danger += 9 * count(w_attacks & ea.bkingattacks)
    if king_danger > 0
        score += makescore(king_danger, fld(king_danger, 2))
    end

    # Score the number of attacks on the king's flank
    camp = FULL ⊻ RANK_1 ⊻ RANK_2 ⊻ RANK_3
    black_king_flank = KINGFLANK[fileof(b_king_sqr)]
    king_flank_attacks = w_attacks & black_king_flank & camp
    king_flank_double_attacks = king_flank_attacks & w_double_attacks
    score += (count(king_flank_attacks) + count(king_flank_double_attacks)) * makescore(params["KING_FLANK_ATTACK_MG"], params["KING_FLANK_ATTACK_EG"])
    king_flank_defence = b_attacks & black_king_flank & camp
    score -= count(king_flank_defence) * makescore(params["KING_FLANK_DEFEND_MG"], params["KING_FLANK_DEFEND_EG"])

    # King ring attack bonus
    score += count(b_king_box & weak)^2 * makescore(params["KING_BOX_WEAK_MG"], params["KING_BOX_WEAK_EG"])
    score += count(unsafechecks)^2 * makescore(params["UNSAFE_CHECK_MG"], params["UNSAFE_CHECK_EG"])

    # Threats on black queen
    black_queens = black(board) & queens(board)
    if isone(black_queens)
        safe = ei.wmobility & ~strongly_protected
        case = ea.wknightattacks & knightMoves(square(black_queens)) & safe
        score += count(case) * KNIGHT_ON_QUEEN
    end


    #========================= Evaluation w.r.t. black ========================#

    # strongly protected by the enemy.
    strongly_protected = ea.wpawnattacks | (w_double_attacks & ~b_double_attacks)
    # well defended by the enemy
    defended = (white(board) & ~pawns(board)) & strongly_protected
    # not well defended by the enemy
    weak = white(board) & ~strongly_protected & b_attacks

    # Case where our opponent is hanging pieces
    case = ~w_attacks | ((white(board) & ~pawns(board)) & b_double_attacks)
    # Bonus if opponent is hanging pieces
    score -= makescore(params["HANGING_BONUS_MG"], params["HANGING_BONUS_EG"]) * count(weak & case)

    if !isempty(weak & ea.bkingattacks)
        score -= makescore(params["THREAT_BY_KING_MG"], params["THREAT_BY_KING_EG"])
    end

    # Case where our opponent is defended or weak, and attacked by a bishop or knight.
    case = (defended | weak) & (ea.bknightattacks | ea.bbishopattacks)
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    @inbounds score -= makescore(params["THREAT_BY_MINOR_1_MG"], params["THREAT_BY_MINOR_1_EG"]) * case_pawns
    @inbounds score -= makescore(params["THREAT_BY_MINOR_2_MG"], params["THREAT_BY_MINOR_2_EG"]) * case_knights
    @inbounds score -= makescore(params["THREAT_BY_MINOR_3_MG"], params["THREAT_BY_MINOR_3_EG"]) * case_bishops
    @inbounds score -= makescore(params["THREAT_BY_MINOR_4_MG"], params["THREAT_BY_MINOR_4_EG"]) * case_rooks
    @inbounds score -= makescore(params["THREAT_BY_MINOR_5_MG"], params["THREAT_BY_MINOR_5_EG"]) * case_queens

    # Case where our opponent is weak and attacked by our rook
    case = weak & ea.brookattacks
    case_pawns = count(case & pawns(board))
    case_knights = count(case & knights(board))
    case_bishops = count(case & bishops(board))
    case_rooks = count(case & rooks(board))
    case_queens = count(case & queens(board))
    @inbounds score -= makescore(params["THREAT_BY_ROOK_1_MG"], params["THREAT_BY_ROOK_1_EG"]) * case_pawns
    @inbounds score -= makescore(params["THREAT_BY_ROOK_2_MG"], params["THREAT_BY_ROOK_2_EG"]) * case_knights
    @inbounds score -= makescore(params["THREAT_BY_ROOK_3_MG"], params["THREAT_BY_ROOK_3_EG"]) * case_bishops
    @inbounds score -= makescore(params["THREAT_BY_ROOK_4_MG"], params["THREAT_BY_ROOK_4_EG"]) * case_rooks
    @inbounds score -= makescore(params["THREAT_BY_ROOK_5_MG"], params["THREAT_BY_ROOK_5_EG"]) * case_queens

    # Case where we get a bonus for restricting our opponent
    case = b_attacks & ~strongly_protected & w_attacks
    score -= count(case) * makescore(params["RESTRICTION_BONUS_MG"], params["RESTRICTION_BONUS_EG"])

    # Case threat by pawn
    safe = ~w_attacks | b_attacks
    case = pawns(board) & black(board) & safe
    case = pawnCapturesBlack(case, white(board) & ~pawns(board))
    score -= makescore(params["THREAT_BY_PAWN_MG"], params["THREAT_BY_PAWN_EG"]) * count(case)

    # Case threat by pawn push
    case = pawnAdvance(black(board) & pawns(board), empty(board), BLACK)
    case |= pawnDoubleAdvance(black(board) & pawns(board), empty(board), BLACK)
    case &= ~ea.wpawnattacks & safe
    case = pawnCapturesBlack(case, white(board) & ~pawns(board))
    score -= makescore(params["THREAT_BY_PUSH_MG"], params["THREAT_BY_PUSH_EG"]) * count(case)

    # Evaluate if there are pieces that can reach a checking square, while being safe.
    # King Danger evaluations.
    # As BLACK, we are seeing how in danger the WHITE king is.
    w_king_sqr = square(white(board) & kings(board))
    w_king_box = ea.wkingattacks | Bitboard(w_king_sqr)
    safe = ~black(board) & (~w_attacks | (weak & b_double_attacks))
    king_bishop_moves = bishopMoves(w_king_sqr, occ)
    king_rook_moves = rookMoves(w_king_sqr, occ)
    king_knight_moves = knightMoves(w_king_sqr)
    knightcheck_sqrs = king_knight_moves & safe & ea.bknightattacks
    rookcheck_sqrs   = king_rook_moves & safe & ea.brookattacks
    # Remove rook checks from queen checks, because they are more valuable.
    # Don't count if queens trade.
    queencheck_sqrs  = (king_rook_moves | king_bishop_moves) & safe & ea.bqueenattacks & ~rookcheck_sqrs & ~ea.wqueenattacks
    # Remove queen checks from bishop checks, because they are more valuable.
    bishopcheck_sqrs = king_bishop_moves & safe & ea.bbishopattacks & ~queencheck_sqrs

    king_danger = 0
    unsafechecks = EMPTY
    if !isempty(knightcheck_sqrs)
        king_danger += params["KNIGHT_SAFE_CHECK"]
    else
        unsafechecks |= king_knight_moves & ea.bknightattacks
    end
    if !isempty(bishopcheck_sqrs)
        king_danger += params["BISHOP_SAFE_CHECK"]
    else
        unsafechecks |= king_bishop_moves & ea.bbishopattacks
    end
    if !isempty(rookcheck_sqrs)
        king_danger += params["ROOK_SAFE_CHECK"]
    else
        unsafechecks |= king_rook_moves & ea.brookattacks
    end
    if !isempty(queencheck_sqrs)
        king_danger += params["QUEEN_SAFE_CHECK"]
    end
    if isempty(board[BLACKQUEEN])
        king_danger -= params["KD_QUEEN"]
    end
    if isempty(board[BLACKROOK])
        king_danger -= params["KD_ROOK"]
    end
    if isempty(board[BLACKBISHOP])
        king_danger -= params["KD_BISHOP"]
    end
    if isempty(board[BLACKKNIGHT])
        king_danger -= params["KD_KNIGHT"]
    end
    king_danger += 9 * count(b_attacks & ea.wkingattacks)
    if king_danger > 0
        score -= makescore(king_danger, fld(king_danger, 2))
    end

    # Count king flank attacks
    camp = (FULL ⊻ RANK_8 ⊻ RANK_7 ⊻ RANK_6)
    white_king_flank = KINGFLANK[fileof(w_king_sqr)]
    king_flank_attacks = b_attacks & white_king_flank & camp
    king_flank_double_attacks = king_flank_attacks & b_double_attacks
    score -= (count(king_flank_attacks) + count(king_flank_double_attacks)) * makescore(params["KING_FLANK_ATTACK_MG"], params["KING_FLANK_ATTACK_EG"])
    king_flank_defence = w_attacks & white_king_flank & camp
    score += count(king_flank_defence) * makescore(params["KING_FLANK_DEFEND_MG"], params["KING_FLANK_DEFEND_EG"])

    # King ring attack bonus
    score -= count(w_king_box & weak)^2 * makescore(params["KING_BOX_WEAK_MG"], params["KING_BOX_WEAK_EG"])
    score -= count(unsafechecks)^2 * makescore(params["UNSAFE_CHECK_MG"], params["UNSAFE_CHECK_EG"])

    # Attacks on white queen
    white_queens = white(board) & queens(board)
    if isone(white_queens)
        safe = ei.bmobility & ~strongly_protected
        case = ea.bknightattacks & knightMoves(square(white_queens)) & safe
        score -= count(case) * KNIGHT_ON_QUEEN
    end

    score
end


function evaluate_initiative(board::Board, passed::Bitboard, score::Int)
    eg = scoreEG(score)
    mg = scoreMG(score)
    black_king = square(kings(board) & black(board))
    white_king = square(kings(board) & white(board))
    black_king_rank = rankof(black_king)
    white_king_rank = rankof(white_king)
    black_king_file = fileof(black_king)
    white_king_file = fileof(white_king)

    outflank = abs(white_king_file - black_king_file) - abs(white_king_rank - black_king_rank)

    infiltrating = (white_king_rank > 4) || (black_king_rank < 5)

    pawns_both_flanks = !isempty(pawns(board) & KINGSIDE) || !isempty(pawns(board) & QUEENSIDE)

    slimchance = isempty(passed) && (outflank < 0) && !pawns_both_flanks

    complexity = 8 * count(passed) + 10 * count(pawns(board)) + 8 * outflank +
        (infiltrating ? 11 : 0) + (pawns_both_flanks ? 19 : 0) + (has_non_pawn_material(board) ? 0 : 44) -
        (slimchance ? 39 : 0) - 90

    c_mg = (Int(mg > 0) - Int(mg < 0)) * max(min(complexity + 45, 0), -abs(mg))
    c_eg = (Int(eg > 0) - Int(eg < 0)) * max(complexity, -abs(eg))
    makescore(c_mg, c_eg)
end


function evaluate_passed(board::Board, ea::EvalAttackInfo)
    black_king = square(kings(board) & black(board))
    white_king = square(kings(board) & white(board))
    white_pawns = white(board) & ea.passed
    black_pawns = black(board) & ea.passed

    w_attacks = ea.wknightattacks | ea.wpawnattacks | ea.wbishopattacks | ea.wrookattacks | ea.wqueenattacks | ea.wkingattacks
    b_attacks = ea.bknightattacks | ea.bpawnattacks | ea.bbishopattacks | ea.brookattacks | ea.bqueenattacks | ea.bkingattacks

    block_sqr = 0

    score = 0
    @inbounds for pawn in white_pawns
        bonus = 0
        file = fileof(pawn)
        rank = rankof(pawn)
        bonus += PASS_PAWN_THREAT[rank]
        if rank > 3
            factor = muladd(5, rank, -13)
            block_sqr = pawn + 8
            bonus += makescore(0, (fld(min(DISTANCE_BETWEEN[block_sqr, black_king],5)*19, 4) - min(DISTANCE_BETWEEN[block_sqr, white_king],5)*2)*factor)
            if rank !== 7
                block_sqr_2 = block_sqr + 8
                bonus -= makescore(0, DISTANCE_BETWEEN[block_sqr_2, white_king]*factor)
            end
            if board[block_sqr] === BLANK
                sqrs_to_queen = PASSED_PAWN_MASKS[1][pawn] & FILE[file]
                unsafe_sqrs = PASSED_PAWN_MASKS[1][pawn]
                case = (PASSED_PAWN_MASKS[2][pawn] & FILE[file]) & rooklike(board)
                if isempty(case & black(board))
                    unsafe_sqrs &= b_attacks
                end

                if isempty(unsafe_sqrs)
                    k = 32
                elseif isempty(unsafe_sqrs & sqrs_to_queen)
                    k = 18
                elseif isempty(unsafe_sqrs & Bitboard(block_sqr))
                    k = 8
                else
                    k = 0
                end

                if !isempty(white(board) & case) || !isempty(w_attacks & Bitboard(block_sqr))
                    k += 5
                end

                bonus += makescore(k * factor, k * factor)
            end
        end
        if board[block_sqr] === WHITEPAWN
            bonus = makescore(fld(scoreMG(bonus), 2), fld(scoreEG(bonus), 2))
        end
        score += bonus
    end


    @inbounds for pawn in black_pawns
        bonus = 0
        file = fileof(pawn)
        rank = 9 - rankof(pawn)
        bonus += PASS_PAWN_THREAT[rank]
        if rank > 3
            factor = muladd(5, rank, -13)
            block_sqr = pawn - 8
            bonus += makescore(0, (fld(min(DISTANCE_BETWEEN[block_sqr, white_king],5)*14, 3) - min(DISTANCE_BETWEEN[block_sqr, black_king],5)*2)*factor)
            if rank !== 7
                block_sqr_2 = block_sqr - 8
                bonus -= makescore(0, DISTANCE_BETWEEN[block_sqr_2, black_king]*factor)
            end
            if board[block_sqr] === BLANK
                sqrs_to_queen = PASSED_PAWN_MASKS[2][pawn] & FILE[file]
                unsafe_sqrs = PASSED_PAWN_MASKS[2][pawn]
                case = (PASSED_PAWN_MASKS[1][pawn] & FILE[file]) & rooklike(board)
                if isempty(case & white(board))
                    unsafe_sqrs &= w_attacks
                end

                if isempty(unsafe_sqrs)
                    k = 32
                elseif isempty(unsafe_sqrs & sqrs_to_queen)
                    k = 18
                elseif isempty(unsafe_sqrs & Bitboard(block_sqr))
                    k = 8
                else
                    k = 0
                end

                if !isempty(black(board) & case) || !isempty(b_attacks & Bitboard(block_sqr))
                    k += 5
                end

                bonus += makescore(k * factor, k * factor)
            end
        end
        if board[block_sqr] === BLACKPAWN
            bonus = makescore(fld(scoreMG(bonus), 2), fld(scoreEG(bonus), 2))
        end
        score -= bonus
    end

    score
end
