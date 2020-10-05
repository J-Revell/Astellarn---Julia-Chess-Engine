using BlackBoxOptim
using NLopt

const TUNING_DATASET = "../tuner/quiet-labeled.epd"

function generate_fens(dataset::String)
   fens = String[]
   results = Float64[]
   open(dataset) do f
      # line_number
      line = 0
      # read till end of file
      while ! eof(f) && line < 750000
         # read a new / next line for every iteration
         s = readline(f)
         idx_end = findfirst("c9", s)[2] + 2
         idx_start = findfirst("c9", s)[1] - 1
         fen = s[1:idx_start] * "0 1"
         push!(fens, fen)
         result = s[idx_end:end-1]
         if result == "\"0-1\""
            R = 0.0
         elseif result == "\"1/2-1/2\""
            R = 0.5
         else
            R = 1.0
         end
         push!(results, R)
         line += 1
      end
   end
   return fens, results
end

# evaluate all the fen positions (assuming quiet)
function evaluate_quiet_fens(fens::Vector{String})
   _pk = PawnKingTable()
   evals = Int[]
   for fen in fens
      board = importfen(fen)
      eval = evaluate(board, _pk)
      board.turn == WHITE ? push!(evals, eval) : push!(evals, -eval)
   end
   return evals
end

#K is a value which has to be tuned prior to the main run.
function sigmoidFunc(input::Int, K::Float64)
   output = 1 / (1 + 10 ^ (-(K * input) / 400))
end

function evalError(R::Float64, eval::Int, K::Float64)
   return (R - sigmoidFunc(eval, K))^2
end

function get_evalerr(K::Float64, evals::Vector{Int}, results::Vector{Float64})
   evalerrs = Float64[]
   for i in eachindex(evals)
      err = evalError(results[i], evals[i], K)
      push!(evalerrs, err)
   end
   evalerr = sum(evalerrs)/length(evalerrs)
   return evalerr
end
get_evalerr(Ks::Vector{Float64}, evals::Vector{Int}, Rs::Vector{Float64}) = get_evalerr(Ks[1], evals, Rs)

function tune_K(evals::Vector{Int}, results::Vector{Float64})
   K = bboptimize(x->get_evalerr(x, evals, results); SearchRange = (0.0,2.0), NumDimensions = 1, MaxSteps = 1500)
   return best_candidate(K)[1]
end

const __PKDummy = PawnKingTable()

