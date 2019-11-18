module ChessProject
    using Crayons
    using StaticArrays

    import Base.iterate, Base.push!, Base.length, Base.eltype, Base.size,
    Base.IndexStyle, Base.getindex

    include("constants.jl")

    # Files relating to the board
    include("board.jl")
    include("boardQuery.jl")
    include("displayBoard.jl")

    # Load the files which build moves
    include("pawnMoves.jl")
    include("kingMoves.jl")
    include("knightMoves.jl")
    include("slidingMoves.jl")
    include("rookMoves.jl")
    include("bishopMoves.jl")
    include("queenMoves.jl")
    include("attacks.jl")
    include("moveBuilder.jl")

    include("makeMove.jl")


    export @newGame, @move

    export Board, gen_moves!, MoveList, Move, randMove!
end # module
