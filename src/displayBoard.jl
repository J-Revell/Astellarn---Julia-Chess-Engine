function displayColorBoard(board::Board)
    for row in 1:9
        for col in 1:9
            if row == 9
                    col == 1 && print("  ")
                    col == 2 && print("A ")
                    col == 3 && print("B ")
                    col == 4 && print("C ")
                    col == 5 && print("D ")
                    col == 6 && print("E ")
                    col == 7 && print("F ")
                    col == 8 && print("G ")
                    col == 9 && print("H ")
            elseif col == 1
                print(9 - row, " ")
            else
                sqr = getBitboard(col - 1, 9 - row)
                piece = getPiece(board, sqr)
                color = getColor(board, sqr)
                if color == BLACK
                    sym = SYMBOLS[piece]
                    foreground = :black
                elseif color == WHITE
                    sym = SYMBOLS[piece]
                    foreground = :white
                else
                    sym = ' '
                    foreground = :default
                end
                if isodd(row + col + 1)
                    background = :blue
                else
                    background = :light_blue
                end
                print(Crayon(foreground = foreground, background = background),
                sym, " ")
                if (row == 1) && (col == 9) && (board.turn == WHITE)
                    print(Crayon(reset = true), " White to move...")
                elseif (row == 1) && (col == 9) && (board.turn == BLACK)
                    print(Crayon(reset = true), " Black to move...")
                end
            end
        end
        print(Crayon(reset = true), "\n")
    end
    println()
end

macro board()
    global __gboard = Board()
    displayColorBoard(__gboard)
end

macro newGame()
    global __gboard = startBoard()
    displayColorBoard(__gboard)
end
