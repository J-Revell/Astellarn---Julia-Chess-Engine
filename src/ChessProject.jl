module ChessProject
    using Crayons
    using StaticArrays

    import Base.iterate, Base.push!, Base.length, Base.eltype, Base.size,
    Base.IndexStyle, Base.getindex, Base.popfirst!, Base.splice!

    # globally used constants
    include("constants.jl")

    # Files relating to the board
    include("board.jl")
    include("boardQuery.jl")
    include("displayBoard.jl")

    # Load the files which build moves
    # standard piece moves
    include("pawnMoves.jl")
    include("kingMoves.jl")
    include("knightMoves.jl")
    # sliding piece moves
    include("magic.jl")
    include("slidingMoves.jl")
    include("rookMoves.jl")
    include("bishopMoves.jl")
    include("queenMoves.jl")

    include("attacks.jl")
    include("moveBuilder.jl")

    include("play.jl")
    include("moveMaker.jl")

    include("judge.jl")

    include("monkeyAI.jl")


    export @newGame, @play

    export Board, startBoard, displayBitboard, displayColorBoard, Move, MoveList, Undo, UndoStack

    export gen_moves!, randMove!, move!, gen_moves

    export isCheckmate, isStalemate, isDrawByMaterial, isLegal
end # module
