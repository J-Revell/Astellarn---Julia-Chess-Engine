#========================== Scoring functions =================================#
struct Score
    val::Int
end
makescore(mg::Int, eg::Int) = Int32(mg + (eg << 16))
scoreMG(s::Integer) = Int(Int32(unsigned(s) & 0x7fff) - Int32(unsigned(s) & 0x8000))
scoreEG(s::Integer) = Int((s + 0x8000) >> 16)


#============================ Piece square tables =============================#


# Accesses the piece square tables, applying any scaling according to the game phase.
function psqt(piece::Piece, sqr::Integer)
    pt = type(piece)
    col = color(piece)
    factor = 1
    if col == BLACK
        sqr = 65 - sqr
        factor = -1
    end
    @inbounds file = FILE_TO_QSIDE_MAP[fileof(sqr)]
    rank = rankof(sqr)
    @inbounds psqt_vec = (PSQT[pt.val][rank][file] + PVALS[pt.val]) * factor
end


#========================= Late Move Reduction tables =========================#


function init_reduction_table()
    lmrtable = zeros(Int, (64, 64))
    for depth in 1:64
        for played in 1:64
            lmrtable[depth, played] = floor(Int, 0.6 + log(depth) * log(played) / 2.0)
        end
    end
    lmrtable
end
