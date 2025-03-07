import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'ccboard/board_template.dart';
import 'ccboard/chessboard.dart';
import 'ccboard/components/hints.dart';
import 'ccboard/models/arrow.dart';
import 'ccboard/models/board_orientation.dart';
import 'ccboard/models/drop_indicator_args.dart';
import 'ccboard/models/hint_map.dart';
import 'ccboard/models/piece_drop_event.dart';
import 'ccboard/models/square.dart';
import 'ccboard/models/ui_adapter.dart';
import 'cchess/cchess.dart';
import 'cchess/models/move.dart';

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

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  bool _isLoaded = false;

  Future<void> _initAsync() async {
    final templatePath = await expandBoardImageAsset('assets/images/board.png');
    if (templatePath == null) return;

    await BoardTemplate().load(templatePath);
    setState(() => _isLoaded = true);
  }

  UIAdapter uiAdapter() {
    Widget wrap(ImageProvider image, double size) {
      return Image(image: image, width: size, height: size, fit: BoxFit.fill);
    }

    return UIAdapter(
      board: BoardTemplate().getBoardImage()!,
      R: (size) => wrap(BoardTemplate().getPieceImage('R')!, size),
      N: (size) => wrap(BoardTemplate().getPieceImage('N')!, size),
      B: (size) => wrap(BoardTemplate().getPieceImage('B')!, size),
      A: (size) => wrap(BoardTemplate().getPieceImage('A')!, size),
      K: (size) => wrap(BoardTemplate().getPieceImage('K')!, size),
      C: (size) => wrap(BoardTemplate().getPieceImage('C')!, size),
      P: (size) => wrap(BoardTemplate().getPieceImage('P')!, size),
      r: (size) => wrap(BoardTemplate().getPieceImage('r')!, size),
      n: (size) => wrap(BoardTemplate().getPieceImage('n')!, size),
      b: (size) => wrap(BoardTemplate().getPieceImage('b')!, size),
      a: (size) => wrap(BoardTemplate().getPieceImage('a')!, size),
      k: (size) => wrap(BoardTemplate().getPieceImage('k')!, size),
      c: (size) => wrap(BoardTemplate().getPieceImage('c')!, size),
      p: (size) => wrap(BoardTemplate().getPieceImage('p')!, size),
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
    final moves = chess.movesOf(square.toString());

    final hintMap = HintMap(key: square.index.toString());

    for (var move in moves) {
      final (fx, fy, tx, ty) = move.coordinateLB;

      hintMap.set(
        ty,
        tx,
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
    ///
    /// Index of event.from and event.to is from left-bottom corner
    ///
    final move = Move(
      Move.toCoordinateLB(event.from.index),
      Move.toCoordinateLB(event.to.index),
    );

    chess.move(move);

    lastMove = [
      [event.from.rank, event.from.file],
      [event.to.rank, event.to.file],
    ];

    controller.setFen(chess.fen, animation: false);
  }

  void doMove(Move move) {
    chess.move(move);
    final (fx, fy, tx, ty) = move.coordinate;

    lastMove = [
      [fy, fx],
      [ty, tx],
    ];

    controller.setFen(chess.fen);
  }

  void setDefaultFen() {
    chess.reset();
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
            builder: (context) => _isLoaded ? buildBody(context) : const Center(child: CircularProgressIndicator()),
          ),
        ),
      );

  Column buildBody(BuildContext context) {
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
          uiAdapter: uiAdapter(),
        ),
        const SizedBox(height: 24),
        TextButton(onPressed: setDefaultFen, child: const Text('Set default Fen')),
        TextButton(onPressed: addArrows, child: const Text('Add Arrows')),
        TextButton(onPressed: removeArrows, child: const Text('Remove Arrows')),
        TextButton(onPressed: toggleOrientation, child: const Text('Change Orientation')),
      ],
    );
  }
}

Future<String?> expandBoardImageAsset(String assetPath) async {
  const kBoardImageFolder = 'board-images';

  Directory? docdir = await getDocDir();
  if (docdir == null) return null;

  final boardImagePath = Directory('${docdir.path}/$kBoardImageFolder/board.png');

  if (!(await boardImagePath.exists())) {
    await boardImagePath.parent.create(recursive: true);

    final file = File(boardImagePath.path);
    await file.create(recursive: true);

    final bytes = await rootBundle.load(assetPath);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }

  return boardImagePath.path;
}

Future<Directory?> getDocDir() async {
  if (Platform.isAndroid) return await getExternalStorageDirectory();
  return await getApplicationDocumentsDirectory();
}
