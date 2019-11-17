module ChessProject
    using Crayons
    using StaticArrays

    import Base.iterate, Base.push!, Base.length, Base.eltype, Base.size,
    Base.IndexStyle, Base.getindex

    include("constants.jl")

    # Files which modify the board
    include("board.jl")
    include("boardQuery.jl")
    include("displayBoard.jl")
    include("makeMove.jl")

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


    export @newGame, @move
end # module
