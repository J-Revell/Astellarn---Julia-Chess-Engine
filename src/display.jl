function displayColorBoard(b::Board)
    for row in 1:8
        for col in 1:8
            sqr = square(col, 9 - row)
            piece = getPiece(b, sqr)
            color = getColor(b, sqr)
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
            if isodd(row+col)
                background = :blue
            else
                background = :light_blue
            end
            print(Crayon(foreground = foreground, background = background),
            sym, " ")
        end
        print(Crayon(reset = true), "\n")
    end
    println()
end

function displayLabelledColorBoard(b::Board)
    for row in 1:9
        for col in 1:9
            if row == 9
                if col == 1
                    print("  ")
                elseif col == 2
                    print("A ")
                elseif col == 3
                    print("B ")
                elseif col == 4
                    print("C ")
                elseif col == 5
                    print("D ")
                elseif col == 6
                    print("E ")
                elseif col == 7
                    print("F ")
                elseif col == 8
                    print("G ")
                elseif col == 9
                    print("H ")
                end
            elseif col == 1
                print(9 - row, " ")
            else
                sqr = square(col - 1, 9 - row)
                piece = getPiece(b, sqr)
                color = getColor(b, sqr)
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
                if (row == 1) && (col == 9) && (b.turn == WHITE)
                    print(Crayon(reset = true), " White to move...")
                elseif (row == 1) && (col == 9) && (b.turn == BLACK)
                    print(Crayon(reset = true), " Black to move...")
                end
            end
        end
        print(Crayon(reset = true), "\n")
    end
    println()
end

# useful for testing
function displayPawnMoves(b::Board)
    moveList = MoveList()
    build_pawn_moves!(moveList, b)
    dests = [el.move_to for el in moveList]
    collapse_dests = mapreduce(|, |, dests)
    for row in 1:9
        for col in 1:9
            if row == 9
                if col == 1
                    print("  ")
                elseif col == 2
                    print("A ")
                elseif col == 3
                    print("B ")
                elseif col == 4
                    print("C ")
                elseif col == 5
                    print("D ")
                elseif col == 6
                    print("E ")
                elseif col == 7
                    print("F ")
                elseif col == 8
                    print("G ")
                elseif col == 9
                    print("H ")
                end
            elseif col == 1
                print(9 - row, " ")
            else
                sqr = square(col - 1, 9 - row)
                #piece = getPiece(b, sqr)
                #color = getColor(b, sqr)
                if (sqr & collapse_dests) > 0
                    sym = 'x'
                    foreground = :red
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
                if (row == 1) && (col == 9)
                    print(Crayon(reset = true), " Available pawn moves...")
                end
            end
        end
        print(Crayon(reset = true), "\n")
    end
    println()
end

macro board()
    global __gboard = Board()
    displayLabelledColorBoard(__gboard)
end

macro newGame()
    global __gboard = startBoard()
    displayLabelledColorBoard(__gboard)
end
