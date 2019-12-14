# Astellarn
Astellarn is a simple chess project to satisfy my own curiosity, and learn about board representation, engine principles, and algorithms! Written in 100% Julia.

## Example usage:
`@newgame` starts a new global instance of the chess board from the starting position.
Moves can be made using the `@move` macro call.

![REPL-Play](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-move.jpg)

Game positions can be imported using the standard FEN notation using the `@importfen` macro.

![REPL-FEN](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-fen.jpg)

Random moves may be played using the "monkeyAI" via the `@random` macro.

![REPL-RAND](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-rand.jpg)


## News:
* 21 Nov 2019: 
  - Internals now support full legal move generation including all castling, promotions, and enpassant. 
  - Internals support making moves, and undoing moves. 
  - Magic bitboards have been implemented for bishop, rook, and queen move generation. 
  - Checks are made for checkmate, stalemate, and draws by insufficient material. 
  - FEN import is now supported.
  - Ability to play random moves using the MonkeyAI
* 12 Nov 2019: 
  - Initial upload, with workable board display in the Julia REPL

## Next steps:
* perft support, and benchmarks.
* FEN export.
* PGN import and export.
* Algebraic notation for input / output.
* Engine search features (alpha-beta or MCTS)
* Better external documentation, and user input.

### Cool things:
* Ethereal Engine (https://github.com/AndyGrant/Ethereal)
* Alan Bahms Julia engine (https://github.com/abahm/Chess.jl)
* Lc0 (https://github.com/LeelaChessZero)
* Chess programming wiki (https://www.chessprogramming.org)
* Stockfish (https://github.com/official-stockfish/Stockfish)
* Tord Romstad's chess library (https://github.com/romstad/Chess.jl)
