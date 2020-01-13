struct Score
    val::Int
end

makescore(mg::Int, eg::Int) = Int32(mg + (eg << 16))
scoreMG(s::Integer) = Int(Int32(unsigned(s) & 0x7fff) - Int32(unsigned(s) & 0x8000))
scoreEG(s::Integer) = Int((s + 0x8000) >> 16)


#============================ Piece square tables =============================#
const PAWN_PSQT = SVector{8}([
    SVector{4}([makescore(  0,  0), makescore(  0,  0), makescore(  0,  0), makescore( 0,   0)]),
    SVector{4}([makescore(  5,-10), makescore(  5, -5), makescore( 10, 10), makescore( 20,  0)]),
    SVector{4}([makescore(-10,-10), makescore(-15,-10), makescore( 10,-10), makescore( 15,  5)]),
    SVector{4}([makescore(-10,  5), makescore(-25,  0), makescore(  5,-10), makescore( 20, -5)]),
    SVector{4}([makescore( 15, 10), makescore(  0,  5), makescore(-15,  5), makescore(  0,-10)]),
    SVector{4}([makescore( -5, 30), makescore(-10, 20), makescore(-10, 20), makescore( 20, 30)]),
    SVector{4}([makescore(-10,  0), makescore( 10,-10), makescore( -5, 10), makescore(-15, 20)]),
    SVector{4}([makescore(  0,  0), makescore(  0,  0), makescore(  0,  0), makescore( 0,   0)])])

const KNIGHT_PSQT = SVector{8}([
    SVector{4}([makescore(-175, -95), makescore(-90, -65), makescore(-75, -50), makescore(-70, -20)]),
    SVector{4}([makescore( -75, -70), makescore(-40, -55), makescore(-30, -20), makescore(-15,  10)]),
    SVector{4}([makescore( -60, -40), makescore(-20, -25), makescore(  5,  -5), makescore( 10,  30)]),
    SVector{4}([makescore( -35, -35), makescore( 10,   0), makescore( 40,  15), makescore( 50,  30)]),
    SVector{4}([makescore( -35, -45), makescore( 15, -15), makescore( 45,  10), makescore( 50,  40)]),
    SVector{4}([makescore( -10, -50), makescore( 20, -45), makescore( 60, -20), makescore( 55,  20)]),
    SVector{4}([makescore( -65, -70), makescore(-25, -50), makescore(  5, -50), makescore( 40,  10)]),
    SVector{4}([makescore(-200,-100), makescore(-80, -85), makescore(-55, -55), makescore(-25, -15)])])


const BISHOP_PSQT = SVector{8}([
    SVector{4}([makescore(-50, -55), makescore( -5, -30), makescore(-10,-35), makescore(-20,-10)]),
    SVector{4}([makescore(-15, -35), makescore( 10, -15), makescore( 20,-20), makescore(  5,  0)]),
    SVector{4}([makescore(-10, -15), makescore( 20,   0), makescore( -5,  0), makescore( 20, 10)]),
    SVector{4}([makescore( -5, -20), makescore( 10,  -5), makescore( 25,  0), makescore( 40, 20)]),
    SVector{4}([makescore(-10, -20), makescore( 30,   0), makescore( 20,-15), makescore( 30, 15)]),
    SVector{4}([makescore(-15, -30), makescore(  5,   5), makescore(  1,  5), makescore( 10,  5)]),
    SVector{4}([makescore(-20, -30), makescore(-15, -20), makescore(  5,  0), makescore(  0,  0)]),
    SVector{4}([makescore(-50, -45), makescore(  0, -40), makescore(-15,-40), makescore(-20,-25)])])


const ROOK_PSQT = SVector{8}([
    SVector{4}([makescore(-30,-10), makescore(-20,-10), makescore(-15,-10), makescore(-5,-10)]),
    SVector{4}([makescore(-20,-10), makescore(-10,-10), makescore(-10,  0), makescore( 5,  0)]),
    SVector{4}([makescore(-25,  5), makescore(-10,-10), makescore(  0,  0), makescore( 0, -5)]),
    SVector{4}([makescore(-10, -5), makescore( -5,  0), makescore( -5,-10), makescore(-5,  5)]),
    SVector{4}([makescore(-30, -5), makescore(-15, 10), makescore( -5,  5), makescore( 0, -5)]),
    SVector{4}([makescore(-20,  5), makescore(  0,  0), makescore(  5, -5), makescore(10, 10)]),
    SVector{4}([makescore(  0,  5), makescore( 10,  5), makescore( 15, 20), makescore(20, -5)]),
    SVector{4}([makescore(-20, 20), makescore(-20,  0), makescore(  0, 20), makescore(10, 10)])])