function tune_custom_subroutine2(x::Vector{Float64}, K::Float64, boards::Vector{Board}, results::Vector{Float64}, hashmap::Dict{Vector{Int}, Float64}, evals::Vector{Int})
   xint = round.(Int, x)
   if in(xint, keys(hashmap))
      return hashmap[xint]
   end
   params = Dict(
   "KNIGHT_SAFE_CHECK" => xint[1],
   "QUEEN_SAFE_CHECK" => xint[2],
   "BISHOP_SAFE_CHECK" => xint[3],
   "ROOK_SAFE_CHECK" => xint[4],
   "KD_QUEEN" => xint[5],
   "KD_ROOK" => xint[6],
   "KD_BISHOP" => xint[7],
   "KD_KNIGHT" => xint[8],
   "HANGING_BONUS_MG" => xint[9],
   "HANGING_BONUS_EG" => xint[10],
   "THREAT_BY_PAWN_MG" => xint[11],
   "THREAT_BY_PAWN_EG" => xint[12],
   "THREAT_BY_PUSH_MG" => xint[13],
   "THREAT_BY_PUSH_EG" => xint[14],
   "THREAT_BY_KING_MG" => xint[15],
   "THREAT_BY_KING_EG" => xint[16],
   "KNIGHT_OUTPOST_BONUS_MG" => xint[17],
   "KNIGHT_OUTPOST_BONUS_EG" => xint[18],
   "BISHOP_OUTPOST_BONUS_MG" => xint[19],
   "BISHOP_OUTPOST_BONUS_EG" => xint[20],
   "BISHOP_CENTRAL_CONTROL_MG" => xint[21],
   "BISHOP_CENTRAL_CONTROL_EG" => xint[22],
   "BISHOP_PAIR_BONUS_MG" => xint[23],
   "BISHOP_PAIR_BONUS_EG" => xint[24],
   "DOUBLE_PAWN_PENALTY_MG" => xint[25],
   "DOUBLE_PAWN_PENALTY_EG" => xint[26],
   "ISOLATED_PAWN_PENALTY_MG" => xint[27],
   "ISOLATED_PAWN_PENALTY_EG" => xint[28],
   "WEAK_UNOPPOSED_MG" => xint[29],
   "WEAK_UNOPPOSED_EG" => xint[30],
   "PIN_BONUS" => xint[31],
   "PAWNLESS_FLANK_MG" => xint[32],
   "PAWNLESS_FLANK_EG" => xint[33],
   "SPACE_BONUS" => xint[34],
   "THREAT_BY_MINOR_1_MG" => xint[35],
   "THREAT_BY_MINOR_1_EG" => xint[36],
   "THREAT_BY_MINOR_2_MG" => xint[37],
   "THREAT_BY_MINOR_2_EG" => xint[38],
   "THREAT_BY_MINOR_3_MG" => xint[39],
   "THREAT_BY_MINOR_3_EG" => xint[40],
   "THREAT_BY_MINOR_4_MG" => xint[41],
   "THREAT_BY_MINOR_4_EG" => xint[42],
   "THREAT_BY_MINOR_5_MG" => xint[43],
   "THREAT_BY_MINOR_5_EG" => xint[44],
   "THREAT_BY_ROOK_1_MG" => xint[45],
   "THREAT_BY_ROOK_1_EG" => xint[46],
   "THREAT_BY_ROOK_2_MG" => xint[47],
   "THREAT_BY_ROOK_2_EG" => xint[48],
   "THREAT_BY_ROOK_3_MG" => xint[49],
   "THREAT_BY_ROOK_3_EG" => xint[50],
   "THREAT_BY_ROOK_4_MG" => xint[51],
   "THREAT_BY_ROOK_4_EG" => xint[52],
   "THREAT_BY_ROOK_5_MG" => xint[53],
   "THREAT_BY_ROOK_5_EG" => xint[54],
   "ROOK_OPEN_FILE_BONUS_MG" => xint[55],
   "ROOK_OPEN_FILE_BONUS_EG" => xint[56],
   "ROOK_SEMIOPEN_FILE_BONUS_MG" => xint[57],
   "ROOK_SEMIOPEN_FILE_BONUS_EG" => xint[58],
   "ROOK_ON_QUEEN_FILE_MG" => xint[59],
   "ROOK_ON_QUEEN_FILE_EG" => xint[60],
   "PAWN_SHIELD_BONUS_MG" => xint[61],
   "PAWN_SHIELD_BONUS_EG" => xint[62],
   "BISHOP_COLOR_PENALTY_MG" => xint[63],
   "BISHOP_COLOR_PENALTY_EG" => xint[64],
   "BISHOP_RAMMED_COLOR_PENALTY_MG" => xint[65],
   "BISHOP_RAMMED_COLOR_PENALTY_EG" => xint[66],
   "KNIGHT_POTENTIAL_OUTPOST_BONUS_MG" => xint[67],
   "KNIGHT_POTENTIAL_OUTPOST_BONUS_EG" => xint[68],
   "KNIGHT_RAMMED_BONUS_MG" => xint[69],
   "KNIGHT_RAMMED_BONUS_EG" => xint[70],
   "WEAK_LEVER_MG" => xint[71],
   "WEAK_LEVER_EG" => xint[72],
   "BACKWARD_PAWN_MG" => xint[73],
   "BACKWARD_PAWN_EG" => xint[74],
   "KING_FLANK_ATTACK_MG" => xint[75],
   "KING_FLANK_ATTACK_EG" => xint[76],
   "KING_FLANK_DEFEND_MG" => xint[77],
   "KING_FLANK_DEFEND_EG" => xint[78],
   "KING_BOX_WEAK_MG" => xint[79],
   "KING_BOX_WEAK_EG" => xint[80],
   "UNSAFE_CHECK_MG" => xint[81],
   "UNSAFE_CHECK_EG" => xint[82],
   "RESTRICTION_BONUS_MG" => xint[83],
   "RESTRICTION_BONUS_EG" => xint[84],
   "VAL_PAWN_MG" => xint[85],
   "VAL_PAWN_EG" => xint[86],
   "VAL_KNIGHT_MG" => xint[87],
   "VAL_KNIGHT_EG" => xint[88],
   "VAL_BISHOP_MG" => xint[89],
   "VAL_BISHOP_EG" => xint[90],
   "VAL_ROOK_MG" => xint[91],
   "VAL_ROOK_EG" => xint[92],
   "VAL_QUEEN_MG" => xint[93],
   "VAL_QUEEN_EG" => xint[94]
   )
   for (i, b) in enumerate(boards)
      eval = evaluate(b, __PKDummy, params)
      b.turn == WHITE ? (evals[i] = eval) : (evals[i] = -eval)
   end
   evalerr = get_evalerr(K, evals, results)
   hashmap[xint] = evalerr
   return evalerr
