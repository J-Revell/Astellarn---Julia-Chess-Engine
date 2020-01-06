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

const PVALS = @SVector [100, 300, 320, 500, 950, 2500]

const TEMPO_BONUS = 22

const ROOK_OPEN_FILE_BONUS = 10

const PAWN_SHIELD_BONUS = 10
const DOUBLE_PAWN_PENALTY = 8
const ISOLATED_PAWN_PENALTY = 12
const ISOLATED_SEMIOPEN_PENALTY = 4

const KNIGHT_RAMMED_BONUS = 2

const BISHOP_COLOR_PENALTY = 4
const BISHOP_RAMMED_COLOR_PENALTY = 5
const BISHOP_PAIR_BONUS = 10

const CASTLE_OPTION_BONUS = 8

struct EvalAux
    rammedpawns::Vector{Bitboard}
end


function initEvalAux(board::Board)
    # check for rammed pawns
    rammedpawns = Vector{Bitboard}(undef, 2)
    rammedpawns[1] = pawnAdvance(board[BLACKPAWN], board[WHITEPAWN], BLACK)
    rammedpawns[2] = pawnAdvance(board[WHITEPAWN], board[BLACKPAWN], WHITE)
    EvalAux(rammedpawns)
end


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board)
    evalaux = initEvalAux(board::Board)
    eval = 0
    eval += evaluate_pawns(board)
    eval += evaluate_knights(board, evalaux)
    eval += evaluate_bishops(board, evalaux)
    eval += evaluate_rooks(board)
    eval += evaluate_queens(board)
    eval += evaluate_kings(board)

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


function evaluate_pawns(board::Board)
    w_pawns = board[WHITEPAWN]
    b_pawns = board[BLACKPAWN]
    pval = PVALS[1]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_pawns)
    material_eval -= pval*count(b_pawns)

    for pawn in w_pawns
        @inbounds position_eval += PAWN_EVAL_TABLE[pawn]
    end

    for pawn in b_pawns
        @inbounds position_eval -= PAWN_EVAL_TABLE[65 - pawn]
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

    for knight in w_knights
        @inbounds position_eval += KNIGHT_EVAL_TABLE[knight]
    end
    position_eval += count((w_knights << 8) & board[WHITEPAWN]) * PAWN_SHIELD_BONUS

    for knight in b_knights
        @inbounds position_eval -= KNIGHT_EVAL_TABLE[65 - knight]
    end
    position_eval -= count((b_knights >> 8) & board[BLACKPAWN]) * PAWN_SHIELD_BONUS

    # bonus for knights in rammed positions
    num_rammed = count(evalaux.rammedpawns[1])
    position_eval += fld(count(w_knights) * KNIGHT_RAMMED_BONUS * num_rammed * num_rammed, 4)
    position_eval -= fld(count(b_knights) * KNIGHT_RAMMED_BONUS * num_rammed * num_rammed, 4)

    eval = material_eval + position_eval
end


function evaluate_bishops(board::Board, evalaux::EvalAux)
    w_bishops = board[WHITEBISHOP]
    b_bishops = board[BLACKBISHOP]
    pval = PVALS[3]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_bishops)
    material_eval -= pval*count(b_bishops)

    for bishop in w_bishops
        @inbounds position_eval += BISHOP_EVAL_TABLE[bishop]
    end
    position_eval += count((w_bishops << 8) & board[WHITEPAWN]) * PAWN_SHIELD_BONUS

    for bishop in b_bishops
        @inbounds position_eval -= BISHOP_EVAL_TABLE[65 - bishop]
    end
    position_eval -= count((b_bishops >> 8) & board[BLACKPAWN]) * PAWN_SHIELD_BONUS

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
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.rammedpawns[1] & LIGHT)
    end
    if !isempty(board[WHITEBISHOP] & DARK)
        position_eval -= BISHOP_COLOR_PENALTY * count(board[WHITEPAWN] & DARK)
        position_eval -= BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.rammedpawns[1] & DARK)
    end
    if !isempty(board[BLACKBISHOP] & LIGHT)
        position_eval += BISHOP_COLOR_PENALTY * count(board[BLACKPAWN] & LIGHT)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.rammedpawns[2] & LIGHT)
    end
    if !isempty(board[BLACKBISHOP] & DARK)
        position_eval += BISHOP_COLOR_PENALTY * count(board[BLACKPAWN] & DARK)
        position_eval += BISHOP_RAMMED_COLOR_PENALTY * count(evalaux.rammedpawns[2] & DARK)
    end

    eval = material_eval + position_eval
end


function evaluate_rooks(board::Board)
    w_rooks = board[WHITEROOK]
    b_rooks = board[BLACKROOK]
    pval = PVALS[4]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_rooks)
    material_eval -= pval*count(b_rooks)

    for rook in w_rooks
        @inbounds position_eval += ROOK_EVAL_TABLE[rook]
        if isempty(file(rook) & board[WHITEPAWN])
            position_eval += ROOK_OPEN_FILE_BONUS
        end
    end

    for rook in b_rooks
        @inbounds position_eval -= ROOK_EVAL_TABLE[65 - rook]
        if isempty(file(rook) & board[BLACKPAWN])
            position_eval -= ROOK_OPEN_FILE_BONUS
        end
    end

    eval = material_eval + position_eval
end


function evaluate_queens(board::Board)
    w_queens = board[WHITEQUEEN]
    b_queens = board[BLACKQUEEN]
    pval = PVALS[5]

    material_eval = 0
    position_eval = 0

    material_eval += pval*count(w_queens)
    material_eval -= pval*count(b_queens)

    for queen in w_queens
        @inbounds position_eval += QUEEN_EVAL_TABLE[queen]
    end

    for queen in b_queens
        @inbounds position_eval -= QUEEN_EVAL_TABLE[65 - queen]
    end

    eval = material_eval + position_eval
end


function evaluate_kings(board::Board)
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

    eval = material_eval + position_eval
end


function evaluate_pins(board::Board)
    eval = 0

    # switch turn and find all pins
    board.turn = !board.turn
    opp_pinned = findpins(board)
    board.turn = !board.turn

    if board.turn == WHITE
        eval -= count(board.pinned) * 10
        eval += count(opp_pinned) * 10
    else
        eval += count(board.pinned) * 10
        eval -= count(opp_pinned) * 10
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
