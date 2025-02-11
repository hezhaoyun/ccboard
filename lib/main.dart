import 'package:flutter/material.dart';

import 'ccboard/chessboard.dart';
import 'ccboard/components/hints.dart';
import 'ccboard/models/arrow.dart';
import 'ccboard/models/board_orientation.dart';
import 'ccboard/models/drop_indicator_args.dart';
import 'ccboard/models/hint_map.dart';
import 'ccboard/models/piece_drop_event.dart';
import 'ccboard/models/square.dart';
import 'ccboard/models/ui_map.dart';
import 'cchess/cchess.dart';
import 'cchess/move.dart';
import 'cchess/position.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final chess = CChess();

  final controller = ChessboardController();
  List<List<int>>? lastMove;

  UIMap uiMap() {
    Widget wrap(Widget child, double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Center(child: child),
        );

    return UIMap(
      bg: (size) => Image.asset('assets/images/board.png', width: size * 9, height: size * 10, fit: BoxFit.fill),
      R: (size) => wrap(Text('R', style: TextStyle(color: Colors.red)), size),
      N: (size) => wrap(Text('N', style: TextStyle(color: Colors.red)), size),
      B: (size) => wrap(Text('B', style: TextStyle(color: Colors.red)), size),
      A: (size) => wrap(Text('A', style: TextStyle(color: Colors.red)), size),
      K: (size) => wrap(Text('K', style: TextStyle(color: Colors.red)), size),
      C: (size) => wrap(Text('C', style: TextStyle(color: Colors.red)), size),
      P: (size) => wrap(Text('P', style: TextStyle(color: Colors.red)), size),
      r: (size) => wrap(Text('r', style: TextStyle(color: Colors.black)), size),
      n: (size) => wrap(Text('n', style: TextStyle(color: Colors.black)), size),
      b: (size) => wrap(Text('b', style: TextStyle(color: Colors.black)), size),
      a: (size) => wrap(Text('a', style: TextStyle(color: Colors.black)), size),
      k: (size) => wrap(Text('k', style: TextStyle(color: Colors.black)), size),
      c: (size) => wrap(Text('c', style: TextStyle(color: Colors.black)), size),
      p: (size) => wrap(Text('p', style: TextStyle(color: Colors.black)), size),
    );
  }

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
    final moves = chess.generateMoves(square.toString());

    final hintMap = HintMap(key: square.index.toString());

    for (var move in moves) {
      hintMap.set(
        move.ty,
        move.tx,
        (size) => MoveHint(
          size: size,
          onPressed: () => doMove(move),
        ),
      );
    }

    controller.setHints(hintMap);
  }

  void onEmptyFieldTap(SquareInfo square) {
    controller.setHints(HintMap());
  }

  void onPieceDrop(PieceDropEvent event) {
    chess.move(Move(event.from.index, event.to.index));

    lastMove = [
      [event.from.rank, event.from.file],
      [event.to.rank, event.to.file],
    ];

    controller.setFen(chess.fen, animation: false);
  }

  void doMove(Move move) {
    chess.move(move);

    lastMove = [
      [move.fy, move.fx],
      [move.ty, move.tx],
    ];

    controller.setFen(chess.fen);
  }

  void setDefaultFen() {
    chess.position = Position.defaultPosition();
    controller.setFen(chess.fen);
  }

  void addArrows() {
    controller.setArrows([
      Arrow(from: Square.fromString('b1'), to: Square.fromString('c3')),
      Arrow(from: Square.fromString('g1'), to: Square.fromString('f3'), color: Colors.red),
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
        title: 'CCBoard Demo',
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
                    controller: controller,
                    // Dont pass any onPieceDrop handler to disable drag and drop
                    onPieceDrop: onPieceDrop,
                    onPieceTap: onPieceTap,
                    onPieceStartDrag: onPieceStartDrag,
                    onEmptyFieldTap: onEmptyFieldTap,
                    turnTopPlayerPieces: false,
                    ghostOnDrag: true,
                    dropIndicator: DropIndicatorArgs(size: size / 2, color: Colors.lightBlue.withAlpha(0x30)),
                    uiMap: uiMap(),
                  ),
                  const SizedBox(height: 24),
                  TextButton(onPressed: setDefaultFen, child: const Text('Set default Fen')),
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