end

function tune_custom_pvals_subroutine(x::Vector{Float64}, K::Float64, boards::Vector{Board}, results::Vector{Float64}, hashmap::Dict{Vector{Int}, Float64}, evals::Vector{Int})
   xintp = round.(Int, x)
   if in(xintp, keys(hashmap))
      return hashmap[xintp]
   end
   params = Dict(
   "VAL_PAWN_MG" => xintp[1],
   "VAL_PAWN_EG" => xintp[2],
   "VAL_KNIGHT_MG" => xintp[3],
   "VAL_KNIGHT_EG" => xintp[4],
   "VAL_BISHOP_MG" => xintp[5],
   "VAL_BISHOP_EG" => xintp[6],
   "VAL_ROOK_MG" => xintp[7],
   "VAL_ROOK_EG" => xintp[8],
   "VAL_QUEEN_MG" => xintp[9],
   "VAL_QUEEN_EG" => xintp[10]
   )
   for (i, b) in enumerate(boards)
      eval = evaluatep(b, __PKDummy, params)
      b.turn == WHITE ? (evals[i] = eval) : (evals[i] = -eval)
   end
   evalerr = get_evalerr(K, evals, results)
   hashmap[xintp] = evalerr
   return evalerr
end

# function check_evalerrs(K::Float64, x::Vector{Float64}, fens::Vector{String}, results::Vector{Float64})
#    _pk = PawnKingTable()
#    evals = Int[]
#    xint = round.(Int, x)
#    params = Dict(
#    "KNIGHT_SAFE_CHECK" => xint[1],
#    "QUEEN_SAFE_CHECK" => xint[2],
#    "BISHOP_SAFE_CHECK" => xint[3],
#    "ROOK_SAFE_CHECK" => xint[4],
#    "KD_QUEEN" => xint[5],
#    "KD_ROOK" => xint[6],
#    "KD_BISHOP" => xint[7],
#    "KD_KNIGHT" => xint[8],
#    "HANGING_BONUS_MG" => xint[9],
#    "HANGING_BONUS_EG" => xint[10],
#    "THREAT_BY_PAWN_MG" => xint[11],
#    "THREAT_BY_PAWN_EG" => xint[12],
#    "THREAT_BY_PUSH_MG" => xint[13],
#    "THREAT_BY_PUSH_EG" => xint[14],
#    "THREAT_BY_KING_MG" => xint[15],
#    "THREAT_BY_KING_EG" => xint[16],
#    "KNIGHT_OUTPOST_BONUS_MG" => xint[17],
#    "KNIGHT_OUTPOST_BONUS_EG" => xint[18],
#    "BISHOP_OUTPOST_BONUS_MG" => xint[19],
#    "BISHOP_OUTPOST_BONUS_EG" => xint[20],
#    "BISHOP_CENTRAL_CONTROL_MG" => xint[21],
#    "BISHOP_CENTRAL_CONTROL_EG" => xint[22],
#    "BISHOP_PAIR_BONUS_MG" => xint[23],
#    "BISHOP_PAIR_BONUS_EG" => xint[24],
#    "DOUBLE_PAWN_PENALTY_MG" => xint[25],
#    "DOUBLE_PAWN_PENALTY_EG" => xint[26],
#    "ISOLATED_PAWN_PENALTY_MG" => xint[27],
#    "ISOLATED_PAWN_PENALTY_EG" => xint[28],
#    "WEAK_UNOPPOSED_MG" => xint[29],
#    "WEAK_UNOPPOSED_EG" => xint[30],
#    "PIN_BONUS" => xint[31],
#    "PAWNLESS_FLANK_MG" => xint[32],
#    "PAWNLESS_FLANK_EG" => xint[33],
#    "SPACE_BONUS" => xint[34],
#    "THREAT_BY_MINOR_1_MG" => xint[35],
#    "THREAT_BY_MINOR_1_EG" => xint[36],
#    "THREAT_BY_MINOR_2_MG" => xint[37],
#    "THREAT_BY_MINOR_2_EG" => xint[38],
#    "THREAT_BY_MINOR_3_MG" => xint[39],
#    "THREAT_BY_MINOR_3_EG" => xint[40],
#    "THREAT_BY_MINOR_4_MG" => xint[41],
#    "THREAT_BY_MINOR_4_EG" => xint[42],
#    "THREAT_BY_MINOR_5_MG" => xint[43],
#    "THREAT_BY_MINOR_5_EG" => xint[44],
#    "THREAT_BY_ROOK_1_MG" => xint[45],
#    "THREAT_BY_ROOK_1_EG" => xint[46],
#    "THREAT_BY_ROOK_2_MG" => xint[47],
#    "THREAT_BY_ROOK_2_EG" => xint[48],
#    "THREAT_BY_ROOK_3_MG" => xint[49],
#    "THREAT_BY_ROOK_3_EG" => xint[50],
#    "THREAT_BY_ROOK_4_MG" => xint[51],
#    "THREAT_BY_ROOK_4_EG" => xint[52],
#    "THREAT_BY_ROOK_5_MG" => xint[53],
#    "THREAT_BY_ROOK_5_EG" => xint[54],
#    "ROOK_OPEN_FILE_BONUS_MG" => xint[55],
#    "ROOK_OPEN_FILE_BONUS_EG" => xint[56],
#    "ROOK_SEMIOPEN_FILE_BONUS_MG" => xint[57],
#    "ROOK_SEMIOPEN_FILE_BONUS_EG" => xint[58],
#    "ROOK_ON_QUEEN_FILE_MG" => xint[59],
#    "ROOK_ON_QUEEN_FILE_EG" => xint[60],
#    "PAWN_SHIELD_BONUS_MG" => xint[61],
#    "PAWN_SHIELD_BONUS_EG" => xint[62],
#    "BISHOP_COLOR_PENALTY_MG" => xint[63],
#    "BISHOP_COLOR_PENALTY_EG" => xint[64],
#    "BISHOP_RAMMED_COLOR_PENALTY_MG" => xint[65],
#    "BISHOP_RAMMED_COLOR_PENALTY_EG" => xint[66],
#    "KNIGHT_POTENTIAL_OUTPOST_BONUS_MG" => xint[67],
#    "KNIGHT_POTENTIAL_OUTPOST_BONUS_MG" => xint[68],
#    "KNIGHT_RAMMED_BONUS_MG" => xint[69],
#    "KNIGHT_RAMMED_BONUS_EG" => xint[70],
#    "WEAK_LEVER_MG" => xint[71],
#    "WEAK_LEVER_EG" => xint[72],
#    "BACKWARD_PAWN_MG" => xint[73],
#    "BACKWARD_PAWN_EG" => xint[74],
#    "KING_FLANK_ATTACK_MG" => xint[75],
#    "KING_FLANK_ATTACK_EG" => xint[76],
#    "KING_FLANK_DEFEND_MG" => xint[77],
#    "KING_FLANK_DEFEND_EG" => xint[78],
#    "KING_BOX_WEAK_MG" => xint[79],
#    "KING_BOX_WEAK_EG" => xint[80],
#    "UNSAFE_CHECK_MG" => xint[81],
#    "UNSAFE_CHECK_EG" => xint[82],
#    "RESTRICTION_BONUS_MG" => xint[83],
#    "RESTRICTION_BONUS_EG" => xint[84]
#    )
#    for fen in fens
#       board = importfen(fen)
#       eval = evaluate(board, _pk, params)
#       board.turn == WHITE ? push!(evals, eval) : push!(evals, -eval)
#    end
#    evalerrs = Float64[]
#    for i in eachindex(evals)
#       err = evalError(results[i], evals[i], K)
#       push!(evalerrs, err)
#    end
#    evalerr = sum(evalerrs)/length(evalerrs)
#    return evalerr
# end

