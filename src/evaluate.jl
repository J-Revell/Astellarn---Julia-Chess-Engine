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



function static_exchange_evaluator(board::Board, move::Move)
    from_bb = from(move)
    to_bb = to(move)

    from_piece = piece(board, from_bb)
    to_piece = piece(board, to_bb)

    occ = occupied(board) & ~from_bb

    attackers = (pawns(board) & pawnAttacks(board.turn, sqr)) |
    (pawns(board) & pawnAttacks(!board.turn, sqr)) |
    (knightMoves(sqr) & knights(board)) |
    (bishopMoves(sqr, occ) & bishoplike(board)) |
    (rookMoves(sqr, occ) & rooklike(board)) |
    (kingMoves(sqr) & kings(board))

    attackers &= occ

    if isempty(attackers & enemies(board))
        to_piece == BLANK ? 0 : PVALS[type(to_piece)]
    end
end


"""
    evaluate(board)

Naive evaluation function to get the code development going.
"""
function evaluate(board::Board)
    if isdraw(board)
        return 0
    end
    if ischeckmate(board)
        return -10000
    end
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

    # naive central pawn control
    position_eval = count(w_pawns & (RANK_4 | RANK_5) & (FILE_D | FILE_E))*20
    position_eval -= count(b_pawns & (RANK_4 | RANK_5) & (FILE_D | FILE_E))*20

    for knight in w_knights
        position_eval += KNIGHT_EVAL_TABLE[knight]
    end
    for knight in b_knights
        position_eval -= KNIGHT_EVAL_TABLE[65-knight]
    end
    for bishop in w_bishops
        position_eval += BISHOP_EVAL_TABLE[bishop]
    end
    for bishop in b_bishops
        position_eval -= BISHOP_EVAL_TABLE[65-bishop]
    end
    for rook in w_rooks
        position_eval += ROOK_EVAL_TABLE[rook]
    end
    for rook in b_rooks
        position_eval -= ROOK_EVAL_TABLE[65-rook]
    end
    for queen in w_queens
        position_eval += QUEEN_EVAL_TABLE[queen]
    end
    for queen in b_queens
        position_eval -= QUEEN_EVAL_TABLE[65-queen]
    end
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
