const PAWN_EVAL_TABLE = @SVector [
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10,-20,-20, 10, 10,  5,
     5, -5,-10,  0,  0,-10, -5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5,  5, 10, 25, 25, 10,  5,  5,
    10, 10, 20, 30, 30, 20, 10, 10,
    50, 50, 50, 50, 50, 50, 50, 50,
     0,  0,  0,  0,  0,  0,  0,  0
     ]

const KING_EVAL_TABLE_MG = @SVector [
     20, 40, 10,  0,  0, 10, 40, 20,
     20, 20,  0,  0,  0,  0, 20, 20,
    -10,-20,-20,-20,-20,-20,-20,-10,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30
    ]

const KING_EVAL_TABLE_EG = @SVector [
    -5, -5, -5, -5, -5, -5, -5, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 5, 5, 5, 5, 0, -5,
    -5, 0, 5, 10, 10, 5, 0, -5,
    -5, 0, 5, 10, 10, 5, 0, -5,
    -5, 0, 5, 5, 5, 5, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, -5, -5, -5, -5, -5, -5, -5
    ]

const BISHOP_EVAL_TABLE = @SVector [
    -10, -5, 0, 0, 0, 0, -5, -10,
    0, 5, 5, 5, 5, 5, 5, 0,
    0, 5, 5, 10, 10, 5, 5, 0,
    0, 5, 10, 10, 10, 10, 5, 0,
    0, 5, 10, 10, 10, 10, 5, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    -10, -5, 0, 0, 0, 0, -5, -10
    ]

const ROOK_EVAL_TABLE = @SVector [
    0,  0,  0,  5,  5,  0,  0,  0,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     5, 10, 10, 10, 10, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
    ]

const KNIGHT_EVAL_TABLE = @SVector [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -20,  5, 10, 15, 15, 10,  5,-20,
    -20,  0, 15, 20, 20, 15,  0,-20,
    -20,  5, 15, 20, 20, 15,  5,-20,
    -20,  0, 10, 15, 15, 10,  0,-20,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50
    ]

const QUEEN_EVAL_TABLE = @SVector [
    -20,-10,-10, -5, -5,-10,-10,-20,
    -10,  0,  5,  0,  0,  0,  0,-10,
    -10,  5,  5,  5,  5,  5,  0,-10,
      0,  0,  5,  5,  5,  5,  0, -5,
     -5,  0,  5,  5,  5,  5,  0, -5,
    -10,  0,  5,  5,  5,  5,  0,-10,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -20,-10,-10, -5, -5,-10,-10,-20
    ]

const PVALS = @SVector [100, 300, 320, 520, 950, 2500]

const TEMPO_BONUS = 22

const ROOK_OPEN_FILE_BONUS = 15
const ROOK_SEMIOPEN_FILE_BONUS = 10
const ROOK_KING_FILE_BONUS = 10

const PAWN_SHIELD_BONUS = 10
const DOUBLE_PAWN_PENALTY = 8
const ISOLATED_PAWN_PENALTY = 12
const ISOLATED_SEMIOPEN_PENALTY = 4
const PAWN_DEFEND_PAWN_BONUS = 10
const PAWN_DEFEND_MINOR_BONUS = 8
const PAWN_DEFEND_MAJOR_BONUS = 5
const PAWN_ATTACK_MINOR_BONUS = 22
const PAWN_ATTACK_MAJOR_BONUS = 38


struct MinorPieceTrap
    pawnmask::Bitboard
    minormask::Bitboard
end


