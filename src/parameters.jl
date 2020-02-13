#============================ Global Parameters ===============================#
const MAX_MOVES = 256
const MAX_PLY = 128
const MATE = 32000
const MAX_QUIET_TRACK = 92
MOVE_OVERHEAD = 100 # But it's not constant, and we don't declare it as such otherwise the compiler may hard-code it.
ABORT_SIGNAL = Base.Threads.Atomic{Bool}(false)

#============================== Search Parameters =============================#


const Q_FUTILITY_MARGIN = 100
const RAZOR_DEPTH = 1
const RAZOR_MARGIN = 500
const BETA_PRUNE_DEPTH = 8
const BETA_PRUNE_MARGIN = 185
const SEE_PRUNE_DEPTH = 8
const SEE_QUIET_MARGIN = -190
const SEE_NOISY_MARGIN = -25
const FUTILITY_PRUNE_DEPTH = 8
const FUTILITY_MARGIN = 200
const FUTILITY_MARGIN_NOHIST = 300
const FUTILITY_LIMIT = @SVector [12000, 6000]
const COUNTER_PRUNE_DEPTH = @SVector [4, 3]
const COUNTER_PRUNE_LIMIT = @SVector [0, -500]
const FOLLOW_PRUNE_DEPTH = @SVector [4, 3]
const FOLLOW_PRUNE_LIMIT = @SVector [-1000, -3000]
const WINDOW_DEPTH = 5
const LATE_MOVE_COUNT = @SVector [SVector{10}([0, 2, 4,  7, 11, 16, 22, 29, 37, 46]), SVector{10}([0, 4, 7, 12, 20, 30, 42, 56, 73, 92])]
const LATE_MOVE_PRUNE_DEPTH = 9
const LMRTABLE = init_reduction_table()
const PROBCUT_DEPTH = 5
const PROBCUT_MARGIN = 190


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
const PVALS_EG = SVector{6}(scoreEG.(PVALS))


#=============================== Tempo Bonus ==================================#


const TEMPO_BONUS = 22


#============================= Rook Evaluation ================================#


const ROOK_OPEN_FILE_BONUS = makescore(50, 25)
const ROOK_SEMIOPEN_FILE_BONUS = makescore(20, 5)
const ROOK_KING_FILE_BONUS = 10
const ROOK_ON_QUEEN_FILE = makescore(8, 5)


#============================= Pawn Evaluation ================================#


const PAWN_SHIELD_BONUS = makescore(17, 3)
const DOUBLE_PAWN_PENALTY = makescore(10, 55)
const ISOLATED_PAWN_PENALTY = makescore(15, 9)
const PAWN_DEFEND_PAWN_BONUS = 10
const WEAK_PAWN_PENALTY = 25
const PASS_PAWN_THREAT = SVector{7}([makescore(0, 0), makescore(10, 30), makescore(20, 35), makescore(15, 40), makescore(60, 70), makescore(170, 180), makescore(275, 260)])
const CONNECTED_PAWN_PSQT = SVector{8}([
    SVector{4}([makescore(   0,  0), makescore(   0,  0), makescore(   0,  0), makescore(   0,  0)]),
    SVector{4}([makescore(   0,-10), makescore(  10,  0), makescore(   5,  0), makescore(   5, 15)]),
    SVector{4}([makescore(  15,  0), makescore(   30, 0), makescore(  20, 10), makescore(  25, 15)]),
    SVector{4}([makescore(  10,  0), makescore(  25,  5), makescore(  10, 10), makescore(  15, 20)]),
    SVector{4}([makescore(  15,  8), makescore(  20, 15), makescore(  25, 20), makescore(  30, 20)]),
    SVector{4}([makescore(  60, 25), makescore(  51, 50), makescore(  70, 55), makescore(  85, 60)]),
    SVector{4}([makescore( 110,  0), makescore( 205, 10), makescore( 230, 30), makescore( 240, 50)]),
    SVector{4}([makescore(   0,  0), makescore(   0,  0), makescore(   0,  0), makescore(   0,  0)])])
const WEAK_UNOPPOSED = makescore(15, 30)
const WEAK_LEVER = makescore(0, 55)
const BACKWARD_PAWN = makescore(10, 25)


#=========================== Knight Evaluation ================================#


const KNIGHT_TRAP_PENALTY = makescore(50, 50)
const KNIGHT_RAMMED_BONUS = makescore(2, 2)
const KNIGHT_OUTPOST_BONUS = makescore(60, 40)
const KNIGHT_POTENTIAL_OUTPOST_BONUS = makescore(30, 10)


#=========================== Bishop Evaluation ================================#


