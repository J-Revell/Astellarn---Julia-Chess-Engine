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
    # if isdraw(board)
    #     return 0
    # end
    # if ischeckmate(board)
    #     return -10000
    # end
    w_pawns     = board[WHITEPAWN]      ; b_pawns   = board[BLACKPAWN]
    w_knights   = board[WHITEKNIGHT]    ; b_knights = board[BLACKKNIGHT]
    w_bishops   = board[WHITEBISHOP]    ; b_bishops = board[BLACKBISHOP]
    w_rooks     = board[WHITEROOK]      ; b_rooks   = board[BLACKROOK]
    w_queens    = board[WHITEQUEEN]     ; b_queens  = board[BLACKQUEEN]
    w_king      = board[WHITEKING]      ; b_king    = board[BLACKKING]

    pval = 100 ; nval = 300; bval = 300; rval = 500; qval = 900; kval = 2500

    # could use matrix operations for this
    material_eval = pval*count(w_pawns) + nval*count(w_knights) + bval*count(w_bishops) + rval*count(w_rooks) + qval*count(w_queens) + kval*count(w_king)
    material_eval -= (pval*count(b_pawns) + nval*count(b_knights) + bval*count(b_bishops) + rval*count(b_rooks) + qval*count(b_queens) + kval*count(b_king))

    # pawn evaluations
    for pawn in w_pawns
        position_eval += PAWN_EVAL_TABLE[pawn]
    end
    for pawn in b_pawns
        position_eval -= PAWN_EVAL_TABLE[65-pawn]
    end

    # knight evaluations
    for knight in w_knights
        position_eval += KNIGHT_EVAL_TABLE[knight]
    end
    for knight in b_knights
        position_eval -= KNIGHT_EVAL_TABLE[65-knight]
    end

    # bishop evaluations
    for bishop in w_bishops
        position_eval += BISHOP_EVAL_TABLE[bishop]
    end
    for bishop in b_bishops
        position_eval -= BISHOP_EVAL_TABLE[65-bishop]
    end

    # rook evaluations
    for rook in w_rooks
        position_eval += ROOK_EVAL_TABLE[rook]
    end
    for rook in b_rooks
        position_eval -= ROOK_EVAL_TABLE[65-rook]
    end

    # queen evaluations
    for queen in w_queens
        position_eval += QUEEN_EVAL_TABLE[queen]
    end
    for queen in b_queens
        position_eval -= QUEEN_EVAL_TABLE[65-queen]
    end

    # king evaluations
    for king in w_king
        position_eval += KING_EVAL_TABLE[king]
    end
    for king in b_king
        position_eval -= KING_EVAL_TABLE[65-king]
    end

    eval = material_eval + position_eval
    if board.turn == WHITE
        return eval
    else
        return -eval
    end
end