function tune_custom()
   fens, results = generate_fens(TUNING_DATASET)
   evals = evaluate_quiet_fens(fens)
   K = tune_K(evals, results)
   boards = [importfen(fen) for fen in fens]
   hashmap = Dict{Vector{Int}, Float64}()
   x0 = [172.65161652791906, 141.58983391303113, 75.13100814216968, 140.626904898952, 36.828578408435625, 2.801681527160235, 0.2575989769807775, 2.4250960429229353, 0.6580962627431566, 16.433942955909334, 129.14809330149285, 18.09705376583098, 58.11137680463415, 52.25487010523731, 0.2678656443201804, 40.57483833270058, 20.00155661767537, 85.95973320726112, 36.01826034540851, 18.113788215214647, 31.473874802700408, 33.82901631928183, 22.69466872370791, 58.81823108488587, 20.035545810410646, 56.73883608209794, 23.155579672110026, 22.30874203966197, 22.134784747798893, 36.9148925760245, 21.502037477090838, 48.71413289606196, 98.42643990442063, 1.0912150802142762, 13.224614395890182, 43.09743303993973, 72.90062973569896, 86.58822732511985, 64.97001565903155, 66.79762015913596, 146.64678597632303, 10.865247182678335, 107.54952124021054, 130.35648556993755, 27.829646196487484, 47.81605489103571, 52.243882337059134, 33.913706470928624, 47.06913635366598, 113.12496252092133, 12.060957166518698, 4.417097395339201, 121.18744683112628, 12.875693093613748, 88.5504292473196, 19.080099403266257, 4.503208716537994, 0.22960251795223277, 28.56183215806565, 7.319238321975622, 18.87915149421753, 7.251113410810003, 15.280227577602734, 28.140104695514932, 13.804326402328456, 9.099058863834156, 0.2851306121799322, 23.20977883850896, 9.09813691004362, 13.030537159199445, 6.936394247560924, 58.181814382412576, 14.873448928692092, 29.582671778401014, 12.747877626658472, 1.7882499089466144, 6.812695839734369, 1.0228518565968991, 14.04047741914536, 5.652516327914085, 11.725816614578658, 5.403808434641939, 13.09803351267975, 1.108363836611018, 201.50949141758343, 232.7973185082286, 899.638150364838, 871.5170506970924, 932.9715606905397, 943.6596072356882, 1185.1411391992644, 1485.8679857814202, 2659.6882745267185, 2790.7090330539286]
   lb = max.(x0 .- 20, 0)
   lb[85:94] .= 50.0
   ub = x0 .+ 20
   bounds = collect(zip(lb, ub))
   r = bboptimize(x->tune_custom_subroutine2(x, K, boards, results, hashmap, evals); SearchRange = bounds, MaxSteps=50000)
   return r
