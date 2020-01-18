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


function init_neighbour_file_masks()
    mask = [EMPTY for i in 1:8]
    for file in 1:8
        if file == 1
            neighbour = FILE[1] | FILE[2]
        elseif file == 8
            neighbour = FILE[7] | FILE[8]
        else
            neighbour = FILE[file + 1] | FILE[file] | FILE[file - 1]
        end
        mask[file] |= neighbour
    end
    mask
end


const NEIGHBOUR_FILE_MASKS = SVector{8}(init_neighbour_file_masks())


function init_passed_pawn_masks()
    mask = [[EMPTY for i in 1:64] for j in 1:2]
    @inbounds for sqr in 1:64
        for colour in 1:2
            rank = rankof(sqr)
            file = fileof(sqr)
            if colour == 1
                @simd for i in (rank+1):8
                    mask[colour][sqr] |= RANK[i] & NEIGHBOUR_FILE_MASKS[file]
                end
            else
                @simd for i in 1:(rank-1)
                    mask[colour][sqr] |= RANK[i] & NEIGHBOUR_FILE_MASKS[file]
                end
            end
        end
    end
    mask
end

function init_connected_pawn_masks()
    mask = [[EMPTY for i in 1:64] for j in 1:2]
    for sqr in 9:56
        mask[1][sqr] = pawnAttacks(BLACK, sqr) | pawnAttacks(BLACK, sqr + 8)
        mask[2][sqr] = pawnAttacks(WHITE, sqr) | pawnAttacks(WHITE, sqr - 8)
    end
    mask
end



const KNIGHT_TRAP_PATTERNS = init_knight_traps()
const BISHOP_TRAP_PATTERNS = init_bishop_traps()
const PASSED_PAWN_MASKS = SArray{Tuple{2}, SArray{Tuple{64}, Bitboard, 1, 64}, 1, 2}(init_passed_pawn_masks())
const CONNECTED_PAWN_MASKS = SArray{Tuple{2}, SArray{Tuple{64}, Bitboard, 1, 64}, 1, 2}(init_connected_pawn_masks())
