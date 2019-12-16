using Astellarn
using Test

# First test perft on known positions for common bugs
# https://www.chessprogramming.org/Perft_Results

@testset "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" begin
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    b = importfen(fen)
    @test cancastlekingside(b) == true
    @test cancastlekingside(b, BLACK) == true
    @test cancastlequeenside(b) == true
    @test cancastlequeenside(b, BLACK) == true
    @test ischeck(b) == false
    @test b.enpass == zero(UInt8)
    @test perft(b, 1) == 20
    @test perft(b, 2) == 400
    @test perft(b, 3) == 8902
    @test perft(b, 4) == 197281
    @test perft(b, 5) == 4865609
    @test perft(b, 6) == 119060324
end

@testset "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -" begin
    fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -"
    b = importfen(fen)
    @test cancastlekingside(b) == true
    @test cancastlekingside(b, BLACK) == true
    @test cancastlequeenside(b) == true
    @test cancastlequeenside(b, BLACK) == true
    @test ischeck(b) == false
    @test b.enpass == zero(UInt8)
    @test perft(b, 1) == 48
    @test perft(b, 2) == 2039
    @test perft(b, 3) == 97862
    @test perft(b, 4) == 4085603
    @test perft(b, 5) == 193690690
    #@test perft(b, 6) == 8031647685
end

@testset "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -" begin
    fen = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -"
    b = importfen(fen)
    @test cancastlekingside(b) == false
    @test cancastlekingside(b, BLACK) == false
    @test cancastlequeenside(b) == false
    @test cancastlequeenside(b, BLACK) == false
    @test ischeck(b) == false
    @test b.enpass == zero(UInt8)
    @test perft(b, 1) == 14
    @test perft(b, 2) == 191
    @test perft(b, 3) == 2812
    @test perft(b, 4) == 43238
    @test perft(b, 5) == 674624
    @test perft(b, 6) == 11030083
end

@testset "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1" begin
    fen1 = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
    fen2 = "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1"
    b1 = importfen(fen1)
    b2 = importfen(fen2)
    @test cancastlekingside(b1, BLACK) == true
    @test cancastlequeenside(b1, BLACK) == true
    @test cancastlekingside(b1, WHITE) == false
    @test cancastlequeenside(b1, WHITE) == false
    @test cancastlekingside(b2, WHITE) == true
    @test cancastlequeenside(b2, WHITE) == true
    @test cancastlekingside(b2, BLACK) == false
    @test cancastlequeenside(b2, BLACK) == false
    @test perft(b1, 1) == perft(b2, 1) == 6
    @test perft(b1, 2) == perft(b2, 2) == 264
    @test perft(b1, 3) == perft(b2, 3) == 9467
    @test perft(b1, 4) == perft(b2, 4) == 422333
    @test perft(b1, 5) == perft(b2, 5) == 15833292
end
