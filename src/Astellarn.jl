module Astellarn
    const ASTELLARN_VERSION = "v0.1.5"

    using Crayons
    using StaticArrays
    using Printf

    import Base.&, Base.|, Base.~, Base.<<, Base.>>, Base.⊻, Base.!
    import Base.isempty, Base.isone
    import Base.getindex, Base.setindex!, Base.push!
    import Base.iterate, Base.length, Base.eltype, Base.size, Base.IndexStyle
    import Base.copy!
    import Base.show

    include("../deps/config.jl")

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
    include("movecount.jl")

    include("perft.jl")

    include("evaluate.jl")
    include("syzygy.jl")
    include("transposition.jl")

    include("moveorder.jl")

    include("thread.jl")
    include("search.jl")

    include("engine.jl")
    include("play.jl")

    include("uci.jl")


    export Bitboard, Board, Piece, PieceType, Color, Magic, Move, Undo, MoveStack, UndoStack
    export @newgame, @move, @random, @engine, @importfen

    export importfen, exportfen
    export pawns, kings, bishops, knights, rooks, queens, enemy, friendly, occupied, empty, rooklike, bishoplike
    export checkers, pinned, cancastlekingside, cancastlequeenside
    export ischeck, islegal, ischeckmate, isstalemate, isdrawbymaterial
    export monkey!, perft, engine!

    export WHITE, BLACK

    export tb_init

    export main

end