const BISHOP_TRAP_PENALTY = makescore(80, 80)
const BISHOP_COLOR_PENALTY = makescore(2, 2)
const BISHOP_RAMMED_COLOR_PENALTY = makescore(5, 10)
const BISHOP_PAIR_BONUS = makescore(20, 60)
const BISHOP_OUTPOST_BONUS = makescore(30, 20)
const BISHOP_CENTRAL_CONTROL = makescore(40, 0)


#============================= King Evaluation ================================#


const CASTLE_OPTION_BONUS = makescore(10, 0)
const KING_PAWN_SHIELD_BONUS = 12
const KING_FLANK_ATTACK = makescore(10, 0)
const PAWNLESS_FLANK = makescore(20, 95)


const KING_SHELTER_OFFFILE = SVector{8}([
SVector{8}([makescore(-11, 1), makescore(12, -25), makescore(18, -9), makescore(9, 2), makescore(4, 2), makescore(0, 0), makescore(-4, -31), makescore(-45, 15)]),
SVector{8}([makescore(14, -9), makescore(18, -18), makescore(0, -6), makescore(-14, 2), makescore(-27, 12), makescore(-63, 60), makescore(81, 72), makescore(-24, 0)]),
SVector{8}([makescore(30, -5), makescore(11, -9), makescore(-27, 5), makescore(-11, -9), makescore(-18, -5), makescore(-11, 0), makescore(0, 58), makescore(-12, -3)]),
SVector{8}([makescore(2, 9), makescore(18, -11), makescore(2, -11), makescore(12, -21), makescore(21, -34), makescore(-54, 3), makescore(-124, 45), makescore(3, -8)]),
SVector{8}([makescore(-15, 5), makescore(2, -5), makescore(-25, 0), makescore(-18, 3), makescore(-18, -7), makescore(-38, -2), makescore(28, -17), makescore(-7, -3)]),
SVector{8}([makescore(40, -18), makescore(18, -17), makescore(-20, 0), makescore(-12, -18), makescore(3, -23), makescore(14, -20), makescore(36, -27), makescore(-23, 0)]),
SVector{8}([makescore(21, -13), makescore(-2, -16), makescore(-22, -3), makescore(-18, -9), makescore(-27, -8), makescore(-34, 27), makescore(0, 38), makescore(-9, 0)]),
SVector{8}([makescore(-9, -12), makescore(4, -18), makescore(5, 0), makescore(-3, 9), makescore(-11, 12), makescore(-9, 32), makescore(-171, 77), makescore(-17, 11)])
])

const KING_SHELTER_ONFILE = SVector{8}([
SVector{8}([makescore(0, 0), makescore(-13, -25), makescore(2, -20), makescore(-40, 14), makescore(-24, 0), makescore(1, 40), makescore(-169, -10), makescore(-48, 5)]),
SVector{8}([makescore(0, 0), makescore(22, -23), makescore(5, -9), makescore(-20, -3), makescore(-3, -14), makescore(24, 64), makescore(-186, -5), makescore(-40, 1)]),
SVector{8}([makescore(0, 0), makescore(30, -13), makescore(-4, -9), makescore(5, -19), makescore(13, -9), makescore(-89, 45), makescore(-86, -75), makescore(-20, -7)]),
SVector{8}([makescore(0, 0), makescore(-5, 7), makescore(-4, 0), makescore(-19, 0), makescore(-29, 0), makescore(-100, 30), makescore(5, -43), makescore(-24, -9)]),
SVector{8}([makescore(0, 0), makescore(10, 0), makescore(10, -7), makescore(12, -13), makescore(12, -28), makescore(-59, 13), makescore(-106, -63), makescore(-3, -9)]),
SVector{8}([makescore(0, 0), makescore(4, -10), makescore(-20, 0), makescore(-29, -8), makescore(15, -26), makescore(-40, 1), makescore(53, 36), makescore(-20, -8)]),
SVector{8}([makescore(0, 0), makescore(20, -17), makescore(10, -15), makescore(-10, -9), makescore(-29, 7), makescore(-10, 13), makescore(-58, -50), makescore(-33, 10)]),
SVector{8}([makescore(0, 0), makescore(10, -40), makescore(17, -29), makescore(-20, -6), makescore(-19, 16), makescore(-7, 20), makescore(-230, -57), makescore(-24, 0)])
])

const KING_STORM_UNBLOCKED = SVector{4}([
SVector{8}([makescore(-7, 26), makescore(116, -10), makescore(-28, 23), makescore(-22, 5), makescore(-17, 0), makescore(-10, -7), makescore(-19, 2), makescore(-25, -5)]),
SVector{8}([makescore(-6, 46), makescore(54, 9), makescore(-22, 21), makescore(-8, 8), makescore(-7, 2), makescore(2, -7), makescore(-4, 0), makescore(-14, 0)]),
SVector{8}([makescore(5, 35), makescore(14, 20), makescore(-26, 18), makescore(-14, 8), makescore(0, 0), makescore(4, 0), makescore(8, -10), makescore(0, -4)]),
SVector{8}([makescore(-5, 22), makescore(13, 18), makescore(-19, 8), makescore(-17, 0), makescore(-16, 0), makescore(4, -14), makescore(0, -10), makescore(-16, 0)])
])

