module ChessProject
    using Crayons
    include("constants.jl")
    include("board.jl")
    include("displayBoard.jl")
    include("makeMove.jl")
    include("pawnMoves.jl")
    include("kingMoves.jl")
    include("knightMoves.jl")
    include("moveBuilder.jl")


    export @newGame, @move
end # module