function init_knight_traps()
    # Trap 1
    # White knight trapped on h8, with pawn on f7
    pawnmask = Bitboard(LABEL_TO_SQUARE["f7"])
    knightmask = Bitboard(LABEL_TO_SQUARE["h8"])
    trap_1 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 2
    # White knight trapped on h8, with pawn on h7
    pawnmask = Bitboard(LABEL_TO_SQUARE["h7"])
    knightmask = Bitboard(LABEL_TO_SQUARE["h8"])
    trap_2 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 3
    # White knight trapped on a8, with pawn on c7
    pawnmask = Bitboard(LABEL_TO_SQUARE["c7"])
    knightmask = Bitboard(LABEL_TO_SQUARE["a8"])
    trap_3 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 4
    # White knight trapped on a8, with pawn on a7
    pawnmask = Bitboard(LABEL_TO_SQUARE["a7"])
    knightmask = Bitboard(LABEL_TO_SQUARE["a8"])
    trap_4 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 5
    # Black knight trapped on h1, with pawn on f2
    pawnmask = Bitboard(LABEL_TO_SQUARE["f2"])
    knightmask = Bitboard(LABEL_TO_SQUARE["h1"])
    trap_5 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 6
    # Black knight trapped on h1, with pawn on h2
    pawnmask = Bitboard(LABEL_TO_SQUARE["h2"])
    knightmask = Bitboard(LABEL_TO_SQUARE["h1"])
    trap_6 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 7
    # Black knight trapped on a1, with pawn on c2
    pawnmask = Bitboard(LABEL_TO_SQUARE["c2"])
    knightmask = Bitboard(LABEL_TO_SQUARE["a1"])
    trap_7 = MinorPieceTrap(pawnmask, knightmask)

    # Trap 8
    # Black knight trapped on a1, with pawn on a2
    pawnmask = Bitboard(LABEL_TO_SQUARE["a2"])
    knightmask = Bitboard(LABEL_TO_SQUARE["a1"])
    trap_8 = MinorPieceTrap(pawnmask, knightmask)

    white_trapped = @SVector [trap_1, trap_2, trap_3, trap_4]
    black_trapped = @SVector [trap_5, trap_6, trap_7, trap_8]
    knight_trap_patterns= @SVector [white_trapped, black_trapped]
end

const KNIGHT_TRAP_PATTERNS = init_knight_traps()
const KNIGHT_TRAP_PENALTY = 50
const KNIGHT_RAMMED_BONUS = 2


