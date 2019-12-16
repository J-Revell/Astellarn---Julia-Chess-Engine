module Astellarn
    using Crayons
    using StaticArrays

    import Base.&, Base.|, Base.~, Base.<<, Base.>>, Base.⊻, Base.!
    import Base.isempty, Base.isone
    import Base.getindex, Base.setindex!, Base.push!
    import Base.iterate, Base.length, Base.eltype, Base.size, Base.IndexStyle
    import Base.show

    include("bitboard.jl")
    include("pieces.jl")

    include("zobrist.jl")

    include("board.jl")
    include("fen.jl")

    include("pawns.jl")
    include("kings.jl")
    include("knights.jl")
    include("magic.jl")
    include("rooks.jl")
    include("bishops.jl")
    include("queens.jl")

    include("attacks.jl")

    include("move.jl")
    include("movegen.jl")

    include("perft.jl")

    include("judge.jl")

    include("evaluate.jl")
    include("search.jl")

    include("engine.jl")
    include("play.jl")


    export Bitboard, Board, Piece, PieceType, Color, Magic, Move, Undo, MoveStack, UndoStack
    export @newgame, @move, @random, @engine

    export importfen
    export pawns, kings, bishops, knights, rooks, queens, enemy, friendly, occupied, empty, rooklike, bishoplike
    export checkers, pinned, cancastlekingside, cancastlequeenside
    export ischeck, islegal, ischeckmate, isstalemate, isdrawbymaterial
    export monkey!, perft, engine!

    export WHITE, BLACK

end
