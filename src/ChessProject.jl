module ChessProject
    using Crayons
    using StaticArrays

    import Base.iterate, Base.push!, Base.length, Base.eltype, Base.size,
    Base.IndexStyle, Base.getindex

    include("constants.jl")
    include("board.jl")
    include("boardQuery.jl")
    include("displayBoard.jl")
    include("makeMove.jl")
    include("slidingMoves.jl")
    include("rookMoves.jl")
    include("bishopMoves.jl")
    include("moveBuilder.jl")


    export @newGame, @move
end # module