function init_bishop_traps()
    # Trap 1
    # White bishop trapped on A7 or B8 by pawns on B6 and C7
    pawnmask = Bitboard(LABEL_TO_SQUARE["b6"]) | Bitboard(LABEL_TO_SQUARE["c7"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["a7"]) | Bitboard(LABEL_TO_SQUARE["b8"])
    trap_1 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 2
    # White bishop trapped on h7 or G8, by pawns on g6 and f7
    pawnmask = Bitboard(LABEL_TO_SQUARE["g6"]) | Bitboard(LABEL_TO_SQUARE["f7"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["h7"]) | Bitboard(LABEL_TO_SQUARE["g8"])
    trap_2 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 3
    # White bishop trapped on a8, c8, A6, B7, by pawns on B5, c6, d7
    pawnmask = Bitboard(LABEL_TO_SQUARE["b5"]) | Bitboard(LABEL_TO_SQUARE["c6"]) | Bitboard(LABEL_TO_SQUARE["d7"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["a8"]) | Bitboard(LABEL_TO_SQUARE["c8"]) | Bitboard(LABEL_TO_SQUARE["a6"]) | Bitboard(LABEL_TO_SQUARE["b7"])
    trap_3 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 4
    # White bishop trapped on h8, f8, H6, g7, by pawns on g5, F6, E7
    pawnmask = Bitboard(LABEL_TO_SQUARE["g5"]) | Bitboard(LABEL_TO_SQUARE["f6"]) | Bitboard(LABEL_TO_SQUARE["e7"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["h8"]) | Bitboard(LABEL_TO_SQUARE["f8"]) | Bitboard(LABEL_TO_SQUARE["h6"]) | Bitboard(LABEL_TO_SQUARE["g7"])
    trap_4 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 5
    # Black bishop trapped on A2 or B1 by pawns on B3 and C2
    pawnmask = Bitboard(LABEL_TO_SQUARE["b3"]) | Bitboard(LABEL_TO_SQUARE["c2"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["a2"]) | Bitboard(LABEL_TO_SQUARE["b1"])
    trap_5 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 6
    # White bishop trapped on H2 or g1, by pawns on g3 and F2
    pawnmask = Bitboard(LABEL_TO_SQUARE["g3"]) | Bitboard(LABEL_TO_SQUARE["f2"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["h2"]) | Bitboard(LABEL_TO_SQUARE["g1"])
    trap_6 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 7
    # White bishop trapped on a1, C1, A3, B2, by pawns on B4, C3, D2
    pawnmask = Bitboard(LABEL_TO_SQUARE["b4"]) | Bitboard(LABEL_TO_SQUARE["c3"]) | Bitboard(LABEL_TO_SQUARE["d2"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["a1"]) | Bitboard(LABEL_TO_SQUARE["c1"]) | Bitboard(LABEL_TO_SQUARE["a3"]) | Bitboard(LABEL_TO_SQUARE["b2"])
    trap_7 = MinorPieceTrap(pawnmask, bishopmask)

    # Trap 8
    # White bishop trapped on H1, F1, H3, g2, by pawns on g4, F3, E2
    pawnmask = Bitboard(LABEL_TO_SQUARE["g4"]) | Bitboard(LABEL_TO_SQUARE["f3"]) | Bitboard(LABEL_TO_SQUARE["e2"])
    bishopmask = Bitboard(LABEL_TO_SQUARE["h1"]) | Bitboard(LABEL_TO_SQUARE["f1"]) | Bitboard(LABEL_TO_SQUARE["h3"]) | Bitboard(LABEL_TO_SQUARE["g2"])
    trap_8 = MinorPieceTrap(pawnmask, bishopmask)

    white_trapped = @SVector [trap_1, trap_2, trap_3, trap_4]
    black_trapped = @SVector [trap_5, trap_6, trap_7, trap_8]
    bishop_trap_patterns= @SVector [white_trapped, black_trapped]
end

const BISHOP_TRAP_PATTERNS = init_bishop_traps()
const BISHOP_TRAP_PENALTY = 110
const BISHOP_COLOR_PENALTY = 4
const BISHOP_RAMMED_COLOR_PENALTY = 5
const BISHOP_PAIR_BONUS = 10

const CASTLE_OPTION_BONUS = 8
const KING_PAWN_SHIELD_BONUS = 12


"""
    EvalAux

EvalAux is an auxilliary data structure for storing useful computations for the evaluation of the board.
"""
struct EvalAux
    wrammedpawns::Bitboard
    brammedpawns::Bitboard
    wpawnattacks::Bitboard
    bpawnattacks::Bitboard
    wknightattacks::Bitboard
    bknightattacks::Bitboard
end


function initEvalAux(board::Board)
    # extract pawn positions
    wpawns = board[WHITEPAWN]
    bpawns = board[BLACKPAWN]

    # check for rammed pawns
    wrammedpawns = pawnAdvance(bpawns, wpawns, BLACK)
    brammedpawns = pawnAdvance(wpawns, bpawns, WHITE)

    # generate list of all positions attacked by a pawn
    wpawnattacks = pawnCapturesWhite(wpawns, FULL)
    bpawnattacks = pawnCapturesBlack(bpawns, FULL)

    # extract knight positions
    wknights = board[WHITEKNIGHT]
    bknights = board[BLACKKNIGHT]

    # generate list of all positions attacked by a knight
    wknightattacks = knightMove_all(wknights)
    bknightattacks = knightMove_all(bknights)

    EvalAux(wrammedpawns, brammedpawns, wpawnattacks, bpawnattacks, wknightattacks, bknightattacks)
end


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board)
    evalaux = initEvalAux(board::Board)
    eval = 0
    eval += evaluate_pawns(board, evalaux)
    eval += evaluate_knights(board, evalaux)
    eval += evaluate_bishops(board, evalaux)
    eval += evaluate_rooks(board, evalaux)
    eval += evaluate_queens(board, evalaux)
    eval += evaluate_kings(board, evalaux)

    eval += evaluate_pins(board)
    #eval += evaluate_space(board)

    if board.turn == WHITE
        eval += TEMPO_BONUS
        return eval
    else
        eval -= TEMPO_BONUS
        return -eval
    end
end


function evaluate_pawns(board::Board, evalaux::EvalAux)
    w_pawns = board[WHITEPAWN]
    b_pawns = board[BLACKPAWN]
    pval = PVALS[1]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_pawns)
    material_eval -= pval*count(b_pawns)

    @inbounds for pawn in w_pawns
        position_eval += PAWN_EVAL_TABLE[pawn]
    end

    @inbounds for pawn in b_pawns
        position_eval -= PAWN_EVAL_TABLE[65 - pawn]
    end

    # double pawns
    for file in FILE
        if file == FILE_A || file == FILE_H
            penalty = 2DOUBLE_PAWN_PENALTY
        else
            penalty = DOUBLE_PAWN_PENALTY
        end
        if ismany(w_pawns & file)
            position_eval -= penalty
        elseif ismany(b_pawns & file)
            position_eval += penalty
        end
    end

    # passed pawn
    w_pass_threats = w_pawns & (RANK_6 | RANK_7)
    b_pass_threats = b_pawns & (RANK_2 | RANK_3)

    for i in eachindex(FILE)
        neighbour = FILE[i]
        if i > 1
            neighbour |= FILE[i - 1]
        end
        if i < 8
            neighbour |= FILE[i + 1]
        end
        if isone(neighbour & w_pawns)
            position_eval -= ISOLATED_PAWN_PENALTY
            if !isempty(FILE[i] & b_pawns) && !isempty(board[BLACKROOK] | board[BLACKQUEEN])
                position_eval -= ISOLATED_SEMIOPEN_PENALTY
            end
        end
        if isone(neighbour & b_pawns)
            position_eval += ISOLATED_PAWN_PENALTY
            if !isempty(FILE[i] & w_pawns) && !isempty(board[WHITEROOK] | board[WHITEQUEEN])
                position_eval += ISOLATED_SEMIOPEN_PENALTY
            end
        end
        if !isempty(w_pass_threats & FILE[i]) && isempty(neighbour & RANK_7 & b_pawns)
            if isone(occupied(board) & RANK_8 & FILE[i])
                position_eval += 5
            else
                position_eval += 15
            end
        end
        if !isempty(b_pass_threats & FILE[i]) && isempty(neighbour & RANK_2 & w_pawns)
            if isone(occupied(board) & RANK_1 & FILE[i])
                position_eval -= 5
            else
                position_eval -= 15
            end
        end
    end
    position_eval += count(evalaux.wpawnattacks & w_pawns) * PAWN_DEFEND_PAWN_BONUS
    position_eval -= count(evalaux.bpawnattacks & b_pawns) * PAWN_DEFEND_PAWN_BONUS

    eval = material_eval + position_eval
end


function evaluate_knights(board::Board, evalaux::EvalAux)
    w_knights = board[WHITEKNIGHT]
    b_knights = board[BLACKKNIGHT]
    pval = PVALS[2]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_knights)
    material_eval -= pval*count(b_knights)

    @inbounds for knight in w_knights
        position_eval += KNIGHT_EVAL_TABLE[knight]
    end
    position_eval += count((w_knights << 8) & board[WHITEPAWN]) * PAWN_SHIELD_BONUS
    position_eval += count(evalaux.wpawnattacks & w_knights) * PAWN_DEFEND_MINOR_BONUS
    position_eval -= count(evalaux.bpawnattacks & w_knights) * PAWN_ATTACK_MINOR_BONUS

    @inbounds for knight in b_knights
        position_eval -= KNIGHT_EVAL_TABLE[65 - knight]
    end
    position_eval -= count((b_knights >> 8) & board[BLACKPAWN]) * PAWN_SHIELD_BONUS
    position_eval -= count(evalaux.bpawnattacks & b_knights) * PAWN_DEFEND_MINOR_BONUS
    position_eval += count(evalaux.wpawnattacks & b_knights) * PAWN_ATTACK_MINOR_BONUS

    # bonus for knights in rammed positions
    num_rammed = count(evalaux.wrammedpawns)
    position_eval += fld(count(w_knights) * KNIGHT_RAMMED_BONUS * num_rammed^2, 4)
    position_eval -= fld(count(b_knights) * KNIGHT_RAMMED_BONUS * num_rammed^2, 4)

    # Evaluate trapped knights.
    for trap in KNIGHT_TRAP_PATTERNS[1]
        if ((board[BLACKPAWN] & trap.pawnmask) == trap.pawnmask) && isone(board[WHITEKNIGHT] & trap.minormask)
            position_eval -= KNIGHT_TRAP_PENALTY
        end
    end
    for trap in KNIGHT_TRAP_PATTERNS[2]
        if ((board[WHITEPAWN] & trap.pawnmask) == trap.pawnmask) && isone(board[BLACKKNIGHT] & trap.minormask)
            position_eval += KNIGHT_TRAP_PENALTY
        end
    end

    position_eval += count(evalaux.wknightattacks & board[WHITEBISHOP]) * 10
    position_eval -= count(evalaux.bknightattacks & board[BLACKBISHOP]) * 10
    position_eval += count(evalaux.wknightattacks & board[WHITEROOK]) * 7
    position_eval -= count(evalaux.bknightattacks & board[BLACKROOK]) * 7
    position_eval += count(evalaux.wknightattacks & board[WHITEQUEEN]) * 5
    position_eval -= count(evalaux.bknightattacks & board[BLACKQUEEN]) * 5

    threat_eval = 0
    threat_eval += count(evalaux.wknightattacks & board[BLACKBISHOP]) * 15
    threat_eval -= count(evalaux.bknightattacks & board[WHITEBISHOP]) * 15
    threat_eval += count(evalaux.wknightattacks & board[BLACKROOK]) * 28
    threat_eval -= count(evalaux.bknightattacks & board[WHITEROOK]) * 28
    threat_eval += count(evalaux.wknightattacks & board[BLACKQUEEN]) * 42
    threat_eval -= count(evalaux.bknightattacks & board[WHITEQUEEN]) * 42


    eval = material_eval + position_eval + threat_eval
end


function evaluate_bishops(board::Board, evalaux::EvalAux)
    w_bishops = board[WHITEBISHOP]
    b_bishops = board[BLACKBISHOP]
    pval = PVALS[3]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_bishops)
    material_eval -= pval*count(b_bishops)

    @inbounds for bishop in w_bishops
        position_eval += BISHOP_EVAL_TABLE[bishop]
    end
    position_eval += count((w_bishops << 8) & board[WHITEPAWN]) * PAWN_SHIELD_BONUS
    position_eval += count(evalaux.wpawnattacks & w_bishops) * PAWN_DEFEND_MINOR_BONUS
    position_eval -= count(evalaux.bpawnattacks & w_bishops) * PAWN_ATTACK_MINOR_BONUS

    @inbounds for bishop in b_bishops
        position_eval -= BISHOP_EVAL_TABLE[65 - bishop]
    end
    position_eval -= count((b_bishops >> 8) & board[BLACKPAWN]) * PAWN_SHIELD_BONUS
    position_eval -= count(evalaux.bpawnattacks & b_bishops) * PAWN_DEFEND_MINOR_BONUS
    position_eval += count(evalaux.wpawnattacks & b_bishops) * PAWN_ATTACK_MINOR_BONUS

    for trap in BISHOP_TRAP_PATTERNS[1]
        if ((board[BLACKPAWN] & trap.pawnmask) == trap.pawnmask) && !isempty(board[WHITEBISHOP] & trap.minormask)
            position_eval -= BISHOP_TRAP_PENALTY
        end
    end
    for trap in BISHOP_TRAP_PATTERNS[2]
        if ((board[WHITEPAWN] & trap.pawnmask) == trap.pawnmask) && !isempty(board[BLACKBISHOP] & trap.minormask)
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
    if !isempty(board[WHITEBISHOP] & LIGHT)
        position_eval -= BISHOP_COLOR_PENALTY * count(board[WHITEPAWN] & LIGHT)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.wrammedpawns & LIGHT)
    end
    if !isempty(board[WHITEBISHOP] & DARK)
        position_eval -= BISHOP_COLOR_PENALTY * count(board[WHITEPAWN] & DARK)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.wrammedpawns & DARK)
    end
    if !isempty(board[BLACKBISHOP] & LIGHT)
        position_eval += BISHOP_COLOR_PENALTY * count(board[BLACKPAWN] & LIGHT)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.brammedpawns & LIGHT)
    end
    if !isempty(board[BLACKBISHOP] & DARK)
        position_eval += BISHOP_COLOR_PENALTY * count(board[BLACKPAWN] & DARK)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.brammedpawns & DARK)
    end

    eval = material_eval + position_eval
