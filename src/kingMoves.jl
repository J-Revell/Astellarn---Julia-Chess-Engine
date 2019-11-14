# steps in all compass directions
function kingMove_N(king::UInt64)
    king << 8
end

function kingMove_NE(king::UInt64)
    ~FILE_A & (king << 7)
end

function kingMove_E(king::UInt64)
    ~FILE_A & (king >> 1)
end

function kingMove_SE(king::UInt64)
    ~FILE_A & (king >> 9)
end

function kingMove_S(king::UInt64)
    (king >> 9)
end

function kingMove_SW(king::UInt64)
    ~FILE_H & (king >> 7)
end

function kingMove_W(king::UInt64)
    ~FILE_H & (king << 1)
end

function kingMove_NW(king::UInt64)
    ~FILE_H & (king << 9)
end

function kingMove_all(king::UInt64)
    kingMove_N(king) | kingMove_NE(king) | kingMove_E(king) | kingMove_SE(king) |
    kingMove_S(king) | kingMove_SW(king) | kingMove_W(king) | kingMove_NW(king)
end

const KING_MOVES = @SVector [kingMove_all(UInt(1) << i) for i in 0:63]