end

function tune_custom2()
   fens, results = generate_fens(TUNING_DATASET)
   evals = evaluate_quiet_fens(fens)
   K = tune_K(evals, results)
   boards = [importfen(fen) for fen in fens]
   opt = Opt(:LN_COBYLA, 94)
   x0 = [178.6058870130871, 144.3676373476542, 80.98115984728992, 146.32811040024748, 42.182244007215985, 6.185882743673277, 1.2844626389174594, 1.4159558153583234, 1.7563667450077964, 23.009660982644466, 123.51270729091468, 17.410091063891137, 57.20370041885199, 58.02139660035854, 4.105475010093423, 33.00742776821396, 11.439933943079396, 67.41746141129222, 39.818185283890315, 30.513228691159036, 42.05896451423976, 36.180051680501336, 34.65151397827, 75.4247949924086, 28.494536841504246, 56.56374960731823, 33.72901140502862, 28.361487701090052, 22.20114049882258, 29.668280935671408, 25.21140424023683, 54.28559340222898, 93.9768341078798, 0.6067247833454101, 12.935759229627966, 35.20958647895319, 66.87655230416657, 81.17970991612935, 57.47466599378172, 64.40526210766676, 152.39618746638263, 4.908922691422668, 104.44014962370797, 129.1654228745449, 23.001259020876986, 35.32246265186432, 60.769909663005805, 44.3471885310492, 50.46199983958596, 98.42419428756698,
2.201695289856095, 7.3074366338775425, 122.3666068170664, 22.167678518114244, 114.67186783060507, 10.614415506370166, 37.22987936939206, 3.7412110115467843, 35.23458536461326, 16.42715107071433, 18.736971307025613, 5.325028834214506, 10.064588656019769, 22.523102551844236, 13.78706904827353, 19.62206637197484, 2.040286116393751, 19.276328835438164, 4.746633755688664, 12.258341554642234, 6.908099637177671, 49.89928640977655, 14.785267311181043, 19.707652909786784, 12.0558693420207, 2.408617940241448, 8.432289073140753, 0.027654886564371234, 5.013527966715608, 17.871198950418716, 17.609961898171683, 3.3373101044894016, 12.948993978535054, 0.2792916459805551, 207.40972508185448, 235.0060983396108, 929.5608597273784, 877.6201896418826, 949.4850654274297, 954.8750470147678, 1176.9402922316572, 1503.0218357847516, 2688.9718065030697, 2819.5488694569435]
   opt.lower_bounds = max.(x0 .- 20.0, 0.0) #repeat([0.0], 84)
   opt.upper_bounds = x0 .+ 20.0 #repeat([190.0], 84)
   #opt.lower_bounds[85:94] .= 50.0
   hashmap = Dict{Vector{Int}, Float64}()
   opt.min_objective = (x,y)->tune_custom_subroutine2(x, K, boards, results, hashmap, evals)
   (minf,minx,ret) = optimize(opt, x0)