end


function evaluate_rooks(board::Board, evalaux::EvalAux)
    w_rooks = board[WHITEROOK]
    b_rooks = board[BLACKROOK]
    pval = PVALS[4]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_rooks)
    material_eval -= pval*count(b_rooks)

    for rook in w_rooks
        @inbounds position_eval += ROOK_EVAL_TABLE[rook]
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            position_eval += ROOK_OPEN_FILE_BONUS
        elseif isempty(rfile & board[WHITEPAWN])
            position_eval += ROOK_SEMIOPEN_FILE_BONUS
        end
        if isone(rfile & board[BLACKKING])
            position_eval += ROOK_KING_FILE_BONUS
        end
    end

    for rook in b_rooks
        @inbounds position_eval -= ROOK_EVAL_TABLE[65 - rook]
        rfile = file(rook)
        if isempty(rfile & pawns(board))
            position_eval -= ROOK_OPEN_FILE_BONUS
        elseif isempty(rfile & board[BLACKPAWN])
            position_eval -= ROOK_SEMIOPEN_FILE_BONUS
        end
        if isone(rfile & board[WHITEKING])
            position_eval -= ROOK_KING_FILE_BONUS
        end
    end

    position_eval += count(evalaux.wpawnattacks & w_rooks) * PAWN_DEFEND_MAJOR_BONUS
    position_eval -= count(evalaux.bpawnattacks & w_rooks) * PAWN_ATTACK_MAJOR_BONUS
    position_eval -= count(evalaux.bpawnattacks & b_rooks) * PAWN_DEFEND_MAJOR_BONUS
    position_eval += count(evalaux.wpawnattacks & b_rooks) * PAWN_ATTACK_MAJOR_BONUS

    eval = material_eval + position_eval