const QUEEN_PSQT = SVector{8}([
    SVector{4}([makescore( 0,-70), makescore(-5,-60), makescore(-5,-45), makescore( 5,-25)]),
    SVector{4}([makescore( 0,-55), makescore( 5,-30), makescore(10,-20), makescore(10, -5)]),
    SVector{4}([makescore( 0,-40), makescore( 5,-20), makescore(10,-10), makescore(10,  0)]),
    SVector{4}([makescore( 5,-25), makescore( 5,  0), makescore(10, 10), makescore(10, 25)]),
    SVector{4}([makescore( 0,-30), makescore(15, -5), makescore(10, 10), makescore( 5, 20)]),
    SVector{4}([makescore(-5,-40), makescore(10,-20), makescore( 5,-10), makescore(10,  0)]),
    SVector{4}([makescore(-5,-50), makescore( 5,-25), makescore(10,-25), makescore(10,-10)]),
    SVector{4}([makescore( 0,-75), makescore( 0,-50), makescore( 0,-40), makescore( 0,-35)])])


const KING_PSQT = SVector{8}([
    SVector{4}([makescore(216,  0), makescore(264, 36), makescore(216, 68), makescore(160, 60)]),
    SVector{4}([makescore(224, 44), makescore(240, 80), makescore(188,108), makescore(144,108)]),
    SVector{4}([makescore(156, 72), makescore(208,104), makescore(136,136), makescore( 96,140)]),
    SVector{4}([makescore(132, 80), makescore(152,124), makescore(112,136), makescore( 80,136)]),
    SVector{4}([makescore(124, 76), makescore(144,132), makescore( 84,160), makescore( 56,160)]),
    SVector{4}([makescore(100, 72), makescore(116,136), makescore( 64,148), makescore( 24,152)]),
    SVector{4}([makescore(72,  40), makescore(96,  96), makescore( 52, 92), makescore( 28,104)]),
    SVector{4}([makescore(48,   8), makescore(72,  48), makescore( 36, 60), makescore(  0, 64)])])


const PSQT = @SVector [PAWN_PSQT, KNIGHT_PSQT, BISHOP_PSQT, ROOK_PSQT, QUEEN_PSQT, KING_PSQT]


#=============================== PIECE VALUES =================================#
const PVALS = @SVector [makescore(120, 210), makescore(780, 850), makescore(820, 920), makescore(1280, 1380), makescore(2540, 2680), makescore(15000, 15000)]
const PVALS_MG = SVector{6}(scoreMG.(PVALS))


#=============================== Tempo Bonus ==================================#
const TEMPO_BONUS = 22


#============================= Rook Evaluation ================================#
const ROOK_OPEN_FILE_BONUS = 15
const ROOK_SEMIOPEN_FILE_BONUS = 10
const ROOK_KING_FILE_BONUS = 10


#============================= Pawn Evaluation ================================#
const PAWN_SHIELD_BONUS = 10
const DOUBLE_PAWN_PENALTY = makescore(10, 55)
const ISOLATED_PAWN_PENALTY = 12
const ISOLATED_SEMIOPEN_PENALTY = 4
const PAWN_DEFEND_PAWN_BONUS = 10
const PAWN_DEFEND_MINOR_BONUS = 8
const PAWN_DEFEND_MAJOR_BONUS = 5
const PAWN_ATTACK_MINOR_BONUS = 22
const PAWN_ATTACK_MAJOR_BONUS = 38
const WEAK_PAWN_PENALTY = 25
const PASS_PAWN_THREAT = SVector{7}([makescore(0, 0), makescore(10, 30), makescore(20, 35), makescore(15, 40), makescore(60, 70), makescore(170, 180), makescore(275, 260)])


#=========================== Knight Evaluation ================================#
const KNIGHT_TRAP_PENALTY = 50
const KNIGHT_RAMMED_BONUS = 2


#=========================== Bishop Evaluation ================================#
const BISHOP_TRAP_PENALTY = 90
const BISHOP_COLOR_PENALTY = 4
const BISHOP_RAMMED_COLOR_PENALTY = 5
const BISHOP_PAIR_BONUS = 10


#============================= King Evaluation ================================#
const CASTLE_OPTION_BONUS = 8
const KING_PAWN_SHIELD_BONUS = 12


#============================ Queen Evaluation ================================#


#============================ Space Evaluation ================================#
const SPACE_BONUS = 4


#============================== Pin Evaluation ================================#
const PIN_BONUS = 15


#========================= Mobility Evaluation ================================#
const ROOK_MOBILITY = @SVector [-90, -45, -10, -5, 0, 0, 0, 5, 10, 15, 20, 24, 26, 30, 60]
const KNIGHT_MOBILITY = @SVector [-70, -30, -15, -5, 5, 10, 20, 30, 40]
const BISHOP_MOBILITY = @SVector [-70, -30, -10, 0, 10, 15, 20, 21, 22, 23, 24, 28, 35, 60]
const QUEEN_MOBILITY = @SVector [-60, -50, -40, -20, 0, 2, 5, 7, 10, 12, 14, 16, 18, 20,
                                20, 20, 20, 20, 20, 20, 22, 24, 26, 28, 28, 28, 22, 18]


#============================ SCALING FACTORS =================================#
const SCALE_OCB_BISHOPS = 64
const SCALE_OCB_ONE_KNIGHT = 106
const SCALE_OCB_ONE_ROOK = 96
const SCALE_DRAW = 0
const SCALE_NORMAL = 128
