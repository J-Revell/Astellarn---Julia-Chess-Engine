module ChessProject
    using Crayons
    include("consts.jl")
    include("board.jl")
    include("display.jl")
    include("move.jl")
    include("gen_moves.jl")


    export @newGame, @move
end # module
