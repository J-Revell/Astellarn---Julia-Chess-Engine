module ChessProject
    using Crayons
    using StaticArrays

    import Base.iterate, Base.push!, Base.length, Base.eltype, Base.size,
    Base.IndexStyle, Base.getindex

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


    export @newGame, @move

    export Board, gen_moves!, MoveList, Move, randMove!, startBoard, move!, gen_moves, gen_moves!, isCheckmate, isStalemate, isDrawByMaterial
end # module
