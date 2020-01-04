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

const KING_EVAL_TABLE = @SVector [
     20, 30, 10,  0,  0, 10, 30, 20,
     20, 20,  0,  0,  0,  0, 20, 20,
    -10,-20,-20,-20,-20,-20,-20,-10,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30
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

const PVALS = @SVector [100, 300, 300, 500, 900, 2500]


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board)
    eval = 0

    eval += evaluate_pawns(board)
    eval += evaluate_knights(board)
    eval += evaluate_bishops(board)
    eval += evaluate_rooks(board)
    eval += evaluate_queens(board)
    eval += evaluate_kings(board)

    #eval += evaluate_pins(board)
    #eval += evaluate_space(board)

    if board.turn == WHITE
        return eval
    else
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

    eval = material_eval + position_eval
end


function evaluate_knights(board::Board)
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

    for knight in b_knights
        @inbounds position_eval -= KNIGHT_EVAL_TABLE[65 - knight]
    end

    eval = material_eval + position_eval
end


function evaluate_bishops(board::Board)
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

    for bishop in b_bishops
        @inbounds position_eval -= BISHOP_EVAL_TABLE[65 - bishop]
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
    end

    for rook in b_rooks
        @inbounds position_eval -= ROOK_EVAL_TABLE[65 - rook]
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

    material_eval = 0
    position_eval = 0

    @inbounds position_eval += KING_EVAL_TABLE[square(w_king)]
    @inbounds position_eval -= KING_EVAL_TABLE[65 - square(b_king)]

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

    w_filter = RANK_2 | RANK_3 | RANK_4
    b_filter = RANK_5 | RANK_6 | RANK_7

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
