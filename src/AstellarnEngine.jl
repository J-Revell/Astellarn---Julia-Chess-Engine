#!/home/jeremy/julia/julia

# initialise the engine
# include("Astellarn.jl")
# using .Astellarn
using Astellarn

# start the uci loop
Base.@ccallable function julia_main()::Cint
    uci_main()
    return 0
end