const KING_STORM_BLOCKED = SVector{4}([
SVector{8}([makescore(0, 0), makescore(-18, -19), makescore(-20, -4), makescore(15, -20), makescore(7, -10), makescore(0, -20), makescore(-6, -4), makescore(14, 26)]),
SVector{8}([makescore(0, 0), makescore(-19, -37), makescore(-6, -11), makescore(32, -14), makescore(-4, -5), makescore(10, -26), makescore(-10, -13), makescore(-20, 0)]),
SVector{8}([makescore(0, 0), makescore(-31, -52), makescore(-30, -9), makescore(8, -14), makescore(0, -5), makescore(-11, -17), makescore(-16, -18), makescore(-14, 3)]),
SVector{8}([makescore(0, 0), makescore(-5, -20), makescore(-19, -20), makescore(-14, -7), makescore(-7, -10), makescore(1, -28), makescore(70, -14), makescore(10, 18)])
])


#============================ Queen Evaluation ================================#


#============================ Other Evaluation ================================#


const SPACE_BONUS = 4
const PIN_BONUS = 15
const HANGING_BONUS = makescore(70, 35)
const THREAT_BY_KING = makescore(25, 90)
const THREAT_BY_MINOR = @SVector [makescore(5, 30), makescore(60, 40), makescore(80, 55), makescore(90, 120), makescore(80, 160)]
const THREAT_BY_ROOK = @SVector [makescore(5, 45), makescore(40, 70), makescore(40, 60), makescore(0, 40), makescore(50, 40)]
const THREAT_BY_PAWN = makescore(170, 95)
const LAZY_THRESH = 2000
const MINOR_KING_PROTECTION = makescore(8, 6)
const RESTRICTION_BONUS = makescore(6, 6)
const KNIGHT_SAFE_CHECK = 100
const QUEEN_SAFE_CHECK  = 80
const BISHOP_SAFE_CHECK = 65
const ROOK_SAFE_CHECK   = 110
const KING_FLANK_DEFEND = makescore(2, 0)
const KING_BOX_WEAK = makescore(7, 0)
const UNSAFE_CHECK = makescore(4, 0)
const KNIGHT_ON_QUEEN = makescore(15, 10)
const THREAT_BY_PUSH = makescore(50, 40)


#========================= Mobility Evaluation ================================#


const KNIGHT_MOBILITY = @SVector [makescore(-60,-80), makescore(-50,-55), makescore(-10,-30), makescore( -5,-15),
    makescore(  5,  10), makescore( 15, 15), makescore( 20, 25), makescore( 30, 30), makescore( 35, 35)]

const BISHOP_MOBILITY = @SVector [makescore(-50,-60), makescore(-20,-25), makescore( 15, -5), makescore( 25, 15), makescore( 40, 25),
    makescore( 50, 40), makescore( 55, 55), makescore( 65, 60), makescore( 65, 65), makescore( 70, 75), makescore( 80, 80),
    makescore( 80, 85), makescore( 90, 90), makescore( 100, 100)]

const ROOK_MOBILITY = @SVector [makescore(-60,-75), makescore(-30,-20), makescore(-15, 30), makescore(-10, 55), makescore( -5, 70), makescore( 0, 80),
      makescore(  10,110), makescore( 15,120), makescore( 30,130), makescore( 30,140), makescore( 30,155), makescore( 40,165),
      makescore( 45,165), makescore( 50,170), makescore( 60,170)]

const QUEEN_MOBILITY = @SVector [makescore(-40,-35), makescore(-20,-15), makescore(  5,  10), makescore(  5, 20), makescore( 15, 35), makescore( 20, 55),
      makescore( 30, 60), makescore( 40, 75), makescore( 45, 80), makescore( 50, 90), makescore( 55, 95), makescore( 60,105),
      makescore( 60,115), makescore( 65,120), makescore( 70,125), makescore( 70,125), makescore( 70,130), makescore( 75,135),
      makescore( 80,140), makescore( 90,145), makescore( 90,150), makescore( 100,165), makescore(100,170), makescore(100,175),
      makescore(105,185), makescore(110,190), makescore(115,205), makescore(115,210)]


#============================ SCALING FACTORS =================================#


const SCALE_OCB_BISHOPS = 64
const SCALE_OCB_ONE_KNIGHT = 106
const SCALE_OCB_ONE_ROOK = 96
const SCALE_DRAW = 0
const SCALE_NORMAL = 128