end

function tune_custom_pvals()
   fens, results = generate_fens(TUNING_DATASET)
   evals = evaluate_quiet_fens(fens)
   K = tune_K(evals, results)
   boards = [importfen(fen) for fen in fens]
   # opt = Opt(:LN_COBYLA, 10)
   x0 = [120.0, 210.0, 780.0, 850, 820, 920, 1280.0, 1380, 2540, 2680]
   # x1 = [178.6058870130871, 144.3676373476542, 80.98115984728992, 146.32811040024748, 42.182244007215985, 6.185882743673277, 1.2844626389174594, 1.4159558153583234, 1.7563667450077964, 23.009660982644466, 123.51270729091468, 17.410091063891137, 57.20370041885199, 58.02139660035854, 4.105475010093423, 33.00742776821396, 11.439933943079396, 67.41746141129222, 39.818185283890315, 30.513228691159036, 42.05896451423976, 36.180051680501336, 34.65151397827, 75.4247949924086, 28.494536841504246, 56.56374960731823, 33.72901140502862, 28.361487701090052, 22.20114049882258, 29.668280935671408, 25.21140424023683, 54.28559340222898, 93.9768341078798, 0.6067247833454101, 12.935759229627966, 35.20958647895319, 66.87655230416657, 81.17970991612935, 57.47466599378172, 64.40526210766676, 152.39618746638263, 4.908922691422668, 104.44014962370797, 129.1654228745449, 23.001259020876986, 35.32246265186432, 60.769909663005805, 44.3471885310492, 50.46199983958596, 98.42419428756698,
2.201695289856095, 7.3074366338775425, 122.3666068170664, 22.167678518114244, 114.67186783060507, 10.614415506370166, 37.22987936939206, 3.7412110115467843, 35.23458536461326, 16.42715107071433, 18.736971307025613, 5.325028834214506, 10.064588656019769, 22.523102551844236, 13.78706904827353, 19.62206637197484, 2.040286116393751, 19.276328835438164, 4.746633755688664, 12.258341554642234, 6.908099637177671, 49.89928640977655, 14.785267311181043, 19.707652909786784, 12.0558693420207, 2.408617940241448, 8.432289073140753, 0.027654886564371234, 5.013527966715608, 17.871198950418716, 17.609961898171683, 3.3373101044894016, 12.948993978535054, 0.2792916459805551, 207.40972508185448, 235.0060983396108, 929.5608597273784, 877.6201896418826, 949.4850654274297, 954.8750470147678, 1176.9402922316572, 1503.0218357847516, 2688.9718065030697, 2819.5488694569435]
   # opt.lower_bounds = x0./3 #repeat([0.0], 84)
   # opt.upper_bounds = x0 .+ 100 #repeat([190.0], 84)
   hashmap = Dict{Vector{Int}, Float64}()
   # opt.min_objective = (x,y)->tune_custom_pvals_subroutine2(x, x1, K, boards, results, hashmap)
   # (minf,minx,ret) = optimize(opt, x0)

   lb = x0 ./ 3
   ub = x0 .+ 100
   bounds = collect(zip(lb, ub))
   r = bboptimize(x->tune_custom_pvals_subroutine(x, K, boards, results, hashmap, evals); SearchRange = bounds, MaxSteps=50000)
end
