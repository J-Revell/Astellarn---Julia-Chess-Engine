# Astellarn
Astellarn is a simple chess project to satisfy my own curiosity, and learn about board representation, engine principles, and algorithms! Written in 100% Julia.

## Features:

### Core representation:
* Bitboard representation.
* Magic bitboards for sliding attack generation.
* Zobrist hashing.
* FEN position import.
* Coloured REPL output.

### Engine features:
* Alpha-beta search.
* Quiescence search.
* Static exchange evaluation.
* Piece square tables.

### Debugging:
* perft (https://www.chessprogramming.org/Perft)

## Example usage:
`@newgame` starts a new global instance of the chess board from the starting position.
Moves can be made using the `@move` macro call.

![REPL-Play](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-move.jpg)

Castling is also implemented via standard algebraic notation.

![REPL-CASTLE](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-castle.jpg)

Game positions can be imported using the standard FEN notation using the `@importfen` macro.

![REPL-FEN](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-fen.jpg)

Random moves may be played using the "monkey" AI via the `@random` macro. Engine moves may be generated using Astellarn via the `@engine` macro. 

![REPL-RAND](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-rand.jpg)
![REPL-ENGINE](https://raw.githubusercontent.com/J-Revell/ChessProject/master/repl-engine.jpg)


## News:
* Dec 2019:
  - Perft support added.
  - Implemented core alpha-beta search.
  - Implemented quiescence search.
  - Implemented static exchange evaluation.
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
* FEN export.
* PGN import and export.
* UCI protocol interface.
* Additional engine search features, pruning heuristics.
* Sophisticated evaluation.

### Cool things:
* Ethereal Engine (https://github.com/AndyGrant/Ethereal)
* Alan Bahms Julia engine (https://github.com/abahm/Chess.jl)
* Lc0 (https://github.com/LeelaChessZero)
* Chess programming wiki (https://www.chessprogramming.org)
* Stockfish (https://github.com/official-stockfish/Stockfish)
* Tord Romstad's chess library (https://github.com/romstad/Chess.jl)
