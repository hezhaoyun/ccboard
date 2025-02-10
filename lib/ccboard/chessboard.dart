import 'package:flutter/material.dart';

import 'components/arrows.dart';
import 'components/drop_targets.dart';
import 'components/hints.dart';
import 'components/pieces.dart';
import 'components/squares.dart';
import 'models/arrow.dart';
import 'models/board_orientation.dart';
import 'models/chess_state.dart';
import 'models/drop_indicator_args.dart';
import 'models/hint_map.dart';
import 'models/piece_drop_event.dart';
import 'models/piece_map.dart';
import 'models/square_info.dart';

class Chessboard extends StatefulWidget {
  final double size;
  final Widget Function(SquareInfo) squareBuilder;
  final PieceMap pieceMap;
  final BoardOrientation orientation;
  final ChessboardController controller;
  final void Function(SquareInfo square, String piece)? onPieceTap;
  final void Function(SquareInfo square, String piece)? onPieceStartDrag;
  final void Function(SquareInfo square)? onEmptyFieldTap;
  final void Function(PieceDropEvent)? onPieceDrop;
  final bool ghostOnDrag;
  final bool turnTopPlayerPieces;
  final DropIndicatorArgs? dropIndicator;

  const Chessboard({
    super.key,
    required this.size,
    required this.squareBuilder,
    required this.pieceMap,
    required this.controller,
    this.onPieceTap,
    this.onPieceDrop,
    this.onEmptyFieldTap,
    this.onPieceStartDrag,
    this.orientation = BoardOrientation.white,
    this.ghostOnDrag = false,
    this.dropIndicator,
    this.turnTopPlayerPieces = false,
  });

  @override
  State<Chessboard> createState() => _ChessboardState();
}

class _ChessboardState extends State<Chessboard> {
  ChessState state = ChessState('');
  HintMap hints = HintMap();
  ArrowList arrows = ArrowList([]);

  @override
  void initState() {
    state = widget.controller.state;
    widget.controller.addListener(_controllerListener);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_controllerListener);
  }

  void _controllerListener() {
    if (state.fen != widget.controller.state.fen) {
      onUpdateState(widget.controller.state);
    }
    if (hints.id != widget.controller.hints.id) {
      onUpdateHints(widget.controller.hints);
    }
    if (arrows.id != widget.controller.arrows.id) {
      onUpdateArrows(widget.controller.arrows);
    }
  }

  void onUpdateState(ChessState newState) {
    setState(() {
      state = newState;
    });
  }

  void onUpdateHints(HintMap newHints) {
    setState(() {
      hints = newHints;
    });
  }

  void onUpdateArrows(ArrowList newArrows) {
    setState(() {
      arrows = newArrows;
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    width: widget.size,
    height: widget.size,
    child: RotatedBox(
      quarterTurns: (widget.orientation == BoardOrientation.black) ? 2 : 0,
      child: Stack(
        children: [
          Squares(
            key: Key('squares_${widget.size}_${state.fen}'),
            size: widget.size,
            squareBuilder: widget.squareBuilder,
          ),

          Positioned.fill(
            child: Pieces(
              key: Key('pieces_${widget.size}_${state.fen}'),
              size: widget.size,
              orientation: widget.orientation,
              turnTopPlayerPieces: widget.turnTopPlayerPieces,
              pieceMap: widget.pieceMap,
              state: state,
              onPieceTap: widget.onPieceTap,
              onPieceStartDrag: widget.onPieceStartDrag,
              disableDrag: widget.onPieceDrop == null,
              ghostOnDrag: widget.ghostOnDrag,
              onEmptyFieldTap: widget.onEmptyFieldTap,
              animated: widget.controller.shouldAnimate,
            ),
          ),

          Positioned.fill(child: Hints(key: Key(hints.id.toString()), size: widget.size, hints: hints)),

          Positioned.fill(child: Arrows(size: widget.size, arrows: arrows.value)),

          Positioned.fill(
            child: DropTargets(size: widget.size, onPieceDrop: widget.onPieceDrop, dropIndicator: widget.dropIndicator),
          ),
        ],
      ),
    ),
  );
}

class ChessboardController extends ChangeNotifier {
  ChessState state = ChessState('');
  HintMap hints = HintMap();
  ArrowList arrows = ArrowList([]);
  bool shouldAnimate = true;

  ChessboardController({initialFen = ''}) {
    state = ChessState(initialFen);
  }

  void setFen(String value, {bool resetHints = true, bool newGame = false, bool animation = true}) {
    shouldAnimate = animation;

    if (newGame) {
      state = ChessState(value, last: null);
    } else {
      state = ChessState(value, last: state);
    }

    if (resetHints) {
      hints = HintMap();
    }

    notifyListeners();
  }

  void setHints(HintMap value) {
    hints = value;
    notifyListeners();
  }

  void setArrows(List<Arrow> value) {
    arrows = ArrowList(value);
    notifyListeners();
  }
}
