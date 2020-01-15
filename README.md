![LOGO](https://github.com/J-Revell/Astellarn/blob/master/logo.png)
# Astellarn
Astellarn is a simple chess project to satisfy my own curiosity, and learn about board representation, engine principles, and algorithms!

Written in Julia, implementing the UCI protocol, with Syzygy tablebase support via calls to Fathom (https://github.com/jdart1/Fathom).

## Features:

### Core representation:
* Bitboard representation.
* Magic bitboards for sliding attack generation.
* Zobrist hashing.

### Engine features:
* Alpha-beta search.
  - Iterative deepening.
  - Aspiration windows.
  - Futility pruning.
  - Late move reductions.
  - Razoring.
  - Null-move pruning.
* Quiescence search.
  - Delta-pruning.
* Static exchange evaluation.
* Move Ordering.
  - Killer moves.
  - Counter moves.
  - History heuristics.
  - MVV-LVA heuristics.
* Syzygy tablebase probing via Fathom (c-library).
* Transposition hash tables.
* Pawn hash tables.
* (In development) Time management function.


### Julia functionality:
* FEN position import.
* Coloured REPL output.
* Engine interface.
* UCI interface.

### Debugging:
* perft (https://www.chessprogramming.org/Perft)

## Example usage in the Julia REPL:
`@newgame` starts a new global instance of the chess board from the starting position.

![REPL-NEWGAME](https://github.com/J-Revell/Astellarn/blob/master/img/repl-newgame.jpg)

Moves can be made using the `@move` macro call.

![REPL-MOVE](https://github.com/J-Revell/Astellarn/blob/master/img/repl-move.png)

Castling is also implemented via standard algebraic notation.

![REPL-CASTLE](https://raw.githubusercontent.com/J-Revell/ChessProject/master/img/repl-castle.jpg)

Game positions can be imported using the standard FEN notation using the `@importfen` macro.

![REPL-FEN](https://raw.githubusercontent.com/J-Revell/ChessProject/master/img/repl-fen.jpg)

Random moves may be played using the "monkey" AI via the `@random` macro. This simply picks a random legal move to play. More sophisticated moves using Astellarn's engine can be played to a given depth with the `@engine depth` macro, where `depth` is an integer depth to search.

![REPL-ENGINE](https://raw.githubusercontent.com/J-Revell/ChessProject/master/img/repl-engine.jpg)

This outputs the evaluation, depth, selected depth, and information about the pricipal variation examined.

## Example usage via the UCI interface:
Astellarn.jl is compatible with the UCI protocol for chess, supplying the function `uci_main()` to read from the I/O. `src/AstellarnEngine.jl` is built to be executable (with chmod a+x), and can be sent to foreign UCI compliant interfaces such as Arena (http://www.playwitharena.de/).

 ![ARENA](https://raw.githubusercontent.com/J-Revell/ChessProject/master/img/arena.png)


## News:
* January 2020:
  - UCI protocol added.
  - Transposition tables implemented.
  - Syzygy tablebases implemented.
  - Added futility pruning, MVV-LVA heuristics
  - Limited move ordering considerations.
  - Limited late move reductions.
  - Razoring added.
  - Implemented aspiration windows.
  - Implemented iterative deepening.
  - Pawn hash tables.
  - Killer move, counter move, and history heuristics.
  - Improved evaluation.
  - Added time management (v0.2.0)
* Dec 2019:
  - Perft support added.
  - Implemented core alpha-beta search.
  - Implemented quiescence search.
  - Implemented static exchange evaluation.
  - Added delta-pruning for quiescence search.
* Nov 2019: 
  - Internals now support full legal move generation including all castling, promotions, and enpassant. 
  - Magic bitboards have been implemented for bishop, rook, and queen move generation. 
  - Checks are made for checkmate, stalemate, and all draws. 
  - FEN import is now supported.
  - Ability to play random moves using the MonkeyAI
  - Initial upload, with workable board display in the Julia REPL

## Next steps:
* PGN import and export.
* Additional engine search features, pruning heuristics.
* Sophisticated evaluation.
* Tuning.
* Multithreading (Julia support is experimental)
* Better time management.

### Cool things:
* Ethereal Engine (https://github.com/AndyGrant/Ethereal)
* Alan Bahms Julia engine (https://github.com/abahm/Chess.jl)
* Lc0 (https://github.com/LeelaChessZero)
* Chess programming wiki (https://www.chessprogramming.org)
* Stockfish (https://github.com/official-stockfish/Stockfish)
* Tord Romstad's chess library (https://github.com/romstad/Chess.jl)
