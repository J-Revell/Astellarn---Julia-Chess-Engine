using Astellarn
using Test

# First test perft on known positions for common bugs
# https://www.chessprogramming.org/Perft_Results

@testset "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" begin
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    b = Astellarn.importfen(fen)
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


@testset "SEE k7/8/6b1/3p4/4r3/3PQ3/5N2/K7 w - - 0 1" begin
    fen = "k7/8/6b1/3p4/4r3/3PQ3/5N2/K7 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(21, 28)
    @test static_exchange_evaluator(b, move, t) == true
    b.turn = !b.turn
    move = Move(28, 20)
    @test static_exchange_evaluator(b, move, t) == true
    move = Move(28, 36)
    @test static_exchange_evaluator(b, move, t) == false
end

@testset "SEE 7k/3r4/3q4/8/3p4/2BK4/8/8 w - - 0 1" begin
    fen = "7k/3r4/3q4/8/3p4/2BK4/8/8 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(22, 29)
    @test static_exchange_evaluator(b, move, t) == false
    fen = "3r3k/8/8/2p1p3/3p4/2BK4/2N5/8 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(22, 29)
    @test static_exchange_evaluator(b, move, t) == false
    fen = "3r3k/3r4/3q4/8/3p4/2BK4/1QN5/8 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(22, 29)
    @test static_exchange_evaluator(b, move, t) == true
    fen = "3r3k/8/8/2p1p3/3n4/2BKP3/8/8 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(22, 29)
    @test static_exchange_evaluator(b, move, t) == true
    fen = "k7/8/8/8/1rrpK3/3R4/8/8 w - - 0 1"
    b = importfen(fen)
    t = 0
    move = Move(21, 29)
    @test static_exchange_evaluator(b, move, t) == false
end

@testset "Wider SEE tests" begin
    fen_data = [
    ("4R3/2r3p1/5bk1/1p1r3p/p2PR1P1/P1BK1P2/1P6/8 b - -", Move(33, 26), 0),
    ("4R3/2r3p1/5bk1/1p1r1p1p/p2PR1P1/P1BK1P2/1P6/8 b - -", Move(33, 26), 0),
    ("4r1k1/5pp1/nbp4p/1p2p2q/1P2P1b1/1BP2N1P/1B2QPPK/3R4 b - -", Move(26, 19), 0),
    ("2r1r1k1/pp1bppbp/3p1np1/q3P3/2P2P2/1P2B3/P1N1B1PP/2RQ1RK1 b - -", Move(45, 36), SEE_VALUES[1]),
    ("7r/5qpk/p1Qp1b1p/3r3n/BB3p2/5p2/P1P2P2/4RK1R w - -", Move(4, 60), 0),
    ("6rr/6pk/p1Qp1b1p/2n5/1B3p2/5p2/P1P2P2/4RK1R w - -", Move(4, 60), -SEE_VALUES[4]),
    ("7r/5qpk/2Qp1b1p/1N1r3n/BB3p2/5p2/P1P2P2/4RK1R w - -", Move(4, 60), -SEE_VALUES[4]),
    ("6RR/4bP2/8/8/5r2/3K4/5p2/4k3 w - -", Move(51, 59, __QUEEN_PROMO), SEE_VALUES[3] - SEE_VALUES[1]),
    ("6RR/4bP2/8/8/5r2/3K4/5p2/4k3 w - -", Move(51, 59, __KNIGHT_PROMO), SEE_VALUES[2] - SEE_VALUES[1]),
    ("7R/5P2/8/8/8/3K2r1/5p2/4k3 w - -", Move(51, 59, __QUEEN_PROMO), SEE_VALUES[5] - SEE_VALUES[1]),
    ("7R/5P2/8/8/8/3K2r1/5p2/4k3 w - -", Move(51, 59, __BISHOP_PROMO), SEE_VALUES[3] - SEE_VALUES[1]),
    ("7R/4bP2/8/8/1q6/3K4/5p2/4k3 w - -", Move(51, 59, __ROOK_PROMO), -SEE_VALUES[1])
    ]
    for fd in fen_data
        @test static_exchange_evaluator(importfen(fd[1]), fd[2], fd[3]) == true
    end
end
