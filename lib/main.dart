import 'package:chess/chess.dart' as chesslib;
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';

import 'ccboard/components/hints.dart';
import 'ccboard/models/arrow.dart';
import 'ccboard/models/board_orientation.dart';
import 'ccboard/models/drop_indicator_args.dart';
import 'ccboard/models/hint_map.dart';
import 'ccboard/models/piece_drop_event.dart';
import 'ccboard/models/piece_map.dart';
import 'ccboard/models/square.dart';
import 'ccboard/chessboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = ChessboardController();
  chesslib.Chess chess = chesslib.Chess();
  List<List<int>>? lastMove;

  // not working on drop
  Widget squareBuilder(SquareInfo info) {
    Color fieldColor = (info.index + info.rank) % 2 == 0 ? Colors.grey.shade200 : Colors.grey.shade600;
    Color overlayColor = Colors.transparent;

    if (lastMove != null) {
      if (lastMove!.first.first == info.rank && lastMove!.first.last == info.file) {
        overlayColor = Colors.blueAccent.withAlpha(0x70);
      } else if (lastMove!.last.first == info.rank && lastMove!.last.last == info.file) {
        overlayColor = Colors.blueAccent.withAlpha(0xA0);
      }
    }

    return Container(
      color: fieldColor,
      width: info.size,
      height: info.size,
      child: AnimatedContainer(
        color: overlayColor,
        width: info.size,
        height: info.size,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  PieceMap pieceMap() => PieceMap(
    K: (size) => WhiteKing(size: size),
    Q: (size) => WhiteQueen(size: size),
    B: (size) => WhiteBishop(size: size),
    N: (size) => WhiteKnight(size: size),
    R: (size) => WhiteRook(size: size),
    P: (size) => WhitePawn(size: size),
    k: (size) => BlackKing(size: size),
    q: (size) => BlackQueen(size: size),
    b: (size) => BlackBishop(size: size),
    n: (size) => BlackKnight(size: size),
    r: (size) => BlackRook(size: size),
    p: (size) => BlackPawn(size: size),
  );

  void onPieceStartDrag(SquareInfo square, String piece) {
    showHintFields(square, piece);
  }

  void onPieceTap(SquareInfo square, String piece) {
    if (controller.hints.key == square.index.toString()) {
      controller.setHints(HintMap());
      return;
    }
    showHintFields(square, piece);
  }

  void showHintFields(SquareInfo square, String piece) {
    final moves = chess.generate_moves({'square': square.toString()});
    final hintMap = HintMap(key: square.index.toString());
    for (var move in moves) {
      String to = move.toAlgebraic;
      int rank = to.codeUnitAt(1) - '1'.codeUnitAt(0) + 1;
      int file = to.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;

      hintMap.set(rank, file, (size) => MoveHint(size: size, onPressed: () => doMove(move)));
    }
    controller.setHints(hintMap);
  }

  void onEmptyFieldTap(SquareInfo square) {
    controller.setHints(HintMap());
  }

  void onPieceDrop(PieceDropEvent event) {
    chess.move({'from': event.from.toString(), 'to': event.to.toString()});

    lastMove = [
      [event.from.rank, event.from.file],
      [event.to.rank, event.to.file],
    ];

    update(animated: false);
  }

  void doMove(chesslib.Move move) {
    chess.move(move);

    int rankFrom = move.fromAlgebraic.codeUnitAt(1) - '1'.codeUnitAt(0) + 1;
    int fileFrom = move.fromAlgebraic.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
    int rankTo = move.toAlgebraic.codeUnitAt(1) - '1'.codeUnitAt(0) + 1;
    int fileTo = move.toAlgebraic.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
    lastMove = [
      [rankFrom, fileFrom],
      [rankTo, fileTo],
    ];

    update();
  }

  void setDefaultFen() {
    setState(() => chess = chesslib.Chess.fromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'));
    update();
  }

  void setRandomFen() {
    setState(() => chess = chesslib.Chess.fromFEN('3bK3/4B1P1/3p2N1/1rp3P1/2p2p2/p3n3/P5k1/6q1 w - - 0 1'));
    update();
  }

  void update({bool animated = true}) {
    controller.setFen(chess.fen, animation: animated);
  }

  void addArrows() {
    controller.setArrows([
      Arrow(from: SquareLocation.fromString('b1'), to: SquareLocation.fromString('c3')),
      Arrow(from: SquareLocation.fromString('g1'), to: SquareLocation.fromString('f3'), color: Colors.red),
    ]);
  }

  void removeArrows() {
    controller.setArrows([]);
  }

  BoardOrientation orientation = BoardOrientation.white;
  void toggleOrientation() {
    setState(
      () => orientation = orientation == BoardOrientation.white ? BoardOrientation.black : BoardOrientation.white,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WPChessboard Demo',
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final double size = MediaQuery.of(context).size.shortestSide;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Chessboard(
                size: size,
                orientation: orientation,
                squareBuilder: squareBuilder,
                controller: controller,
                // Dont pass any onPieceDrop handler to disable drag and drop
                onPieceDrop: onPieceDrop,
                onPieceTap: onPieceTap,
                onPieceStartDrag: onPieceStartDrag,
                onEmptyFieldTap: onEmptyFieldTap,
                turnTopPlayerPieces: false,
                ghostOnDrag: true,
                dropIndicator: DropIndicatorArgs(size: size / 2, color: Colors.lightBlue.withAlpha(0x30)),
                pieceMap: pieceMap(),
              ),
              const SizedBox(height: 24),
              TextButton(onPressed: setDefaultFen, child: const Text('Set default Fen')),
              TextButton(onPressed: setRandomFen, child: const Text('Set random Fen')),
              TextButton(onPressed: addArrows, child: const Text('Add Arrows')),
              TextButton(onPressed: removeArrows, child: const Text('Remove Arrows')),
              TextButton(onPressed: toggleOrientation, child: const Text('Change Orientation')),
            ],
          );
        },
      ),
    ),
  );
}