end


function evaluate_queens(board::Board, evalaux::EvalAux)
    w_queens = board[WHITEQUEEN]
    b_queens = board[BLACKQUEEN]
    pval = PVALS[5]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_queens)
    material_eval -= pval*count(b_queens)

    @inbounds for queen in w_queens
        position_eval += QUEEN_EVAL_TABLE[queen]
    end

    @inbounds for queen in b_queens
        position_eval -= QUEEN_EVAL_TABLE[65 - queen]
    end

    # attacked by a pawn?
    position_eval -= count(evalaux.bpawnattacks & w_queens) * 2PAWN_ATTACK_MAJOR_BONUS
    position_eval += count(evalaux.wpawnattacks & b_queens) * 2PAWN_ATTACK_MAJOR_BONUS

    eval = material_eval + position_eval
end


function evaluate_kings(board::Board, evalaux::EvalAux)
    w_king = board[WHITEKING]
    b_king = board[BLACKKING]
    pval = PVALS[6]

    if count(occupied(board)) <= 12
        ktable = KING_EVAL_TABLE_EG
    else
        ktable = KING_EVAL_TABLE_MG
    end

    material_eval = 0
    position_eval = 0
    king_safety = 0

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

    @inbounds position_eval += ktable[square(w_king)]
    @inbounds position_eval -= ktable[65 - square(b_king)]

    # Increase king safety if attacking pieces are non existent
    if isempty(board[BLACKQUEEN])
        king_safety += 15
    end
    if isempty(board[WHITEQUEEN])
        king_safety -= 15
    end
    if isempty(board[BLACKROOK])
        king_safety += 9
    end
    if isempty(board[WHITEROOK])
        king_safety -= 9
    end
    if isempty(board[BLACKBISHOP])
        king_safety += 6
    end
    if isempty(board[WHITEBISHOP])
        king_safety -= 6
    end
    if isempty(board[BLACKKNIGHT])
        king_safety += 5
    end
    if isempty(board[WHITEKNIGHT])
        king_safety -= 5
    end

    # Increase king safety for each pawn surrounding him
    king_safety += count(kingMoves(square(w_king)) & board[WHITEPAWN]) * KING_PAWN_SHIELD_BONUS
    king_safety -= count(kingMoves(square(b_king)) & board[BLACKPAWN]) * KING_PAWN_SHIELD_BONUS

    # decrease king safety if on an open file, with enemy rooks or queens on the board.
    if !isempty(board[BLACKROOK] | board[BLACKQUEEN]) && isempty(file(square(w_king)) & pawns(board))
        king_safety -= 15
    end
    if !isempty(board[WHITEROOK] | board[WHITEQUEEN]) && isempty(file(square(b_king)) & pawns(board))
        king_safety += 15
    end

    # decrease king safety if a neighbouring knight can deliver a check
    if !isempty(knightMove_all(w_king) & evalaux.bknightattacks)
        king_safety -= 10
    end
    if !isempty(knightMove_all(b_king) & evalaux.wknightattacks)
        king_safety += 10
    end

    eval = material_eval + position_eval + king_safety
