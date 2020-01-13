module Astellarn
    const ASTELLARN_VERSION = "v0.1.9"

    using Crayons
    using StaticArrays
    using Printf

    import Base.&, Base.|, Base.~, Base.<<, Base.>>, Base.⊻, Base.!, Base.bswap
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

    include("types.jl")

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

    include("parameters.jl")
    include("evaluate.jl")
    include("syzygy.jl")
    include("transposition.jl")

    include("thread.jl")
    include("moveorder.jl")
    include("history.jl")
    include("search.jl")

    include("engine.jl")
    include("play.jl")

    include("uci.jl")


    export Bitboard, Board, Piece, PieceType, Color, Magic, Move, Undo, MoveStack, UndoStack
    export @newgame, @move, @random, @engine, @importfen, @perft

    export importfen, exportfen
    export pawns, kings, bishops, knights, rooks, queens, enemy, friendly, occupied, empty, rooklike, bishoplike
    export checkers, pinned, cancastlekingside, cancastlequeenside
    export ischeck, islegal, ischeckmate, isstalemate, isdrawbymaterial
    export monkey!, perft, engine!

    export WHITE, BLACK
    export PAWN, KNIGHT, BISHOP, ROOK, KING, QUEEN
    export WHITEPAWN, WHITEKNIGHT, WHITEBISHOP, WHITEROOK, WHITEQUEEN, WHITEKING
    export BLACKPAWN, BLACKKNIGHT, BLACKBISHOP, BLACKROOK, BLACKQUEEN, BLACKKING

    #export tb_init

    export uci_main

end