end


function evaluate_pins(board::Board)
    eval = 0

    # switch turn and find all pins
    board.turn = !board.turn
    opp_pinned = findpins(board)
    board.turn = !board.turn

    if board.turn == WHITE
        eval -= count(board.pinned) * 14
        eval += count(opp_pinned) * 14
    else
        eval += count(board.pinned) * 14
        eval -= count(opp_pinned) * 14
    end

    eval
end


function evaluate_space(board::Board)
    eval = 0

    w_filter = (RANK_2 | RANK_3 | RANK_4) & (FILE_C | FILE_D | FILE_E | FILE_F)
    b_filter = (RANK_5 | RANK_6 | RANK_7) & (FILE_C | FILE_D | FILE_E | FILE_F)

    # remove pawns
    non_pawn = FULL & ~board[PAWN]

    # find space squares
    w_sqrs = w_filter & non_pawn
    b_sqrs = b_filter & non_pawn

    # check for attacks
    if board.turn == WHITE
        for sqr in w_sqrs
            !isattacked(board, sqr) && (eval += 3)
        end
        board.turn = !board.turn
        for sqr in b_sqrs
            !isattacked(board, sqr) && (eval -= 3)
        end
        board.turn = !board.turn
    else
        board.turn = !board.turn
        for sqr in w_sqrs
            !isattacked(board, sqr) && (eval += 3)
        end
        board.turn = !board.turn
        for sqr in b_sqrs
            !isattacked(board, sqr) && (eval -= 3)
        end
    end

    eval
end
